package XML::Trivial;

use XML::Parser::Expat;

use strict;
use warnings;

our $VERSION = '0.06';

my @stack;
my @nsstack = ({''=>'',
		xml=>'http://www.w3.org/XML/1998/namespace',
		xmlns=>'http://www.w3.org/2000/xmlns/'});
my $cur;

sub parseFile {
    my $filename = shift;
    local *FH;
    open(FH,$filename);
    my $ret = XML::Trivial::parse(*FH);
    close(FH);
    return $ret;
}

sub parse {
    @stack = undef;
    $cur = 0;
    my $expat = new XML::Parser::Expat;
    $expat->setHandlers(XMLDecl    => \&XML::Trivial::_xmldecl,
			Doctype    => \&XML::Trivial::_doctype,
			Start      => \&XML::Trivial::_startElement,
			End        => \&XML::Trivial::_endElement,
			Char       => \&XML::Trivial::_char,
			Comment    => \&XML::Trivial::_comment,
			Proc       => \&XML::Trivial::_proc,
			CdataStart => \&XML::Trivial::_startCDATA,
			CdataEnd   => \&XML::Trivial::_endCDATA
		       );
    $expat->parse(@_);
    $expat->release;
    my $ret = XML::Trivial::Element->new($stack[0]);
    return $ret;
}

#handlers

sub _xmldecl {
    my ($p, $ver, $enc, $std) = @_;
    push @{$stack[$cur]},('-xml',[$ver,$enc,$std]);
}

sub _doctype {
    my ($p, $nam, $sid, $pid, $int) = @_;
    push @{$stack[$cur]},('-doc',[$nam, $sid, $pid, $int]);
}

sub _startElement {
    my ($p, $el, %atts) = @_;
    $cur++; 
    push @stack, [$el,\%atts];
    my %ns;
    my ($name, $value);
    while (($name, $value) = each %atts) {
	$name =~ /^xmlns(:|)(.*)$/ and $ns{$2} = $value;
    }
    push @nsstack, \%ns;
}

sub _endElement {
    my ($p, $el) = @_;
    my $n = XML::Trivial::Element->new($stack[$cur], \@nsstack);
    $cur--;
    pop @stack;
    push @{$stack[$cur]},('-elm',$n);
    pop @nsstack;
}

sub _char {
    my ($p, $str) = @_;
    if ($stack[$cur][@{$stack[$cur]}-2] eq '-txt' or
	$stack[$cur][@{$stack[$cur]}-2] eq '-cds') {
	$stack[$cur][@{$stack[$cur]}-1] .= $str;
    } elsif ($stack[$cur][@{$stack[$cur]}-1] eq '-cds') {
	push @{$stack[$cur]},$str;
    } else {
	push @{$stack[$cur]},('-txt',$str);	
    }
}

sub _comment {
    my ($p, $str) = @_;
    push @{$stack[$cur]},('-not',$str);
}

sub _proc {
    my ($p, $tgt, $data) = @_;
    push @{$stack[$cur]},('-pro',[$tgt, $data]);
}

sub _startCDATA {
    my ($p) = @_;
    push @{$stack[$cur]},'-cds';
}

sub _endCDATA {
    my ($p) = @_;
    if ($stack[$cur][@{$stack[$cur]}-1] eq '-cds') {
	push @{$stack[$cur]},undef;
    }
    $stack[$cur][@{$stack[$cur]}-2] = '-cdt';
}


package XML::Trivial::Element;
use Scalar::Util 'weaken';
use strict;
use warnings;

sub new {
    my ($class, $aref, $nsstack) = @_;
    tie my %h, $class, $aref || [], $nsstack;
    my $self =  bless \%h, $class;
    my %ehns;
    my $key;
    my $s = tied(%$self);
    foreach (@{$s->{ea}}) {
	tied(%$_)->{parent} = $self;
	weaken(tied(%$_)->{parent});#because it is circular ref
	$key = $_->ns(undef).'*'.$_->ln();
	$ehns{$key} = $_ unless exists $ehns{$key};
    }
    $s->{ehns} = \%ehns;
    return $self;
}

