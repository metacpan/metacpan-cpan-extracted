use Test::More;

eval "use Test::Perl::Critic( -severity => 1 )";

plan skip_all => 'Test::Perl::Critic only run for author tests' unless $ENV{AUTHOR_TEST};
plan skip_all => "Test::Perl::Critic required for reviewing coding style"
    if $@;

Test::Perl::Critic::all_critic_ok();
