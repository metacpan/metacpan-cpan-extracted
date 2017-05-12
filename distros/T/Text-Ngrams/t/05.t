#!/usr/bin/perl
# $Id: 05.t,v 1.3 2006/12/18 22:07:01 vlado Exp $

use Test::More tests => 5;
use_ok("Text::Ngrams");
require 't/auxfunctions.pl';

my $ng = Text::Ngrams->new(windowsize=>2, type=>'word');
$ng->process_files('t/05.in');
isn('t/03.out', $ng->to_string('orderby'=>'ngram'));

$ng = Text::Ngrams->new();
$ng->process_files('t/05-0.in');
my $o = $ng->to_string( 'orderby' => 'ngram' );
#putfile('t/05-0.out', $o);
isn('t/05-0.out', $o);

$ng = Text::Ngrams->new(type=>'byte');
$ng->process_files('t/05-1.in');
$o = $ng->to_string( 'orderby' => 'ngram');
#putfile('t/05-1.out', $o);
isn('t/05-1.out', $o);

$ng = Text::Ngrams->new(type=>'byte');
$ng->process_files('t/05-2.in');
my @a = $ng->get_ngrams( 'orderby' => 'frequency');
$o = '';
while (@a) {
  my $n=shift @a; my $f = shift @a;
  $o.= "$n $f\n";
}
#putfile('t/05-2.out', $o);
isn('t/05-2.out', $o);
