package jQuery;

use warnings;
use strict;
use XML::LibXML 1.70;
use HTML::Entities;
use Encode;
use Carp;

use base qw/jQuery::Functions Exporter/;
our @EXPORT = qw(jquery jQuery this);

use vars qw/$DOC $PARSER $VERSION/;
$VERSION = "0.004";

my $obj_class = 'jQuery::Obj';
sub this { 'jQuery::Functions'->this(@_) }

sub new {
    my $class = shift;
    my $string = shift;
    my $parser;
    my $doc;
    if (!$PARSER){
        $parser = XML::LibXML->new();
        $parser->recover(1);
        $parser->recover_silently(1);
        $parser->keep_blanks(1);
        $parser->expand_entities(1);
        $parser->no_network(1);
        local $XML::LibXML::skipXMLDeclaration = 1;
        local $XML::LibXML::skipDTD = 1;
        local $XML::LibXML::setTagCompression = 1;
        $PARSER = $parser;
    } else {
        $parser = $PARSER;
    }
    
    if ($string){
        if ($string =~ /^http/){
            $string = $class->get($string);
        } elsif ($string =~ /^<\?xml/) {
            $doc = $parser->parse_string($string);
        } else {
            $doc = $parser->parse_html_string($string);
        }
        $DOC = $doc;
    }
    
    return bless({
        document => $doc
    }, __PACKAGE__);
}

*jQuery = \&jquery;
sub jquery {
    my ($selector, $context) = (shift,shift);
    my $this;
    my $c;
    
    if ( ref ($selector) eq __PACKAGE__ ){
        $this->{document} = $selector->{document};
        $selector = $context;
        $context = shift;
    } else {
        $this->{document} = $DOC;
    }
    
    if ($context){
        if (@_){
            $context = bless([$context,@_], ref $context);
        }
        return jQuery($context)->find($selector);
    }
    
    if ( ref($selector) eq $obj_class ){
        return $selector;
    }
    
    bless($this, $obj_class);
    $this->{nodes} = [];   
    return $this if !$selector;
    
    my $nodes;
    if ( ref($selector) =~ /XML::/i ){   
        if ($selector->isa('ARRAY')){
            $nodes = $selector;
        } else {
            $nodes = [$selector];
        }
    } elsif ( ref ($selector) eq 'ARRAY' ){
        $nodes = $selector;
    } elsif ($this->is_HTML($selector)) {
        $nodes = $this->createNode($selector);
    } else {
        $nodes = $this->_find($selector);
        ##another try to create html fragment
        if (!$nodes->[0]){
            $nodes = $this->createNode($selector);
        }
    }
    
    return $this->pushStack(@$nodes);
}

##something like pushStack in jquery
sub pushStack {
    my $self = shift;
    my @elements;
    
    return jQuery($self,@_) unless $self->isa('HASH') and
    ref $self eq $obj_class;
    @elements = ref $_[0] eq 'ARRAY'
    ?   @{$_[0]}
    :   @_;
    
    #save old object
    $self->{prevObject} = $self->{nodes};
    
    #$self = bless ([@elements], $obj_class);
    $self->{nodes} = \@elements;
    return $self;
}

sub toArray {
    my $self = shift;
    my @nodes;
    if ($self->isa('ARRAY')) {
        @nodes = @{$self};
    } elsif ($self->isa('HASH')) {
        @nodes = @{$self->{nodes}};
    } else {
        @nodes = ($self);
    }
    
    return wantarray ?
    @nodes
    : \@nodes;
}

sub getNodes {
    my $self = shift;
    my @nodes;
    if ($self->isa('ARRAY')) {
        @nodes = @{$self};
    } elsif ($self->isa('HASH')) {
        @nodes = @{$self->{nodes}};
    } else {
        @nodes = ($self);
    }
    return wantarray ? @nodes : bless(\@nodes, $obj_class);
}


