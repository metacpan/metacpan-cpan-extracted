package XUL::tests::Assert;

use strict;
use warnings;
use Carp;
use Test::Class;
use Test::Builder;
use Test::More;
use XUL::Node::Server::NodeState;

use base 'Exporter';

our @EXPORT  = qw(is_xul is_xul_xml);

# TODO: check that +1 caller hack works with unhacked mods

sub is_xul ($$;$) {
	my ($actual, $expected, $name) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$expected = join'', map {
		s/_/ /g; # no spaces for easier testing
		XUL::Node::Server::NodeState::make_command(split /\./)
	} @$expected;

	is $actual, $expected, $name;
}

sub is_xul_xml ($$;$) {
	my ($subject, $expected, $name) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	chomp $expected;
	is $subject->as_xml, $expected, $name;
}

1;

