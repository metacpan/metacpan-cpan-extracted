let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
vmap  <Plug>SchleppDupLeft
vmap <silent> + :call EQAS_Align('vmap', {'cursor':1} )
nmap <silent> ++ :call EQAS_Align('nmap', {'cursor':1, 'paragraph':1} )
nmap <silent> + :call EQAS_Align('nmap', {'cursor':1} )
nnoremap ,S :mksession!
nnoremap ,s :mksession
nnoremap ,  :nohlsearch 
nnoremap ,<l> :set nonumber set norelativenumber
vmap <silent> = :call EQAS_Align('vmap')
nmap <silent> == :call EQAS_Align('nmap', {'paragraph':1} )
nmap <silent> = :call EQAS_Align('nmap')
vmap D <Plug>SchleppDupLeft
vmap gx <Plug>NetrwBrowseXVis
nmap gx <Plug>NetrwBrowseX
nnoremap gr gT
nnoremap j gj
nnoremap k gk
nnoremap <Right> <Nop>
nnoremap <Left> <Nop>
nnoremap <Down> <Nop>
nnoremap <Up> <Nop>
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())
vmap <Right> <Plug>SchleppRight
vmap <Left> <Plug>SchleppLeft
vmap <Down> <Plug>SchleppDown
vmap <Up> <Plug>SchleppUp
onoremap <Right> <Nop>
onoremap <Left> <Nop>
onoremap <Down> <Nop>
onoremap <Up> <Nop>
let &cpo=s:cpo_save
unlet s:cpo_save
set background=dark
set backspace=indent,eol,start
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set foldlevelstart=10
set helplang=en
set hlsearch
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set iskeyword=@,48-57,_,192-255,$,%,@-@,:
set lazyredraw
set nomodeline
set mouse=a
set pastetoggle=<F2>
set printoptions=paper:a4
set ruler
set runtimepath=~/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim80,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/after
set shiftwidth=4
set shortmess=aoO
set showcmd
set showmatch
set showtabline=2
set softtabstop=4
set splitbelow
set splitright
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabstop=4
set wildmenu
set winwidth=1
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/Documents/Code/Perl/Modules/Transport-AU-PTV
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 lib/Transport/AU/PTV.pm
badd +1 lib/Transport/AU/PTV/Routes.pm
badd +1 lib/Transport/AU/PTV/Route.pm
badd +7 lib/Transport/AU/PTV/Stop.pm
badd +1 lib/Transport/AU/PTV/Stops.pm
badd +8 lib/Transport/AU/PTV/APIRequest.pm
badd +1 lib/Transport/AU/PTV/Collection.pm
badd +1 lib/Transport/AU/PTV/Error.pm
badd +8 lib/Transport/AU/PTV/Departures.pm
badd +1 lib/Transport/AU/PTV/Departure.pm
argglobal
silent! argdel *
edit lib/Transport/AU/PTV.pm
set splitbelow splitright
wincmd t
set winminheight=1 winheight=1 winminwidth=1 winwidth=1
argglobal
nmap <buffer> <silent> * :let @/ = TPV_locate_perl_var()
vmap <buffer> cv :call TPV_rename_perl_var('visual')gv
nmap <buffer> cv :call TPV_rename_perl_var('normal')
nmap <buffer> <silent> gd :let @/ = TPV_locate_perl_var_decl()
nmap <buffer> <silent> tt :let b:track_perl_var_locked = ! b:track_perl_var_locked:call TPV_track_perl_var()
setlocal keymap=
setlocal noarabic
setlocal noautoindent
setlocal backupcopy=
setlocal balloonexpr=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
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
setlocal foldlevel=10
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
set foldnestmax=10
setlocal foldnestmax=10
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
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0],0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,$,%,@-@,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal nomodeline
setlocal modifiable
setlocal nrformats=bin,octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/include,,,~/perl5/lib/perl5,~/perl5/perlbrew/perls/perl-5.29.0/lib/site_perl/5.29.0/x86_64-linux,~/perl5/perlbrew/perls/perl-5.29.0/lib/site_perl/5.29.0,~/perl5/perlbrew/perls/perl-5.29.0/lib/5.29.0/x86_64-linux,~/perl5/perlbrew/perls/perl-5.29.0/lib/5.29.0
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
set relativenumber
setlocal relativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
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
setlocal tags=
setlocal termkey=
setlocal termsize=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 7 - ((6 * winheight(0) + 24) / 49)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
7
normal! 04|
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=1 shortmess=aoO
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
