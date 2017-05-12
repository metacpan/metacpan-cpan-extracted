#!/usr/bin/perl -w

use XML::MetaGenerator;
use XML::MetaGenerator::Formula;
use XML::MetaGenerator::Formula::Collector::ReadLine;
use XML::MetaGenerator::Formula::Generator::SimpleHTML;

my $wow = XML::MetaGenerator->get_instance();
$wow->setObject($ARGV[0]);
$wow->setLanguage(XML::MetaGenerator::Formula->new());

my $input = XML::MetaGenerator::Formula::Collector::ReadLine->new();
$wow->setCollector($input);

my $generator = XML::MetaGenerator::Formula::Generator::SimpleHTML->new();
$wow->setGenerator($generator);

$wow->collect();

foreach (keys %{$wow->{form}}) {
  print "$_\t=>\t".$wow->{form}->{$_}."\n";
}

my ($valids, $missings, $invalids)= $wow->validate();

print "This elements are valid:\n";
foreach (keys %{$valids}) {
  print "$_ => '".$ {$valids}{$_}."'\n";
}
print "This elements are missing:\n";
foreach (@{$missings}) {
  print "$_\n";
}
print "This elements are invalid:\n";
foreach (@{$invalids}) {
  print "$_\n";
}

open OUT, ">page.html";
my $page =  $wow->generate();
print OUT "$page";


