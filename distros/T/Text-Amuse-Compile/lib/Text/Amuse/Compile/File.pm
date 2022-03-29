package Text::Amuse::Compile::File;

use strict;
use warnings;
use utf8;

use constant { DEBUG => $ENV{AMW_DEBUG} };

# core
# use Data::Dumper;
use File::Copy qw/move/;
use Encode qw/decode_utf8/;

# needed
use Template::Tiny;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use EBook::EPUB::Lite;
use File::Copy;
use File::Spec;
use IPC::Run qw(run);
use File::Basename ();

# ours
use PDF::Imposition;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_fast_scan_header
                              muse_format_line/;
use Text::Amuse::Utils;

use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::MuseHeader;
use Text::Amuse::Compile::Indexer;
use Types::Standard qw/Str Bool Object Maybe CodeRef HashRef InstanceOf ArrayRef/;
use Moo;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::File - Object for file scheduled for compilation

=head1 SYNOPSIS

Everything here is pretty much private. It's used by
Text::Amuse::Compile in a forked and chdir'ed environment.

=head1 ACCESSORS AND METHODS

=head2 new(name => $basename, suffix => $suffix, templates => $templates)

Constructor. Accepts the following named parameters:

=over 4

=item name

=item virtual

If it's a virtual file which doesn't exit on the disk (a merged one)

=item suffix

=item ttdir

The directory with the custom templates.

=item fileobj

An optional L<Text::Amuse::Compile::FileName> object (for partials)

=item standalone

When set to true, the tex output will obey bcor and twoside/oneside.

=item options

An hashref with the options to pass to the templates.

=item include_paths

Include paths arrayref.

=back

=head1 INTERNALS

=over 4

=item is_deleted

=item status_file

=item check_status

=item purged_extensions

=item muse_file

=item document

The L<Text::Amuse> object

=item tt

The L<Template::Tiny> object

=item logger

The logger subroutine set in the constructor.

=item cleanup

Remove auxiliary files (like the complete file and the status file)

=item luatex

Use luatex instead of xetex

=item fonts

The L<Text::Amuse::Compile::Fonts::Selected> object (required).

=item epub_embed_fonts

Boolean (default to true) which triggers the epub font embedding.

=item coverpage_only_if_toc

Boolean (default to false). Activates the conditional article output.

=item document_indexes

The raw, unparsed indexes found in the muse comments

=item indexes

If present, the parsed indexes are stored here

=back

=cut

has luatex => (is => 'ro', isa => Bool, default => sub { 0 });
has name => (is => 'ro', isa => Str, required => 1);
has suffix => (is => 'ro', isa => Str, required => 1);

has ttdir => (is => 'ro',   isa => Maybe[Str]);
has templates => (is => 'lazy', isa => Object);

sub _build_templates {
    my $self = shift;
    return Text::Amuse::Compile::Templates->new(ttdir => $self->ttdir,
                                                format_id => $self->options->{format_id});
}

has virtual => (is => 'ro', isa => Bool, default => sub { 0 });
has standalone => (is => 'ro', isa => Bool, default => sub { 0 });
has tt => (is => 'ro', isa => Object, default => sub { Template::Tiny->new });
has logger => (is => 'ro', isa => Maybe[CodeRef]);
has fileobj => (is => 'ro', isa => Maybe[Object]);
has document => (is => 'lazy', isa => Object);
has options => (is => 'ro', isa => HashRef, default => sub { +{} });
has full_options => (is => 'lazy', isa => HashRef);
has tex_options => (is => 'lazy', isa => HashRef);
has html_options => (is => 'lazy', isa => HashRef);
has wants_slides => (is => 'lazy', isa => Bool);
has is_deleted => (is => 'lazy', isa => Bool);
has file_header => (is => 'lazy', isa => Object);
has coverpage_only_if_toc => (is => 'ro', isa => Bool, default => sub { 0 });
has fonts => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Selected']);
has epub_embed_fonts => (is => 'ro', isa => Bool, default => sub { 1 });
has indexes => (is => 'rwp', isa => Maybe[ArrayRef]);
has include_paths => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub _build_file_header {
    my $self = shift;
    my $header;
    if ($self->virtual) {
        $header = { $self->document->headers };
    }
    else {
        $header = muse_fast_scan_header($self->muse_file);
        $self->log_fatal("Not a muse file!") unless $header && %$header;
    }
    return Text::Amuse::Compile::MuseHeader->new($header);
}

sub _build_is_deleted {
    return shift->file_header->is_deleted;
}

sub _build_wants_slides {
    return shift->file_header->wants_slides;
}

sub _build_document {
    my $self = shift;
    my %args;
    die "virtual files need an already built document" if $self->virtual;
    if (my $fileobj = $self->fileobj) {
        %args = $fileobj->text_amuse_constructor;
    }
    else {
        %args = (file => $self->muse_file);
    }
    return Text::Amuse->new(%args,
                            include_paths => $self->include_paths,
                           );
}

sub _build_tex_options {
    my $self = shift;
    return $self->_escape_options_hashref(ltx => $self->full_options);
}

sub _build_html_options {
    my $self = shift;
    return $self->_escape_options_hashref(html => $self->full_options);
}

