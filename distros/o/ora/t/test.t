#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
my ($input, $output) = (q{}, q{});
system
  'wget -q ftp://ftp.ensembl.org/pub/release-84/fasta/canis_familiaris/dna/Canis_familiaris.CanFam3.1.dna.chromosome.10.fa.gz >/dev/null 2>/dev/null';
system 'gunzip Canis_familiaris.CanFam3.1.dna.chromosome.10.fa.gz';
system
  './scripts/or.pl -v -a -d --sequence Canis_familiaris.CanFam3.1.dna.chromosome.10.fa > test.output';
unlink 'Canis_familiaris.CanFam3.1.dna.chromosome.10.fa';
if (open my $in, q{<}, 'test.output')
{
    while (<$in>)
    {
        chomp;
        $input .= $_;
    }
    close $in;
}
unlink 'test.output';
while (<DATA>)
{
    chomp;
    $output .= $_;
}
ok($input eq $output, 'Run test (dog chromosome 10)');
done_testing();
__DATA__
>10:36300-38053|OR6|PSEUDOGENE
GACTTTTTCCACGTCTTCCTGGAGGCTACAGAGTTCCTCCTCCTCACACCCAAGGCCTGTGACCACTACATTGCCATCTG
CCAGCCTCTCTGCTACCTCAGTGTCATGAGCAACAGAGTCTGCACACGGCTCATCCTCACCTGCTGGCTGGCAGGATTCT
CCTTCATCATCGTGCCTGTCATCCTGACCAGTCATCTTCCATTATGCAACACCCACATCAACCACTTCTTCTGTAACTAT
ATGCCTCTAATGGAAGTAGTGTGTAGCAGGCCACAAGTGTTAGAGGTGGTGGCTTTTACCCTGGCCATTGAGGCGCTGGT
CAGCACTGTATTGCTGATCACCATATCTTATGTCCAGATCATCCAGACCATTGTAAGGATCCCCTCTGTCCAGGAGAGAA
GGAAAGCTTTCTCTACCTCTTCTTCCCATATCATTGTGATCACCAGGTGCTATGACAGCTGCTTCTTCATGTATGTCAAG
CCCTCTCTAGGCAAGGGGGTTGATTTCAACAAAGGAGTGTCTGTAATCAATACAATTATTGCCCCCCTCTTGAATCCCTT
CATCTATACTCTCAGGAACCAACAAGTTAAGGAAGTAGTGAAAAACCTGATCAGGAAAATGGCTTGGATTCAAAATAAAT
GA

>10:50397-51767|OR10|PSEUDOGENE
CCTGGCCTCCCCATACCCCGGGCCATCTCCTTCCAGAGCTGTGTGGCCCAGATGTACGTCTTCATGGTCCTGGGCATCTC
AGAGTGCTGCCTCCTCACAGCCATGGCCTATGACCACTATGCAGCCATCTGTCAGCCCCTGCACTATGCCACCCTCATGA
GCTGGAGGGCCTGCACGGCTATGGTGGGTGTCTCCTGGCTCATGGGCATCGTCACAGCCACCACCCATTCCACTCTCATC
TTCACTCTGCCCTTCCCCAGCCACCCCATCATCCTGCACTTCCTCTGTGACATCCTGCCAGTACTGAGGCTGGCAAGTGC
TGGGAAACACGAGAGTGAAATCTCCGTGATGACAGCCACCGTGGTCTTCATCATGGTCCCCTTCTCTCTGATCATTGCCT
CTTATGCCTGCATTCTGAGTGCCAACCTGGCAATGGCCTCCACCCAGAGCCGTCACAAGGTCTTCTCTACTTGCTCCTCC
CACCTGCTTGTGGTCTTCCTCTTCTTTGGAACAGCCAGCATCACCTACATCCAGCCCCGGACTGGCTCCTCTGTTACCAT
GAACCGCATCCTCAGCCTCTTCTACACAGTCATCACACCCATGCTCAACCCCATCATCTACACCCTTCGCAACAAGGAGG
TGGCAAGGGCCCTGCAGCGCATGGTGAAGAGGGAGGTCTCCTCACCATGA

