#-----------------------------------------------------------------
# XML::SemanticCompare
# Author: Edward Kawas <edward.kawas+xml-semantic-compare@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: SemanticCompare.pm,v 1.1 2009-12-01 21:12:28 ubuntu Exp $
#-----------------------------------------------------------------
package XML::SemanticCompare;
use strict;
use Carp;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;
use vars qw($AUTOLOAD);

#-----------------------------------------------------------------
# load all modules needed
#-----------------------------------------------------------------
use XML::Simple;
use XML::LibXML;
use XML::SemanticCompare::SAX;

use Data::Dumper;

=head1 NAME

XML::SemanticCompare - compare 2 XML trees semantically

=head1 SYNOPSIS

	use XML::SemanticCompare;
	my $x = XML::SemanticCompare->new;

	# compare 2 different files
	my $isSame = $x->compare($control_xml, $test_xml);
	# are they the same
	print "XML matches!\n"
	  if $isSame;
	print "XML files are semantically different!\n"
	  unless $isSame;

	# get the diffs and print them out
    my $diffs_arrayref = $x->diff( $control_xml, $test_xml );
    print "Diff: $_\n" foreach (@$diffs_arrayref);

	# test xpath statement against XML
	my $success = $x->test_xpath($xpath, $test_xml);
	print "xpath success!\n" if $success;

=head1 DESCRIPTION

This module is used for semantically comparing XML documents.

=cut

=head1 AUTHORS

Edward Kawas (edward.kawas+xml-semantic-compare@gmail.com)

=cut

#-----------------------------------------------------------------
# AUTOLOAD
#-----------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
	  or croak("$self is not an object");
	my $name = $AUTOLOAD;
	$name =~ s/.*://;    # strip fully-qualified portion
	unless ( exists $self->{_permitted}->{$name} ) {
		croak("Can't access '$name' field in class $type");
	}
	my $is_func = $self->{_permitted}->{$name}[1] =~ m/subroutine/i;
	unless ($is_func) {
		if (@_) {
			my $val = shift;
			$val = $val || "";
			return $self->{$name} = $val
			  if $self->{_permitted}->{$name}[1] =~ m/write/i;
			croak("Can't write to '$name' field in class $type");
		} else {
			return $self->{$name}
			  if $self->{_permitted}->{$name}[1] =~ m/read/i;
			croak("Can't read '$name' field in class $type");
		}
	}

	# call a function
	if ($is_func) {
		if (@_) {

			# parameterized call
			my $x = $self->{_permitted}->{$name}[0];
			return $self->$x(@_);
		} else {

			# un-parameterized call
			my $x = $self->{_permitted}->{$name}[0];
			return $self->$x();
		}
	}
}

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
	my ( $class, %options ) = @_;

	# permitted fields
	my %fields = (

		# attribute	        => [default, accessibility],
		trim       => [ 1,                       'read/write' ],
		use_attr   => [ 1,                       'read/write' ],
		compare    => [ "_test_xml",             'subroutine' ],
		diff       => [ "_get_xml_differences",  'subroutine' ],
		test_xpath => [ "_test_xpath_statement", 'subroutine' ],
	);

	# create an object
	my $self = { _permitted => \%fields };

	# set user values if they exist
	$self->{trim}     = $options{trim}     || '1';
	$self->{use_attr} = $options{use_attr} || '1';
	bless $self, $class;
	return $self;
}

#-----------------------------------------------------------------
# _test_xml: semantically compare $control_xml to $xml
#-----------------------------------------------------------------
sub _test_xml {
	my ( $self, $control_xml, $xml ) = @_;
	return undef unless $control_xml;
	return undef unless $xml;
	return undef if $control_xml =~ m//g;
	return undef if $xml         =~ m//g;

	# check the root element name first
	# this isnt very efficient, but until someone gives a better way ...
	my $parser   = XML::LibXML->new();
	my $cont_ele = undef;
	my $test_ele = undef;

	# try parsing a string or a file
	eval { $cont_ele = $parser->parse_string($control_xml); };
	eval { $cont_ele = $parser->parse_file($control_xml); } if $@;
	return undef if $@;
	eval { $test_ele = $parser->parse_string($xml); };
	eval { $test_ele = $parser->parse_file($xml); } if $@;
	return undef if $@;
	$cont_ele = $cont_ele->getDocumentElement;
	$test_ele = $test_ele->getDocumentElement;
	return undef
	  unless $cont_ele->localname eq $test_ele->localname
		  and $cont_ele->namespaceURI() eq $test_ele->namespaceURI();

	# free memory
	$parser   = undef;
	$cont_ele = undef;
	$test_ele = undef;

	# done checking the root element
	# create object with attributes
	my $xml_simple = new XML::Simple(
		ForceArray   => 1,
		ForceContent => 1,

		#		SuppressEmpty => 1,
		keyattr => [],
	) if $self->use_attr;

	# or create it without attributes
	$xml_simple = new XML::Simple(
		ForceArray   => 1,
		ForceContent => 1,

		#		SuppressEmpty => 1,
		NoAttr  => 1,
		keyattr => [],
	) unless $self->use_attr;

	# read both XML files into a HASH
	my $control = undef;
	my $test    = undef;

	# parse the control doc
	eval { $control = $xml_simple->XMLin($control_xml); };

	# check for invalid XML
	return undef if $@;

	# parse the test doc
	eval { $test = $xml_simple->XMLin($xml); };

	# check for invalid XML
	return undef if $@;
	return $self->_compare_current_level( $control, $test, (), () );
}

