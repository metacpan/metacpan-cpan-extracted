requires 'perl', '5.010001';

on develop => sub {
    requires 'CPAN::Uploader', '0.103012';
    requires 'Minilla', '3.0.12';
    requires 'Perl::Critic', '1.125';
    requires 'Pod::Markdown::Github', '0.04';
    requires 'Software::License::MIT', '0.103011';
    requires 'Test::CPAN::Meta', '0.25';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.05';
    requires 'Test::Perl::Critic', '1.03';
    requires 'Test::Pod', '1.51';
    requires 'Test::Spellunker', '0.4.0';
    requires 'Version::Next', '1.000';
    requires 'Text::Diff', '1.44';
};

on configure => sub {
    requires 'Module::Build::XSUtil', '0.16';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Time::Strptime', '1.00';
    requires 'File::Slurp';
};
