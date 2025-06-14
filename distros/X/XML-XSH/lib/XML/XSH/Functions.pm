# -*- cperl -*-
# $Id: Functions.pm,v 1.73 2003/09/10 15:54:09 pajas Exp $

package XML::XSH::Functions;

eval "no encoding";
undef $@;
use strict;
no warnings;

use XML::XSH::Help;
use XML::XSH::Iterators;
use IO::File;

use Exporter;
use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION $REVISION $OUT $LOCAL_ID $LOCAL_NODE
            $_xml_module $_sigint
            $_xsh $_xpc $_parser %_nodelist @stored_variables
            $_newdoc
            $TRAP_SIGINT $TRAP_SIGPIPE $_die_on_err $_on_exit
            %_doc %_files %_defs %_includes %_chr %_ns
	    $ENCODING $QUERY_ENCODING
	    $INDENT $BACKUPS $SWITCH_TO_NEW_DOCUMENTS $EMPTY_TAGS $SKIP_DTD
	    $QUIET $DEBUG $TEST_MODE
	    $VALIDATION $RECOVERING $PARSER_EXPANDS_ENTITIES $KEEP_BLANKS
	    $PEDANTIC_PARSER $LOAD_EXT_DTD $PARSER_COMPLETES_ATTRIBUTES
	    $PARSER_EXPANDS_XINCLUDE
	    $XPATH_AXIS_COMPLETION
	    $XPATH_COMPLETION $DEFAULT_FORMAT
	  /;

BEGIN {
  $VERSION='1.8.7';
  $REVISION='$Revision: 1.73 $';
  @ISA=qw(Exporter);
  my @PARAM_VARS=qw/$ENCODING
		    $QUERY_ENCODING
		    $INDENT
                    $EMPTY_TAGS
                    $SKIP_DTD
		    $BACKUPS
		    $SWITCH_TO_NEW_DOCUMENTS
		    $QUIET
		    $DEBUG
		    $TEST_MODE
		    $VALIDATION
		    $RECOVERING
		    $PARSER_EXPANDS_ENTITIES
		    $XPATH_AXIS_COMPLETION
		    $XPATH_COMPLETION
		    $KEEP_BLANKS
		    $PEDANTIC_PARSER
		    $LOAD_EXT_DTD
		    $PARSER_COMPLETES_ATTRIBUTES
		    $PARSER_EXPANDS_XINCLUDE
		    $DEFAULT_FORMAT
		    /;
  *EMPTY_TAGS=*XML::LibXML::setTagCompression;
  *SKIP_DTD=*XML::LibXML::skipDTD;
  @EXPORT_OK=(qw(&xsh_init &xsh &xsh_get_output
                &xsh_set_output &xsh_set_parser
                &set_quiet &set_debug &set_compile_only_mode
		&create_doc &open_doc &set_doc
		&xsh_pwd &xsh_local_id &get_doc &out
		&toUTF8 &fromUTF8 &set_local_doc
		&xsh_xml_parser &xsh_parse_string &xsh_docs
	       ),@PARAM_VARS);
  %EXPORT_TAGS = (
		  default => [@EXPORT_OK],
		  param_vars => [@PARAM_VARS]
		 );

  $TRAP_SIGINT=0;
  $_xml_module='XML::XSH::LibXMLCompat';
  $INDENT=1;
  $EMPTY_TAGS=1; # no effect (reseted by XML::LibXML)
  $SKIP_DTD=0;   # no effect (reseted by XML::LibXML)
  $BACKUPS=1;
  $SWITCH_TO_NEW_DOCUMENTS=1;
  $ENCODING='utf-8';
  $QUERY_ENCODING='utf-8';
  $QUIET=0;
  $DEBUG=0;
  $TEST_MODE=0;
  $VALIDATION=0;
  $RECOVERING=0;
  $PARSER_EXPANDS_ENTITIES=1;
  $KEEP_BLANKS=1;
  $PEDANTIC_PARSER=0;
  $LOAD_EXT_DTD=0;
  $PARSER_COMPLETES_ATTRIBUTES=1;
  $PARSER_EXPANDS_XINCLUDE=0;
  $XPATH_COMPLETION=1;
  $XPATH_AXIS_COMPLETION='always'; # never / when-empty
  $DEFAULT_FORMAT='xml';
  $_newdoc=1;
  $_die_on_err=1;
  %_nodelist=();

  %_chr = ( n => "\n", t => "\t", r => "\r",
	    f => "\f", b => "\b", a => "\a",
	    e => "\e" );
  autoflush STDOUT;
  autoflush STDERR;
}

sub min { $_[0] > $_[1] ? $_[1] : $_[0] }

sub out {
  if (ref($OUT) eq 'GLOB' or ref($OUT) eq 'Term::ReadLine::Gnu::Var') {
    print $OUT @_;
  } else {
    $OUT->print(@_);
  }
}

sub __debug {
  _err(@_);
}

sub __bug {
  _err("BUG: ",@_);
}


# initialize XSH and XML parsers
sub xsh_init {
  my $module=shift;
  shift unless ref($_[0]);
  if (ref($_[0])) {
    $OUT=$_[0];
  } else {
    $OUT=\*STDOUT;
  }
  $_xml_module=$module if $module;
  eval "require $_xml_module;";
  if ($@) {
    _err(
      "\n------------------------------------------------------------\n",
      $@,
      "\n------------------------------------------------------------.\n",
      "I suspect you have not installed XML::LibXML properly.\n",
      "Please install and try again. If you are 100% sure you have, send\n",
      "a full bug report to <pajas".'@'."users.sourceforge.net>\n");
    exit 1;
  }
  my $mod=$_xml_module->module();
  if ($] >= 5.008) {
    require Encode;
    *encodeToUTF8=*Encode::decode;
    *decodeFromUTF8=*Encode::encode;
  } else {
    no strict 'refs';
    *encodeToUTF8=*{"$mod"."::encodeToUTF8"};
    *decodeFromUTF8=*{"$mod"."::decodeFromUTF8"};
  }
  $_parser = $_xml_module->new_parser();

  xpc_init();
  xsh_rd_parser_init();
}

sub xsh_rd_parser_init {
  if (eval { require XML::XSH::Parser; }) {
    $_xsh=XML::XSH::Parser->new();
  } else {
    print STDERR "Parsing raw grammar...\n";
    require XML::XSH::Grammar;
    $_xsh=XML::XSH::Grammar->new();
    print STDERR "... done.\n";
    unless ($QUIET) {
      print STDERR << 'EOF';
NOTE: To avoid this, you should regenerate the XML::XSH::Parser.pm
      module from XML::XSH::Grammar.pm module by changing to XML/XSH/
      directory in your load-path and running the following command:

         perl -MGrammar -e XML::XSH::Grammar::compile

EOF
    }
  }
  return $_xsh;
}

sub set_validation	     { $VALIDATION=$_[0]; 1; }
sub set_recovering	     { $RECOVERING=$_[0]; 1; }
sub set_expand_entities	     { $PARSER_EXPANDS_ENTITIES=$_[0]; 1; }
sub set_keep_blanks	     { $KEEP_BLANKS=$_[0]; 1; }
sub set_pedantic_parser	     { $PEDANTIC_PARSER=$_[0]; 1; }
sub set_load_ext_dtd	     { $LOAD_EXT_DTD=$_[0]; 1; }
sub set_complete_attributes  { $PARSER_COMPLETES_ATTRIBUTES=$_[0]; 1; }
sub set_expand_xinclude	     { $PARSER_EXPANDS_XINCLUDE=$_[0]; 1; }
sub set_indent		     { $INDENT=$_[0]; 1; }
sub set_empty_tags           { $EMPTY_TAGS=$_[0]; 1; }
sub set_skip_dtd             { $SKIP_DTD=$_[0]; 1; }
sub set_backups		     { $BACKUPS=$_[0]; 1; }
sub set_cdonopen	     { $SWITCH_TO_NEW_DOCUMENTS=$_[0]; 1; }
sub set_xpath_completion     { $XPATH_COMPLETION=$_[0]; 1; }
sub set_xpath_axis_completion { $XPATH_AXIS_COMPLETION=$_[0];
				if ($XPATH_AXIS_COMPLETION!~/^always|when-empty|never$/) {
				  $XPATH_AXIS_COMPLETION='never';
				}
				1; }

sub get_validation	     { $VALIDATION }
sub get_recovering	     { $RECOVERING }
sub get_expand_entities	     { $PARSER_EXPANDS_ENTITIES }
sub get_keep_blanks	     { $KEEP_BLANKS }
sub get_pedantic_parser	     { $PEDANTIC_PARSER }
sub get_load_ext_dtd	     { $LOAD_EXT_DTD }
sub get_complete_attributes  { $PARSER_COMPLETES_ATTRIBUTES }
sub get_expand_xinclude	     { $PARSER_EXPANDS_XINCLUDE }
sub get_indent		     { $INDENT }
sub get_empty_tags           { $EMPTY_TAGS }
sub get_skip_dtd             { $SKIP_DTD }
sub get_backups		     { $BACKUPS }
sub get_cdonopen	     { $SWITCH_TO_NEW_DOCUMENTS }
sub get_xpath_completion     { $XPATH_COMPLETION }
sub get_xpath_axis_completion { $XPATH_AXIS_COMPLETION }


# initialize global XPathContext
sub xpc_init {
  unless (eval { require XML::LibXML::XPathContext;
		 $_xpc=XML::LibXML::XPathContext->new();
	       }) {
    require XML::XSH::DummyXPathContext;
    print STDERR ("Warning: XML::LibXML::XPathContext not found!\n".
		  "XSH will lack namespace and function registering functionality!\n\n");
    $_xpc=XML::XSH::DummyXPathContext->new();
  }
  $_xpc->registerVarLookupFunc(\&xpath_var_lookup,undef);
  $_xpc->registerNs('xsh',$XML::XSH::xshNS);
  $_xpc->registerFunctionNS('doc',$XML::XSH::xshNS,
			  sub {
			    die "Wrong number of arguments for function doc(id)!" if (@_!=1);
			    my ($id)=literal_value($_[0]);
			    die "Wrong number of arguments for function doc(id)!" if (@_!=1);
			    die "Document does not exist!" unless (exists($_doc{$id}));
			    return $_doc{$id};
			  });
  $_xpc->registerFunctionNS('matches',$XML::XSH::xshNS,
			  sub {
			    die "Wrong number of arguments for function matches(string,regexp)!" if (@_!=2);
			    my ($string,$regexp)=@_;
			    $regexp=literal_value($regexp);
			    use utf8;
			    my $ret=literal_value($string)=~m{$regexp} ?
			      XML::LibXML::Boolean->True : XML::LibXML::Boolean->False;
			    $ret;
			  });
  $_xpc->registerFunctionNS('grep',$XML::XSH::xshNS,
			  sub {
			    die "Wrong number of arguments for function grep(list,regexp)!" if (@_!=2);
			    my ($nodelist,$regexp)=@_;
			    die "1st argument must be a node-list in grep(list,regexp)!" 
			      unless (ref($nodelist) and $nodelist->isa('XML::LibXML::NodeList'));
			    use utf8; 
			    [grep { $_->to_literal=~m{$regexp} } @$nodelist];
			  });
  $_xpc->registerFunctionNS('same',$XML::XSH::xshNS,
			  sub {
			    die "Wrong number of arguments for function same(node,node)!" if (@_!=2);
			    my ($nodea,$nodeb)=@_;
			    die "1st argument must be a node in grep(list,regexp)!" 
			      unless (ref($nodea) and $nodea->isa('XML::LibXML::NodeList'));
			    die "2nd argument must be a node in grep(list,regexp)!" 
			      unless (ref($nodeb) and $nodeb->isa('XML::LibXML::NodeList'));
			    return XML::LibXML::Boolean->new($nodea->size() && $nodeb->size() &&
							     $nodea->[0]->isSameNode($nodea->[0]));
			  });
}

sub list_flags {
  print "validation ".(get_validation() or "0").";\n";
  print "recovering ".(get_recovering() or "0").";\n";
  print "parser_expands_entities ".(get_expand_entities() or "0").";\n";
  print "parser_expands_xinclude ".(get_expand_xinclude() or "0").";\n";
  print "keep_blanks ".(get_keep_blanks() or "0").";\n";
  print "pedantic_parser ".(get_pedantic_parser() or "0").";\n";
  print "load_ext_dtd ".(get_load_ext_dtd() or "0").";\n";
  print "complete_attributes ".(get_complete_attributes() or "0").";\n";
  print "indent ".(get_indent() or "0").";\n";
  print "empty_tags ".(get_empty_tags() or "0").";\n";
  print "skip_dtd ".(get_skip_dtd() or "0").";\n";
  print ((get_backups() ? "backups" : "nobackups"),";\n");
  print (($QUIET ? "quiet" : "verbose"),";\n");
  print (($DEBUG ? "debug" : "nodebug"),";\n");
  print (($TEST_MODE ? "run-mode" : "test-mode"),";\n");
  print "switch_to_new_documents ".(get_cdonopen() or "0").";\n";;
  print "encoding '$ENCODING';\n";
  print "query_encoding '$QUERY_ENCODING';\n";
  print "xpath_completion ".(get_xpath_completion() or "0").";\n";
  print "xpath_axis_completion \'".get_xpath_axis_completion()."';\n";
}

sub toUTF8 {
  # encode/decode from UTF8 returns undef if string not marked as utf8
  # by perl (for example ascii)
  my $res=eval { encodeToUTF8($_[0],$_[1]) };
  if ($@ =~ /^SIGINT/) {
    die $@
  } else {
    undef $@;
  }
  return defined($res) ? $res : $_[1];
}

sub fromUTF8 {
  # encode/decode from UTF8 returns undef if string not marked as utf8
  # by perl (for example ascii)
  my $res=eval { decodeFromUTF8($_[0],$_[1]) };
  if ($@ =~ /^SIGINT/) {
    die $@
  } else {
    undef $@;
  }
  return defined($res) ? $res : $_[1];
}

# evaluate a XSH command
sub xsh {
  xsh_init() unless (ref($_xsh));
  if (ref($_xsh)) {
    my $code=join "",@_;
    return ($code=~/^\s*$/) ? 1 : $_xsh->startrule($code);
  } else {
    die "XSH init failed!\n";
  }
}

# setup output stream
sub xsh_set_output {
  $OUT=$_[0];
  return 1;
}

# get output stream
sub xsh_get_output {
  return $OUT;
}

sub xsh_docs {
  return keys %_doc;
}

