
package Xmldoom::ORB::Transport::XML;

use XML::Writer;
use strict;

sub new
{
	bless {}, shift;
}

sub get_mime_type 
{
	return "text/xml";
}

sub write_object
{
	my ($self, $object, $xml) = (shift, shift, shift);

	my $owner = 0;

	if ( not defined $xml )
	{
		$xml   = XML::Writer->new();
		$owner = 1;
	}

	# write our attribute base object XML jobber
	$xml->startTag('object');
	$xml->startTag('attributes');
	while ( my ($name, $value) = each %$object ) 
	{
		$xml->startTag( 'value', name => $name );
		$xml->characters( $value );
		$xml->endTag( 'value' );
	}
	$xml->endTag('attributes');
	$xml->endTag('object');

	if ( $owner )
	{
		$xml->end();
	}
}

sub write_object_list
{
	my ($self, $rs) = (shift, shift);

	my $xml = XML::Writer->new();
	$xml->startTag('results');
	while ( $rs->next() )
	{
		$self->write_object($rs->get_row(), $xml);
	}
	$xml->endTag('results');
	$xml->end();
}

sub write_count
{
	my ($self, $count) = (shift, shift);

	my $xml = XML::Writer->new();

	$xml->startTag('count');
	$xml->characters($count);
	$xml->endTag('count');

	$xml->xml();
}

1;

