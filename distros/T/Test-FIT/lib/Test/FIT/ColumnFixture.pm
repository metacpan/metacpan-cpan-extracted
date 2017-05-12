package Test::FIT::ColumnFixture;
$VERSION = '0.10';
use strict;
use base 'Test::FIT::Fixture';

sub set_headers {
    my $self = shift;
    my $matrix = $self->matrix;
    my $header_row = shift @$matrix
    or do {
        $self->fixture_cell->mark_error("No Header Row!");
        $self->has_errors(1);
    };
    $self->headers($header_row);
}

sub next_slice {
    my $self = shift;
    my $matrix = $self->matrix;
    shift @$matrix
}

1;

__END__

=head1 NAME

Test::FIT::ColumnFixture - Base class for column oriented fixtures

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
