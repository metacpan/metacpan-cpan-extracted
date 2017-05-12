package XML::Mini::Document;
use strict;
$^W = 1;

use FileHandle;

use XML::Mini;
use XML::Mini::Element;
use XML::Mini::Element::Comment;
use XML::Mini::Element::Header;
use XML::Mini::Element::CData;
use XML::Mini::Element::DocType;
use XML::Mini::Element::Entity;
use XML::Mini::Node;

use vars qw ( 	$VERSION
		$TextBalancedAvailable
	 );

use Text::Balanced;
$TextBalancedAvailable = 1;

$VERSION = '1.38';


if ($XML::Mini::IgnoreDeepRecursionWarnings)
{
	XML::Mini->ignoreDeepRecursionWarning();
}

sub new
{
    my $class = shift;
    my $string = shift;
    
    my $self = {};
    bless $self, ref $class || $class;
    
    $self->init();
    
    if (defined $string)
    {
	$self->fromString($string);
    }
    
    return $self;
}

sub init {
	my $self = shift;
	delete $self->{'_xmlDoc'};
	
	$self->{'_xmlDoc'} = XML::Mini::Element->new("PSYCHOGENIC_ROOT_ELEMENT");
}
	

sub getRoot
{
    my $self = shift;
    return $self->{'_xmlDoc'};
}

sub setRoot
{
    my $self = shift;
    my $root = shift;
    
    return XML::Mini->Error("XML::Mini::Document::setRoot(): Trying to set non-XML::Mini::Element as root")
	unless ($self->isElement($root));
    
    $self->{'_xmlDoc'} = $root;
}
	
sub isElement
{
    my $self = shift;
    my $element = shift || return undef;
    
    my $type = ref $element;
    
    return undef unless $type;
    
    return 0 unless ($type =~ /^XML::Mini::Element/);
    
    return 1;
}

sub isNode
{
    my $self = shift;
    my $element = shift || return undef;
    
    my $type = ref $element;
    
    return undef unless $type;
    
    return 0 unless ($type =~ /^XML::Mini::Node/);
    
    return 1;
}

sub createElement
{
    my $self = shift;
    my $name = shift;
    my $value = shift; # optional
    
    my $newElement = XML::Mini::Element->new($name);
    
    return XML::Mini->Error("Could not create new element named '$name'")
	unless ($newElement);
    
    if (defined $value)
    {
	$newElement->text($value);
    }
    
    return $newElement;
}

sub getElementByPath
{
    my $self = shift;
    my $path = shift;
    my @elementNumbers = @_;
    
    my $element = $self->{'_xmlDoc'}->getElementByPath($path, @elementNumbers);
    if ($XML::Mini::Debug)
    {
	if ($element)
	{
	    XML::Mini->Log("XML::Mini::Document::getElementByPath(): element at $path found.");
	  } else {
	      XML::Mini->Log("XML::Mini::Document::getElement(): element at $path NOT found.");
	    }
    }
    
    return $element;
}

sub getElement
{
    my $self = shift;
    my $name = shift;
    my $elementNumber = shift; # optionally get only the ith element
    
    my $element = $self->{'_xmlDoc'}->getElement($name, $elementNumber);
    
    if ($XML::Mini::Debug)
    {
	if ($element)
	{
		XML::Mini->Log("XML::Mini::Document::getElement(): element named $name found.");
	} else {
		XML::Mini->Log("XML::Mini::Document::getElement(): element named $name NOT found.");
	}
    }
    
    return $element;
}

