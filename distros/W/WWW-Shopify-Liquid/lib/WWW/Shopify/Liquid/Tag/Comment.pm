#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Comment;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';
sub inner_halt_lexing { return 1; }
sub max_arguments { return 0; }
sub process { return ''; }



1;