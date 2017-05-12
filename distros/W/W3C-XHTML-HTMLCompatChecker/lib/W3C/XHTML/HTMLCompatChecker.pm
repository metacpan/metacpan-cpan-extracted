package W3C::XHTML::HTMLCompatChecker;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;
sub Version { $VERSION; }

use XML::Parser;
use URI;
use LWP::UserAgent;

# Define global constants
use constant TRUE  => 1;
use constant FALSE => 0;


use constant APPC_FOUND_XML_DECL =>  1; # http://www.w3.org/TR/xhtml1/#C_1
use constant APPC_FOUND_XML_PI   =>  2; # http://www.w3.org/TR/xhtml1/#C_1
use constant APPC_MISSING_SPACE  =>  3; # http://www.w3.org/TR/xhtml1/#C_2
use constant APPC_UNMINIMIZED    =>  4; # http://www.w3.org/TR/xhtml1/#C_2
use constant APPC_MINIMIZED      =>  5; # http://www.w3.org/TR/xhtml1/#C_3
use constant APPC_MANY_ISINDEX   =>  6; # http://www.w3.org/TR/xhtml1/#C_6
use constant APPC_ONLY_LANG      =>  7; # http://www.w3.org/TR/xhtml1/#C_7
use constant APPC_ONLY_XML_LANG  =>  8; # http://www.w3.org/TR/xhtml1/#C_7
use constant APPC_APOS_IN_ATTR   =>  9; # http://www.w3.org/TR/xhtml1/#C_16
use constant APPC_APOS_IN_ELEM   => 10; # http://www.w3.org/TR/xhtml1/#C_16

use constant APPC_ERRO => 0; # @@
use constant APPC_WARN => 1; # @@
use constant APPC_INFO => 2; # @@
use constant APPC_HINT => 3; # @@

use constant SEVERITY_NAMES =>
{
    APPC_ERRO, "Error",
    APPC_WARN, "Warning",
    APPC_INFO, "Info",
    APPC_HINT, "Hint",
};

use constant CRITERIA =>
{
    APPC_FOUND_XML_DECL,    [ 1, APPC_INFO, "XML declarations are problematic"                                              ],
    APPC_FOUND_XML_PI,      [ 1, APPC_INFO, "XML processing instructions are problematic"                                   ],
    APPC_MISSING_SPACE,     [ 2, APPC_ERRO, "<example/> shall be written as <example />"                                    ],
    APPC_UNMINIMIZED,       [ 2, APPC_ERRO, "For empty elements you shall use <example />"                                  ],
    APPC_MINIMIZED,         [ 3, APPC_ERRO, "For non-empty elements, you shall use <example></example>"                     ],
    APPC_ONLY_LANG,         [ 7, APPC_ERRO, "<example lang='en'> shall be written as <example lang='en' xml:lang='en'>"     ],
    APPC_ONLY_XML_LANG,     [ 7, APPC_ERRO, "<example xml:lang='en'> shall be written as <example lang='en' xml:lang='en'>" ],
    APPC_MANY_ISINDEX,      [10, APPC_WARN, "Avoid more than one <isindex> element in the <head> element"                   ],
    APPC_APOS_IN_ATTR,      [16, APPC_ERRO, "You must write &apos; as e.g. &#39; for legacy user agents"                    ],
    APPC_APOS_IN_ELEM,      [16, APPC_ERRO, "You must write &apos; as e.g. &#39; for legacy user agents"                    ],
};

use constant GUIDELINE_TITLES =>
{
    1, "Processing Instructions and the XML Declaration",
    2, "Empty Elements",
    3, "Element Minimization and Empty Element Content",
    6, "Isindex",
    7, "The lang and xml:lang Attributes",
    16, "The Named Character Reference &apos;",
};

use constant EMPTY_ELEMENTS => { map { $_ => 1 }
qw/
    base basefont link area hr img
    meta param input isindex col br
/ };

# global variables...
our $ISINDEX = 0;
our $IS_RELEVANT_DOC = 1; # whether the checker is relevant to the doctype of the document being processed.
our $IS_RELEVANT_CT = 1; # whether the checker is relevant to the media type of the document being processed.
our $IS_WF = 1; # whether the document is at least well-formed XML
our @MESSAGES;