sub _build_full_options {
    my $self = shift;
    # merge the options with the ones found in the header.
    # print "Building full options\n" if DEBUG;
    my %options = %{ $self->options };
    # these values are picked from the file, if not provided by the compiler
    foreach my $override (qw/cover coverwidth nocoverpage notoc
                             impressum
                             continuefootnotes
                             centerchapter
                             centersection
                             nofinalpage/) {
        $options{$override} = $self->$override;
    }
    return \%options;
}

sub cover {
    my $self = shift;
    # options passed take precendence
    if (exists $self->options->{cover}) {
        if ($self->_looks_like_a_sane_name($self->options->{cover})) {
            return $self->options->{cover};
        }
        else {
            return '';
        }
    }
    if (my $cover = $self->file_header->cover) {
        # already validated by the MuseHeader class
        return $cover;
    }
}

sub coverwidth {
    my $self = shift;
    # print "Building coverwidth\n";
    # validation here is not crucial, as the TeX routine will pass it
    # through the class.
    if (exists $self->options->{coverwidth}) {
        # print "Picking coverwidth from options\n";
        return $self->options->{coverwidth};
    }
    # obey this thing only if the file set the cover
    if ($self->file_header->cover) {
        # print "Picking coverwidth from file\n";
        return $self->file_header->coverwidth || 1;
    }
    return 1;
}

sub nocoverpage {
    shift->_look_at_header('nocoverpage');
}

sub notoc {
    shift->_look_at_header('notoc');
}

sub nofinalpage {
    shift->_look_at_header('nofinalpage');
}

sub impressum {
    shift->_look_at_header('impressum');
}

sub continuefootnotes   { shift->_look_at_header('continuefootnotes') }
sub centerchapter       { shift->_look_at_header('centerchapter') }
sub centersection       { shift->_look_at_header('centersection') }

sub _look_at_header {
    my ($self, $method) = @_;
    # these are booleans, so we enforce them
    !!$self->file_header->$method || !!$self->options->{$method} || 0;
}

=head2 Options which are looked up in the file headers first

See L<Text::Amuse::Compile::TemplateOptions> for the explanation.

=over 4

=item cover

=item coverwidth

=item nocoverpage

=item notoc

=item nofinalpage

=item impressum

=item continuefootnotes

=item centerchapter

=item centersection

=back

=cut

sub _escape_options_hashref {
    my ($self, $format, $ref) = @_;
    die "Wrong usage of internal method" unless $format && $ref;
    my %out;
    foreach my $k (keys %$ref) {
        if (defined $ref->{$k}) {
            if ($k eq 'logo' or $k eq 'cover') {
                if (my $checked = $self->_looks_like_a_sane_name($ref->{$k})) {
                    $out{$k} = $checked;
                }
            }
            elsif (ref($ref->{$k})) {
                # pass it verbatim
                $out{$k} = $ref->{$k};
            }
            else {
                $out{$k} = muse_format_line($format, $ref->{$k});
            }
        }
        else {
            $out{$k} = undef;
        }
    }
    return \%out;
}


sub muse_file {
    my $self = shift;
    return $self->name . $self->suffix;
}

sub status_file {
    return shift->name . '.status';
}

=head2 purge_all

Remove all the output files related to basename

=head2 purge_slides

Remove all the files produces by the C<slides> call, i.e. file.sl.pdf
and file.sl.log and all the leftovers (.sl.toc, .sl.aux, etc.).

=head2 purge_latex

Remove files left by previous latex compilation, i.e. file.pdf and
file.log and all the leftovers (toc, aux, etc.).

=head2 purge_latex_leftovers

Remove the latex leftover files (toc, aux, etc.).

=head2 purge_slides_leftovers

Remove the latex leftover files (.sl.toc, .sl.aux, etc.).

=head2 purge('.epub', ...)

Remove the files associated with this file, by extension.

=cut

sub _compiled_extensions {
    return qw/.sl.tex .tex .a4.pdf .lt.pdf .ok .html .bare.html .epub .zip/;
}

sub _latex_extensions {
    return qw/.pdf .log/;
}

sub _slides_extensions {
    my $self = shift;
    return map { '.sl' . $_ } $self->_latex_extensions;
}

sub _latex_leftover_extensions {
    return qw/.aux .nav .out .snm .toc .tuc .vrb/;
}

sub _slides_leftover_extensions {
    my $self = shift;
    return map { '.sl' . $_ } $self->_latex_leftover_extensions;
}

sub purged_extensions {
    my $self = shift;
    my @exts = (
                $self->_compiled_extensions,
                $self->_latex_extensions,
                $self->_latex_leftover_extensions,
                $self->_slides_extensions,
                $self->_slides_leftover_extensions,
               );
    return @exts;
}

sub purge {
    my ($self, @exts) = @_;
    $self->log_info("Started purging\n") if DEBUG;
    my $basename = $self->name;
    foreach my $ext (@exts) {
        $self->log_fatal("wtf? Refusing to purge " . $basename . $ext)
          if ($ext eq '.muse');
        my $target = $basename . $ext;
        if (-f $target) {
            $self->log_info("Removing target $target\n") if DEBUG;
            unlink $target or $self->log_fatal("Couldn't unlink $target $!");
        }
    }
    $self->log_info("Ended purging\n") if DEBUG;
}

sub purge_all {
    my $self = shift;
    $self->purge($self->purged_extensions);
}

sub purge_latex {
    my $self = shift;
    $self->purge($self->_latex_extensions, $self->_latex_leftover_extensions);
}

