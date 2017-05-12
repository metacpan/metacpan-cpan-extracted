" Vim syntax file
" Language:	Perl Embeded Templates (PET)
" Maintainer:	William Tan <wil@dready.org>
" URL:		http://pee.sourceforge.net/
" Last Change:	2000 June 26

" Remove old syntax
syn clear

if !exists("main_syntax")
  let main_syntax = 'pee'
endif

so <sfile>:p:h/html.vim

" syntax items are case-sensitive
syn case match

" include Perl syntax
syn include @peePerl <sfile>:p:h/perl.vim

syn region petScript	matchgroup=petTag start=/<?/ keepend end=/?>/ contains=@peePerl
syn region petExp	matchgroup=petTag start=/<?=/ keepend end=/?>/ contains=@peePerl
syn region petDirective	matchgroup=petTag start=/<?!/ keepend end=/?>/ contains=@peePerl
syn region petComment start=/<?--/ end=/?>/

syn keyword petDirName contained include sinclude


if !exists("pet_init_done")
  let pet_init_done = 1
  hi link htmlComment Comment
  hi link htmlCommentPart Comment
  hi link petComment htmlComment
  hi link petTag htmlTag
  hi link petDirective petTag
  hi link petDirName htmlTagName
endif


let b:current_syntax = "pet"

if main_syntax == 'pet'
  unlet main_syntax
endif
