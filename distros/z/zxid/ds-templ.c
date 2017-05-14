/** ds-templ.c  -  DirectoryScript template, used in code generation
 ** Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 ** Author: Sampo Kellomaki (sampo@iki.fi)
 ** This is confidential unpublished proprietary source code of the author.
 ** NO WARRANTY, not even implied warranties. Contains trade secrets.
 ** Distribution prohibited unless authorized in writing.
 ** Licensed under Apache License 2.0, see file COPYING.
 ** $Id: ds-templ.c,v 1.1 2007-08-10 17:44:49 sampo Exp $
 **
 ** 6.6.2007, created, Sampo Kellomaki (sampo@iki.fi)
 **
 ** N.B: This template is meant to be processed by pd/xsd2sg.pl. Beware
 ** of special markers that xsd2sg.pl expects to find and understand.
 **/

function parse_ELNAME(data, x) {
ATTRS_PARSE;
ELEMS_PARSE;
}

function build_ELNAME(data) {
  attr = [];
  body = [];
ATTRS_BUILD;
ELEMS_BUILD;
  return TAG('ELNS:ELTAG', attr, body);
}

/* EOF */
