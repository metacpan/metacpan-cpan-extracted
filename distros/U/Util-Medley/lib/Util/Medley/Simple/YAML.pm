package Util::Medley::Simple::YAML;
$Util::Medley::Simple::YAML::VERSION = '0.062';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::YAML - an exporter module for Util::Medley::YAML

=head1 VERSION

version 0.062

=cut

use Modern::Perl;
use Util::Medley::YAML;

use Exporter::Easy (
    OK   => [qw(yamlDecode yamlEncode yamlRead yamlWrite)],
    TAGS => [
        all => [qw(yamlDecode yamlEncode yamlRead yamlWrite)],
    ]
);

my $yaml = Util::Medley::YAML->new;
 
sub yamlDecode {
    return $yaml->decode(@_);    
}        
     
sub yamlEncode {
    return $yaml->encode(@_);    
}        
     
sub yamlRead {
    return $yaml->read(@_);    
}        
     
sub yamlWrite {
    return $yaml->write(@_);    
}        
    
1;
