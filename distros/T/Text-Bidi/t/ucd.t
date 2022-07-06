#!/usr/bin/env perl

use 5.10.0;
use warnings;
use integer;
use open qw[:encoding(utf-8) :std];
use charnames qw(:full :short);
use version 0.77;
use Test::More;

plan skip_all => "'\$TEXT_BIDI_SKIP_UCD' set to $ENV{TEXT_BIDI_SKIP_UCD}"
    if $ENV{'TEXT_BIDI_SKIP_UCD'};

sub crange { map { chr } $_[0]..$_[1] }

no warnings 'qw';
my %char = (
    L => ['A'..'Z','a'..'z',"\N{LEFT-TO-RIGHT MARK}"],
    R => [crange(ord("\N{hebrew:alef}"), ord("\N{hebrew:tav}")), "\N{RIGHT-TO-LEFT MARK}"],
    AL => [crange(ord("\N{arabic:alef}"), ord("\N{arabic:yeh}")), chr(0x61c)],
    EN => ['0'..'9'],
    ES => [qw(+ -)],
    ET => [qw(# $ %), crange(0xa2,0xa5)],
    AN => [crange(0x600, 0x604)],
    CS => [qw(, . / :), chr(0xa0), chr(0x60c)],
    NSM => [crange(0x300, 0x36f),crange(0x610, 0x61a)],
    BN => [crange(0, 8), crange(0xe, 0x1b), crange(0x7f, 0x84), crange(0x86, 0x9f)],
    B => [map { chr } (0xa, 0xd, 0x1c..0x1e, 0x85, 0x2029)],
    S => [chr(9), chr(0xb), chr(0x1f)],
    WS => [chr(0xc), ' '],
    ON => [qw(! " & ' * ; < = > ? @ [ \ ] ^ _ ` { | } ~), chr(0x606), chr(0x60e)],
    LRE => ["\N{LEFT-TO-RIGHT EMBEDDING}"],
    LRO => ["\N{LEFT-TO-RIGHT OVERRIDE}"],
    RLE => ["\N{RIGHT-TO-LEFT EMBEDDING}"],
    RLO => ["\N{RIGHT-TO-LEFT OVERRIDE}"],
    PDF => ["\N{POP DIRECTIONAL FORMATTING}"],
    LRI => [chr(0x2066)],
    RLI => [chr(0x2067)],
    FSI => [chr(0x2068)],
    PDI => [chr(0x2069)],
);

use Text::Bidi qw(log2vis get_bidi_type_name unicode_version);

BEGIN {
    plan skip_all => 'libfribidi Unicode version too old'
        if version->parse(unicode_version()) < v6.0.0;
}

use Text::Bidi::Constants;

sub char {
    my $l = $char{$_[0]};
    my $i = int(rand(scalar(@$l)));
    $l->[$i]
}

sub dirs {
    my $bits = shift;
    my @res;
    push @res, $Text::Bidi::Par::ON if $bits & 1;
    push @res, $Text::Bidi::Par::LTR if $bits & 2;
    push @res, $Text::Bidi::Par::RTL if $bits & 4;
    @res
}

{
use Data::Dumper;
my $dd = (new Data::Dumper [])->Terse(1)->Indent(0)->Useqq(1);

sub escape {
    $dd->Values(\@_)->Dump
}
}

open my $fh, '<', 't/BidiTest.txt' 
    or plan skip_all => "can't open UCD datafile: $!";
#open my $err, '<', 't/known.txt' or plan skip_all => "Can't open known 
#errors file: $!";

#our %known;
#foreach ( <$err> ) {
#    next unless /^(.*): (.*)$/;
#    $known{$1} = $2;
#}

# we don't reorder NSM
my $flags = $Text::Bidi::Flags::DEFAULT & ~$Text::Bidi::Flag::REORDER_NSM;

foreach ( <$fh> ) {
    next if /^\s*(#|$)/;
    chomp;
    if ( /^\@Levels:\s*(.*)/ ) { 
        @levels = split ' ', $1;
        @levund = grep { $levels[$_] eq 'x' } 0..$#levels;
        %levund = ();
        $levund{$_} = 1 foreach @levund;
        next;
    }
    if ( /^\@Reorder:\s*(.*)/ ) { @reorder = split ' ', $1; next }
    if ( /^([A-Z ]*); ([1-7])/ ) {
        my $bits = $2;
        my $ing = $1;
        my @chars = map { char($_) } (split ' ', $ing);
        my @ords = map { ord } @chars;
        my $in = join ('', @chars);
        my $ine = escape($in);
        for my $pdir ( dirs($bits) ) {
        SKIP: {
            my $pdname = get_bidi_type_name($pdir);
            #skip 'Test fails in libfribidi', 2
            #    if defined $known{"$ing;$pdname"};
            my ($p, $vis) = log2vis($in, length($in), $pdir, $flags);
            my $lev = $p->levels;
            my @olev = @$lev;
            $olev[$_] = 'x' foreach @levund;
            local $" = ',';
            my @int = @{$p->_unicode};
            my @types = $p->type_names;
            my $cpdname = get_bidi_type_name($p->dir);
            #say $err "$ing;$pdname: @olev > @levels % $in" unless
            is("@olev", "@levels", <<EOF

Levels of '$ine' (line $.)
  ord of chars:@ords
  types in: $ing
  Internal rep.: @int
  Determined types: @types
  with par dir: $pdname
  computed par dir: $cpdname
EOF
                ); # or BAIL_OUT('failed');
            my $map = $p->map;
            my @map = grep { not $levund{$_} } @$map;
            is("@map", "@reorder", <<EOF

Reorder of '$ine' (line $.)
  ord of chars:@ords
  types in: $ing
  Internal rep.: @int
  Determined types: @types
  with par dir: $pdname
  computed par dir: $cpdname
  levels: @levels
EOF
            ); # or BAIL_OUT('failed');
        }}
        next;
    }
    warn "Don't know what to do with '$_'\n";
}

done_testing;
