#!/usr/bin/perl
#
# merge-align-results [OPTIONS] result-file1 result-file2
#
# OPTIONS
#
#   -m metrics (recall|precision|F), default=F
#

use strict;


my $metric='F';

while ($ARGV[0]=~/~\-/){
    my $opt=shift(@ARGV);
    if ($opt=~/^\-m/){
	$metric=shift(@ARGV);
    }
}

my $file1=shift(@ARGV);
my $file2=shift(@ARGV);

my %settings1;
my %settings2;

my $vec1;
my $vec2;

my %vv1;
my %vv2;

&ReadSettings($file1,\%settings1,$metric);
&ReadSettings($file2,\%settings2,$metric);

foreach (sort { $settings1{$a} <=> $settings1{$b} } keys %settings1){
    if ((defined $settings1{$_}) and (defined $settings2{$_})){
	if ($settings1{$_}=~/(\A|\s)0.00(\s|\Z)/){next;}  # skip 0.00 results!
	if ($settings2{$_}=~/(\A|\s)0.00(\s|\Z)/){next;}
	print "# $settings1{$_}\t$settings2{$_}\t$_\n";
	$vec1.=' '.$settings1{$_};
	$vec2.=' '.$settings2{$_};
	my $nr=scalar split(/\+/,$_);
	if ($_=~/^dyn/){
	    $vv1{"$nr\_dyn"}.=' '.$settings1{$_};
	    $vv2{"$nr\_dyn"}.=' '.$settings2{$_};
	}
	else{
	    $vv1{$nr}.=' '.$settings1{$_};
	    $vv2{$nr}.=' '.$settings2{$_};
	}
    }
}

&Correlation($vec1,$vec2,'all');


foreach (sort { $a <=> $b } keys %vv1){
    &Correlation($vv1{$_},$vv2{$_},$_);
#    print "\n# nr clues: $_ \n";
#    print "x=[$vv1{$_}]\n";
#    print "y=[$vv2{$_}]\n";
#    print "puts \"SETTINGS WITH $_ CLUES\\n\"\n";
#    print 'R=corrcoef(x,y)'."\n";
}


sub Correlation{
    my ($vec1,$vec2,$name)=@_;

    print "\n# settings: $name\n";
    print "x=[$vec1]\n";
    print "y=[$vec2]\n";
    print "puts \"SETTINGS: $name\\n\"\n";
    print 'r=corrcoef(x,y)'."\n";
    print 'xdev=std(x)'."\n";
    print 'ydev=std(y)'."\n";
    print 'xmean=mean(x)'."\n";
    print 'ymean=mean(y)'."\n";
    print 'b=r*(ydev/xdev)'."\n";
    print 'a=ymean-(b*xmean)'."\n";
    print 'reg=a+b*x'."\n";
    print "gset term postscript\n";
    print "gset output '$name.ps'\n";
    print "plot(x,y,'+',x,reg,'-')\n";
    print "gset term x11\n";
}


sub ReadSettings{
    my $file=shift;
    my $set=shift;
    my $met=shift;

    open F,"<$file";
    while(<F>){
	if (/^([0-9\.]{4,5})\s+([0-9\.]{4,5})\s+([0-9\.]{4,5})\s+.*?\s(\S+)$/){
	    if ($met eq 'precision'){
		if ($2>0){$$set{$4}=$1;}
	    }
	    elsif ($met eq 'recall'){
		if ($2>0){$$set{$4}=$2;}
	    }
	    else{
		if ($3>0){$$set{$4}=$3;}
	    }
	}
    }
    close F;
}
