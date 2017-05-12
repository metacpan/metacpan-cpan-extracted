use Test::More;
eval "use Test::Valgrind";
plan skip_all => 'Test::Valgrind is not installed.' if $@;
leaky();
