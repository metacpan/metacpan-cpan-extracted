package t::ExampleProject::KidsShow::NewClown;
use strict;
use base qw( Exporter );
our @EXPORT_OK = qw ( ShowOfWeight );

sub ShowOfWeight ($){
    my ($LitersOfWater) = @_;
    return $LitersOfWater * 1000; ## no critic (ProhibitMagicNumbers)
}
1;