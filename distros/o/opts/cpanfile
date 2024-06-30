requires 'Filter::Util::Call';
requires 'Getopt::Long', '2.37';
requires 'PadWalker', '1.9';
requires 'Text::Table';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Module::Used';
    requires 'Test::Perl::Critic';
    requires 'Test::Exception';
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