>10:16100952-16102398|OR6|PSEUDOGENE
TTGTGCAAGTCAAATATTTTTTTTGTTATTCTCTTTGGATCAACTGAATTTTTTCTCCTGGCCGCCATGTCCTATGATCG
CTATGTTGCTATCTGTAAACCACTTCATTACATGACCATCATGAGCAATAGGGTGTGTAGCTTATTAGTCTTCTGCTGTT
GGGTGTCTGGCTTGATGATCATTCTCCCACCCCCTAGCTTGTGCCTCCAGCTGGAATTTTGTGACTCCAATGCCATTGAT
CATTTTAGCTGTGATGCAGCTCCCCTCCTGAAGATCTCATGTTCAGATACATGGATGATAGAACAAATGGTTATCCTTGT
GGCTGTATTTGCACTCATTATCACCTTAGTGTGTGTATTTCTGTCCTACACATACATCATCAGGACCATTCTGAGATTCC
CCTCTGTCCAACAAAGAAAAAAGGCCTTTTCCACCTGCTCATCCCACATGATTGTAGTTTCCATCACCTATGGAAGCGGC
ATCTTCATCTATATCAAGCCATCAGCAAAAGAAGGGATAGCCATAAATAAAGGTGTTTCGGTGCTCACTACTTCTGTTGC
ACCCTTGCTGAACCCCTTCTTTTACACCTTAAGAAATAAGCAAGTGAAACAAGCTTTTAATGACTTCATAAAGAAGATGA
CATTTCACTCAAAGAAACTGAAGTTTTAA

>10:16133796-16135230|OR6|PSEUDOGENE
TTATAATGCTTGTGCTTGCCAAATATTTTTTATTGGGCTTTTTGGGGTCACAGAATTTTTTCTCCTGGCAGCCATGTCCT
ATGACCGCTATGTGGCCATCTGCAAACCCCTTCATTACATGACCATCATGAATAACAAAGTCTGTACCATCCTTGTCCAC
TGTTGCTGGATTTCTGTGCTGCTGATCATCATCACACCCCTTGGTATGGGCCTCCAGCTGGAATTCTGTGACTCCAATGC
CACTGATCATTTTGGCTGTGATGCATCTCCTCTTTTTAAGATTTCATGCTCGGATACATGGGTTATAGAACAGATGGTTA
TAATCTGTGCAGTACTGACATTCATTATTACACT

>10:16157829-16159267|OR6
ATGAGAAACCAAACGGCACTAACAACTTTCATCTTGCTGGGACTCACAGAGGACCCTCAACTAAAAATTTTGCTTTTTAT
GTTTCTGTTTCTTTCCTACATGTTGAATGTATCTGGAAACCTAACCATCATCATCCTCACTCTGATTGATTCCCACCTTA
AAACACCAATGTATCTTTTCCTCCAAAATTTCTCCTTCCTAGAAATTTCATTCACAACTGCTTGTGTCCCCAGATTTTTA
TATAGCATATCATCAGGGGACAAATCCATTACCTATAATGCTTGTGTCAGTCAACTGTTGTTTACAGACCTCTTTGCAGT
AACAGAATTTTTTCTCTTGGCCACTATGTCCTATGATCGCTATGTGGCCATCTGCAAACCCCTGCATTACATGACCATCA
TGAGCAGAAGAGTCTGCAAGAACTTCATCGTCTTCTGTTGGGTAGCAGCACTGATCATCATTCTCCCACCAATTAGTCTA
GGTTTGGGCCTGGAATTCTGTGATTCAAACATCATTGATCATTTTTGTTGTGATGCATCTCCTATCCTGAAGATCTCTTG
CTCAGACACATGGTTGATAGAACAGATGGTTATAGTCTGTGCTGTGTTGACATTCATCATCACCCTCATGTGTGTAGTTC
TTTCTTACATTTATATTATCGGGACCATTCTAAGGTTTCCCTCTGCTCAGCAAAGGAAAAAGGCCTTTTCCACTTGTTCT
TCCCACATGATTGTTGTTTCCATTACTTATGGTAGCTGTATCTTCATTTATGTCAAACCTTCAGCCAAGGATGAGGTAGC
TATTAATAAAGGGATTTCACTCCTTATTACTTCTATCTCACCAATGTTGAACCCCTTTATTTACACACTGAGAAACAAGC
AAGTGAAGAAAGCTTTTCATGATTCAATTAAAAAAATCGCATTCCTATCAAAGATGTAA

