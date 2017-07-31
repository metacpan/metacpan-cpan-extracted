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
use IO::Pipe;
use File::Basename ();

# ours
use PDF::Imposition;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_fast_scan_header
                              muse_format_line/;

use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::MuseHeader;
use Types::Standard qw/Str Bool Object Maybe CodeRef HashRef InstanceOf/;
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

=item templates

=item fileobj

An optional L<Text::Amuse::Compile::FileName> object (for partials)

=item standalone

When set to true, the tex output will obey bcor and twoside/oneside.

=item options

An hashref with the options to pass to the templates.

=item webfonts

The L<Text::Amuse::Compile::Webfonts> object (or undef).

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

The optional L<Text::Amuse::Compile::Fonts::Selected> object.

=item epub_embed_fonts

Boolean (default to true) which triggers the epub font embedding.

=item coverpage_only_if_toc

Boolean (default to false). Activates the conditional article output.

=back

=cut

has luatex => (is => 'ro', isa => Bool, default => sub { 0 });
has name => (is => 'ro', isa => Str, required => 1);
has suffix => (is => 'ro', isa => Str, required => 1);
has templates => (is => 'ro', isa => Object, required => 1);
has virtual => (is => 'ro', isa => Bool, default => sub { 0 });
has standalone => (is => 'ro', isa => Bool, default => sub { 0 });
has tt => (is => 'ro', isa => Object, default => sub { Template::Tiny->new });
has logger => (is => 'ro', isa => Maybe[CodeRef]);
has fileobj => (is => 'ro', isa => Maybe[Object]);
has webfonts => (is => 'ro', isa => Maybe[Object]);
has document => (is => 'lazy', isa => Object);
has options => (is => 'ro', isa => HashRef, default => sub { +{} });
has full_options => (is => 'lazy', isa => HashRef);
has tex_options => (is => 'lazy', isa => HashRef);
has html_options => (is => 'lazy', isa => HashRef);
has wants_slides => (is => 'lazy', isa => Bool);
has is_deleted => (is => 'lazy', isa => Bool);
has file_header => (is => 'lazy', isa => Object);
has cover => (is => 'lazy', isa => Str);
has coverwidth => (is => 'lazy', isa => Str);
has nocoverpage => (is => 'lazy', isa => Bool);
has coverpage_only_if_toc => (is => 'ro', isa => Bool, default => sub { 0 });
has nofinalpage => (is => 'lazy', isa => Bool);
has notoc => (is => 'lazy', isa => Bool);
has fonts => (is => 'ro', isa => InstanceOf['Text::Amuse::Compile::Fonts::Selected']);
has epub_embed_fonts => (is => 'ro', isa => Bool, default => sub { 1 });

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
    return Text::Amuse->new(%args);
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
                             nofinalpage/) {
        $options{$override} = $self->$override;
    }
    return \%options;
}

