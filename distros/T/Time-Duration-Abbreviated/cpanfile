requires 'perl', '5.008005';
requires 'parent';
requires 'Time::Duration';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
};

on develop => sub {
    requires 'Test::Perl::Critic';
    requires 'Test::Synopsis::Expectation';
};
