#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 19;

use Try::Tiny::ByClass;
use IO::Handle ();

{
	my $val;
	my $x = try {
		die "asdf";
	} catch_case [
		':str' => sub { 42 },
	], finally {
		$val = 'xyzzy';
	};
	is $x, 42;
	is $val, 'xyzzy';
}

{
	package DummyClass;
	sub new { bless {}, $_[0] }
	sub subclass {
		my $class = shift;
		for my $subclass (@_) {
			no strict 'refs';
			push @{$subclass . '::ISA'}, $class;
		}
	}
}

DummyClass->subclass(qw(Some::Class Other::Class));

{
	my @catch_case = catch_case [
		'Some::Class'  => sub { 1 },
		'Other::Class' => sub { 2 },
		'UNIVERSAL'    => sub { "???" },
	];
	is +(try { die Other::Class->new } @catch_case), 2;
	is +(try { die IO::Handle->new } @catch_case), "???";
	is +(
		try {
			try { die ["not an object"] } @catch_case;
			ok 0;
		} catch {
			is_deeply $_, ["not an object"];
			'k'
		}
	), 'k';
}

DummyClass->subclass(qw(Mammal Tree));
Mammal->subclass(qw(Dog Bunny));
Dog->subclass(qw(Dog::Tiny Barky Setter));
Tree->subclass(qw(Barky));

my @trace;

my @catches = catch_case [
	map {
		my $class = $_;
		$_ => sub {
			push @trace, $class;
			return $class, $_[0];
		}
	} qw(
		Tree
		Dog::Tiny
		Dog
		ARRAY
		Mammal
		:str
		HASH
		*
	)
];

my @prep = (
	'Tree' => Tree->new,
	'Mammal' => Mammal->new,
	'Dog' => Dog->new,
	'Mammal' => Bunny->new,
	'Dog::Tiny' => Dog::Tiny->new,
	'Tree' => Barky->new,
	'Dog' => Setter->new,
	'ARRAY' => [1, 2, 3],
	'HASH' => {A => 'b'},
	':str' => "foo bar\n",
	':str' => "5\n",
	'*' => IO::Handle->new,
);

my @ks;
for (my $i = 0; $i < @prep; $i += 2) {
	my ($k, $v) = @prep[$i, $i + 1];
	my @got = try { die $v } @catches;
	is_deeply \@got, [$k, $v];
	push @ks, $k;
}
is_deeply \@trace, \@ks;
