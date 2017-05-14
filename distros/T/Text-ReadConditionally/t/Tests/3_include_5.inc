.# Included by 3_include_1.input
.echo Included: _LineNumber = \v{_LineNumber}
.echo Included: _FileName = \v{_FileName}
.echo Included: _IncludeDepth = \v{_IncludeDepth}
.# But NOT local thang, so the value set here is not local
.local thing
.let thing := 'from inc 2'; thang := 'thang from inc 2'
.echo In 3_include_5.inc thing='\v{thing}' thang='\v{thang}'
.#
.# Show _ARGS that we find here:
.let na := count(_ARGS) ; a0 := na > 0 ? _ARGS[0] : 'undefined'
.echo 3_include_5.inc: _ARGS[0] = '\v{a0}' number of args \v{na}
.#
.# This will show a different _ARGS
.include 3_include_5.1_inc a1 a2 a3
.# but our version is restored when the include has been processed:
.let na := count(_ARGS) ; a0 := na > 0 ? _ARGS[0] : 'undefined'
.echo Back into 3_include_5.inc: thing='\v{thing}' thang='\v{thang}' na = \v{na} a0='\v{a0}'
