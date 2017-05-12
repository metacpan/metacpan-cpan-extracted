package HTML::HTPL::Client;

BEGIN {
@EXPORT = qw($VERSION $VERSION_HEADER $RESPONSE_SIMPLE $RESPONSE_FREEZETHAW
        $RESPONSE_ERROR $RESPONSE_PREFIX $RESPONSE_ZLIB);
} 

use HTML::HTPL::Lib;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI::URL;
use strict vars;
use vars qw(@EXPORT @ISA);
use vars(@EXPORT);
use Exporter;
use Carp;

@ISA = qw(Exporter);

$VERSION = '1.00';
$VERSION_HEADER = 'X-HTPL-NET';
$RESPONSE_SIMPLE = 'scalar';
$RESPONSE_FREEZETHAW = 'freezethaw';
$RESPONSE_ERROR = 'error';
$RESPONSE_PREFIX = 'htpl-';
$RESPONSE_ZLIB = 'z-';

sub new {
    my $class = shift;
    my ($url, $user, $passwd, $key) = @_;
    unless ($url =~ m|://|) {
        $url = "http://$url/htpl/server.htpl";
    }
    my $self = {'url' => $url, 'user' => $user, 'passwd' => $passwd,
		'key' => $key};
    bless $self, $class;
}

sub get {
    my ($self, $call, $key) = @_;
    my $url = new URI::URL($self->{'url'});
    my $req = POST  $url, ['call' => $call];
    my $ua = new HTML::HTPL::Client::FooBar;
    $ua->initup($self->{'user'}, $self->{'passwd'});
    my $res = $ua->request($req);
    my $type = $res->content_type;
    my $head = $res->headers;
    my $var = $res->content;

    my ($super, $sub) = split("/", $type);
    Carp::croak("Wrong content type in response: $type\nContent: $var") unless ($super eq "application"
           && $sub =~ /^$RESPONSE_PREFIX/);
    $sub =~ s/^$RESPONSE_PREFIX($RESPONSE_ZLIB)/$RESPONSE_PREFIX/;
    if ($1) {
        require Compress::Zlib;
        my $zcmp = Compress::Zlib::inflateInit();
        $var = $zcmp->inflate($var);
    }
    Carp::croak("Remote error: $var") if ($sub eq "$RESPONSE_PREFIX$RESPONSE_ERROR");

    my $htplnet = $head->header($VERSION_HEADER);    
    Carp::croak("Server did not shake hands") unless ($htplnet);
    $key ||= $self->{'key'};
    if ($key) {
        die $@ if $@;
        unless ($key =~ /^(\w+?):(.*)$/) {
            die "Old cipher format obsolete. Must be: Algorithm:Key";
        }
        require Crypt::CBC;
        my $cipher = new Crypt::CBC($2, $1);
        $var = $cipher->decrypt($var);
    }
    return $var if ($sub eq "$RESPONSE_PREFIX$RESPONSE_SIMPLE");
    if ($sub eq "$RESPONSE_PREFIX$RESPONSE_FREEZETHAW") {
        require Storable;
        import Storable;
        my ($v) = thaw($var) ;
        return $v;
    }
    Carp::croak("Unknown response $sub");
}

package HTML::HTPL::Client::FooBar;
use LWP::UserAgent;
@HTML::HTPL::Client::FooBar::ISA = qw(LWP::UserAgent);

sub initup {
    my ($self, $u, $p) = @_;
    $self->{'username'} = $u;
    $self->{'password'} = $p;
}

sub get_basic_credentials
{
    my($self, $realm, $uri, $proxy) = @_;
    return if $proxy;
    return ($self->{'username'}, $self->{'password'});
}

1;
