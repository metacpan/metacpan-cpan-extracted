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
use strict;
use warnings;
use Getopt::Long;
use File::Basename qw/ dirname /;
use Cwd qw/ abs_path /;
use Bio::Seq;
use Bio::SeqIO;
use Bio::ORA;

#----------------------------------------------------------
my $VERSION = '2.0';

#----------------------------------------------------------
sub hmm_disc
{
    my (
        $seq,    $name,   $id,  $translate, $evalue,
        $format, $detail, $aug, $hmm,       $filter,
        $frag,   $subset, $organism
       ) = @_;
    my $chrom;
    if    (defined $name)            { $chrom = $name . q{_} . $id; }
    elsif (defined $seq->display_id) { $chrom = $seq->display_id; }
    else                             { $chrom = 'noname_' . $id; }
    $seq->display_id($chrom);
    my $ora_obj = Bio::ORA->new($seq, $translate, $aug, $hmm);
    $ora_obj->{'_frag'} = $frag if (defined $frag);

    if (
        $ora_obj->find($evalue)
        && (
            !(defined $filter)
            || (   (defined $filter)
                && (substr($ora_obj->{'_hmmor'}[1], 2) == $filter))
           )
       )
    {

        if (defined $subset)
        {
            my $out =
              Bio::SeqIO->new('-format' => 'fasta', '-file' => ">>$subset");
            $out->write_seq($seq);
        }
        $ora_obj->show($format, $detail, $organism);
    }
    return $ora_obj->{'_verbose'};
}

