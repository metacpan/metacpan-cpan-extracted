package Visio;


#PLEASE SEE MSPATENTLICENSE
# "This product may incorporate intellectual property owned by 
# Microsoft Corporation. The terms and conditions upon which Microsoft 
# is licensing such intellectual property may be found at 
# http://msdn.microsoft.com/library/en-us/odcXMLRef/html/odcXMLRefLegalNotice.asp"

# Copyright 2005 Aamer Akhter. All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE LICENSOR(S) ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE LICENSOR(S) OR OTHER CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation
# are those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of the Licensor(s).

# The software may be subject to additional license restrictions
# provided by the Licensor(s).




use 5.008;
use strict;
use strict;
use warnings;
use Log::Log4perl  qw(get_logger);
use XML::LibXML;
use Carp;
use Data::Dumper;
use vars qw($VERSION);

use Visio::Page;
use Visio::Master;

$VERSION = sprintf "%d.%03d", q$Revision: 1.10 $ =~ /: (\d+)\.(\d+)/;

Log::Log4perl->init_once(\ qq{
 log4perl.logger                                 = DEBUG, Screen
 log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
 log4perl.appender.Screen.layout = PatternLayout
 log4perl.appender.Screen.layout.ConversionPattern=[%d] [%c] [%F{1}:%L] [%p] %m%n
});
my $log = get_logger('visio');
my $vNS = 'visio';
my $vNSURI = 'http://schemas.microsoft.com/visio/2003/core';

our $xmlParser = XML::LibXML->new();

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $opts = shift;
    my $fileName = $$opts{fromFile};
    my $self = {};
    $self->{xmlparser} = $Visio::xmlParser;

    if (defined $fileName) {
	$self->{xmldoc} = $self->{xmlparser}->parse_file($fileName);
	$log->debug("visio object created from $fileName");
	$self->{xmlroot} = $self->{xmldoc}->documentElement();
	bless($self,$class);
    } else {
	$self->{xmldoc} = $self->{xmlparser}->parse_string(<<'EOT');
	<VisioDocument xmlns='http://schemas.microsoft.com/visio/2003/core'>
	</VisioDocument>
EOT
$self->{xmlroot} = $self->{xmldoc}->documentElement();
	bless($self,$class);
	$log->debug("visio xml object created");
    }
    $self->{vNSURI} = $self->{xmlroot}->namespaceURI;
    	#add the visio ns as a prefix
    $self->{xmlroot}->setNamespace
	    (
	     ($self->{vNSURI}),
	     $vNS,
	     0
	     );
    return $self;
}

sub addpage {
    my $self = shift;
    my $pagesN;

#if pages nodes does not exist, create it;
    $pagesN = generic_create_node($self->{xmlroot},
				  'Pages'
				  );

    if (defined $self->{maxpageid}) {
	$self->{maxpageid} = $self->{maxpageid} + 1;	
    } else {
	$self->{maxpageid} = 0;	
    }
    my $page = new Visio::Page($pagesN,$self->{maxpageid});
    return $page;
}

sub toFile {
    my $self = shift;
    my $filename = shift;
    $self->{xmldoc}->toFile($filename,1);
}

sub toString {
    my $self = shift;
    $self->{xmldoc}->toString(2);
}

sub toXmlDoc {
    my $self = shift;
    return $self->{xmldoc};
}

sub set_docprop_node {
    my $self = shift;
    my $nodeType = shift;
    my $text = shift;
    my $dpt = $self->create_docprop_node($nodeType);
    my $textNode = $self->{xmldoc}->createTextNode($text);
    $dpt->removeChildNodes();
    $log->debug("doc $nodeType set");
    $dpt->appendChild($textNode);
}

sub set_docprop_timenode {
    my $self = shift;
    my $nodeType = shift;
    my $text = shift;
    $text = visio_timeformat() if (!defined $text);
    $self->set_docprop_node($nodeType,$text);
}

sub visio_timeformat {
    my $time = shift;
    if (!defined $time) {$time = time()};
    my @gmTime = gmtime($time);
    $gmTime[4]++;		# perl months are from 0..11
    $gmTime[5] += 1900;		# perl years
    return sprintf("%4d-%02d-%02dT%02d:%02d:%02d",
		   $gmTime[5],
		   $gmTime[3],
		   $gmTime[4],
		   $gmTime[2],
		   $gmTime[1],
		   $gmTime[0]
		   );
}

