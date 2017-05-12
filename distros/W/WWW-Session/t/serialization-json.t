#!perl

use Test::More tests => 5;

use_ok('WWW::Session::Serialization::JSON');

my $serializer = WWW::Session::Serialization::JSON->new();

{
	my $test_data = {
		sid => 123,
		expires => 1234,
		data => {a => 1, b => 2},
	};
	
	my $string = $serializer->serialize($test_data);

	foreach (qw(sid expires data)) {
		like($string,qr/$_/,"$_ key saved");
	}
	
	my $data = $serializer->expand($string);
	
	is_deeply($data,$test_data,'Structure preserved');
}