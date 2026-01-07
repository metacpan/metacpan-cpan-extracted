package Thunderhorse::SSE;
$Thunderhorse::SSE::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Gears::X::Thunderhorse;

extends 'PAGI::SSE';
with 'Thunderhorse::Message';

sub FOREIGNBUILDARGS ($class, %args)
{
	Gears::X::Thunderhorse->raise('no context for sse')
		unless $args{context};

	return $args{context}->pagi->@*;
}

sub update ($self)
{
	my $pagi = $self->context->pagi;
	$self->{scope} = $pagi->[0];
	$self->{receive} = $pagi->[1];
	$self->{send} = $pagi->[2];
}

