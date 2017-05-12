#!/usr/bin/env perl
#
# Author: petr.danecek@sanger
#
# Usage: test.t [-d]
#

use strict;
use warnings;
use Carp;
use IPC::Open2;
use FindBin;
use lib "$FindBin::Bin";
use VCF;
use VCF::Reader;

BEGIN {
    use Test::Most tests => 57;
}

my $path = $FindBin::RealBin;

my $debug = ($ARGV[0] && $ARGV[0] eq '-d') ? 1 : 0;

test_validator($path,"$path/../examples/valid-3.3.vcf");
test_validator($path,"$path/../examples/valid-4.0.vcf");
test_validator($path,"$path/../examples/valid-4.1.vcf");
test_validator($path,"$path/../examples/floats.vcf");
test_format_validation($path,'3.3');
test_format_validation($path,'4.0');
test_format_validation($path,'4.1');
test_parse($path);
test_empty_cols($path,'4.0');
test_api_event_type([qw(A C),'s 1 C'],[qw(A ACGT),'i 3 CGT'],[qw(ACGT A),'i -3 CGT'],[qw(ACGT ACT),'i -1 G'],
    [qw(ACGT AAA),'o 3 AAA'],[qw(A .),'r 0 A'],[qw(A <ID>),'u 0 <ID>'],[qw(ACG AGC),'s 2 AGC'], [qw(A .A),'b'], [qw(A A.),'b']);
test_api();

exit;

#--------------------------------------

sub test_validator
{
    my ($path,$fname) = @_;

    my $cmd = "perl -I$path -MVCF -e validate $fname";
    my @out = `$cmd 2>&1`;
    my @exp = ();
    is_deeply(\@out,\@exp,"Testing validator .. $cmd");
}

sub test_format_validation
{
    my ($path,$version) = @_;

    my ($chld_in,$chld_out);
    my $cmd = "perl -I$path -MVCF -e validate 2>&1";
    my $pid = open2($chld_out, $chld_in, $cmd);

    my $vcf = VCF->new(version=>$version);
    $vcf->recalc_ac_an(2);
    $vcf->add_header_line({key=>'INFO', ID=>'AC',Number=>-1,Type=>'Integer',Description=>'Allele count in genotypes'});
    $vcf->add_header_line({key=>'INFO', ID=>'AN',Number=>1,Type=>'Integer',Description=>'Total number of alleles in called genotypes'});
    $vcf->add_header_line({key=>'FORMAT', ID=>'GT',Number=>1,Type=>'String',Description=>'Genotype'});
    if ( $version >= 4.0 )
    {
        $vcf->add_header_line({key=>'ALT',ID=>'DEL:ME:ALU', Description=>'Deletion of ALU element'});
    }
    if ( $version >= 4.1 )
    {
        $vcf->add_header_line({key=>'reference',value=>'file:/some/file.fa'});
        $vcf->add_header_line({key=>'contig',ID=>'1',length=>12345,md5=>'f126cdf8a6e0c7f379d618ff66beb2da',assembly=>'E.T.'});
    }
    $vcf->add_columns('NA0001','NA0002');
    print $vcf->format_header() unless !$debug;
    print $chld_in $vcf->format_header();

    my %rec = ( CHROM=>1, POS=>1, REF=>'A', QUAL=>$$vcf{defaults}{QUAL}, FORMAT=>['GT'] );
    $rec{gtypes}{NA0001}{GT} = 'A/A';
    $rec{gtypes}{NA0002}{GT} = $$vcf{defaults}{GT};
    $vcf->format_genotype_strings(\%rec);
    print $vcf->format_line(\%rec) unless !$debug;
    print $chld_in $vcf->format_line(\%rec);

    $rec{POS} = 2;
    $rec{gtypes}{NA0002}{GT} = 'IA|D1';
    if ( $version >= 4.0 )
    {
        $rec{REF} = 'AC';
        $rec{gtypes}{NA0002}{GT} = 'ATC|<DEL:ME:ALU>';
    }
    $vcf->format_genotype_strings(\%rec);
    print $vcf->format_line(\%rec) unless !$debug;
    print $chld_in $vcf->format_line(\%rec);
    close($chld_in);

    my @exp = ();
    my @out = ();
    while (my $line=<$chld_out>)
    {
        chomp($line);
        push @out,$line;
    }
    close($chld_out);
    waitpid $pid, 0;

    if ( !is_deeply(\@out,\@exp,"Testing formatting followed by validation .. $cmd") )
    {
        print STDERR @out;
    }
}

