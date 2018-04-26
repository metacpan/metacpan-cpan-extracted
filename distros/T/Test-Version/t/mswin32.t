#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Version;
use File::Temp qw( tempdir );
use File::Spec;
use Cwd;

plan skip_all => 'only on MSWin32'
  unless $^O eq 'MSWin32';

#
# these characters are (unfortunately) rather common in
# a MSWin32 file system, so we need to beable to handle
# them under taint mode, since the test suite runs under
# taint mode now:
#
#  parens: ( and )
#  spaces: ' '
#  short names with tilde: C:/STRAWB~1/cpan/build/Test-Version-2.08_01-0
#
my %tests = (
  'with parentheticals' => 'corpus2/mswin32/(withparan)',
  'with space'          => 'corpus2/mswin32/dir with space',
  'long as short'       => Win32::GetShortPathName('corpus2/mswin32/veryveryveryveryveryveryverylongdirname'),
);

foreach my $name (sort keys %tests)
{
  subtest $name => sub {

    my $dir = $tests{$name};

    my($save) = Cwd::getcwd =~ /^(.*)$/;
    chdir $dir;
    note "dir = $dir";

    eval { version_all_ok('lib') };
    is $@, '';

    chdir $save;
  };
}

done_testing;
