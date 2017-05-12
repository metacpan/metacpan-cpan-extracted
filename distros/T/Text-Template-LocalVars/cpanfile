#!perl

on runtime => sub {

    requires 'Text::Template';
    requires 'Symbol';
    requires 'Package::Stash';
    requires 'Storable';
    requires 'parent';
};


on develop => sub {

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';

    requires 'Module::Install';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::ReadmeFromPod';
    requires 'Test::CheckManifest';
    requires 'CPAN::Meta::Check';
};

on test => sub {

    requires 'Test::More';

};



