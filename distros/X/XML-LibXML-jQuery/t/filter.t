#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;

test();
done_testing;


sub test {

    my $source = <<HTML;
    <div class="container">
      <div class="inner">Hello</div>
    </div>

    <span>root</span>

    <div class="container">
      <div class="inner">Hello</div>
      <span>inner</span>
    </div>

    <span>root2</span>
HTML

    my $j = j($source);

    is $j->filter('span')->size, 2;
    is $j->filter('span')->as_html, '<span>root</span><span>root2</span>';


    is $j->xfilter('./span')->as_html, '<span>root</span><span>root2</span>', 'xfilter';
}
