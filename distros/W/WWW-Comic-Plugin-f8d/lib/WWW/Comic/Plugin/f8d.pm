package WWW::Comic::Plugin::f8d;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA %COMICS);
our $VERSION = '0.02';
@ISA = qw(WWW::Comic::Plugin);
%COMICS = (f8d => 'f8d - minimalist and esoteric webcomic');

# $Id: f8d.pm 733 2009-09-17 13:31:20Z davidp $

=head1 NAME

WWW::Comic::Plugin::f8d - WWW::Comic plugin to fetch f8d comic


=head1 SYNOPSIS

See L<WWW::Comic> for full details, but here's a brief example:

 use WWW::Comic;
 my $wc = new WWW::Comic;
 my $latest_candh_strip_url 
    = WWW::Comic->strip_url(comic => 'f8d');
 

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch the f8d comic from http://www.f8d.org/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.


=head1 FUNCTIONS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=cut


sub new {
    my $class = shift;
    my $self = { homepage => 'http://www.f8d.org/' };
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
    $url .= "?c=$param{id}/" if $param{id};
    
    my $response = $self->_new_agent->get($url);
    if ($response->is_success) {
        my $html = $response->content;
        if ($html =~ m{<img src="(.+?)" title}i) {
            my $stripurl = $1;
            if (!$stripurl !~ /^http/) {
                $stripurl = "http://f8d.org" . $stripurl;
                return $stripurl;
            }
        } else {
            carp "Failed to find f8d comic strip at $url";
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
C<bug-www-comic-plugin-f8d at rt.cpan.org>,
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-f8d>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::f8d


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-f8d>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-f8d>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-f8d>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-f8d>

=back


=head1 ACKNOWLEDGEMENTS

To Nicola Worthington (NICOLAW) for writing WWW::Comic

=head1 COPYRIGHT & LICENSE

Copyright 2008-09 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Comic::Plugin::f8d
