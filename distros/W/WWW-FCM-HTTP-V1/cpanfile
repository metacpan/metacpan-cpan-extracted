requires 'Class::Accessor::Lite';
requires 'JSON';
requires 'JSON::WebToken';
requires 'Crypt::OpenSSL::RSA';
requires 'Furl';
requires 'HTTP::Status';
requires 'Carp';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fake::HTTPD', '0.08';
    requires 'Test::Exception', '0.43';
};

