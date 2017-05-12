package WWW::Mechanize::Plugin::Web::Scraper;

use strict;
use warnings;

our $VERSION = '0.02';

use Web::Scraper;

#####################################################################

sub import { }  # This plugin does not have any import options

sub init {
   no strict 'refs';
   *{caller(). '::scrape'} = \&scrape;
}

sub scrape {
   my ($mech, @processes) = @_;

   my $scraper = scraper { process @processes };
   return $scraper->scrape($mech->response);
}

1;

__END__

=head1 NAME

WWW::Mechanize::Plugin::Web::Scraper - Scrape the planet!

=head1 SYNOPSIS

  use strict;
  use WWW::Mechanize::Pluggable;

  my $mech = WWW::Mechanize::Pluggable->new();
     $mech->get("http://search.cpan.org/");
     $mech->submit_form(
        form_name => "f",
        fields    => {
           query  => "WWW::Mechanize"
        }
     );

  my $results = $mech->scrape( "/html/body/h2/a", "results[]", 
                               { title => "TEXT", url => '@href' }
                );
     

=head1 DESCRIPTION

C<WWW::Mechanize::Plugin::Web::Scraper> gives you the scraping power 
of L<Web::Scraper> in L<WWW::Mechanize>, hence the name ...

=head2 METHODS

=head3 scrape

C<scrape> is the only new method that can be called (as of yet) and accepts
process information as described in L<Web::Scraper>. Note that the function
I<process> can (and should) be omitted. The scraper will use the current
L<WWW::Mechanize> content, so make sure to "browse" to the right page before
calling the scrape function.

=head1 SEE ALSO

=over 4

=item L<WWW::Mechanize>

=item L<WWW::Mechanize::Pluggable>

=item L<Web::Scraper>

=back

=head1 BUGS

C<Bugs?> Most likely you want to pester either L<Andy|http://search.cpan.org/~petdance/> (if L<WWW::Mechanize> is broken), L<Joe|http://search.cpan.org/~mcmahon/> (if L<WWW::Mechanize::Pluggable> isn't working as expected) or L<Tatsuhiko|http://search.cpan.org/~miyagawa/> (the L<Web::Scraper> mastermind).

If these three people can't help, it then might be possible that this module is to blame (ok, I admit it, this module probably *is* to blame to begin with). Please be so kind to report it to L<http://rt.cpan.org/Ticket/Create.html?Queue=WWW-Mechanize-Plugin-Web-Scraper>.

=head1 AUTHOR

Menno Blom, E<lt>blom@cpan.orgE<gt>, L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
