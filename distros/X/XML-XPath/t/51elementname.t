#!/usr/bin/perl

use utf8;
use open qw(:std :encoding(utf-8));
use Test::More tests => 3;
use strict;
use warnings;
use XML::XPath;

my $good_path = '/employees/employee[@age="30"]/yağcı';
my $bad_path  = '/employees/employee[@age="30"]/şımarık';

my $xp = XML::XPath->new(ioref => \*DATA);

ok($xp);
ok($xp->findvalue($good_path), 'değil');
ok($xp->findvalue($bad_path), 'değil');

__DATA__
<?xml version="1.0" encoding="utf-8" ?>
<employees>
    <employee age="30">
        <şımarık>değil</şımarık>
        <yağcı>değil</yağcı>
    </employee>
</employees>
