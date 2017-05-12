package WWW::Comic::Plugin::DinosaurComics;

use warnings;
use strict;

use HTML::TreeBuilder;

use vars qw($VERSION @ISA %COMICS);

our $VERSION    = '0.01';
@ISA            = qw(WWW::Comic::Plugin);
%COMICS         = ( dinosaur_comics => 'Dinosaur Comics');

sub new {
        my $class       = shift;
        my $self        = { uri => 'http://www.qwantz.com' };
        bless $self, $class;
        $self->{ua}     = $self->_new_agent;
        return $self
}

sub strip_url {
        my ( $self, %args ) = @_; 

	unless ( $self->{cur} ) {
		my $r = $self->{ua}->get( "$self->{uri}/index.php" );

		if ( $r->is_success ) {
			$self->{tree} = HTML::TreeBuilder->new_from_content( $r->content );
			$self->{cur} = $self->{tree}->look_down( _tag => 'img', class => 'comic' )->attr( 'src' );
			$self->{cur} =~ s/^.*comic2-//;
			$self->{cur} =~ s/\.png//
		}
		else {
			$self->{cur} = 2372;
		}
	}
	
        return          ( ( exists $args{id} and $args{id} =~ /\d+$/ and $args{id} <= $self->{cur} )
                                ? "$self->{uri}/comics/comic2-$args{id}.png"
                                : "$self->{uri}/comics/comic2-$self->{cur}.png"
                        )   
}

=head1 NAME

WWW::Comic::Plugin::DinosaurComics - WWW::Comic plugin to fetch Dinosaur Comics

=head1 SYNOPSIS

See L<WWW::Comic> for full details.

	use strict;
	use warnings;

	use WWW::Comic;

	my $wc = new WWW::Comic;

	my $latest = $wc->get_strip( comic => 'dinosaur_comics' );

	my $favorite = $wc->get_strip( comic => 'dinosaur_comics', id => 1999 );

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch Dinosaur Comics from http://www.qwantz.com/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.

=head1 METHODS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=back

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-comic-plugin-dinosaurcomics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-DinosaurComics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::DinosaurComics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-DinosaurComics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-DinosaurComics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-DinosaurComics>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-DinosaurComics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Comic::Plugin::DinosaurComics
