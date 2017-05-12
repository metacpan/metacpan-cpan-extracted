package Test::Requires::Scanner::CLI;
use strict;
use warnings;
use utf8;

use Test::Requires::Scanner;

use File::Zglob;

sub run {
    my @argv = @_;

    my @files = zglob('{t,xt}/**/*.t');
    my $result = Test::Requires::Scanner->scan_files(@files);
    print "$_\n" for sort keys %$result;
}

1;
