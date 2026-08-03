requires 'Class::Accessor::Lite';
requires 'IO::Socket::SSL';
requires 'Furl';
requires 'JSON';
requires 'URI';
requires 'Try::Tiny';
requires 'HTTP::Request::Common';
requires 'File::Temp'; 
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
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
};
