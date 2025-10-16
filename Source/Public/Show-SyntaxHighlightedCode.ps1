function Show-SyntaxHighlightedCode {
    <#
    .SYNOPSIS
        Displays PowerShell code with syntax highlighting in the console
    .DESCRIPTION
        Takes PowerShell code and displays it with color-coded syntax highlighting
        for keywords, cmdlets, strings, comments, variables, and operators
    .PARAMETER Code
        The PowerShell code to display with syntax highlighting
    .EXAMPLE
        Show-SyntaxHighlightedCode -Code "Get-Process | Where-Object {$_.CPU -gt 10}"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Code
    )
    
    # Define PowerShell syntax patterns and their colors
    $patterns = @(
        # Comments (must be first to avoid conflicts)
        @{ Pattern = '#.*$'; Color = 'DarkGray'; Name = 'Comment' }
        
        # Strings (double quotes)
        @{ Pattern = '"[^"]*"'; Color = 'DarkYellow'; Name = 'String' }
        
        # Strings (single quotes)
        @{ Pattern = "'[^']*'"; Color = 'DarkYellow'; Name = 'String' }
        
        # PowerShell Keywords
        @{ Pattern = '\b(if|else|elseif|switch|foreach|for|while|do|until|break|continue|return|function|param|begin|process|end|try|catch|finally|throw|trap|filter|in|exit)\b'; Color = 'Magenta'; Name = 'Keyword' }
        
        # PowerShell Operators
        @{ Pattern = '\b(-eq|-ne|-gt|-lt|-ge|-le|-like|-notlike|-match|-notmatch|-contains|-notcontains|-in|-notin|-replace|-and|-or|-not|-xor|-band|-bor|-bnot|-bxor|-f)\b'; Color = 'DarkCyan'; Name = 'Operator' }
        
        # Cmdlets (capitalized words with hyphen)
        @{ Pattern = '\b[A-Z][a-z]+(-[A-Z][a-z]+)+\b'; Color = 'Yellow'; Name = 'Cmdlet' }
        
        # Variables
        @{ Pattern = '\$\w+'; Color = 'Green'; Name = 'Variable' }
        
        # Numbers
        @{ Pattern = '\b\d+(\.\d+)?\b'; Color = 'Cyan'; Name = 'Number' }
        
        # Operators and special characters
        @{ Pattern = '[{}()\[\]|&;,<>=+\-*/!]'; Color = 'White'; Name = 'Punctuation' }
    )
    
    # Split code into lines for processing
    $lines = $Code -split "`r`n|`n"
    
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            Write-Host ""
            continue
        }
        
        # Track which characters have been colored
        $coloredPositions = @{}
        $segments = @()
        
        # Process each pattern
        foreach ($patternInfo in $patterns) {
            $matches = [regex]::Matches($line, $patternInfo.Pattern)
            
            foreach ($match in $matches) {
                # Check if this position is already colored
                $alreadyColored = $false
                for ($i = $match.Index; $i -lt ($match.Index + $match.Length); $i++) {
                    if ($coloredPositions.ContainsKey($i)) {
                        $alreadyColored = $true
                        break
                    }
                }
                
                if (-not $alreadyColored) {
                    # Mark these positions as colored
                    for ($i = $match.Index; $i -lt ($match.Index + $match.Length); $i++) {
                        $coloredPositions[$i] = $true
                    }
                    
                    # Add segment
                    $segments += @{
                        Index = $match.Index
                        Length = $match.Length
                        Text = $match.Value
                        Color = $patternInfo.Color
                    }
                }
            }
        }
        
        # Sort segments by index
        $segments = $segments | Sort-Object -Property Index
        
        # Fill in uncolored segments
        $currentIndex = 0
        $finalSegments = @()
        
        foreach ($segment in $segments) {
            # Add any text before this segment
            if ($segment.Index -gt $currentIndex) {
                $finalSegments += @{
                    Text = $line.Substring($currentIndex, $segment.Index - $currentIndex)
                    Color = 'Gray'
                }
            }
            
            # Add the colored segment
            $finalSegments += $segment
            $currentIndex = $segment.Index + $segment.Length
        }
        
        # Add any remaining text
        if ($currentIndex -lt $line.Length) {
            $finalSegments += @{
                Text = $line.Substring($currentIndex)
                Color = 'Gray'
            }
        }
        
        # Display the line with colors
        foreach ($segment in $finalSegments) {
            Write-Host $segment.Text -NoNewline -ForegroundColor $segment.Color
        }
        Write-Host "" # New line
    }
}
