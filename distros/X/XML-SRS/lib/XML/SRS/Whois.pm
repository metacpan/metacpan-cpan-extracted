
package XML::SRS::Whois;
BEGIN {
  $XML::SRS::Whois::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use MooseX::Aliases;
use MooseX::Aliases::Meta::Trait::Attribute;

has_attr 'full' =>
	is => "ro",
	isa => "XML::SRS::Boolean",
	xml_name => "FullResult",
	predicate => "has_full",
	lazy => 1,
	default => sub {1},
	;

has_attr 'source_ip' =>
	is => "ro",
	isa => "Str",
	predicate => "has_source_ip",
	xml_name => "SourceIP",
	;

has_attr 'domain_name' =>
	is => "ro",
	isa => "XML::SRS::DomainName",
	xml_name => "DomainName",
	required => 1,
	traits => [qw(Aliased)],
	alias => 'domain',
	;

sub root_element {"Whois"}
with 'XML::SRS::Query';
1;

__END__

=head1 NAME

XML::SRS::Whois - Class representing an SRS Whois transaction

=head1 SYNOPSIS

  my $whois = XML::SRS::Whois->new(
      full => 1,
      source_ip => 192.168.1.1,
      domain => 'nzrs.net.nz',
  );

=head1 DESCRIPTION

This class represents an SRS Whois request. The root XML element of this
class is 'Whois'.

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 full

Optional boolean. Maps to FullResult XML attribute.

=head2 source_ip

Optional string. Maps to SourceIP XML attribute.

=head2 domain

Required string, containing a valid domain name to query on.

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Query>