sub TIEHASH {
    my ($class, $a, $nsstack) = @_;
    #$a is arrayref like [name, atts, type1, data1, type2, data2, ...]
    my @ea; my %eh;#elements
    my @ta;        #texts
    my @ca;        #cdatas
    my @pa; my %ph;#process instructions
    my @na;        #notes
    my $firstkey;
    my $lastkey;
    my %next;
    my %nh;        #hash of namespaces in scope
    foreach (@$nsstack) {
	while (my ($name, $value) = each %$_) {
	    $nh{$name} = $value;
	}
    }
    for (my $i = 0; $i < @$a; $i += 2) {
	if ($$a[$i] =~ /^-(.*)$/) {
	    if ($1 eq 'elm') {
		push @ea, $$a[$i+1];
		unless ($eh{$$a[$i+1]->a(0)}) {
		    $eh{$$a[$i+1]->a(0)} = $$a[$i+1];
		    if ($lastkey) {
			$next{$lastkey} = $$a[$i+1]->a(0);
		    }
		    $lastkey = $$a[$i+1]->a(0);
		}
		$firstkey ||= $$a[$i+1]->a(0);
	    } elsif ($1 eq 'txt') {
		push @ta, $$a[$i+1];
	    } elsif ($1 eq 'cdt') {
		push @ta, $$a[$i+1];
		push @ca, $$a[$i+1];		
	    } elsif ($1 eq 'pro') {
		push @pa, $$a[$i+1];		
		unless ($ph{$$a[$i+1][0]}) {
		    $ph{$$a[$i+1][0]} = $$a[$i+1][1];
		}
	    } elsif ($1 eq 'not') {
		push @na, $$a[$i+1];
	    }
	}
    }
    return bless {a=>$a,
		  ea=>\@ea, eh=>\%eh,
		  ta=>\@ta,
		  ca=>\@ca,
		  pa=>\@pa, ph=>\%ph,
		  na=>\@na,
		  nh=>\%nh,
		  parent=>undef,
		  firstkey=>$firstkey,
		  next=>\%next
		 }, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    $key =~ /^\d+$/ and return $$self{ea}[$key];
    $key =~ /\*/ and return $$self{ehns}{$key};
    return $$self{eh}{$key};
}

sub EXISTS {
    my ($self, $key) = @_;
    $key =~ /\*/ and return exists $$self{ehns}{$key};
    return exists $$self{eh}{$key};
}

sub FIRSTKEY {
    return $$_[0]{firstkey};
}

sub NEXTKEY {
    return $$_[0]{next}{$$_[1]};
}

sub SCALAR {
    return $$_[0]{a}[0];
}

sub p { #parent
    my ($self) = @_;
    return tied(%$self)->{parent};
}

sub xv { #xml version
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->xv();
    $s->{a}[0] eq '-xml' and return $s->{a}[1][0];
    return '1.0';
}

sub xe { #xml encoding
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->xe();
    $s->{a}[0] eq '-xml' and defined $s->{a}[1][1] and 
	return $s->{a}[1][1];
    return 'UTF-8';
}

sub xs { #xml standalone
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->xs();
    $s->{a}[0] eq '-xml' and defined $s->{a}[1][2] and
	return $s->{a}[1][2]?1:0;
    return undef;
}

sub dn { #doctype name
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->dn();
    my $i = 0;
    while ($s->{a}[$i] =~ /^-/) {
	$s->{a}[$i] eq '-doc' and return $s->{a}[$i+1][0];
	$i += 2;
    }
    return undef;
}

sub ds { #doctype system
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->ds();
    my $i = 0;
    while ($s->{a}[$i] =~ /^-/) {
	$s->{a}[$i] eq '-doc' and return $s->{a}[$i+1][1];
	$i += 2;
    }
    return undef;
}

sub dp { #doctype public
    my ($self) = @_;
    my $s = tied(%$self);
    defined $s->{parent} and return $s->{parent}->dp();
    my $i = 0;
    while ($s->{a}[$i] =~ /^-/) {
	$s->{a}[$i] eq '-doc' and return $s->{a}[$i+1][2];
	$i += 2;
    }
    return undef;
}

sub en { #element (qualified) name 
    my ($self) = @_;
    return tied(%$self)->{a}[0];
}

