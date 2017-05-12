package Wiki::Toolkit::Formatter::WikiLinkFormatterParent;

use strict;

use vars qw( $VERSION @_links_found );
$VERSION = '0.01';

use Text::WikiFormat as => 'wikiformat';

=head1 NAME

Wiki::Toolkit::Formatter::WikiLinkFormatterParent - The parent of Wiki::Toolkit formatters that work with Wiki Links.

=head1 DESCRIPTION

A provider of common formatter methods for L<Wiki::Toolkit> formatters that
deal with Wiki Links.

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(@args) or return undef;
    return $self;
}

=head1 METHODS

=head2 C<rename_links>

  $formatter->rename_links( $from, $to, $content );

Renames all the links to a certain page in the supplied content.
(Obviously this is dependent on object properties such as
C<extended_links> and C<implicit_links>.)

=cut

sub rename_links {
    my ($self, $from, $to, $content) = @_;

    # If we support extended (square bracket) links, update those
    if($self->{_extended_links}) {
        $content =~ s/\[$from\]/\[$to\]/g;
        $content =~ s/\[$from(\s*|.*?)\]/\[$to$1\]/g;
    }

    # If we support implicit (camelcase) links, update those
    if($self->{_implicit_links}) {
        $content =~ s/\b$from\b/$to/g;
        $content =~ s/^$from\b/$to/gm;
        $content =~ s/\b$from$/$to/gm;
    }

    return $content;
}

=head2 C<find_internal_links>

  my @links_to = $formatter->find_internal_links( $content );

Returns a list of all nodes that the supplied content links to.
(Obviously this is dependent on object properties such as
C<extended_links> and C<implict_links>.)

=cut

sub find_internal_links {
    my ($self, $raw) = @_;

    @_links_found = ();

    my $foo = wikiformat($raw,
            { link => sub {
                    my ($link, $opts) = @_;
                    $opts ||= {};
                    my $title;
                    ($link, $title) = split(/\|/, $link, 2)
                        if $opts->{extended};
                    push @Wiki::Toolkit::Formatter::WikiLinkFormatterParent::_links_found,
                        $link;
                    return ""; # don't care about output
                }
            },
            {
                extended       => $self->{_extended_links},
                prefix         => $self->{_node_prefix},
                implicit_links => $self->{_implicit_links} 
            } 
    );

    my @links = @_links_found;
    @_links_found = ();
    return @links;
}

=head1 SEE ALSO

L<Wiki::Toolkit::Formatter::Default>

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002-2003 Kake Pugh.  All Rights Reserved.
     Copyright (C) 2006-2009 the Wiki::Toolkit team. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
