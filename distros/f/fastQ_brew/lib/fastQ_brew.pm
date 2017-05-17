#
# module for fastQ_brew
#
# Copyright Damien O'Halloran
#
# You may distribute this module under the same terms as perl itself
# History
# January 16, 2017
# POD documentation - main docs before the code

=head1 NAME

fastQ_brew - a module for preprocessing of fastQ formatted files

=head1 SYNOPSIS

  use fastQ_brew;
  use List::Util qw(min max sum);
  use fastQ_brew_Utilities;
  use Cwd;
  
  my $lib       = "sanger";
  my $file_path = cwd();
  my $in_file   = "sample_sanger.fastq";

  my $tmp = fastQ_brew->new();

  $tmp->load_fastQ_brew(
                    library_type  => $lib || "illumina",
                    file_path     => $file_path,
                    in_file       => $in_file,
                    summary       => "Y",
                    de_duplex     => "Y",
                    qual_filter   => 30,
                    length_filter => 25,
                    adapter_left  => "GTACGTGTGGTGGGGAT",
                    mismatches_l  => 1,
                    adapter_right => "TAGCGCGCGATGATT",
                    mismatches_r  => 1,
                    left_trim     => 5,
                    right_trim    => 8,
                    fasta_convert => "Y",
                    dna_rna       => "Y",
                    rev_comp      => "Y",
                    remove_n      => "Y",
                    cleanup       => "Y"
  );

  $tmp->run_fastQ_brew();

=head1 DESCRIPTION

Returns summary statistics for all reads from fastQ formatted files and provides methods for filtering and trimming reads by lenght and quality.

=head1 FEEDBACK

damienoh@gwu.edu

=head2 Mailing Lists

User feedback is an integral part of the evolution of this module. Send your comments and suggestions preferably to one of the mailing lists. Your participation is much appreciated.

=head2 Support

Please direct usage questions or support issues to:
<damienoh@gwu.edu>
Please include a thorough description of the problem with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the GitHub bug tracking system to help keep track of the bugs and their resolution.  Bug reports can be submitted via the GitHub page:

 https://github.com/dohalloran/fastQ_brew/issues

=head1 AUTHORS - Damien OHalloran

Email: damienoh@gwu.edu

=head1 APPENDIX

The rest of the documentation details each of the object
methods.

=cut

# Let the code begin...

package fastQ_brew;

use warnings;
use strict;
use List::Util qw(min max sum);
use fastQ_brew_Utilities;

##################################
our $VERSION = '1.0.2';
##################################

=head2 new()

 Title   : new()
 Usage   : my $tmp = fastQ_brew->new();
 Function: constructor routine
 Returns : a blessed object
 Args    : none

=cut

##################################

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    return $self;
}

##################################

