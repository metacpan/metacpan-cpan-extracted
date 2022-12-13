use strict;
use warnings;
use feature 'say';
use oo_sub;
use Data::Dumper;
use DDP; # CPAN: Data-Printer

my $user = getpwnam 'root';
print $user -> uid;

my $group = getgrgid 0;
say $group -> name; # use feature 'say';

say my $file = stat( '.' ) -> ino;

printf "%s: %s", getprotobyname( 'tcp' ) -> proto, getservbyname( 'ftp' ) -> port;

say Dumper getnetbyname 'loopback'; # use Data::Dumper;

p my $time = localtime; # use DDP; (ie. Data::Printer)

# Type of arg 1 to Data::Printer::p must be one of [@$%&] (not subroutine entry)
# Alternatively: p ${\getpwnam('root')};