sub xsh_parse_string {
  my $format=$_[1] || $DEFAULT_FORMAT;
  if ($format eq 'xml') {
    my $xmldecl;
    $xmldecl="<?xml version='1.0' encoding='utf-8'?>" unless $_[0]=~/^\s*\<\?xml /;
    return $_xml_module->parse_string($_parser,$xmldecl.$_[0]);
  } elsif ($format eq 'html') {
    return $_xml_module->parse_html_string($_parser,$_[0]);
  } elsif ($format eq 'docbook') {
    print "parsing SGML\n";
    return $_xml_module->parse_sgml_string($_parser,$_[0]);
  }
}

sub xsh_xml_parser {
  xsh_init() unless ref($_parser);
  return $_parser;
}

# store a pointer to an XSH-Grammar parser
sub xsh_set_parser {
  $_xsh=$_[0];
  return 1;
}

# print version info
sub print_version {
  out("Main program:              $::VERSION $::REVISION\n");
  out("XML::XSH::Functions:       $VERSION $REVISION\n");
  out("XML::LibXML:               $XML::LibXML::VERSION\n");
#  out($_xml_module->module(),"\t",$_xml_module->version(),"\n");
  out("XML::LibXSLT               $XML::LibXSLT::VERSION\n")
    if defined($XML::LibXSLT::VERSION);
  out("XML::LibXML::XPathContext  $XML::LibXML::XPathContext::VERSION\n")
    if defined($XML::LibXML::XPathContext::VERSION);
  return 1;
}

# print a list of all open files
sub files {
  out(map { "$_ = $_files{$_}\n" } sort keys %_files);
  return 1;
}

sub docs {
  return sort keys %_files;
}

sub _doc {
  return $_doc{$_[0]} if exists($_doc{$_[0]});
}

sub xpath_var_lookup {
  my ($data,$name,$ns)=@_;
  no strict;
  if ($ns eq "") {
    if ($name=~/^_\.(.*)$/ and exists($_nodelist{$1})) {
      return $_nodelist{$1}[1];
    } elsif (defined(${"XML::XSH::Map::$name"})) {
      return ${"XML::XSH::Map::$name"};
    } else {
      die "Undefined nodelist variable `$name'\n";
    }
  }
}

# return a value of the given XSH string or nodelist variable
sub var_value {
  no strict;
  if ($_[0]=~/^\$(.*)/ and defined(${"XML::XSH::Map::$1"})) {
    return "".${"XML::XSH::Map::$1"};
  } elsif ($_[0]=~/^\%(.*)/ and exists($_nodelist{$1})) {
    return $_nodelist{$1};
  } else {
    return undef;
  }
}

sub string_vars {
  no strict;
  return sort grep { defined(${"XML::XSH::Map::$_"}) } keys %{"XML::XSH::Map::"};
}

sub nodelist_vars {
  no strict;
  return sort keys %_nodelist;
}

# print a list of XSH variables and their values
sub variables {
  no strict;
  foreach (keys %{"XML::XSH::Map::"}) {
    out("\$$_='",fromUTF8($ENCODING,${"XML::XSH::Map::$_"}),"';\n") if defined(${"XML::XSH::Map::$_"});
  }
  return 1;
}

# print value of an XSH variable
sub print_var {
  no strict;
  if ($_[0]=~/^\$?(.*)/) {
    out("\$$1='",fromUTF8($ENCODING,${"XML::XSH::Map::$1"}),"';\n") if defined(${"XML::XSH::Map::$1"});
    return 1;
  }
  return 0;
}

sub echo { out(fromUTF8($ENCODING,join " ",expand(@_)),"\n"); return 1; }
sub set_quiet { $QUIET=$_[0]; return 1; }
sub set_debug { $DEBUG=$_[0]; return 1; }
sub set_compile_only_mode { $TEST_MODE=$_[0]; return 1; }

sub test_enc {
  my ($enc)=@_;
  if (defined(toUTF8($enc,'')) and
      defined(fromUTF8($enc,''))) {
    return 1;
  } else {
    _err("Error: Cannot convert between $enc and utf-8\n");
    return 0;
  }
}

sub set_encoding { 
  my $enc=expand($_[0]);
  my $ok=test_enc($enc);
  $ENCODING=$enc if $ok;
  return $ok;
}

sub set_qencoding { 
  my $enc=expand($_[0]);
  my $ok=test_enc($enc);
  $QUERY_ENCODING=$enc if $ok;
  return $ok;
}

sub print_encoding { print "$ENCODING\n"; return 1; }
sub print_qencoding { print "$QUERY_ENCODING\n"; return 1; }

sub sigint {
  if ($TRAP_SIGINT) {
    print STDERR "\nCtrl-C pressed. \n";
    die "SIGINT";
  } else {
    print STDERR "\nCtrl-C pressed. \n";
    exit 1;
  }
}

sub sigpipe {
  if ($TRAP_SIGPIPE) {
    die "SIGPIPE";
  } else {
    _err('broken pipe (SIGPIPE)');
    exit 1;
  }
}

sub flagsigint {
  print STDERR "\nCtrl-C pressed. \n";
  $_sigint=1;
}

sub propagate_flagsigint {
  if ($_sigint) {
    $_sigint=0;
    die 'SIGINT';
  }
}


sub convertFromDocEncoding ($$\$) {
  my ($doc,$encoding,$str)=@_;
  return fromUTF8($encoding, toUTF8($_xml_module->doc_encoding($doc), $str));
}

sub _err {
  print STDERR @_,"\n";
}

# if the argument is non-void then print it and return 0; return 1 otherwise
sub _check_err {
  my ($err,$survive_int)=@_;
  if ($err) {
    if ($err=~/^SIGINT/) {
      if ($survive_int) {
	$err=~s/ at (?:.|\n)*$//;
	_err($err);
	return 0;
      } else {
	die $err; # propagate
      }
    } elsif ($_die_on_err) {
      if ($err=~/^SIGPIPE/) {
	_err('broken pipe (SIGPIPE)');
      } else {
	die $err; # propagate
      }
    } else {
      if ($err=~/^SIGPIPE/) {
	_err('broken pipe (SIGPIPE)');
      } else {
	_err($err);
      }
      return 0;
    }
  }
  return 1;
}

# return current document id
sub xsh_local_id {
  return $LOCAL_ID;
}


# return current node for given document or document root if
# current node is not from the given document
sub get_local_node {
  my ($id)=@_;
  if ($LOCAL_NODE and $id eq $LOCAL_ID) {
    return $LOCAL_NODE;
  } else {
    $id=$LOCAL_ID if ($id eq "");
    return $_doc{$id} ? $_doc{$id} : undef;
  }
}

# return current document's id (and optionally the doc itself) if id is void
sub _id {
  my ($id)=@_;
  if ($id eq "") {
    $id=$LOCAL_ID;
    print STDERR "assuming current document $id\n" if $DEBUG;
  }
  return wantarray ? ($id,$_doc{$id}) : $id;
}

# try to find a document ID by its node
sub _find_id {
  my ($node)=@_;
  if (ref($node)) {
    my $doc=$_xml_module->owner_document($node);
    foreach my $id (keys %_doc) {
      if ($_xml_module->xml_equal($_doc{$id},$doc)) {
	print STDERR "FOUND ID: $id\n" if $DEBUG;
	return $id;
      }
    }
    print STDERR "Error: no document found for current node\n";
    my $uri=$_xml_module->doc_URI($doc);
    if ($uri ne "") {
      pirnt STDERR "Using document('$uri')\n" if $DEBUG;
      return "document('$uri')";
    }
  }
  return "";
}

# extract document id, xpath query string and document pointer from XPath type
sub _xpath {
  my ($id,$query)=expand(@{$_[0]});
  ($id,my $doc)=_id($id);
  return ($id,$query,$doc);
}

# make given node current (no checking!)
sub set_local_node {
  my ($node)=@_;
  if (ref($node)) {
    $LOCAL_NODE=$node;
    $LOCAL_ID=_find_id($node);
  } else {
    $LOCAL_NODE=undef;
    $LOCAL_ID=undef;
  }
}

# make root of the document the current node (no checking!)
sub set_local_doc {
  my ($id)=@_;
  $LOCAL_NODE=$_doc{$id};
  $LOCAL_ID=$id;
}


# set current node to given XPath
sub set_local_xpath {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  if ($query eq "") {
    set_local_doc($id);
    return 1;
  }
  return 0 unless ref($doc);
  my ($newlocal);
  $newlocal=find_nodes($xp)->[0];
  if (ref($newlocal)) {
    set_local_node($newlocal);
  } else {
    die "No node in document $id matches XPath $query!\n";
  }

  return 1;
}

# return XPath identifying a node within its parent's subtree
sub node_address {
  my ($node)=@_;
  my $name;
  if ($_xml_module->is_element($node)) {
    $name=$node->getName();
  } elsif ($_xml_module->is_text($node) or
	   $_xml_module->is_cdata_section($node)) {
    $name="text()";
  } elsif ($_xml_module->is_comment($node)) {
    $name="comment()";
  } elsif ($_xml_module->is_pi($node)) {
    $name="processing-instruction()";
  } elsif ($_xml_module->is_attribute($node)) {
    return "@".$node->getName();
  }
  if ($node->parentNode) {
    my @children;
    if ($_xml_module->is_element($node)) {
      @children=$node->parentNode->findnodes("./*[name()='$name']");
    } else {
      @children=$node->parentNode->findnodes("./$name");
    }
    if (@children == 1 and $_xml_module->xml_equal($node,$children[0])) {
      return "$name";
    }
    for (my $pos=0;$pos<@children;$pos++) {
      return "$name"."[".($pos+1)."]"
	if ($_xml_module->xml_equal($node,$children[$pos]));
    }
    return undef;
  } else {
    return ();
  }
}

# parent element (even for attributes)
sub tree_parent_node {
  my $node=$_[0];
  if ($_xml_module->is_attribute($node)) {
    return $node->ownerElement();
  } else {
    return $node->parentNode();
  }
}

# return canonical xpath for the given or current node
sub pwd {
  my $node=$_[0] || $LOCAL_NODE || $_doc{$LOCAL_ID};
  return undef unless ref($node);
  my @pwd=();
  do {
    unshift @pwd,node_address($node);
    $node=tree_parent_node($node);
  } while ($node);
  my $pwd="/".join "/",@pwd;
  return $pwd;
}

# return canonical xpath for current node (encoded)
sub xsh_pwd {
  my $pwd;
  my ($id, $doc)=_id();
  return undef unless $doc;
  $pwd=fromUTF8($ENCODING,pwd());
  return $pwd;
}

# print current node's xpath
sub print_pwd {
  my $pwd=xsh_pwd();
  if ($pwd) {
    out("$pwd\n\n");
    return $pwd;
  } else {
    return 0;
  }
}

# evaluate variable and xpath expresions given string
sub _expand {
  my $l=$_[0];
  my $k;
  no strict;
  $l=~/^/o;
  while ($l !~ /\G$/gsco) {
    if ($l=~/\G\\(.|\n)/gsco) {
      if (exists($_chr{$1})) {
	$k.=$_chr{$1};
      } else {
	$k.=$1;
      }
    } elsif ($l=~/\G([^\\\$]+)/gsco) {
      $k.=$1;
    } elsif ($l=~/\G\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}/gsco
	     or $l=~/\G\$([a-zA-Z_][a-zA-Z0-9_]*)/gsco) {
      $k.=${"XML::XSH::Map::$1"};
    } elsif ($l=~/\G\$\{\{\{(.+?)\}\}\}/gsco) {
      $k.=perl_eval($1);
    } elsif ($l=~/\G\$\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*):(?!:)(.*?)\}\}/gsco) {
      $k.=count([$1,$2]);
    } elsif ($l=~/\G\$\{\{([^\{].*?)\}\}/gsco) {
      $k.=count([undef,$1]);
    } elsif ($l=~/\G\$\{\(\s*([a-zA-Z_][a-zA-Z0-9_]*):(?!:)(.*?)\)\}/gsco) {
      $k.=eval_xpath_literal([$1,$2]);
    } elsif ($l=~/\G\$\{\((.+?)\)\}/gsco) {
      $k.=eval_xpath_literal([undef,$1]);
    } elsif ($l=~/\G(.|\n)/gsco) {
      $k.=$1;
    }
  }
  return $k;
}

# expand one or all parameters (according to return context)
sub expand {
  return wantarray ? (map { _expand($_) } @_) : _expand($_[0]);
}

# assign a value to a variable
sub _assign {
  my ($name,$value)=@_;
  no strict 'refs';
  $name=~/^\$(.+)/;
  ${"XML::XSH::Map::$1"}=$value;
  print STDERR "\$$1=",${"XML::XSH::Map::$1"},"\n" if $DEBUG;
  return 1;
}

sub _undef {
  my ($name)=@_;
  no strict 'refs';
  $name=~/^\$(.+)/;
  undef ${"XML::XSH::Map::$1"};
  return 1;
}

sub literal_value {
  return ref($_[0]) ? $_[0]->value() : $_[0];
}

# evaluate xpath and assign the result to a variable
sub xpath_assign {
  my ($name,$xp)=@_;
  _assign($name,count($xp));
  return 1;
}

sub xpath_assign_local {
  store_variables(0,$_[0]);
  xpath_assign(@_);
  return 1;
}

sub nodelist_assign_local {
  my ($name)=@_;
  $name=expand($name);
  store_variables(0,"\%$name");
  nodelist_assign(@_);
  return 1;
}

sub make_local {
  foreach (@_) {
    if ($_->[0] eq '$') {
      xpath_assign_local($_->[1],undef);
    } else {
      nodelist_assign_local($_->[1],undef);
    }
  }
}


sub get_stored_nodelists {
  return grep { ref($_) } map { @$_ } @stored_variables;
}

