package Thunderhorse::Module;
$Thunderhorse::Module::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::Component';

has param 'config' => (
	isa => HashRef,
);

has field 'methods' => (
	isa => HashRef,
	default => sub {
		{
			controller => {},
		}
	},
);

has field 'wrappers' => (
	isa => ArrayRef,
	default => sub { [] },
);

# register new methods for various areas
sub register ($self, $for, $name, $code)
{
	my $area = $self->methods->{$for};
	Gears::X::Thunderhorse->raise("bad area '$for'")
		unless defined $area;

	Gears::X::Thunderhorse->raise("symbol '$name' already exists in area '$for'")
		if exists $area->{$name};

	$area->{$name} = $code;
}

sub wrap ($self, $mw)
{
	push $self->wrappers->@*, $mw;
}

