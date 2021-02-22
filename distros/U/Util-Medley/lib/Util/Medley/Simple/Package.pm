package Util::Medley::Simple::Package;
$Util::Medley::Simple::Package::VERSION = '0.058';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::Package - an exporter module for Util::Medley::Package

=head1 VERSION

version 0.058

=cut

use Modern::Perl;
use Util::Medley::Package;

use Exporter::Easy (
    OK   => [qw(pkgBasename)],
    TAGS => [
        all => [qw(pkgBasename)],
    ]
);

my $package = Util::Medley::Package->new;
 
sub pkgBasename {
    return $package->basename(@_);    
}        
    
1;
