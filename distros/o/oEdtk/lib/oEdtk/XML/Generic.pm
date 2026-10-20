package oEdtk::XML::Generic;

use strict;
use warnings;

use 5.020;

use feature qw(signatures);
## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
no warnings 'experimental::signatures';

use Carp;
use XML::Simple;
use XML::LibXML;
use File::Basename;
use English qw( -no_match_vars );

our $VERSION = 2.1129;

use Exporter 'import';
our @EXPORT_OK = qw(xml_open xml_verif);

# Extract the key/value pairs from a Cameleon XML file and return them in a hash.
sub xml_open ( $fh, $options_arg = undef ) {

	# The caller's options win over the default. The fork merged them with
	# Hash::Merge::Simple, a dependency the fork never declared here; the default is a
	# single scalar key, so a plain hash copy is equivalent and keeps the merged
	# distribution free of that (dead) prerequisite.
	my $options = { suppressempty => q{}, %{ $options_arg // {} } };

	binmode($fh);    # Make sure to drop any PerlIO layer.
	my $xml  = XML::Simple->new();
	my $data = $xml->XMLin( $fh, %{$options} );

	return $data;
}

sub xml_verif ($namefile) {
	my ( $name, $path, $suffix ) = fileparse( $namefile, "\.[^\n+.]*" );

	# to be completed according to the future XML parsers
	my @lib_ext = qw(.xsd .dtd);

	# The schema sits next to the document, under the same basename. The fork built
	# the candidate by interpolating "$name.$lib_ext[$i]", which doubled the dot
	# ("data..xsd") so the existence test never matched and xml_verif croaked on every
	# call; the loader below used the concatenation form and so disagreed with the
	# test. Build the candidate once and use it for both.
	my $schema_file;
	foreach my $ext (@lib_ext) {
		my $candidate = $name . $ext;
		if ( -e $candidate ) { $schema_file = $candidate; last; }
	}

	if ($schema_file) {
		my $schema     = XML::LibXML::Schema->new( location => $schema_file );
		my $parser     = XML::LibXML->new;
		my $doc_parser = $parser->parse_file($namefile);

		# XML::LibXML::Schema::validate returns a false value when the document is
		# valid and dies when it is not, so the check keys on the exception. The
		# fork keyed it on the return value ("if (eval { ... })") and was inverted:
		# it croaked on success and silently accepted an invalid document.
		my $valid = eval { $schema->validate($doc_parser); 1 };
		croak $@ unless $valid;
		return ( print "\n>>>> validated successfully\n" );
	}
	else {
		print "\n>>>>> can\'t locate schema_file\n";
		croak;
	}
	return 0;
}

1;

=head1 NAME

oEdtk::XML::Generic - generic XML reader and schema verifier

=head1 SYNOPSIS

    use oEdtk::XML::Generic qw(xml_open xml_verif);

    my $data = xml_open($fh);
    xml_verif($file);    # dies when $file does not match its .xsd / .dtd

=head1 DESCRIPTION

Two generic helpers: C<xml_open> turns an XML filehandle into the plain Perl
data structure L<XML::Simple> builds, and C<xml_verif> validates a file against
the C<.xsd> or C<.dtd> sitting next to it. Moved from C<oEUser::XML::Generic>
into the mainline at S21 of the fork-merge plan (decision D23); the old name
stays available as a delegate.

=head1 FUNCTIONS

=head2 xml_open

    my $data = xml_open($fh, $options);

Read C<$fh> with L<XML::Simple> and return the resulting structure. C<$options>
is merged over the default C<< { suppressempty => '' } >>.

=head2 xml_verif

    xml_verif($file);

Look for C<$file> with its extension replaced by C<.xsd> then C<.dtd>, validate
C<$file> against the first one found and report success. It croaks when the
document is invalid or when no schema file is found. Note that
C<XML::LibXML::Schema::validate> returns a false value on success and dies on
failure, which is what the check relies on; see F<t/int/42_xml_readers.t>.

=head1 AUTHOR

The oEdtk team.

=cut
