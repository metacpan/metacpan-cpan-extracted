package WWW::Mechanize::Plugin::Display;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '1.01';
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

=head1 NAME

WWW::Mechanize::Plugin::Display - Display WWW::Mechanize results in a local web browser. 

=head1 SYNOPSIS

  use WWW::Mechanize;
  use WWW::Mechanize::Plugin::Display;

  my $mech = WWW::Mechanize->new;
  $mech->get('http://www.google.com');
  $mech->display;

=head1 DESCRIPTION

When you get an unexpected result while using WWW::Mechanize, it can be useful
to inspect the current page that Mechanize has fetched in a local browser.

This plugin adds a method for that, depending on L<HTML::Display> for most of
the work. 

It should work with WWW::Mechanize, or any sub-class of it. 

=head2 display()

    $mech->display();

Display the current HTML content in a local browser.

A quick example of setting a preferred browser:

 PERL_HTML_DISPLAY_COMMAND=w3m -T text/html %s

See L<HTML::Display> for configuration details. 

=cut

sub WWW::Mechanize::display {
    my $mech = shift;

    require HTML::Display;
    my $browser = HTML::Display->new();
    $browser->display(
        html     => $mech->content(), 
        location => $mech->uri(),
    );

}

=head1 AUTHOR

	Mark Stosberg C<< mark@summersault.com >>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1; #this line is important and will help the module return a true value
