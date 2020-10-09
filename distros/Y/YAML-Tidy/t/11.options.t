#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More;
use Test::Warnings qw/ :report_warnings /;
use FindBin '$Bin';
use Data::Dumper;
local $Data::Dumper::Useqq = 1;

use YAML::Tidy;

no warnings 'redefine';
sub YAML::Tidy::Config::_homedir {
    return "$Bin/home"
}

subtest partial => sub {
    my $yaml = <<'EOM';
      c:  
       d: e	
       f: g
EOM
    my $partial = <<'EOM';
      c:
        d: e
        f: g
EOM
    my $yt = YAML::Tidy->new( partial => 1 );
    my $out = $yt->tidy($yaml);
    is($out, $partial, 'Partial tidy keeps first level of indent');

    $yaml = <<'EOM';

      c  
       d e	
       f g
EOM
    $partial = <<'EOM';

      c
      d e
      f g
EOM
    $out = $yt->tidy($yaml);
    is($out, $partial, 'Partial tidy keeps first level of indent');

    $yaml = <<'EOM';

      |  
      c  
       d e	
       f g
EOM
    $partial = <<'EOM';

      |
      c  
       d e	
       f g
EOM
    $out = $yt->tidy($yaml);
    is($out, $partial, 'Partial tidy keeps first level of indent');
};

done_testing;