sub store_variables {
  my ($new,@vars)=@_;
  my $pool;
  if ($new) {
    $pool=[];
  } elsif (@stored_variables and ref($stored_variables[$#stored_variables])) {
    $pool=$stored_variables[$#stored_variables];
  } else {
    print STDERR "WARNING: Ignoring attempt to make a local variable outside a localizable context!\n";
    return 0;
  }

  foreach (@vars) {
    my $value=var_value($_);
    push @$pool, $_ => $value;
  }
  push @stored_variables, $pool if ($new);

  return 1;
}

sub restore_variables {
  my $pool=pop @stored_variables;
  unless (ref($pool)) {
    __bug("Local variable pool is empty, which was not expected!\n");
    return 0;
  }
  while (@$pool) {
    my ($value,$name)=(pop(@$pool), pop(@$pool));
    if ($name =~ m/^\$/) {
      if (defined($value)) {
	_assign($name,$value);
      } else {
	_undef($name);
      }
    } elsif ($name =~ m/^\%(.*)$/) {
      if (defined($value)) {
	$_nodelist{$1}=$value;
      } else {
	delete $_nodelist{$1};
      }
    } else {
      __bug("Invalid variable name $1\n");
    }
  }
  return 1;
}

sub _xpc_find_nodes {
  my ($node,$query)=@_;
  $_xpc->setContextNode($node);
  return $_xpc->findnodes($query);
}

# findnodes wrapper which handles both xpaths and nodelist variables
sub _find_nodes {
  my ($context,$q)=@_;
  if ($q=~s/^\%([a-zA-Z_][a-zA-Z0-9_]*)(.*)$/\$_.$1$2/) { # node-list
    my $query=$2;
    my $name=$1;
    unless (exists($_nodelist{$name})) {
      die "No such nodelist '\%$name'\n";
    }
    if ($query =~ /\S/) {
      if ($_xpc->isa('XML::LibXML::XPathContext')) {
	if ($query =~m|^\s*\[(\d+)\](.*)$|) { # index on a node-list
	  return exists($_nodelist{$name}->[1]->[$1+1]) ?
	    scalar(_xpc_find_nodes($_nodelist{$name}->[1]->[$1],'./self::*'.$2)) : [];
	} else {
	  return scalar(_xpc_find_nodes($_nodelist{$name}->[0], $q));
	}
      } else {
	# workaround for dummy XPathContext
	if ($query =~m|^\s*\[(\d+)\](.*)$|) { # index on a node-list
	  return $_nodelist{$name}->[1]->[$1+1] ?
	    [ grep {defined($_)} $_nodelist{$name}->[1]->[$1]->findnodes('./self::*'.$2) ] : [];
	} elsif ($query =~m|^\s*\[|) { # filter in a nodelist
	  return [ grep {defined($_)} map { ($_->findnodes('./self::*'.$query)) }
		   @{$_nodelist{$name}->[1]}
		 ];
	}
	return [ grep {defined($_)} map { ($_->findnodes('.'.$query)) }
		 @{$_nodelist{$name}->[1]}
	       ];
      }
    } else {
      return $_nodelist{$name}->[1];
    }
  } else {
    return scalar(_xpc_find_nodes($context,$q));
  }
}

# _find_nodes wrapper with q-decoding
sub find_nodes {
  my ($id,$query,$doc)=_xpath($_[0]);
  if ($query eq "") { $query="."; }
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }

  return _find_nodes(get_local_node($id),toUTF8($QUERY_ENCODING,$query));
}

sub count_xpath {
  my ($node,$xp)=@_;
  my $result;
  $_xpc->setContextNode($node);
  $result=$_xpc->find($xp);

  if (ref($result)) {
    if ($result->isa('XML::LibXML::NodeList')) {
      return $result->size();
    } elsif ($result->isa('XML::LibXML::Literal')) {
      return $result->value();
    } elsif ($result->isa('XML::LibXML::Number') or
	     $result->isa('XML::LibXML::Boolean')) {
      return $result->value();
    }
  } else {
    return $result;
  }
}

# assign a result of xpath search to a nodelist variable
sub nodelist_assign {
  my ($name,$xp)=@_;
  $name=expand($name);
  my ($id,$query,$doc)=_xpath($xp);
  if ($doc) {
    if ($query eq "") {
      $_nodelist{$name}=[$doc,[]];
    } else {
      $_nodelist{$name}=[$doc,find_nodes($xp)];
      print STDERR "\nStored ",scalar(@{$_nodelist{$name}->[1]})," node(s).\n" unless "$QUIET";
    }
  }
}

sub has_all_ancestors {
  my ($node)=@_;
  while ($node) {
    return 1 if ($_xml_module->is_document($node));
    $node=$node->parentNode;
  }
  return 0;
}

# remove unbounded nodes from all nodelists of a given document
sub remove_dead_nodes_from_nodelists {
  my ($doc)=@_;
  foreach my $list (values(%_nodelist),get_stored_nodelists()) {
    if ($_xml_module->xml_equal($doc,$list->[0])) {
      $list->[1]=[ grep { has_all_ancestors($_) } @{$list->[1]} ];
    }
  }
}

# remove given node and all its descendants from all nodelists
sub remove_node_from_nodelists {
  my ($node,$doc)=@_;
  foreach my $list (values(%_nodelist),get_stored_nodelists()) {
    if ($_xml_module->xml_equal($doc,$list->[0])) {
      $list->[1]=[ grep { !is_ancestor_or_self($node,$_) } @{$list->[1]} ];
    }
  }
}

# create new document
sub create_doc {
  my ($id,$root_element,$format)=expand @_;
  $id=_id($id);
  my $doc;
  $root_element="<$root_element/>" unless ($root_element=~/^\s*</);
  $root_element=toUTF8($QUERY_ENCODING,$root_element);
  $root_element=~s/^\s+//;
  $doc=xsh_parse_string($root_element,$format);
  set_doc($id,$doc,"new_document$_newdoc.xml");
  $_newdoc++;

  set_local_doc($id) if $SWITCH_TO_NEW_DOCUMENTS;
  return $doc;
}

# bind a document with a given id and filename
sub set_doc {
  my ($id,$doc,$file)=@_;
  $_doc{$id}=$doc;
  $_files{$id}=$file;
  return $doc;
}

# return DOM of the document identified by given id
sub get_doc {
  return $_doc{$_[0]};
}

# create a new document by parsing a file
sub open_doc {
  my ($id,$file)=expand @_[0,1];
  my $format;
  my $source;
  if ($_[2]=~/(?:open)?(?:(?:\s*|_|-)(HTML|XML|DOCBOOK|html|xml|docbook))?(?:(?:\s*|_|-)(FILE|file|PIPE|pipe|STRING|string))?/) {
    $format = lc($1) || $DEFAULT_FORMAT;
    $source = lc($2) || 'file';
  } else {
    $format=$DEFAULT_FORMAT;
    $source='file';
  }
  $file=expand($file);
  $file=~s{^(\~[^\/]*)}{(glob($1))[0]}eg;
  $id=_id($id);
  print STDERR "open [$file] as [$id]\n" if "$DEBUG";
  if ($id eq "" or $file eq "") {
    print STDERR "hint: open identifier=file-name\n" unless "$QUIET";
    return;
  }
  if (($source ne 'file') or
      (-f $file) or $file eq "-" or
      ($file=~/^[a-z]+:/)) {
    print STDERR "parsing $file\n" unless "$QUIET";

    my $doc;
    if ($source eq 'pipe') {
      open my $F,"$file|";
      $F || die "Cannot open pipe to $file: $!\n";
      if ($format eq 'xml') {
	$doc=$_xml_module->parse_fh($_parser,$F);
      } elsif ($format eq 'html') {
	$doc=$_xml_module->parse_html_fh($_parser,$F);
      } elsif ($format eq 'docbook') {
	$doc=$_xml_module->parse_sgml_fh($_parser,$F,$QUERY_ENCODING);
      }
      close $F;
    } elsif ($source eq 'string') {
      my $root_element=$file;
      $root_element="<$root_element/>" unless ($root_element=~/^\s*</);
      $root_element=toUTF8($QUERY_ENCODING,$root_element);
      $root_element=~s/^\s+//;
      $doc=xsh_parse_string($root_element,$format);
      set_doc($id,$doc,"new_document$_newdoc.xml");
      $_newdoc++;
    } else  {
      if ($format eq 'xml') {
	$doc=$_xml_module->parse_file($_parser,$file);
      } elsif ($format eq 'html') {
	$doc=$_xml_module->parse_html_file($_parser,$file);
      } elsif ($format eq 'docbook') {
	$doc=$_xml_module->parse_sgml_file($_parser,$file,$QUERY_ENCODING);
      }
    }
    print STDERR "done.\n" unless "$QUIET";
    set_doc($id,$doc,$file);
    set_local_doc($id) if $SWITCH_TO_NEW_DOCUMENTS;
    
#     if ($@ =~ /^'' at /) {
#       print STDERR 
# 	"\nError: ",
# 	"Parsing failed. LibXML returned no error message!\n";
#       print STDERR "Hint: Maybe you are trying to parse with validation on,\n".
# 	"but your document has no DTD? Consider 'validation 0'.\n" if get_validation();
#       return 0;
#     }
#     return _check_err($@);
  } else {
    die "file not exists: $file\n";
    return 0;
  }
}

# close a document and destroy all nodelists that belong to it
sub close_doc {
  my ($id)=expand(@_);
  $id=_id($id);
  unless (exists($_doc{$id})) {
    die "No such document '$id'!\n";
  }
  out("closing file $_files{$id}\n") unless "$QUIET";
  delete $_files{$id};
  foreach (values %_nodelist) {
    if ($_->[0]==$_doc{$id}) {
      delete $_nodelist{$_};
    }
  }
  delete $_doc{$id};
  if (xsh_local_id() eq $id) {
    if ($_doc{'scratch'}) {
      set_local_xpath(['scratch','/']);
    } else {
      set_local_node(undef);
    }
  }
  return 1;
}

sub open_io_file {
  my ($file)=@_;
  if ($file=~/^\s*[|>]/) {
    return IO::File->new($file);
  } elsif ($file=~/.gz\s*$/) {
    return IO::File->new("| gzip -c > $file");
  } else {
    return IO::File->new(">$file");
  }
}

sub is_xinclude {
  my ($node)=@_;
  return
    $_xml_module->is_xinclude_start($node) ||
    ($_xml_module->is_element($node) and
     $node->namespaceURI() eq 'http://www.w3.org/2001/XInclude' and
     $node->localname() eq 'include');
}

sub xinclude_start_tag {
  my ($xi)=@_;
  my %xinc = map { $_->nodeName() => $_->value() } $xi->attributes();
  $xinc{parse}='xml' if ($xinc{parse} eq "");
  return "<".$xi->nodeName()." href='".$xinc{href}."' parse='".$xinc{parse}."'>";
}

sub xinclude_end_tag {
  my ($xi)=@_;
  return "</".$xi->nodeName().">";
}

sub xinclude_print {
  my ($doc,$F,$node,$enc)=@_;
  return unless ref($node);
  if ($_xml_module->is_element($node) || $_xml_module->is_document($node)) {
    $F->print(fromUTF8($enc,start_tag($node))) if $_xml_module->is_element($node);
    my $child=$node->firstChild();
    while ($child) {
      if (is_xinclude($child)) {
	my %xinc = map { $_->nodeName() => $_->value() } $child->attributes();
	$xinc{parse}||='xml';
	$xinc{encoding}||=$enc; # may be used even to convert included XML
	my $elements=0;
	my @nodes=();
	my $node;
	my $expanded=$_xml_module->is_xinclude_start($child);
	if ($expanded) {
	  $node=$child->nextSibling(); # in case of special XINCLUDE node
	} else {
	  $node=$child->firstChild(); # in case of include element from XInclude NS
	}
	my $nested=0;
	while ($node and not($_xml_module->is_xinclude_end($node)
			     and $nested==0
			     and $expanded)) {
	  if ($_xml_module->is_xinclude_start($node)) { $nested++ }
	  elsif ($_xml_module->is_xinclude_end($node)) { $nested-- }
	  push @nodes,$node;
	  $elements++ if $_xml_module->is_element($node);
	  $node=$node->nextSibling();
	}
	if ($nested>0) {
	  print STDERR "Error: Unbalanced nested XInclude nodes.\n",
                       "       Ignoring this XInclude span!\n";
	  $F->print("<!-- ".fromUTF8($enc,xinclude_start_tag($child))." -->");
	} elsif (!$node and $_xml_module->is_xinclude_start($child)) {
	  print STDERR "Error: XInclude end node not found.\n",
 	               "       Ignoring this XInclude span!\n";
	  $F->print("<!-- ".fromUTF8($enc,xinclude_start_tag($child))." -->");
	} elsif ($xinc{parse} ne 'text' and $elements==0) {
	  print STDERR "Warning: XInclude: No elements found in XInclude span.\n",
                       "         Ignoring whole XInclude span!\n";
	  $F->print("<!-- ".fromUTF8($enc,xinclude_start_tag($child))." -->");
	} elsif ($xinc{parse} ne 'xml' and $elements>1) {
	  print STDERR "Error: XInclude: More than one element found in XInclude span.\n",
                       "       Ignoring whole XInclude span!\n";
	  $F->print("<!-- ".fromUTF8($enc,xinclude_start_tag($child))." -->");
	} elsif ($xinc{parse} eq 'text' and $elements>0) {
	  print STDERR "Warning: XInclude: Element(s) found in textual XInclude span.\n",
                       "         Skipping whole XInclude span!\n";
	  $F->print("<!-- ".fromUTF8($enc,xinclude_start_tag($child))." -->");
	} else {
	  $F->print(fromUTF8($enc,xinclude_start_tag($child)));
	  save_xinclude_chunk($doc,\@nodes,$xinc{href},$xinc{parse},$xinc{encoding});
	  $F->print(fromUTF8($enc,xinclude_end_tag($child)));
	  $child=$node if ($expanded); # jump to XINCLUDE end node
	}
      } elsif ($_xml_module->is_xinclude_end($child)) {
	$F->print("<!-- ".fromUTF8($enc,xinclude_end_tag($child))." -->");
      } else {
	xinclude_print($doc,$F,$child,$enc); # call recursion
      }
      $child=$child->nextSibling();
    }
    $F->print(fromUTF8($enc,end_tag($node))) if $_xml_module->is_element($node);
  } else {
    $F->print(fromUTF8($enc,$_xml_module->toStringUTF8($node,$INDENT)));
  }
}

sub save_xinclude_chunk {
  my ($doc,$nodes,$file,$parse,$enc)=@_;

  return unless @$nodes>0;

  if ($BACKUPS) {
    eval { rename $file, $file."~"; };
    _check_err($@);
  }
  my $F=open_io_file($file);
  $F || die "Cannot open $file\n";

  if ($parse eq 'text') {
    foreach my $node (@$nodes) {
      $F->print(fromUTF8($enc,literal_value($node->to_literal)));
    }
  } else {
    my $version=$doc->can('getVersion') ? $doc->getVersion() : '1.0';
    $F->print("<?xml version='$version' encoding='$enc'?>\n");
    foreach my $node (@$nodes) {
      xinclude_print($doc,$F,$node,$enc);
    }
    $F->print("\n");
  }
  $F->close();
}

# save a document
sub save_doc {
  my $type=$_[0];
  my ($id,$file,$enc)=expand($_[1],$_[2],@{$_[3]});

  ($id,my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }

  my $format=$DEFAULT_FORMAT;
  my $target='file';
  if ($type=~/save(?:as|_as|-as)?(?:(?:\s*|_|-)(HTML|html|XML|xml|XINCLUDE|Xinclude|xinclude))?(?:(?:\s*|_|-)(FILE|file|PIPE|pipe|STRING|string))?/) {
    $format = lc($1) if $1;
    $target = lc($2) if $2;
  }

  if ($target eq 'file' and $file eq "") {
    $file=$_files{$id};
    if ($BACKUPS) {
      eval { rename $file, $file."~"; };
      _check_err($@);
    }
  }

  $enc = $enc || $_xml_module->doc_encoding($doc) || 'utf-8';
  print STDERR "saving $id=$_files{$id} to $file as $format (encoding $enc)\n" if "$DEBUG";

  if ($format eq 'xinclude') {
    if ($format ne 'file') {
      print STDERR "Saving to a ".uc($target)." not supported for XInclude\n";
    } else {
      save_xinclude_chunk($doc,[$doc->childNodes()],$file,'xml',$enc);
    }
  } else {
    if ($format eq 'xml') {
      if (lc($_xml_module->doc_encoding($doc)) ne lc($enc)
	  and not($_xml_module->doc_encoding($doc) eq "" and
	  lc($enc) eq 'utf-8')
	 ) {
	$_xml_module->set_encoding($doc,$enc);
      }
      if ($target eq 'file') {
	if ($file=~/\.gz\s*$/) {
	  $doc->setCompression(6);
	} else {
	  $doc->setCompression(-1);
	}
	$doc->toFile($file,$INDENT); # should be document-encoding encoded
	$_files{$id}=$file;
      } elsif ($target eq 'pipe') {
	$file=~s/^\s*\|?//g;
	open my $F,"| $file" || die "Cannot open pipe to $file\n";
	$doc->toFH($F,$INDENT);
	close $F;
      } elsif ($target eq 'string') {
	if ($file =~ /^\$?([a-zA-Z_][a-zA-Z0-9_]*)$/) {
	  no strict qw(refs);
	  ${"XML::XSH::Map::$1"}=$doc->toString($INDENT);
	} else {
	  out($doc->toString($INDENT));
	}
      }
    } elsif ($format eq 'html') {
      my $F;
      if ($target eq 'file') {
	($F=open_io_file($file)) || die "Cannot open $file\n";
	$_files{$id}=$file;
      } elsif ($target eq 'pipe') {
	$file=~s/^\s*\|?//g;
	open $F,"| $file";
	$F || die "Cannot open pipe to $file\n";
      } elsif ($target eq 'string') {
	$F=$OUT;
      }
      $F->print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n")
	unless ($_xml_module->has_dtd($doc));
      $F->print(fromUTF8($enc, toUTF8($_xml_module->doc_encoding($doc),
				      $doc->toStringHTML())));

      $F->close() unless $target eq 'string';
    } elsif ($format eq 'docbook') {
      print STDERR "Docbook is not supported output format!\n";
    }
  }

  print STDERR "Document $id written.\n" unless ($@ or "$QUIET");
  return 1;
}


# create start tag for an element

###
### Workaround of a bug in XML::LibXML:
### getNamespaces, getName returns prefix only,
### prefix returns prefix not xmlns, getAttributes contains also namespaces
### findnodes('namespace::*') returns (namespaces,undef)
###

sub start_tag {
  my ($element)=@_;
  return "<".$element->nodeName().
    join("",map { " ".$_->nodeName()."=\"".$_->nodeValue()."\"" } 
	 $element->attributes())
#	 findnodes('attribute::*'))
#      .    join("",map { " xmlns:".$_->getName()."=\"".$_->nodeValue()."\"" }
#		$element->can('getNamespaces') ?
#		$element->getNamespaces() :
#		$element->findnodes('namespace::*')
#		)
    .($element->hasChildNodes() ? ">" : "/>");
}

# create close tag for an element
sub end_tag {
  my ($element)=@_;
  return $element->hasChildNodes() ? "</".$element->getName().">" : "";
}

# convert a subtree to an XML string to the given depth
sub to_string {
  my ($node,$depth,$folding)=@_;
  my $result;
  if ($node) {
    if (ref($node) and $_xml_module->is_element($node) and $folding and
	$node->hasAttributeNS($XML::XSH::xshNS,'fold')) {
      if ($depth>=0) {
	$depth = min($depth,$node->getAttributeNS($XML::XSH::xshNS,'fold'));
      } else {
	$depth = $node->getAttributeNS($XML::XSH::xshNS,'fold');
      }
    }

    if ($depth<0 and !$folding) {
      $result=ref($node) ? $_xml_module->toStringUTF8($node,$INDENT) : $node;
    } elsif (ref($node) and $_xml_module->is_element($node) and $depth==0) {
      $result=start_tag($node).
	($node->hasChildNodes() ? "...".end_tag($node) : "");
    } elsif ($depth>0 or $folding) {
      if (!ref($node)) {
	$result=$node;
      } elsif ($_xml_module->is_element($node)) {
	$result= start_tag($node).
	  join("",map { to_string($_,$depth-1,$folding) } $node->childNodes).
	    end_tag($node);
      } elsif ($_xml_module->is_document($node)) {
	if ($node->can('getVersion') and $node->can('getEncoding')) {
	  $result=
	    '<?xml version="'.($node->getVersion() || '1.0').'"'.
	      ($node->getEncoding() ne "" ? ' encoding="'.$node->getEncoding().'"' : '').
		'?>'."\n";
	}
	$result.=
	  join("\n",map { to_string($_,$depth-1,$folding) }
	       grep { $SKIP_DTD ? !$_xml_module->is_dtd($_) : 1 } $node->childNodes);
      } else {
	$result=$_xml_module->toStringUTF8($node,$INDENT);
      }
    } else {
      $result = ref($node) ? $_xml_module->toStringUTF8($node,$INDENT) : $node;
    }
  }
  return $result;
}

# list nodes matching given XPath argument to a given depth
sub list {
  my ($xp,$depth)=@_;
  my ($id,$query,$doc)=_xpath($xp);
  my $folding;
  if ($depth=~/^fold/) {
    $folding = 1;
    $depth=-1;
  }
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  print STDERR "listing $query from $id=$_files{$id}\n\n" if "$DEBUG";

  my $ql=find_nodes($xp);
  foreach (@$ql) {
    print STDERR "checking for folding\n" if "$DEBUG";
    my $fold=$folding && ($_xml_module->is_element($_) || $_xml_module->is_document($_)) &&
      $_->findvalue("count(.//\@*[local-name()='fold' and namespace-uri()='$XML::XSH::xshNS'])");
    print STDERR "folding: $fold\n" if "$DEBUG";
    out (fromUTF8($ENCODING,to_string($_,$depth,$fold)),"\n");
  }
  print STDERR "\nFound ",scalar(@$ql)," node(s).\n" unless "$QUIET";

  return 1;
}

# list namespaces in scope of the given nodes
sub list_namespaces {
  my $xp = $_[0] || [undef,'.'];
  my ($id,$query,$doc)=_xpath($xp);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  print STDERR "listing namespaces for $query from $id=$_files{$id}\n\n" if "$DEBUG";

  my $ql=find_nodes($xp);
  foreach my $node (@$ql) {
    my $n=$node;
    my %namespaces;
    while ($n) {
      foreach my $ns ($n->getNamespaces) {
	$namespaces{$ns->getName()}=$ns->getData()
	  unless (exists($namespaces{$ns->getName()}));
      }
      $n=$n->parentNode();
    }
    out(fromUTF8($ENCODING,pwd($node)),":\n");
    foreach (sort { $a cmp $b } keys %namespaces) {
      out("xmlns", ($_ ne "" ? ":" : ""),
	  fromUTF8($ENCODING,$_),"=\"",
	  fromUTF8($ENCODING,$namespaces{$_}),"\"\n");
    }
    out("\n");
  }
  return 1;
}

sub mark_fold {
  my ($xp,$depth)=@_;
  $depth=expand($depth);
  $depth=0 if $depth eq "";

  my $l=find_nodes($xp);
  foreach my $node (@$l) {
    if ($_xml_module->is_element($node)) {
      $node->setAttributeNS($XML::XSH::xshNS,'xsh:fold',$depth);
    }
  }
  return 1;
}

sub mark_unfold {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);
  my $l=find_nodes($xp);
  foreach my $node (@$l) {
    if ($_xml_module->is_element($node) and $node->hasAttributeNS($XML::XSH::xshNS,'fold')) {
      remove_node($node->getAttributeNodeNS($XML::XSH::xshNS,'fold'));
    }
  }
  remove_dead_nodes_from_nodelists($doc);
  return 1;
}


# print canonical xpaths identifying nodes matching given XPath
sub locate {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);

  print STDERR "locating $query from $id=$_files{$id}\n\n" if "$DEBUG";
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $ql=find_nodes($xp);
  foreach (@$ql) {
    out(fromUTF8($ENCODING,pwd($_)),"\n");
  }
  print STDERR "\nFound ",scalar(@$ql)," node(s).\n" unless "$QUIET";
  return 1;
}

# evaluate given xpath and output the result
sub count {
  my ($xp)=@_;
  my ($id,$query,$doc)= _xpath($xp);

  return undef if ($id eq "" or $query eq "");
  unless (ref($doc)) {
    die "No such document: $id\n";
  }
  print STDERR "Query $query on $id=$_files{$id}\n" if $DEBUG;
  my $result=undef;

  if ($query=~/^%/) {
    $result=find_nodes($xp);
    $result=scalar(@$result);
  } else {
    $query=toUTF8($QUERY_ENCODING,$query);
    print STDERR "query: $query\n" if "$DEBUG";
    $result=fromUTF8($ENCODING,count_xpath(get_local_node($id), $query));
    print STDERR "result: $result" if "$DEBUG";
  }
  return $result;
}

# evaluate given xpath and return the text content of the result
sub eval_xpath_literal {
  my ($xp)=@_;
  my ($id,$query)=_xpath($xp);
  $_xpc->setContextNode(get_local_node($id));
  my $result = $_xpc->find(toUTF8($QUERY_ENCODING,$query));
  if (!ref($result)) {
    return $result;
  } else {
    if ($result->isa('XML::LibXML::NodeList')) {
      if (wantarray) {
	return map { literal_value($_->to_literal) } @$result;
      } elsif ($result->[0]) {
	return literal_value($result->[0]->to_literal);
      } else {
	return '';
      }
    } else {
      return literal_value($result->to_literal);
    }
  }
}


# remove nodes matching given XPath from a document and
# remove all their descendants from all nodelists
sub prune {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $i=0;

  my $ql=find_nodes($xp);
  foreach my $node (@$ql) {
    remove_node($node,get_keep_blanks());
    $i++;
  }
  remove_dead_nodes_from_nodelists($doc);
  print STDERR "$i node(s) removed from $id=$_files{$id}\n" unless "$QUIET";
  return 1;
}

# evaluate given perl expression
sub eval_substitution {
  my ($val,$expr)=@_;
  $_ = fromUTF8($QUERY_ENCODING,$val) if defined($val);

  eval "package XML::XSH::Map; no strict 'vars'; $expr";
  die $@ if $@; # propagate
  return toUTF8($QUERY_ENCODING,$_);
}

# sort given nodelist according to the given xsh code and perl code
sub perlsort {
  my ($crit,$perl,$var)=@_;
  $var=expand($var);
  return 1 unless (exists($_nodelist{$var}));
  return 1 unless ref(my $list=$_nodelist{$var});
  my $doc=$list->[0];

  my @list = map {
      local $LOCAL_NODE=$_;
      local $LOCAL_ID=_find_id($_);
      [$_, (ref($crit) eq 'ARRAY') ? eval_xpath_literal($crit) : scalar(perl_eval($crit))]
    } @{$list->[1]};

  @{$list->[1]} = map { $_->[0] }
    sort {
      local $XML::XSH::Map::a = $a->[1];
      local $XML::XSH::Map::b = $b->[1];
      my $result=eval "package XML::XSH::Map; no strict 'vars'; $perl";
      die $@ if ($@); # propagate
      $result;
    } @list;

  return 1;
}

# Evaluate given perl expression over every element matching given XPath.
# The element is passed to the expression by its name or value in the $_
# variable.
sub perlmap {
  my ($q, $expr)=@_;
  my ($id,$query,$doc)=_xpath($q);

  print STDERR "Executing $expr on $query in $id=$_files{$id}\n" if "$DEBUG";
  unless ($doc) {
    die "No such document $id\n";
  }

  my $sdoc=get_local_node($id);

  my $ql=_find_nodes($sdoc, toUTF8($QUERY_ENCODING,$query));
  foreach my $node (@$ql) {
    if ($_xml_module->is_attribute($node)) {
      my $val=$node->getValue();
      $node->setValue(eval_substitution("$val",$expr));
    } elsif ($_xml_module->is_element($node)) {
      my $val=$node->getName();
      if ($node->can('setName')) {
	$node->setName(eval_substitution("$val",$expr));
      } else {
	_err "Node renaming not supported by ",ref($node);
      }
    } elsif ($node->can('setData') and $node->can('getData')) {
      my $val=$node->getData();
      $node->setData(eval_substitution("$val",$expr));
    }
  }
  return 1;
}

sub perlrename {
  my ($q, $expr)=@_;
  my ($id,$query,$doc)=_xpath($q);

  print STDERR "Executing $expr on $query in $id=$_files{$id}\n" if "$DEBUG";
  unless ($doc) {
    die "No such document $id\n";
  }

  my $sdoc=get_local_node($id);

  my $ql=_find_nodes($sdoc, toUTF8($QUERY_ENCODING,$query));
  foreach my $node (@$ql) {
    if ($_xml_module->is_attribute($node) ||
	$_xml_module->is_element($node) ||
	$_xml_module->is_pi($node)) {
      if ($node->can('setName')) {
	my $val=$node->getName();
	$node->setName(eval_substitution("$val",$expr));
      } else {
	_err "Node renaming not supported by ",ref($node);
      }
    }
  }
  return 1;
}

sub set_attr_ns {
  my ($node,$ns,$name,$value)=@_;
  if ($ns eq "") {
    $node->setAttribute($name,$value);
  } else {
    $node->setAttributeNS("$ns",$name,$value);
  }
}

# return NS prefix used in the given name
sub name_prefix {
  if ($_[0]=~/^([^:]+):/) {
    return $1;
  }
}

# try to safely clone a node
sub node_copy {
  my ($node,$ns,$dest_doc,$dest)=@_;

  my $copy;
  if ($_xml_module->is_element($node) and !$node->hasChildNodes) {
    # -- prepare NS
    $ns=$node->namespaceURI() if ($ns eq "");
    if ($ns eq "" and name_prefix($node->getName) ne "") {
      $ns=$dest->lookupNamespaceURI(name_prefix($node->getName));
    }
    # --
    $copy=new_element($dest_doc,$node->getName(),$ns,
		      [map { [$_->nodeName(),$_->nodeValue(), $_->namespaceURI()] } $node->attributes],$dest);
  } elsif ($_xml_module->is_document_fragment($node)) {
    $copy=$_parser->parse_xml_chunk($node->toString());
  } else {
    $copy=$_xml_module->clone_node($dest_doc,$node);
  }
}

# get element-children of a node (e.g. of a document fragment)
sub get_subelements {
  my ($docfrag)=@_;
  return grep { $_xml_module->is_element($_) } $docfrag->childNodes();
}

sub get_following_siblings {
  my ($node)=@_;
  my @siblings;
  $node=$node->nextSibling();
  while ($node) {
    push @siblings,$node;
    $node=$node->nextSibling();
  }
  return @siblings;
}

# create new document element before the given nodelist
sub new_document_element {
  my ($doc,$node,@nodelist)=@_;
  $doc->setDocumentElement($node);
  foreach my $n (reverse @nodelist) {
    $doc->removeChild($n);
    $doc->insertAfter($n,$node);
  }
}

# safely insert source node after, before or instead of the
# destination node. Safety means here that nodes inserted on the
# document level are given special care.  the source node may only be
# a document fragment, element, text, CDATA, Comment, Entity or
# a PI (i.e. not an attribute).

sub safe_insert {
  my ($source,$dest,$where) = @_;
  my $parent=$dest->parentNode();
  return unless $parent;
  if ($_xml_module->is_document($parent)) {

    # placing a node on the document-level
    # SOURCE: Element
    if ($_xml_module->is_element($source)) {
      if ($where eq 'after') {
	if ($parent->getDocumentElement()) {
	  die("Error: cannot insert another element into /:\n",
	       "  there's one document element already!");
	} else {
	  new_document_element($parent,$source,
			       get_following_siblings($dest));
	}
	return 'keep';
      } elsif ($where eq 'before') {
	if ($parent->getDocumentElement()) {
	  die("Error: cannot insert another element into /:\n",
	       "  there's one document element already!");
	} else {
	  new_document_element($parent,$source,
			       $dest,get_following_siblings($dest));
	}
	return 'keep';
      } elsif ($where eq 'replace') {
	# maybe we are loosing the document element here !
	if ($parent->getDocumentElement()) {
	  if ($_xml_module->is_element($dest)) {
	    my $nextnode = $parent->getDocumentElement()->nextSibling();
	    new_document_element($parent,$source,
				 $dest,get_following_siblings($dest));
	  } else {
	    die("Error: cannot insert another element into /:\n",
	         "  there's one document element already!");
	  }
	} else {
	  new_document_element($parent,$source,
			       $dest,get_following_siblings($dest));
	}
	return 'remove';
      }
    } # SOURCE: PI or Comment or DocFragment with PI's or Comments
    elsif ($_xml_module->is_pi($source) ||
	   $_xml_module->is_comment($source) ||
	   $_xml_module->is_entity_reference($source) ||
	   $_xml_module->is_document_fragment($source)) {
      # placing a node into an element
      if ($where eq 'after') {
	$parent->insertAfter($source,$dest);
	return 'keep';
      } elsif ($where eq 'before') {
	$parent->insertBefore($source,$dest);
	return 'keep';
      } elsif ($where eq 'replace') {
	# maybe we are loosing the document element here !
	$parent->insertBefore($source,$dest);
	return 'remove';
      }
    } else {
      die("Error: cannot insert node ",ref($source)," on a document level");
    }
  } else {
    if ($where eq 'after') {
      $parent->insertAfter($source,$dest);
      return 'keep';
    } elsif ($where eq 'before') {
      $parent->insertBefore($source,$dest);
      return 'keep';
    } elsif ($where eq 'replace') {
      $parent->insertBefore($source,$dest);
      return 'remove';
    }
  }
}

# insert given node to given destination performing
# node-type conversion if necessary
sub insert_node {
  my ($node,$dest,$dest_doc,$where,$ns)=@_;

  if ($_xml_module->is_document($node)) {
    die "Error: Can't insert/copy/move document nodes!";
  }

  # destination: Attribute
  if ($_xml_module->is_attribute($dest)) {
    # source: Text, CDATA, Comment, Entity, Element
    if ($_xml_module->is_text($node)           ||
	$_xml_module->is_cdata_section($node)  ||
	$_xml_module->is_comment($node) ||
	$_xml_module->is_element($node) ||
	$_xml_module->is_pi($node)) {
      my $val = $_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      if ($where eq 'replace' or $where eq 'into') {
	$val=~s/^\s+|\s+$//g;
	# xcopy will replace the value several times, which may not be intended
	set_attr_ns($dest->ownerElement(),$dest->namespaceURI(),$dest->getName(),$val);
	return 'keep'; # as opposed to 'remove'
      } elsif ($where eq 'before' or $where eq 'prepend') {
	$val=~s/^\s+//g;
	set_attr_ns($dest->ownerElement(),$dest->namespaceURI(),$dest->getName(),
		    $val.$dest->getValue());
      } elsif ($where eq 'after' or $where eq 'append') {
	$val=~s/\s+$//g;
	set_attr_ns($dest->ownerElement(),$dest->namespaceURI(),$dest->getName(),
		    $dest->getValue().$val);
      }

    }
    # source: Attribute
    elsif ($_xml_module->is_attribute($node)) {
      my $name=$node->getName();
      my $value = $node->getValue();
      if ($where eq 'replace' or $where eq 'after' or $where eq 'before') {
	# -- prepare NS
	$ns=$node->namespaceURI() if ($ns eq "");
	if ($ns eq "" and name_prefix($name) ne "") {
	  $ns=$dest->lookupNamespaceURI(name_prefix($name))
	}
	# --
	my $elem=$dest->ownerElement();
	set_attr_ns($elem,"$ns",$name,$value);
	if ($where eq 'replace' and $name ne $dest->getName()) {
	  return 'remove'; # remove the destination node in the end
	} else {
	  return 'keep'; # no need to remove the destination node
	}
      } else {
	# -- prepare NS
	$ns=$dest->namespaceURI(); # given value of $ns is ignored here
	# --
	if ($where eq 'append') {
	  set_attr_ns($dest->ownerElement(),"$ns",$dest->getName,$dest->getValue().$value);
	} elsif ($where eq 'into') {
	  set_attr_ns($dest->ownerElement(),"$ns",$dest->getName(),$value);
	} elsif ($where eq 'prepend') {
	  set_attr_ns($dest->ownerElement(),"$ns",$dest->getName(),$value.$dest->getValue());
	}
      }
    } else {
      _err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
            ref($node)," $where ",ref($dest),"!");
      return 1;
    }
  }
  # destination: Document
  elsif ($_xml_module->is_document($dest)) {
    # source: Attribute, Text, CDATA
    if ($_xml_module->is_attribute($node) or
	$_xml_module->is_text($node) or
	$_xml_module->is_cdata_section($node)
       ) {
      _err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
            ref($node)," $where ",ref($dest),"!");
      return 1;
    } elsif ($_xml_module->is_element($node)) {
    # source: Element
      my $copy=node_copy($node,$ns,$dest_doc,$dest);
      my $destnode;
      my $newwhere;
      if ($where =~ /^(?:after|append|into)/) {
	$newwhere='after';
	$destnode=$dest->lastChild();
      } elsif ($where =~ /^(?:before|prepend)/) {
	$newwhere='before';
	$destnode=$dest->firstChild();
      } elsif ($where eq 'replace') {
	_err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
	     ref($node)," $where ",ref($dest),"!");
	return 1;
      }
      if ($destnode) {
	return safe_insert($copy,$destnode,$newwhere);
      } else {
	new_document_element($dest,$copy);
	return 1;
      }
    } else {
    # source: Chunk, PI, Comment, Entity
      my $copy=node_copy($node,$ns,$dest_doc,$dest);
      if ($where =~ /^(?:after|append|into)/) {
	# rather than appendChild which does not work
	# for Chunks!
	$dest->insertAfter($copy,$dest->lastChild());
      } elsif ($where =~ /^(?:before|prepend)/) {
	$dest->insertBefore($copy,$dest->firstChild());
      } elsif ($where eq 'replace') {
	_err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
	     ref($node)," $where ",ref($dest),"!");
	return 1;
      }
    }
  }
  # destination: Element
  elsif ($_xml_module->is_element($dest)) {
    # source: Attribute
    if ($_xml_module->is_attribute($node)) {
      # -- prepare NS
      $ns=$node->namespaceURI() if ($ns eq "");
      if ($ns eq "" and name_prefix($node->getName) ne "") {
	$ns=$dest->lookupNamespaceURI(name_prefix($node->getName))
      }
      # --
      if ($where eq 'into' or $where eq 'append' or $where eq 'prepend') {
	set_attr_ns($dest,"$ns",$node->getName(),$node->getValue());
      } elsif ($where eq 'replace') {
	my $parent=$dest->parentNode();
	if ($_xml_module->is_element($parent)) {
	  set_attr_ns($dest,"$ns",$node->getName(),$node->getValue());
	} else {
	  _err("Warning: Cannot replace ",ref($node)," with ",ref($parent),
               ": parent node is not an element!");
	  return 1;
	}
	return 'remove';
      } else {
	_err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
	     ref($node)," $where ",ref($dest),"!");
	return 1;
# 	# converting attribute to element
# 	my $new=new_element($dest_doc,$node->getName(),$ns,$dest);
# 	$new->appendText($node->getValue());
# 	my $parent=$dest->parentNode();
# 	if ($_xml_module->is_element($parent)) {
# 	  if ($where eq 'before' or $where eq 'after') {
# 	    safe_insert($new,$dest,$where);
# 	  }
# 	} elsif ($where eq 'append') {
# 	  $dest->appendChild($new);
# 	} elsif ($where eq 'prepend') {
# 	  $dest->insertBefore($new,$dest->firstChild());
# 	}
      }
    }
    # source: Any but Attribute
    else {
      my $copy=node_copy($node,$ns,$dest_doc,$dest);
      if ($where eq 'after' or $where eq 'before' or $where eq 'replace') {
	return safe_insert($copy,$dest,$where);
      } elsif ($where eq 'into' or $where eq 'append') {
	$dest->appendChild($copy);
      } elsif ($where eq 'prepend') {
	if ($dest->hasChildNodes()) {
	  $dest->insertBefore($copy,$dest->firstChild());
	} else {
	  $dest->appendChild($copy);
	}
      }
    }
  }
  # destination: Text, CDATA, Comment, PI
  elsif ($_xml_module->is_text($dest)          ||
	 $_xml_module->is_cdata_section($dest) ||
	 $_xml_module->is_comment($dest)       ||
	 $_xml_module->is_pi($dest) ||
	 $_xml_module->is_entity_reference($dest)
	) {
    if ($where =~ /^(?:into|append|prepend)$/ and
	($_xml_module->is_entity_reference($dest) ||
	 $_xml_module->is_entity_reference($node))) {
      _err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
	   ref($node)," $where ",ref($dest),"!");
      return 1;
    }
    if ($where eq 'into') {
      my $value=$_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      $dest->setData($value);
    } elsif ($where eq 'append') {
      my $value=$_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      $dest->setData($dest->getData().$value);
    } elsif ($where eq 'prepend') {
      my $value=$_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      $dest->setData($value.$dest->getData());
    }
    # replace + source: Attribute
    elsif ($where eq 'replace' and $_xml_module->is_attribute($node)) {
      my $parent=$dest->parentNode();
      # -- prepare NS
      $ns=$node->namespaceURI() if ($ns eq "");
      if ($ns eq "" and name_prefix($node->getName) ne "") {
	$ns=$dest->lookupNamespaceURI(name_prefix($node->getName));
      }
      # --
      if ($_xml_module->is_element($parent)) {
	set_attr_ns($dest,"$ns",$node->getName(),$node->getValue());
      }
      return 'remove';
    } else {
      my $parent=$dest->parentNode();
      my $new;
      # source: Attribute
      if ($_xml_module->is_attribute($node)) {
	_err("Warning: Ignoring incompatible nodes in insert/copy/move operation:\n",
	     ref($node)," $where ",ref($dest),"!");
	return 1;
# 	# implicit conversion of attribute to element
# 	# -- prepare NS
# 	$ns=$node->namespaceURI() if ($ns eq "");
# 	if ($ns eq "" and name_prefix($node->getName) ne "") {
# 	  $ns=$parent->lookupNamespaceURI(name_prefix($node->getName));
# 	}
# 	# --
# 	$new=new_element($dest_doc,$node->getName(),$ns,$dest);
# 	$new->appendText($node->getValue());
      }
      # source: All other
      else {
	$new=node_copy($node,$ns,$dest_doc,$dest);
      }
      if ($where =~ /^(?:after|before|replace)$/) {
	return safe_insert($new,$dest,$where);
      }
    }
  } else {
    print STDERR "Warning: unsupported/unknown destination type: ",ref($dest),"\n";
  }
  return 1;
}

