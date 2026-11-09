requires 'Class::Accessor::Lite';
requires 'IO::Socket::SSL';
requires 'Furl';
requires 'JSON';
requires 'URI';
requires 'Try::Tiny';
requires 'HTTP::Request::Common';
requires 'File::Temp';
requires 'Scalar::Util';
requires 'perl', '5.020000';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'Time::Piece';
    requires 'Time::Seconds';
    requires 'String::Random';
};

on 'develop' => sub {
    # v3.2.0: manage_changes in minil.toml (the change log is CHANGELOG.md)
    requires 'Minilla', 'v3.2.0';
    requires 'Pod::Markdown::Github';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
};
