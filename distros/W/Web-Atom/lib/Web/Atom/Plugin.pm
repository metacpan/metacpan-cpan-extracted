package Web::Atom::Plugin;
BEGIN {
  $Web::Atom::Plugin::VERSION = '0.1.0';
}
use strict;
use warnings;

=head1 NAME

Web::Atom::Plugin - Base class of plugins

=head1 VERSION

version 0.1.0

=cut

use Any::Moose;
has 'author_email' => (is => 'rw', isa => 'Str', default => 'example@example.com');
has 'author_name' => (is => 'rw', isa => 'Str', default => 'John Doe');
has 'body' => (is => 'rw', isa => 'Str', lazy_build => 1);
has 'id' => (is => 'rw', isa => 'Str');
has 'title' => (is => 'rw', isa => 'Str', default => 'Default title');
has 'url' => (is => 'rw', isa => 'Str');
has 'url_encoding' => (is => 'rw', isa => 'Str', default => '');

use Carp;
use Encode;
use LWP::UserAgent;
use namespace::autoclean;

sub _build_body {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts(verify_hostname => 0);

    my $res = $ua->get($self->url);
    if ('' eq $self->url_encoding) {
	return encode('utf8', $res->decoded_content);
    } else {
	return encode('utf8', decode($self->url_encoding, $res->content));
    }
}

=head2 entries

=cut

sub entries {
    croak 'Not implemented';
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;