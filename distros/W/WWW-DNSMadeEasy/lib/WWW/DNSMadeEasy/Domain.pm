package WWW::DNSMadeEasy::Domain;
our $VERSION = '0.100';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A domain in the DNSMadeEasy API

use Moo;
use WWW::DNSMadeEasy::Domain::Record;

has name => (
	# isa => 'Str',
	is => 'ro',
	required => 1,
);

has dme => (
	# isa => 'WWW::DNSMadeEasy',
	is => 'ro',
	required => 1,
);

sub create {
	my ( $class, @args ) = @_;
	my $domain = $class->new(@args);
	$domain->put;
	return $domain;
}

sub path {
	my ( $self ) = @_;
	$self->dme->path_domains.'/'.$self->name;
}

sub delete {
	my ( $self ) = @_;
	$self->dme->request('DELETE',$self->path);
}

sub put {
	my ( $self ) = @_;
	$self->dme->request('PUT',$self->path);
}

sub path_records { shift->path.'/records' }

sub name_server { shift->response->data->{nameServer} }
sub gtd_enabled { shift->response->data->{gtdEnabled} }
sub vanity_name_servers { shift->response->data->{vanityNameServers} }
sub vanity_id { shift->response->data->{vanityId} }

has response => (
	is => 'ro',
	builder => '_build_response',
	lazy => 1,
);

sub _build_response {
	my ( $self ) = @_;
	$self->dme->request('GET',$self->path);
}

sub create_record {
	my ( $self, $data ) = @_;

	my $post_response = $self->dme->request('POST',$self->path_records,$data);

	return WWW::DNSMadeEasy::Domain::Record->new({
		domain => $self,
		id => $post_response->data->{id},
		response => $post_response,
	});
}

sub post {
	my ( $self ) = @_;
	$self->dme->request('POST',$self->path);
}

sub all_records {
	my ( $self ) = @_;

	my $data = $self->dme->request('GET', $self->path_records)->as_hashref;

	my @records;
	push @records, WWW::DNSMadeEasy::Domain::Record->new({
		domain     => $self,
		id         => $_->{id},
		as_hashref => $_,
	}) for @$data;
	
	return @records;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DNSMadeEasy::Domain - A domain in the DNSMadeEasy API

=head1 VERSION

version 0.100

=head1 ATTRIBUTES

=head2 name

Name of the domain

=head2 dme

L<WWW::DNSMadeEasy> object

=head2 obj

Hash object representation given by DNSMadeEasy.

=head1 METHODS

=head2 $obj->put

=head2 $obj->delete

=head2 $obj->all_records

=head2 $obj->create_record

=head2 $obj->name_server

=head2 $obj->gtd_enabled

=head2 $obj->vanity_name_servers

=head2 $obj->vanity_id

=head1 ATTRIBUTES

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-dnsmadeeasy>

  git clone https://github.com/Getty/p5-www-dnsmadeeasy.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Torsten Raudssus|https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
