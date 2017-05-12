use Test::Effects;

plan tests => 2;

effects_ok {
    effects_ok { die "Shouldn't happen" }
               'Not a spec'
                => 'Bad spec';
}
ONLY {
    die => qr/\A\QSecond argument to effects_ok() must be hash or hash reference, not scalar value at\E/,
}
=> 'Bad effects_ok() specification diagnostic';

effects_ok {
    effects_ok { die "Shouldn't happen" }
               { timing => 'all' }
                => 'Bad spec';
}
ONLY {
    die => qr/\A\QInvalid timing specification: timing => 'all'\E/,
}
=> 'Bad timing specification diagnostic';

done_testing();
