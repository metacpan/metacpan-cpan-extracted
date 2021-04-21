package Util::Medley::Simple::Hostname;
$Util::Medley::Simple::Hostname::VERSION = '0.059';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::Hostname - an exporter module for Util::Medley::Hostname

=head1 VERSION

version 0.059

=cut

use Modern::Perl;
use Util::Medley::Hostname;

use Exporter::Easy (
    OK   => [qw(isFqdn parseHostname stripDomain)],
    TAGS => [
        all => [qw(isFqdn parseHostname stripDomain)],
    ]
);

my $hostname = Util::Medley::Hostname->new;
 
sub isFqdn {
    return $hostname->isFqdn(@_);    
}        
     
sub parseHostname {
    return $hostname->parseHostname(@_);    
}        
     
sub stripDomain {
    return $hostname->stripDomain(@_);    
}        
    
1;
