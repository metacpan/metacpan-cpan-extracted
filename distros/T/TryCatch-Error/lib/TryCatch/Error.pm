package TryCatch::Error;

use MooseX::FollowPBP;
use Moose;

=head1 NAME

TryCatch::Error - A simple error base class.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module provides a building block to writing your own error objects, to use with TryCatch (or some similar module).

It enables you to write things like this, straight away:

    use TryCatch::Error;
    use TryCatch;

    try {
        # ...
        # something that can go horribly wrong
        if ( $error_condition ) {
            die TryCatch::Error->new( value => $foo, message => $bar );
        }
    }
    catch ( TryCatch::Error $e ) {
        print STDERR 'Ooops: ', $e->get_message, ' with ', $e->get_value;
    }

TryCatch::Error can be sub-classed to create your own errors (possibly containing more detail, see t/03-subclassing.t for an example).

=cut

has 'value'   => (
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
);

has 'message' => (
    is        => 'rw',
    isa       => 'Str',
    default   => '',
);

__PACKAGE__->meta->make_immutable;
no Moose;
no MooseX::FollowPBP;

=head1 FUNCTIONS

=head2 new

Create a new error object:

    my $e = TryCatch::Error->new( value => $foo, message => bar );

=head1 ACCESSORS

=head2 get_*

=head2 set_*

The default TryCatch::Error has 2 attributes, B<value> and B<message>, which are an integer and a string.


=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trycatch-error at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TryCatch-Error>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TryCatch::Error


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TryCatch-Error>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TryCatch-Error>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TryCatch-Error>

=item * Search CPAN

L<http://search.cpan.org/dist/TryCatch-Error/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Ash Berlin, the author of TryCatch

=item * The Moose crew

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Figueiredo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

45; # End of TryCatch::Error
