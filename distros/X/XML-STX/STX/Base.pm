package XML::STX::Base;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict ('refs', 'subs');
use vars qw(@EXPORT);
use XML::STX::Writer;
use XML::SAX::PurePerl;
require Exporter;
@XML::STX::Base::ISA = qw(Exporter);

# --------------------------------------------------
# common constants
# --------------------------------------------------
@EXPORT = qw( STX_ELEMENT_NODE 
	      STX_TEXT_NODE
	      STX_CDATA_NODE
	      STX_PI_NODE
	      STX_COMMENT_NODE
	      STX_ATTRIBUTE_NODE
	      STX_ROOT_NODE

              STX_NODE
              STX_BOOLEAN
              STX_NUMBER
              STX_STRING

	      STX_NS_URI
	      STX_FNS_URI
	      STX_VERSION
	      XMLNS_URI

              STXE_START_DOCUMENT
	      STXE_END_DOCUMENT
	      STXE_START_ELEMENT
	      STXE_END_ELEMENT
	      STXE_CHARACTERS
	      STXE_PI
	      STXE_START_CDATA
	      STXE_END_CDATA
	      STXE_COMMENT
	      STXE_START_BUFFER
	      STXE_END_BUFFER
	      STXE_START_PREF
	      STXE_END_PREF

	      I_LITERAL_START
	      I_LITERAL_END
	      I_ELEMENT_START
	      I_ELEMENT_END
	      I_P_CHILDREN_START
	      I_P_CHILDREN_END
	      I_P_SIBLINGS_START
	      I_P_SIBLINGS_END
	      I_P_SELF_START
	      I_P_SELF_END
	      I_P_BUFFER_START
	      I_P_BUFFER_END
	      I_P_DOC_START
	      I_P_DOC_END
	      I_P_ATTRIBUTES_START
	      I_P_ATTRIBUTES_END
              I_CALL_PROCEDURE_START
              I_CALL_PROCEDURE_END
	      I_CHARACTERS
	      I_COPY_START
	      I_COPY_END
              I_ATTRIBUTE_START
	      I_ATTRIBUTE_END
	      I_CDATA_START
	      I_CDATA_END
	      I_COMMENT_START
	      I_COMMENT_END
	      I_PI_START
	      I_PI_END
	      
	      I_IF_START
	      I_IF_END
	      I_VARIABLE_START
	      I_VARIABLE_END
	      I_VARIABLE_SCOPE_END
	      I_ASSIGN_START
	      I_ASSIGN_END
	      I_ELSE_START
	      I_ELSE_END
	      I_ELSIF_START
	      I_ELSIF_END
              I_BUFFER_START
              I_BUFFER_END
              I_BUFFER_SCOPE_END
              I_RES_BUFFER_START
              I_RES_BUFFER_END
              I_RES_DOC_START
              I_RES_DOC_END
	      I_WITH_PARAM_START
	      I_WITH_PARAM_END
	      I_PARAMETER_START
              I_FOR_EACH_ITEM
              I_WHILE

	      $NCName
	      $QName
	      $NCWild
	      $QNWild
	      $NODE_TYPE
	      $NUMBER_RE
	      $DOUBLE_RE
	      $LITERAL
              $URIREF
	    );

# node types
sub STX_ELEMENT_NODE(){1;}
sub STX_TEXT_NODE(){2;}
sub STX_CDATA_NODE(){3;}
sub STX_PI_NODE(){4;}
sub STX_COMMENT_NODE(){5;}
sub STX_ATTRIBUTE_NODE(){6;}
sub STX_ROOT_NODE(){7;}

# atomic data types
sub STX_NODE(){1;}
sub STX_BOOLEAN(){2;}
sub STX_NUMBER() {3;}
sub STX_STRING() {4;}

# STX constants
sub STX_NS_URI() {'http://stx.sourceforge.net/2002/ns'};
sub STX_FNS_URI() {'http://stx.sourceforge.net/2003/functions'};
sub STX_VERSION() {'1.0'};
sub XMLNS_URI() {'http://www.w3.org/2000/xmlns/'};

