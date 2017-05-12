use 5.010_001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 're-engine-Hooks-TestDist';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my $top;
BEGIN {
 require File::Spec;
 my $up = File::Spec->updir;
 $top   = File::Spec->rel2abs(File::Spec->catdir($up, $up));
}

use ExtUtils::Depends;

my %ed_vars = eval {
 require blib;
 blib->import($top);

 my $ed = ExtUtils::Depends->new($name => 're::engine::Hooks');

 $ed->get_makefile_vars;
};

$ed_vars{clean}->{FILES} .= ' ' . join ' ',
      "$dist-*", qw{*.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt};

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 PL_FILES         => {},
 MIN_PERL_VERSION => '5.010001',
 %ed_vars,
);
