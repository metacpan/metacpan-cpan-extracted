requires 'Class::Accessor::Lite';
requires 'IO::Socket::SSL';
requires 'Furl';
requires 'JSON::XS';
requires 'URI';
requires 'Try::Tiny';
requires 'HTTP::Request::Common';
requires 'perl', '5.010000';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'Time::Piece';
    requires 'Time::Seconds';
    requires 'String::Random';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Pod::Markdown::Github';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
