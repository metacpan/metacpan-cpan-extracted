requires 'CGI::Simple';
requires 'Devel::Confess';
requires 'Digest::MD5';
requires 'Env::Path';
requires 'HTML::Tagset';
requires 'HTML::Tiny';
requires 'HTML::TreeBuilder';
requires 'HTTP::Status';
requires 'Hash::MultiValue';
requires 'IO::String';
requires 'JSON';
requires 'Router::Simple';
requires 'Storable';
requires 'Text::Template';
requires 'Tie::IxHash';
requires 'Time::HiRes';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'Capture::Tiny';
    requires 'Test::Deep';
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::Simple', '0.44';
};
