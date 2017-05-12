package MooX::SugarFactory;

use strictures 2;
use Import::Into;
use MooX::BuildClass;
use MooX::BuildRole;
use Constructor::SugarLibrary ();
use Throwable::SugarFactory::Utils '_getglob';

our $VERSION = '0.152700'; # VERSION

# ABSTRACT: build a library of syntax-sugared Moo classes

#
# This file is part of Throwable-SugarFactory
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


sub import {
    my ( $class ) = @_;
    Constructor::SugarLibrary->import::into( scalar caller );    # I::I 1.001000
    my $factory = caller;
    *{ _getglob $factory, $_ } = $class->_creator_with( $factory, $_ )
      for qw( class role );
}

sub _creator_with {
    my ( $class, $factory, $type ) = @_;
    my $create = \&{ "Build" . ucfirst $type };
    sub {
        my ( $spec, @args ) = @_;
        my ( $class ) = split /->/, $spec;
        my $build = $factory->can( "BUILDARGS" ) || sub { shift; @_ };
        $create->( $class, $build->( $class, @args ) );
        $factory->sweeten_meth( $spec );
        return;
    };
}

1;

__END__

=pod

=head1 NAME

MooX::SugarFactory - build a library of syntax-sugared Moo classes

=head1 VERSION

version 0.152700

=head1 SYNOPSIS

Declare classes in a library that will export sugar.

    package My::SugarLib;
    use MooX::SugarFactory;
    
    class "My::Moo::Object" => (
        has => [ plus => ( is => 'ro' ) ],
        has => [ more => ( is => 'ro' ) ],
    );
    
    class "My::Moose::ThingRole" => (
        has     => [ contains => ( is => 'ro' ) ],
        has     => [ metaa    => ( is => 'ro' ) ],
    );
    
    class "My::Moose::Thing" => ( with => ThingRole(), extends => Object() );

Use class library to export sugar for object construction and class checking.

    package My::Code;
    use My::SugarLib;
    
    my $obj = object plus => "some", more => "data";
    die if !$obj->isa( Object );
    die if !$obj->plus eq "some";
    
    my $obj2 = thing contains => "other", meta => "data",    #
      plus => "some", more => "data";
    
    die if !$obj2->isa( Thing );
    die if !$obj2->does( ThingRole );
    die if !$obj2->isa( Object );
    die if !$obj2->meta eq "data";

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
