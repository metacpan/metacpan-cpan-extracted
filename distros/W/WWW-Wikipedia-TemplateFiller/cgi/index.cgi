#!/usr/bin/perl
use warnings;
use strict;

use WWW::Wikipedia::TemplateFiller::WebApp;

#
# Configure the template filler web application. (Note that each line
# ends in a comma.)
#

my %config = (
  # This points to the templates/ directory to be used
  template_path => '__PATH_TO_TEMPLATES__',

  # ISBNdb documentation at http://isbndb.com/docs/api/30-keys.html
  isbndb_access_key => '__ISBNDB_ACCESS_KEY__',
);

WWW::Wikipedia::TemplateFiller::WebApp->new( PARAMS => \%config )->run;
