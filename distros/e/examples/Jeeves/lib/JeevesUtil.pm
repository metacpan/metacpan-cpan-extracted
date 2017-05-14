package JeevesUtil;

sub compare {
    $f1 = $_[0]; $f2 = $_[1];
        if ((-s $f1) != (-s $f2)) {
        return 1;
    }
    open (F1, "$f1") || die "Could not open $f1";
    open (F2, "$f2") || die "Could not open $f2";
    while (sysread(F1, $buf1, 1024)) {
        return 1 if (! sysread(F2, $buf2, 1024)) ;
        return 1 if ($buf1 ne $buf2);
    }
    close (F1); close (F2);
    return 0;
}

1;
