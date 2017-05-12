package Constructor::Sugar;

use strictures 2;

use String::CamelCase 'decamelize';
use Throwable::SugarFactory::Utils '_getglob';

our $VERSION = '0.152700'; # VERSION

# ABSTRACT: export constructor syntax sugar

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


sub _export {
    my ( $pkg, $func, $code ) = @_;
    *{ _getglob $pkg, $func } = $code;
    return $func;
}

sub import {
    my ( undef, @specs ) = @_;
    my $target = caller;
    my ( @constructors, @iders );

    for my $spec ( @specs ) {
        my ( $class, $method ) = split /->/, $spec;
        $method ||= "new";
        my $id = ( reverse split /::/, $class )[0];
        my $ct = decamelize $id;
        die "Converting '$id' into a snake_case constructor did not result in"
          . " a different string."
          if $ct eq $id;

        push @constructors, _export $target, $ct, sub { $class->$method( @_ ) };
        push @iders,        _export $target, $id, sub { $class };
    }

    return ( \@constructors, \@iders );
}

1;

__END__

=pod

=head1 NAME

Constructor::Sugar - export constructor syntax sugar

=head1 VERSION

version 0.152700

=head1 SYNOPSIS

    { package My::Moo::Object; use Moo; has $_, is => 'ro' for qw( plus more ) }
    
    {
        package BasicSyntax;
        
        my $o = My::Moo::Object->new( plus => "some", more => "data" );
        die if !$o->isa( "My::Moo::Object" );
    }
    
    {
        package ConstructorWrapper;
        use Constructor::Sugar 'My::Moo::Object';
        
        my $o = object plus => "some", more => "data";
        die if !$o->isa( Object );
        die if Object ne "My::Moo::Object";
    }

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
