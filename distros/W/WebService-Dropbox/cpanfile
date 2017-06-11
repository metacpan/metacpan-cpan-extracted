requires 'perl', '5.008001';

requires 'JSON', '2.94';
requires 'URI', '1.71';
requires 'HTTP::Message', '6.11';
requires 'LWP::UserAgent', '6.26';
requires 'LWP::Protocol::https', '6.07';

# Modern http client.
recommends 'Furl', '3.11';
recommends 'IO::Socket::SSL', '2.048';
recommends 'JSON::XS', '3.03';

# Module required for license otherwise Perl_5 license.
recommends 'Software::License';

on 'test' => sub {
    requires 'Test::More', '1.302085';
};

on 'configure' => sub {
    requires 'Module::Build';
};
