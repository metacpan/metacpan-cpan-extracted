package WWW::Comic::Plugin::CyanideAndHappiness;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA %COMICS);
our $VERSION = '0.01';
@ISA = qw(WWW::Comic::Plugin);
%COMICS = ( cyanideandhappiness => 'Cyanide and Happiness' );

# $Id: CyanideAndHappiness.pm 326 2008-04-04 22:28:44Z davidp $

=head1 NAME

WWW::Comic::Plugin::CyanideAndHappiness - WWW::Comic plugin to fetch C+H

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

See L<WWW::Comic> for full details, but here's a brief example:

 use WWW::Comic;
 my $wc = new WWW::Comic;
 my $latest_candh_strip_url 
    = WWW::Comic->strip_url(comic => 'cyanideandhappiness');
 

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch the Cyanide and Happiness comic from
http://www.explosm.net/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.


=head1 FUNCTIONS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=cut


sub new {
    my $class = shift;
    my $self = { homepage => 'http://www.explosm.net/comics/' };
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
    
    my $id = $param{id} || 'new';
    my $url = $self->{homepage} . "$id/";
    
    my $response = $self->_new_agent->get($url);
    if ($response->is_success) {
        my $html = $response->content;
        my $alt_text = 'Cyanide and Happiness, a daily webcomic';
        if ($html =~ m{<img alt="$alt_text" src="([^"]+)">}msi)
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
C<bug-www-comic-plugin-cyanideandhappiness at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-CyanideAndHappiness>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::CyanideAndHappiness


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-CyanideAndHappiness>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-CyanideAndHappiness>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-CyanideAndHappiness>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-CyanideAndHappiness>

=back


=head1 ACKNOWLEDGEMENTS

To Nicola Worthington (NICOLAW) for writing WWW::Comic

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Comic::Plugin::CyanideAndHappiness
