## -*- cperl -*-

package XML::DT;
use 5.008006;

use strict;

use Data::Dumper;
use LWP::Simple;
use XML::DTDParser "ParseDTDFile";

use XML::LibXML ':libxml';
our $PARSER = 'XML::LibXML';

use parent 'Exporter';

use vars qw($c $u %v $q @dtcontext %dtcontextcount @dtatributes
            @dtattributes );

our @EXPORT = qw(&dt &dtstring &dturl &inctxt &ctxt &mkdtskel &inpath
                 &mkdtskel_fromDTD &mkdtdskel &tohtml &toxml &MMAPON $c %v $q $u
                 &xmltree &pathdturl @dtcontext %dtcontextcount
                 @dtatributes @dtattributes &pathdt &pathdtstring
                 &father &gfather &ggfather &root);

our $VERSION = '0.68';

=encoding utf-8

=head1 NAME

XML::DT - a package for down translation of XML files

=head1 SYNOPSIS

 use XML::DT;

 %xml=( 'music'    => sub{"Music from: $c\n"},
        'lyrics'   => sub{"Lyrics from: $v{name}\n"},
        'title'    => sub{ uc($c) },
        '-userdata => { something => 'I like' },
        '-default' => sub{"$q:$c"} );

 print dt($filename,%xml);

=head1 ABSTRACT

This module is a XML down processor. It maps tag (element)
names to functions to process that element and respective
contents.

=head1 DESCRIPTION

This module processes XML files with an approach similar to
OMNIMARK. As XML parser it uses XML::LibXML module in an independent
way.

You can parse HTML files as if they were XML files. For this, you must
supply an extra option to the hash:

 %hander = ( -html => 1,
             ...
           );

You can also ask the parser to recover from XML errors:

 %hander = ( -recover => 1,
             ...
           );

=head1 Functions

=head2 dt

Down translation function C<dt> receives a filename and a set of
expressions (functions) defining the processing and associated values
for each element.

=head2 dtstring

C<dtstring> works in a similar way with C<dt> but takes input from a
string instead of a file.

=head2 dturl

C<dturl> works in a similar way with C<dt> but takes input from an
Internet url instead of a file.

=head2 pathdt

The C<pathdt> function is a C<dt> function which can handle a subset
of XPath on handler keys. Example:

 %handler = (
   "article/title"        => sub{ toxml("h1",{},$c) },
   "section/title"        => sub{ toxml("h2",{},$c) },
   "title"                => sub{ $c },
   "//image[@type='jpg']" => sub{ "JPEG: <img src=\"$c\">" },
   "//image[@type='bmp']" => sub{ "BMP: sorry, no bitmaps on the web" },
 )

 pathdt($filename, %handler);

