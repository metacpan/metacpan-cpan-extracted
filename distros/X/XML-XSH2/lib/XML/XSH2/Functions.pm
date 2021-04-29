# -*- cperl -*-
# $Id: Functions.pm,v 2.49 2008-01-27 10:48:39 pajas Exp $

package XML::XSH2::Functions;

#eval "no encoding";
#undef $@;
use strict;
no warnings;

use XML::XSH2::Help;
use XML::XSH2::Iterators;
use IO::File;
use File::Spec;
use Scalar::Util;
use File::Temp qw(tempfile tempdir);
use Carp;
use URI;
use URI::file;

use Exporter;
use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION $REVISION $OUT
	    @PARAM_VARS
            $_xml_module $_sigint
            $_xsh $_xpc $_parser @stored_variables
	    $lexical_variables $_newdoc
            $TRAP_SIGINT $TRAP_SIGPIPE $_die_on_err $_on_exit
	    $_want_returns
	    %_files %_defs %_includes %_ns %_func %COMMANDS
	    $ENCODING $QUERY_ENCODING
	    $INDENT $BACKUPS $SWITCH_TO_NEW_DOCUMENTS $EMPTY_TAGS $SKIP_DTD
	    $QUIET $DEBUG $TEST_MODE $WARNINGS $ERRORS
	    $VALIDATION $RECOVERING $PARSER_EXPANDS_ENTITIES $KEEP_BLANKS
	    $PEDANTIC_PARSER $LOAD_EXT_DTD $PARSER_COMPLETES_ATTRIBUTES
	    $PARSER_EXPANDS_XINCLUDE $MAXPRINTLENGTH
	    $XPATH_AXIS_COMPLETION $STRICT_PWD
	    $XPATH_COMPLETION $DEFAULT_FORMAT $LINE_NUMBERS
            $RT_LINE $RT_COLUMN $RT_OFFSET $RT_SCRIPT $SCRIPT
            $BENCHMARK $DUMP $DUMP_APPEND $Xinclude_prefix $HISTFILE
	    $PROMPT
	  /;

BEGIN {
  $VERSION='2.2.9'; # VERSION TEMPLATE
  $REVISION=q($Revision: 2.49 $);
  @ISA=qw(Exporter);
  @PARAM_VARS=qw/$ENCODING
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
		 $LINE_NUMBERS
		 $WARNINGS
		 $MAXPRINTLENGTH
		 $HISTFILE
		 $STRICT_PWD
		 $PROMPT
		 /;
  *XSH_NS=*XML::XSH2::xshNS;
  *XML::XSH2::Map::XSH_NS=*XML::XSH2::xshNS;
  *XML::XSH2::Map::OUT=\$OUT;
  *EMPTY_TAGS=*XML::LibXML::setTagCompression;
  *SKIP_DTD=*XML::LibXML::skipDTD;
  *XML::XSH2::Map::PROGRAM_NAME=\$RT_SCRIPT;
  @EXPORT_OK=(qw(&xsh_init &xsh &xsh_get_output
                &xsh_set_output &xsh_set_parser
                &set_quiet &set_debug &set_compile_only_mode
		&create_doc &open_doc &set_doc
		&xsh_pwd &out
		&toUTF8 &fromUTF8 &xsh_set_script
		&xsh_context_node &xsh_context_var
		&xsh_xml_parser &xsh_parse_string
	       ),@PARAM_VARS);
  %EXPORT_TAGS = (
		  default => [@EXPORT_OK],
		  param_vars => [@PARAM_VARS]
		 );

  $TRAP_SIGINT=0;
  $_xml_module='XML::XSH2::LibXMLCompat';
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
  $LINE_NUMBERS=1;
  $WARNINGS=1;
  $ERRORS=1;
  $BENCHMARK=0;
  $MAXPRINTLENGTH=256;
  $HISTFILE="$ENV{HOME}/.xsh2_history";
  $STRICT_PWD=1;
  $PROMPT='%p> ';
  *XML::XSH2::Map::CURRENT_SCRIPT=\$RT_SCRIPT;

  $_newdoc=1;
  $_die_on_err=1;
  $_want_returns=0;

  autoflush STDOUT;
  autoflush STDERR;
  $lexical_variables = [];
  $Xinclude_prefix = 'http://www.w3.org/2001/XInclude';
  require XML::XSH2::Commands;
}

sub VERSION {
  shift if $_[0] eq __PACKAGE__;
  my $ver = shift;
  if (defined($ver)) {
    my @V = split /\./,$VERSION;
    my @v = split /\./,$ver;
    for my $component (@v) {
      croak __PACKAGE__." version $ver required--this is only version $VERSION"
	if $component > shift @V;
    }
  }
  return $VERSION;
}


sub min { $_[0] > $_[1] ? $_[1] : $_[0] }

sub out {
  if (ref($OUT) eq 'IO::Scalar') {
    $OUT->print(@_);
  } else {
    foreach (map(fromUTF8($ENCODING,$_), @_)) {
      my $l = length;
      my $i = 1;
      while ($l > $i*$MAXPRINTLENGTH) {
	print $OUT (substr($_,($i-1)*$MAXPRINTLENGTH,$MAXPRINTLENGTH));
	$i++;
      }
      print $OUT (substr($_,($i-1)*$MAXPRINTLENGTH)); # the rest
    }
  }
}

sub __debug {
  _err(@_);
}

sub __bug {
  _err("BUG: ",@_);
}

sub _tilde_expand {
  my ($filename)=@_;
  $filename=~s{^(\~[^\/]*)}{(glob($1))[0]}eg;

#   $filename =~ s{ ^ ~ ( [^/]* ) }
#     { $1
# 	? (getpwnam($1))[7]
# 	  : ( $ENV{HOME} || $ENV{LOGDIR}
# 		|| (getpwuid($>))[7]
# 	       )
# 	}ex;
  return $filename;
}

sub _ev_opts {
  my ($opts)=@_;
  return {} unless ref($opts);
  return $opts if ref($opts) eq 'HASH';
  my %o;
  my @opts = @$opts;
  while (@opts) {
    my ($t,$n)=split /\//,shift(@opts);
    my $v=shift @opts;
    if ($t eq '' or $t eq 'exp') {
      $o { $n } = _ev($v);
    } elsif ($t eq 'var') {
      $o { $n } = $v;
    } elsif ($t eq 'xpath') {
      utf8::upgrade($v);
      $o { $n } = _expand($v);
    } else { # string
      $o { $n } = _ev_string($v);
    }
  }
  return \%o;
}

sub _hash_opts {
  my ($opts)=@_;
  return {} unless ref($opts);
  my %o;
  my @opts = @$opts;
  while (@opts) {
    my ($t,$n)=split /\//,shift(@opts);
    my $v=shift @opts;
    $o { $n } = $v;
  }
  return \%o;
}

sub alias_sr {
  my($src, $dest)=@_;
  tie($$dest, 'XML::XSH2::VarAlias', $src);
}

sub lexicalize {
  my $p="package XML::XSH2::Map; no strict qw(vars); \$Lexical::Alias::SWAP=0; use utf8;";
  my %seen;
  for (my $i=$#$lexical_variables; $i>=0; $i--) {
    foreach my $v (keys %{$lexical_variables->[$i]}) {
      next if $seen{$v};
      $seen{$v}=1;
      $p.="my \$$v; \&XML::XSH2::Functions::alias_sr(\\\$XML::XSH2::Functions::lexical_variables->[$i]{q#$v#}, \\\$$v);"
    }
  }
#  $p.="\n# line  $RT_LINE \"$RT_SCRIPT\"\n";
  return $p.$_[0];
}

# initialize XSH and XML parsers
sub xsh_init {
  my $module=shift;
  shift unless ref($_[0]);
  if (ref($_[0])) {
    $OUT=$_[0];
  } else {
    if (open $OUT, '>&', \*STDOUT) {
      binmode $OUT;
      binmode $OUT, ':bytes';
    } else {
      $OUT = \*STDOUT;
    }
  }
  set_encoding({},$ENCODING);
  $_xml_module=$module if $module;
  eval("require $_xml_module;");
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
#  xsh_rd_parser_init();

  # create a first document so that we always have non-empty context
  create_doc('$scratch',"scratch",'xml','scratch.xml');
  set_local_xpath({},'/');
}

sub xsh_rd_parser_init {
  unless ($_xsh) {
    if (eval { require XML::XSH2::Parser; }) {
      $_xsh=XML::XSH2::Parser->new();
    } else {
      print STDERR "Parsing raw grammar...\n";
      require XML::XSH2::Grammar;
      $_xsh=XML::XSH2::Grammar->new();
      print STDERR "... done.\n";
      unless ($QUIET) {
	print STDERR << 'EOF';
NOTE: To avoid this, you should regenerate the XML::XSH2::Parser.pm
      module from XML::XSH2::Grammar.pm module by changing to XML/XSH/
      directory in your load-path and running the following command:

         perl -MGrammar -e XML::XSH2::Grammar::compile

EOF
      }
    }
  }
  return $_xsh;
}

sub set_validation	     { shift if @_>1; $VALIDATION=$_[0]; 1; }
sub set_recovering	     { shift if @_>1; $RECOVERING=$_[0]; 1; }
sub set_expand_entities	     { shift if @_>1; $PARSER_EXPANDS_ENTITIES=$_[0]; 1; }
sub set_keep_blanks	     { shift if @_>1; $KEEP_BLANKS=$_[0]; 1; }
sub set_pedantic_parser	     { shift if @_>1; $PEDANTIC_PARSER=$_[0]; 1; }
sub set_load_ext_dtd	     { shift if @_>1; $LOAD_EXT_DTD=$_[0]; 1; }
sub set_complete_attributes  { shift if @_>1; $PARSER_COMPLETES_ATTRIBUTES=$_[0]; 1; }
sub set_expand_xinclude	     { shift if @_>1; $PARSER_EXPANDS_XINCLUDE=$_[0]; 1; }
sub set_indent		     { shift if @_>1; $INDENT=$_[0]; 1; }
sub set_empty_tags           { shift if @_>1; $EMPTY_TAGS=$_[0]; 1; }
sub set_skip_dtd             { shift if @_>1; $SKIP_DTD=$_[0]; 1; }
sub set_backups		     { shift if @_>1; $BACKUPS=$_[0]; 1; }
sub set_cdonopen	     { shift if @_>1; $SWITCH_TO_NEW_DOCUMENTS=$_[0]; 1; }
sub set_xpath_completion     { shift if @_>1; $XPATH_COMPLETION=$_[0]; 1; }
sub set_xpath_axis_completion { shift if @_>1; $XPATH_AXIS_COMPLETION=$_[0];
				if ($XPATH_AXIS_COMPLETION!~/^always|when-empty|never$/) {
				  $XPATH_AXIS_COMPLETION='never';
				}
				1; }
sub set_line_numbers         { shift if @_>1; $LINE_NUMBERS=$_[0]; 1; }

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
sub get_line_numbers	     { $LINE_NUMBERS }

# initialize global XPathContext
sub xpc_init {
  $_xpc=new_xpath_context();
  $_ns{xsh}=$XML::XSH2::xshNS;
}

sub init_XPATH_funcs {
  my ($xpc,$ns)=@_;
  foreach my $name (get_XPATH_extensions()) {
    my $func=$name; $func =~ s/-/_/g;
    $xpc->registerFunctionNS($name,$ns,\&{"XPATH_$func"});
  }
}

sub new_xpath_context {
  my $xpc;
  unless (eval { require XML::LibXML::XPathContext;
		 $xpc=XML::LibXML::XPathContext->new();
	       }) {
    require XML::XSH2::DummyXPathContext;
    print STDERR ("Warning: XML::LibXML::XPathContext not found!\n".
		  "XSH will lack namespace and function registering functionality!\n\n");
    return XML::XSH2::DummyXPathContext->new();
  }
  $xpc = XML::LibXML::XPathContext->new();
  $xpc->registerVarLookupFunc(\&xpath_var_lookup,undef);
  $xpc->registerNs('xsh',$XML::XSH2::xshNS);
  init_XPATH_funcs($xpc,$XML::XSH2::xshNS);
  return $xpc;
}

sub clone_xpc {
  my $xpc = new_xpath_context();
  foreach (keys(%_ns)) {
    $xpc->registerNs($_,$_ns{$_});
  }
  foreach (keys(%_func)) {
    if (/\n/) {
      my ($name,$ns)=/^(.*)\n((?:.|\n)*)$/;
      $xpc->registerFunctionNS($name, $ns, $_func{$_});
    } else {
      $xpc->registerFunction($_, $_func{$_});
    }
  }
  $xpc->setContextNode($_xpc->getContextNode());
  return $xpc;
}

sub xpath_extensions {
  my $opts = shift;
  init_XPATH_funcs($_xpc,shift);
  return 1;
}

# ===================== XPATH EXT FUNC ================

sub get_XPATH_extensions {
  qw( current doc filename grep id2 if join lc uc ucfirst lcfirst
  lineno evaluate map matches match max min new-attribute
  new-cdata new-chunk new-comment new-element new-element-ns new-pi
  new-text node-type parse path reverse same serialize split sprintf
  strmax strmin subst substr sum times var document documents lookup span context
  resolve-uri base-uri document-uri
  )
}

sub XPATH_doc {
  die "Wrong number of arguments for function xsh:doc(nodeset)!\n" if (@_!=1);
  my ($nodelist)=@_;
  die "1st argument must be a nodeset in xsh:doc(nodeset)!\n"
    unless (ref($nodelist) and UNIVERSAL::isa($nodelist,'XML::LibXML::NodeList'));
  use utf8;
  return XML::LibXML::NodeList->new(grep { ref($_) } map { $_->ownerDocument } @$nodelist);
}

sub XPATH_filename {
  die "Wrong number of arguments for function xsh:filename(nodeset?) or xsh:document-uri(nodeset?)!\n" if (@_>1);
  my $doc;
  if (@_) {
    die "1st argument must be a node in xsh:filename(nodeset?) or xsh:document-uri(nodeset?)!\n"
      unless (ref($_[0]) and UNIVERSAL::isa($_[0],'XML::LibXML::NodeList'));
  }
  if ($_[0]) {
    return XML::LibXML::Literal->new('') unless $_[0][0];
    $doc = $_[0][0]->ownerDocument;
  } else {
    $doc = $XML::XSH2::Functions::_xpc->getContextNode()->ownerDocument;
  }
  use utf8;
  return XML::LibXML::Literal->new($doc->URI());
}

sub XPATH_resolve_uri {
  die "Wrong number of arguments for function xsh:resolve-uri(relative-URI,base-URI?)!\n" if (@_>2 or @_==0);
  my ($rel,$base)=map literal_value($_), @_;
  return XML::LibXML::Literal->new(XML::XSH2::Map::resolve_uri($rel,$base)->as_string);
}

sub XPATH_document_uri {
  &XPATH_filename;
}

sub XPATH_base_uri {
  die "Wrong number of arguments for function xsh:base_uri(node?)!\n" if (@_>1);
  my $node;
  if (@_) {
    die "1st argument must be a node in xsh:base_uri(node?)!\n"
      unless (ref($_[0]) and UNIVERSAL::isa($_[0],'XML::LibXML::NodeList'));
  }
  if ($_[0]) {
    return XML::LibXML::Literal->new('') unless $_[0][0];
    $node = $_[0][0];
  } else {
    $node = $XML::XSH2::Functions::_xpc->getContextNode();
  }
  use utf8;
  return XML::LibXML::Literal->new($node->baseURI() || '');
}


sub XPATH_var {
  die "Wrong number of arguments for function xsh:var(id)!\n" if (@_!=1);
  my ($id)=literal_value($_[0]);
  return var_value($id);
}

sub XPATH_matches {
  die "Wrong number of arguments for function xsh:matches(string,regexp)!\n" if (@_!=2 and @_!=3);
  use utf8;
  my ($string,$regexp,$ignore_case)=@_;
  $string=literal_value($string);
  $regexp=literal_value($regexp);
  $ignore_case=literal_value($ignore_case);
  return ($ignore_case ?
	  $string=~m{$regexp}i :
	  $string=~m{$regexp}) ?
	    XML::LibXML::Boolean->True :
		XML::LibXML::Boolean->False;
}

sub XPATH_substr {
  die "Wrong number of arguments for function xsh:substr(string,position,[length])!\n" if (@_<2 or @_>3);
  use utf8;
  my ($str,$pos,$len)=@_;
  my $result = (@_ == 2) ? 
    substr(literal_value($str),
	   literal_value($pos)) :
	     substr(literal_value($str),
		    literal_value($pos),
		    literal_value($len));
  $result = "" unless defined ($result);
  return $result;
}

sub XPATH_reverse {
  die "Wrong number of arguments for function xsh:reverse(string)!\n" if (@_!=1);
  use utf8;
  return scalar reverse(literal_value($_[0]));
}

sub XPATH_lc {
  die "Wrong number of arguments for function xsh:lc(string)!\n" if (@_!=1);
  use utf8;
  return lc(literal_value($_[0]));
}

sub XPATH_uc {
  die "Wrong number of arguments for function xsh:uc(string)!\n" if (@_!=1);
  use utf8;
  return uc(literal_value($_[0]));
}

sub XPATH_lcfirst {
  die "Wrong number of arguments for function xsh:lcfirst(string)!\n" if (@_!=1);
  use utf8;
  return lcfirst(literal_value($_[0]));
}

sub XPATH_ucfirst {
  die "Wrong number of arguments for function xsh:ucfirst(string)!\n" if (@_!=1);
  use utf8;
  return ucfirst(literal_value($_[0]));
}

sub XPATH_grep {
  die "Wrong number of arguments for function xsh:grep(list,regexp)!\n" if (@_!=2);
  my ($nodelist,$regexp)=@_;
  die "1st argument must be a nodeset in grep(list,regexp)!\n" 
    unless (ref($nodelist) and UNIVERSAL::isa($nodelist,'XML::LibXML::NodeList'));
  use utf8; 
  [grep { $_->to_literal=~m{$regexp} } @$nodelist];
}

sub XPATH_same {
  die "Wrong number of arguments for function xsh:same(node,node)!\n" if (@_!=2);
  my ($nodea,$nodeb)=@_;
  die "1st argument must be a node in grep(list,regexp)!\n" 
    unless (ref($nodea) and UNIVERSAL::isa($nodea,'XML::LibXML::NodeList'));
  die "2nd argument must be a node in grep(list,regexp)!\n" 
    unless (ref($nodeb) and UNIVERSAL::isa($nodeb,'XML::LibXML::NodeList'));
  return XML::LibXML::Boolean->new($nodea->size() && $nodeb->size() &&
				   $nodea->[0]->isSameNode($nodeb->[0]));
}

sub XPATH_max {
  my $r;
  foreach (cast_objects_to_values(@_)) {
    next unless /^\s*(-\s*)?(\d+(\.\d*)?|\.\d+)\s*$/;
    $r = $_ unless defined($r);
    $r = $_>$r ? $_ : $r;
  }
  ; 0+$r;
}

sub XPATH_strmax {
  my $r;
  foreach (cast_objects_to_values(@_)) {
    $r = $_ unless defined($r);
    $r = $_ ge $r ? $_ : $r;
  }
  ; defined($r) ? $r : "";
}

sub XPATH_min {
  my $r;
  foreach (cast_objects_to_values(@_)) {
    next unless /^\s*(-\s*)?(\d+(\.\d*)?|\.\d+)\s*$/;
    $r = $_ unless defined($r);
    $r = $_ < $r ? $_ : $r;
  }
  ;
  return 0+$r;
}

sub XPATH_strmin {
  my $r;
  foreach (cast_objects_to_values(@_)) {
    $r = $_ unless defined($r);
    $r = $_ le $r ? $_ : $r;
  }
  ; defined($r) ? $r : "";
}

sub XPATH_sum {
  my $r=0;
  foreach (cast_objects_to_values(@_)) {
    $r += $_;
  }
  ; $r;
}

sub XPATH_join {
  my $j=literal_value(shift @_);
  join $j,cast_objects_to_values(@_);
}

sub XPATH_serialize {
  my $result="";
  foreach my $obj (@_) {
    if (ref($obj) and 
	UNIVERSAL::isa($obj,'XML::LibXML::NodeList')) {
      foreach my $node (@$obj) {
	$result.=$node->toString();
      }
    } else {
      $result.=literal_value($obj);
    }
  }
  $result;
}

sub XPATH_subst {
  die "Wrong number of arguments for function xsh:subst(string,regexp,replacement,[options])!\n" if (@_!=3 and @_!=4);
  use utf8;
  my ($string,$regexp,$replace,$options)=@_;
  $string=literal_value($string);
  $regexp=literal_value($regexp);
  return $string unless $regexp ne "";
  $replace=literal_value($replace);
  $options=literal_value($options);
  die "Invalid options: $options (should only consist of 'egimsx')!\n"
    unless ($options =~ /^[egimsx]*$/);
  $replace =~ s{\\(.)|(/)|(\\)$}{\\$1$2$3}gs;
  eval "\$string=~s/\$regexp/$replace/$options";
  return $string;
}

sub XPATH_parse {
  use utf8;
  my $string=join '',map {literal_value($_)} @_;
  my $dom=xsh_parse_string($string,'xml');
  if ($dom) {
    return XML::LibXML::NodeList->new($dom->childNodes());
  } else {
    return XML::LibXML::NodeList->new();
  }
}

sub XPATH_sprintf {
  die "Wrong number of arguments for function xsh:sprintf(format-string,...)!\n" if (@_<1);
  use utf8;
  my @args=map { literal_value($_) } @_;
  return sprintf(shift(@args),@args);
}

sub XPATH_current {
  die "Wrong number of arguments for function xsh:current()!\n" if (@_);
  my $ln = xsh_context_node();
  return XML::LibXML::NodeList->new($ln ? $ln : ());
}

