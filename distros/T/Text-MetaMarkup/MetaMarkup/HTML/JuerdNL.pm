package Text::MetaMarkup::HTML::JuerdNL;
use strict;
use base qw(
    Text::MetaMarkup::HTML
    Text::MetaMarkup::AddOn::Raw
    Text::MetaMarkup::AddOn::Perl
);

sub link_ {
    my ($self, $href, $text) = @_;
    my $link = \$href->{href};
    my $exlinx = \%PLP::Script::exlinx;
    return unless $href->{href} or $text;
    $text ||= $$link;
    $$link = $exlinx->{lc $$link} if exists $exlinx->{lc $$link};
    $$link = $$link =~ m[/] ? $$link : lc $$link;
    return $self->SUPER::link($href, $text);
}

sub link_cpan {
    my ($self, $href, $text) = @_;
    $text ||= (split m[/], $href->{rest})[-1];
    $href->{rest} =~ s/::/-/g;
    $href->{href} = "http://search.cpan.org/author/$href->{rest}/" .
        (split /-/, $href->{rest})[-1] . ".pm";
    return $self->link($href, $text);
}

sub link {
    my ($self, $href, $text) = @_;
    $href = $self->escape($href->{href});
    $text = $href if not defined $text;
    return sprintf
        q[<a title="Off-site link: %s" href="/elsewhere.plp?href=%s" ] .
        q[target=_blank>%s</a>],
        $href, $href,
        $self->parse_paragraph_text($text);
}

1;

__END__

=head1 NAME

Text::MetaMarkup::HTML::JuerdNL - Example MM implementation

=head1 SYNOPSIS

    use Text::MetaMarkup::HTML::JuerdNL;
    print Text::MetaMarkup::HTML::JuerdNL->new->parse(file => $filename);

=head1 DESCRIPTION

Text::MetaMarkup::HTML::JuerdNL is a simple implementation of:

=over 4

=item * Text::MetaMarkup::HTML

=item * Text::MetaMarkup::AddOn::Raw

=item * Text::MetaMarkup::AddOn::Perl

=back

Text::MetaMarkup::JuerdNL adds support for the following special linking
schemes:

=over 4

=item C<%exlinx>

%PLP::Script::exlinx is a hash of C<< alias => address >> pairs, used to
resolve schemeless links. If the link is not found in this hash, it is
considered to be a local page.

=item C<cpan>

A link like C<[cpan:AUTHOR/Some::Module]> will be a link to its documentation,
namely at C<http://search.cpan.org/author/AUTHOR/Some-Module/Module.pm>.

This only works properly if the Some-Module distribution has a Module.pm in its
primary directory.

=back

=head1 EXAMPLE

Just have a look at <http://juerd.nl/>. To get the MetaMarkup source, use the
I<source> link near the end of a page.

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut
