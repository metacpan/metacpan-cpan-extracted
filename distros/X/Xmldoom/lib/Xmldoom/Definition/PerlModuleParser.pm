
package Xmldoom::Definition::PerlModuleParser;

use IO::File;
use XML::GDOME;
use XML::DOM;
use Exception::Class::TryCatch;
use Xmldoom::Definition::SAXHandler qw( $OBJECT_NS $OBJECT_PERL_NS );
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $filename;

	if ( ref($args) eq 'HASH' )
	{
		$filename = $args->{filename};
	}
	else
	{
		$filename = $args;
	}

	my $self = {
		filename => $filename,
		text     => { },
		docs     => { }
	};
	bless $self, $class;

	# read the text in
	$self->_read();

	return $self;
}

sub get_package_names { return keys %{shift->{text}}; };

sub get_text 
{
	my ($self, $name) = @_;

	return $self->{text}->{$name};
}

sub get_document
{
	my ($self, $name) = @_;

	return $self->{docs}->{$name};
}

sub get_object_nodes
{
	my $self = shift;

	my @object_nodes;

	while ( my ($package_name, $doc) = each %{$self->{docs}} )
	{
		my $node = $doc->getDocumentElement()->getFirstChild();
		while ( $node )
		{
			if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
				 $node->getTagName() eq 'object' )
			{
				push @object_nodes, $node;
			}

			$node = $node->getNextSibling();
		}
	}

	return \@object_nodes;
}

sub _read
{
	my $self = shift;

	my $fd = IO::File->new( $self->{filename}, 'r' ) || die "$!: Cannot open $self->{filename}";
	my $in_xmldoom = 0;
	my $package_name = undef;

	while ( my $line = <$fd> )
	{
		if ( $line =~ /^package (.*);$/ )
		{
			$package_name = $1;
		}
		if ( $line eq "=begin Xmldoom\n" )
		{
			$in_xmldoom = 1;
		}
		elsif ( $line eq "=end Xmldoom\n" )
		{
			$in_xmldoom = 0;
		}
		elsif ( $in_xmldoom )
		{
			$self->{text}->{$package_name} .= $line;
		}
	}

	$fd->close();
}

sub create_documents
{
	my $self = shift;
	my $args = shift;

	my $infer_perl_class = 1;

	if ( ref($args) eq 'HASH' )
	{
		$infer_perl_class = $args->{infer_perl_class} if defined $args->{infer_perl_class};
	}

	while ( my ($package_name, $text) = each %{$self->{text}} )
	{
		my $xml_str = '';

		# add the initial declarations
		$xml_str .= "<?xml version='1.0'?>\n\n";
		$xml_str .= "<objects ";
		$xml_str .= "xmlns='$OBJECT_NS' ";
		$xml_str .= "xmlns:perl='$OBJECT_PERL_NS'>\n";

		# add the actual text
		$xml_str .= $text;

		# the footer
		$xml_str .= "</objects>\n";

		my $doc;
		
		# parse the XML attempting to die with the filename as well as 
		# the error from the parser.
		try eval
		{
			$doc = XML::GDOME->createDocFromString( $xml_str );
		};
		my $err = catch;
		if ( $err )
		{
			my $fn = $self->{filename};
			die "$fn: $err";
		}

		if ( $infer_perl_class )
		{
			my @object_nodes;

			# get all the <object/> nodes that lack a perl:class attribute
			my $node = $doc->getDocumentElement()->getFirstChild();
			while ( $node )
			{
				if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
				     $node->getTagName() eq 'object' and
				     not $node->hasAttributeNS($OBJECT_PERL_NS, 'class') )
				{
					push @object_nodes, $node;
				}

				$node = $node->getNextSibling();
			}

			if ( scalar @object_nodes > 1 )
			{
				die "Cannot infer perl:class='...' value because more than one <object/> defined in this package is missing such a declaration.";
			}

			if ( scalar @object_nodes == 1 )
			{
				$object_nodes[0]->setAttributeNS($OBJECT_PERL_NS, 'perl:class', $package_name);
			}
		}

		$self->{docs}->{$package_name} = $doc;
	}
}

1;

