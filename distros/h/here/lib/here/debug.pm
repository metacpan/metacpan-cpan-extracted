package here::debug;
    use warnings;
    use strict;

    sub import   {$here::DEBUG = 1}
    sub unimport {$here::DEBUG = 0}

=head1 NAME

here::debug - enable / disable here debugging

=head1 SYNOPSIS

    use here::debug;
    use here ''.reverse '1 = x$ ym';
        # warns "use here: my $x = 1 at file.pl line 2."
        # and then inserts it into the source as normal.

=head2 import

    use here::debug;

is the same as

    BEGIN {$here::DEBUG = 1}

and causes all applications of the C< here > code injector to print the code to
stderr before inserting it into the source.

=head2 unimport

    no here::debug;

is the same as

    BEGIN {$here::DEBUG = 0}

=head1 SEE ALSO

=over 4

=item * L<here>

=item * L<here::install>

=item * L<here::declare>

=back

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-here at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=here>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1