###########################
# usual package interface #
###########################
sub new
{
        my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;
        bless($self, $class);        
        return $self;
}




## Helper functions #######################################################
sub is_empty_element   { EMPTY_ELEMENTS->{shift()} }
sub is_isindex_element { shift eq "isindex" }
sub is_inside_head     { shift->within_element("head") }

sub report_problem
{
    my $exp = shift;
    my $cod = shift;
    my $loc = shift;

    my $str = $exp->recognized_string;
    my $lin = $exp->current_line;
    my $col = $exp->current_column;
    my $off = $exp->current_byte;
    
    # determine position after skipping $loc, e.g. if there is
    #
    #   <p lang     = "de"
    #      xml:lang = "de"
    #      class    = "a b c d e f g"
    #      id       = "example"/>
    #
    # the error is the / and it would be unhelpful to point at
    # the < as expat would do in this case.
    
    my $left = substr $str, 0, $loc;
    my $lines = $left =~ y/\n//; # @@ does \n always work?
    $left =~ s/^.*\n//s;         # @@ does \n always work?
    my $chars = length $left;
    
    # set new positions
    my $posy = $lin + $lines;                   # advance pointer
    my $posx = $lines ? $chars : $col + $chars; # advance or replace
    my $posxy = $off + $loc;                    # advance pointer

    my $stext = SEVERITY_NAMES->{CRITERIA->{$cod}->[1]};
    my $mtext = CRITERIA->{$cod}->[2];
    my $cnum  = CRITERIA->{$cod}->[0];
    my $gtitle = GUIDELINE_TITLES->{$cnum};

	push @MESSAGES, {severity => $stext, line => $posy, column => $posx + 1, cnum => $cnum, message_text => $mtext, guideline_title => $gtitle}
   
}


## Pre-Parsing routines ###################################################
# make sure we are actually handling XHTML 1.0 documents served as text/html
# some code taken from W3C Markup Validator Codebase

sub parse_content_type {
    my $Content_Type = shift;
    my ($ct, @others) = split /\s*;\s*/, lc $Content_Type;
    #print p($ct);
    if ($ct ne "text/html") {
            $IS_RELEVANT_CT = 0;
    } 
    return $ct;
}


## Handler for XML::Parser ################################################

