package File::Spec::Epoc;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '3.30';
$VERSION = eval $VERSION;

require File::Spec::Unix;
@ISA = qw(File::Spec::Unix);

sub case_tolerant {
    return 1;
}

sub canonpath {
    my ($self,$path) = @_;
    return unless defined $path;

    $path =~ s|/+|/|g;                             # xx////xx  -> xx/xx
    $path =~ s|(/\.)+/|/|g;                        # xx/././xx -> xx/xx
    $path =~ s|^(\./)+||s unless $path eq "./";    # ./xx      -> xx
    $path =~ s|^/(\.\./)+|/|s;                     # /../../xx -> xx
    $path =~  s|/\Z(?!\n)|| unless $path eq "/";          # xx/       -> xx
    return $path;
}

1;
