#!perl

use utf8;
use strict;
use warnings;

use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::Footnotes;

use Test::More tests => 15;
use Data::Dumper;

my $out = catfile(qw/t footnotes out.muse/);

my $pp;

foreach my $good (qw/good good2 good-3/) {
    my $input    = catfile(qw/t footnotes/, $good . '.in');
    my $expected = catfile(qw/t footnotes/, $good . '.out');
    diag "Testing $input => $expected";
    $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $input,
                                                    output => $out,
                                                    debug  => 0,
                                                  );
    ok ($pp->process, "success") or diag Dumper($pp->error);
    ok (!$pp->error);
    compare_files($out, $expected);
}


my $too_many_refs = catfile(qw/t footnotes bad.muse/);

$pp = Text::Amuse::Preprocessor::Footnotes->new(output => $out,
                                                input => $too_many_refs,
                                                debug  => 0,
                                               );
ok (!$pp->process, "No success");
ok (! -f $out, "$out not written");
is_deeply ($pp->error, {
                        references => 3,
                        footnotes => 2,
                        references_found => '[1] [2] [4]',
                        footnotes_found  => '[1] [1]',
                       }, "Error found");

my $too_many_fns = catfile(qw/t footnotes bad2.muse/);

$pp = Text::Amuse::Preprocessor::Footnotes->new(output => $out,
                                                input => $too_many_fns,
                                                debug  => 0,
                                               );
ok (!$pp->process, "No success");
ok (! -f $out, "$out not written");
is_deeply ($pp->error, {
                        references => 3,
                        footnotes => 4,
                        references_found => '[1] [2] [4]',
                        footnotes_found  => '[1] [1] [4] [5]',
                       }, "Error found");


sub compare_files {
    my ($got, $exp) = @_;
    is_deeply([split /\n/, Text::Amuse::Preprocessor->_read_file($got)],
              [split /\n/, Text::Amuse::Preprocessor->_read_file($exp)],
              "$got is equal to $exp") ? unlink $got : die;
}

