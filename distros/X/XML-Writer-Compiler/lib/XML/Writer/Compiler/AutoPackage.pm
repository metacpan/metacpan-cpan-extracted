package XML::Writer::Compiler::AutoPackage;
BEGIN {
  $XML::Writer::Compiler::AutoPackage::VERSION = '1.112060';
}

# ABSTRACT: methods that are used by compiler-generated packages

use Moose::Role;
use Data::Diver qw( Dive DiveRef DiveError );

use Data::Dumper;

use XML::Writer;
use XML::Writer::String;

sub BUILD {
    my ($self) = @_;

    my $s = XML::Writer::String->new();
    my $writer = XML::Writer->new( DATA_MODE => 1, DATA_INDENT => 2, OUTPUT => $s );

    $self->string($s);
    $self->writer($writer);
}

sub DIVE {
    my ( $self, $root, @keys ) = @_;
    my $ref = Dive( $root, @keys );
    my $ret;

    #warn "DIVEROOT: " . Dumper($root);
    #warn "DIVEKEYS: @keys";
    if ( ref $ref eq 'ARRAY' ) {

        #warn 1.1;
        $ret = $ref;
    }
    elsif ( ref $ref eq 'HASH' ) {

        #warn 1.2;
        $ret = '';
    }
    elsif ( not defined $ref ) {

        #warn 1.3;
        $ret = '';
    }
    else {

        #warn 1.4;
        $ret = $ref;
    }

    #warn "DIVERET: $ret";
    $ret;

}

sub EXTRACT {
    my ( $self, $scalar ) = @_;

    my @ret;

    if ( ref $scalar eq 'ARRAY' ) {
        @ret = @$scalar;
    }
    elsif ( ref $scalar eq 'HASH' ) {
        @ret = ( [], '' );
    }
    else {
        @ret = ( [], $scalar );
    }

    #warn "EXTRACTRET: " . Dumper(\@ret);
    @ret;

}

sub maybe_morph {
    my ($self) = @_;
    if ( $self->can('morph') ) {
        warn "MORPHING";
        $self->morph;
    }
}

1;

