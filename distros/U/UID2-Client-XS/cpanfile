requires 'perl', '5.010001';
requires 'parent';

on 'configure' => sub {
    requires 'Module::Build';
};

on 'build' => sub {
    requires 'ExtUtils::ParseXS';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'JSON::PP';
    requires 'CryptX', '0.060';
};

on 'develop' => sub {
    requires 'Test::LeakTrace', '0.08';
};
