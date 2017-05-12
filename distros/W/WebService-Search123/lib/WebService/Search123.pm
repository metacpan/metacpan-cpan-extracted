package WebService::Search123;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use URI;
use XML::LibXML;
use Time::HiRes qw(gettimeofday);

use WebService::Search123::Ad;

use constant HOSTNAME => 'cgi.search123.uk.com';
use constant PATH     => '/xmlfeed';

our $DEBUG => 0;

=head1 NAME

WebService::Search123 - Interface to the Search123 XML API.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.09';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

The Search123 XML API interface.

Configure the call with C<new()>, supplying your account details, keywords, etc. then calling C<ads> to make the actual call.

 use WebService::Search123;

 my $s123 = WebService::Search123->new( aid => 99999 );
 
 foreach my $ad ( $s123->ads )
 {
    print $ad->title;
    print $ad->description;
    print $ad->url->as_string;           # url is a URI object
    print $ad->display_url;              # probably not a valid URL
    print $ad->favicon_url->as_string;   # if available
 }


The list of ads returned with C<ads> is remembered, so only one call is made.

If options are changed with the methods below, the list will be cleared and re-requested when calling C<ads> again.

=cut

=head1 DESCRIPTION

Interface to the Search123 platform for searching for ads.

 use WebService::Search123;
 
 $WebService::Search123::DEBUG = 1;
 
 my $s123 = WebService::Search123->new(
     aid      => 10057,
     keyword  => 'ipod',
     per_page => 5,
     client   => {
         ip   => '88.208.204.52',
         ua   => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8)',
         ref  => 'http://www.ultimatejujitsu.com/jujitsu-for-beginners/',
     },
 );
 
 binmode STDOUT, ":encoding(UTF-8)";
 
 foreach my $ad ( $s123->ads )
 {
     print $ad->title . "\n";
 }

 # change the keyword and get new ads

 $s123->keyword( 'phone' );

 foreach my $ad ( $s123->ads ) { ... }

=cut

=head1 METHODS

=head2 Attributes

=head3 ua

 $s123->ua

The internal L<LWP::UserAgent> to use.

The default user-agent has an identifier string of 'WebService-Search123/$VERSION', where $VERSION is the version of this module.

=cut

has ua => ( is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new( agent => 'WebService-Search123/$VERSION' ) } );

=head3 secure

 $s123->secure( 1 );

Flag to indicate whether to use https or http (default).

=cut

has secure => ( is => 'rw', isa => 'Bool', default => 0, trigger => \&_reset );

=head3 aid

 $s123->aid( 99999 );

Your account ID with Search123.

=cut

has aid => ( is => 'rw', isa => 'Num', trigger => \&_reset );

=head3 keyword

The user-supplied keywords to search against.

 $s123->keyword( 'ipod' );

=cut

has keyword => ( is => 'rw', isa => 'Str', trigger => \&_reset );

=head3 per_page

The number of results requested.

 $s123->per_page( 5 );

=cut

has per_page => ( is => 'rw', isa => 'Int', default => 20, trigger => \&_reset );

=head3 ads

The returned list of ad objects based on the criteria supplied.

See L<WebService::Search123::Ad> for details on these objects.

 foreach my $ad ( $s123->ads ) { ... }

=cut

has _ads => (
    is      => 'rw',
    isa     => 'ArrayRef[WebService::Search123::Ad]',
    lazy    => 1,
    builder => '_build__ads',
    clearer => '_clear__ads',
    traits  => [ 'Array' ],
    handles => {
        ads     => 'elements',
        num_ads => 'count',
    },
);

=head3 client

A hash-reference containing details about your end-user, including IP address, user-agent string, and the page they're on to view the ads.

You should set this at construction time.

Set and get methods are available as C<set_client()> and C<get_client()>.

 $s123->set_client( ip => '127.0.0.1' );

 $s123->get_client( 'ua' );

=cut

has client => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    handles => {
        get_client => 'get',
        set_client => 'set',
    },
);

=head3 session

The session string/cookie to send with each request.

You should store this in a cookie and re-use it for 30 minutes as per the Search123 documentation.

 $s123->session

=cut

has session => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build_session', clearer => 'new_session', trigger => \&_reset );

sub _build_session
{
    my $self = shift;

    my $time = time;

    my $session = md5_hex( $self->aid . $self->get_client( 'ua' ) . $self->get_client( 'ip' ) . $time ) . '.' . $time;

    return $session;
}

has _type => ( is => 'rw', isa => 'Str', default => 'q', trigger => \&_reset );

has _uid => ( is => 'rw', isa => 'Str', default => 1 );

has _request => ( is => 'rw', isa => 'URI', clearer => '_clear__request' );

has _response => ( is => 'rw', isa => 'HTTP::Response', clearer => '_clear__response' );

=head3 request_time

How long the underlying HTTP API request took.

 $s123->request_time;

=cut

has request_time => ( is => 'rw', isa => 'Num' );

sub _reset
{
    my ( $self ) = @_;

    $self->_clear__request;
    $self->_clear__response;
    $self->_clear__ads;
}

sub _build__ads
{
    my ($self) = @_;

    my $uri = URI->new( ( $self->secure ? 'https' : 'http' ) . '://' . HOSTNAME . PATH );

    $uri->query_form( $uri->query_form, aid => $self->aid );

    $uri->query_form( $uri->query_form, query      => $self->keyword           ) if $self->keyword;
    $uri->query_form( $uri->query_form, type       => $self->_type             ) if $self->_type;
    $uri->query_form( $uri->query_form, uid        => $self->_uid              ) if $self->_uid;
    $uri->query_form( $uri->query_form, size       => $self->per_page          ) if $self->per_page;
    $uri->query_form( $uri->query_form, ip         => $self->get_client('ip')  ) if $self->get_client('ip');
    $uri->query_form( $uri->query_form, client_ref => $self->get_client('ref') ) if $self->get_client('ref');
    $uri->query_form( $uri->query_form, client_ua  => $self->get_client('ua')  ) if $self->get_client('ua');
    $uri->query_form( $uri->query_form, usid       => $self->session           ) if $self->session;

    $self->_request( $uri );

    warn $uri->as_string if $DEBUG;

    my $before = gettimeofday();

    $self->_response( $self->ua->get( $uri->as_string ) );

    $self->request_time( gettimeofday() - $before );

    warn $self->_response->code . ' ' . $self->_response->message if $DEBUG;

    warn $self->request_time . ' seconds' if $DEBUG;

    my @ads = ();

    if ( $self->_response->is_success )
    {
        my $content = $self->_response->decoded_content;

        my $dom = XML::LibXML->load_xml( string => $content );

        foreach my $node ( $dom->findnodes('/S123_SEARCH/RETURN/LISTING') )
        {
            my $ad = WebService::Search123::Ad->new(
                 title        => $node->findvalue('TITLE'),
                 description  => $node->findvalue('DESCRIPTION'),
                _url          => $node->findvalue('REDIRECT_URL'),
                 display_url  => $node->findvalue('SITE_URL'),
            );

            $ad->_favicon_url( $node->findvalue('FAVICON_URL') ) if $node->findvalue('FAVICON_URL');

            push @ads, $ad;
        }
    }

    warn scalar @ads . ' items' if $DEBUG;

    return \@ads;
}


__PACKAGE__->meta->make_immutable;


1;
