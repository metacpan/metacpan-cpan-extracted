sub usage {
    my $script = shift;
    print <<"END";

 Usage: perl $script [--with-apache2=C:\Path\to\Apache2]
        perl $script --help

Options:

  --with-apache2=C:\Path\to\Apache2 : specify the top-level Apache2 directory
  --help                            : print this help message

With no options specified, an attempt will be made to find a suitable 
Apache2 directory.

END
    exit;
}

require File::Spec;
sub check {
    my $apache = shift;
    die qq{No libhttpd library found under $apache/lib}
        unless -e qq{$apache/lib/libhttpd.lib};
    die qq{No httpd header found under $apache/include}
        unless -e qq{$apache/include/httpd.h};
    for my $b(qw(Apache.exe httpd.exe)) {
        my $binary = File::Spec->catfile($apache, 'bin', $b);
        next unless -x $binary;
        my $vers = qx{$binary -v};
        die qq{"$apache" does not appear to be version 2.x}
            unless $vers =~ m!Apache/2.!;
        last;
    }
    return 1;
}

1;
