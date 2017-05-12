requires 'perl', '5.012000';

requires 'HTML::Entities';
requires 'JSON::XS';
requires 'Export::Attrs';
requires 'URI::Escape';

on configure => sub {
    requires 'Devel::AssertOS';
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Filter::CommaEquals';
    requires 'Path::Tiny';
    requires 'Test::Exception';
    requires 'Test::MockModule';
    requires 'Test::More';
    recommends 'Pod::Coverage', '0.18';
    recommends 'Test::CheckManifest', '0.9';
    recommends 'Test::Perl::Critic';
    recommends 'Test::Pod', '1.22';
    recommends 'Test::Pod::Coverage', '1.08';
};
