package WWW::LogicBoxes::DomainAvailability;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Aliases;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Bool DomainName Str );

use Mozilla::PublicSuffix;

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: LogicBoxes Domain Availability Response

has name => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has is_available => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has sld => (
    is       => 'ro',
    isa      => Str,
    builder  => '_build_sld',
    lazy     => 1,
    init_arg => undef,
);

has public_suffix => (
    is       => 'ro',
    isa      => Str,
    alias    => 'tld',
    builder  => '_build_public_suffix',
    lazy     => 1,
    init_arg => undef,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _build_sld {
    my $self = shift;

    return substr( $self->name, 0, length( $self->name ) - ( length( $self->public_suffix ) + 1 ) );
}
## use critic

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _build_public_suffix {
    my $self = shift;

    return Mozilla::PublicSuffix::public_suffix( $self->name );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::DomainAvailability

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain_availabilities = $logic_boxes->check_domain_availability(
        slds => [qw( cpan drzigman brainstormincubator ],
        tlds => [qw( com net org )],
        suggestions => 0,
    );

    for my $domain_availability (@{ $domain_availabilities }) {
        if ( $domain_availability->is_available ) {
            print 'Domain: ' . $domain_availability->name . " is available! :) \n";
        }
        else {
            print 'Domain: ' . $domain_availability->name . " is not available! :( \n";
        }
    }

=head1 DESCRIPTION

Contains details about the availability of a domain.

=head1 ATTRIBUTES

=head2 B<name>

The full domain name (test-domain.com).

=head2 B<is_available>

Boolean indicating if this domain is available for registration.

=head2 sld

The portion of the domain name excluding the public_suffix, (test-domain).

=head2 public_suffix

The "root" of the domain (.com).  There is an alias of tld to this attribute.

B<NOTE> For domains like test-domain.co.uk the public_suffix is .co.uk.  The public suffix is what is available for someone to actually register.  For additional information between the distinction between Top Level Domain and Public Suffix please see L<https://publicsuffix.org/learn/>

=cut