# events
sub STXE_START_DOCUMENT(){1;}
sub STXE_END_DOCUMENT(){2;}
sub STXE_START_ELEMENT(){3;}
sub STXE_END_ELEMENT(){4;}
sub STXE_CHARACTERS(){5;}
sub STXE_PI(){6;}
sub STXE_START_CDATA(){7;}
sub STXE_END_CDATA(){8;}
sub STXE_COMMENT(){9;}
sub STXE_START_BUFFER(){10;}
sub STXE_END_BUFFER(){11;}
sub STXE_START_PREF(){12;}
sub STXE_END_PREF(){13;}

# instructions
sub I_LITERAL_START(){1;}
sub I_LITERAL_END(){2;}
sub I_ELEMENT_START(){3;}
sub I_ELEMENT_END(){4;}
sub I_P_CHILDREN_START(){5;}
sub I_P_CHILDREN_END(){6;}
sub I_CHARACTERS(){7;}
sub I_COPY_START(){8;}
sub I_COPY_END(){9;}
sub I_ATTRIBUTE_START(){10;}
sub I_ATTRIBUTE_END(){11;}
sub I_CDATA_START(){12;}
sub I_CDATA_END(){13;}
sub I_COMMENT_START(){14;}
sub I_COMMENT_END(){15;}
sub I_PI_START(){16;}
sub I_PI_END(){17;}
sub I_P_SELF_START(){18;}
sub I_P_SELF_END(){19;}
sub I_P_ATTRIBUTES_START(){20;}
sub I_P_ATTRIBUTES_END(){21;}
sub I_CALL_PROCEDURE_START(){22;}
sub I_CALL_PROCEDURE_END(){23;}
sub I_P_BUFFER_START(){24;}
sub I_P_BUFFER_END(){25;}
sub I_P_DOC_START(){26;}
sub I_P_DOC_END(){27;}
sub I_P_SIBLINGS_START(){28;}
sub I_P_SIBLINGS_END(){29;}

sub I_IF_START(){101;}
sub I_IF_END(){102;}
sub I_VARIABLE_START(){103;}
sub I_VARIABLE_END(){104;}
sub I_VARIABLE_SCOPE_END(){105;}
sub I_ASSIGN_START(){106;}
sub I_ASSIGN_END(){107;}
sub I_ELSE_START(){108;}
sub I_ELSE_END(){109;}
sub I_ELSIF_START(){110;}
sub I_ELSIF_END(){111;}
sub I_BUFFER_START(){112;}
sub I_BUFFER_END(){113;}
sub I_BUFFER_SCOPE_END(){114;}
sub I_RES_BUFFER_START(){115;}
sub I_RES_BUFFER_END(){116;}
sub I_WITH_PARAM_START(){117;}
sub I_WITH_PARAM_END(){118;}
sub I_PARAMETER_START(){119;}
sub I_RES_DOC_START(){120;}
sub I_RES_DOC_END(){121;}
sub I_FOR_EACH_ITEM(){122};
sub I_WHILE(){123};

# tokens
$NCName = '[A-Za-z_][\w\\.\\-]*';
$QName = "($NCName:)?$NCName";
$NCWild = "${NCName}:\\*|\\*:${NCName}";
$QNWild = "\\*";
$NODE_TYPE = '((text|comment|processing-instruction|node|cdata)\\(\\))';
$NUMBER_RE = '\d+(\\.\d*)?|\\.\d+';
$DOUBLE_RE = '\d+(\\.\d*)?[eE][+-]?\d+';
$LITERAL = '\\"[^\\"]*\\"|\\\'[^\\\']*\\\'';
$URIREF = '[a-z][\w\;\/\?\:\@\&\=\+\$\,\-\_\.\!\~\*\'\(\)\%]+';

# --------------------------------------------------
# error processing
# --------------------------------------------------

