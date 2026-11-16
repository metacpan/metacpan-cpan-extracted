requires 'perl', '5.036';
requires 'Carp';
requires 'Exporter';
requires 'List::Util', '1.33';
requires 'POSIX';

on test => sub {
    requires 'Test2::V0';
    requires 'Test2::Plugin::NoWarnings';
};

# The maintainers' tools, as Ekorn-Pipeline's, less what only it needs,
# and what scripts/update-rules needs: TOML::Parser to read gitleaks'
# rules, and HTTP::Tiny, with IO::Socket::SSL, to fetch them over HTTPS.
# JSON::MaybeXS is for Devel::Cover's JSON report, which scripts/coverage
# reads.
on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Data::Dump';
    requires 'Devel::Cover';
    requires 'HTTP::Tiny';
    requires 'IO::Socket::SSL';
    requires 'JSON::MaybeXS';
    requires 'JSON::PP', '4.18';
    requires 'Minilla';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Pod::Coverage';
    requires 'Pod::Markdown::Github';
    requires 'Software::License';
    requires 'Test2::Harness';
    requires 'Test2::Plugin::Cover';
    requires 'Test::Spellunker';
    requires 'TOML::Parser';
    requires 'UUID';
    requires 'Version::Next';
};
