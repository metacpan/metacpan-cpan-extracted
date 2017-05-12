#!/usr.bin/perl -w
use strict;
use warnings;


use Test::More tests=>10;
use Util::XML_YAML_Perl;

use Data::Dumper;


sub class_under_test { 

    my $module_name='Util::XML_YAML_Perl';
    return $module_name;

}


my $obj=Util::XML_YAML_Perl->new();

my $module_name=class_under_test();
isa_ok($obj,$module_name);

{
    no warnings;
    no strict qw(refs);
    my $func_called;
    my @new_args;
    my @xmlin_args;

    local  *XML::Simple::new = sub {  shift;@new_args=@_;$func_called->{new}++;return bless {}, 'XML::Simple';};
    local  *XML::Simple::XMLin= sub { shift;@xmlin_args=@_; $func_called->{XMLin}++;return {op=>'xmldata'};};

    my $test_args= ['file_name', [qw/option1 option2/]];
    my $return_val=$obj->xml_to_perl(@$test_args);

    my @want_new_args=qw/option1 option2/;
    my @want_xmlin_args=('file_name');
    my $want_return_val={op=>'xmldata'};

    is_deeply(\@new_args,\@want_new_args,'xml_to_perl() - arguments to XML::Simple passed correctly');
    is_deeply(\@xmlin_args,\@want_xmlin_args,'xml_to_perl() - arguments to XML::Simple::XMLin passed correctly');
    is_deeply($return_val,$want_return_val,'xml_to_perl() - values returned correctly');

    my $func_called_want={new=>1,XMLin=>1};
    is_deeply($func_called,$func_called_want,'xml_to_perl() - all functions called correctly');


    ##testing perl_to_yaml
    my $perl_ref= {apple => 'good', banana => 'bad', cauliflower => 'ugly'};

    undef $func_called;
    my $got_args;

    my $func_name=$module_name."::Dump";
    local *{$func_name}=sub {$got_args=shift;$func_called->{Dump}++;return 'test_string';};
    local *YAML::AppConfig::new= sub { my ($c, %h)=@_;$func_called->{new}++;return bless {args=>\%h},'YAML::AppConfig';};


    my $yaml_ref=$obj->perl_to_yaml($perl_ref);

    my $want_args=$perl_ref;
    is_deeply($got_args,$want_args,'perl_to_yaml() - arguments passed correctly into sub');
    is_deeply($yaml_ref->{args},{string=>'test_string'},'perl_to_yaml() - arguments passed correctly into YAML::AppConfig new()');


    my $file_got;
    local *YAML::AppConfig::dump= sub { shift;$func_called->{DumpFile}++;$file_got=shift;};

    $yaml_ref=$obj->perl_to_yaml($perl_ref,'test_file');
    is_deeply($file_got,'test_file','perl_to_yaml() - arguments passed correctly into dump()');

    isa_ok($yaml_ref,'YAML::AppConfig','perl_to_yaml() - returned YAML::AppConfig obj');
    
    $func_called_want={new=>2,DumpFile=>1,Dump=>2};
    is_deeply($func_called,$func_called_want,'xml_to_perl() - all functions called correctly');




}




