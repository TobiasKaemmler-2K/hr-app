param(
  [int]$Port = 5203,
  [switch]$PrintOnly,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$projectRoot = Split-Path -Parent $PSScriptRoot

function Get-ActiveHostIp {
  $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.State -eq 'Alive' } |
    Sort-Object RouteMetric, ifMetric |
    Select-Object -First 1

  if (-not $defaultRoute) {
    return $null
  }

  $ip = Get-NetIPAddress -InterfaceIndex $defaultRoute.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -ne '127.0.0.1' -and
      -not $_.IPAddress.StartsWith('169.254.')
    } |
    Select-Object -First 1 -ExpandProperty IPAddress

  return $ip
}

$ip = Get-ActiveHostIp
if (-not $ip) {
  Write-Error 'Keine aktive IPv4-Adresse gefunden. Prüfe Netzwerkverbindung.'
  exit 1
}

$baseUrl = "http://${ip}:$Port"
Write-Host "Using API_BASE_URL=$baseUrl"

if ($PrintOnly) {
  exit 0
}

Push-Location $projectRoot
try {
  & flutter run "--dart-define=API_BASE_URL=$baseUrl" @FlutterArgs
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