# copy nodes matching one XPath expression to locations determined by
# other XPath expression
sub copy {
  my ($fxp,$txp,$where,$all_to_all)=@_;
  my ($fid,$fq,$fdoc)=_xpath($fxp); # from xpath
  my ($tid,$tq,$tdoc)=_xpath($txp); # to xpath

  unless (ref($fdoc)) {
    die "No such document '$fid'!\n";
  }
  unless (ref($tdoc)) {
    die "No such document '$tid'!\n";
  }
  my ($fl,$tl);

  $fl=find_nodes($fxp);
  $tl=find_nodes($txp);

  unless (@$tl) {
    print STDERR "No matching nodes found for $tq in $tid=$_files{$tid}\n" unless "$QUIET";
    return 0;
  }
  my $some_nodes_removed=0;
  if ($all_to_all) {
    foreach my $tp (@$tl) {
      my $replace=0;
      foreach my $fp (@$fl) {
	$replace = ((insert_node($fp,$tp,$tdoc,$where) eq 'remove') || $replace);
      }
      if ($replace) {
	$some_nodes_removed=1;
	remove_node($tp);
      }
    }
  } else {
    while (ref(my $fp=shift @$fl) and ref(my $tp=shift @$tl)) {
      my $replace=insert_node($fp,$tp,$tdoc,$where);
      if ($replace eq 'remove') {
	$some_nodes_removed=1;
	remove_node($tp);
      }
    }
  }
  if ($some_nodes_removed) {
    remove_dead_nodes_from_nodelists($tdoc);
  }
  return 1;
}

