package Text::MetaMarkup::AddOn::Raw;
use strict;

sub paragraph_raw {
    my ($self, $tag, $text) = @_;
    return $text;
}

sub inline_raw {
    my ($self, $tag, $text) = @_;
    return $text;
}

1;

__END__

=head1 NAME

Text::MetaMarkup::AddOn::Raw - Add-on for MM to support raw code

=head1 SYNOPSIS

    package Text::MetaMarkup::Subclass;
    use base qw(Text::MetaMarkup Text::MetaMarkup::AddOn::Raw);

=head1 DESCRIPTION

Text::MetaMarkup::AddOn::Raw adds support for the following special tags:

=over 4

=item Paragraph tag C<raw>

Includes the paragraph's text without further parsing.

=item Inline tag C<perl>

Includes the tag's text without further parsing.

=back

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut

