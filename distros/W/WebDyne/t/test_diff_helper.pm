package test_diff_helper;

use strict;
use warnings;

use Exporter qw(import);
use Algorithm::Diff qw(sdiff);
use Test::Differences qw(eq_or_diff_text table_diff unified_diff oldstyle_diff context_diff);

our @EXPORT_OK=qw(eq_or_diff_text_test);


sub set_diff_type {

    my ($actual, $expect)=@_;
    my $diff_type=lc($ENV{'WEBDYNE_TEST_DIFF_TYPE'} || 'auto');

    if ($diff_type eq 'auto') {
        my $max_char=(
            defined($ENV{'WEBDYNE_TEST_AUTO_MAX_CHAR'}) &&
            $ENV{'WEBDYNE_TEST_AUTO_MAX_CHAR'}=~/^\d+$/
        ) ? $ENV{'WEBDYNE_TEST_AUTO_MAX_CHAR'} : 60;
        my @actual_line=split(/\n/, $actual || '');
        my @expect_line=split(/\n/, $expect || '');
        my $max_change_len=0;
        foreach my $diff_ar (sdiff(\@actual_line, \@expect_line)) {
            next if ($diff_ar->[0] eq 'u');
            foreach my $line (@{$diff_ar}[1,2]) {
                my $line_len=length($line || '');
                $max_change_len=$line_len if ($line_len > $max_change_len);
            }
        }
        $diff_type=($max_change_len > $max_char) ? 'unified' : 'table';
    }

    if ($diff_type eq 'table') {
        table_diff();
    }
    elsif ($diff_type eq 'oldstyle') {
        oldstyle_diff();
    }
    elsif ($diff_type eq 'context') {
        context_diff();
    }
    else {
        unified_diff();
    }

}


sub eq_or_diff_text_test {

    set_diff_type($_[0], $_[1]);

    local $Test::Builder::Level=$Test::Builder::Level+1;
    my $ok=eq_or_diff_text(@_);
    die "aborting after first test failure\n" if (!$ok && $ENV{'WEBDYNE_TEST_FAIL_ABORT'});

    return $ok;

}


1;