sub fromString
{
    my $self = shift;
    my $string = shift;
    
    
    if ($XML::Mini::CheckXMLBeforeParsing)
    {
    	my $copy = $string;
    
    	$copy =~ s/<\s*\?\s*xml.*?\?>//smg;
    	$copy =~ s/<!--.+?-->//smg;
	
	$copy =~s/<!\[CDATA[^>]*>//smg;
	$copy =~ s/<!DOCTYPE[^>]*>//smg;
	$copy =~ s/<!ENTITY[^>]*>//smg;
    	$copy =~ s/<\s*[^\s>]+[^>]*\/\s*>//smg; # get rid of <unary /> tags
    
    	# get rid of all pairs of tags...
   	 my %counts;
   	 while ($copy =~ m/<\s*([^\/\s>]+)[^>]*>/smg)
    	{
    		$counts{$1}->{'open'} = 0 unless (exists $counts{$1}->{'open'});
		$counts{$1}->{'open'}++;
    	}	
    
    	while ($copy =~ m/<\s*\/\s*([^\s>]+)(\s[^>]*)?>/smg)
    	{
    		$counts{$1}->{'close'} = 0 unless (exists $counts{$1}->{'close'});
		$counts{$1}->{'close'}++;
    	}
    
    	# anything left
    	my @unmatched;
   	while (my ($tag, $res) = each %counts)
    	{
    		unless ($res->{'open'} && $res->{'close'} 
			&& $res->{'open'} == $res->{'close'} )
		{
			push @unmatched, $tag;
		}
    	}
    
    	if (scalar @unmatched)
    	{
		if ($XML::Mini::DieOnBadXML)
		{
    			XML::Mini->Error("Found unmatched tags in your XML... " . join(',', @unmatched));
		} else {
			
    			XML::Mini->Log("Found unmatched tags in your XML... " . join(',', @unmatched));
		}
		
		return 0;
    	}
	
	# passed our basic check...
   }
    	
    
    $self->fromSubString($self->{'_xmlDoc'}, $string);
    
    return $self->{'_xmlDoc'}->numChildren();
}

sub fromFile
{
    my $self = shift;
    my $filename = shift;
    
    my $fRef = \$filename;
    my $contents;
    if (ref($filename) && UNIVERSAL::isa($filename, 'IO::Handle'))
    {
	$contents = join("", $filename->getlines());
	$filename->close();

    } elsif (ref $fRef eq 'GLOB') {
    
    	$contents = join('', $fRef->getlines());
	$fRef->close();
	
    } elsif (ref $fRef eq 'SCALAR') {
    
	return XML::Mini->Error("XML::Mini::Document::fromFile() Can't find file $filename")
		unless (-e $filename);
    
    
	return XML::Mini->Error("XML::Mini::Document::fromFile() Can't read file $filename")
		unless (-r $filename);
	
	my $infile = FileHandle->new();
	$infile->open( "<$filename")
		|| return  XML::Mini->Error("XML::Mini::Document::fromFile()  Could not open $filename for read: $!");
	$contents = join("", $infile->getlines());
	$infile->close();
    }
    
    return $self->fromString($contents);
}

sub parse 
{
	my $self = shift;
	my $input = shift;
	
	my $inRef = \$input;
	my $type = ref($inRef);
	
	if ($type eq 'SCALAR' && $input =~ m|<[^>]+>|sm)
	{
		# we have some XML
		return $self->fromString($input);
		
	} else {
		# hope it's a file name or handle
		return $self->fromFile($input);
	}
	
}


sub fromHash {
	my $self = shift;
	my $href = shift ||  return XML::Mini->Error("XML::Mini::Document::fromHash - must pass a hash reference");
	my $params = shift || {};
	
	$self->init();
	
	if ($params->{'attributes'})
	{
		my %attribs;
		while (my ($attribName, $value) = each %{$params->{'attributes'}})
		{
			my $vType = ref $value || "";
			if ($vType)
			{
				if ($vType eq 'ARRAY')
				{
					foreach my $v (@{$value})
					{
						$attribs{$attribName}->{$v}++;
					}
					
				}
			} else {
				$attribs{$attribName}->{$value}++;
			}
		}
		
		$params->{'attributes'} = \%attribs;
	}
				
		
	
	while (my ($keyname, $value) = each %{$href})
	{
	
		my $sub = $self->_fromHash_getExtractSub(ref $value);
			
		$self->$sub($keyname, $value, $self->{'_xmlDoc'}, $params);
		
	}
	
	return $self->{'_xmlDoc'}->numChildren();
	
}

sub _fromHash_getExtractSub {
	my $self = shift;
	my $valType = shift || 'STRING';
	
	my $sub = "_fromHash_extract$valType";
		
	return XML::Mini->Error("XML::Mini::Document::fromHash Don't know how to interpret '$valType' values")
		unless ($self->can($sub));
	
	return $sub;
	
}
	

sub _fromHash_extractHASH {
	my $self = shift;
	my $name = shift;
	my $value = shift || return XML::Mini->Error("XML::Mini::Document::extractHASHref No value passed!");
	my $parent = shift || return XML::Mini->Error("XML::Mini::Document::extractHASHref No parent element passed!");
	my $params = shift || {};
	
	return XML::Mini->Error("XML::Mini::Document::extractHASHref No element name passed!")
		unless (defined $name);
		
	
	my $thisElement = $parent->createChild($name);
	
	while (my ($key, $val) = each %{$value})
	{
		
			
		my $sub = $self->_fromHash_getExtractSub(ref $val);
			
		$self->$sub($key, $val, $thisElement, $params);
		
	}
	
	return ;
}

sub _fromHash_extractARRAY {
	my $self = shift;
	my $name = shift;
	my $values = shift || return XML::Mini->Error("XML::Mini::Document::extractARRAYref No value passed!");
	my $parent = shift || return XML::Mini->Error("XML::Mini::Document::extractARRAYref No parent element passed!");
	my $params = shift || {};
	
	return XML::Mini->Error("XML::Mini::Document::extractARRAYref No element name passed!")
		unless (defined $name);
		
	# every element in an array ref is a child element of the parent
	foreach my $val (@{$values})
	{
		my $valRef = ref $val;
		
		if ($valRef)
		{
			# this is a complex element
			#my $childElement = $parent->createChild($name);
			
			# process sub elements
			my $sub = $self->_fromHash_getExtractSub($valRef);
			
			$self->$sub($name, $val, $parent, $params);
			
		} else {
			# simple string
			$self->_fromHash_extractSTRING($name, $val, $parent, $params);
			
			
		}
		
	}
	
	return;

}

sub _fromHash_extractSTRING {
	my $self = shift;
	my $name = shift;
	my $val = shift ;
	my $parent = shift || return XML::Mini->Error("XML::Mini::Document::extractSTRING No parent element passed!");
	my $params = shift || {};
	
	return XML::Mini->Error("XML::Mini::Document::extractSTRING No element name passed!")
		unless (defined $name);
	
	
	return XML::Mini->Error("XML::Mini::Document::extractSTRING No value passed!")
		unless (defined $val);

	my $pname = $parent->name();
			
	if ($params->{'attributes'}->{$pname}->{$name} || $params->{'attributes'}->{'-all'}->{$name})
	{
		$parent->attribute($name, $val);
	} elsif ($name eq '-content') {
	
		$parent->text($val);
		
	} else {
		$parent->createChild($name, $val);
	}
	
	return ;
	

}



sub toHash {
	my $self = shift;
	
	my $retVal = $self->{'_xmlDoc'}->toStructure();
	
	my $type = ref $retVal;
	
	if ($type && $type eq 'HASH')
	{
		return $retVal;
	}
	
	my $retHash = {
			'-content'	=> $retVal,
		};
		
	return $retHash;

}
	


sub toString
{
    my $self = shift;
    my $depth = shift || 0;
    
    my $retString = $self->{'_xmlDoc'}->toString($depth);
    
    $retString =~ s/<\/PSYCHOGENIC_ROOT_ELEMENT>//smi;
    $retString =~ s/<PSYCHOGENIC_ROOT_ELEMENT([^>]*)?>\s*//smi;
    
    
    return $retString;
}

sub fromSubStringBT {
	my $self = shift;
	my $parentElement = shift;
   	my $XMLString = shift;
	my $useIgnore = shift;
	
	if ($XML::Mini::Debug) 
	{
		XML::Mini->Log("Called fromSubStringBT() with parent '" . $parentElement->name() . "'\n");
	}
	
	my @res;
	if ($useIgnore)
	{
		my $ignore = [ '<\s*[^\s>]+[^>]*\/\s*>',	# <unary \/>
			'<\?\s*[^\s>]+\s*[^>]*\?>', # <? headers ?>
			'<!--.+?-->',			# <!-- comments -->
			'<!\[CDATA\s*\[.*?\]\]\s*>\s*', 	# CDATA 
			'<!DOCTYPE\s*([^\[>]*)(\[.*?\])?\s*>',	# DOCTYPE
			'<!ENTITY\s*[^>]+>'
		];
		
		@res = Text::Balanced::extract_tagged($XMLString, undef, undef, undef, { 'ignore' => $ignore });
	} else {
		@res = Text::Balanced::extract_tagged($XMLString);
	}
	
	if ($#res == 5)
	{
		# We've extracted a balanced <tag>..</tag>
	
		my $extracted = $res[0]; # the entire <t>..</t>
		my $remainder = $res[1]; # stuff after the <t>..</t>HERE  - 3
		my $prefix = $res[3]; # the <t ...> itself - 1
		my $contents = $res[4]; # the '..' between <t>..</t> - 2
		my $suffix = $res[5]; # the </t>
		
		#XML::Mini->Log("Grabbed prefix '$prefix'...");
		my $newElement;
		
		if ($prefix =~ m|<\s*([^\s>]+)\s*([^>]*)>|)
		{
			my $name = $1;
			my $attribs = $2;
			$newElement = $parentElement->createChild($name);
	    		$self->_extractAttributesFromString($newElement, $attribs) if ($attribs);
			
			$self->fromSubStringBT($newElement, $contents) if ($contents =~ m|\S|);
			
			$self->fromSubStringBT($parentElement, $remainder) if ($remainder =~ m|\S|);
		} else {
			
			XML::Mini->Log("XML::Mini::Document::fromSubStringBT extracted balanced text from invalid tag '$prefix' - ignoring");
    		}
	} else {
	
		$XMLString =~ s/>\s*\n/>/gsm;
		if ($XMLString =~ m/^\s*<\s*([^\s>]+)([^>]*>).*<\s*\/\1\s*>/osm)
		{
			# starts with a normal <tag> ... </tag> but has some ?? in it
			
			my $startTag = $2;
			return $self->fromSubStringBT($parentElement, $XMLString, 'USEIGNORE')
				unless ($startTag =~ m|/\s*>$|);
		}
	
		# not a <tag>...</tag>
		#it's either a                             
		if ($XMLString =~ m/^\s*(<\s*([^\s>]+)([^>]+)\/\s*>|	# <unary \/>
					 <\?\s*([^\s>]+)\s*([^>]*)\?>|	# <? headers ?>
					 <!--(.+?)-->|			# <!-- comments -->
					 <!\[CDATA\s*\[(.*?)\]\]\s*>\s*| 	# CDATA 
					 <!DOCTYPE\s*([^\[>]*)(\[.*?\])?\s*>\s*|	# DOCTYPE
					 <!ENTITY\s*([^"'>]+)\s*(["'])([^\11]+)\11\s*>\s*| # ENTITY
					 ([^<]+))(.*)/xogsmi) # plain text
		{
			my $firstPart	 = $1;
			my $unaryName 	 = $2;
			my $unaryAttribs = $3;
			my $headerName 	 = $4;
			my $headerAttribs= $5;
			my $comment 	 = $6;
			my $cdata	 = $7;
			my $doctype	 = $8;
			my $doctypeCont  = $9;
			my $entityName	 = $10;
			my $entityCont	 = $12;
			my $plainText	 = $13;
			my $remainder 	 = $14;
			
			
			
			# There is some duplication here that should be merged with that in fromSubString()
			if ($unaryName)
			{
				my $newElement = $parentElement->createChild($unaryName);
				$self->_extractAttributesFromString($newElement, $unaryAttribs) if ($unaryAttribs);
			} elsif ($headerName)
			{
				my $newElement = XML::Mini::Element::Header->new($headerName);
				$self->_extractAttributesFromString($newElement, $headerAttribs) if ($headerAttribs);
				$parentElement->appendChild($newElement);
			} elsif (defined $comment) {
				$parentElement->comment($comment);
			} elsif (defined $cdata) {
				my $newElement = XML::Mini::Element::CData->new($cdata);
				$parentElement->appendChild($newElement);
			} elsif ($doctype || defined $doctypeCont) {
				my $newElement = XML::Mini::Element::DocType->new($doctype);
				$parentElement->appendChild($newElement);
				if ($doctypeCont)
				{
					$doctypeCont =~ s/^\s*\[//smg;
					$doctypeCont =~ s/\]\s*$//smg;
					
					$self->fromSubStringBT($newElement, $doctypeCont);
				}
			} elsif (defined $entityName) {
				my $newElement = XML::Mini::Element::Entity->new($entityName, $entityCont);
				$parentElement->appendChild($newElement);
			} elsif (defined $plainText && $plainText =~ m|\S|sm)
			{
				$parentElement->createNode($plainText);
			} else {
				XML::Mini->Log("NO MATCH???") if ($XML::Mini::Debug);
			}
			
			
			if (defined $remainder && $remainder =~ m|\S|sm)
			{
				$self->fromSubStringBT($parentElement, $remainder);
			}
			
		} else {
			# No match here either...
			XML::Mini->Log("No match in fromSubStringBT() for '$XMLString'") if ($XML::Mini::Debug);
			
		} # end if it matches one of our other tags or plain text
		
	} # end if Text::Balanced returned a match
	
	
} # end fromSubStringBT()
			
	
    

sub fromSubString
{
    my $self = shift;
    my $parentElement = shift;
    my $XMLString = shift;
    
    if ($XML::Mini::Debug) 
    {
		XML::Mini->Log("Called fromSubString() with parent '" . $parentElement->name() . "'\n");
    }
    
    
    # The heart of the parsing is here, in our mega regex
    # The sections are for:
    # <tag>...</tag>
    # <!-- comments -->
    # <singletag />
    # <![CDATA [ STUFF ]]>
    # <!DOCTYPE ... [ ... ]>
    # <!ENTITY bla "bla">
    # plain text
    #=~/<\s*([^\s>]+)([^>]+)?>(.*?)<\s*\/\\1\s*>\s*([^<]+)?(.*)
    
    
    if ($TextBalancedAvailable)
    {
    	return $self->fromSubStringBT($parentElement, $XMLString);
    }
    
    while ($XMLString =~/\s*<\s*([^\s>]+)([^>]+)?>(.*?)<\s*\/\1\s*>\s*([^<]+)?(.*)|
    \s*<!--(.+?)-->\s*|
    \s*<\s*([^\s>]+)\s*([^>]*)\/\s*>\s*([^<>]+)?|
    \s*<!\[CDATA\s*\[(.*?)\]\]\s*>\s*|
    \s*<!DOCTYPE\s*([^\[>]*)(\[.*?\])?\s*>\s*|
    \s*<!ENTITY\s*([^"'>]+)\s*(["'])([^\14]+)\14\s*>\s*|
    \s*<\?\s*([^\s>]+)\s*([^>]*)\?>|
    ^([^<]+)(.*)/xogsmi)
	   

    {
	# Check which string matched.'
	my $uname = $7;
	my $comment = $6;
	my $cdata = $10;
	my $doctypedef = $11;
	if ($12)
	{
		if ($doctypedef)
		{
			$doctypedef .= ' ' . $12;
		} else {
			$doctypedef = $12;
		}
	}
	
	my $entityname = $13;
	my $headername = $16;
	my $headerAttribs  = $17;
	my $plaintext = $18;
	
	if (defined $uname)
	{
	    my $ufinaltxt = $9;
	    my $newElement = $parentElement->createChild($uname);
	    $self->_extractAttributesFromString($newElement, $8);
	    if (defined $ufinaltxt && $ufinaltxt =~ m|\S+|)
	    {
		$parentElement->createNode($ufinaltxt);
	    }
	} elsif (defined $headername)
	{
		my $newElement = XML::Mini::Element::Header->new($headername);
		$self->_extractAttributesFromString($newElement, $headerAttribs) if ($headerAttribs);
		$parentElement->appendChild($newElement);
	
	} elsif (defined $comment) {
	    #my $newElement = XML::Mini::Element::Comment->new('!--');
	    #$newElement->createNode($comment);
	    $parentElement->comment($comment);
	} elsif (defined $cdata) {
	    my $newElement = XML::Mini::Element::CData->new($cdata);
	    $parentElement->appendChild($newElement);
	} elsif (defined $doctypedef) {
	    
	    my $newElement = XML::Mini::Element::DocType->new($11);
	    $parentElement->appendChild($newElement);
	    $self->fromSubString($newElement, $doctypedef);
	    
	} elsif (defined $entityname) {
	    
	    my $newElement = XML::Mini::Element::Entity->new($entityname, $15);
	    $parentElement->appendChild($newElement);
	    
	} elsif (defined $plaintext) {
	    
	    my $afterTxt = $19;
	    if ($plaintext !~ /^\s+$/)
	    {
		$parentElement->createNode($plaintext);
	    }
	    
	    if (defined $afterTxt)
	    {
		$self->fromSubString($parentElement, $afterTxt);
	    }
	} elsif ($1) {
	    
	    my $nencl = $3;
	    my $finaltxt = $4;
	    my $otherTags = $5;
	    my $newElement = $parentElement->createChild($1);
	    $self->_extractAttributesFromString($newElement, $2);
	    
	    
	    if ($nencl =~ /^\s*([^\s<][^<]*)/)
	    {
		my $txt = $1;
		$newElement->createNode($txt);
		$nencl =~ s/^\s*[^<]+//;
	    }
	    
	    $self->fromSubString($newElement, $nencl);
	    
	    if (defined $finaltxt)
	    {
		$parentElement->createNode($finaltxt);
	    }
	    
	    if (defined $otherTags)
	    {
		$self->fromSubString($parentElement, $otherTags);
	    }
	}
    } # end while matches
} #* end method fromSubString */

sub toFile
{
    my $self = shift;
    my $filename = shift || return XML::Mini->Error("XML::Mini::Document::toFile - must pass a filename to save to");
    my $safe = shift;
    
    my $dir = $filename;
    
    $dir =~ s|(.+/)?[^/]+$|$1|;
    
    if ($dir)
    {
	return XML::Mini->Error("XML::Mini::Document::toFile - called with file '$filename' but cannot find director $dir")
	    unless (-e $dir && -d $dir);
	return XML::Mini->Error("XML::Mini::Document::toFile - called with file '$filename' but no permission to write to dir $dir")
	    unless (-w $dir);
    }
    
    my $contents = $self->toString();
    
    return XML::Mini->Error("XML::Mini::Document::toFile - got nothing back from call to toString()")
	unless ($contents);
    
    my $outfile = FileHandle->new();
    
    if ($safe)
    {
	if ($filename =~ m|/\.\./| || $filename =~ m|#;`\*|)
	{
	    return XML::Mini->Error("XML::Mini::Document::toFile() Filename '$filename' invalid with SAFE flag on");
	}
	    
	if (-e $filename)
	{
	    if ($safe =~ /NOOVERWRITE/i)
	    {
		return XML::Mini->Error("XML::Mini::Document::toFile() file '$filename' exists and SAFE flag is '$safe'");
	    }
	    
	    if (-l $filename)
	    {
		return XML::Mini->Error("XML::Mini::Document::toFile() file '$filename' is a "
					. "symbolic link and SAFE flag is on");
	    }
	}
    }

    $outfile->open( ">$filename")
	|| return  XML::Mini->Error("XML::Mini::Document::toFile()  Could not open $filename for write: $!");
    $outfile->print($contents);
    $outfile->close();
    return length($contents);
}

sub getValue
{
    my $self = shift;
    return $self->{'_xmlDoc'}->getValue();
}

sub dump
{
    my $self = shift;
    return Dumper($self);
}

#// _extractAttributesFromString
#// private method for extracting and setting the attributs from a
#// ' a="b" c = "d"' string
sub _extractAttributesFromString
{
    my $self = shift;
    my $element = shift;
    my $attrString = shift;
    
    return undef unless (defined $attrString);
    my $count = 0;
    while ($attrString =~ /([^\s]+)\s*=\s*(['"])([^\2]*?)\2/g)
    {
	my $attrname = $1;
	my $attrval = $3;

	if (defined $attrname)
	{
	    $attrval = '' unless (defined $attrval && length($attrval));
	    $element->attribute($attrname, $attrval, '');
	    $count++;
	}
    }
    
    return $count;
}

1;

__END__

=head1 NAME

XML::Mini::Document - Perl implementation of the XML::Mini Document API.

=head1 SYNOPSIS

	use XML::Mini::Document;

	
	use Data::Dumper;
	
	
	###### PARSING XML #######
	
	# create a new object
	my $xmlDoc = XML::Mini::Document->new();
	
	# init the doc from an XML string
	$xmlDoc->parse($XMLString);
	
	# You may use the toHash() method to automatically
	# convert the XML into a hash reference
	my $xmlHash = $xmlDoc->toHash();
	
	print Dumper($xmlHash);
	
	
	# You can also manipulate the elements like directly, like this:	
	
	# Fetch the ROOT element for the document
	# (an instance of XML::Mini::Element)
	my $xmlRoot = $xmlDoc->getRoot();
	
	# play with the element and its children
	# ...
	my $topLevelChildren = $xmlRoot->getAllChildren();
	
	foreach my $childElement (@{$topLevelChildren})
	{
		# ...
	}
	
	
	###### CREATING XML #######
	
	# Create a new document from scratch
	
	my $newDoc = XML::Mini::Document->new();
	
	# This can be done easily by using a hash:
	my $h = {	
	 'spy'	=> {
		'id'	=> '007',
		'type'	=> 'SuperSpy',
		'name'	=> 'James Bond',
		'email'	=> 'mi5@london.uk',
		'address'	=> 'Wherever he is needed most',
		},
	};

	$newDoc->fromHash($h);
 
	
	
	# Or new XML can also be created by manipulating 
	#elements directly:
	
	my $newDocRoot = $newDoc->getRoot();
	
	# create the <? xml ?> header
	my $xmlHeader = $newDocRoot->header('xml');
	# add the version 
	$xmlHeader->attribute('version', '1.0');
	
	my $person = $newDocRoot->createChild('person');
	
	my $name = $person->createChild('name');
	$name->createChild('first')->text('John');
	$name->createChild('last')->text('Doe');
	
	my $eyes = $person->createChild('eyes');
	$eyes->attribute('color', 'blue');
	$eyes->attribute('number', 2);
	
	# output the document
	print $newDoc->toString();
	
	
This example would output :

 

 <?xml version="1.0"?>
  <person>
   <name>
    <first>
     John
    </first>
    <last>
     Doe
    </last>
  </name>
  <eyes color="blue" number="2" />
  </person>


=head1 DESCRIPTION

The XML::Mini::Document class is the programmer's handle to XML::Mini functionality.

A XML::Mini::Document instance is created in every program that uses XML::Mini.
With the XML::Mini::Document object, you can access the root XML::Mini::Element, 
find/fetch/create elements and read in or output XML strings.


=head2 new [XMLSTRING]

Creates a new instance of XML::Mini::Document, optionally calling
fromString with the passed XMLSTRING

=head2 getRoot

Returns a reference the this document's root element
(an instance of XML::Mini::Element)

=head2 setRoot NEWROOT

setRoot NEWROOT
Set the document root to the NEWROOT XML::Mini::Element object.

=head2 isElement ELEMENT

Returns a true value if ELEMENT is an instance of XML::Mini::Element,
false otherwise.

=head2 isNode NODE

Returns a true value if NODE is an instance of XML::MiniNode,
false otherwise.

=head2 createElement NAME [VALUE]

Creates a new XML::Mini::Element with name NAME.

This element is an orphan (has no assigned parent)
and will be lost unless it is appended (XML::Mini::Element::appendChild())
to an element at some point.

If the optional VALUE (string or numeric) parameter is passed,
the new element's text/numeric content will be set using VALUE.
Returns a reference to the newly created element.

=head2 getElement NAME [POSITON]

Searches the document for an element with name NAME.

Returns a reference to the first XML::Mini::Element with name NAME,
if found, NULL otherwise.

NOTE: The search is performed like this, returning the first 
element that matches:

 - Check the Root Element's immediate children (in order) for a match.
 - Ask each immediate child (in order) to XML::Mini::Element::getElement()
  (each child will then proceed similarly, checking all it's immediate
   children in order and then asking them to getElement())
   
If a numeric POSITION parameter is passed, getElement() will return only 
the POSITIONth element of name NAME (starting at 1).  Thus, on document
 

  <?xml version="1.0"?>
  <people>
   <person>
    bob
   </person>
   <person>
    jane
   </person>
   <person>
    ralph
   </person>
  </people>


$people->getElement('person') will return the element containing the text node
'bob', while $people->getElement('person', 3) will return the element containing the 
text 'ralph'.



=head2 getElementByPath PATH [POSITIONARRAY]

Attempts to return a reference to the (first) element at PATH
where PATH is the path in the structure from the root element to
the requested element.

For example, in the document represented by:

	 <partRateRequest>
	  <vendor>
	   <accessid user="myusername" password="mypassword" />
	  </vendor>
	  <partList>
	   <partNum>
	    DA42
	   </partNum>
	   <partNum>
	    D99983FFF
	   </partNum>
	   <partNum>
	    ss-839uent
	   </partNum>
	  </partList>
	 </partRateRequest>

 	$accessid = $xmlDocument->getElementByPath('partRateRequest/vendor/accessid');

Will return what you expect (the accessid element with attributes user = "myusername"
and password = "mypassword").

BUT be careful:

	my $accessid = $xmlDocument->getElementByPath('partRateRequest/partList/partNum');

will return the partNum element with the value "DA42".  To access other partNum elements you
must either use the POSITIONSARRAY or the getAllChildren() method on the partRateRequest element.

POSITIONSARRAY functions like the POSITION parameter to getElement(), but instead of specifying the
position of a single element, you must indicate the position of all elements in the path.  Therefore, to
get the third part number element, you would use

	my $thirdPart = $xmlDocument->getElementByPath('partRateRequest/partList/partNum', 1, 1, 3);
	
The additional 1,1,3 parameters indicate that you wish to retrieve the 1st partRateRequest element in 
the document, the 1st partList child of partRateRequest and the 3rd partNum child of the partList element
(in this instance, the partNum element that contains 'ss-839uent').


Returns the XML::Mini::Element reference if found, NULL otherwise.


=head2 parse SOURCE

Initialise the XML::Mini::Document (and its root XML::Mini::Element) using the
XML from file SOURCE.

SOURCE may be a string containing your XML document.

In addition to parsing strings, possible SOURCEs are:
 

	# a file location string 
	$miniXMLDoc->parse('/path/to/file.xml');
	
	# an open file handle
	open(INFILE, '/path/to/file.xml');
	$miniXMLDoc->parse(*INFILE);
	
	# an open FileHandle object
	my $fhObj = FileHandle->new();
	$fhObj->open('/path/to/file.xml');
	$miniXML->parse($fhObj);
	
In all cases where SOURCE is a file or file handle, XML::Mini takes care of slurping the
contents and closing the handle.


=head2 fromHash HASHREF [OPTIONS]

Parses a "hash representation" of your XML structure.  For each key => value pair within the
hash ref, XML::Mini will create an element of name 'key' :

 
 	- with the text contents set to 'value' if 'value' is a string
	
	- for each element of 'value' if value is an ARRAY REFERENCE
	
	- with suitable children for each subkey => subvalue if 'value' is a HASH REFERENCE.


For instance, if fromHash() is passed a simple hash ref like:
 
    
    my $h = {
	 
	 'spy'	=> {
		'id'	=> '007',
		'type'	=> 'SuperSpy',
		'name'	=> 'James Bond',
		'email'	=> 'mi5@london.uk',
		'address'	=> 'Wherever he is needed most',
	},
   };


then :

  $xmlDoc->fromHash($h);
  print $xmlDoc->toString();
  
will output 

 <spy>
  <email> mi5@london.uk </email>
  <name> James Bond </name>
  <address> Wherever he is needed most </address>
  <type> SuperSpy </type>
  <id> 007 </id>
 </spy>



The optional OPTIONS parameter may be used to specify which keys to use as attributes (instead of 
creating subelements).  For example, calling

  	
 my $options = { 
  			'attributes'	=> {
  					'spy'	=> 'id',
					'email'	=> 'type',
					'friend' => ['name', 'age'],
				}
		};


 my $h = {
	 
	 'spy'	=> {
		'id'	=> '007',
		'type'	=> 'SuperSpy',
		'name'	=> 'James Bond',
		'email'	=> {
				'type'		=> 'private',
				'-content'	=> 'mi5@london.uk',
				
			},
		'address' => {
				'type'	=> 'residential',
				'-content' => 'Wherever he is needed most',
			},
		
		'friend' => [
					{
						'name' 	=> 'claudia',
						'age'	=> 25,
						'type'	=> 'close',
					},
					
					{
						'name'	=> 'monneypenny',
						'age'	=> '40something',
						'type'	=> 'tease',
					},
					
					{
						'name'	=> 'Q',
						'age'	=> '10E4',
						'type'	=> 'pain',
					}
				],
									
	},
   };
   
	
  $xmlDoc->fromHash($h, $options);
  print $xmlDoc->toString();
  
will output something like:
 
 <spy id="007">
  <name> James Bond </name>
  <email type="private"> mi5@london.uk </email>
  <address>
   <type> residential </type>
   Wherever he is needed most
  </address>
  <type> SuperSpy </type>
  <friend age="25" name="claudia">
   <type> close </type>
  </friend>
  <friend age="40something" name="monneypenny">
   <type> tease </type>
  </friend>
  <friend age="10E4" name="Q">
   <type> pain </type>
  </friend>
 </spy>

As demonstrated above, you can use the optional href to specify tags for which attributes (instead of elements) should be 
created and you may nest hash and array refs to create complex structures.

NOTE: Whenever a hash references is used you lose the sequence in which the elements are placed - only the array references (which create
a list of identically named elements) can preserve their order.

See ALSO: the documentation for the related toHash() method.

Still TODO: Create some better docs for this!  For the moment you can take a peek within the test suite of the source distribution.


=head2 fromString XMLSTRING

Initialise the XML::Mini::Document (and it's root XML::Mini::Element) using the 
XML string XMLSTRING.

Returns the number of immediate children the root XML::Mini::Element now
has.

=head2 fromFile FILENAME

Initialise the XML::Mini::Document (and it's root XML::Mini::Element) using the
XML from file FILNAME.

Returns the number of immediate children the root XML::Mini::Element now
has.





=head2 toString [DEPTH]

Converts this XML::Mini::Document object to a string and returns it.

The optional DEPTH may be passed to set the space offset for the
first element.

If the optional DEPTH is set to $XML::Mini::NoWhiteSpaces
no \n or whitespaces will be inserted in the xml string
(ie it will all be on a single line with no spaces between the tags.

Returns a string of XML representing the document.

=head2 toFile FILENAME [SAFE]

Stringify and save the XML document to file FILENAME

If SAFE flag is passed and is a true value, toFile will do some extra checking, refusing to open the file
if the filename matches m|/\.\./| or m|#;`\*| or if FILENAME points to a softlink.  In addition, if SAFE
is 'NOOVERWRITE', toFile will fail if the FILENAME already exists.


=head2 toHash 

Transform the XML structure internally represented within the object 
(created manually or parsed from a file or string) into a HASH reference and returns the href.
 
For instance, if this XML is parse()d:
 
<people>
 
 <person id="007">                                   
  <email> mi5@london.uk </email>
  <name> James Bond </name>
  <address> Wherever he is needed most </address>
  <type> SuperSpy </type>
 </person>
 
 <person id="006" number="6">
  <comment> I am not a man, I am a free number </comment>
  <name> Number 6 </name>
  <email type="private"> prisoner@aol.com </email>
  <address> 6 Prison Island Road, Prison Island, Somewhere </address>
 </person>

</people>

The hash reference returned will look like this (as output by Data::Dumper):
 

 'people' => {

      'person' => [
                    {
                      'email' => 'mi5@london.uk',
                      'name' => 'James Bond',
                      'type' => 'SuperSpy',
                      'address' => 'Wherever he is needed most',
                      'id' => '007'
                    },
                    {
                      'email' => {
                                   'type' => 'private',
                                   '-content' => 'prisoner@aol.com'
                                 },
                      'comment' => 'I am not a man, I am a free number',
                      'number' => '6',
                      'name' => 'Number 6',
                      'address' => '6 Prison Island Road, Prison Island, Somewhere',
                      'id' => '006'
                    }
                  ]
    }
        


=head2 getValue

Utility function, call the root XML::Mini::Element's getValue()

=head2 dump

Debugging aid, dump returns a nicely formatted dump of the current structure of the
XML::Mini::Document object.


=head1 CAVEATS

It is impossible to parse "cross-nested" tags using regular expressions (i.e. sequences of the form
<a><b><a>...</a></b></a>).  However, if you have the Text::Balanced module installed (it is installed 
by default with Perl 5.8), such sequences will be handled flawlessly.

Even if you do not have the Text::Balanced module available, it is still possible to generate this type
of XML - the problem only appears when parsing.


=head1 AUTHOR


Copyright (C) 2002-2008 Patrick Deegan, Psychogenic Inc.

Programs that use this code are bound to the terms and conditions of the GNU GPL (see the LICENSE file). 
If you wish to include these modules in non-GPL code, you need prior written authorisation 
from the authors.


This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


=head2 LICENSE

    XML::Mini::Document module, part of the XML::Mini XML parser/generator package.
    Copyright (C) 2002-2008 Patrick Deegan
    All rights reserved
    
    XML::Mini is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    XML::Mini is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with XML::Mini.  If not, see <http://www.gnu.org/licenses/>.



=head1 SEE ALSO


XML::Mini, XML::Mini::Element

http://minixml.psychogenic.com

=cut
