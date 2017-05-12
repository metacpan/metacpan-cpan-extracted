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
    <div idclass="container">
      <div class="inner">Hello</div>
    </div>

    <div class="container">
      <div class="inner">Hello</div>
    </div>
HTML

    my $j = j($source);

    is $j->xfind('./div')->size, 2, 'xfind()';
}
