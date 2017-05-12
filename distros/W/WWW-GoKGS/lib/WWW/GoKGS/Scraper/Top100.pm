package WWW::GoKGS::Scraper::Top100;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use WWW::GoKGS::Scraper::Declare;

sub base_uri { 'http://www.gokgs.com/top100.jsp' }

sub __build_scraper {
    my $self = shift;

    scraper {
        process '//table[@class="grid"]//following-sibling::tr',
                'players[]' => scraper {
                    process '//td[1]', 'position' => 'TEXT';
                    process '//td[2]/a', 'name' => 'TEXT',
                                         'uri' => '@href';
                    process '//td[3]', 'rank' => 'TEXT'; };
    };
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::Top100 - Top 100 KGS Players

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::Top100;
  my $top_100 = WWW::GoKGS::Scraper::Top100->new;
  my $result = $top_100->query;

=head1 DESCRIPTION

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 CLASS METHODS

=over 4

=item $uri = $class->base_uri

  # => "http://www.gokgs.com/top100.jsp"

=item $URI = $class->build_uri

  # => URI->new( "http://www.gokgs.com/top100.jsp" )

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $top_100->user_agent

=item $top_100->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $HashRef = $top_100->query

Returns a hash reference which contains the top 100 KGS players.
The hashref is formatted as follows:

  {
      players => [
          {
              position => 1,
              name     => 'foo',
              rank     => '9d',
              uri      => '/graphPage.jsp?user=foo'
          },
          {
              position => 2,
              name     => 'bar',
              rank     => '9d',
              uri      => '/graphPage.jsp?user=bar'
          },
          ...
          {
              position => 100,
              name     => 'baz',
              rank     => '6d',
              uri      => '/graphPage.jsp?user=baz'
          }
      ]
  }

=item $HashRef = $top_100->scrape( URI->new(...) )

=item $HashRef = $top_100->scrape( HTTP::Response->new(...) )

=item $HashRef = $top_100->scrape( $html[, $base_uri] )

=item $HashRef = $top_100->scrape( \$html[, $base_uri] )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
