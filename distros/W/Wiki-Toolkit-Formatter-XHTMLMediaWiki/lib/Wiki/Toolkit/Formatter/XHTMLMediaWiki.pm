use strict;
use warnings;

package Wiki::Toolkit::Formatter::XHTMLMediaWiki;

use base 'XHTML::MediaWiki';

=head1 NAME

Wiki::Toolkit::Formatter::XHTMLMediaWiki - A Mediawiki-style formatter for Wiki::Toolkit.

=head1 VERSION

Version 0.04

=cut

use vars qw{$VERSION};
$VERSION = '0.04';

=head1 SYNOPSIS

This package implements a formatter for the Wiki::Toolkit module which attempts
to duplicate the behavior of the Mediawiki application (a set of PHP scripts
used by Wikipedia and friends).

    use Wiki::Toolkit
    use Wiki::Toolkit::Store::Mediawiki;
    use Wiki::Toolkit::Formatter::XHTMLMediaWiki;

    my $store = Wiki::Toolkit::Store::Mediawiki->new( ... );
    # See below for parameter details.
    my $formatter = Wiki::Toolkit::Formatter::XHTMLMediaWiki->new(
       store => $store
    );
    my $wiki = Wiki::Toolkit->new(store     => $store,
                                  formatter => $formatter);

=cut

use Carp qw(croak);

=head1 METHODS

=head2 new

  my $formatter = Wiki::Toolkit::Formatter::XHTMLMediaWiki->new(
      store => $store
  );

See: L<XHTML::MediaWiki> for other arguments

=cut

sub new
{
    my ($class, %args) = @_;

#    croak "`store' is a required argument" unless $args{store};
    my $store = $args{store};
    delete $args{store};

    my $self = $class->SUPER::new(%args);

    $self->{store} = $store;

    return $self;
}

1; # End of Wiki::Toolkit::Formatter::XHTMLMediaWiki
__END__

=head2 format

  my $html = $formatter->format($content);

This is the main method. You give this method C<wiki text> and it
returns C<xhtml>.

=cut

=head1 SEE ALSO

=over 4

=item L<XHTML::MediaWiki>

=item L<Wiki::Toolkit>

=item L<Wiki::Toolkit::Formatter::Default>

=item L<Wiki::Toolkit::Store::Mediawiki>

=item L<Wiki::Toolkit::Kwiki>

=back

=head1 AUTHOR

"G. Allen Morris III" C<< <gam3 at gam3.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-wiki-formatter-XHTMLMediaWiki at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wiki-Toolkit-Formatter-Mediawiki>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find more information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wiki-Toolkit-Formatter-XHTMLMediaWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wiki-Toolkit-Formatter-XHTMLMediaWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wiki-Toolkit-Formatter-XHTMLMediaWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/Wiki-Toolkit-Formatter-Mediawiki>

=back

=head1 EXAMPLE

There is a simple example C<cgi-bin> file in the examples directory of the distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2008 G. Allen Morris III, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
