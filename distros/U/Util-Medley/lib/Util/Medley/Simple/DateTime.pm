package Util::Medley::Simple::DateTime;
$Util::Medley::Simple::DateTime::VERSION = '0.062';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::DateTime - an exporter module for Util::Medley::DateTime

=head1 VERSION

version 0.062

=cut

use Modern::Perl;
use Util::Medley::DateTime;

use Exporter::Easy (
    OK   => [qw(iso8601DateTime iso8601DateTimeToEpoch localDateTime localDateTimeAdd localDateTimeIsValid localDateTimeToEpoch SECS_PER_DAY SECS_PER_HOUR SECS_PER_MIN timeMs)],
    TAGS => [
        all => [qw(iso8601DateTime iso8601DateTimeToEpoch localDateTime localDateTimeAdd localDateTimeIsValid localDateTimeToEpoch SECS_PER_DAY SECS_PER_HOUR SECS_PER_MIN timeMs)],
    ]
);

my $datetime = Util::Medley::DateTime->new;
 
sub iso8601DateTime {
    return $datetime->iso8601DateTime(@_);    
}        
     
sub iso8601DateTimeToEpoch {
    return $datetime->iso8601DateTimeToEpoch(@_);    
}        
     
sub localDateTime {
    return $datetime->localDateTime(@_);    
}        
     
sub localDateTimeAdd {
    return $datetime->localDateTimeAdd(@_);    
}        
     
sub localDateTimeIsValid {
    return $datetime->localDateTimeIsValid(@_);    
}        
     
sub localDateTimeToEpoch {
    return $datetime->localDateTimeToEpoch(@_);    
}        
     
sub SECS_PER_DAY {
    return $datetime->SECS_PER_DAY(@_);    
}        
     
sub SECS_PER_HOUR {
    return $datetime->SECS_PER_HOUR(@_);    
}        
     
sub SECS_PER_MIN {
    return $datetime->SECS_PER_MIN(@_);    
}        
     
sub timeMs {
    return $datetime->timeMs(@_);    
}        
    
1;
