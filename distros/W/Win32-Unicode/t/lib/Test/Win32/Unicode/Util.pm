package Test::Win32::Unicode::Util;

use strict;
use warnings;
use Exporter 'import';

use Cwd ();
use Carp qw(croak);
use File::Temp ();
use File::Spec;
use Test::More;

use constant CYGWIN => $^O eq 'cygwin';

our @EXPORT = qw/safe_dir dump_tree tempdir CYGWIN/;

#use Win32::Unicode::Console;
#tie *Foo, 'Win32::Unicode::Console::Tie';
#binmode STDOUT => ':utf8';
#Test::More->builder->$_(\*Foo) for qw/output failure_output todo_output/;

sub tempdir {
    File::Temp::tempdir(CLEANUP => 1, @_);
}

sub safe_dir(&) {
    my $code = shift;

    my $cwd    = Cwd::getcwd;
    my $tmpdir = tempdir();

    chdir $tmpdir or croak "$tmpdir: $!";
    eval { $code->($tmpdir) };
    chdir $cwd or croak "$cwd: $!";
    croak $@ if $@;
}

sub dump_tree {
    require Win32::Unicode::Dir;
    my $dir = shift;

    unless ($ENV{HARNESS_ACTIVE}) {
        Win32::Unicode::Dir::findW(+{
            wanted   => sub { note $_ },
            no_chdir => 1,
        }, $dir);
    }
}

1;