sub _build_cover {
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

sub _build_coverwidth {
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

sub _build_nocoverpage {
    my $self = shift;
    if ($self->file_header->nocoverpage) {
        return 1;
    }
    elsif ($self->options->{nocoverpage}) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _build_notoc {
    my $self = shift;
    if ($self->file_header->notoc) {
        return 1;
    }
    elsif ($self->options->{notoc}) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _build_nofinalpage {
    my $self = shift;
    if ($self->file_header->nofinalpage) {
        return 1;
    }
    elsif ($self->options->{nofinalpage}) {
        return 1;
    }
    else {
        return 0;
    }
}


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
    $self->tt->process($self->templates->css, { fonts => $self->fonts, %tokens }, \$out);
    return $out;
}


sub html {
    my $self = shift;
    $self->purge('.html');
    my $outfile = $self->name . '.html';
    $self->_process_template($self->templates->html,
                             {
                              doc => $self->document,
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
    $self->_process_template($self->templates->latex,
                             $self->_prepare_tex_tokens(%arguments),
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
    return $self->_process_template($self->templates->slides,
                                    $self->_prepare_tex_tokens,
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
    # maybe a check on the toc if more runs are needed?
    # 1. create the toc
    # 2. insert the toc
    # 3. adjust the toc. Should be ok, right?
    foreach my $i (1..3) {
        my $pipe = IO::Pipe->new;
        # parent swallows the output
        my $latexname = $self->luatex ? 'LuaLaTeX' : 'XeLaTeX';
        my $latex = $self->luatex ? 'lualatex' : 'xelatex';
        $pipe->reader($latex, '-interaction=nonstopmode', $source);
        $pipe->autoflush(1);
        my $shitout;
        while (my $line = <$pipe>) {
            if ($line =~ m/^[!#]/) {
                $shitout++;
            }
            if ($shitout) {
                $self->log_info($line);
            }
        }
        wait;
        my $exit_code = $? >> 8;
        if ($exit_code != 0) {
            $self->log_info("$latexname compilation failed with exit code $exit_code\n");
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

    my @pieces = $text->as_splat_html;
    my @toc = $text->raw_html_toc;
    # fixed in 0.51
    if (my $missing = scalar(@pieces) - scalar(@toc)) {
        $self->log_fatal("This shouldn't happen: missing pieces: $missing");
    }
    my $epub = EBook::EPUB::Lite->new;

    # embedded CSS
    my $webfonts;
    if ($self->epub_embed_fonts) {
        if (my $legacy = $self->webfonts) {
            $webfonts = $legacy;
            foreach my $style (qw/regular italic bold bolditalic/) {
                $epub->copy_file(File::Spec->catfile($legacy->srcdir,
                                                     $legacy->$style),
                                 $legacy->$style,
                                 $legacy->mimetype);
            }
        }
        if (my $fonts = $self->fonts) {
            my $main = $fonts->main;
            if ($main->has_files) {
                # this is not 100% accurate, to be fixed when webfonts
                # will be deprecated.
                $webfonts = {
                             family => $main->name,
                             regular => $main->regular->basename,
                             bold => $main->bold->basename,
                             italic => $main->italic->basename,
                             bolditalic => $main->bolditalic->basename,
                             format => $main->regular->format,
                             size => $fonts->size,
                            };
                foreach my $shape (qw/bold italic bolditalic regular/) {
                    my $fontfile = $main->$shape;
                    $epub->copy_file($fontfile->file,
                                     $fontfile->basename,
                                     $fontfile->mimetype);
                }
            }
        }
    }
    my $css = $self->_render_css(epub => 1,
                                 webfonts => $webfonts );
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

    if ($text->header_defined->{source}) {
        my $source = $header->{source};
        $epub->add_source($self->_clean_html($source));
        $titlepage .= "<p>$source</p>" if $text->wants_postamble;
    }

    if ($text->header_defined->{notes}) {
        my $notes = $header->{notes};
        $epub->add_description($self->_clean_html($notes));
        $titlepage .= "<p>$notes</p>" if $text->wants_postamble;
    }
    $titlepage .= "</div>\n";
    # create the front page
    my $firstpage = '';
    $self->tt->process($self->templates->minimal_html,
                       {
                        title => $self->_remove_tags($header->{title} || 'Untitled'),
                        text => $titlepage,
                        options => { %{$self->html_options} },
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
            while ($piece =~ m/<a id="(text-amuse-label-.+?)"( class="text-amuse-internal-anchor")?><\/a>/g) {
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
        my $fi =    shift @pieces;
        my $index = shift @toc;
        my $xhtml = "";
        # print Dumper($index);
        my $filename = $self->_format_epub_fragment($index->{index});
        my $prefix = '*' x $index->{level};
        my $title = $prefix . " " . $index->{string};
        $fi =~ s/(<a class="text-amuse-link" href=")#(text-amuse-label-.+?)"/$1 . $fix_link->($2) .  '"'/ge;

        $self->tt->process($self->templates->minimal_html,
                           {
                            title => $self->_remove_tags($title),
                            options => { %{$self->html_options} },
                            text => $fi,
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
        $self->log_fatal("$att doesn't exist!") unless -f $att;
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
    die "Fatal exception\n";
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

        while (my $line = <$fh>) {
            if ($line =~ m/^missing character/i) {
                chomp $line;
                # if we get the warning, nothing we can do about it,
                # but shouldn't happen.
                $errors{$line} = 1;
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
    my %tokens = %{ $self->tex_options };
    my $escaped_args = $self->_escape_options_hashref(ltx => \%args);
    foreach my $k (keys %$escaped_args) {
        $tokens{$k} = $escaped_args->{$k};
    }
    # now tokens have the unparsed options
    # now validate the options against the new shiny module
    my %options = (%{ $self->full_options }, %args);
    # print Dumper($self->full_options);
    my $parsed = eval { Text::Amuse::Compile::TemplateOptions->new(%options) };
    unless ($parsed) {
        $parsed = Text::Amuse::Compile::TemplateOptions->new;
        $self->log_info("# Validation failed: $@, setting one by one\n");
        foreach my $method ($parsed->config_setters) {
            if (exists $options{$method}) {
                eval { $parsed->$method($options{$method}) };
                if ($@) {
                    print "Error on $method: $@\n";
                }
            }
        }
    }
    my $safe_options =
      $self->_escape_options_hashref(ltx => $parsed->config_output);

    # defaults
    my %parsed = (%$safe_options,
                  class => 'scrbook',
                  lang => 'english',
                  mainlanguage_script => '',
                  wants_toc => 0,
                 );

    if (my $fonts = $self->fonts) {
        # these are validated and sane.
        $parsed{mainfont} = $fonts->main->name;
        $parsed{sansfont} = $fonts->sans->name;
        $parsed{monofont} = $fonts->mono->name;
        $parsed{fontsize} = $fonts->size;
    }


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

    # main language
    my $orig_lang = $doc->language;
    my %lang_aliases = (
                        # bad hack, no mk hyphens...
                        macedonian => 'russian',

                        # the rationale is that polyglossia seems to
                        # go south when you load serbian with latin
                        # script, as the logs are spammed with cyrillic loading.
                        serbian    => 'croatian',
                       );
    my $lang = $parsed{lang} = $lang_aliases{$orig_lang} || $orig_lang;

    # I don't like doing this here, but here we go...
    my %scripts = (
                   russian    => 'Cyrillic',
                  );

    if (my $script = $scripts{$lang}) {
        $parsed{mainlanguage_script} = "\\newfontfamily\\" .
          $lang . 'font[Script=' . $script . ']{' . $parsed{mainfont} . "}\n";
    }

    my %toc_names = (
                     macedonian => 'Содржина',
                    );
    if (my $toc_name = $toc_names{$orig_lang}) {
        $parsed{mainlanguage_toc_name} = $toc_name;
    }

    if (my $other_langs_arrayref = $doc->other_languages) {
        my %other_languages;
        my %additional_strings;
        foreach my $olang (@$other_langs_arrayref) {

            # a bit of duplication...
            my $other_lang = $lang_aliases{$olang} || $olang;
            $other_languages{$other_lang} = 1;
            if (my $script = $scripts{$other_lang}) {
                my $additional = "\\newfontfamily\\" . $other_lang
                  . 'font[Script=' . $script . ']{' . $parsed{mainfont} . "}";
                $additional_strings{$additional} = 1;
            }
        }
        if (%other_languages) {
            $parsed{other_languages} = join(',', sort keys %other_languages);
        }
        if (%additional_strings) {
            $parsed{other_languages_additional} = join("\n", sort keys %additional_strings);
        }
    }

    return {
            options => \%tokens,
            safe_options => \%parsed,
            doc => $doc,
            tex_metadata => $self->file_header->tex_metadata,
           };
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

1;
