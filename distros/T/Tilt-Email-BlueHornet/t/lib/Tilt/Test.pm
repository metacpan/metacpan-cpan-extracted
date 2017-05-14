use Test::More;
#use Tilt;

# NOTE: See Test::More documentation for more information on why this is
# required.
# http://search.cpan.org/~exodist/Test-Simple-1.001014/lib/Test/More.pm
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";
