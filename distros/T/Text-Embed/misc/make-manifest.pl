#!/usr/bin/perl
use Cwd;
use File::Find;

my $cwd = cwd();
chdir("..") if($cwd =~ /misc/);

find(sub 
{ 
    my $f = $File::Find::name;
    if(-f $_)
    { 
        $f =~ s#^\./##; 
        print "$f\n";
    }
} , ".");

