use lib qw(inc); use Devel::AssertOS qw(Unix);

die("OS unsupported: your sudo appears to not be working\n")
    # duplicated out of t/lib/sudosecurity.pm. Eeuuww. Needed
    # because we want to bail early if a CPAN-tester is just gonna
    # bounce on Enter. Partly to annoy him less, partly because if
    # we skip all the tests we generate PASS reports and I'm only
    # interested in reports where the tests are actually run!
    # Still need the prompt in tests for use in dev where we want
    # to mention tests in the prompt instead of using U::S's slightly
    # terser prompt.
    unless(!system(
        "sudo", "-p",
        "\nThe build and tests for Unix::Sudo need your password. They'll run 'whoami',\n".
        "  'true', and some perl code as root: ",
        "true"
    ));

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Unix::Sudo',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Unix-Sudo',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Unix-Sudo/issues'
        }
    },
  VERSION_FROM => 'lib/Unix/Sudo.pm',
  PREREQ_PM    => {
    'B::Deparse'     => 0,
    'Capture::Tiny', => 0,
    'Data::Compare'  => 0,
    'Data::Dumper'   => 0,
    'PadWalker'      => 0,
    'Probe::Perl',   => 0,
    'Taint::Runtime' => 0,
    'Test::More'     => '0.88', # need done_testing (0.88)
  },
);
