#
# YUI::MenuBar::Markup::YAML
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 01/19/2010 10:32:05 PST 10:32:05
package YUI::MenuBar::Markup::YAML;

=head1 NAME

YUI::MenuBar::Markup::YAML - Provides the menu content from a YAML file

=head1 DESCRIPTION

It reads a L<YAML> file, gets the content and returns it so that
L<YUI::MenuBar::Markup> can use it for building YUI menu.

It uses L<YAML::Syck> for reading the YAML file.

An example of a YAML file can be:

    menu:
        -
            name: Searchers
            menu:
                -
                    name: Yahoo!
                    link: http://search.yahoo.com
                -
                    name: Google
                    link: http://www.google.com
                -
                    name: Altavista
                    link: http://www.altavista.com
        -
            name: Mail
            menu:
                -
                    name: Yahoo Mail!
                    link: http://mail.yahoo.com
                -
                    name: Gmail
                    link: http://gmail.com
                -

And so on, for any additional sub-menu you should just declare a new I<menu:>
and then list the items of it.

Valid items or any menu item are:

=over 4

=item * name: The name (text) of the item.

=item * link: The link where the item will be pointing

=item * menu: In case the item will have sub-items

=back

=cut
use Mouse;
use YAML::Syck;

our $VERSION = '0.01';

=head1 Attributes

=over 4

=item B<filename>

YAML path filename

=back

=cut
has 'filename' => (
        is => 'rw',
        isa => 'Str',
        required => 1);

=head1 Methods

=head2 B<get_data()>

Opens the YAML file (see L<filename>) and looks for the first I<menu> item,
once its found then all of its items are returned.

The method is called by L<YUI::MenuBar::Markup>.

=cut
sub get_data {
    my ($self) = @_;

    if (!-f $self->{'filename'}) {
        confess "$self->{'filename'} does not exists";
    }

    my $data = LoadFile($self->{'filename'});
    if (defined $data->{'menu'}) {
        return $data->{'menu'};
    }

    warn "No *menu* item found in $self->{'filename'}, returning undef";
    return undef;
}

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

