#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 12;
use Data::Dumper;
use File::Spec;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Devel qw/create_font_object/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';


my $counter = 0;
my $logger = sub {
    $counter++;
};

my @errors;

my $c = Text::Amuse::Compile->new(logger => $logger,
                                  tex => 1,
                                  report_failure_sub => sub {
                                      push @errors, $_[0];
                                  });

$c->compile('laksdfljalsdkfj.muse');

is_deeply(\@errors, ['laksdfljalsdkfj.muse'], "One error found");

ok $counter, "failure reported";

# dummy entry, normally we need to be chdired, but we want to test
# only the log parser.

my @report;
my %options = (
               name => File::Spec->catfile(qw/t log-encoding/),
               suffix => '.muse',
               templates => Text::Amuse::Compile::Templates->new,
               logger => sub {
                   push @report, @_;
               },
               fonts => create_font_object(),
              );

my $muse = Text::Amuse::Compile::File->new(%options);
my @warnings;
INTERCEPT: {
    local $SIG{__WARN__} = sub { push @warnings, @_};
    $muse->parse_tex_log_file(File::Spec->catfile(qw/t log-encoding.log/));
}

ok (!@warnings, "No warnings") or diag Dumper(\@warnings);

is scalar(@report), 8, "8 lines found" or die;

foreach my $i (4..7) {
    like $report[$i], qr/Missing character: There is no . in font/, "Found $report[$i]";
}
diag $report[$_] for 0..3;

like $report[0], qr/overfull/i;
unlike $report[1], qr/overfull/i;
like $report[2], qr/overfull/i;
unlike $report[3], qr/overfull/i;

# there was an infinite loop here
if ($ENV{RELEASE_TESTING}) {
    $c->logger(sub{ warn @_ });
    $c->compile(File::Spec->catfile(qw/t testfile invalid.muse/));
}