# parse a string and create attribute nodes
sub create_attributes {
  my ($exp)=@_;
  my (@ret,$value,$name);
  while ($exp!~/\G$/gsco) {
    if ($exp=~/\G\s*([^ \n\r\t=]+)=/gsco) {
      my $name=$1;
      print STDERR "attribute_name=$1\n" if $DEBUG;
      if ($exp=~/\G"((?:[^\\"]|\\.)*)"/gsco or
	  $exp=~/\G'((?:[^\\']|\\.)*)'/gsco or
	  $exp=~/\G(.*?\S)(?=\s*[^ \n\r\t=]+=|\s*$)/gsco) {
	$value=$1;
	$value=~s/\\(.)/$1/g;
	print STDERR "creating $name=$value attribute\n" if $DEBUG;
	push @ret,[$name,$value];
      } else {
	$exp=~/\G(\S*\s*)/gsco;
	print STDERR "ignoring $name=$1\n";
      }
    } else {
      $exp=~/\G(\S*\s*)/gsco;
      print STDERR "ignoring characters $1\n";
    }
  }
  return @ret;
}

sub new_element {
  my ($doc,$name,$ns,$attrs,$dest)=@_;
  my $el;
  my $prefix;
  if ($name=~/^([^:>]+):(.*)$/) {
    $prefix=$1;
    die "Error: undefined namespace prefix `$prefix'\n"  if ($ns eq "");
    if ($dest && $_xml_module->is_element($dest)) {
      $el=$dest->addNewChild($ns,$name);
      $el->unbindNode();
    } else {
      $el=$doc->createElementNS($ns,$name);
    }
  } else {
    $el=$doc->createElement($name);
  }
  if (ref($attrs)) {
    foreach (@$attrs) {
      if ($ns ne "" and ($_->[0]=~/^${prefix}:/)) {
	print STDERR "NS: $ns\n" if $DEBUG;
	$el->setAttributeNS($ns,$_->[0],$_->[1]);
      } elsif  ($_->[0] eq "xmlns:(.*)") {
	# don't redeclare NS if already declared on destination node
	unless ($1 eq $ns or $dest->lookupNamespaceURI($1) eq $_->[2]) {
	  $el->setAttribute($_->[0],$_->[1]) unless ($_->[1] eq $ns);
	}
      } elsif ($_->[0]=~/^([^:>]+):/) {
	my $lprefix=$1;
	if ($_->[2] ne "") {
	  $el->setAttributeNS($_->[2],$_->[0],$_->[1]);
	} else {
	  # add the attribute anyway (may have wrong qname!)
	  $el->setAttribute($_->[0],$_->[1]);
	}
      } else {
	next if ($_->[0] eq "xmlns:$prefix" and $_->[1] eq $ns);
	$el->setAttribute($_->[0],$_->[1]); # what about other namespaces?
      }
    }
  }
  return $el;
}

