package WWW::MelissaData::PhoneLocation;

use 5.008000;
use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = '0.01';

=head1 NAME

WWW::MelissaData::PhoneLocation - Provides an interface to MelissaData's free
phone location lookup service

=head1 SYNOPSIS

  use WWW::MelissaData::PhoneLocation;
  my $loc = WWW::MelissaData::PhoneLocation->new;
  my $phone = $loc->query('4079347639'); # 407-W-DISNEY (Disney Reservations)
  use Data::Dumper;
  print Dumper($phone);

=head1 DESCRIPTION

Put in a phone number and it will give you the city, state, telco, and other
assorted data for that number.  The data comes from MelissaData.com.  This only
provides data for NANPA phone numbers (US/Canada).

=head2 new

Creates WWW::MelissaData::PhoneLocation object.

=cut

sub new
{
  my $self = bless({}, shift);
  my %args = @_;
  $self->{url} = $args{url} || 'http://www.melissadata.com/lookups/phonelocation.asp?number=';
  $self->{uastring} = $args{uastring} || 'WWW::MelissaData::PhoneLocation/'.$VERSION;
  $self->{ua} = $args{ua}; # pass an existing LWP::UserAgent object

  if (!$self->{ua})
  {
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent($self->{uastring});
  }

  return $self;
}

=head2 query

Queries the site.  Provide a phone number as the only argument.

Do not include a country code.  Do not provide a "1" prefix.  Use only the
ten-digit phone number.  It is okay to include hyphens/dashes/etc; non-digit
characters will be removed automatically.

=cut

sub query
{
  my $self = shift;
  my $number = shift;
  $number =~ s/\D+//g; # kill any non-digit chars
  my $req = HTTP::Request->new(GET => $self->{url}.$number);
  my $res = $self->{ua}->request($req);
  if ($res->is_success)
  {
    my $content = $res->content;
    $content =~ s#[\r\n]# #gm;
    $content =~ m#<center><table\s.*?>(.*?)</table>#i;
    my $data = $1;
    $data =~ s#</?(a|img|br|b).*?># #gi;
    $data =~ s#</t[rd].*?>##gi;
    $data =~ s#\s+# #g;
    my @data = split(/<tr.*?>/i, $data);
    shift(@data); # header
    shift(@data); # header
    my $info = {};
    foreach my $row (@data)
    {
      my @parts = split(/<td.*?>/i, $row);
      shift(@parts); # empty
      my $var = lc(shift(@parts));
      $var =~ s/\s+//g;
      my $val = shift(@parts);
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
      $val =~ s/\s+/ /g;
      $info->{$var} = $val;
    }

    delete($info->{'name&amp;address'});
    $info->{zip1} = $info->{'primaryzipcode'};
    delete($info->{'primaryzipcode'});
    $info->{zip2} = $info->{'secondaryzipcode'};
    delete($info->{'secondaryzipcode'});
    $info->{zip3} = $info->{'otherzipcode'};
    delete($info->{'otherzipcode'});
    $info->{type} = $info->{'typeofservice'};
    delete($info->{'typeofservice'});
    $info->{businessesinprefix} = $info->{'#ofbusinessesinprefix'};
    delete($info->{'#ofbusinessesinprefix'});
    ($info->{countyname} = $info->{'countyname(fipscode)'}) =~ s#\s*\(\s*(.*?)\s*\)\s*##g;
    $info->{fipscode} = $1 if ($info->{'countyname(fipscode)'});
    delete($info->{'countyname(fipscode)'});
    ($info->{metroarea} = $info->{'metroarea(code)'}) =~ s#\s*\(\s*(.*?)\s*\)\s*##g;
    $info->{metrocode} = $1 if ($info->{'metroarea(code)'});
    delete($info->{'metroarea(code)'});
    ($info->{timezone} = $info->{'timezone(localtime)'}) =~ s#\s*\(\s*(.*?)\s*\)\s*##g;
    $info->{localtime} = $1 if ($info->{'timezone(localtime)'});
    delete($info->{'timezone(localtime)'});

    return $info;
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
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
