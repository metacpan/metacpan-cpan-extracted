requires 'perl', '5.008005';
requires 'JSON::XS';
requires 'MIME::Base64';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Class::Inspector';
};

