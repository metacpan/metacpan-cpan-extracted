package Util::Medley::XML;
$Util::Medley::XML::VERSION = '0.055';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Carp;

with 'Util::Medley::Roles::Attributes::File';
with 'Util::Medley::Roles::Attributes::Spawn';

=head1 NAME

Util::Medley::XML - utility XML methods

=head1 VERSION

version 0.055

=cut

=head1 SYNOPSIS

 my $util = Util::Medley::XML->new;

=cut

########################################################

=head1 DESCRIPTION

Provides utility methods for working with XML.  All methods confess on
error.

=cut

########################################################

=head1 METHODS

=head2 xmlBeautifyFile

Beautifies an XML file.  Requires the xmllint command.

=over

=item usage:

 $util->xmlBeautifyFile($path);

 $util->xmlBeautifyFile(path => $path);
 
=item args:

=over

=item path [Str]

Location of the xml file.

=back

=back

=cut

multi method xmlBeautifyFile (Str :$path!) {

	my $cmd = "xmllint --format $path > $path.tmp";
	$self->Spawn->spawn( cmd => $cmd );
	$self->File->mv( "$path.tmp", $path );
}

multi method xmlBeautifyFile (Str $path) {

	$self->xmllBeautifyFile(path => $path);
}

=head2 xmlBeautifyString

Formats an XML string.  Requires the xmllint command.

=over

=item usage:

 $util->xmlBeautifyString($xml);

 $util->XmlBeautifyString(xml => $xml);
 
=item args:

=over

=item xml [Str]

An XML string.

=back

=back

=cut

multi method xmlBeautifyString (Str :$xml!) {

	my @cmd = ( 'xmllint', '--format', '-' );
	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, stdin => $xml );

	return $stdout;
}

multi method xmlBeautifyString (Str $xml) {

	return $self->xmlBeautifyString(xml => $xml);
}
                	  
######################################################################

1;
