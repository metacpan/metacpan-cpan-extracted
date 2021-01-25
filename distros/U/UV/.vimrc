autocmd FileType c    setlocal sw=4
autocmd FileType xs   setlocal sw=4
autocmd FileType perl setlocal sw=4

autocmd BufNewFile,BufRead *.xsi setfiletype xs
autocmd BufNewFile,BufRead *.ci  setfiletype c
