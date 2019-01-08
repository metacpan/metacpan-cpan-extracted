#!/usr/bin/perl
#-*-perl-*-

use utf8;
use FindBin qw( $Bin );
use lib ("$Bin/../lib");

use Test::More;
use File::Compare;

use Text::PDF2XML;

############

my $pdf_file = "$Bin/french.pdf";

my $output = pdf2xml( $pdf_file,
		      # output => 'data/french.tika.xml',
		      java_heap => '64m',
		      use_tika_server => 0,
		      vocabulary_from_tika => 0,
		      vocabulary_from_pdf => 0,
		      vocabulary_from_raw_pdf => 0 );
is( my_compare( $output, "$Bin/data/french.tika.xml" ),1, "pdf2xml (Apache Tika)" );

# ## this is only different if there is an Apache::Tika server running
# $output = pdf2xml( $pdf_file,
# 		      # output => 'data/french.tika.xml',
# 		      use_tika_server => 1,
# 		      vocabulary_from_tika => 0,
# 		      vocabulary_from_pdf => 0,
# 		      vocabulary_from_raw_pdf => 0 );
# is( my_compare( $output, "$Bin/data/french.tika.xml" ),1, "pdf2xml (Apache Tika Server)" );

$output = pdf2xml( $pdf_file,
		      # output => 'data/french.lm.xml',
		      java_heap => '64m',
		      use_tika_server => 0,
		      vocabulary_from_tika => 1,
		      vocabulary_from_pdf => 0,
		      vocabulary_from_raw_pdf => 0 );
is( my_compare( $output, "$Bin/data/french.lm.xml" ),1, "pdf2xml (LM-based merge)" );

# $output = pdf2xml( $pdf_file,
# 		      # output => 'data/french.lm.xml',
# 		      use_tika_server => 1,
# 		      vocabulary_from_tika => 1,
# 		      vocabulary_from_pdf => 0,
# 		      vocabulary_from_raw_pdf => 0 );
# is( my_compare( $output, "$Bin/data/french.lm.xml" ),1, "pdf2xml (LM-based merge, Server)" );

$output = pdf2xml( $pdf_file,
		      # output => 'data/french.voc.xml',
		      java_heap => '64m',
		      use_tika_server => 0,
		      vocabulary => "$Bin/word-list.txt",
		      vocabulary_from_tika => 1,
		      vocabulary_from_pdf => 0,
		      vocabulary_from_raw_pdf => 0 );
is( my_compare( $output, "$Bin/data/french.voc.xml" ),1, "pdf2xml (wordlist)" );

done_testing;



# there is one line that destroys the tests! take it away!
# meta includes localized time! --> remove

sub my_compare{
    my ($output,$file2) = @_;
    open F,"<$file2" || die "cannot find reference file $file2\n";
    binmode (F,":utf8");
    my @lines = <F>;
    my $reference = join("",@lines);

    ## ignore extra white spaces 
    $output =~s/(\n|A)\s*/$1/sg;
    $output =~s/\s*(\n|\Z)/$1/sg;
    $output =~s/<head>.*<\/head>//s;
    # $output =~s/\n[^\n]+\(U ο υ a vu Q[^\n]*\n/\n/s;

    $reference =~s/(\n|A)\s*/$1/sg;
    $reference =~s/\s*(\n|\Z)/$1/sg;
    $reference =~s/<head>.*<\/head>//s;
    # $reference =~s/\n[^\n]+\(U ο υ a vu Q[^\n]*\n/\n/s;

    return $output eq $reference;
}

