package Weather::Airport;

use 5.008000;
use strict;
use warnings;
use LWP::UserAgent;

our $VERSION = '0.01';

=head1 NAME

Weather::Airport - Provides an interface to FlightStats.com Airport Weather Query

=head1 SYNOPSIS

   use Weather::Airport;
   my $wa = Weather::Airport->new;
   my $airport = $wa->query('LAX');
   use Data::Dumper;
   print Dumper ($airport);

=head1 DESCRIPTION



=head2 new

Creates Weather::Airport object.

=cut

sub new {
   my $self = bless({}, shift);
   my %args = @_;
   $self->{url} = $args{url} || 'http://www.flightstats.com/go/Airport/weather.do?airport=';
   $self->{referer} = $args{referer} || 'http://www.flightstats.com/go/Home/home.do';
   $self->{uastring} = $args{uastring} || 'Weather::Airport/'.$VERSION;
   $self->{ua} = $args{ua}; # pass an existing LWP::UserAgent object

   if (!$self->{ua})
   {
     $self->{ua} = LWP::UserAgent->new;
     $self->{ua}->agent($self->{uastring});
   }
   return $self;
}

=head2 query

Queries the site.  Provide an airport code to retrieve current conditions.

=cut

sub query {
   my $self = shift;
   my $apcode = shift;
   my @data;
   my $error = "The airport code is invalid.";
   $apcode =~ s/[^A-Za-z0-9]//g;
   my $req = HTTP::Request->new(GET => $self->{url} . $apcode);
   $req->referer($self->{referer}) if $self->{referer};
   $req->content_type('application/x-www-form-urlencoded');
   my $res = $self->{ua}->request($req);
   if ($res->is_success) {
      my $content = $res->content;
      $content =~ s/\s+/ /g;
      if ($content =~ m#The airport code is invalid#) {
         return $error;
      }
      else {
         while ($content =~ m/<tr> <td class="label">(.*?)<\/tr>/g) {
            my $ap = ($1);
            $ap =~ s/<(.*?)>//gi;
            $ap =~ s/\&nbsp\;//gi;
            $ap =~ s/\&deg\;/°/gi;
            $ap =~ s/\s+/ /g;
            push(@data, "$ap");
         }
         return \@data;
      }
   }
}

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Joseph Tartaro, E<lt>droogie@foster.stonedcoder.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


