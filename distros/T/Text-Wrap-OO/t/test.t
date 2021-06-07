#!/usr/bin/env perl

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use Scalar::Util qw(blessed reftype);
use List::Util qw(min first pairs);
use Text::Wrap::OO;
use Test::More;

my $text = <<'EOF';
This is the first paragraph. There isn't much interesting for you to
read here, it's just to test line wrapping. Honestly! Go read
something else.

Also, here are some explicit
line
breaks.

    This line is preceded by several spaces.
  This one's preceded by a different number of spaces.

Finally, here's one more fairly long paragraph to be filled. Here's
some more text to make it even longer. And some more, just for good
measure.
EOF

sub test_method {
    my %args = @_;

    my ($params, $method, $expected, $test_name) =
	@args{qw(params method expected name)};
    $params //= {};
    # Be consistent with fill() output.
    $expected =~ s/\n$/ / if $method eq 'fill';
    my @args = do {
	my $args = exists $args{args} ? $args{args} : $text;
	ref $args eq 'ARRAY' ? @$args : $args;
    };
    my @expected = do {
	my $tmp = Text::Wrap::OO->new(%$params);
	my $sep = first { defined } $tmp->separator2, $tmp->separator;
	die 'No separator defined' unless defined $sep;
	split $sep, $expected, -1;
    };

    my sub check_return (&$) {
	my ($code, $name) = @_;
	$name = "$method: $test_name: $name";
	is scalar $code->(), $expected, "$name: scalar context";
	is_deeply [$code->()], \@expected, "$name: list context";
    }

    # First test the method with a hash ref passed to the constructor.
    my $wrapper = Text::Wrap::OO->new($params);
    check_return { $wrapper->$method(@args) }
	'attrs set through hash ref arg';

    # With a hash passed to the constructor.
    $wrapper = Text::Wrap::OO->new(%$params);
    check_return { $wrapper->$method(@args) }
	'attrs set through hash arg';

    # With accessors used to set parameters.
    $wrapper = Text::Wrap::OO->new;
    while (my ($attr, $value) = each %$params) {
	$wrapper->$attr($value);
    }
    check_return { $wrapper->$method(@args) }
	'attrs set through accessors';
}

# Now perfom the actual tests.

my %functionality_test = (
    name	=> 'basic functionality',
    params	=> {
	columns		=> 50,
	init_tab	=> '>',
	subseq_tab	=> '>>>',
	separator2	=> "\n===\n",
    },
);

test_method
    %functionality_test,
    method	=> 'wrap',
    expected	=> <<'EOF';
>This is the first paragraph. There isn't much
===
>>>interesting for you to
>>>read here, it's just to test line wrapping.
===
>>>Honestly! Go read
>>>something else.
>>>
>>>Also, here are some explicit
>>>line
>>>breaks.
>>>
>>>    This line is preceded by several spaces.
>>>  This one's preceded by a different number of
===
>>>spaces.
>>>
>>>Finally, here's one more fairly long paragraph
===
>>>to be filled. Here's
>>>some more text to make it even longer. And
===
>>>some more, just for good
>>>measure.
EOF

test_method
    %functionality_test,
    method	=> 'fill',
    expected	=> <<'EOF';
>This is the first paragraph. There isn't much
===
>>>interesting for you to read here, it's just to
===
>>>test line wrapping. Honestly! Go read
===
>>>something else.
>Also, here are some explicit line breaks.
>This line is preceded by several spaces.
>This one's preceded by a different number of
===
>>>spaces.
>Finally, here's one more fairly long paragraph
===
>>>to be filled. Here's some more text to make it
===
>>>even longer. And some more, just for good
===
>>>measure.
EOF

