package WSST::Schema::Base;

use strict;
use base qw(Class::Accessor::Fast);

use constant BOOL_FIELDS => ();

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    foreach my $fld ($class->BOOL_FIELDS) {
        $self->{$fld} = ($self->{$fld} && $self->{$fld} eq "true");
    }
    return $self;
}

=head1 NAME

WSST::Schema::Base - Base class for Schema elements

=head1 DESCRIPTION

This is a base class for schema elements.

=head1 METHODS

=head2 new

Constructor.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
