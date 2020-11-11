package Text::Amuse::Preprocessor;

use strict;
use warnings;

use Text::Amuse::Preprocessor::HTML;
use Text::Amuse::Preprocessor::Parser;
use Text::Amuse::Preprocessor::Typography qw/get_typography_filter/;
use Text::Amuse::Preprocessor::Footnotes;
use Text::Amuse::Functions;
use File::Spec;
use File::Temp qw();
use File::Copy qw();
use Data::Dumper;

=head1 NAME

Text::Amuse::Preprocessor - Helpers for Text::Amuse document formatting.

=head1 VERSION

Version 0.64

=cut

our $VERSION = '0.64';


=head1 SYNOPSIS

  use Text::Amuse::Preprocessor;
  my $pp = Text::Amuse::Preprocessor->new(
                                          input => $infile,
                                          output => $outfile,
                                          html           => 1,
                                          fix_links      => 1,
                                          fix_typography => 1,
                                          fix_nbsp       => 1,
                                          fix_footnotes  => 1
                                         );
  $pp->process;

=head1 DESCRIPTION

This module provides a solution to apply some common fixes to muse
files.

Without any option save for C<input> and C<output> (which are
mandatory), the only things the module does is to remove carriage
returns, replace character ligatures or characters which shouldn't
enter at all and expand the tabs to 4 spaces (no smart expanding).

=head1 LANGUAGE SUPPORT

The following languages are supported

=over 4

=item english

smart quotes, dashes, and the common superscripts (like 11th)

=item russian

smart quotes, dashes and non-breaking spaces

=item spanish

smart quotes and dashes

=item finnish

smart quotes and dashes

=item swedish

smart quotes and dashes

=item serbian

smart quotes and dashes

=item croatian

smart quotes and dashes

=item italian

smart quotes and dashes

=item macedonian

smart quotes and dashes

=item german

smart quotes and dashes

=back

=head1 ACCESSORS

The following values are read-only and must be passed to the constructor.

=head2 Mandatory

=head3 input

Can be a string (with the input file path) or a reference to a scalar
with the text to process).

=head3 output

Can be a string (with the output file path) or a reference to a scalar
with the processed text.

=head2 Optional

=head3 html

Before doing anything, convert the HTML input into a muse file. Even
if possible, you're discouraged to do the html import and the fixing
in the same processing. Instead, create two objects, then first do the
HTML to muse convert, save the result somewhere, add the headers, then
reprocess it with the required fixes above.

Notably, the output will be without an header, so the language will
not be detected.

Default to false.

=head3 fix_links

Find the links and add the markup if needed. Default to false.

=head3 fix_typography

Apply the typographical fixes. Default to false. This add the "smart
quotes" feature.

=head3 remove_nbsp

Remove all the non-break spaces in the document, unconditionally. This
options does not conflict with the following. If both are provided,
first the non-break spaces are removed, then reinserted.

=head3 fix_nbsp

Add non-break spaces where appropriate (whatever this means).

=head3 show_nbsp

Make the non-break spaces visible and explicit as ~~ (available on
Text::Amuse since version 0.94).

=head3 fix_footnotes

Rearrange the footnotes if needed. Default to false.

=head3 debug

Don't unlink the temporary files and be verbose

=head1 METHODS

=head2 new(%options)

Constructor. Accepts the above options.

=cut

sub new {
    my ($class, %options) = @_;
    my $self = {
                html            => 0,
                fix_links       => 0,
                fix_typography  => 0,
                fix_footnotes   => 0,
                remove_nbsp     => 0,
                show_nbsp       => 0,
                fix_nbsp        => 0,
                debug  => 0,
                input  => undef,
                output => undef,
               };
    foreach my $k (keys %$self) {
        if (exists $options{$k}) {
            $self->{$k} = delete $options{$k};
        }
    }
    $self->{_error} = '';
    $self->{_verbatim_pieces} = {};
    $self->{_unique_counter} = 0;
    die "Unrecognized option: " . join(' ', keys %options) . "\n" if %options;
    die "Missing input" unless defined $self->{input};
    die "Missing output" unless defined $self->{output};
    bless $self, $class;
}

sub _get_unique_counter {
    my $self = shift;
    my $counter = ++$self->{_unique_counter};
    return $counter;
}

sub _verbatim_pieces {
    return shift->{_verbatim_pieces};
}

