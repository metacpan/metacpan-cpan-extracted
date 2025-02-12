use Type::Guess;
use Type::Tiny;
use Types::Standard qw( Int Num Str );
use Mojo::Util qw/dumper/;

use strict;

$\ = "\n"; $, = "\t";

my @lol = (
	   [qw/a b cd efg hijk/],
	   [qw/1 23 456 12000 12.0/],
	   [qw/1.12345 23 456 12000 12.0/],
	   [qw/-100% -13% 12.1%/],
	   [23, +16, -100],
	   [ "2022-12-30", "1923-12-30" ]
	  );

use Type::Tiny;

my $Date = Type::Tiny->new(
   name       => "Date",
   constraint => sub { /^\d{4,4}-\d{2,2}-\d{2,2}$/ },
   message    => sub { "$_ ain't a date" },
);

print ref $Date;

no strict 'refs';
my $date_type_ref = *{"main::Date"}{SCALAR};
print $date_type_ref;
my $date_type = $$date_type_ref;
print $date_type->name;

exit;

# print ref Str, Str->name;


# print ref $Date;
# exit;

for my $l (@lol) {
    print Type::Guess->with_roles("+Tiny")->new($l->@*)->type->name
}

# print "-" x 80;


for my $l (@lol) {
    print Type::Guess->with_roles("+Tiny")->new($l->@*, { types => [$Date, Int, Num, Str] })->type->name
}