sub purge_slides {
    my $self = shift;
    $self->purge($self->_slides_extensions, $self->_slides_leftover_extensions);
}

sub purge_latex_leftovers {
    my $self = shift;
    $self->purge($self->_latex_leftover_extensions);
}

sub purge_slides_leftovers {
    my $self = shift;
    $self->purge($self->_slides_leftover_extensions);
}

sub _write_file {
    my ($self, $target, @strings) = @_;
    open (my $fh, ">:encoding(UTF-8)", $target)
      or $self->log_fatal("Couldn't open $target $!");

    print $fh @strings;

    close $fh or $self->log_fatal("Couldn't close $target");
    return;
}


=head1 METHODS

=head2 Formats

Emit the respective format, saving it in a file. Return value is
meaningless, but exceptions could be raised.

=over 4

=item html

=item bare_html

=item pdf

=item epub

=item lt_pdf

=item a4_pdf

=item zip

The zipped sources. Beware that if you don't call html or tex before
this, the attachments (if any) are ignored if both html and tex files
exist. Hence, the muse-compile.pl scripts forces the --tex and --html
switches.

=cut

sub _render_css {
    my ($self, %tokens) = @_;
    my $out = '';
    $self->tt->process($self->templates->css, {
                                               fonts => $self->fonts,
                                               centersection => $self->centersection,
                                               centerchapter => $self->centerchapter,
                                               %tokens
                                              }, \$out);
    return $out;
}


sub html {
    my $self = shift;
    $self->purge('.html');
    my $outfile = $self->name . '.html';
    my $doc = $self->document;
    my $title = $doc->header_as_html->{title} || 'Untitled';
    $self->_process_template($self->templates->html,
                             {
                              doc => $doc,
                              title => $self->_remove_tags($title),
                              css => $self->_render_css(html => 1),
                              options => { %{$self->html_options} },
                             },
                             $outfile);
}

sub bare_html {
    my $self = shift;
    $self->purge('.bare.html');
    my $outfile = $self->name . '.bare.html';
    $self->_process_template($self->templates->bare_html,
                             {
                              doc => $self->document,
                              options => { %{$self->html_options} },
                             },
                             $outfile);
}

sub a4_pdf {
    my $self = shift;
    $self->_compile_imposed('a4');
}

sub lt_pdf {
    my $self = shift;
    $self->_compile_imposed('lt');
}

sub _compile_imposed {
    my ($self, $size) = @_;
    $self->log_fatal("Missing size") unless $size;
    # the trick: first call tex with an argument, then pdf, then
    # impose, then rename.
    $self->tex(papersize => "half-$size");
    my $pdf = $self->pdf;
    my $outfile = $self->name . ".$size.pdf";
    if ($pdf) {
        my $imposer = PDF::Imposition->new(
                                           file => $pdf,
                                           schema => '2up',
                                           signature => '40-80',
                                           cover => 1,
                                           outfile => $outfile
                                          );
        $imposer->impose;
    }
    else {
        $self->log_fatal("PDF was not produced!");
    }
    return $outfile;
}


=item tex

This method is a bit tricky, because it's called with arguments
internally by C<lt_pdf> and C<a4_pdf>, and with no arguments before
C<pdf>.

With no arguments, this method enforces the options C<twoside=true>
and C<bcor=0mm>, effectively ignoring the global options which affect
the imposed output, unless C<standalone> is set to true.

This means that the twoside and binding correction options follow this
logic: if you have some imposed format, they are ignored for the
standalone PDF but applied for the imposed ones. If you have only
the standalone PDF, they are applied to it.

=cut

sub tex {
    my ($self, @args) = @_;
    my $texfile = $self->name . '.tex';
    $self->log_fatal("Wrong usage") if @args % 2;
    my %arguments = @args;
    unless (@args || $self->standalone) {
        %arguments = (
                      twoside => 0,
                      oneside => 1,
                      bcor    => '0mm',
                     );
    }
    $self->purge('.tex');
    my $template_body = $self->templates->latex;
    $self->_process_template($template_body,
                             $self->_prepare_tex_tokens(%arguments,
                                                        template_body => $template_body,
                                                       ),
                             $texfile);
}

=item sl_tex

Produce a file with extension C<.sl.tex>, a LaTeX Beamer source file.
If the source muse file doesn't require slides, do nothing.

=item sl_pdf

Compiles the file produced by C<sl_tex> (if any) and generate the
slides with extension C<.sl.pdf>

=back

=cut

sub sl_tex {
    my ($self) = @_;
    # no slides for virtual files
    return if $self->virtual;
    $self->purge('.sl.tex');
    my $texfile = $self->name . '.sl.tex';
    return unless $self->wants_slides;
    my $template_body = $self->templates->slides;
    return $self->_process_template($template_body,
                                    $self->_prepare_tex_tokens(is_slide => 1,
                                                               template_body => $template_body,
                                                              ),
                                    $texfile);
}

sub sl_pdf {
    my $self = shift;
    $self->purge_slides; # remove .sl.pdf and .sl.log
    my $source = $self->name . '.sl.tex';
    unless (-f $source) {
        $source = $self->sl_tex;
    }
    if ($source) {
        $self->log_fatal("Missing source file $source!") unless -f $source;
        if (my $out = $self->_compile_pdf($source)) {
            $self->purge_slides_leftovers;
            return $out;
        }
    }
    return;
}

