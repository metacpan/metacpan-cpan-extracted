# XML::Validate::LibXML

package XML::Validate::LibXML;

use strict;
use XML::Validate::Base;
use XML::LibXML;
use Carp;

use vars qw($VERSION @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.20 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw( XML::Validate::Base );

my $VALID_OPTIONS = {
	strict_validation => 1,
	base_uri          => '',
};

sub new {
	my $class = shift;
	my %options = @_;
	my $self = {
	};
	bless ($self, $class);
	
	$self->clear_errors();
	$self->set_options(\%options,$VALID_OPTIONS);
	
	DUMP("Instantiating XML::Validate::LibXML", $self);
	
	return $self;
}

sub version {
	return XML::LibXML->VERSION;
}

sub validate {
	my $self = shift;
	my ($xml) = @_;
	TRACE("Validating with LibXML. XML => " . defined($xml) ? $xml : 'undef' );
	
	$self->clear_errors();
	$self->{dom} = undef;

	die "validate called with no data to validate\n" unless defined $xml and length $xml > 0;

	my $parser = XML::LibXML->new();
	$parser->line_numbers(1) if $parser->can('line_numbers'); # (XML::LibXML > 1.56)
	$parser->load_ext_dtd(1);
	$parser->expand_entities(1);
	
	my $doc = eval { $parser->parse_string($xml) };

	if ($@) {
		TRACE("We have a parsing error: $@");
		$self->add_error({message => $@});
		return;
	}
	
	TRACE("We have a doctype") if $doc->internalSubset;
	
	if ($self->options->{strict_validation} && $doc->internalSubset) {
		TRACE("Parsing with strict validation");
		$parser->validation(1);
		DUMP("Base uri",$self->options->{base_uri});
		$doc = eval { $parser->parse_string($xml,$self->options->{base_uri}) };
		if ($@) {
			TRACE("We have a validation error: $@");
			$self->add_error({message => $@});
			return;
		}
	}
	
	$self->{dom} = $doc;
	return 1;
}

sub last_dom {
	my $self = shift;
	return $self->{dom};	
}

# Note: Our use of TRACE and DUMP here is a bit weird. We explicitly pass to
# the TRACE and DUMP in the superclass (XML::Validate::Base) because we expect
# to be dynamically loaded and we assume that the calling class will have dealt
# with Base but not this module. (Note that Log::Trace now has some support for
# dynamic loading. It doesn't play well with some modules in 5.6.1, but it seems
# fine in 5.8. So someday this won't be necessary.)

sub TRACE { XML::Validate::Base::TRACE(@_) }
sub DUMP  { XML::Validate::Base::DUMP(@_)  }

1;

__END__

=head1 NAME

XML::Validate::LibXML - Interface to LibXML validator

=head1 SYNOPSIS

  my $validator = new XML::Validate::LibXML(%options);
  if ($doc = $validator->validate($xml)) {
    ... Do stuff with $doc ...
  } else {
    print "Document is invalid\n";
  }

=head1 DESCRIPTION

XML::Validate::LibXML is an interface to the LibXML validating parser which can
be used with the XML::Validate module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Validate::LibXML instance using the specified options. (See
OPTIONS below.)

=item validate($xml)

Returns a true value if $xml could be successfully parsed, undef otherwise.

Returns a true (XML::LibXML::Document) if $xml could be successfully
parsed, undef otherwise.

=item last_dom()

Returns the DOM (XML::LibXML::Document) of the document last validated.

=item last_error()

Returns a hash ref containing the error from the last validate call. This
backend currently only fills in the message field of hash. Note that the error
gets cleared at the beginning of each C<validate> call.

=item version()

Returns the version of the XML::LibXML module that is installed

=back

=head1 OPTIONS

XML::Validate::LibXML takes the following options:

=over

=item strict_validation

If this boolean value is true, the document will be validated during parsing.
Otherwise it will only be checked for well-formedness. Defaults to true.

=item base_uri

Since the XML document is supplied as a string, the validator doesn't know the
document's URI. If the document contains any components referenced using
relative URI's, you'll need to set this option to the document's URI so that
the validator can retrieve them correctly.

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved using last_error.

On errors not related to the XML parsing, these methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 DEPENDENCIES

XML::LibXML

=head1 BUGS

last_error currently returns a hash ref with only the message field filled. It
would be nice to also fill the line and column fields.

=head1 VERSION

$Revision: 1.20 $ on $Date: 2005/09/06 11:05:08 $ by $Author: johna $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
