use strict;
use warnings;

package WebService::TVDB;
{
  $WebService::TVDB::VERSION = '1.133200';
}

# ABSTRACT: Interface to http://thetvdb.com/

use WebService::TVDB::Languages qw($languages);
use WebService::TVDB::Series;
use WebService::TVDB::Util qw(get_api_key_from_file);

use Carp qw(carp);
use LWP::Simple ();
use URI::Escape qw(uri_escape);
use XML::Simple qw(:strict);

use constant SEARCH_URL =>
  'http://thetvdb.com/api/GetSeries.php?seriesname=%s&language=%s';

use constant API_KEY_FILE => '/.tvdb';

use Object::Tiny qw(
  api_key
  language
  max_retries
);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    unless ( $self->api_key ) {
        require File::HomeDir;
        $self->{api_key} =
          get_api_key_from_file( File::HomeDir->my_home . API_KEY_FILE );
        die 'Can\'t find API key' unless $self->api_key;
    }

    unless ( $self->language ) {
        $self->{language} = 'English';
    }

    unless ( $self->max_retries ) {
        $self->{max_retries} = 10;
    }

    return $self;
}

sub search {
    my ( $self, $term ) = @_;

    unless ($term) {
        die 'search term is required';
    }

    my $url = sprintf( SEARCH_URL,
        uri_escape($term), $languages->{ $self->language }->{abbreviation} );
    my $agent = $LWP::Simple::ua->agent;
    $LWP::Simple::ua->agent("WebService::TVDB/$WebService::TVDB::VERSION");
    my $xml     = LWP::Simple::get($url);
    my $retries = 0;
    until ( defined $xml || $retries == $self->max_retries ) {
        carp "failed to get URL $url - retrying";

        # TODO configurable wait time
        sleep 1;
        $xml = LWP::Simple::get($url);

        $retries++;
    }
    $LWP::Simple::ua->agent($agent);
    unless ($xml) {
        die "failed to get URL $url after $retries retries. Aborting.";
    }
    $self->{series} = _parse_series(
        XML::Simple::XMLin(
            $xml,
            ForceArray    => ['Series'],
            KeyAttr       => 'Series',
            SuppressEmpty => 1
        ),
        $self->api_key,
        $languages->{ $self->language },
        $self->max_retries
    );

    return $self->{series};
}

sub get {
    my ( $self, $id ) = @_;

    die 'id is required' unless $id;

    $self->{series} = _parse_series(
        {
            Series => [
                {
                    seriesid => $id,
                    language => $languages->{ $self->language }->{abbreviation},
                }
            ]
        },
        $self->api_key,
        $languages->{ $self->language },
        $self->max_retries
    );

    $self->{series}->[0]->fetch();

    return $self->{series}->[0];
}

# parse the series xml and return an array of WebService::TVDB::Series
sub _parse_series {
    my ( $xml, $api_key, $api_language, $max_retries ) = @_;

    # loop over results and create new series objects
    my @series;
    for ( @{ $xml->{Series} } ) {
        push @series,
          WebService::TVDB::Series->new(
            %$_,
            _api_key      => $api_key,
            _api_language => $api_language,
            _max_retries  => $max_retries
          );
    }

    return \@series;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB - Interface to http://thetvdb.com/

=head1 VERSION

version 1.133200

=head1 SYNOPSIS

  my $tvdb = WebService::TVDB->new(api_key => 'ABC123', language => 'English', max_retries => 10);

  my $series_list = $tvdb->search('men behaving badly');

  my $series = @{$series_list}[0];
  # $series is a WebService::TVDB::Series
  say $series->SeriesName;
  say $series->Overview;

  # fetches full series data
  $series->fetch();

  say $series->Rating;
  say $series->Status;

  for my $episode (@{ $series->episodes }){
    # $episode is a WebService::TVDB::Episode
    say $episode->Overview;
    say $episode->FirstAired;
  }

  for my $actor (@{ $series->actors }){
    # $actor is a WebService::TVDB::Actor
    say $actor->Name;
    say $actor->Role;
  }

  for my $banner (@{ $series->banners }){
    # $banner is a WebService::TVDB::Banner
    say $banner->Rating;
    say $banner->url;
  }

  # can also get by id
  my $series = $tvdb->get(76213);

  # already done a fetch()

  say $series->SeriesName;
  say $series->Overview;
  say $series->Rating;
  say $series->Status;

=head1 DESCRIPTION

WebService::TVDB is an interface to L<http://thetvdb.com/>.

=head1 METHODS

=head2 new

Creates a new WebService::TVDB object. Takes the following parameters:

=over 4

=item api_key

This is your API key. If not passed in here, we will look in ~/.tvdb. Otherwise we will die.

=item language

The language you want tour results in. L<See WebService::TVDB::Languages> for a list of languages. Defaults to English.

=item max_retries

The amount of times we will try to get the series if our call to the URL failes. Defaults to 10.

=back

=head2 search( $term )

Searches the TVDB and returns a list of L<WebService::TVDB::Series> as the result.

=head2 get( $id )

Get a single L<WebService::TVDB::Series> by series id.

=head1 API KEY

To use this module, you will need an API key from http://thetvdb.com/?tab=apiregister.

You can pass this key into the constructor, or save it to ~/.tvdb.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Jones <andrew@andrew-jones.com>

=item *

Andrew Jones <andrewjones86@googlemail.com>

=item *

Fayland Lam <fayland@gmail.com>

=item *

Tim De Pauw <tim@pwnt.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
