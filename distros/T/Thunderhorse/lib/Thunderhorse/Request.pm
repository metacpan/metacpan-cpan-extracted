package Thunderhorse::Request;
$Thunderhorse::Request::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Gears::X::Thunderhorse;

extends 'PAGI::Request';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for response')
		unless $args{context};

	return $args{context}->pagi->@[0, 1];
}

sub update ($self)
{
	my $pagi = $self->context->pagi;
	$self->{scope} = $pagi->[0];
	$self->{receive} = $pagi->[1];
}

