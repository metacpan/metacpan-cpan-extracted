package WWW::DNSMadeEasy::Domain;
BEGIN {
  $WWW::DNSMadeEasy::Domain::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::DNSMadeEasy::Domain::VERSION = '0.001';
}
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

sub name_server { shift->obj->{nameServer} }
sub gtd_enabled { shift->obj->{gtdEnabled} }
sub vanity_name_servers { shift->obj->{vanityNameServers} }
sub vanity_id { shift->obj->{vanityId} }

has obj => (
	is => 'ro',
	builder => '_build_obj',
	lazy => 1,
);

sub _build_obj {
	my ( $self ) = @_;
	return $self->dme->request('GET',$self->path);
}

sub create_record {
	my ( $self, $obj ) = @_;
	my $post_result = $self->dme->request('POST',$self->path_records,$obj);
	return WWW::DNSMadeEasy::Domain::Record->new({
		domain => $self,
		id => $_->{id},
		obj => $post_result,
	});
}

sub post {
	my ( $self ) = @_;
	$self->dme->request('POST',$self->path);
}

sub all_records {
	my ( $self ) = @_;
	my $data = $self->dme->request('GET',$self->path_records);
	my @records;
	for (@{$data}) {
		push @records, WWW::DNSMadeEasy::Domain::Record->new({
			domain => $self,
			id => $_->{id},
			obj => $_,
		});
	}
	return @records;
}

1;


__END__
=pod

=head1 NAME

WWW::DNSMadeEasy::Domain - A domain in the DNSMadeEasy API

=head1 VERSION

version 0.001

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

=encoding utf8

=head1 ATTRIBUTES

=head1 METHODS

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

