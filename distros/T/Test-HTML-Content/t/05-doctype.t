#!/usr/bin/perl -w
use strict;
use lib 't';
use testlib;

sub run {
  use_ok('Test::HTML::Content');

  # Tests for comments
  has_declaration('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
  ', 'DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"', "Doctype 3.2");
  has_declaration('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
  ', qr'HTML', "Doctype via RE");
  has_declaration('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
  ', qr'DOCTYPE.*?HTML 3\.2',"Doctype via other RE");

  no_declaration('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
  ', qr'DOCTYPE.*?HtML 3\.2',"Doctype via other RE");
};

# Borked javadoc HTML DOCTYPE ...
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN""http://www.w3.org/TR/REC-html40/loose.dtd>

runtests( 1+4, \&run );