sub _find {
    my ($this, $selector, $context ) = @_;
    $context ||= $this->document;
    my @nodes;
    eval {
        if ($selector !~ m/\//){
            $selector = $this->_translate_css_to_xpath($selector,$context->nodePath);
        }
        @nodes = $context->findnodes($selector) if $selector;
    };
    
    if ($@){
        croak $@;
    }
    return wantarray 
    ? @nodes
    : \@nodes;
}

#Should I use HTML::Selector::XPath and port some jquery selectors by hand ??
#it's well maintained
#this is faster but not easy to maintain and not quiet mature
sub _translate_css_to_xpath {
    my $self = shift;
    my $start_query = shift;
    my $old_query = shift;
    my $custompath = shift || '';
    my @args;
    $start_query =~ s/\((.*?),(.*?)\)/\($1<COMMA>$2\)/g;
    my @queries = split(/\,/,$start_query);
    my $this_query = 0;
    
    foreach my $query (@queries){
        $query =~ s/<COMMA>/,/g;
        #remove all leading and ending whitespaces
        $query =~ s/^\s+|\s+$//g;
        $query =~ s/\s+/</g;
        ##add one whitespace at the beginning
        $query = " ".$query;
        
        my $selector;
        $selector = $old_query if $old_query;
        
        my $pos = 0;
        my $directpath = 0;
        my $empty_path =0;
        my $single = 0;
        
        ##setting starting search path custom path is // which search down all elements
        my $path = '//';
        $path = $custompath if $custompath;
        
        ##I wrote this some while ago, I feel dizzy when I try to read it again
        while ($query =~ /([\s|\.|\:|\#]?)((\[.*?\])|(~)|(\+)|(\>)|(\<)|(\*)|([\w\-]+(\(.*?\))?))/g){
            
            my $type = $1;
            my $value = $2;
            my $pos2 = 0;
            
            ##set empty starting path
            if ($custompath eq 'empty' && $pos2 eq '0'){
                $path = '';
                ###if we want to search direct childrens
            }   elsif ($directpath || $empty_path){
                $path = '/';
                $path = '//' if $directpath eq '2';
                $path = '' if $empty_path;
                if (($type =~ /(\:|\.|\#)/ || $value =~ /\[.*?\]/)){
                    $selector .= $path.'*';
                }
                
                #reset direct path
                $directpath = 0;
                ##reset empty path
                $empty_path = 0;
            }   else {
                $path = '//';
            }
            
            $type =~ s/\s+//;
            $value =~ s/\s+//;
            if ($pos == 0){
                $path = $custompath if $custompath && $custompath ne 'empty';
                if (($type =~ /(\:|\.|\#)/ || $value =~ /\[.*?\]/)){
                    $selector .= $path.'*';
                }
            }
            
            if ($value eq '*'){
                $selector .= $path.'*';
            } elsif ($value eq '>'){
                $directpath = 1;
            }   elsif ($value eq '<'){
                $directpath = 2;
            } elsif ($value eq '+'){
                $selector .= '/following-sibling::';
                $empty_path = 1;
                $single = 1;
            } elsif ($value eq '~'){
                $selector .= '/following-sibling::';
                $empty_path = 1;
            } elsif ($value =~ /\[(.*?)\]/){
                
                my ($name, $value) = split(/\s*=\s*/, $1, 2);
                if (defined $value) {
                    for ($value) {
                        s/^['"]//;
                        s/['"]$//;
                    }
                    
                    if ($name =~ s/\^$//){
                        $selector .= "[starts-with (\@$name,'$value')]";
                    } elsif ($name =~ s/\$$//){
                        #$selector .= "[ends-with (\@$name,'$value')]";
                        $selector .= "[substring(\@$name, string-length(\@$name) - string-length('$value')+ 1, string-length(\@$name))= '$value']";
                    } elsif ($name =~ s/\*$//){
                        $selector .= "[contains (\@$name,'$value')]";
                    } elsif ($name =~ s/\|$//){
                        $selector .= "[\@$name ='$value'"." or "."starts-with(\@$name,'$value".'-'."')]";
                    } else {
                        $selector .= "[\@$name='$value']";
                    }
                    
                } else {
                    $selector .= "[\@$name]";
                }
                
            ##this is tag
            } elsif (!$type){
                $selector .= $path.$value;
            ##this is class
            } elsif ($type eq "."){
                ##finally found a good solution from
                ##http://plasmasturm.org/log/444/
                $selector .= '[ contains(concat( " ", @class, " " ),concat( " ", "'.$value.'", " " )) ]';
                
            ##id selector
            } elsif ($type eq '#'){
                $selector .= '[@id="'.$value.'"]';
            }
            
            ###pseduo-class
            elsif ($type eq ':'){
                
                if ($value eq "first-child"){
                    $selector .= '[1]';
                } elsif ($value eq "first"){
                    #$selector = "getIndex($selector,'eq','0')";
                    $selector .= '[position() = 1]'; ##this doesn't really do the job exactly as jQuery
                } elsif ($value eq "odd"){
                    #$selector = 'getOdd('.$selector.')';
                    $selector .= '[position() mod 2 != 1]'; ##this doesn't do the job exactly as jQuery
                } elsif ($value eq "even"){
                    #$selector = 'getEven('.$selector.')';
                    $selector .= '[position() mod 2 != 0]'; ##this doesn't do the job exactly as jQuery
                } elsif ($value =~ /(gt|lt|eq)\((.*?)\)/){
                    $selector = "getIndex($selector,'$1','$2')";
                } elsif ($value =~ /nth-child\((.*?)\)/){
                    $selector .= "[position() = $1]";
                } elsif ($value =~ /has\((.*?)\)/){
                    $selector = "getHas($selector,'$1')";
                } elsif ($value =~ /not\((.*?)\)/){
                    $selector = "getNot($selector,'$1')";
                } elsif ($value eq "button"){
                    #$selector .= '[@type="button"]';
                    $selector = "getButton($selector)";
                } elsif ($value =~ /(checkbox|file|hidden|image|text|submit|radio|password|reset)/){
                    $selector .= "[\@type='$value']";
                } elsif ($value eq "checked"){
                    $selector .= '[@checked="checked"]';
                } elsif ($value eq "selected"){
                    $selector .= '[@selected="selected"]';
                } elsif ($value eq "disabled"){
                    $selector .= '[@disabled]';
                } elsif ($value eq "enabled"){
                    $selector .= '[not(@disabled)]';
                } elsif ($value =~ /contains\((.*?)\)/){
                    my $str = $1;
                    for ($str) {
                        s/^['"]//;
                        s/['"]$//;
                    }
                    $selector .= "[contains(.,'$str')]";
                } elsif ($value eq "empty"){
                    $selector .= '[not(node())]';
                } elsif ($value eq "only-child"){
                    
                    my ($str1, $str2) = $selector =~ /(.*)\/(.*)/;
                    if ($str1 =~ s/\/$//){
                        $str2 = '/'.$str2;
                        $selector = $str1.'//child::*/parent::*[count(*)=1]'.'/'.$str2;
                    } else{
                        $selector = $str1.'/child::*/parent::*[count(*)=1]'.'/'.$str2;
                    }
                    
                } elsif ($value eq "header"){
                    $selector = "getHeaders($selector)";
                } elsif ($value eq "parent"){
                    $selector .= '[(node())]';
                } elsif ($value eq "last"){
                    #$selector = "getLast($selector)";
                    $selector .= '[position()=last()]';
                } elsif ($value eq "last-child"){
                    $selector .= "[last()]";
                }
            }
            $pos++; $pos2++;
        }
        if ($single){
            $selector .= '[1]';
            $single = 0;
        }
        $this_query++;
        push (@args,$selector);
    }
    return join(' | ',@args);
}

sub as_HTML {
    my $self = shift;
    my $doc = $self->document;
    if (ref($doc) eq 'XML::LibXML::Document' ){
        my $html = $doc->serialize_html();
        if ($html =~ m/<div class="REMOVE_THIS_ELEMENT">/g){
            $html =~ s/(?:.*?)<div class="REMOVE_THIS_ELEMENT">(.*)<\/div>(?:.*)/$1/s;
        }
        return $html;
    }
    return $doc->getDocumentElement->html();
}

sub as_XML {   
    my $doc = $_[0]->document;
    if ($$DOC ne $$doc){
        if (ref($doc) eq 'XML::LibXML::Document' ){
            my $xml = $doc->serialize();
            if ($xml =~ m/<div class="REMOVE_THIS_ELEMENT">/g){
                $xml =~ s/(?:.*?)<div class="REMOVE_THIS_ELEMENT">(.*)<\/div>(?:.*)/$1/s;
            }
            return $xml;
        }
        return $doc->getDocumentElement->html();
    }
    
    return $doc->serialize();
}


sub is_HTML {
    my ($self,$html) = @_;
    ### very permative solution but it seems 
    ### to work with all tests so far
    if ($html =~ /<.*>/g){
        return 1;
    }
    return 0;
}

sub createNode {
    my ($self,$html) = @_;
    my $node;
    if (!$PARSER){ $self->new(); }
    $html = "<div class='REMOVE_THIS_ELEMENT'>".$html."</div>";
    if ($html =~ /^<div class='REMOVE_THIS_ELEMENT'><\?xml/) {
        $node = $PARSER->parse_string($html);
    } else{
        $node = $PARSER->parse_html_string($html);
    }
    
    $DOC = $node if !$DOC;
    $node->removeInternalSubset;
    my $nodes = $node->getDocumentElement->findnodes("//*[\@class='REMOVE_THIS_ELEMENT']")->[0]->childNodes;
    return $nodes;
}

sub createNode2 {
    my ($self,$html) = @_;
    $html = "<div class='REMOVE_THIS_ELEMENT'>".$html."</div>";
    my $new = $self->new($html);
    return $new->jQuery('.REMOVE_THIS_ELEMENT *');
}

##detect node parent document
sub document {
    my $self = shift;
    my $doc;
    if ($self->isa('ARRAY') && $self->[0]){
        $doc = $self->[0]->ownerDocument;
    } elsif ($self->isa('HASH') && $self->{document}){
        $doc = $self->{document};
    }
    return $doc ? $doc : $DOC;
}

sub cloneDOC {
    my $self = shift;
    my $clone = $self->document->cloneNode(1);
    return bless([$clone], __PACKAGE__);
}

sub decode_html { return decode_entities($_[1]); }
sub parser { return shift->{parser}; }

###custom internal functions
###copied from jQuery.js
sub body { return shift->getElementsByTagName('body'); }

sub makeArray {
    my ( $array, $results ) = @_;
    my $ret = $results || [];
    if ( ref $array eq 'ARRAY' ) {
	push @{$ret}, @{$array};
    }
    else { $ret = \@_; }
    return wantarray
    ? @$ret
    : $ret;
}

sub merge {
    my ( $first, $second ) = @_;
    my $i = _length($first);
    my $j = 0;
    if ( _length($second) ) {
	for ( my $l = _length($second); $j < $l; $j++ ) {
	    $first->[ $i++ ] = $second->[ $j ];
	}
    } else {
	while ( $second->[$j] ) {
            $first->[ $i++ ] = $second->[ $j++ ];
	}
    }
    $i = _length($first);
    return wantarray
    ? @$first
    : $first ;   
}

sub _length {
    if (ref $_[0] eq 'ARRAY'){
        @_ = @{$_[0]};
    }
    return $#_ + 1;
}

sub isDisconnected {
    my $node = shift;
    return !$node || !$node->parentNode || $node->parentNode->nodeType == 11;
}

sub unique {
    my %hash;
    my @ele = grep{!$hash{$$_}++} @_;
    return @ele;
}

sub nodeName  {
    my ( $elem, $name ) = @_;
    return $elem->nodeName && uc $elem->nodeName eq uc $name;
}

package jQuery::Obj;
use base 'jQuery';

##hack Libxml modules to use jQuery as base module
##is this a bad practice?
package XML::LibXML::NodeList;
use base 'jQuery::Obj';

package XML::LibXML::Node;
use base 'jQuery::Obj';

package XML::LibXML::Element;
use base 'jQuery::Obj';

package XML::LibXML::Text;
use base 'jQuery::Obj';
use base 'XML::LibXML::Element';

1;

__END__

=head1 NAME

jQuery - complete jQuery port to Perl

=head1 SYNOPSIS
  
    ##OOP style
    use jQuery;
    my $j = jQuery->new('http://someurl.com');
    
    ##or insert html directly
    my $j = jQuery->new('<html>...</html>');
    
    $j->jQuery('p')->append( sub {
      my $i = shift;
      my $html = shift;
      return "<strong>Hello</strong>";
    } )->css('color','red');
    
    print $j->as_HTML;
    
    ##non OOP - more like jQuery.js style
    jQuery->new($html);

    jQuery("p")->append( sub{
        my $i = shift;
        my $html = shift;
        return "<strong>Hello</strong>";
    } )->css('color','red');
    
    print jQuery->as_HTML;
  
  
=head1 DESCRIPTION

This is another attempt to port jQuery to Perl "the DOM part and what ever could be run on the server side NOT client side"

To create this module I went through jQuery.js and some times literally translated javascript functions to their perl equivalent, which made
my job way easier than thinking of how and why I can do this or that. of course some other times I had to roll my own hacks :)

=head2 How this differ from other Perl jQuery modules?

First, I wrote this long time ago, I wasn't sure if there were any jQuery modules then
or maybe I didn't search CPAN well, then later I found L<pQuery> which is nice, clean and written by
Ingy döt Net

=head2 Here are some differences

    * it uses XML::LibXML as it's parsing engine
    * Work just like jQuery.js. Translate jQuery.js by simply replace . with -> "with some minor twists"
    * Almost all jQuery DOM functions are supported

=head1 jQuery

Method for matching a set of elements in a document
    
=over 4

=item jQuery( selector, [ context ] )
    
=item jQuery( element )
    
=item jQuery( elementArray )
    
=item jQuery( jQuery object )

=item jQuery( <html> )
    
=back

=cut

=head1 this Method

this method in loop represents current selected node

    jQuery('div')->each(sub{
        this->addClass('hola');
    });

=head1 Caveats

When dealing with multiple HTML document at once always use OO style
    
    my $j1 = jQuery->new($html1);
    my $j2 = jQuery->new($html2);
    
    ##then
    
    $j1->jQuery('div')->find('..')->addClass('..');
    my $nodes = $j2->('div');
    $nodes->find('span')->css('border','1px solid red');
    
    print $j1->as_HTML();
    print $j2->as_HTML();

This way, different documents will never overlap, you may use the non OO style but you need to be careful then

    jQuery->new($html1);
    jQuery('div')->find('..')->addClass('..');
    jQuery->as_HTML;
    
    ##always use a new constructure when switching documents
    ##the previous will be lost
    jQuery->new($html2);
    my $nodes = jQuery('div');
    $nodes->find('..')->css('border','1px solid red');
    jQuery->as_HTML;
    
=head1 Dependencies

    * XML::LibXML 1.70 and later
    * LWP::UserAgent
    * HTML::Entities
    * HTTP::Request::Common

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 Methods

See L<jQuery::Functions>

=head1 Examples

Please see the included examples folder for more on how to use and supported functions
All examples have been copied directly from jQuery document web site
you can see their equivalent in jQuery api section at http://api.jquery.com/

=head1 AUTHOR

Mamod A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2013 by Mamod A. Mehyar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
