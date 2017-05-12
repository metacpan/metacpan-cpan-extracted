package XML::DocStats;

# this module produces a simple format of an XML document with statics
#
# Copyright (c) 2001-2002 Alan Dickey
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

use Object::_Initializer;
use XML::Parser::PerlSAX;

use vars qw($VERSION @ISA);

$VERSION = '0.01';

@ISA = qw(Object::_Initializer);

# Preloaded methods.
# new and _init inherited from Object::_Initializer

sub _defaults { # called by Object::_Initializer::new
    my ($self) = @_;
    my %defaults = qw(
format  html
output  print 
print_htmlpage yes
print_element  yes
print_text     yes
print_entity   yes
print_doctype  yes
print_xmldcl   yes
print_comment  yes
print_pi       yes
);
    $defaults{xmlsource} = {ByteStream => \*STDIN};
    $self->_init(%defaults);
}

sub analyze {
  my ($self, @params) = @_;

  my %params = (%{$self}, @params,);

  my $handler = MySaxHandler->new(%params);
  my $parser = XML::Parser::PerlSAX->new(Handler => $handler);

  my %parser_args = (Source => $self->xmlsource, UseAttributeOrder => 1);

  eval {$parser->parse(%parser_args)};

  if ($@) { # xml not well formed, get error message from XML::Parser 
    require XML::Parser;
    my $xml = $self->xmlsource->{ByteStream};
    $xml = $self->xmlsource->{String} unless $xml;
    $xml = $self->xmlsource->{SystemId} unless $xml;
    my $p1 = new XML::Parser(ErrorContext => 3);
    eval{$p1->parse($xml)};
    $handler->fatal_error($@);
  }
  return $handler->_output_buffer unless $params{output} eq 'print';
}

package MySaxHandler;

use vars qw(@ISA);

@ISA = qw(Object::_Initializer);

sub ok_print {
    my ($self,$item) = @_;
    $self->{"print_$item"} eq 'yes';
}

sub prnt {
    my ($self,@message) = @_;
    if ($self->output eq 'print') {print @message;}
    else {$self->{_output_buffer} .= join'',@message;}
}

sub fatal_error {
    my ($self,$message) = @_;
    $message =~ s{\<}{\&lt\;}g if $self->format eq 'html';
    $message =~ s{\>}{\&gt\;}g if $self->format eq 'html';
    $self->prnt($self->color('ERROR',$message));
    $self->end_document;
}

sub xml_decl {
    my ($self,$option) = @_;
    my @options = qw(Version Encoding Standalone);
    my @attrs;
    for my $opt (@options) {
        push @attrs,"$opt='".$option->{$opt}."'" if exists $option->{$opt};
    }
    $self->print($self->color('XML','XML-DCL: ').$self->color('ATTR'," @attrs\n")) if $self->ok_print('xmldcl');
    $self->stats('!XML-DCL');
}

sub doctype_decl {
    my ($self,$option) = @_;
    my @options = qw(Name SystemId PublicId Internal);
    my @attrs;
    for my $opt (@options) {
        push @attrs,"$opt='".$option->{$opt}."'" if $option->{$opt};
    }
    $self->print($self->color('DTD','DOCTYPE: ').$self->color('ATTR'," @attrs\n")) if $self->ok_print('doctype');
    $self->stats('!DOCTYPE');
}

sub start_document {
    my ($self) = @_;
    $self->_init(level=>0,chars=>{},element=>'',elestack=>[],STATS=>{});
    $self->_init(_output_buffer=>'') unless $self->output eq 'print';
    $self->stats('!BYTES',$self->{BYTES}) if exists $self->{BYTES};
    my $title = "Start parse of XML on ${\$self->_timeformat}";
    $self->prnt(<<HTML) if $self->ok_print('htmlpage') and ($self->format eq 'html');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$title</title>
<link rel="stylesheet" type="text/css" href="/includes/xmldump.css">
</head>
<body bgcolor="white">
HTML
    $self->prnt('<pre>') if $self->format eq 'html';
    $self->prnt($self->color('STATS',"$title\n"));
}

