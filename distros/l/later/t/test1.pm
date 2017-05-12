package test1;

use Carp;
use base qw(Exporter);

our @EXPORT = qw(foo);

my $count_imports = 0;

sub import {
    # just to make sure that _autoload is not called multiple times...
    $count_imports++;
    confess "ERROR: ".__PACKAGE__." was used more than once." if ($count_imports > 1);

    __PACKAGE__->export_to_level(1);
}

sub foo { 
    return 'foo'; 
}

1;