sub XPATH_path {
  die "Wrong number of arguments for function xsh:path(nodeset)!\n" if (@_!=1);
  die "Wrong type of argument 1 for xsh:path(nodeset)!\n" unless (ref($_[0]) and UNIVERSAL::isa($_[0],'XML::LibXML::NodeList'));
  return "" unless $_[0][0];
  return
    XML::LibXML::Literal->new(pwd($_[0][0]));
}

sub XPATH_node_type {
  die "Wrong number of arguments for function xsh:node-type(node-set)!\n" if (@_!=1);
  die "Wrong type of argument 1 for xsh:node-type(node-set)!\n" unless (ref($_[0]) and UNIVERSAL::isa($_[0],'XML::LibXML::NodeList'));
  return "" unless $_[0][0];
  return
    XML::LibXML::Literal->new(node_type($_[0][0]));
}

sub XPATH_object_type {
  die "Wrong number of arguments for function xsh:object-type(object)!\n" if (@_!=1);
  my ($obj)=@_;
  my $ret;
  if (!ref($obj)) {
    $ret = "string"
  } elsif (UNIVERSAL::isa($obj,"XML::LibXML::NodeList")) {
    $ret = "nodeset"
  } elsif (UNIVERSAL::isa($obj,"XML::LibXML::Literal")) {
    $ret = "string"
  } elsif (UNIVERSAL::isa($obj,"XML::LibXML::Boolean")) {
    $ret = "boolean"
  } elsif (UNIVERSAL::isa($obj,"XML::LibXML::Number")) {
    $ret = "float"
  } else {
    $ret = "unknown"
  }
  return XML::LibXML::Literal->new($ret);
}

sub XPATH_evaluate {
  die "Wrong number of arguments for function xsh:evaluate(string)!\n"
    if ((@_==0) or (@_>4));
  my ($xpath,$node,$size,$pos)=@_;
  my $old_context;
  if (@_>1) {
    $old_context = _save_context();
    die "Wrong type of argument 1 for xsh:evaluate(string,node?,size?,position?)!\n"
      unless (ref($node) and UNIVERSAL::isa($node,'XML::LibXML::NodeList'));
    if (@$node) {
      _set_context([$node->[0],$size,$pos]);
    } else {
      return XML::LibXML::NodeList->new();
    }
  }
  if ($xpath eq "") { return XML::LibXML::NodeList->new() }
  my $val;
  eval { $val = $_xpc->find($xpath) };
  _set_context($old_context) if $old_context;
  return defined($val) ? $val : XML::LibXML::NodeList->new();
}

sub XPATH_map {
  die "Wrong number of arguments for function xsh:map(nodeset,string)!\n"
    if (@_!=2);
  die "Wrong type of argument 1 for xsh:map(nodeset,string)!\n"
    unless (ref($_[0]) and UNIVERSAL::isa($_[0],'XML::LibXML::NodeList'));
  my ($nl,$xpath)=@_;
  my $res = XML::LibXML::NodeList->new();
  unless (@{$nl} and $xpath ne "") { return $res; }
  return $res if $xpath eq "";
#  my $xpc = clone_xpc();
  my $res_el;
  $_xpc->setContextSize(0+@{$nl}) if $_xpc->can('setContextSize');
  my $pos=1;
  foreach my $node (@{$nl}) {
    $_xpc->setContextPosition($pos++) if $_xpc->can('setContextSize');
    my $val;
    eval { $val = $_xpc->find($xpath,$node); };
    return XML::LibXML::NodeList->new() if $@;
    next unless (ref($val));
    push @$res,cast_value_to_objects($val,undef,1);
  }
  return $res;
}

sub XPATH_match {
  die "Wrong number of arguments for function xsh:match(string,regexp,options?)!\n" if (@_!=2 and @_!=3);
  use utf8;
  my ($string,$regexp,$options)=@_;
  $string=literal_value($string);
  $regexp=literal_value($regexp);
  $options=literal_value($options);

  die "Invalid options: $options (should only consist of 'cgimosx')!\n"
    unless ($options =~ /^[cgimosx]*$/);
  my @result = eval "\$string=~/\$regexp/$options";
  die $@ if $@;
  my $res = XML::LibXML::NodeList->new();
  my $res_doc=XML::LibXML::Document->new();
  my $res_el=$res_doc->createElementNS($XML::XSH2::xshNS,'xsh:result');
  $res_doc->setDocumentElement($res_el);
  my $el;
  foreach my $str (@result) {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:string');
    $el->appendText($str);
    $res_el->appendChild($el);
    push @$res,$el;
  }
  return $res;
}

sub XPATH_split {
  die "Wrong number of arguments for function xsh:split(regexp,string)!\n"
    if (@_!=2);
  my ($regexp,$string)=@_;
  $regexp=literal_value($regexp);
  $string=literal_value($string);
  my $res = XML::LibXML::NodeList->new();
  my $res_doc=XML::LibXML::Document->new();
  my $res_el=$res_doc->createElementNS($XML::XSH2::xshNS,'xsh:result');
  $res_doc->setDocumentElement($res_el);
  my $el;
  foreach my $str (split $regexp,$string) {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:string');
    $el->appendText($str);
    $res_el->appendChild($el);
    push @$res,$el;
  }
  return $res;
}

sub XPATH_new_attribute {
  die "Wrong number of arguments for function xsh:new-attributes(string, string, [string, string,...])!\n"
    unless (@_ and (scalar(@_) % 2 == 0));
  my %attr=map { literal_value($_) } @_;
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  return XML::LibXML::NodeList->new(map {$doc->createAttribute($_,$attr{$_})} keys %attr);
}

sub XPATH_new_element {
  die "Wrong number of arguments for function xsh:new-element(string, [string,string,...])!\n"
    unless (scalar(@_)%2);
  my ($name,%attrs)=map {literal_value($_)} @_;
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  my $e = $doc->createElement($name);
  foreach my $aname (keys %attrs) {
    $e->setAttribute($aname,$attrs{$aname});
  }
  return XML::LibXML::NodeList->new($e);
}

sub XPATH_new_element_ns {
  die "Wrong number of arguments for function xsh:new-element-ns(string, string, [string,string])!\n"
    unless (@_ and (scalar(@_)+1)%2);
  my ($name,$ns,%attrs)=map {literal_value($_)} @_;
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
#  __debug("ns: $ns");
  my $e=$doc->createElementNS("$ns",$name);
#  my ($prefix,$name) = split ':',$name;
#  my $e=XML::LibXML::Element->new($name);
#  $e->setNamespace("$ns","$prefix",1);
  foreach my $aname (keys %attrs) {
    $e->setAttribute($aname,$attrs{$aname});
  }
  return XML::LibXML::NodeList->new($e);
}


sub XPATH_new_text {
  die "Wrong number of arguments for function xsh:new-text(string)!\n"
    if (@_!=1);
  my $text=literal_value(shift);
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  my $t=$doc->createTextNode($text);
  return XML::LibXML::NodeList->new($t);
}

sub XPATH_new_comment {
  die "Wrong number of arguments for function xsh:new-comment(string)!\n"
    if (@_!=1);
  my $text=literal_value(shift);
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  my $t=$doc->createComment($text);
  return XML::LibXML::NodeList->new($t);
}

sub XPATH_new_cdata {
  die "Wrong number of arguments for function xsh:new-cdata(string)!\n"
    if (@_!=1);
  my $name=literal_value(shift);
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  my $t=$doc->createCDATASection($name);
  return XML::LibXML::NodeList->new($t);
}

sub XPATH_new_pi {
  die "Wrong number of arguments for function xsh:new-pi(string,[ string])!\n"
    if (!@_ or @_>2);
  my ($name,$value)=map { literal_value($_) } @_;
  my $doc = $_xpc->getContextNode;
  unless (ref($doc) and ref($doc = $doc->ownerDocument())) {
    die "No context document\n";
  }
  my $pi = $doc->createPI($name => $value);
  return XML::LibXML::NodeList->new($pi);
}

sub XPATH_new_chunk {
  die "Wrong number of arguments for function xsh:new-chunk(string,[ string])!\n"
    if (@_!=1);
  return XPATH_parse(@_);
}

sub XPATH_times {
  die "Wrong number of arguments for function xsh:times(string,float)!\n"
    if (@_!=2);
  my ($string,$times)=@_;
  $times=literal_value($times);
  $string=literal_value($string);
  return XML::LibXML::Literal->new($times x $string);
}

sub XPATH_if {
  die "Wrong number of arguments for function xsh:if(object,object,object)!\n"
    if (@_!=3);
  my ($test, $if, $else)=@_;
  if (ref($test) and
      (UNIVERSAL::isa($test,'XML::LibXML::NodeList') and @$test
       or $test->to_literal->value)
      or $test) {
    return $if;
  } else {
    return $else;
  }
}

