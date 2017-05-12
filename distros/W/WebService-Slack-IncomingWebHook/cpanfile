# vim: ft=perl
requires 'perl', '5.008001';

requires 'Encode';
requires 'Furl';
requires 'IO::Socket::SSL'; # for https
requires 'JSON';

on 'test' => sub {
    requires 'Capture::Tiny';
    requires 'Plack';
    requires 'Test::Exception';
    requires 'Test::More', '0.96';
    requires 'Test::TCP';
};