sub ep { #element prefix
    my ($self) = @_;
    tied(%$self)->{a}[0] =~ /^([^:]*):.*$/ and return $1;
    return '';
}

sub ln { #local (unqualified) name
    my ($self) = @_;
    tied(%$self)->{a}[0] =~ /^([^:]*:)?([^:]*)$/ and return $2;
}

sub ns { #namespace
    my ($self, $p) = @_;
    1 == @_ and return wantarray ? %{tied(%$self)->{nh}} : tied(%$self)->{nh};
    defined $p and return tied(%$self)->{nh}{$p};
    return tied(%$self)->{nh}{$self->ep()};
}

sub ah { #attribute hash
    my ($self, $key, $ns) = @_;
    1 == @_ and return wantarray ? %{tied(%$self)->{a}[1]} : tied(%$self)->{a}[1];
    2 == @_ and return tied(%$self)->{a}[1]{$key};
    my $s = tied(%$self);
    my ($ret, $name, $value);
    if (defined $key) {
	if (defined $ns) {
	    $key =~ /:/ and return undef;
	    while (($name, $value) = each %{$s->{a}[1]}) {
		unless (defined $ret) {
		    if ($name eq $key) {
			$ns eq '' and $ret = $value;
		    } elsif ($name =~ /^([^:]+):$key$/) {
			exists $s->{nh}{$1} and $s->{nh}{$1} eq $ns and 
			    $ret = $value;
		    }
		}
	    }
	    return $ret;
	} else {
	    $ret = {};
	    $key =~ /:/ and return $ret;
	    while (($name, $value) = each %{$s->{a}[1]}) {
		if ($name eq $key) {
		    $$ret{''} = $value;
		} elsif ($name =~ /^((([^:]+):)|)$key$/) {
		    $$ret{$s->{nh}{$3}} = $value;
		}
	    }
	}
    } else {
	$ns = $self->ns(undef) unless defined $ns;
	$ret = {};
	if ($ns eq '') {
	    while (($name, $value) = each %{$s->{a}[1]}) {
		$name !~ /:/ and $$ret{$name} = $value;
	    }
	} else {
	    while (($name, $value) = each %{$s->{a}[1]}) {
		$name =~ /^([^:]+):([^:]+)$/ and $s->{nh}{$1} eq $ns and 
		    $$ret{$2} = $value;    
	    }
	}
    }
    return wantarray ? %$ret : $ret;
}

sub eh { #element hash
    my ($self, $key) = @_;
    1 == @_ and return wantarray ? %{tied(%$self)->{eh}} : tied(%$self)->{eh};
    $key =~ /\*/ and return tied(%$self)->{ehns}{$key};
    return tied(%$self)->{eh}{$key};
}

sub ea { #element array
    my ($self, $index) = @_;
    1 == @_ and return wantarray ? @{tied(%$self)->{ea}} : tied(%$self)->{ea};
    return tied(%$self)->{ea}[$index];
}

sub ta { #text array (ca included)
    my ($self, $index) = @_;
    (1 == @_ or not defined $index)
	and return wantarray ? @{tied(%$self)->{ta}} : tied(%$self)->{ta};
    return tied(%$self)->{ta}[$index];
}

sub ca { #cdata array
    my ($self, $index) = @_;
    (1 == @_ or not defined $index)
	and return wantarray ? @{tied(%$self)->{ca}} : tied(%$self)->{ca};
    return tied(%$self)->{ca}[$index];
}

sub ts { #text serialized
    my ($self) = @_;
    return join '', @{tied(%$self)->{ta}};
}

sub pa { #process instr. array
    my ($self, $index) = @_;
    (1 == @_ or not defined $index)
	and return wantarray ? @{tied(%$self)->{pa}} : tied(%$self)->{pa};
    return tied(%$self)->{pa}[$index];
}

sub ph { #process instr. hash
    my ($self, $key) = @_;
    1 == @_ and return wantarray ? %{tied(%$self)->{ph}} : tied(%$self)->{ph};
    return tied(%$self)->{ph}{$key};
}

sub na { #notes array
    my ($self, $index) = @_;
    (1 == @_ or not defined $index)
	and return wantarray ? @{tied(%$self)->{na}} : tied(%$self)->{na};
    return tied(%$self)->{na}[$index];
}

