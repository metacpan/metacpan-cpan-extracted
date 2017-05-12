package WWW::FoneFinder;

use 5.008000;
use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = '0.02';

=head1 NAME

WWW::FoneFinder - Provides an interface to FoneFinder.net

=head1 SYNOPSIS

  use WWW::FoneFinder;
  my $ff = WWW::FoneFinder->new;
  my $phone = $ff->query('4079347639'); # 407-W-DISNEY (Disney Reservations)
  use Data::Dumper;
  print Dumper($phone);

=head1 DESCRIPTION

Put in a phone number and it will give you the city, state, and telco for that
number.  The data comes from FoneFinder.net.  This only provides data for NANPA
phone numbers (US/Canada).

=head2 new

Creates WWW::FoneFinder object.

=cut

sub new
{
  my $self = bless({}, shift);
  my %args = @_;
  $self->{url} = $args{url} || 'http://www.fonefinder.net/findome.php';
  $self->{referer} = $args{referer} || 'http://www.fonefinder.net/index.php';
  $self->{uastring} = $args{uastring} || 'WWW::FoneFinder/'.$VERSION;
  $self->{ua} = $args{ua}; # pass an existing LWP::UserAgent object

  if (!$self->{ua})
  {
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent($self->{uastring});
  }

  return $self;
}

=head2 query

Queries the site.  Provide a phone number.  It only sends the area code (NPA),
prefix (NXX), and first digit of the last four.

Do not include a country code.  Do not provide a "1" prefix.  Use only the
ten-digit phone number.  It is okay to include hyphens/dashes/etc; non-digit
characters will be removed automatically.

Format must be: NPANXXNNNN (1234567890: 123 = areacode, 456 = prefix, 7890 =
last four digits).

If you provide "4079347639", it will send 407, 934, and 7.  It will not send the
last three digits 639 as they are not useful (plus an added privacy bonus).

=cut

sub query
{
  my $self = shift;
  my $number = shift;
  $number =~ s/\D+//g; # kill any non-digit chars
  $number =~ s/^(\d{3})//;
  my $npa = $1;
  $number =~ s/^(\d{3})//;
  my $nxx = $1;
  $number =~ s/^(\d)//;
  my $thoublock = $1;
  my $req = HTTP::Request->new(POST => $self->{url});
  $req->referer($self->{referer}) if $self->{referer};
  $req->content_type('application/x-www-form-urlencoded');
  $req->content('npa='.$npa.'&nxx='.$nxx.'&thoublock='.$thoublock.'&usaquerytype=1');
  my $res = $self->{ua}->request($req);
  if ($res->is_success)
  {
    my $content = $res->content;
    $content =~ s#</td>##gi; # in case they decided to be more proper with their HTML it won't break this (hopefully)
    $content =~ m#<TABLE\s.*?>(.*?)</TABLE>#i;
    my $data = $1;
    $data =~ s#</?(a|img|br).*?>##gi;
    $data =~ s#<tr>\s*$##i;
    my @data = split(/<tr>/i, $data);
    shift(@data); # header
    my @list;
    foreach my $row (@data)
    {
      my @parts = split(/<td>/i, $row);
      shift(@parts); # empty
      my $item = {
        npa => shift(@parts),
        nxx => shift(@parts),
        city => shift(@parts),
        state => shift(@parts),
        telco => shift(@parts),
      };
      push(@list, $item);
    }
    return \@list;
  }
  else
  {
    return undef;
  }
}

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Dusty Wilson, E<lt>dusty@megagram.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
