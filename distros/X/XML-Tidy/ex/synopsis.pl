#!/usr/bin/perl
use strict;use  warnings;
use   utf8;use XML::Tidy;

# create new   XML::Tidy object by loading:  MainFile.xml
my $tidy_obj = XML::Tidy->new('filename' => 'MainFile.xml');

#   tidy  up  the  indenting
   $tidy_obj->tidy();

#             write out changes back     to  MainFile.xml
   $tidy_obj->write();