sub doError {
    my ($self, $no, $sev, @params) = @_;
    my ($pkg, $file, $line, $sub) = caller(1);

    my %severity = ( 1 => 'Warning', 
		     2 => 'Recoverable Error', 
		     3 => 'Fatal Error' );

    my $orig;
    if ($no == 1)      { $orig = 'STXPath Tokenizer'   } 
    elsif ($no < 100)  { $orig = 'STXPath Evaluator'    }
    elsif ($no < 200)  { $orig = 'STXPath Function'    }
    elsif ($no < 500)  { $orig = 'Stylesheet Parser' }
    elsif ($no < 1000) { $orig = 'Runtime Engine'  }
    else               { $orig = 'XML Parser'}

    my $msg = $self->_err_msg($no, @params);

    my $txt = "[XML::STX $severity{$sev} $no] $orig: $msg!\n";

    if (exists $self->{locator}) {
	$txt .= "URI: $self->{locator}->{SystemId}, ";
	$txt .= "LINE: $self->{locator}->{LineNumber}\n";
    }

    if ($self->{DBG} or (exists $self->{STX} and $self->{STX}->{DBG})) {
	$txt .= "DEBUG INFO: subroutine: $sub, line: $line\n"
    }

    my $eL = exists $self->{STX} ? $self->{STX}->{ErrorListener}
      : $self->{ErrorListener};

    if ($sev == 1) {
	$eL->warning({Message => $txt, Exception => $no});

    } elsif ($sev == 2) {
	$eL->error({Message => $txt, Exception => $no});

    } else {
	$eL->fatal_error({Message => $txt, Exception => $no});
    }
}

sub set_document_locator {
    my ($self, $locator) = @_;
    
    $self->{locator} = $locator;
}

sub _err_msg {
    my $self = shift;
    my $no = shift;
    my @params = @_;

    my %msg = (

	# STXPath engine       
	1 => "Invalid query:\n_P\n_P^^^",
	2 => "_P expression failed to parse - junk after end: _P",
	3 => "Invalid parenthesized expression: _P not expected",
	4 => "Error in expression - //..",
	5 => "Error in expression - .._P",
	6 => "Error in expression - _P not expected",
	7 => "Incorrect match pattern: [ expected instead of _P",
	8 => "Unknown kind-test - something is wrong",
	9 => "Predicate not terminated: ] expected instead of _P",
	10 => "Prefix _P not bound",
	11 => "Conversion of _P to number failed: NaN",
	12 => "Function _P not supported",
	13 => "( expected after function name (_P), _P found instead",
	14 => ", or ) expected after function argument (_P), _P found instead",
	15 => "Incorrect number (_P) of arguments; _P() has _P arguments",
	16 => "Variable _P not visible",
	17 => "Namespace nodes can only be associated with elements, _P found",
	18 => "Collation _P is ignored in _P() function",

	# STXPath functions
        101 => "Unknown data type: _P",
        102 => "String value not defined for _P nodes",
        103 => "Unknown node type: _P",
        104 => "Empty sequence can't be converted to _P",
        105 => "_P() function requires a _P argument (_P passed)",
        106 => "Invalid position: item _P requested from sequence of _P items",
        107 => "Invalid position: item _P requested. Indexes start from 1",
        108 => "Invalid argument to _P() function: _P",
        109 => "Invalid string-pad count: _P",

	# Stylesheet parser
        201 => "Chunk after the end of document element",
        202 => "_P not allowed as document element (use <stx:transform>)",
        203 => "Only one instance of <_P> is allowed in stylesheet",
        204 => "visibility=\"_P\" (must be 'local', 'group' or 'global')",
        205 => "_P=\"_P\" (must be either 'yes' or 'no')",
        206 => "pass-through=\"_P\" (must be 'none','all' or 'text')",
        207 => "stx:attribute must be preceded by element start (i_P found)",
        208 => "_P instructions must not be nested",
        209 => "_P instruction not supported",
        210 => "_P - literal elements must be NS qualified outside templates",
        211 => "_P _P is redeclared in the same scope",
        212 => "_P must contain the _P mandatory attribute",
        213 => "_P attribute of _P can't contain {...}",
        214 => "_P attribute of _P must be _P",
        215 => "_P not allowed at this point (as child of _P)",
        216 => "Static evaluation failed, _P requires a context",
        217 => "Value of _P attribute (_P) must be _P",
        218 => "_P must follow immediately behind _P (found behind i_P)",
        219 => "Duplicate name of _P: _P",
        220 => "Duplicate name of procedure _P in precedence category _P",
        221 => "Prefix _P used in _P not declared",
        222 => "Test expression for <stx:while> contains no variable (_P)",

	# Runtime
        501 => "Prefix in <stx:element name=\"_P\"> not declared",
        502 => "_P attribute of _P must evaluate to _P (_P)",
        503 => "Output not well-formed: </_P> expected instead of </_P>",
        504 => "Output not well-formed: </_P> found after end of document",
        505 => "Assignment failed: _P _P not declared in this scope",
        506 => "Position not defined for attributes, 1 returned",
        507 => "Group named '_P' not defined",
        508 => "Called procedure _P not visible",
        509 => "_P is not valid _P for TrAX API",
        510 => "Required parameter _P hasn't been supplied",
	);

    my $msg = $msg{$no};
    foreach (@params) {	$msg =~ s/_P/$_/; }
    return $msg;
}

