use 5.010;
use Web::ID::SAN::Email;
use RDF::Trine;

my $san = Web::ID::SAN::Email->new(
	type     => 'rfc822Address',
	value    => 'somebody@fingerpoint.tobyinkster.co.uk',
	);

say $san->uri_object;

print RDF::Trine::Serializer
	-> new('Turtle')
	-> serialize_model_to_string( $san->model );