sub a { #all in the document order
    my ($self, $index) = @_;
    (1 == @_ or not defined $index)
	and return wantarray ? @{tied(%$self)->{a}} : tied(%$self)->{a};
    return tied(%$self)->{a}[$index];
}



sub sr { #serialize
    my ($self) = @_;
    my $s = tied(%$self);
    my $ret = '';
    my $val;
    my $i = 0;
    my $en;
    my $pfix = "\n";
    while ($s->{a}[$i]) {
	if ($s->{a}[$i] =~ /^-(.*)$/) {
	    if ($1 eq 'elm') {
		$ret .= $s->{a}[$i+1]->sr;
	    } elsif ($1 eq 'txt') {
		$val = $s->{a}[$i+1];
		$val =~ s/\&/\&amp;/g;
		$val =~ s/</\&lt;/g;
		$val =~ s/\]\]>/]]\&gt;/g;
	        $ret .= $val;
            } elsif ($1 eq 'cdt') {
	        $ret .= '<![CDATA['.$s->{a}[$i+1].']]>';
            } elsif ($1 eq 'pro') {
	        $ret .= '<?'.$s->{a}[$i+1][0].' '.$s->{a}[$i+1][1].'?>'.$pfix;
            } elsif ($1 eq 'not') {
	        $ret .= '<!--'.$s->{a}[$i+1].'-->'.$pfix;
            } elsif ($1 eq 'xml') {
		$ret .= "<?xml version='".$s->{a}[$i+1][0]."'";
		$s->{a}[$i+1][1] and $ret .= " encoding='".$s->{a}[$i+1][1]."'";
		defined $s->{a}[$i+1][2] and $ret .= " standalone='".($s->{a}[$i+1][2]?'yes':'no')."'";
		$ret .= "?>".$pfix;
	    } elsif ($1 eq 'doc') {
		$ret .= '<!DOCTYPE '.$s->{a}[$i+1][0];
		$s->{a}[$i+1][2] and $ret .= ' PUBLIC \''.$s->{a}[$i+1][2].'\'';
		$s->{a}[$i+1][1] and not $s->{a}[$i+1][2] and $ret .= ' SYSTEM';
		$s->{a}[$i+1][1] and $ret .= ' \''.$s->{a}[$i+1][1].'\'';
		$ret .= ">".$pfix;
	    }
	} else {
	    $pfix = '';
	    $en = $s->{a}[$i];
	    $ret .= '<'.$en;
	    foreach (keys %{$s->{a}[$i+1]}) {
		$val = $s->{a}[$i+1]{$_};
		$val =~ s/\&/\&amp;/g;
		$val =~ s/\'/\&apos;/g;
		$val =~ s/</\&lt;/g;
		$ret .= ' '.$_."='".$val."'";
	    }
	    $ret .= '>';
	}
	$i += 2;
    }
    defined $en or return $ret;
    return $ret.'</'.$en.'>';
}

1;

__END__

=head1 NAME

XML::Trivial - The trivial tool representing parsed XML as tree of read only objects.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 use XML::Trivial ();
 my $xml = XML::Trivial::parseFile('filename');
 print "Names and text contents of /root/child/* elements:\n";
 foreach ($$xml{0}{child}->ea) {
   print "name:".$_->en;
   print " text:".$_->ts."\n";
 }

=head1 DESCRIPTION

This module provides easy read only and random access to previously parsed XML documents in Perl. The xml declaration, elements, attributes, comments, text nodes, CDATA sections and processing instructions are implemented. Following limitations are assumed:

* The XML files are small, respectively, parsed XML data are storable in memory. 

* Perl structure representing XML file is NOT serializable by Data::Dumper. (But every element is serializable by its own sr() method.)

* Perl structure is read only.

The module is namespace-aware.

=head2 IDEAS

This module is designed for reading and traversing the small XML files in Perl. There are no expectations of xml structure before parse time, every well-formed document can be parsed and traversed, every element can be serialized, all without any lose of information.

=head2 DEPENDENCIES

XML::Parser::Expat is used for parsing of the XML files. This may change or may get optional.

=head2 USAGE

 use XML::Trivial ();

=head3 Module functions

=over

