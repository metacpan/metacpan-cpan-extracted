package WebDriver::Tiny 0.102;

use 5.020;
use feature qw/lexical_subs postderef signatures/;
use warnings;
no  warnings 'experimental';

# https://www.w3.org/TR/webdriver/#elements
my sub ELEMENT_ID :prototype() {'element-6066-11e4-a52e-4f735466cecf'}

# Allow "cute" $drv->('selector') syntax.
#
# $self->[4] contains a sub ref that closes over a weakened $self that calls
# find, i.e. sub { $weak_self->find(@_) }. This sub ref is returned when $self
# is invoked as a sub ref thanks to the magic of overloading. We weaken to
# avoid a memory leak. The closure is built in new().
use overload fallback => 1, '&{}' => sub { $_[0][4] };

use Carp 1.25 ();
use HTTP::Tiny;
use JSON::PP ();
use WebDriver::Tiny::Elements;

our @CARP_NOT = 'WebDriver::Tiny::Elements';

sub import {
    # https://www.w3.org/TR/webdriver/#sendkeys
    state $chars = {
        WD_NULL            => 57344, WD_CANCEL     => 57345,
        WD_HELP            => 57346, WD_BACK_SPACE => 57347,
        WD_TAB             => 57348, WD_CLEAR      => 57349,
        WD_RETURN          => 57350, WD_ENTER      => 57351,
        WD_SHIFT           => 57352, WD_CONTROL    => 57353,
        WD_ALT             => 57354, WD_PAUSE      => 57355,
        WD_ESCAPE          => 57356, WD_SPACE      => 57357,
        WD_PAGE_UP         => 57358, WD_PAGE_DOWN  => 57359,
        WD_END             => 57360, WD_HOME       => 57361,
        WD_ARROW_LEFT      => 57362, WD_ARROW_UP   => 57363,
        WD_ARROW_RIGHT     => 57364, WD_ARROW_DOWN => 57365,
        WD_INSERT          => 57366, WD_DELETE     => 57367,
        WD_SEMICOLON       => 57368, WD_EQUALS     => 57369,
        WD_NUMPAD0         => 57370, WD_NUMPAD1    => 57371,
        WD_NUMPAD2         => 57372, WD_NUMPAD3    => 57373,
        WD_NUMPAD4         => 57374, WD_NUMPAD5    => 57375,
        WD_NUMPAD6         => 57376, WD_NUMPAD7    => 57377,
        WD_NUMPAD8         => 57378, WD_NUMPAD9    => 57379,
        WD_MULTIPLY        => 57380, WD_ADD        => 57381,
        WD_SEPARATOR       => 57382, WD_SUBTRACT   => 57383,
        WD_DECIMAL         => 57384, WD_DIVIDE     => 57385,
        WD_F1              => 57393, WD_F2         => 57394,
        WD_F3              => 57395, WD_F4         => 57396,
        WD_F5              => 57397, WD_F6         => 57398,
        WD_F7              => 57399, WD_F8         => 57400,
        WD_F9              => 57401, WD_F10        => 57402,
        WD_F11             => 57403, WD_F12        => 57404,
        WD_META            => 57405, WD_COMMAND    => 57405,
        WD_ZENKAKU_HANKAKU => 57408,
    };

    require charnames;

    charnames->import( ':alias' => $chars );
}

