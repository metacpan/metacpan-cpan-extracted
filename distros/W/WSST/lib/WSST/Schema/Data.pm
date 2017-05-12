package WSST::Schema::Data;

use strict;
use base qw(WSST::Schema::Base);
__PACKAGE__->mk_accessors(qw(company_name service_name version title abstract
                             license author see_also copyright methods));

use WSST::Schema::Method;

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if ($self->{methods}) {
        foreach my $method (@{$self->{methods}}) {
            $method = WSST::Schema::Method->new($method);
        }
    }
    return $self;
}

sub meta_spec {
    my $self = shift;
    $self->{'meta-spec'} = $_[0] if scalar(@_);
    return $self->{'meta-spec'};
}

=head1 NAME

WSST::Schema::Data - Schema::Data class of WSST

=head1 DESCRIPTION

This class represents the top-level elements of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 company_name

Accessor for the company name.

=head2 service_name

Accessor for the service name.

=head2 version

Accessor for the version.

=head2 title

Accessor for the title.

=head2 abstract

Accessor for the abstract.

=head2 license

Accessor for the license.

=head2 author

Accessor for the author.

=head2 see_also

Accessor for the see_also.

=head2 copyright

Accessor for the copyright.

=head2 methods

Accessor for the methods.

=head2 meta_spec

Accessor for the meta-spec.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
