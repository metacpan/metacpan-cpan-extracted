#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok('XML::Loy');
use_ok('Test::XML::Loy');

my $t = Test::XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Test foo="bar">
  <baum>Check!</baum>
  <baum test="1">Hehe</baum>
</Test>
XML

$t->attr_is('Test', 'foo', 'bar')
  ->attr_isnt('Test', 'foo', 'foo')
  ->attr_like('Test', 'foo', qr!b.r!)
  ->attr_unlike('Test', 'foo', qr!x!)

  ->content_is(<<'XML')
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Test foo="bar">
  <baum>Check!</baum>
  <baum test="1">Hehe</baum>
</Test>
XML
  ->content_isnt('<test />')
  ->content_like(qr!<baum>Che!)
  ->content_unlike(qr!<tree>Che!)

  ->text_is('baum', 'Check!')
  ->text_isnt('baum', 'Hui!')
  ->text_like('baum', qr!Ch.*\!!)
  ->text_unlike('baum', qr!B!)

  ->text_is('Test baum', 'Check!')
  ->text_isnt('Test baum', 'Hui!')
  ->text_like('Test baum', qr!Ch.*\!!)
  ->text_unlike('Test baum', qr!B!)

  ->text_is('Test > baum', 'Check!')
  ->text_isnt('Test > baum', 'Hui!')
  ->text_like('Test > baum', qr!Ch.*\!!)
  ->text_unlike('Test > baum', qr!B!)

  ->element_count_is('Test > baum', 2)
  ->element_count_is('Test > baum[test=1]', 1)

  ->element_exists('Test > baum[test=1]')
  ->element_exists_not('Test > baum[test=2]')
  ;

$t = Test::XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<env>
  <header>
    <!-- My Greeting -->
    <greetings>
      <title style="color: red">Hello!</title>
    </greetings>
  </header>
  <body date="today">
    <p>That&#39;s all!</p>
  </body>
</env>
XML

$t->attr_is('env title', 'style', 'color: red')
  ->attr_is('env body', 'date', 'today')
  ->text_is('body > p', "That's all!");


my $loy = XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<env>
  <header>
    <!-- My Greeting -->
    <greetings>
      <title style="color: red">Hello!</title>
    </greetings>
  </header>
  <body date="today">
    <p>That&#39;s all!</p>
  </body>
</env>
XML

$t = Test::XML::Loy->new($loy);

$t->attr_is('env title', 'style', 'color: red')
  ->attr_is('env body', 'date', 'today')
  ->text_is('body > p', "That's all!");


done_testing;
__END__