sub set_timeSaved {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_timenode('TimeSaved',$text);
}

sub set_timeCreated {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_timenode('TimeCreated',$text);
}


sub set_title {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Title',$text);
}

sub set_subject {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Subject',$text);
}

sub set_manager {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Manager',$text);
}

sub set_company {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Company',$text);
}

sub set_desc {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Desc',$text);
}

sub set_creator {
    my $self = shift;
    my $text = shift;
    $self->set_docprop_node('Creator',$text);
}

sub find_master_dom {
    my $self = shift;
    my $opts = shift;
    my $nname = $opts->{'name'};
    my $xp = "/$vNS:VisioDocument/$vNS:Masters/$vNS:Master";
    my $xpSel = "";
    if (defined $nname) {
	$xpSel .= "\@Name = '$nname'";
    }
    $xp .= "[$xpSel]";
    $log->debug("searching with $xp");
    return $self->{xmlroot}->findnodes($xp);
}


sub create_master {
    my $self = shift;
    my $opts = shift;
    my $fromDom = $$opts{'fromDom'};
    my $master;
    my $mastersNode = generic_create_node($self->{xmlroot},
					  'Masters'
					  );
    if (defined $self->{maxMasterid}) {
	$self->{maxMasterid} = $self->{maxMasterid} + 1;	
    } else {
	$self->{maxMasterid} = 0;	
    }
    if (defined $fromDom) {
	$master = new Visio::Master($mastersNode,
				    $self->{maxMasterid},
				    {fromDom=>$fromDom}
				    );
    }
    return $master;
}




#================ PRIIVATE FUNCTIONS


sub create_docprop_node {
    my $self = shift;
    my $node = shift;
    my $dp = $self->create_docprop();
    return generic_create_node($dp, $node);
}

sub create_docprop {
    my $self = shift;
    #see of DocumentProperties already exists, if not crate it
    my $docpropNL = $self->{xmlroot}->findnodes("DocumentProperties");
    return $docpropNL->pop if ($docpropNL->size() > 0);
    $log->debug('creating DocumentProperties node');
    my $docpropN = $self->{xmldoc}->createElement("DocumentProperties");
    $self->{xmlroot}->insertBefore(
				   $docpropN,
				   $self->{xmlroot}->firstChild
				   );
}

sub generic_create_node {
    my $parent = shift;
    my $node = shift;
    my $nodeNL = $parent->findnodes("$node");
    return $nodeNL->pop if ($nodeNL->size() > 0);
    $log->debug("creating $parent/$node node");
    my $uri = $parent->namespaceURI;
    if (!defined $uri) {
	$uri = $vNSURI;
    }
    my $nodeN = $parent->ownerDocument->createElement("$node");
    $parent->appendChild($nodeN);
    return $nodeN;
}