#-----------------------------------------------------------------
# _compare_current_level:
#    compares current level of data structures that represent XML
#      documents.
#    If the current level and all child levels match, a true value
#      is returned. Otherwise, undef is returned.
#-----------------------------------------------------------------
sub _compare_current_level {

	# $control is current level in hash
	# x_ns are the prefixes that we use
	my ( $self, $control, $test, $control_ns, $test_ns ) = @_;

	# if either hash is missing they arent equal
	return undef unless $control;
	return undef unless $test;

	# get the namespace prefix and uris at the  current level
	# for each doc and remove from current level of hash
	for my $key ( keys %$control ) {
		next unless $key =~ m/^xmlns[:]?/;

		#next unless $key =~ m|^{http://www\.w3\.org/2000/xmlns/}[\w]*$|;
		$control_ns->{''} = $control->{$key} if $key eq 'xmlns';
		$control_ns->{$1} = $control->{$key} if $key =~ m/xmlns\:(.*)$/g;
		delete $control->{$key} if ref( $control->{$key} ) ne 'ARRAY';
	}
	for my $key ( keys %$test ) {
		next unless $key =~ m/^xmlns[:]?/;

		#next unless $key =~ m|^{http://www\.w3\.org/2000/xmlns/}[\w]*$|;
		$test_ns->{''} = $test->{$key} if $key eq 'xmlns';
		$test_ns->{$1} = $test->{$key} if $key =~ m/xmlns\:(.*)$/g;
		delete $test->{$key} if ref( $test->{$key} ) ne 'ARRAY';
	}

	# compare current level number of keys
	return undef unless ( keys %$control ) == ( keys %$test );

	# number of keys are equal, so start comparing!
	my $matching_nodes = 0;
	for my $key ( keys %$control ) {
		my $success = 1;
		for my $test_key ( keys %$test ) {

		   # does the key exist?
		   # 'content' is a special case ... because its text content for a node
			if (
				 ( $key eq $test_key and $key eq 'content' )
				 or ( $self->_get_prefixed_key( $test_key, $test_ns ) eq
					      $self->_get_prefixed_key( $key, $control_ns )
					  and $self->_get_prefixed_key( $key, $control_ns ) )
			  )
			{

				# are we dealing with scalar values now or more nesting?
				if ( ref( $control->{$key} ) eq 'ARRAY' ) {

					# both items should be an array
					next unless ref( $test->{$test_key} ) eq 'ARRAY';

					# array sizes should match here ...
					next
					  unless @{ $control->{$key} } == @{ $test->{$test_key} };

					# more nesting try matching child nodes
					my $child_matches = 0;
					foreach my $child ( @{ $control->{$key} } ) {
						my $matched = undef;
						foreach my $test_child ( @{ $test->{$test_key} } ) {
							$matched =
							  $self->_compare_current_level( $child,
										   $test_child, $control_ns, $test_ns );
							$child_matches++ if $matched;
							last if $matched;
						}    # end inner foreach
						$matching_nodes++
						  if @{ $control->{$key} } == $child_matches;
					}
				} else {

					# compare scalar values now
					# we dont care about whitespace, so we need to trim the text
					my $c_text = $self->_clear_whitespace( $control->{$key} );
					my $t_text = $self->_clear_whitespace( $test->{$test_key} );
					$matching_nodes++ if $c_text eq $t_text;
					last if $c_text eq $t_text;
				}
			}
		}    #end inner for
	}

	# no differences found!
	return undef unless $matching_nodes == ( keys %$control );
	return 1;
}

#-----------------------------------------------------------------
# _clear_whitespace: a whitespace trim function
#-----------------------------------------------------------------
sub _clear_whitespace {
	my ( $self, $text ) = @_;
	return $text unless $self->trim;
	$text =~ s/^\s+//;
	$text =~ s/\s+$//;
	return $text;
}