# create nodes from their textual representation
sub create_nodes {
  my ($type,$exp,$doc,$ns)=@_;
  my @nodes=();
#  return undef unless ($exp ne "" and ref($doc));
  if ($type eq 'attribute') {
    foreach (create_attributes($exp)) {
      my $at;
      if  ($_->[0]=~/^([^:]+):/ and $1 ne 'xmlns') {
	die "Error: undefined namespace prefix `$1'\n"  if ($ns eq "");
	$at=$doc->createAttributeNS($ns,$_->[0],$_->[1]);
      } else {
	$at=$doc->createAttribute($_->[0],$_->[1]);
      }
      push @nodes,$at;
    }
  } elsif ($type eq 'element') {
    my ($name,$attributes);
    if ($exp=~/^\<?([^ \t\n\/\<\>]+)(\s+.*)?(?:\/?\>)?\s*$/) {
      print STDERR "element_name=$1\n" if $DEBUG;
      print STDERR "attributes=$2\n" if $DEBUG;
      my ($elt,$att)=($1,$2);
      my $el;
      if ($elt=~/^([^:>]+):(.*)$/) {
	print STDERR "NS: $ns\n" if $DEBUG;
	print STDERR "Name: $elt\n" if $DEBUG;
	die "Error: undefined namespace prefix `$1'\n"  if ($ns eq "");
	$el=$doc->createElementNS($ns,$elt);
      } else {
	$el=$doc->createElement($elt);
      }
      if ($att ne "") {
	$att=~s/\/?\>?$//;
	foreach (create_attributes($att)) {
	  print STDERR "atribute: ",$_->[0],"=",$_->[1],"\n" if $DEBUG;
	  if ($elt=~/^([^:]+):/ and $1 ne 'xmlns') {
	    print STDERR "NS: $ns\n" if $DEBUG;
	    die "Error: undefined namespace prefix `$1'\n"  if ($ns eq "");
	    $el->setAttributeNS($ns,$_->[0],$_->[1]);
	  } else {
	    $el->setAttribute($_->[0],$_->[1]);
	  }
	}
      }
      push @nodes,$el;
    } else {
      print STDERR "invalid element $exp\n" unless "$QUIET";
    }
  } elsif ($type eq 'text') {
    push @nodes,$doc->createTextNode($exp);
    print STDERR "text=$exp\n" if $DEBUG;
  } elsif ($type eq 'entity_reference') {
    push @nodes,$doc->createEntityReference($exp);
    print STDERR "entity_reference=$exp\n" if $DEBUG;
  } elsif ($type eq 'cdata') {
    push @nodes,$doc->createCDATASection($exp);
    print STDERR "cdata=$exp\n" if $DEBUG;
  } elsif ($type eq 'pi') {
    my ($name,$data)=($exp=~/^\s*(?:\<\?)?(\S+)(?:\s+(.*?)(?:\?\>)?)?$/);
    my $pi = $doc->createProcessingInstruction($name);
    $pi->setData($data);
    print STDERR "pi=<?$name ... $data?>\n" if $DEBUG;
    push @nodes,$pi;
#    print STDERR "cannot add PI yet\n" if $DEBUG;
  } elsif ($type eq 'comment') {
    push @nodes,$doc->createComment($exp);
    print STDERR "comment=$exp\n" if $DEBUG;
  }
  return @nodes;
}

# create new nodes from an expression and insert them to locations
# identified by XPath
sub insert {
  my ($type,$exp,$xpath,$where,$ns,$to_all)=@_;

  $exp = expand($exp);
  $ns  = expand($ns);

  my ($tid,$tq,$tdoc)=_xpath($xpath); # destination(s)

  return 0 unless ref($tdoc);

  my @nodes;
  $ns=toUTF8($QUERY_ENCODING,$ns);
  unless ($type eq 'chunk') {
    $exp=toUTF8($QUERY_ENCODING,$exp);
    @nodes=grep {ref($_)} create_nodes($type,$exp,$tdoc,$ns);
    return unless @nodes;
  } else {
    if ($exp !~/^\s*<?xml [^>]*encoding=[^>]*?>/) {
      $exp=toUTF8($QUERY_ENCODING,$exp);
    }
    @nodes=grep {ref($_)} ($_parser->parse_xml_chunk($exp));
  }
  my $tl=find_nodes($xpath);
  my $some_nodes_removed=0;
  if ($to_all) {
    foreach my $tp (@$tl) {
      my $replace=0;
      foreach my $node (@nodes) {
	$replace = (insert_node($node,$tp,$tdoc,$where) eq 'remove') || $replace;
      }
      if ($replace) {
	$some_nodes_removed=1;
	remove_node($tp);
      }
    }
  } elsif ($tl->[0]) {
    foreach my $node (@nodes) {
      if (ref($tl->[0])) {
	if (insert_node($node,$tl->[0],$tdoc,$where) eq 'remove') {
	  $some_nodes_removed=1;
	  remove_node($tl->[0]);
	}
      }
    }
  }
  if ($some_nodes_removed) {
    remove_dead_nodes_from_nodelists($tdoc);
  }
  return 1;
}

# normalize nodes
sub normalize_nodes {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);

  print STDERR "normalizing $query from $id=$_files{$id}\n\n" if "$DEBUG";
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $ql=find_nodes($xp);
  foreach (@$ql) {
    $_->normalize();
  }
  return 1;
}

sub _trim_ws {
  my ($text)=@_;
  $text=~s/^\s*//;
  $text=~s/\s*$//;
  return $text;
}

# strip whitespace from given nodes
sub strip_ws {
  my ($xp)=@_;
  my ($id,$query,$doc)=_xpath($xp);

  print STDERR "stripping whitespace in $query from $id=$_files{$id}\n\n" if "$DEBUG";
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $ql=find_nodes($xp);
  foreach my $node (@$ql) {
    if ($_xml_module->is_text($node)
	or
	$_xml_module->is_cdata_section($node)
	or
	$_xml_module->is_comment($node)
       ) {
      my $data=_trim_ws($node->getData());
      if ($data ne "") {
	$node->setData($data);
      } else {
	$node->unbindNode();
      }
    } elsif ($_xml_module->is_pi($node)) {
      $node->setData(_trim_ws($node->getData($node)));
    } elsif ($_xml_module->is_attribute($node)) {
      $node->setValue(_trim_ws($node->getValue));
    } elsif ($_xml_module->is_element($node) or
	     $_xml_module->is_document($node)) {
      # traverse children, skip comments, strip text nodes
      # until first element or PI or text node containing
      # a non-ws character
      my $child=$node->firstChild();
      while ($child) {
	if ($_xml_module->is_text($child) or
	    $_xml_module->is_cdata_section($child)) {
	  my $data=_trim_ws($child->getData());
	  if ($data ne "") {
	    $child->setData($data);
	    last;
	  } else {
	    $child->unbindNode();
	  }
	} elsif ($_xml_module->is_element($child) or
		 $_xml_module->is_pi($child)) {
	  last;
	}
	$child=$child->nextSibling();
      }
      # traverse children (upwards), skip comments, strip text nodes
      # until first element or PI or text node containing a non-ws
      # character
      my $child=$node->lastChild();
      while ($child) {
	if ($_xml_module->is_text($child) or
	    $_xml_module->is_cdata_section($child)) {
	  my $data=_trim_ws($child->getData());
	  if ($data ne "") {
	    $child->setData($data);
	    last;
	  } else {
	    $child->unbindNode();
	  }
	} elsif ($_xml_module->is_element($child) or
		 $_xml_module->is_pi($child)) {
	  last;
	}
	$child=$child->previousSibling();
      }
    }
  }
  return 1;
}

# fetch document's DTD
sub get_dtd {
  my ($doc)=@_;
  my $dtd;
  $dtd=$_xml_module->get_dtd($doc,$QUIET);

  return $dtd;
}

# check document validity
sub validate_doc {
  my ($show_errors,$schema,$id)=@_;
  $id=expand $id;
  __debug("SCHEMA @$schema");
  my @schema = expand @$schema;
  __debug("SCHEMA @schema");
  ($id,my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id' (to validate)!\n";
  }

  if ($doc->can('is_valid')) {
    if (@schema) {
      my $type = shift @schema;
      my $format = shift @schema;
      if ($type eq 'DTD') {
	my $dtd;
	eval { XML::LibXML::Dtd->can('new') } ||
	  die "DTD validation not supported by your version of XML::LibXML\n";
	if ($format eq 'FILE') {
	  __debug("PUBLIC $schema[0], SYSTEM $schema[1]");
	  $dtd=XML::LibXML::Dtd->new(@schema);
	  __debug($dtd);
	} elsif ($format eq 'STRING') {
	  __debug("STRING $schema[0]");
	  $dtd=XML::LibXML::Dtd->parse_string($schema[0]);
	  __debug($dtd);
	  __debug($dtd->toString());
	} else {
	  die "Unknown DTD format '$format!'\n";
	}
	if ($show_errors) {
	  $doc->validate($dtd);
	} else {
	  out(($doc->is_valid($dtd) ? "yes\n" : "no\n"));
	}
      } elsif ($type eq 'RNG') {
	eval { XML::LibXML::RelaxNG->can('new') } ||
	  die "RelaxNG validation not supported by your version of XML::LibXML\n";
	my $rng;
	if ($format eq 'FILE') {
	  $rng=XML::LibXML::RelaxNG->new(location => $schema[0]);
	} elsif ($format eq 'STRING') {
	  $rng=XML::LibXML::RelaxNG->new(string => $schema[0]);
	} elsif ($format eq 'DOC') {
	  my $rngdoc=_doc($schema[0]);
	  unless (ref($rngdoc)) {
	    die "No such document '$schema[0]'!\n";
	  }
	  $rng=XML::LibXML::RelaxNG->new(DOM => $rngdoc);
	} else {
	  die "Unknown RelaxNG format '$format!'\n";
	}
	eval { $rng->validate($doc) };
	if ($show_errors) {
	  die "$@\n";
	} else {
	  out($@ ? "no\n" : "yes\n");
	}
      } elsif ($type eq 'XSD') {
	eval { XML::LibXML::Schema->can('new') } ||
	  die "Schema validation not supported by your version of XML::LibXML\n";
	my $xsd;
	if ($format eq 'FILE') {
	  $xsd=XML::LibXML::Schema->new(location => $schema[0]);
	} elsif ($format eq 'STRING') {
	  $xsd=XML::LibXML::Schema->new(string => $schema[0]);
	} elsif ($format eq 'DOC') {
	  my $xsddoc=_doc($schema[0]);
	  unless (ref($xsddoc)) {
	    die "No such document '$schema[0]'!\n";
	  }
	  $xsd=XML::LibXML::Schema->new(string => $xsddoc->toString());
	} else {
	  die "Unknown Schema format '$format!'\n";
	}
	eval { $xsd->validate($doc) };
	if ($show_errors) {
	  die "$@\n";
	} else {
	  out($@ ? "no\n" : "yes\n");
	}
      }
    } else {
      if ($show_errors) {
	$doc->validate();
      } else {
	out(($doc->is_valid() ? "yes\n" : "no\n"));
      }
    }
  } else {
    die("Vaidation not supported by ",ref($doc));
  }
  return 1;
}

