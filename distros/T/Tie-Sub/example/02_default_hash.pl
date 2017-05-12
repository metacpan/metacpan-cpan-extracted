#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use Tie::Sub;

my %data_hash = (
    a => 'x',
    b => 'y',
    c => 'z',
);

tie my %default_hash, 'Tie::Sub', sub { ## no critic (Ties)
    my $key = shift;

    exists $data_hash{$key}
        and return $data_hash{$key};

    return 'default';
};

() = print <<"EOT";
$default_hash{a}
$default_hash{b}
$default_hash{c}
$default_hash{d}
EOT

# $Id$

__END__

Output:
x
y
z
default
