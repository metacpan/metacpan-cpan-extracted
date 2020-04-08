let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
inoremap <silent> <F5> :silent call Run(&ft)
inoremap <silent> <C-Tab> =UltiSnips#ListSnippets()
imap <F2> 
snoremap <silent>  c
nmap  gT
xnoremap 	 :call UltiSnips#SaveLastVisualSelection()gvs
snoremap <silent> 	 :call UltiSnips#ExpandSnippet()
nmap <NL> j
nmap  k
nmap  gt
nnoremap ] ]T
nmap <silent>  <Plug>SearchPartyHighlightToggle
nmap   
vmap <silent> # <Plug>SearchPartyVisualFindPrev
vmap & <Plug>SearchPartyVisualSubstitute
vmap <silent> * <Plug>SearchPartyVisualFindNext
vmap <silent> K <Plug>(ref-keyword)
nmap K k
nmap Q gq
nmap T :tabnew
vmap [% [%m'gv``
nmap <silent> \cv <Plug>VCSVimDiff
nmap <silent> \cu <Plug>VCSUpdate
nmap <silent> \cU <Plug>VCSUnlock
nmap <silent> \cs <Plug>VCSStatus
nmap <silent> \cr <Plug>VCSReview
nmap <silent> \cq <Plug>VCSRevert
nmap <silent> \cn <Plug>VCSAnnotate
nmap <silent> \cN <Plug>VCSSplitAnnotate
nmap <silent> \cl <Plug>VCSLog
nmap <silent> \cL <Plug>VCSLock
nmap <silent> \ci <Plug>VCSInfo
nmap <silent> \cg <Plug>VCSGotoOriginal
nmap <silent> \cG <Plug>VCSClearAndGotoOriginal
nmap <silent> \cd <Plug>VCSDiff
nmap <silent> \cD <Plug>VCSDelete
nmap <silent> \cc <Plug>VCSCommit
nmap <silent> \ca <Plug>VCSAdd
map \## :execute Octothorpe_add()
map \*# :execute Octothorpe_add()
map \** :execute Star_add()
nmap \mF <Plug>MashFOWDisable
nmap \mf <Plug>MashFOWEnable
nmap <silent> \g* <Plug>SearchPartyHighlightWORD
nmap <silent> \* <Plug>SearchPartyHighlightWord
nmap \mm <Plug>SearchPartySetMatch
nmap <silent> \ms <Plug>SearchPartySetSearch
nmap <silent> \/ <Plug>SearchPartyFindLiteral
nmap \sc <Plug>SearchPartyHighlightClear
nmap \pt :%! perltidy
vmap \pt :!perltidy
nmap \K yiw :exe '!perldoc -f ' @0
nmap \" :tabe "
nmap \f gf
nmap \u 0/httpyE:noh
nmap \g yiw :exe 'grep! -ir --exclude-dir=\.svn -I ' @0 '*'
nmap \p :call PerlX()
nmap \v :tabe ~/.vimrc
vmap ]% ]%m'gv``
vmap a% [%v]%
vmap gx <Plug>NetrwBrowseXVis
nmap gx <Plug>NetrwBrowseX
nmap yaf zcyyzo
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())
nnoremap <silent> <F5> :silent call Run(&ft)
vnoremap <silent> <Plug>(ref-keyword) :call ref#K('visual')
nnoremap <silent> <Plug>(ref-keyword) :call ref#K('normal')
nnoremap <silent> <Plug>VCSVimDiff :VCSVimDiff
nnoremap <silent> <Plug>VCSUpdate :VCSUpdate
nnoremap <silent> <Plug>VCSUnlock :VCSUnlock
nnoremap <silent> <Plug>VCSStatus :VCSStatus
nnoremap <silent> <Plug>VCSSplitAnnotate :VCSAnnotate!
nnoremap <silent> <Plug>VCSReview :VCSReview
nnoremap <silent> <Plug>VCSRevert :VCSRevert
nnoremap <silent> <Plug>VCSLog :VCSLog
nnoremap <silent> <Plug>VCSLock :VCSLock
nnoremap <silent> <Plug>VCSInfo :VCSInfo
nnoremap <silent> <Plug>VCSClearAndGotoOriginal :VCSGotoOriginal!
nnoremap <silent> <Plug>VCSGotoOriginal :VCSGotoOriginal
nnoremap <silent> <Plug>VCSDiff :VCSDiff
nnoremap <silent> <Plug>VCSDelete :VCSDelete
nnoremap <silent> <Plug>VCSCommit :VCSCommit
nnoremap <silent> <Plug>VCSAnnotate :VCSAnnotate
nnoremap <silent> <Plug>VCSAdd :VCSAdd
snoremap <silent> <Del> c
snoremap <silent> <BS> c
snoremap <silent> <C-Tab> :call UltiSnips#ListSnippets()
nmap <silent> <F12> <Plug>ToggleProject
vnoremap <silent> <Plug>(calendar) :Calendar
nnoremap <silent> <Plug>(calendar) :Calendar
nnoremap <Plug>SearchPartyHighlightWORD :let @/=expand('<cWORD>')|set hlsearch
nnoremap <Plug>SearchPartyHighlightWord :let @/='\<'.expand('<cword>').'\>'|set hlsearchviwo
nnoremap <Plug>SearchPartyHighlightToggle :set invhlsearch hlsearch?
vnoremap <Plug>SearchPartyVisualSubstitute "*y:%s/=substitute(escape(@*, '\/.*$^~[]'), "\n", '\\n', "g")/
vnoremap <Plug>SearchPartyVisualFindPrev "*y?=substitute(escape(@*, '\/.*$^~[]'), "\n", '\\n', "g")
vnoremap <Plug>SearchPartyVisualFindNext "*y/=substitute(escape(@*, '\/.*$^~[]'), "\n", '\\n', "g")
nnoremap <Plug>SearchPartySetSearch :let @/=input("set search: ")|set hlsearch
nmap <C-Down> +
nmap <C-Up> -
nmap <C-Left> <C-lt>
nmap <C-Right> <C->>
nmap <C-F12> :tabnew<F12> 
nmap <F4> ]
nmap <F3> nzz
nmap <F2> @q
inoremap  I
inoremap  A
inoremap  
inoremap <silent> 	 =UltiSnips#ExpandSnippet()
imap jj 
cabbr phpx call Run('php')
cabbr rubyx call Run('ruby')
cabbr perlx call Run('perl')
cabbr pyx call Run('python')
cabbr shx call Run('bash')
cabbr sx call Run(&ft)
cabbr syntoggle SyntasticToggleMode
cabbr COL1 s/\v(\S+).*/\1/|noh
cabbr sqltx sudo -u postgres psql crowdtilt -x
cabbr sqlt sudo -u postgres psql crowdtilt
cabbr findunicode [^\x00-\x7f]
cabbr HH %:h
cabbr textmode nmap j gj|nmap k gk
cabbr uncommentxml perldo s/<!--(.*)-->\s*$/$1/g
cabbr commentxml perldo $_ = "<!--$_-->"
cabbr synsync syntax sync fromstart
cabbr synhtml set syntax=html
cabbr synpl set syntax=perl
cabbr synperl set syntax=perl
cabbr synjs set syntax=javascript
cabbr synsql set syntax=sql
cabbr sovimrc source ~/.vimrc
cabbr TT tab split|tabN|pop|tabn
cabbr setfold2 set fdm=indent|set fdn=2
cabbr foldj /{j0zf]}0zz:nohlsearch
cabbr rzz r ~/zz
cabbr ryy r ~/yy
cabbr rxx r ~/xx
cabbr newzz new ~/zz
cabbr newyy new ~/yy
cabbr newxx new ~/xx
cabbr ZZ w! ~/zz
cabbr YY w! ~/yy
cabbr XX w! ~/xx
cabbr tabmake tabnew|make
cabbr Make make
iabbr unicamel 🐪
iabbr unitiltman ⋱ o⋰
iabbr unibacktilt ⋱
iabbr unitilt ⋰
iabbr persianyo وي
iabbr ringring ☎
iabbr hadoken ↓↘→ + ⓟ
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set backspace=indent,eol,start
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set fileformats=unix
set guicursor=n-v-c:block,o:hor50,i-ci:hor15,r-cr:hor30,sm:block,n-v-c:blinkon0
set helplang=en
set history=500
set hlsearch
set ignorecase
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set keywordprg=ref
set laststatus=2
set modelines=0
set nrformats=hex
set path=.,/usr/include,,,lib
set ruler
set runtimepath=~/.vim,~/.vim/bundle/SearchParty,~/.vim/bundle/ack.vim,~/.vim/bundle/add-to-word-search.vim,~/.vim/bundle/bufexplorer,~/.vim/bundle/calendar.vim,~/.vim/bundle/project.tar.gz,~/.vim/bundle/syntastic,~/.vim/bundle/ultisnips,~/.vim/bundle/vcscommand.vim,~/.vim/bundle/vim-fugitive,~/.vim/bundle/vim-go,~/.vim/bundle/vim-matchit,~/.vim/bundle/vim-perl-variable-highlighter,~/.vim/bundle/vim-ref,~/.vim/bundle/vim-script-runner,~/.vim/bundle/vim-snippets,/usr/share/vim/vimfiles,/usr/share/vim/vim81,/usr/share/vim/vimfiles/after,~/.vim/bundle/ultisnips/after,~/.vim/after
set shiftwidth=4
set showcmd
set showtabline=2
set softtabstop=4
set tabstop=4
set tags=tags;
set visualbell
set window=0
set nowrapscan
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/projects/WebService-Client
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
argglobal
%argdel
$argadd lib/WebService/Client.pm
tabnew
tabnew
tabnew
tabrewind
edit lib/WebService/Client.pm
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal autoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=+1
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=PerlFold(v:lnum)
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=expr
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=crqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,lib,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0,~/.plenv/versions/5.30.0/lib/perl5/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/5.30.0
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tagfunc=
setlocal tags=~/projects/WebService-Client/.git/perl.tags,~/projects/WebService-Client/.git/tags,tags;
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
86
normal! zo
150
normal! zo
let s:l = 165 - ((154 * winheight(0) + 26) / 53)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
165
normal! 016|
tabnext
edit foo.pl
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal autoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=+1
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=crqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,lib,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0,~/.plenv/versions/5.30.0/lib/perl5/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/5.30.0
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tagfunc=
setlocal tags=~/projects/WebService-Client/.git/perl.tags,~/projects/WebService-Client/.git/tags,tags;
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 17 - ((16 * winheight(0) + 26) / 53)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
17
normal! 0
tabnext
edit stocks.pl
set splitbelow splitright
wincmd _ | wincmd |
split
1wincmd k
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe '1resize ' . ((&lines * 40 + 28) / 56)
exe '2resize ' . ((&lines * 12 + 28) / 56)
argglobal
setlocal autoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=+1
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=crqol
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(substitute(v:fname,'::','/','g'),'->*','',''),'$','.pm','')
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,lib,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/site_perl/5.30.0,~/.plenv/versions/5.30.0/lib/perl5/5.30.0/darwin-2level,~/.plenv/versions/5.30.0/lib/perl5/5.30.0
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tagfunc=
setlocal tags=~/projects/WebService-Client/.git/perl.tags,~/projects/WebService-Client/.git/tags,tags;
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=80
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 1 - ((0 * winheight(0) + 20) / 40)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
1
normal! 0
wincmd w
argglobal
enew
map <buffer> <silent> q :quit
setlocal autoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=hide
setlocal nobuflisted
setlocal buftype=nofile
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'runner'
setlocal filetype=runner
endif
setlocal fixendofline
setlocal foldcolumn=1
setlocal nofoldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal nomodifiable
setlocal nrformats=hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal readonly
setlocal norelativenumber
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'runner'
setlocal syntax=runner
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tagfunc=
setlocal tags=
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal nowrap
setlocal wrapmargin=0
wincmd w
exe '1resize ' . ((&lines * 40 + 28) / 56)
exe '2resize ' . ((&lines * 12 + 28) / 56)
tabnext
edit ~/bin/stocks.rb
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
let s:cpo_save=&cpo
set cpo&vim
cmap <buffer>  <Plug><cfile>
let &cpo=s:cpo_save
unlet s:cpo_save
setlocal autoindent
setlocal backupcopy=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=^\\s*\\<\\(load\\>\\|require\\>\\|autoload\\s*:\\=[\"']\\=\\h\\w*[\"']\\=,\\)
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=.,/usr/include,,,lib,/Library/Ruby/Site/2.6.0,/Library/Ruby/Site/2.6.0/x86_64-darwin19,/Library/Ruby/Site/2.6.0/universal-darwin19,/Library/Ruby/Site,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0/x86_64-darwin19,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0/universal-darwin19,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/x86_64-darwin19,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/universal-darwin19
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=2
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tagcase=
setlocal tagfunc=
setlocal tags=tags;,/Library/Ruby/Site/2.6.0/tags,/Library/Ruby/Site/2.6.0/x86_64-darwin19/tags,/Library/Ruby/Site/2.6.0/universal-darwin19/tags,/Library/Ruby/Site/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0/x86_64-darwin19/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/2.6.0/universal-darwin19/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/vendor_ruby/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/x86_64-darwin19/tags,/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/universal-darwin19/tags
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 28 - ((27 * winheight(0) + 26) / 53)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
28
normal! 0
tabnext 1
badd +0 lib/WebService/Client.pm
badd +0 foo.pl
badd +0 stocks.pl
badd +0 ~/bin/stocks.rb
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOS
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
