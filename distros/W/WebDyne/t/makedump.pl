#!/bin/perl
#
#  Create dump files in test directory from PSP sources
#

sub BEGIN {
    #  Massage warnings and @INC path
    $^W=0;
    use File::Spec;
    use FindBin qw($RealBin $Script);
    foreach my $dn ($RealBin, File::Spec->path()) {
        if (-f (my $fn=File::Spec->catfile($dn, 'perl5lib.pl'))) {
            require $fn;
            perl5lib->import(File::Spec->catdir($dn, File::Spec->updir()));
            last;
        }
    }
};
use strict qw(vars);
use vars   qw($VERSION);


#  External Modules
#
use WebDyne::Request::Fake;
use WebDyne;
use File::Temp qw(tempfile);
use File::Find qw(find);
use File::Spec;
use IO::File;
use HTML::TreeBuilder;
use Data::Dumper;
use CGI qw(-no_xhtml);
$CGI::XHTML=0;


#  Get list of files either from command line or from *.psp if no
#  command line given
#
my @test_fn=@ARGV;
my $wanted_sr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
find($wanted_sr, $RealBin) unless @ARGV;


#  Iterate over files
#
foreach my $test_fn (sort {$a cmp $b } @test_fn) {


    #  Create WebDyne render of PSP file and capture to file
    #
    printf("processing: %s .. ", (File::Spec->splitpath($test_fn))[2]);
    
    
    #  Check for en-us attribute - needed to consitency across CGI vers
    #
    my $test_fh=IO::File->new($test_fn, O_RDONLY) || die;
    my $html_ln=<$test_fh>;
    $test_fh->close();
    unless ($html_ln=~/en-US/) { die("no html 'lang=en-US' attribute found in file '$test_fn'")}
    
    
    
    #  Render to temp file
    #
    my ($temp_fh, $temp_fn)=tempfile();
    my $r=WebDyne::Request::Fake->new( filename=>$test_fn, select=>$temp_fh, noheader=>1 );
    WebDyne->handler($r);
    $r->DESTROY();
    $temp_fh->close();
    


    #  Create TreeBuilder dump of rendered text in temp file
    #
    (my $dump_fn=$test_fn)=~s/\.psp$/\.dmp/;
    my $dump_fh=IO::File->new($dump_fn, O_WRONLY|O_CREAT|O_TRUNC) ||
      die("unable to create dump file $dump_fn, $!");
    my $html_fh=IO::File->new($temp_fn, O_RDONLY);
    my $tree_or=HTML::TreeBuilder->new();
    while (my $html=<$html_fh>) {
	#  Do this way to get rid of extraneous CR's older version of CGI insert, spaces
	#  after tags which also differ from ver to ver, confusing test
	print "html $html\n";
	$html=~s/\n+$//;
	$html=~s/>\s+/>/g;
	$tree_or->parse($html);
    }
    $tree_or->eof();
    $html_fh->close();
    $tree_or->dump($dump_fh);
    $tree_or->delete();
    $dump_fh->close();

    print "ok\n";
    
}
