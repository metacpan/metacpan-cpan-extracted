requires 'Mouse';
requires 'Redis';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};

on develop => sub {
    requires 'Pod::Markdown::Github';
};
