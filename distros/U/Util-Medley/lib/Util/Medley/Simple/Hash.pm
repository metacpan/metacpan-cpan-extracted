package Util::Medley::Simple::Hash;
$Util::Medley::Simple::Hash::VERSION = '0.061';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::Hash - an exporter module for Util::Medley::Hash

=head1 VERSION

version 0.061

=cut

use Modern::Perl;
use Util::Medley::Hash;

use Exporter::Easy (
    OK   => [qw(isHash merge)],
    TAGS => [
        all => [qw(isHash merge)],
    ]
);

my $hash = Util::Medley::Hash->new;
 
sub isHash {
    return $hash->isHash(@_);    
}        
     
sub merge {
    return $hash->merge(@_);    
}        
    
1;
