package WWW::Comic::Plugin::XKCD;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA %COMICS);
our $VERSION = '0.02';
@ISA = qw(WWW::Comic::Plugin);
%COMICS = (xkcd => 'xkcd - A webcomic of romance, sarcasm, math, and language');

# $Id: XKCD.pm 331 2008-04-07 21:58:43Z davidp $

=head1 NAME

WWW::Comic::Plugin::XKCD - WWW::Comic plugin to fetch XKCD comic


=head1 SYNOPSIS

See L<WWW::Comic> for full details, but here's a brief example:

 use WWW::Comic;
 my $wc = new WWW::Comic;
 my $latest_candh_strip_url 
    = WWW::Comic->strip_url(comic => 'xkcd');
 

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch the xkcd comic from http://www.xkcd.org/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.


=head1 FUNCTIONS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=cut


sub new {
    my $class = shift;
    my $self = { homepage => 'http://www.xkcd.org/' };
    bless $self, $class;
    return $self;
}

=item strip_url

Returns the URL to the current strip image (or, if given the 'id' param,
the URL to that particular strip)

=cut

sub strip_url {
    my $self = shift;
    my %param = @_;
    
    my $url = $self->{homepage};
    $url .= "$param{id}/" if $param{id};
    
    my $response = $self->_new_agent->get($url);
    if ($response->is_success) {
        my $html = $response->content;
        my $alt_text = 'Cyanide and Happiness, a daily webcomic';
        if ($html 
            =~ m{<h3>Image URL \(for hotlinking/embedding\): (.+)</h3>}msi)
        {
            my $url = $1;
            return $url;
        } else {
            carp "Failed to find C+H comic strip at $url";
            warn "Content was:\n$html\n";
            return;
        }
    
    } else {
        carp "Failed to fetch $url - " . $response->status_line;
        return;
    }
    
}

=back

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-www-comic-plugin-XKCD at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-XKCD>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::XKCD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-XKCD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-XKCD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-XKCD>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-XKCD>

=back


=head1 ACKNOWLEDGEMENTS

To Nicola Worthington (NICOLAW) for writing WWW::Comic

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Comic::Plugin::XKCD
