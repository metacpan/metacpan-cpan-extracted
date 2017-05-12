requires 'Digest::SHA1';
requires 'Encode', '2.57';
requires 'Furl';
requires 'JSON';
requires 'YAML::Tiny';
requires 'perl', '5.008005';

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
};
