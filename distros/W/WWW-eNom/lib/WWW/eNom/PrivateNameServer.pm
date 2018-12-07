package WWW::eNom::PrivateNameServer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( DomainName IP );

use Try::Tiny;
use Carp;

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Representation of Private Nameserver

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'ip' => (
    is       => 'ro',
    isa      => IP,
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

WWW::eNom::PrivateNameServer - Representation of Private Nameserver

=head1 SYNOPSIS

    my $domain = WWW::eNom::Domain->new( ... );

    my $private_name_server = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

=head1 DESCRIPTION

Represents L<eNom|https://www.enom.com> private nameservers, containing the name and ip address.

=head1 ATTRIBUTES

=head2 B<name>

The FQDN of the nameserver (will be ns1.your-domain.com).  Keep in mind the 'your-domain.com' part must match the registered domain this is going to be a private nameserver for.

=head2 B<ip>

The IP address that the above name should resolve to.

=cut
