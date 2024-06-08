param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [String[]]$InputFiles
)

function Convert-VTKtoVRML {
    param(
        [String]$inputFilePath,
        [String]$outputFilePath
    )

    # Read the content of the input file
    $content = Get-Content -Path $inputFilePath

    # Initialize variables for storing points and cell indices
    $points = @()
    $cellIndices = @()

    # Parse the content to extract points and cell indices
    $noOfLines = 0
    foreach ($line in $content) {
        $noOfLines++
        if ($line -match '^POINTS (\d+)') { 
            $numPoints = [int]::Parse($matches[1])
            $points = @()
            $pointStartIndex = $content.IndexOf($line) + 1
            for ($i = $noOfLines; $i -lt $numPoints +$noOfLines; $i++) {
                $pointLine = $content[$i]
                $point = $pointLine
                $points += $point
            }
        }
        elseif ($line -match '^CELLS (\d+) (\d+)') {
            $numCells = [int]::Parse($matches[1])
            $cellIndices = @()
            for ($i = 1; $i -le $numCells; $i++) {
                $cellLine = $content[(($content.IndexOf($line)) + $i)]
                $cell = $cellLine.Trim() -split '\s+'
                $cellIndices += "$($cell -join ', ') $(',')"
            }
        }
    }

    # Write the converted content to the output file
    @"
#VRML V1.0 ascii

Transform {
    children [
        Shape {
            appearance Appearance {
                material Material {
                    diffuseColor 1 0 0
                }
            }
            geometry IndexedFaceSet {
                coord Coordinate {
                    point [
$(($points | ForEach-Object { "                    $_" }) -join ",`n")
                    ]
                }
                coordIndex [
$(($cellIndices | ForEach-Object { "                    $_ -1" }) -join ",`n")
                ]
            }
        }
    ]
}
"@ | Set-Content -Path $outputFilePath
}

# Process each input file
foreach ($file in $InputFiles) {
    $outputFile = $file -replace '\.vtk$', '.wrl'
    Convert-VTKtoVRML -inputFilePath $file -outputFilePath $outputFile
}
