use 5.010;

use MooseX::Declare;

class WWW::StaticBlog
{
    our $VERSION = '0.02';
}

"My hovercraft is full of eels.";
__END__

=head1 NAME

WWW::StaticBlog - Generate a set of static pages for a blog.

=head1 VERSION

0.02

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=end readme


=head1 SYNOPSIS

Generate a set of static pages for a blog.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StaticBlog>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc WWW::StaticBlog
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StaticBlog>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StaticBlog>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StaticBlog>


=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StaticBlog>


=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jacob Helwig, all rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
