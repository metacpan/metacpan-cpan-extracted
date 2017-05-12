package Test::File::Find::Rule::Helper;

use strict;
use Test::File::Find::Rule;
use File::Find::Rule::MMagic;
# see File::Find::Rule::Type (based on File::Type)
use Number::Compare;

use base qw(Exporter);
use vars qw(@EXPORT);

our $VERSION = '1.0';

@EXPORT = qw(sizes_ok sizes_magic_ok);

sub sizes_ok {
	my ($magic, $compare, $dir, $name) = @_;

	my $rule = File::Find::Rule
		->file
		->relative
		->name(ref($magic) ? @$magic : $magic)
		->size($compare);
	match_rule_no_result($rule, $dir, $name);
}

sub sizes_magic_ok {
	my ($magic, $compare, $dir, $name) = @_;

	my $rule = File::Find::Rule
		->file
		->relative
		->magic(ref($magic) ? @$magic : $magic)
		->size($compare);
	match_rule_no_result($rule, $dir, $name);
}

1;
