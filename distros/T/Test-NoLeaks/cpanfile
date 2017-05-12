requires 'POSIX';
requires 'perl', '5.010000';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::More';
    requires 'File::Temp';
    requires 'IO';
    requires 'Test::TCP';
    requires 'Test::Warnings';
};
