package FakeStaticTools;
use strict;
use warnings;
use base qw( Exporter );
our @EXPORT_OK = qw (
        ReturnHelloWorld
        HelloSpy
        HappyOverride
    );
    
sub ReturnHelloWorld {
    #this method could, for example, access the database
    return 'Hello World';
}

sub HelloSpy {
    return 'Bond, James Bond!';
}

sub HappyOverride {
    return 'original in FakeStaticTools';
}