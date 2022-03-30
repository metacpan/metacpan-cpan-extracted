package Test2::Tools::HTTP::UA::LWPClass;

use strict;
use warnings;
use URI;
use parent 'Test2::Tools::HTTP::UA';

# ABSTRACT: Global LWP user agent wrapper for Test2::Tools::HTTP
our $VERSION = '0.10'; # VERSION


my %orig;
my $ua;

sub instrument
{
  my($self) = @_;

  require LWP::Protocol;
  require LWP::UserAgent;

  foreach my $proto (qw( http https ))
  {
    $orig{$proto} ||= do {
      my $orig = LWP::Protocol::implementor($proto);
      LWP::Protocol::implementor($proto, 'Test2::Tools::HTTP::UA::LWPClass::Proto');
      $orig;
    };
  }

  $ua ||= LWP::UserAgent->new;
}

sub request
{
  my($self, $req, %options) = @_;

  if($self->apps->uri_to_app($req->uri) && $req->uri =~ /^\//)
  {
    $req->uri(
      URI->new_abs($req->uri, $self->apps->base_url),
    );
  }

  my $res = $options{follow_redirects}
    ? $ua->request($req)
    : $ua->simple_request($req);

  if(my $warning = $res->header('Client-Warning'))
  {
    $self->error(
      "connection error: " . ($res->decoded_content || $warning),
      $res,
    );
  }

  $res;
}

__PACKAGE__->register('LWP::UserAgent', 'class');

package Test2::Tools::HTTP::UA::LWPClass::Proto;

use parent qw(LWP::Protocol);
use HTTP::Message::PSGI qw( req_to_psgi res_from_psgi );

sub apps { Test2::Tools::HTTP::UA->apps }

sub request
{
  my($self, $req, $proxy, $arg, @rest) = @_;

  if(my $app = $self->apps->uri_to_app($req->uri))
  {
    my $env = req_to_psgi $req;
    my $res = res_from_psgi $app->($env);
    my $content = $res->content;
    $res->content('');
    return $self->collect_once($arg, $res, $content);
  }
  else
  {
    return $orig{$self->{scheme}}->new($self->{scheme}, $self->{ua})->request($req, $proxy, $arg, @rest);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP::UA::LWPClass - Global LWP user agent wrapper for Test2::Tools::HTTP

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Test2::Tools::HTTP;
 use LWP::UserAgent;
 
 psgi_app_add 'http://example.test' => sub { ... };
 
 http_ua 'LWP::UserAgent';
 
 my $ua = LWP::UserAgent->new;
 my $res = $ua->get('http://example.test');

=head1 DESCRIPTION

This class is not intended to be used directly.

This module provides the machinery for instrumenting
L<LWP::UserAgent> for use with L<Test2::Tools::HTTP>.
Since L<LWP::UserAgent>.  It is different from
L<Test2::Tools::HTTP::UA::LWP> in that it instruments
the L<LWP::UserAgent> class itself, so ALL instances
will be able to use any apps registered.

=head1 SEE ALSO

=over 4

=item L<Test2::Tools::HTTP>

=item L<Test2::Tools::HTTP::UA::LWP>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
