requires 'Carp';
requires 'Module::Pluggable';
requires 'POSIX';
requires 'Tie::Hash::LRU';
requires 'Time::Seconds', '1.27';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::FailWarnings';
    requires 'Test::More', '0.84';
    requires 'Test::NoWarnings';
};
