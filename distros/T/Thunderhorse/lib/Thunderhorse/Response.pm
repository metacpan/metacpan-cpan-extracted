package Thunderhorse::Response;
$Thunderhorse::Response::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;

extends 'PAGI::Response';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for response')
		unless $args{context};

	return $args{context}->pagi->@[0, 2];
}

sub update ($self)
{
	my $pagi = $self->context->pagi;
	$self->{scope} = $pagi->[0];
	$self->{send} = $pagi->[2];
}

