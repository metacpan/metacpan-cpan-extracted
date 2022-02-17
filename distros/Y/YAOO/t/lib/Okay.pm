package Okay;

use YAOO;

extends Test;

require_has qw/one two three/;

require_sub qw/before_method/;

has six => rw, isa(string);

has seven => rw, isa(string);

method testing => sub {
	return "okay";
};

1;
