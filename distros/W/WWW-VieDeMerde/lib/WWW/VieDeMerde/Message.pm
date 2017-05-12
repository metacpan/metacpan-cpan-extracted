package WWW::VieDeMerde::Message;

use warnings;
use strict;
use Carp;

use XML::Twig;

=encoding utf8

=head1 NAME

WWW::VieDeMerde::Message - A message from VieDeMerde.fr

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    use WWW::VieDeMerde;
    
    my $toto = WWW::VieDeMerde->new();
    my $tata = $toto->get(1664);
    
    print $tata->text, $tata->author;

=head1 DESCRIPTION

You should first read the documentation L<WWW::VieDeMerde> !

A WWW::VieDeMerde::Message object describes a fmylife or viedemerde item. You probably do not need to create yourself such object, L<WWW::VieDeMerde> manage it.

The following accessors are useful:

=over 4

=item * id

=item * author

=item * category

=item * date

=item * agree

=item * deserved

=item * comments

It's the number of commentaries

=item * text

=item * comments_flag

=back

=head1 METHODS

=head2 new

Create a new WWW::VieDeMerde::Message given a vdm node the xml response to a query.

=cut

sub new {
    my $class = shift;
    my $t     = shift;

    my $self = {};
    bless($self, $class);

    $self->{id} = $t->att('id');
    foreach ($t->children()) {
        my $tag = $_->tag;
        $self->{$tag} = $_->text;
    }

    return $self;
}


=head2 parse

Take an xml tree and return a list of WWW::VieDeMerde::Message.
qu'il contient.

=cut

#'

sub parse {
    my $class = shift;
    my $t     = shift;

    my $root = $t->root;
    my $vdms = $root->first_child('items');

    my @vdm = $vdms->children('item');

    my @result = ();

    foreach (@vdm) {
        my $m = WWW::VieDeMerde::Message->new($_);
        push @result, $m;
#        print $m->{auteur}, ", ";
    }

# marche pas ?????
#    return map(WWW::VieDeMerde::Message->new, @vdm);
    return @result;
}

# read-only accessors
for my $attr (qw(id author category date agree deserved
                 comments comments_flag text )) {
    no strict 'refs';
    *{"WWW::VieDeMerde::Message::$attr"} = sub { $_[0]{$attr} }
}

=head1 AUTHOR

Olivier Schwander, C<< <olivier.schwander at ens-lyon.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-vdm at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-VieDeMerde>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::VieDeMerde


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-VieDeMerde>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-VieDeMerde>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-VieDeMerde>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-VieDeMerde>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::VieDeMerde
