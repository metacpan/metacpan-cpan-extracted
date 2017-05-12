package XML::CanonicalizeXML;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::CanonicalizeXML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&XML::CanonicalizeXML::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('XML::CanonicalizeXML', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::CanonicalizeXML - Perl extension for inclusive and exclusive canonicalization of XML using libxml2


=head1 SYNOPSIS

use XML::CanonicalizeXML;
 

=head1 DESCRIPTION

useage:  

canonicalize (xml, xpath, namespace, exclusive, with_comments)

where:

xml is the xml string to be canonicalized

xpath is a string containing an xpath statement to the part of the xml document to be canonicalized, can optionally be null. See the examples provided with libxml2 for further details.

namespace is a string containing a list of namespaces to be included (only used in exclusive canonicalization)

exclusive is an int to specify exclusive canonicalization (1 = exclusive, 0 = non-exclusive)

with_comments is an int specifying whether comments are included in the canonicalized xml (0 = comments not included)

the function returns a string containing the canonicalized xml.


=head2 EXPORT

None by default.


=head1 SEE ALSO

http://www.xmlsoft.org for full details of libxml2


=head1 AUTHOR

Stefan Zasada, E<lt>sjz@zasada.co.ukE<gt>
with thanks to Mark Mc Keown

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
