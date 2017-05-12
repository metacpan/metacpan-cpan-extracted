# This file was automatically generated from src/xsh_grammar.xml on 
# Wed Sep 10 17:53:03 2003


package XML::XSH::Grammar;

use strict;
use Parse::RecDescent;
use vars qw/$grammar/;

$Parse::RecDescent::skip = '(\s|\n|#[^\n]*)*';
$grammar=<<'_EO_GRAMMAR_';

  
  command:
	    ... /\s*[}{;]/ <commit> <reject>
	  | /(switch-to-new-documents|switch_to_new_documents)\s/ expression
		{ [\&XML::XSH::Functions::set_cdonopen,$item[2]] }
  	
	  | /(backups)/
		{ [\&XML::XSH::Functions::set_backups,1] }
  	
	  | /(nobackups)/
		{ [\&XML::XSH::Functions::set_backups,0] }
  	
	  | /(quiet)/
		{ [\&XML::XSH::Functions::set_quiet,1] }
  	
	  | /(verbose)/
		{ [\&XML::XSH::Functions::set_quiet,0] }
  	
	  | /(test-mode|test_mode)/
		{ ["test-mode"] }
  	
	  | /(run-mode|run_mode)/
		{ ["run-mode"] }
  	
	  | /(debug)/
		{ [\&XML::XSH::Functions::set_debug,1] }
  	
	  | /(nodebug)/
		{ [\&XML::XSH::Functions::set_debug,0] }
  	
	  | /(version)/
		{ [\&XML::XSH::Functions::print_version,0] }
  	
	  | /(validation)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_validation,$item[3]] }
  	
	  | /(recovering)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_recovering,$item[3]] }
  	
	  | /(parser-expands-entities|parser_expands_entities)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_expand_entities,$item[3]] }
  	
	  | /(keep-blanks|keep_blanks)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_keep_blanks,$item[3]] }
  	
	  | /(pedantic-parser|pedantic_parser)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_pedantic_parser,$item[3]] }
  	
	  | /(parser-completes-attributes|complete_attributes|complete-attributes|parser_completes_attributes)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_complete_attributes,$item[3]] }
  	
	  | /(indent)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_indent,$item[3]] }
  	
	  | /(empty-tags|empty_tags)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_empty_tags,$item[3]] }
  	
	  | /(skip-dtd|skip_dtd)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_skip_dtd,$item[3]] }
  	
	  | /(parser-expands-xinclude|parser_expands_xinclude)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_expand_xinclude,$item[3]] }
  	
	  | /(load-ext-dtd|load_ext_dtd)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_load_ext_dtd,$item[3]] }
  	
	  | /(encoding)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_encoding,$item[3]] }
  	
	  | /(query-encoding|query_encoding)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_qencoding,$item[3]] }
  	
	  | /(options|flags)/ <commit>
		{ [\&XML::XSH::Functions::list_flags] }
  	
	  | /(copy|cp)\s/ <commit> xpath loc xpath
		{ [\&XML::XSH::Functions::copy,@item[3,5,4]] }
  	
	  | /(xcopy|xcp)\s/ <commit> xpath loc xpath
		{ [\&XML::XSH::Functions::copy,@item[3,5,4],1] }
  	
	  | /(move|mv)\s/ <commit> xpath loc xpath
		{ [\&XML::XSH::Functions::move,@item[3,5,4]] }
  	
	  | /(xmove|xmv)\s/ <commit> xpath loc xpath
		{ [\&XML::XSH::Functions::move,@item[3,5,4],1] }
  	
	  | /(ls|list)\s/ xpath expression
		{ [\&XML::XSH::Functions::list,$item[2],$item[3]] }
  	
	  | /(ls|list)\s/ xpath
		{ [\&XML::XSH::Functions::list,$item[2],-1] }
  	
	  | /(ls|list)/
		{ [\&XML::XSH::Functions::list,[undef,'.'],1] }
  	
	  | /(exit|quit)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::quit,@{$item[3]}] }
  	
	  | /(remove|rm|prune|delete|del)\s/ <commit> xpath
		{ [\&XML::XSH::Functions::prune,$item[3]] }
  	
	  | /(map|sed)\s/ <commit> perl_code xpath
		{ [\&XML::XSH::Functions::perlmap,@item[4,3]] }
  	
	  | /(rename)\s/ <commit> perl_code xpath
		{ [\&XML::XSH::Functions::perlrename,@item[4,3]] }
  	
	  | /(sort)\s/ <commit> condition perl_code nodelistvariable
		{ [\&XML::XSH::Functions::perlsort,@item[3..5]] }
  	
	  | /(close)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::close_doc,@{$item[3]}] }
  	
	  | /(validate)/ validation_scheme optional_expression(?)
		{ [\&XML::XSH::Functions::validate_doc,1,$item[2],@{$item[3]}] }
  	
	  | /(validate)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::validate_doc,1,[],@{$item[3]}] }
  	
	  | /(valid)/ validation_scheme optional_expression(?)
		{ [\&XML::XSH::Functions::validate_doc,0,$item[2],@{$item[3]}] }
  	
	  | /(valid)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::validate_doc,0,[],@{$item[3]}] }
  	
	  | /(dtd)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::list_dtd,@{$item[3]}] }
  	
	  | /(enc)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::print_enc,@{$item[3]}] }
  	
	  | /(set-enc)\s/ <commit> expression optional_expression(?)
		{ [\&XML::XSH::Functions::set_doc_enc,$item[3],@{$item[4]}] }
  	
	  | /(set-standalone)\s/ <commit> expression optional_expression(?)
		{ [\&XML::XSH::Functions::set_doc_standalone,$item[3],@{$item[4]}] }
  	
	  | /(lcd|chdir)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::cd,@{$item[3]}] }
  	
	  | /(clone|dup)\s/ <commit> id_or_var /\s*=\s*/ expression
		{ [\&XML::XSH::Functions::clone,@item[3,5]] }
  	
	  | /(count|print_value|get)\s/ <commit> xpath
		{ [\&XML::XSH::Functions::print_count,$item[3]] }
  	
	  | /(perl|eval)\s/ <commit> perl_code
		{ [\&XML::XSH::Functions::print_eval,$item[3]] }
  	
	  | /save(as|_as|-as)?((\s*|_|-)(HTML|html|XML|xml|XINCLUDE|Xinclude|xinclude))?((\s*|_|-)(FILE|file|PIPE|pipe|STRING|string))?/ expression filename encoding_param(?)
		{ [\&XML::XSH::Functions::save_doc,@item[1,2,3,4]] }
  	
	  | /save(as|_as|-as)?((\s*|_|-)(HTML|html|XML|xml|XINCLUDE|Xinclude|xinclude))?((\s*|_|-)(FILE|file|STRING|string))?/ expression encoding_param(?)
		{ [\&XML::XSH::Functions::save_doc,@item[1,2],undef,$item[3]] }
  	
	  | /save(as|_as|-as)?([-_](HTML|html|XML|xml|XINCLUDE|Xinclude|xinclude))?/ <commit>
		{ [\&XML::XSH::Functions::save_doc,$item[1]] }
  	
	  | /(documents|files|docs)/
		{ [\&XML::XSH::Functions::files] }
  	
	  | /(xslt|transform|xsl|xsltproc|process)\s/ <commit> expression filename expression xslt_params(?)
		{ [\&XML::XSH::Functions::xslt,@item[3,4,5],@{$item[6]}] }
  	
	  | /(insert|add)\s/ <commit> nodetype expression namespace(?) loc xpath
		{ [\&XML::XSH::Functions::insert,@item[3,4,7,6],$item[5][0],0] }
  	
	  | /(xinsert|xadd)\s/ <commit> nodetype expression namespace(?) loc xpath
		{ [\&XML::XSH::Functions::insert,@item[3,4,7,6],$item[5][0],1] }
  	
	  | /(help|\?)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::help,@{$item[3]}] }
  	
	  | /(exec|system)\s/ <commit> expression(s)
		{ [\&XML::XSH::Functions::sh,join(" ",@{$item[3]})] }
  	
	  | /(include|\.)\s/ <commit> filename
		{ [\&XML::XSH::Functions::include,$item[3]] }
  	
	  | /(ifinclude)\s/ <commit> filename
		{ [\&XML::XSH::Functions::include,$item[3],1] }
  	
	  |( /(assign)\s/
	   )(?) variable '=' xpath
		{ [\&XML::XSH::Functions::xpath_assign,$item[2],$item[4]] }
  	
	  |( /(assign)\s/
	   )(?) nodelistvariable '=' xpath
		{ [\&XML::XSH::Functions::nodelist_assign,$item[2],$item[4]] }
  	
	  | /(local)\s/ variable '=' xpath
		{ [\&XML::XSH::Functions::xpath_assign_local,$item[2],$item[4]] }
  	
	  | /(local)\s/ nodelistvariable '=' xpath
		{ [\&XML::XSH::Functions::nodelist_assign_local,$item[2],$item[4]] }
  	
	  | /(local)\s/ anyvariable(s)
		{ [\&XML::XSH::Functions::make_local,@{$item[2]}] }
  	
	  | variable
		{ [\&XML::XSH::Functions::print_var,$item[1]] }
  	
	  | /(variables|vars|var)/
		{ [\&XML::XSH::Functions::variables] }
  	
	  | /(print|echo)\s/ expression(s)
		{ [\&XML::XSH::Functions::echo,@{$item[2]}] }
  	
	  | /(print|echo)/
		{ [\&XML::XSH::Functions::echo] }
  	
	  | /(create|new)\s/ <commit> expression expression
		{ [\&XML::XSH::Functions::create_doc,@item[3,4]] }
  	
	  | /(defs)/ <commit>
		{ [\&XML::XSH::Functions::list_defs] }
  	
	  | /(select)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_local_xpath,[$item[3],"/"]] }
  	
	  | /(if)\s/ <commit> condition command
		{ [\&XML::XSH::Functions::if_statement,[$item[3],[$item[4]]]] }
  	
	  | /(unless)\s/ <commit> condition command
		{ [\&XML::XSH::Functions::unless_statement,$item[3],[$item[4]]] }
  	
	  | /(while)\s/ <commit> condition command
		{ [\&XML::XSH::Functions::while_statement,$item[3],[$item[4]]] }
  	
	  | /(foreach|for)\s/ <commit> condition command
		{ [\&XML::XSH::Functions::foreach_statement,$item[3],[$item[4]]] }
  	
	  | /(process-xinclude|process_xinclude|process-xincludes|process_xincludes|xinclude|xincludes|load_xincludes|load-xincludes|load_xinclude|load-xinclude)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::process_xinclude,@{$item[3]}] }
  	
	  | /(cd|chxpath)/ <commit> optional_xpath(?)
		{ [\&XML::XSH::Functions::set_local_xpath,@{$item[3]}] }
  	
	  | /(pwd)/
		{ [\&XML::XSH::Functions::print_pwd] }
  	
	  | /(locate)/ <commit> optional_xpath(?)
		{ [\&XML::XSH::Functions::locate,@{$item[3]}] }
  	
	  | /(xupdate)\s/ <commit> expression expression(?)
		{ [\&XML::XSH::Functions::xupdate,$item[3],@{$item[4]}] }
  	
	  | /open((\s*|_|-)(HTML|XML|DOCBOOK|html|xml|docbook)(?!\s*=))?((\s*|_|-)(FILE|file|PIPE|pipe|STRING|string)(?!\s*=))?/ <commit> id_or_var /\s*=\s*/ expression
		{ [\&XML::XSH::Functions::open_doc,@item[3,5,1]] }
  	
	  | ID /\s*=\s*/ <commit> filename
		{ [\&XML::XSH::Functions::open_doc,@item[1,4]] }
  	
	  | /(fold)\s/ xpath expression(?)
		{ [\&XML::XSH::Functions::mark_fold,$item[2],@{$item[3]}] }
  	
	  | /(unfold)\s/ xpath
		{ [\&XML::XSH::Functions::mark_unfold,$item[2]] }
  	
	  | /(normalize)\s/ <commit> xpath
		{ [\&XML::XSH::Functions::normalize_nodes,$item[3]] }
  	
	  | /(strip-whitespace|strip_whitespace)\s/ <commit> xpath
		{ [\&XML::XSH::Functions::strip_ws,$item[3]] }
  	
	  | /(last)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::loop_last,@{$item[3]}] }
  	
	  | /(next)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::loop_next,@{$item[3]}] }
  	
	  | /(prev)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::loop_prev,@{$item[3]}] }
  	
	  | /(redo)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::loop_redo,@{$item[3]}] }
  	
	  | /(return)/
		{ [\&XML::XSH::Functions::call_return] }
  	
	  | /(throw)\s/ expression
		{ [\&XML::XSH::Functions::throw_exception,$item[2]] }
  	
	  | /(catalog)\s/ expression
		{ [\&XML::XSH::Functions::load_catalog,$item[2]] }
  	
	  | /(register-namespace|regns)\s/ <commit> expression expression
		{ [\&XML::XSH::Functions::register_ns,
                 $item[3],$item[4]] }
  	
	  | /(unregister-namespace|unregns)\s/ <commit> expression
		{ [\&XML::XSH::Functions::unregister_ns,
                 $item[3]] }
  	
	  | /(register-xhtml-namespace|regns-xhtml)\s/ <commit> expression
		{ [\&XML::XSH::Functions::register_ns,
                 $item[3],'http://www.w3.org/1999/xhtml'] }
  	
	  | /(register-xsh-namespace|regns-xsh)\s/ <commit> expression
		{ [\&XML::XSH::Functions::register_ns,
                 $item[3],$XML::XSH::xshNS] }
  	
	  | /(unregister-function|unregfunc)\s/ <commit> expression
		{ [\&XML::XSH::Functions::unregister_func, $item[3]] }
  	
	  | /(register-function|regfunc)\s/ <commit> expression perl_code
		{ [\&XML::XSH::Functions::register_func,
                 $item[3],$item[4]] }
  	
	  | /(stream)\s/ <commit> /input((\s*|_|-)(FILE|file|PIPE|pipe|STRING|string))?\s/ filename /output((\s*|_|-)(FILE|file|PIPE|pipe|STRING|string))?\s/ filename stream_select(s)
		{ [\&XML::XSH::Functions::stream_process,$item[3],$item[4],$item[5],$item[6],$item[7]] }
  	
	  | /(namespaces)/ <commit> xpath(?)
		{ [\&XML::XSH::Functions::list_namespaces,@{$item[3]}] }
  	
	  | /(xpath-completion|xpath_completion)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_xpath_completion,$item[3]] }
  	
	  | /(xpath-axis-completion|xpath_axis_completion)\s/ <commit> expression
		{ [\&XML::XSH::Functions::set_xpath_axis_completion,$item[3]] }
  	
	  | /(doc-info|doc_info)/ <commit> optional_expression(?)
		{ [\&XML::XSH::Functions::doc_info,@{$item[3]}] }
  	
	  | /(use)\s/ <commit> /Inline::XSH/
		{ 1 }
  	
	  | call_command

  statement:
	    ... /\s*[}{;]/ <commit> <reject>
	  | /(if)\s/ <commit> condition block elsif_block else_block
		{ [\&XML::XSH::Functions::if_statement,[$item[3],$item[4]],@{$item[5]},@{$item[6]}] }
  	
	  | /(unless)\s/ <commit> condition block else_block(?)
		{ [\&XML::XSH::Functions::unless_statement,$item[3],$item[4],@{$item[5]}] }
  	
	  | /(while)\s/ <commit> condition block
		{ [\&XML::XSH::Functions::while_statement,$item[3],$item[4]] }
  	
	  | /(foreach|for)\s/ <commit> condition block
		{ [\&XML::XSH::Functions::foreach_statement,$item[3],$item[4]] }
  	
	  | /(try)\s/ <commit> block 'catch' local_var(?) block
		{ [\&XML::XSH::Functions::try_catch,$item[3],$item[6],@{$item[5]}] }
  	
	  | /(iterate)\s/ <commit> xpstep block
		{ [\&XML::XSH::Functions::iterate,$item[4],@{$item[3]}] }
  	

  complex_command:
	    ';'
	  | statement <commit> trail(?)
		{ 
	  if (scalar(@{$item[3]})) {
	    if ($item[3][0][0] eq 'pipe') {
  	      $return=[\&XML::XSH::Functions::pipe_command,[$item[1]],$item[3][0][1]]
	    } else {
   	      $return=[\&XML::XSH::Functions::string_pipe_command,[$item[1]],$item[3][0][1]]
	    }
          } else {
            $return=$item[1]
          }
	 }
  	
	  | command <commit> trail(?)
	  ( ';'
	  | ... /^\s*(}|\Z)/
	   )
		{ 
	  if (scalar(@{$item[3]})) {
	    if ($item[3][0][0] eq 'pipe') {
  	      $return=[\&XML::XSH::Functions::pipe_command,[$item[1]],$item[3][0][1]]
	    } else {
   	      $return=[\&XML::XSH::Functions::string_pipe_command,[$item[1]],$item[3][0][1]]
	    }
          } else {
            $return=$item[1]
          }
	 }
  	
	  | <error:Parse error near: "}.substr($text,0,40).qq{ ...">

  statement_or_command:
	    def
	  | undef
	  | complex_command

  block:
	    '{' <commit> complex_command(s) '}'
		{ [grep ref,@{$item[3]}] }
  	

  type:
	   

  TOKEN:
	    /\S+/

  STRING:
	    /([^'"\$\\ \t\n\r\|;\{\}]|\$[^{]|\$\{[^{}]*\}|]|\\.)+/

  single_quoted_string:
	    /\'([^\'\\]|\\\'|\\\\|\\[^\'\\])*\'/
		{ 
	  local $_=$item[1];
	  s/^\'|\'$//g;
	  s{(\\)(.|\n)|(\$)}{ ($3 eq '$') ? "\\\$" : (($2 eq "\\")
	  ? "\\\\" : (($2 eq "'") ? "'" : ( ($2 eq '$') ? "\\\\\\$2" :
	  "\\\\$2"))) }eg;
	  $_;
	 }
  	

  double_quoted_string:
	    /\"([^\"\\]|\\.)*\"/
		{ 
	  local $_=$item[1];
	  s/^\"|\"$//g;
	  $_;
	 }
  	

  exp_part:
	    STRING
	  | exp_inline_count
	  | single_quoted_string
	  | double_quoted_string

  exp_inline_count:
	    /\$\{\((.+?)\)\}/
	  | /\$\{\{\{(.+?)\}\}\}/
	  | /\$\{\{([^{].*?)\}\}/

  expression:
	    /<</ /(\'|\")?/ ID /$item[2]/ <skip:""> /.*\n/ /(.|\n)*?\n$item[3]\s*(\n|$)/
		{ 
	    $text=$item[6].$text;
	    local $_=$item[7]; s/\n$item[3]\s*$//;
	    if ($item[2] eq "'") {
	      s{(\\)(.|\n)|(\$)}{ ($3 eq '$') ? "\\\$" : (($2 eq "\\")
	      ? "\\\\" : (($2 eq "'") ? "'" : ( ($2 eq '$') ? "\\\\\\$2" :
	      "\\\\$2"))) }eg;
          }
	    $_;
	   }
  	
	  | exp_part <skip:""> expression(?)
		{ $item[1].join("",@{$item[3]}) }
  	

  ws:
	    /(\s|\n|#[^\n]*)+/

  optional_expression:
	    <skip:""> ws expression
		{ $item[3] }
  	

  optional_expressions:
	    <skip:""> ws expression(s)
		{ $item[3] }
  	

  optional_xpath:
	    <skip:""> ws xpath
		{ $item[3] }
  	

  enc_string:
	    expression

  ID:
	    /[a-zA-Z_][a-zA-Z0-9_]*/

  id_or_var:
	    ID
	  | variable

  public_dtd:
	    'PUBLIC' expression
		{ $item[2] }
  	

  system_dtd:
	    /SYSTEM|FILE/ filename
		{ $item[2] }
  	

  validation_scheme:
	    'DTD' public_dtd system_dtd
		{ ['DTD','FILE',$item[2],$item[3]] }
  	
	  | 'DTD' public_dtd
		{ ['DTD','FILE',$item[2],undef] }
  	
	  | 'DTD' system_dtd
		{ ['DTD','FILE',undef,$item[2]] }
  	
	  | 'DTD' 'STRING' expression
		{ ['DTD','STRING',$item[3]] }
  	
	  | /RNG|RelaxNG|RELAXNG/ /FILE|STRING|DOC/ filename
		{ ['RNG',@item[2,3]] }
  	
	  | /Schema|SCHEMA|XSD/ /FILE|STRING|DOC/ filename
		{ ['XSD',@item[2,3]] }
  	

  filename:
	    expression

  xpath:
	    id_or_var <skip:""> /:(?!:)/ xp
		{ [$item[1],$item[4]] }
  	
	  | xp
		{ [undef,$item[1]] }
  	
	  | <error:expected ID:XPath or XPath, but got "}.substr($text,0,40).qq{ ...">

  xpcont:
	   ( xpfilters
	  | xpbrackets
	   ) <skip:""> xp(?)
		{ $item[1].join("",@{$item[3]}) }
  	
	  | xp
		{ $item[1] }
  	

  xp:
	    xpsimple <skip:""> xpcont(?)
		{ $item[1].join("",@{$item[3]}) }
  	
	  | xpstring

  xpfilters:
	    xpfilter(s)
		{ join("",@{$item[1]}) }
  	

  xpfilter:
	    '[' xpinter ']'
		{ "[$item[2]]" }
  	

  xpbracket:
	    '(' xpinter ')'
		{ "($item[2])" }
  	

  xpbrackets:
	    xpbracket <skip:""> xpfilters(?)
		{ join "",$item[1],@{$item[3]} }
  	

  xpintercont:
	   ( xpfilters
	  | xpbrackets
	   ) <skip:""> xpinter(?)
		{ join("",$item[1],@{$item[3]}) }
  	

  xpinter:
	    xps <skip:""> xpintercont(?)
		{ join("",$item[1],@{$item[3]}) }
  	

  xps:
	    /([^][()'"]|'[^']*'|"[^"]*")*/

  xpstring:
	    /'[^']*'|"[^"]*"/

  xpsimple:
	    /[^]}|"' [();]+/
	  | xpbrackets

  perl_expression:
	    expression

  variable:
	    '$' <skip:""> ID
		{ "$item[1]$item[3]" }
  	

  nodelistvariable:
	    '%' <skip:""> ID
		{ $item[3] }
  	

  loosenodelistvariable:
	    '%' <skip:""> id_or_var
		{ $item[3] }
  	

  eof:
	    /^\Z/
		{ 1; }
  	

  startrule:
	    shell <commit> eof
		{ XML::XSH::Functions::run_commands($item[1],1) }
  	
	  | statement_or_command(s) <commit> eof
		{ XML::XSH::Functions::run_commands($item[1],1) }
  	

  trail:
	    '|>' <commit> variable
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
		{ [[\&XML::XSH::Functions::sh,$item[3]]] }
  	
	  | <error?:Parse error near: "! }.substr($text,0,40).qq{ ..."> <reject>

  condition:
	    <perl_codeblock>
	  | xpath

  elsif_block:
	    /(elsif)\s/ <commit> condition block elsif_block
		{ [[$item[3],$item[4]],@{$item[5]}] }
  	
	  | ...! /(elsif)/
		{ [] }
  	
	  | <uncommit> <error:Parse error near keyword elsif: "}.substr($text,0,40).qq{ ...">

  else_block:
	    /(else)\s/ <commit> block
		{ [[undef,$item[3]]] }
  	
	  | ...! /(else)/
		{ [] }
  	
	  | <uncommit> <error:Parse error near keyword else: "}.substr($text,0,40).qq{ ...">

  local_var:
	   ( /local\s/
	   )(?) variable
		{ [$item[2],@{$item[1]}] }
  	

  typedvariable:
	    /[\$\%]/ <skip:""> ID
		{ "$item[1]$item[3]" }
  	

  undef:
	    /(undef|undefine)\s/ <commit> expression
		{ 
	  &XML::XSH::Functions::undef_sub($item[3]);
	 }
  	

  def:
	    /(def|define)\s/ <commit> ID typedvariable(s?) block(?)
		{ 
	  &XML::XSH::Functions::def($item[3],$item[5],$item[4]);
	 }
  	
	  | <error?:Parse error near: "}.substr($text,0,40).qq{ ..."> <reject>

  anyvariable:
	    variable
		{ ['$',$item[1]] }
  	
	  | nodelistvariable
		{ ['%',$item[1]] }
  	

  match_typedargs:
	   
		{ 
	  $return = ((@arg and $arg[0]<=$#arg and $arg[$arg[0]]=~m/^%/) 
	            ? $arg[$arg[0]] : undef)
	 }
  	 xpath match_typedargs[$arg[0]+1,@arg[1..$#arg]]
		{ 
	  $return=(defined($item[3]) ? [$item[2],@{$item[3]}] : undef);
	 }
  	
	  |
		{ 
	  $return = ((@arg and $arg[0]<=$#arg and $arg[$arg[0]]=~m/^\$/)
  	            ? $arg[$arg[0]] : undef)
	 }
  	 expression match_typedargs[$arg[0]+1,@arg[1..$#arg]]
		{ 
	  $return=(defined($item[3]) ? [$item[2],@{$item[3]}] : undef);
	 }
  	
	  |
		{ 
	  $return= (($arg[0]==$#arg+1) ? [] : undef);
	 }
  	

  subroutine_arguments:
	   
		{ 
	  if (exists($XML::XSH::Functions::_defs{$arg[0]})) {
	    $return=[ @{$XML::XSH::Functions::_defs{$arg[0]}} ];
	    shift @$return;
          } else { 
	    $return=undef;
	  }
	 }
  	
	  | <error:Call to undefined subroutine $arg[0]!>

  call_command:
	    <rulevar:@args>
	  | /(call)\s/ <commit> ID subroutine_arguments[$item[3]] match_typedargs[1,@{$item[4]}]
		{ 
	  $return=[\&XML::XSH::Functions::call,$item[3],$item[5]]
	 }
  	

  xslt_params:
	    /(params|parameters)\s/ param(s)
		{ $item[2] }
  	

  param:
	    /[^=\s]+/ '=' expression
		{ [$item[1],$item[3]] }
  	

  nodetype:
	    /element|attribute|attributes|text|cdata|pi|comment|chunk|entity_reference/

  namespace:
	    /namespace\s/ expression
		{ $item[2] }
  	

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
  	

  perl_code:
	    <perl_codeblock>
	  | perl_expression

  encoding_param:
	    /encoding\s/ expression
		{ $item[2] }
  	

  xpaxis:
	    /[-a-z]+::/

  xpnodetest:
	    /node\(\)|text\(\)|comment\(\)|processing-instruction\(\)|[^\(\[\/\"\'\&\;\s]+/

  xplocationstep:
	    xpaxis(?) <skip:""> xpnodetest
		{ [ (@{$item[1]} ? $item[1][0] : 'child::'),$item[3] ] }
  	

  xpstep:
	    xplocationstep <skip:""> xpfilter(?)
		{ [ @{$item[1]}, @{$item[3]}] }
  	

  stream_select:
	    /select\s/ xp block
		{ [$item[2],$item[3]] }
  	



_EO_GRAMMAR_

sub compile {
  Parse::RecDescent->Precompile($grammar,"XML::XSH::Parser");
}

sub new {
  return new Parse::RecDescent ($grammar);
}

1;

  