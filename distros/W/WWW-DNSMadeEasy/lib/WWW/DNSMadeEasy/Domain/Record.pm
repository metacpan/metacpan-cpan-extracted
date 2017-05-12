package WWW::DNSMadeEasy::Domain::Record;
BEGIN {
  $WWW::DNSMadeEasy::Domain::Record::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::DNSMadeEasy::Domain::Record::VERSION = '0.001';
}
# ABSTRACT: A domain record in the DNSMadeEasy API

use Moo;

has id => (
	# isa => 'Int',
	is => 'ro',
	required => 1,
);

has domain => (
	# isa => 'WWW::DNSMadeEasy::Domain',
	is => 'ro',
	required => 1,
);

has obj => (
	# isa => 'HashRef',
	is => 'ro',
	builder => '_build_obj',
	lazy => 1,
);

sub _build_obj {
	my ( $self ) = @_;
	return $self->domain->dme->request('GET',$self->path);
}

sub ttl { shift->obj->{ttl} }
sub gtd_location { shift->obj->{gtdLocation} }
sub name { shift->obj->{name} }
sub data { shift->obj->{data} }
sub type { shift->obj->{type} }
sub password { shift->obj->{password} }
sub description { shift->obj->{description} }
sub keywords { shift->obj->{keywords} }
sub title { shift->obj->{title} }
sub redirect_type { shift->obj->{redirectType} }
sub hard_link { shift->obj->{hardLink} }

sub path {
	my ( $self ) = @_;
	$self->domain->path_records.'/'.$self->id;
}

sub delete {
	my ( $self ) = @_;
	$self->dme->request('DELETE',$self->path);
}

1;


__END__
=pod

=head1 NAME

WWW::DNSMadeEasy::Domain::Record - A domain record in the DNSMadeEasy API

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 id

=head2 domain

=head2 obj

=head1 METHODS

=head2 $obj->delete

=head2 $obj->ttl

=head2 $obj->gtd_location

=head2 $obj->name

=head2 $obj->data

=head2 $obj->type

=head2 $obj->password

=head2 $obj->description

=head2 $obj->keywords

=head2 $obj->title

=head2 $obj->redirect_type

=head2 $obj->hard_link

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