sub html {
    return shift->{html};
}

sub fix_links {
    return shift->{fix_links};
}

sub fix_typography {
    return shift->{fix_typography};
}

sub remove_nbsp {
    return shift->{remove_nbsp};
}

sub show_nbsp {
    return shift->{show_nbsp};
}

sub fix_nbsp {
    return shift->{fix_nbsp};
}

sub fix_footnotes {
    return shift->{fix_footnotes};
}

sub debug {
    return shift->{debug};
}

sub input {
    return shift->{input};
}

sub output {
    return shift->{output};
}

=head2 process

Process C<input> according to the options passed and write into
C<output>. Return C<output> on success, false otherwise.

=cut

sub _infile {
    my ($self, $arg) = @_;
    if ($arg) {
        die "Infile already set" if $self->{_infile};
        $self->{_infile} = $arg;
    }
    return $self->{_infile};
}

# temporary file for output
sub _outfile {
    my $self = shift;
    return File::Spec->catfile($self->tmpdir, 'output.muse');
}

sub _fn_outfile {
    my $self = shift;
    return File::Spec->catfile($self->tmpdir, 'fn-out.muse');
}

sub process {
    my $self = shift;
    my $debug = $self->debug;

    my $wd = $self->tmpdir;
    print "# Using $wd to store temporary files\n" if $debug;
    my $infile = $self->_set_infile;
    die "Something went wrong" unless -f $infile;

    if ($self->html) {
        $self->_process_html;
    }

    # then try to get the language
    my ($filter, $specific_filter, $nbsp_filter);
    my $fixlinks = $self->fix_links;
    my $fixtypo = $self->fix_typography;
    my $remove_nbsp = $self->remove_nbsp;
    my $show_nbsp = $self->show_nbsp;
    my $lang = $self->_get_lang;

    if ($lang && $fixtypo) {
        $filter =
          Text::Amuse::Preprocessor::TypographyFilters::filter($lang);
        $specific_filter =
          Text::Amuse::Preprocessor::TypographyFilters::specific_filter($lang);
    }

    if ($lang && $self->fix_nbsp) {
        $nbsp_filter =
          Text::Amuse::Preprocessor::TypographyFilters::nbsp_filter($lang);
    }

    my $outfile = $self->_outfile;
    my $line;
    my @body = Text::Amuse::Preprocessor::Parser::parse_text($self->_read_file($infile));
    # print Dumper(\@body);
  CHUNK:
    foreach my $piece (@body) {
        next CHUNK if $piece->{type} ne 'text';
        # print "Processing $piece->{type} $piece->{string}\n";

        # do the job
        $line = $piece->{string};

        # some bad things we want to filter anyway
        # $line =~ s/─/—/g; # they look the same, but they are not
        $line =~ s/\x{2500}/\x{2014}/g;
        # ligatures, totally lame to have in input file
        $line =~ s/\x{fb00}/ff/g;
        $line =~ s/\x{fb01}/fi/g;
        $line =~ s/\x{fb02}/fl/g;
        $line =~ s/\x{fb03}/ffi/g;
        $line =~ s/\x{fb04}/ffl/g;
        # remove soft-hyphens + space. They are invisible in browsers
        # and sometimes even on the console
        $line =~ s/\x{ad}\s*//g;
        if ($remove_nbsp) {
            $line =~ s/\x{a0}/ /g;
            $line =~ s/~~/ /g;
        }
        if ($fixtypo) {
            $line =~ s/(?<=\.) (?=\.)//g; # collapse the dots
        }
        if ($fixlinks) {
            $line = Text::Amuse::Preprocessor::TypographyFilters::linkify($line);
        }
        if ($filter) {
            $line = $filter->($line);
        }
        if ($specific_filter) {
            $line = $specific_filter->($line);
        }
        if ($nbsp_filter) {
            $line = $nbsp_filter->($line);
        }
        if ($show_nbsp) {
            $line =~ s/\x{a0}/~~/g;
        }
        $piece->{string} = $line;
    }
    # write out
    $self->_write_file($outfile, join('', map { $_->{string} } @body));

    if ($self->fix_footnotes) {
        my $fn_auxfile = $self->_fn_outfile;
        my $fnfixer = Text::Amuse::Preprocessor::Footnotes
          ->new(input  => $outfile,
                output => $fn_auxfile);
        # print "$outfile $fn_auxfile\n";
        if ($fnfixer->process) {
            # replace the outfile
            $outfile = $fn_auxfile;
        }
        else {
            # set the error
            $self->_set_error({ %{ $fnfixer->error } });
            return;
        }
    }

    my $output = $self->output;
    if (my $ref = ref($output)) {
        if ($ref eq 'SCALAR') {
            $$output = $self->_read_file($outfile);
        }
        else {
            die "Output is not a scalar ref!";
        }
    }
    else {
        File::Copy::move($outfile, $output)
            or die "Cannot move $outfile to $output, $!";
    }
    return $output;
}

