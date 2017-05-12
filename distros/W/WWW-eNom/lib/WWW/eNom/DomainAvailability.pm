package WWW::eNom::DomainAvailability;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool DomainName );

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: eNom Domain Availability Response

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'is_available' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

with 'WWW::eNom::Role::ParseDomain';

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::eNom::DomainAvailability

=head1 SYNOPSIS

    use WWW::eNom;

    my $eNom = WWW::eNom->new( ... );

    my $domain_availabilities = $eNom->check_domain_availability(
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
