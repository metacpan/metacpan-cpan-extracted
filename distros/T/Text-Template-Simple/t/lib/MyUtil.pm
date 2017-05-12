package MyUtil;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.10';
our @EXPORT  = qw( _p );

sub _p { ## no critic (ProhibitUnusedPrivateSubroutines)
    my @args = @_;
    return if print @args;
    warn "@args\n";
    return;
}

1;

__END__