=head2 load_fastQ_brew()

 Title   : load_fastQ_brew()
 Usage   : $tmp->load_fastQ_brew(
                    library_type  => $lib || "illumina",
                    file_path     => $file_path,
                    in_file       => $in_file,
                    summary       => "Y",
                    de_duplex     => "Y",
                    qual_filter   => 30,
                    length_filter => 25,
                    adapter_left  => "GTACGTGTGGTGGGGAT",
                    mismatches_l  => 1,
                    adapter_right => "GTACGTGTGGTGGGGAT",
                    mismatches_r  => 1,
                    left_trim     => 5,
                    right_trim    => 8,
                    fasta_convert => "Y",
                    dna_rna       => "Y",
                    rev_comp      => "Y",
                    remove_n      => "Y",
                    cleanup       => "Y"
              );
 Function: Populates the user data into $self hash
 Returns : nothing returned
 Args    :
 -library_type, either sanger or illumina
 -file_path, path to sequences
 -in_file, the name of the files containing the fastQ reads
 -summary, return summary statistics for the unfiltered and filtered fastq data
 -de_duplex, remove duplicate entries
 -qual_filter, fiter reads by Q score: N=no, 200=remove reads with Quality (Q) scores below 200
 -adapter_left, remove adapter from left side
 -mismatches_l, remove adapter from left side that include a number of mismatches
 -adapter_right, remove adapter from right side
 -mismatches_r, remove adapter from right side that include a number of mismatches
 -left_trim, remove x number of bases from left end
 -right_trim, remove x nnumber of bases from right end
 -length_filter, fiter reads by length: N=no, 40=remove reads shorter than 40 bases
 -fasta_convert, option to convert to fastA file: Y=yes, N=no
 -dna_rna, transcribe reads in fastQ file: N=no, Y=yes
 -rev_comp, reverse complement reads in fastQ file: N=no, Y=yes
 -remove_n, remove reads with non-designated bases (i.e. N's) in fastQ file: N=no, Y=yes
 -cleanup, option to delete tmp file: Y=yes, N=no

=cut

##################################

sub load_fastQ_brew {
    my ( $self, %arg ) = @_;
    if ( defined $arg{library_type} ) {
        $self->{library_type} = $arg{library_type};
    }
    if ( defined $arg{file_path} ) {
        $self->{file_path} = $arg{file_path};
    }
    if ( defined $arg{in_file} ) {
        $self->{in_file} = $arg{in_file};
    }

    # default obj attributes or user specifications
    $self->{summary}       = $arg{summary}       || "N";
    $self->{de_duplex}     = $arg{de_duplex}     || "N";
    $self->{fasta_convert} = $arg{fasta_convert} || "N";
    $self->{adapter_left}  = $arg{adapter_left}  || "N";
    $self->{mismatches_l}  = $arg{mismatches_l}  || 0;
    $self->{adapter_right} = $arg{adapter_right} || "N";
    $self->{mismatches_r}  = $arg{mismatches_r}  || 0;
    $self->{qual_filter}   = $arg{qual_filter}   || "N";
    $self->{length_filter} = $arg{length_filter} || "N";
    $self->{left_trim}     = $arg{left_trim}     || "N";
    $self->{right_trim}    = $arg{right_trim}    || "N";
    $self->{rev_comp}      = $arg{rev_comp}      || "N";
    $self->{dna_rna}       = $arg{dna_rna}       || "N";
    $self->{remove_n}      = $arg{remove_n}      || "N";
    $self->{cleanup}       = $arg{cleanup}       || "N";
}

##################################

=head2 run_fastQ_brew()

 Title   : run_fastQ_brew()
 Usage   : $self->run_fastQ_brew(%arg)
 Function: processes the input file and start cycle
 Returns : tmp file with only phred score and sequence for each read
 Args    : fastQ file

=cut

##################################

sub run_fastQ_brew {
    my ( $self, %arg ) = @_;

    # calculate execution time
    $self->{start} = time;

    # process fastq file
    open my $fh, '<', $self->{in_file}
      or die "Cannot open $self->{in_file}: $!";
    print "\nprocessing input file...\n";

    # new file will only contain the base pairs and quality scores
    my $new_file = $self->{file_path} . "new_temp_" . $self->{in_file};
    $self->{temp_file} = $new_file;
    open my $fn, '>', $new_file or die "Cannot open $new_file: $!";
    my $count;
    while ( my $line = <$fh> ) {
        $count++;
        if ( $count % 2 == 0 ) {
            print $fn $line;
        }
    }

    # close handles
    close $fh;
    close $fn;
    $self->_summary_stats(%arg);
}

###################################

=head2 _summary_stats()

 Title   : _summary_stats()
 Usage   : _summary_stats();
 Function: runs the summary stats
 Returns : the stats
 Args    : $self, %arg

=cut

##################################

sub _summary_stats {
    my ( $self, %arg ) = @_;
    if ( $self->{summary} eq "Y" ) {

        # open the newfile to read
        open my $fn, '<', $self->{temp_file}
          or die "Cannot open  $self->{temp_file}: $!";
        my $counter;

        # array container for reads gc%
        my @gc_content;

        # array container for reads lengths
        my @read_len;

        # array container for read phred scores
        my @phred;

        # array container for read probability
        my @prob;

        # the 1st line 3rd, lines etc.. (i.e. odd #'s) contain
        # the read sequence
        print "\ncalculating stats...\n\n\n";
        while ( my $row = <$fn> ) {
            chomp $row;
            $counter++;
            if ( $counter % 2 != 0 ) {

                # Calculate percent GC
                my $percent_GC = calcgc($row);

                # round the percent GC
                my $percentGC_rounded = sprintf( "%0.1f", $percent_GC );

                # push gc% and length into arrays
                push @gc_content, $percentGC_rounded;
                push @read_len,   length($row);
            }
            elsif ( $counter % 2 == 0 ) {

                # Calculate phred score
                my $calc_phred = phred_calc( $row, $self->{library_type} );

                # Calculate read probability
                my $calc_prob = prob_calc( $row, $self->{library_type} );

                # push phred and prob into arrays
                push @phred, $calc_phred;
                push @prob,  $calc_prob;
            }
        }
        close $fn;

        #add ref to phred score array into obj
        $self->{phreds} = \@phred;

        #add ref to phred score array into obj
        $self->{read_length} = \@read_len;

        # calulate the min, max, and average
        # for the gc% from array @gc_content
        my $min_gc = min(@gc_content);
        my $max_gc = max(@gc_content);
        my $avg_gc =
          scalar @gc_content
          ? ( sum(@gc_content) / ( scalar @gc_content ) )
          : 0;

        # calulate the min, max, and average
        # for the read length from array @read_len
        my $min_len = min(@read_len);
        my $max_len = max(@read_len);
        my $avg_len =
          scalar @read_len
          ? ( sum(@read_len) / ( scalar @read_len ) )
          : 0;

        # calulate the min, max, and average
        # for the phred scores from array @phred
        my $min_phred = min(@phred);
        my $max_phred = max(@phred);
        my $avg_phred =
          scalar @phred
          ? ( sum(@phred) / ( scalar @phred ) )
          : 0;

        # calulate the min, max, and average
        # for the read prob from array @prob
        my $min_prob = min(@prob);
        my $max_prob = max(@prob);
        my $avg_prob =
          scalar @prob
          ? ( sum(@prob) / ( scalar @prob ) )
          : 0;

        # print execution time
        my $duration = time - $self->{start};

        # Results Table:
        print "_________________________________________________________\n";
        print "fastQ_brew PRE-FILTERED SUMMARY TABLE:\n";
        print "_________________________________________________________\n";
        print "*********************************************************\n";

        # print total number of reads
        print "| Total reads    \t\t => ", scalar @gc_content, "\n";

        # print the min, max, and average
        print "| largest GC% value \t\t => ",  $max_gc, "%\n";
        print "| smallest GC% value \t\t => ", $min_gc, "%\n";
        print "| average GC% value \t\t => ", sprintf( "%0.1f", $avg_gc ),
          "%\n";

        print "*********************************************************\n";

        print "| largest read length value \t => ",  $max_len, " bases\n";
        print "| smallest read length value \t => ", $min_len, " bases\n";
        print "| average read length value \t => ",
          sprintf( "%0.1f", $avg_len ),
          " bases\n";

        print "*********************************************************\n";

        print "| largest read phred score \t => ",  $max_phred, "\n";
        print "| smallest read phred score \t => ", $min_phred, "\n";
        print "| average read phred score \t => ",
          sprintf( "%0.1f", $avg_phred ),
          "\n";

        print "*********************************************************\n";

        print "| largest read probability \t => ",  $max_prob, "\n";
        print "| smallest read probability \t => ", $min_prob, "\n";
        print "| average read probability \t => ",
          sprintf( "%0.1f", $avg_prob ),
          "\n";

        print "_________________________________________________________\n";
        print "_________________________________________________________\n";
    }

    $self->_de_duplex(%arg);
}

##################################

=head2 _de_duplex()

 Title   : _de_duplex
 Usage   : _de_duplex();
 Function: remove duplicate reads
 Returns : fastQ file with only singletons
 Args    : Y=yes, N=no

=cut

##################################

sub _de_duplex {
    my ( $self, %arg ) = @_;
    if ( $self->{de_duplex} eq "Y" ) {
        print "\nremoving duplicate reads...\n\n\n";
        my $temp;
        my @temp;

        my $no_dupes = "temp_";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $no_dupes
          or die "Cannot open $no_dupes: $!";

        my %seen;
        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            if ( !$seen{ $temp[1] }++ ) {

                # Print to new de-duplicated file.
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $no_dupes;
        close $fh;
        close $fh_out;

    }
    $self->_remove_n(%arg);
}
##################################

=head2 _remove_n()

 Title   : _remove_n()
 Usage   : $self->_remove_n(%arg)
 Function: option to remove reads with N's
 Returns : fastQ file
 Args    : Y=yes, N=no

=cut

##################################

sub _remove_n {
    my ( $self, %arg ) = @_;
    if ( $self->{remove_n} ne "N" ) {
        print "\nremoving reads with non-designated bases...\n\n\n";
        my $temp;
        my @temp;
        my $noN = "temp________";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $noN
          or die "Cannot open $noN: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            if ( $temp[1] !~ m/N/i ) {

                # Print to noN file
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $noN;
        close $fh;
        close $fh_out;
    }
    $self->_remove_adapter_left(%arg);
}

###################################

=head2 _remove_adapter_left()

 Title   : _remove_adapter_left
 Usage   : _remove_adapter_left();
 Function: option to remove specific adapters from left side 
 Returns : fastQ file
 Args    : string="GTCGAGT" and mismatches=integer

=cut

##################################

sub _remove_adapter_left {
    my ( $self, %arg ) = @_;
    if ( $self->{adapter_left} ne "N" ) {
        print "\nremoving left side adapters...\n\n\n";
        my $temp;
        my @temp;
        my $mis         = $self->{mismatches_l};
        my $pattern_    = $self->{adapter_left};
        my $pattern     = "\^" . $pattern_;
        my $pattern_len = length $pattern;

        my $no_adapters = "temp__";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $no_adapters
          or die "Cannot open $no_adapters: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            my $specificty = $temp[1];

            my $number_matches = adapter_check( $temp[1], $pattern, $mis );

            if ( $number_matches == 1 ) {

                # trim from left
                my $left_seq  = substr $temp[1], $pattern_len, length $temp[1];
                my $left_qual = substr $temp[3], $pattern_len, length $temp[3];

                # Print to trimmed file.
                print $fh_out "$temp[0]\n";
                print $fh_out "$left_seq\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$left_qual\n";

            }
            else {

                # Print to trimmed file.
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $no_adapters;
        close $fh;
        close $fh_out;
    }
    $self->_remove_adapter_right(%arg);
}

##################################

=head2 _remove_adapter_right()

 Title   : _remove_adapter_right
 Usage   : _remove_adapter_right();
 Function: option to remove specific adapters from right side 
 Returns : fastQ file
 Args    : string="GTCGAGT" and mismatches=integer

=cut

##################################

sub _remove_adapter_right {
    my ( $self, %arg ) = @_;
    if ( $self->{adapter_right} ne "N" ) {
        print "\nremoving right side adapters...\n\n\n";
        my $temp;
        my @temp;
        my $mis         = $self->{mismatches_r};
        my $pattern_    = $self->{adapter_right};
        my $pattern     = $pattern_ . "\?";
        my $pattern_len = length $pattern;

        my $no_adapters = "temp___";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $no_adapters
          or die "Cannot open $no_adapters: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            my $specificty = $temp[1];

            my $number_matches = adapter_check( $temp[1], $pattern, $mis );

            if ( $number_matches == 1 ) {

                # trim from right
                my $right_seq  = substr $temp[1], 0, -$pattern_len;
                my $right_qual = substr $temp[3], 0, -$pattern_len;

                # Print to trimmed file.
                print $fh_out "$temp[0]\n";
                print $fh_out "$right_seq\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$right_qual\n";

            }
            else {

                # Print to trimmed file.
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $no_adapters;
        close $fh;
        close $fh_out;
    }
    $self->_right_trim(%arg);
}

##################################

=head2 _right_trim()

 Title   : _right_trim()
 Usage   : $self->_right_trim(%arg)
 Function: option to remove right side bases from reads
 Returns : right trimmed fastQ file
 Args    : integer=yes, N=no

=cut

##################################

sub _right_trim {
    my ( $self, %arg ) = @_;
    if ( $self->{right_trim} ne "N" ) {
        print "\ntrimming fastQ file from right...\n\n\n";
        my $temp;
        my @temp;
        my $right_seq;
        my $right_qual;

        my $right_t = "temp_____";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $right_t
          or die "Cannot open $right_t: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            # trim from right
            $right_seq  = substr $temp[1], 0, -$self->{right_trim};
            $right_qual = substr $temp[3], 0, -$self->{right_trim};

            # Print to revcomp file.
            print $fh_out "$temp[0]\n";
            print $fh_out "$right_seq\n";
            print $fh_out "$temp[2]\n";
            print $fh_out "$right_qual\n";
        }
        $self->{in_file} = $right_t;
        close $fh;
        close $fh_out;

    }
    $self->_left_trim(%arg);
}

##################################

=head2 _left_trim()

 Title   : _left_trim()
 Usage   : $self->_left_trim(%arg)
 Function: option to remove left side bases from reads
 Returns : left trimmed fastQ file
 Args    : integer=yes, N=no

=cut

##################################

sub _left_trim {
    my ( $self, %arg ) = @_;
    if ( $self->{left_trim} ne "N" ) {
        print "\ntrimming fastQ file from left...\n\n\n";
        my $temp;
        my @temp;
        my $left_seq;
        my $left_qual;

        my $left_t = "temp______";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $left_t
          or die "Cannot open $left_t: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            # trim from left
            $left_seq  = substr $temp[1], $self->{left_trim}, length $temp[1];
            $left_qual = substr $temp[3], $self->{left_trim}, length $temp[3];

            # Print to left_trim file.
            print $fh_out "$temp[0]\n";
            print $fh_out "$left_seq\n";
            print $fh_out "$temp[2]\n";
            print $fh_out "$left_qual\n";
        }
        $self->{in_file} = $left_t;
        close $fh;
        close $fh_out;

    }
    $self->_prune_fastq(%arg);
}

##################################

=head2 _prune_fastq()

 Title   : _prune_fastq()
 Usage   : _prune_fastq();
 Function: option to remove reads below phred score
 Returns : pruned fastQ file
 Args    : integer=yes, N=no

=cut

##################################

sub _prune_fastq {
    my ( $self, %arg ) = @_;
    if ( $self->{qual_filter} ne "N" ) {
        print "\npruning fastQ file...\n\n\n";
        my $temp;
        my @temp;

        my $pruned = "temp____";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $pruned
          or die "Cannot open $pruned: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            my $temp_phred = phred_calc( $temp[3], $self->{library_type} );

            if ( $temp_phred > $self->{qual_filter} ) {

                # Print to trimmed file
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $pruned;
        close $fh;
        close $fh_out;

    }
    $self->_trim_length(%arg);
}

##################################

=head2 _trim_length()

 Title   : _trim_length()
 Usage   : $self->_trim_length(%arg)
 Function: option to remove reads below specified length
 Returns : trimmed fastQ file
 Args    : integer=yes, N=no

=cut

##################################

sub _trim_length {
    my ( $self, %arg ) = @_;
    if ( $self->{length_filter} ne "N" ) {
        print "\ntrimming fastQ file for read length...\n\n\n";
        my $temp;
        my @temp;
        my $pruned = "temp_______";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $pruned
          or die "Cannot open $pruned: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            if ( length( $temp[1] ) > $self->{length_filter} ) {

                # Print to trimmed file
                print $fh_out "$temp[0]\n";
                print $fh_out "$temp[1]\n";
                print $fh_out "$temp[2]\n";
                print $fh_out "$temp[3]\n";
            }
        }
        $self->{in_file} = $pruned;
        close $fh;
        close $fh_out;
    }
    $self->_convert_fasta(%arg);
}

##################################

=head2 _convert_fasta()

 Title   : _convert_fasta()
 Usage   : _convert_fasta();
 Function: option to convert fastQ file to fastA
 Returns : fastA file
 Args    : Y=yes, N=no

=cut

##################################

sub _convert_fasta {
    my ( $self, %arg ) = @_;
    if ( $self->{fasta_convert} eq "Y" ) {
        print "\nconverting fastQ file to fastA...\n\n\n";
        my $temp;
        my @temp;

        my $fasta = "fastA_convert.fa";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $fasta
          or die "Cannot open $fasta: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            # Print to fasta file.
            print $fh_out ">$temp[0]\n";
            print $fh_out "$temp[1]\n";
        }

        close $fh;
        close $fh_out;

    }
    $self->_reverse_comp(%arg);
}
##################################

