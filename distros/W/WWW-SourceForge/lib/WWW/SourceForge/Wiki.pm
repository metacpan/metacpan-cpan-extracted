package WWW::SourceForge::Wiki;
use strict;
use warnings;
use WWW::SourceForge;
use WWW::SourceForge::Project;
use LWP::Simple qw();
use Data::Dumper;
use JSON::Parse;
use LWP::UserAgent;
use LWP::Authen::OAuth;
use HTTP::Request::Common;

our $VERSION = '0.02';
our $baseurl = 'https://sourceforge.net/rest/p/';

=head1 new

my $wiki = WWW::SourceForge::Wiki->new( project => 'newsgrowler' );
my $content = $wiki->get_page( page => 'Home' ); 

=cut

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless( {}, ref($class) || $class );

    my $proj_name = $parameters{project};

    my $proj_obj = WWW::SourceForge::Project->new( name => $proj_name );
    
    # Must be an Allura project for this to work
    if ( $proj_obj->type == 10 ) {

        # API URL
        $self->{url_prefix} = $baseurl . $proj_obj->shortdesc() . '/wiki/';
        return $self;

    } else {
        die("This doesn't work on Classic SF projects");
    }

}

=head1 list_pages

my $ref = $self->list_pages();

=cut
sub list_pages {
    my ( $self, %parameters ) = @_;
    my $url = $self->{url_prefix};
    return $self->get( url => $url );
}

=head1 get_page

my $ref = $self->get_page( page => 'Home' );

=cut
sub get_page {
    my ( $self, %parameters ) = @_;
    my $url = $self->{url_prefix} . $parameters{page};

   return $self->get( url => $url );
}

=head1 get

Fetch the JSON and parse it. Die on bad JSON;

=cut
sub get {
    my ( $self, %parameters ) = @_;
    my $r = {};

    my $json = LWP::Simple::get( $parameters{url} );
    eval { $r = JSON::Parse::json_to_perl( $json ); };
    if ( $@ ) {
        warn $@;
        return {};
    } else {
        return $r;
    }

}

=head1 post_page

$self->post_page(
    page   => 'NewPage',
    text   => 'Wiki page body goes here',
    labels => 'new,page,cool',
);

Must have ConsumerKey and ConsumerSecret set in ~/.sourceforge  See
https://sourceforge.net/auth/oauth/ to get one.

=cut
sub post_page {
    my ( $self, %parameters ) = @_;
    my $url = $self->{url_prefix} . $parameters{page};

    my %config = WWW::SourceForge::get_config();

    my $ua = LWP::Authen::OAuth->new(
        oauth_consumer_key    => $config{consumer_key},
        oauth_consumer_secret => $config{consumer_secret},
        oauth_token           => $config{oauth_token},
        oauth_token_secret    => $config{oauth_token_secret},
    );

    my $response = $ua->post(
        $url,
        [
            text   => $parameters{text},
            labels => $parameters{labels},
        ]
    );


    # I don't know why this isn't working, and could use help from
    # anyone with OAuth fu that can help me get it working.


    # TODO: Error Handling

    return ($response);

}

