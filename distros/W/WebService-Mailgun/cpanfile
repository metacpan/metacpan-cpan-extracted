requires 'Class::Accessor::Lite';
requires 'IO::Socket::SSL';
# 3.08: delete() sends a body (delete_tag)
requires 'Furl', '3.08';
requires 'JSON';
requires 'URI';
requires 'Try::Tiny';
# 6.07: PUT takes the content of a form, as POST does (update_template, update_template_version)
requires 'HTTP::Request::Common', '6.07';
requires 'Scalar::Util';
requires 'perl', '5.020000';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Temp';
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