=head2 _reverse_comp()

 Title   : _reverse_comp()
 Usage   : $self->_reverse_comp(%arg)
 Function: option to rev comp fastQ reads
 Returns : reverse complemented fastQ file
 Args    : Y=yes, N=no

=cut

##################################

sub _reverse_comp {
    my ( $self, %arg ) = @_;
    if ( $self->{rev_comp} eq "Y" ) {
        print "\nreverse complementing fastQ reads...\n\n\n";
        my $temp;
        my @temp;
        my $revComp;

        my $revcomp = "rev_comp.fastq";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $revcomp
          or die "Cannot open $revcomp: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            # rev comp the array element
            $temp[1] =~ tr/ATGCatgc/TACGtacg/;
            $revComp = reverse( $temp[1] );

            # Print to revcomp file.
            print $fh_out "$temp[0]\n";
            print $fh_out "$revComp\n";
            print $fh_out "$temp[2]\n";
            print $fh_out "$temp[3]\n";
        }

        close $fh;
        close $fh_out;

    }
    $self->_dna_rna(%arg);
}

##################################

=head2 _dna_rna()

 Title   : _dna_rna()
 Usage   : $self->_dna_rna(%arg)
 Function: option to convert dna to rna for fastQ reads
 Returns : RNA fastQ file
 Args    : Y=yes, N=no

