package Util::Medley::Simple::String;
$Util::Medley::Simple::String::VERSION = '0.061';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::String - an exporter module for Util::Medley::String

=head1 VERSION

version 0.061

=cut

use Modern::Perl;
use Util::Medley::String;

use Exporter::Easy (
    OK   => [qw(camelize isBlank isInt isUpper lTrim pascalize rTrim snakeize titleize trim undefToString)],
    TAGS => [
        all => [qw(camelize isBlank isInt isUpper lTrim pascalize rTrim snakeize titleize trim undefToString)],
    ]
);

my $string = Util::Medley::String->new;
 
sub camelize {
    return $string->camelize(@_);    
}        
     
sub isBlank {
    return $string->isBlank(@_);    
}        
     
sub isInt {
    return $string->isInt(@_);    
}        
     
sub isUpper {
    return $string->isUpper(@_);    
}        
     
sub lTrim {
    return $string->lTrim(@_);    
}        
     
sub pascalize {
    return $string->pascalize(@_);    
}        
     
sub rTrim {
    return $string->rTrim(@_);    
}        
     
sub snakeize {
    return $string->snakeize(@_);    
}        
     
sub titleize {
    return $string->titleize(@_);    
}        
     
sub trim {
    return $string->trim(@_);    
}        
     
sub undefToString {
    return $string->undefToString(@_);    
}        
    
1;
