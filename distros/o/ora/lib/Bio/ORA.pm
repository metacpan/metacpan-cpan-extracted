#!/usr/bin/perl
# $Revision: 2.0 $
# $Date: 2016/06/15 $
# $Id: or.pl $
# $Author: Michael Bekaert $
#
# Olfactory Receptor family Assigner (ORA) [bioperl module]
# Copyright 2007-2016 Bekaert M <michael.bekaert@stir.ac.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# POD documentation - main docs before the code

=head1 NAME

Bio::ORA - Olfactory Receptor family Assigner (ORA) [bioperl module]

=head1 SYNOPSIS

Take a sequence object from, say, an inputstream, and find an Olfactory
Receptor gene. HMM profiles are used in order to identify location, frame
and orientation of such gene.

Creating the ORA object, eg:

  my $inputstream = Bio::SeqIO->new( -file => 'seqfile', -format => 'fasta' );
  my $seqobj = $inputstream->next_seq();
  my $ORA_obj = Bio::ORA->new( $seqobj );

Obtain an array holding the start point, the stop point, the DNA sequence
and amino-acid sequence, eg:

  my $array_ref = $ORA_obj->{'_result'} if ( $ORA_obj->find() );

Display result in genbank format, eg:

  $ORA_obj->show( 'genbank' );

=head1 DESCRIPTION

Bio::ORA is a featherweight object for identifying mammalian
olfactory receptor genes. The sequences should not be longer than 40kb. The
returned array include location, sequence and statistic for the putative
olfactory receptor gene. Fully functional with DNA and EST
sequence, no intron supported.

See Synopsis above for the object creation code.

=head1 DRIVER SCRIPT

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Bio::Seq;
  use Bio::ORA;

  my $inseq = Bio::SeqIO->new( '-file' => q{<} . $ARGV[0], -format => 'fasta' );
  while (my $seq = $inseq->next_seq) {
    my $ORA_obj = Bio::ORA->new( $seq );
    if ( $ORA_obj->find() ) {
      $ORA_obj->show( 'genbank' );
    } else {
      print {*STDOUT} "  no hit!\n";
    }
  }

=head1 REQUIREMENTS

