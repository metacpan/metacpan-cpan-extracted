package WWW::eNom::Role::ParseDomain;

use strict;
use warnings;

use Moose::Role;
use MooseX::Aliases;

use WWW::eNom::Types qw( Str );

use Mozilla::PublicSuffix;

requires 'name';

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Parse a domain into sld and public_suffix/tld

has 'sld' => (
    is       => 'ro',
    isa      => Str,
    builder  => '_build_sld',
    lazy     => 1,
    init_arg => undef,
);

has 'public_suffix' => (
    is       => 'ro',
    isa      => Str,
    alias    => 'tld',
    builder  => '_build_public_suffix',
    lazy     => 1,
    init_arg => undef,
);

sub _build_sld {
    my $self = shift;

    return substr( $self->name, 0, length( $self->name ) - ( length( $self->public_suffix ) + 1 ) );
}

sub _build_public_suffix {
    my $self = shift;

    return Mozilla::PublicSuffix::public_suffix( $self->name );
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::ParseDomain - Parse a domain into sld and public_suffix/tld

=head1 REQUIRES

=over 4

=item name

=back

=head1 DESCRIPTION

This role is consumed by objects that have a domain name and adds to the consuming object the ability to split that domain into sld and public_suffix/tld.  This is critically important because most of L<eNom|https://www.enom.com>'s API expects the SLD and TLD to be sent as different parameters.

=head1 ATTRIBUTES

=head2 sld

The SLD of the domain.  For google.co.uk this value would be google.

B<NOTE> this is lazy built with an init_arg of undef.

=head2 public_suffix

The public_suffix of the domain (what some folks incorrectly call the TLD).  For domains like google.co.uk the public_suffix is .co.uk.  The public suffix is what is available for someone to actually register.  For additional information between the distinction between Top Level Domain and Public Suffix please see L<https://publicsuffix.org/learn/>

An alias of 'tld' is also provided if you really wish to refer to this as the TLD.

B<NOTE> this is lazy built with an init_arg of undef.

=cut
