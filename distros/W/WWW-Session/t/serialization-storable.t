#!perl

use Test::More tests => 2;

use_ok('WWW::Session::Serialization::Storable');

my $serializer = WWW::Session::Serialization::Storable->new();

{
	my $test_data = {
		sid => 123,
		expires => 1234,
		data => {a => 1, b => 2,
				 user => WWW::Session::MockObject->new(1),
				},
	};
	
	my $string = $serializer->serialize($test_data);
	
	my $data = $serializer->expand($string);
	
	is_deeply($data,$test_data,'Structure preserved');
}


package WWW::Session::MockObject;

sub new {
	my ($class,$id) = @_;
	
	my %data = (
		1 => { a=>1, b=>2},
		2 => { a=>3, b=>4},
	);

	my $self = {
				id => $id,
				data => $data{$id},
	};
	
	bless $self, $class;
		
	return $self;
}
	
sub id { return $_[0]->{id} }
sub a { return $_[0]->{data}->{a} }
sub b { return $_[0]->{data}->{b} }

1;