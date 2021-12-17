package Util::Medley::Simple::List;
$Util::Medley::Simple::List::VERSION = '0.061';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::List - an exporter module for Util::Medley::List

=head1 VERSION

version 0.061

=cut

use Modern::Perl;
use Util::Medley::List;

use Exporter::Easy (
    OK   => [qw(contains diff differ isArray listToMap max min nsort shuffle undefsToStrings uniq)],
    TAGS => [
        all => [qw(contains diff differ isArray listToMap max min nsort shuffle undefsToStrings uniq)],
    ]
);

my $list = Util::Medley::List->new;
 
sub contains {
    return $list->contains(@_);    
}        
     
sub diff {
    return $list->diff(@_);    
}        
     
sub differ {
    return $list->differ(@_);    
}        
     
sub isArray {
    return $list->isArray(@_);    
}        
     
sub listToMap {
    return $list->listToMap(@_);    
}        
     
sub max {
    return $list->max(@_);    
}        
     
sub min {
    return $list->min(@_);    
}        
     
sub nsort {
    return $list->nsort(@_);    
}        
     
sub shuffle {
    return $list->shuffle(@_);    
}        
     
sub undefsToStrings {
    return $list->undefsToStrings(@_);    
}        
     
sub uniq {
    return $list->uniq(@_);    
}        
    
1;
