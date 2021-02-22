package Util::Medley::XML;
$Util::Medley::XML::VERSION = '0.058';
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

version 0.058

=cut

=head1 SYNOPSIS

 my $util = Util::Medley::XML->new;

=cut

########################################################

=head1 DESCRIPTION

Provides utility methods for working with XML.  All methods confess on
error.

=cut

has _xmlLintExists => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    builder => '_buildXmlLintExists',
);

########################################################

=head1 METHODS

=head2 beautifyFile

Beautifies an XML file.  Requires the xmllint command.

=over

=item usage:

 $util->beautifyFile($path);

 $util->beautifyFile(path => $path);
 
=item args:

=over

=item path [Str]

Location of the xml file.

=back

=back

=cut

multi method beautifyFile (Str :$path!) {

    if (!$self->_xmlLintExists) {
        confess "unable to find xmllint cmd";
    }
    
	my $cmd = "xmllint --format $path > $path.tmp";
	$self->Spawn->spawn( cmd => $cmd );
	$self->File->mv( "$path.tmp", $path );
}

multi method beautifyFile (Str $path) {

	$self->xmllBeautifyFile(path => $path);
}

# deprecated method
multi method xmlBeautifyFile (Str :$path!) {
   
    return $self->beautifyFile(@_);
}

# deprecated method
multi method xmlBeautifyFile (Str $path) {
    
    return $self->beautifyFile(@_);
}

=head2 beautifyString

Formats an XML string.  Requires the xmllint command.

=over

=item usage:

 $util->beautifyString($xml);

 $util->XmlBeautifyString(xml => $xml);
 
=item args:

=over

=item xml [Str]

An XML string.

=back

=back

=cut

multi method beautifyString (Str :$xml!) {

    if (!$self->_xmlLintExists) {
        confess "unable to find xmllint cmd";
    }
    
	my @cmd = ( 'xmllint', '--format', '-' );
	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, stdin => $xml );

	return $stdout;
}

multi method beautifyString (Str $xml) {

	return $self->beautifyString(xml => $xml);
}
           
# deprecated method            
multi method xmlBeautifyString (Str :$xml!) {
    
    return $self->beautifyString(@_); 
}

# deprecated method
multi method xmlBeautifyString (Str $xml) {
    
    return $self->beautifyString(@_);
}
                	  
######################################################################

method _buildXmlLintExists {

    my $path = $self->File->which('xmllint');        
    if ($path) {
        return 1;    
    }    
    
    return 0;
}

1;