# process XInclude elements in a document
sub process_xinclude {
  my ($id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  $_xml_module->doc_process_xinclude($_parser,$doc);
  return 1;
}

# print document's DTD
sub list_dtd {
  my ($id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $dtd=get_dtd($doc);

  if ($dtd) {
    out(fromUTF8($ENCODING,$_xml_module->toStringUTF8($dtd)),"\n");
  }
  return 1;
}

# print document's encoding
sub print_enc {
  my ($id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  out($_xml_module->doc_encoding($doc),"\n");
  return 1;
}

sub set_doc_enc {
  my ($encoding,$id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  $_xml_module->set_encoding($doc,$encoding);
  return 1;
}

sub set_doc_standalone {
  my ($standalone,$id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  $standalone=1 if $standalone=~/yes/i;
  $standalone=0 if $standalone=~/no/i;
  $_xml_module->set_standalone($doc,$standalone);
  return 1;
}

sub doc_info {
  my ($id)=expand @_;
  ($id, my $doc)=_id($id);
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  out("type=",$doc->nodeType,"\n");
  out("version=",$doc->version(),"\n");
  out("encoding=",$doc->encoding(),"\n");
  out("standalone=",$doc->standalone(),"\n");
  out("compression=",$doc->compression(),"\n");
}

# create an identical copy of a document
sub clone {
  my ($id1,$id2)=@_;
  ($id2, my $doc)=_id(expand $id2);

  return if ($id2 eq "" or $id2 eq "" or !ref($doc));
  print STDERR "duplicating $id2=$_files{$id2}\n" unless "$QUIET";

  set_doc($id1,$_xml_module->parse_string($_parser,
					  $doc->toString($INDENT)),
	  $_files{$id2});
  print STDERR "done.\n" unless "$QUIET";
  return 1;
}

# test if $nodea is an ancestor of $nodeb
sub is_ancestor_or_self {
  my ($nodea,$nodeb)=@_;
  while ($nodeb) {
    if ($_xml_module->xml_equal($nodea,$nodeb)) {
      return 1;
    }
    $nodeb=tree_parent_node($nodeb);
  }
}

# remove node and all its surrounding whitespace textual siblings
# from a document; remove all its descendant from all nodelists
# change current element to the nearest ancestor
sub remove_node {
  my ($node,$trim_space)=@_;
  if (is_ancestor_or_self($node,$LOCAL_NODE)) {
    $LOCAL_NODE=tree_parent_node($node);
  }
  my $doc;
  $doc=$_xml_module->owner_document($node);
  if ($trim_space) {
    my $sibling=$node->nextSibling();
    if ($sibling and
	$_xml_module->is_text($sibling) and
	$sibling->getData =~ /^\s+$/) {
#      remove_node_from_nodelists($sibling,$doc);
      $_xml_module->remove_node($sibling);
    }
  }
#  remove_node_from_nodelists($node,$doc);
  $_xml_module->remove_node($node);
}

# move nodes matching one XPath expression to locations determined by
# other XPath expression
sub move {
  my ($xp)=@_; #source xpath
  my ($id,$query,$doc)= _xpath($xp);
  my $sourcenodes;
  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $i=0;
  $sourcenodes=find_nodes($xp);
  if (copy(@_)) {
    foreach my $node (@$sourcenodes) {
      remove_node($node);
      $i++;
    }
    if ($i) {
      remove_dead_nodes_from_nodelists($doc);
    }
    return 1;
  } else {
    return 0;
  }
}

# call a shell command and print out its output
sub sh {
  my $cmd=expand($_[0]);
  out(`$cmd`);
  return 1;
}

# print the result of evaluating an XPath expression in scalar context
sub print_count {
  my $count=count(@_);
  out("$count\n");
  return 1;
}

sub perl_eval {
  if (wantarray) {
    my @result=eval("package XML::XSH::Map; no strict 'vars'; $_[0]");
    die $@ if $@;
    return @result;
  } else {
    my $result=eval("package XML::XSH::Map; no strict 'vars'; $_[0]");
    die $@ if $@;
    return $result;
  }
}

# evaluate a perl expression
# (OBSOLETE! and print out the result)
sub print_eval {
  my ($expr)=@_;
  my $result=perl_eval($expr);
#  out("$result\n") unless "$QUIET";
  return 1;
}

# change current directory
sub cd {
  unless (chdir $_[0]) {
    print STDERR "Can't change directory to $_[0]\n";
    return 0;
  } else {
    print "$_[0]\n" unless "$QUIET";
  }
  return 1;
}

# call methods from a list
sub run_commands {
  return 0 unless ref($_[0]) eq "ARRAY";
  my @cmds=@{$_[0]};
  my $top_level=$_[1];
  my $trapsignals=$top_level;
  my $result=0;

  my ($cmd,@params);

  # make sure errors throw exceptions
  local $_die_on_err=1 unless ($top_level);

  store_variables(1);
  eval {
    local $SIG{INT}=\&sigint if $trapsignals;
    local $SIG{PIPE}=\&sigpipe if $trapsignals;
    foreach my $run (@cmds) {
      if (ref($run) eq 'ARRAY') {
	($cmd,@params)=@$run;
	if ($cmd eq "test-mode") { $TEST_MODE=1; $result=1; next; }
      if ($cmd eq "run-mode") { $TEST_MODE=0; $result=1; next; }
	next if $TEST_MODE;
	$result=&{$cmd}(@params);
      } else {
	$result=1;
      }
    }
  };
  do {
    local $SIG{INT}=\&flagsigint;
    restore_variables();
    propagate_flagsigint();
  };
  if (!$trapsignals and $@ =~ /^SIGINT|^SIGPIPE/) {
    die $@
  } else {
    _check_err($@,1);
  }
  return $result;
}

# redirect output and call methods from a list
sub pipe_command {
  return 1 if $TEST_MODE;

  local $SIG{PIPE}=sub { };
  my ($cmd,$pipe)=@_;

  return 0 unless (ref($cmd) eq 'ARRAY');

  if ($pipe ne '') {
    my $out=$OUT;
    local *PIPE;
    print STDERR "openning pipe $pipe\n" if $DEBUG;
    eval {
      open(PIPE,"| $pipe") || die "cannot open pipe $pipe\n";
      $OUT=\*PIPE;
      run_commands($cmd);
    };
    do {
      local $SIG{INT}=\&flagsigint;
      $OUT=$out;
      close PIPE;
      propagate_flagsigint();
    };
    die $@ if $@; # propagate
  }
  return 1;
}

# redirect output to a string and call methods from a list
sub string_pipe_command {
  my ($cmd,$name)=@_;
  return 0 unless (ref($cmd) eq 'ARRAY');
  if ($name ne '') {
    my $out=$OUT;
    print STDERR "Pipe to $name\n" if $DEBUG;
    $OUT=new IO::MyString;
    eval {
      run_commands($cmd);
    };
    do {
      local $SIG{INT}=\&flagsigint;
      _assign($name,$OUT->value()) unless $@;
      $OUT=$out;
      propagate_flagsigint();
    };
    die $@ if $@; # propagate
  }
  return 0;
}


# call methods as long as given XPath returns positive value
sub while_statement {
  my ($xp,$command)=@_;
  my $result=1;
  if (ref($xp) eq 'ARRAY') {
    while (count($xp)) {
      eval {
	$result = run_commands($command) && $result;
      };
      if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  next;
	} elsif ($@->label eq 'last') {
	  last;
	} elsif ($@->label eq 'redo') {
	  redo;
	} else {
	  die $@; # propagate
	}
      } elsif ($@) {
	die $@; # propagate
      }
    }
  } else {
    while (perl_eval($xp)) {
      eval {
	$result = run_commands($command) && $result;
      };
      if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  next;
	} elsif ($@->label eq 'last') {
	  last;
	} elsif ($@->label eq 'redo') {
	  redo;
	} else {
	  die $@; # propagate
	}
      } elsif ($@) {
	die $@; # propagate
      }
    }
  }
  return $result;
}

sub throw_exception {
  die expand($_[0])."\n";
}

sub try_catch {
  my ($try,$catch,$var)=@_;
  eval {
    local $TRAP_SIGPIPE=1;
    local $SIG{INT}=\&sigint;
    local $SIG{PIPE}=\&sigpipe;
#    local $_die_on_err=1; # make sure errors cause an exception
    run_commands($try);
  };
  if (ref($@) and $@->isa('XML::XSH::Internal::UncatchableException')) {
    die $@; # propagate
  } elsif ($@) {
    if ($@ =~ /^SIGINT/) {
      die $@; # propagate sigint
    } else {
      chomp($@) unless ref($@);
      if (ref($var) and @{$var}>1) {
	store_variables(1,$var->[0]);
	_assign($var->[0],$@);
	eval {
	  run_commands($catch);
	};
	do {
	  local $SIG{INT}=\&flagsigint;
	  restore_variables();
	  propagate_flagsigint();
	};
	die $@ if $@; # propagate
      } else {
	_assign($var->[0],$@) if ref($var);
	run_commands($catch);
      }
    }
  }
}

sub loop_next {
  die XML::XSH::Internal::LoopTerminatingException->new('next',expand(@_));
}
sub loop_prev {
  die XML::XSH::Internal::LoopTerminatingException->new('prev',expand(@_));
}
sub loop_redo {
  die XML::XSH::Internal::LoopTerminatingException->new('redo',expand(@_));
}
sub loop_last {
  die XML::XSH::Internal::LoopTerminatingException->new('last',expand(@_));
}

# call methods on every node matching an XPath
sub foreach_statement {
  my ($xp,$command)=@_;
  if (ref($xp) eq 'ARRAY') {
    my ($id,$query,$doc)=_xpath($xp);
    unless (ref($doc)) {
      die "No such document '$id'!\n";
    }
    my $old_local=$LOCAL_NODE;
    my $old_id=$LOCAL_ID;
    eval {
      my $ql=find_nodes($xp);
      foreach my $node (@$ql) {
	$LOCAL_NODE=$node;
	$LOCAL_ID=_find_id($node);
	eval {
	  run_commands($command);
	};
	if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	  if ($@->label =~ /^(?:next|last|redo)$/ and $@->[1]>1) {
	    $@->[1]--;
	    die $@; # propagate to a higher level
	  }
	  if ($@->label eq 'next') {
	    next;
	  } elsif ($@->label eq 'last') {
	    last;
	  } elsif ($@->label eq 'redo') {
	    redo;
	  } else {
	    die $@; # propagate
	  }
	} elsif ($@) {
	  die $@; # propagate
	}
      }
    };
    do {
      local $SIG{INT}=\&flagsigint;
      $LOCAL_NODE=$old_local;
      $LOCAL_ID=$old_id;
      propagate_flagsigint();
    };
    die $@ if $@; # propagate
  } else {
    foreach $XML::XSH::Map::__ (perl_eval($xp)) {
      eval {
	run_commands($command);
      };
      if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  next;
	} elsif ($@->label eq 'last') {
	  last;
	} elsif ($@->label eq 'redo') {
	  redo;
	} else {
	  die $@; # propagate
	}
      } elsif ($@) {
	die $@; # propagate
      }
    }
  }
  return 1;
}

# run commands if given XPath holds
sub if_statement {
  my @cases=@_;
#  print STDERR "Parsed $xp\n";
  foreach (@cases) {
    my ($xp,$command)=@$_;
    if (!defined($xp) or
	(ref($xp) eq 'ARRAY') && count($xp) ||
	!ref($xp) && perl_eval($xp)) {
      return run_commands($command);
    }
  }
  return 1;
}

# run commands unless given XPath holds
sub unless_statement {
  my ($xp,$command,$else)=@_;
  unless ((ref($xp) eq 'ARRAY')&&count($xp) || 
	  !ref($xp) && perl_eval($xp)) {
    return run_commands($command);
  } else {
    return ref($else) ? run_commands($else->[1]) : 1;
  }
}

# transform a document with an XSLT stylesheet
# and create a new document from the result
sub xslt {
  my ($id,$stylefile,$newid)=expand @_[0..2];
  $id=_id($id);
  my $params=$_[3];
  print STDERR "running xslt on @_\n" if "$DEBUG";
  return unless $_doc{$id};
  my %params;
  %params=map { expand($_) } map { @$_ } @$params if ref($params);
  if ($DEBUG) {
    print STDERR map { "$_ -> $params{$_} " } keys %params;
    print STDERR "\n";
  }

  if ((-f $stylefile) or
      ($stylefile=~/^[a-z]+:/)) {
    require XML::LibXSLT;

    local *SAVE;

    my $_xsltparser=XML::LibXSLT->new();
    my $st=$_xsltparser->parse_stylesheet_file($stylefile);
    $stylefile=~s/\..*$//;
    my $doc=$st->transform($_doc{$id},%params);
    set_doc($newid,$doc,
	    "$stylefile"."_transformed_".$_files{$id});
  } else {
    die "File not exists $stylefile\n";
  }
  return 1;
}

# perform xupdate processing over a document
sub xupdate {
  my ($xupdate_id,$id)=expand(@_);
  $id=_id($id);
  if (get_doc($xupdate_id) and get_doc($id)) {
    require XML::XUpdate::LibXML;
    require XML::Normalize::LibXML;
    my $xupdate = XML::XUpdate::LibXML->new();
    $XML::XUpdate::LibXML::debug=1;
    $xupdate->process(get_doc($id)->getDocumentElement(),get_doc($xupdate_id));
  } else {
    if (get_doc($xupdate_id)) {
      die "No such document $id\n";
    } else {
      die "No such document $xupdate_id\n";
    }
    return 0;
  }
}

sub call_return { die XML::XSH::Internal::SubTerminatingException->new('return'); }

# call a named set of commands
sub call {
  my ($name,$args)=@_;
  $name=expand($name);
  if (exists $_defs{$name}) {
    my @vars=();
    if (ref($args)) {
      @vars=@{ $_defs{$name} };
      shift @vars;
    }
    my $result;
    store_variables(1,@vars);
    eval {
      if (ref($args)) {
	my $var;
	foreach (@$args) {
	  $var=shift @vars;
	  if (defined($var)) {
	    if ($var =~ /^\$/) {
	      _assign($var,expand($_)); # string assignment
	    } elsif ($var =~ /^\%(.*)$/) {
	      local $QUIET=1;
	      nodelist_assign($1,$_); # nodelist assignment
	    }
	  }
	}
      }
      $result = run_commands($_defs{$name}->[0]);
    };
    do {
      local $SIG{INT}=\&flagsigint;
      restore_variables() if (ref($args));
      propagate_flagsigint();
    };
    if (ref($@) and $@->isa('XML::XSH::Internal::SubTerminatingException')) {
      undef $@;
      return 1;
    }
    die $@ if $@; # propagate
    return $result;
  } else {
    die "ERROR: $name not defined\n";
  }
}


sub undef_sub {
  my ($name)=@_;
  if (exists($_defs{$name})) {
    delete $_defs{$name};
  } else {
    foreach (keys %_defs) {
      delete $_defs{$_} if /^$name$/;
    }
  }
}

