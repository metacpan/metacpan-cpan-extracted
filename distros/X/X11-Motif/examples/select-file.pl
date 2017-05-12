#!../xperl -w
#!/ford/thishost/unix/div/ap/bin/perl -w

use strict;
use blib;
use lib qw(.);

use X11::Motif::URLChooser::FTP;

my $toplevel = X::Toolkit::initialize("Example");
my $chooser = new X11::Motif::URLChooser('ftp://pt0204.pto.ford.com');

while (1) {
    my $filename = $chooser->choose();

    print "FILE = $filename\n";

    if (open(FILE, "<$filename")) {
	my $line = <FILE>;
	chomp $line;
	print "the first line of $filename is '$line'\n";
	close(FILE);
    }
}
