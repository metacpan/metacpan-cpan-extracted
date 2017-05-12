package WWW::PGXN::Mirror;

use 5.8.1;
use strict;

our $VERSION = v0.12.4;

BEGIN {
    for my $attr (qw(
        uri
        frequency
        location
        organization
        timezone
        bandwidth
        src
        rsync
        notes
     )) {
        no strict 'refs';
        *{$attr} = sub { shift->{$attr} };
    }
}

sub new {
    my ($class, $data) = @_;
    bless $data, $class;
}

sub email {
    my ($host, $user) = split /[|]/ => shift->{email};
    return "$user\@$host";
}

1;
__END__

=head1 Name

WWW::PGXN::Mirror - Mirror metadata fetched from PGXN

=head1 Synopsis

  my $pgxn = WWW::PGXN->new( url => 'http://api.pgxn.org/' );
  for my $mirror ($pgxn->mirrors) {
      say $mirror->url;
  }

=head1 Description

This module represents PGXN mirror metadata fetched from PGXN>. It is not
intended to be constructed directly, but via the L<WWW::PGXN/mirrors> method
of L<WWW::PGXN>.

=head1 Interface

=begin private

=head2 Constructor

=head3 C<new>

  my $mirror = WWW::PGXN::Mirror->new($data);

Construct a new WWW::PGXN::Mirror object. The argument must be the data
fetched.

=end private

=head2 Instance Accessors

=head3 C<uri>

  my $uri = $mirror->uri;
  $mirror->uri($uri);

The URI of the mirror.

=head3 C<bandwidth>

  my $bandwidth = $mirror->bandwidth;
  $mirror->bandwidth($bandwidth);

The mirror's bandwidth.

=head3 C<frequency>

  my $frequency = $mirror->frequency;
  $mirror->frequency($frequency);

A description of how frequently the mirror updates.

=head3 C<location>

  my $location = $mirror->location;
  $mirror->location($location);

The location of the mirror.

=head3 C<notes>

  my $notes = $mirror->notes;
  $mirror->notes($notes);

Notes about the mirror.

=head3 C<organization>

  my $organization = $mirror->organization;
  $mirror->organization($organization);

The name of the organization hosting the mirror.

=head3 C<email>

  my $email = $mirror->email;
  $mirror->email($email);

The email address of the contact responsible for the mirror..

=head3 C<src>

  my $src = $mirror->src;
  $mirror->src($src);

The rsync URL that the mirror updates from.

=head3 C<rsync>

  my $rsync = $mirror->rsync;
  $mirror->rsync($rsync);

The rsync URL the mirror offers for other mirrors to update from. If false,
the mirror provides no rsync URL of its own.

=head3 C<timezone>

  my $timezone = $mirror->timezone;
  $mirror->timezone($timezone);

The time zone in which the mirror lives.

=head1 See Also

=over

=item * L<WWW::PGXN>

The main class to communicate with a PGXN mirror or API server.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/www-pgxn/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/www-pgxn/issues/> or by sending mail to
L<bug-WWW-PGXN@rt.cpan.org|mailto:bug-WWW-PGXN@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
