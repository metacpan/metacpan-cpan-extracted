use strict;
use warnings;

# ABSTRACT: Internal fatal value object for the "Unknown::Values" distribution

package Unknown::Values::Instance::Fatal;
$Unknown::Values::Instance::Fatal::VERSION = '0.101';
use Carp 'confess';
use base 'Unknown::Values::Instance';

sub bool {
    confess("Boolean operations not allowed with 'fatal unknown' objects");
}

sub compare {
    confess("Comparison operations not allowed with 'fatal unknown' objects");

}

sub sort {
    confess("Sorting operations not allowed with 'fatal unknown' objects");
}

sub to_string {
    confess("Printing not allowed with 'fatal unknown' objects");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Unknown::Values::Instance::Fatal - Internal fatal value object for the "Unknown::Values" distribution

=head1 VERSION

version 0.101

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