# We're a blessed arrayref (for speed) of the following parts:
#
# $self = [
#   0: HTTP::Tiny instance,
#   1: URL of the WebDriver daemon,
#   2: Base URL which schemeless get calls are based off,
#   3: The capabilities of the WebDriver daemon,
#   4: Cached closure of $self for ->() syntax,
# ]
sub new($class, %args) {
    Carp::croak qq/$class - Missing required parameter "port"/
        unless exists $args{port};

    $args{host} //= 'localhost';
    $args{path} //= '';

    my $self = bless [
        HTTP::Tiny->new,
        "http://$args{host}:$args{port}$args{path}/session",
        $args{base_url} // '',
    ], $class;

    my $reply = $self->_req(
        POST => '',
        { capabilities => { alwaysMatch => $args{capabilities} // {} } },
    );

    $self->[1] .= '/' . $reply->{sessionId};

    # Store the capabilities.
    $self->[3] = $reply->{capabilities};

    # Numify bool objects, saves memory.
    $_ += 0 for grep ref eq 'JSON::PP::Boolean', values $self->[3]->%*;

    # See the overloading at the top of the file for details.
    Scalar::Util::weaken( my $weak_self = $self );
    $self->[4] = sub { $weak_self->find(@_) };

    $self;
}

sub capabilities($self) { $self->[3] }

sub  html($self) { $self->_req( GET => '/source' ) }
sub title($self) { $self->_req( GET => '/title'  ) }
sub   url($self) { $self->_req( GET => '/url'    ) }

sub    back($self) { $self->_req( POST => '/back'    ); $self }
sub forward($self) { $self->_req( POST => '/forward' ); $self }
sub refresh($self) { $self->_req( POST => '/refresh' ); $self }

sub status {
    # /status is the only path without the session prefix, so surpress it.
    local $_[0][1] = substr $_[0][1], 0, rindex $_[0][1], '/session/';

    $_[0]->_req( GET => '/status' );
}

sub  alert_accept($self) { $self->_req( POST => '/alert/accept'  ); $self }
sub alert_dismiss($self) { $self->_req( POST => '/alert/dismiss' ); $self }

sub alert_text($self) { $self->_req( GET => '/alert/text' ) }

sub base_url {
    if ( @_ == 2 ) {
        $_[0][2] = $_[1] // '';

        return $_[0];
    }

    $_[0][2];
}

sub cookie {
    my ( $self, $name, $value, @args ) = @_;

    # GET /cookie/{name} isn't supported by ChromeDriver, so get all.
    return $self->cookies->{$name} if @_ == 2;

    $self->_req( POST => '/cookie',
        { cookie => { name => $name, value => $value, @args } } );

    $self;
}

sub cookie_delete($self, @cookies) {
    if (@cookies) {
        $self->_req( DELETE => "/cookie/$_" ) for @cookies;
    }
    else {
        $self->_req( DELETE => '/cookie' );
    }

    $self;
}

sub cookies {
    my @cookies = @{ $_[0]->_req( GET => '/cookie' ) // [] };

    # Map the incorrect key to the correct key.
    $_->{httpOnly} //= delete $_->{httponly} for @cookies;

    +{ map { $_->{name} => $_ } @cookies };
}

# NOTE This method can be called from a driver or a collection of elements.
sub find($self, $selector, %args) {
    state $methods = {
        css               => 'css selector',
        ecmascript        => 'ecmascript',
        link_text         => 'link text',
        partial_link_text => 'partial link text',
        xpath             => 'xpath',
    };

    my $method = $methods->{ $args{method} // '' } // 'css selector';

    # FIXME
    my $drv = ref $self eq 'WebDriver::Tiny::Elements' ? $self->[0] : $self;

    my @ids;

    for ( 0 .. ( $args{tries} // 5 ) ) {
        my $reply = $self->_req(
            POST => '/elements',
            { using => $method, value => "$selector" },
        );

        @ids = map $_->{+ELEMENT_ID}, @$reply;

        @ids = grep {
            $drv->_req( GET => "/element/$_/displayed" )
        } @ids if $args{visible};

        last if @ids;

        select undef, undef, undef, $args{sleep} // .1;
    }

    Carp::croak ref $self, qq/->find failed for $method = "$_[1]"/
        if !@ids && !exists $args{dies} && !$args{dies};

    wantarray ? map { bless [ $drv, $_ ], 'WebDriver::Tiny::Elements' } @ids
              : bless [ $drv, @ids ], 'WebDriver::Tiny::Elements';
}

my $js = sub($path, $self, $script, @args) {
    # Currently only takes the first ID in the collection, this should change.
    $_ = { ELEMENT_ID, $_->[1] }
        for grep ref eq 'WebDriver::Tiny::Elements', @args;
    $self->_req( POST => $path, { script => $script, args => \@args } );
};

sub js       { unshift @_, '/execute/sync';  goto $js }
sub js_async { unshift @_, '/execute/async'; goto $js }

sub get($self, $url) {
    $self->_req(
        POST => '/url',
        { url => $url =~ m(^https?://) ? $url : $self->[2] . $url },
    );

    $self;
}

sub screenshot($self, $file = undef) {
    require MIME::Base64;

    my $data = MIME::Base64::decode_base64(
        $self->_req( GET => '/screenshot' )
    );

    if ( defined $file ) {
        open my $fh, '>', $file or die $!;
        print $fh $data;
        close $fh or die $!;

        return $self;
    }

    $data;
}

sub user_agent($self) { $js->( '/execute/sync', $self, 'return window.navigator.userAgent') }

sub  window($self) { $self->_req( GET => '/window'         ) }
sub windows($self) { $self->_req( GET => '/window/handles' ) }

sub      window_close($self) { $self->_req( DELETE => '/window'            ); $self }
sub window_fullscreen($self) { $self->_req( POST   => '/window/fullscreen' ); $self }
sub   window_maximize($self) { $self->_req( POST   => '/window/maximize'   ); $self }
sub   window_minimize($self) { $self->_req( POST   => '/window/minimize'   ); $self }

sub window_rect {
    my $self = shift;

    return $self->_req( GET => '/window/rect' ) unless @_;

    $#_ = 3;

    my %args;
    @args{ qw/width height x y/ } = map $_ // 0, @_;

    $self->_req( POST => '/window/rect', \%args );

    $self;
}

sub window_switch($self, $handle) {
    $self->_req( POST => '/window', { handle => $handle } );

    $self;
}

sub _req($self, $method, $path, $args = undef) {
    my $reply = $self->[0]->request(
        $method,
        $self->[1] . $path,
        { content => JSON::PP::encode_json( $args // {} ) },
    );

    my $value = eval { JSON::PP::decode_json( $reply->{content} )->{value} };

    unless ( $reply->{success} ) {
        my $error = $value
            ? $value->{message} || $value->{error} || $reply->{content}
            : $reply->{content};

        Carp::croak ref $self, ' - ', $error;
    }

    $value;
}

sub DESTROY($self) { $self->_req( DELETE => '' ) if $self->[0] && $self->[3] }

1;