sub _start
{
    my $exp = shift;
    my $ele = shift;
    my %att = @_;
    my $str = $exp->recognized_string;
    my $lin = $exp->current_line;
    my $col = $exp->current_column;
    my $off = $exp->current_byte;
    my $end = length($str) - 1;
    
    # check for multiple isindex elements
    if (is_isindex_element($ele) and
        is_inside_head($exp) and
        $ISINDEX++)
    {
        report_problem($exp, APPC_MANY_ISINDEX, 0);
    }
    
    if ($str =~ m|/>$|)
    {
        # check for preceding space in empty element tag
        if ($str !~ m|[ \x0d\x0a\t]/>$|)
        {
            report_problem($exp, APPC_MISSING_SPACE, $end - 1);
        }
        
        # check that empty element tags are used only for
        # elements declared as EMPTY in the DTD
        if (!is_empty_element($ele))
        {
            report_problem($exp, APPC_MINIMIZED, $end - 1);
        }
    }
    
    # check that elements declared as EMPTY use empty element tags
    if (is_empty_element($ele))
    {
        if ($str !~ m|/>$|)
        {
            report_problem($exp, APPC_UNMINIMIZED, $end);
        }
    }
    
    # check for &apos; in attribute values
    if ($str =~ m|&apos;|)
    {
        local $_ = $str;
        my $len = 0;
        
        while(s/^(.*?)&apos;//)
        {
            $len += length $1;
            report_problem($exp, APPC_APOS_IN_ATTR, $len);
            
        }
    }
    
    # check for <p lang="de">...</p>
    if (exists $att{'lang'} && not exists $att{'xml:lang'})
    {
        report_problem($exp, APPC_ONLY_LANG, $end);
    }
    
    # check for <p xml:lang="de">...</p>
    if (exists $att{'xml:lang'} && not exists $att{'lang'})
    {
        report_problem($exp, APPC_ONLY_XML_LANG, $end);
    }
}

sub _char
{
    my $exp = shift;
    my $txt = shift;
    my $str = $exp->recognized_string;
    my $lin = $exp->current_line;
    my $col = $exp->current_column;
    my $off = $exp->current_byte;
    
    # check for &apos; in parsed character data
    if ($str =~ /&apos;/)
    {
        local $_ = $str;
        my $len = 0;
        
        while(s/^(.*?)&apos;//)
        {
            $len += length $1;
            report_problem($exp, APPC_APOS_IN_ELEM, $len);
            
        }
    }
}

sub _proc
{
    # check for XML processing instructions
    report_problem(shift, APPC_FOUND_XML_PI, 0);
}

sub _xmldecl
{
    # check for XML declaration
    report_problem(shift, APPC_FOUND_XML_DECL, 0);
}

sub _doctype
{
    my $exp = shift;
    my $doctypename = shift;
    my $doctypesys = shift;
    my $doctypepub = shift;
    my $doctypeint = shift;
    if (defined $doctypename) {
            $IS_RELEVANT_DOC = 0 if ($doctypename ne "html");
    }
    if(defined $doctypesys) {
            $_ = $doctypesys;
            $IS_RELEVANT_DOC = 0 if (not /http:\/\/www.w3.org\/.*\/xhtml.*.dtd/);
            #$IS_RELEVANT_DOC = 0 if (not /http:\/\/www.w3.org\/.*\/xhtml1\/DTD\/xhtml1-(strict|transitional|frameset).dtd/);
    }
    if (defined $doctypepub) {
            $_ = $doctypepub;
            $IS_RELEVANT_DOC = 0 if (not /-\/\/W3C\/\/DTD XHTML .*\/\/EN/);
            # we choose to accept checking any XHTML - could be stricter and only check for XHTML 1.0 
            #$IS_RELEVANT_DOC = 0 if (not /-\/\/W3C\/\/DTD XHTML 1.0 (Strict|Transitional|Frameset)\/\/EN/);
    }
    if (defined $doctypeint) # there should be no internal subset
    { 
           $IS_RELEVANT_DOC = 0 if (length  $doctypeint);
    }
    $IS_RELEVANT_DOC = 0 if ((not defined $doctypesys) and (not defined $doctypepub)); # should not happen with XHTML 1.0
}



## Main ###################################################################

sub check_uri {
    my $self = shift;
	my $uri = shift;
	my $any_xhtml = 0; # by default, only check XHTML 1.0 docs served as text/html
	my @local_messages;
	if (@_) {
	    my @anyxhtmlarry = @_;
	    if (int (@anyxhtmlarry) eq 2)
        {
            my $any_xhtml_varname=shift;
            $any_xhtml = shift;
    	    if ($any_xhtml ne "1") {$any_xhtml = 0}
        }	    
    }
	
    # body...
    my @messages;

    if (defined $uri and length $uri and URI->new($uri)->scheme eq "http")
    {
         my $ua = LWP::UserAgent->new;
         my $response = $ua->get($uri);
         my $xml = undef;
         my $ct = undef;
         my @content_type_values = undef;
         if ($response->is_success) {
             $xml =  $response->content;
             @content_type_values = $response->header('Content-Type');
             $ct = $content_type_values[0];
             @messages = $self->check_content($xml);
        }
        if (defined $ct and length $ct) {
            $ct = &parse_content_type($ct);
        }
        if ($IS_RELEVANT_CT eq 0 and $any_xhtml eq 0) {
            push @local_messages, {severity => "Abort", message_text => "not text/html"}; 
            return @local_messages;           
        }
    }
    else {
        push @local_messages, {severity => "Abort", message_text => "Bad URI"}; 
        return @local_messages;          
    }
    return @messages;
}

sub check_content {
    my $self = shift;
	my $xml = shift;
	my $any_xhtml = 0; # by default, only check XHTML 1.0 docs
	my @local_messages;
	
	if (@_) {
	    my @anyxhtmlarry = @_;
	    if (int (@anyxhtmlarry) eq 2)
        {
            my $any_xhtml_varname=shift;
            $any_xhtml = shift;
    	    if ($any_xhtml ne "1") {$any_xhtml = 0}
        }	    
    }
	        
    if (defined $xml and length $xml)
    {
        my $p = XML::Parser->new;
        $p->setHandlers(Doctype => \&_doctype);
        
        eval { $p->parsestring($xml); };
        #$output->param(is_relevant_ct => $IS_RELEVANT_CT);
        #$output->param(is_relevant_doctype => $IS_RELEVANT_DOC);

        if ($@) # not well-formed
        {
                $IS_WF = 0;
                my $wf_errors = join '', $@;
                push @local_messages, {severity => "Abort", message_text => "Content is not well-formed XML"}; 
                return @local_messages;          
                #$output->param(info_count => 1);
                #$output->param(wf_errors => $wf_errors);      
        }
        elsif (not $IS_RELEVANT_DOC)
        {
            if ($any_xhtml){
                push @local_messages, {severity => "Abort", message_text => "Content is not XHTML"}; 
            }
            else {
                push @local_messages, {severity => "Abort", message_text => "Content is not XHTML 1.0"}; 
                
            }
            return @local_messages;          
            
        }
        else # woot, Well-formed, and relevant. Let's get to work.
        {
            my $p = XML::Parser->new;
            $p->setHandlers(Char    => \&_char,
                        Proc    => \&_proc,
                        Start   => \&_start,
                        XMLDecl => \&_xmldecl);       
            eval { $p->parsestring($xml); };
            return @MESSAGES;
        }
    }
    else {
        return -1;
    }
}


package W3C::XHTML::HTMLCompatChecker;
1;


__END__


=head1 NAME

W3C::XHTML::HTMLCompatChecker - The W3C XHTML/HTML Compatibility Checker

Checks XHTML documents (online or local) for compatibility with legacy HTML User-Agents.

=head1 DESCRIPTION

C<W3C::XHTML::HTMLCompatChecker> can be used to check whether some content written in XHTML 
can safely be served as HTML (C<text/html>) to User-Agents that can process HTML, but not XML.

This checker follows the guidelines for compatibility found in the XHTML 1.0 Specification, 
for XHTML 1.0 content served "as HTML" (i.e with the media type C<text/html>).
L<http://www.w3.org/TR/xhtml1/#guidelines>

This checker also has a "any xhtml" mode, where any XHTML document, regardless of its media type, will be checked. 

=head1 SYNOPSIS

    use W3C::XHTML::HTMLCompatChecker;
    my $checker = W3C::XHTML::HTMLCompatChecker->new();
    my @messages = $checker->check_uri("http://...  ");

=head1 API

=head2 Constructor

    $checker = W3C::XHTML::HTMLCompatChecker->new


=head2 Checker Methods

    $checker->check_uri("http://...  ")

Check an online XHTML 1.0 document, served as "text/html" media type, for incompatibilities with legacy HTML. 

  
    $checker->check_uri("http://...  ", any_xhtml=>1)

Check any online XHTML document, regardless of doctype and media type for incompatibilities with legacy HTML. 

  
    $checker->check_content("<!DOCTYPE html ...")

Check an XHTML 1.0 document (as string), for incompatibilities with legacy HTML. 
 
    $checker->check_content("<!DOCTYPE html ...", any_xhtml=>1)

Check any XHTML document (as string), for incompatibilities with legacy HTML. 


=head3 Returned Messages

The checker will return an array of hashes, each hash representing an error/warning/info, as follows:

=over 4

=item severity

Severity of message: Error, Warning, Info, Hint or Abort

=item line 

line where observation was made 

(may be undefined for Abort messages)

=item column 

column/offset where observation was made

(may be undefined for Abort messages)

=item message_text 

Explanation of the message

=item cnum

Identifier for the relevant compatibility guideline 

Example: 
 1 is L<http://www.w3.org/TR/xhtml1/#C_1>

=item guideline_title 

Title of the relevant guideline

Example:
 Element Minimization and Empty Element Content 


=back


=head3 Abort causes

B<If the C<any_xhtml> parameter is not set>, the checker will return a single I<Abort> message if:

=over 4

=item *

the document is not served as C<text/html> (N/A for C<check_content>), or

=item *

the document is not identifiable as XHTML 1.0, or 

=item *

the document is not well-formed XML

=back

B<If the C<any_xhtml> parameter is set>, the checker will return a single I<Abort> message if the document is not well-formed XML.


=head1 BUGS

Public bug-tracking interface at http://www.w3.org/Bugs/Public/

=head1 AUTHOR

Developed as one of the Open Source projects at The World Wide Web Consortium
L<http://www.w3.org/Status>

Based on original code donated by Björn Höhrmann.