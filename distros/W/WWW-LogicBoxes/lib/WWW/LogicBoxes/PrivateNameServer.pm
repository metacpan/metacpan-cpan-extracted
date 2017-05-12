package WWW::LogicBoxes::PrivateNameServer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( DomainName Int IPs );

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: LogicBoxes Private Nameserver

has domain_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has ips => (
    is       => 'ro',
    isa      => IPs,
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::PrivateNameServer - Representation of Private Nameserver

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::PrivateNameServer;

    my $domain = WWW::LogicBoxes::Domain->new( ... ); # Valid LogicBoxes domain

    my $private_name_server = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '8.8.8.8', '2001:4860:4860:0:0:0:0:8888' ],  # IPv4 and IPv6 are supported
    );

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $updated_domain = $logic_boxes->create_private_nameserver( $private_name_server );

=head1 DESCRIPTION

Private Nameservers are those that are from the same domain as the L<registered domain|WWW::LogicBoxes::Domain>.  For example, a domain test-domain.com could have private nameservers ns1.test-domain.com and ns2.test-domain.com.

These nameservers must be "registered" with L<LogicBoxes|http://www.logicboxes.com> and it is the responsiblity of WWW::LogicBoxes::PrivateNameServer to represent all of the data assoicated with these registrations.

=head1 ATTRIBUTES

=head2 B<domain_id>

The L<domain|WWW::LogicBoxes::Domain> id assoicated with the domain that this will be a private nameserver for (test-domain.com).

=head2 B<name>

The full domain name that will represent the private nameserver (ns1.test-domain.com).  It must be a child of the L<domain|WWW::LogicBoxes::Domain> whose id is being used.

=head2 B<ips>

An ArrayRef of IP addresses ( both IPv4 and IPv6 are supported ) that the above L<name> should resolve to.

=cut
