package WWW::GoKGS;
use 5.008_009;
use strict;
use warnings;
use Carp qw/croak/;
use HTML::TreeBuilder::XPath;
use LWP::RobotUA;
use URI;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournList;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournEntrants;
use WWW::GoKGS::Scraper::TournGames;
use WWW::GoKGS::Scraper::TzList;

our $VERSION = '0.21';

sub _tree_builder_class { 'HTML::TreeBuilder::XPath' }

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless {}, $class;

    for my $key (qw/user_agent/) {
        $self->{$key} = $args{$key} if exists $args{$key};
    }

    $self->init( \%args );

    $self;
}

sub init {
    my ( $self, $args ) = @_;

    unless ( exists $self->{user_agent} ) {
        my $class = ref $self;

        $self->user_agent(
            LWP::RobotUA->new(
                agent => $args->{agent} || "$class/" . $class->VERSION,
                from => $args->{from},
                cookie_jar => $args->{cookie_jar},
            )
        );
    }

    return;
}

sub user_agent {
    my $self = shift;
    $self->{user_agent} = shift if @_;
    $self->{user_agent};
}

sub agent {
    my ( $self, @args ) = @_;
    $self->user_agent->agent( @args );
}

sub from {
    my ( $self, @args ) = @_;
    $self->user_agent->default_header( 'From', @args );
}

sub cookie_jar {
    my ( $self, @args ) = @_;
    $self->user_agent->cookie_jar( @args );
}

sub get {
    my ( $self, @args ) = @_;
    $self->user_agent->get( @args );
}

sub _scrapers {
    my $self = shift;
    $self->{_scrapers} ||= $self->__build_scrapers;
}

BEGIN { # install scrapers
    my %scrapers = (
        game_archives  => 'WWW::GoKGS::Scraper::GameArchives',
        top_100        => 'WWW::GoKGS::Scraper::Top100',
        tourn_list     => 'WWW::GoKGS::Scraper::TournList',
        tourn_info     => 'WWW::GoKGS::Scraper::TournInfo',
        tourn_entrants => 'WWW::GoKGS::Scraper::TournEntrants',
        tourn_games    => 'WWW::GoKGS::Scraper::TournGames',
        tz_list        => 'WWW::GoKGS::Scraper::TzList',
    );

    my %paths;
    while ( my ($method, $class) = each %scrapers ) {
        my $path = $paths{$class} = $class->build_uri->path;
        my $body = sub { $_[0]->get_scraper($path) };
        no strict 'refs';
        *$method = $body;
    }

    sub __build_scrapers {
        my $self = shift;
        my $class = ref $self;

        my %_scrapers;
        while ( my ($scraper, $path) = each %paths ) {
            $_scrapers{$path} = $scraper->new(
                _tree_builder_class => $class->_tree_builder_class,
                user_agent => $self->user_agent,
            );
        }

        \%_scrapers;
    }
}

sub get_scraper {
    my ( $self, $path ) = @_;
    $self->_scrapers->{$path};
}

sub each_scraper {
    my ( $self, $code ) = @_;
    my %scrapers = %{ $self->_scrapers };

    croak 'Not a CODE reference' unless ref $code eq 'CODE';

    while ( my ($path, $scraper) = each %scrapers ) {
        $code->( $path => $scraper );
    }

    return;
}

