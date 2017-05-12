package Text::Markup::Rest;

use 5.8.1;
use strict;
use File::Spec;
use File::Basename ();
use constant WIN32  => $^O eq 'MSWin32';
use Symbol 'gensym';
use IPC::Open3;

our $VERSION = '0.23';

# Find Python (process stolen from App::Info).
my ($PYTHON, $RST2HTML);
for my $exe (WIN32 ? 'python.exe' : 'python') {
    my @path = (
        File::Spec->path,
        WIN32 ? (map { "C:\\Python$_" } '', 27, 26, 25) : ()
    );

    for my $p (@path) {
        my $path = File::Spec->catfile($p, $exe);
        next unless -f $path && -x $path;
        $PYTHON = $path;
        last;
    }

    unless ($PYTHON) {
        use Carp;
        my $sep = WIN32 ? ';' : ':';
        Carp::croak(
            "Cannot find $exe in path " . join $sep => @path
        );
    }

    # We have python, let's find out if we have docutils.
    my $output = gensym;
    my $pid = open3 undef, $output, $output, $PYTHON, '-c', 'import docutils';
    waitpid $pid, 0;
    if ($?) {
        use Carp;
        local $/;
        Carp::croak(
            qq{Missing required Python "docutils" module\n},
            <$output>
        );
    }

    # We ship with our own rst2html that's lenient with unknown directives.
    $RST2HTML = File::Spec->catfile(
        File::Basename::dirname(__FILE__),
        'rst2html_lenient.py'
    );

    # Make sure it looks like it will work.
    $pid = open3 undef, $output, $output, $PYTHON, $RST2HTML, '--test-patch';
    waitpid $pid, 0;
    if ($?) {
        use Carp;
        local $/;
        Carp::croak(
            qq{$RST2HTML will not execute\n},
            <$output>
        );
    }
}

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
        my $fh = _fh(
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

# Stolen from SVN::Notify.
sub _fh {
    # Ignored; looks like docutils always emits UTF-8.
    if (WIN32) {
        my $cmd = join join(q{" "}, @_) . q{"|};
        open my $fh, $cmd or die "Cannot fork: $!\n";
        return $fh;
    }

    my $pid = open my $fh, '-|';
    die "Cannot fork: $!\n" unless defined $pid;

    if ($pid) {
        # Parent process, return the file handle.
        return $fh;
    } else {
        # Child process. Execute the commands.
        exec @_ or die "Cannot exec $_[0]: $!\n";
        # Not reached.
    }
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
L<reStructuredText|http://docutils.sourceforge.net/docs/user/rst/quickref.html>
parser for L<Text::Markup>. It depends on the C<docutils> Python package
(which can be found as C<python-docutils> in many Linux distributions, or
installed using the command C<easy_install docutils>). It recognizes files
with the following extensions as reST:

=over

=item F<.rest>

=item F<.rst>

=back

=head1 Author

Daniele Varrazzo <daniele.varrazzo@gmail.com>

=head1 Copyright and License

Copyright (c) 2011-2014 Daniele Varrazzo. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
