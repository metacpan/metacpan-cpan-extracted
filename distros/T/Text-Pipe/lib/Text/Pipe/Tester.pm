package Text::Pipe::Tester;

use strict;
use warnings;
use Text::Pipe;
use Test::More;


our $VERSION = '0.10';


use base 'Exporter';


our @EXPORT = qw(pipe_ok);



sub pipe_ok {
    my ($type, $options, $input, $expect, $name) = @_;
    $name = $type unless defined $name;
    my $pipe = Text::Pipe->new($type, @$options);
    if (ref $expect eq 'ARRAY') {
        is_deeply($pipe->filter($input), $expect, $name);
    } else {
        is($pipe->filter($input), $expect, $name);
    }
}


1;


__END__



=head1 NAME

Text::Pipe::Tester - Common text filter API

=head1 SYNOPSIS

    use Text::Pipe::Tester;
    pipe_ok('List::Grep', [ code => sub { $_ % 2 } ],
        [ 1 .. 10 ], [ 1, 3, 5, 7, 9 ]);

=head1 DESCRIPTION

This is not a pipe segment; rather it exports a function that helps in testing
pipes.

=head1 FUNCTIONS

=over 4

=item C<pipe_ok>

    pipe_ok($type, $options, $input, $expect, $name);

    pipe_ok('List::Grep', [ code => sub { $_ % 2 } ],
        [ 1 .. 10 ], [ 1, 3, 5, 7, 9 ]);

Constructs a pipe segment of type C<$type> using options C<$options>. It then
sends the C<$input> through the pipe and checks that the pipe returns
C<$output>; the check is done with C<is_deeply()> for array references. For
the test name, C<$name> is used if given, or C<$type> if no name has been
specified.

=back

Text::Pipe::Tester inherits from L<Exporter>.

The superclass L<Exporter> defines these methods and functions:

    as_heavy(), export(), export_fail(), export_ok_tags(), export_tags(),
    export_to_level(), import(), require_version()

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

The development version lives at L<http://github.com/hanekomu/text-pipe/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

