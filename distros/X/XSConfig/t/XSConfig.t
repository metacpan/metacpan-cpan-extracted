#!/usr/bin/perl
BEGIN {
    $| = 1;
    if (scalar keys %Config:: > 2) {
        print "1..0 #SKIP Cannot test with static or builtin Config\n";
        exit(0);
    }
}

require Config; #this is supposed to be XS config
require B;

*isXSUB = !B->can('CVf_ISXSUB')
  ? sub { shift->XSUB }
  : sub { shift->CvFLAGS & B::CVf_ISXSUB() }; #CVf_ISXSUB added in 5.9.4

#is_deeply->overload.pm wants these 2 XS modules
#can't be required once DynaLoader is removed later on
require Scalar::Util;
eval { require mro; };
#Test::More based on Test2 (1.3XXXXX) will load POSIX XS module
require Test::More;
my $cv = B::svref_2object(*{'Config::FETCH'}{CODE});
unless (isXSUB($cv)) {
  if (-d 'regen') { #on CPAN
    warn "Config:: is not XS Config";
  } else {
    print "1..0 #SKIP Config:: is not XS Config, miniperl?\n";
    exit(0);
  }
}

my $in_core = ! -d "regen";

# change the class name of XS Config so there can be XS and PP Config at same time
foreach (qw( TIEHASH DESTROY DELETE CLEAR EXISTS NEXTKEY FIRSTKEY KEYS SCALAR FETCH)) {
  *{'XSConfig::'.$_} = *{'Config::'.$_}{CODE};
}
tie(%XSConfig, 'XSConfig');

# delete package
undef( *main::Config:: );
require Data::Dumper;
$Data::Dumper::Useperl = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 0;
$Data::Dumper::Quotekeys = 0;

# full perl is now miniperl
undef( *main::XSLoader::);
require 'Config_mini.pl';
Config->import();
require 'Config_heavy.pl';
Test::More->import (tests => 4);

ok(isXSUB($cv), 'XS Config:: is XS');

$cv = B::svref_2object(*{'Config::FETCH'}{CODE});
ok(!isXSUB($cv), 'PP Config:: is PP');

my $klenXS = scalar(keys %XSConfig);
my $copy = 0;
my %Config_copy;
if (exists $XSConfig{canned_gperf}) { #fix up PP Config to look like XS Config
  #to see in CPAN Testers reports if the builder had gperf or not
  warn "This XS Config was built with the canned XS file\n";
  $copy = 1;
  for (keys %Config) {
    $Config_copy{$_} = $Config{$_};
  }
  $Config_copy{canned_gperf} = '';
  is (scalar keys %Config_copy, $klenXS, 'same adjusted key count');
} else {
  is (scalar(keys %Config), $klenXS, 'same key count');
}

#is_deeply(got==PP, expect==XS)
is_deeply ($copy ? \%Config_copy : \%Config, \%XSConfig, "cmp PP to XS hashes");

# old Test::Builders dont have is_passing
if ( Test::More->builder->can('is_passing')
      ? !Test::More->builder->is_passing() : 1 ) {
# 2>&1 because output string not captured on solaris
# http://cpantesters.org/cpan/report/fa1f8f72-a7c8-11e5-9426-d789aef69d38
  my $diffout = `diff --help 2>&1`;
  if (index($diffout, 'Usage: diff') != -1 #GNU
      || index($diffout, 'usage: diff') != -1) { #Solaris
    open my $f, '>','xscfg.txt';
    print $f Data::Dumper::Dumper({%XSConfig});
    close $f;
    open my $g, '>', 'ppcfg.txt';
  
    print $g ($copy
              ? Data::Dumper::Dumper({%Config_copy})
              : Data::Dumper::Dumper({%Config}));
    close $g;
    system('diff -U 0 ppcfg.txt xscfg.txt > cfg.diff');
    unlink('xscfg.txt');
    unlink('ppcfg.txt');
    if (-s 'cfg.diff') {
      open my $h , '<','cfg.diff';
      local $/;
      my $file = <$h>;
      close $h;
      diag($file);
    }
    unlink('cfg.diff');
  } else {
    diag('diff not available, can\'t output config delta');
  }
}
