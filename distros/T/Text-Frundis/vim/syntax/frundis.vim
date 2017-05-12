" VIM syntax file
" Language:	frundis
" Maintainer:	Yon <anaseto@bardinflor.perso.aquilenet.fr>
" Last Change:	2015 Feb 13
"
" inspired from nroff.vim

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

setlocal paragraphs=D\ P\ BdEdBlEl

setlocal sections=PtChShSs

" Traling whitespace
if exists("frundis_space_errors")
	syn match frundisError /\s\+$/
endif

" Macro lines

syn match frundisMacroLine /^[.]/ nextgroup=frundisMacroName,frundisDialogue,frundisStateMacroName,frundisXMacro skipwhite
syn match frundisMacroName /[^\t ]\+/ contained nextgroup=frundisMacroArgs skipwhite
syn match frundisStateMacroName /#[^\t ]\+/ contained nextgroup=frundisMacroArgs skipwhite
syn match frundisXMacro /X\(\s\)\@=/ contained nextgroup=frundisMacroArgs skipwhite
" Dialogs
syn match frundisDialogue /D/ contained nextgroup=frundisMacroArgs skipwhite
syn region frundisMacroArgs start=/\S/ skip=/\\$/ end=/$/ contained keepend contains=frundisMacroArg,frundisMacroOption,frundisComment,frundisDialogue
syn match frundisMacroArg /[^ \t]\+/ contained contains=frundisError,frundisEscape
syn match frundisMacroOption /-[^ \t]\+/ contained contains=frundisEscape
syn region frundisMacroArg matchgroup=FrundisDelim start=/"/ end=/"\|$/ skip=/\\$\|""/ contained contains=frundisEscape,frundisQuoteEscape,frundisError
syn region frundisMacroOption start=/"-/ end=/"\|$/ skip=/\\$\|""/ contained contains=frundisEscape
syn match frundisQuoteEscape /""/ contained

" Escape sequences \$2
			
syn match frundisEscape /\\[$]\d\+/
syn match frundisEscape /\\[e~&]/
syn match frundisEscape /\\$/
syn match frundisEscape /\\\*/ nextgroup=frundisEscIdentifier
syn region frundisEscIdentifier matchgroup=frundisEscape start=/\[/ end=/\]/ contained oneline

" Unsupported escape sequence

syn match frundisError /\\[^e~&$*]/

" Comments

syn match frundisComment /\(^[.']\s*\)\=\\".*/ contains=frundisTodo
syn match frundisComment /^'''.*/  contains=frundisTodo


syn keyword frundisTodo TODO XXX FIXME contained

if version >= 508 || !exists("did_frundis_syn_inits")

	if version < 508
		let did_frundis_syn_inits = 1
		command -nargs=+ HiLink hi link <args>
	else
		command -nargs=+ HiLink hi def link <args>
	endif

	HiLink frundisEscape Preproc
	HiLink frundisQuoteEscape Preproc
	HiLink frundisComment Comment
	HiLink frundisDialogue Todo
	HiLink frundisTodo Todo
	HiLink frundisError ErrorMsg
	HiLink frundisEscIdentifier Identifier

	HiLink frundisMacroLine Statement
	HiLink frundisMacroName Statement
	"HiLink frundisMacroArg Constant
	HiLink frundisMacroOption Type
	HiLink frundisXMacro PreProc
	HiLink frundisStateMacroName PreProc

	delcommand HiLink
endif

let b:current_syntax = "frundis"
