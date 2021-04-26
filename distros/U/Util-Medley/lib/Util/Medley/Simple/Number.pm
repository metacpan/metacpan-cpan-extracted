package Util::Medley::Simple::Number;
$Util::Medley::Simple::Number::VERSION = '0.060';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::Number - an exporter module for Util::Medley::Number

=head1 VERSION

version 0.060

=cut

use Modern::Perl;
use Util::Medley::Number;

use Exporter::Easy (
    OK   => [qw(commify decommify)],
    TAGS => [
        all => [qw(commify decommify)],
    ]
);

my $number = Util::Medley::Number->new;
 
sub commify {
    return $number->commify(@_);    
}        
     
sub decommify {
    return $number->decommify(@_);    
}        
    
1;
