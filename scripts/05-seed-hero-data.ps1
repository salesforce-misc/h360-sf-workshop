<#
  05-seed-hero-data.ps1 — PowerShell port of 05-seed-hero-data.sh for Windows
  users who don't have Git Bash / WSL.

  Seeds the 5 hero Order__c records (OR-1001..OR-1005) the demo/agent depends on.
  The metadata deploy (02) creates the Order__c object but NOT its data; without
  these rows the agent answers "No order matches OR-1003".

  Idempotent: upserts on the Order_Number__c external id, so re-running is safe.
  Requires the Headless360_Workshop_Access permset assigned to the running user
  (Order__c field FLS comes from the permset), so run AFTER assigning the permset.

  Usage:  .\scripts\05-seed-hero-data.ps1 -Org <alias>
#>
param(
  [Parameter(Mandatory = $true)][string]$Org
)
$ErrorActionPreference = 'Stop'

$apex = @'
List<Order__c> os = new List<Order__c>{
  new Order__c(Name='Order OR-1001', Order_Number__c='OR-1001', Status__c='Shipped',
    Owner_Name__c='Jordan Rivera', Status_Summary__c='Order OR-1001 shipped.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1002', Order_Number__c='OR-1002', Status__c='Processing',
    Owner_Name__c='Priya Shah', Status_Summary__c='Order OR-1002 is being processed.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1003', Order_Number__c='OR-1003', Status__c='Exception',
    Owner_Name__c='Initech', Status_Summary__c='Order OR-1003 hit a carrier exception - address needs confirmation.',
    Next_Action__c='Approve rebooking'),
  new Order__c(Name='Order OR-1004', Order_Number__c='OR-1004', Status__c='Delivered',
    Owner_Name__c='Sam Nguyen', Status_Summary__c='Order OR-1004 was delivered.', Next_Action__c='None'),
  new Order__c(Name='Order OR-1005', Order_Number__c='OR-1005', Status__c='Processing',
    Owner_Name__c='Alex Kim', Status_Summary__c='Order OR-1005 is being processed.', Next_Action__c='None')
};
upsert os Order_Number__c;
System.debug('Seeded/updated ' + os.size() + ' hero orders');
'@

$apexFile = New-TemporaryFile
try {
  Set-Content -Path $apexFile -Value $apex -Encoding utf8
  sf apex run --file $apexFile --target-org $Org | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Error "seed apex failed - is the permset assigned? assign Headless360_Workshop_Access first."
    exit 1
  }
}
finally {
  Remove-Item $apexFile -ErrorAction SilentlyContinue
}

$json = sf data query --target-org $Org `
  --query "SELECT Order_Number__c FROM Order__c WHERE Order_Number__c LIKE 'OR-100%'" --json | Out-String
$rows = ([regex]::Matches($json, '"Order_Number__c"')).Count
if ($rows -ge 5) {
  Write-Host "PASS: hero data seeded ($rows Order__c rows, incl. OR-1003 exception)"
}
else {
  Write-Error "expected 5 hero orders, found $rows after seed"
  exit 1
}
