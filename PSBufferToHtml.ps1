<#
 
.SYNOPSIS
This is a Powershell script to dump console buffer as html to file.
 
.DESCRIPTION
This Powershell script will iterate over the current console buffer and
output it as html preserving colors.

.PARAMETER FilePath
Specifies the path to the output file.
.PARAMETER Encoding
Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", default is UTF8
.PARAMETER Last
Specifies the rows to output from the end of the buffer
.PARAMETER SkipLast
Skips last buffer row in output
#>
Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ ![String]::IsNullOrWhiteSpace($_) })]
    [string] $FilePath,

    [ValidateSet("Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode")]
    [string] $Encoding = "UTF8",

    [int] $Last = 0,

    [switch]$SkipLast
)

Function ToHex ([System.ConsoleColor] $color)
{
    switch($color)
    {
        "Black"         { "#000000" }
        "DarkBlue"      { "#012456" }
        "DarkGreen"     { "#005711" }
        "DarkCyan"      { "#007680" }
        "DarkRed"       { "#6F0711" }
        "DarkMagenta"   { "#6F0780" }
        "DarkYellow"    { "#888F11" }
        "Gray"          { "#878E98" }
        "DarkGray"      { "#666D77" }
        "Blue"          { "#0000FF" }
        "Green"         { "#00FF00" }
        "Cyan"          { "#00FFFF" }
        "Red"           { "#FF0000" }
        "Magenta"       { "#FF00FF" }
        "Yellow"        { "#FFFF00" }
        "White"         { "#FFFFFF" }    
        default         { throw "Unknown color: $color" }
    }
}

if ($host.Name -ne "ConsoleHost")
{
    throw "Console host $($host.Name) not supported";
}

$state = @{
    Width                   = $host.ui.rawui.BufferSize.Width
    Height                  = if($SkipLast.IsPresent) { $host.ui.rawui.CursorPosition.Y - 1 } else { $host.ui.rawui.CursorPosition.Y }
    Rect                    = (new-object System.Management.Automation.Host.Rectangle 0,0, ($host.ui.rawui.BufferSize.Width-1), $host.ui.rawui.CursorPosition.Y)
    DefaultBackgroundColor  = [System.ConsoleColor]::DarkMagenta
    DefaultForegroundColor  = [System.ConsoleColor]::White
}

$buffer                 = $host.ui.rawui.GetBufferContents($state.Rect)
$currentForegroundColor = $state.DefaultForegroundColor
$currentBackgroundColor = $state.DefaultBackgroundColor
$outputBuilder          = new-object System.Text.StringBuilder
$inSpan                 = $false;

[void]$outputBuilder.AppendLine("<body>")
[void]$outputBuilder.Append("<pre style=`"display: inline-block;padding:2px;border:2px solid black;font-size:10px;font-family: Consolas, 'Lucida Console', Monaco, monospace;color:$(ToHex([System.ConsoleColor]::White));background-color:$(ToHex([System.ConsoleColor]::DarkBlue))`">")
$firstRow = 0
if($Last -gt 0 -and ($state.Height -$Last) -gt 0)
{
    $firstRow = $state.Height - $Last;
}
for ($row=$firstRow; $row -lt $state.Height; $row++)
{
    for($col = 0; $col -lt $state.Width; $col++)
    {
        $cell = $buffer[$row, $col]
        if ($currentForegroundColor -ne $cell.ForegroundColor -or $currentBackgroundColor -ne $cell.BackgroundColor)
        {
            $currentForegroundColor = $cell.ForegroundColor
            $currentBackgroundColor = $cell.BackgroundColor

            if ($inSpan)
            {
                [void]$outputBuilder.Append("</span>")
                $inSpan = $false
            }

            if (($currentForegroundColor -ne $state.DefaultForegroundColor -and $currentForegroundColor -ne [System.ConsoleColor]::DarkYellow) -or $currentBackgroundColor -ne $state.DefaultBackgroundColor)
            {
                
                [void]$outputBuilder.Append("<span style=`"")

                if ($currentForegroundColor -ne $state.DefaultForegroundColor -and $currentForegroundColor -ne [System.ConsoleColor]::DarkYellow)
                {
                    [void]$outputBuilder.Append("color:$(ToHex($currentForegroundColor))")
                }

                if ($currentBackgroundColor -ne $state.DefaultBackgroundColor)
                {
                    [void]$outputBuilder.Append(";background-color:$(ToHex($currentBackgroundColor))")
                }

                [void]$outputBuilder.Append("`">")
                $inSpan = $true
            }
        }

        switch($cell.Character)
        {
            "<"     { [void]$outputBuilder.Append("&lt;") }
            ">"     { [void]$outputBuilder.Append("&gt;") }
            default { [void]$outputBuilder.Append($cell.Character) }
        }
    }

    for ($index = $outputBuilder.Length-1; $outputBuilder.Length -gt 0 -and [String]::IsNullOrWhiteSpace($outputBuilder[$index]); $index--)
    {
        [void]$outputBuilder.Remove($index, 1);
    }
    
    if ($inSpan)
    {
        [void]$outputBuilder.Append("</span>")
        $inSpan = $false;
    }

    [void]$outputBuilder.AppendLine()
}

[void]$outputBuilder.AppendLine("</pre>")
[void]$outputBuilder.AppendLine("</body>")

$outputBuilder.ToString()|Out-File -FilePath $FilePath -Encoding $Encoding