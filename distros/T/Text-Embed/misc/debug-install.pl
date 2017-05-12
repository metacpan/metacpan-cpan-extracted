#!/usr/bin/perl

#
# DONT RUN ON WINDOWS!
#

use Cwd;
my $cwd = cwd();
chdir("..") if($cwd =~ /misc/);

die "uh-oh" unless cwd() =~ /Text-Embed/;

cleanup();

system("perl Makefile.PL"); print "\n";
system("make");             print "\n";
system("make test");        print "\n";

foreach(`make install`)
{
    print;
    if(m/(\S+)\n$/s)
    {
        my $f = $1;
        print "    unlinked $f\n" and unlink($f) if m/^installing|writing/i;
    }
}

cleanup();

sub cleanup
{
    foreach("pm_to_blib", "Makefile")
    {
        unlink $_ if -e $_;
    } 
    system("rm -rf ./blib") if -d "./blib";
}