sub _process_html {
    my $self = shift;
    # read the infile, process, overwrite. Doc states that it's just lame.
    my $body = $self->_read_file($self->_infile);
    my $html = Text::Amuse::Preprocessor::HTML::html_to_muse($body);
    $self->_write_file($self->_infile, $html);
}

sub _write_file {
    my ($self, $file, $body) = @_;
    die unless $file && $body;
    open (my $fh, '>:encoding(UTF-8)', $file) or die "opening $file $!";
    print $fh $body;
    close $fh or die "closing $file: $!";

}

sub _read_file {
    my ($self, $file) = @_;
    die unless $file;
    open (my $fh, '<:encoding(UTF-8)', $file) or die "$file: $!";
    local $/ = undef;
    my $body = <$fh>;
    close $fh;
    return $body;
}



sub _set_infile {
    my $self = shift;
    my $input = $self->input;
    my $infile = File::Spec->catfile($self->tmpdir, 'input.txt');
    if (my $ref = ref($input)) {
        if ($ref eq 'SCALAR') {
            open (my $fh, '>:encoding(UTF-8)', $infile) or die "$infile: $!";
            print $fh $$input;
            close $fh or die "closing $infile $!";
            $self->_infile($infile);
        }
        else {
            die Dumper($ref) . " is not a scalar ref!";
        }
    }
    else {
        File::Copy::copy($input, $infile) or die "Couldn't copy $input to $infile $!";
        $self->_infile($infile);
    }
    return $self->_infile;
}


=head2 html_to_muse

Can be called on the class and will invoke the
L<Text::Amuse::Preprocessor::HTML>'s C<html_to_muse> function on the
argument returning the converted chunk.

=cut

sub html_to_muse {
    my ($self, $text) = @_;
    return unless defined $text;
    return Text::Amuse::Preprocessor::HTML::html_to_muse($text);
}

=head2 error

This is set only when processing footnotes. See
L<Text::Amuse::Preprocessor::Footnotes> documentation for the hashref
returned when an error has been detected.

=cut

sub error {
    return shift->{_error};
}

sub _set_error {
    my ($self, $error) = @_;
    $self->{_error} = $error if $error;
}

=head2 tmpdir

Return the directory name used internally to hold the temporary files.

=cut

sub tmpdir {
    my $self = shift;
    unless ($self->{_tmpdir}) {
        $self->{_tmpdir} = File::Temp->newdir(CLEANUP => !$self->debug);
    }
    return $self->{_tmpdir}->dirname;
}

sub _get_lang {
    my $self = shift;
    my $infile = $self->_infile;
    # shouldn't happen
    die unless $infile && -f $infile;
    my $info;
    eval {
        $info = Text::Amuse::Functions::muse_fast_scan_header($infile);
    };
    if ($info && $info->{lang}) {
        if ($info->{lang} =~ m/^\s*([a-z]{2,3})\s*$/s) {
            return $1;
        }
    }
    return;
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email. If
you find a bug, please provide a minimal muse file which reproduces
the problem (so I can add it to the test suite).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse::Preprocessor

Repository available at GitHub:
L<https://github.com/melmothx/text-amuse-preprocessor>

=head1 SEE ALSO

The original documentation for the Emacs Muse markup can be found at:
L<http://mwolson.org/static/doc/muse/Markup-Rules.html>

The parser itself is L<Text::Amuse>.

This distribution ships the following executables

=over 4

=item * html-to-muse.pl (HTML to muse converter)

=item * muse-check-footnotes.pl (footnote checker)

=item * muse-rearrange-footnotes.pl (fix footnote numbering)

=item * pod-to-muse.pl (POD to muse converter)

=item * muse-preprocessor.pl (script which uses this module)

=back

See the manpage or pass --help to the scripts for usage.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Text::Amuse::Preprocessor
