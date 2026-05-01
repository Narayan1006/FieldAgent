$projectId = "fieldagent-901d6"
$base = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents"

function Set-Doc($col, $id, $fields) {
    $body = @{ fields = $fields } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$base/$col/$id" -Method Patch -Body $body -ContentType "application/json" | Out-Null
    Write-Host "  OK: $col/$id"
}
function S($v) { @{ stringValue = $v } }
function N($v) { @{ integerValue = "$v" } }

$now = (Get-Date -Format "o")
Write-Host "Seeding patients..."

Set-Doc "patients" "p001" @{
    id = S "p001"; name = S "Sunita Devi"; age = N 24
    village = S "Rampura"; anc_number = S "ANC-2024-001"
    lmp_date = S "2024-09-15"; edd = S "2025-06-22"; created_at = S $now
}
Set-Doc "patients" "p002" @{
    id = S "p002"; name = S "Meena Kumari"; age = N 28
    village = S "Sitapur"; anc_number = S "ANC-2024-002"
    lmp_date = S "2024-10-01"; edd = S "2025-07-08"; created_at = S $now
}
Set-Doc "patients" "p003" @{
    id = S "p003"; name = S "Priya Sharma"; age = N 22
    village = S "Govindpur"; anc_number = S "ANC-2024-003"
    lmp_date = S "2024-08-20"; edd = S "2025-05-27"; created_at = S $now
}
Set-Doc "patients" "p004" @{
    id = S "p004"; name = S "Radha Yadav"; age = N 31
    village = S "Rampura"; anc_number = S "ANC-2024-004"
    lmp_date = S "2024-11-10"; edd = S "2025-08-17"; created_at = S $now
}
Set-Doc "patients" "p005" @{
    id = S "p005"; name = S "Anita Patel"; age = N 26
    village = S "Krishnanagar"; anc_number = S "ANC-2024-005"
    lmp_date = S "2024-09-28"; edd = S "2025-07-05"; created_at = S $now
}

Write-Host "Done! 5 patients seeded."
