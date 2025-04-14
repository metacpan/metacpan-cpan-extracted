package Whelk::Schema::Definition::Null;
$Whelk::Schema::Definition::Null::VERSION = '1.04';
use Whelk::StrictBase 'Whelk::Schema::Definition';

sub openapi_dump
{
	my ($self, $openapi_obj, %hints) = @_;

	my $res = $self->SUPER::openapi_dump($openapi_obj, %hints);
	$res->{type} = 'null';

	return $res;
}

sub inhale
{
	return 'null' unless !defined pop();
	return undef;
}

sub exhale
{
	return undef;
}

1;

