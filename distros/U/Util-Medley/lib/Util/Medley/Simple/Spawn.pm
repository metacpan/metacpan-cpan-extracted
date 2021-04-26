package Util::Medley::Simple::Spawn;
$Util::Medley::Simple::Spawn::VERSION = '0.060';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::Spawn - an exporter module for Util::Medley::Spawn

=head1 VERSION

version 0.060

=cut

use Modern::Perl;
use Util::Medley::Spawn;

use Exporter::Easy (
    OK   => [qw(capture spawn)],
    TAGS => [
        all => [qw(capture spawn)],
    ]
);

my $spawn = Util::Medley::Spawn->new;
 
sub capture {
    return $spawn->capture(@_);    
}        
     
sub spawn {
    return $spawn->spawn(@_);    
}        
    
1;
