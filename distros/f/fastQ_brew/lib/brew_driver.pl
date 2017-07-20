#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long 'HelpMessage';
use fastQ_brew;

GetOptions(
    'i=s'        => \my $in_file,
    'lib=s'      => \my $lib,
    'path=s'     => \my $file_path,
    'smry'       => \my $summary,
    'dup'        => \my $dedup,
    'qf=i'       => \my $qf,
    'lf=i'       => \my $lf,
    'trim_l=i'   => \my $trim_L,
    'trim_r=i'   => \my $trim_R,
    'adpt_l=s'   => \my $l_adapt,
    'adpt_r=s'   => \my $r_adapt,
    'mis_l=i'    => \my $mis_L,
    'mis_r=i'    => \my $mis_R,
    'fasta'      => \my $fasta_convert,
    'rna'        => \my $dna_rna,
    'rev_comp'   => \my $reverse_comp,
    'no_n'       => \my $remove,
    'clean'      => \my $clean_tmp,
    'help'       =>   sub { HelpMessage(0) },
) or HelpMessage(1);

HelpMessage(1) unless $in_file;


my $tmp = fastQ_brew->new();

$tmp->load_fastQ_brew(
    library_type  => $lib,
    file_path     => $file_path,
    in_file       => $in_file,
    summary       => $summary,
    de_duplex     => $dedup,
    qual_filter   => $qf,
    length_filter => $lf,
    adapter_left  => $l_adapt,
    mismatches_l  => $mis_L,
    adapter_right => $r_adapt,
    mismatches_r  => $mis_R,
    left_trim     => $trim_L,
    right_trim    => $trim_R,
    fasta_convert => $fasta_convert,
    dna_rna       => $dna_rna,
    rev_comp      => $reverse_comp,
    remove_n      => $remove,
    cleanup       => $clean_tmp
);

$tmp->run_fastQ_brew();


=head1 NAME

=head1 SYNOPSIS

  --i, input file (required)
  --lib, library type  (default is sanger)       
  --path, path to input fiile (defaults to cwd)
  --smry, return summary statistics 
  --dup, remove duplicate reads
  --qf, filter by read quality
  --lf, filter by read length
  --trim_l, trim reads starting at left end
  --trim_r, trim reads starting at left end
  --adpt_l, remove a left end adapter 
  --mis_l, permit mismatches between left end adapter and read      
  --adpt_r, remove a right end adapter
  --mis_r, permit mismatches between left end adapter and read
  --fasta, convert to fastA format 
  --rna, convert reads to RNA
  --rev_comp, reverse complement reads
  --no_n, remove non-designated bases from reads
  --clean, remove temp files
  --help, Print this help

=cut