>10:16190982-16192432|OR6
ATGAGAAACGGTACAATAACAACATTCATTCTGCTGGGACTGACAGATGACCCTGAGCTGCAAGTTCTGATTTTTATCTT
TCTATTTCTCACCTACACTTTGAGTATAACTGGAAACCTGACCATCATCATACTCACTTTTGTGGATCCCCACCTTAAAA
CACCCATGTACTTTTTCTTAAAAAATTTCTCCTTCTTGGAGATCTCATTCACATCTGCCGTTATTCCCAGATATTTGTAT
AGCATAGCAACAGGTGACAATGTTATTACCTATAATGCTTGTGTCATTCAAGTGTTTTTTACTGACCTCTGTGGAGTATC
AGAGTTTTTTCTGCTGGCTGCCATGTCCTATGACCGCTATGTTGCCATCTGCAAACCCTTGCATTATGTGATCATAATGA
GTAACAGTGTCTGCAGGATTCTCAATATCTGTTGTTGGGTGGCTGGTTTATGTATAATAATCCCACCACTTAGCCTGGGT
TTAAATCTAAAATTTTGTGACTCTAACATAATTGATCATTTTGGCTGTGATGCATTTCCCTTAGTGAAAATCTCATGTTC
AGATACAAGGTTCATGGAATGGACAGTTATAATATGTGCCATACTGACCTTGAATATGACTCTTACCTGTGTGGTTCTGT
CATATGCTTACATCATCAAGACAATTTTTAGATTCCCTTCTGTTCAACAAAGAAAAAAGGCCTATTCGACCTGTTCTTCC
CACATGATTGTGGTATCCATCACCTATGGCACATGCATTTTCATCTATATGAATCCTACAGCAAAGGAAAAAGTGACCAT
TAATAAAGTGGTTTCACTGCTCATTTTTTCTATTTCACCTACATTGAACCCATTTATTTATACCTTGAGAAACAATCAAG
TTAAGAAAGCCTTCGAGGACTCAATCAAAAGAATTGCCTTGCTCTCAACTAAGTAA

>10:16269621-16270817|OR4|PSEUDOGENE
TTCTCACAGACACCACCTATCGAGGCAGGGGTATTTGTACTATTTATTTTCTTCTATGTGCCCACTTGGGTAGGCAATGT
CCTCATCTTGGTCACAGTAGCCTCTGATAACTATCTGAATTCATCACCCATGTATTTCCTTCTTGGCAACCCCTCTTTCC
TGGACTTACGTTATTCAACTATCCCTAAGCTTCTGGCTGACTTTCTTGATAATGAGAAGCTCATTCGCTATGGCCAATGC
ATTGTGCAGCTCTTCTTTCTGCATTTTGTAGGAGCAGTTGAGATGTTCCTGCTTACAGTGATGGCCTATGATCTTTATGT
TGCAATTTGTTGCCCTCTGCACTATACCACTATTATGAGTCAAGGATTACGCTGTATGTTGGTAGCTGCTTCCTGGATGG
GAGTGTTTGTG

