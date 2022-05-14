# =======================
# Setup Script
# =======================


# -----------------------
# Stop Docker compose
# -----------------------
Write-Host "! Stop Docker compose" -BackgroundColor Cyan -ForegroundColor Black
docker compose rm -fsv grafana
docker compose rm -fsv fluentd
docker compose rm -fsv influxdb



# -----------------------
# Setup InfluxDB
# -----------------------
Write-Host "! Setup InfluxDB" -BackgroundColor Cyan -ForegroundColor Black

docker compose build influxdb

docker compose up -d influxdb

Start-Sleep -Seconds 5

$influxdbOrg = "myorg"
$influxdbBucket = "netflow"

$influxdbUser = "netflow"
$influxdbUserPassword = "influxdb-NetFlowUser-Password"

# https://docs.influxdata.com/influxdb/v2.2/organizations/buckets/create-bucket/
$influxdbBucketId = docker exec influxdb influx bucket create -n $influxdbBucket -o $influxdbOrg --hide-headers | %{ $_.Split("`t")[0]}

# https://docs.influxdata.com/influxdb/v2.2/users/create-user/
docker exec influxdb influx user create -n $influxdbUser -p $influxdbUserPassword -o $influxdbOrg

# https://docs.influxdata.com/influxdb/v2.2/security/tokens/create-token/
$influxdbTokenFluentd = docker exec influxdb influx auth create -u $influxdbUser -o $influxdbOrg -d fluentd_token --write-bucket $influxdbBucketId --hide-headers | %{ $_.Split("`t")[2]}

$influxdbTokenGrafana = docker exec influxdb influx auth create -u $influxdbUser -o $influxdbOrg -d grafana_token --read-bucket $influxdbBucketId --hide-headers | %{ $_.Split("`t")[2]}



# -----------------------
# Setup fluentd
# -----------------------
Write-Host "! Setup fluentd" -BackgroundColor Cyan -ForegroundColor Black

docker compose build fluentd

docker compose up -d fluentd

Start-Sleep -Seconds 5

$fluentdConf = (Get-Content -path fluentd\fluentd.conf -Raw) -replace 'my-token-from-influxdb2', $influxdbTokenFluentd

docker exec fluentd sh -c "echo '$fluentdConf' > /fluentd/etc/fluent.conf"

docker compose restart fluentd



# -----------------------
# Setup Grafana
# -----------------------
Write-Host "! Setup Grafana" -BackgroundColor Cyan -ForegroundColor Black

$urlGrafana = "http://localhost:3000"

docker compose build grafana

docker compose up -d grafana

Start-Sleep -Seconds 5

$authorizationText = "admin:Password"

$grafanaUser = "netflow"
$grafanaUserPassword = "grafana-NetFlowUser-Password"

$authorizationBase64 = [Convert]::ToBase64String(([System.Text.Encoding]::Default).GetBytes($authorizationText))


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $authorizationBase64")
$headers.Add("Content-Type", "application/json")

# Create User
# https://grafana.com/docs/grafana/latest/http_api/admin/#global-users
$url = "$urlGrafana/api/admin/users"
$body = @"
{
    "name":"$grafanaUser",
    "email":"$grafanaUser@localhost",
    "login":"$grafanaUser",
    "password":"$grafanaUserPassword",
    "OrgId": 1
}
"@

$response = Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers $headers
$grafanaUserId = $response.id

# Change User Role
# https://grafana.com/docs/grafana/latest/http_api/org/#update-users-in-organization
$url = "$urlGrafana/api/org/users/$grafanaUserId"
$body = @"
{
    "role": "Editor"
}
"@

$response = Invoke-RestMethod -Uri $url -Method PATCH -Body $body -Headers $headers

# Create Data source
# https://grafana.com/docs/grafana/latest/http_api/data_source/#create-a-data-source
$url = "$urlGrafana/api/org/users/$grafanaUserId"
$body = @"
{
  "name":"InfluxDB_netflow",
  "type":"influxdb",
  "url":"http://influxdb:8086",
  "access":"Server",
  "basicAuth":true,
  "basicAuthUser":"netflow",
  "secureJsonData": {
    "basicAuthPassword": "grafana-NetFlowUser-Password",
    "token": "$influxdbTokenGrafana"
  },
  "jsonData": {
    "version": "Flux",
    "organization": "myorg",
    "defaultBucket": "netflow"
  }
}
"@

$response = Invoke-RestMethod -Uri $url -Method POST -Body $body -Headers $headers