=cut

##################################

sub _dna_rna {
    my ( $self, %arg ) = @_;
    if ( $self->{dna_rna} eq "Y" ) {
        print "\ntranscribing fastQ reads...\n\n\n";
        my $temp;
        my @temp;

        my $dna_to_rna = "dna_to_rna.fastq";
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";

        open my $fh_out, '>', $dna_to_rna
          or die "Cannot open $dna_to_rna: $!";

        while (<$fh>) {
            chomp( $temp[0] = $_ );
            chomp( $temp[1] = <$fh> );
            chomp( $temp[2] = <$fh> );
            chomp( $temp[3] = <$fh> );

            # transcribe the array element
            $temp[1] =~ tr/Tt/Uu/;

            # Print to RNA file.
            print $fh_out "$temp[0]\n";
            print $fh_out "$temp[1]\n";
            print $fh_out "$temp[2]\n";
            print $fh_out "$temp[3]\n";
        }

        close $fh;
        close $fh_out;

    }
    $self->_post_fastQ_brew(%arg);
}

##################################

=head2 _post_fastQ_brew()

 Title   : _post_fastQ_brew
 Usage   : _post_fastQ_brew();
 Function: runs the summary stats after filtering
 Returns : the stats
 Args    : $self, %arg

=cut

##################################

