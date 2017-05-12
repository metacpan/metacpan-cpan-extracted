package WWW::Comic::Plugin::Wulffmorgenthaler;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA %COMICS);
our $VERSION = '0.01';
@ISA = qw(WWW::Comic::Plugin);
%COMICS = (wulffmorgenthaler => 'A Commentary on Life: Politics, News, '
    .'Entertainment, Technology, Culture, and Weirdo Beavers');


# $Id: Wulffmorgenthaler.pm 437 2008-08-25 23:00:18Z davidp $

=head1 NAME

WWW::Comic::Plugin::Wulffmorgenthaler - WWW::Comic plugin to fetch daily
Wulffmorgenthaler comic


=head1 SYNOPSIS

See L<WWW::Comic> for full details, but here's a brief example:

 use WWW::Comic;
 my $wc = new WWW::Comic;
 my $latest_candh_strip_url 
    = WWW::Comic->strip_url(comic => 'wulffmorgenthaler');
 

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch the Wulffmorgenthaler comic from
http://www.wulffmorgenthaler.com/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.


=head1 FUNCTIONS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=cut


sub new {
    my $class = shift;
    my $self = { homepage => 'http://www.wulffmorgenthaler.com/' };
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
    if ($param{id}) {
        return $url . 'striphandler.ashx?stripid=' . $param{id};
    }
    
    my $response = $self->_new_agent->get($url);
    if ($response->is_success) {
        my $html = $response->content;
        if ($html =~ m{class="strip" src="([^"]+)"}i) {
            my $stripurl = $1;
            if (!$stripurl !~ /^http/) {
                $stripurl = $self->{homepage} . $stripurl;
                return $stripurl;
            }
        } else {
            carp "Failed to find Wulffmorgenthaler comic strip at $url";
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
C<bug-www-comic-plugin-wulffmorgenthaler at rt.cpan.org>,
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-Wulffmorgenthaler>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::Wulffmorgenthaler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-Wulffmorgenthaler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-Wulffmorgenthaler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-Wulffmorgenthaler>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-Wulffmorgenthaler>

=back


=head1 ACKNOWLEDGEMENTS

To Nicola Worthington (NICOLAW) for writing WWW::Comic

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Comic::Plugin::Wulffmorgenthaler
