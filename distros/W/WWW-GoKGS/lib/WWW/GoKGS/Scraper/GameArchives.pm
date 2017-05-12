package WWW::GoKGS::Scraper::GameArchives;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use WWW::GoKGS::Scraper::Declare;
use WWW::GoKGS::Scraper::Filters qw/game_result datetime/;

sub base_uri { 'http://www.gokgs.com/gameArchives.jsp' }

sub __build_scraper {
    my $self = shift;

    my $month2num = do {
        my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        my %month2num; @month2num{ @months } = ( 1..12 );
        sub { $month2num{$_[0]} };
    };

    my %user = (
        name => [ 'TEXT', sub { s/ \[[^\]]+\]$// } ],
        rank => [ 'TEXT', sub { m/ \[([^\]]+)\]$/ ? $1 : undef } ],
        uri  => '@href',
    );

    my $game = scraper {
        process '//td[1]/a', 'sgf_uri' => '@href';
        process '//td[2]/a', 'white[]' => \%user;
        process '//td[3]/a', 'black[]' => \%user;
        process '//td[3]', 'maybe_setup' => 'TEXT';
        process '//td[4]', 'setup' => 'TEXT';
        process '//td[5]', 'start_time' => 'TEXT';
        process '//td[6]', 'type' => 'TEXT';
        process '//td[7]', 'result' => 'TEXT';
        process '//td[8]', 'tag' => 'TEXT';
    };

    my $calendar = scraper {
        process 'td', 'year' => 'TEXT';
        process '//following-sibling::td[not(@colspan)]',
                'month[]' => scraper {
                    process '.', 'month' => [ 'TEXT', $month2num ];
                    process 'a', 'uri' => '@href'; };
    };

    scraper {
        process '//a[@href="tzList.jsp"]', 'time_zone' => 'TEXT';
        process '//table[tr/th/text()="Viewable?"]//following-sibling::tr',
                'games[]' => $game;
        process '//a[contains(@href, ".zip")]', 'zip_uri' => '@href';
        process '//a[contains(@href, ".tar.gz")]', 'tgz_uri' => '@href';
        process '//table[colgroup]//following-sibling::tr',
                'calendar[]' => $calendar;
    };
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    return $result unless $result->{calendar};

    my @calendar;
    for my $calendar ( @{$result->{calendar}} ) {
        for my $month ( @{$calendar->{month}} ) {
            $month->{year} = $calendar->{year};
            push @calendar, $month;
        }
    }

    if ( @calendar == 1 and $calendar[0]{year} == 1970 ) { # KGS's bug
        delete $result->{calendar};
    }
    else {
        $result->{calendar} = \@calendar;
    }

    return $result unless $result->{games};

    for my $game ( @{$result->{games}} ) {
        next if exists $game->{black};

        # <td colspan="2">
        my $users = $game->{white};
        if ( @$users == 1 ) { # Type: Demonstration
            $game->{owner} = $users->[0];
        }
        elsif ( @$users == 3 ) { # Type: Review
            $game->{owner} = $users->[0];
            $game->{white} = [ $users->[1] ];
            $game->{black} = [ $users->[2] ];
        }
        elsif ( @$users == 5 ) { # Type: Rengo Review
            $game->{owner} = $users->[0];
            $game->{white} = [ @{$users}[1,2] ];
            $game->{black} = [ @{$users}[3,4] ];
        }
        else {
            die 'Oops! Something went wrong';
        }

        $game->{tag}        = $game->{result} if exists $game->{result};
        $game->{result}     = $game->{type};
        $game->{type}       = $game->{start_time};
        $game->{start_time} = $game->{setup};
        $game->{setup}      = $game->{maybe_setup};
    }
    continue {
        $game->{start_time} = datetime( $game->{start_time} );
        $game->{result}     = game_result( $game->{result} );
        $game->{setup}      =~ /^(\d+)\x{d7}\d+ (?:H(\d+))?$/;
        $game->{board_size} = $1;
        $game->{handicap}   = $2 if defined $2;

        for my $user (
            $game->{owner} || (),
            @{ $game->{black} || [] },
            @{ $game->{white} || [] },
        ) {
            delete $user->{rank} unless $user->{rank};
        }

        delete $game->{setup};
        delete $game->{maybe_setup};
    }

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::GameArchives - KGS Game Archives

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::GameArchives;
  my $game_archives = WWW::GoKGS::Scraper::GameArchives->new;
  my $result = $game_archives->query( user => 'YourAccount' );

=head1 DESCRIPTION

L<KGS|http://www.gokgs.com/> Game Archives
preserves Go games played by the users. You can search games by filling
in the HTML forms. The search result is provided as an HTML document naturally.

This module provides yet another interface to send a query to the archives,
and also parses the result into a neatly arranged Perl data structure.

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 DISCLAIMER

According to KGS's C<robots.txt>, bots are not allowed to crawl 
the Game Archives:

  User-agent: *
  Disallow: /gameArchives.jsp

Although this module can be used to implement crawlers,
the author doesn't intend to violate their policy.
Use at your own risk.

=head2 CLASS METHODS

=over 4

=item $uri = $class->base_uri

  # => "http://www.gokgs.com/gameArchives.jsp"

=item $URI = $class->build_uri( $k1 => $v1, $k2 => $v2, ... )

=item $URI = $class->build_uri({ $k1 => $v1, $k2 => $v2, ... })

=item $URI = $class->build_uri([ $k1 => $v1, $k2 => $v2, ... ])

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the parameters.

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $game_archives->user_agent

=item $game_archives->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $HashRef = $game_archives->query( user => 'YourAccount', ... )

Given key-value pairs of query parameters, returns a hash reference
which represnets the result. The hashref is formatted as follows:

  {
      time_zone => 'GMT',
      games => [
          {
              sgf_uri => 'http://files.gokgs.com/.../foo-bar.sgf',
              white => [
                  {
                      name => 'foo',
                      rank => '4k',
                      uri  => 'http://...&user=foo...'
                  }
              ],
              black => [
                  {
                      name => 'bar',
                      rank => '6k',
                      uri  => 'http://...&user=bar...'
                  }
              ],
              board_size => '19',
              handicap => '2',
              start_time => '2013-07-04T05:32',
              type => 'Ranked',
              result => 'W+Resign'
          },
          ...
      ],
      zip_uri => 'http://.../foo-2013-7.zip',    # contains SGF files
      tgz_uri => 'http://.../foo-2013-7.tar.gz', # created in July 2013
      calendar => [
          ...
          {
              year  => 2011,
              month => 7,
              uri   => '/gameArchives.jsp?user=foo&year=2011&month=7'
          },
          ...
      ]
  }

The possible parameters are as follows:

=over 4

=item user (required)

Represents a KGS username.

  my $result = $game_archives->query( user => 'foo' );

=item year, month

Can be used to search games played in the specified month.

  my $result = $game_archives->query(
      user  => 'foo',
      year  => 2013
      month => 7
  );

=item oldAccounts

Can be used to search games played by expired and guest accounts.

  my $result = $game_archives->query(
      user        => 'foo',
      oldAccounts => 'y'
  );

=item tags

Can be used to search games tagged by the specified C<user>.

  my $result = $game_archives->query(
      user => 'foo',
      tags => 't'
  );

=back

=item $HashRef = $game_archives->scrape( $stuff )

The given arguments are passed to L<Web::Scraper>'s C<scrape> method.
C<query> method is just a wrapper of this method. For example,
you can pass URIs included by the return value of C<query> method.

=back

=head1 EXAMPLES

  use JSON::Path qw/jpath_map/; 
  use Time::Piece qw/gmtime/;

  # convert start times for games into Time::Piece objects
  jpath_map { gmtime->strftime('%Y-%m-%dT%H:%MZ', $_) }
      $result, '$.games[*].start_time';

=head1 HISTORY

L<WWW::KGS::GameArchives> was renamed to C<WWW::GoKGS::Scraper::GameArchives>
(this module).
The return value of the C<scrape> method (C<$result>) was modified as follows:

  - Remove $result->{summary}
  - Rename $game->{kifu_uri} to $game->{sgf_uri}
  - Rename $game->{editor} to $game->{owner}
  - Remove $game->{setup}
  - Add $game->{board_size}
  - Add $game->{handicap}
  - $user->{name} does not end with a rank string such as "[2k]"
  - Add $user->{rank}
  - Rename $user->{link} to $user->{uri}

where C<$game> denotes an element of C<< $result->{games} >>
and  C<$user> denotes C<< $game->{owner} >>, an element of
C<< $game->{white} >> or an element of C<< $game->{black} >> respectively.

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
