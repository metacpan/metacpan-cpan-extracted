package Whelk::Schema::Definition::Empty;
$Whelk::Schema::Definition::Empty::VERSION = '0.02';
use Kelp::Base 'Whelk::Schema::Definition';

sub inhale
{
	my ($self, $value) = @_;
	return 'empty' if defined $value && length $value;
	return undef;
}

sub exhale
{
	return '';
}

sub empty
{
	return !!1;
}

1;

