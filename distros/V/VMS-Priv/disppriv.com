$! .COM file to display privs. We can't just do a 
$! WRITE SYS$OUTPUT F$GETJPI(pid, CURPRIV) or whatever, because it can
$! cause a DCL overflow error on V7.1 if you've got heaps of privs.
$ my_really_local_fooey = f$getjpi("%D''p1'", p2)
$ write/symbol sys$output my_really_local_fooey