sub _post_fastQ_brew {
    my ( $self, %arg ) = @_;

    # calculate execution time
    $self->{start} = time;

    #finalize output
    my $clean_out = "fastQ_brew_output.fastq";
    open my $fqz, '<', $self->{in_file}
      or die "Cannot open $self->{in_file}: $!";

    open my $fqy, '>', $clean_out
      or die "Cannot open $clean_out: $!";

    while ( my $final_line = <$fqz> ) {
        print $fqy $final_line;
    }

    # close handles
    close $fqz;
    close $fqy;

    if ( $self->{summary} eq "Y" ) {

        # process fastq file
        open my $fh, '<', $self->{in_file}
          or die "Cannot open $self->{in_file}: $!";
        print "\nprocessing output file...\n";

        # new file will only contain the base pairs and quality scores
        my $new_file = $self->{file_path} . "new_temp_" . $self->{in_file};
        $self->{temp_file_post} = $new_file;
        open my $fn, '>', $new_file or die "Cannot open $new_file: $!";
        my $count;
        while ( my $line = <$fh> ) {
            $count++;
            if ( $count % 2 == 0 ) {
                print $fn $line;
            }
        }

        # close handles
        close $fh;
        close $fn;

        # open the newfile to read
        open my $fj, '<', $self->{temp_file_post}
          or die "Cannot open  $self->{temp_file_post}: $!";
        my $counter;

        # array container for reads gc%
        my @gc_content;

        # array container for reads lengths
        my @read_len;

        # array container for read phred scores
        my @phred;

        # array container for read probability
        my @prob;

        # the 1st line 3rd, lines etc.. (i.e. odd #'s) contain
        # the read sequence
        print "\ncalculating stats...\n\n\n";
        while ( my $row = <$fj> ) {
            chomp $row;
            $counter++;
            if ( $counter % 2 != 0 ) {

                # Calculate percent GC
                my $percent_GC = calcgc($row);

                # round the percent GC
                my $percentGC_rounded = sprintf( "%0.1f", $percent_GC );

                # push gc% and length into arrays
                push @gc_content, $percentGC_rounded;
                push @read_len,   length($row);
            }
            elsif ( $counter % 2 == 0 ) {

                # Calculate phred score
                my $calc_phred = phred_calc( $row, $self->{library_type} );

                # Calculate read probability
                my $calc_prob = prob_calc( $row, $self->{library_type} );

                # push phred and prob into arrays
                push @phred, $calc_phred;
                push @prob,  $calc_prob;
            }
        }
        close $fj;

        #add ref to phred score array into obj
        $self->{phreds} = \@phred;

        #add ref to phred score array into obj
        $self->{read_length} = \@read_len;

        # calulate the min, max, and average
        # for the gc% from array @gc_content
        my $min_gc = min(@gc_content);
        my $max_gc = max(@gc_content);
        my $avg_gc =
          scalar @gc_content
          ? ( sum(@gc_content) / ( scalar @gc_content ) )
          : 0;

        # calulate the min, max, and average
        # for the read length from array @read_len
        my $min_len = min(@read_len);
        my $max_len = max(@read_len);
        my $avg_len =
          scalar @read_len
          ? ( sum(@read_len) / ( scalar @read_len ) )
          : 0;

        # calulate the min, max, and average
        # for the phred scores from array @phred
        my $min_phred = min(@phred);
        my $max_phred = max(@phred);
        my $avg_phred =
          scalar @phred
          ? ( sum(@phred) / ( scalar @phred ) )
          : 0;

        # calulate the min, max, and average
        # for the read prob from array @prob
        my $min_prob = min(@prob);
        my $max_prob = max(@prob);
        my $avg_prob =
          scalar @prob
          ? ( sum(@prob) / ( scalar @prob ) )
          : 0;

        # print execution time
        my $duration = time - $self->{start};

        # Results Table:
        print "_________________________________________________________\n";
        print "fastQ_brew POST-FILTERED SUMMARY TABLE:\n";
        print "_________________________________________________________\n";
        print "*********************************************************\n";
        print "| Execution time \t\t => $duration secs\n";

        # print total number of reads
        print "| Total reads    \t\t => ", scalar @gc_content, "\n";

        # print the min, max, and average
        print "| largest GC% value \t\t => ",  $max_gc, "%\n";
        print "| smallest GC% value \t\t => ", $min_gc, "%\n";
        print "| average GC% value \t\t => ", sprintf( "%0.1f", $avg_gc ),
          "%\n";

        print "*********************************************************\n";

        print "| largest read length value \t => ",  $max_len, " bases\n";
        print "| smallest read length value \t => ", $min_len, " bases\n";
        print "| average read length value \t => ",
          sprintf( "%0.1f", $avg_len ),
          " bases\n";

        print "*********************************************************\n";

        print "| largest read phred score \t => ",  $max_phred, "\n";
        print "| smallest read phred score \t => ", $min_phred, "\n";
        print "| average read phred score \t => ",
          sprintf( "%0.1f", $avg_phred ),
          "\n";

        print "*********************************************************\n";

        print "| largest read probability \t => ",  $max_prob, "\n";
        print "| smallest read probability \t => ", $min_prob, "\n";
        print "| average read probability \t => ",
          sprintf( "%0.1f", $avg_prob ),
          "\n";

        print "_________________________________________________________\n";
        print "_________________________________________________________\n";
    }

    $self->_cleanup(%arg);
}