sub test_parse
{
    my ($path) = @_;
    my $vcf = VCF->new(file=>"$path/../examples/parse-test.vcf");
    $vcf->parse_header;
    my $line;
    $line = $vcf->next_data_array; is_deeply($$line[4],"G","Testing next_data_array");
    $line = $vcf->next_data_array; is_deeply($$line[4],"G,<DEL2>,T,<DEL3>","Testing next_data_array");
    $line = $vcf->next_data_array; is_deeply($$line[4],"<DEL1>,G,<DEL2>,T","Testing next_data_array");
    $line = $vcf->next_data_array; is_deeply($$line[4],"<DEL1>,G,<DEL2>,T,<DEL3>","Testing next_data_array");
}

sub test_empty_cols
{
    my ($path,$version) = @_;

    my ($header,$vcf,@out,$exp);

    $vcf = VCF->new(version=>$version);
    $vcf->add_header_line({key=>'FORMAT', ID=>'GT',Number=>1,Type=>'String',Description=>'Genotype'});
    $vcf->add_columns(qw(CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  NA0001));
    $header = $vcf->format_header();
    @out = split(/\n/,$header);
    $exp = join("\t",qw(CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  NA0001));
    is_deeply($out[-1],'#'.$exp,"Testing add_columns with genotypes full, $version.");

    $vcf = VCF->new(version=>$version);
    $vcf->add_header_line({key=>'FORMAT', ID=>'GT',Number=>1,Type=>'String',Description=>'Genotype'});
    $vcf->add_columns('NA0001');
    $header = $vcf->format_header();
    @out = split(/\n/,$header);
    $exp = join("\t",qw(CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  NA0001));
    is_deeply($out[-1],'#'.$exp,"Testing add_columns with genotypes brief, $version.");

    $vcf = VCF->new(version=>$version);
    $vcf->add_header_line({key=>'FORMAT', ID=>'GT',Number=>1,Type=>'String',Description=>'Genotype'});
    $vcf->add_columns();
    $header = $vcf->format_header();
    @out = split(/\n/,$header);
    $exp = join("\t",qw(CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO));
    is_deeply($out[-1],'#'.$exp,"Testing add_columns brief, $version.");

    $vcf = VCF->new(version=>$version);
    $vcf->add_header_line({key=>'FORMAT', ID=>'GT',Number=>1,Type=>'String',Description=>'Genotype'});
    $vcf->add_columns('FORMAT');
    $header = $vcf->format_header();
    @out = split(/\n/,$header);
    $exp = join("\t",qw(CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO FORMAT));
    is_deeply($out[-1],'#'.$exp,"Testing add_columns no gtypes, $version.");
}

sub test_api_event_type
{
    my (@subs) = @_;
    my $vcf = VCF->new();
    for my $mut (@subs)
    {
        my $exp = join(' ', $vcf->event_type($$mut[0],$$mut[1]));
        is_deeply($$mut[2],$exp,"Testing API event_type($$mut[0],$$mut[1]) .. $exp");
    }
}

