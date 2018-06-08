requires 'CHI';
requires 'Data::Serializer';
requires 'Digest::MD5';
requires 'JSON';
requires 'Moo';
requires 'namespace::clean';
requires 'REST::Client';
requires 'Role::REST::Client';
requires 'Sereal';
requires 'strictures', '2';
requires 'Types::Standard';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl', '5.008005';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Warn';
    requires 'Test::Kwalitee';
    requires 'Test::HasVersion';
    requires 'Test::DistManifest';
};

on 'develop' => sub {
    requires 'App::CISetup';
    requires 'App::Software::License';
    requires 'Dist::Milla';
    recommends 'Devel::NYTProf';
};