sub can_scrape {
    my $self = shift;
    my $uri = $self->_build_uri( shift );
    my $path = $uri =~ m{^http://www\.gokgs\.com(?::80)?/} && $uri->path;
    $path ? $self->get_scraper( $path ) : undef;
}

sub scrape {
    my ( $self, $arg ) = @_;
    my $uri = $self->_build_uri( $arg );
    my $scraper = $self->can_scrape( $uri );
    croak "Don't know how to scrape '$arg'" unless $scraper;
    $scraper->scrape( $self->get($uri), $uri );
}

sub _build_uri {
    my $self = shift;
    my $uri = URI->new( shift );
    $uri->scheme( 'http' ) unless $uri->scheme;
    $uri->authority( 'www.gokgs.com' ) unless $uri->authority;
    $uri;
}

1;

__END__

=head1 NAME

WWW::GoKGS - KGS Go Server (http://www.gokgs.com/) Scraper

=head1 SYNOPSIS

  use WWW::GoKGS;

  my $gokgs = WWW::GoKGS->new(
      from => 'user@example.com'
  );

  # Game archives
  my $game_archives_1 = $gokgs->scrape( '/gameArchives.jsp?user=foo' );
  my $game_archives_2 = $gokgs->game_archives->query( user => 'foo' );

  # Top 100 players
  my $top_100_1 = $gokgs->scrape( '/top100.jsp' );
  my $top_100_2 = $gokgs->top_100->query;

  # List of tournaments 
  my $tourn_list_1 = $gokgs->scrape( '/tournList.jsp?year=2014' );
  my $tourn_list_2 = $gokgs->tourn_list->query( year => 2014 );

  # Information for the tournament
  my $tourn_info_1 = $gokgs->scrape( '/tournInfo.jsp?id=123' );
  my $tourn_info_2 = $gokgs->tourn_info->query( id => 123 );

  # The tournament entrants
  my $tourn_entrants_1 = $gokgs->scrape( '/tournEntrans.jsp?id=123&sort=n' );
  my $tourn_entrants_2 = $gokgs->tourn_entrants->query( id => 123, sort => 'n' );

  # The tournament games
  my $tourn_games_1 = $gokgs->scrape( '/tournGames.jsp?id=123&round=1' );
  my $tourn_games_2 = $gokgs->tourn_games->query( id => 123, round => 1 );

  # List of time zones
  my $tz_list_1 = $gokgs->scrape( '/tzList.jsp' );
  my $tz_list_2 = $gokgs->tz_list->query;

=head1 DESCRIPTION

This module is a KGS Go Server (C<http://www.gokgs.com/>) scraper.
KGS allows the users to play a board game called go a.k.a. baduk (Korean)
or weiqi (Chinese). Although the web server provides resources generated
dynamically, such as Game Archives, they are formatted as HTML,
the only format. This module provides yet another representation of those
resources, Perl data structure.

This class maps a URI preceded by C<http://www.gokgs.com/>
to a proper scraper. The supported resources on KGS are as follows:

=over 4

=item KGS Game Archives (http://www.gokgs.com/archives.jsp)

Handled by L<WWW::GoKGS::Scraper::GameArchives>.

=item Top 100 KGS Players (http://www.gokgs.com/top100.jsp)

Handled by L<WWW::GoKGS::Scraper::Top100>.

=item KGS Tournaments (http://www.gokgs.com/tournList.jsp)

Handled by L<WWW::GoKGS::Scraper::TournList>,
L<WWW::GoKGS::Scraper::TournInfo>,
L<WWW::GoKGS::Scraper::TournEntrants> and
L<WWW::GoKGS::Scraper::TournGames>.

=item KGS Time Zone Selector (http://www.gokgs.com/tzList.jsp)

Handled by L<WWW::GoKGS::Scraper::TzList>.

=back

=head2 ATTRIBUTES

=over 4

=item $UserAgent = $gokgs->user_agent

=item $gokgs->user_agent( LWP::RoboUA->new(...) )

Can be used to get or set a user agent object which is used to C<GET>
the requested resource. Defaults to L<LWP::RobotUA> object which consults
C<http://www.gokgs.com/robots.txt> before sending HTTP requests,
and also sets a proper delay between requests.

NOTE: C<LWP::RobotUA> fails to read C</robots.txt>
since the KGS web server doesn't returns the Content-Type response header
as of June 23rd, 2014. This module can not solve this problem.

You can also set your own user agent object which inherits from
L<LWP::UserAgent> as follows:

  use LWP::UserAgent;

  $gokgs->user_agent(
      LWP::UserAgent->new(
          agent => 'MyAgent/1.00'
      )
  );

NOTE: You should set a delay between requests to avoid overloading
the KGS server.

=item $GameArchives = $gokgs->game_archives

Returns a L<WWW::GoKGS::Scraper::GameArchives> object.

=item $Top100 = $gokgs->top_100

Returns to a L<WWW::GoKGS::Scraper::Top100> object.

=item $TournList = $gokgs->tourn_list

Returns a L<WWW::GoKGS::Scraper::TournList> object.

=item $TournInfo = $gokgs->tourn_info

Returns a L<WWW::GoKGS::Scraper::TournInfo> object.

=item $TournEntrants = $gokgs->tourn_entrants

Returns a L<WWW::GoKGS::Scraper::TournEntrants> object.

=item $TournGames = $gokgs->tourn_games

Returns a L<WWW::GoKGS::Scraper::TournGames> object.

=item $TzList = $gokgs->tz_list

Returns a L<WWW::GoKGS::Scraper::TzList> object.

=back

=head2 INSTANCE METHODS

=over 4

=item $email_address = $gokgs->from

=item $gokgs->from( 'user@example.com' )

Can be used to get or set your email address which is used to send
the From request header that indicates who is making the request.

=item $agent = $gokgs->agent

=item $gokgs->agent( 'MyAgent/0.01' )

Can be used to get or set the product token that is used to send
the User-Agent request header.

=item $Response = $gokgs->get( URI->new(...) )

A shortcut for:

  my $response = $gokgs->user_agent->get( URI->new(...) );

This method is used by C<scrape> method to C<GET> the requested resource.
You can override this method by subclassing.

=item $cookie_jar = $gokgs->cookie_jar

=item $gokgs->cookie_jar( $cookie_jar_obj )

Can be used to get or set a cookie jar object to use.

=item $scraper = $gokgs->can_scrape( '/fooBar.jsp' )

=item $scraper = $gokgs->can_scrape( 'http://www.gokgs.com/fooBar.jsp' )

Returns a scraper object which can C<scrape> the resource specified
by the given URL. If the scraper object does not exist, then C<undef>
is returned. This method can be used to check whether C<$gokgs> can C<scrape>
the resource.

=item $HashRef = $gokgs->scrape( '/gameArchives.jsp?user=foo' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/gameArchives.jsp?user=foo' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/gameArchives.jsp?user=foo' );
  my $game_archives = $gokgs->game_archives->scrape( $uri );

See L<WWW::GoKGS::Scraper::GameArchives> for details.

=item $HashRef = $gokgs->scrape( '/top100.jsp' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/top100.jsp' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/top100.jsp' );
  my $top_100 = $gokgs->top_100->scrape( $uri );

See L<WWW::GoKGS::Scraper::Top100> for details.

=item $HashRef = $gokgs->scrape( '/tournList.jsp?year=2014' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournList.jsp?year=2014' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournList.jsp?year=2014' );
  my $tourn_list = $gokgs->tourn_list->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournList> for details.

=item $HashRef = $gokgs->scrape( '/tournInfo.jsp?id=123' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournInfo.jsp?id=123' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournInfo.jsp?id=123' );
  my $tourn_info = $gokgs->tourn_info->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournInfo> for details.

=item $HashRef = $gokgs->scrape( '/tournEntrants.jsp?id=123&s=n' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournEntrants.jsp?id=123&s=n' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournEntrants.jsp?id=123&s=n' );
  my $tourn_entrants = $gokgs->tourn_entrants->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournEntrants> for details.

=item $HashRef = $gokgs->scrape( '/tournGames.jsp?id=123&round=1' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournGames.jsp?id=123&round=1' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournGames.jsp?id=123&round=1' );
  my $tourn_games = $gokgs->tourn_games->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournGames> for details.

=item $HashRef = $gokgs->scrape( '/tzList.jsp' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tzList.jsp' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tzList.jsp' );
  my $tz_list = $gokgs->tz_list->scrape( $uri );

See L<WWW::GoKGS::Scraper::TzList> for details.

=item $scraper = $gokgs->get_scraper( $path )

Returns a scraper object which can C<scrape> a resource located at C<$path>
on KGS. If the scraper object does not exist, then C<undef> is returned.

  my $game_archives = $gokgs->get_scraper( '/gameArchives.jsp' );
  # => WWW::GoKGS::Scraper::GameArchives object

=item $gokgs->each_scraper( sub { my ($path, $scraper) = @_; ... } )

Given a subref, applies the subroutine to each scraper object in turn.
The callback routine is called with two parameters; the path to the resource
on KGS and the scraper object which can scrape the resource.

  $gokgs->each_scraper(sub {
      my $path = shift; # => "/gameArchives.jsp"
      my $scraper = shift; # isa WWW::GoKGS::Scraper::GameArchives

      # overwrite "user_agent" attributes of all the scraper objects
      $scraper->user_agent( $gokgs->user_agent );
  });


=back

=head1 DIAGNOSTICS

This module throws the following exceptions:

=over 4

=item LWP::RobotUA from required

This message is printed by the constructor of L<LWP::RobotUA>.
You must provide your email address when you use the module.

  my $gokgs = WWW::GoKGS->new(
      from => 'user@example.com'
  );

=item Don't know how to scrape '/fooBar.jsp'

You tried to C<scrape> a resource which C<$gokgs> can't handle.
Use C<can_scrape> before invoke the C<scrape> method.

  # scrape safely
  if ( $gokgs->can_scrape('/fooBar.jsp') ) {
      my $result = $gokgs->scrape('/fooBar.jsp');
  }

=item GET /fooBar.jsp failed: ...

C<$gokgs> failed to C<GET> the requested resource.
The reason phrase is added to the end of the message.

=back

=head1 LIMITATIONS

Although KGS website allows you to set a locale and time zone
by using HTTP cookie, this module ignores the settings.
The scrapers assume the locale is set to C<en_US>, and the time zone C<GMT>.

  # not supported
  $gokgs->user_agent->cookie_jar(...);

=head1 ENVIRONMENTAL VARIABLES

=over 4

=item AUTHOR_TESTING

Some tests for scrapers send HTTP requests to C<GET> resources on KGS.
When you run C<./Build test>, they are skipped by default
to avoid overloading the KGS server. To run those tests,
you have to set C<AUTHOR_TESTING> to true explicitly:

  $ perl Build.PL
  $ env AUTHOR_TESTING=1 ./Build test

Author tests are run by L<Travis CI|https://travis-ci.org/anazawa/p5-WWW-GoKGS>
once a day. You can visit the website to check whether the tests passed or not.

=back

=head1 ACKNOWLEDGEMENT

Thanks to wms, the author of KGS Go Server, we can enjoy playing go online
for free.

=head1 SEE ALSO

L<KGS Go Server|http://www.gokgs.com>, L<Web::Scraper>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