sub test_api
{
    my $vcf = VCF->new();

    my $ret;
    my $fmt = 'GT:GL:PL';
    $ret = $vcf->get_tag_index($fmt,'GT',':'); is($ret,0,"Testing get_tag_index($fmt,'GT',':')");
    $ret = $vcf->get_tag_index($fmt,'GL',':'); is($ret,1,"Testing get_tag_index($fmt,'GL',':')");
    $ret = $vcf->get_tag_index($fmt,'PL',':'); is($ret,2,"Testing get_tag_index($fmt,'PL',':')");

    $ret = $vcf->remove_field($fmt,0,':'); is($ret,'GL:PL',"Testing get_tag_index($fmt,0,':')");
    $ret = $vcf->remove_field($fmt,1,':'); is($ret,'GT:PL',"Testing get_tag_index($fmt,1,':')");
    $ret = $vcf->remove_field($fmt,2,':'); is($ret,'GT:GL',"Testing get_tag_index($fmt,2,':')");

    $ret = $vcf->replace_field($fmt,'XX',0,':'); is($ret,'XX:GL:PL',"Testing get_tag_index($fmt,'XX',0,':')");
    $ret = $vcf->replace_field($fmt,'XX',1,':'); is($ret,'GT:XX:PL',"Testing get_tag_index($fmt,'XX',1,':')");
    $ret = $vcf->replace_field($fmt,'XX',2,':'); is($ret,'GT:GL:XX',"Testing get_tag_index($fmt,'XX',2,':')");
    $ret = $vcf->replace_field($fmt,'XX',4,':'); is($ret,'GT:GL:PL::XX',"Testing get_tag_index($fmt,'XX',4,':')");

    $ret = $vcf->decode_genotype('C',[qw(G T)],'0/1/2|1/0|1|2'); is($ret,'C/G/T|G/C|G|T',"Testing decode_genotype('C',['G','T'],'0/1/2|1/0|1|2')");
    $ret = $vcf->decode_genotype('C',[qw(G T)],'2|1'); is($ret,'T|G',"Testing decode_genotype('C',['G','T'],'2|1')");
    $ret = $vcf->decode_genotype('C',[qw(G T)],'2'); is($ret,'T',"Testing decode_genotype('C',['G','T'],'2')");

    my $info = 'NS=2;HM;AF=0.333;AFA=T;DB';
    $ret = $vcf->get_info_field($info,'NS');  is($ret,'2',"Testing get_info_field($info,'NS')");
    $ret = $vcf->get_info_field($info,'AF');  is($ret,'0.333',"Testing get_info_field($info,'AF')");
    $ret = $vcf->get_info_field($info,'AFA'); is($ret,'T',"Testing get_info_field($info,'AFA')");
    $ret = $vcf->get_info_field($info,'HM');  is($ret,'1',"Testing get_info_field($info,'HM')");
    $ret = $vcf->get_info_field($info,'DB');  is($ret,'1',"Testing get_info_field($info,'DB')");
    $ret = $vcf->get_info_field($info,'DBX'); is($ret,undef,"Testing get_info_field($info,'DBX')");
    $ret = $vcf->get_info_field('DB','DB'); is($ret,'1',"Testing get_info_field('DB','DB')");
    $ret = $vcf->get_info_field('XDB','DB'); is($ret,undef,"Testing get_info_field('XDB','DB')");

    my @ret;
    @ret = $vcf->split_gt('0/1'); is_deeply(\@ret,[0,1],"Testing split_gt('0/1')");
    @ret = $vcf->split_gt('0'); is_deeply(\@ret,[0],"Testing split_gt('0')");

    my @als;
    @als = ("TTGGTAT","TTGGTATCTAGTGGTAT,TGGTATCTAGTGGTAT"); @ret = $vcf->normalize_alleles(@als);
    is_deeply(\@ret,["T","TTGGTATCTAG","TGGTATCTAG"],"Testing normalize_alleles(".join(',',@als).")");
    @als = ("TT","TCTAGTGGTAAT,TCT"); @ret = $vcf->normalize_alleles(@als);
    is_deeply(\@ret,["T","TCTAGTGGTAA","TC"],"Testing normalize_alleles(".join(',',@als).")");
    @als = ("TGGGGGG","TGGGGGGG"); @ret = $vcf->normalize_alleles(@als);
    is_deeply(\@ret,["T","TG"],"Testing normalize_alleles(".join(',',@als).")");
    @als = ("CAAAAAA","CAAAAA"); @ret = $vcf->normalize_alleles(@als);
    is_deeply(\@ret,["CA","C"],"Testing normalize_alleles(".join(',',@als).")");
    @als = ("CA","CT"); @ret = $vcf->normalize_alleles(@als);
    is_deeply(\@ret,["CA","CT"],"Testing normalize_alleles(".join(',',@als).")");
    @als = ("GAACCCACA","GA"); @ret = $vcf->normalize_alleles_pos(@als);
    is_deeply(\@ret,[0,"GAACCCAC","G"],"Testing normalize_alleles_pos(".join(',',@als).")");
    @als = ("CAGTAAAA","CAGAAAA"); @ret = $vcf->normalize_alleles_pos(@als);
    is_deeply(\@ret,[2,"GT","G"],"Testing normalize_alleles_pos(".join(',',@als).")");
    @als = ("CAGTAAA","CAGAAAA"); @ret = $vcf->normalize_alleles_pos(@als);
    is_deeply(\@ret,[3,"T","A"],"Testing normalize_alleles_pos(".join(',',@als).")");
    @als = ("GA","GACC"); @ret = $vcf->normalize_alleles_pos(@als);
    is_deeply(\@ret,[1,"A","ACC"],"Testing normalize_alleles_pos(".join(',',@als).")");
}

1;
