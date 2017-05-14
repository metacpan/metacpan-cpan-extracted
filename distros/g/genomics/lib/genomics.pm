package genomics;

use 5.008001;
#use strict; #see line 78.
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use genomics ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';


# Preloaded methods go here.

# Preloaded methods go here.
################################################################################################
sub FilterSeq {
	#print "\n<BR>Starting FilterSeq sub from FilterSeq.pm<BR>\n";
	my $i=0;
	my $SEQ_HASH = $_[$i++];
	my $filter_start = $_[$i++];
	my $filter_length = $_[$i++];
	my $filter_window = $_[$i++];
	my $filter_type = $_[$i++];
	my $length_count=0;
	my $position_squashed_count;
	my %KEYS;
	my %KEY_COUNT;
	my %TOP_KEY;
	my %TOP_COUNT;
	my %SHIFTED;
	my $keys_bumpped;
	my $test_key_count;
	my $test_key;
	my $top_count;
	my $top_key;
	my $top_pos;
	my $pos1a;
	my $key_count;
	my %EST_PER_SITE;
	my %SITES_CHOSEN;
	my %STATS;
	my %RefKeyHash;
	my %RefKeyHashSeq;
	my $seq_count;
	my $Refseq_ID_count;
	##################################################################################################################3
	foreach(keys (%$SEQ_HASH)){
		my $Refseq_ID = $_;
		my $cur_seq = $$SEQ_HASH{$_};
		$cur_seq =~ s/\s//g;
		$cur_seq = uc ( $cur_seq );
		my $length = length($cur_seq);
		$length_count+=$length;
		my $key_seq = substr($cur_seq, $filter_start, $filter_length);
		if(length($key_seq)<$filter_length){
			next;
		}
		#my @$key_seq;#DOES NOT WORK !! -> can't use strict
		push(@$key_seq,$Refseq_ID);
		#keep track of the position squashed keys
		$KEYS{$key_seq}=$cur_seq;#this should be one to one or last seen if duplicate key are encountered
		$KEY_COUNT{$key_seq}+=1;
		$seq_count++;
		#print "$_\t$$SEQ_HASH{$_}<BR>\n";
	}
	###################################################################################################################
	my $loop=1;
	my $loop_count=1;
	while($loop==1){
		my $keys_bumpped=0;
		my $keys_mapped_loop=0;
		#next we have to pre-calculate the top and nearest neighbors
		#Map All of the %KEYS -> %TOP_KEY
		undef %TOP_COUNT;
		undef %TOP_KEY;
		my $total_keys=0;
		my $new_top=0;
		foreach (keys %KEYS){#get the position squashed sequences
			my $top_key = "null";
			my $top_count=0;
			my $top_pos = 0;
			my $my_key = $_;
			my $my_key_count;
			#get the keys prevelance
			if(defined($KEY_COUNT{$my_key})){
				$my_key_count = $KEY_COUNT{$my_key};
			}else{
				$my_key_count=0;
			}
			my $my_seq = $KEYS{$my_key};
			#iterate though to find the best and nearby neighbors
			if($loop_count==1){
				#count the number of staring pac sites
				$position_squashed_count++;
			}
			#############################################################################################################################################
			#############################################################################################################################################
			if ($filter_type=~/M/){#don't suppress ambiguous sites
				for ($pos1a = ($filter_start - $filter_window); $pos1a <= ($filter_start + $filter_window); $pos1a +=1){
					$test_key= substr($my_seq,$pos1a,$filter_length);
					if(length($test_key)<$filter_length){
						next;
					}
					if(defined($KEY_COUNT{$test_key})){
						$test_key_count = $KEY_COUNT{$test_key};
					}else{
						$test_key_count=0;
					}
					if($pos1a==$filter_start){
						if(($test_key_count>=$top_count)and($test_key_count>=$my_key_count)){#squash by top_count and then by 3'
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}else{
						#pick only if > than $my_key_count (larger set)
						if(($test_key_count>$top_count)){#squash by top_count and then by 3'
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}
				}
			}
			#############################################################################################################################################
			#############################################################################################################################################
			if ($filter_type=~/T/){#suppress ambiguous sites -> 3'
				for ($pos1a = ($filter_start - $filter_window); $pos1a <= ($filter_start + $filter_window); $pos1a +=1){
					$test_key= substr($my_seq,$pos1a,$filter_length);
					if(length($test_key)<$filter_length){
						next;
					}
					if(defined($KEY_COUNT{$test_key})){
						$test_key_count = $KEY_COUNT{$test_key};
					}else{
						$test_key_count=0;
					}
					if($pos1a==$filter_start){
						if(($test_key_count>=$top_count)and($test_key_count>=$my_key_count)){#squash by top_count and then by 3'
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}else{
						#pick most 3' that is >= to $my_key_count (smaller set)
						if(($test_key_count>=$top_count)){#squash by top_count and then by 3'
							#we only want one position here (or the most 3' all else equal)
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}
				}
			}
			#############################################################################################################################################
			#############################################################################################################################################
			if ($filter_type=~/F/){#suppress ambiguous sites -> 5'
				for ($pos1a = ($filter_start + $filter_window); $pos1a >= ($filter_start - $filter_window); $pos1a -=1){
					$test_key= substr($my_seq,$pos1a,$filter_length);
					if(length($test_key)<$filter_length){
						next;
					}
					if(defined($KEY_COUNT{$test_key})){
						$test_key_count = $KEY_COUNT{$test_key};
					}else{
						$test_key_count=0;
					}
					if($pos1a==$filter_start){
						if(($test_key_count>=$top_count)and($test_key_count>=$my_key_count)){#squash by top_count and then by 3'
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}else{
						#pick most 5' that is >= to $my_key_count (smaller set)
						if(($test_key_count>=$top_count)){#squash by top_count and then by 5'
							#we only want one position here (or the most 5' all else equal)
							$top_count = $test_key_count;
							$top_key = $test_key;
							$top_pos = $pos1a;
						}
					}
				}
			}
			#############################################################################################################################################
			#############################################################################################################################################
			#we now have the best place to put the pac site
			if($top_key!~$my_key){
				#we can move this pac site
				$new_top++;
			}
			$TOP_KEY{$my_key}=$top_key;
			$TOP_COUNT{$my_key}=$top_count;
		}
		foreach(sort {$KEY_COUNT{$a}<=>$KEY_COUNT{$b}} keys(%KEY_COUNT)){#this orders the mapping in a logical way
			my $my_key = $_;
			my $my_key_count = $KEY_COUNT{$my_key};
			my $top_key = $TOP_KEY{$my_key};
			if($top_key!~$my_key){
				#remap the key
				$KEY_COUNT{$top_key}+=$my_key_count;
				foreach(@$my_key){
					push(@$top_key,$_);
				}
				my $Sites_forward = $SHIFTED{$my_key};
				$Sites_forward+=1;
				$SHIFTED{$top_key}+=$Sites_forward;#the_top_key picked up a new site
				undef @$my_key;
				delete ($KEYS{$my_key});
				delete ($KEY_COUNT{$my_key});
				$keys_bumpped++;
				#$my_key nolonger ezists - remapped to $TOP_COUNT
			}
		}
		if($keys_bumpped==0){
			$loop=0;
		}
		$loop_count++;
	}
	$key_count=0;
	foreach(sort {$KEY_COUNT{$b}<=>$KEY_COUNT{$a}} keys(%KEY_COUNT)){#this orders the mapping in a logical way
		my $my_key = $_;
		$RefKeyHash{$my_key}=\@$my_key;
		$RefKeyHashSeq{$my_key}=\$KEYS{$my_key};
		$EST_PER_SITE{$my_key}=$KEY_COUNT{$my_key};
		$SITES_CHOSEN{$my_key}=$SHIFTED{$my_key};
		$SITES_CHOSEN{$my_key}+=1;
		$key_count++;
		foreach(@$my_key){
			$Refseq_ID_count++;
		}
		#print "$my_key\t$SITES_CHOSEN{$my_key}\t$EST_PER_SITE{$my_key}\n";
	}
	undef %KEYS;
	undef %KEY_COUNT;
	undef %TOP_KEY;
	undef %TOP_COUNT;
	undef %SHIFTED;
	$STATS{"seq_count"} = $seq_count;
	$STATS{"Refseq_ID_count"} = $Refseq_ID_count;
	$STATS{"position_squashed_count"} = $position_squashed_count;
	$STATS{"key_count"} = $key_count;
	$STATS{"length_ave"} = ($length_count/$seq_count);

return ( \%RefKeyHash, \%RefKeyHashSeq, \%EST_PER_SITE, \%SITES_CHOSEN, \%STATS );
}#end FilterSeq
#####################################################################################################################

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

genomics - Perl extension for various DNA sequence analysis tools

=head1 SYNOPSIS

  use genomics::FilterSeq;

=head1 DESCRIPTION

This module condenses a fasta formated file to a 'unique' list of sequences.
This is done rcursively by Hash{key} lookups. A unique key is sampled from
each sequence and listed in a %HASH, thereby making all seqeucnes with identcal keys equivelent.
The sequences are scanned +- the scanning window for other keys. Duplicates are squashed based on
key prevelence or 5'->3' directionality.
=head2 EXPORT
Usage:
Call the subroutine by sending in order:
1.	\%SEQUENCE - a reference to a hash with %SEQUENCE{$name}=$sequence structure
2.	$filter_start - the staring position in the sequence to gab a key
3.	$filter_length - the length of the key (shorter keys produce more 'pruned' sets)
4.	$filter_window - window +- to scan for keys
5.	$filter_type - "M" = leave ambigous sequences, "T" = force ambigous to most 3' position, "F" =  force ambigous to most 5' position

my ( $RefKeyHash_R,$RefKeyHashSeq_R,$EST_PER_SITE_R,$SITES_CHOSEN_R,$STATS_R )= genomics::FilterSeq(\%SEQUENCE,$filter_start,$filter_length,$filter_window,$filter_type);

subroutine returs the following:
1.	$RefKeyHash_R - hash_reference to hash containing references to arrays with sequence names by key. [ %hash{$key}=@ref_to_names ]
2.	$RefKeyHashSeq_R, - similar, only returns condensed sequence by key
3.	$EST_PER_SITE_R, a reference to a hash containg the key count value (number of keys represented)
4.	$SITES_CHOSEN_R, a reference to a hash containg the key count value (number of sites represented)
5.	$STATS_R reference to a hash of various counts.



my $seq_count = $$STATS_R{"seq_count"};
my $Refseq_ID_count = $$STATS_R{"Refseq_ID_count"};
my $position_squashed_count = $$STATS_R{"position_squashed_count"};
my $key_count = $$STATS_R{"key_count"};
my $my_length_ave = $$STATS_R{"length_ave"};

print "Out of $seq_count  sequences ($my_length_ave), $Refseq_ID_count Id's were placed into $position_squashed_count sites (exact key), further reduced to $key_count sites by positional iteratation<BR>\n";

foreach(keys(%$RefKeyHash_R)){
	print "$_ ";
	my $my_name_arr = $$RefKeyHash_R{$_};
	print @$my_name_arr;
	print "\n";
	print ${$$RefKeyHashSeq_R{$_}};
	print "\n";
}


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

=head1 AUTHOR

ltboots, E<lt>jesse.salisbury@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
