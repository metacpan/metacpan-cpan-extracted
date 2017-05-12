use strict;
package UNIVERSAL::canAUTOLOAD;
use Class::ISA;
our $VERSION = '0.01';

no warnings 'redefine';
sub UNIVERSAL::can {
    my ($referent, $want) = @_;

    my $class = ref $referent || $referent;
    my @path = ( Class::ISA::self_and_super_path( $class ), 'UNIVERSAL' );

    # first look for a solid method
    for my $search (@path) {
        return \&{"$search\::$want"} if exists &{"$search\::$want"};
    }

    # then look for an AUTOLOAD sub
    for my $search (@path) {
        next unless exists &{"$search\::AUTOLOAD"};
        my $code = "package $search;".
          'sub { our $AUTOLOAD = "$class\::$want"; goto &AUTOLOAD }';
        my $sub = eval $code or die "compiling '$code': $@";
        return $sub;
    }

    # no? give up
    return undef;
}

1;
__END__

=head1 NAME

UNIVERSAL::canAUTOLOAD - installs a UNIVERSAL::can that respects AUTOLOAD subs

=head1 SYNOPSIS

 use UNIVERSAL::canAUTOLOAD;

 package MyModule;

 sub DESTROY {}
 sub AUTOLOAD {
     our $AUTOLOAD;
     print "in AUTOLOAD for $AUTOLOAD\n";
 }

 my $object = bless {}, 'MyModule';
 my $method = $object->can( 'potato' ); # returns a true value
 $object->$method();                    # call the AUTOLOADed potato method

=head1 DESCRIPTION

Ever flying in the face of common sense, this module makes a special
effort to make a section of L<UNIVERSAL/can> false.

For discussion of this need, consult this thread:

http://london.pm.org/pipermail/london.pm/Week-of-Mon-20031020/022190.html

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net> original need and anticipated
documentation from Mark Fowler.

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<UNIVERSAL/can>

=cut
