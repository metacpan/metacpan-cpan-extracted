#!/usr/bin/perl -w

use Test::More;

plan skip_all => "Need ExtUtils::CBuilder to test the XS"
    unless eval { require ExtUtils::CBuilder };
plan skip_all => "Need a working compiler"
    unless ExtUtils::CBuilder->new->have_compiler;
plan "no_plan";

use File::Spec;
my $perl = File::Spec->rel2abs($^X);

local $ENV{PERL5LIB} = join ':', File::Spec->rel2abs("blib/lib"), $ENV{PERL5LIB};
ok chdir("t/Some-Employee");
is system("$perl Build.PL"),        0;
is system("$perl Build"),           0;
is system("$perl Build test"),      0;
is system("$perl Build realclean"), 0;