sub pdf {
    my ($self, %opts) = @_;
    my $source = $self->name . '.tex';
    unless (-f $source) {
        $self->tex;
    }
    $self->log_fatal("Missing source file $source!") unless -f $source;
    $self->purge_latex;
    if (my $out = $self->_compile_pdf($source)) {
        $self->purge_latex_leftovers;
        return $out;
    }
    return;
}

sub _compile_pdf {
    my ($self, $source) = @_;
    my ($output, $logfile);
    die "Missing $source!" unless $source;
    if ($source =~ m/(.+)\.tex$/) {
        my $name = $1;
        $output = $name . '.pdf';
        $logfile = $name . '.log';
    }
    else {
        die "Source must be a tex source file\n";
    }
    $self->log_info("Compiling $source to $output\n") if DEBUG;
    my $max = 3;
    my @run_xindy;
    # maybe a check on the toc if more runs are needed?
    # 1. create the toc
    # 2. insert the toc
    # 3. adjust the toc. Should be ok, right?
    foreach my $idx (@{ $self->indexes || [] }) {
        push @run_xindy, [
                          texindy => '--quiet',
                          -L => $idx->{language},
                          -I => 'xelatex',
                          -C => 'utf8',
                          $idx->{name} . '.idx',
                         ];
    }
    if (@run_xindy) {
        $max++;
    }
    foreach my $i (1..$max) {
        if ($i > 2 and @run_xindy) {
            foreach my $exec (@run_xindy) {
                $self->log_info("Executing " . join(" ", @$exec) . "\n");
                system(@$exec) == 0 or $self->log_fatal("Errors running " . join(" ", @$exec) ."\n");
            }
        }
        my $latexname = $self->luatex ? 'LuaLaTeX' : 'XeLaTeX';
        my $latex = $self->luatex ? 'lualatex' : 'xelatex';
        my @run = ($latex, '-interaction=nonstopmode', $source);
        my ($in, $out, $err);
        my $ok = run \@run, \$in, \$out, \$err;
        my $shitout;
        foreach my $line (split(/\n/, $out)) {
            if ($line =~ m/^[!#]/) {
                if ($line =~ m/^! Paragraph ended before/) {
                    $self->log_info("***** WARNING *****\n"
                                    . "It is possible that you have a multiparagraph footnote\n"
                                    . "inside an header or inside a em or strong tag.\n"
                                    . "Unfortunately this is not supported in the PDF output.\n"
                                    . "Please correct it.\n");
                }
                if ($line =~ m/^! LaTeX Error: Unknown option.*fragile.*for package.*bigfoot/) {
                    my $help =<<HELP;
It appears that your TeX installation has an obsolete version of the
bigfoot package. You can upgrade this package following this
procedure (per user, not global).

cd /tmp/
mkdir -p `kpsewhich -var-value TEXMFHOME`/tex/latex/bigfoot
wget http://mirrors.ctan.org/macros/latex/contrib/bigfoot.zip
unzip bigfoot.zip
cd bigfoot
make
mv *.sty `kpsewhich -var-value TEXMFHOME`/tex/latex/bigfoot
texhash `kpsewhich -var-value TEXMFHOME`

Please contact the sys-admin if the commands above mean nothing to you.
HELP
                    $self->log_info("***** WARNING *****\n" . $help);
                }
                $shitout++;
            }
            if ($shitout) {
                # List of CHECK values
                # FB_DEFAULT
                #   I<CHECK> = Encode::FB_DEFAULT ( == 0)
                # If CHECK is 0, encoding and decoding replace any
                # malformed character with a substitution character.
                # When you encode, SUBCHAR is used. When you decode,
                # the Unicode REPLACEMENT CHARACTER, code point
                # U+FFFD, is used. If the data is supposed to be
                # UTF-8, an optional lexical warning of warning
                # category "utf8" is given.
                $self->log_info(decode_utf8($line));
            }
        }
        unless ($ok) {
            $self->log_info("$latexname compilation failed\n");
            if (-f $logfile) {
                # if we have a .pdf file, this means something was
                # produced. Hence, remove the .pdf
                unlink $output;
                $self->log_fatal("Bailing out\n");
            }
            else {
                $self->log_info("Skipping PDF generation\n");
                return;
            }
        }
    }
    $self->parse_tex_log_file($logfile);
    $self->log_info("Compilation over\n") if DEBUG;
    return $output;
}



sub zip {
    my $self = shift;
    $self->purge('.zip');
    my $zipname = $self->name . '.zip';
    my $tempdir = File::Temp->newdir;
    my $tempdirname = $tempdir->dirname;
    foreach my $todo (qw/tex html/) {
        my $target = $self->name . '.' . $todo;
        unless (-f $target) {
            $self->$todo;
        }
        $self->log_fatal("Couldn't produce $target") unless -f $target;
        copy($target, $tempdirname)
          or $self->log_fatal("Couldn't copy $target in $tempdirname $!");
    }
    copy ($self->name . '.muse', $tempdirname);

    my $text = $self->document;
    foreach my $attach ($text->attachments) {
        copy($attach, $tempdirname)
          or $self->log_fatal("Couldn't copy $attach to $tempdirname $!");
    }
    if (my $cover = $self->cover) {
        if (-f $cover) {
            copy($cover, $tempdirname)
              or $self->log_info("Cannot find the cover to attach");
        }
    }
    my $zip = Archive::Zip->new;
    $zip->addTree($tempdirname, $self->name) == AZ_OK
      or $self->log_fatal("Failure zipping $tempdirname");
    $zip->writeToFileNamed($zipname) == AZ_OK
      or $self->log_fatal("Failure writing $zipname");
    return $zipname;
}


sub epub {
    my $self = shift;
    $self->purge('.epub');
    my $epubname = $self->name . '.epub';

    my $text = $self->document;

    my @pieces;
    if ($text->can('as_splat_html_with_attrs')) {
        @pieces = $text->as_splat_html_with_attrs;
    }
    else {
        @pieces = map {
            +{
              text => $_,
              language_code => $text->language_code,
              html_direction => $text->html_direction,
             }
        } $text->as_splat_html;
    }
    my @toc = $text->raw_html_toc;
    # fixed in 0.51
    if (my $missing = scalar(@pieces) - scalar(@toc)) {
        $self->log_fatal("This shouldn't happen: missing pieces: $missing");
    }
    my $epub = EBook::EPUB::Lite->new;

    # embedded CSS
    if ($self->epub_embed_fonts) {
        # pass all
        if (my $fonts = $self->fonts) {
            my %done;
            foreach my $family (@{ $fonts->families }) {
                if ($family->has_files) {
                    foreach my $ff (@{ $family->font_files }) {
                        # do not produce duplicate entries when using
                        # the same file
                        unless ($done{$ff->basename}) {
                            $epub->copy_file($ff->file,
                                             $ff->basename,
                                             $ff->mimetype);
                            $done{$ff->basename}++;
                        }
                    }
                }
            }
        }
    }
    my $css = $self->_render_css(
                                 epub => 1,
                                 epub_embed_fonts => $self->epub_embed_fonts,
                                );
    $epub->add_stylesheet("stylesheet.css" => $css);

    # build the title page and some metadata
    my $header = $text->header_as_html;

    my @navpoints;
    my $order = 0;

    if (my $cover = $self->cover) {
        if (-f $cover) {
            if (my $basename = File::Basename::basename($cover)) {
                my $coverpage = <<'HTML';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Cover</title>
    <style type="text/css" title="override_css">
      @page {padding: 0pt; margin:0pt}
      body { text-align: center; padding:0pt; margin: 0pt; }
    </style>
  </head>
  <body>
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
         width="100%" height="100%" viewBox="0 0 573 800" preserveAspectRatio="xMidYMid meet">
      <image width="573" height="800" xlink:href="__IMAGE__" />
    </svg>
  </body>
</html>
HTML
                $coverpage =~ s/__IMAGE__/$basename/;
                my $cover_id = $epub->copy_file($cover, $basename,
                                                $self->_mime_for_attachment($basename));
                $epub->add_meta_item(cover => $cover_id);
                my $cpid = $epub->add_xhtml("coverpage.xhtml", $coverpage);
                $epub->guide->add_reference(type => 'cover', href => "coverpage.xhtml");
                push @navpoints, {
                                  label => 'Cover',
                                  id => $cpid,
                                  content => "coverpage.xhtml",
                                  play_order => ++$order,
                                  level => 1,
                                 };
            }
        }
    }

    my $titlepage = qq{<div style="text-align:center">\n};

    if ($text->header_defined->{author}) {
        my $author = $header->{author};
        $epub->add_author($self->_clean_html($author));
        $titlepage .= "<h2>$author</h2>\n" if $text->wants_preamble;
    }
    my $muse_header = $self->file_header;
    foreach my $aut ($muse_header->authors_as_html_list) {
        $epub->add_author($self->_clean_html($aut));
    }
    foreach my $topic ($muse_header->topics_as_html_list) {
        $epub->add_subject($self->_clean_html($topic));
    }
    if ($text->header_defined->{title}) {
        my $t = $header->{title};
        $epub->add_title($self->_clean_html($t));
        $titlepage .= "<h1>$t</h1>\n" if $text->wants_preamble;
    }
    else {
        $epub->add_title('Untitled');
    }

    if ($text->header_defined->{subtitle}) {
        my $st = $header->{subtitle};
        $titlepage .= "<h2>$st</h2>\n" if $text->wants_preamble;
    }
    if ($text->header_defined->{date}) {
        if ($header->{date} =~ m/([0-9]{4})/) {
            $epub->add_date($1);
        }
        $titlepage .= "<h3>$header->{date}</h3>" if $text->wants_preamble;
    }

    $epub->add_language($text->language_code);

    $titlepage .= qq{<div class="amw-impressum-container">\n};

    if ($text->header_defined->{seriesname} && $text->header_defined->{seriesnumber}) {
        $titlepage .= qq{<div class="amw-impressum amw-impressum-series">}
          . $header->{seriesname} . ' ' . $header->{seriesnumber}
          . qq{</div>};
    }

    my @impressum_map = (
                         [ source => [qw/add_source/],        ],
                         [ notes => [qw/add_description/],    ],
                         [ rights => [qw/add_rights/],       ],
                         [ isbn => [qw/add_identifier ISBN/], ],
                         [ publisher => [qw/add_publisher/],  ],
                        );

    foreach my $imp (@impressum_map) {
        my $k = $imp->[0];
        if ($text->header_defined->{$k}) {
            my $str = $header->{$k};
            my ($method, @additional_args) = @{$imp->[1]};
            $epub->$method($self->_clean_html($str), @additional_args);
            if ($k eq 'isbn') {
                $str = 'ISBN ' . $str;
            }
            $titlepage .= qq{<div class="amw-impressum amw-impressum-$k">$str</div>\n}
              if $text->wants_postamble;
        }
    }
    $titlepage .= "</div>\n</div>\n";
    # create the front page
    my $firstpage = '';
    $self->tt->process($self->templates->minimal_html,
                       {
                        title => $self->_remove_tags($header->{title} || 'Untitled'),
                        text => $titlepage,
                        html_direction => $text->html_direction,
                        language_code => $text->language_code,
                       },
                       \$firstpage)
      or $self->log_fatal($self->tt->error);

    my $tpid = $epub->add_xhtml("titlepage.xhtml", $firstpage);

    # main loop
    push @navpoints, {
                      label => $self->_clean_html($header->{title} || 'Untitled'),
                      id => $tpid,
                      content => "titlepage.xhtml",
                      play_order => ++$order,
                      level => 1,
                     };

    my %internal_links;
    {
        my $piecenumber = 0;
        foreach my $piece (@pieces) {
            # we insert these in Text::Amuse, so it's not a wild regexp.
            while ($piece->{text} =~ m/<a id="(text-amuse-label-.+?)"( class="text-amuse-internal-anchor")?><\/a>/g) {
                my $label = $1;
                $internal_links{$label} =
                  $self->_format_epub_fragment($toc[$piecenumber]{index});
            }
            $piecenumber++;
        }
    }
    my $fix_link = sub {
        my ($target) = @_;
        die unless $target;
        if (my $file = $internal_links{$target}) {
            return $file . '#' . $target;
        }
        else {
            # broken link
            return '#' . $target;
        }
    };
    while (@pieces) {
        my $piece = shift @pieces;
        my $index = shift @toc;
        my $xhtml = "";
        # print Dumper($index);
        my $filename = $self->_format_epub_fragment($index->{index});
        my $prefix = '*' x $index->{level};
        my $title = $prefix . " " . $index->{string};
        $piece->{text} =~ s/(<a class="text-amuse-link" href=")#(text-amuse-label-.+?)"/$1 . $fix_link->($2) .  '"'/ge;

        $self->tt->process($self->templates->minimal_html,
                           {
                            title => $self->_remove_tags($title),
                            %$piece,
                           },
                           \$xhtml)
          or $self->log_fatal($self->tt->error);

        my $id = $epub->add_xhtml($filename, $xhtml);
        push @navpoints, {
                          label => $self->_clean_html($index->{string}),
                          content => $filename,
                          id => $id,
                          play_order => ++$order,
                          level => $index->{level},
                         };
    }
    $self->_epub_create_toc($epub, \@navpoints);

    # attachments
    foreach my $att ($text->attachments) {
        $self->log_fatal("Referenced file $att does not exist!") unless -f $att;
        $epub->copy_file($att, $att, $self->_mime_for_attachment($att));
    }
    # finish
    $epub->pack_zip($epubname);
    return $epubname;
}

sub _epub_create_toc {
    my ($self, $epub, $navpoints) = @_;
    my %levelnavs;
    # print Dumper($navpoints);
  NAVPOINT:
    foreach my $navpoint (@$navpoints) {
        my %nav = %$navpoint;
        my $level = delete $nav{level};
        die "Shouldn't happen: false level: $level" unless $level;
        die "Shouldn't happen either: $level not 1-4" unless $level =~ m/\A[1-4]\z/;
        my $checklevel = $level - 1;

        my $current;
        while ($checklevel > 0) {
            if (my $parent = $levelnavs{$checklevel}) {
                $current = $parent->add_navpoint(%nav);
                last;
            }
            $checklevel--;
        }
        unless ($current) {
            $current = $epub->add_navpoint(%nav);
        }
        for my $clear ($level..4) {
            delete $levelnavs{$clear};
        }
        $levelnavs{$level} = $current;
    }
    # probably not needed, but let's be sure we don't leave circular
    # refs.
    foreach my $k (keys %levelnavs) {
        delete $levelnavs{$k};
    }
}

sub _remove_tags {
    my ($self, $string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    return $string;
}

sub _clean_html {
    my ($self, $string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&quot;/"/g;
    $string =~ s/&#x27;/'/g;
    $string =~ s/&nbsp;/ /g;
    $string =~ s/&#160;/ /g;
    $string =~ s/&amp;/&/g;
    return $string;
}

=head2 Logging

While the C<logger> accessor holds a reference to a sub, but could be
very well be empty, the object uses these two methods:

=over 4

=item log_info(@strings)

If C<logger> exists, it will call it passing the strings as arguments.
Otherwise print to the standard output.

=item log_fatal(@strings)

Calls C<log_info>, remove the lock and dies.

=item parse_tex_log_file($logfile)

(Internal) Parse the produced logfile for missing characters.

=back

=head1 INTERNAL CONSTANTS

=head2 DEBUG

Set from AMW_DEBUG environment.

=cut



sub log_info {
    my ($self, @info) = @_;
    my $logger = $self->logger;
    if ($logger) {
        $logger->(@info);
    }
    else {
        print @info;
    }
}

sub log_fatal {
    my ($self, @info) = @_;
    $self->log_info(@info);
    my $failure = join("\n", @info) || "Fatal exception";
    die "$failure\n";
}

sub parse_tex_log_file {
    my ($self, $logfile) = @_;
    die "Missing file argument!" unless $logfile;
    if (-f $logfile) {
        # if you're wandering why we open this in raw mode: The log
        # file produced by XeLaTeX is utf8, but it splits the output
        # at 80 bytes or so. This of course sometimes, expecially
        # working with cyrillic scripts, cut the multibyte character
        # in half, producing invalid utf8 octects.
        open (my $fh, '<:raw', $logfile)
          or $self->log_fatal("Couldn't open $logfile $!");

        my %errors;
        my $continue = 0;

        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ m/^missing character/i) {
                # if we get the warning, nothing we can do about it,
                # but shouldn't happen.
                $errors{$line} = 1;
            }
            elsif ($line =~ m/^Overfull/) {
                $self->log_info(decode_utf8($line) . "\n");
                $continue++;
            }
            elsif ($continue) {
                $self->log_info(decode_utf8($line) . "\n\n");
                $continue = 0;
            }
        }
        close $fh;
        foreach my $error (sort keys %errors) {
            $self->log_info(decode_utf8($error) . "...\n");
        }
    }
}

sub cleanup {
    my $self = shift;
    if (my $f = $self->status_file) {
        if (-f $f) {
            unlink $f or $self->log_fatal("Couldn't unlink $f $!");
        }
        else {
            $self->log_info("Couldn't find " . File::Spec->rel2abs($f));
        }
    }
}

sub _process_template {
    my ($self, $template_ref, $tokens, $outfile) = @_;
    eval {
        my $out = '';
        die "Wrong usage" unless ($template_ref && $tokens && $outfile);
        $self->tt->process($template_ref, $tokens, \$out);
        open (my $fh, '>:encoding(UTF-8)', $outfile) or die "Couldn't open $outfile $!";
        print $fh $out, "\n";
        close $fh;
    };
    if ($@) {
        $self->log_fatal("Error processing template for $outfile: $@");
    };
    return $outfile;
}


# method for options to pass to the tex template
sub _prepare_tex_tokens {
    my ($self, %args) = @_;
    my $doc = $self->document;
    my $is_slide = delete $args{is_slide};
    my $template_body = delete $args{template_body};
    die "Missing required argument template_body " unless $template_body;
    my %tokens = %{ $self->tex_options };
    my $escaped_args = $self->_escape_options_hashref(ltx => \%args);
    foreach my $k (keys %$escaped_args) {
        $tokens{$k} = $escaped_args->{$k};
    }
    # now tokens have the unparsed options
    # now validate the options against the new shiny module
    my %options = (%{ $self->full_options }, %args);
    # print Dumper($self->full_options);
    my $template_options = eval { Text::Amuse::Compile::TemplateOptions->new(%options) };
    unless ($template_options) {
        $template_options = Text::Amuse::Compile::TemplateOptions->new;
        $self->log_info("# Validation failed: $@, setting one by one\n");
        foreach my $method ($template_options->config_setters) {
            if (exists $options{$method}) {
                eval { $template_options->$method($options{$method}) };
            }
        }
    }
    my $safe_options =
      $self->_escape_options_hashref(ltx => $template_options->config_output);

    # defaults
    my %parsed = (%$safe_options,
                  class => 'scrbook',
                  lang => 'english',
                  mainlanguage_script => '',
                  wants_toc => 0,
                 );


    my $fonts = $self->fonts;

    # not used but for legacy templates
        $parsed{mainfont} = $fonts->main->name;
        $parsed{sansfont} = $fonts->sans->name;
        $parsed{monofont} = $fonts->mono->name;
        $parsed{fontsize} = $fonts->size;

    my $latex_body = $self->_interpolate_magic_comments($template_options->format_id, $doc);

    my $enable_secondary_footnotes = $latex_body =~ m/\\footnoteB\{/;

    # check if the template body support this conditional, which is new. If not,
    # always setup bigfoot
    # print "SECONDARY FOOTNOTES ENABLED? $enable_secondary_footnotes\n";
    if (index($$template_body, '[% IF enable_secondary_footnotes %]', 0) < 0) {
        $enable_secondary_footnotes = 1;
    }
    # print "SECONDARY FOOTNOTES ENABLED? $enable_secondary_footnotes\n";

    my $tex_setup_langs = $fonts
      ->compose_polyglossia_fontspec_stanza(lang => $doc->language,
                                            others => $doc->other_languages || [],
                                            enable_secondary_footnotes => $enable_secondary_footnotes,
                                            bidi => $doc->is_bidi,
                                            has_ruby => $doc->has_ruby,
                                            is_slide => $is_slide,
                                            captions => Text::Amuse::Utils::language_code_locale_captions($doc->language_code),
                                           );

    my @indexes;
    if (my @raw_indexes = $self->document_indexes) {
        my $indexer = Text::Amuse::Compile::Indexer->new(latex_body => $latex_body,
                                                         language_code => $doc->language_code,
                                                         logger => $self->logger || sub { print @_ },
                                                         index_specs => \@raw_indexes);
        $latex_body = $indexer->indexed_tex_body;
        my %xindy_langs = (
                           bg => 'bulgarian',
                           cs => 'czech',
                           da => 'danish',
                           de => 'german-din', # ae is sorted like ae. alternative -duden
                           el => 'greek',
                           en => 'english',
                           es => 'spanish-modern',
                           et => 'estonian',
                           fi => 'finnish',
                           fr => 'french',
                           hr => 'croatian',
                           hu => 'hungarian',
                           is => 'icelandic',
                           it => 'italian',
                           lv => 'latvian',
                           lt => 'lithuanian',
                           mk => 'macedonian',
                           # nl => 'dutch', # unclear why missing
                           no => 'norwegian',
                           sr => 'croatian', # serbian is cyrillic
                           ro => 'romanian',
                           ru => 'russian',
                           sk => 'slovak-small', # exists also slovak-large
                           sl => 'slovenian',
                           pl => 'polish',
                           pt => 'portuguese',
                           sq => 'albanian',
                           sv => 'swedish',
                           tr => 'turkish',
                           uk => 'ukrainian',
                           vi => 'vietnamese',
                          );
        @indexes = map { +{
                           name => $_->index_name,
                           title => $_->index_label,
                           language => $xindy_langs{$doc->language_code} || 'general',
                          } }
          @{ $indexer->specifications };
    }
    $self->_set_indexes(@indexes ? \@indexes : undef);
    # no cover page if header or compiler says so, or
    # if coverpage_only_if_toc is set and doc doesn't have a toc.
    if ($self->nocoverpage or
        ($self->coverpage_only_if_toc && !$doc->wants_toc)) {
            $parsed{nocoverpage} = 1;
            $parsed{class} = 'scrartcl';
            delete $parsed{opening}; # not needed for article.
    }


    unless ($parsed{notoc}) {
        if ($doc->wants_toc) {
            $parsed{wants_toc} = 1;
        }
    }

    return {
            options => \%tokens,
            safe_options => \%parsed,
            doc => $doc,
            tex_setup_langs => $tex_setup_langs,
            latex_body => $latex_body,
            enable_secondary_footnotes => $enable_secondary_footnotes,
            tex_metadata => $self->file_header->tex_metadata,
            tex_indexes => \@indexes,
           };
}

sub _interpolate_magic_comments {
    my ($self, $format, $doc) = @_;
    $format ||= 'DEFAULT';
    my $latex = $doc->as_latex;
    # format is validated.
    # switch is gmx, no "s", we are line-based here
    my $prefix = qr{
                \%
                \x{20}+
                \:
                (?:
                    \Q$format\E | \* | ALL
                )
                \:
                \x{20}+
                \\textbackslash\{\}
               }x;
    my $size = qr{-?[1-9][0-9]*(?:mm|cm|pt|em)}x;

    $latex =~ s/^
                $prefix
                ( # permitted commands
                    sloppy |
                    fussy  |
                    newpage |
                    strut |
                    flushbottom |
                    raggedbottom |
                    vfill |
                    amusewiki[a-zA-Z]+ |
                    clearpage |
                    cleardoublepage |
                    vskip \x{20}+ $size
                )
                \x{20}*
                $
              /\\$1/gmx;
    $latex =~ s/^
                $prefix
                ( (this)? pagestyle )
                \\ \{
                ( plain | empty | headings | myheadings | scrheadings )
                \\ \}
                \x{20}*
                $
               /\\$1\{$3\}/gmx;

    $latex =~ s/^
                $prefix
                ( enlargethispage )
                \\ \{
                ( $size )
                \\ \}
                \x{20}*
                $
               /\\$1\{$2\}/gmx;

    my $regular = qr{[^\#\$\%\&\~\^\\\{\}_]+};
    $latex =~ s/^
                $prefix
                markboth
                \\ \{
                ($regular)
                \\\}
                \\\{
                ($regular)
                \\\}
                \x{20}*
                $
               /\\markboth\{$1}\{$2\}/gmx;
    $latex =~ s/^
                $prefix
                markright
                \\ \{
                ($regular)
                \\\}
                \x{20}*
                $
               /\\markright\{$1}/gmx;

    # with looseness, we need to attach it to the next paragraph, so
    # eat all the space and replace with a single \n

    $latex =~ s/^
                $prefix
                looseness\=(-?[0-9])
                $
                \s*
               /\\looseness=$1\n/gmx;
    return $latex;
}

sub _looks_like_a_sane_name {
    my ($self, $name) = @_;
    return unless defined $name;
    my $out;
    eval {
        $out = Text::Amuse::Compile::TemplateOptions::check_filename($name);
    };
    if (!$out || $@) {
        $self->log_info("$name is not good: $@") if DEBUG;
        return;
    }
    else {
        $self->log_info("$name is good") if DEBUG;
        return $out;
    }
}

sub _mime_for_attachment {
    my ($self, $att) = @_;
    die "Missing argument" unless $att;
    my $mime;
    if ($att =~ m/\.jpe?g$/) {
        $mime = "image/jpeg";
    }
    elsif ($att =~ m/\.png$/) {
        $mime = "image/png";
    }
    else {
        $self->log_fatal("Unrecognized attachment $att!");
    }
    return $mime;
}

sub _format_epub_fragment {
    my ($self, $index) = @_;
    return sprintf('piece%06d.xhtml', $index || 0);
}

sub document_indexes {
    my ($self) = @_;
    my @docs = ($self->virtual ? ($self->document->docs) : ( $self->document ));
    my @comments = grep { /\AINDEX +([a-z]+): (.+)/ }
      map { $_->string }
      grep { $_->type eq 'comment' }
      map { $_->document->elements } @docs;
    return @comments;
}


1;
