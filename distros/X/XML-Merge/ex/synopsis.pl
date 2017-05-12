#!/usr/bin/perl
use strict;use   warnings;
use   utf8;use XML::Merge;

# create new   XML::Merge object from         MainFile.xml
my $merge_obj= XML::Merge->new('filename' => 'MainFile.xml');

# Merge File2Add.xml             into         MainFile.xml
   $merge_obj->merge(          'filename' => 'File2Add.xml');

# Tidy up the indenting that resulted from the merge
   $merge_obj->tidy();

# Write out changes back           to         MainFile.xml
   $merge_obj->write();
