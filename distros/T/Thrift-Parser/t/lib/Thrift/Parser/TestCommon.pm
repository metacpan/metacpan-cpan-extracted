package Thrift::Parser::TestCommon;

use strict;
use warnings;
use Test::More;
use base qw(Exporter);

our @EXPORT = qw(new_type_ok new_type new_field);

sub new_field (@) {
	return Thrift::Parser::Field->new({ @_ });
}

sub new_type_ok ($;$) {
	my ($type, $value) = @_;
	my $class = "Thrift::Parser::Type::$type";
	my $obj = $class->compose($value);
	isa_ok $obj, $class, "Created new $type";
	return $obj;
}

sub new_type ($;$) {
	my ($type, $value) = @_;
	my $class = "Thrift::Parser::Type::$type";
	return $class->compose($value);
}

1;
