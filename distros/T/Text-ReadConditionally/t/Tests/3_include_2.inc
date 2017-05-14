.# Included by 3_include_2.input
.echo Included: _LineNumber = \v{_LineNumber}
.echo Included: _FileName = \v{_FileName}
.echo Included: _IncludeDepth = \v{_IncludeDepth}
Include something else
.include 3_include_2.1_inc
Back again
.echo Included: _LineNumber = \v{_LineNumber}
.echo Included: _FileName = \v{_FileName}
.echo Included: _IncludeDepth = \v{_IncludeDepth}
.let allfiles := join(':', _FileNames); allnumbers := join(':', _LineNumbers)
.echo allfiles = \v{allfiles}
.echo allnumbers = \v{allnumbers}
