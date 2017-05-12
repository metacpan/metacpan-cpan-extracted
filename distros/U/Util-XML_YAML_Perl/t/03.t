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
    my $func_called;
    my $got_yaml_ref;
    local *YAML::Load = sub { $got_yaml_ref=shift;$func_called->{Load}++;};
    my $return_val=$obj->yaml_to_perl("a\nb");

    is_deeply($got_yaml_ref,"a\nb",'yaml_to_perl() - arguments passed into Load()');
    local *YAML::LoadFile = sub { $got_yaml_ref=shift;$func_called->{LoadFile}++;};
    $return_val=$obj->yaml_to_perl("./t/test_file");
    is_deeply($got_yaml_ref,"./t/test_file",'yaml_to_perl() - arguments passed into LoadFile()');
    eval { $return_val=$obj->yaml_to_perl("c"); };
    like($EVAL_ERROR,qr/YAML file\/string not found for conversion/,'yaml_to_perl() -YAML not found');
    is_deeply($func_called,{Load=>1,LoadFile=>1},'yaml_to_perl() - all functions called correctly');

    undef $func_called;
    my $got_args_out;
    my @got_args_new;
    local *YAML::Load = sub { $got_yaml_ref=shift;$func_called->{Load}++;return 'perl_ref';};
    local *XML::Simple::new= sub {shift;@got_args_new=@_;$func_called->{new}++;return bless {},'XML::Simple'; };
    local *XML::Simple::XMLout = sub {  shift; $got_args_out=shift; $func_called->{out}++; return 1;};
    $return_val=$obj->yaml_to_xml("a\nb",[qw/a b/]);

    is_deeply($got_yaml_ref,"a\nb",'yaml_to_xml() - arguments passed into Load()');
    is_deeply(\@got_args_new,[qw/a b/],'yaml_to_xml() - arguments passed correctly into new()');
    is_deeply($got_args_out,'perl_ref','yaml_to_xml() - arguments passed correctly into XMLout()');

    $return_val=$obj->yaml_to_xml("./t/test_file");
    is_deeply($got_yaml_ref,"./t/test_file",'yaml_to_xml() - arguments passed into LoadFile()');


    local *XML::Simple::XMLout = sub {  shift; $got_args_out=shift; $func_called->{out}++; return 0;};
    eval { $return_val=$obj->yaml_to_xml("a\nb",[qw/a b/]); };
    like($EVAL_ERROR,qr/No such file or directory/,'yaml_to_xml() - XMLout died');
    is_deeply($func_called,{'out' => 3,'new' => 3,'Load' => 2,'LoadFile' => 1 },'yaml_to_xml() - all functions called correctly');
}

