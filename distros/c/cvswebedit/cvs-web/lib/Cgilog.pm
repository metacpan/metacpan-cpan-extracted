#! /usr/local/bin/perl -w

#use strict;
package Cgilog;

use Exporter;
use FileHandle;
@ISA = qw(Exporter);
@EXPORT = qw(do_log log_system log_exec log_chdir init_output output);
@EXPORT_OK = (@EXPORT);
%EXPORT_TAGS = ();

my $outfh;
my $tempfile = 'c:\temp\c.txt'; # TODO, HACK

sub init_output {
    my ($logfile, $mode) = @_;

    if ($mode eq "adddate") {
	while (-e $logfile) {
	    my $date = scalar(gmtime);
	    $date =~ s/ /-/g; # no spaces
	    $date =~ s/:/;/g; # no colons for windows
	    $logfile .= $date;
	}
    }
	
    $outfh = new FileHandle ($logfile, "w");
    if (!$outfh) {
	 die "You specified that '$logfile' is to be used for writing debug output to, but it is not writeable: $!";
    }
    do_log("Started logging ".scalar(localtime)."\nFile=$logfile\n");
};

sub do_log {
    print $outfh "LOG {\n";
    print $outfh @_;
    print $outfh "\n}\n";
}

sub log_system {
    $! = '';
    print $outfh "SYSTEM {\n";
    print $outfh @_;
    print $outfh "\n";
    system @_ ;
    print $outfh "Return code : $!"; 
    print $outfh "}\n";
}

sub log_exec {
    my ($arg) = @_;
    if ($^O eq "MSWin32") {
	$arg =~ s/2>&1/>$tempfile/;
    }
    my @ans =  `$arg`;
    if ($^O eq "MSWin32") {
        my $fh = new FileHandle($tempfile);
	@ans = <$fh>; # slurrp.
	close $fh;
    }

    $! = '';
    print $outfh "EXEC {\n". $arg;
    print $outfh "\n";
    print $outfh @ans;
    print $outfh $!."}\n"; 
    return join("",@ans);
} 

sub log_chdir {
    my ($dir) = @_;
    print $outfh "CHDIR 'chdir $dir'\n";
    chdir($dir) || print $outfh "chdir FAILED";
}


sub output {
    print $outfh @_;
    print @_;
}

1;