sub end_document {  
    my ($self) = @_;
    $self->printstats;
    $self->prnt($self->color('STATS',"Finish parse of XML on ${\$self->_timeformat}"));
    $self->prnt('</pre>') if $self->format eq 'html';
    $self->prnt(<<HTML) if $self->ok_print('htmlpage') and ($self->format eq 'html');
</body>
</html>
HTML
}

sub print {
    my ($self, @items) = @_;
    my $indent = '  ' x $self->level;
    $self->prnt($indent,@items);
}

sub trim {
    my ($self, $text) = @_;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return $text;
}

sub color {
    my ($self, $tag, $text) = @_;
    my %color = qw(element purple PI maroon TEXT blue COMMENT green ATTR olive XML teal DTD navy ERROR red STATS fuchsia ROOT fuchsia ENTITY fuchsia);
    return "<font color=\"$color{$tag}\">$text</font>" if $self->format eq 'html';
    return $text;
}

sub escape {
    my ($self, $text) = @_;
    return $text unless $self->format eq 'html';
    $text =~ s{\<}{\&lt\;}g;
    $text =~ s{\>}{\&gt\;}g;
    $text =~ s{\n}{\&nbsp\;}g;
    return $text;
}

sub start_element {
    my ($self, $element) = @_;
 
    push @{$self->elestack},$self->element if $self->element;
    $self->prnt($self->color('ROOT',"ROOT: ${\$element->{Name}}\n")) unless $self->element;
    $self->element($element->{Name});
    $self->print($self->color('element',$self->element)) if $self->ok_print('element');
    my $lev = $self->level;
    $self->level(++$lev);
    $self->chars->{$lev.$self->element}=undef;
    my @attrs;
    for my $attr (@{$element->{AttributeOrder}}) {
      $self->stats('@'.$attr);
      $self->stats('^'.$element->{Attributes}->{$attr});
      push @attrs,"$attr='".$element->{Attributes}->{$attr}."'";
      }
    $self->prnt($self->color('ATTR'," @attrs")) if @attrs and $self->ok_print('element');
    $self->stats('!ATTRIBUTE',scalar(@attrs)) if @attrs;
    $self->prnt("\n") if $self->ok_print('element');
    $self->stats($self->element);
    $self->stats('!ELEMENT');
}

sub entity_reference {
    my ($self, $entity) = @_;
    $self->stats('!ENTITY');
    $self->print($self->color('ENTITY','ENTITY: ')."'${\$entity->{Name}}'\n") if $self->ok_print('entity');
    $self->stats('&'.$entity->{Name});
}


sub characters {
    my ($self, $characters) = @_;
    my $text = $self->trim($characters->{Data});
    $self->chars->{$self->level.$self->element} .= $text;
    $text = $self->escape($text);
    $self->print($self->color('TEXT','TEXT: ').$self->color('element',$self->element)." '$text'\n") if $text and $self->ok_print('text');
    $self->stats('!TEXT') if $text;
}

sub end_element {
    my ($self, $element) = @_;
    my $lev = $self->level;
    $self->chars->{$lev.$self->element} = undef;
    $self->level(--$lev);
    $self->element(pop @{$self->elestack});
}

sub processing_instruction {
    my ($self, $pi) = @_;
    my $target = $pi->{Target};
    (my $data = $pi->{Data}) =~ s/\n//g;
    $data =~ s/\s+/ /g;
    my @attrs = ("Target='$target'","Data='$data'");
    $self->print($self->color('PI','PI: ').$self->color('element',$self->element).$self->color('ATTR'," @attrs\n")) if $self->ok_print('pi');
    $self->stats('!PI');
}

sub comment {
    my ($self, $comment) = @_;
    my $text = $self->trim($comment->{Data});
    $text = $self->escape($text);
    $self->print($self->color('COMMENT','COMMENT: ').$self->color('element',$self->element)." '$text'\n") if $self->ok_print('comment');
    $self->stats('!COMMENT');
}

sub stats {
    my ($self, $stat, $amount) = @_;
#    $stat = "!$stat"; # invalid element name
    $amount = 1 unless $amount;
    $self->STATS->{$stat} = exists $self->STATS->{$stat}?
        $amount+($self->STATS->{$stat}):
        $amount;
}

