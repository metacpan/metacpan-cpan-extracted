use Test::More tests => 1;

eval "use perl5::ingy";

my $error = $@;
$error =~ s/ at .*//s;

is $error, "Don't 'use perl5::ingy'. Try 'use perl5-ingy'",
    'Test incorrect usage';
