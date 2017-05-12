package UNIVERSAL::dump;

# version info
$VERSION= '0.06';

# be as strict and verbose as possible
use strict;
use warnings;

# presets
my %preset= (
 blessed => 'Scalar::Util::blessed',
 dump    => 'Data::Dumper::Dumper',
 peek    => 'Devel::Peek::Dump',
 refaddr => 'Scalar::Util::refaddr',
);

# installed handlers
my %installed;

# satisfy require
1;

#-------------------------------------------------------------------------------
#
# Perl specific subroutines
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N method => subroutine pairs

sub import {
    my $class= shift;

    # make sure default is set
    unshift( @_,'dump' ) unless @_;

    # allow for redefining subroutines
    no warnings 'redefine';

    # handle all simple specifications
  METHOD:
    foreach my $spec (@_) {
        if ( !ref($spec) ) {
            die qq{Don't know how to install method "UNIVERSAL::$spec"\n}
              unless my $sub= $preset{$spec};
            $class->import( { $spec => $sub } );
            next METHOD;
        }

        # all methods
        foreach my $method ( keys %{$spec} ) {
            my $sub= $spec->{$method};
            $sub= $preset{$sub} if $preset{$sub};

            # already installed
            if ( my $installed= $installed{$method} ) {
                die qq{Cannot install "UNIVERSAL::$method" with "$sub":}
                    . qq{ already installed with "$installed"\n}
                  if $sub ne $installed;
            }

            # mark method as installed
            ( my $module= $sub ) =~ s#::[^:]+$##;
            $module =~ s#::#/#;
            $module .= ".pm";
            $installed{$method}= $sub;

            # install the method in the indicated namespace
            no strict 'refs';
            *{"UNIVERSAL::$method"}= sub {
                my $self = shift;
                eval { require $module };
                return $sub->( @_ ? @_ : $self ) if defined wantarray;
                print STDERR $sub->( @_ ? @_ : $self );
            } #UNIVERSAL::$method
        }
    }
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

UNIVERSAL::dump - add dump and other methods to all classes and objects

=head1 SYNOPSIS

  use UNIVERSAL::dump; # implicit 'dump'

 or:

  use UNIVERSAL::dump qw( dump peek ); # create both "dump" and "peek"

 or:

  use UNIVERSAL::dump ( { _dump => 'dump' } ); # dump using "_dump"

 or:

  use UNIVERSAL::dump ( { bar => 'Bar::Dumper' } ); # "bar" dumper

 my $foo = Foo->new;
 print $foo->dump;         # send dump of $foo to STDOUT
 print $foo->dump( $bar ); # send dump of $bar to STDOUT

 $foo->dump;         # send dump of $foo to STDERR
 $foo->dump( $bar ); # send dump of $bar to STDERR

=head1 VERSION

This documentation describes version 0.06.

=head1 DESCRIPTION

Loading the UNIVERSAL::dump module adds one or more methods to all classes
and methods.  It is intended as a debugging aid, alleviating the need to
add and remove debugging code from modules and programs.

By default, it adds a method "dump" to all classes and objects.  This method
either dumps the object, or any parameters specified, using L<Data::Dumper>.

As an extra feature, the output is sent to STDERR whenever the method is
called in a void context.  This makes it easier to dump variable structures
while debugging modules and programs.

The name of the method can be specified by parameters when loading the module.
These are the method names that are currently recognized:

=over 2

=item blessed

Return or prints with which class the object (or any value) is blessed.
Uses L<Scalar::Util>'s "blessed" subroutine.

=item dump

Return or prints a representation of the object (or any value that is
specified).  Uses L<Data::Dumper>'s "Dumper" subroutine.

=item peek

Return or prints the internal representation of the object (or any value that
is specified).  Uses L<Devel::Peek>'s "Dump" subroutine.

=item refaddr

Return or prints with the memory address of the object (or any value
specified).  Uses L<Scalar::Util>'s "refaddr" subroutine.

=back

If you cannot use one of the preset names of methods, you can specify a
reference to a hash instead, in which the key is the new name of the method
and the value is the name with which the dumping method is normally indicated.

If you have a dumping subroutine that is not available by default, you can
add your own by specifying a reference to a hash, in which the key is the
method name, and the value is the (fully qualified) name of the subroutine.

To prevent different modules fighting over the same method name, a check
has been built in which will cause an exception when the same method is
attempted with a different subroutine name.

=head1 WHY?

One day, I finally had enough of always putting a "dump" and "peek" method
in my modules.  I came across L<UNIVERSAL::moniker> one day, and realized
that I could do something similar for my "dump" methods.

=head1 REQUIRED MODULES

 Data::Dumper (any)

=head1 CAVEATS

=head2 AUTOLOADing methods

Any method called "dump" (or whichever class or object methods you activate
with this module) will B<not> be AUTOLOADed because they are already found
in the UNIVERSAL package.

=head2 Why no direct code refs?

It has been suggested that it should be possible to specify code references
as dump subroutines directly.  So far I haven't been convinced that this is
really necessary.  And it complicates the check for parameters versus preset
specification.  And it complicates the check for double definition of a dump
subroutine.

You could try to convince me with a good patch.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004, 2005, 2006, 2012 Elizabeth Mattijsen (liz@dijkmat.nl).
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

Development of this module sponsored by the kind people of Booking.com.

=cut
