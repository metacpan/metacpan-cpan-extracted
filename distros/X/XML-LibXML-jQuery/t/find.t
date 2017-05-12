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

    is $j->find('.inner')->size, 2, 'find() on multiple tree object';
    is $j->document->find('div')->size, 4, 'on document';

    is j('<html>1</html>')->find('html')->size, 0, 'find() does not include root elements';
    is j('<div>foo</div><div>bar</div>')->find('div')->size, 0;

    is $j->find('.inner')->end, $j, 'end';
}
