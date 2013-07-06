# Vapor test suite script

param(
    [Parameter(Mandatory = $false)]
    [int] $id = -1
)

[int] $Global:tested = 0
[int] $Global:passed = 0

function RunTest
{
    param(
        [Parameter(Mandatory = $true)]
        [String] $file,
        [Parameter(Mandatory = $false)]
        [String] $in,
        [Parameter(Mandatory = $false)]
        [String] $out
    )
    $t = " `n"
    & ..\Aqua.exe Vapor ..\Vapor_stage1.aqua - $Global:core "$file" "aqua_${file}"
    & ..\Assembler "aqua_${file}" "$file.aqua"
    $o = ($in.Trim($t)) | & ..\Aqua Test "$file.aqua"
    Remove-Item "aqua_${file}"
    Remove-Item "$file.aqua"
    $o = [String]::Join("`n", $o)

    $Global:tested++;
    if ($o.Trim($t) -eq $out.Trim($t))
    {
        $Global:passed++;
        Write-Host "Passed" -ForegroundColor Green
    }
    else
    {
        Write-Host "Failed" -ForegroundColor Red
    }
}

function TestOneCase
{
    param(
        [Parameter(Mandatory = $true)]
        [Object] $case
    )

    if ($case.GetType.Name -eq [System.IO.FileInfo].GetType.Name)
    {
        $text = [String]::Join("`n", (Get-Content $case))
        $text = $text -Replace '(?s)/\*(.*?)\*/.*', '$1'
        $last = ""
        $lines = $text -Split '\n'
        $current = ''
        $tests = @()
        foreach ($line in $lines)
        {
            $line = $line.Trim(' ')
            if ($line -eq '- input')
            {
                if ($last -eq "input" -or $last -eq "output")
                {
                    $tests += $current
                }
                $current = ""
                $last = "input"
            }
            elseif ($line -eq '- output')
            {
                if ($last -eq "")
                {
                    $tests += ""
                }
                elseif ($last -eq "output")
                {
                    $tests += ""
                    $tests += $current
                }
                elseif ($last -eq "input")
                {
                    $tests += $current
                }
                $current = ""
                $last = "output"
            }
            else
            {
                $current = $current + $line + "`n"
            }
        }
        $tests += $current

        $filename = ([System.IO.FileInfo] $case).Name
        Write-Host "Testing $filename..."
        for ($i = 0; $i -lt $tests.Count; $i += 2)
        {
            Write-Host ("  #{0:D}: " -f ($i / 2 + 1)) -NoNewline
            RunTest $filename $tests[$i] $tests[$i + 1]
        }
    }
    elseif ($case.GetType.Name -eq [System.IO.Directory].GetType.Name)
    {
    }
}

Push-Location
Set-Location $PSScriptRoot

$Global:core = New-Object System.Collections.Generic.List[System.String]

$list = Get-ChildItem "..\Aqua\Core" -Filter "*.txt" -Recurse

foreach ($file in $list)
{
    $Global:core.Add($file.FullName)
}

if ($id -eq -1)
{
    $testcases = Get-ChildItem -Filter "*.txt"
    foreach ($case in $testcases)
    {
        TestOneCase($case)
    }
    Write-Host ("Summary: {0:D} / {1:D} tests passed." -f $Global:passed, $Global:tested)
}
else
{
    $case = Get-ChildItem ("{0:D4}.txt" -f $id)
    TestOneCase($case)
}

Pop-Location