sub generic_settext {
    my $node = shift;
    my $text = shift;
    my $textNode = $node->ownerDocument->createTextNode($text);
    $node->removeChildNodes();
    $log->debug("doc $node text set");
    $node->appendChild($textNode);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Visio - Perl extension mainpulating XML based Visio files

=head1 SYNOPSIS

To create a viso vdx file, create multiple pages, reorient one of the pages:

  my $v = new Visio();
  $v->set_title('wabla wabla');
  $v->set_timeCreated();
  $v->set_timeSaved()

  my $page = $v->addpage();
  $page->set_name('my page');
  $page->set_heightWidth(8,11);

  my $page2 = $v->addpage();
  $page2->set_name('my page2');

  $v->toFile('myvisofile.vdx');

=head1 ABSTRACT

  Visio is an alpha stage library to create and manipulate Microsoft Visio
  drawings.

=head1 DESCRIPTION

  Visio is an alpha stage library to create and manipulate Microsoft Visio
  drawings.

  Currently it can only create drawings from scratch, and can not
  create a usable object model from a pre-existing file.

  The Visio module is however able to extract stencils from pre-existing
  files and insert them into your new drawings. This is helpfull as 
  it is fairly difficult to make a nice drawing on your own via the 
  current Visio perl module API.

  This is my first public Perl module, and I'm sure there are tons of 
  mistakes. Please feel free to communicate any design flaws or reworking
  you may feel would make Visio more usable and approachable.
  
=head1 Document Methods

=head2 new()

A new Visio document is created using the new method:

 my $vDoc = new Visio();

By default the document is completely empty and the document creator is set to 'perl-visio'. This can be overwritten by use of the set_creator method.

=head2 toString()

Visio document is returned as an XML string.

 my $vString = $vDoc->toString;

=head2 toFile($filename)

Visio doc is written out to an XML file.

 $vDoc->toFile('myfile.vdx');

=head2 toXmlDoc()

libxml2 doc element is returned

 $vDoc->toXmlDoc();

=head2 set_title($title)

Sets Document title

 $vDoc->set_title('my title');

=head2 set_subject($subject)

Sets Document subject

 $vDoc->set_subject('my subject');

=head2 set_manager($manager)

Sets Document manager field

 $vDoc->set_manager('my manager');

=head2 set_company($company)

Sets company filed in document.

 $vDoc->set_company('my company');

=head2 set_desc($desc)

Sets Document description.

 $vDoc->set_desc('my really good description');

=head2 set_creator($creator)

Sets Document creator field.

 $vDoc->set_creator('just me');

=head2 set_timeCreated($visoTimeString)

Set's document time created information. If time is not passed, the current time (UTC) is set.

 $vDoc->set_timeCreated();

=head2 set_timeSaved($visioTimeString)

Set's document time saved information. If time is not passed, the current time (UTC) is set.

 $vDoc->set_timeSaved();

=head2 visio_timeformat($time)

Takes in argument of $time, which is in the format of the perl time() function. Returns a $visioTimeString formatted string.

 $vDoc->set_timeCreated(Visio::visio_timeformat(time()));
 
 is equivilent to:

 $vDoc->set_timeCreated();

=head2 find_master_dom()

searches the visio masters (stencils). filters can be specifed:

 $vDoc->find_master_dom({name=>'myrectangle'})

returns a libxml nodelist object of all stencils that had name 'myractangle'. Not specifying filters returns all stencils.

filters avaliable:

name



=head1 Page Methods

=head2 addpage()

A new Visio page is created in a Visio document.

 my $vPage1 = $vDoc->addpage();

By default the document is completely empty and the document creator is set to 'perl-visio'. This can be overwritten by use of the set_creator method.

=head2 set_name($name)

Sets the name of the page

 $vPage->set_name('mypage');

=head2 set_heightWidth($height,$width)

Sets a page's height and width. In inches by default:

 $vPage->setheightWidth(8,11);

=head2 create_pageSheet();

creates a pageSheet method if needed under this page

    my $pageSheet = $vPage->create_pageSheet();

=head1 PageSheet methods

For the most part one shouldn't need to directly use these methods

=head2 new($parentNode)

new creates (if one does not already exist) a new child PageSheet element node under $parentNode, which is a libxml2 object.

=head2 get_node

returns the PageSheet libxml2 node

 my $pageSheetNode = $pageSheet->getnode();

=head2 create_pageProps 

creates a PageProps object and element under the current PageSheet

=head1 PageProps methods

For the most part one shouldn't need to directly use these methods

=head2 new($parentNode)

new creates (if one does not already exist) a new child PageProps element node under $parentNode, which is a libxml2 object.


=head2 get_node

returns the PageProps libxml2 node

 my $pagePropsNode = $pageProps->getnode();

=head2 set_PageWidth($width) 

sets the page width of this PageProps node. Default unit is in inches.

 $pageProps->set_PageWidth($width);

=head2 set_PageHeight($height) 

sets the page height of this PageProps node. Default unit is in inches.

 $pageProps->set_PageHeight($height);



=head2 EXPORT

None by default.



=head1 SEE ALSO


If you have a mailing list set up for your module, mention it here.


=head1 AUTHOR

Aamer Akhter, E<lt>aakhter@cisco.comE<gt> E<lt>aakhter@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Aamer Akhter

This library is free software; you can redistribute it and/or modify
it under the same terms as in LICENSE and MSPATENTLICENSE files.

 "This product may incorporate intellectual property owned by 
 Microsoft Corporation. The terms and conditions upon which Microsoft 
 is licensing such intellectual property may be found at 
 http://msdn.microsoft.com/library/en-us/odcXMLRef/html/odcXMLRefLegalNotice.asp"

=cut
