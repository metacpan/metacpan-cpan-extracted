#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN { 
    use_ok('Tree::Parser') 
}

my $BAD_SUB = sub { 1 };
ok($BAD_SUB->());

my $tp = Tree::Parser->new();

# constructor errors

#   too much strictness for Path::Class
#throws_ok {
#    my $tp = Tree::Parser->new(bless({}, "Fail"));
#} qr/Incorrect Object Type/, '.. be sure we have the right exception';

# input errors

throws_ok {
    $tp->setInput();
} qr/Insufficient Arguments \: input undefined/, '... this should die';

throws_ok {
    $tp->setInput("file_that_does_not_exist.tree");
} qr/cannot open file\:/, '... this should die';

throws_ok {
    $tp->setInput("A Tree with no Newlines");
} qr/Incorrect Object Type \: input looked like a single string/, '... this should die';

# parse filter errors

throws_ok {
    $tp->setParseFilter();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $tp->setParseFilter("Fail");
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $tp->setParseFilter([]);
} qr/Insufficient Arguments/, '... this should die';

# parse error

throws_ok {
    $tp->parse();
} qr/Parse Error \: No parse filter is specified to parse with/, '... this should die';

$tp->setParseFilter($BAD_SUB);

throws_ok {
    $tp->parse();
} qr/Parse Error \: no input has yet been defined, there is nothing to parse/, '... this should die';


# deparse filter errors

throws_ok {
    $tp->setDeparseFilter();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $tp->setDeparseFilter("Fail");
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $tp->setDeparseFilter([]);
} qr/Insufficient Arguments/, '... this should die';

# deparse error

throws_ok {
    $tp->deparse();
} qr/Parse Error \: no deparse filter is specified/, '... this should die';

$tp->setDeparseFilter($BAD_SUB);

throws_ok {
    $tp->deparse();
} qr/Parse Error \: Tree is a leaf node, cannot de-parse a tree that has not be created yet/, '... this should die';





