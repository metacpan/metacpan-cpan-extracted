package Text::Emoticon::Unicode;

use 5.006;
use strict;
use warnings;
use utf8;
use parent 'Text::Emoticon';

our $VERSION = '0.02';

sub default_config {
    return {
        strict => 0,
    };
}

sub do_filter {
    my ($self, $char) = @_;
    return $char;
}

__PACKAGE__->register_subclass({
    ':-)' => '☺',
    ':)'  => '☺',
    ':-(' => '☹',
    ':('  => '☹',
});

1;

__END__

=encoding utf8

=head1 NAME

Text::Emoticon::Unicode - Text::Emoticon filter for Unicode emoticons

=head1 VERSION

This document describes Text::Emoticon::Unicode version 0.02.

=head1 SYNOPSIS

    use Text::Emoticon;

    my $emoticon = Text::Emoticon->new('Unicode');

    my $msg = $emoticon->filter('Howdy :)');  # returns 'Howdy ☺'

=head1 DESCRIPTION

This is a L<Text::Emoticon> filter for converting ASCII emoticons to their
Unicode emoticon character equivalent.  Unlike the other Text::Emoticon
filters, this one does not use images from an external site or even use any
HTML.  Instead it replaces a series of characters like C<:-)> with a single
character like C<☺>.

Currently only the Unicode 1.1 emoticons C<☺> and C<☹> are supported, but an
option to enable the vast range of Unicode 6.0 emoticons will be added in a
future version.  An option to use numeric character references for HTML or XML
will also be added, but it’s easy to use L<HTML::Entities> or L<XML::Entities>
instead.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2012 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
