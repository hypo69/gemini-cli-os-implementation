@{
    RootModule        = 'Gemini.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '8c8b5d9e-f21d-4c42-bb34-9d9f33b9a11d'
    Author            = 'hypo69'
    CompanyName       = 'OpenSource'
    PowerShellVersion = '5.1'
    Description       = 'PowerShell wrapper for Google Gemini CLI'
    FunctionsToExport = @('Invoke-Gemini','New-GeminiSession','Set-GeminiSystemPrompt')
}
