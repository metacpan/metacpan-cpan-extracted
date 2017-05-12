#!perl
use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More (HAS_LEAKTRACE && $ENV{RELEASE_TESTING} && $ENV{TEST_WITH_LATEX}) ?
  (skip_all => "Test is disabled") :
  # (tests => 1) :
  (skip_all => 'require Test::LeakTrace and RELEASE_TESTING and TEST_WITH_LATEX');
use Test::LeakTrace;
use Text::Amuse::Compile;
use File::Spec;

no_leaks_ok {
    my @logs;
    my $logger = sub {
        push @logs, @_;
    };
    my %opt = (
               'bare_html' => '1',
               'pdf' => '1',
               'zip' => '1',
               'html' => '1',
               'lt_pdf' => '1',
               'epub' => '1',
               'extra' => {
                           'sitename' => 'The Anarchist Library',
                           'mainfont' => 'Linux Libertine O',
                           'division' => '12',
                           'papersize' => '',
                           'siteslogan' => 'Anti-Copyright',
                           'logo' => 'logo',
                           'fontsize' => '10',
                           'site' => 'http://theanarchistlibrary.org',
                           'twoside' => '1',
                           'bcor' => '1cm'
                          },
               'tex' => '1',
               'a4_pdf' => '1',
               'logger' => $logger,
              );

    my $compiler = Text::Amuse::Compile->new(%opt);
    my $target = File::Spec->catfile(qw/t manual manual.muse/);
    $compiler->compile($target);
    $compiler->compile($target);
    diag "found logs: " . scalar(@logs);
}, "No leaks found";
