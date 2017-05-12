#!perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most tests => 5;
use Test::LWP::UserAgent;
use Const::Fast;
use HTTP::Response;
use HTTP::Status qw(:constants status_message);
use Path::Tiny;
use URI;
use URI::file;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::CompileX::Schema::Loader;

#use Log::Report mode => 'DEBUG';

const my $SERVICE_WSDL => 't/stockquote/stockquoteservice.wsdl';

my $user_agent = Test::LWP::UserAgent->new( network_fallback => 1 );
$user_agent->map_response( 'example.com' => \&examplecom_responder );
my $transport
    = XML::Compile::Transport::SOAPHTTP->new( user_agent => $user_agent );

my $wsdl   = XML::Compile::WSDL11->new;
my $loader = new_ok(
    'XML::CompileX::Schema::Loader' => [
        uris       => URI::file->new_abs($SERVICE_WSDL),
        user_agent => $user_agent,
        wsdl       => $wsdl,
    ],
    'stockquoteservice WSDL',
);
lives_and(
    sub {
        isa_ok( $loader->collect_imports,
            'XML::Compile::WSDL11' => 'collect_imports' );
    } => 'collect_imports',
);
lives_ok(
    sub { $wsdl->compileCalls( transport => $transport ) } =>
        'compileCalls' );

cmp_bag(
    [ keys %{ $wsdl->index } ],
    [qw(binding message port portType service)] => 'WSDL definition classes',
);
cmp_bag(
    [ map { $_->name } $wsdl->operations ],
    [qw(GetLastTradePrice)] => 'WSDL operations',
);

sub examplecom_responder {
    my $request = shift;

    my $path = $request->uri->path;
    $path =~ s(^/)();

    my $response = HTTP::Response->new( HTTP_OK => status_message(HTTP_OK) );
    $response->content( path( 't', $path )->slurp );
    return $response;
}
