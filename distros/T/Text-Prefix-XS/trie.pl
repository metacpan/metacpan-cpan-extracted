#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(time);
use blib;
use Text::Prefix::XS;
use Log::Fu;
use Getopt::Long;
use Text::Match::FastAlternatives;
use Dir::Self;
use lib __DIR__ . '/t';
use Benchmark qw(:all);

require 'txs_gendata.pm';

GetOptions(
    'pp'            => \my $UsePP,
    'xs'            => \my $UseXS,
    'xs_multi'      => \my $UseXS_multi,
    'xs_op'         => \my $UseXS_OP,
    're'            => \my $UseRE,
    're2'           => \my $UseRE2,
    
    're2_cap'       => \my $UseRE2_CAP,
    're_cap'        => \my $UseRE_CAP,
    
    'tmfa'          => \my $UseTMFA,
    'cached'        => \my $UseCached,
    'cycles=i'      => \my $Cycles,
    'count=i'       => \my $StringCount,
    'min=i'         => \my $TermMin,
    'max=i'         => \my $TermMax,
    'terms=i'       => \my $TermCount,
    'bench'         => \my $DoBench
);

$Cycles ||= 0;
$StringCount ||= 2_000_000;

my $matches = 0;

txs_gendata::GenData( {
        StringCount => $StringCount,
        TermCount => $TermCount ||= 20,
        MinLength => $TermMin ||= 5,
        MaxLength => $TermMax ||= 20
    },
    \my @terms,
    \my @strings);

printf("Generated INPUT=%d TERMS=%d TERM_MIN=%d TERM_MAX=%d\n",
       $StringCount, scalar @terms, $TermMin, $TermMax);


sub search_PP {
    my $match_first_pass = 0;
    my $not_filtered = 0;
    my %index;
    my %fullmatch;
    my $MIN_INDEX = 100;
    foreach my $term (@terms) {
        if(length($term) < $MIN_INDEX) {
            $MIN_INDEX = length($term);
        }
        my @chars = split(//, $term);
        while(@chars) {
            $index{join("", @chars)} = 1;
            pop @chars;
        }
        $fullmatch{$term} = 1;
    }
    
    CHECK_TERM:
    foreach my $str (@strings) {
        my $j = 1;
        while($j <= $MIN_INDEX) {
            if(!exists $index{substr($str,0,$j)}){
                next CHECK_TERM;
            }
            $j++;
        }
        $not_filtered++;
        #The prefix matches
        foreach my $term (@terms) {
            if(substr($str,0,length($term)) eq $term) {
                $matches++;
                next CHECK_TERM;
            }
        }
    };
    return $matches;
}

#Try large regex version..
sub gen_big_re {
    my ($is_cap,$is_re2) = @_;
    
    my $ret;
    $ret = join '|',  map quotemeta $_, @terms;
    if($is_cap) {
        $ret = qr/^($ret)/;
    } else {
        $ret = qr/^(?:$ret)/;
    }
}

sub search_Perl_RE {
    
    my $re = gen_big_re();
    foreach my $str (@strings) {
        if($str =~ $re) {
            $matches++;
        }
    }
    return $matches;
}

sub search_Perl_RE_cap {
    my $re = gen_big_re(1, 0);
    foreach my $str (@strings) {
        my ($match) = ( $str =~ $re );
        if($match) {
            $matches++;
        }
    }
    return $matches;
}


sub search_TMFA {
    my $tmfa = Text::Match::FastAlternatives->new(@terms);
    foreach my $str (@strings) {
        if($tmfa->match_at($str, 0)) {
            $matches++;
        }
    }
    return $matches;
}

sub search_XS {
    my $xs_begin_time = time();
    my $xs_search = prefix_search_create(@terms);
    my $xs_duration = time() - $xs_begin_time;
    if($ENV{TEXT_XS_DUMP}) {
        printf("Creating search took %0.3f sec\n", $xs_duration);
    }
    foreach my $str (@strings) {
        if(my $result = prefix_search $xs_search, $str) {
            $matches++;
        }
    }
    if($ENV{TEXT_XS_DUMP}) {
        Text::Prefix::XS::prefix_search_dump($xs_search);
    }
    return $matches;
}

sub search_XS_multi {
    my $xs_search = prefix_search_create(@terms);
    my $match_hash = prefix_search_multi($xs_search, @strings);
    while (my ($pfix,$mch) = each %$match_hash) {
        $matches += scalar @$mch;
    }
    if($ENV{TEXT_XS_DUMP}) {
        Text::Prefix::XS::prefix_search_dump($xs_search);
    }
    return $matches;
}

sub search_XS_op {
    my $xs_search = prefix_search_create(@terms);
    foreach my $str (@strings) {
        if(my $result = psearch($xs_search,$str)) {
            $matches++;
        }
    }
}

if(!($UsePP||$UseXS||$UseRE||$UseRE2
     ||$UseRE2_CAP||$UseRE_CAP||$UseXS_multi||
     $UseXS_OP)) {
    $UsePP = 1;
    $UseXS = 1;
    $UseXS_OP = 1;
    $UseXS_multi = 1;
    $UseRE = 1;
    $UseRE2 = 1;
    $UseTMFA = 1;
    $UseRE2_CAP = 1;
    $UseRE_CAP = 1;
}

my $can_have_re2;
eval {
    require 're2_test.pm';
    $can_have_re2 = 1;
};

my @fn_maps = (
    #[$UsePP,
    # "[Y] Perl-Trie", \&search_PP],
    
    [$UseTMFA,
     "[N] TMFA", \&search_TMFA],
    [$UseRE,
     "[N] perl-re", \&search_Perl_RE],
    [$UseRE2 && $can_have_re2,
     "[N] RE2", sub { re2_test::search_RE2(\@terms, \@strings) }],
    [$UseRE_CAP,
     '[Y] perl-re', \&search_Perl_RE_cap],
    [$UseRE2_CAP && $can_have_re2,
     '[Y] RE2', sub { re2_test::search_RE2_CAP(\@terms, \@strings) }],
    
    [$UseXS, "[Y] TXS", \&search_XS],
    [$UseXS_multi, '[Y] TXS-Multi', \&search_XS_multi],
    
    #[$UseXS_OP, '[Y] TXS-OP', \&search_XS_op],
);

printf("%-5s %-10s %3s\t%s\n",
       'CAP', 'NAME', 'DUR', 'MATCH');

my $cycle_print = $Cycles;

foreach my $cycle (0..$Cycles) {
    if($Cycles) {
        print "Cycle: $cycle\n";
    }
    foreach (@fn_maps) {
        my ($enabled,$title,$fn) = @$_;
        if(!$enabled) {
            printf("%-15s SKIP\n", $title);
            next;
        }
        $matches = 0;
        my $begin_time = time();
        my $matches = $fn->();
        my $duration = time() - $begin_time;
        printf("%-15s\t%0.2fs\tM=%d\n",
                  $title, $duration, $matches);
    }
}
1;
