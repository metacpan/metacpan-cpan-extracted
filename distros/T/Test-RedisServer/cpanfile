requires 'File::Temp';
requires 'Mouse';
requires 'Time::HiRes';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
    requires 'Redis';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