##################################

=head2 _cleanup()

 Title   : _cleanup()
 Usage   : _cleanup();
 Function: option to delete tmp files
 Returns : nothing
 Args    : Y=yes, N=no

=cut

##################################

sub _cleanup {
    my ( $self, %arg ) = @_;
    if ( $self->{cleanup} eq "Y" ) {

        # delete tmp file
        unlink $self->{temp_file};
        if ( $self->{temp_file_post} ) {
            unlink $self->{temp_file_post};
        }
        unlink "temp_";
        unlink "temp__";
        unlink "temp___";
        unlink "temp____";
        unlink "temp_____";
        unlink "temp______";
        unlink "temp_______";
        unlink "temp________";

        # TODO: glob all this
    }
    print "\n\nall done....\n\n";
}

##################################

=head2 DESTROY()

 Title   : DESTROY
 Usage   : DESTROY();
 Function: garbage collection
 Returns : nothing
 Args    : automatically called

=cut

##################################

sub DESTROY {
    my ( $self, %arg ) = @_;
    print "\n\nGarbage collection....\n\n";
}

##################################

=head2 get_lib_type()

 Title   : get_lib_type()
 Usage   : my $get_lib_type= $tmp->get_lib_type();
 Function: Retrieves the library type used
 Returns : A string of the type e.g. Sanger
 Args    : none

