

[CmdletBinding(DefaultParameterSetName="Path",
               SupportsShouldProcess=$TRUE)]
param(
  [parameter(Mandatory=$TRUE,ParameterSetName="Path",
    Position=2,ValueFromPipeline=$TRUE)]
    [String[]] $Path,
  [parameter(Mandatory=$TRUE,ParameterSetName="LiteralPath",
    Position=2)]
    [String[]] $LiteralPath
)



begin {
 
  function checkpath($path) {
    switch ($PSCmdlet.ParameterSetName) {
      "Path" {
        test-path $path
      }
      "LiteralPath" {
        test-path -literalpath $path
      }
    }
  }

  function getchilds($path) {
    switch ($PSCmdlet.ParameterSetName) {
      "Path" {
        get-childitem $path -force
      }
      "LiteralPath" {
        get-childitem -literalpath $path -force
      }
    }
  }

}

process {

  switch ($PSCmdlet.ParameterSetName) {
    "Path" { $list = $Path }
    "LiteralPath" { $list = $LiteralPath }
  }

  foreach ($item in $list) {
    if (-not (checkpath $item)) {
      write-error "Unable to find '$item'."
      continue
    }

  foreach ($file in getchilds $item) {
      if ($file -isnot [IO.FileInfo]) {
        write-error "'$file' is not in the file system."
        break
      }

  try {
        write-verbose "Reading '$file'."
        $text = [IO.File]::ReadAllText($file.FullName)
        write-verbose "Finished reading '$file'."
      }
   catch [Management.Automation.MethodInvocationException] {
        write-error $ERROR[0]
        continue
      }



   try {
        $texttofind = '<?define BuildVersion[\s]{1,}= "[\d]{1,}'
        $match = [regex]::Match($text,$texttofind).Value
        $texttoreplace = [regex]::Match($match, '[\d]{1,}').Value
        $IntReplacement = (([int]([System.Convert]::ToInt32($texttoreplace))+1).ToString().PadLeft(2, '0'))
        $Intregex = new-object Text.RegularExpressions.Regex $texttoreplace
        $Replacement = $Intregex.Replace($match,$IntReplacement)
        $regex = new-object Text.RegularExpressions.Regex $texttofind
      }
   catch [Management.Automation.MethodInvocationException] {
          write-error $ERROR[0]
          continue
      }
      
   try {
        write-verbose "Writing new version to file."
        [IO.File]::WriteAllText($file, $regex.Replace($text,$Replacement))
        write-verbose "Finished writing to file."
      }
   catch [Management.Automation.MethodInvocationException] {
        write-error $ERROR[0]
      }
    } # foreach $file
  } # foreach $item
} # process

end { }