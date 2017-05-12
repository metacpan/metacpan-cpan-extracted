#!perl
# Copyright (c) 1999 Michael Koehne <kraehe@copyleft.de>

use XML::Edifact;
use File::Spec;
use File::Copy;
use SDBM_File;
use Fcntl;

$CHKDIR=File::Spec->catdir("html");                        mkdir $CHKDIR,0777 unless -d $CHKDIR;
$CHKDIR=File::Spec->catdir("html","TR");                   mkdir $CHKDIR,0777 unless -d $CHKDIR;
$CHKDIR=File::Spec->catdir("html","EX");                   mkdir $CHKDIR,0777 unless -d $CHKDIR;
$CHKDIR=File::Spec->catdir("html","LIB");                  mkdir $CHKDIR,0777 unless -d $CHKDIR;
$CHKDIR=File::Spec->catdir("html","LIB","xml-edifact-03"); mkdir $CHKDIR,0777 unless -d $CHKDIR;
$CHKDIR=File::Spec->catdir("html","LIB","untdid-d96b");    mkdir $CHKDIR,0777 unless -d $CHKDIR;

$DATA=File::Spec->catdir("blib","lib","XML","Edifact","d96b");
mkdir $DATA, 0777 unless -d $DATA;

XML::Edifact::open_dbm( $DATA, O_RDWR|O_CREAT );

#------------------------------------------------------------------------------#
$run=File::Spec->catdir("boot","segment.run");   $req_ok = require $run;
$run=File::Spec->catdir("boot","composite.run"); $req_ok = require $run;
$run=File::Spec->catdir("boot","element.run");   $req_ok = require $run;
$run=File::Spec->catdir("boot","annex_b.run");   $req_ok = require $run;
$run=File::Spec->catdir("boot","codes.run");     $req_ok = require $run;
$run=File::Spec->catdir("boot","dtd.run");       $req_ok = require $run;

#------------------------------------------------------------------------------#

XML::Edifact::close_dbm( );

open TOUCH,">>".File::Spec->catfile($DATA,".exists"); close TOUCH;

$DATA=File::Spec->catdir("blib","lib","XML","Edifact","extend");
mkdir $DATA, 0777 unless -d $DATA;

opendir(CODEDIR, "code_lists") || die "can't opendir $some_dir: $!";
foreach (readdir(CODEDIR)) {
    if ( /\.txt$/ ) {
	print "reading ".$_."\n";
	load_dbm(File::Spec->catfile("code_lists",$_));
    }
}
closedir CODEDIR;

open TOUCH,">>".File::Spec->catfile("html",".exists"); close TOUCH;

#------------------------------------------------------------------------------#

sub load_dbm {
    foreach $name (@_) {
	open (INFILE, $name)                                || die "can not open !".$name."! for reading";
	$tiename = $name;
	$tiename =~ s/\.txt$//;
	tie(%DBM, 'SDBM_File', $tiename, O_RDWR|O_CREAT, 0644) || die "can not tie ".$tiename.$!;

	%DBM = ();

	while (<INFILE>) {
		chop;
		if (($_ !~ /^[\t ]*$/) && ($_ !~ /^#/)) {
			($key,$val)      = split /\t+/, $_, 2;
			$val =~ s/^\t+//g;
			if ($key ne "") {
				$DBM{$key} = $val;
				$oldkey=$key;
			} else {
				$val = $DBM{$oldkey}." ".$val;
				$DBM{$oldkey} = $val;
			}
		}
	};
	close(INFILE);
    }
}

#------------------------------------------------------------------------------#
opendir(UNDIR, "un_edifact_d96b") || die "can't opendir $some_dir: $!";
foreach (readdir(UNDIR)) {
    if ( /^[a-zA-Z]/ ) {
	print "copying ".$_."\n";
	File::Copy::copy(File::Spec->catfile("un_edifact_d96b",$_),File::Spec->catfile("html","LIB","untdid-d96b",$_));
    }
}
closedir UNDIR;
#------------------------------------------------------------------------------#
0;