# --------------------------------------------------
# utils
# --------------------------------------------------

sub _type($) {
    my ($self, $seq) = @_;
    my $type = 'unknown';

    if ($seq->[0]) {
	if ($seq->[0]->[1] == STX_STRING) {$type = 'string'}
	elsif ($seq->[0]->[1] == STX_BOOLEAN) {$type = 'boolean'}
	elsif ($seq->[0]->[1] == STX_NUMBER) {$type = 'number'}
	elsif ($seq->[0]->[1] == STX_NODE) {
	    $type = 'node';
	    if ($seq->[0]->[0]->{Type} == STX_ELEMENT_NODE) {
		$type .= '-element';
	    } elsif ($seq->[0]->[0]->{Type} == STX_ATTRIBUTE_NODE) {
		$type .= '-attribute';
	    } elsif ($seq->[0]->[0]->{Type} == STX_TEXT_NODE) {
		$type .= '-text';
	    } elsif ($seq->[0]->[0]->{Type} == STX_CDATA_NODE) {
		$type .= '-cdata';
	    } elsif ($seq->[0]->[0]->{Type} == STX_PI_NODE) {
		$type .= '-processing-instruction';
	    } elsif ($seq->[0]->[0]->{Type} == STX_COMMENT_NODE) {
		$type .= '-comment';
	    } else {
		$type .= '-root';
	    }
	}

    } else {
	$type = 'empty sequence';	
    }
    return $type;
}

sub _counter_key($) {
    my ($self, $tok) = @_;

    $tok =~ s/^node\(\)$/\/node/ 
      or $tok =~ s/^text\(\)$/\/text/ 
	or $tok =~ s/^cdata\(\)$/\/cdata/ 
	  or $tok =~ s/^comment\(\)$/\/comment/
	    or $tok =~ s/^processing-instruction\(\)$/\/pi/ 
	      or $tok =~ s/^processing-instruction:(.*)$/\/pi:$1/ 
		or $tok = index($tok, ':') > 0 ? $tok : ':' . $tok;
    $tok =~ s/\*/\/star/;

    return $tok;
}

sub _to_sequence {
    my ($self, $value) = @_;

    if ($value =~ /^($NUMBER_RE|$DOUBLE_RE)$/) {
	return [[$1, STX_NUMBER]]

    } else {
	return [[$value, STX_STRING]];
    }
}

1;
__END__

=head1 XML::STX::Base

XML::STX::Base - basic definitions for XML::STX

=head1 SYNOPSIS

no API

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut


