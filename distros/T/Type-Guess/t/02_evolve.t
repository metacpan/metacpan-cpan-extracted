use strict;
use warnings;
use Test::More tests => 2;
use Type::Guess;

Type::Guess->tolerance(.1);

my @dates = qw(
    2015-10-26
    2022-10-14
    2022-12-05
    2024-07-26
    2018-03-12
    2023-01-19
    2028-01-07
    1903-01-15
    2093-11-10
    1954-01-05
    2027-08-18
    1983-11-13
);
my $t = Type::Guess->with_roles("+Date")->new(@dates);

isa_ok ($t, "Type::Guess", "Class correct");
ok ((ref $t) =~ /Role::Date$/ , "role applied")