>10:16269621-16270817|OR4|PSEUDOGENE
TTCTCACAGACACCACCTATCGAGGCAGGGGTATTTGTACTATTTATTTTCTTCTATGTGCCCACTTGGGTAGGCAATGT
CCTCATCTTGGTCACAGTAGCCTCTGATAACTATCTGAATTCATCACCCATGTATTTCCTTCTTGGCAACCCCTCTTTCC
TGGACTTACGTTATTCAACTATCCCTAAGCTTCTGGCTGACTTTCTTGATAATGAGAAGCTCATTCGCTATGGCCAATGC
ATTGTGCAGCTCTTCTTTCTGCATTTTGTAGGAGCAGTTGAGATGTTCCTGCTTACAGTGATGGCCTATGATCTTTATGT
TGCAATTTGTTGCCCTCTGCACTATACCACTATTATGAGTCAAGGATTACGCTGTATGTTGGTAGCTGCTTCCTGGATGG
GAGTGTTTGTG

>10:16453178-16454595|OR6
ATGAGAAACCATTCAACAGAAATAGAGTTTATTCTCATAAGACTGACGGATGACCCACAATTGCAAGTTGTGATTTTTGT
GTTTTTATTTCTTAATTACACATTGAGCCTGATGGGGAACTTAACCATTATCCTACTCACTCTGCTGGATCCTCACCTCA
AGATGCCAATGTATTTCTTTCTCTGTAATTTCTCATTTTTAGAAATCATATTCACAACGGTATGTATTCCCAGATACTTG
AAAACCATAGTGACTAAAGAACAAAACGTTTCATATAATAACTGTGTGGCTCAATTATTTTTTATTCTTTTACTGGGAGT
TGCAGAGTTTTACCTTCTGGCTGCTATGTCCTATGACCGCTATGTGGCCATCTGTAAACCCTTGCATTACCCAATCATTA
TGAACAGCAGAGTGTGCTATTGGCTTGTACTTTCTTCTTGGCTGACTGGATTCCTAATCATCTTTCCACCATTGCTCATG
GGACTCAAGCTGGATTTCTGTGCTTCCAAAACGATTGATCACTTTATGTTTCCCCCATCCTGCAGATATCCTGCACAGAC
ACACACACAATTTTATGTCCTAGAATTGATGTCTTTCATCTTCGCTGTGGTGACACTTGTGGTCACATTGGTGTTAGTGG
ATCTCTCCTACACTTGCATCATGAAGACCATTATGAAATTCCCTTCTGCACAGCAAAGGACCAAAGCTTTTTCCACCTGT
ACTTCCCATATGATTGTTGTCTCCATGACATATGGGAGCTACATCTTTATGTATATTAAGCCATCTGCCAAAGAAAGGGT
GACTGTATCCAAAGATGTAGCTTTGCTGTATACCTCAATTGCCCCTTTACTAAATCCCTTCATTTATATCCTAAGGAACC
AGCAGGTGAACGAAATCTTTTGCTCCTAA

>10:16496990-16498381|OR6|PSEUDOGENE
GGAAAACTGTACAACTGTGACAGTATTTATCTTAGCAGGATTGATGGAGGACCCAAAACTGAAGATTGTGCTATTTGTCT
TCCTGCTCCTCACCTGCTTGCTAAGAATCTCAGGCAACTTAGTTATTATTACCCTCACTTTGCTGGACTCACATCTCAAG
ACCCCTATGTATTTCTTTCTTTGAAATTTTTCTTTCTTAGAAATTTCTTATACGACAGTCTGCATCCCCAAATTGCTTGT
AAGCATGGCAACTGATGACAAAACCATTTCCTATAACTGTTGTGCAACTCAGTT

>10:16550166-16550923|OR6|PSEUDOGENE
ACTGATGGATGACCCAAAGTGGCAGGTCGTACTTTTCATATTTCTTCTTGTTACCTACATGTTCAGTGTGACTGGGAACC
TGGTCATTATCATCCTCACACTAACAGATCCCCACCTGAAGACTCTAATGTATTTCTTCCTTCGAAACTTCTCATTCCTA
GAAATGTCATTCACATCTGTTGCAATTCCCAGATTCCTTGTCACTGTTGTGACGGGAGACAAAACCATTTCCTACAATGA
CTGTCT
