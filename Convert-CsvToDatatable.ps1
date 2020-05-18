Param (

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ })]
    [String] $CsvPath,

    [Parameter(Mandatory = $false)]
    [String] $Delimiter = ","

)


$DataTable = New-Object -TypeName Data.DataTable("Data")

$ExportContent = Import-Csv -Path $CsvPath -Delimiter $Delimiter

foreach ($NoteProperty in ($ExportContent | Get-Member -MemberType NoteProperty)) {

    [Void] $DataTable.columns.add($NoteProperty.Name, [String])

}

$Items = ($ExportContent | Measure-Object).Count

$Done = 0

$ExportContent | ForEach-Object {

    $Row = $DataTable.NewRow()

    foreach ($Column in $DataTable.columns) {

        $Row.($Column.ColumnName) = $_.($Column.ColumnName)

    }

    $DataTable.Rows.Add($Row)
    
    $Done++

    $PercentDone = [Math]::Round((($Done / $Items) * 100), 1, [MidpointRounding]::AwayFromZero)

    Write-Progress -Activity ("Building DataTable") -Status "$PercentDone% done:" -PercentComplete $PercentDone;

}

Return $DataTable
