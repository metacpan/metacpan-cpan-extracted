# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl genomics.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('genomics') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#use genomics::FilterSeq;

my $uploadfilename="t\/sample.fa";
open(SEQ,"$uploadfilename") or die "Can't open file $uploadfilename";
print "using File $uploadfilename\n";

my $filter_start=100;
my $filter_length=20;
my $filter_window=25;
my $filter_type="T";
my $out_file = "t\/sample.out";

my %SEQUENCE;
my $linecount=0;
my $cur_seq;
my $previous_name;

foreach my $line (<SEQ>){
	chomp $line;
	if( $line =~ m/\>/ ){
		$linecount++;
		if($linecount>1) {
			$SEQUENCE{$previous_name}=$cur_seq;
			undef $cur_seq;
			$previous_name = $line;
		}else{
			$previous_name = $line;
		}

	}else {
		$cur_seq = $cur_seq.$line;
	}
}
$SEQUENCE{$previous_name}=$cur_seq;
close(SEQ);


my ( $RefKeyHash_R,$RefKeyHashSeq_R,$EST_PER_SITE_R,$SITES_CHOSEN_R,$STATS_R )= genomics::FilterSeq(\%SEQUENCE,$filter_start,$filter_length,$filter_window,$filter_type);

my $seq_count = $$STATS_R{"seq_count"};
my $Refseq_ID_count = $$STATS_R{"Refseq_ID_count"};
my $position_squashed_count = $$STATS_R{"position_squashed_count"};
my $key_count = $$STATS_R{"key_count"};
my $my_length_ave = $$STATS_R{"length_ave"};

#Output follows
unless ( open(OUT, ">$out_file")) {print "cannot open file MC.scratch\n\n";exit;}
print OUT "Out of $seq_count  sequences ($my_length_ave), $Refseq_ID_count Id's were placed into $position_squashed_count sites (exact key), further reduced to $key_count sites by positional iteratation<BR>\n";
foreach(keys(%$RefKeyHash_R)){
	print OUT "$_ ";
	my $my_name_arr = $$RefKeyHash_R{$_};
	print OUT @$my_name_arr;
	print OUT "\n";
	print OUT ${$$RefKeyHashSeq_R{$_}};
	print OUT "\n";
}
