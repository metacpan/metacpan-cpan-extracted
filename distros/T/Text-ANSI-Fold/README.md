# NAME

Text::ANSI::Fold - Text folding with ANSI sequence and Asian wide characters.

# SYNOPSIS

    use Text::ANSI::Fold qw(ansi_fold);
    ($folded, $remain) = ansi_fold($text, $width, [ option ]);

    use Text::ANSI::Fold;
    my $f = new Text::ANSI::Fold width => 80, boundary => 'word';
    $f->configure(ambiguous => 'wide');
    ($folded, $remain) = $f->fold($text);

# DESCRIPTION

Text::ANSI::Fold provides capability to fold a text into two strings
by given width.  Text can include ANSI terminal sequences.  If the
text is divided in the middle of ANSI-effect region, reset sequence is
appended to folded text, and recover sequence is prepended to trimmed
string.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.

Use exported **ansi\_fold** function to fold original text, with number
of visual columns you want to cut off the text.  Width parameter have
to be a number greater than zero.

    ($folded, $remain) = ansi_fold($text, $width);

It returns a pair of strings.  First one is folded text, and second is
cut-off text.

This function returns at least one character in any situation.  If you
provide Asian wide string and just one column as width, it trims off
the first wide character even if it does not fit to given width.

Default parameter can be set by **configure** class method:

    Text::ANSI::Fold->configure(width => 80, padding => 1);

Then you don't have to pass second argument.

    ($folded, $remain) = ansi_fold($text);

Because second argument is always taken as width, use _undef_ when
using default width with additional parameter:

    ($folded, $remain) = ansi_fold($text, undef, padding => 1);

# OBJECT INTERFACE

You can create an object to hold parameters, which is effective during
object life time.  For example, 

    my $f = new Text::ANSI::Fold
        width => 80,
        boundary => 'word';

makes an object folding on word boundaries with 80 columns width.
Then you can use this without parameters.

    $f->fold($text);

Use **configure** method to update parameters:

    $f->configure(padding => 1);

Additional parameter can be specified on each call, and they precede
saved value.

    $f->fold($text, width => 40);

# STRING OBJECT INTERFACE

Experimentally fold object can hold string inside.

    $f->configure(text => "text");

And folded string can be taken by _retrieve_ method.

    while ((my $folded = $f->retrieve) ne '') {
        print $folded;
        print "\n" if $folded !~ /\n\z/;
    }

# OPTIONS

Option parameter can be specified as name-value list for **ansi\_fold**
function as well as **new** and **configure** method.

    ansi_fold($text, $width, boundary => 'word', ...);

    Text::ANSI::Fold->configure(boundary => 'word');

    my $f = new Text::ANSI::Fold boundary => 'word';

    $f->configure(boundary => 'word');

- **width** => _n_

    Specify folding width.

- **boundary** => "word"

    **boundary** option currently takes only "word" as a valid value.  In
    this case, text is folded on word boundary.  This occurs only when
    enough space will be provided to hold the word on next call with same
    width.

- **padding** => _bool_

    If **padding** option is given with true value, margin space is filled
    up with space character.  Next code fills spaces if the given text is
    shorter than 80.

        ansi_fold($text, 80, padding => 1);

- **padchar** => _char_

    **padchar** option specifies character used to fill up the remainder of
    given width.

        ansi_fold($text, 80, padding => 1, padchar => '_');

- **ambiguous** => "narrow" or "wide"

    Tells how to treat Unicode East Asian ambiguous characters.  Default
    is "narrow" which means single column.  Set "wide" to tell the module
    to treat them as wide character.

# SEE ALSO

- [App::sdif](https://metacpan.org/pod/App::sdif)

    [Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) was originally implemented in **sdif** command for
    long time, which provide side-by-side view for diff output.  It is
    necessary to process output from **cdif** command which highlight diff
    output using ANSI escape sequences.

- [Text::ANSI::Util](https://metacpan.org/pod/Text::ANSI::Util), [Text::ANSI::WideUtil](https://metacpan.org/pod/Text::ANSI::WideUtil)

    These modules provide a rich set of functions to handle string
    contains ANSI color terminal sequences.  In contrast,
    [Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) provides simple folding mechanism with minimum
    overhead.  Also **sdif** need to process other than SGR (Select Graphic
    Rendition) color sequence, and non-spacing combining characters, those
    are not supported by these modules.

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

- Kazumasa Utashiro
- [https://github.com/kaz-utashiro/Text-ANSI-Fold](https://github.com/kaz-utashiro/Text-ANSI-Fold)
