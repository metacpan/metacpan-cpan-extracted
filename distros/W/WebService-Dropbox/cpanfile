requires 'perl', '5.008001';

requires 'JSON', '2.59';
requires 'URI', '1.60';
requires 'HTTP::Message', '6.06';
requires 'LWP::UserAgent', '6.05';
requires 'LWP::Protocol::https', '6.04';

# Modern http client.
recommends 'Furl', '2.19';
recommends 'IO::Socket::SSL', '1.954';
recommends 'JSON::XS', '3.02';

# Module required for license otherwise Perl_5 license.
recommends 'Software::License';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'configure' => sub {
    requires 'Module::Build';
};
