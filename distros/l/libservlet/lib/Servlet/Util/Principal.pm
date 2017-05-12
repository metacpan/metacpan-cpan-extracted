# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Util::Principal;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Util::Principal - security principal interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface represents the abstract notion of a principal, which
can be used to represent any entity, such as an individual, a
corporation, or a login id.

=head1 ACCESSOR METHODS

=over

=item getName()

Return the name of this Principal.

=back

=head1 SEE ALSO

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
