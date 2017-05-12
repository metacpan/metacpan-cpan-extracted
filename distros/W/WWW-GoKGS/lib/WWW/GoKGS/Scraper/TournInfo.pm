package WWW::GoKGS::Scraper::TournInfo;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use WWW::GoKGS::Scraper::Declare;
use WWW::GoKGS::Scraper::TournLinks;

sub base_uri { 'http://www.gokgs.com/tournInfo.jsp' }

sub __build_scraper {
    my $self = shift;
    my $links = $self->__build_tourn_links;

    scraper {
        process '//h1', 'name' => [ 'TEXT', sub { s/\s+\([^)]+\)$// } ],
                        'notes' => [ 'TEXT', sub { m/\s+\(([^)]+)\)$/ && $1 } ];
        process '//a[@href="tzList.jsp"]', 'time_zone' => 'TEXT';
        process '//node()[preceding-sibling::h1 and following-sibling::div]',
                'description[]' => sub { $_[0]->as_XML };
        process '//div[@class="tournData"]', 'links' => $links; 
    };
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    if ( exists $result->{description} ) {
        $result->{description} = join q{}, @{$result->{description}};
    }

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::TournInfo - Information for the KGS tournament

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::TournInfo;

  my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new;

  my $result = $tourn_info->query(
      id => 762
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     notes => 'Winner: foo',
  #     description => 'Welcome to the KGS Meijin October Qualifier! ...',
  #     links => {
  #         entrants => [
  #             {
  #                 sort_by => 'name',
  #                 uri     => '/tournEntrants.jsp?id=762&sort=n'
  #             },
  #             {
  #                 sort_by => 'result',
  #                 uri     => '/tournEntrants.jsp?id=762&sort=s'
  #             }
  #         ],
  #         rounds => [
  #             {
  #                 round      => 1,
  #                 start_time => '2012-10-27T16:05',
  #                 end_time   => '2012-10-27T18:35',
  #                 uri        => '/tournGames.jsp?id=762&round=1'
  #             },
  #             ...
  #         ]
  #     }
  # }

=head1 DESCRIPTION

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 CLASS METHODS

=over 4

=item $uri = $class->base_uri

  # => "http://www.gokgs.com/tournInfo.jsp"

=item $URI = $class->build_uri( $k1 => $v1, $k2 => $v2, ... )

=item $URI = $class->build_uri({ $k1 => $v1, $k2 => $v2, ... })

=item $URI = $class->build_uri([ $k1 => $v1, $k2 => $v2, ... ])

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the paramters.

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $tourn_info->user_agent

=item $tourn_info->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $HashRef = $tourn_info->scrape( URI->new(...) )

=item $HashRef = $tourn_info->scrape( HTTP::Response->new(...) )

=item $HashRef = $tourn_info->scrape( $html[, $base_uri] )

=item $HashRef = $tourn_info->scrape( \$html[, $base_uri] )

=item $HashRef = $tourn_info->query( id => $tourn_id )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
