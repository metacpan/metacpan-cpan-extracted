package XML::Writer::Compiler;
BEGIN {
  $XML::Writer::Compiler::VERSION = '1.112060';
}

# ABSTRACT: produce aoa from tree

use strict;
use warnings;
use feature "switch";

use autodie;

use Moose;

use Carp;

sub buildclass {
    my ( $self, $pkg, $tree, $firstdepth, $prepend_lib, $fileheader ) = @_;

    my $rootnode = $tree->look_down( '_tag' => qr/./ );

    my $lol = __PACKAGE__->mklol( $tree, $firstdepth );

    my $pkgstr = __PACKAGE__->_mkpkg(
        $pkg => $lol,
        $prepend_lib, $fileheader, $rootnode->{_tag}
    );

    warn "PKG:$pkg";

    my @part = split '::', $pkg;
    my $file = $part[$#part];
    warn "PART:@part";

    use File::Spec;
    my $path = File::Spec->catdir( $prepend_lib ? $prepend_lib : (),
        @part[ 0 .. $#part - 1 ] );
    warn "PATH:$path";
    use File::Path;
    File::Path::make_path( $path, { verbose => 1 } );

    $file = File::Spec->catfile( $path, "$file.pm" );
    warn "FILE:$file";
    open( my $fh, '>', $file );

    $fh->print($pkgstr);
    $pkgstr;

}

sub mklol {
    my ( $class, $tree, $firstdepth ) = @_;
    unless ($firstdepth) {
        Carp::cluck('Assuming firstdepth == 0');
        $firstdepth = 0;
    }
    open( my $fh, '>', \my $string ) or die "Could not open string for writing";
    $tree->methodsfrom( $fh, 0, '', $firstdepth );

    use Perl::Tidy;

    perltidy( source => \$string, destination => \my $dest );
    $dest;

}

sub _mkpkg {
    my ( $self, $pkg, $lol, $prepend_lib, $extends_string, $rootnode ) = @_;

    open( my $fh, '>', \my $pkgstr ) or die "Could not open pkg for writing";

    my $extends = $extends_string ? "extends qw($extends_string)" : '';
    $extends =~ s/^\s+//g;
    $fh->printf( <<'EOPKG', $pkg, $extends, $lol, $rootnode );
package %s;
use Moose;

with qw(XML::Writer::Compiler::AutoPackage);


%s;

use Data::Dumper;
use HTML::Element::Library;




use XML::Element;

has 'data' => (
  is => 'rw', 
  trigger => \&maybe_morph
);
has 'writer' => (is => 'rw', isa => 'XML::Writer');
has 'string' => (is => 'rw', isa => 'XML::Writer::String');


%s;

sub xml {
my($self)=@_;
  my $method = '_tag_%s';
  $self->$method;
$self->writer->end;
$self;
}


1;

EOPKG

    use Perl::Tidy;

    perltidy( source => \$pkgstr, destination => \my $dest );
    $dest;

}

1;

package XML::Element;
BEGIN {
  $XML::Element::VERSION = '1.112060';
}

sub cleantag {
    my ( $self, $andattr ) = @_;
    my $tag = $self->{_tag};

    return $tag unless $andattr;

    my %attr = $self->all_external_attr;
    my $attr;
    if ( scalar keys %attr ) {
        use Data::Dumper;
        my $d = Data::Dumper->new( [ \%attr ] );
        $d->Purity(1)->Terse(1);
        $attr = $d->Dump;

        $tag .= " => $attr";

    }

    $tag;
}

sub childname {
  my ($child, $M, $D) = @_;
  if ( scalar(@$D) == 0 ) {
    sprintf '$self->_tag_%s; %s', $child->{_tag}, "\n";
  }
  else {
    sprintf '$self->%s_%s; %s', $M, $child->{_tag}, "\n";
  }
}


sub tagmethod {
    my ( $self, $tag, $divecall, $children, $derefchain ) = @_;

    my $childname;
    my $methodname = do {
        if ( scalar(@$derefchain) == 0 ) {
            "_tag_$tag";
        }
        else {
            sprintf '_tag_%s', join '_', @$derefchain;
        }
    };
    warn "METHODNAME: $methodname... derefchain: @$derefchain";


    my @children = map { ref($_) ? childname($_, $methodname, $derefchain) : () } @$children;
    my $childstr = @children ? "@children" : '$self->writer->characters($data)';

    sprintf( <<'EOSTR', $methodname, $divecall, $tag, $childstr );
  sub %s {
  my($self)=@_;

  my $root = $self->data;
%s;
  my ($attr, $data) = $self->EXTRACT($elementdata);
  $self->writer->startTag(%s => @$attr);

%s;
 $self->writer->endTag;
}
EOSTR
}

sub divecall {
    my ( $self, $derefstring ) = @_;
    use Data::Dumper;
    my $str = Dumper($derefstring);
    sprintf( <<'EOSTR', "@$derefstring" );

my $elementdata = $self->DIVE( $root, qw(%s) ) ;
 
EOSTR
}

sub methodsfrom {
    my ( $self, $fh, $depth, $derefstring, $firstdepth ) = @_;
    $fh    = *STDOUT{IO} unless defined $fh;
    $depth = 0           unless defined $depth;

    my @newderef;

    if ( $depth < $firstdepth ) {
        @newderef = ();
    }
    else {
        if ( $depth == $firstdepth ) {
            @newderef = $self->cleantag;
        }
        if ( $depth > $firstdepth ) {
            @newderef = ( @$derefstring, $self->cleantag );
        }
    }

    #warn "DEREF: @newderef";
    my @children = @{ $self->{'_content'} };
    my $divecall = $self->divecall( \@newderef );

    #warn "DIVECALL: $divecall";
    my $tagmethod =
      $self->tagmethod( $self->cleantag, $divecall, \@children, \@newderef );

    $fh->print($tagmethod);
    for (@children) {

        if ( ref $_ ) {    # element
                           #use Data::Dumper;
                           #warn Dumper($_);
            $_->methodsfrom( $fh, $depth + 1, \@newderef, $firstdepth )
              ;            # recurse
        }
        else {             # text node
            ;
        }
    }

}

1;

=head1 NAME

XML::Writer::Compiler - create XML::Writer based classes whose instances can generate, refine and extend sample XML

=head1 SYNOPSIS

 ROOT=CustomerAdd
 XML_FILE=$ROOT.xml
 OUTPUT_PKG = XML::Quickbooks::$ROOT
 HASH_DEPTH=4 #counting from 0, which level of XML file should hash keys start mapping from
 OUTPATH_PREPEND=lib
 EXTENDS=XML::Quickbooks # the XML class we generate, XML::Quickbooks::CustomerAdd has the parent XML::Quickbooks

 # Now run the compiler on the XML file to produce an XML class, which produces XML when a hashref is supplied
 # Also possible to subclass the generated XML class to customize XML generation when hashrefs are inadequate
  xwc $XML_FILE $OUTPUT_PKG $HASH_DEPTH $OUTPUT_PREPEND $EXTENDS

=head1 DESCRIPTION

XML::Writer::Compiler is a module which takes a sample XML document and creates a single class from it. 
This class contains methods for each tag of the XML. The instance of the class can generate XML with the content supplied via a 
hashref. Subclassing the generated class allows more precise control over how the object-oriented XML generation occurs.

The CPAN module most similar to XML::Writer::Compiler is L<XML::Toolkit>. 

=head2 Simple Example

=head3 XML

 <note>
  <to>
    <person>
      Bob
    </person>
  </to>
  <from>Jani</from>
  <heading>Reminder</heading>
  <body>Don't forget me this weekend!</body>
 </note>

=head3 Compile XML to Perl class

This step is normally done via the F<xwc> script, but you can also write Perl code to compile XML:

 my $compiler = XML::Writer::Compiler->new;

 my $tree = XML::TreeBuilder->new( { 'NoExpand' => 0, 'ErrorContext' => 0 } );
 $tree->parse_file('t/sample.xml');

 my $pkg = XML::Note';
 my $class = $compiler->buildclass( $pkg, $tree, 0, '' );

=head3 Perl
 
 my %data = (
    note => {
        to => { person => 'Satan' },
        from => [ [ via => 'postcard', russia => 'with love' ], 'moneypenny' ]
    }
 );

 my $xml = XML::Note->new;
 $xml->data(\%data);
 warn  $xml->xml->string->value;
 
=head2 Subclassing Example

If a simple substitution from a hashref of data will not suffice, then you can take the methods of the generated class and 
subclass them for things like repeating or conditional content. See the test file F<repeating.t> for an example.

=head1 USAGE of xwc

The F<xwc> script is the most common way to convert an XML file to an equivalent Perl class. The script takes the 
following arguments

=head2 xml_file (required)

the full/relative path to the sample XML file

=head2 perl_pkg

the name of the Perl package that will represent the C<xml_file>

=head2 hash_depth

An XML file has nesting levels, or depth. Oftentimes, the outer levels will never be rewritten via the data hashref you supply.
As a result, you dont want to have to several levels of your hashref before you actually specify the data you want to bind.

Concretely, let's take some XML from the Quickbooks SDK:
L<https://member.developer.intuit.com/qbSDK-current/Common/newOSR/index.html>

For instance the CustomerAdd xml starts like this:

 <QBXML>
  <QBXMLMsgsRq onError="stopOnError">
   <CustomerAddRq>
    <CustomerAdd> <!-- required -->
     <Name >STRTYPE</Name> <!-- required -->
     <IsActive >BOOLTYPE</IsActive>
  ....
 </QBXML>

Now, none of the XML from the root to the XPath C<< QBXML/QBXMLMsgsRq/CustomerAddRq/CustomerAdd >> needs any
binding from the hashref. If you compiled this XML and had C<< hash_depth>> set to 0, then to set the name your hashref
would have to look like:

  my %data = ( QBXML => { QXBMLMsgsRq => { CustomerAddRq => { CustomerAdd => { Name => 'Bob Jones' }}}}} ;

In contrast , if you compiled this XML and had C<< hash_depth>> set to 4, then to set the name your hashref
would only have to look like:

  my %data = (  Name => 'Bob Jones' } ;

=head2 prepend_lib

The generated class file has a path generated from splitting the class name on double colon. In most cases, you will want to write
the class file to a path with 'lib' prepended and so you would set this option to 'lib'

=head2 extends

The XML class file is a L<Moose> class and can extend any superclass. E.g., in the L<XML::Quickbooks> distribution, each
XML class file extends C<< XML::Quickbooks >>.

=head1 SEE ALSO

=head2 Source code repository

L<https://github.com/metaperl/xml-writer-compiler>

=head2 Related modules

=head3 XML::Toolkit

L<XML::Toolkit>

=head3 XML::Element::Tolol

L<XML::Element::Tolol>

=head2 Relevant links

=head3 Moose, the tree structure of XML and object-oriented inheritance hiearchies

L<http://perlmonks.org/index.pl?node_id=910617>

=head3 Control Windows Quickbooks with Win32::OLE

L<http://perlmonks.org/index.pl?node_id=909187>

=head3 generating XML with data structures and Perl classes - the XML::Element::Tolol approach

L<http://perlmonks.org/index.pl?node_id=913713>


=head1 COPYRIGHT

Copyright C<< RANGE('2011-07-25', NOW()) >> Terrence Brannon.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, 
but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.

=head1 AUTHOR

Terrence Brannon <tbone@cpan.org>



