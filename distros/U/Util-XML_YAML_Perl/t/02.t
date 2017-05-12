#!/usr.bin/perl -w
use strict;
use warnings;
use English;

use Test::More tests=>10;
use Util::XML_YAML_Perl;

use Data::Dumper;
my $module_name='Util::XML_YAML_Perl';
my $obj=Util::XML_YAML_Perl->new();

{
    no warnings;
    no strict;
    my $func_called;
    my @got_args;
    my @got_args_new;
    my $got_file_name;
    my $yaml_ref;
    local *XML::Simple::new= sub {shift;@got_args_new=@_;$func_called->{new}++;return bless {},'XML::Simple'; };
    my $p_Dump=$module_name."::Dump";
    local *{$p_Dump}=sub {@got_args=@_;$func_called->{Dump}++;return 'yaml_string';};
    local *YAML::AppConfig::new=sub {my ($c,%h)=@_;return bless {args=>\%h},'YAML::AppConfig';};
    local *XML::Simple::XMLin=sub { $func_called->{in}++;shift;$got_file_name=shift;return 'perl_ref';};

    $yaml_ref=$obj->xml_to_yaml('file',[qw/a b/]);

    is_deeply(\@got_args_new,[qw/a b/],'xml_to_yaml() - arguments passed correctly into new()');


    is_deeply($got_file_name,'file','xml_to_yaml() - arguments passed correctly into XMLin()');

    is_deeply(\@got_args,['perl_ref'],'xml_to_yaml() - arguments passed correctly into Dump');
    is_deeply($yaml_ref->{args},{string => 'yaml_string'},'xml_to_yaml() - arguments passed correctly into YAML::AppConfing::new()');
    isa_ok($yaml_ref,'YAML::AppConfig','xml_to_yaml() - returned YAML::AppConfig obj');
    is_deeply($func_called,{'Dump'=>1,'in' => 1,'new' => 1},'perl_to_xml() - all funcs called properly');

    undef $func_called;
    my $got_args_out;
    local *XML::Simple::XMLout = sub {  shift; $got_args_out=shift; $func_called->{out}++; return 1;};

    $xml=$obj->perl_to_xml('perl_ref',[qw/a b/]);

    is_deeply(\@got_args_new,[qw/a b/],'perl_to_xml() - arguments passed correctly into new()');
    is_deeply($got_args_out,'perl_ref','perl_to_xml() - arguments passed correctly into XMLout()');

    local *XML::Simple::XMLout = sub {  shift; $got_args_out=shift; $func_called->{out}++; return 0;};
    eval { $xml=$obj->perl_to_xml('perl_ref',[qw/a b/]); };
    
    like( $EVAL_ERROR, qr/No such file or directory at/,'perl_to_xml() - XMLout could not write file');
    is_deeply($func_called,{'out' => 2,'new' => 2},'perl_to_xml() - all funcs called properly');

}

