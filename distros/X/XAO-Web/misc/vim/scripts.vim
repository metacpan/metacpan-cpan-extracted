" Vim support for detecting XAO::Web file type

" Only do this when the FileType autocommand has not been triggered yet
"if did_filetype()
"  finish
"endif

" Line continuation is used here, remove 'C' from 'cpoptions'
let s:cpo_save = &cpo
set cpo&vim

" XAO::Web template
if getline(1) =~ '<[%$][A-Z]' ||
 \ getline(2) =~ '<[%$][A-Z]' ||
 \ getline(3) =~ '<[%$][A-Z]' ||
 \ getline(4) =~ '<[%$][A-Z]' ||
 \ getline(5) =~ '<[%$][A-Z]' ||
 \ getline(6) =~ '<[%$][A-Z]' ||
 \ getline(7) =~ '<[%$][A-Z]' ||
 \ getline(8) =~ '<[%$][A-Z]'
  setf xaoweb

endif

" Restore 'cpoptions'
let &cpo = s:cpo_save

unlet s:cpo_save
