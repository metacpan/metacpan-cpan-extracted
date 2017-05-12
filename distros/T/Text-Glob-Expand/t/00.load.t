#!/usr/bin/perl 
use strict;
use warnings;
use File::Find;
use FindBin qw($Bin);

use Test::More 'no_plan';

# This test checks that all scripts compile without errors, and all
# modules load ok.

my $script_dir = "$Bin/../script";

# We need to use blib/lib and not lib, since some 
# modules depend on the ConfigData.pm module
# generated there by Module::Build.
# SO MAKE SURE YOU RUN ./Build BEFORE RUNNING THIS TEST DIRECTLY!
my $lib_dir = "$Bin/../blib/lib"; 
push @INC, $lib_dir;

# check to see if a file has a shebang first line
sub has_shebang 
{
    my $file = shift;
    die "can't open $file: $!" unless open my $fh, "<$file";
    return unless defined(my $line = <$fh>);
    close $fh;
    return $line =~ m{^\s* \#! \s* (\S*/)? perl}x;
}

# compile a script and return the errors as a string, if any
sub compile_script
{
    my $file = shift;
    my @errors = grep !/syntax OK/, `perl -cw -I '$lib_dir' '$file' 2>&1 >/dev/null`;

    my $errors = join "", @errors;
    $errors .= "Return code ". ($? & 0xff) 
        if $?;
    return $errors;
}

# find bad scripts
find 
{
    wanted => sub 
    {
        return if /~$/;
        return unless /\.pl$/ || has_shebang $_;
        (my $name = $_) =~ s!^$script_dir/!!;
        my $errors = compile_script $_;
        is $errors, "", $name;
    },
    no_chdir => 1,     
}, $script_dir 
    if -d $script_dir;

# find bad modules
find 
{
    wanted => sub 
    {
        my $name = $_;
        return unless $name =~ s/\.pm$//;
        $name =~ s!^$lib_dir/!!;
        $name =~ s!/!::!g;

        use_ok $name;
    },
    no_chdir => 1,     
}, $lib_dir
    if -d $lib_dir;


