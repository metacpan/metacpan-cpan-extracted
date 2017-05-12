package VM::Virtuozzo;

use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use Carp;
use File::ShareDir "dist_dir";
use File::Spec::Functions qw(catdir catfile);
use Params::Check "check";
use XML::Compile::Cache;
use XML::Compile::Util "pack_type";
use VM::Virtuozzo::Response;
use Socket qw(inet_aton);
use IO "Socket::INET";

use constant {
	Document => "XML::LibXML::Document",
	Element  => "XML::LibXML::Element",
	Response => "VM::Virtuozzo::Response" };

use namespace::clean;

our $VERSION = 'v0.0.5'; # VERSION
# ABSTRACT: Client implementation of the Parallels Virtuozzo XML API

my $schema = XML::Compile::Cache->new(
	allow_undeclared => 1,
	opts_rw          => { elements_qualified => 0 } );
do {
	my $dist_dir  = dist_dir("VM-Virtuozzo");
	my $xsd_dir   = catdir $dist_dir, "v4";
	my @xsd_files = glob catfile $xsd_dir, "*.xsd";
	$schema->importDefinitions($_) for @xsd_files; };

sub new {
	my ( $class, %params ) = @_;

	# Check params:
	my %tmpl = (
		xsd_version => {
			required => 1,
			allow    => [4] }, # Only version supported for now
		use_ssl => {
			default => 1,
			allow   => [ 0, 1 ] },
		hostname => {
			required => 1,
			allow    => sub { $_[0] && inet_aton($_[0]) } } );
	check( \%tmpl, \%params, 1 ) or croak "Parameter check failed";

	# Create self and client attribute:
	my $client = IO::Socket::INET->new(
		PeerAddr => $params{hostname},
		PeerPort => 4433,
		Proto    => "tcp",
		Timeout  => 10 ) or croak "Unable to connect to server";
	local $/ = "\0";

	return bless {
		_client => $client,
		_schema => $schema }, $class; }

my $packet_id = 1;
my $doc       = Document->new("1.0", "UTF-8");
sub _write_packet {
	my ($self, $namespace, $function, $params) = @_;
	my $protocol_ns = $namespace;
	$protocol_ns =~ s/\w+$/protocol/x;
	$protocol_ns =~ s/\bvza\b/vzl/xg;
	my $packet_type =  pack_type($protocol_ns, "packet");
	my $op_type = pack_type($namespace, $function);
	my ($short_ns) = $namespace =~ /(\w+)$/x;
	my $operator = Element->new($short_ns);

	$operator->addChild(
		defined $params
			? $self->{_schema}->writer($op_type)->($doc, $params)
			: Element->new($function) );
	my $packet = $self->{_schema}->writer($packet_type)->(
		$doc, {
			id      => $packet_id++,
			version => "4.0.0",
			( $short_ns eq "system" ? () : ( target => $short_ns ) ),
			data    => { cho_operator => [ { $short_ns => $operator } ] } } );
	return $packet->toString; }

# Generate API methods:

foreach my $namespace ( $schema->namespaces->list ) {
	my ($ns_short) = $namespace =~ /(\w+)$/x;
	no strict "refs";
	*{__PACKAGE__ . "::" . $ns_short} = sub {
		use strict "refs";
		my ($self, $function, $params) = @_;
		my $operation = $self->_write_packet($namespace, $function, $params);
		$operation =~ s/(\w+?>.+?==)\n/$1/gx;
		$self->{_client}->print($operation . "\0");
		local $/ = "\0";
		return $self->{_client}->getline; } }
#		return Response->new(
#			$client->reader($namespace)->( $self->_client->getline ) ); } }

1;

__END__

=encoding utf8

=head1 NAME

VM::Virtuozzo - Client implementation of the Parallels Virtuozzo XML API

=head1 SYNOPSIS

	my $vzzo = VM::Virtuozzo->new(
	    hostname    => "domain.tld", # or an IPv4 address
	    use_ssl     => 0,
	    xsd_version => 4
	);
	$vzzo->system( login => {
	    name     => "root",
	    realm    => "00000000-0000-0000-0000-000000000000",
	    password => "mysecret123"
	} );
	$vzzo->vzaenvm( suspend => { # suspend a container
	    eid => "e43581cb-f13a-324d-aab5-e356e19ebee4"
	} );

=head1 DESCRIPTION

This distribution provides a client implementation of the Parallels Virtuozzo
XML API, enabling the user to remotely manage Parallels Virtuozzo Containers.
Handling of the XML data objects is delegated to L<XML::Compile>.

Be warned: this is B<ALPHA QUALITY SOFTWARE>. Significant bugs probably exist,
some features are missing, and the interface should be considered unstable. Use
at your own risk.

=head1 METHODS

=head2 CLASS

=over

=item new(%args)

Constructor method callable with the following named parameters (all mandatory):

=item C<hostname>

Domain name or IPv4 address of the Virtuozzo server.

=item C<use_ssl>

1 or 0 to connect over HTTPS.

=item C<xsd_version>

Integer value indicating API version: only B<4> is supported for this release.

=back

=head2 OBJECT

=over

=item alertm(...)

=item authm(...)

=item backupm(...)

=item computerm(...)

=item data_storagem(...)

=item devm(...)

=item env_samplem(...)

=item envm(...)

=item event_log(...)

=item filer(...)

=item firewallm(...)

=item licensem(...)

=item mailer(...)

=item networkm(...)

=item op_log(...)

=item packagem(...)

=item perf_mon(...)

=item proc_info(...)

=item processm(...)

=item progress_event(...)

=item protocol(...)

=item relocator(...)

=item res_log(...)

=item resourcem(...)

=item scheduler(...)

=item server_group(...)

=item servicem(...)

=item sessionm(...)

=item system(...)

=item types(...)

=item userm(...)

=item vzadevm(...)

=item vzaenvm(...)

=item vzanetworkm(...)

=item vzapackagem(...)

=item vzaproc_info(...)

=item vzaprocessm(...)

=item vzarelocator(...)

=item vzasupport(...)

=item vzatypes(...)

=item vzaup2date(...)

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License v. 3.0|http://gnu.org/licenses/lgpl.html>
and may be modified and/or redistributed under the same or any compatible
license.