=cut

##################################

sub get_lib_type {
    my ($self) = @_;
    return $self->{library_type};
}

###################################

=head2 set_lib_type()

 Title   : set_lib_type()
 Usage   : my $set_lib_type = $tmp->set_lib_type("sanger");
 Function: Populates the $self->{lib_type} property
 Returns : $self->{lib_type}
 Args    : the lib as a string

=cut

##################################

sub set_lib_type {
    my ( $self, $value ) = @_;
    $self->{library_type} = $value;
    return $self->{library_type};
}

###################################

=head2 get_in_file()

 Title   : get_in_file()
 Usage   : my $get_in_file = $tmp->get_in_file();
 Function: Retrieves the input filename
 Returns : A string containing filename
 Args    : none

=cut

##################################

sub get_in_file {
    my ($self) = @_;
    return $self->{in_file};
}

###################################

=head2 set_in_file()

 Title   : set_in_file()
 Usage   : my $set_in_file= $tmp->set_in_file("myOutPutFile.txt");
 Function: Populates the $self->{in_file} property
 Returns : $self->{in_file}
 Args    : name of the user provided input file

=cut

##################################

sub set_in_file {
    my ( $self, $value ) = @_;
    $self->{in_file} = $value;
    return $self->{in_file};
}

###################################

=head2 get_de_duplex()

 Title   : get_de_duplex()
 Usage   : my $get_de_duplex= $tmp->get_de_duplex();
 Function: Retrieves the de_duplex choice 
 Returns : Y or N
 Args    : none

=cut

##################################

sub get_de_duplex {
    my ($self) = @_;
    return $self->{de_duplex};
}

###################################

=head2 set_de_duplex()

 Title   : set_de_duplex()
 Usage   : my $set_de_duplex= $tmp->set_de_duplex();
 Function: Sets the de_duplex choice 
 Returns : Populates the $self->{de_duplex} property
 Args    : Y or N

=cut

##################################

sub set_de_duplex {
    my ( $self, $value ) = @_;
    $self->{de_duplex} = $value;
    return $self->{de_duplex};
}

###################################

=head2 get_qual_filter()

 Title   : get_qual_filter()
 Usage   : my $get_qual_filter= $tmp->get_qual_filter();
 Function: Retrieves the qual filter used
 Returns : integer
 Args    : none

=cut

##################################

sub get_qual_filter {
    my ($self) = @_;
    return $self->{qual_filter};
}

###################################

=head2 set_qual_filter()

 Title   : set_qual_filter()
 Usage   : my $set_qual_filter= $tmp->set_qual_filter();
 Function: Sets the qual filter used
 Returns : Populates the $self->{qual_filter} property
 Args    : integer

=cut

##################################

sub set_qual_filter {
    my ( $self, $value ) = @_;
    $self->{qual_filter} = $value;
    return $self->{qual_filter};
}

###################################

=head2 get_len_filter()

 Title   : get_len_filte()
 Usage   : my $get_len_filte= $tmp->get_len_filte();
 Function: Retrieves the length filter
 Returns : integer
 Args    : none

=cut

##################################

sub get_len_filter {
    my ($self) = @_;
    return $self->{length_filter};
}

###################################

=head2 set_len_filter()

 Title   : set_len_filter()
 Usage   : my $set_len_filter= $tmp->set_len_filter();
 Function: Sets the len filter used
 Returns : Populates the $self->{length_filter} property
 Args    : integer

=cut

##################################

sub set_len_filter {
    my ( $self, $value ) = @_;
    $self->{length_filter} = $value;
    return $self->{length_filter};
}

###################################

=head2 get_adapter_l()

 Title   : get_adapter_l()
 Usage   : my $get_adapter_l= $tmp->get_adapter_l();
 Function: Retrieves the left adapter specified 
 Returns : A string of the left adapater
 Args    : none

=cut

##################################

sub get_adapter_l {
    my ($self) = @_;
    return $self->{adapter_left};
}

###################################

=head2 set_adapter_l()

 Title   : set_adapter_l()
 Usage   : my $set_adapter_l= $tmp->set_adapter_l();
 Function: Sets the $self->{adapter_left} property
 Returns : Populates the $self->{adapter_left} property
 Args    : string

=cut

##################################

sub set_adapter_l {
    my ( $self, $value ) = @_;
    $self->{adapter_left} = $value;
    return $self->{adapter_left};
}

###################################

=head2 get_adapter_r()

 Title   : get_adapter_r()
 Usage   : my $get_adapter_r= $tmp->get_adapter_r();
 Function: Retrieves the right adapter specified 
 Returns : A string of the right adapater
 Args    : none

=cut

##################################

sub get_adapter_r {
    my ($self) = @_;
    return $self->{adapter_right};
}

###################################

=head2 set_adapter_r()

 Title   : set_adapter_r()
 Usage   : my $set_adapter_r= $tmp->set_adapter_r();
 Function: Sets the $self->{adapter_right} property
 Returns : Populates the $self->{adapter_right} property
 Args    : string