=item parseFile('filename')

See next chapter.

=item parse($string)

See next chapter.

=back

=head3 Parsing

 my $xml = XML::Trivial::parseFile('filename');

If specified filename does not exist or the content is not well formed xml document, the subroutine dies with origin expat's message, because this module has no opinion about what to do in these situations.

Or:

 my $xml = XML::Trivial::parse(q{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
 <root>
   <home>/usr/local/myApplication</home>
   <sections>
     <section name="A" version="1.8" escaped="',&quot;,&lt;">
       <a_specific>aaa</a_specific>
     </section>
     <section name="B">bbb</section>
     <text>
     ...and there is another stuff
     <![CDATA[<html><body><hr>Hello, world!<hr></body></html>]]>
     ...more stuff here...
       <element/>
     <![CDATA[2nd CDATA]]>
     ...]]&gt;...
     </text>
   </sections>
 <!--processing instructions-->
   <?first do something ?>
   <?second do st. else ?>
   <?first fake ?>
 <!--namespaces-->
   <meta xmlns="meta_ns" xmlns:p1="first_ns" xmlns:p2="second_ns">
     <desc a="v" p1:a="v1" p2:a="v2"/>
     <p1:desc a="v" p1:a="v1" p2:a="v2"/>
     <p2:desc a="v" p1:a="v1" p2:a="v2"/>
   </meta>
 </root>});

This xml document, represented by C<$xml>, is used in examples below.

=head3 XML declaration 

 print "xml version: ".$xml->xv()."\n";

If xml declaration is not present in parsed document, '1.0' is returned as xml version.

 print "xml encoding: ".$xml->xe()."\n";

If xml declaration is not present in parsed document or encoding is not specified, 'UTF-8' is returned. REMEMBER that returned value reflects origin encoding of parsed document, perl internal representation is already in UTF-8.

 print "xml standalone: ".$xml->xs()."\n";

If xml declaration is not present in parsed document or standalone is not present, undef is returned. Otherwise, 1 is returned when standalone="yes" or 0 is returned when standalone="no".

=head3 Doctype

 print "doctype name: ".$xml->dn()."\n";

If document type declaration present, it returns its name, otherwise returns undef.

 print "doctype system: ".$xml->ds()."\n";

If document type declaration and system part of external entity declaration present, it is returned, otherwise undef is returned.

 print "doctype public: ".$xml->dp()."\n";

If document type declaration and public part of external entity declaration present, it is returned, otherwise undef is returned.

=head3 Document tree

Parsed xml is organized into tree datastructure, which nodes represents the rootnode and the elements. All nodes have the same class, XML::Trivial::Element. The simplest navigation through the tree is possible according to following examples (the sr() method of final element serializes that element, just for demonstration):

Navigation by element name:

 print "homeelement: ".$$xml{root}{home}->sr."\n";
 print "prefix based access: ".$$xml{root}{meta}{'p1:desc'}->sr."\n";
 print "namespace based access: ".$$xml{root}{meta}{'first_ns*desc'}->sr."\n";

BE CAREFULL, if more sibbling elements would belong to the same hashkey, the first sibbling is already returned. 

Navigation by element position:

 print "first child element of rootelement: ".$$xml{root}{0}->sr."\n";

If the non-negative integer is used as a key, the sibling on that position is returned.

=head3 Element methods

Describing particular methods, terms 'hash(ref)' and 'array(ref)' are used when returned type depends on calling context - in scalar context, method returns hashref or arrayref, in list context, method returns list (hash or array).

All XML declaration methods and Doctype methods (see above) are usable on elements.

=over

=item p()

B<p>arentnode. Returns parent element or root node.

 print "serializes whole document: ".$$xml{0}->p->sr."\n";

=item en()

B<e>lement (qualified) B<n>ame

 print "home element name: ".$$xml{0}{0}->en."\n";
 print "name of 3rd childelement of meta: ".$$xml{0}{meta}{2}->en."\n";

Returns qualified element name (including namespace prefix).

=item ep()

B<e>lement B<p>refix

 print "home element prefix: '".$$xml{0}{0}->ep."'\n";
 print "prefix of 3rd childelement of meta: '".$$xml{0}{meta}{2}->ep."'\n";

