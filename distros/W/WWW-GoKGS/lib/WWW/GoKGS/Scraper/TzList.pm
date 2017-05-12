package WWW::GoKGS::Scraper::TzList;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use WWW::GoKGS::Scraper::Declare;

sub base_uri { 'http://www.gokgs.com/tzList.jsp' }

sub __build_scraper {
    my $self = shift;

    scraper {
        process '//option', 'time_zones[]' => {
                    # tzdata-compatible name of time zone (maybe or maybe not)
                    name => sub { $_[0]->attr('value') },
                    # java.util.TimeZone's getDisplayName (long version, maybe)
                    # obviously useless, but harmless :)
                    display_name => [ 'TEXT', sub { s/ \([^\)]+\)$// } ],
                    selected => sub { $_[0]->attr('selected') } };
    };
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    for my $time_zone ( @{$result->{time_zones}} ) {
        next unless delete $time_zone->{selected};
        $result->{current_time_zone} = { %$time_zone };
    }

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::TzList - KGS Time Zone Selector

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::TzList;

  my $tz_list = WWW::GoKGS::Scraper::TzList->new;

  my $result = $tz_list->query( tz => 'Asia/Tokyo' );
  # => {
  #     current_time_zone => {
  #         name => 'Asia/Tokyo',
  #         display_name => 'Japan Standard Time'
  #     },
  #     time_zones => [
  #         {
  #             name => 'America/Anchorage',
  #             display_name => 'Alaska Standard Time'
  #         },
  #         ...
  #     ]
  # }

=head1 DESCRIPTION

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 CLASS METHODS

=over 4

=item $String = $class->base_uri

  # => "http://www.gokgs.com/tzList.jsp"

=item $URI = $class->build_uri( tz => 'Asia/Tokyo' );

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the parameters.

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $tz_list->user_agent

=item $tz_list->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $HashRef = $tz_list->query

Returns a hash reference which contains your current time zone
and a list of available time zones. The hashref is formatted as follows:

  {
      current_time_zone => {
          name => 'Asia/Tokyo',
          display_name => 'Japan Standard Time'
      },
      time_zones => [
          {
              name => 'America/Anchorage',
              display_name => 'Alaska Standard Time'
          },
          ...
      ]
  }

=item $HashRef = $tz_list->query( tz => 'Asia/Tokyo' )

Can be used to set your time zone. The time zone must be included by the list
of time zones. HTTP cookies must be accepted by your user agent.
All the KGS web pages are affected by the cookie setting, i.e.,
times for games are shown in the specified time zone.
In other words, all the KGS resources will become stateful.
If you dislike this behaviour, do not change the default time zone, GMT.

Returns a hash reference which contains your current time zone
and a list of available time zones.

=item $HashRef = $tz_list->scrape( URI->new(...) )

=item $HashRef = $tz_list->scrape( HTTP::Response->new(...)[, $base_uri] )

=item $HashRef = $tz_list->scrape( $html[, $base_uri] )

=item $HashRef = $tz_list->scrape( \$html[, $base_uri] )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