{
    local $Text::Wrap::columns = 50;
    local $Text::Wrap::separator2 = "\n===\n";

    my $expected_with_sep = <<'EOF';
This is the first paragraph. There isn't much
===
interesting for you to read here, it's just to
===
test line wrapping. Honestly! Go read something
===
else.

Also, here are some explicit line breaks.

This line is preceded by several spaces.

This one's preceded by a different number of
===
spaces.

Finally, here's one more fairly long paragraph to
===
be filled. Here's some more text to make it even
===
longer. And some more, just for good measure.
EOF

    my $expected_without_sep = $expected_with_sep =~ s/\n===\n/\n/gr;

    test_method
	name		=> 'full inheritance',
	params		=> { inherit => 1 },
	method		=> 'fill',
	expected	=> $expected_with_sep;

    test_method
	name		=> 'partial inheritance',
	params		=> { inherit => [qw(columns)] },
	method		=> 'fill',
	expected	=> $expected_without_sep;
}

# Make sure each array in $got matches the corresponding regexp in
# $expected.
sub like_list {
    my ($got, $expected, $name) = @_;
    my $total = @$expected;
    cmp_ok scalar @$got, '==', $total, "$name: number is $total";
    for my $i (0 .. (min $#$got, $#$expected)) {
	my $num = $i + 1;
	like $got->[$i], $expected->[$i], "$name: $num of $total";
    }
}

# Trap errors and warnings, and check them against the expected
# values.
sub trap {
    my %args = @_;

    my $is_return;
    if (defined $args{return} && $args{return} eq 'object') {
	$is_return = \&isa_ok;
	$args{return} = 'Text::Wrap::OO';
    }
    else {
	$is_return = \&is;
    }

    my %values = (warnings => []);
    local $SIG{__WARN__} = sub { push @{$values{warnings}}, @_ };
    eval { $values{return} = $args{code}->(); 1 }
	or $values{error} = $@;

    $args{warnings} //= [];
    my $name = $args{name};
    foreach ([return	=> 'return value',	$is_return],
	     [error	=> 'error message',	\&like],
	     [warnings	=> 'warnings',		\&like_list]) {
	my ($what, $descr, $is) = @$_;
	defined (my $expect = $args{$what}) or $is = \&is;
	$is->($values{$what}, $expect, "$name: $descr");
    }
}

trap
    name	=> 'validity of attributes passed to constructor',
    error	=>
	qr/^Invalid attribute passed to constructor: 'foo'/,
    code	=> sub {
	Text::Wrap::OO->new(foo => 'bar');
    };

trap
    name	=> 'extra arguments passed to constructor',
    return	=> 'object',
    warnings	=> [qr/^Too many arguments passed to constructor/],
    code	=> sub {
	Text::Wrap::OO->new({}, 'foo');
    };

trap
    name	=> 'odd number of elements passed to constructor',
    return	=> 'object',
    warnings	=>
	[qr/^Odd number of elements passed to constructor/],
    code	=> sub {
	# Use separator2 as the extra argument, because undef is a
	# valid value for it.
	Text::Wrap::OO->new(columns => 50, 'separator2');
    };

my $expect_err = qr/\(in attribute 'columns'\)/;

trap
    name	=> 'constructor type checking',
    error	=> $expect_err,
    code	=> sub {
	Text::Wrap::OO->new(columns => 'foo');
    };

trap
    name	=> 'accessor error checking',
    error	=> $expect_err,
    code	=> sub {
	my $wrapper = Text::Wrap::OO->new;
	$wrapper->columns('foo');
	return 1;
    };

trap
    name	=> 'inheritance error checking',
    return	=> 'object',
    warnings	=> [
	map qr/^Invalid value for \$Text::Wrap::$_:/,
	    qw(columns huge columns),
    ],
    code	=> sub {
	my $wrapper = Text::Wrap::OO->new(inherit => 1);
	local $Text::Wrap::columns = 'foo';
	local $Text::Wrap::huge = 'bar';
	$wrapper->wrap('text');
	$wrapper->inherit([qw(columns)]);
	$wrapper->wrap('text');
	return $wrapper;
    };

trap
    name	=> 'namespace cleaning',
    error	=> qr/^Can't locate object method "carp"/,
    code	=> sub {
	Text::Wrap::OO->carp('This should not be carped');
	return 1;
    };

done_testing;
