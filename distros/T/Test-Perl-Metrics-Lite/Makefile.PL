sub readme_from {
    warn
        "You need to install Module::Install::ReadmeFromPod to generate README";
}

sub use_test_base {
    warn "You need to install Test::Base to run make test from git clone";
}

sub author_requires {
    warn
        "You need to install Module::Install::AuthorRequires to install modules author requires";
}
sub author_tests        { }
sub auto_set_repository { }

use inc::Module::Install;

name 'Test-Perl-Metrics-Lite';
all_from 'lib/Test/Perl/Metrics/Lite.pm';

requires(
    'Perl::Metrics::Lite' => 0.061,
    'List::MoreUtils'     => 0,
);
test_requires( 'Test::More' => 0.88, );
use_test_base;
auto_include;
WriteAll;