sub printstat {
    my ($self,$label,$quote,@keys) = @_;
    my @attrs;
    for my $attr (@keys) {
      (my $name = $attr) =~ s/^[!@^&]//;
      $name =~ s{\&}{&amp;}g;
      push @attrs,$self->STATS->{$attr}." $quote$name$quote";
      }
    $self->prnt($self->color('STATS',$label).$self->color('ATTR',join(', ',@attrs))) if @attrs;
    $self->prnt("\n");
}

sub printstats {
    my ($self) = @_;
    $self->prnt("\n");
    my @keys = sort keys %{$self->STATS};
    $self->printstat('TOTALS:     ','',grep {m/^!/} @keys);
    $self->printstat('ELEMENTS:   ','',grep {not m/^[!@^&]/} @keys);
    $self->printstat('ATTRIBUTES: ','',grep {m/^@/} @keys);
    $self->printstat('ATTRVALUES: ',"'",grep {m/^\^/} @keys);
    $self->printstat('ENTITIES:   ','',grep {m/^&/} @keys);
}

sub start_cdata {
    my ($self, $element) = @_;
    $self->stats('!CDATA');
}

1;
__END__

=head1 NAME

XML::DocStats - produce a simple analysis of an XML document

=head1 SYNOPSIS

Analyze the xml document on STDIN, the STDOUT output format is html:

    use XML::DocStats;
    my $parse = XML::DocStats->new;
    $parse->analyze;

Analyze in-memory xml document:

    use XML::DocStats;
    my ($xmldata) = @_;
    my $parse = XML::DocStats->new(xmlsource=>{String => $xmldata},
                                           BYTES => length($xmldata));
    $parse->analyze;

Analyze xml document IO stream, the output format is plain text:

    use XML::DocStats;
    use IO::File;
    my $xmlsource = IO::File->new("< document.xml");
    my $parse = XML::DocStats->new(xmlsource=>{ByteStream => $xmlsource});
    $parse->format('text');
    $parse->analyze;

=head1 DESCRIPTION

=over 4

XML::DocStats parses an xml document using a SAX handler built using Ken MacLeod's XML::Parser::PerlSAX. It produces a listing indented to show the element heirarchy, and collects counts of various xml components along the way. A summary of the counts is produced following the conclusion of the parse. This is useful to visualize the structure and content of an XML document. 

The output listing is either in plain text or html.

Each xml thingy is color-coded in the html output for easy reading:

=begin text

  - purple denotes elements.
  - blue denotes text (character data). The text itself is black.
  - olive denotes attributes and attribute values in elements, 
    XML-DCL, DOCTYPE, and PIs.
  - fuchsia denotes entity references. The name of the entity is 
    in black. fuchsia is also used to denote the root element, and 
    to mark the start and finish of the parse, as well as to label 
    the statistices at the end.
  - teal denotes the XML declaration.
  - navy denotes the DOCTYPE declaration.
  - maroon denotes processing instructions.
  - green denotes comments. The text of the comment is black.
  - red denotes error messages should the xml fail to be well-formed.

=end text

=over 4

=begin man

.Ve
\&\fBpurple\fR denotes elements.
.Sp
\&\fBblue\fR denotes text (character data). The text itself is black.
.Sp
\&\fBolive\fR denotes attributes and attribute values in elements, \s-1XML-DCL\s0, \s-1DOCTYPE\s0, and PIs.
.Sp
\&\fBfuchsia\fR denotes entity references. The name of the entity is in black. fuchsia is also used to denote the root element, and to mark the start and finish of the parse, as well as to label the statistices at the end.
.Sp
\&\fBteal\fR denotes the \s-1XML\s0 declaration.
.Sp
\&\fBnavy\fR denotes the \s-1DOCTYPE\s0 declaration.
.Sp
\&\fBmaroon\fR denotes processing instructions.
.Sp
\&\fBgreen\fR denotes comments. The text of the comment is black.
.Sp
\&\fBred\fR denotes error messages should the xml fail to be well-formed.
.Sp
.Vb 1

=end man

=begin html

