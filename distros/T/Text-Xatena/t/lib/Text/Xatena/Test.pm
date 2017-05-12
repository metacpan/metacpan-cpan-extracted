package Text::Xatena::Test;

use strict;
use warnings;
use Test::More;
use Test::Base -Base;
use HTML::Parser;
use Data::Dumper;
use UNIVERSAL::require;
use HTML::Entities;
use Test::HTML::Differences;

use lib 'lib';
use Text::Xatena;
our $options = {};

filters {
    input => [qw/chomp/],
    expected => [qw/chomp/],
};

our @EXPORT = qw(run_html thx);
our $INLINE = "";
our $INLINE_ARGS = [];

sub thx ($);
sub html ($);

sub run_html (%) {
    my %opts = @_;
    run {
        my ($block) = @_;
        my $input = $block->input;
        my $expected = $block->expected;
        if ($opts{linefeed}) {
            $input =~ s/\n/$opts{linefeed}/g;
        }
        my $got = thx $input;
        eq_or_diff_html($got, $expected, $block->name) or note $input;
    }
}

sub thx ($) {
    my ($str) = @_;
    $INLINE->use if $INLINE;
    my $thx = Text::Xatena->new(
        %{ $options },
        inline => $INLINE ? $INLINE->new(@{ $INLINE_ARGS }) : undef 
    );
    my $ret = $thx->format($str, );
    $ret;
}


1;
