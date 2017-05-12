" Vim syntax file
" Language:     XAO::Web Templates
" Maintainer:   Andrew Maltsev <am@xao.com>
" URL:          http://xao.com/
" Last Change:  2002 Feb 8

" Quit when a syntax file was already loaded
"
if exists("b:current_syntax")
  finish
endif

" Based on HTML
"
runtime syntax/html.vim
unlet b:current_syntax

syn cluster htmlPreproc add=xaowebCode,xaowebVariable

syn case match

syn region xaowebCode     matchgroup=xaowebCode start="<%[A-Z][A-Za-z0-9_.:]\+" end="%>" contains=xaowebFlags,xaowebAttrName,xaowebVarName,xaowebValSubst,xaowebValConst
syn match  xaowebAttrName "\(\s\|\_^\)\@<=[a-zA-Z][a-zA-Z0-9_.]*\>" contained display
syn match  xaowebVarName  "\(\s\|\_^\)\@<=[A-Z][A-Z0-9_.]*\>" contained display
syn region xaowebValSubst start=/"/ end=/"/ contains=xaowebCode,xaowebVariable contained
syn region xaowebValSubst start=/{/ end=/}/ contains=xaowebCode,xaowebVariable contained
syn region xaowebValConst start=/'/ end=/'/ contained

syn match  xaowebVariable "<\$[A-Za-z0-9_.]\+\(/[a-z]\+\)\{0,1}\$>" contains=xaowebFlags
syn match  xaowebVariable "<%[A-Z0-9_.]\+\(/[a-z]\+\)\{0,1}%>" contains=xaowebFlags

syn match  xaowebFlags    "\(<[%\$][A-Z][A-Za-z0-9_.:]\+\)\@<=/[a-z]\+" contained

syn match  xaowebError    "%>"
syn match  xaowebError    "\$>"

hi def link xaowebValConst  String
hi def link xaowebValSubst  String

hi xaowebCode      ctermfg=DarkBlue    guifg=DarkBlue      gui=bold
hi xaowebVariable  ctermfg=DarkGreen   guifg=DarkGreen     gui=bold
hi xaowebFlags     ctermfg=DarkCyan    guifg=DarkCyan      gui=bold

hi xaowebAttrName  ctermfg=DarkBlue    guifg=DarkCyan      gui=NONE
hi xaowebVarName   ctermfg=DarkGreen   guifg=DarkGreen     gui=NONE

hi xaowebError     ctermfg=Red         guifg=Red           gui=NONE

let b:current_syntax = "xaoweb"
