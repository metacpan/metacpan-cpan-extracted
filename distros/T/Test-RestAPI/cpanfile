requires 'perl', '5.010';

requires 'parent';
requires 'Moo';
requires 'Type::Tiny';
requires 'Mojolicious';
requires 'Path::Tiny';
requires 'Port::Selector';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Module::Build::Tiny';
    requires 'Version::Next';
};
