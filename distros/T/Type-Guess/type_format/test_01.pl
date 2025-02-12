use Foo;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t";

my @list;

@list = qw/a b cd efg hijk/;
my $str = Foo->new(@list);
for (qw/type precision length integers to_string sql/) {
    printf "%-12s %s\n", $_, $str->$_
}
for (@list) {
    printf "|%s|\n", $str->($_)
}

@list = qw/1 23 456 12000 12.0/;

my $str = Foo->new(@list);
for (qw/type precision length integers to_string sql/) {
    printf "%-12s %s\n", $_, $str->$_
}

for (@list) {
    printf "|%s|\n", $str->($_)
}

@list = qw/1.12345 23 456 12000 12.0/;
my $str = Foo->new(@list);
for (qw/type precision length integers to_string sql/) {
    printf "%-12s %s\n", $_, $str->$_
} 

for (@list) {
    printf "|%s|\n", sprintf $str->to_string, $_
}

$str->precision(2);
for (@list) {
    printf "|%s|\n", sprintf $str->to_string, $_
}

$str->type("string");
for (@list) {
    printf "|%s|\n", $str->($_)
}

@list = qw/-100% -13% 12.1%/;
my $str = Foo->new(@list);
for (qw/type precision length integers to_string sql/) {
    printf "%-12s %s\n", $_, $str->$_
}

for (@list) {
    printf "|%s|\n", $str->($_)
}

@list = (23, +16, -100);
my $str = Foo->new(@list);
for (qw/type precision length integers to_string sql/) {
    printf "%-12s %s\n", $_, $str->$_
}

for (@list) {
    printf "|%s|\n", $str->($_)
}

