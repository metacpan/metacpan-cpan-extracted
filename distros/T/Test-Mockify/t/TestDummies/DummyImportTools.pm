package t::TestDummies::DummyImportTools;
use strict;
use warnings;
use base qw ( Exporter );
our @EXPORT_OK = qw (Doubler EmptyProtoType);

sub Doubler($) {
    my ($Value) = @_;
    return $Value * 2;
}

sub EmptyProtoType(){
    return 'yes';
}
1;