Returns prefix of qualified element name.

=item ln()

element B<l>ocal (unqualified) B<n>ame

 print "home element localname: '".$$xml{0}{0}->ln."'\n";
 print "localname of 3rd childelement of meta: '".$$xml{0}{meta}{2}->ln."'\n";

Returns unqualified element name (excludes namespace prefix).

=item ns()

B<n>ameB<s>paces. Returns hash(ref) of namespaces in the element's scope.

 print "all namespaces of 'desc' element:\n";
 for (my %h = $$xml{0}{meta}{desc}->ns(); 
      my ($key, $val) = each %h; 
      print " '$key'='$val'\n"){}; 

=item ns(undef)

B<n>ameB<s>pace of the element.

 print "namespace of 'p2:desc' element: ".$$xml{0}{meta}{'p2:desc'}->ns(undef)."\n";

=item ns($prefix)

B<n>ameB<s>pace of specified prefix.

 print "namespace of 'p2' prefix in <desc> element: ".$$xml{0}{meta}{desc}->ns('p2')."\n";

Returns namespace of specified prefix, valid in the element.

=item ah()

B<a>ttribute B<h>ash(ref). Returns the hash (in list context) or hashref (in scalar context) of all attributes - the keys of the hash are qualified attribute names.

 print "all attributes of 'desc' element:\n";
 for (my %h = $$xml{0}{meta}{desc}->ah(); 
      my ($key, $val) = each %h; 
      print " '$key'='$val'\n"){}; 

=item ah($attrname)

B<a>ttribute B<h>ash. Returns the value of specified attribute name.

 print "\n1st section version: ".$$xml{0}{sections}{section}->ah('version')."\n";
 print "p1:a value of p2:desc element: ".$$xml{0}{meta}{'p2:desc'}->ah('p1:a')."\n";

This usage of this method (with 1 argument) is namespace naive - the argument have to be qualified attribute name with the same prefix as in parsed document. 

=item ah($unprefixedattrname, $namespace)

B<a>ttribute B<h>ash. If both arguments are defined, it returns the value of specified attribute unprefixed name in specified namespace.

 print "attrval of 'a' in 'first_ns' in 'desc' element: ".$$xml{0}{2}{0}->ah('a','first_ns')."\n";

=item ah($unprefixedattrname, undef)

B<a>ttribute B<h>ash. If second argument is not defined but present, it returns the hash or hashref of attribute values of all namespaces, where such attribute unprefixed name actually occurs.

 print "values of 'a' attrs of 'desc' element:\n";
 for (my %h = $$xml{0}{meta}{desc}->ah('a',undef); 
      my ($key, $val) = each %h; 
      print " '$key'='$val'\n"){}; 

=item ah(undef, $namespace)

B<a>ttribute B<h>ash. If first argument is not defined, it returns the hash or hashref of attributes in specified namespace.

 print "attributes of 'desc' element in 'second_ns':\n";
 for (my %h = $$xml{0}{meta}{desc}->ah(undef,'second_ns'); 
      my ($key, $val) = each %h; 
      print " '$key'='$val'\n"){}; 

=item ah(undef, undef)

B<a>ttribute B<h>ash. If both arguments are not defined but present, it returns the hash or hashref of attributes in the element's namespace.

 print "attributes of 'p1:desc' element in its namespace:\n";
 for (my %h = $$xml{0}{meta}{'p1:desc'}->ah(undef,undef); 
      my ($key, $val) = each %h; 
      print " '$key'='$val'\n"){};

Remember, that unprefixed attribute does NOT inherit namespace from its element.

=item eh() 

B<e>lement B<h>ash(ref). Returns hash or hashref (depends on calling context) of child elements. If more than one child element have the same qualified name, only the first one is present in return. 

 print "hash of child elements of 'sections':\n";
 for (my %h = $$xml{0}{sections}->eh(); 
      my ($key, $val) = each %h; 
      print " '$key'='".$val->sr."'\n"){}; 

=item eh($childname) 

B<e>lement B<h>ash. Returns the first child element with specified name. 

 print "first section: ".$$xml{0}{sections}->eh('section')->sr."\n";

=item ea()