# define a named set of commands
sub def {
  my ($name,$block,$args)=@_;
  my ($command)=@$block;
  if (exists($_defs{$name})) {
    my ($prevcmd, @prevargs)=@{$_defs{$name}};
    if ($prevcmd) {
      _err "Error: Subroutine $name already defined!";
      return 0;
    } elsif (!$command) {
      _err "Error: Subroutine $name already pre-declared!";
      return 0;
    } else {
      if (@$args != @prevargs) {
	_err "Error: Different number of arguments in declaration and pre-declarartion of $name!";
	return 0;
      }
      my $parg;
      foreach (@$args) {
	$parg=shift @prevargs;
	if (substr($parg,0,1) ne substr($_,0,1)) {
	  _err "Error: Argument types of $_ and $parg in declarations of $name do not match!";
	  return 0;
	}
      }
    }
  }
  $_defs{$name} = [ $command, @$args ];
  return 1;
}

# return a list of all definined subroutines
sub defs {
  return sort keys %_defs;
}

# list all defined subroutines
sub list_defs {
  foreach (sort keys (%_defs)) {
    out(join(" ",$_,@{ $_defs{$_} }[1..$#{ $_defs{$_} }] ),"\n" );
  }
  return 1;
}

# load a file
sub load {
  my ($file)=@_;
  my $l;
  print STDERR "loading file $file\n" unless "$QUIET";
  local *F;
  if (open F,"$file") {
    return join "",<F>;
  } else {
    die "ERROR: couldn't open input file $file";
  }
}

# call XSH to evaluate commands from a given file
sub include {
  my $f=expand(shift);
  my $conditionally = shift;
  if (!$conditionally || !$_includes{$f}) {
    $_includes{$f}=1;
    my $l=load($f);
    return $_xsh->startrule($l);
  }
}

# print help
sub help {
  my ($command)=expand @_;
  if ($command) {
    if (exists($XML::XSH::Help::HELP{$command})) {
      out($XML::XSH::Help::HELP{$command}->[0]);
    } else {
      my @possible =
	grep { index($_,$command)==0 }
	  keys(%XML::XSH::Help::HELP);
      my %h = map { $XML::XSH::Help::HELP{$_} => $_ } @possible;
      if (keys(%h) == 1) {
	out($XML::XSH::Help::HELP{$possible[0]}->[0]);
	return 1;
      } elsif (keys(%h) > 1) {
	out("No help available on $command\n");
	out("Did you mean some of ", join(', ',@possible)," ?\n");
      } else {
	out("No help available on $command\n");
	return 0;
      }
    }
  } else {
    out($XML::XSH::Help::HELP);
  }
  return 1;
}

# load catalog file to the parser
sub load_catalog {
  $_xml_module->load_catalog($_parser,expand($_[0]));
  return 1;
}

sub stream_process_node {
  my ($node,$command,$input,$id)=@_;
  set_doc($id,$_xml_module->owner_document($node),$input);
  my $old_local=$LOCAL_NODE;
  my $old_id=$LOCAL_ID;
  eval {
    foreach (1) {
      $LOCAL_NODE=$node;
      $LOCAL_ID=$id;
      eval {
	run_commands($command);
      };
      if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|redo)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  last;
	} elsif ($@->label eq 'redo') {
	  redo;
	} else {
	  die $@; # propagate
	}
      } elsif ($@) {
	die $@; # propagate
      }
    }
  };
  do {
    local $SIG{INT}=\&flagsigint;
    delete $_doc{$id};
    delete $_files{$id};
    $LOCAL_NODE=$old_local;
    $LOCAL_ID=$old_id;
    propagate_flagsigint();
  };
  die $@ if $@; # propagate
}

sub stream_process {
  my ($itype, $input, $otype, $output, $process)=@_;
  ($input,$output)=expand($input,$output);
  require XML::Filter::DOMFilter::LibXML;
  require XML::LibXML::SAX;
  require XML::SAX::Writer;

  my $out;
  my $termout;
  my $i=1;
  $i++ while (exists($_doc{"_stream_$i"}));
  if ($otype =~ /pipe/i) {
    open $out,"| $output";
    $out || die "Cannot open pipe to $output\n";
  } elsif ($otype =~ /string/i) {
    if ($output =~ /^\$?([a-zA-Z_][a-zA-Z0-9_]*)$/) {
      no strict qw(refs);
      $out=\${"XML::XSH::Map::$1"};
    } elsif (ref($OUT)=~/Term::ReadLine/) {
      $out = *$OUT;
      $termout=1;
    } else {
      $out = $OUT;
      $termout=1;
    }
  } else {
    $out = $output;
  }
  my $parser=XML::LibXML::SAX
    ->new( Handler =>
	   XML::Filter::DOMFilter::LibXML
	   ->new(Handler =>
		 XML::SAX::Writer::XML
		 ->new(
		       Output => $out,
		       Writer => 'XML::SAX::Writer::XMLEnc'
		      ),
		 XPathContext => $_xpc,
		 Process => [
			     map {
			       $_->[0] => [\&stream_process_node,$_->[1],
					   $input,"_stream_$i"] }
			     @$process
			    ]
		)
	 );
  if ($itype =~ /pipe/i) {
    open my $F,"$input|";
    $F || die "Cannot open pipe to $input: $!\n";
    $parser->parse_fh($F);
    close $F;
  } elsif ($itype =~ /string/i) {
    $parser->parse_string($input);
  } else  { #file
    $parser->parse_uri($input);
  }
  if ($otype =~ /pipe/i) {
    close($out);
  }
  if ($termout) { out("\n"); }
  return 1;
}

sub iterate {
  my ($code,$axis,$nodefilter,$filter)=@_;

  return unless get_local_node(_id());

  $axis =~ s/::$//;
  $axis=~s/-/_/g;

  $filter =~ s/^\[\s*((?:.|\n)*?)\s*\]$/$1/ if defined $filter;
  my $test;
  if ($nodefilter eq "comment()") {
    $test = q{ $_xml_module->is_comment($_[0]) }
  } if ($nodefilter eq "text()") {
    $test = q{ $_xml_module->is_text_or_cdata($_[0]) }
  } elsif ($nodefilter =~ /processing-instruction\((\s*['"]([^'"]+)['"]\s*)?\)$/) {
    $test = q{ $_xml_module->is_pi($_[0]) };
    $test .= qq{ && (\$_[0]->nodeName eq '$1') } if $1 ne "";
  } elsif ($nodefilter eq 'node()') {
    $test = '1 ';
  } elsif ($nodefilter =~ /^(?:([^:]+):)?(.+)$/) {
    $test = q{ $_xml_module->is_element($_[0]) };
    $test .= qq{ && (\$_[0]->getLocalName() eq '$2') } unless ($2 eq '*');
    if ($1 ne "") {
      my $ns = get_local_node(_id())->lookupNamespaceURI($1);
      die("Unrecognized namespace prefix '$1:'!") if ($ns eq "");
      $test .= qq{ && (\$_[0]->namespaceURI() eq '$ns') };
    }
  }

  die("Position index filter not supported for iteration ([$filter])") if $filter =~ /^\d+$/;
  if ($filter ne '') {
    $filter =~ s/\\/\\\\/g;
    $filter =~ s/'/\\'/g;
    $test .= qq{ && count_xpath(\$_[0],'$filter') };
  }

  my $filter_sub = eval "sub { $test }";
  my $iterator;
  do {
    my $start=get_local_node(_id());
    $iterator=XML::XSH::Iterators->create_iterator($start,$axis,$filter_sub);
  };
  return 1 unless defined $iterator;

  my $old_local=$LOCAL_NODE;
  my $old_id=$LOCAL_ID;

  eval {
  ITER: while ($iterator->current()) {
      $LOCAL_NODE=$iterator->current();
      eval {
	run_commands($code);
      };
      if (ref($@) and $@->isa('XML::XSH::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo|prev)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  $iterator->next() || last;
	  next;
	} elsif ($@->label eq 'prev') {
	  $iterator->prev() || die("No previous node to iterate to!");
	  next;
	} elsif ($@->label eq 'last') {
	  last;
	} elsif ($@->label eq 'redo') {
	  redo;
	} else {
	  die $@; # propagate
	}
      } elsif ($@) {
	die $@; # propagate
      }
      $iterator->next() || last;
    }
  };
  do {
    local $SIG{INT}=\&flagsigint;
    $LOCAL_NODE=$old_local;
    $LOCAL_ID=$old_id;
    propagate_flagsigint();
  };
  die $@ if $@; # propagate
  return 1;
}

# quit
sub quit {
  if (ref($_on_exit)) {
    &{$_on_exit->[0]}($_[0],@{$_on_exit}[1..$#$_on_exit]); # run on exit hook
  }
  exit(int($_[0]));
}

sub register_ns {
  my ($prefix,$ns)=expand(@_);
  $_ns{$prefix}=$ns;
  $_xpc->registerNs($prefix,$ns);
  return 1;
}

sub unregister_ns {
  my ($prefix)=expand(@_);
  delete $_ns{$prefix};
  $_xpc->unregisterNs($prefix);
  return 1;
}

sub register_func {
  my ($name,$code)=(expand($_[0]),$_[1]);
  my $sub;
  if ($code =~ /^\s*{/) {
    $sub=eval("package XML::XSH::Map; no strict; sub $code");
  } elsif ($code =~/^\s*([A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_][A-Za-z_0-9]*)*)\s*$/) {
    if ($2 ne "") {
      $sub=\&{"$1"};
    } else {
      $sub=\&{"XML::XSH::Map::$1"};
    }
  } else {
    $sub=eval("package XML::XSH::Map; no strict; sub { $code }");
  }
  die $@ if $@;
  if ($name =~ /^([^:]+):(.*)$/) {
    if (exists($_ns{$1})) {
      $_xpc->registerFunctionNS($2, $_ns{$1}, $sub);
    } else {
      die "Registration failed: unknown namespace prefix $1!\n";
    }
  } else {
    $_xpc->registerFunction($name, $sub);
  }
  return 1;
}

sub unregister_func {
  my ($name)=expand(@_);
  $_xpc->unregisterFunction($name);
  return 1;
}

#######################################################################
#######################################################################


package XML::XSH::Map;

import XML::XSH::Functions ':param_vars';

# make this command available from perl expressions
sub echo {
  &XML::XSH::Functions::out(XML::XSH::Functions::fromUTF8($XML::XSH::Functions::ENCODING,join("",@_)));
  return 1;
}

# make this command available from perl expressions
sub xsh {
  &XML::XSH::Functions::xsh(join "",@_);
}

sub count {
  my $xp=$_[0];
  $xp=~/^(?:([a-zA-Z_][a-zA-Z0-9_]*):(?!:))?((?:.|\n)*)$/;
  return &XML::XSH::Functions::count([$1,$2]);
}

sub xml_list {
  my ($xp)=@_;
  $xp=~/^(?:([a-zA-Z_][a-zA-Z0-9_]*):(?!:))?((?:.|\n)*)$/;
  my ($id,$query,$doc)=&XML::XSH::Functions::_xpath([$1,$2]);

  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $ql=&XML::XSH::Functions::find_nodes([$id,$query]);
  my $result='';
  foreach (@$ql) {
    $result.=$_->toString();
  }
  return $result;
}

sub literal {
  my ($xp)=@_;
  my $xp=$_[0];
  $xp=~/^(?:([a-zA-Z_][a-zA-Z0-9_]*):(?!:))?((?:.|\n)*)$/;
  return XML::XSH::Functions::eval_xpath_literal([$1,$2]);
}

sub type {
  my ($xp)=@_;
  $xp='.' if $xp eq "";
  $xp=~/^(?:([a-zA-Z_][a-zA-Z0-9_]*):(?!:))?((?:.|\n)*)$/;
  my ($id,$query,$doc)=&XML::XSH::Functions::_xpath([$1,$2]);

  unless (ref($doc)) {
    die "No such document '$id'!\n";
  }
  my $ql=&XML::XSH::Functions::find_nodes([$id,$query]);


  my $xm=$XML::XSH::Functions::_xml_module;
  my @result;
  foreach (@$ql) {
    if ($xm->is_element($_)) {
      push @result, 'element';
    } elsif ($xm->is_attribute($_)) {
      push @result, 'attribute';
    } elsif ($xm->is_text($_)) {
      push @result, 'text';
    } elsif ($xm->is_cdata_section($_)) {
      push @result, 'cdata';
    } elsif ($xm->is_pi($_)) {
      push @result, 'pi';
    } elsif ($xm->is_entity_reference($_)) {
      push @result, 'entity_reference';
    } elsif ($xm->is_document($_)) {
      push @result, 'document';
    } elsif ($xm->is_document_fragment($_)) {
      push @result, 'chunk';
    } elsif ($xm->is_comment($_)) {
      push @result, 'comment';
    } elsif ($xm->is_namespace($_)) {
      push @result, 'namespace';
    } else {
      push @result, 'unknown';
    }
    return $result[0] unless (wantarray);
  }
  return @result;
}

#######################################################################
#######################################################################

package XML::XSH::Internal::Exception;

sub new {
  my $class=(ref($_[0]) || $_[0]);
  shift;
  return bless [@_], $class;
}

sub set_label {
  my ($label)=@_;
  return $_[0]->[0]=$label;
}

sub label {
  return $_[0]->[0];
}

sub value {
  my ($index)=@_;
  return $_[0]->[$index];
}

sub set_value {
  my ($index,$value)=@_;
  return $_[0]->[$index]=$value;
}

package XML::XSH::Internal::UncatchableException;
use vars qw(@ISA);
@ISA=qw(XML::XSH::Internal::Exception);

package XML::XSH::Internal::LoopTerminatingException;
use vars qw(@ISA);
@ISA=qw(XML::XSH::Internal::UncatchableException);

package XML::XSH::Internal::SubTerminatingException;
use vars qw(@ISA);
@ISA=qw(XML::XSH::Internal::UncatchableException);


#######################################################################
#######################################################################

package IO::MyString;

use vars qw(@ISA);
@ISA=qw(IO::Handle);

sub new {
  my $class=(ref($_[0]) || $_[0]);
  return bless [""], $class;
}

sub print {
  my $self=shift;
  $self->[0].=join("",@_);
}

sub value {
  return $_[0]->[0];
}

sub close {
  $_[0]->[0]=undef;
}

package XML::SAX::Writer::XMLEnc;
use vars qw(@ISA);
@ISA=qw(XML::SAX::Writer::XML);

sub xml_decl {
  my ($self,$data) = @_;
  if ($data->{Encoding}) {
    $self->{EncodeTo}=$data->{Encoding};
    $self->setConverter();
  }
  $self->SUPER::xml_decl($data);
}

1;
