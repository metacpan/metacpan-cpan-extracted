package WordTest;
#Utility functions for testing Word stuff


sub setup {
    chdirT();
    delDoc();
    print "\n";
}


sub teardown {
    print "\n";
    delDoc();
}


sub delDoc {
    for (aGlobFiles()) {
        unlink($_) or warn("$_: $!\n");
    }
    return( aGlobFiles() ? 0 : 1 );
}


sub chdirT {
    -d "t" and chdir("t");
    -d "../t" or return(0);
    return(1);
}


sub readFile {
    local $/;
    open(my $fh, $_[0]) or return(undef);
    return(<$fh>);
}


sub aGlobFiles {
    return( keys %{ { map { $_ => 1 } map { glob("*.$_") } qw(doc rtf html) } } );
}

1;



__END__
