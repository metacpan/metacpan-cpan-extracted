package Text::Markup::Rest;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use Text::Markup::Cmd;
use File::Basename;

our $VERSION = '0.40';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( rest => $_[1] ) if $_[1];
}

# Find Python or die.
my $PYTHON = find_cmd(
    [WIN32 ? 'python3.exe' : 'python3'],
    '--version',
);

# We have python, let's find out if we have docutils.
exec_or_die(
    qq{Missing required Python "docutils" module},
    $PYTHON, '-c', 'import docutils',
);

# We ship with our own rst2html that's lenient with unknown directives.
my $RST2HTML = File::Spec->catfile(dirname(__FILE__), 'rst2html_lenient.py');

exec_or_die(
    "$RST2HTML will not execute",
    $PYTHON, $RST2HTML, '--test-patch',
);

# Optional arguments to pass to rst2html
my @OPTIONS = qw(
    --no-raw
    --no-file-insertion
    --stylesheet=
    --cloak-email-address
    --no-generator
    --quiet
);

# Options to improve rendering of Sphinx documents
my @SPHINX_OPTIONS = qw(
    --dir-ignore toctree
    --dir-ignore highlight
    --dir-ignore index
    --dir-ignore default-domain

    --dir-nested note
    --dir-nested warning
    --dir-nested versionadded
    --dir-nested versionchanged
    --dir-nested deprecated
    --dir-nested seealso
    --dir-nested hlist
    --dir-nested glossary

    --dir-notitle code-block

    --dir-nested module
    --dir-nested function
    --output-encoding utf-8
);
# note: domains directive (last 2 options) incomplete

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $html = do {
        my $fh = open_pipe(
            $PYTHON, $RST2HTML,
            @OPTIONS, @SPHINX_OPTIONS,
            '--input-encoding', $encoding,
            $file
        );
        local $/;
        <$fh>;
    };

    # Make sure we have something.
    return undef if $html =~ m{<div\s+class\s*=\s*(['"])document\1>\s+</div>}ms;

    # Alas, --no-generator does not remove the generator meta tag. :-(
    $html =~ s{^\s*<meta\s+name\s*=\s*(['"])generator\1[^>]+>\n}{}ms;

    return $html;
}

1;
__END__

=head1 Name

Text::Markup::Rest - reStructuredText parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.rst');

=head1 Description

This is the
L<reStructuredText|https://docutils.sourceforge.io/rst.html> parser for
L<Text::Markup>. It depends on the C<docutils> Python package, which can be
found as C<python3-docutils> in many Linux distributions, or installed using
the command C<pip install docutils>. It recognizes files with the following
extensions as reST:

=over

=item F<.rest>

=item F<.rst>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Rest qr{re?st(?:aurant)};

=head1 Author

Daniele Varrazzo <daniele.varrazzo@gmail.com>

=head1 Copyright and License

Copyright (c) 2011-2023 Daniele Varrazzo. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
