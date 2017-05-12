#!/usr/local/bin/perl
use strict;
use warnings;
use Text::Darts;
use Regexp::Assemble;
use Benchmark qw/cmpthese timethese/;

my $str = do { open my $fh, __FILE__; local $/; my $s = <$fh>; close $fh; $s };
my @words = do { my %h; $h{$_}++ for split /\W+/, $str; keys %h };

my $td = Text::Darts->new(@words);
my $ra = Regexp::Assemble->new;
$ra->add($_) for @words;
my $re_ra = $ra->re;
my $re_nv = do{ my $str = join '|', @words; qr/(?:$str)/  };

cmpthese( timethese( 0,
      {
          Darts => sub {
              $td->gsub( $str, sub { "<$_[0]>" } );
          },
          'R::A' => sub {
              my $tmp = $str;
              $tmp =~ s{ ($re_ra) }{ "<$1>" }msgex;
          },
          'Naive' => sub {
              my $tmp = $str;
              $tmp =~ s{ ($re_nv) }{ "<$1>" }msgex;
          },
      } ) );
