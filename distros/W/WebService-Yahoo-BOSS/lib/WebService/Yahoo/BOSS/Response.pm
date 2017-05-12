package WebService::Yahoo::BOSS::Response;

=head1 NAME

WebService::Yahoo::BOSS::Response - Response class for Yahoo BOSS searches

=cut

use Moo;
use JSON::XS ();
use Data::Dumper;
use Module::Runtime qw(require_module);

has 'count'        => ( is => 'ro', required => 1 );
has 'start'        => ( is => 'ro', required => 1 );
has 'results'      => ( is => 'ro', required => 1 );
has 'totalresults' => ( is => 'ro', required => 0 ); # not provided by all services


sub parse {
    my ( $class, $content, $resultclass ) = @_;

    my $response = JSON::XS::decode_json($content);

    my $rc = $response->{bossresponse}->{responsecode};
    die "Boss response error $rc: " . Dumper($response)
        unless $rc == 200;

    require_module($resultclass);

    my $results = $resultclass->parse($response->{bossresponse});

    my $self = $class->new( %$results );

    return $self;
}

1;
