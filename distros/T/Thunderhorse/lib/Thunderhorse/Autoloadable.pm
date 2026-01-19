package Thunderhorse::Autoloadable;
$Thunderhorse::Autoloadable::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard, -role;

requires qw(
	_run_method
	_can_method
);

sub AUTOLOAD ($self, @args)
{
	our $AUTOLOAD;

	state %methods;
	my $method = $methods{$AUTOLOAD} //= do {
		my $wanted = $AUTOLOAD =~ s{^(.+)::}{}r;
		return if $wanted eq 'DESTROY';
		$wanted;
	};

	$self->_run_method($method, @args);
}

sub can ($self, $method)
{
	my $I_can = $self->SUPER::can($method);
	return $I_can if $I_can;

	return undef unless ref $self;
	return $self->_can_method($method);
}