<ul>
<li><font color="purple"><b>purple</b></font> denotes elements.</li>
<li><font color="blue"><b>blue</b></font> denotes text (character data). The text itself is black.</li>
<li><font color="olive"><b>olive</b></font> denotes attributes and attribute valuesin elements, XML-DCL, DOCTYPE, and PIs.</li>
<li><font color="fuchsia"><b>fuchsia</b></font> denotes entity references. The name of the entity is in black. <font color="fuchsia"><b>fuchsia</b></font> is also used to denote the root element, and to mark the start and finish of the parse, as well as to label the statistices at the end.</li>
<li><font color="teal"><b>teal</b></font> denotes the XML declaration.</li>
<li><font color="navy"><b>navy</b></font> denotes the DOCTYPE declaration.</li>
<li><font color="maroon"><b>maroon</b></font> denotes PIs (processing instructions).</li>
<li><font color="green"><b>green</b></font> denotes comments. The text of the comment is black.</li>
<li><font color="red"><b>red</b></font> denotes error messages should the xml fail to be well-formed.</li>
</ul>

=end html

=back

=back

=head1 METHODS

=head2 new

=over 4

Create a XML::DocStats. Parameters to control the input, output, and analysis format can
be passed to B<new>, to B<analyse>, or by invoking parameter methods. See below.

=back

=head2 analyze

=over 4

Parse the xml document and produce the analysis listing.

=back

=head2 parameter methods

=over 4

Parameters to control the input, output, and analysis format can
be passed to B<new>, to B<analyse>, or by invoking the parameter methods listed below, e.g. B<$parse-E<gt>param('value')>.
When passing parameters to B<new> or B<analyse>, the form B<$parse-E<gt>analyze(param=E<gt>'value')> is used.

=over 4

B<xmlsource> - values: the B<XML::Parser::PerlSAX Source>, default: {ByteStream => \*STDIN}. See L<XML::Parser::PerlSAX>.

B<format> - values: html/text, default: html. When B<format> is B<html>, the analysis listing is formatted in HTML; otherwise, plain text is produced.

B<output> - values: print/return, default: print. When B<outout> is B<print>, the analysis listing is printed to STDOUT incrementally as the parse progresses; otherwise, the listing is retured as a text string by B<analyze>.

B<print_htmlpage> - values: yes/no, default: yes. When B<print_htmlpage> is B<yes> and B<format> is B<html>, the analysis listing is formatted as a complete XHTML document. Otherwise, if B<format> is B<html>, only the HTML tags necessary to format the listing are included. 

The following parameters control whether the corresponding xml thingy is included in the analysis listing. Setting all B<print_E<lt>itemE<gt>>s to B<no> will produce just the summary statistics.

B<print_element> - values: yes/no, default: yes.

B<print_text> - values: yes/no, default: yes.

B<print_entity> - values: yes/no, default: yes.

B<print_doctype> - values: yes/no, default: yes.

B<print_xmldcl> - values: yes/no, default: yes.

B<print_comment> - values: yes/no, default: yes.

B<print_pi> - values: yes/no, default: yes.

=back

=back

=head1 EXAMPLES

An example command line script, B<xmldocstats.pl> is included in
the B<eg> directory of the distribution. After installation, you
can put this script in your PATH and use it to analyze an xml document:

    xmldocstats.pl mydoc.xml

or

    xmldocstats.pl < mydoc.xml | less

My web site has an online example, see: L<"WEB SITE">

=head1 AUTHOR

=for html
<a href="mailto:afdickey@intac.com">Alan Dickey &lt;afdickey@intac.com&gt;</a>

=for man
Alan Dickey \fI<afdickey@intac.com\fR>

=for text
Alan Dickey <afdickey@intac.com>

=head1 WEB SITE

A working example of B<XML::DocStats> can be found online at:

=for html
<a href="http://adickey.addr.com/xmldocstats">adickey.addr.com/xmldocstats</a>

=for man
\fIhttp://adickey.addr.com/xmldocstats\fR

=for text
http://adickey.addr.com/xmldocstats

=head1 SEE ALSO

L<XML::Parser::PerlSAX>, L<XML::Parser>, L<Object::_Initializer>.

=cut