sub XPATH_id2 {
  die "Wrong number of arguments for function xsh:id2(object,string)!\n"
    if (@_!=2);
  my ($nl, $id)=@_;
  die "Wrong type of argument 1 for function xsh:id2(object,string)!\n"
    if (!ref($nl) or not UNIVERSAL::isa($nl,"XML::LibXML::NodeList"));
  die "Argument 2 for function xsh:id2(object,string) isn't a valid qname!\n"
    if ($id =~ /\'/);
  my $res=XML::LibXML::NodeList->new();
  if ($nl->[0]) {
    push @$res, $nl->[0]->findnodes("id('".$id."')");
  }
  return $res;
}

sub XPATH_lineno {
  die "Wrong number of arguments for function xsh:lineno(node-set)!\n"
    if (@_!=1);
  my ($nl, $id)=@_;
  die "Wrong type of argument 1 for function xsh:lineno(node-set)!\n"
    if (!ref($nl) or not UNIVERSAL::isa($nl,"XML::LibXML::NodeList"));
  my $res=-1;
  if ($nl->[0]) {
    $res=$nl->[0]->line_number;
  }
  return XML::LibXML::Number->new($res);
}

sub XPATH_document {
  die "Wrong number of arguments for function xsh:document(string)!\n"
    if (@_!=1);
  my $URI = shift;
  my $abs;
  my @files = _files(); 
  for my $f (@files) {
    return XML::LibXML::NodeList->new($f->[0])
      if ($f->[0]->URI eq $URI);
  }
  unless (_is_absolute($URI)) {
    $URI = File::Spec->rel2abs(_tilde_expand($URI));
    for my $f (@files) {
      return XML::LibXML::NodeList->new($f->[0])
	if ($f->[0]->URI eq $URI);
    }
  }
  my $is_URL = _is_url($URI);
  for my $f (@files) {
    my $f_URI = $f->[0]->URI;
    return XML::LibXML::NodeList->new($f->[0])
      if (_is_url($f_URI) and !$is_URL and $f_URI eq 'file://'.$URI
	    or
	  !_is_url($f_URI) and $is_URL and $URI eq 'file://'.$f_URI);
  }

  return XML::LibXML::NodeList->new();
}

sub XPATH_documents {
  die "Wrong number of arguments for function xsh:documents()!\n"
    if (@_!=0);
  my $res = XML::LibXML::NodeList->new();
  for my $f (_files()) {
    $res->push($f->[0]);
  }
  return $res;
}

sub XPATH_lookup {
  die "Wrong number of arguments for function xsh:lookup(string,string)!\n"
    if (@_!=2);
  my $name = shift;
  my $key = shift;
  my $res;
  $name=~s/^\$//;
  no strict 'refs';
  my $lex = lex_var($name);
  if ($lex) {
    $res = $$lex
  } elsif (defined(${"XML::XSH2::Map::$name"})) {
    $res = ${"XML::XSH2::Map::$name"};
  } else {
    die "xsh:lookup(): variable '\$$name' not defined\n";
  }
  
  if (ref($res) eq 'HASH') {
    my $val = $res->{to_literal($key)};
    if (defined($val)) {
      return $val;
    } else {
      return XML::LibXML::NodeList->new();
    }
  } else {
    return XML::LibXML::NodeList->new();
  }
}

sub XPATH_span {
  die "Wrong number of arguments for function xsh:span(node-set,node-set)!\n"
    if (@_!=2);
  # the first argument is a start node and
  # the second is an end node;
  # only the first argument is taken from each node-set!
  #
  # returns span of sibling nodes "between" them (inclusively).
  # it is an error if the start and end nodes are not siblings.

  my ($start,$end)=@_;
  for my $nl ($start,$end) {
    die "Wrong type of argument in function xsh:span(node-set,node-set)!\n"
      if (!ref($nl) or not UNIVERSAL::isa($nl,"XML::LibXML::NodeList"));
  }
  ($start,$end) = map { $_->[0] } ($start,$end);
  if ($start and $end) {
    if ($start->parentNode->isSameNode($end->parentNode)) {
      my @nodes = ();
      do {{
	push @nodes, $start;
	if ($start->isSameNode($end)) {
	  return XML::LibXML::NodeList->new_from_ref(\@nodes,1);
	}
	$start = $start->nextSibling();
      }} while ($start);
      return XML::LibXML::NodeList->new();
    } else {
      die "Start node and end node are not siblings at xsh:span(node-set,node-set)!\n"
    }
  } else {
    return XML::LibXML::NodeList->new();
  }
}

sub XPATH_context {
  die "Wrong number of arguments for function xsh:context(node-set,float,float)!\n"
    if (@_<2 or @_>3);
  # returns a span of nodes consisting of a given number of nodes
  # before the given context node, the context node itself and a given number of nodes
  # following the context node

  # $context ... preceding-sibling::node()[position()<$before] | . | following-sibling::node()[position<$after]
  my ($context,$before,$after)=@_;
  die "Wrong type of argument in function xsh:context(node-set,float,float)!\n"
      if (!ref($context) or not UNIVERSAL::isa($context,"XML::LibXML::NodeList"));
  $before = int($before);
  $after = defined ($after) ? $before : int($after);
  return scalar($_xpc->findnodes("preceding-sibling::node()[position()<$before] | . | following-sibling::node()[position()<$after]",$context->[0]));
}

# ===================== END OF XPATH EXT FUNC ================

sub get_flags_as_vars {
  no strict qw(refs);
  use Data::Dumper;
  return Data::Dumper->Dump([map eval, @PARAM_VARS],\@PARAM_VARS);
}

sub list_flags {
  my ($opts) = @_;
  $opts = _ev_opts($opts);
  if ($opts->{variables}) {
    no strict qw(refs);
    use Data::Dumper;
    out(get_flags_as_vars());
  } else {
    out("validation ".(get_validation() or "0").";\n");
    out("recovering ".(get_recovering() or "0").";\n");
    out("parser_expands_entities ".(get_expand_entities() or "0").";\n");
    out("parser_expands_xinclude ".(get_expand_xinclude() or "0").";\n");
    out("keep_blanks ".(get_keep_blanks() or "0").";\n");
    out("pedantic_parser ".(get_pedantic_parser() or "0").";\n");
    out("load_ext_dtd ".(get_load_ext_dtd() or "0").";\n");
    out("complete_attributes ".(get_complete_attributes() or "0").";\n");
    out("indent ".(get_indent() or "0").";\n");
    out("empty_tags ".(get_empty_tags() or "0").";\n");
    out("skip_dtd ".(get_skip_dtd() or "0").";\n");
    out(((get_backups() ? "backups" : "nobackups"),";\n"));
    out((($QUIET ? "quiet" : "verbose"),";\n"));
    out((($DEBUG ? "debug" : "nodebug"),";\n"));
    out((($TEST_MODE ? "run-mode" : "test-mode"),";\n"));
    out("switch_to_new_documents ".(get_cdonopen() or "0").";\n");
    out("encoding '$ENCODING';\n");
    out("query_encoding '$QUERY_ENCODING';\n");
    out("xpath_completion ".(get_xpath_completion() or "0").";\n");
    out("xpath_axis_completion \'".get_xpath_axis_completion()."';\n");
  }
}

sub toUTF8 {
  # encode/decode from UTF8 returns undef if string not marked as utf8
  # by perl (for example ascii)
#  return $_[1];
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
#  return $_[1];
  my $res=eval { decodeFromUTF8($_[0],$_[1]) };
  if ($@ =~ /^SIGINT/) {
    die $@
  } else {
    undef $@;
  }
  return defined($res) ? $res : $_[1];
}

# return true if given string is a XSH command name
sub is_command {
  my ($test)=@_;
  foreach my $cmd (@XML::XSH2::CompletionList::XSH_COMMANDS) {
    return 1 if $cmd eq $test;
  }
  return 0;
}

# set current script name
sub xsh_set_script {
  $SCRIPT=$_[0];
}

sub benchtime {
  my ($t0,$t1)=@_;
  Benchmark::timestr(Benchmark::timediff($t0,$t1));
}

# evaluate a XSH command
sub xsh {
  print STDERR "Benchmark: running script $SCRIPT\n" if $BENCHMARK;
  require Benchmark if $BENCHMARK;
  my ($t0,$t1);
  $t0 = Benchmark->new() if $BENCHMARK;
  unless (ref($_xsh)) {
    xsh_init();
    xsh_rd_parser_init();
  }
  $t1 = Benchmark->new() if $BENCHMARK;
  print STDERR "Benchmark: init xsh took:",benchtime($t1,$t0),"\n" if $BENCHMARK;
  if (ref($_xsh)) {
    my $code=join "",map toUTF8($QUERY_ENCODING,$_),@_;
    return run($code);
  } else {
    die "XSH init failed!\n";
  }
}

sub run {
  my ($code) = @_;
  return 1 if ($code=~/^\s*$/);
  require Benchmark if $BENCHMARK;
  my $t0 = Benchmark->new() if $BENCHMARK;
  my $pt = $_xsh->startrule($code);
  my $t1 = Benchmark->new() if $BENCHMARK;
  print STDERR "Benchmark: xsh parsing took:",benchtime($t1,$t0),"\n" if $BENCHMARK;

#  __debug "Post processing parse tree";
  $t0 = Benchmark->new() if $BENCHMARK;
  post_process_parse_tree($pt);
  $t1 = Benchmark->new() if $BENCHMARK;
  print STDERR "Benchmark: compile took:",benchtime($t1,$t0),"\n" if $BENCHMARK;
  dump_parse_tree($pt) if defined $DUMP;
  $t0 = Benchmark->new() if $BENCHMARK;
  my $result=run_commands($pt,1);
  $t1 = Benchmark->new() if $BENCHMARK;
  print STDERR "Benchmark: execution took:",benchtime($t1,$t0),"\n" if $BENCHMARK;
  return $result;
}

sub dump_parse_tree {
  my ($pt) = shift;
  use Data::Dumper;
  local $Data::Dumper::Purity=1;
  
  my $dump = '';

  unless ($DUMP_APPEND) {
    $dump .= <<"EOS";
require XML::XSH2;
XML::XSH2::Functions->VERSION( '$VERSION' );

EOS

    $dump .= <<'EOS';
{
package XML::XSH2::Functions;

# initialize context
xsh_init();

# prepare ARGV
@XML::XSH2::Map::ARGV=@ARGV; 
for (@ARGV,@XML::XSH2::Map::ARGV) {
  $_=toUTF8($QUERY_ENCODING,$_) 
}
# XPath variant of perlish {@ARGV} ($ARGV[1] is the first arg though)
$XML::XSH2::Map::ARGV = XML::LibXML::NodeList->new(
  map { cast_value_to_objects($_) } @XML::XSH2::Map::ARGV
);

EOS
  {
    local $TEST_MODE;
    $dump.= get_flags_as_vars();
  }
  } else {
    $dump.=<<'EOS'
{
package XML::XSH2::Functions;
EOS
  }
  $dump.= "# script $SCRIPT\n\n";
  local $Data::Dumper::Deparse=1;
  $dump.= Data::Dumper->Dump([$pt],['parse_tree']);
  $dump.= "\nXML::XSH2::Functions::run_commands(\$parse_tree);\n";
  $dump.= "};\n\n";
  if (ref($DUMP) eq 'SCALAR') {
    if ($DUMP_APPEND) {
      $$DUMP.=$dump;
    } else {
      $$DUMP=$dump;
    }
  } else {    
    print STDERR "Saving compiled '$SCRIPT' to '$DUMP'\n" unless $QUIET;
    open my $f, ($DUMP_APPEND ? '>>' : '>'), $DUMP || die "Can't dump parse tree to '$DUMP': $!";
    require Config;
    print {$f} "$Config::Config{startperl}\n" unless $DUMP_APPEND;
    print {$f} $dump;
    close $f;
    chmod 0755, $DUMP unless $DUMP_APPEND;
  }
  $DUMP_APPEND = 1;
}

sub post_process_parse_tree {
  my ($pt)=@_;
#  __debug "[ $pt";
  if (ref($pt) eq 'XML::XSH2::Command') {
#    __debug "COMMAND: @$pt\n";
    my ($line,$column,$offset,$script,$cmd,@args)=@$pt;
    unless (ref($cmd)) {
      my $spec = $COMMANDS{$cmd};
      $spec = $COMMANDS{$spec} if ($spec and !ref($spec));
      if ($spec) {
	my ($func,$minargs,$maxargs,$optspec,@extraargs)=@$spec;
	my @opts;
#	print STDERR ("matched $cmd\n");
	while (@args) {
	  if ($optspec and $args[0]=~/^--(.*)$|^:(.)$/) {
	    my $opt = defined($1) ? $1 : $optspec->{$2}; # resolve short opt
	    if (exists($optspec->{$opt})) {
	      shift(@args);
	      if ($optspec->{$opt} ne '') {
		push @opts, $optspec->{$opt}.'/'.$opt;
		push @opts,shift(@args);
	      } else {
		push @opts, '/'.$opt,1;
	      }
	    } else {
	      die "$script: Compile error: unknown option '$args[0]' for command '$cmd' at line $line column $column offset $offset\n";
	    }
	  } else {
	    last;
	  }
	}
	if (@args<$minargs) {
	  die "$script: Compile error: too few arguments (have ",$#args+1,", expect $minargs) for command '$cmd' at line $line column $column offset $offset\n";
	} elsif (defined($maxargs) and @args>$maxargs) {
	  die "$script: Compile error: too many arguments (have ",$#args+1,", expect $maxargs) for command '$cmd' at line $line column $column offset $offset\n";
	}
	foreach (@args) {
	  if (ref eq 'ARRAY') {
	    post_process_parse_tree($_);
	  }
	}
	@$pt=($line,$column,$offset,$script,$func,\@opts,@args,@extraargs);
      } else {
#	print STDERR ("$cmd is a sub call?\n");
	@$pt=($line,$column,$offset,$script,'call',{},1,$cmd,@args);
      }
    }
  } elsif (ref($pt) eq 'ARRAY') {
#    __debug "Processing array @$pt\n";
    for(my $i=0;$i<=$#$pt;$i++) {
      post_process_parse_tree($pt->[$i]) if ref($pt);
    }
  }
#  __debug "]";
}

# setup output stream
sub xsh_set_output {
  $OUT=$_[0];
  binmode $OUT;
  binmode $OUT, ':bytes';
  open STDOUT, ">&", $OUT or warn "Can't dup STDOUT\n";
  select $OUT;
  return 1;
}

# get output stream
sub xsh_get_output {
  return $OUT;
}

sub cast_objects_to_values {
  return map {
    if (ref($_)) {
      UNIVERSAL::can($_,'textContent') ? $_->textContent() : $_->value();
    } else { $_ }
  } map {
    UNIVERSAL::isa($_,'XML::LibXML::NodeList') ? @$_ : $_;
  } @_;
}

sub create_xsh_result_element {
  my $res_doc=XML::LibXML::Document->new();
  my $res_el=$res_doc->createElementNS($XML::XSH2::xshNS,'xsh:result');
  $res_doc->setDocumentElement($res_el);
  return $res_el;
}

sub cast_value_to_objects {
  my ($val, $res_el, $wrap)=@_;
  if (UNIVERSAL::isa($val,"XML::LibXML::NodeList")) {
    return @$val;
  } elsif (UNIVERSAL::isa($val,"XML::LibXML::Node")) {
    return ($val);
  }
  $res_el = create_xsh_result_element() unless (ref($res_el));
  my $res_doc = $res_el->ownerDocument;
  my $el;
  my $res;
  if (!ref($val)) {
    if ($val =~ /^\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*$/) {
      $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:number');
    } else {
      $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:string');
    }
    $el->appendText($val);
    $res = $el->firstChild;
  } elsif (UNIVERSAL::isa($val,"XML::LibXML::Literal")) {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:string');
    $el->appendText($val->value);
    $res = $el->firstChild;
  } elsif (UNIVERSAL::isa($val,"XML::LibXML::Boolean")) {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:boolean');
    $el->appendText($val ? 'true' : '');
    $res = $el->firstChild;
  } elsif (UNIVERSAL::isa($val,"XML::LibXML::Number")) {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:number');
    $el->appendText($val->value);
    $res = $el->firstChild;
  } elsif (ref($val) eq 'ARRAY') {
    $el = $res_doc->createElementNS($XML::XSH2::xshNS,'xsh:array');
    map { cast_value_to_objects($_,$el) } @$val;
    $res=$el;
  } else {
    die("don't know how to cast object '$val' to nodeset");
    return ();
  }
  $res_el->appendChild($el);
  return $wrap ? $el : $res;
}

sub expr {
  my $opts = shift;
  &_ev;
}

# evaluate given XPath or Perl expression
sub _ev {
  my ($exp,$map,$in_place)=@_;
  return undef unless defined $exp;
  utf8::upgrade($exp) unless ref($exp);
  if (ref($exp) eq 'ARRAY') {
    return run_commands($exp,0,1);
  } elsif ($exp =~ /^<<(.)/) {
    # inline document
    if ($1 eq "{") {
      return perl_eval($',$map,$in_place);
    } elsif ($1 eq "(") {
      my $ret = eval { $_xpc->find(_expand($')); };
      _check_err($@,1,1);
      if (ref($ret) and UNIVERSAL::isa($ret,'XML::LibXML::Literal')) {
	return $ret->value;
      } else {
	return $ret;
      }
    } elsif ($1 eq "'") {
      return $';
    } else {
      return _expand($');
    }
  } elsif ($exp =~ /^(?:\d*\.\d+|\d+)$/) {  # a number/float literal
    return 0+$exp;
  } elsif ($exp =~ /^{/) {  # a perl expression
    return perl_eval($exp,$map,$in_place);
  } elsif ($exp eq "") {  # empty
    return "";
  } else {  # an xpath expression
    my $ret = eval { $_xpc->find(_expand($exp)); };
    _check_err($@,1,1);
    if (ref($ret) and UNIVERSAL::isa($ret,'XML::LibXML::Literal')) {
      return $ret->value;
    } else {
      return $ret;
    }
  }
}

# Evaluate given XPath or Perl expression to a node-list.  Evaluate the
# expression using _ev.  If the result is a plain scalar string, it is
# re-evaluated as XPath. If the result is a node or node-list object
# or a perl array containing nodes, it is cast to node-list and
# returned. Otherwise an error is reported.

sub _ev_nodelist {
  my @res = map { cast_value_to_objects($_) } _ev($_[0]);
  if (wantarray) {
    return @res;
  } else {
    XML::LibXML::NodeList->new(@res);
  }
}

sub _ev_list {
  my $exp = $_[0];
  if (ref($exp) eq 'ARRAY') {
    $exp = run_commands($exp, 0, 1);
  } if ($exp =~ /^<<(.)/) {
    # inline document
    if ($1 eq "{") {
      return perl_eval($');
    } else {
      $exp = $';
    }
  } elsif ($exp =~ /^{/) {
    return (perl_eval($exp));
  } else {
    $exp = _expand($exp);
  }
  my $val = eval { $_xpc->find($exp); };
  _check_err($@,1,1);
  if (UNIVERSAL::isa($val,"XML::LibXML::NodeList")) {
    return @$val;
  } elsif (UNIVERSAL::isa($val,"XML::LibXML::Node")) {
    return ($val);
  }

  return ();
}


# evaluate given XPath or Perl expression and return the text content
# of the result
sub _ev_literal {
  my ($exp,$map,$in_place)=@_;
  return "" if $exp eq "";
  my $val = _ev($exp,$map,$in_place);
  return to_literal($val);
}

sub to_literal {
  my ($obj)=@_;
  if (!ref($obj)) {
    my $r=$obj;
    utf8::upgrade($r);
    return $r;
  } else {
    if (UNIVERSAL::isa($obj,'XML::LibXML::NodeList')) {
      if (wantarray) {
	return map { literal_value($_->to_literal) } @$obj;
      } elsif ($obj->[0]) {
	return literal_value($obj->[0]->to_literal);
      } else {
	return '';
      }
    } elsif (UNIVERSAL::isa($obj,'XML::LibXML::Element')) {
      return $obj->textContent();
    } elsif (UNIVERSAL::isa($obj,'XML::LibXML::Attr')) {
      return $obj->getValue();
    } elsif (UNIVERSAL::isa($obj,'XML::LibXML::Node')) {
      return $obj->getData();
    } elsif(ref($obj)=~/^XML::LibXML/) {
      return literal_value($obj);
    } else {
      my $r = "$obj";
      utf8::upgrade($r);
      return $r;
    }
  }
}

# evaluate given XPath or Perl expression and return the text content
# of the result
sub _ev_count {
  my ($exp)=@_;
  return "" if $exp eq "";
  my $result = _ev($exp);
  if (!ref($result)) {
    return $result;
  } else {
    if (UNIVERSAL::isa($result,'XML::LibXML::NodeList')) {
      return $result->size();
    } elsif (UNIVERSAL::isa($result,'XML::LibXML::Node')) {
      return 1;
    } elsif(ref($result)=~/^XML::LibXML/) {
      return literal_value($result);
    }
  }
}


# evaluate given expression to obtain a node-set, take
# and return the owner document of the first node

sub _ev_doc {
  my ($exp)=@_;
  $exp = "." if $exp eq "";
  my ($node)=_ev_nodelist($exp)->pop();
  if ($node) {
    return $_xml_module->owner_document($node);
  } else {
    _warn("Expression '$exp' returns no node");
  }
}

sub _doc {
  my ($obj)=@_;
  my ($node) = map { cast_value_to_objects($_) } $obj;
  if ($node) {
    return $_xml_module->owner_document($node);
  } else {
    _warn("Cannot cast object to a document");
  }
}

sub _ev_string {
  my ($exp,$map,$in_place)=@_;
  if ($exp=~/^\s*(?:&|<<|{)|[\'\"\[\]\(\)\@]|::|\$/) {
    return _ev_literal($exp,$map,$in_place);
  } else {
    return _expand($exp);
  }
}

sub xsh_parse_string {
  my $format=$_[1] || $DEFAULT_FORMAT;
  local $VALIDATION=0;
  if ($format eq 'xml') {
    my $xmldecl;
    $xmldecl="<?xml version='1.0' encoding='utf-8'?>" unless $_[0]=~/^\s*\<\?xml /;
    return $_xml_module->parse_string($_parser,$xmldecl.$_[0]);
  } elsif ($format eq 'html') {
    return $_xml_module->parse_html_string($_parser,$_[0]);
  } elsif ($format eq 'docbook') {
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
  my $opts = shift;
  out("Main program:              $::VERSION $::REVISION\n");
  out("XML::XSH2::Functions:       $VERSION $REVISION\n");
  out("XML::LibXML:               $XML::LibXML::VERSION\n");
#  out($_xml_module->module(),"\t",$_xml_module->version(),"\n");
  out("XML::LibXSLT               $XML::LibXSLT::VERSION\n")
    if defined($XML::LibXSLT::VERSION);
  out("XML::LibXML::XPathContext  $XML::LibXML::XPathContext::VERSION\n")
    if defined($XML::LibXML::XPathContext::VERSION);
  return 1;
}

# print a list of all open files
sub _files {
#  out(map { "$_ = $_files{$_}\n" } sort keys %_files);
  my @ret;
  no strict 'refs';
  my %seen;
  foreach my $var (keys %{"XML::XSH2::Map::"}) {
    my $value = ${"XML::XSH2::Map::".$var};
    if (ref($value)) {
      $value = $value->[0] if (UNIVERSAL::isa($value,'XML::LibXML::NodeList')
			       and $value->size()==1);
      if (UNIVERSAL::isa($value,'XML::LibXML::Node') and
	  $_xml_module->is_document($value) and !exists($seen{$$value})) {
	push @ret, [$value, $var];
	$seen{$$value}=undef;
      }
    }
  }
  my $cur_doc = $_xml_module->owner_document(xsh_context_node());
  if (!exists($seen{$$cur_doc})) {
    push @ret, [$cur_doc, undef];
  }
  return @ret;
}


sub files {
  my $opts = shift;
  for my $f (_files) {
    out((defined($f->[1]) ? "\$".$f->[1] . " := " : ()),
	'open ',
	($_xml_module->document_type($f->[0]) eq 'html' ?
	   '--format html ' : ()),
	"'".$f->[0]->URI()."';\n");
  }
}


sub close_undef_value {
  my ($doc,$value)=@_;
  if (ref($value)) {
    if (UNIVERSAL::isa($value,'XML::LibXML::NodeList')) {
      @$value = grep
	{eval { $doc->isSameNode($_xml_module->owner_document($_)) ? 0 : 1}}
	  @$value;
    } elsif (UNIVERSAL::isa($value,'XML::LibXML::Node')
	and $doc->isSameNode($_xml_module->owner_document($value))) {
      undef $value;
    }
  }
  return $value;
}

sub close_doc {
  my ($opts,$exp)=@_;
  my $doc = _ev_doc($exp);
  no strict 'refs';
  foreach my $var (keys %{"XML::XSH2::Map::"}) {
    my $value = ${"XML::XSH2::Map::".$var};
    next unless defined $value;
    undef ${"XML::XSH2::Map::".$var} 
      unless defined(close_undef_value($doc,$value));
  }
  foreach my $lex_context (@$lexical_variables) {
    my ($name,$value);
    while (($name,$value) = each %$lex_context) {
      next unless defined $value;
      $value = close_undef_value($doc,$value);
      unless (defined($value)) {
	$lex_context->{$name} = undef 
      }
    }
  }
  return 1;
}

sub xpath_var_lookup {
  my ($data,$name,$ns)=@_;
  no strict;
  my $res;
  if ($ns ne "") {
    $res = $XML::XSH2::Map::NAMESPACED_VARIABLES{$ns." ".$name};
    unless (defined ($res)) {
      die "Undefined variable '\%$name' in namespace `$ns'\n";
    }
  } else {
    my $lex = lex_var($name);
    if ($lex) {
      $res = $$lex
    } elsif (defined(${"XML::XSH2::Map::$name"})) {
      $res = ${"XML::XSH2::Map::$name"};
    } else {
      die "Undefined variable '\$$name'\n";
    }
  }
  if (ref($res) and UNIVERSAL::isa($res,'XML::LibXML::Node')) {
    return XML::LibXML::NodeList->new($res);
  } else {
    return $res;
  }
}

sub lex_var {
  my ($n)=@_;
  for (my $i=$#$lexical_variables; $i>=0; $i--) {
    return \$lexical_variables->[$i]{$n} if exists($lexical_variables->[$i]{$n});
  }
  return undef;
}

# return a value of the given XSH variable
sub var_value {
  my ($var) = @_;
  if ($var=~/^\$(\$.*)/) {
    my $name = var_value($1);
    die "Dereferencing $var to a non-ID: $name\n"
      if ($name !~ /((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*/);
    return var_value(q($).$name);
  } elsif ($var=~/^\$?(.*)/) {
    no strict qw(refs);
    my $lex = lex_var($1);
    if ($lex) {
      return $$lex
    } elsif (defined(${"XML::XSH2::Map::$1"})) {
      return ${"XML::XSH2::Map::$1"};
    }
  } else {
    return undef;
  }
}

sub string_vars {
  no strict qw(refs);
  return sort grep { defined(${"XML::XSH2::Map::$_"}) } keys %{"XML::XSH2::Map::"};
}

# print a list of XSH variables and their values
#
# KNOWN BUG: $ARGV doesn't map to the correct i.e. (no) package
#

sub variables {
  my $opts = shift;
  no strict 'refs';
  foreach (string_vars()) {
    my $value = var_value(q($).$_);
    if (!defined($value)) { 
      out(qq(\$$_={ )."undef".qq( };\n));
    } elsif (ref($value)) {
      out(qq(\$$_={ ).var_value(q($).$_).qq( };\n));
    } elsif (0+$value eq $value) {
      out(qq(\$$_=).var_value(q($).$_).qq(;\n));
    } else {
      out(qq(\$$_=\').var_value(q($).$_).qq(\';\n));
    }
  }
  return 1;
}

sub echo {
  my $opts = _ev_opts(shift);
  my $val = join(($opts->{nospace} ? "" : " ") ,
		 (map _ev_string($_),@_)).($opts->{nonl} ? "" : "\n");
  $opts->{stderr} ? (print STDERR $val) : out($val);
  return 1;
}
sub set_quiet { shift if @_>1; $QUIET=$_[0]; return 1; }
sub set_debug { shift if @_>1; $DEBUG=$_[0]; return 1; }
sub set_compile_only_mode { shift if @_>1; $TEST_MODE=$_[0]; return 1; }

sub test_enc {
  my ($enc)=@_;
  if (
    defined(toUTF8($enc,'')) and defined(fromUTF8($enc,''))
     ) {
#    print STDERR "OK\n";
    return 1;
  } else {
#    print STDERR "NOT-OK\n";
    _err("Error: Cannot convert between $enc and utf-8\n");
    return 0;
  }
}

sub set_encoding {
  shift if @_>1; # opts
# print STDERR "ENCOD: @_\n";
 my $enc=_ev_string($_[0]);
 my $ok=test_enc($enc);
 $ENCODING=$enc;
 return 1;
#   my $ok=test_enc($enc);
#   if ($ok) {
#     $ENCODING=$enc;
# #     $enc = "encoding($enc)" unless $enc eq 'utf8';
# #     binmode $OUT;
# #     binmode $OUT,":$enc";
# #     binmode STDOUT;
# #     binmode STDOUT,":$enc";
# #     binmode STDERR;
# #     binmode STDERR,":$enc";
# #     print "Setting encoding to :$enc\n";
#   }
#   return $ok;
}

sub set_qencoding { 
  my ($opts,$exp)=@_;
  my $enc=_ev_string($exp);
  my $ok=test_enc($enc);
  $QUERY_ENCODING=$enc if $ok;
  return $ok;
}

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

sub _rt_position {
  return "$RT_SCRIPT line $RT_LINE, column $RT_COLUMN,".
    ($RT_LINE==1 ? "" : " offset $RT_OFFSET.");
}

sub _err {
  print STDERR @_," at ",_rt_position(),"\n" if $ERRORS;
}

sub _warn {
  print STDERR "Warning: ",@_," at ",_rt_position(),"\n" if $WARNINGS;
}


# if the argument is non-void then print it and return 0; return 1 otherwise
sub _check_err {
  my ($err,$survive_int,$remove_at)=@_;
  if ($err) {
    # cleanup the error message
    $err =~ s/^XPathContext: error coming back from perl-dispatcher in pm file\.\s*//;
    if ($remove_at and !ref($err)) {
      $err=~s/ at (?:.|\n)*$//;
    }

    if ($err=~/^SIGINT/) {
      if ($survive_int) {
	$err=~s/ at (?:.|\n)*$//;
	_err($err);
	return 0;
      } elsif (ref($err)) {
	die $err; # propagate
      } else {
	chomp $err;
	unless ($err=~/ at (?:.|\n)*$/) {
	  $err.=" at "._rt_position();
	}
	die $err."\n"; # propagate
      }
    } elsif ($_die_on_err) {
      if ($err=~/^SIGPIPE/) {
	_err('broken pipe (SIGPIPE)');
      } elsif (ref($err)) {
	die $err; # propagate
      } else {
	chomp $err;
	unless ($err=~/ at (?:.|\n)*$/) {
	  $err.=" at "._rt_position();
	}
	die $err."\n"; # propagate
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


# return current node for given document or document root if
# current node is not from the given document
sub xsh_context_node {
  return $_xpc->getContextNode;
}

sub xsh_context_var {
  my $node = xsh_context_node();
  if ($node) {
    return xsh_search_docvar($node);
  }
  return "";
}


# set current node to given XPath
sub set_local_xpath {
  my ($opts,$exp)=@_;
  $exp = "/" if ($exp eq "");
  _set_context([_ev_nodelist($exp)->shift()]);
  return 1;
}

sub cannon_name {
  my ($node)=@_;
  my $local_name =$node->localname();
  my $uri = $node->namespaceURI();
  if ($uri ne '') {
    my $prefix=$node->prefix;
    #if ($prefix eq '') {
    my %r = reverse %_ns;
    $prefix = $r{ $uri };
    if ($prefix ne '') {
      return $prefix.':'.$local_name 
    } elsif(my $parent = $node->parentNode) {
      $prefix = $parent->lookupNamespacePrefix($uri);
      if ($prefix ne '') {
	return $prefix.':'.$local_name 
      }
    }      
    return '*[name()="'.$node->getName().'"]';
  }
  return $local_name;
}

# return XPath identifying a node within its parent's subtree
sub node_address {
  my $node = shift || $_xpc->getContextNode();
  my $no_parent = shift;
  my $name;
  if ($_xml_module->is_element($node)) {
    $name=cannon_name($node);
  } elsif ($_xml_module->is_text($node) or
	   $_xml_module->is_cdata_section($node)) {
    $name="text()";
  } elsif ($_xml_module->is_comment($node)) {
    $name="comment()";
  } elsif ($_xml_module->is_pi($node)) {
    $name="processing-instruction()";
  } elsif ($_xml_module->is_attribute($node)) {
    return "@".cannon_name($node);
  }
  
  if (!$no_parent and $node->parentNode) {
    my @children;
#    if ($_xml_module->is_element($node)) {
#      @children=$_xpc->findnodes("./$name",$node->parentNode);
#    } else {
    my $context = $_xpc->getContextNode;
    @children= eval { $_xpc->findnodes("./$name",$node->parentNode) };
#    }
    if (@children == 1 and $_xml_module->xml_equal($node,$children[0])) {
      return "$name";
    }
    for (my $pos=0;$pos<@children;$pos++) {
      return "$name"."[".($pos+1)."]"
	if ($_xml_module->xml_equal($node,$children[$pos]));
    }
    return "??$name??";
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

# get node's ID
sub node_id {
  my ($node)=@_;
  if ($node) {
    for my $attr ($node->attributes) {
      if ($attr->can('isId') and $attr->isId) {
	my $value = $attr->value;
	return $value if defined $value;
      }
    }
  }
  return undef;
}

# return canonical xpath for the given or current node
sub pwd {
  my $node=shift || $_xpc->getContextNode();
  my $use_id = shift;
  return undef unless ref($node);
  return $node->nodePath() if !$STRICT_PWD and UNIVERSAL::can($node,'nodePath');
  my @pwd=();
  do {
    if ($use_id) {
      my $id = node_id($node);
      if (defined $id) {
	return join "/","id('$id')",@pwd;
      }
    }
    unshift @pwd,node_address($node);
    $node=tree_parent_node($node);
  } while ($node);
  my $pwd="/".join "/",@pwd;
  return $pwd;
}

# return canonical xpath for current node (encoded)
sub xsh_pwd {
  shift if $_[0] && !ref($_[0]); # package name
  &pwd;
}

# print current node's xpath
sub print_pwd {
  my $opts = _ev_opts(shift);
  
  my $pwd=pwd(undef, $opts->{id});
  if ($pwd) {
    out("$pwd\n");
    return $pwd;
  } else {
    return 0;
  }
}

# return base file-name of a given path
sub _base_filename {
  my ($fn)=@_;
  ($^O eq 'Win32') ? ($fn =~ m{([^\\]*)$}) : ($fn =~ m{([^/]*)$});
  return $1;
}

# evaluate variable and xpath expresions in a given string
sub _expand {
  my ($l,$vars)=@_;
  my $k;
  no strict;
  $l=~/^/o;
  while ($l !~ /\G$/gsco) {
    if ($l=~/\G\\\$\{/gsco) {
      $k.='${';
    } elsif ($l=~/\G\$\{(\$?[a-zA-Z_][a-zA-Z0-9_]*)\}/gsco) {
      $k.=var_value(q($).$1);
    } elsif ($vars and $l=~/\G(\$\$?[a-zA-Z_][a-zA-Z0-9_]*)/gsco) {
      $k.=var_value($1);
    } elsif ($l=~/\G\$\{\{(.*?)\}\}/gsco) {
      $k.=perl_eval($1);
    } elsif ($l=~/\G\$\{\((.+?)\)\}/gsco) {
      $k.=_ev_literal($1);
    } elsif ($l=~/\G(\$(?!\{)|\\(?!\$\{)|[^\\\$]+)/gsco) {
      # skip to the next \ or $
      $k.=$1;
    }
  }
  return $k;
}

# expand one or all parameters (according to return context)
sub expand {
  return wantarray ? (map { _expand($_) } @_) : _expand($_[0]);
}

# return a reference to a variable storage
sub _get_var_ref {
  my ($name,$value)=@_;
  no strict 'refs';
  if ($name=~/^\$(\$.*)/) {
    my $prev = $name;
    $name = var_value($1);
    die "Dereferencing $prev to a non-ID: $name\n"
      if ($name !~ /((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/);
    return _get_var_ref(q($).$name);
  } elsif ($name=~/^\$((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/) {
    my $lex = lex_var($1);
    return $lex if ($lex);
    return \${"XML::XSH2::Map::$1"};
  } else {
    die "Invalid variable name $name\n"
  }
  return 1;
}

# assign a value to a variable
sub _assign {
  my ($name,$value,$op)=@_;
  no strict 'refs';
  if ($name=~/^\$(\$.*)/) {
    my $prev = $name;
    $name = var_value($1);
    die "Dereferencing $prev to a non-ID: $name\n"
      if ($name !~ /((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/);
    return _assign(q($).$name,$value,$op);
  } elsif ($name=~/^\$?((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/) {
    $op = '=' unless $op;
    my $lex = lex_var($1);
    if ($lex) {
      eval '$$lex'.$op.'$value'; die $@ if $@;
      print STDERR "lexical \$$1=",${"XML::XSH2::Map::$1"},"\n" if $DEBUG;
    } else {
      eval '${"XML::XSH2::Map::$1"}'.$op.'$value'; die $@ if $@;
      print STDERR "\$$1=",${"XML::XSH2::Map::$1"},"\n" if $DEBUG;
    }
  } else {
    die "Invalid variable name $name\n"
  }
}

# undefine global or localized variable
sub _undef {
  my ($name)=@_;
  no strict 'refs';
  if ($name=~/^\$(\$.*)/) {
    my $prev = $name;
    $name = var_value($1);
    die "Dereferencing $prev to a non-ID: $name\n"
      if ($name !~ /((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/);
    return _undef(q($).$name);
  } elsif ($name=~/^\$((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/) {
    undef ${"XML::XSH2::Map::$1"};
  } else {
    die "Invalid variable name $name\n"
  }
  return 1;
}

# undefine lexical, global or localized variable
sub undefine {
  my ($name)=@_;
  if ($name=~/^\$(\$.*)/) {
    my $prev = $name;
    $name = var_value($1);
    die "Dereferencing $prev to a non-ID: $name\n"
      if ($name !~ /((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/);
    return undefine(q($).$name);
  } elsif ($name=~/^\$((?:::)?[a-zA-Z_][a-zA-Z0-9_]*)*$/) {
    my $lex = lex_var($1);
    if ($lex) {
      undef $$lex;
    } else {
      no strict qw(refs);
      undef ${"XML::XSH2::Map::".$1};
    }
  } else {
    die "Invalid variable name $name\n"
  }
  return 1;
}

sub literal_value {
  return ref($_[0]) ? $_[0]->value() : $_[0];
}

# evaluate xpath and assign the result to a variable
sub xpath_assign {
  my ($exp,$op,$type,$name)=@_;
  if ($type eq 'my') {
    store_lex_variables(0,$name);
  } elsif ($type eq 'local') {
    store_variables(0,$name);
  }
  my $val = _ev($exp);
  _assign($name,$val,$op);
  return 1;
}

sub command_assign {
  my ($command,$op,$type,$name)=@_;
  if ($type eq 'my') {
    store_lex_variables(0,$name);
  } elsif ($type eq 'local') {
    store_variables(0,$name);
  }
  $op =~ s/\s*:\s*//;
  _assign($name,run_commands([$command],0,1),$op);
  return 1;
}

sub make_local {
  foreach (@_) {
    xpath_assign(undef,'=','local',$_);
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
    _warn "Ignoring attempt to make a local variable outside a localizable context!";
    return 0;
  }

  foreach (@vars) {
    my $value=var_value($_);
    push @$pool, $_ => $value;
  }
  push @stored_variables, $pool if ($new);

  return 1;
}

sub store_lex_variables {
  my $new = shift;
  my $pool;
  if ($new) {
    $pool={};
    push @$lexical_variables, $pool;
  } elsif (@$lexical_variables) {
    $pool=$lexical_variables->[$#$lexical_variables]
  } else {
    _warn "Ignoring attempt to make a lexical variable outside a lexical context!";
    return 0;
  }
  foreach (@_) {
    if (/^\s*\$?([^\$]*)/) {
      $pool->{$1} = undef;
    } else {
      die "Invalid lexical variable name $_\n";
    }
  }
}

sub restore_lex_variables {
  unless (ref(pop @$lexical_variables)) {
    __bug("Lexical variable pool is empty, which was not expected!\n");
  }
}

sub create_block_var {
  my ($var,$local) = @_;
  if ($local =~ /local/) {
    store_variables(1,$var);
  } elsif ($local=~/my/) {
    store_lex_variables(1,$var);
  }
}

sub destroy_block_var {
  if ($_[0] =~ /local/) {
    restore_variables();
  } elsif ($_[0]=~/my/) {
    restore_lex_variables();
  }
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
    } else {
      __bug("Invalid variable name '$_'\n");
    }
  }
  return 1;
}

sub _prepare_result_nl {
#   my ($opts)=@_;
#   return undef unless ref($opts);
#   my ($append, $var);
#   if (exists($opts->{'append-result'})) {
#     $append = 1;
#     $var = $opts->{'append-result'};
#   } elsif (exists($opts->{result})) {
#     $append = 0;
#     $var = $opts->{result};
#   } elsif (exists($opts->{'append-result'})) {
#     $append = 1;
#     $var = $opts->{'append-result'};
#   } else {
#     return undef;
#   }
#   my $rl;
#   if ($var ne "") {
#     $rl = var_value($var);
#     unless ($append and (UNIVERSAL::isa($rl,'XML::LibXML::NodeList') or ref($rl) eq 'ARRAY')) {
#       _assign($var,XML::LibXML::NodeList->new());
#       $rl = var_value($var);
#     }
#   }
#   return $rl;
  if ($_want_returns) {
    return XML::LibXML::NodeList->new();
  } else {
    return undef;
  }
}


sub count_xpath {
  my ($exp)=@_;
  my $result = _ev($exp);
  if (ref($result)) {
    if (UNIVERSAL::isa($result,'XML::LibXML::NodeList')) {
      return $result->size();
    } elsif (UNIVERSAL::isa($result,'XML::LibXML::Literal')) {
      return $result->value();
    } elsif (UNIVERSAL::isa($result,'XML::LibXML::Number') or
	     UNIVERSAL::isa($result,'XML::LibXML::Boolean')) {
      return $result->value();
    }
  } else {
    return $result;
  }
}

sub new_doc {
  my ($opts,$root_element)=@_;
  $opts = _ev_opts($opts);
  $root_element = _ev_string($root_element);
  my $format= $opts->{format} || $DEFAULT_FORMAT;
  create_doc(undef, $root_element, $format);
}

# create new document
sub create_doc {
  my ($id, $root_element, $format, $filename)=@_;
  # TODO: $format argument is not used by the grammar
  my $doc;
  $root_element="<$root_element/>" unless ($root_element=~/^\s*</);
  $root_element=~s/^\s+//;
  $doc=xsh_parse_string($root_element,$format);
  set_doc($id,$doc,$filename) if defined($id);
  $_newdoc++;

  _set_context([$doc]) if $SWITCH_TO_NEW_DOCUMENTS;
  return $doc;
}

# bind a document with a given id and filename
sub set_doc {
  my ($id,$doc,$file)=@_;
#  $_doc{$id}=$doc;
#  $_files{$id}=$file;
  _assign($id,$doc);
  set_doc_URI($doc,$file);
  return $doc;
}

sub set_filename {
  my ($opts,$file, $doc)=@_;
  $file = _tilde_expand(_ev_string($file));
  $doc = _ev_doc(defined($doc) ? $doc : '.');
  set_doc_URI($doc,$file);
}

sub set_doc_URI {
  my ($doc,$file)=@_;
  $doc->setBaseURI($file)
    if (defined($file) and ref($doc) and
	UNIVERSAL::can($doc,'setBaseURI'));
  return $doc->URI;
}


sub xsh_search_docvar {
  my ($node)=@_;
  my $doc = $_xml_module->owner_document($node);
  return undef unless ref($doc);
  no strict 'refs';
  foreach my $var (keys %{"XML::XSH2::Map::"}) {
    my $value = ${"XML::XSH2::Map::".$var};
    if (ref($value)) {
      $value = $value->[0] if (UNIVERSAL::isa($value,'XML::LibXML::NodeList')
			       and $value->size()==1);
      if (UNIVERSAL::isa($value,'XML::LibXML::Document')
	  and $value->isSameNode($doc)) {
	return "\$".$var;
      }
    }
  }
}

sub index_doc {
  my ($opts,$exp)=@_;
  $exp = '.' if $exp eq "";
  my $doc = _ev_doc($exp);
  my $result;
  if ($doc->can('indexElements')) {
    $result = $doc->indexElements;
    print STDERR $result." elements indexed.\n" unless $QUIET;
  } else {
    _warn "Indexing not supported by installed version of XML::LibXML\n";
  }
  return $result;
}

sub _is_url {
  return ($_[0] =~ m(^\s*[[:alnum:]]+://)) ? 1 : 0;
}
sub _is_absolute {
  my ($path) = @_;
  return ($path eq '-' or 
	  _is_url($path) or 
	  File::Spec->file_name_is_absolute($path)) ? 1 : 0;
}

# create a new document by parsing a file
sub open_doc {
  my ($opts,$src)=@_;
  $opts = _ev_opts($opts);

  if (exists($opts->{file})+exists($opts->{pipe})+
      exists($opts->{string})>1) {
    die "'open' may have only one input flag: --file | ".
        "--pipe | --string\n";
  }
  my $format= $opts->{format} || $DEFAULT_FORMAT;
  if ($format !~ /^xml$|^html$/) {
    die "Unknown --format for command open: '$format'! Use 'xml' or 'html'.\n";
  }

  foreach my $o (qw(switch-to validate recover expand-entities xinclude
                    keep-blanks pedantic load-ext-dtd complete-attributes)) {
    die "Can't use --$o and --no-$o together\n"
      if ($opts->{'no-'.$o} and $opts->{$o});
  }
  local $SWITCH_TO_NEW_DOCUMENTS = 1 if $opts->{'switch-to'};
  local $SWITCH_TO_NEW_DOCUMENTS = 0 if $opts->{'no-switch-to'};
  local $VALIDATION = 1 if $opts->{validate};
  local $VALIDATION = 0 if $opts->{'no-validate'};
  local $RECOVERING = 1 if $opts->{recover};
  local $RECOVERING = 0 if $opts->{'no-recover'};
  local $PARSER_EXPANDS_ENTITIES = 1 if $opts->{'expand-entities'};
  local $PARSER_EXPANDS_ENTITIES = 0 if $opts->{'no-expand-entities'};
  local $KEEP_BLANKS = 1 if $opts->{'keep-blanks'};
  local $KEEP_BLANKS = 0 if $opts->{'no-keep-blanks'};
  local $PEDANTIC_PARSER = 1 if $opts->{pedantic};
  local $PEDANTIC_PARSER = 0 if $opts->{'no-pedantic'};
  local $LOAD_EXT_DTD = 1 if $opts->{'load-ext-dtd'};
  local $LOAD_EXT_DTD = 0 if $opts->{'no-load-ext-dtd'};
  local $PARSER_COMPLETES_ATTRIBUTES = 1 if $opts->{'complete-attributes'};
  local $PARSER_COMPLETES_ATTRIBUTES = 0 if $opts->{'no-complete-attributes'};
  local $PARSER_EXPANDS_XINCLUDE = 1 if $opts->{'xinclude'};
  local $PARSER_EXPANDS_XINCLUDE = 0 if $opts->{'no-xinclude'};

  my ($source) = grep exists($opts->{$_}),qw(file pipe string);
  my $file;
  unless ($source eq 'string') {
    $file = _tilde_expand(_ev_string($src));
    #  $file=~s{^(\~[^\/]*)}{(glob($1))[0]}eg;
    if ($source eq 'file' and !_is_absolute($file)) {
      $file = File::Spec->rel2abs($file);
    }
    print STDERR "open [$file]\n" if "$DEBUG";
    if ($file eq "") {
      die "filename is empty (hint: \$variable := open file-name)\n";
    }
  } else {
    $file = _ev_string($src);
    print STDERR "open [<STRING>]\n" if "$DEBUG";
    if ($file eq "") {
      die "string is empty\n";
    }
  }

  if (($source ne 'file') or
      (-f $file) or $file eq "-" or
      ($file=~/^[a-z]+:/)) {
    unless ("$QUIET") {
      if ($source eq 'string') {
	print STDERR "parsing string\n";
      } else {
	print STDERR "parsing $file\n";
      }
    }
    my $doc;
    if ($source eq 'pipe') {
      open my $F,"$file|" || die "Can't open pipe: $!\n";
      $F || die "Cannot open pipe to $file: $!\n";
      eval {
	if ($format eq 'xml') {
	  $doc=$_xml_module->parse_fh($_parser,$F);
	} elsif ($format eq 'html') {
	  $doc=$_xml_module->parse_html_fh($_parser,$F);
	} elsif ($format eq 'docbook') {
	  $doc=$_xml_module->parse_sgml_fh($_parser,$F,$QUERY_ENCODING);
	}
      };
      close $F;
      _check_err($@,1,1);
    } elsif ($source eq 'string') {
      my $root_element=$file;
      $root_element="<$root_element/>" unless ($root_element=~/^\s*</);
      $root_element=~s/^\s+//;
      eval {
	$doc=xsh_parse_string($root_element,$format);
      };
      _check_err($@,1,1);
      die "Failed to parse string\n" unless (ref($doc));
      $_newdoc++;
    } else  {
      eval {
	if ($format eq 'xml') {
	  $doc=$_xml_module->parse_file($_parser,$file);
	} elsif ($format eq 'html') {
	  $doc=$_xml_module->parse_html_file($_parser,$file);
	} elsif ($format eq 'docbook') {
	  $doc=$_xml_module->parse_sgml_file($_parser,$file,$QUERY_ENCODING);
	}
      };
      _check_err($@,1,1);
      die "Failed to parse $file as $format\n" unless (ref($doc));
    }
    print STDERR "done.\n" unless "$QUIET";
    _set_context([$doc]) if $SWITCH_TO_NEW_DOCUMENTS;
    return $doc;
  } else {
    die "file doesn't exist: $file\n";
    return 0;
  }
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
     $node->namespaceURI() eq $Xinclude_prefix and
     $node->localname() eq 'include');
}

sub xinclude_start_tag {
  my ($xi)=@_;
  my %xinc = map { $_->nodeName() => $_->value() } $xi->attributes();
  $xinc{parse}='xml' if ($xinc{parse} eq "");
  return "<".$xi->nodeName()." xmlns:".$xi->prefix()."=\"".$Xinclude_prefix."\" href=\"".$xinc{href}."\" parse=\"".$xinc{parse}."\">";
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

sub _xml_decl {
  my ($doc,$version,$enc) = @_;
  $version=($doc->can('getVersion') ? $doc->getVersion() : '1.0')
    if ($doc and !defined $version);
  $enc=($doc->can('getEncoding') ? $doc->getEncoding() : undef)
    if ($doc and !defined $enc);
  return "<?xml version='$version'".(defined($enc) ? " encoding='$enc'?>" : "?>");
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
    $F->print(_xml_decl($doc,undef,$enc),"\n");
    foreach my $node (@$nodes) {
      xinclude_print($doc,$F,$node,$enc);
    }
    $F->print("\n");
  }
  $F->close();
}

# save a document
sub save_doc {
  my ($opts,$exp)=@_;
  $opts = _ev_opts($opts);
  my ($doc,$node);
  if ($opts->{subtree}) {
    $exp ||= '.';
    ($node)=_ev_nodelist($exp)->pop();
    $doc = $_xml_module->owner_document($node) if $node
  } else {
    $node = $doc = _ev_doc($exp);
  }
  die "No document to save\n" unless ($node);

  $opts->{file} = _tilde_expand($opts->{file}) if exists($opts->{file});
  if (exists($opts->{file})+exists($opts->{pipe})+
      exists($opts->{print})+exists($opts->{string})>1) {
    die "'save' may have only one output flag: --file | ".
        "--pipe | --print | --string\n";
  }
  foreach my $o (qw(indent skip-dtd empty-tags skip-xmldecl backup)) {
    die "Can't use --$o and --no-$o together\n"
      if ($opts->{'no-'.$o} and $opts->{$o});
  }

  local $INDENT=1 if $opts->{indent};
  local $XML::LibXML::skipDTD = 1 if $opts->{'skip-dtd'};
  local $XML::LibXML::setTagCompression = 1 if $opts->{'empty-tags'};
  local $XML::LibXML::skipXMLDeclaration = 1 if $opts->{'skip-xmldecl'};

  local $INDENT=0 if $opts->{'no-indent'};
  local $XML::LibXML::skipDTD = 0 if $opts->{'no-skip-dtd'};
  local $XML::LibXML::setTagCompression = 0 if $opts->{'no-empty-tags'};
  local $XML::LibXML::skipXMLDeclaration = 0 if $opts->{'no-skip-xmldecl'};

  local $BACKUPS = 0 if $opts->{'no-backup'};
  local $BACKUPS = 1 if $opts->{'backup'};

  #__debug("$XML::LibXML::skipXMLDeclaration\n");

  my $format = $DEFAULT_FORMAT;

  if (exists($opts->{format})) {
    $format=lc($opts->{format});
  }
  if (exists($opts->{xinclude})) {
    if ($format eq 'html') {
      die "'save --xinclude' can only be used with XML format\n"
    }
    $format = 'xinclude';
  }

  die "'save --subtree' can't be used with HTML format\n" if ($format eq 'html' and $opts->{subtree});

  my ($target) = grep exists($opts->{$_}),qw(file pipe string print);
  $target = 'file' unless defined $target;
  my $file; $file = $opts->{$target} if $target;
  if ($target eq 'file') {
    if ($file eq "") {
      $file=$doc->URI;
    } else {
      $doc->setBaseURI($file) if $doc->can('setBaseURI');
    }
    if ($BACKUPS) {
      eval { rename $file, $file."~"; };
      _check_err($@);
    }
  }

  my $enc = $opts->{encoding} || $_xml_module->doc_encoding($doc) || 'utf-8';
  print STDERR "saving to $target $file as $format (encoding $enc)\n" if "$DEBUG";

  if ($format eq 'xinclude') {
    if ($target ne 'file') {
      die "Target '".uc($target)."' not supported with 'save --xinclude'\n";
    } else {
      if ($doc->{subtree}) {
	save_xinclude_chunk($doc,[$node],$file,'xml',$enc);
      } else {
	save_xinclude_chunk($doc,[$doc->childNodes()],$file,'xml',$enc);
      }
    }
  } elsif ($opts->{subtree}) {
    die "Unsupported format '$format'\n" unless $format eq 'xml';
    my $string =
      _xml_decl($doc,undef,$enc)."\n".
      (($target ne 'string' and lc($enc) =~ /^utf-?8$/i) ?
      $node->toString($INDENT) : fromUTF8($enc,$node->toString($INDENT)))."\n";
    if ($target eq 'file') {
      open my $F, '>', $file || die "Cannot open file $file\n";
      print {$F} ($string);
      close $F;
    } elsif ($target eq 'pipe') {
      $file=~s/^\s*\|?//g;
      open my $F,"| $file" || die "Cannot open pipe to $file\n";
      print {$F} ($string);
      close $F;
    } elsif ($target eq 'string') {
      return $string;
    } elsif ($target eq 'print') {
      out($string);
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
	$doc->toFile($file,$INDENT)
	  or _err("Saving $file failed!"); # should be document-encoding encoded
	# TODO: we should set the URL here
      } elsif ($target eq 'pipe') {
	$file=~s/^\s*\|?//g;
	open my $F,"| $file" || die "Cannot open pipe to $file\n";
	$doc->toFH($F,$INDENT);
	close $F;
      } elsif ($target eq 'string') {
	  return toUTF8($_xml_module->doc_encoding($doc),
			$doc->toString($INDENT));
      } elsif ($target eq 'print') {
	out($doc->toString($INDENT));
      }
    } elsif ($format eq 'html') {
      my $F;
      if ($target eq 'string') {
	no strict qw(refs);
	_assign($1,'');
	my $out=
	  "<!DOCTYPE HTML ".
	    "PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n"
	      unless ($_xml_module->has_dtd($doc));
	$out.=toUTF8($_xml_module->doc_encoding($doc), $doc->toStringHTML());
	return $out;
      } else {
	if ($target eq 'file') {
	  ($F=open_io_file($file)) || die "Cannot open $file\n";
	  # TODO: we should set the URL here
	} elsif ($target eq 'pipe') {
	  $file=~s/^\s*\|?//g;
	  open $F,"| $file";
	  $F || die "Cannot open pipe to $file\n";
	} elsif ($target eq 'print') {
	  $F=$OUT;
	}
	$F->print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n")
	  unless ($_xml_module->has_dtd($doc));
	$F->print(fromUTF8($enc, toUTF8($_xml_module->doc_encoding($doc) || 'utf-8',
					$doc->toStringHTML())));

	$F->close() unless $target eq 'print';
      }
    } else {
      die "Unknown format '$format'\n";
    }
  }
  print STDERR "Document saved into $target '$file'.\n" unless ($@ or $target eq 'print' or "$QUIET");
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
  my ($element,$fold_attrs)=@_;
  return "<".$element->nodeName().
    ($fold_attrs ? ((grep { $_->nodeName() ne "xsh:fold" }
		     $element->attributes()) ? " ..." : "") :
     join("",map { " ".$_->nodeName()."=\"".$_->nodeValue()."\"" } 
	  $element->attributes())
    )
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
  my ($node,$depth,$folding,$fold_attrs)=@_;
  my $result;
  if ($node) {
    if (ref($node) and $_xml_module->is_element($node) and $folding and
	$node->hasAttributeNS($XML::XSH2::xshNS,'fold')) {
      if ($depth>=0) {
	$depth = min($depth,$node->getAttributeNS($XML::XSH2::xshNS,'fold'));
      } else {
	$depth = $node->getAttributeNS($XML::XSH2::xshNS,'fold');
      }
    }

    if ($depth<0 and $folding==0) {
      $result=ref($node) ? $_xml_module->toStringUTF8($node,$INDENT) : $node;
    } elsif (ref($node) and $_xml_module->is_element($node) and $depth==0) {
      $result=start_tag($node,$fold_attrs).
	($node->hasChildNodes() ? "...".end_tag($node) : "");
    } elsif (ref($node) and $_xml_module->is_document($node) and $depth==0) {
      $result=to_string($node,1,$folding,$fold_attrs);
    } elsif ($depth>0 or $folding) {
      if (!ref($node)) {
	$result=$node;
      } elsif ($_xml_module->is_element($node)) {
	$result= start_tag($node).
	  join("",map { to_string($_,$depth-1,$folding,$fold_attrs) } $node->childNodes).
	    end_tag($node);
      } elsif ($_xml_module->is_document($node)) {
	if ($node->can('getVersion') and $node->can('getEncoding')) {
	  $result=_xml_decl($node,undef,undef)."\n";
	}
	$result.=
	  join("\n",map { to_string($_,$depth-1,$folding,$fold_attrs) }
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
  my ($opts,$exp)=@_;
  my $opts = _ev_opts($opts);
  $opts->{depth} = ($exp eq '' ? 1 : -1) unless exists($opts->{depth});
  $exp = '.' if $exp eq '';
  if ($opts->{noindent} and $opts->{indent}) {
    die "Can't use --indent and --no-indent together\n";
  }
  local $INDENT=1 if $opts->{indent};
  local $INDENT=0 if $opts->{'no-indent'};
  my $ql=_ev_nodelist($exp);
  foreach my $node (@$ql) {
    print STDERR "checking for folding\n" if "$DEBUG";
    my $fold=$opts->{fold} &&
      ($_xml_module->is_element($node) || $_xml_module->is_document($node)) &&
      $node->findvalue("count(.//\@*[local-name()='fold' and namespace-uri()='$XML::XSH2::xshNS'])");
    print STDERR "folding: $fold\n" if "$DEBUG";
    out (to_string($node,$opts->{depth},$fold,$opts->{'fold-attrs'}),"\n");
  }
  print STDERR "\nFound ",scalar(@$ql)," node(s).\n" unless "$QUIET";

  return 1;
}

# list namespaces in scope of the given nodes
sub list_namespaces {
  my ($opts,$exp) = @_;
  $opts = _ev_opts($opts);
  my $ql= ($opts->{registered} and $exp eq "") ? [] : _ev_nodelist(defined $exp ? $exp : '.');
  foreach my $node (@$ql) {
    my $n=$node;
    my %namespaces;
    while ($n) {
      foreach my $ns ($n->getNamespaces) {
	$namespaces{$ns->localname()}=$ns->value()
	  unless (exists($namespaces{$ns->localname()}));
      }
      $n=$n->parentNode();
    }
    out(pwd($node),":\n");
    foreach (sort { $a cmp $b } keys %namespaces) {
      out("  xmlns", ($_ ne "" ? ":" : ""),
	  $_,"=\"",
	  $namespaces{$_},"\"\n");
    }
    out("\n");
  }
  if ($opts->{registered}) {
    for (sort keys(%_ns)) {
      out(qq(register-namespace $_ "$_ns{$_}";\n));
    }
  }
  return 1;
}

sub mark_fold {
  my ($opts,$exp)=@_;
  $opts  = _ev_opts($opts);
  $opts->{depth} = 0 if $opts->{depth} eq "";
  $exp = "." if $exp eq "";
  foreach my $node (_ev_nodelist($exp)) {
    if ($_xml_module->is_element($node)) {
      my $doc=$node->ownerDocument;
      if ($doc) {
	# pre-declare xsh namespace
	my $root=$doc->getDocumentElement;
	$root->setAttribute('xmlns:xsh',$XML::XSH2::xshNS) if $root;
      }
      $node->setAttributeNS($XML::XSH2::xshNS,'xsh:fold',$opts->{depth});
    }
  }
  return 1;
}

sub mark_unfold {
  my ($opts,$exp)=@_;
  foreach my $node (_ev_nodelist($exp)) {
    if ($_xml_module->is_element($node) and $node->hasAttributeNS($XML::XSH2::xshNS,'fold')) {
      remove_node($node->getAttributeNodeNS($XML::XSH2::xshNS,'fold'));
    }
  }
  return 1;
}

# canonicalize nodes matching given XPath
sub c14n {
  my ($opts,$exp)=@_;
  $opts = _ev_opts($opts);
  $exp ||= '.';
  my $ql = _ev_nodelist($exp);
  foreach my $node (@$ql) {
    out($node->toStringC14N($opts->{comments},$opts->{filter}),"\n");
  }
  print STDERR "\nFound ",scalar(@$ql)," node(s).\n" unless "$QUIET";
  return 1;

}

# print canonical xpaths identifying nodes matching given XPath
sub locate {
  my ($opts,$exp)=@_;
  $opts = _ev_opts($opts);
  my $ql= _ev_nodelist($exp);
  foreach (@$ql) {
    out(pwd($_,$opts->{id}),"\n");
  }
  print STDERR "\nFound ",scalar(@$ql)," node(s).\n" unless "$QUIET";
  return 1;
}

# print line numbers of matching nodes
sub print_lineno {
  my ($opts,$exp)=@_;
  $opts = _ev_opts($opts);
  my $ql=_ev_nodelist($exp);
  foreach (@$ql) {
    out($_->line_number,"\n");
  }
  return 1;
}

# remove nodes matching given XPath from a document and
# remove all their descendants from all nodelists
sub prune {
  my ($opts,$exp)=@_;
  my $i=0;
  my $ql=_ev_nodelist($exp);
  foreach my $node (@$ql) {
    remove_node($node,get_keep_blanks());
    $i++;
  }
  print STDERR "removed $i node(s)\n" unless "$QUIET";
  return $i;
}

# evaluate given perl expression
sub eval_substitution {
  my ($val,$expr)=@_;
  local $_ = $val if defined($val);

  eval lexicalize("$expr");
  die $@ if $@; # propagate
  return $_;
}

# sort given nodelist according to the given xsh code and perl code
sub perlsort {
  my ($opts,$exp)=@_;
  my $opts = _hash_opts($opts);
  my $list = _ev_nodelist($exp);
  my @list;
  my $old_context = _save_context();
  my $pos=1;
  my $rl = _prepare_result_nl();
  if ($opts->{compare}) {
    foreach (qw(numeric descending)) {
      die "sort cannot use --$_ with --compare at the same time\n" if (exists($opts->{$_}));
    }
  }
  eval {
    if (defined($opts->{key})) {
      foreach my $node (@$list) {
	_set_context([$node,0+@$list,$pos]);
	push @list,[$node, _ev_literal($opts->{key})];
	$pos++;
      }
    } else {
      @list = map { [$_,to_literal($_)] } @$list;
    }
    if ($opts->{numeric}) {
      if ($opts->{descending}) {
	@$rl = map { $_->[0] } sort { $b->[1] <=> $a->[1] } @list;
      } else {
	@$rl = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @list;
      }
    } elsif ($opts->{compare}) {
      @$rl = map { $_->[0] }
	sort {
	  local $XML::XSH2::Map::a = $a->[1];
	  local $XML::XSH2::Map::b = $b->[1];
	  my $result=eval lexicalize($opts->{compare});
	  die $@ if ($@); # propagate
	  $result;
	} @list;
    } else {
      if ($opts->{descending}) {
	if ($opts->{locale}) {
	  use locale;
	  @$rl = map { $_->[0] } sort { $b->[1] cmp $a->[1] } @list;
	} else {
	  @$rl = map { $_->[0] } sort { $b->[1] cmp $a->[1] } @list;
	}
      } else {
	if ($opts->{locale}) {
	  use locale;
	  @$rl = map { $_->[0] } sort { $a->[1] cmp $b->[1] } @list;
	} else {
	  @$rl = map { $_->[0] } sort { $a->[1] cmp $b->[1] } @list;
	}
      }
    }
  };
  my $err = $@;
  do {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  };
  die $err if $err; # propagate

  return $rl;
}

# Evaluate given expression over every node matching given XPath
# and substitute content with the result.
# The element is passed to the expression by its name or value in the $_
# variable.
sub perlmap {
  my ($opts, $mapexp, $exp)=@_;
  $opts = _ev_opts($opts);
  my $ql=_ev_nodelist($exp);
  my $old_context = _save_context();
  my $pos=1;
  my $size = @$ql;
  my $in_place = $opts->{'in-place'};
  @$ql = reverse @$ql if $opts->{reverse};
  eval {
    foreach my $node (@$ql) {
      _set_context([$node,$size,$pos++]);
      if ($_xml_module->is_attribute($node)) {
	my $val = _ev_literal($mapexp, $node->getValue(),$in_place);
	$node->setValue($val) if defined $val;
      } elsif ($_xml_module->is_element($node)) {
	my $value = _ev($mapexp, $node->textContent(),$in_place);
	if (defined($value)) {
	  # prune content
	  for my $child ($node->childNodes()) {
	    $child->unbindNode();
	  }
	  if (ref($value)) {
	    if (UNIVERSAL::isa($value,'XML::LibXML::NodeList')) {
	      foreach my $n (@$value) {
		if ($_xml_module->is_document_fragment($n) or
		      $n->parentNode and 
			$_xml_module->is_document_fragment($n->parentNode)) {
		  # it's a fragment
		  $node->appendChild($n);
		} else {
		  # safely insert a copy
		  insert_node($n,$node,undef,'into',undef,undef);
		}
	      }
	    } elsif (UNIVERSAL::isa($value,'XML::LibXML::Node')) {
	      insert_node($value,$node,undef,'into',undef,undef);
	    } else {
	      $node->appendTextNode(to_literal($value));
	    }
	  } else {
	    $node->appendTextNode($value);
	  }
	}
      } elsif ($node->can('setData') and $node->can('getData')) {
	my $val = _ev_literal($mapexp, $node->getData(),$in_place);
	$node->setData($val) if defined $val;
      }
    }
  };
  my $err = $@;
  {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  }
  die $err if $err; # propagate

  return 1;
}

sub hash {
  my ($opts, $mapexp, $exp)=@_;
  $opts = _ev_opts($opts);
  my $ql=_ev_nodelist($exp);
  my $old_context = _save_context();
  my $pos=1;
  my $size = @$ql;
  my $hash = {};
  eval {
    foreach my $node (@$ql) {
      _set_context([$node,$size,$pos++]);
      my $key = _ev($mapexp, $node);
      if (exists($hash->{$key})) {
	$hash->{$key}->push($node);
      } else {
	$hash->{$key} = XML::LibXML::NodeList->new($node);
      }
    }
  };
  my $err = $@;
  {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  }
  die $err if $err; # propagate

  return $hash;
}


# 
sub _ev_namespace {
  my ($val)=@_;
  if (UNIVERSAL::isa($val,'XML::LibXML::NodeList')) {
    die "Namespace cannot be specified as a node-set!";
  } elsif (ref($val)) {
    return to_literal($val);
  } else {
    return $val;
  }
}

sub perlrename {
  my ($opts, $nameexp, $exp)=@_;
  $opts = _ev_opts($opts);
  my $ns = _ev_namespace($opts->{namespace});
  my $ql=_ev_nodelist($exp);
  my $old_context = _save_context();
  my $pos=1;
  my $size = @$ql;
  @$ql = reverse @$ql if $opts->{reverse};
  my $in_place = $opts->{'in-place'};
  eval {
    foreach my $node (@$ql) {
      _set_context([$node,$size,$pos++]);
      if ($_xml_module->is_attribute($node) ||
	    $_xml_module->is_element($node) ||
	      $_xml_module->is_pi($node)) {
	if ($node->can('setName')) {
	  my $name=$node->getName();
          my $old_name = $name;
          $name = _ev_string($nameexp,$name,$in_place);
          if (defined $name) {
            # If it is an attribute, check there is no attribute
            # with the same name already.
            if ($_xml_module->is_attribute($node) and
                $old_name ne $name and
                $node->getOwnerElement()
                ->hasAttributeNS($ns || $node->namespaceURI(), $name)) {
              _err "Cannot rename attribute '$old_name' to '$name': ",
                "An attribute with same name already exists!";
            } else {
              $node->setName($name);
              if (defined($ns) && $node->nodeName=~/^([^:]+):(.*)$/) {
                $node->setNamespace($ns,$1,1);
              }
            }
	  }
	} else {
	  _err "Node renaming not supported by ",ref($node);
	}
      }
    }
  };
  my $err = $@;
  {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  }
  die $err if $err; # propagate

  return 1;
}


############### AUXILIARY FUNCTIONS ###############

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
    my $prefix = name_prefix($node->getName);
    if ($ns eq "" and $prefix ne "") {
      $ns=$dest->lookupNamespaceURI($prefix);
    }
    # --
    $copy=new_element($dest_doc,$node->getName(),$ns,
		      [map { [$_->nodeName(),$_->nodeValue(), 
			      $_xml_module->is_attribute($_) ?
			      $_->namespaceURI() : ""
			     ] } $node->attributes],$dest);
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

# replace document element with a new one
sub replace_document_element {
  my ($old, $new)=@_;
  my $doc=$_xml_module->owner_document($old);
  my @after_nodes = $old->findnodes('following::node()');
  $old->unbindNode();
  new_document_element($doc,$new,@after_nodes);
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
	    my @nextnodes = get_following_siblings($dest);
	    $dest->unbindNode();
	    new_document_element($parent,$source, @nextnodes);
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

sub _expand_fragment {
  return $_xml_module->is_document_fragment($_[0]) ?
    $_[0]->childNodes : $_[0];
}

sub _is_attached {
  my ($node)=@_;
  while ($node and !$_xml_module->is_document_fragment($node)
	 and !$_xml_module->is_document($node)) {
    $node=$node->parentNode;
  }
  return $node && !$_xml_module->is_document_fragment($node);
}

sub set_namespace {
  my ($opts,$uri)=@_;
  $opts = _ev_opts($opts);
  $uri = _ev_string($uri);
  my $node = $_xpc->getContextNode;
  my $prefix = $opts->{prefix};
  unless ($_xml_module->is_element($node) ||
	    $_xml_module->is_attribute($node)) {
    die "set_namespace: namespaces can only be set for element and attribute nodes\n";
  }
  if (defined $prefix) {
    my $declaredURI = $node->lookupNamespaceURI($prefix);
    if (defined $declaredURI and $declaredURI eq $uri) {
      return $node->setNamespace($uri,$prefix);
    } else {
      die "Namespace error: prefix '$prefix' already used for the namespace '$declaredURI'\n";
    }
  } else {
    if (defined($prefix = $node->lookupNamespacePrefix($uri))) {
      return $node->setNamespace($uri,$prefix);
    } else {
      die "Namespace error: use declare-ns command to declare a prefix for '$uri' first\n";
    }
  }
}

sub declare_namespace {
  my ($opts,$prefix,$uri)=@_;
  $prefix = _ev_string($prefix);
  $uri = _ev_string($uri);
  my $node = $_xpc->getContextNode;
  unless ($_xml_module->is_element($node)) {
    die "declare-ns: namespaces can only be declared on element nodes\n";
  }
  my $declaredURI = $node->lookupNamespaceURI($prefix);
  if (defined $declaredURI and $declaredURI ne $uri) {
    die "Namespace error: prefix '$prefix' already used for the namespace '$declaredURI'\n";
  }
  $node->setNamespace($uri,$prefix,0);
}

sub change_namespace_prefix {
  my ($opts,$new,$old)=@_;
  $old = _ev_string($old) if $old;
  $new = _ev_string($new);
  my $node = $_xpc->getContextNode;
  if ($node && $_xml_module->is_element($node)) {
    $old = $node->prefix unless defined $old;
    return $node->setNamespaceDeclPrefix($old,$new);
  } else {
    _err("The context node is not an element");
  }
}

sub change_namespace_uri {
  my ($opts,$uri,$prefix)=@_;
  $prefix = _ev_string($prefix) if $prefix;
  $uri = _ev_string($uri);
  my $node = $_xpc->getContextNode;
  if ($node && $_xml_module->is_element($node)) {
    $prefix = $node->prefix unless defined $prefix;
    return $node->setNamespaceDeclURI($prefix,$uri);
  } else {
    _err("The context node is not an element");
  }
}

# use the XPathToXML module to build
# up a XML structure
sub xpath_set {
  my ($opts,$exp,$value)=@_;
  require XML::XSH2::XPathToXML;
  my $xtx = XML::XSH2::XPathToXML->new(namespaces => \%_ns,
				 XPathContext => $_xpc,
				 node => xsh_context_node(),
				);
  $value = _ev($value);
  $exp = _expand($exp);
  if (ref($value) and UNIVERSAL::isa($value,'XML::LibXML::NodeList')) {
    my $result = $xtx->createNode($exp);
    if ($_xml_module->is_element($result)) {
      # if it's an element, try to clone or attach given nodes
      foreach my $node (@$value) {
	if ($_xml_module->is_document_fragment($node) or
	    $node->parentNode and 
	    $_xml_module->is_document_fragment($node->parentNode)) {
	  # it's a fragment
	  $result->appendChild($node);
	} else {
	  # safely insert a copy
	  insert_node($node,$result,undef,'into',undef,undef);
	}
      }
    } else {
      $result->setValue(to_literal($value));
    }
    return $result;
  } else {
    return $xtx->createNode($exp,to_literal($value));
  }
}

# insert given node to given destination performing
# node-type conversion if necessary
sub insert_node {
  my ($node,$dest,$dest_doc,$where,$ns,$rl)=@_;
  if ($_xml_module->is_document($node)) {
    die "Error: Can't insert/copy/move document nodes!\n";
  }
  if (!defined($dest_doc)) {
    $dest_doc = $_xml_module->owner_document($dest);
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
	push @$rl,$dest->ownerElement()->getAttributeNodeNS($dest->namespaceURI(),$dest->getName()) if defined($rl);
	return 'keep'; # as opposed to 'remove'
      } elsif ($where eq 'before' or $where eq 'prepend') {
	$val=~s/^\s+//g;
	set_attr_ns($dest->ownerElement(),$dest->namespaceURI(),$dest->getName(),
		    $val.$dest->getValue());
	push @$rl,$dest->ownerElement()->getAttributeNodeNS($dest->namespaceURI(),$dest->getName()) if defined($rl);
      } elsif ($where eq 'after' or $where eq 'append') {
	$val=~s/\s+$//g;
	set_attr_ns($dest->ownerElement(),$dest->namespaceURI(),$dest->getName(),
		    $dest->getValue().$val);
	push @$rl,$dest->ownerElement()->getAttributeNodeNS($dest->namespaceURI(),$dest->getName()) if defined($rl);
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
	push @$rl,$elem->getAttributeNodeNS("$ns",$name) if defined($rl);
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
	push @$rl,$dest->ownerElement()->getAttributeNodeNS("$ns",$dest->getName()) if defined($rl);
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
      push @$rl,_expand_fragment($copy) if defined($rl);
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
      push @$rl,_expand_fragment($copy) if (defined($rl));
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
	push @$rl,$dest->getAttributeNodeNS("$ns",$node->getName()) if defined($rl);
      } elsif ($where eq 'replace') {
	my $parent=$dest->parentNode();
	if ($_xml_module->is_element($parent)) {
	  set_attr_ns($dest,"$ns",$node->getName(),$node->getValue());
	  push @$rl,$dest->getAttributeNodeNS("$ns",$node->getName()) if defined($rl);
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
	push @$rl,_expand_fragment($copy) if defined($rl);
	return safe_insert($copy,$dest,$where);
      } elsif ($where eq 'into' or $where eq 'append') {
	$dest->appendChild($copy);
	push @$rl,_expand_fragment($copy) if defined($rl);
      } elsif ($where eq 'prepend') {
	if ($dest->hasChildNodes()) {
	  $dest->insertBefore($copy,$dest->firstChild());
	} else {
	  $dest->appendChild($copy);
	}
	push @$rl,_expand_fragment($copy) if defined($rl);
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
      $value = "" unless defined $value;
      $dest->setData($value);
      push @$rl,$dest if defined($rl);
    } elsif ($where eq 'append') {
      my $value=$_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      $dest->setData($dest->getData().$value);
      push @$rl,$dest if defined($rl);
    } elsif ($where eq 'prepend') {
      my $value=$_xml_module->is_element($node) ?
	$node->textContent() : $node->getData();
      $dest->setData($value.$dest->getData());
      push @$rl,$dest if defined($rl);
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
	push @$rl,$dest->getAttributeNodeNS("$ns",$node->getName()) if defined($rl);
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
	push @$rl,_expand_fragment($new) if defined $rl;
	return safe_insert($new,$dest,$where);
      }
    }
  } else {
    print STDERR "Warning: unsupported/unknown destination type: ",ref($dest),"\n";
    print STDERR substr($node->toString(),0,200), substr($dest->toString(),0,200),"\n" if ref($dest);
  }
  return 1;
}

# parse a string and create attribute nodes
sub create_attributes {
  my ($str)=@_;
  my (@ret,$value,$name);
  while ($str!~/\G$/gsco) {
    if ($str=~/\G\s*([^ \n\r\t=]+)=/gsco) {
      my $name=$1;
      print STDERR "attribute_name=$1\n" if $DEBUG;
      if ($str=~/\G\"((?:[^\\\"]|\\.)*)\"/gsco or
	  $str=~/\G\'((?:[^\\\']|\\.)*)\'/gsco or
	  $str=~/\G(.*?)(?=\s+[^ \n\r\t=]+=|\s*$)/gsco) {
	$value=$1;
	$value=~s/\\(.)/$1/g;
	print STDERR "creating $name='$value' attribute\n" if $DEBUG;
	push @ret,[$name,$value];
      } elsif ($str=~/\G(\s*)$/gsco) {
	$value=$1;
	print STDERR "creating $name='$1' attribute\n" if $DEBUG;
	push @ret,[$name,$value];
	last;
      } else {
	die "Invalid attribute specification near '".substr($str,pos($str))."'\n";
      }
    } elsif ($str =~ /\G(.*)/gsco) {
      die "Invalid attribute specification near '$1'\n"
    } else {
      last;
    }
  }
  return @ret;
}

sub new_element {
  my ($doc,$name,$ns,$attrs,$dest)=@_;
  my $el;
  my ($prefix,$localname) = $name=~/^([^:>]+):(.*)$/;
  if ($prefix ne "" and $ns eq "") {
    die "Error: namespace error: undefined namespace prefix `$prefix'\n";
  }
  if ($dest && $_xml_module->is_element($dest)) {
    print STDERR "DEST is element\n" if $DEBUG;
    $el=$dest->addNewChild($ns,$name);
    
    if ($prefix eq "" and $ns eq "" and $dest->lookupNamespaceURI(undef) ne "") {
      print STDERR "CLEAR Default NS\n" if $DEBUG;
      $el->setNamespace('','',1);
    } else {
      print STDERR "prefix: $prefix, ns: $ns, lookup: ",$dest->lookupNamespaceURI(undef),".\n" if $DEBUG;
      print STDERR $dest->toString(1),"\n" if $DEBUG;
    }
    $el->unbindNode();
  } elsif ($ns ne '') {
    print STDERR "DEST is not element, NS: $ns\n" if $DEBUG;
    $el=$doc->createElementNS($ns,$name);
  } else {
    print STDERR "DEST is not element no NS\n" if $DEBUG;
    $el=$doc->createElement($name);
  }
  if (ref($attrs)) {
    foreach (@$attrs) {
      if ($ns ne "" and ($_->[0]=~/^\Q${prefix}\E:/)) {
	print STDERR "NS: $ns\n" if $DEBUG;
	$el->setAttributeNS($ns,$_->[0],$_->[1]);
      } elsif  ($_->[0] =~ "xmlns:(.*)") {
	print STDERR "xmlns: $1\n" if $DEBUG;
	# don't redeclare NS if already declared on destination node
	unless ($_->[1] eq $ns or $dest->lookupNamespaceURI($1) eq $_->[2]) {
	  $el->setNamespace($_->[1],$1,0) unless ($_->[1] eq $ns);
	}
      } elsif  ($_->[0] eq "xmlns") {
	print STDERR "xmlns: @$_\n" if $DEBUG;
	# don't redeclare NS if already declared on destination node
	unless ($->[1] eq $ns or $dest->lookupNamespaceURI('') eq $_->[2]) {
	  $el->setNamespace($_->[1],'',0) unless ($_->[1] eq $ns);
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
  my ($type,$str,$doc,$ns)=@_;
  my @nodes=();
  die "No document for create $type $str for.\n" unless ref($doc);
  die "Can't create $type from empty specification.\n"
    if ($str eq "" and $type !~ /text|cdata|comment/);
#  return undef unless ($str ne "" and ref($doc));
  if ($type eq 'chunk') {
    @nodes=map {$_->childNodes()}
      grep {ref($_)} ($_parser->parse_xml_chunk($str));
  } else {
    if ($type eq 'attribute') {
      foreach (create_attributes($str)) {
	my $at;
	if ($_->[0]=~/^([^:]+):/ and $1 ne 'xmlns') {
	  $ns = get_registered_ns($1) if $ns eq "";
	  die "Error: undefined namespace prefix `$1'\n"  if ($ns eq "");
	  $at=$doc->createAttributeNS($ns,$_->[0],$_->[1]);
	} else {
	  $at=$doc->createAttribute($_->[0],$_->[1]);
	}
	push @nodes,$at;
      }
    } elsif ($type eq 'element') {
      my ($name,$attributes);
      if ($str=~/^\<?([^ \t\n\/\<\>]+)(\s+.*)?(?:\/?\>)?\s*$/) {
	print STDERR "element_name=$1\n" if $DEBUG;
	print STDERR "attributes=$2\n" if $DEBUG;
	my ($elt,$att)=($1,$2);
	my $el;
	if ($elt=~/^([^:>]+):(.*)$/ or $ns ne "") {
	  print STDERR "Name: $elt\n" if $DEBUG;
	  if ($ns eq "") {
	    print STDERR "NS prefix registered as: $ns\n" if $DEBUG;
	    $ns = get_registered_ns($1) if $ns eq "";
	  } else {
	    print STDERR "NS: $ns\n" if $DEBUG;
	  }
	  die "Error: undefined namespace prefix `$1'\n"  if ($1 ne "" and $ns eq "");
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
	# __debug("ns: $ns\n".$el->toString());
      } else {
	print STDERR "invalid element $str\n" unless "$QUIET";
      }
    } elsif ($type eq 'text') {
      push @nodes,$doc->createTextNode($str);
      print STDERR "text=$str\n" if $DEBUG;
    } elsif ($type eq 'entity_reference') {
      push @nodes,$doc->createEntityReference($str);
      print STDERR "entity_reference=$str\n" if $DEBUG;
    } elsif ($type eq 'cdata') {
      push @nodes,$doc->createCDATASection($str);
      print STDERR "cdata=$str\n" if $DEBUG;
    } elsif ($type eq 'pi') {
      my ($name,$data)=($str=~/^\s*(?:\<\?)?(\S+)(?:\s+(.*?)(?:\?\>)?)?$/);
      $data = "" unless defined $data;
      my $pi = $doc->createPI($name,$data);
      print STDERR "pi=<?$name ... $data?>\n" if $DEBUG;
      push @nodes,$pi;
      #    print STDERR "cannot add PI yet\n" if $DEBUG;
    } elsif ($type eq 'comment') {
      push @nodes,$doc->createComment($str);
      print STDERR "comment=$str\n" if $DEBUG;
    } else {
      die "unknown type: $type\n";
    }
  }
  return @nodes;
}

sub run_editor {
  my ($data,$editor,$encoding)=@_;
  ($editor) = grep {$_ ne ""} $editor,$ENV{VISUAL},$ENV{EDITOR},'vi';
  $encoding = $QUERY_ENCODING unless $encoding;
  my $dir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $dir );
  binmode $fh,'bytes';
  $fh->print(fromUTF8($encoding,$data));
  $fh->flush if $fh->can('flush');
  close($fh);
  if (system($editor." ".$filename) == 0) {
    open $fh,$filename;
    binmode $fh,'bytes';
    $data= join "",map toUTF8($encoding,$_),<$fh>;
    close $fh;
  } else {
    $data=undef;
  }
  unlink $filename;
  unlink $dir;
  return $data;
}

sub ask_user {
  my ($question, $answers) = @_;
  print STDERR $question;
  STDERR->flush;
  my $reply = <STDIN>;
  chomp $reply;
  if ($answers ne "") {
    while ($reply !~ /^$answers$/) {
      print STDERR "Answer ",join("/",split(/\|/,$answers)),": ";
      STDERR->flush;
      $reply = <STDIN>;
      chomp $reply;
    }
  }
  return $reply;
}

############### END OF AUXILIARY FUNCTIONS ###############

sub edit {
  my ($opts,$exp,$variable)=@_;
  $opts = _ev_opts($opts);
  my $rl = _prepare_result_nl();
  my $ql;
  unless ($variable) {
    $exp = '.' if $exp eq '';
    $ql =_ev_nodelist($exp);
    unless (@$ql) {
      _warn("No nodes matching $exp");
      return $rl;
    }
    # prune nodes included in subtrees of already present nodes
    # cause they would get replaced anyway
    my %n;
    $ql = [ grep {
      my $d=$_; my $ret=1;
      while ($d) {
	if (exists ($n{$$d})) { $ret = 0; last;	}
	else { $d=$d->parentNode; }
      }
      $n{$$_}=1; $ret } @$ql ];
  }
  my $data;
  my $node_idx = 0;
  my $fix;
  my $node;
  my $nodes = scalar(@$ql) unless $variable;
  while ($variable or ($node = $ql->[$node_idx++])) {
    if ($variable) {
      $data=_ev_literal($exp)
    } else {
      my $pwd = pwd($node);
      if ($fix) {
	undef $fix;
      } else {
	if ($_xml_module->is_attribute($node)) {
	  $data=$node->value;
	} elsif ($_xml_module->is_element($node) or
		 $_xml_module->is_document($node) or
		 $_xml_module->is_text_or_cdata($node) or
		 $_xml_module->is_comment($node) or
		 $_xml_module->is_pi($node)) {
	  $data=$_xml_module->toStringUTF8($node,$opts->{noindent} ? 0 :$INDENT);
	} else {
	  die("Cannot edit ".ref($node)."\n");
	}
      }
      $data="<!-- XSH-COMMENT: $pwd ".
	($opts->{all} ? "($node_idx/$nodes) " : "")."-->\n"
	  .$data unless $opts->{'no-comment'};
    }
    my $replacement = run_editor($data,$opts->{editor},$opts->{encoding});
    $replacement =~ s/^\s*<!-- XSH-COMMENT: [^>]*-->[ \t]*\n?// unless $variable;
    chomp $replacement unless $variable;
    while ($replacement eq "" and not($opts->{'allow-empty'})) {
      if (-t) {
	my $response = ask_user("Result is empty! Is that correct? (yes/no/stop): ",
				"y|n|s|yes|no|stop");
	if ($response =~ /^y/) {
	  last;
	} elsif ($response =~ /^s/) {
	  return $variable ? $data : $rl;
	} else {
	  $replacement = run_editor($data,$opts->{editor},$opts->{encoding});
	  $replacement =~ s/^\s*<!-- XSH-COMMENT: [^>]*-->[ \t]*\n?//;
	}
      } else {
	die("Result is empty, ignoring changes!\n".
	    "Hint: use --allow-empty option or remove command.\n");
      }
    }
    if ($variable) {
      if ($exp) {
	_assign($exp,$replacement);
      }
      return $replacement;
    } elsif ($_xml_module->is_attribute($node)) {
      $node->setValue($replacement) if defined $replacement;
      push @$rl, $node if defined $rl;
    } else {
      local $RECOVERING=$opts->{recover} ? 1 : $RECOVERING;
      local $KEEP_BLANKS=$opts->{'keep-blanks'} ? 1 : !$INDENT;
      my $chunk;
      if ($_xml_module->is_document($node)) {
	$chunk = eval { $_xml_module->parse_string($_parser,$replacement) };
      } else {
	$chunk = eval { $_xml_module->parse_chunk($_parser,$replacement); };
      }
      if ($@ or not ref($chunk)) {
	if (-t) {
	  my $c = ask_user("$@\n"."Parse error! Press:\n".
			   "  1 - continue with next node\n".
			   "  2 - fix the error in the editor\n".
			   "  3 - restart editor on this node (discarding changes)\n".
			   "  4 - stop\n\n".
			   "Your choice: ","1|2|3|4");
	  if ($c == 1) {
	    next;
	  } elsif ($c == 2) {
	    $data = $replacement;
	    $fix=1;
	    redo;
	  } elsif ($c == 3) {
	    redo;
	  } else {
	    return $rl;
	  }
	} else {
	  die("$@"."Error parsing result, ignoring changes!\n");
	}
      }
      if ($_xml_module->is_document($node)) {
	foreach my $child ($node->childNodes()) {
	  $child->unbindNode();
	}
	foreach my $child ($chunk->childNodes()) {
	  $child->unbindNode();
	  if ($_xml_module->is_element($child)) {
	    $node->setDocumentElement($child);
	    while (my $sibling = $child->nextSibling) {
	      $sibling->unbindNode();
	      $node->insertBefore($sibling);
	    }
	  } else {
	    $node->appendChild($child);
	  }
	}
	push @$rl, $chunk->childNodes() if defined $rl;
      } else {
	if (insert_node($chunk,$node,undef,'replace',undef,$rl) eq 'remove') {
	  remove_node($node);

	}
      }
    }
  } continue {
    last if (not(exists($opts->{all})) or $variable);
  }
  return $rl;
}

# copy nodes matching one XPath expression to locations determined by
# other XPath expression
sub copy {
  my ($opts,$fexp,$where,$texp,$all_to_all)=@_;
  my $fl;
  $opts = _ev_opts($opts);
  $fl=_ev_nodelist($fexp);
  unless (@$fl) {
    _warn("No nodes matching $fexp");
    return 1;
  }
  # respective copying
  my $rl=_prepare_result_nl();
  if ($opts->{respective}) {
    my @rtl;
    my $old_context = _save_context();
    eval {
      my $pos=1;
      my $size = @$fl;
      foreach my $fp (@$fl) {
	_set_context([$fp,$size,$pos]);
	my $tl=_ev_nodelist($texp);
	unless (@$tl) {
	  my $th = ($pos%10 == 1 ? "st" : $pos%10 == 2 ? "nd" : "th");
	  _warn("No nodes matching $texp for $pos$th node matching $fexp\n");
	}
	unless ($all_to_all) { @$tl = ($tl->[0]) }
	push @rtl, $tl;
	$pos++;
      }
    };
    my $err = $@;
    do {
      local $SIG{INT}=\&flagsigint;
      _set_context($old_context);
      propagate_flagsigint();
    };
    die $err if $err; # propagate
    my $reverse = $opts->{'preserve-order'} && $where=~/^(after|prepend)$/;
    foreach my $fp ($reverse ? reverse @$fl : @$fl) {
      my $tl = $reverse ? pop(@rtl) : shift(@rtl);
      foreach my $tp (@$tl) {
	my $replace=0;
	$replace = ((insert_node($fp,$tp,undef,$where,undef,$rl)
		     eq 'remove') || $replace);
	if ($replace) {
	  remove_node($tp);
	}
      }
    }
  } else {
    # non-respective copying
    my $tl=_ev_nodelist($texp);
    unless (@$tl) {
      _warn("No nodes matching $texp");
      return $rl;
    }
    if ($all_to_all) {
      my $real_fl;
      if ($opts->{'preserve-order'} && $where=~/^(after|prepend)$/) {
	$real_fl = [ reverse @$fl ];
      } else {
	$real_fl = $fl;
      }
      foreach my $tp (@$tl) {
	my $replace=0;
	foreach my $fp (@$real_fl) {
	  $replace = ((insert_node($fp,$tp,undef,$where,undef,$rl)
		       eq 'remove') || $replace);
	}
	if ($replace) {
	  remove_node($tp);
	}
      }
    } else {
      _warn("Different number of source and destination nodes.\n".
	    "(Maybe you wanted to call xcopy/xmove?)\n".
	    "Continuing anyway!") if (@$fl != @$tl);
      while (ref(my $fp=shift @$fl) and ref(my $tp=shift @$tl)) {
	my $replace=insert_node($fp,$tp,undef,$where,undef,$rl);
	if ($replace eq 'remove') {
	  remove_node($tp);
	}
      }
    }
  }
  return $rl;
}


# create new nodes from an expression and insert them to locations
# identified by XPath
sub insert {
  my ($opts,$type,$str,$where,$exp,$to_all)=@_;
  $opts = _ev_opts($opts);
  $str = _ev_string($str);
  my $ns  = _ev_namespace($opts->{namespace});
  my $tl=_ev_nodelist($exp);
  unless (@$tl) {
    _warn("Expression '$exp' returns empty node-list");
    return 1;
  }
  my $rl = _prepare_result_nl();
  my @nodes;
  @nodes=grep {ref($_)} create_nodes($type,$str,$_xml_module->owner_document($tl->[0]),$ns);
  unless (@nodes) {
    _warn("Expression generates no nodes to insert");
    return $rl;
  }
  if ($to_all) {
    foreach my $tp (@$tl) {
      my $replace=0;
      foreach my $node (@nodes) {
	$replace = (insert_node($node,$tp,undef,$where,undef,$rl) eq 'remove') || $replace;
      }
      if ($replace) {
	remove_node($tp);
      }
    }
  } elsif ($tl->[0]) {
    foreach my $node (@nodes) {
      if (ref($tl->[0])) {
	if (insert_node($node,$tl->[0],undef,$where,undef,$rl) eq 'remove') {
	  remove_node($tl->[0]);
	}
      }
    }
  }
  return $rl;
}

# wrap nodes into a given element
sub wrap {
  my ($opts,$str,$exp)=@_;
  $opts = _ev_opts($opts);
  my $ns = _ev_namespace($opts->{namespace});
  $str = _ev_string($str);

  my $rl=_prepare_result_nl();
  my $ql=_ev_nodelist($exp);
  my %moved;
  foreach my $node (@$ql) {
    next if $moved{$$node};
    my ($el) = create_nodes('element',$str,
			    $_xml_module->owner_document($node),$ns);
    if ($opts->{inner}) {
      if ($opts->{while} or $opts->{until}) {
	die "wrap: cannot use --while or --until together with --inner\n";
      }
      if ($_xml_module->is_element($node)) {
	my @children = $node->childNodes;
	$node->appendChild($el);
	foreach my $child (@children) {
	  $child->unbindNode();
	  $el->appendChild($child);
	}
      }
    } else {
      if ($_xml_module->is_attribute($node)) {
	if ($opts->{while} or $opts->{until}) {
	  _warn("wrap: ignoring --while or --until on an attribute");
	}
	my $parent=$node->ownerElement();
	$parent->insertBefore($el,$parent->firstChild());
	set_attr_ns($el,$node->namespaceURI(),
		    $node->getName(),$node->getValue());
	$node->unbindNode();
      } else {
	my $parent = $node->parentNode();
	my $last = undef;
	unless ($parent) {
	  die "wrap: cannot wrap node: ".pwd($node)." (node has no parent)\n";
	}
	  # process --while and --until
	if (defined $opts->{while} or defined $opts->{until}) {
	  my $while = $opts->{while};
	  my $until = $opts->{until};
	  my $skip_comments = $opts->{'skip-comments'};
	  my $skip_ws = $opts->{'skip-whitespace'};
	  my $skip_pi = $opts->{'skip-pi'};
	  my $next = $node->nextSibling;
	  # evaluate $opts->{while} in the context of the following sibling
	  if ($next) {
	    my $old_context = _save_context();
	    eval {
	      # what should the size be? guess number of all following siblings
	      my $pos=1;
	      my $size = $node->findvalue('count(following-sibling::node())');
	      while ($next) {
		unless (($skip_ws and $_xml_module->is_text($next) and $next->getData =~ /^\s*$/) or
			($skip_comments and  $_xml_module->is_comment($next)) or 
			  ($skip_pi and $_xml_module->is_pi($next))) {
		  _set_context([$next,$size,$pos]);
		  if (defined $while) {
		    last if !_ev_count($while);
		  }
		  if (defined $until) {
		    my $res = _ev_count($until);
		    last if $res;
		  }
		  $last = $next;
 		  $pos++;
		}
		$next = $next->nextSibling;
	      }
	    };
	    my $err = $@;
	    do {
	      local $SIG{INT}=\&flagsigint;
	      _set_context($old_context);
	      propagate_flagsigint();
	    };	    
	  }
	}
	safe_insert($el,$node,'replace');
	$el->appendChild($node);
	if ($last) {
	  my $next = $el->nextSibling;
	  while ($next) {
	    $next->unbindNode();
	    $el->appendChild($next);
	    $moved{$$next}=1;
	    last if $next->isSameNode($last);
	    $next = $el->nextSibling;
	  }
	  unless ($next) {
	    _warn("wrap: something went wrong");
	  }
	}
      }
    }
    push @$rl, $el if defined $rl;
  }
  return $rl;
}

# wrap span of nodes into a given element
sub wrap_span {
  my ($opts,$str,$xp_start,$xp_end)=@_;
  $opts = _ev_opts($opts);
  $str = _ev_string($str);
  my $ns = _ev_namespace($opts->{namespace});
  my $rl=_prepare_result_nl();
  my $ql_start=_ev_nodelist($xp_start);
  my $ql_end=_ev_nodelist($xp_end);
  if (@$ql_start != @$ql_end) {
    die "Error: there are ".scalar(@$ql_start)." start nodes, ".
      " but ".scalar(@$ql_end)." end nodes!\n";
  }
  for (my $i=0; $i<=$#$ql_start; $i++) {
    my $node = $ql_start->[$i];
    my $end_node = $ql_end->[$i];
    if (not($node->parentNode()) or not($end_node->parentNode())) {
      die "Error: cannot wrap document node\n";
    }
    foreach my $n ($node,$end_node) {
      if ($_xml_module->is_attribute($n)) {
	die "Error: attribute node ".pwd($n).
	  " cannot define a node span boundary\n";
      }
    }
    if (not $node->parentNode()->isSameNode($end_node->parentNode())) {
      die "Error: start node ".pwd($node)." and end node ".
	pwd($end_node)." have different parents\n";
    }
    my ($el) = create_nodes('element',$str,
			    $_xml_module->owner_document($node),$ns);
    my $parent = $node->parentNode();
    my @span;
    my $n=$node;
    while ($n) {
      push @span,$n;
      last if ($n->isSameNode($end_node));
      $n=$n->nextSibling();
    }
    die "Error: Node ".pwd($end_node).
      " isn't following sibling of ".pwd($node)."!\n" unless $n;
    if ($_xml_module->is_document($parent)) {
      # check that document element is within the span
      my $docel=$parent->getDocumentElement();
      my $found=0;
      foreach my $n (@span) {
	if ($n->isSameNode($docel)) {
	  $found=1;
	  last;
	}
      }
      die "Cannot wrap span: ".pwd($node).
	" .. ".pwd($end_node)." (document already has a root element)\n"
	  unless $found;
      replace_document_element($docel,$el);
      foreach my $n (@span) {
	$n->unbindNode();
	$el->appendChild($n);
      }
    } else {
      $parent->insertBefore($el,$node);
      foreach my $n (@span) {
	$n->unbindNode();
	$el->appendChild($n);
      }
    }
    push @$rl, $el if defined $rl;
  }
  return $rl;
}


# normalize nodes
sub normalize_nodes {
  my ($opts,$exp)=@_;
  my $ql=_ev_nodelist($exp);
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
  my ($opts,$exp)=@_;
  my $ql=_ev_nodelist($exp);
  foreach my $node (@$ql) {
    if ($_xml_module->is_text($node)
	or
	$_xml_module->is_cdata_section($node)
	or
	$_xml_module->is_comment($node)
       ) {
      my $data=_trim_ws($node->getData());
      if ($data ne "") {
	$data = "" unless defined $data;
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
	    $data = "" unless defined $data;
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
	    $data = "" unless defined $data;
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
  my ($opts,$exp)=@_;
  my $doc = _ev_doc($exp);
  $opts = _ev_opts($opts);
  if ($opts->{dtd}+$opts->{schema}+$opts->{relaxng}>1) {
    die "You can only specify one validation schema at a time\n";
  }
  if (grep(exists($opts->{$_}), qw(file doc string))>1) {
    die "You can only specify one of --file, --doc, --string at a time\n";
  }
  $opts->{dtd} = 1 unless $opts->{schema} or $opts->{relaxng};
  if (exists($opts->{public}) ne "" and not $opts->{dtd}) {
    die "--public ID can only be used for DTD validation (--dtd)\n";
  }
  $opts->{file} = _tilde_expand($opts->{file}) if exists($opts->{file});
  my $ret = 0;
  if ($doc->can('is_valid')) {
    if (!$opts->{dtd} or exists($opts->{file}) or exists($opts->{string}) or
	exists($opts->{doc}) or exists($opts->{public})) {
      if ($opts->{dtd}) {
	my $dtd;
	eval { XML::LibXML::Dtd->can('new') } ||
	  die "DTD validation not supported by your version of XML::LibXML\n";
	if (exists($opts->{file}) or exists($opts->{public})) {
	  $dtd=XML::LibXML::Dtd->new($opts->{public},$opts->{file});
	} elsif (exists($opts->{string})) {
	  $dtd=XML::LibXML::Dtd->parse_string($opts->{string});
	} else {
	  die "Can't use --doc with DTD validation\n";
	}
	if ($opts->{yesno}) {
	  $ret = $doc->is_valid($dtd);
	  out(($ret ? "yes\n" : "no\n"));
	} else {
	  $doc->validate($dtd);
	  $ret = 1;
	}
      } elsif ($opts->{relaxng}) {
	eval { XML::LibXML::RelaxNG->can('new') } ||
	  die "RelaxNG validation not supported by your version of XML::LibXML\n";
	my $rng;
	if (exists($opts->{file})) {
	  $rng=XML::LibXML::RelaxNG->new(location => $opts->{file});
	} elsif (exists($opts->{string})) {
	  $rng=XML::LibXML::RelaxNG->new(string => $opts->{string});
	} elsif (exists($opts->{doc})) {
	  my $rngdoc=_doc($opts->{doc});
	  unless (ref($rngdoc)) {
	    die "--doc argument doesn't evaluate to a document!\n";
	  }
	  $rng=XML::LibXML::RelaxNG->new(DOM => $rngdoc);
	} else {
	  die "No RelaxNG schema specified\n";
	}
	eval { $rng->validate($doc) };
	$ret = $@ ? 0 : 1;
	if ($opts->{yesno}) {
	  out($ret ? "yes\n" : "no\n");
	} else {
	  die "$@\n" if $@;
	}
      } elsif ($opts->{schema}) {
	eval { XML::LibXML::Schema->can('new') } ||
	  die "Schema validation not supported by your version of XML::LibXML\n";
	my $xsd;
	if (exists($opts->{file})) {
	  $xsd=XML::LibXML::Schema->new(location => $opts->{file});
	} elsif (exists($opts->{string})) {
	  $xsd=XML::LibXML::Schema->new(string => $opts->{string});
	} elsif ($opts->{doc}) {
	  my $xsddoc=_doc($opts->{doc});
	  unless (ref($xsddoc)) {
	    die "--doc argument doesn't evaluate to a document!\n";
	  }
	  $xsd=XML::LibXML::Schema->new(string => $xsddoc->toString());
	} else {
	  die "No XSD schema specified\n";
	}
	eval { $xsd->validate($doc) };
	$ret = $@ ? 0 : 1;
	if ($opts->{yesno}) {
	  out($ret ? "yes\n" : "no\n");
	} else {
	  die "$@\n" if $@;
	}
      }
    } else {
      if ($opts->{yesno}) {
	$ret = $doc->is_valid();
	out(($ret ? "yes\n" : "no\n"));
      } else {
	$doc->validate();
	$ret = 1;
      }
    }
  } else {
    die("Vaidation not supported by ",ref($doc));
  }
  return $ret;
}

# process XInclude elements in a document
sub process_xinclude {
  my ($opts, $exp)=@_;
  my $doc = _ev_doc($exp);
  if ($doc) {
    $_xml_module->doc_process_xinclude($_parser,$doc);
  }
  return 1;
}

# print document's DTD
sub list_dtd {
  my $opts = shift;
  my $doc = _ev_doc($_[0]);
  if ($doc) {
    my $dtd=get_dtd($doc);
    if ($dtd) {
      out($_xml_module->toStringUTF8($dtd),"\n");
    }
  }
  return 1;
}

# set document's DTD
sub set_dtd {
  my $opts = _ev_opts($_[0]);
  my $doc = _ev_doc($_[1]);

  if ($doc) {
    my $root = $opts->{name};
    my $public = $opts->{public};
    my $system = $opts->{system};
    if ((defined ($public) or defined ($system)) and !defined($root)) {
      if ($doc->getDocumentElement) {
	$root = $doc->getDocumentElement->nodeName();
      } else {
	die "No --name not specified and document has no root element\n"
      }
    }
    if ($doc->internalSubset) {
      $doc->removeInternalSubset();
    }
    if ($doc->externalSubset) {
      $doc->removeExternalSubset();
    }
    return 1 unless (defined $root or defined $public or defined $system);
    if ($opts->{internal}) {
      $doc->setInternalSubset($doc->createInternalSubset($root, $public,
							 $system));
    } else {
      $doc->setInternalSubset($doc->createInternalSubset($root, $public,
							 $system));
    }
  }
  return 1;
}


# print document's encoding
sub print_enc {
  my ($opts,$doc)=@_;
  my $doc = _ev_doc($doc);
  if ($doc) {
    out($_xml_module->doc_encoding($doc),"\n");
  }
  return 1;
}

sub set_doc_enc {
  my $opts = shift;
  my ($encoding,$doc)=(_ev_literal($_[0]),_ev_doc($_[1]));
  if ($doc) {
    $_xml_module->set_encoding($doc,$encoding);
  }
  return 1;
}

sub set_doc_standalone {
  my $opts = shift;
  my ($standalone,$doc)=(_ev_literal($_[0]),_ev_doc($_[1]));
  $standalone=1 if $standalone=~/yes/i;
  $standalone=0 if $standalone=~/no/i;
  $_xml_module->set_standalone($doc,$standalone);
  return 1;
}

sub doc_info {
  my $opts = shift;
  my $doc = _ev_doc($_[0]);
  if ($doc) {
#    out("type=",$doc->nodeType,"\n");
    out("version=",$doc->version(),"\n");
    out("encoding=",$doc->encoding(),"\n");
    out("standalone=",$doc->standalone(),"\n");
    out("compression=",$doc->compression(),"\n");
    out("URI=",$doc->URI(),"\n");
  }
}

# create an identical copy of a document
sub clone {
  my ($opts,$exp)=@_;
  my $doc = _ev_doc($exp);
  if ($doc) {
    return _clone_xmldoc($doc);
  } else {
    return undef;
  }
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
  if (is_ancestor_or_self($node,xsh_context_node())) {
    _set_context([tree_parent_node($node)]);
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
  my $exp=$_[1]; #source xpath
  my $sourcenodes=_ev_nodelist($exp);
  my $res=copy(@_);
  foreach my $node (@$sourcenodes) {
    remove_node($node);
  }
  return $res;
}

# call a shell command and print out its output
sub sh_noev {
  system($_[0]);
  return 1;
}

sub sh {
  my $opts = shift;
  my $cmd=join " ",map { _ev_string($_) } @_;
  return system(fromUTF8($ENCODING, $cmd));
}

# print the result of evaluating an XPath expression in scalar context
sub print_count {
  my $opts = _ev_opts(shift);
  my $count=count_xpath(@_);
  out("$count\n") unless $opts->{quiet};
  return $count;
}

sub perl_eval_command {
  shift; # opts
  &perl_eval;
}

sub perl_eval {
  my ($exp,$map,$in_place)=@_;
  select $OUT;
  use utf8;
  if (wantarray) {
    my @result=eval(lexicalize($exp));
    die $@ if $@;
    return @result;
  } elsif (defined $map) {
    if (ref($map)) {
      $map = to_literal($map);
    }
    if ($in_place) {
      local $_ = $map;
      eval(lexicalize($exp));
      die $@ if $@;
      return $_;
    } else {
      # abraka dabra: some magic to make $_ read only
      local *_ = eval "\\'$map'";
      my $result=eval(lexicalize($exp));
      die $@ if $@;
      return $result;
    }
  } else {
    my $result=eval(lexicalize($exp));
    die $@ if $@;
    return $result;
  }
}

# evaluate a perl expression
sub print_eval {
  my ($expr)=@_;
  perl_eval($expr);
  return 1;
}

# change current directory
sub cd {
  my $dir = _tilde_expand(_ev_string($_[0]));
  unless (chdir $dir) {
    print STDERR "Can't change directory to $dir\n";
    return 0;
  } else {
    out("$dir\n") unless "$QUIET";
  }
  return 1;
}

# call methods from a list
sub run_commands {
  return 0 unless ref($_[0]) eq "ARRAY";
  my @cmds=@{$_[0]};
  my $top_level=$_[1];
  my $want_returns=$_[2];
  my $trapsignals=$top_level;
  my $result=undef;

  my ($cmd,@params);

  # make sure errors throw exceptions
  local $_die_on_err=1 unless ($top_level);
  local $_want_returns=1 if ($want_returns);

  store_variables(1);
  store_lex_variables(1);
  no strict qw(refs);
  eval {
    local $SIG{INT}=\&sigint if $trapsignals;
    local $SIG{PIPE}=\&sigpipe if $trapsignals;
    foreach my $run (@cmds) {
      if (ref($run) eq 'ARRAY' or ref($run) eq 'XML::XSH2::Command') {
	($RT_LINE,$RT_COLUMN,$RT_OFFSET,$RT_SCRIPT,$cmd,@params)=@$run;
	if ($cmd eq "test-mode") { $TEST_MODE=1; $result=1; next; }
	if ($cmd eq "run-mode") { $TEST_MODE=0; $result=1; next; }
	next if $TEST_MODE;
	$result=$cmd->(@params) if defined($cmd);
      } else {
	$result=0;
      }
    }
  };
  my $err = $@;
  do {
    local $SIG{INT}=\&flagsigint;
    restore_lex_variables();
    restore_variables();
    propagate_flagsigint();
  };
  if (!$trapsignals and $err =~ /^SIGINT|^SIGPIPE/) {
    die $err
  } else {
    _check_err($err,1);
  }
  return $result;
}

sub run_string {
  xsh_rd_parser_init() unless $_xsh;
  my $pt = $_xsh->startrule($_[0]);
  post_process_parse_tree($pt);
  return run_commands($pt,0);
}

sub run_exp {
  my ($opts,$exp)=@_;
  local $SCRIPT="<eval() called from $RT_SCRIPT line $RT_COLUMN>";
  run_string(_ev_literal($exp));
}

# redirect output and call methods from a list
sub pipe_command {
  return 1 if $TEST_MODE;

  local $SIG{PIPE}=sub { };
  my ($cmd,$pipe)=@_;

  return 0 unless (ref($cmd) eq 'ARRAY');

  if ($^O eq 'MSWin32') {
    _warn("Output redirection not supported on Win32 - ignoring pipe!");
    return run_commands($cmd);
  }
  $pipe = expand($pipe);
  if ($pipe eq '') {
    die "Error: empty redirection\n";
  }
  my $out=$OUT;
  print STDERR "openning pipe $pipe\n" if $DEBUG;
  my $pid;
  eval {
    use IPC::Open2;
    {
      local *O = *$out;
      my $P;
      $pid = open2('>&O',$P,$pipe) || die "cannot open pipe $pipe\n";
      $OUT=$P;
## this is an approach to locate a bug in perl
#       local *NEWIN;
#       $pid = open2('>&O',\*NEWIN,$pipe) || die "cannot open pipe $pipe\n";
#       $OUT=\*NEWIN; #$P;
#       my $STDOUT=\*STDOUT;
#       for ($STDOUT,$OUT,$out) {
# 	print STDERR "$_ => ".$_->fileno."\n";
#       }
##    print $OUT "FOO\n";
    run_commands($cmd);
    }
  };
#  print STDERR "FILENO:",$OUT->fileno,"\n";
#  print STDERR `ls -l /proc/$$/fd/`;
  my $err=$@;
  do {
    local $SIG{INT}=\&flagsigint;
    if (UNIVERSAL::can($OUT,'flush')) {
      flush $OUT;
      flush $OUT;
    }
    close $OUT;
    waitpid($pid,0);
    $OUT=$out;
    flush $OUT  if UNIVERSAL::can($OUT,'flush');
    propagate_flagsigint();
  };
  die $err if $err; # propagate
  return 1;
}

# redirect output to a string and call methods from a list
sub string_pipe_command {
  my ($cmd,$name)=@_;
  return 0 unless (ref($cmd) eq 'ARRAY');
  if ($name ne '') {
    my $out=$OUT;
    print STDERR "Pipe to $name\n" if $DEBUG;
    require IO::Scalar;
    $OUT=new IO::Scalar;
    eval {
      run_commands($cmd);
    };
    my $err;
    do {
      local $SIG{INT}=\&flagsigint;
      _assign($name,${$OUT->sref}) unless $@;
      $OUT=$out;
      propagate_flagsigint();
    };
    die $err if $err; # propagate
  }
  return 0;
}


# call methods as long as given XPath returns positive value
sub while_statement {
  my ($exp,$command)=@_;
  my $result=1;
  my $res;
  while ($res=_ev_count($exp)) {
    eval {
      $result = run_commands($command) && $result;
    };
    if (ref($@) and UNIVERSAL::isa($@,'XML::XSH2::Internal::LoopTerminatingException')) {
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
  return $result;
}

sub throw_exception {
  my $opts = shift;
  die _ev_literal($_[0])."\n";
}

sub try_catch {
  my ($try,$catch,$var)=@_;
  my $result;
  eval {
    local $TRAP_SIGPIPE=1;
    local $SIG{INT}=\&sigint;
    local $SIG{PIPE}=\&sigpipe;
#    local $_die_on_err=1; # make sure errors cause an exception
    $result = run_commands($try);
  };
  if (ref($@) and UNIVERSAL::isa($@,'XML::XSH2::Internal::UncatchableException')) {
    die $@; # propagate
  } elsif ($@) {
    my $err=$@;
    if ($err =~ /^SIGINT/) {
      die $err; # propagate sigint
    } else {
      chomp($err) unless ref($err);
      if (ref($var) and @{$var}>1) {
	create_block_var(@$var);
	_assign($var->[0],$err);
	eval {
	  $result = run_commands($catch);
	};
	$err = $@;
	do {
	  local $SIG{INT}=\&flagsigint;
	  destroy_block_var($var->[1]);
	  propagate_flagsigint();
	};
	die $err if $err; # propagate
      } else {
	_assign($var->[0],$@) if ref($var);
	$result = run_commands($catch);
      }
    }
  }
  return $result;
}

sub loop_next {
  my $opts = shift;
  die XML::XSH2::Internal::LoopTerminatingException->new('next',_ev_literal(@_));
}
sub loop_prev {
  my $opts = shift;
  die XML::XSH2::Internal::LoopTerminatingException->new('prev',_ev_literal(@_));
}
sub loop_redo {
  my $opts = shift;
  die XML::XSH2::Internal::LoopTerminatingException->new('redo',_ev_literal(@_));
}
sub loop_last {
  my $opts = shift;
  die XML::XSH2::Internal::LoopTerminatingException->new('last',_ev_literal(@_));
}

sub _save_context {
  return [xsh_context_node(),
	  $_xpc->can('setContextSize') ?
	  ($_xpc->getContextSize(),$_xpc->getContextPosition()) : 
	  (undef,undef)];
}

sub _set_context {
  my ($node,$size,$pos)=@{$_[0]};
  if ($node) {
    $_xpc->setContextNode($node);
    if (defined($size) and defined($pos) and $_xpc->can('setContextSize')) {
      die "invalid size $size\n" if ($size < -1);
      $_xpc->setContextSize($size);
      die "invalid position $pos (size is $size)\n" if ($pos < -1 or $pos>$size);
      $_xpc->setContextPosition($pos);
    }
  } else {
    die "Trying to change current node to an undefined value\n";
  }
}


# call methods on every node matching an XPath
sub foreach_statement {
  my ($exp,$command,$v)=@_;
  my ($var,$local) = ref($v) ? @$v : ();
  my $old_context = _save_context();
  create_block_var($var,$local) if $var ne "";
  eval {
    my @ql = ($var ne "") ? _ev_list($exp) : _ev_nodelist($exp);
    my $pos=1;
    my $size = @ql;
    foreach my $node (@ql) {
      if ($var ne "") {
	_assign($var,$node);
      } else {
	_set_context([$node,$size,$pos]);
      }
      eval {
	run_commands($command);
      };
      if (ref($@) and UNIVERSAL::isa($@,'XML::XSH2::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  $pos++;
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
      $pos++;
    }
  };
  my $err = $@;
  do {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    destroy_block_var($local) if ($var ne "");
    propagate_flagsigint();
  };
  die $err if $err; # propagate
  return 1;
}

# run commands if given XPath holds
sub if_statement {
  my @cases=@_;
  foreach (@cases) {
    my ($exp,$command)=@$_;
    if (!defined($exp) or _ev_count($exp)) {
      return run_commands($command);
    }
  }
  return 1;
}

# run commands unless given XPath holds
sub unless_statement {
  my ($exp,$command,$else)=@_;
  unless (_ev_count($exp)) {
    return run_commands($command);
  } else {
    return ref($else) ? run_commands($else->[1]) : 1;
  }
}

sub _clone_xmldoc {
  my ($doc)=@_;
  if (XML::LibXML::Document->can('cloneNode') ==
      XML::LibXML::Node->can('cloneNode')) {
    # emulated clone
    return $_xml_module->new_parser->parse_string($doc->toString());
  } else {

    # native clone (if my patch ever gets into LibXML)
    return $doc->cloneNode(1);
  }
}

sub xslt_compile {
  my ($as_doc,$stylefile,$want_doc)=@_;
  my $styledoc;
  if ($as_doc) {
    $styledoc = _ev_doc($stylefile);
    die "No XSL document: $stylefile\n" unless $styledoc;
  } else {
    $stylefile = _tilde_expand(_ev_string($stylefile));
    if ((-f $stylefile) or ($stylefile=~/^[a-z]+:/)) {
      $styledoc = XML::LibXML->new()->parse_file($stylefile);
    } else {
      die "File not exists '$stylefile'\n";
    }
  }
  require XML::LibXSLT;
  my $xsltparser=XML::LibXSLT->new();
  my $st = $xsltparser->parse_stylesheet($styledoc);
  if ($want_doc) {
    return ($st, $styledoc);
  } else {
    return $st;
  }
}

# transform a document with an XSLT stylesheet
# and create a new document from the result
sub xslt {
  my ($opts,$stylefile)=(shift,shift);
  my $opts = _ev_opts($opts);

  my $st;
  if ($opts->{compile}) {
    if (@_ or $opts->{'precompiled'}) {
      _warn("Document argument or --precompiled flag given. Ignoring --compile flag!");
    } else {
      return xslt_compile($opts->{'doc'},$stylefile);
    }
  }

  if ($opts->{'precompiled'}) {
    if ($stylefile =~ /^{/) {
      $st = _ev($stylefile);
    } elsif ($stylefile =~ /^\$/) {
      $st = var_value($stylefile);
    } else {
      die "Pre-compiled XSLT stylesheet can't be given only as perl expression or a variable: $stylefile\n";
    }
    unless (ref($st) and UNIVERSAL::isa($st,'XML::LibXSLT::Stylesheet') or
	      UNIVERSAL::isa($st,'XML::LibXSLT::StylesheetWrapper')) {
      die "Pre-compiled XSLT stylesheet doesn't appear to be a XML::LibXSLT::Stylesheet object: $stylefile\n";
    }
  } else {
    print STDERR "compiling\n";
    ($st,my $styledoc) = xslt_compile($opts->{doc},$stylefile,1);
    die "No XSLT document: $stylefile\n" unless $st;
    $stylefile = $styledoc->URI;
  }

  my $source;
  if (@_) {
    $source = shift;
  } else {
    $source = '.';
  }

  my $doc = _ev_doc($source);

  my @params = expand(@_);
  print STDERR "running xslt on $doc stylesheet $stylefile params @params\n" if "$DEBUG";
  die "No document to process with XSLT: $source\n" unless $doc;
  my %params;
  foreach my $p (@params) {
    $p=$1 while $p=~/^\s*\((.*)\)\s*$/;
    if ($p=~/^\s*(\S+?)\s*=\s*(.*?)\s*$/) {
      $params{$1}=$2;
    } else {
      die("Malformed XSLT parameter $p");
    }
  }
  if ($DEBUG) {
    print STDERR map { "$_ -> $params{$_} " } keys %params;
    print STDERR "\n";
  }

  my $rl = $opts->{'string'} ? undef : _prepare_result_nl();
  if ($st) {
    $stylefile=~s/\..*$//;
    my $result = eval {
      $st->transform(_clone_xmldoc($doc),%params);
    };
    if ($result) {
      _warn $@ if $@;
    } else {
      die $@."\n" if $@;
    }
    if ($opts->{'string'}) {
      return $st->output_string($result);
    } else {
      set_doc_URI($result,
		  _base_filename($stylefile).
		  "_transformed_".
		  _base_filename($result->URI()));
      push @$rl,$result if defined $rl;
    }
  } else {
    die "Failed to parse stylesheet '$stylefile'\n";
  }
  return $rl;
}

# perform xupdate processing over a document
sub xupdate {
  my ($opts,$xupdate_doc,$doc)=map { _ev_doc($_) } @_;
  if ($xupdate_doc and $doc) {
    require XML::XUpdate::LibXML;
    require XML::Normalize::LibXML;
    my $xupdate = XML::XUpdate::LibXML->new();
    $XML::XUpdate::LibXML::debug=1;
    $xupdate->process($doc->getDocumentElement(),$xupdate_doc);
  } else {
    if ($xupdate_doc) {
      die "Expression '$_[0]' returns empty nodeset\n";
    } else {
      die "Expression '$_[1]' returns empty nodeset\n";
    }
    return 0;
  }
}

sub call_return { 
  my $opts = shift;
  die XML::XSH2::Internal::SubTerminatingException->new('return',_ev($_[0])); 
}

sub call_command {
  my ($opts,$exp,@args)=@_;
  my $name = _ev_string($exp);
  call($opts,1,$name, @args);
}

# call a named set of commands
sub call {
  my ($opts,$eval_args, $name, @args)=@_;
  my $def = $_defs{$name};
  if (defined $def) {
    my @vars = @$def[2..$#$def];
    if (@vars < @args) {
      _err("too many arguments [".join(";\n",@args)."] for subroutine '$name @vars'");
    } elsif (@vars > @args) {
      _err("too few arguments for subroutine '$name @vars'");
    }
    my $result;
    my %vars;
    foreach (@args) {
      $vars{ shift(@vars) }=$eval_args ? _ev($_) : $_;
    }
    my $prev_lex_context = $lexical_variables;
    $lexical_variables = $def->[1];
    store_lex_variables(1,keys(%vars));
    eval {
      foreach (keys(%vars)) {
	_assign($_,$vars{$_});
      }
      $result = run_commands($def->[0]);
    };
    my $err = $@;
    do {
      local $SIG{INT}=\&flagsigint;
      restore_lex_variables();
      $lexical_variables=$prev_lex_context;
      propagate_flagsigint();
    };
    if (ref($err) and UNIVERSAL::isa($err,'XML::XSH2::Internal::SubTerminatingException')) {
      my $ret = $err->[1];
      undef $err;
      return $ret;
    }
    die $err if $err; # propagate
    return $result;
  } else {
    die "ERROR: $name not defined\n";
  }
}

sub undefine {
  my ($name)=@_;
  if ($name =~ /^\s*\$(.*)$/) {
    _undef($name);
    my $lex = lex_var($1);
    if ($lex) {
      undef $$lex;
    } else {
      no strict qw(refs);
      undef ${"XML::XSH2::Map::".$1};
    }
  } else {
    delete $_defs{$name};
  }
  return 1;
}

# define a named set of commands
sub def {
  my ($name,$command,$args)=@_;
  $_defs{$name} = [ $command, [ @$lexical_variables ], @$args ];
  return 1;
}

# return a list of all definined subroutines
sub defs {
  return sort keys %_defs;
}

# list all defined subroutines
sub list_defs {
  my $opts = shift;
  foreach (sort keys (%_defs)) {
    out(join(" ",$_,@{ $_defs{$_} }[2..$#{ $_defs{$_} }] ),"\n" );
  }
  return 1;
}

# load a file
sub load {
  my ($file,$enc)=@_;
  my $l;
  print STDERR "loading file $file\n" unless "$QUIET";
  $enc ||= $QUERY_ENCODING;
  if (-f $file and open my $f,"$file") {
    if ($] >= 5.008) {
      binmode $f,":encoding($enc)";
    }
    return join "",<$f>;
  } else {
    die "ERROR: couldn't open input file $file\n";
  }
}

# call XSH to evaluate commands from a given file
sub include {
  my ($opts,$f,$conditionally)=@_;
  $f=_tilde_expand(_ev_string($f));
  # File should be relative to the current script URI.
  $f = XML::XSH2::Map::resolve_uri(URI::file->new($f),
                                   URI::file->new($SCRIPT))->file;
  $opts=_ev_opts($opts);
  if (!$conditionally || !$_includes{$f}) {
    $_includes{$f}=1;
    my $l=load($f,$opts->{encoding});
    local $SCRIPT = $f;
    return run($l);
  }
}

# print help

sub apropos {
  my ($opts,$query)=@_;
  $query = expand($query);
  $opts=_ev_opts($opts);
  if ($opts->{fulltext}) {
    foreach my $k (sort keys %XML::XSH2::Help::HELP) {
      if ($opts->{regexp}) {
	out("$k\n") if ($XML::XSH2::Help::HELP{$k}->[0]=~/$query/i);
      } else {
	out("$k\n") if ($XML::XSH2::Help::HELP{$k}->[0]=~/\b\Q$query\E\b/i);
      }
    }
  } else {
    foreach my $k (sort keys %$XML::XSH2::Help::Apropos) {
      if ($opts->{regexp}) {
	out("$k\n") if (($k." - ".$XML::XSH2::Help::Apropos->{$k})=~/$query/i);
      } else {
	out("$k\n") if (($k." - ".$XML::XSH2::Help::Apropos->{$k})=~/\b\Q$query\E\b/i);
      }
    }
  }
}

sub help {
  my $opts = shift;
  my ($command)=expand @_;
  if ($command) {
    if (exists($XML::XSH2::Help::HELP{$command})) {
      out($XML::XSH2::Help::HELP{$command}->[0]);
    } else {
      my @possible =
	grep { index($_,$command)==0 }
	  keys(%XML::XSH2::Help::HELP);
      my %h = map { $XML::XSH2::Help::HELP{$_} => $_ } @possible;
      if (keys(%h) == 1) {
	out($XML::XSH2::Help::HELP{$possible[0]}->[0]);
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
    out($XML::XSH2::Help::HELP);
  }
  return 1;
}

# load catalog file to the parser
sub load_catalog {
  my $opts = shift;
  $_xml_module->load_catalog($_parser,_tilde_expand(_ev_string($_[0])));
  return 1;
}

sub stream_process_node {
  my ($node,$command,$input)=@_;
  my $old_context = _save_context();
  eval {
    foreach (1) {
      _set_context([$node,1,1]);
      eval {
	run_commands($command);
      };
      if (ref($@) and UNIVERSAL::isa($@,'XML::XSH2::Internal::LoopTerminatingException')) {
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
  my $err = $@;
  do {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  };
  die $err if $err; # propagate
}

sub stream_process {
  my ($opts, $process)=@_;
  $opts = _ev_opts($opts);

  require XML::Filter::DOMFilter::LibXML;
  require XML::LibXML::SAX;
  require XML::SAX::Writer;

  if (grep {/^input-/} keys %$opts>1) {
    die "Only one --input-xxxx parameter can be specified\n";
  }
  if (grep {/^output-/} grep { !/^output-encoding/ } keys %$opts>1) {
    die "Only one --output-xxxx parameter can be specified\n";
  }
  if ($opts->{'no-output'} && grep /^output-/, keys %$opts) {
      die "Can't combine --no-output with --output-xxxx\n";
  }

  my $out;
  my $termout;
  $opts->{'input-file'} = _tilde_expand($opts->{'input-file'}) if exists($opts->{'input-file'});
  $opts->{'output-file'} = _tilde_expand($opts->{'output-file'}) if exists($opts->{'output-file'});
  my $output = $opts->{'output-string'} || $opts->{'output-pipe'} ||
               $opts->{'output-file'} || undef;
  my $input = $opts->{'input-string'} || $opts->{'input-pipe'} ||
              $opts->{'input-file'} || '-';

  if (exists $opts->{'output-file'}) {
    open $out,'>'.$output || die "Cannot open output file ".$output."\n";
    if ($] >= 5.008) {
      binmode ($out,
	($opts->{'output-encoding'} ? 
	   ":encoding(".$opts->{'output-encoding'}.")" : ":utf8"));
    }
  } elsif (exists $opts->{'output-pipe'}) {
    open $out,'| '.$output || die "Cannot open pipe to ".$output."\n";
    if ($] >= 5.008) {
      binmode ($out,
	($opts->{'output-encoding'} ? 
	   ":encoding(".$opts->{'output-encoding'}.")" : ":utf8"));
    }
  } elsif (exists $opts->{'output-string'}) {
    my $output = $opts->{'output-string'};
    if ($output =~ /^\$(\$?[a-zA-Z_][a-zA-Z0-9_]*)$/) {
      $out = _get_var_ref($output);
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
	   ->new($opts->{'no-output'} ? ()
                                      : (Handler => XML::SAX::Writer::XML
		                        ->new(
                                              Output => $out,
                                              Writer => 'XML::SAX::Writer::XMLEnc'
                                             )),
		 XPathContext => $_xpc,
		 Process => [
			     map {
			       $_->[0] => [\&stream_process_node,$_->[1],
					   $input] }
			     @$process
			    ]
		)
	 );
  my $old_context = _save_context();
  my $error;
  eval {
      if (exists $opts->{'input-pipe'}) {
        open my $F,"$input|";
        $F || die "Cannot open pipe to $input: $!\n";
        $parser->parse_file($F);
        close $F;
      } elsif (exists $opts->{'input-string'}) {
        $parser->parse_string($input);
      } else  { #file
        $parser->parse_uri($input);
      }
      if (exists $opts->{'output-pipe'}) {
        close($out);
      }
      if ($termout) { out("\n"); }
  1 } or $error = $@;
  _set_context($old_context);
  die $error if $error;

  return 1
}

sub iterate {
  my ($code,$axis,$nodefilter,$filter)=@_;

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
      my $ns = xsh_context_node()->lookupNamespaceURI($1);
      die("Unrecognized namespace prefix '$1:'!") if ($ns eq "");
      $test .= qq{ && (\$_[0]->namespaceURI() eq '$ns') };
    }
  }

  die("Position index filter not supported for iteration ([$filter])") if $filter =~ /^\d+$/;
  if ($filter ne '') {
    $filter =~ s/\\/\\\\/g;
    $filter =~ s/'/\\'/g;
    $test .= qq{ && \$_xpc->find('$filter',\$_[0]) };
  }
  $test = "1" if $test eq "";

  my $filter_sub = eval "sub { $test }";
  die $@ if $@;
  my $iterator;
  do {
    my $start=xsh_context_node();
    $iterator=XML::XSH2::Iterators->create_iterator($start,$axis,$filter_sub);
  };
  return 1 unless defined $iterator;

  my $old_context=_save_context();

  my $count = 1;
  my $pos = 1;
  eval {
  ITER: while ($iterator->current()) {
      _set_context([$iterator->current(),$count,$pos]);
      eval {
	run_commands($code);
      };
      if (ref($@) and UNIVERSAL::isa($@,'XML::XSH2::Internal::LoopTerminatingException')) {
	if ($@->label =~ /^(?:next|last|redo|prev)$/ and $@->[1]>1) {
	  $@->[1]--;
	  die $@; # propagate to a higher level
	}
	if ($@->label eq 'next') {
	  $count ++; $pos ++;
	  $iterator->next() || last;
	  next;
	} elsif ($@->label eq 'prev') {
	  $pos --;
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
      $count ++; $pos ++;
      $iterator->next() || last;
    }
  };
  my $err = $@;
  do {
    local $SIG{INT}=\&flagsigint;
    _set_context($old_context);
    propagate_flagsigint();
  };
  die $err if $err; # propagate
  return 1;
}

# quit
sub quit {
  my $opts = shift;
  if (ref($_on_exit)) {
    &{$_on_exit->[0]}($_[0],@{$_on_exit}[1..$#$_on_exit]); # run on exit hook
  }
  exit(int($_[0]));
}

sub register_ns {
  my $opts = shift;
  my $prefix = _ev_string($_[0]);
  my $ns = _ev_string($_[1]);

  unless ($prefix=~m{^[-_.[:alpha:]][-_.[:alnum:]]*$}) {
    die "Invalid namespace prefix '$prefix'\n";
  }
  $_ns{$prefix}=$ns;
  $_xpc->registerNs($prefix,$ns);
  return 1;
}

sub register_xsh_ns {
  my $opts = shift;
  register_ns($opts,_ev_string($_[0]),$XML::XSH2::xshNS);
}

sub register_xhtml_ns {
  my $opts = shift;
  register_ns($opts,_ev_string($_[0]),'http://www.w3.org/1999/xhtml');
}

sub unregister_ns {
  my ($opts,$exp)=@_;
  my $prefix = _ev_string($exp);
  delete $_ns{$prefix};
  $_xpc->unregisterNs($prefix);
  return 1;
}

sub get_registered_ns {
  return $_ns{$_[0]};
}

sub get_registered_prefix {
  my %r = reverse %_ns;
  return $r{$_[0]};
}

sub register_func {
  my ($opts,$name,$code)=@_;
  $name=_ev_string($name);
  my $sub;
  if ($code =~ /^\s*{/) {
    my $lex = lexicalize("sub $code");
    $sub = eval($lex);
  } elsif ($code =~/^\s*([A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_][A-Za-z_0-9]*)*)\s*$/) {
    if ($2 ne "") {
      $sub=\&{"$1"};
    } else {
      $sub=\&{"XML::XSH2::Map::$1"};
    }
  } else {
    $sub = eval(lexicalize("sub \{ $code \}"));
  }
  die $@ if $@;
  if ($name =~ /^([^:]+):(.*)$/) {
    if (exists($_ns{$1})) {
      $_func{"$2\n$_ns{$1}"}=$sub;
      $_xpc->registerFunctionNS($2, $_ns{$1}, $sub);
    } else {
      die "Registration failed: unknown namespace prefix $1!\n";
    }
  } else {
    $_func{$name}=$sub;
    $_xpc->registerFunction($name, $sub);
  }
  return 1;
}

sub unregister_func {
  my ($opts,$name)=@_;

  if ($name =~ /^([^:]+):(.*)$/) {
    if (exists($_ns{$1})) {
      delete $_func{"$2\n$_ns{$1}"};
      $_xpc->unregisterFunctionNS($2, $_ns{$1});
    } else {
      die "Registration failed: unknown namespace prefix $1!\n";
    }
  } else {
    delete $_func{$name};
    $_xpc->unregisterFunction($name);
  }
  return 1;
}

sub node_type {
  my ($node)=@_;
  return undef unless $node;
  if ($_xml_module->is_element($node)) {
    return 'element';
  } elsif ($_xml_module->is_attribute($node)) {
    return 'attribute';
  } elsif ($_xml_module->is_text($node)) {
    return 'text';
  } elsif ($_xml_module->is_cdata_section($node)) {
    return 'cdata';
  } elsif ($_xml_module->is_pi($node)) {
    return 'pi';
  } elsif ($_xml_module->is_entity_reference($node)) {
    return 'entity_reference';
  } elsif ($_xml_module->is_document($node)) {
    return 'document';
  } elsif ($_xml_module->is_document_fragment($node)) {
    return 'chunk';
  } elsif ($_xml_module->is_comment($node)) {
    return 'comment';
  } elsif ($_xml_module->is_namespace($node)) {
    return 'namespace';
  } else {
    return 'unknown';
  }
}

#######################################################################
#######################################################################


  package XML::XSH2::Map;

BEGIN {
  import XML::XSH2::Functions ':param_vars';
  

  *fromUTF8 = *XML::XSH2::Functions::fromUTF8;
  *toUTF8 = *XML::XSH2::Functions::toUTF8;
}

sub call {
  XML::XSH2::Functions::call({},0,@_);
}

sub serialize {
  my $exp=$_[0];
  my $ql;
  if (ref($exp)) {
    if (UNIVERSAL::isa($exp,'XML::LibXML::NodeList')) {
      $ql=$exp;
    } elsif (UNIVERSAL::isa($exp,'XML::LibXML::Node')) {
      $ql=[$exp];
    } else {
      $ql=&XML::XSH2::Functions::_ev_nodelist($exp);
    }
  } else {
    $ql=&XML::XSH2::Functions::_ev_nodelist($exp);
  }
  my $result='';
  foreach (@$ql) {
    $result.=$_->toString();
  }
  return $result;
}

sub literal {
  my $xp=$_[0] || current();
  return XML::XSH2::Functions::to_literal(ref($xp) ? $xp : XML::XSH2::Functions::_ev($xp));
}

sub type {
  my ($xp)=@_;
  my $ql;
  unless (ref($xp)) {
    $xp='.' if $xp eq "";
    $ql = &XML::XSH2::Functions::_ev_nodelist($xp);
  } elsif (ref($xp) eq 'ARRAY' or 
	   UNIVERSAL::isa($xp,'XML::LibXML::NodeList')) {
    $ql = $xp;
  } else {
    $ql = [$xp];
  }
  my @result;
  foreach (@$ql) {
    push @result,&XML::XSH2::Functions::node_type($_);
    return $result[0] unless (wantarray);
  }
  return @result;
}

sub nodelist {
  return XML::LibXML::NodeList->new(map {
    XML::XSH2::Functions::cast_value_to_objects($_)
    } @_);
}

sub xpath {
  my ($exp, $node) = @_;
  $node = $node->[0] if (UNIVERSAL::isa($node,'XML::LibXML::NodeList'));
  my $r = $XML::XSH2::Functions::_xpc->find($exp,$node);
#  my $r = XML::XSH2::Functions::_ev($_[0]);
  if (wantarray and ref($r) and UNIVERSAL::isa($r,'XML::LibXML::NodeList')) {
    return @$r;
  } else {
    return $r;
  }
}

*echo = *XML::XSH2::Functions::out;

sub xsh {
  my ($p, $s, $l)=caller;
  local $XML::XSH2::Functions::SCRIPT="<xsh() called from $s line $l>";
  XML::XSH2::Functions::run_string(join "",XML::XSH2::Functions::cast_objects_to_values(@_));
}

sub current {
  return XML::XSH2::Functions::xsh_context_node();
}

sub position {
  if ($XML::XSH2::Functions::_xpc->can('getContextPosition')) {
    return $XML::XSH2::Functions::_xpc->getContextPosition();
  } else {
    die "Sorry, installed XML::LibXML::XPathContext version doesn't support proximity position\n";
  }
}

*count = *XML::XSH2::Functions::count_xpath;
*xml_list = *serialize;

sub resolve_uri {
  my ($rel,$base)=@_;
  if (defined $base) {
    return URI->new_abs($rel,URI->new($base)->abs(URI::file->cwd));
  } else {
    return URI->new_abs($rel,URI::file->cwd);
  }
}

#######################################################################
#######################################################################

  package XML::XSH2::Internal::Exception;

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

  package XML::XSH2::Internal::UncatchableException;
use vars qw(@ISA);
@ISA=qw(XML::XSH2::Internal::Exception);

  package XML::XSH2::Internal::LoopTerminatingException;
use vars qw(@ISA);
@ISA=qw(XML::XSH2::Internal::UncatchableException);

  package XML::XSH2::Internal::SubTerminatingException;
use vars qw(@ISA);
@ISA=qw(XML::XSH2::Internal::UncatchableException);


#######################################################################
#######################################################################

  package # hide from PAUSE
      XML::SAX::Writer::XMLEnc;
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


# taken from Variable::Alias
  package XML::XSH2::VarAlias;
use strict;
use warnings;
use Tie::Scalar;
use vars qw(@ISA);
@ISA=qw(Tie::StdScalar);

sub TIESCALAR {
  return bless $_[1], $_[0];
}

1;

