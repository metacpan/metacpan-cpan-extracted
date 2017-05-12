#!/usr/bin/perl -w
# Quick-n-dirty script to benchmark web sites using ApacheBench, there
# is much more to ApacheBench then this..
# XAO Inc., Andrew Maltsev, am@xao.com

use HTTPD::Bench::ApacheBench;

use strict;

my $repeat=int(shift(@ARGV) || 100);
my $thread=int(shift(@ARGV) || 5);

if(!@ARGV) {
    print "Usage: $0 count threads url url url ...\n\n";
    print "Example: $0 100 5 http://localhost/ http://localhost/cgi-bin/xxx.cgi\n";
    exit(1);
}

my $urlskip=0;
foreach my $url (@ARGV) {
    $urlskip=length($url) if length($url)>$urlskip;
}
$urlskip=$urlskip>30 ? $urlskip-27 : 0;

print "Doing $repeat iterations in $thread thread(s)..\n";
print '='x78,"\n";
printf '%-30s %5s %8s %10s  %7s => %7s'."\n",
       'URL','Count','Bytes','Byte/sec','Time','Req/Sec';
print '-'x78,"\n";

my $b=HTTPD::Bench::ApacheBench->new;

$b->concurrency($thread);
$b->priority("run_priority");
$b->memory(1);

my $g_count=0;
my $g_bytes=0;
my $g_time=0;
foreach my $url (@ARGV) {
    my $run=HTTPD::Bench::ApacheBench::Run->new({
        urls        => [ $url ],
        repeat      => $repeat,
    });
    my $slot=$b->add_run($run);
    my $ro=$b->execute;

    my $count=$b->total_requests;
    $g_count+=$count;
    my $time=$b->total_time;
    $g_time+=$time;
    my $bytes=$b->bytes_received;
    $g_bytes+=$bytes;

    $b->delete_run($slot);

    pr($url,$count,$time,$bytes);
}
print '-'x78,"\n";
pr('',$g_count,$g_time,$g_bytes);
print '='x78,"\n";

exit 0;

sub pr {
    my ($url,$c,$t,$b)=@_;
    my $bname='Kb';
    $b/=1024;
    if($b>9999) {
        $bname='Mb';
        $b/=1024;
    }
    my $bpsname='Kb/s';
    my $bps=$t ? $b/$t*1000 : 0;
    if($bps>9999) {
        $bps/=1024;
        $bpsname='Mb/s';
    }
    printf '%-30s %5u %6u%s %6.1f%s %7.2fs => %7.2f'."\n",
           $urlskip && $urlskip<length($url) ? '...' . substr($url,$urlskip) : $url,
           $c,
           $b, $bname,
           $bps, $bpsname,
           $t/1000,
           $t ? $c/$t*1000 : 0;
}
