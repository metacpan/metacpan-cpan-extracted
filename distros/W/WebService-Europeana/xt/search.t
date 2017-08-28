use Test::More;
use Data::Dumper;
use Log::Any::Adapter;
use Log::Any::Adapter::Screen;

Log::Any::Adapter->set('Screen',
     min_level => 'debug', 
     stderr    => 0, # print to STDOUT instead of the default STDERR
    
);

plan skip_all => "environment variable \$WSKEY not set!" unless ($ENV{WSKEY});


use_ok( 'WebService::Europeana' );



diag( "Testing WebService::Europeana $WebService::Europeana::VERSION" );



my $Europeana = WebService::Europeana->new(wskey=>$ENV{WSKEY});

my $result = $Europeana->search(query=>"Österreich", rows=>1, profile=>"minimal", reusability=>"open");

is($result->{success},1,"Search successful");
is($result->{itemsCount},1,"Correct number of rows returned");

$result = $Europeana->search(query=>"where:asdfasdf", rows=>1);

is($result->{success},1,"Search for non-existant place successful");
is($result->{itemsCount},0,"Zero rows returned");

#print Dumper($result);

done_testing;
