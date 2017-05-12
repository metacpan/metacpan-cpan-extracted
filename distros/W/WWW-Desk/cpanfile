requires 'Carp';
requires 'Data::Random';
requires 'HTTP::Request::Common';
requires 'IO::Socket::SSL', '1.84';
requires 'MIME::Base64';
requires 'Mojo::Headers';
requires 'Mojo::Path';
requires 'Mojo::URL';
requires 'Mojo::UserAgent';
requires 'Mojolicious', '5.17';
requires 'Moose';
requires 'Net::OAuth', '0.2';
requires 'Net::OAuth::Client';
requires 'Tie::Hash::LRU';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::FailWarnings';
    requires 'Test::More';
    requires 'Test::NoWarnings';
};
