package TestFilter;

 use vars qw( @ISA );

use       XML::Filter::GenericChunk;
@ISA = qw(XML::Filter::GenericChunk);

sub characters {
	my $self = shift;
	unless ( exists $self->{filter} && $self->{filter} == 2 ) {
		$self->SUPER::characters( @_ );	
	}
} 

sub start_element {
	my $self = shift;
	my $elem = shift;

	$self->SUPER::start_element( $elem );	
}

sub end_element {
	my $self = shift;
	my $elem = shift;

	if ( $self->is_tag() ) {
#		unless ( $self->is_current( $elem ) ) {
#			die "this filter avoids deep structures";
#		}
		if ( exists $self->{filter} && $self->{filter} == 2 ) {
			$self->add_data( $self->{xmldata} );
			$self->flush_chunk();
		}
	}

	$self->SUPER::end_element( $elem );
	if ( $self->is_tag() ) {
		die "tag boundaries crossed";
	}
}

# The __CORE__ package needs to be defined, because the TestFilter has to 
# be defined before the test cases. Otherwise we will not be able inherit 
# from XML::Filter::GenericChunk.
package __CORE__;

use Test;
use strict;

BEGIN { plan tests => 7 }


use XML::LibXML;
use XML::LibXML::SAX;
use XML::LibXML::SAX::Builder;
use XML::Filter::CharacterChunk;

use XML::Filter::GenericChunk;

sub test_new {
	my $filter;

	eval {
		$filter = XML::Filter::GenericChunk->new();
	};

	if ($@) {
		print "#  cannot create filter: $@\n";
		return 0;
	}
	return 1;
}

ok(test_new());

sub test_relaxednames {
	my $filter = XML::Filter::GenericChunk->new();

	# relaxed_names
	if ( $filter->relaxed_names() != 0 ) {
		print "#  bad default value for relaxed_names()\n";
		return 0;
	}

	$filter->relaxed_names(1);
	if ( $filter->relaxed_names() != 1 ) {
		print "#  relaxed_names() was not set\n";
		return 0;
	}

	if ( $filter->relaxed_names() != 1 ) {
		print "#  relaxed_names() was accidentaly reset\n";
		return 0;
	}

	$filter->relaxed_names(0);
	if ( $filter->relaxed_names() == 1 ) {
		print "#  relaxed_names() was not propperly set\n";
		return 0;
	}

	if ( $filter->relaxed_names() != 0 ) {
		print "#  relaxed_names() was not propperly set to 0\n";
		return 0;
	}

	# in this case the fuction should work as called without parameters
	$filter->relaxed_names(undef);
	if ( not defined $filter->relaxed_names() ) {
		print "#  relaxed_names() must not be undefined\n";
		return 0;
	}

	return 1;
}

ok(test_relaxednames());

sub test_dummyfilter01 {
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter    = XML::Filter::GenericChunk->new(Handler=>$handler);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter);

	my $string = q(<a><b>d</b><c/></a>);
	
	$filter->set_tagname(qw(b));

	my $doc = $generator->parse_string( $string );
	unless ( defined $doc ) {
		print "#  string was not parsed\n";
		return 0;
	}

	my $root = $doc->documentElement;
	unless ( $root->toString eq $string ) {
		print "#  string was not propperly parsed\n";
		print "#  " . $root->toString() . "\n";
		return 0;
	}

	$filter->{DropElement} = 1;
	my $tstring = q(<a>d<c/></a>);
	$doc = $generator->parse_string( $string );
	unless ( defined $doc ) {
		print "#  string was not parsed\n";
		return 0;
	}

	$root = $doc->documentElement;
	if ( $root->toString ne $tstring ) {
		print "#  tag b was not dropped\n";
		print "#  " . $root->toString() . "\n";
		return 0;
	}

	return 1;
}

ok(test_dummyfilter01());

sub test_dummyfilter02 {
 	# This test checks if two instances in one pipeline interfere
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter1    = XML::Filter::GenericChunk->new(Handler=>$handler);
	my $filter2    = XML::Filter::GenericChunk->new(Handler=>$filter1);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter2);

	my $string = q(<a><b>foo</b><c>bar</c></a>);

	$filter1->{DropElement} = 1;
	$filter2->{DropElement} = 1;

	$filter1->set_tagname( qw( b ) );
	$filter2->set_tagname( qw( c ) );

	my $doc = $generator->parse_string( $string );
	unless ( defined $doc ) {
		print "#  string was not parsed\n";
		return 0;
	}
	
	my $root = $doc->documentElement;
	if ( defined $root && $root->firstChild->toString() ne "foobar" ) {
		print "#  elements were not correctly filtered.\n";
		print "#  " . $root->toString() . "\n";
		return 0;
	} 
	return 1;
}

ok(test_dummyfilter02());

sub test_testfilter01 {
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter    = TestFilter->new(Handler=>$handler);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter);
	my $doc;

	$filter->set_tagname(qw( b ));

	my $string = q(<a><b>d</b><c/></a>);

	eval { $doc = $generator->parse_string( $string ); };
	if ($@) {
		print "#  parser run failed due to filter errors\n";
		print "#  $@ \n";
		return 0;
	}

	return 1;
}

ok(test_testfilter01());

sub test_testfilter02 {
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter    = TestFilter->new(Handler=>$handler);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter);
	my $doc;

	$filter->set_tagname(qw( a ));

	my $string  = q(<a>foo</a>);
	my $string2 = q(<a><b>d</b><c/></a>);
	my $xmldata = q(<b>d</b><c/>);

	$filter->{filter} = 2;
	$filter->{xmldata} = $xmldata;

	eval { $doc = $generator->parse_string( $string ); };
	if ($@) {
		print "#  parser run failed due to filter errors\n";
		print "#  $@ \n";
		return 0;
	}

	unless ( defined $doc ) {
		print "#  document was not properly parsed\n";
		return 0;
	}

	if ( $doc->documentElement->toString() ne $string2 ) {
		print "#  document wasn't properly filtered\n";
		return 0;
	}

	return 1;
}

ok(test_testfilter02());

sub test_testfilter03 {
	my $handler   = XML::LibXML::SAX::Builder->new();
	my $filter1   = XML::Filter::CharacterChunk->new(Handler=>$handler);
	my $filter2   = TestFilter->new(Handler=>$filter1);
	my $generator = XML::LibXML::SAX->new(Handler=>$filter2);
	my $doc;

	$filter2->set_tagname(qw( a ));
	$filter1->set_tagname(qw( b ));

	my $string  = q(<a>foo</a>);
	my $string2 = q(<a><b><d/></b><c/></a>);
	my $xmldata = q(<b>&lt;d/&gt;</b><c/>);

	$filter2->{filter} = 2;
	$filter2->{xmldata} = $xmldata;

	eval { $doc = $generator->parse_string( $string ); };
	if ($@) {
		print "#  parser run failed due to filter errors\n";
		print "#  $@ \n";
		return 0;
	}

	unless ( defined $doc ) {
		print "#  document was not properly parsed\n";
		return 0;
	}

	if ( $doc->documentElement->toString() ne $string2 ) {
		print "#  document wasn't properly filtered\n";
		return 0;
	}

	return 1;
}

ok(test_testfilter03());

1;