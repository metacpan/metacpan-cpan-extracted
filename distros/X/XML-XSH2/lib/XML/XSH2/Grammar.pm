# This file was automatically generated from src/xsh_grammar.xml on 
# Tue Jun 18 23:25:51 2019


package XML::XSH2::Grammar;

use strict;
use Parse::RecDescent;
use vars qw/$grammar/;

$Parse::RecDescent::skip = '(\s|\n|#[^\n]*)*';
$grammar=<<'_EO_GRAMMAR_';

  
  command:
	    /(?=\s*[}{;]|\s*\Z)/ <commit> <reject>
	  | /assign\b|(?:local\b|my\b)?(?=\s*\$[a-zA-Z_][a-zA-Z0-9_]*\s*\s*(?:[\-\+\*\/%x.]|\|\||\&\&)?:?=)/ <commit> variable
	  ( /(?:[\-\+\*\/%x.]|\|\||\&\&)?=/ <commit> loose_exp
		{ ['xpath_assign',$item[3],$item[1]] }
  	
	  | /\s*(?:[\-\+\*\/%x.]|\|\||\&\&)?:=/ command
		{ ['command_assign',$item[2],$item[1]] }
  	
	   )
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,@{$item[4]},$item[1],$item[3]] }
  	
	  | /(my)\b/ variable(s)
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'store_lex_variables',0,@{$item[2]}] }
  	
	  | /(local)\b/ variable(s)
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'make_local',@{$item[2]}] }
  	
	  | /(do)\b/ <commit> block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'run_commands',$item[3],0] }
  	
	  | /(if)\b/ <commit> exp command
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'if_statement',[$item[3],[$item[4]]]] }
  	
	  | /(unless)\b/ <commit> exp command
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'unless_statement',$item[3],[$item[4]]] }
  	
	  | /(while)\b/ <commit> exp command
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'while_statement',$item[3],[$item[4]]] }
  	
	  | /(foreach|for)\b/ <commit> local_var_in(?) exp command
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'foreach_statement',$item[4],[$item[5]],@{$item[3]}] }
  	
	  | /(stream)\b/ <commit>
	  (( /--input-file|:f/ filename { [ 'string/input-file' => $item[2] ] }
	   | /--input-pipe|:p/ filename { [ 'string/input-pipe' => $item[2] ] }
	   | /--input-string|:s/ exp { [ 'exp/input-string' => $item[2] ] }
	   | /--output-file|:F/ filename { [ 'string/output-file' => $item[2] ] }
	   | /--output-encoding|:E/ enc_string { [ 'string/output-encoding' => $item[2] ] }
	   | /--output-pipe|:P/ filename { [ 'string/output-pipe' => $item[2] ] }
	   | /--output-string|:S/ exp { [ 'varname/output-string' => $item[2] ] }
	   | /--no-output|:N/ { [ '/no-output' => 1 ] }
	   )(s?) { [ map { @$_ } @{$item[1]} ] }
	  )
 stream_select(s)
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'stream_process',$item[3],$item[4]] }
  	
	  | /(undef|undefine)\b/ <commit> /\$?[a-zA-Z_][a-zA-Z0-9_]*/
		{ 
	  [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'undefine',$item[3]];
	 }
  	
	  | /(use)\b/ <commit> /XML::XSH2::(?:Inline|Compile)/
		{ 1 }
  	
	  | /(test-mode|test_mode)/
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,"test-mode"] }
  	
	  | /(run-mode|run_mode)/
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,"run-mode"] }
  	
	  | /(?!(?:iterate|try|def|define)\b)/ /\.|[a-zA-Z_][-a-zA-Z0-9_]*/ exp_or_opt(s?)
		{ 
	  bless
	  [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,$item[2],@{$item[3]}],
	  'XML::XSH2::Command'
	 }
  	

  statement:
	    /(?=\s*[}{;])/ <commit> <reject>
	  | /(if)\b/ <commit> exp block elsif_block else_block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'if_statement',[$item[3],$item[4]],@{$item[5]},@{$item[6]}] }
  	
	  | /(unless)\b/ <commit> exp block else_block(?)
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'unless_statement',$item[3],$item[4],@{$item[5]}] }
  	
	  | /(while)\b/ <commit> exp block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'while_statement',$item[3],$item[4]] }
  	
	  | /(foreach|for)\b/ <commit> local_var_in(?) exp block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'foreach_statement',@item[4,5],@{$item[3]}] }
  	
	  | /(try)\b/ <commit> block 'catch' local_var(?) block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'try_catch',$item[3],$item[6],@{$item[5]}] }
  	
	  | /(iterate)\b/ <commit> xpstep block
		{ [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'iterate',$item[4],@{$item[3]}] }
  	
	  | /(def|define)\b/ <commit> ID
		{ XML::XSH2::Functions::is_command($item[3])?undef:1 }
  	 variable(s?) block
		{ 
	  [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'def',$item[3],$item[6],$item[5]]
	 }
  	

  complex_command:
	    /(?=\s*[{}]|\s*\Z)/ <commit> <reject>
	  | /\s*;/ <commit>
	  | /(?=(?:foreach|for|if|unless|iterate|while|try|def|define)\b)/ statement <commit> trail(?)
		{ 
	  if (scalar(@{$item[4]})) {
	    if ($item[4][0][0] eq 'pipe') {
  	      $return=[$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'pipe_command',[$item[2]],$item[4][0][1]]
	    } else {
   	      $return=[$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'string_pipe_command',[$item[2]],$item[4][0][1]]
	    }
          } else {
            $return=$item[2]
          }
	 }
  	
	  | command <commit> trail(?) /\s*;|(?=\s*}|\s*\Z)/
		{ 
	  if (scalar(@{$item[3]})) {
	    if ($item[3][0][0] eq 'pipe') {
  	      $return=[$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'pipe_command',[$item[1]],$item[3][0][1]]
	    } else {
   	      $return=[$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'string_pipe_command',[$item[1]],$item[3][0][1]]
	    }
          } else {
            $return=$item[1]
          }
	 }
  	
	  | <error:Parse error near: "}.substr($text,0,40).qq{ ...">

  block:
	    '{' <commit> complex_command(s) '}'
		{ [grep ref,@{$item[3]}] }
  	

  exp_or_opt:
	    /(?=\s*[};]|\s*\Z)/ <commit> <reject>
	  | option
	  | exp

  option:
	    /:[[:alnum:]]|--[-_[:alnum:]]+/

  inline_doc_string:
	    /'[a-zA-Z_][a-zA-Z0-9_]*'|"[a-zA-Z_][a-zA-Z0-9_]*"|\([a-zA-Z_][a-zA-Z0-9_]*\)|\{[a-zA-Z_][a-zA-Z0-9_]*\}|[a-zA-Z_][a-zA-Z0-9_]*/
		{ [($item[1]=~/^(['"({])?(.*?)(['")}])?$/)] }
  	

  inline_doc:
	    /<</ inline_doc_string <skip:""> /.*\n/ /(.|\n)*?\n$item[2][1]\s*(\n|$)/
		{ 
	  $text=$item[4].$text;
	  local $_=$item[5]; s/\n$item[2][1]\s*$//;
	  my $paren = $item[2][0];
	  $paren = '"' if $paren eq "";
	  if ($paren eq "'") {
	      $paren = '"';
	      s{(\\)(.|\n)|(\$)}{ (defined($3) and $3 eq '$') ? "\\\$"
	        : ((defined($2) and $2 eq "\\")
	        ? "\\\\" : ((defined($2) and $2 eq "'") ? "'" : (
	        (defined($2) and $2 eq '$') ? "\\\\\\$2" :
	        "\\\\$2"))) }eg;
	  } "<<".$paren.$_;
	 }
  	

  enc_string:
	    exp

  ID:
	    /[a-zA-Z_][a-zA-Z0-9_]*/

  filename:
	    exp

  nodename:
	    exp

  xpath:
	    /(?=['"])/ <commit> xpstring
		{ $item[3] }
  	
	  | xpsimple <skip:""> xpcont(?)
		{ $item[1].join("",@{$item[3]}) }
  	
	  | <error:expected XPath, but got "}.substr($text,0,40).qq{ ...">

  xpsimple:
	    /(?: 
              \$\{ (?: \$?[a-zA-Z_][a-zA-Z0-9_]* | \{.*?\} | \(.+?\) ) \} |
              \$(?!\{) |
              [^-:\$\[\]{}|"'\ \s();] |
              -[^-\[\]{}|"'\ \s();]
          )
          (?:
              \$\{ (?: \$?[a-zA-Z_][a-zA-Z0-9_]* | \{.*?\} | \(.+?\) ) \} |
              \$(?!\{) |
              [^\[\]\${}|"'\ \s();]
          )*/x
	  | xpbrackets

  xpcont:
	   ( xpfilters
	  | xpbrackets
	   ) <skip:""> xpath(?)
		{ $item[1].join("",@{$item[3]}) }
  	
	  | xpath
		{ $item[1] }
  	

  xpfilters:
	    /(?=\[)/ xpfilter(s)
		{ join("",@{$item[2]}) }
  	

  xpfilter:
	    '[' xpinter ']'
		{ "[$item[2]]" }
  	

  xpbracket:
	    '(' <skip:""> xpinter ')'
		{ "($item[3])" }
  	

  xpbrackets:
	    /(?=\()/ xpbracket <skip:""> xpfilters(?)
		{ join "",$item[2],@{$item[4]} }
  	

  xpinter:
	    xps <skip:""> xpintercont(?)
		{ join("",$item[1],@{$item[3]}) }
  	

  xpintercont:
	   ( xpfilters
	  | xpbrackets
	   ) <skip:""> xpinter(?)
		{ join("",$item[1],@{$item[3]}) }
  	

  xps:
	    /(?: [^\$\[\]()'"};]+ |
              \$(?!\{) |
              \$\{ (?:\$?[a-zA-Z_][a-zA-Z0-9_]* |
                       \{.*?\} |
                       \(.+?\)
                   )
               \} |
              '(?:\$\{ (?: \$?[a-zA-Z_][a-zA-Z0-9_]* | \{.*?\} | \(.+?\)) \} | 
                  \$(?!\{) | [^\$'] | \\\$
               )*' |
              "(?:\$\{ (?: \$?[a-zA-Z_][a-zA-Z0-9_]* | \{.*?\} | \(.+?\)) \} |
                  \$(?!\{) | [^\$"] | \\\$
               )*"
          )*/x

  xpstring:
	    /'(?:\$\{(?:\$?[a-zA-Z_][a-zA-Z0-9_]*|\{.*?\}|\(.+?\))\}|\$(?!\{)|[^\$']|\\\$)*' |
              "(?:\$\{(?:\$?[a-zA-Z_][a-zA-Z0-9_]*|\{.*?\}|\(.+?\))\}|\$(?!\{)|[^\$"]|\\\$)*"/x

  perl_expression:
	   
		{ $main::myline = $thisline; }
  	 <reject>
	  | exp
		{ {local $^W=0; "\n# line $main::myline \"$XML::XSH2::Functions::SCRIPT\"\n".$item[1]} }
  	

  perl_block:
	   
		{ $main::myline = $thisline; }
  	 <reject>
	  |
		{ $main::myline = $thisline; }
  	 <reject>
	  | <perl_codeblock>
		{ {
	  $return=$item[1];
	  {
  	    local $^W = 0; # don't warn about undefined contants
	    my $pos="# line $main::myline \"$XML::XSH2::Functions::SCRIPT\"\n";
	    $return=~s/^\{/\{\n$pos/;
          }
	  } }
  	

  loose_exp:
	    /^(?={)/ perl_block
		{ $item[2] }
  	
	  | '&' block
		{ $item[2] }
  	
	  | /^(?=<<)/ inline_doc
		{ $item[2] }
  	
	  | xpinter

  exp:
	    /^(?={)/ perl_block
		{ $item[2] }
  	
	  | '&' block
		{ $item[2] }
  	
	  | /^(?=<<)/ inline_doc
		{ $item[2] }
  	
	  | xpath

  variable:
	    /\$[a-zA-Z_][a-zA-Z0-9_]*/

  eof:
	    /\Z/
		{ 1; }
  	

  startrule:
	    shell <commit> eof
		{ $item[1] }
  	
	  | complex_command(s) <commit> eof
		{ $item[1] }
  	

  trail:
	    /(?=\s*[};]|\s*\Z)/ <commit> <reject>
	  | '|>' <commit> variable
		{ ['var',$item[3]] }
  	
	  | '|' <commit> shline
		{ ['pipe',$item[3]] }
  	

  shline_nosc:
	    /([^;()\\"'\|]|\|[^>]|\\.|\"([^\"\\]|\\.)*\"|\'([^\'\\]|\\\'|\\\\|\\[^\'\\])*\')*/

  shline_inter:
	    /([^()\\"']|\\.|\"([^\"\\]|\\.)*\"|\'([^\'\\]|\\\'|\\\\|\\[^\'\\])*\')*/

  shline_bracket:
	    '(' shline_inter shline_bracket(?) shline_inter ')'
		{ join("",'(',$item[2],@{$item[3]},$item[4],')') }
  	

  shline:
	    shline_nosc shline_bracket(?) shline_nosc
		{ join("",$item[1],@{$item[2]},$item[3]) }
  	

  shell:
	    /!\s*/ <commit> /.*/
		{ [[$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'sh_noev',$item[3]]] }
  	
	  | <error?:Parse error near: "! }.substr($text,0,40).qq{ ..."> <reject>

  elsif_block:
	    /(elsif)\b/ <commit> exp block elsif_block
		{ [[$item[3],$item[4]],@{$item[5]}] }
  	
	  | /(?!elsif)/
		{ [] }
  	
	  | <uncommit> <error:Parse error near keyword elsif: "}.substr($text,0,40).qq{ ...">

  else_block:
	    /(else)\b/ <commit> block
		{ [[undef,$item[3]]] }
  	
	  | /(?!else)/
		{ [] }
  	
	  | <uncommit> <error:Parse error near keyword else: "}.substr($text,0,40).qq{ ...">

  local_var:
	   ( /(local|my)\s/
	   )(?) variable
		{ [$item[2],@{$item[1]}] }
  	

  local_var_in:
	    local_var 'in'
		{ $item[1] }
  	

  undef:
	    /(undef|undefine)\b/ <commit> /\$?[a-zA-Z_][a-zA-Z0-9_]*/
		{ 
	  [$thisline,$thiscolumn,$thisoffset,$XML::XSH2::Functions::SCRIPT,'undefine',$item[3]];
	 }
  	

  param:
	    /[^=\s]+/ '=' exp
		{ [$item[1],$item[3]] }
  	

  nodetype:
	    /element|attribute|attributes|text|cdata|pi|comment|chunk|entity_reference/

  loc:
	    /after\s/
		{ "after" }
  	
	  | /before\s/
		{ "before" }
  	
	  | /(in)?to\s/
		{ "into" }
  	
	  | /(append(ing)?|as\s+(a\s+)child(\s+of)?)\s/
		{ "append" }
  	
	  | /(prepend(ing)?|(as\s+)(the\s+)first(\s+child(\s+of)?)?)\s/
		{ "prepend" }
  	
	  | /(replace|instead( of)?)\s/
		{ "replace" }
  	

  xpaxis:
	    /[-a-z]+::/

  xpnodetest:
	    /node\(\)|text\(\)|comment\(\)|processing-instruction\(\s*(?:"[^"]*"\s*|'[^'*]'\s*)?\)|[^\(\[\/\"\'\&\;\s]+/

  xplocationstep:
	    xpaxis(?) xpnodetest
		{ [ (@{$item[1]} ? $item[1][0] : 'child::'),$item[3] ] }
  	

  xpstep:
	    xplocationstep <skip:""> xpfilter(?)
		{ [ @{$item[1]}, @{$item[3]}] }
  	

  stream_select:
	    /select\s/ xpath block
		{ [$item[2],$item[3]] }
  	



_EO_GRAMMAR_

sub compile {
  my @opts = ( { -standalone => 1 },
               $grammar,
               "XML::XSH2::Parser",
             );
  shift @opts
      if $Parse::RecDescent::VERSION < 1.967_005; # Standalone not supported.
  Parse::RecDescent->Precompile(@opts);
}

sub new {
  return new Parse::RecDescent ($grammar);
}

1;

  
