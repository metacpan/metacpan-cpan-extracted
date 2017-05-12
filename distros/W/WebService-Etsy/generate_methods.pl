use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

my $ua = LWP::UserAgent->new;

my $api_key = shift @ARGV;
if ( ! defined $api_key ) {
    print STDERR "No API key supplied\n";
    exit 0;
}
my $resp = $ua->get( 'http://openapi.etsy.com/v2/sandbox/public/?api_key=' . $api_key );
if ( ! $resp->is_success ) {
    print STDERR "Error getting method table: " . $resp->status_line . "\n";
    exit 0;
}

my $method_response = from_json $resp->content;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

print qq(
package WebService::Etsy::Methods;
use strict;
use warnings;
);

my %seen;
for my $method ( @{ $method_response->{ results } } ) {
    my $name = $method->{ name };
    next if $seen{$name};
    $seen{$name} = 1;
    my $uri  = $method->{ uri };
    my $type = $method->{ type };
    my $visibility = $method->{ visibility };
    my $description = $method->{ description };
    my $http_method = $method->{ http_method };
    my $params = $method->{ params };
    $params = ( $params ) ? Dumper( $params ) : '{}';
    my $defaults = $method->{ defaults };
    $defaults = ( $defaults ) ? Dumper( $defaults ) : '{}';
    print qq(
sub $name {
    my \$self = shift;
    my \$info = {
        name => '$name',
        uri  => '$uri',
        type => '$type',
        params => $params,
        visibility => '$visibility',
        http_method => '$http_method',
        defaults => $defaults,
        description => "$description",
    };
    return \$self->_call_method( \$info, \@_ );
}
);
}
print "\n1;\n";
