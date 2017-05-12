package Try::Tiny::WarnCaught;
our $VERSION = 0.01;
use strictures;
use true;
use Try::Tiny ();
use Sub::Exporter -setup => {
    exports => [qw(catch)],
    groups => {
        default => [ qw(catch) ],
    },
};

sub catch (&;@) {
    my $cb = shift;
    Try::Tiny::catch {
        warn "Caught exception: $_";
        $cb->(@_);
    };
}

__END__

=head1 NAME

Try::Tiny::WarnCaught - L<Try::Tiny> extension to warn exceptions

=head1 SYNOPSIS

 use Try::Tiny;
 use Try::Tiny::WarnCaught;

=head1 DESCRIPTION

This module extends the very useful L<Try::Tiny>'s C<catch> functionality to automatically issue a warning
containing the caught exception.

=head1 SEE ALSO

L<Try::Tiny>

=head1 AUTHOR

 Joel Bernstein C< rataxis@cpan.org >.

=head1 COPYRIGHT

 Copyright (c) 2011 Joel Bernstein. All rights reserved.
 This program is free software; you can redistribute
 it and/or modify it under the same terms as Perl itself.

=cut