B<e>lement B<a>rray(ref). Returns the array or arrayref of child elements.

 print "all childelements of sections:\n";
 foreach ($$xml{0}{sections}->ea) {
     print " element name:".$_->en."\n";
 }

=item ea($index)

B<e>lement B<a>rray. Returns the $index'th child element.

 print "second childelement of sections: ".$$xml{0}{sections}->ea(1)->sr."\n";

=item ta()

B<t>ext B<a>rray(ref). Returns array(ref) of all textnodes, including CDATA sections.

 print "all texts under <text>:\n";
 foreach ($$xml{0}{sections}{text}->ta) {
     print " piece of text:".$_."\n";
 }

=item ta($index)

B<t>ext B<a>rray. Returns $index'th textnode under element, including CDATA sections.

 print "second text under <text>: ".$$xml{0}{sections}{text}->ta(1)."\n";

=item ca()

B<c>data B<a>rray(ref). Returns array(ref) of CDATA sections.

 print "all cdatas under <text>:\n";
 foreach ($$xml{0}{sections}{text}->ca) {
     print " cdata: ".$_."\n";
 }

=item ca($index)

B<c>data B<a>rray. Returns $index'th CDATA section under element.

 print "first cdata section under <text>: ".$$xml{0}{sections}{text}->ca(0)."\n";

=item ts()

B<t>ext B<s>erialized. Returns all textnodes, serialized into scalar string.

 print "whole serialized text under <text>:".$$xml{0}{sections}{text}->ts."\n";

=item pa()

B<p>rocessing instruction B<a>rray(ref). Returns array(ref) of all processing instructions if called without arguments. Items of returned array are arrayrefs of two items, target and body.

 print "processing instructions under rootelement:\n";
 foreach ($$xml{0}->pa) {
     print " target:$$_[0] body:$$_[1]\n";
 }

=item pa($index)

B<p>rocessing instruction B<a>rray. Returns $index'th processing instruction under element. Returned processing instruction is arrayref of two items, target and body.

 print "first processing instruction under rootelement: ".join(' ',@{$$xml{0}->pa(0)})."\n";

=item ph()

B<p>rocessing instruction B<h>ash(ref). Returns the hash(ref) of processing instructions (the first occur of target wins) if called without arguments. 

 print "processing instructions with different targets under rootelement:\n";
 for (my %h = $$xml{0}->ph(); 
      my ($key, $val) = each %h; 
      print " '$key'='".$val."'\n"){};  

=item ph($target)

B<p>rocessing instruction B<h>ash. Returns the first processing instruction with specified target. 

 print "first processing instruction having target 'first' under rootelement: ".$$xml{0}->ph('first')."\n";

=item na()

B<n>ote B<a>rray(ref). Returns array(ref) of all comments if called without arguments.

 print "notes under rootelement:\n";
 foreach ($$xml{0}->na) {
     print " $_\n";
 }

=item na($index)

B<n>ote B<a>rray. Returns $index'th note under element.

 print "second note under rootelement: ".$$xml{0}->na(1)."\n";

=item a($index)

B<a>ll. Returns internal representation of element. Helpfull if the order of mixed elements, text nodes, PI's etc. does matter. See the code, for instance body of sr() method.

=item sr()

B<s>eB<r>ialize.

 print "whole document, serialized:\n";
 print $xml->sr;

Returns serialized element or root node. For attribute values, it outputs apostrophes as delimiters, escaping ampersands, apostrophes and left brackets inside. For text values, it escapes ampersands, left brackets and ]]> sequence (the last one to ]]&gt;). For better readability, the "\n" is appended when serializing child of root node which occurs before root element (xml declaration, doctype declaration, comment, processing instruction).

=back

=head1 SEE ALSO

XML::Parser::Expat

XML::Simple for much more sophisticated XML2perlstruct transformations.

XML::Twig for parsing and traversing huge xml documents.

XML::LibXML for more complex review of the XML possibilities in Perl.

=head1 AUTHOR

Jan Poslusny aka Pajout, C<< <pajout at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-trivial at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Trivial>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Trivial

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Trivial>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Trivial>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Trivial>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Trivial>

=back

=head1 COPYRIGHT

Copyright 2007 Jan Poslusny.

=head1 LICENSE 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


