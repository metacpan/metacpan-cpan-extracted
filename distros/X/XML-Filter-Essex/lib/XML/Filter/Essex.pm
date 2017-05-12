package XML::Filter::Essex;

$VERSION = 0.01;

=head1 NAME

XML::Filter::Essex - SAX & DOM pull filtering

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<XML::Handler::Essex|XML::Handler::Essex> for how to receive and
react to events and L<XML::Generator::Essex|XML::Generator::Essex> for
how to create and send events.

Any events not returned by get() are sent downstream by default.

=head2 Methods

=over

=cut

use XML::Handler::Essex ();
use XML::Generator::Essex ();

@ISA = qw( XML::Handler::Essex XML::Generator::Essex );

use strict;

sub _skip_event {
    my $self = shift;
    $self->put( @_ );
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