=cut

##################################

sub set_adapter_r {
    my ( $self, $value ) = @_;
    $self->{adapter_right} = $value;
    return $self->{adapter_right};
}

###################################

=head2 get_left_trim()

 Title   : get_left_trim()
 Usage   : my $get_left_trim= $tmp->get_left_trim();
 Function: Retrieves the left trim number
 Returns : integer
 Args    : none

=cut

##################################

sub get_left_trim {
    my ($self) = @_;
    return $self->{left_trim};
}

###################################

=head2 set_left_trim()

 Title   : set_left_trim()
 Usage   : my $set_left_trim = $tmp->set_left_trim();
 Function: Populates the $self->{left_trim} property
 Returns : $self->{left_trim}
 Args    : integer

=cut

##################################

sub set_left_trim {
    my ( $self, $value ) = @_;
    $self->{left_trim} = $value;
    return $self->{left_trim};
}

###################################

=head2 get_right_trim()

 Title   : get_right_trim()
 Usage   : my $get_right_trim= $tmp->get_right_trim();
 Function: gets the right trim number
 Returns : integer
 Args    : none

=cut

##################################

sub get_right_trim {
    my ($self) = @_;
    return $self->{right_trim};
}

###################################

=head2 set_right_trim()

 Title   : set_right_trim()
 Usage   : my $set_right_trim = $tmp->set_right_trim();
 Function: Populates the $self->{right_trim} property
 Returns : $self->{right_trim}
 Args    : integer

=cut

##################################

sub set_right_trim {
    my ( $self, $value ) = @_;
    $self->{right_trim} = $value;
    return $self->{right_trim};
}

###################################

=head2 get_fasta()

 Title   : get_fasta()
 Usage   : my $get_fasta= $tmp->get_fasta();
 Function: Retrieves the get_fasta option
 Returns : Y or N
 Args    : none

=cut

##################################

sub get_fasta {
    my ($self) = @_;
    return $self->{fasta_convert};
}

###################################

=head2 set_fasta()

 Title   : set_fasta()
 Usage   : my $set_fasta = $tmp->set_fasta();
 Function: Populates the $self->{fasta_convert} property
 Returns : $self->{fasta_convert}
 Args    : a command to execute fastA convert or not: Y=yes, N=no

=cut

##################################

sub set_fasta {
    my ( $self, $value ) = @_;
    $self->{fasta_convert} = $value;
    return $self->{fasta_convert};
}

###################################

=head2 get_rev_com()

 Title   : get_rev_com()
 Usage   : my $get_rev_com= $tmp->get_rev_com();
 Function: Retrieves the rev_comp option
 Returns : Y or N
 Args    : none

=cut

##################################

sub get_rev_com {
    my ($self) = @_;
    return $self->{rev_comp};
}

###################################

=head2 set_rev_com()

 Title   : set_rev_com()
 Usage   : my $set_rev_com = $tmp->set_rev_com();
 Function: Populates the $self->{rev_comp} property
 Returns : $self->{rev_comp}
 Args    : a command to execute rev_comp or not: Y=yes, N=no

=cut

##################################

sub set_rev_com {
    my ( $self, $value ) = @_;
    $self->{rev_comp} = $value;
    return $self->{rev_comp};
}

###################################

=head2 get_remove_n()

 Title   : get_remove_n()
 Usage   : my $get_remove_n= $tmp->get_remove_n();
 Function: Retrieves the command for N removal reads
 Returns : Y or N
 Args    : none

=cut

##################################

sub get_remove_n {
    my ($self) = @_;
    return $self->{remove_n};
}

###################################

=head2 set_remove_n()

 Title   : set_remove_n()
 Usage   : my $set_remove_n = $tmp->set_remove_n();
 Function: Populates the $self->{remove_n} property
 Returns : $self->{remove_n}
 Args    : a command to remove reads with N or not: Y=yes, N=no

=cut

##################################

sub set_remove_n {
    my ( $self, $value ) = @_;
    $self->{remove_n} = $value;
    return $self->{remove_n};
}

###################################

=head2 get_cleanup()

 Title   : get_cleanup()
 Usage   : my $get_cleanup = $tmp->get_cleanup();
 Function: returns the value option for cleanup
 Returns : Y or N
 Args    : none

=cut

###################################

sub get_cleanup {
    my ($self) = @_;
    return $self->{cleanup};
}

###################################

=head2 set_cleanup()

 Title   : set_cleanup()
 Usage   : my $set_cleanup = $tmp->set_cleanup("Y");
 Function: Populates the $self->{cleanup} property
 Returns : $self->{cleanup}
 Args    : a command to execute cleanup or not: Y=yes, N=no

=cut

###################################

sub set_cleanup {
    my ( $self, $value ) = @_;
    $self->{cleanup} = $value;
    return $self->{cleanup};
}

###################################
###################################

=head1 LICENSE AND COPYRIGHT

 Copyright (C) 2017 Damien M. O'Halloran
 GNU GENERAL PUBLIC LICENSE

=cut

1;
