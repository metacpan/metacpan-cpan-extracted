requires 'perl', '5.010001';

requires 'Export::Attrs';
requires 'List::Util', '1.33';
requires 'Scalar::Util';
requires 'Test::MockModule';
requires 'bignum';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More', '0.96';
    recommends 'Time::HiRes';
    recommends 'EV';
    recommends 'Mojolicious', '6';
    suggests 'AnyEvent';
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