sub fasta_filter
{
    my (
        $seq,    $ref,    $id,  $translate, $evalue,
        $format, $detail, $aug, $hmm,       $filter,
        $frag,   $subset, $organism
       ) = @_;
    my $mess = '* FASTA search for ' . $seq->display_id . "\n";
    my @hits = Bio::ORA->getHits($seq, 1, $ref);
    if ($#hits >= 0)
    {
        for (my $i = 0 ; $i <= $#hits ; $i++)
        {
            my ($hitstrand, $hitstart, $hitend) = split m/\|/, $hits[$i];
            my $seqstart = $hitstart - 250;
            $seqstart = 1 if ($seqstart < 1);
            my $seqend = $hitend + 250;
            $seqend = $seq->length() if ($seqend > $seq->length());
            my $seq_or = Bio::Seq->new(
                                  -seq      => $seq->subseq($seqstart, $seqend),
                                  -alphabet => 'dna',
                                  -id       => $seq->display_id . ":$seqstart-$seqend"
                                      );
            my $ora_obj = Bio::ORA->new($seq_or, $translate, $aug, $hmm);
            $ora_obj->{'_frag'} = $frag if (defined $frag);

            if (
                $ora_obj->find($evalue, $hitstrand, $seqstart, $seqend)
                && (
                    !(defined $filter)
                    || (   (defined $filter)
                        && (substr($ora_obj->{'_hmmor'}[1], 2) == $filter))
                   )
               )
            {

                if (defined $subset)
                {
                    my $out =
                      Bio::SeqIO->new('-format' => 'fasta',
                                      '-file'   => ">>$subset");
                    $out->write_seq($seq_or);
                }
                $ora_obj->show($format, $detail, $organism);
            }
            $mess .= q{ } . $ora_obj->{'_verbose'};
        }
    }
    else { $mess = '* No FASTA hit for ' . $seq->display_id . "\n"; }
    return $mess;
}

#------------------------ Main ----------------------------
my (
    $infile, $translate, $name,   $filter, $subset,
    $aug,    $frag,      $resume, $organism
   );
my ($evalue, $contigs, $verbose, $detail, $format, $out, $hmm, $ref) = (
                                   1e-10, 0, 0, 0, 'fasta', 1,
                                   abs_path(dirname(abs_path($0)) . '/or.hmm'),
                                   abs_path(dirname(abs_path($0)) . '/or.fasta')
                                                                       );
GetOptions(
           'sequence:s'  => \$infile,
           'hmmfile:s'   => \$hmm,
           'fastafile:s' => \$ref,
           'organism:s'  => \$organism,
           'c!'          => \$contigs,
           'a!'          => \$aug,
           'format:s'    => \$format,
           'expect:f'    => \$evalue,
           'name:s'      => \$name,
           'table:i'     => \$translate,
           'filter:i'    => \$filter,
           'sub:s'       => \$subset,
           'resume:s'    => \$resume,
           'd!'          => \$detail,
           'v!'          => \$verbose,
           'size:i'      => \$frag
          );
$format = lc $format;
if (
       (defined $infile)
    && (-r $infile)
    && (defined $hmm)
    && (-r $hmm)
    && (defined $hmm)
    && (-r $hmm)
    && (  !(defined $translate)
        || ((defined $translate) && ($translate =~ m/([1-9]|1[1-6]|2[12])/)))
    && (!(defined $filter) || ((defined $filter) && ($filter =~ m/^\d+$/)))
    && ($format =~ m/^fasta|genbank|csv|tsv|xml|tbl$/)
   )
{
    $translate = 1 unless (defined $translate);
    print {*STDERR}
      "\n..:: Olfactory Receptor Assigner (ORA) v$VERSION ::..\n\n"
      if ($verbose);
    if ($contigs)
    {
        $out--;
        my $id = 0;
        my @prehits = Bio::ORA->fastScan($infile, $ref);
        if (
            ($#prehits >= 0)
            && (my $inseq =
                Bio::SeqIO->new('-file' => "<$infile", '-format' => 'fasta'))
           )
        {
            print {*STDERR} $#prehits, " Informative contigs\n" if ($verbose);
            my $myresume = shift @prehits;
            while (my $seq = $inseq->next_seq)
            {
                my $mess;
                next
                  if (!(defined $myresume) || ($myresume ne $seq->display_id));
                $myresume = shift @prehits;
                next
                  if (   (defined $resume)
                      && !$id
                      && ($resume ne $seq->display_id));
                $id++;
                if (length($seq->seq()) > 2500)
                {
                    $mess = fasta_filter(
                                         $seq,    $ref,    $id,     $translate,
                                         $evalue, $format, $detail, $aug,
                                         $hmm,    $filter, $frag,   $subset,
                                         $organism
                                        );
                }
                else
                {
                    $mess = hmm_disc(
                                     $seq,       $name,   $id,
                                     $translate, $evalue, $format,
                                     $detail,    $aug,    $hmm,
                                     $filter,    $frag,   $subset,
                                     $organism
                                    );
                }
                print {*STDERR} $mess if ($verbose && defined $mess);
            }
        }
    }
    elsif (my $inseq =
           Bio::SeqIO->new('-file' => "<$infile", '-format' => 'fasta'))
    {
        $out--;
        my $id = 0;
        while (my $seq = $inseq->next_seq)
        {
            my $mess;
            next
              if ((defined $resume) && !$id && ($resume ne $seq->display_id));
            $id++;
            if (length($seq->seq()) > 2500)
            {
                $mess = fasta_filter(
                                     $seq,       $ref,    $id,
                                     $translate, $evalue, $format,
                                     $detail,    $aug,    $hmm,
                                     $filter,    $frag,   $subset,
                                     $organism
                                    );
            }
            else
            {
                $mess = hmm_disc(
                                 $seq,    $name,   $id,     $translate,
                                 $evalue, $format, $detail, $aug,
                                 $hmm,    $filter, $frag,   $subset,
                                 $organism
                                );
            }
            print {*STDERR} $mess if ($verbose && defined $mess);
        }
    }
    else { print {*STDERR} "FATAL: Incorrect file format.\n"; }
    print {*STDERR} "\n" if ($verbose);
}
else
{
    print {*STDERR}
      "\n..:: Olfactory Receptor Assigner (ORA) v$VERSION ::..\n\nFATAL: Incorrect arguments.\nUsage: or.pl [-options] --sequence=<sequence fasta file>\n\nOptions\n -a\n    Force the use of alternative start codons, according to the current genetic code.\n    Otherwise, ATG is the only initiation codon allow.\n --expect\n    Set the E-value threshold. This setting specifies the statistical significance\n    threshold for reporting matches against database sequences. [Default $evalue].\n --format\n    Available output format [Default $format]:\n      fasta (FASTA format)\n      csv (Comma-separated values)\n      genbank (GenBank format)\n      tsv (Direct output for R)\n      tbl (GenBank TBL format)\n -c\n    When using a large number of contigs (e.g. newly sequenced genome), proceed to an\n    initial FASTA search to identify the contigs where to run the actual ORA search.\n --filter\n    Show ONLY the selected family number.\n --sub\n    Extract the sequences of the Fasta hits.\n --name\n    Overwrite the sequence name by the provided one. Otherwise the program will use the\n    sequence name from as input.\n --table\n    Force a genetic code to be used for the translation of the query. [Default 1]\n --size\n    Filter fragments over the specified size as functional.\n -d\n    Print all sequence details.\n\nAdvance options\n --resume\n    Resume the search from given sequence name.\n --hmmfile\n    Provide alternative HMM profiles.\n    [Default $hmm]\n --fastafile\n    Provide alternative reference OR sequences (fasta format).\n    [Default $ref]\n -v\n    Print more possibly useful stuff, such as the individual scores for each sequence.\n\n";
    $out++;
}
exit $out;
