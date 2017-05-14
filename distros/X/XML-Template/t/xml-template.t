#!/usr/bin/perl


use strict;
use Test;
BEGIN { plan tests => 3 }

use XML::Template;
use XML::Template::Element::File::Load;


ok (1);
my $xml_template = XML::Template->new (
                     Load => XML::Template::Element::File::Load->new (
                               IncludePath => ['t']));
ok ($xml_template);
my $r = $xml_template->process ('t.xhtml')
  || warn $xml_template->error ();
ok ($r);
