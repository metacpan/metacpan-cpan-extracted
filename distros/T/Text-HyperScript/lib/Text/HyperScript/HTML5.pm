package Text::HyperScript::HTML5;

use strict;
use warnings;

use Exporter::Lite;
use Text::HyperScript ();

our $h = Text::HyperScript->can('h');

sub h {
    goto $h;
}

BEGIN {
    # referenced from: https://developer.mozilla.org/en-US/docs/Web/HTML/Element
    our @EXPORT = qw(
        html

        base head link_ meta style title

        body

        address article aside footer header
        h1 h2 h3 h4 h5 h6 main nav section

        blockquote dd div dl dt figcaption figure
        hr li menu ol p pre ul

        a abbr b bdi bdo br cite code data em
        i kbd mark q_ rp rt ruby s_ samp small
        span strong sub_ sup time_ u var wbr

        area audio img map_ track video

        embed iframe object picture portal source

        svg math

        canvas noscript script

        del ins

        caption col colgroup table tbody td tfoot
        th thead tr_

        buttom datalist fieldset form input
        label legend meter optgroup option
        output progress select_ textarea

        details dialog summary

        slot template
    );

    no strict 'refs';
    for my $func (@EXPORT) {
        my $tag = $func;
        $tag =~ s{_}{};

        *{ __PACKAGE__ . "::${func}" } = sub {
            unshift @_, $tag;
            goto &h;
        };
    }
    use strict 'refs';
}

1;

=encoding utf-8

=head1 NAME

Text::HyperScript::HTML5 - The html5 tagset for L<Text::HyperScript>.

=head1 SYNOPSIS

    use Text::HyperScript::HTML5 qw(p);

    print p('hi,'), "\n";
    # => "<p>hi,</p>\n"

=head1 SUPPORTED TAGS


    html

    base head link_ meta style title

    body

    address article aside footer header
    h1 h2 h3 h4 h5 h6 main nav section

    blockquote dd div dl dt figcaption figure
    hr li menu ol p pre ul

    a abbr b bdi bdo br cite code data em
    i kbd mark q_ rp rt ruby s_ samp small
    span strong sub_ sup time_ u var wbr

    area audio img map_ track video

    embed iframe object picture portal source

    svg math

    canvas noscript script

    del ins

    caption col colgroup table tbody td tfoot
    th thead tr_

    buttom datalist fieldset form input
    label legend meter optgroup option
    output progress select_ textarea

    details dialog summary

    slot template


=head1 GLOBAL VARIABLES

=head2 $h : CodeRef of Text::HyperScript::h

This variable exist for extends or replace hyperscript functions.

You could use your C<h> function instead of default C<h> function.

=head1 NOTE

some tags added C<_> suffix,
these name is conflict to perl builtin functions.

=head1 LICENSE

Copyright (C) OKAMURA Naoki a.k.a nyarla.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

OKAMURA Naoki a.k.a nyarla: E<lt>nyarla@kalaclista.comE<gt>

=cut
