package UNIVERSAL::source_location_for;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use B ();

sub UNIVERSAL::source_location_for {
    my($self, $method) = @_;
    my $entity = $self->can($method) or return();
    my $gv     = B::svref_2object($entity)->GV;
    return($gv->FILE, $gv->LINE);
}

1;
__END__

=head1 NAME

UNIVERSAL::source_location_for - Get source filename and line number of a subroutine

=head1 SYNOPSIS

    use UNIVERSAL::source_location_for;
    use File::Spec;
    my ($source_filename, $line)
        = File::Spec->source_location_for('canonpath');

=head1 DESCRIPTION

This module supplys a universal function "source_location_for",  a perl implementation of the method Method#source_location of Ruby.

It's useful for debug.

=head2 Functions

=head3 C<< Module->source_location_for('method') >>

Reuturn source filename and line number of the subroutine.

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>

Hiroki Honda E<lt>cside.story <at> gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
