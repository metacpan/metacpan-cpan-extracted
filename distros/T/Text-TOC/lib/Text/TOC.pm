package Text::TOC;
{
  $Text::TOC::VERSION = '0.10';
}

1;

# ABSTRACT: Build a table of contents from text documents


__END__
=pod

=head1 NAME

Text::TOC - Build a table of contents from text documents

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This module is intended to provide a general framework for building a table of
contents from one or more text documents. For now, it includes just one
concrete implementation, L<Text::TOC::HTML>.

=head1 SUPPORT

Please report any bugs or feature requests to C<bug-text-toc@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

