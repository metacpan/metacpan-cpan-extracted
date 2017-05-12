package XML::FXN;
# Copyright Jerzy Wachowiak 2005
# Fast XML Notation

use strict;
use warnings;

require Exporter;
        use vars qw( @ISA @EXPORT $VERSION );
        @ISA =qw( Exporter );
        @EXPORT =qw( xml2fxn fxn2xml );
        $VERSION = '0.01';

sub xml2fxn {
    
    my $line = shift;
    
    # Some definitions from the XML standard...
    my $S = "[ \\n\\t\\r]+";
    my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
    my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
    my $Name = "(?:$NameStrt)(?:$NameChar)*";
    my $EndTagCE = "$Name(?:$S)?";
    my $AttValSE = "\"[^<\"]*\"|'[^<']*'";
    my $TextSE = "(?:[^<]+)*";     

    my @string = split( //, $line );
    
    my( $char1 , $char2, $buffer, $output ); 
    $output = $buffer = $char1 = $char2 = '';
    my $IsSetDoctypedecl = 0;
    my $IsSetComment = 0;

    foreach $char2 ( @string ){
        
        $buffer .= $char1;
    
                
        if(  "$char1$char2" =~ m/[?%]>/ ){
            $buffer .= $char2;
            $output .= $buffer;
            $char1 = '';
            $buffer = '';
            next
        }
        
        if( "$buffer$char2" =~ m/-->$/ ){
            $buffer .= $char2;
            $output .= $buffer;
            $char1 = '';
            $buffer = '';
            $IsSetComment = 0;
            next
        }
        
        if( $IsSetComment ){
            $char1 = $char2;
            next
        } 
    
        if( $IsSetDoctypedecl and $char2 =~ m/>/ ){
            $buffer .= $char2;
            $output .= $buffer;
            $char1 = '';
            $buffer = '';
            $IsSetDoctypedecl = 0;
            next
        } 
           
        if( "$buffer$char2" =~ m/<!$/ ){
            $char1 = $char2;
            $IsSetDoctypedecl = 1;           
            next
        }
    
        if( "$buffer$char2" =~ m/<!--$/ ){
            $char1 = $char2;
            $IsSetDoctypedecl = 0;
            $IsSetComment = 1; 
            next
        }
        
        if(  "$char1$char2" eq '/>'){
            $buffer =~ 
              s/($TextSE)<($Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?)\//trim( $1, $2,'<>' )/eg;
            $output .= $buffer;
            $char1 = '';
            $buffer = ''; 
            next
        }    
    
        if( $char2 eq '>' ){
            $buffer =~ s/<\/$EndTagCE/>/g;
            $buffer =~ 
              s/($TextSE)<($Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?)/trim( $1, $2, '<' )/eg;
            $output .= $buffer;
            $char1 = '';
            $buffer = '';
            next
        }
    
       $char1 = $char2 
    }
    $output .= $buffer.$char1;
    return $output
}

sub trim {
    
    my $string1 = shift;
    my $string2 = shift;
    my $the_end = shift;
    
    if ( $string1 =~ m/\w+/ ){ return "$string1 $string2$the_end" } 
    else { return "$string1$string2$the_end" }      
}   

sub fxn2xml {
    
    my $line = shift;
    
    # Some definitions from the XML standard...
    my $S = "[ \\n\\t\\r]+";
    my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
    my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
    my $Name = "(?:$NameStrt)(?:$NameChar)*";
    my $EndTagCE = "$Name(?:$S)?";
    my $AttValSE = "\"[^<\"]*\"|'[^<']*'";
    my $TextSE = "(?:[^<]+)*"; 
    
    my @string = split( //, $line );    
    my( $char1 , $char2, $buffer, $output ); 
    my( @name_stack, $last_name_on_stack );
    $output = $buffer = $char1 = $char2 = '';

    foreach $char2 ( @string ) {
       
        $buffer .= $char1;
    
        if(  "$char1$char2" =~ m/[?]>/ ){
            $output .= $buffer.$char2;
            $char1 = '';
            $buffer = '';
            next
        }
    
         if( "$buffer$char1$char2" =~ m/.*-->/ ) {
            $output .= $buffer.$char2;
            $char1 = '';
            $buffer = ''; 
            next
        }
   
        if( "$buffer$char1$char2" =~ m/<[?!]/ ) {
            $char1 = $char2;
            next
        }
    
        if(  "$char1$char2" eq '<>'){
            $buffer =~ 
             s/(($Name)(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?)</<$1\/>/g;
            $buffer =~ 
              s/($TextSE) (<$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?\/>)/trim_back( $1, $2 )/ge;
            $output .= $buffer;
            $char1 = '';
            $buffer = ''; 
            next
        }    
    
        if( $char1 eq '>' ){
            $last_name_on_stack = pop( @name_stack ); 
            $buffer =~ s/>//g;
            $buffer = "$buffer<\/$last_name_on_stack>";
            $output .= $buffer;
            $buffer = ''
        }
    
        if( $char1 eq '<' ){
            $buffer =~ 
             s/(($Name)(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?)</<$1>/g;
            push( @name_stack, $2 );
            $buffer =~ 
              s/($TextSE) (<$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?>)/trim_back( $1, $2 )/ge;
            $output .= $buffer;
            $buffer = ''
        }
        
       $char1 = $char2; 
    }
    $output .= $buffer.$char1;
    return $output   
}



sub trim_back {
    
    my $string1 = shift;
    my $string2 = shift;
        
    if ( $string1 =~ m/\w+/ ){ return "$string1$string2" } 
    else { return "$string1 $string2" }      
}   

1;
__END__
######################## User Documentation ##################

=head1 NAME

XML::FXN - Fast XML Notation.

=head1 SYNOPSIS

 use strict;
 use XML::FXN;

 my $xml_document = <<EOXML;
    <?xml version="1.0" standalone="yes"?>
    <user role='sender'>
        <name>fbHNkg==</name>
        <password>bb0GwesZoM</password>
        <resource>Just another client</resource>
        <priority/>
    </user>
 EOXML
 my $fxn_document = xml2fxn( $xml_document );
 
 $fxn_document = <<EOFXN;
    <?xml version="1.0" standalone="yes"?>
    user role='sender'<
        name<fbHNkg==>
        password<bb0GwesZoM>
        resource<Just another client>
        priority<>
    >
 EOFXN
 $xml_document = fxn2xml( $fxn_document );  

=head1 DESCRIPTION

=head2 Fast XML Notation

XML is used more and more in specifications like BPEL 
as a notation for programming tasks. There is a need for a XML 
notation, which can help handle XML in text mode in a manner 
similar to 'normal' programming languages. Fast XML 
Transformation applies only to well-formed XML documents and 
should allow 1:1 transformation in both directions 
without any loss in the content meaning and editorial 
structure. The transformation is based on shallow XML parsing.

Comments, Processing Instructions, Prolog and Document Type 
Declaration as defined in the Extensible Markup Language (XML) 
1.0 (http://www.w3.org/TR/REC-xml) are not touched by the Fast 
XML Transformation.

A so-called data-centric XML document as shown in the example 
below: 

 <tag1 atribute1='XXX' atribute2='YYY'>
     <tag2>AAA</tag2>
     <tag3> </tag3>
     <tag4/>
     <tag5></tag5>
     <tag6 atribute3 = 'ZZZ'/>
 </tag1>

is transformed to:

 tag1 atribute1='XXX' atribute2='YYY'<
    tag2<AAA>
    tag3< >
    tag4<>
    tag5<>
    tag6 atribute3 = 'ZZZ'<>
 >

A XML document with mixed content establishes a special case. 
For transformation from XML to FXN C<content1E<lt>tag1E<gt>> is converted 
to C<content tag1E<lt>E<gt>>, if content has any other than C<\s> characters.
Converting back from FXN to XML removes the injected space character. 

 <tag1 atribute1='XXX'>cccc <tag2>AAA</tag2> ccc<tag3>fff</tag3>
  <tag4/>   <tag5/><tag6 atribute3 = 'ZZZ'/>dddd</tag1> 

is transformed to:

 tag1 atribute1='XXX'<cccc  tag2<AAA> ccc tag3<fff>
  tag4<>   tag5<>tag6 atribute3 = 'ZZZ'<>dddd> 

The FXN file can be marked with the extention C<*.fxn>.

=head2 Transformation functions

The module provides only two methods:

=over 4

=item * C<xml2fxn( $xml_document )> 

takes a string
with the XML document as argument and returns document 
transformed to the Fast XML Notation;

=item * C<fxn2xml( $fxn_document )> 

takes a string
with the FXN document as argument and returns document 
transformed to XML.

=back

=head1 BUGS

If a bug is detected or FXN non-conform behavior, please send the xml file 
and fxn file as error report to E<lt>jwach@cpan.orgE<gt>.

=head1 COPYRIGHT 

Copyright 2005 Jerzy Wachowiak E<lt>jwach@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut 



