use Test::More tests=>1;

BEGIN {
    use_ok( 'Test::Spelling' );
}

if (my $checker = Test::Spelling::has_working_spellchecker()) {
    diag "Test::Spelling found a spellchecker: $checker";
}
else {
    diag "Test::Spelling did not find a spellchecker. Please make sure you have spell, aspell, ispell, or hunspell installed.";
}

