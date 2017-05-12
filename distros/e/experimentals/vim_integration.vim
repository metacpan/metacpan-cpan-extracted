" The following mapping may be of use in streamlining the use of
"
"   use experimentals -report
"
" in Vim...

nnoremap er :call Experimental_Report()<CR>

function! Experimental_Report ()
    " Insert the necessary test code...
    normal 1GOuse experimentals -report;

    " Temporarily replace the :make program...
    setlocal makeprg=perl\ % errorformat=%f\ line\ %l:%m

    " Find issues...
    make

    " Restore the previous state...
    set makeprg< errorformat<
    normal 1Gdd``

    " Jump to first issue...
    redraw
    cc
endfunction
