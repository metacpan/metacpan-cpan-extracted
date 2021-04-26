package Util::Medley::Simple::XML;
$Util::Medley::Simple::XML::VERSION = '0.060';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::XML - an exporter module for Util::Medley::XML

=head1 VERSION

version 0.060

=cut

use Modern::Perl;
use Util::Medley::XML;

use Exporter::Easy (
    OK   => [qw(xmlBeautifyFile xmlBeautifyString)],
    TAGS => [
        all => [qw(xmlBeautifyFile xmlBeautifyString)],
    ]
);

my $xml = Util::Medley::XML->new;
 
sub xmlBeautifyFile {
    return $xml->beautifyFile(@_);    
}        
     
sub xmlBeautifyString {
    return $xml->beautifyString(@_);    
}        
    
1;
