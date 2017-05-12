use strict;
use File::Path;

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

my $doc_block = <<END;
<?xml version="1.0"?>
<!-- dummy comment -->
<_test_parser>
  <sing attr1="foo" attr2="bar"><a href="/foo">some link text</a></sing>
</_test_parser>
END

my $doc_cdata_block = <<END;
<?xml version="1.0"?>
<!-- dummy comment -->
<_test_parser>
  <sing><![CDATA[ a cdata string ]]></sing>
</_test_parser>
END

###########

use Test::More 'no_plan';

##
# a bunch of simple parser tests
##

# well-formed root element
eval {
  XML::Comma->parser()->parse ( block=>
'<a>
<b>
<c foo="foo" bar="bar">some link text</c>
</b>
</a>
' ) };
ok( ! $@ );

# unclosed element
eval {
  XML::Comma->parser()->parse ( block=>'<a>' );
};
ok( $@ );

# another unclosed element
eval {
  XML::Comma->parser()->parse ( block=>'<a>foo' );
};
ok( $@ );

# unclosed tag
eval {
  XML::Comma->parser()->parse ( block=>'<a' );
};
ok( $@ );

# unclosed comment
eval {
  XML::Comma->parser()->parse ( block=>'<a><!-- foo </a>' );
};
ok( $@ );

# unclosed cdata
eval {
  XML::Comma->parser()->parse ( block=>'<a><![CDATA[ foo </a>' );
};
ok( $@ );

# unclosed processing instruction
eval {
  XML::Comma->parser()->parse ( block=>'<a><? ... </a>' );
};
ok( $@ );

# unclosed close tag
eval {
  XML::Comma->parser()->parse ( block=>'<a>foo</a' );
};
ok( $@ );

# another unclosed close tag (trailing whitespace)
eval {
  XML::Comma->parser()->parse ( block=>'<a>foo</a  ' );
};
ok( $@ );

# mismatched tag
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo</a></b>' );
};
ok( $@ );

# unclosed envelope el
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo</b>' );
};
ok( $@ );

# bad entity
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo &amp no semicolon</b></a>' );
};
ok( $@ );

# bad entity right up against a tag
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo &amp</b></a>' );
};
ok( $@ );

# bad <
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo < oops</b></a>' );
};
ok( $@ );

# good entity
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo &amp; with semi</b></a>' );
};
ok( ! $@ );

# bad entity and < okay because inside comment
eval {
  XML::Comma->parser()->parse ( block=>'<a><b><!-- foo & < --></b></a>' );
};
ok( ! $@ );

# -- inside comment
eval {
  XML::Comma->parser()->parse ( block=>'<a><!-- illegal -- oops --></a>' );
};
ok( $@ );

eval {
  XML::Comma->parser()->parse ( block=>'<a><!-  and other things' );
};
ok( $@ );

# cdata
eval {
  XML::Comma->parser()->parse (block=>'<a><![CDATA[ hmmm & > < <foo> ]]></a>');
};
ok ( ! $@ );

# tricky cdata ending
eval {
  XML::Comma->parser()->parse (block=>'<a><![CDATA[ hmmm & > < <foo> ]   ]]]></a>');
};
ok ( ! $@ );

# trailing junk after root element
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo</b></a> more' );
};
ok ( $@ );

# trailing comment after root element
eval {
  XML::Comma->parser()->parse ( block=>'<a><b>foo</b></a> <!-- comment --> ' );
};
ok ( ! $@ );


##
# now some simple actual document parsing
##

## try to make a def with a bunch of stuff in it
my $def = XML::Comma::Def->read ( name => '_test_parser' );
XML::Comma::DefManager->add_def ( $def );
ok($def);

## create a doc, so we can test what we get in elements
my $doc = XML::Comma::Doc->new ( block=>$doc_block );
ok($doc);
ok($doc->sing() eq '<a href="/foo">some link text</a>');
# and attributes
ok($doc->element('sing')->get_attr('attr1') eq 'foo');
ok($doc->element('sing')->get_attr('attr2') eq 'bar');

my $doc_cd = XML::Comma::Doc->new ( block=>$doc_cdata_block );
ok($doc_cd->sing() eq 'a cdata string');

$doc->element ( 'included_element_one' )->set ( 'foo bar' );
ok("didn't die - ok");
ok($doc->element ( 'included_element_one' )->get() eq 'foo bar');

$doc->element ( 'included_element_two' )->set ( 'b' );
ok("didn't die - ok");
ok($doc->element ( 'included_element_two' )->get() eq 'b');

ok(join ( ',', sort $doc->element ( 'included_element_two' )->enum_options() ) eq 'a,b,c');


$doc->element ( 'dynamic_include_element_one' )->set ( 'hello di' );
ok($doc->dynamic_include_element_one() eq 'hello di');

$doc->element ( 'dyn_arg_el_one' )->set ( 'hello da1' );
ok($doc->dyn_arg_el_one() eq 'hello da1');

$doc->element ( 'dyn_arg_el_two' )->set ( 'hello da2' );
ok($doc->dyn_arg_el_two() eq 'hello da2');

# messy collection of files -- this should be cleaned up and made
# pretty and regular

eval {
  $def = XML::Comma::Def->read ( name => '_test_parser_di_lst_eval_err' ); 
};
ok($@ and $@ =~ m|error while evaling args list|);

eval { 
  $def = XML::Comma::Def->read ( name => '_test_parser_di_sub_eval_err' );
};
ok($@ and $@ =~ m|error while evaling|);

eval { 
  $def = XML::Comma::Def->read ( name => '_test_parser_di_sub_exe_err' );
};
ok($@ and $@ =~ m|ouch|);

# mixin parsing/instantiation

# my $mdoc = XML::Comma::Doc->new ( type => '_test_parser_mixin' );
# my $mel = $mdoc->element('mixed_in');
