package Test::Spy::Observer;
$Test::Spy::Observer::VERSION = '0.004';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Carp qw(croak);

has param 'method_name';

has field 'call_history' => (
	clearer => -hidden,
	lazy => sub { [] },
);

with qw(Test::Spy::Interface);

sub _called
{
	my ($self, $inner_self, @params) = @_;

	push @{$self->call_history}, [@params];
}

1;

