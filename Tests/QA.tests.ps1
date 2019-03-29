Describe 'ARM Templates QA tests' {
  $files = Get-ChildItem Templates -File -Recurse -Filter *.json -Exclude *parameters*, *example* |
    ForEach-Object -Process {
    @{
      File = $_.FullName
      ConvertedJSON = try {
        Get-Content -Path $_.FullName | ConvertFrom-Json -ErrorAction Stop
      } catch {
        $null
      }
    }
  }

  It 'Converts from JSON | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )

    $ConvertedJSON | Should -Not -BeNullOrEmpty
  }

  # remove files which did not convert from json
  $files = $files.Where{$null -ne $_.ConvertedJSON}

  It 'Has the expected properties | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $expected_elements = @(
      '$schema',
      'contentVersion',
      'parameters',
      'variables',
      'resources',
      'outputs'
    )
    $expected_elements | Should -BeIn $ConvertedJSON.psobject.Properties.Name
  }

  It 'Schema URI should use https and latest apiVersion | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $ConvertedJSON.'$schema' | Should -BeExactly 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
  }

  It 'Do parameters use camelCasing | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $ConvertedJSON.parameters.psobject.Properties.Name.ForEach{
      $_ | Should -MatchExactly '^([a-z][0-9]?)+(([A-Z]{1}([a-z]|[0-9]){1}([a-z]|[0-9]?)+)?)+'
    }
  }

  It 'Do parameter types use lower casing | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $ConvertedJSON.parameters.psobject.Properties.value.type.ForEach{
      $_ | Should -MatchExactly '^[a-z]+$'
    }
  }

  It 'Every parameter must have a {"metadata" : {"description":""}} element and value | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $ConvertedJSON.parameters.psobject.Properties.Value | ForEach-Object {
      ($_.metadata.description).count | Should -Be 1
      $_.metadata.description.length | Should -BeGreaterThan 3
    }
  }

  It 'Do variables use camelCasing | <file>' -TestCases $files {
    param(
      $File,
      $ConvertedJSON
    )
    if ($ConvertedJSON.variables.psobject.Properties.Name.Count -gt 0) {
      $ConvertedJSON.variables.psobject.Properties.Name.ForEach{
        $_ | Should -MatchExactly '^([a-z][0-9]?)+(([A-Z]{1}([a-z]|[0-9]){1}([a-z]|[0-9]?)+)?)+'
      }
    }
  }

  It 'Every resource must have a literal apiVersion | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    if ($ConvertedJSON.resources.Count -gt 0) {
      $ConvertedJSON.resources.ForEach{
        $_.apiVersion | Should -MatchExactly "^\d{4}-\d{2}-\d{2}(-preview)?"
      }
    }
  }

  It 'Does not have unused parameters defined | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $rawContent = Get-Content -Path $File -Raw
    $ConvertedJSON.parameters.psobject.Properties.Name.ForEach{
      $rawContent | Should -Match "parameters\('$_'\)" -Because "Unused Parameter '$_'"
    }
  }

  It 'Does not have unused variables defined | <file>' -TestCases $files {
    param (
      $File,
      $ConvertedJSON
    )
    $rawContent = Get-Content -Path $File -Raw
    $ConvertedJSON.variables.psobject.Properties.Name.ForEach{
      # exclude copy variable name
      if ($_ -ne 'copy') {
        $rawContent | Should -Match "variables\('$_'\)" -Because "Unused Variable '$_'"
      }
    }
  }
}