#-----------------------------------------------------------------
# _get_prefixed_key:
#    goes through and tries to determine what the namespace URI
#     is for a prefix.
#    Once a URI is found, the prefix is swapped with URI and
#     returned.
#-----------------------------------------------------------------
sub _get_prefixed_key {
	my ( $self, $key, $ns_hash ) = @_;
	my $prefixed_key = $key;
	my $prefix = $1 if $key =~ m/^([\w]+)\:.*/;
	$prefixed_key =~ s/$prefix/$ns_hash->{$prefix}/
	  if $prefix and $ns_hash->{$prefix};

	# check for default xmlns
	$prefix = $prefix || '';
	$prefixed_key = $ns_hash->{$prefix} . ":" . $key
	  if not $prefix and defined $ns_hash->{$prefix};
	return $prefixed_key;
}

#-----------------------------------------------------------------
# _test_xpath_statement: apply $xpath to $xml
#-----------------------------------------------------------------
sub _test_xpath_statement {
	my ( $self, $xpath, $xml ) = @_;

	# no xpath expression, nothing to test
	return undef if $xpath =~ m//g;

	# empty xml, nothing to test
	return undef if $xml =~ m//g;

	#instantiate a parser
	my $parser = XML::LibXML->new();
	my $tree   = undef;

	# try parsing a string or a file
	eval { $tree = $parser->parse_string($xml); };
	eval { $tree = $parser->parse_file($xml); } if $@;
	return undef if $@;
	my $root = $tree->getDocumentElement;

	# evaluate the xpath statement
	my $results = undef;
	eval { $results = $root->find($xpath); };
	return undef if $@;

	# no results?
	return undef unless $results;

	# got some hits!
	return 1;
}

#-----------------------------------------------------------------
# _get_xml_differences:
#    get the differences between $xml and expected xml
#      and return them
#-----------------------------------------------------------------
sub _get_xml_differences {
	my ( $self, $control_xml, $test_xml ) = @_;
	my @diffs;

	# create a parser
    my $parser = new XML::SemanticCompare::SAX();
    
    # parse a file $xml is an array of strings representing the XML tree
    my $xml = undef;
    eval {$xml = $parser->parse ( method => 'string', data => $control_xml );};
    eval {$xml = $parser->parse ( method => 'file', data => $control_xml );} unless $xml;
	#my %control = map {($_, 1)} @$xml;
	my $xml2 = undef;
    eval {$xml2 = $parser->parse ( method => 'string', data => $test_xml );};
    eval {$xml2 = $parser->parse ( method => 'file', data => $test_xml );} unless $xml2;
	
	foreach my $i ( 0 .. scalar(@$xml)-1) {
		next unless $xml->[$i];
		foreach my $j (0 .. scalar(@$xml2)-1) {
			next unless $xml2->[$i];
	        if ($xml->[$i] eq $xml2->[$j]) {
	        	delete $xml->[$i];
	        	delete $xml2->[$j];
	        	last;
	        }
		}
	}
	push @diffs, grep {defined $_} (@$xml, @$xml2);
	# items left over ...
	# grep {$control{$_} > 0} keys %control;
	return \@diffs;
}

sub DESTROY { }
1;
__END__


=head1 SUBROUTINES

=head2 new

constructs a new XML::SemanticCompare reference.
parameters (all optional) include:

=over

=item   C<trim> - if set to a true value, then all whitespace is trimmed when comparing text. [defaults to 1]

=item   C<use_attr> - if set to a true value, then all attributes and elements are compared. [defaults to 1]

=back

=cut

=head2 trim 

getter/setter - use to get/set whether or not you would like whitespace trimmed before comparing text. Setting this to a true value (e.g. 1) causes text to be trimmed before being compared. Setting to undef leaves text as is.

=cut

=head2 use_attr

getter/setter - use to get/set whether or not you would like compare attributes. Setting this to a true value (e.g. 1) will allow you to compare attributes and elements. Setting to undef causes SemanticCompare to ignore attributes.

=cut

=head2 compare 

subroutine that determines whether or not the passed in text XML is semantically similar to the passed in control XML.

parameters - a scalar string of control XML (or a file location) and a scalar string of test XML (or a file location) to compare against each other.

a true value is returned if both XML docs are semantically similar, otherwise undef is returned. 

=cut

=head2 test_xpath 

subroutine that applies an XPATH expression to the passed in XML.

parameters - a scalar string representing an XPATH expression and a scalar string of XML (or a file location) to test it against.

a true value is returned if the xpath statement matches 1 or more nodes in the XML, otherwise undef is returned.

=cut

=head2 diff

subroutine that retrieves any differences found when comparing control XML and the test XML passed into this sub.

parameters - a scalar string of control XML (or a file location) and a scalar string of test XML (or a file location) to compare against each other.

an array ref of strings representing the differences found between xml docs is returned. The strings look like XPATH statements but are not actual XPATH statements.

=cut

=cut
