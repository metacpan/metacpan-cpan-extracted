package WWW::TextMarks;

use 5.008000;
use strict;
use warnings;
use LWP::Simple;
use XML::Simple;

our $VERSION = '0.01';

=head1 NAME

WWW::TextMarks - Provides access to the TextMarks SMS Service V2 API

=head1 SYNOPSIS

  use WWW::TextMarks;
  my $tm = WWW::TextMarks->new(
    apik => 'example_com_12345678',
    user => '5556781234',
    pass => 'y0ur$ekretPassword',
    tm   => 'yourtextmark',
  );
  my $res = $tm->send('5559994321', 'Hey, pick up your dry cleaning.');
  if ($res->{success})
  {
    print "Yippie.\n";
  }
  else
  {
    print "Error: $res->{error}\n";
  }

=head1 DESCRIPTION

WWW::TextMarks provides access to the TextMarks SMS Service V2 API.

Currently, it only allows you to send text messages to individual subscribers.
Eventually, it'll also allow you to maintain your subscriber list and perform
the full set of tasks made available by the TextMarks API.

Patches are welcome in case you get to it before I do.  :-)

=head1 METHODS

=head2 new

See SYNOPSIS above for an example.

Required: apik, user, pass, tm.
Optional: url

Setting the C<url> is not recommended unless the embedded URL in this module
fails to work properly or if you require an alternate URL provided by TextMarks.

The C<apik> is created by registering for an API key at:
L<http://www.textmarks.com/dev/api/reg/?ref=devapi>

The C<user> and C<pass> is your TextMarks website login username and password.
Your username is most likely your cell phone number.

=cut

sub new
{
  my $self = bless({}, shift);
  my %opts = @_;
  $self->{url} = $opts{url} || 'http://dev1.api.textmarks.com/Messaging/sendText/?apik=%%apik%%&auth_user=%%user%%&auth_pass=%%pass%%&tm=%%tm%%&to=%%phone%%&msg=%%message%%';
  $self->{apik} = $opts{apik}; # http://www.textmarks.com/dev/api/reg/?ref=devapi
  $self->{user} = $opts{user}; # textmarks username
  $self->{pass} = $opts{pass}; # textmarks password
  $self->{tm} = $opts{tm}; # textmark
  return $self;
}

=head2 send

See SYNOPSIS above for an example.

The first argument is the SMS recipient's phone number.  The second argument is
the message to send.  There are no other arguments.

If you wish to send to many recipients, just call C<send> multiple times, once
per recipient.

=cut

sub send
{
  my $self = shift;
  my $phone = shift;
  my $message = shift;
  $message =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
  my $url = $self->{url};
  $url =~ s/(%%([^%]+)%%)/$self->{$2}||$1/eg;
  $url =~ s/%%phone%%/$phone/g;
  $url =~ s/%%message%%/$message/g;
  my $response = get($url);
  my $resxml = {
    error => 'Response parser error',
    response => $response,
  };
  eval
  {
    $resxml = XMLin($response);
  };
  $resxml->{success} = ($resxml->{TMHead}->{ResMsg} eq 'Success' || 0);
  $resxml->{error} = $resxml->{TMHead}->{ResMsg} unless $resxml->{success};
  return $resxml;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dusty Wilson, E<lt>dusty@megagram.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
=cut

1;
