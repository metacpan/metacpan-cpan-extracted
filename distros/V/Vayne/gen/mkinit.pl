#!/usr/bin/env perl
use FindBin qw($Bin);
use File::Basename;
use Path::Tiny;
use YAML;

our %var;
my @dir = glob("$Bin/../vayne/*");

while(@dir)
{
    my $dir = shift @dir;
    if(-f $dir)
    {
        my $p = path($dir)->relative("$Bin/../vayne");
        $var{$p} = path($dir)->slurp;

    }
    push @dir, glob("$dir/*");
}

my $origin = path($Bin,'vayne-init')->slurp;
my $dst = path($Bin, '../', 'script', 'vayne-init');
$dst->spew($origin. Dump \%var);
$dst->chmod("a+x");
