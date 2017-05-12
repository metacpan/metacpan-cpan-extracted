#!/usr/bin/perl -I.
# note: this does not yet handle adding new nodes to the instance
# (e.g., for a bound repeat with a minOccurs. File upload is not implemented either.
package PostFilter;

use HTML::Entities ();
use XML::LibXML;

my $inst_param = '_instance';

sub new {
	my $class=shift;
	bless {@_},$class;
}

sub parse {
	my($self,$params)=@_;
	
	my $inst=$params->{$inst_param};
	die "No instance data in params" unless $inst;
	print STDERR "$inst\n" if $self->{debug} > 1;
	delete $params->{$inst_param};


	$self->{parser}||=XML::LibXML->new;
	#note: CGI.pm seems to do the decode already. not sure about
	#apache, so decode it just in case
	my $doc=$self->{parser}->parse_string(HTML::Entities::decode($inst));
	my $root=$doc->documentElement;

	print STDERR 'IN ','-' x 40,"\n",$doc->toString(1), "\n" if $self->{debug};

	while (my($k,$v) = each(%$params)) {
		$v=~s/\0/ /g;
		print STDERR "$k=$v\n" if $self->{debug} > 1;
		my($node)=$root->findnodes($k);
		next unless $node;		# only handles input already in instance data
		
		my $type=$node->nodeType;
		if ($type == XML_ELEMENT_NODE) {
			my $new=$doc->createTextNode($v);
			my $old=$node->firstChild;
			$node->replaceChild($new,$old);
		} elsif ($type == XML_ATTRIBUTE_NODE) {
			$node->setValue($v);
		} else {				# impossible?
			die "$type not found\n";
		}
	}
	print STDERR 'OUT ','-' x 40,"\n",$doc->toString(1), "\n" if $self->{debug};
	return $doc;
}
