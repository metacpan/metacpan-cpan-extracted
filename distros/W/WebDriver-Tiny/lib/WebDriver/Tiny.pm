package WebDriver::Tiny 0.006;

use 5.020;
use feature 'postderef';
use warnings;
no  warnings 'experimental::postderef';

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
    # From http://www.w3.org/TR/webdriver/#sendkeys
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
sub new {
    my ( $class, %args ) = @_;

    Carp::croak qq/$class - Missing required parameter "port"/
        unless exists $args{port};

    $args{host} //= 'localhost';
    $args{path} //= '';

    my $self = bless [
        # FIXME Keep alive can make PhantomJS return a 400 bad request :-S.
        HTTP::Tiny->new( keep_alive => 0 ),
        "http://$args{host}:$args{port}$args{path}/session",
        $args{base_url} // '',
    ], $class;

    my $reply = $self->_req(
        POST => '', { desiredCapabilities => $args{capabilities} // {} } );

    $self->[1] .= '/' . $reply->{sessionId};

    # Store the capabilities.
    $self->[3] = $reply->{value};

    # Numify bool objects, saves memory.
    $_ += 0 for grep ref eq 'JSON::PP::Boolean', values $self->[3]->%*;

    # See the overloading at the top of the file for details.
    Scalar::Util::weaken( my $weak_self = $self );
    $self->[4] = sub { $weak_self->find(@_) };

    $self;
}

sub capabilities { $_[0][3] }

sub source { $_[0]->_req( GET => '/source' )->{value} }
sub title  { $_[0]->_req( GET => '/title'  )->{value} }
sub url    { $_[0]->_req( GET => '/url'    )->{value} }

sub back       { $_[0]->_req( POST   => '/back'    ); $_[0] }
sub forward    { $_[0]->_req( POST   => '/forward' ); $_[0] }
sub refresh    { $_[0]->_req( POST   => '/refresh' ); $_[0] }

sub status {
    # /status is the only path without the session prefix, so surpress it.
    local $_[0][1] = substr $_[0][1], 0, rindex $_[0][1], '/session/';

    $_[0]->_req( GET => '/status' )->{value};
}

sub storage {
    my ( $self, $key, $value ) = @_;

    # Set a key.
    if ( @_ == 3 ) {
        my $ret = $self->_req(
            POST => '/local_storage', { key => $key, value => $value } );

        Carp::croak $ret->{value}{message} if $ret->{value}{message};

        $self;
    }
    # Get a key.
    elsif ( @_ == 2 ) {
        $self->_req( GET => "/local_storage/key/$key" )->{value};
    }
    # List all keys.
    else {
        my @keys = $self->_req( GET => '/local_storage' )->{value}->@*;

        return @keys if wantarray;

        +{ map {
            $_ => $self->_req( GET => "/local_storage/key/$_" )->{value}
        } @keys };
    }
}

sub accept_alert {
    $_[0]->_req( POST => '/accept_alert' ) if $_[0][3]{handlesAlerts};

    $_[0];
}

sub alert_text {
    $_[0][3]{handlesAlerts} ? $_[0]->_req( GET => '/alert_text' )->{value} : ();
}

sub dismiss_alert {
    $_[0]->_req( POST => '/dismiss_alert' ) if $_[0][3]{handlesAlerts};

    $_[0];
}

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

sub cookie_delete {
    my $self = shift;

    if (@_) {
        $self->_req( DELETE => "/cookie/$_" ) for @_;
    }
    else {
        $self->_req( DELETE => '/cookie' );
    }

    $self;
}

sub cookies {
    my @cookies = @{ $_[0]->_req( GET => '/cookie' )->{value} // [] };

    # Map the incorrect key to the correct key.
    $_->{httpOnly} //= delete $_->{httponly} for @cookies;

    +{ map { $_->{name} => $_ } @cookies };
}

# NOTE This method can be called from a driver or a collection of elements.
sub find {
    my ( $self, $selector, %args ) = @_;

    state $methods = {
        css               => 'css selector',
        ecmascript        => 'ecmascript',
        link_text         => 'link text',
        partial_link_text => 'partial link text',
        xpath             => 'xpath',
    };

    my $method = $methods->{ $args{method} // '' } // 'css selector';

    my $must_be_visible
        = $method eq 'css selector' && $selector =~ s/:visible$//;

    # FIXME
    my $drv = ref $self eq 'WebDriver::Tiny::Elements' ? $self->[0] : $self;

    my @ids;

    for ( 0 .. ( $args{tries} // 5 ) ) {
        my $reply = $self->_req(
            POST => '/elements',
            { using => $method, value => "$selector" },
        );

        my $type = ref $reply->{value};
        if ($type eq 'ARRAY') {
            @ids = map $_->{ELEMENT}, $reply->{value}->@*;
        }
        elsif ($type eq 'HASH') {
            Carp::croak ref $self, qq/->find failed: $reply->{value}{message}/;
        }
        else {
            Carp::croak ref $self, qq/->find failed: $reply->{value}/;
        }

        @ids = grep {
            $drv->_req( GET => "/element/$_/displayed" )->{value}
        } @ids if $must_be_visible;

        last if @ids;

        select undef, undef, undef, $args{sleep} // .1;
    }

    Carp::croak ref $self, qq/->find failed for $method = "$_[1]"/
        if !@ids && !exists $args{dies} && !$args{dies};

    wantarray ? map { bless [ $drv, $_ ], 'WebDriver::Tiny::Elements' } @ids
              : bless [ $drv, @ids ], 'WebDriver::Tiny::Elements';
}

my $js = sub {
    my ( $path, $self, $script, @args ) = @_;

    # Currently only takes the first ID in the collection, this should change.
    $_ = { ELEMENT => $_->[1] }
        for grep ref eq 'WebDriver::Tiny::Elements', @args;

    $self->_req( POST => $path, { script => $script, args => \@args } )
        ->{value};
};

sub js         { unshift @_, '/execute';         goto $js }
sub js_async   { unshift @_, '/execute_async';   goto $js }
sub js_phantom { unshift @_, '/phantom/execute'; goto $js }

sub get {
    my ( $self, $url ) = @_;

    $self->_req(
        POST => '/url',
        { url => $url =~ m(^https?://) ? $url : $self->[2] . $url },
    );

    $self;
}

# TODO make this handle elements too? Or make a new method?
sub screenshot {
    my ( $self, $file ) = @_;

    require MIME::Base64;

    my $data = MIME::Base64::decode_base64(
        $self->_req( GET => '/screenshot' )->{value}
    );

    if ( @_ == 2 ) {
        open my $fh, '>', $file or die $!;
        print $fh $data;
        close $fh or die $!;

        return $self;
    }

    $data;
}

sub user_agent { $js->( '/execute', $_[0], 'return window.navigator.userAgent') }

sub window  { $_[0]->_req( GET => '/window'         )->{value} }
sub windows { $_[0]->_req( GET => '/window_handles' )->{value} }

sub window_close      { $_[0]->_req( DELETE => '/window'            ); $_[0] }
sub window_fullscreen { $_[0]->_req( POST   => '/window/fullscreen' ); $_[0] }

sub window_maximize {
    $_[0]->_req( POST => '/window/' . ( $_[1] // 'current' ) . '/maximize' );

    $_[0];
}

sub window_position {
    my $self = shift;

    return @{
        $self->_req( GET => '/window/' . ( $_[0] // 'current' ) . '/position' )->{value}
    }{'x', 'y'} if @_ < 2;

    my ( $handle, $x, $y ) = @_ == 2 ? ( 'current', @_ ) : @_;

    $self->_req( POST => "/window/$handle/position", { 'x' => $x, 'y' => $y } );

    $self;
}

sub window_size {
    my $self = shift;

    return @{
        $self->_req( GET => '/window/' . ( $_[0] // 'current' ) . '/size' )->{value}
    }{qw/width height/} if @_ < 2;

    my ( $handle, $w, $h) = @_ == 2 ? ( 'current', @_ ) : @_;

    $self->_req( POST => "/window/$handle/size", { width => $w, height => $h } );

    $self;
}

sub window_switch {
    my ( $self, $handle ) = @_;

    $self->_req( POST => '/window', { name => $handle } );

    $self;
}

sub _req {
    my ( $self, $method, $path, $args ) = @_;

    my $reply = $self->[0]->request(
        $method,
        $self->[1] . $path,
        { content => JSON::PP::encode_json( $args // {} ) },
    );

    unless ( $reply->{success} ) {
        # Try to extract an error message from the reply. Yep nested JSON :-(
        my $error = eval {
            # FIXME We probably just want to tell JSON::PP not to decode.
            utf8::encode my $msg
                = JSON::PP::decode_json($reply->{content})->{value}{message};

            JSON::PP::decode_json($msg)->{errorMessage};
        };

        Carp::croak ref $self, ' - ', $error // $reply->{content};
    }

    JSON::PP::decode_json $reply->{content};
}

sub DESTROY { $_[0]->_req( DELETE => '' ) if $_[0][3] && $_[0][0] }

1;