Here are some examples of valid XPath expressions under XML::DT:

 /aaa
 /aaa/bbb
 //ccc                           - ccc somewhere (same as "ccc")
 /*/aaa/*
 //*                             - same as "-default"
 /aaa[@id]                       - aaa with an attribute id
 /*[@*]                          - root with an attribute
 /aaa[not(@name)]                - aaa with no attribute "name"
 //bbb[@name='foo']              - ... attribute "name" = "foo"
 /ccc[normalize-space(@name)='bbb']
 //*[name()='bbb']               - complex way of saying "//bbb"
 //*[starts-with(name(),'aa')]   - an element named "aa.*"
 //*[contains(name(),'c')]       - an element       ".*c.*"
 //aaa[string-length(name())=4]                     "...."
 //aaa[string-length(name())&lt;4]                  ".{1,4}"
 //aaa[string-length(name())&gt;5]                  ".{5,}"

Note that not all XPath is currently handled by XML::DT. A lot of
XPath will never be added to XML::DT because is not in accordance with
the down translation model. For more documentation about XPath check
the specification at http://www.w3c.org or some tutorials under
http://www.zvon.org

=head2 pathdtstring

Like the C<dtstring> function but supporting XPath.

=head2 pathdturl

Like the C<dturl> function but supporting XPath.


=head2 ctxt

Returns the context element of the currently being processed
element. So, if you call C<ctxt(1)> you will get your father element,
and so on.

=head2 inpath

C<inpath(pattern)> is true if the actual element path matches the
provided pattern. This function is meant to be used in the element
functions in order to achieve context dependent processing.

=head2 inctxt

C<inctxt(pattern)> is true if the actual element father matches the
provided pattern.

=head2 toxml

This is the default "-default" function. It can be used to generate
XML based on C<$c> C<$q> and C<%v> variables. Example: add a new
attribute to element C<ele1> without changing it:

   %handler=( ...
     ele1 => sub { $v{at1} = "v1"; toxml(); },
   )

C<toxml> can also be used with 3 arguments: tag, attributes and contents

   toxml("a",{href=> "http://local/f.html"}, "example")

returns:

 <a href='http://local/f.html'>example</a>

Empty tags are written as empty tags. If you want an empty tag with opening and
closing tags, then use the C<tohtml>.

=head2 tohtml

See C<toxml>.

=head2 xmltree

This simple function just makes a HASH reference:

 { -c => $c, -q => $q, all_the_other_attributes }

The function C<toxml> understands this structure and makes XML with it.

=head2 mkdtskel

Used by the mkdtskel script to generate automatically a XML::DT perl
script file based on an XML file. Check C<mkdtskel> manpage for
details.

=head2 mkdtskel_fromDTD

Used by the mkdtskel script to generate automatically a XML::DT perl
script file based on an DTD file. Check C<mkdtskel> manpage for
details.

=head2 mkdtdskel

Used by the mkdtskel script to generate automatically a XML::DT perl
script file based on a DTD file. Check C<mkdtdskel> manpage for
details.

=head1 Accessing parents

With XML::DT you can access an element parent (or grand-parent)
attributes, till the root of the XML document.

If you use c<$dtattributes[1]{foo} = 'bar'> on a processing function,
you are defining the attribute C<foo> for that element parent.

In the same way, you can use C<$dtattributes[2]> to access the
grand-parent. C<$dtattributes[-1]> is, as expected, the XML document
root element.

There are some shortcuts:

=over 4

=item C<father>

=item C<gfather>

=item C<ggfather>

You can use these functions to access to your C<father>, grand-father
(C<gfather>) or great-grand-father (C<ggfather>):

   father("x"); # returns value for attribute "x" on father element
   father("x", "value"); # sets value for attribute "x" on father
                                 # element

You can also use it directly as a reference to C<@dtattributes>:

   father->{"x"};           # gets the attribute
   father->{"x"} = "value"; # sets the attribute
   $attributes = father;            # gets all attributes reference


=item C<root>

You can use it as a function to access to your tree root element.

   root("x");          # gets attribute C<x> on root element
   root("x", "value"); # sets value for attribute C<x> on root

You can also use it directly as a reference to C<$dtattributes[-1]>:

   root->{"x"};           # gets the attribute x
   root->{"x"} = "value"; # sets the attribute x
   $attributes = root;    # gets all attributes reference

=back

=head1 User provided element processing functions

The user must provide an HASH with a function for each element, that
computes element output. Functions can use the element name C<$q>, the
element content C<$c> and the attribute values hash C<%v>.

All those global variables are defined in C<$CALLER::>.

Each time an element is find the associated function is called.

Content is calculated by concatenation of element contents strings and
interior elements return values.

=head2 C<-default> function

When a element has no associated function, the function associated
with C<-default> called. If no C<-default> function is defined the
default function returns a XML like string for the element.

When you use C</-type> definitions, you often need do set C<-default>
function to return just the contents: C<sub{$c}>.

=head2 C<-outputenc> option

C<-outputenc> defines the output encoding (default is Unicode UTF8).

=head2 C<-inputenc> option

C<-inputenc> forces a input encoding type. Whenever that is possible,
define the input encoding in the XML file:

 <?xml version='1.0' encoding='ISO-8859-1'?>

=head2 C<-pcdata> function

C<-pcdata> function is used to define transformation over the
contents.  Typically this function should look at context (see
C<inctxt> function)

The default C<-pcdata> function is the identity

=head2 C<-cdata> function

You can process C<<CDATA>> in a way different from pcdata. If you
define a C<-cdata> method, it will be used. Otherwise, the C<-pcdata>
method is called.

=head2 C<-begin> function

Function to be executed before processing XML file.

Example of use: initialization of side-effect variables

=head2 C<-end> function

Function to be executed after processing XML file.  I can use C<$c>
content value.  The value returned by C<-end> will be the C<dt> return
value.

Example of use: post-processing of returned contents

=head2 C<-recover> option

If set, the parser will try to recover in XML errors.

=head2 C<-html> option

If set, the parser will try to recover in errors. Note that this
differs from the previous one in the sense it uses some knowledge of
the HTML structure for the recovery.

=head2 C<-userdata> option

Use this to pass any information you like to your handlers. The data
structure you pass in this option will be available as C<< $u >> in
your code. -- New in 0.62.


=head1 Elements with values other than strings (C<-type>)

By default all elements return strings, and contents (C<$c>) is the
concatenation of the strings returned by the sub-elements.

In some situations the XML text contains values that are better
processed as a structured type.

The following types (functors) are available:

=over 4

=item THE_CHILD

Return the result of processing the only child of the element.

=item LAST_CHILD

Returns the result of processing the last child of the element.

=item STR

concatenates all the sub-elements returned values (DEFAULT) all the
sub-element should return strings to be concatenated;

=item SEQ

makes an ARRAY with all the sub elements contents; attributes are
ignored (they should be processed in the sub-element). (returns a ref)
If you have different types of sub-elements, you should use SEQH

=item SEQH

makes an ARRAY of HASH with all the sub elements (returns a ref); for
each sub-element:

 -q  => element name
 -c  => contents
 at1 => at value1    for each attribute

=item MAP

makes an HASH with the sub elements; keys are the sub-element names,
values are their contents. Attributes are ignored. (they should be
processed in the sub-element) (returns a ref)

=item MULTIMAP

makes an HASH of ARRAY; keys are the sub-element names; values are
lists of contents; attributes are ignored (they should be processed in
the sub-element); (returns a ref)

=item MMAPON(element-list)

makes an HASH with the sub-elements; keys are the sub-element names,
values are their contents; attributes are ignored (they should be
processed in the sub-element); for all the elements contained in the
element-list, it is created an ARRAY with their contents. (returns a
ref)

=item XML

return a reference to an HASH with:

 -q  => element name
 -c  => contents
 at1 => at value1    for each attribute

=item ZERO

don't process the sub-elements; return ""

=back

When you use C</-type> definitions, you often need do set C<-default>
function returning just the contents C<sub{$id}>.

=head2 An example:

 use XML::DT;
 %handler = ( contacts => sub{ [ split(";",$c)] },
              -default => sub{$c},
	      -type    => { institution => 'MAP',
	                    degrees     =>  MMAPON('name')
		            tels        => 'SEQ' }
            );
 $a = dt ("f.xml", %handler);

with the following f.xml

 <degrees>
    <institution>
       <id>U.M.</id>
       <name>University of Minho</name>
       <tels>
          <item>1111</item>
          <item>1112</item>
          <item>1113</item>
       </tels>
       <where>Portugal</where>
       <contacts>J.Joao; J.Rocha; J.Ramalho</contacts>
    </institution>
    <name>Computer science</name>
    <name>Informatica </name>
    <name> history </name>
 </degrees>

would make $a

 { 'name' => [ 'Computer science',
               'Informatica ',
	       ' history ' ],
   'institution' => { 'tels' => [ 1111, 1112, 1113 ],
  	              'name' => 'University of Minho',
	              'where' => 'Portugal',
	              'id' => 'U.M.',
	              'contacts' => [ 'J.Joao',
			       ' J.Rocha',
			       ' J.Ramalho' ] } };


=head1 DT Skeleton generation

It is possible to build an initial processor program based on an example

To do this use the function C<mkdtskel(filename)>.

Example:

 perl -MXML::DT -e 'mkdtskel "f.xml"' > f.pl

=head1 DTD skeleton generation

It makes a naive DTD based on an example(s).

To do this use the function C<mkdtdskel(filename*)>.

Example:

 perl -MXML::DT -e 'mkdtdskel "f.xml"' > f.dtd

=head1 SEE ALSO

mkdtskel(1) and mkdtdskel(1)

=head1 AUTHORS

Home for XML::DT;

http://natura.di.uminho.pt/~jj/perl/XML/

Jose Joao Almeida, <jj@di.uminho.pt>

Alberto Manuel Simões, <albie@alfarrabio.di.uminho.pt>

=head1 ACKNOWLEDGEMENTS

Michel Rodriguez    <mrodrigu@ieee.org>

José Carlos Ramalho <jcr@di.uminho.pt>

Mark A. Hillebrand

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2012 Project Natura.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut



our %ty = ();

sub dt {
  my ($file, %xml)=@_;
  my ($parser, $tree);

  # Treat -decl option
  my $declr = "";
  if ($xml{-declr}) {
    if ($xml{-outputenc}) {
      $declr = "<?xml version=\"1.0\" encoding=\"$xml{-outputenc}\"?>\n";
    } else {
      $declr = "<?xml version=\"1.0\"?>\n";
    }
  }

  %ty = ();
  %ty = (%{$xml{'-type'}}) if defined($xml{'-type'});
  $ty{-ROOT} = "NONE";

  &{$xml{-begin}} if $xml{-begin};

  # TODO --- how to force encoding with XML::LibXML?
  # $xml{-inputenc}

  # create a new LibXML parser
  $parser = XML::LibXML->new();

  #### We don't wan't DT to load everytime the DTD (I Think!)
  $parser->validation(0);
  # $parser->expand_xinclude(0);  # testing
  $parser->load_ext_dtd(0);
  $parser->expand_entities(0);
  $parser->expand_xincludes(1) if $xml{'-xinclude'};

  # parse the file
  my $doc;
  if ( $xml{'-recover'}) {
      $parser->recover(1);
      eval {
          local $SIG{__WARN__} = sub{};
          $doc = $parser->parse_file($file);
      };
      return undef if !$doc;
  }
  elsif ( $xml{'-html'}) {
      $parser->recover(1);
      eval {
          local $SIG{__WARN__} = sub{};
          $doc = $parser->parse_html_file($file);
      };
      return undef if !$doc;
  }
  else {
      $doc = $parser->parse_file($file)
  }

  # get the document root element
  $tree = $doc->getDocumentElement();

  my $return = "";
  # execute End action if it exists
  if($xml{-end}) {
      $c = _omni("-ROOT", \%xml, $tree);
      $return = &{$xml{-end}}
  } else {
      $return = _omni("-ROOT",\%xml, $tree)
  }

  if ($declr) {
    return $declr.$return;
  } else {
    return $return;
  }
}


sub ctxt {
  my $level = $_[0];
  $dtcontext[-$level-1];
}

sub inpath {
  my $pattern = shift ;
	join ("/", @dtcontext) =~ m!\b$pattern\b!;
}


sub inctxt {
  my $pattern = shift ;
  # see if is in root context...
  return 1 if (($pattern eq "^" && @dtcontext==1) || $pattern eq ".*");
  join("/", @dtcontext) =~ m!$pattern/[^/]*$! ;
}

sub father {
  my ($a,$b)=@_;
  if   (defined($b)){$dtattributes[1]{$a} = $b}
  elsif(defined($a)){$dtattributes[1]{$a} }
  else              {$dtattributes[1]}
}

sub gfather {
  my ($a,$b)=@_;
  if   (defined($b)){$dtattributes[2]{$a} = $b}
  elsif(defined($a)){$dtattributes[2]{$a} }
  else              {$dtattributes[2]}
}


sub ggfather {
  my ($a,$b)=@_;
  if   (defined($b)){$dtattributes[3]{$a} = $b}
  elsif(defined($a)){$dtattributes[3]{$a} }
  else              {$dtattributes[3]}
}


sub root {         ### the root
  my ($a,$b)=@_;
  if   (defined($b)){$dtattributes[-1]{$a} = $b }
  elsif(defined($a)){$dtattributes[-1]{$a} }
  else              {$dtattributes[-1] }
}

sub pathdtstring{
  my $string = shift;
  my %h = _pathtodt(@_);
  return dtstring($string,%h);
}



sub pathdturl{
  my $url = shift;
  my %h = _pathtodt(@_);
  return dturl($url,%h);
}



sub dturl{
  my $url = shift;
  my $contents = get($url);
  if ($contents) {
    return dtstring($contents, @_);
  } else {
    return undef;
  }
}



sub dtstring {
  my ($string, %xml)=@_;
  my ($parser, $tree);

  my $declr = "";
  if ($xml{-declr}) {
    if ($xml{-outputenc}) {
      $declr = "<?xml version=\"1.0\" encoding=\"$xml{-outputenc}\"?>\n";
    } else {
      $declr = "<?xml version=\"1.0\"?>\n";
    }
  }

  $xml{'-type'} = {} unless defined $xml{'-type'};
  %ty = (%{$xml{'-type'}}, -ROOT => "NONE");

  # execute Begin action if it exists
  if ($xml{-begin}) {
      &{$xml{-begin}}
  }

  if ($xml{-inputenc}) {
      $string = XML::LibXML::encodeToUTF8($xml{-inputenc}, $string);
  }

  # create a new LibXML parser
  $parser = XML::LibXML->new();
  $parser->validation(0);
  $parser->load_ext_dtd(0);
  $parser->expand_entities(0);

  # parse the string
  my $doc;
  if ( $xml{'-recover'}) {
      $parser->recover(1);
      eval {
          local $SIG{__WARN__} = sub{};
          $doc = $parser->parse_string($string);
      };
      return undef if !$doc;
  }
  elsif ( $xml{'-html'}) {
      $parser->recover(1);
      eval{
          local $SIG{__WARN__} = sub{};
          $doc = $parser->parse_html_string($string);
      };
      #    if ($@) { return undef; }
      return undef unless defined $doc;
  } else {
      $doc = $parser->parse_string($string);
  }

  # get the document root element
  $tree = $doc->getDocumentElement();

  my $return;

  # Check if we have an end function
  if ($xml{-end}) {
    $c = _omni("-ROOT", \%xml, $tree);
    $return = &{$xml{-end}}
  } else {
    $return = _omni("-ROOT", \%xml, $tree)
  }

  if ($declr) {
    return $declr.$return;
  } else {
    return $return;
  }
}



sub pathdt{
  my $file = shift;
  my %h = _pathtodt(@_);
  return dt($file,%h);
}



# Parsing dos predicados do XPath
sub _testAttr {
  my $atr = shift;
  for ($atr) {
    s/name\(\)/'$q'/g;
    # s/\@([A-Za-z_]+)/'$v{$1}'/g;
    s/\@([A-Za-z_]+)/defined $v{$1}?"'$v{$1}'":"''"/ge;
    s/\@\*/keys %v?"'1'":"''"/ge;
    if (/^not\((.*)\)$/) {
      return ! _testAttr($1);
    } elsif (/^('|")([^\1]*)(\1)\s*=\s*('|")([^\4]*)\4$/) {
      return ($2 eq $5);
    } elsif (/^(.*?)normalize-space\((['"])([^\2)]*)\2\)(.*)$/) {
      my ($back,$forward)=($1,$4);
      my $x = _normalize_space($3);
      return _testAttr("$back'$x'$forward"); 
    } elsif (/starts-with\((['"])([^\1))]*)\1,(['"])([^\3))]*)\3\)/) {
      my $x = _starts_with($2,$4);
      return $x;
    } elsif (/contains\((['"])([^\1))]*)\1,(['"])([^\3))]*)\3\)/) {
      my $x = _contains($2,$4);
      return $x; 
    } elsif (/^(.*?)string-length\((['"])([^\2]*)\2\)(.*)$/) {
      my ($back,$forward) = ($1,$4);
      my $x = length($3);
      return _testAttr("$back$x$forward");
    } elsif (/^(\d+)\s*=(\d+)$/) {
      return ($1 == $2);
    } elsif (/^(\d+)\s*&lt;(\d+)$/) {
      return ($1 < $2);
    } elsif (/^(\d+)\s*&gt;(\d+)$/) {
      return ($1 > $2);
    } elsif (/^(['"])([^\1]*)\1$/) {
      return $2;
    }
  }
  return 0; #$atr;
}



# Funcao auxiliar de teste de predicados do XPath
sub _starts_with {
  my ($string,$preffix) = @_;
  return 0 unless ($string && $preffix);
  return 1 if ($string =~ m!^$preffix!);
  return 0;
}


# Funcao auxiliar de teste de predicados do XPath
sub _contains {
  my ($string,$s) = @_;
  return 0 unless ($string && $s);
  return 1 if ($string =~ m!$s!);
  return 0;
}


# Funcao auxiliar de teste de predicados do XPath
sub _normalize_space {
  my $z = shift;
  $z =~ /^\s*(.*?)\s*$/;
  $z = $1;
  $z =~ s!\s+! !g;
  return $z;
}


sub _pathtodt {
  my %h = @_;
  my %aux=();
  my %aux2=();
  my %n = ();
  my $z;
  for $z (keys %h) {
    # TODO - Make it more generic
    if ( $z=~m{\w+(\|\w+)+}) {
      my @tags = split /\|/, $z;
      for(@tags) {
	$aux2{$_}=$h{$z}
      }
    }
    elsif ( $z=~m{(//|/|)(.*)/([^\[]*)(?:\[(.*)\])?} ) {
      my ($first,$second,$third,$fourth) = ($1,$2,$3,$4);
      if (($first eq "/") && (!$second)) {
	$first = "";
	$second = '.*';
	$third =~ s!\*!-default!;
      } else {
	$second =~ s!\*!\[^/\]\+!g;
	$second =~ s!/$!\(/\.\*\)\?!g;
	$second =~ s!//!\(/\.\*\)\?/!g;
	$third =~ s!\*!-default!g;
      }
      push( @{$aux{$third}} , [$first,$second,$h{$z},$fourth]);
    }
    else                           { $aux2{$z}=$h{$z};}
  }
  for $z (keys %aux){
    my $code = sub {
      my $l;
      for $l (@{$aux{$z}}) {
	my $prefix = "";
	$prefix = "^" unless (($l->[0]) or ($l->[1]));
	$prefix = "^" if (($l->[0] eq "/") && ($l->[1]));
	if ($l->[3]) {
	  if(inctxt("$prefix$l->[1]") && _testAttr($l->[3])) 
	    {return &{$l->[2]}; }
	} else {
	  if(inctxt("$prefix$l->[1]")) {return &{$l->[2]};}
	}
      }
      return &{ $aux2{$z}} if $aux2{$z} ;
      return &{ $h{-default}} if $h{-default};
      &toxml();
    };
    $n{$z} = $code;
  }
  for $z (keys %aux2){
    $n{$z} ||= $aux2{$z} ;
  }
  return %n;
}



sub _omni {
    my ($par, $xml, @l) = @_;
    my $defaulttype =
      (exists($xml->{-type}) && exists($xml->{-type}{-default}))
        ?
          $xml->{-type}{-default} : "STR";
    my $type = $ty{$par} || $defaulttype;
    my %typeargs = ();

  if (ref($type) eq "mmapon") {
      $typeargs{$_} = 1  for (@$type);
      $type = "MMAPON";
  }

  my $r ;
  if( $type eq 'STR')                                   { $r = "" }
  elsif( $type eq 'THE_CHILD' or $type eq 'LAST_CHILD') { $r = 0  }
  elsif( $type eq 'SEQ'  or $type eq "ARRAY")           { $r = [] }
  elsif( $type eq 'SEQH' or $type eq "ARRAYOFHASH")     { $r = [] }
  elsif( $type eq 'MAP'  or $type eq "HASH")            { $r = {} }
  elsif( $type eq 'MULTIMAP')                           { $r = {} }
  elsif( $type eq 'MMAPON' or $type eq "HASHOFARRAY")   { $r = {} }
  elsif( $type eq 'NONE')                               { $r = "" }
  elsif( $type eq 'ZERO')                               { return "" }

  my ($name, $val, @val, $atr, $aux);

    $u = $xml->{-userdata};
  while(@l) {
      my $tree = shift @l;
      next unless $tree;

      $name = ref($tree) eq "XML::LibXML::CDATASection" ? "-pcdata" : $tree->getName();

      if (ref($tree) eq "XML::LibXML::CDATASection") {
          $val = $tree->getData();

          $name = "-cdata";
          $aux = (defined($xml->{-outputenc}))?_fromUTF8($val,$xml->{-outputenc}):$val;

          if (defined($xml->{-cdata})) {
              push(@dtcontext,"-cdata");
              $c = $aux;
              $aux = &{$xml->{-cdata}};
              pop(@dtcontext);
          } elsif (defined($xml->{-pcdata})) {
              push(@dtcontext,"-pcdata");
              $c = $aux;
              $aux = &{$xml->{-pcdata}};
              pop(@dtcontext);
          }

      } elsif (ref($tree) eq "XML::LibXML::Comment") {
          ### At the moment, treat as Text
          ### We will need to change this, I hope!
          $val = "";
          $name = "-pcdata";
          $aux= (defined($xml->{-outputenc}))?_fromUTF8($val, $xml->{-outputenc}):$val;
          if (defined($xml->{-pcdata})) {
              push(@dtcontext,"-pcdata");
              $c = $aux;
              $aux = &{$xml->{-pcdata}};
              pop(@dtcontext);
          }
      }
      elsif (ref($tree) eq "XML::LibXML::Text") {
          $val = $tree->getData();

          $name = "-pcdata";
          $aux = (defined($xml->{-outputenc}))?_fromUTF8($val,$xml->{-outputenc}):$val;

          if (defined($xml->{-pcdata})) {
              push(@dtcontext,"-pcdata");
              $c = $aux;
              $aux = &{$xml->{-pcdata}};
              pop(@dtcontext);
          }

      } elsif (ref($tree) eq "XML::LibXML::Element") {
          my %atr = _nodeAttributes($tree);
          $atr = \%atr;

          if (exists($xml->{-ignorecase})) {
              $name = lc($name);
              for (keys %$atr) {
                  my ($k,$v) = (lc($_),$atr->{$_});
                  delete($atr->{$_});
                  $atr->{$k} = $v;
              }
          }

          push(@dtcontext,$name);
          $dtcontextcount{$name}++;
          unshift(@dtatributes, $atr);
          unshift(@dtattributes, $atr);
          $aux = _omniele($xml, $name, _omni($name, $xml, ($tree->getChildnodes())), $atr);
          shift(@dtatributes);
          shift(@dtattributes);
          pop(@dtcontext); $dtcontextcount{$name}--;
      } elsif (ref($tree) eq "XML::LibXML::Node") {
          if ($tree->nodeType == XML_ENTITY_REF_NODE) {
              # if we get here, is because we are not expanding entities (I think)
              if ($tree->textContent) {
                  $aux = $tree->textContent;
              } else {
                  $aux = '&'.$tree->nodeName.';';
              }
          } else {
              print STDERR "Not handled, generic node of type: [",$tree->nodeType,"]\n";
          }
      } else {
          print STDERR "Not handled: [",ref($tree),"]\n";
      }

      if    ($type eq "STR"){ if (defined($aux)) {$r .= $aux} ;}
      elsif ($type eq "THE_CHILD" or $type eq "LAST_CHILD"){
          $r = $aux unless _whitepc($aux, $name); }
      elsif ($type eq "SEQ" or $type eq "ARRAY"){
          push(@$r, $aux) unless _whitepc($aux, $name);}
      elsif ($type eq "SEQH" or $type eq "ARRAYHASH"){
          push(@$r,{"-c" => $aux,
                    "-q" => $name,
                    _nodeAttributes($tree)
                   }) unless _whitepc($aux,$name);
      }
      elsif($type eq "MMAPON"){
          if(not _whitepc($aux,$name)){
              if(! $typeargs{$name}) {
                  warn "duplicated tag '$name'\n" if(defined($r->{$name}));
                  $r->{$name} = $aux }
              else { push(@{$r->{$name}},$aux) unless _whitepc($aux,$name)}}
      }
      elsif($type eq "MAP" or $type eq "HASH"){
          if(not _whitepc($aux,$name)){
              warn "duplicated tag '$name'\n" if(defined($r->{$name}));
              $r->{$name} = $aux }}
      elsif($type eq "MULTIMAP"){
          push(@{$r->{$name}},$aux) unless _whitepc($aux,$name)}
      elsif($type eq "NONE"){ $r = $aux;}
      else { $r="undefined type !!!"}
  }
  $r;
}



sub _omniele {
  my $xml = shift;
  my $aux;
  ($q, $c, $aux) = @_;

  %v = %$aux;

  if (defined($xml->{-outputenc})) {
    for (keys %v){
      $v{$_} = _fromUTF8($v{$_}, $xml->{-outputenc})
    }
  }

  if (defined $xml->{$q})
    { &{$xml->{$q}} }
  elsif (defined $xml->{'-default'})
    { &{$xml->{'-default'}} }
  elsif (defined $xml->{'-tohtml'})
    { tohtml() }
  else
    { toxml() }
}



sub xmltree { +{'-c' => $c, '-q' => $q, %v} }

sub tohtml {
    my ($q,$v,$c);
	
    if (not @_) {
        ($q,$v,$c) = ($XML::DT::q, \%XML::DT::v, $XML::DT::c);
    } elsif (ref($_[0])) {
        $c = shift;
    } else {
        ($q,$v,$c) = @_;
    }
	
    if (not ref($c)) {
        if ($q eq "-pcdata") {
            return $c
        } elsif ($q eq "link" || $q eq "br" || $q eq "hr" || $q eq "img") {
            return _openTag($q,$v)
	} else {
            return _openTag($q,$v) . "$c</$q>"
        }
    }
    elsif (ref($c) eq "HASH" && $c->{'-q'} && $c->{'-c'}) {
        my %a = %$c;
        my ($q,$c) = delete @a{"-q","-c"};
        tohtml($q,\%a,(ref($c)?tohtml($c):$c));
    }
    elsif (ref($c) eq "HASH") {
        _openTag($q,$v).
          join("",map {($_ ne "-pcdata")
                         ? ( (ref($c->{$_}) eq "ARRAY")
                             ? "<$_>".
                             join("</$_>\n<$_>", @{$c->{$_}}).
                             "</$_>\n" 
                             : tohtml($_,{},$c->{$_})."\n" )
                           : () }
               keys %{$c} ) .
                 "$c->{-pcdata}</$q>" } ########  "NOTYetREady"
    elsif (ref($c) eq "ARRAY") {
        if (defined($q) && exists($ty{$q}) && $ty{$q} eq "SEQH") {
            tohtml($q,$v,join("\n",map {tohtml($_)} @$c))
        } elsif (defined $q) {
            tohtml($q,$v,join("",@{$c}))
        } else {
            join("\n",map {(ref($_)?tohtml($_):$_)} @$c)
        }
    }
}

sub toxml {
  my ($q,$v,$c);

  if (not @_) {
    ($q, $v, $c) = ($XML::DT::q, \%XML::DT::v, $XML::DT::c);
  } elsif (ref($_[0])) {
    $c = shift;
  } else {
    ($q, $v, $c) = @_;
  }

  if (not ref($c)) {
    if ($q eq "-pcdata") {
      return $c
    } elsif ($c eq "") {
      return _emptyTag($q,$v)
    } else {
      return _openTag($q,$v) . "$c</$q>"
    }
  }
  elsif (ref($c) eq "HASH" && $c->{'-q'} && $c->{'-c'}) {
    my %a = %$c;
    my ($q,$c) = delete @a{"-q","-c"};
    ###   _openTag($q,\%a).toxml($c).).
    ###   toxml($q,\%a,join("\n",map {toxml($_)} @$c))
    toxml($q,\%a,(ref($c)?toxml($c):$c));
  }
  elsif (ref($c) eq "HASH") {
    _openTag($q,$v).
      join("",map {($_ ne "-pcdata")
		     ? ( (ref($c->{$_}) eq "ARRAY")
			 ? "<$_>".
			 join("</$_>\n<$_>", @{$c->{$_}}).
			 "</$_>\n" 
			 : toxml($_,{},$c->{$_})."\n" )
		       : () }
	   keys %{$c} ) .
	     "$c->{-pcdata}</$q>" } ########  "NOTYetREady"
  elsif (ref($c) eq "ARRAY") {
    if (defined($q) && exists($ty{$q}) && $ty{$q} eq "SEQH") {
      toxml($q,$v,join("\n",map {toxml($_)} @$c))
    } elsif (defined $q) {
      toxml($q,$v,join("",@{$c}))
    } else {
      join("\n",map {(ref($_)?toxml($_):$_)} @$c)
    }
  }
}


sub _openTag{
  "<$_[0]". join("",map {" $_=\"$_[1]{$_}\""} keys %{$_[1]} ).">"
}

sub _emptyTag{
  "<$_[0]". join("",map {" $_=\"$_[1]{$_}\""} keys %{$_[1]} )."/>"
}


sub mkdtskel_fromDTD {
  my $filename = shift;
  my $file = ParseDTDFile($filename);

  print <<'PERL';
#!/usr/bin/perl
use warnings;
use strict;
use XML::DT;
my $filename = shift;

# Variable Reference
#
# $c - contents after child processing
# $q - element name (tag)
# %v - hash of attributes

my %handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{"<$q>$c</$q>"},
PERL


  for (sort keys %{$file}) {
    print "     '$_' => sub { },";
    print " # attributes: ",
      join(", ", keys %{$file->{$_}{attributes}}) if exists($file->{$_}{attributes});
    print "\n";
  }


  print <<'PERL';
);

print dt($filename, %handler);
PERL

}

sub mkdtskel{
  my @files = @_;
  my $name;
  my $HTML = "";
  my %element;
  my %att;
  my %mkdtskel =
    ('-default' => sub{
       $element{$q}++;
       for (keys %v) {
	 $att{$q}{$_} = 1
       };
       ""},

     '-end' => sub{
       print <<'END';
#!/usr/bin/perl
use XML::DT;
use warnings;
use strict;
my $filename = shift;

# Variable Reference
#
# $c - contents after child processing
# $q - element name (tag)
# %v - hash of attributes

my %handler=(
#    '-outputenc' => 'ISO-8859-1',
#    '-default'   => sub{"<$q>$c</$q>"},
END
       print $HTML;
       for $name (sort keys %element) {
	 print "     '$name' => sub{ }, #";
	 print " $element{$name} occurrences;";
	 print ' attributes: ',
	   join(', ', keys %{$att{$name}}) if $att{$name};
#	 print "       \"\$q:\$c\"\n";
	 print "\n";
       }
       print <<'END';
);
print dt($filename, %handler);
END
     }
    );

  my $file = shift(@files);
  while($file =~ /^-/){
    if   ($file eq "-html")   {
        $HTML = "     '-html' => 1,\n";
        $mkdtskel{'-html'} = 1;} 
    elsif($file eq "-latin1") { $mkdtskel{'-inputenc'}='ISO-8859-1';}
    else { die("usage mktskel [-html] [-latin1] file \n")}
    $file=shift(@files)}

  dt($file,%mkdtskel)
}



sub _nodeAttributes {
  my $node = shift;
  my %answer = ();
  my @attrs = $node->getAttributes();
  for (@attrs) {
    if (ref($_) eq "XML::LibXML::Namespace") {
      # TODO: This should not be ignored, I think.
      # This sould be converted on a standard attribute with
      # key 'namespace' and respective contents
    } else {
      $answer{$_->getName()} = $_->getValue();
    }
  }
  return %answer;
}


sub mkdtdskel {
  my @files = @_; 
  my $name;
  my %att;
  my %ele;
  my %elel;
  my $root;
  my %handler=(
    '-outputenc' => 'ISO-8859-1',
    '-default'   => sub{ 
          $elel{$q}++;
          $root = $q unless ctxt(1);
          $ele{ctxt(1)}{$q} ++;
          for(keys(%v)){$att{$q}{$_} ++ } ;
        },
    '-pcdata'    => sub{ if ($c =~ /[^ \t\n]/){ $ele{ctxt(1)}{"#PCDATA"}=1 }},
  );

  while($files[0] =~ /^-/){
    if   ($files[0] eq "-html")   { $handler{'-html'} = 1;} 
    elsif($files[0] eq "-latin1") { $handler{'-inputenc'}='ISO-8859-1';}
    else { die("usage mkdtdskel [-html] [-latin1] file* \n")}
    shift(@files)}

  for my $filename (@files){
    dt($filename,%handler); 
  }

  print "<!-- DTD $root ... -->\n<!-- (C) ... " . localtime(time) ." -->\n";
  delete $elel{$root};

  for ($root, keys %elel){
    _putele($_, \%ele);
    for $name (keys(%{$att{$_}})) {
       print( "\t<!-- $name : ... -->\n");
       print( "\t<!ATTLIST $_ $name CDATA #IMPLIED >\n");
    }
  }
}

sub _putele {
  my ($e,$ele) = @_;
  my @f ;
  if ($ele->{$e}) {
    @f = keys %{$ele->{$e}};
    print "<!ELEMENT $e (", join("|", @f ),")",
      (@f >= 1 && $f[0] eq "#PCDATA" ? "" : "*"),
	" >\n";
    print "<!-- ", join(" | ", (map {"$_=$ele->{$e}{$_}"} @f )), " -->\n";
  }
  else {
    print "<!ELEMENT $e  EMPTY >\n";
  }
}

sub _whitepc {
  $_[1] eq '-pcdata' and $_[0] =~ /^[ \t\r\n]*$/
}

sub MMAPON {
  bless([@_],"mmapon")
}


sub _fromUTF8 {
  my $string = shift;
  my $encode = shift;
  my $ans = eval { XML::LibXML::decodeFromUTF8($encode, $string) };
  if ($@) {
    return $string
  } else {
    return $ans
  }
}

1;
