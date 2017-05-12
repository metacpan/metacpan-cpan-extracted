package WebService::CloudFlare::Host::Role::Response;
use Moose::Role;
use JSON;
use Data::Dumper;
use Moose::Util::TypeConstraints;

requires 'res_map';

sub BUILDARGS {
    my ( $class, $http ) = @_;
    
    die "HTTP Status " . $http->code . " returned, expected 200."
        unless $http->code == 200;

    my $json = decode_json( $http->content );
    my %map = $class->res_map;
    my $args = { __JSON__ => $json };

    %map = __PACKAGE__->add_map_defaults( %map );

    OUTER: for my $key ( keys %map ) {
        my ( @elems ) = split( ":", $map{$key} );
        my $tmp_json = $json;
        for my $elem ( @elems ) {
            next OUTER unless exists $tmp_json->{$elem};
            $tmp_json = $tmp_json->{$elem};
        }
        $args->{$key} = $tmp_json;
        #$self->$key($tmp_json);
    }
    return $args;
}

sub BUILD {
    my ( $self ) = @_;
    if ( $ENV{'CLOUDFLARE_TRACE'} ) {
        print STDERR "<<< BEGIN CLOUDFLARE TRACE >>>\n";
        print STDERR "\t-> API Response ($self)\n";
        print STDERR Dumper $self->__JSON__;
        print STDERR "<<< END   CLOUDFLARE TRACE >>>\n";
    }
    $self->unset_json;
}

# Oh, decode_json, how silly you can be.
subtype 'json_bool' => as 'Int';
coerce  'json_bool', from 'Object', via { $_ ? 1 : 0 };

has '__JSON__' => ( 
    is => 'ro', 
    required => 1, 
    clearer => 'unset_json' 
);

has [qw/ result action /] => ( is => 'rw', isa => 'Str', required => 1 );
has [qw/ msg code /]      => ( is => 'rw', isa => 'Str|Undef', required => 0 );

sub add_map_defaults {
    my ( $class, %map ) = @_;

    $map{'msg'}         = 'msg';
    $map{'action'}      = 'request:act',
    $map{'code'}        = 'err_code',
    $map{'result'}      = 'result',

    return %map;
}

1;