To use this module you may need:
 * Bioperl (L<http://bioperl.org/>) modules,
 * HMMER v3+ distribution (L<http://hmmer.org/>) and
 * FASTA 36+ distribution (L<ftp://ftp.ebi.ac.uk/pub/software/unix/fasta/>).

=head1 LOCAL ADAPTATION

This module uses three softwares. If HMMER or FASTA are updated make sure that
HMMER's hmmscan and FASTA's tfastx36 and fastx36 still exists under these names.
You change the call my editing the "Default softwares" section.

  # Default softwares
  my $hmmscan = 'hmmscan';
  my $tfastx = 'tfastx36';
  my $fastx = 'fastx36';

=head1 FEEDBACK

If you have any problems with or questions about the scripts, please contact us
through a GitHub issue (L<https://github.com/pseudogene/ora/issues>). You are
invited to contribute new features, fixes, or updates, large or small; we are
always thrilled to receive pull requests, and do our best to process them as
fast as we can.

=head1 AUTHOR

B<Michael Bekaert> (michael.bekaert@stir.ac.uk)

Address:
     Institute of Aquaculture
     University of Stirling
     Stirling
     Scotland, FK9 4LA
     UK

=head1 SEE ALSO

perl(1), bioperl web site

=head1 LICENSE

Copyright 2007-2016 - Michael Bekaert

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal
methods are usually preceded with a _

=cut

package Bio::ORA;
use strict;
use warnings;
use vars qw($VERSION);
use File::Temp qw/tempfile/;
use File::Basename qw/ dirname /;
use Cwd qw/ abs_path /;
use Bio::SeqIO;
use Bio::Seq;
use Bio::SearchIO;
use Bio::PrimarySeq;
use Bio::PrimarySeqI;
use Bio::Tools::CodonTable;
use base qw/Bio::Root::Root Bio::Root::IO/;
our $VERSION = '2.0';

# Default softwares
my $hmmscan = 'hmmscan';
my $tfastx  = 'tfastx36';
my $fastx   = 'fastx36';

# Default path
my $PATH_REF = abs_path(dirname(abs_path($0)) . '/or.fasta');
my $PATH_HMM = abs_path(dirname(abs_path($0)) . '/or.hmm');
my $PATH_TMP = '/tmp';

=head2 _findexec

 Title   : _findexec
 Usage   : my $path = $self->_findexec( $exec );
 Function: Find an executable file in the $PATH.
 Returns : The full path to the executable.
 Args    : $exec (mandatory) executable to be find.

=cut

sub _findexec
{
    my ($self, @args) = @_;
    my $exec = shift @args;
    foreach my $p (split /:/, $ENV{'PATH'}) {
        return "$p/$exec"
          if (-x "$p/$exec");
    }
    return $ENV{'HOME'} . "/bin/$exec" if (-x $ENV{'HOME'} . "/bin/$exec");
    return;
}

=head2 new

 Title   : new
 Usage   : my $nb = Bio::ORA->new( $seqobj, $table, $aug, $hmm );
 Function: Initialize ORA object.
 Returns : An ORA object.
 Args    : $seqobj (mandatory) PrimarySeqI object (dna or rna),
           $table (optional) translation table/genetic code number,
              the default value is 1,
           $aug (optional) use other start codon than AUG (default 0),
           $hmm (optional) path to hmm profiles by default ORA looks at
             ./or.hmm.

=cut

sub new
{
    my ($class, @args) = @_;
    my ($seqobj, $table, $aug, $hmm) = @args;
    my $self = bless {}, $class;
    $self->{'_aug'} = ((defined $aug && int($aug) == 1) ? 0 : 1);
    $self->{'_hmm'} = ((defined $hmm) ? $hmm : $PATH_HMM);
    $seqobj->throw(
               "die in _initialize, ORA.pm works only on PrimarySeqI objects\n")
      unless ($seqobj->isa('Bio::PrimarySeqI'));
    $seqobj->throw("die in _initialize, ORA.pm works only on DNA sequences\n")
      if ($seqobj->alphabet eq 'protein');
    $seqobj->throw(
              "die in _initialize, ORA.pm works only on DNA sequences < 40kb\n")
      if (length($seqobj->seq()) > 40_000);
    $seqobj->throw('die in _initialize, hmm profile not found at '
                   . $self->{'_hmm'} . "\n")
      unless (-f $self->{'_hmm'});
    my $chrom =
      ((defined $seqobj->display_id) ? $seqobj->display_id : 'noname');
    $seqobj = uc $seqobj->seq();
    $seqobj =~ tr/U/T/;
    $chrom  =~ tr/,/\_/;
    $self->{'_seqref'} =
      Bio::Seq->new(-seq => $seqobj, -alphabet => 'dna', -id => $chrom);
    $self->{'_table'} = ((defined $table) ? $table : 1);
    $self->{'_verbose'} = q{};
    return $self;
}

=head2 find

 Title   : find
 Usage   : my $bool = $ORI_obj->find( $evalue, $strand, $start, $end );
 Function: Identify an olfactory receptor protein.
 Returns : boolean.
 Args    : $evalue (optional) set the E-value (expected) threshold.
             Default is 1e-30,
           $strand(optional) strand where search should be done (1 direct,
             -1 reverse or 0 both). Default is 0,
           $start (optional) coordinate of the first nucleotide. Useful
             for coordinate calculation when first is not 1. Default is 1,
           $end (optional) coordinate of the last nucleotide. Default is
             the sequence length.

=cut

sub find
{
    my ($self, @args) = @_;
    my ($evalue, $strand, $start, $end) = @args;
    $self->{'_evalue'} = ((defined $evalue) && ($evalue > 0)) ? $evalue : 1e-30;
    $strand = 0 unless ((defined $strand) && ($strand == 1 || $strand == -1));
    $start = 1 unless ((defined $start) && $start > 1);
    $end = $self->{'_seqref'}->length
      unless ((defined $end) && $end > 1 && $end > $start);
    my $status = $self->_what_or($strand);
    if (($status) && ($self->{'_hmmor'}[0] < $self->{'_evalue'}))
    {
        $self->{'_verbose'} = '> '
          . $self->{'_hmmor'}[1]
          . ' found ('
          . $self->{'_hmmor'}[0]
          . ') for '
          . $self->{'_seqref'}->display_id
          . ' in frame '
          . ($self->{'_hmmor'}[6] > 0 ? q{+} : q{-})
          . $self->{'_hmmor'}[2] . "\n";
        return $self->_find_orf($self->{'_hmmor'}[6], $start, $end);
    }
    else
    {
        $self->{'_verbose'} =
          '> no hit for ' . $self->{'_seqref'}->display_id . "\n";
    }
    return 0;
}

=head2 _what_or

 Title   : _what_or
 Usage   : my $bool = $self->_what_or( $strand );
 Function: Use HMM profiles to identify an olfactory receptor gene.
 Returns : boolean.
 Args    : $strand (optional) strand where search should be done
           (1 direct, -1 reverse or 0 both). Default is 0.

=cut

sub _what_or
{
    my ($self, @args) = @_;
    my $strand = shift @args;
    my ($best, $second);
    my $seq = $self->{'_seqref'};
    $seq = $seq->revcom if ($strand < 0);
    my ($TMP, $filename) = tempfile(DIR => $PATH_TMP, UNLINK => 1);
    for (my $i = 0 ; $i < 3 ; $i++)
    {
        print {$TMP} ">$i\n",
          $seq->translate(undef, undef, $i, $self->{'_table'})->seq(), "\n";
    }
    if ($strand == 0)
    {
        $seq = $seq->revcom;
        for (my $i = 0 ; $i < 3 ; $i++)
        {
            print {$TMP} ">$i-\n",
              $seq->translate(undef, undef, $i, $self->{'_table'})->seq(), "\n";
        }
    }
    close $TMP;
    my $pfam = $self->_findexec($hmmscan);
    if ((defined $seq) && (-x $pfam))
    {
        system $pfam . q{ }
          . $self->{'_hmm'} . q{ }
          . $filename . q{>}
          . $filename
          . '.report';
        eval
        {
            my $hmmer =
              Bio::SearchIO->new(-file   => $filename . '.report',
                                 -format => 'hmmer');
            while (my $result = $hmmer->next_result)
            {
                while (my $hit = $result->next_hit)
                {
                    while (my $hsp = $hit->next_hsp)
                    {
                        $self->{'_hmmor'} = (
                              [
                               $hsp->evalue(),
                               $hit->name,
                               substr($result->query_name(), 0, 1),
                               $hsp->score(),
                               $hsp->start('query'),
                               $hsp->end('query'),
                               (
                                ($strand != 0)
                                ? $strand
                                : ((length($result->query_name()) > 1) ? -1 : 1)
                               )
                              ]
                          )
                          if (!defined $self->{'_hmmor'}[0]
                              || $hsp->evalue() < $self->{'_hmmor'}[0]);
                        $best = $hsp->evalue()
                          if ((!defined $best) || $hsp->evalue() < $best);
                        $second = $hsp->evalue()
                          if ($hsp->evalue() > $best
                             && (!defined $second || $hsp->evalue() < $second));
                    }
                }
            }
            $self->{'_hmmor'}[7] = $second
              if (defined $best && defined $self->{'_hmmor'}[0]);
        };
        unlink $filename . '.report';
    }
    unlink $filename;
    return (defined $self->{'_hmmor'}[0]) ? 1 : 0;
}

=head2 _find_orf

 Title   : _find_orf
 Usage   : my $bool = $self->_find_or( $strand, $start, $end );
 Function: Retrieve the olfactory receptor ORF.
 Returns : boolean.
 Args    : $strand (mandatory) strand where ORA have been found
           (1 direct or -1 reverse),
           $start (mandatory) coordinate of the first nucleotide,
           $end (mandatory) coordinate of the last nucleotide.

=cut

sub _find_orf
{
    my ($self, @args) = @_;
    my ($strand, $start, $end) = @args;
    my ($position1, $position2);
    if ((defined $self->{'_hmmor'}) && (defined $self->{'_hmmor'}[0]))
    {
        my ($begin, $stop) = $self->_translation();
        my $seq = $self->{'_seqref'};
        $seq = $seq->revcom if ($strand < 0);
        $seq = $seq->seq();
        my ($i, $j) = 0;
        $self->{'_no5'} = 1 if ($self->{'_hmmor'}[4] < 9);
        my $mydna = substr $seq, 0,
          ($self->{'_hmmor'}[4] * 3 + abs($self->{'_hmmor'}[2]) + 9);
        if ($mydna =~ m/(($begin)((?!($stop|$begin))(.{3}))*?)$/o)
        {
            $position1 = length $`;
        }
        else
        {
            if ($mydna =~ m/(($stop)((?!($stop))(.{3}))*)$/o)
            {
                $position1 = 3 + length $`;
                $self->{'_noaug'} = 1;
            }
            elsif ($mydna =~ m/^(.{0,2})((.{3})*)$/o)
            {
                $position1 = length $1;
                $self->{'_noaug'} = 2;
            }
        }
        if (defined $position1)
        {
            $mydna = substr $seq, $position1;
            my ($coord, $dna, $stopcodon);
            if ($mydna =~ m/^(.{3})(((?!($stop))(.{3})){194,})($stop)/o)
            {
                $dna       = $1 . $2;
                $stopcodon = $6;
            }
            elsif ($mydna =~ m/^(.{3})(((?!($stop))(.{3})){194,})(.{0,2})$/o)
            {
                $self->{'_no3'} = 1;
                $dna            = $2;
                $stopcodon      = q{};
            }
            elsif ($mydna =~ m/($stop)(((?!($stop))(.{3})){194,})($stop)/o)
            {
                $self->{'_noaug'} = 1;
                $position1        = 3 + length $`;
                $dna              = $2;
                $stopcodon        = $6;
            }
            else
            {
                $dna = substr $seq, ($self->{'_hmmor'}[4] * 3) - 3,
                  (($self->{'_hmmor'}[5] - $self->{'_hmmor'}[4] + 1) * 3);
                $dna               = $1 if ($dna =~ m/^((.{3})*).{0,2}$/o);
                $position1         = $self->{'_hmmor'}[4] * 3;
                $self->{'_pseudo'} = 1;
                $stopcodon         = q{};
            }
            if (defined $dna)
            {
                if ($self->{'_hmmor'}[6] > 0)
                {
                    $position2 =
                      $start + $position1 + length($dna . $stopcodon) - 1;
                    $position1 = $start + $position1;
                    $coord =
                        ((defined $self->{'_no5'}) ? q{<} : q{})
                      . $position1 . '..'
                      . $position2
                      . ((defined $self->{'_no3'}) ? q{>} : q{});
                }
                else
                {
                    $position2 = $end - $position1;
                    $position1 =
                      $end - $position1 - length($dna . $stopcodon) + 1;
                    $coord =
                        'complement('
                      . ((defined $self->{'_no3'}) ? q{<} : q{})
                      . $position1 . '..'
                      . $position2
                      . ((defined $self->{'_no5'}) ? q{>} : q{}) . q{)};
                }
                if (defined $self->{'_frag'})
                {
                    $self->{'_pseudo'} = 0
                      if (($position2 - $position1 + 1) < $self->{'_frag'});
                }
                else
                {
                    $self->{'_pseudo'} = 0
                      if (($position2 - $position1 + 1) < 600);
                    $self->{'_pseudo'} = 0
                      if ( (($position2 - $position1 + 1) < 900)
                        && ($self->{'_hmmor'}[1] ne 'OR7')
                        && !(defined $self->{'_no5'} || defined $self->{'_no3'})
                      );
                    $self->{'_pseudo'} = 0
                      if ( (($position2 - $position1 + 1) < 800)
                        && ($self->{'_hmmor'}[1] eq 'OR7')
                        && !(defined $self->{'_no5'} || defined $self->{'_no3'})
                      );
                }
                $self->{'_result'} = (
                    [
                     $coord,
                     $position1,
                     $position2,
                     $self->{'_hmmor'}[6],
                     'Olfactory Receptor, family '
                       . substr($self->{'_hmmor'}[1], 2),
                     $self->{'_hmmor'}[1],
                     (
                      defined $self->{'_pseudo'}
                      ? 'Pseudogene (' . $self->{'_pseudo'} . '); '
                      : q{}
                     )
                       . (
                         (defined $self->{'_no5'})
                         ? 'The sequence seems incomplete, 5\' of the CDS is missing; '
                         : q{}
                       )
                       . (
                         (defined $self->{'_no3'})
                         ? 'The sequence seems incomplete, 3\' of the CDS is missing; '
                         : q{}
                       )
                       . (
                         !(defined $self->{'_pseudo'})
                           && (defined $self->{'_noaug'})
                         ? 'The position of the initiation codon is not identified; '
                         : q{}
                       )
                       . 'HMM for family '
                       . $self->{'_hmmor'}[1] . ': '
                       . $self->{'_hmmor'}[0] . ' ('
                       . ($self->{'_hmmor'}[7] - $self->{'_hmmor'}[0]) . q{)},
                     $dna . $stopcodon,
                     Bio::Seq->new(-seq => $dna, alphabet => 'dna')
                       ->translate(undef, undef, undef, $self->{'_table'})
                       ->seq()
                    ]
                ) if (defined $coord);
            }
        }
    }
    return (defined $position2) ? 1 : 0;
}

=head2 getHits

 Title   : getHits
 Usage   : my @hits = Bio::ORA->getHits( $seq, $evalue, $ref );
 Function: Quick localization of ORs (use FASTA).
 Returns : Array of hits start/stop positions.
 Args    : $seq (mandatory) primarySeqI object (dna or rna),
           $evalue (mandatory) det the E-value threshold,
           $ref (optional) path to fasta reference file, by default ORA
             look at ./or.fasta.

=cut

sub getHits
{
    my ($self, @args) = @_;
    my ($seq, $evalue, $ref) = @args;
    $ref = ((defined $ref) ? $ref : $PATH_REF);
    $evalue = ((defined $evalue) && ($evalue > 0)) ? $evalue : 1;
    my ($TMP, $filename) = tempfile(DIR => $PATH_TMP, UNLINK => 1);
    my $fasta = $self->_findexec($tfastx);
    my @hits;
    if ((defined $seq) && (-x $fasta))
    {
        print {$TMP} ">query\n", $seq->seq(), "\n\n";
        close $TMP;
        system(  $fasta
               . ' -Q -b 1 -d 1 -H '
               . $ref . q{ }
               . $filename . q{>}
               . $filename
               . '.report') == 0
          or return;
        eval
        {
            my $in = Bio::SearchIO->new(-format => 'fasta',
                                        -file   => $filename . '.report');
            while (my $result = $in->next_result)
            {
                while (my $hit = $result->next_hit)
                {
                    while (my $hsp = $hit->next_hsp)
                    {
                        push(
                             @hits,
                             (
                                  $hit->strand('query') . q{|}
                                . sprintf("%09d", $hsp->start('hit')) . q{|}
                                . sprintf("%09d", $hsp->end('hit'))
                             )
                            ) if ($hsp->evalue <= $evalue);
                    }
                }
            }
        };
        unlink $filename . '.report';
    }
    unlink $filename;
    if ($#hits >= 0)
    {
        @hits = sort @hits;
        my @hits2 = ();
        for (my $i = 0 ; $i < $#hits ; $i++)
        {
            my ($hitstrand, $hitstart, $hitend) = split /\|/, $hits[$i];
            my $loop = 0;
            do
            {
                $loop = 0;
                my ($hitstrand_n, $hitstart_n, $hitend_n);
                ($hitstrand_n, $hitstart_n, $hitend_n) =
                  split(/\|/, $hits[$i + 1])
                  if (defined $hits[$i + 1]);
                if (
                    (defined $hits[$i + 1])
                    && (   (abs($hitstart_n - $hitend) < 500)
                        || (abs($hitstart - $hitend_n) < 500)
                        || (   ($hitstart_n < $hitend)
                            && ($hitstart_n > $hitstart))
                        || (($hitend_n < $hitend) && ($hitend_n > $hitstart))
                        || (   ($hitstart < $hitend_n)
                            && ($hitstart > $hitstart_n))
                        || (($hitend < $hitend_n) && ($hitend > $hitstart_n)))
                    && ($hitstrand == $hitstrand_n)
                   )
                {
                    $i++;
                    $hitend   = $hitend_n   if ($hitend < $hitend_n);
                    $hitstart = $hitstart_n if ($hitstart > $hitstart_n);
                    $loop     = 1;
                }
            } until ($loop == 0);
            push @hits2,
              (   $hitstrand . q{|}
                . sprintf("%09d", $hitstart) . q{|}
                . sprintf("%09d", $hitend));
        }
        @hits = @hits2;
    }
    return @hits;
}

=head2 fastScan

 Title   : fastScan
 Usage   : my @hits = Bio::ORA->fastScan( $seq, $ref );
 Function: Quick localization of ORs (use FASTA).
 Returns : Array of hits start/stop positions.
 Args    : $seq (mandatory) primarySeqI object (dna or rna),
           $ref (optional) path to fasta reference file, by default ORA
             look at ./or.fasta.

=cut

sub fastScan
{
    my ($self,    @args) = @_;
    my ($seqfile, $ref)  = @args;
    $ref = ((defined $ref) ? $ref : $PATH_REF);
    my ($TMP, $filename) = tempfile(DIR => $PATH_TMP, UNLINK => 1);
    close $TMP;
    my $fasta = $self->_findexec($fastx);
    my @hits;
    if ((defined $seqfile) && (-x $fasta))
    {
        system(  $fasta
               . ' -b 1 -d 1 -E 1 -H -Q '
               . $seqfile . q{ }
               . $ref . q{>}
               . $filename) == 0
          or return;
        eval {
            my $in = Bio::SearchIO->new(-format => 'fasta', -file => $filename);
            my $last;
            while (my $result = $in->next_result)
            {
                push(@hits, $result->query_name())
                  if (!defined $last || $last ne $result->query_name());
                $last = $result->query_name();
            }
        };
    }
    unlink($filename);
    return @hits;
}

=head2 show

 Title   : show
 Usage   : $ORA_obj->show( $outstyle );
 Function: Print result in various style.
 Returns : none.
 Args    : $outstyle (mandatory) 'fasta', 'genbank', 'cvs', 'xml' or 'tsv' style.


=cut

sub show
{
    my ($self, @args) = @_;
    my $out = shift @args;
    $out = ((defined $out) ? $out : 'fasta');
    if ($out eq 'xml-begin')
    {
        print {*STDOUT} "<orml version=\"0.9\">\n";
        print {*STDOUT} " <analysis>\n";
        print {*STDOUT} "  <program>\n";
        print {*STDOUT} "   <prog-name>ORA.pm</prog-name>\n";
        print {*STDOUT} "   <prog-version>$VERSION</prog-version>\n";
        print {*STDOUT} "  </program>\n";
        print {*STDOUT} "  <date>\n";
        print {*STDOUT} '   <day>', (gmtime)[3], "</day>\n";
        print {*STDOUT} '   <month>', (gmtime)[4] + 1, "</month>\n";
        print {*STDOUT} '   <year>', (gmtime)[5] + 1900, "</year>\n";
        print {*STDOUT} "  </date>\n";
        print {*STDOUT} "  <parameter>\n";
        print {*STDOUT} '   <evalue>', shift(@args), "</evalue>\n";
        print {*STDOUT} '   <table>', shift(@args), "</table>\n";
        print {*STDOUT} "  </parameter>\n";
        print {*STDOUT} " </analysis>\n";
    }
    elsif ($out eq 'xml-end') { print {*STDOUT} "</orml>\n"; }
    elsif ((defined $self->{'_result'}) && (defined $self->{'_result'}[8]))
    {
        my $detail = shift @args;
        if ($out eq 'genbank')
        {
            my @dated = localtime time;
            my %month = (
                         0  => 'JAN',
                         1  => 'FEB',
                         2  => 'MAR',
                         3  => 'APR',
                         4  => 'MAY',
                         5  => 'JUN',
                         6  => 'JUL',
                         7  => 'AUG',
                         8  => 'SEP',
                         9  => 'OCT',
                         10 => 'NOV',
                         11 => 'DEC'
                        );
            printf {*STDOUT}
              "\nLOCUS       %-20s %7d bp            linear   UNA %02d-%3s-%04d\n",
              (
                $self->{'_seqref'}->display_id,
                $self->{'_seqref'}->length(),
                $dated[3], $month{$dated[4]}, $dated[5] + 1900
              );
            print {*STDOUT} 'ACCESSION   ', $self->{'_seqref'}->display_id,
              "\n";
            print {*STDOUT} 'DEFINITION  ', $self->{'_result'}[5], ".\n";
            print {*STDOUT}
              "KEYWORDS    .\nSOURCE      Unknown.\n  ORGANISM  Unknown\n            Unclassified.\n";
            print {*STDOUT} 'COMMENT     Method: ORA v', $VERSION, ".\n";
            print {*STDOUT} "FEATURES             Location/Qualifiers\n";
            print {*STDOUT} '     source          1..',
              $self->{'_seqref'}->length(), "\n";
            print {*STDOUT} '     gene            ',
              (
                ($self->{'_result'}[3] < 0)
                ? ('complement(<'
                   . $self->{'_result'}[1] . '..'
                   . $self->{'_result'}[2] . '>)')
                : (  q{<}
                   . $self->{'_result'}[1] . '..'
                   . $self->{'_result'}[2] . q{>})
              ),
              "\n";
            print {*STDOUT} '                     /locus_tag="',
              $self->{'_seqref'}->display_id, "\"\n";
            print {*STDOUT} '                     /gene="',
              $self->{'_result'}[5], "\"\n";
            print "                     /pseudo\n"
              if (defined $self->{'_pseudo'});
            print {*STDOUT} '                     /inference="',
              $self->{'_hmmor'}[1], ' family: ', $self->{'_hmmor'}[0], ' (',
              ($self->{'_hmmor'}[7] - $self->{'_hmmor'}[0]), ")\"\n";

            if ($detail)
            {
                my $dna = $self->{'_result'}[7] . q{"};
                print {*STDOUT} '                     /dna="',
                  substr($dna, 0, 52), "\n";
                my $i = 0;
                while (length($dna) > (($i * 58) + 52))
                {
                    print {*STDOUT} q{ } x 21,
                      substr($dna, (($i++ * 58) + 52), 58), "\n";
                }
            }
            print {*STDOUT} '     CDS             ', $self->{'_result'}[0],
              "\n";
            print {*STDOUT} '                     /locus_tag="',
              $self->{'_seqref'}->display_id, "\"\n";
            print {*STDOUT} '                     /gene="',
              $self->{'_result'}[5], "\"\n";
            my $note = $self->{'_result'}[6] . q{"};
            print {*STDOUT} '                     /note="',
              substr($note, 0, 51), "\n";
            my $i = 0;
            while (length($note) > (($i * 58) + 51))
            {
                print {*STDOUT} q{ } x 21,
                  substr($note, (($i++ * 58) + 51), 58), "\n";
            }
            print {*STDOUT} "                     /pseudo\n"
              if (defined $self->{'_pseudo'});
            print {*STDOUT} "                     /codon_start=1\n";
            print {*STDOUT} '                     /transl_table=',
              $self->{'_table'}, "\n";
            print {*STDOUT} '                     /product="',
              $self->{'_result'}[4],
              ((defined $self->{'_pseudo'}) ? ', pseudogene' : q{}), "\"\n";
            my $translation_issue = $self->{'_result'}[8] . q{"};
            print {*STDOUT} '                     /translation="',
              substr($translation_issue, 0, 44), "\n";
            $i = 0;

            while (length($translation_issue) > (($i * 58) + 44))
            {
                print {*STDOUT} q{ } x 21,
                  substr($translation_issue, (($i++ * 58) + 44), 58), "\n";
            }
            print {*STDOUT} "ORIGIN\n";
            my $dna = $self->{'_seqref'}->seq();
            my $j   = 0;
            while (length($dna) > ($j * 60))
            {
                $i = 0;
                printf {*STDOUT} '  %7d ', ($j * 60 + 1);
                while (length($dna) > ($j * 60 + $i * 10) && $i < 6)
                {
                    print {*STDOUT} substr($dna, ($j * 60 + $i++ * 10), 10),
                      q{ };
                }
                print {*STDOUT} "\n";
                $j++;
            }
            print {*STDOUT} "//\n";
        }
        elsif ($out eq 'tbl')
        {    # 'Feature Table' output (for tbl2asn, NCBI)
            my $organism = shift @args;
            print {*STDOUT} '>Feature ', $self->{'_seqref'}->display_id, "\n";
            print {*STDOUT} "<1\t>", $self->{'_seqref'}->length(), "\tgene\n";
            print {*STDOUT} "\t\t\tgene\t", $self->{'_result'}[5], "\n";
            print {*STDOUT} "\t\t\tlocus_tag\t", $self->{'_seqref'}->display_id,
              "\n";
            print {*STDOUT} "\t\t\tpseudo\n" if (defined $self->{'_pseudo'});
            print {*STDOUT} "\t\t\tnote\t", $self->{'_hmmor'}[1], ' family: ',
              $self->{'_hmmor'}[0], "\n";
            unless (defined $self->{'_pseudo'})
            {
                print {*STDOUT} "<1\t>", $self->{'_seqref'}->length(),
                  "\tCDS\n";
                print {*STDOUT} "\t\t\tcodon_start\t",
                  ((($self->{'_result'}[1]) % 3 == 0)
                    ? 3
                    : ($self->{'_result'}[1]) % 3), "\n";
                print {*STDOUT} "\t\t\ttransl_table\t", $self->{'_table'}, "\n";
                print {*STDOUT} "\t\t\tproduct\t", $self->{'_result'}[4], "\n";
            }
            print {*STDOUT} "\n";
            print {*STDERR} "\n>", $self->{'_seqref'}->display_id,
              ' [organism=', (defined $organism ? $organism : 'Unknown'), '] ',
              $self->{'_result'}[4], " gene member, partial cds.\n";
            my $i   = 0;
            my $dna = $self->{'_seqref'}->seq();
            while (length($dna) > ($i * 80))
            {
                print {*STDERR} substr($dna, ($i++ * 80), 80), "\n";
            }
        }
        elsif ($out eq 'csv')
        {    # CSV output
            print {*STDOUT} $self->{'_seqref'}->display_id, q{,},
              ((defined $self->{'_pseudo'}) ? q{N} : q{Y}), q{,},
              ($self->{'_result'}[2] - $self->{'_result'}[1] + 1), q{,},
              substr($self->{'_hmmor'}[1], 2), q{,}, $self->{'_hmmor'}[0], q{,},
              $self->{'_hmmor'}[7], q{,}, $self->{'_result'}[7], q{,},
              $self->{'_result'}[8], "\n";
        }
        elsif ($out eq 'tsv')
        {    # numeric TSV aka R output
            print {*STDOUT} $self->{'_seqref'}->display_id, "\t",
              ((defined $self->{'_pseudo'}) ? q{0} : q{1}), "\t",
              ($self->{'_result'}[2] - $self->{'_result'}[1] + 1), "\tOR",
              sprintf("%02d", substr($self->{'_hmmor'}[1], 2)), "\t",
              $self->{'_hmmor'}[0], "\t",
              ((defined $self->{'_pseudo'}) ? $self->{'_pseudo'} : q{0}), "\n";
        }
        elsif ($out eq 'xml')
        {
            print {*STDOUT} ' <sequence id="', $self->{'_seqref'}->display_id,
              ".seq\">\n";
            print {*STDOUT} "  <input>\n";
            print {*STDOUT} '   <seq type="dna" length="',
              $self->{'_seqref'}->length, '">', $self->{'_seqref'}->seq,
              "</seq>\n";
            print {*STDOUT} "  </input>\n";
            print {*STDOUT} '  <output id="', $self->{'_seqref'}->display_id,
              "\">\n";
            print {*STDOUT} '   <gene id="', $self->{'_seqref'}->display_id,
              ".1\">\n";
            print {*STDOUT} '    <coord',
              (defined $self->{'_no5'}) ? ' 5prime="missing"' : q{},
              (defined $self->{'_no3'}) ? ' 3prime="missing"' : q{}, q{>},
              (
                ($self->{'_result'}[3] < 0)
                ? ('complement('
                   . ((defined $self->{'_no3'}) ? q{<} : q{})
                   . $self->{'_result'}[1] . '..'
                   . $self->{'_result'}[2]
                   . ((defined $self->{'_no5'}) ? q{>} : q{}) . q{)})
                : (  ((defined $self->{'_no5'}) ? q{<} : q{})
                   . $self->{'_result'}[1] . '..'
                     . $self->{'_result'}[2]
                     . ((defined $self->{'_no3'}) ? q{>} : q{}))
              ),
              "</coord>\n";
            print {*STDOUT} '    <name>', $self->{'_result'}[5], "</name>\n";
            print {*STDOUT} '    <seq type="dna" length="',
              length($self->{'_result'}[7]), '">', $self->{'_result'}[7],
              "</seq>\n";
            print {*STDOUT} "   </gene>\n";
            print {*STDOUT} '   <cds id="', $self->{'_seqref'}->display_id,
              ".2\">\n";
            print {*STDOUT} '    <coord',
              (defined $self->{'_noaug'}) ? ' start="unknown"'  : q{},
              (defined $self->{'_no5'})   ? ' 5prime="missing"' : q{},
              (defined $self->{'_no3'})   ? ' 3prime="missing"' : q{}, q{>},
              $self->{'_result'}[0], "</coord>\n";
            print {*STDOUT} '    <name>', $self->{'_result'}[5], "</name>\n";
            print {*STDOUT} '    <note>', $self->{'_result'}[6], "</note>\n";
            print {*STDOUT} '    <product>', $self->{'_result'}[4],
              "</product>\n";
            print {*STDOUT} '    <seq type="prt" length="',
              length($self->{'_result'}[8]), '">', $self->{'_result'}[8],
              "</seq>\n";
            print {*STDOUT} '    <model hmm="', $self->{'_hmmor'}[1], '">',
              $self->{'_hmmor'}[0], "</model>\n";
            print {*STDOUT} "   </cds>\n";
            print {*STDOUT} "  </output>\n";
            print {*STDOUT} " </sequence>\n";
        }
        else
        {    # fasta format
            print {*STDOUT} "\n>", $self->{'_seqref'}->display_id, q{|},
              $self->{'_result'}[5],
              ((defined $self->{'_pseudo'}) ? '|PSEUDOGENE' : q{}), "\n";
            my $i = 0;
            while (length($self->{'_result'}[7]) > ($i * 80))
            {
                print {*STDOUT} substr($self->{'_result'}[7], ($i++ * 80), 80),
                  "\n";
            }
        }
    }
    return;
}

=head2 _translation

 Title   : _translation
 Usage   : my ( $start, $end ) = $self->_translation();
 Function: format initiation and stop codons for regex.
 Returns : array with initiation and stop codons.
 Args    : none.

=cut

sub _translation
{
    my $self         = shift;
    my @table        = qw(A T C G);
    my @var          = ();
    my @var2         = ();
    my $var_i        = 0;
    my $var2_i       = 0;
    my $myCodonTable = Bio::Tools::CodonTable->new(-id => $self->{'_table'});
    for (my $i = 0 ; $i < 4 ; $i++)
    {

        for (my $j = 0 ; $j < 4 ; $j++)
        {
            for (my $k = 0 ; $k < 4 ; $k++)
            {
                $var[$var_i++] = $table[$i] . $table[$j] . $table[$k]
                  if $myCodonTable->is_start_codon(
                                          $table[$i] . $table[$j] . $table[$k]);
                $var2[$var2_i++] = $table[$i] . $table[$j] . $table[$k]
                  if $myCodonTable->is_ter_codon(
                                          $table[$i] . $table[$j] . $table[$k]);
            }
        }
    }
    @var = ('ATG') if ($self->{'_aug'});
    return (join(q{|}, @var), join(q{|}, @var2));
}

# and that's all the module
1;
