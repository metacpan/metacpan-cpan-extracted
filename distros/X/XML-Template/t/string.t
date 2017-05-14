#!/usr/bin/perl 


use strict;
use Test;
BEGIN { plan tests => 13 }

use XML::Template::Vars;
use XML::Template::Parser::String;


my $vars = XML::Template::Vars->new ();
$vars->create_context ();
$vars->set (scalar	=> 'SCALAR');
$vars->set (array	=> ['ZERO', 'ONE', 'TWO']);
$vars->set (hash	=> {key		=> 'KEY',
                            'back.dot'	=> {
                              key2		=> 'KEY2'
                            },
                            'back/slash'=> {
                              'key3'		=> 'KEY3',
                            }});
$vars->set (one		=> 'one');
$vars->set (test_one	=> 'test_one');
$vars->set (backdot	=> 'back.dot');
$vars->set (backslash	=> 'back/slash');
$vars->set (xml		=> qq{
<xml>
  <a>
    <b name="one">ONE</b>
    <b name="two">TWO</b>
    <b name="three">THREE</b>
    <b.1>B.1</b.1>
  </a>
</xml>
});

ok (1);
my $parser = XML::Template::Parser::String->new ();
ok ($parser);

my %strings = (
     '${scalar}'				=> 'SCALAR',
     '${array[1]}'				=> 'ONE',
     '${hash.key}'				=> 'KEY',

     '${test_${one}}'				=> 'test_one',

     '${hash.back\.dot.key2}'			=> 'KEY2',
     '${hash.{back.dot}.key2}'			=> 'KEY2',
     '${hash.{${backdot}}.key2}'		=> 'KEY2',
     '${hash.{${backslash}}.key3}'		=> 'KEY3',

     '${xml/xml/a/b[@name="one"]/text()}'	=> 'ONE',
     '${xml/xml/a/b[@name=\'one\']/text()}'	=> 'ONE',
     '${xml/xml/a/b.1/text()}'			=> 'B.1',
   );

while (my ($string, $val) = each %strings) {
#print "string $string\n";
  my $code = $parser->text ($string);
#print "code: $code\n";
  my $testval = eval $code;
  ok ($testval, $val);
}
