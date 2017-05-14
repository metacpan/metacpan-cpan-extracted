package WWW::Mechanize::Plugin::Selector;
use strict;
use vars qw($VERSION);
$VERSION= '0.16';
use HTML::Selector::XPath 'selector_to_xpath';

=head1 SYNOPSIS

=head1 NAME

WWW::Mechanize::Plugin::Selector - CSS selector method for WWW::Mechanize

=head1 DESCRIPTION

This is a plugin (or "Role", for some) which supplies the C<< ->selector >>
method to your WWW::Mechanize object. It requires that the WWW::Mechanize
object implements a corresponding C<< ->xpath >> method, as L<WWW::Mechanize::Firefox>
and L<WWW::Mechanize::PhantomJS> do.

=head1 ADDED METHODS

=head2 C<< $mech->selector( $css_selector, %options ) >>

  my @text = $mech->selector('p.content');

Returns all nodes matching the given CSS selector. If
C<$css_selector> is an array reference, it returns
all nodes matched by any of the CSS selectors in the array.

This takes the same options that C<< ->xpath >> does.

=cut

sub selector {
    my ($self,$query,%options) = @_;
    $options{ user_info } ||= "CSS selector '$query'";
    if ('ARRAY' ne (ref $query || '')) {
        $query = [$query];
    };
    my $root = $options{ node } ? './' : '';
    my @q = map { selector_to_xpath($_, root => $root) } @$query;
    $self->xpath(\@q, %options);
};

1;

=head1 USE IN YOUR MODULE

If you are not using L<WWW::Mechanize::Pluggable>, you can import this
code in your module via the following:

  use WWW::Mechanize::Plugin::Selector;
  {
    no warnings 'once';
    *selector = \&WWW::Mechanize::Plugin::Selector::selector;
  }

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/www-mechanize-plugin-selector>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Mechanize-Plugin-Selector>
or via mail to L<www-mechanize-plugin-selector-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2010-2017 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
