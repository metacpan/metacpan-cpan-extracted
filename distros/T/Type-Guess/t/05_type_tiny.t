use Type::Tiny;
use Test::More;
use Mojo::Util qw/dumper/;
use Type::Guess;
use Types::Standard qw( Int Num Str );
use strict;

$\ = "\n"; $, = "\t";

my @data = (
	   [qw/a b cd efg hijk/],
	   [qw/1 23 456 12000 12.0/],
	   [qw/1.12345 23 456 12000 12.0/],
	   [qw/-100% -13% 12.1%/],
	   [23, +16, -100],
	   [ "2022-12-30", "1923-12-30" ]
	  );

my @expected = qw/Str
		  Int
		  Num
		  Num
		  Int
		  Str/;


for my $l (@data) {
    is(Type::Guess->with_roles("+Tiny")->new($l->@*)->type->name, $expected[0], shift @expected)
}

print "-" x 80;

my $Date = Type::Tiny->new(
   name       => "Date",
   constraint => sub { /^\d{4,4}-\d{2,2}-\d{2,2}$/ },
   message    => sub { "$_ ain't a date" },
);

my @expected = qw/Str
		  Int
		  Num
		  Num
		  Int
		  Date/;

for my $l (@data) {
    is(Type::Guess->with_roles("+Tiny")->new($l->@*, { types => [$Date, Int, Num, Str] })->type->name, $expected[0], shift @expected)
}

done_testing()
