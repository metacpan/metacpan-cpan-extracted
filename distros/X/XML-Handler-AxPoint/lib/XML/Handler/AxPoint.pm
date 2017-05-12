# $Id: AxPoint.pm,v 1.49 2005/10/19 16:43:48 matt Exp $

package XML::Handler::AxPoint;
use strict;

use XML::SAX::Writer;
use Text::Iconv;
use File::Spec;
use File::Basename;
use Data::Dumper;
use PDFLib 0.13;
use POSIX qw(ceil acos);
use Time::Piece;
use Carp qw(carp verbose);

use vars qw($VERSION);
$VERSION = '1.5';

sub new {
    my $class = shift;
    my $opt   = (@_ == 1)  ? { %{shift()} } : {@_};

    $opt->{Output} ||= *{STDOUT}{IO};
    return bless $opt, $class;
}

sub set_document_locator {
    my ($self, $locator) = @_;
    $self->{locator} = $locator;
}

sub start_document {
    my ($self, $doc) = @_;

    # setup consumer
    my $ref = ref $self->{Output};
    if ($ref eq 'SCALAR') {
        $self->{Consumer} = XML::SAX::Writer::StringConsumer->new($self->{Output});
    }
    elsif ($ref eq 'ARRAY') {
        $self->{Consumer} = XML::SAX::Writer::ArrayConsumer->new($self->{Output});
    }
    elsif ($ref eq 'GLOB' or UNIVERSAL::isa($self->{Output}, 'IO::Handle')) {
        $self->{Consumer} = XML::SAX::Writer::HandleConsumer->new($self->{Output});
    }
    elsif (not $ref) {
        local *FH;

        open FH, '> ' . $self->{Output} or
          XML::SAX::Writer::Exception->throw( Message => "Error opening '" .
            $self->{Output} . "': $!" );
        binmode FH;
        $self->{Consumer} = XML::SAX::Writer::HandleConsumer->new(*FH);
    }
    elsif (UNIVERSAL::can($self->{Output}, 'output')) {
        $self->{Consumer} = $self->{Output};
    }
    else {
        XML::SAX::Writer::Exception->throw({ Message => 'Unknown option for Output' });
    }

    $self->{Encoder} = XML::SAX::Writer::NullConverter->new();

    $self->{text_encoder} = Text::Iconv->new('utf-8', 'ISO-8859-1');

    # create PDF and set defaults
    $self->{pdf} = PDFLib->new();
    $self->{pdf}->papersize("slides");
    $self->{pdf}->set_border_style("solid", 0);

    $self->{headline_font} = "Helvetica";
    $self->{headline_size} = 18.0;

    $self->{title_font} = "Helvetica-Bold";
    $self->{title_size} = 24.0;

    $self->{subtitle_font} = "Helvetica-Bold";
    $self->{subtitle_size} = 20.0;

    $self->{normal_font} = "Helvetica";

    $self->{todo} = [];
    $self->{bookmarks} = [];

    $self->{default_transition} = [];

    $self->{gathered_text} = '';
    $self->{bullets} = [ ' ', 'l', 'u', 'p', 'n', 'm', 'F' ];
    $self->{numbers} = [ ' ', '$1.', '$a)', '$i.', '$A)', '$I' ];
    $self->{captions} = [];
    $self->{list_index} = [];
    $self->{values} = { 'current-slide' => 0 };
    $self->{slide_index} = [ 0 ];
    $self->{boxtransition} = [];
    $self->{fill} = 1;
    $self->{stroke} = 0;
    $self->{coords} = 'svg';
}

sub run_todo {
    my $self = shift;
    while (my $todo = shift(@{$self->{todo}})) {
        $todo->();
    }
}

sub push_todo {
    my $self = shift;

    push @{$self->{todo}}, shift;
}

sub push_bookmark {
    my $self = shift;
    # warn("push_bookmark($_[0]) from ", caller, "\n");
    push @{$self->{bookmarks}}, shift;
}

sub top_bookmark {
    my $self = shift;
    return $self->{bookmarks}[-1];
}

sub pop_bookmark {
    my $self = shift;
    # warn("pop_bookmark() from ", caller, "\n");
    pop @{$self->{bookmarks}};
}

sub end_document {
    my ($self) = @_;

    $self->{pdf}->finish;

    $self->{Consumer}->output( $self->{pdf}->get_buffer );
    $self->{Consumer}->finalize;
}

sub new_page {
    my $self = shift;
    my ($trans,$type) = @_;
    $type ||= 'normal';

    $self->{pdf}->start_page;
    $self->{values}->{'current-slide'}++ unless $self->{transitional};

    my $transition = $trans || $self->get_transition || 'replace';
    $transition = 'replace' if $transition eq 'none';
    $transition = 'replace' if $self->{PrintMode};

    $self->{pdf}->set_parameter(transition => lc($transition));

    if ($type ne 'empty') {
        if (my $bg = $self->{bg}) {
            my @scale = split(/\*/,$bg->{scale});
            my $imgw = $self->get_scale($scale[0],0,$self->{pdf}->get_value("imagewidth", $bg->{image}->img),$self->{pdf}->get_value("resx", $bg->{image}->img));
            my $imgh = $self->get_scale($scale[1]||$scale[0],1,$self->{pdf}->get_value("imageheight", $bg->{image}->img),$self->{pdf}->get_value("resy", $bg->{image}->img));
            $self->{pdf}->add_image(img => $bg->{image}, x => 0, y => 0, w => $imgw, h => $imgh);
        }

        if (my $logo = $self->{logo}) {
            my @scale = split(/\*/,$logo->{scale});
            my $imgw = $self->get_scale($scale[0],0,$self->{pdf}->get_value("imagewidth", $logo->{image}->img),$self->{pdf}->get_value("resx", $logo->{image}->img));
            my $imgh = $self->get_scale($scale[1]||$scale[0],1,$self->{pdf}->get_value("imageheight", $logo->{image}->img),$self->{pdf}->get_value("resy", $logo->{image}->img));
            $self->{pdf}->add_image(img => $logo->{image}, x => 612 - $imgw - $logo->{x}, y => $logo->{y}, w => $imgw, h => $imgh);
        }
    }

    $self->{pagetype} = $type || 'normal';

    $self->process_css_styles("font-family:".$self->{headline_font}.";font-size:".$self->{headline_size}.";stroke:none;fill:black;font-weight:normal;font-style:normal;");
    pop @{$self->{font_stack}};

    $self->{xindent} = [];

    $self->{pdf}->set_text_pos(80, 300);
}

sub get_node_transition {
    my $self = shift;
    my ($node) = @_;

    if (exists($node->{Attributes}{"{}transition"})) {
        return $node->{Attributes}{"{}transition"}{Value};
    }
    return;
}

sub get_scale {
    my ($self, $spec, $vertical, $rel, $res) = @_;
    $res = 72 if ($res <= 0); # substitute sensible fallback

    my ($num, $unit) = ($spec =~ m/^\s*([0-9]*(?:\.[0-9]+)?)\s*(em|ex|pt|px|line|page|)\s*$/);
    die "unknown scale specifier: $spec" if !defined $unit;

    my $pdf = $self->{bb} || $self->{pdf}; # don't use 'line' outside of a slide, will return "0".
    if ($unit eq 'em') {
        if ($vertical) {
            return $num*$pdf->get_value('capheight')*$pdf->get_value('fontsize');
        } else {
            return $num*$pdf->string_width(text => 'M');
        }
    } elsif ($unit eq 'ex') {
        if ($vertical) {
            # FIXME: (probably unfixable) this uses an estimation, not the real value
            return $num*$pdf->get_value('ascender')*2/3*$pdf->get_value('fontsize');
        } else {
            return $num*$pdf->string_width(text => 'x');
        }
    } elsif ($unit eq 'pt') {
        return $num;
    } elsif ($unit eq 'px') {
        return $num*72/$res;
    } elsif ($unit eq 'line') {
        if ($vertical) {
            return $num*$pdf->get_value('leading');
        } else {
            return $num*($pdf->{w} || $self->{extents}[0]{w});
        }
    } elsif ($unit eq 'page') {
        if ($vertical) {
            return $num*$pdf->get_value('pageheight');
        } else {
            return $num*$pdf->get_value('pagewidth');
        }
    } else {
        return $num*$rel*72/$res;
    }
    die "unknown unit: $unit";
}

sub get_transition {
    my $self = shift;

    my $node = $self->{SlideCurrent} || $self->{Current};

    my $transition;
    while ($node && !($transition = $self->get_node_transition($node))) {
        $node = $node->{Parent};
    }
    return $transition;
}

sub playback_cache {
    my $self = shift;
    $self->{cache_trash} = [];

    while (@{$self->{cache}}) {
        my $thing = shift @{$self->{cache}};
        my ($method, $node) = @$thing;
        $self->$method($node);
        push @{$self->{cache_trash}}, $thing;
    }

    delete $self->{cache_trash};
}

sub start_element {
    my ($self, $el) = @_;

    my $parent = $el->{Parent} = $self->{Current};
    $self->{Current} = $el;

    if ($self->{cache_until}) {
        push @{$self->{cache}}, ["slide_start_element", $el];
    }

    my $name = $el->{LocalName};

    # warn("start_ $name\n");

    if ($name eq 'slideshow') {
        $self->push_todo(sub { $self->new_page(undef,$el->{Attributes}{"{}type"}{Value}) });
        if (exists($el->{Attributes}{"{}default-transition"})) {
            unshift @{$self->{default_transition}}, $el->{Attributes}{"{}default-transition"}{Value};
        }
        if (exists($el->{Attributes}{"{}coordinates"})) {
            $self->{coords} = $el->{Attributes}{"{}coordinates"}{Value};
            if ($self->{coords} !~ /^(svg|old)$/) {
                Carp::croak("Unknown coordinate system: $self->{coords}");
            }
        }
    }
    elsif ($name eq 'title') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'metadata') {
    }
    elsif ($name eq 'total-slides') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'speaker') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'email') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'organisation') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'link') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'logo') {
        if (exists($el->{Attributes}{"{}scale"})) {
            $self->{logo}{scale} = $el->{Attributes}{"{}scale"}{Value};
        }
        if (exists($el->{Attributes}{"{}x"})) {
            $self->{logo}{x} = $el->{Attributes}{"{}x"}{Value};
        }
        if (exists($el->{Attributes}{"{}y"})) {
            $self->{logo}{y} = $el->{Attributes}{"{}y"}{Value};
        }
    $self->{logo}{x} ||= 0;
    $self->{logo}{y} ||= 0;
        $self->{logo}{scale} ||= 1.0;
        $self->gathered_text; # reset
    }
    elsif ($name eq 'background') {
        if (exists($el->{Attributes}{"{}scale"})) {
            $self->{bg}{scale} = $el->{Attributes}{"{}scale"}{Value};
        }
        $self->{bg}{scale} ||= 1.0;
        $self->gathered_text; # reset
    }
    elsif ($name eq 'bullet' or $name eq 'numbers') {
        $self->gathered_text; # reset
    }
    elsif ($name eq 'slideset') {
        $self->run_todo;
        $self->{slide_index}[0]++;
        unshift @{$self->{slide_index}}, 0;
        if (exists($el->{Attributes}{"{}default-transition"})) {
            unshift @{$self->{default_transition}}, $el->{Attributes}{"{}default-transition"}{Value};
        }
        $self->new_page(undef,$el->{Attributes}{"{}type"}{Value}) unless ($el->{Attributes}{"{}type"}{Value}||'normal') eq 'empty';
    }
    elsif ($name eq 'subtitle') {
    }
    elsif ($name eq 'slide') {
        $self->run_todo; # might need to create slideset here.
        $self->{pdf}->end_page;

        $self->{slide_index}[0]++;

        if (exists($el->{Attributes}{"{}default-transition"})) {
            unshift @{$self->{default_transition}}, $el->{Attributes}{"{}default-transition"}{Value};
        }
        $self->{images} = [];
        # cache these events now...
        $self->{cache_until} = $el->{Name};
        $self->{cache} = [["slide_start_element", $el]];
    }
    elsif ($name eq 'image') {
        $self->gathered_text;
        if (exists($el->{Attributes}{"{http://www.w3.org/1999/xlink}href"})) {
            # uses xlink, not characters
            $self->characters({ Data => $el->{Attributes}{"{http://www.w3.org/1999/xlink}href"}{Value}});
        } elsif (exists($el->{Attributes}{"{}href"})) {
            # workaround for XML::LibXML::SAX problem
            $self->characters({ Data => $el->{Attributes}{"{}href"}{Value}});
        }
    }
    elsif ($name =~ /^(source[_-]code|box|table|list|point|plain|value|i|b|u|colou?r|row|col|rect|circle|ellipse|polyline|line|path|text|g|span|variable)$/) {
      # passthrough to allow these types
    }
    else {
        warn("Unknown tag: $name");
    }
}

sub end_element {
    my ($self, $el) = @_;

    if ($self->{cache_until}) {
        push @{$self->{cache}}, ["slide_end_element", $el];
        if ($el->{Name} eq $self->{cache_until}) {
            delete $self->{cache_until};
            $self->playback_cache;
        }
    }

    $el = $self->{Current};
    my $parent = $self->{Current} = $el->{Parent};

    my $name = $el->{LocalName};
    # warn("end_ $name\n");
    if ($name eq 'slideshow') {
        $self->run_todo;
        if (exists($el->{Attributes}{"{}default-transition"})) {
            shift @{$self->{default_transition}};
        }
        $self->pop_bookmark;
    }
    elsif ($name eq 'title') {
        if ($parent->{LocalName} eq 'slideshow') {
            my $title = $self->gathered_text;
            $self->{values}->{'slideshow-title'} = $title;
            $self->push_todo(sub {
                $self->{pdf}->set_font(face => $self->{title_font}, size => $self->{title_size});

                $self->push_bookmark( $self->{pdf}->add_bookmark(text => "Title", open => 1) );

                if ($self->{pagetype} ne 'empty') {
                    $self->{pdf}->print_boxed(
                        $title,
                        x => 20, y => 50, w => 570, h => 300, mode => "center");

                    $self->{pdf}->print_line("") for (1..4);

                    my ($x, $y) = $self->{pdf}->get_text_pos();

                    $self->{pdf}->set_font(face => $self->{subtitle_font}, size => $self->{subtitle_size});

                # speaker
                    if ($self->{metadata}{speaker}) {
                        $self->{pdf}->add_link(link => "mailto:" . $self->{metadata}{email},
                                               x => 20, y => $y - 10, w => 570, h => 24)
                        if defined $self->{metadata}{email};
                        $self->{pdf}->print_boxed(
                            $self->{metadata}{speaker},
                            x => 20, y => 40, w => 570, h => $y - 24, mode => "center");
                    }

                    $self->{pdf}->print_line("");
                    (undef, $y) = $self->{pdf}->get_text_pos();

                # organisation
                    if ($self->{metadata}{organisation}) {
                        $self->{pdf}->add_link(
                            link => $self->{metadata}{link},
                            x => 20, y => $y - 10, w => 570, h => 24);
                        $self->{pdf}->print_boxed(
                            $self->{metadata}{organisation},
                            x => 20, y => 40, w => 570, h => $y - 24, mode => "center");
                    }
                }
            });
        }
        elsif ($parent->{LocalName} eq 'slideset') {
            my $title = $self->gathered_text;
            $self->push_bookmark(
                $self->{pdf}->add_bookmark(
                    text => $title,
                    level => 2,
                    parent_of => $self->top_bookmark,
                    open => 1,
                )
            );

            $self->{pdf}->set_font(face => $self->{title_font}, size => $self->{title_size});
            if ($self->{pagetype} ne 'empty') {
                $self->{pdf}->print_boxed(
                    $title,
                    x => 20, y => 50, w => 570, h => 200, mode => "center");

                my ($x, $y) = $self->{pdf}->get_text_pos();
                $self->{pdf}->add_link(
                    link => $el->{Attributes}{"{}href"}{Value},
                    x => 20, y => $y - 5, w => 570, h => 24) if exists($el->{Attributes}{"{}href"});
            }
        }
    }
    elsif ($name eq 'metadata') {
        $self->run_todo;
    }
    elsif ($name eq 'total-slides') {
        $self->{metadata}{'total-slides'} = $self->gathered_text;
    }
    elsif ($name eq 'speaker') {
        $self->{metadata}{speaker} = $self->gathered_text;
    }
    elsif ($name eq 'email') {
        $self->{metadata}{email} = $self->gathered_text;
    }
    elsif ($name eq 'organisation') {
        $self->{metadata}{organisation} = $self->gathered_text;
    }
    elsif ($name eq 'link') {
        $self->{metadata}{link} = $self->gathered_text;
    }
    elsif ($name eq 'logo') {
        my $logo_file =
            File::Spec->rel2abs(
                $self->gathered_text,
                File::Basename::dirname($self->{locator}{SystemId} || '')
            );
        my $type = get_filetype($logo_file);
        my $logo = $self->{pdf}->load_image(
                filename => $logo_file,
                filetype => $type,
            ) || die "Couldn't load $logo_file";
        if (!$logo) {
            $self->{pdf}->finish;
            die "Cannot load image $logo_file!";
        }
        $self->{logo}{image} = $logo;
    }
    elsif ($name eq 'background') {
        my $bg_file =
            File::Spec->rel2abs(
                $self->gathered_text,
                File::Basename::dirname($self->{locator}{SystemId} || '')
            );
        my $type = get_filetype($bg_file);
        my $bg = $self->{pdf}->load_image(
                filename => $bg_file,
                filetype => $type,
            ) || die "Couldn't load $bg_file";
        if (!$bg) {
            $self->{pdf}->finish;
            die "Cannot load image $bg_file!";
        }
        $self->{bg}{image} = $bg;
    }
    elsif ($name eq 'bullet') {
        die "need 'level' attribute for bullet tag" if (!exists($el->{Attributes}{"{}level"}));
        die "'level' attribute of bullet tag must be an integer > 1" if (int($el->{Attributes}{"{}level"}) < 1);
        my $bullet = $self->gathered_text;
        die "bullet text must be a single character" if length($bullet) != 1;
        $self->{bullets}[int($el->{Attributes}{"{}level"}{Value})] = $bullet;
    }
    elsif ($name eq 'numbers') {
        die "need 'level' attribute for numbers tag" if (!exists($el->{Attributes}{"{}level"}));
        die "'level' attribute of numbers tag must be an integer > 1" if (int($el->{Attributes}{"{}level"}) < 1);
        my $num = $self->gathered_text;
        $self->{numbers}[int($el->{Attributes}{"{}level"}{Value})] = $num;
    }
    elsif ($name eq 'slideset') {
        $self->pop_bookmark;
        shift @{$self->{slide_index}};
        if (exists($el->{Attributes}{"{}default-transition"})) {
            shift @{$self->{default_transition}};
        }
    }
    elsif ($name eq 'subtitle') {
        if ($parent->{LocalName} eq 'slideset') {
            $self->{pdf}->set_font(face => $self->{subtitle_font}, size => $self->{subtitle_size});
            if ($self->{pagetype} ne 'empty') {
                $self->{pdf}->print_boxed(
                    $self->gathered_text,
                    x => 20, y => 20, w => 570, h => 200, mode => "center");
                if (exists($el->{Attributes}{"{}href"})) {
                    my ($x, $y) = $self->{pdf}->get_text_pos();
                    $self->{pdf}->add_link(
                        link => $el->{Attributes}{"{}href"}{Value},
                        x => 20, y => $y - 5, w => 570, h => 18);
                }
            }
        }
    }
    elsif ($name eq 'slide') {
        $self->run_todo;
        if (exists($el->{Attributes}{"{}default-transition"})) {
            shift @{$self->{default_transition}};
        }
    }
    elsif ($name eq 'image') {
        my $image =
            File::Spec->rel2abs(
                $self->gathered_text,
                File::Basename::dirname($self->{locator}{SystemId} || '')
            );
        my $image_ref = $self->{pdf}->load_image(
                filename => $image,
                filetype => get_filetype($image),
            ) || die "Couldn't load $image";
        my $scale = $el->{Attributes}{"{}scale"}{Value} || 1.0;
        my $href = $el->{Attributes}{"{}href"}{Value};
        my $x = $el->{Attributes}{"{}x"}{Value};
        my $y = $el->{Attributes}{"{}y"}{Value};
        my $width = $el->{Attributes}{"{}width"}{Value};
        my $height = $el->{Attributes}{"{}height"}{Value};

        push @{$self->{images}},
            {
                scale => $scale,
                image_ref => $image_ref,
                href => $href,
                x => $x,
                y => $y,
                width => $width,
                height => $height,
            };
    }

    $self->{Current} = $parent;
}

sub characters {
    my ($self, $chars) = @_;

    if ($self->{cache_until}) {
        push @{$self->{cache}}, ["slide_characters", $chars];
    }

    $self->{gathered_text} .= $self->{text_encoder}->convert($chars->{Data});
}

sub invalid_parent {
    my $self = shift;
    warn("Invalid tag nesting: <$self->{Current}{Parent}{LocalName}> <$self->{Current}{LocalName}>");
}

sub gathered_text {
    my $self = shift;
    return substr($self->{gathered_text}, 0, length($self->{gathered_text}), '');
}

sub image {
    my ($self, $scale, $file_handle, $href) = @_;
    my $pdf = $self->{pdf};

    $pdf->print_line("");

    my ($x, $y) = $pdf->get_text_pos;

    my @scale = split(/\*/,$scale);
    my $imgw = $self->get_scale($scale[0],0,$pdf->get_value("imagewidth", $file_handle->img),$pdf->get_value("resx", $file_handle->img));
    my $imgh = $self->get_scale($scale[1]||$scale[0],1,$pdf->get_value("imageheight", $file_handle->img),$pdf->get_value("resy", $file_handle->img));

    my $xpos = (($self->{extents}[0]{x} + ($self->{extents}[0]{w} / 2))
                    - ($imgw / 2));
    my $ypos = ($y - $imgh);

    # warn("image: ($xpos,$ypos) $imgw x $imgh");

    $pdf->add_image(img => $file_handle,
            x => $xpos,
            y => $ypos,
            w => $imgw,
            h => $imgh);
    $pdf->add_link(link => $href, x => $xpos, y => $ypos, w => $imgw, h => $imgh) if $href;

    $pdf->set_text_pos($x, $ypos);
}

sub bullet {
    my ($self, $el) = @_;

    my $pdf = $self->{pdf};

    my ($char, $size);

    my $level = $el->{Attributes}{"{}level"}{Value} || @{$self->{list_index}} || 1;
    my ($x, $y) = $pdf->get_text_pos;

    if (@{$self->{xindent}} && $level <= $self->{xindent}[0]{level}) {
        my $last;
        while ($last = shift @{$self->{xindent}}) {
            if ($last->{level} == $level) {
                $self->{pdf}->set_text_pos($last->{x}, $y);
                $x = $last->{x};
                last;
            }
        }
    }

    if ($level == 1) {
        my $indent = 80 * ($self->{extents}[0]{w} / $self->{extents}[-1]{w});
        $self->{pdf}->set_text_pos($self->{extents}[0]{x} + $indent, $y);
    }

    $char = $self->{bullets}->[$level];
    $size = 20-(2*$level);

    if ($level == 1) {
        my ($x, $y) = $pdf->get_text_pos;
        $y += 9;
        $pdf->set_text_pos($x, $y);
        $pdf->print_line("");
    }

    ($x, $y) = $pdf->get_text_pos;

    if (!@{$self->{xindent}} || $level > $self->{xindent}[0]{level}) {
        unshift @{$self->{xindent}}, {level => $level, x => $x};
    }

    my $bw;
    if (!$el->{Attributes}{"{}level"}{Value} && @{$self->{list_index}} && $self->{list_index}->[-1] > 0) {
        my $index = $self->{list_index}->[-1];
        $self->{list_index}->[-1]++;
        $char = $self->{numbers}->[$level];
        $char =~ s/(([^\$]|^)(\$\$)*)\$1/$1$index/g;
        my $alpha = ('','a'..'z')[$index];
        $char =~ s/(([^\$]|^)(\$\$)*)\$a/$1$alpha/g;
        $alpha = uc($alpha);
        $char =~ s/(([^\$]|^)(\$\$)*)\$A/$1$alpha/g;
        $alpha = '';
        $alpha .= 'x', $index -= 10 while ($index > 10);
        $alpha .= ('','i','ii','iii','iv','v','vi','vii','viii','ix','x')[$index];
        $char =~ s/(([^\$]|^)(\$\$)*)\$i/$1$alpha/g;
        $alpha = uc($alpha);
        $char =~ s/(([^\$]|^)(\$\$)*)\$I/$1$alpha/g;
        $char =~ s/\$\$/\$/g;
        $pdf->set_font(face => $self->{normal_font}, size => $size);
        $bw = $pdf->string_width(text => $char." ");
        $pdf->print($char);
    } else {
        $pdf->set_font(face => "ZapfDingbats", size => $size - 4, encoding => "builtin");
        $bw = $pdf->string_width(text => $char);
        $pdf->print($char);
        $pdf->set_font(face => $self->{normal_font}, size => $size);
    }
    if ($pdf->string_width(text => "     ") < $bw) {
        $pdf->print(" ");
    } else {
        $pdf->set_text_pos($x, $y);
        $pdf->print("     ");
    }

    return ($pdf->get_text_pos, $size);
}

sub get_filetype {
    my $filename = shift;

    my ($suffix) = $filename =~ /([^\.]+?)$/;
    $suffix = lc($suffix);
    if ($suffix eq 'jpg') {
        return 'jpeg';
    }
    return $suffix;
}

my %colours = (
    black => "000000",
    green => "008000",
    silver => "C0C0C0",
    lime => "00FF00",
    gray => "808080",
    olive => "808000",
    white => "FFFFFF",
    yellow => "FFFF00",
    maroon => "800000",
    navy => "000080",
    red => "FF0000",
    blue => "0000FF",
    purple => "800080",
    teal => "008080",
    fuchsia => "FF00FF",
    aqua => "00FFFF",
);

sub get_colour {
    my $colour = shift;
    if ($colour !~ s/^#//) {
        $colour = $colours{$colour} || die "Unknown colour: $colour";
    }
    if ($colour !~ /^[0-9a-fA-F]{6}$/) {
        die "Invalid colour format: #$colour";
    }
    my ($r, $g, $b) = map { hex()/255 } ($colour =~ /(..)/g);
    return [$r, $g, $b];
}

my $current_fill_colour = [0,0,0];
my $current_stroke_colour = [0,0,0];
my $current_rendering = 0;
my $current_line_cap = 0;
my $current_line_join = 0;
my $current_line_width = 1;
my $current_miter_limit = 10;
my $current_fillrule = "winding";

sub push_font {
    my ($self) = @_;
    my $pdf = $self->{bb} || $self->{pdf};
    my $elt = $self->{SlideCurrent} || $self->{Current};
    push @{$self->{font_stack}}, [
                                  $pdf->get_parameter("fontname"),
                                  $pdf->get_value("fontsize"),
                                  $current_fill_colour,
                                  $current_stroke_colour,
                                  $pdf->{underline},
                                  $elt->{LocalName},
                                  $self->{fill},
				  $self->{stroke},
                                  $current_line_cap,
                                  $current_line_join,
                                  $current_line_width,
                                  $current_miter_limit,
                                  $current_fillrule,
                                  $self->{transitional},
                                 ];
}

sub pop_font {
    my ($self) = @_;
    my ($font, $size, $fill_colour, $stroke_colour, $underline, $name, $fill, $stroke, $lc, $lj, $lw, $ml, $fr, $trans) = @{pop @{$self->{font_stack}}};
    my $pdf = $self->{bb} || $self->{pdf};
    my $elt = $self->{SlideCurrent} || $self->{Current};
    $pdf->set_font(face => $font, size => $size);
    $current_fill_colour = $fill_colour;
    $pdf->set_colour(rgb => $current_fill_colour, type => "fill");
    $current_stroke_colour = $stroke_colour;
    $pdf->set_colour(rgb => $current_stroke_colour, type => "stroke");
    $pdf->set_decoration($underline?"underline":"none");
    $current_line_cap = $lc;
    $pdf->set_line_cap($lc);
    $current_line_join = $lj;
    $pdf->set_line_join($lj);
    $current_line_width = $lw;
    $pdf->set_line_width($lw);
    $current_miter_limit = $ml;
    $pdf->set_miter_limit($ml);
    $pdf->set_parameter("fillrule",$fr);
    $self->{fill} = $fill;
    $self->{stroke} = $stroke;
    if ($self->{fill} && $self->{stroke}) {
        $pdf->set_value(textrendering => 2);
    }
    elsif ($self->{fill}) {
        $pdf->set_value(textrendering => 0);
    }
    elsif ($self->{stroke}) {
        $pdf->set_value(textrendering => 1);
    }
    else {
        $pdf->set_value(textrendering => 3); # invisible
    }
}

sub process_css_styles {
    my ($self, $style, $text_mode) = @_;

    if ($text_mode) {
        $self->{stroke} = 0;
        $self->{fill} = 1;
    }
    else {
        $self->{stroke} = 1;
        $self->{fill} = 0;
    }

    $self->push_font();
    return unless $style;

    my $pdf = $self->{bb} || $self->{pdf};

    my $new_font = $pdf->get_parameter("fontname");
    my $bold = 0;
    my $italic = 0;
    my $underline = 0;
    my $size = $pdf->get_value('fontsize');
    if ($new_font =~ s/-(.*)$//) {
        my $removed = $1;
        if ($removed =~ /Bold/i) {
            $bold = 1;
        }
        if ($removed =~ /(Oblique|Italic)/i) {
            $italic = 1;
        }
    }
    foreach my $part (split(/;\s*/s, $style)) {
        my ($key, $value) = split(/\s*:\s*/, $part, 2);
        # Keys we need to implement:
        # color, fill, font, font-style, font-weight, font-size,
        # font-family, stroke, stroke-linecap, stroke-linejoin, stroke-width,

        # warn("got $key = $value\n");
        if ($key eq 'font') {
            # [ [ <'font-style'> || <'font-variant'> || <'font-weight'> ]? <'font-size'> [ / <'line-height'> ]? <'font-family'> ]
            if ($value =~ /^((\S+)\s+)?((\S+)\s+)(\S+)$/) {
                my ($attribs, $ptsize, $name) = ($2, $4, $5);
                $attribs ||= 'inherit';
                if ($attribs eq 'normal') {
                    $bold = 0; $italic = 0;
                }
                elsif ($attribs eq 'inherit') {
                    # Do nothing
                }
                elsif ($attribs eq 'bold' || $attribs eq 'bolder') {
                    $bold = 1;
                }
                elsif ($attribs eq 'italic' || $attribs eq 'oblique') {
                    $italic = 1;
                }

                if ($ptsize !~ s/pt$//) {
                    die "Cannot support fonts in anything but point sizes yet: $value";
                }
                $size = $ptsize;

                $name =~ s/sans-serif/Helvetica/;
                $name =~ s/serif/Times/;
                $name =~ s/monospace/Courier/;
                $new_font = $name;
            }
            else {
                die "Failed to parse CSS font attribute: $value";
            }
        }
        elsif ($key eq 'font-family') {
            $value =~ s/sans-serif/Helvetica/;
            $value =~ s/serif/Times/;
            $value =~ s/monospace/Courier/;
            $new_font = $value;
        }
        elsif ($key eq 'font-style') {
            if ($value eq 'normal') {
                $italic = 0;
            }
            elsif ($value eq 'italic') {
                $italic = 1;
            }
        }
        elsif ($key eq 'font-weight') {
            if ($value eq 'normal') {
                $bold = 0;
            }
            elsif ($value eq 'bold') {
                $bold = 1;
            }
        }
        elsif ($key eq 'text-decoration') {
            if ($value eq 'none') {
                $underline = 0;
            }
            elsif ($value eq 'underline') {
                $underline = 1;
            }
        }
        elsif ($key eq 'font-size') {
            if ($value !~ s/pt$// && $value =~ m/[a-z]/) {
                die "Can't do anything but font-size in pt yet";
            }
            $size = $value;
        }
        elsif ($key eq 'color') {
            # set both the stroke and fill color
            $current_fill_colour = $current_stroke_colour = get_colour($value);
            $pdf->set_colour(rgb => $current_fill_colour, type => "both");
        }
        elsif ($key eq 'fill') {
            if ($value eq 'none') {
                $self->{fill} = 0;
            }
            else {
                # it's a color
                $self->{fill} = 1;
                $current_fill_colour = get_colour($value);
                $pdf->set_colour(rgb => $current_fill_colour, type => "fill");
            }
        }
        elsif ($key eq 'fill-rule') {
            $value = 'winding' if $value eq 'nonzero';
            $pdf->set_parameter(fillrule => $value);
            $current_fillrule = $value;
        }
        elsif ($key eq 'stroke') {
            if ($value eq 'none') {
                $self->{stroke} = 0;
            }
            else {
                # it's a color
                $self->{stroke} = 1;
                $current_stroke_colour = get_colour($value);
                $pdf->set_colour(rgb => $current_stroke_colour, type => "stroke");
            }
        }
        elsif ($key eq 'stroke-linecap') {
            $pdf->set_line_cap("${value}_end"); # PDFLib takes care of butt|round|square
            $current_line_cap = $value;
        }
        elsif ($key eq 'stroke-linejoin') {
            $pdf->set_line_join($value); # PDFLib takes care of miter|round|bevel
            $current_line_join = $value;
        }
        elsif ($key eq 'stroke-width') {
            $pdf->set_line_width($value);
            $current_line_width = $value;
        }
        elsif ($key eq 'stroke-miterlimit') {
            $pdf->set_miter_limit($value);
            $current_miter_limit = $value;
        }
    }

    return unless $text_mode;

    $pdf->set_decoration($underline?"underline":"none");

    my $ok = 0;
#    warn(sprintf("set_font(%s => %s, %s => %s, %s => %s, %s => %s)\n",
#                    face => $new_font,
#                    italic => $italic,
#                    bold => $bold,
#                    size => $size,
#                    )
#    );
    foreach my $face (split(/\s*/, $new_font)) {
        eval {
            $pdf->set_font(
                    face => $new_font,
                    italic => $italic,
                    bold => $bold,
                    size => $size,
                    );
        };
        if (!$@) {
            $ok = 1;
            last;
        }
    }
    if (!$ok) {
        die "Unable to find font: $new_font : $@";
    }

    if ($self->{fill} && $self->{stroke}) {
        $pdf->set_value(textrendering => 2);
    }
    elsif ($self->{fill}) {
        $pdf->set_value(textrendering => 0);
    }
    elsif ($self->{stroke}) {
        $pdf->set_value(textrendering => 1);
    }
    else {
        $pdf->set_value(textrendering => 3); # invisible
    }
}

sub slide_start_element {
    my ($self, $el) = @_;

    $self->{SlideCurrent} = $el;

    my $name = $el->{LocalName};

    #warn("slide_start_ $name ".join(",",map { $_."=>".$el->{Attributes}{$_}->{Value} } keys %{$el->{Attributes}})."\n");

    # transitions...
    if ( (!$self->{PrintMode}) &&
        $name =~ /^(point|plain|image|source[_-]code|table|col|row|circle|ellipse|rect|text|line|path)$/) {
        if (exists($el->{Attributes}{"{}transition"})
            || @{$self->{default_transition}}) {
            # has a transition
            my $trans = $el->{Attributes}{"{}transition"};
            # default transition if unspecified (and not for table tags)
            if ( (!$trans) && ($name ne 'table') && ($name ne 'row') && ($name ne 'col') && ($name ne 'box') ) {
                $trans = { Value => $self->{default_transition}[0] };
            }
            if ($trans && ($trans->{Value} ne 'none') ) {
                my @cache = @{$self->{cache_trash}};
                local $self->{cache} = \@cache;
                local $self->{cache_trash};
                # warn("playback on $el\n");
                $self->{transitional} = 1;
                my $parent = $el->{Parent};
                while ($parent) {
                    last if $parent->{LocalName} eq 'slide';
                    $parent = $parent->{Parent};
                }
                die "No parent slide element" unless $parent;
                local $parent->{Attributes}{"{}transition"}{Value} = $trans->{Value};
                $self->playback_cache; # should get us back here.
                $self->run_todo;
                # make sure we don't transition this node again
                $el->{Attributes}{"{}transition"}{Value} = 'none';
                # warn("playback returns\n");
                $self->{transitional} = 0;
                pop @{$self->{font_stack}} while (@{$self->{font_stack}} && $self->{font_stack}[-1][-1]);
            }
        } else {
            $el->{Attributes}{"{}transition"}{Value} = 'none';
        }
    }

    if ($name =~ m/^(table|list|image|source[-_]code)$/ && $el->{Attributes}{'{}title'}) {
        $self->push_font();
        $self->{pdf}->set_font(face => $self->{normal_font}, italic => 1, size => 15);
        my ($x, $y) = $self->{pdf}->get_text_pos;
        my $indent = 80 * ($self->{extents}[0]{w} / $self->{extents}[-1]{w});
        $self->{pdf}->set_text_pos($self->{bb}?$self->{bb}->{x}:$self->{extents}[0]{x}+$indent, $y);
        $self->{pdf}->print($el->{Attributes}{'{}title'}{Value});
        $self->{pdf}->print_line("") unless $name eq 'image';
        $self->pop_font();
    }

    if ($name eq 'slide') {
        $self->new_page(undef,$el->{Attributes}{"{}type"}{Value});
        $self->{image_id} = 0;
        # if we do bullet/image transitions, make sure new pages don't use a transition
        $el->{Attributes}{"{}transition"}{Value} = "replace";
        $self->{extents} = [{ x => 0, w => 612 }];
    }
    elsif ($name eq 'title') {
        $self->gathered_text; # reset
        $self->{chars_ok} = 1;

        if ($self->{pagetype} ne 'empty') {
            my $bb = $self->{pdf}->new_bounding_box(
                x => 5, y => 400, w => 602, h => 50,
                align => "centre",
               );
            $self->{bb} = $bb;
            $bb->set_font(
                face => $self->{title_font},
                size => $self->{title_size},
               );
        }
    }
    elsif ($name eq 'table') {
        # push extents.
        $self->{extents} = [{ %{$self->{extents}[0]} }, @{$self->{extents}}];
        $self->{col_widths} = [];
        my ($x, $y) = $self->{pdf}->get_text_pos;
        $self->{pdf}->set_text_pos($self->{extents}[1]{x}, $y);
        $self->{max_height} = $y;
        $self->{row_number} = 0;
    }
    elsif ($name eq 'box') {
        if (!$self->{transitional}) {
            if (exists($el->{Attributes}{"{}default-transition"})) {
                unshift @{$self->{default_transition}}, $el->{Attributes}{"{}default-transition"}{Value};
                unshift @{$self->{boxtransition}}, 1;
                delete $el->{Attributes}{"{}default-transition"};
            } else {
                unshift @{$self->{boxtransition}}, 0;
            }
        }
        # push extents.
        $self->{extents} = [{ %{$self->{extents}[0]} }, @{$self->{extents}}];
        $self->{extents}[0]{x} = $el->{Attributes}{'{}x'}{Value};
        $self->{extents}[0]{w} = $el->{Attributes}{'{}width'}{Value};
        $self->{extents}[0]{y} = $el->{Attributes}{'{}y'}{Value};
        $self->{extents}[0]{h} = $el->{Attributes}{'{}height'}{Value};
        $self->{boxlast} = [ $self->{pdf}->get_text_pos() ];
        $self->{pdf}->set_text_pos($self->{extents}[0]{x}, $self->{extents}[0]{y});
    }
    elsif ($name eq 'row') {
        $self->{col_number} = 0;
        $self->{row_start} = [];
        @{$self->{row_start}} = $self->{pdf}->get_text_pos;
    }
    elsif ($name eq 'col') {
        my $width;
        my $prev_x = $self->{extents}[1]{x};
        if ($self->{row_number} > 0) {
            $width = $self->{col_widths}[$self->{col_number}];
        }
        else {
            $width = $el->{Attributes}{"{}width"}{Value};
            $width =~ s/%$// || die "Column widths must be in percentages";
            # warn("calculating ${width}% of $self->{extents}[1]{w}\n");
            $width = $self->{extents}[1]{w} * ($width/100);
            $self->{col_widths}[$self->{col_number}] = $width;
        }
        if ($self->{col_number} > 0) {
            my $up_to = $self->{col_number} - 1;
            foreach my $col (0 .. $up_to) {
                $prev_x += $self->{col_widths}[$col];
            }
        }
        # warn("col setting extents to x => $prev_x, w => $width\n");
        $self->{extents}[0]{x} = $prev_x;
        $self->{extents}[0]{w} = $width;
        $self->{pdf}->set_text_pos(@{$self->{row_start}});
    }
    elsif ($name eq 'value') {
        my $type = $el->{Attributes}{'{}type'}{Value};
        my $pdf = $self->{bb} || $self->{pdf};
        if (exists $self->{values}->{$type}) {
            $pdf->print($self->{values}->{$type});
        } elsif (exists $self->{metadata}->{$type}) {
            $pdf->print($self->{metadata}->{$type});
        } elsif ($type eq 'today') {
            $pdf->print(localtime->strftime($el->{Attributes}{'{}format'}{Value}||'%Y-%m-%d'));
        } elsif ($type eq 'logo') {
            if (my $logo = $self->{logo}) {
                my @scale = split(/\*/,$logo->{scale});
                my $imgw = $self->get_scale($scale[0],0,$self->{pdf}->get_value("imagewidth", $logo->{image}->img),$self->{pdf}->get_value("resx", $logo->{image}->img));
                my $imgh = $self->get_scale($scale[1]||$scale[0],1,$self->{pdf}->get_value("imageheight", $logo->{image}->img),$self->{pdf}->get_value("resy", $logo->{image}->img));
                my ($x, $y) = $pdf->get_text_pos();
                if ($self->{bb}) {
                    $pdf->push_todo('add_image',img => $logo->{image}, x => $x+$pdf->{cur_width}, y => $y, w => $imgw, h => $imgh);
                    $pdf->push_todo('set_text_pos',$x+$pdf->{cur_width}+$imgw,$y);
                } else {
                    $pdf->add_image(img => $logo->{image}, x => $x, y => $y, w => $imgw, h => $imgh);
                }
            }
        } elsif ($type eq 'background') {
            if (my $bg = $self->{bg}) {
                my @scale = split(/\*/,$bg->{scale});
                my $imgw = $self->get_scale($scale[0],0,$self->{pdf}->get_value("imagewidth", $bg->{image}->img),$self->{pdf}->get_value("resx", $bg->{image}->img));
                my $imgh = $self->get_scale($scale[1]||$scale[0],1,$self->{pdf}->get_value("imageheight", $bg->{image}->img),$self->{pdf}->get_value("resy", $bg->{image}->img));
                my ($x, $y) = $pdf->get_text_pos();
                if ($self->{bb}) {
                    $pdf->push_todo('add_image',img => $bg->{image}, x => $x+$pdf->{cur_width}, y => $y, w => $imgw, h => $imgh);
                    $pdf->push_todo('set_text_pos',$x+$pdf->{cur_width}+$imgw,$y);
                } else {
                    $pdf->add_image(img => $bg->{image}, x => $x, y => $y, w => $imgw, h => $imgh);
                }
            }
        } elsif ($type eq 'current-slideset') {
            $pdf->print(join(".",reverse @{$self->{slide_index}}).". ");
        }
    }
    elsif ($name eq 'i') {
        my $new = $self->{pdf}->get_parameter("fontname") || $self->{normal_font};
        my $bold = 0;
        if ($new =~ s/-(.*)$//) {
            my $removed = $1;
            if ($removed =~ /Bold/i) {
                $bold = 1;
            }
        }
        $self->push_font();
        $self->{bb}->set_font(face => $new, italic => 1, bold => $bold);
    }
    elsif ($name eq 'b') {
        my $new = $self->{pdf}->get_parameter("fontname") || $self->{normal_font};
        my $italic = 0;
        if ($new =~ s/-(.*)$//) {
            my $removed = $1;
            if ($removed =~ /(Oblique|Italic)/i) {
                $italic = 1;
            }
        }
        $self->push_font();
        $self->{bb}->set_font(face => $new, italic => $italic, bold => 1);
    }
    elsif ($name eq 'u') {
        $self->push_font();
        $self->{bb}->set_decoration("underline");
    }
    elsif ($name eq 'plain') {
        $self->{chars_ok} = 1;
        my ($x, $y) = $self->{pdf}->get_text_pos;

        my $indent = 80 * ($self->{extents}[0]{w} / $self->{extents}[-1]{w});
        $y += 9;
        $self->{pdf}->set_text_pos($self->{extents}[0]{x} + $indent, $y);
        $self->{pdf}->set_font(face => $self->{normal_font}, size => 18);
        $self->{pdf}->print_line("");

        ($x, $y) = $self->{pdf}->get_text_pos;
        my $align = $el->{Attributes}{"{}align"}{Value} || 'left';
        my $bb = $self->{pdf}->new_bounding_box(
            x => $x, y => $y, w => ($self->{extents}[0]{w} - ($x - $self->{extents}[0]{x})), h => $y, align => $align
        );
        $self->{bb} = $bb;
    }
    elsif ($name eq 'point') {
        $self->{chars_ok} = 1;

        my ($x, $y, $size) = $self->bullet($el);

        # warn(sprintf("creating new bb: %s => %d, %s => %d, %s => %d, %s => %d",
        #     x => $x, y => $y, w => ($self->{extents}[0]{w} - ($x - $self->{extents}[0]{x})), h => (450 - $y)
        #     ));
        my $bb = $self->{pdf}->new_bounding_box(
            x => $x, y => $y, w => ($self->{extents}[0]{w} - ($x - $self->{extents}[0]{x})), h => $y
        );
        $self->{bb} = $bb;
    }
    elsif ($name eq 'image') {
        my $image = $self->{images}[$self->{image_id}];
        my ($scale, $handle, $href) =
            ($image->{scale}, $image->{image_ref}, $image->{href});
        if (defined($image->{x}) && defined($image->{y})) {
            my $pdf = $self->{pdf};
            my @scale = split(/\*/,$scale);
            my $imgw = $self->get_scale($scale[0],0,$pdf->get_value("imagewidth", $handle->img),$pdf->get_value("resx", $handle->img));
            my $imgh = $self->get_scale($scale[1]||$scale[0],1,$pdf->get_value("imageheight", $handle->img),$pdf->get_value("resy", $handle->img));
            $pdf->add_image(img => $handle,
                x => $image->{x},
                y => $image->{y},
                w => $imgw,
                h => $imgh
            );
        }
        else {
            $self->image($scale, $handle, $href);
        }
    }
    elsif ($name eq 'source_code' || $name eq 'source-code') {
        my $size = $el->{Attributes}{"{}fontsize"}{Value} || 14;
        $self->{chars_ok} = 1;

        my ($x, $y) = $self->{pdf}->get_text_pos;
        my $indent = 80 * ($self->{extents}[0]{w} / $self->{extents}[-1]{w});
        $self->{pdf}->set_text_pos($self->{extents}[0]{x} + $indent, $y);

        $self->push_font();
        $self->{pdf}->set_font(face => "Courier", size => $size);
        ($x, $y) = $self->{pdf}->get_text_pos;
        my $bb = $self->{pdf}->new_bounding_box(
            x => $x, y => $y, w => ($self->{extents}[0]{w} - ($x - $self->{extents}[0]{x})), h => $y,
            wrap => 0,
        );
        # warn("new_bounding_box( h => $y ) => $bb\n");
        $self->{bb} = $bb;
    }
    elsif ($name eq 'color' || $name eq 'colour') {
        my $hex_colour;
        if (exists($el->{Attributes}{"{}name"})) {
            my $colour = lc($el->{Attributes}{"{}name"}{Value});
            $hex_colour = $colours{$colour}
                || die "No such colour: $colour";
        }
        else {
            $hex_colour = $el->{Attributes}{"{}rgb"}{Value};
        }
        if (!$hex_colour) {
            die "Missing colour attribute: name or rgb (found: " . join(', ', keys(%{$el->{Attributes}})) .")";
        }
        $hex_colour =~ s/^#//;
        if ($hex_colour !~ /^[0-9a-fA-F]{6}$/) {
            die "Invalid hex format: $hex_colour";
        }

        my ($r, $g, $b) = map { hex()/255 } ($hex_colour =~ /(..)/g);

        $self->push_font();
        $self->{bb}->set_color(rgb => [$r,$g,$b]);
    }
    elsif ($name eq 'span') {
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value}, 1);
    }
    elsif ($name eq 'g') {
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value}, 1);
    }
    elsif ($name eq 'rect') {
        my ($x, $y, $width, $height) = (
            $el->{Attributes}{"{}x"}{Value},
            $el->{Attributes}{"{}y"}{Value},
            $el->{Attributes}{"{}width"}{Value},
            $el->{Attributes}{"{}height"}{Value},
            );
        $self->{pdf}->save_graphics_state();
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value});
        if ($self->{coords} eq 'svg') {
            $self->{pdf}->rect(x => $x, y => $self->{pdf}->get_value('pageheight')-$y-$height, w => $width, h => $height);
        }
        else {
            $self->{pdf}->rect(x => $x, y => $y, w => $width, h => $height);
        }

        if ($self->{fill} && $self->{stroke}) {
            $self->{pdf}->fill_stroke;
        }
        elsif ($self->{fill}) {
            $self->{pdf}->fill;
        }
        elsif ($self->{stroke}) {
            $self->{pdf}->stroke;
        }
    }
    elsif ($name eq 'circle') {
        my ($cx, $cy, $r) = (
            $el->{Attributes}{"{}cx"}{Value},
            $el->{Attributes}{"{}cy"}{Value},
            $el->{Attributes}{"{}r"}{Value},
            );
        $self->{pdf}->save_graphics_state();
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value});
        if ($self->{coords} eq 'svg') {
            $self->{pdf}->circle(x => $cx, y => $self->{pdf}->get_value('pageheight')-$cy, r => $r);
        }
        else {
            $self->{pdf}->circle(x => $cx, y => $cy, r => $r);
        }
        if ($self->{fill} && $self->{stroke}) {
            $self->{pdf}->fill_stroke;
        }
        elsif ($self->{fill}) {
            $self->{pdf}->fill;
        }
        elsif ($self->{stroke}) {
            $self->{pdf}->stroke;
        }
    }
    elsif ($name eq 'ellipse') {
        my ($cx, $cy, $rx, $ry) = (
            $el->{Attributes}{"{}cx"}{Value},
            $el->{Attributes}{"{}cy"}{Value},
            $el->{Attributes}{"{}rx"}{Value},
            $el->{Attributes}{"{}ry"}{Value},
            );
        my $r = $rx;
        my $scale = $ry / $r;
        $cy /= $scale;
        # warn("ellipse at $cx, $cy, scale: $scale, r: $r\n");
        $self->{pdf}->save_graphics_state();
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value});
        $self->{pdf}->coord_scale(1, $scale);
        if ($self->{coords} eq 'svg') {
            $self->{pdf}->circle(x => $cx, y => $self->{pdf}->get_value('pageheight')-$cy, r => $r);
        }
        else {
            $self->{pdf}->circle(x => $cx, y => $cy, r => $r);
        }
        if ($self->{fill} && $self->{stroke}) {
            $self->{pdf}->fill_stroke;
        }
        elsif ($self->{fill}) {
            $self->{pdf}->fill;
        }
        elsif ($self->{stroke}) {
            $self->{pdf}->stroke;
        }
    }
    elsif ($name eq 'line') {
        my ($x1, $y1, $x2, $y2) = (
            $el->{Attributes}{"{}x1"}{Value},
            $el->{Attributes}{"{}y1"}{Value},
            $el->{Attributes}{"{}x2"}{Value},
            $el->{Attributes}{"{}y2"}{Value},
            );
        $self->{pdf}->save_graphics_state();
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value});
        if ($self->{coords} eq 'svg') {
            $self->{pdf}->move_to($x1, $self->{pdf}->get_value('pageheight')-$y1);
            $self->{pdf}->line_to($x2, $self->{pdf}->get_value('pageheight')-$y2);
        }
        else {
            $self->{pdf}->move_to($x1, $y1);
            $self->{pdf}->line_to($x2, $y2);
        }
        if ($self->{fill} && $self->{stroke}) {
            $self->{pdf}->fill_stroke;
        }
        elsif ($self->{fill}) {
            $self->{pdf}->fill;
        }
        elsif ($self->{stroke}) {
            $self->{pdf}->stroke;
        }
    }
    elsif ($name eq 'text') {
        my ($x, $y) = (
            $el->{Attributes}{"{}x"}{Value},
            $el->{Attributes}{"{}y"}{Value},
        );
        $self->{pdf}->save_graphics_state();
        $self->push_font();
        $self->{pdf}->set_font( face => $self->{normal_font}, size => 14.0 ) unless $el->{Parent}->{LocalName} eq 'g';
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value}, 1);
        if ($self->{coords} eq 'svg') {
            $self->{pdf}->set_text_pos($x, $self->{pdf}->get_value('pageheight')-$y);
        }
        else {
            $self->{pdf}->set_text_pos($x, $y);
        }
        $self->{chars_ok} = 1;
        $self->gathered_text; # reset
    }
    elsif ($name eq 'list') {
        if ($el->{Attributes}{"{}ordered"}) {
            push @{$self->{list_index}}, 1;
        } else {
            push @{$self->{list_index}}, 0;
        }
    }
    elsif ($name eq 'path') {
        my ($data) = (
            $el->{Attributes}{"{}d"}{Value},
            );
        $self->{pdf}->save_graphics_state();
        $self->process_css_styles($el->{Attributes}{"{}style"}{Value});
        $self->process_path($data);
    }
}

use constant PI => atan2(1, 1) * 4.0;

sub convert_from_svg
{
    my ($x0, $y0, $rx, $ry, $phi, $large_arc, $sweep, $x, $y) = @_;
    my ($cx, $cy, $theta, $delta);

    # a plethora of temporary variables 
    my (
        $dx2, $dy2, $phi_r, $x1, $y1,
        $rx_sq, $ry_sq,
        $x1_sq, $y1_sq,
        $sign, $sq, $coef,
        $cx1, $cy1, $sx2, $sy2,
        $p, $n,
        $ux, $uy, $vx, $vy
    );

    # Compute 1/2 distance between current and final point
    $dx2 = ($x0 - $x) / 2.0;
    $dy2 = ($y0 - $y) / 2.0;

    # Convert from degrees to radians
    $phi %= 360;
    $phi_r = $phi * PI / 180.0;

    # Compute (x1, y1)
    $x1 = cos($phi_r) * $dx2 + sin($phi_r) * $dy2;
    $y1 = -sin($phi_r) * $dx2 + cos($phi_r) * $dy2;

    # Make sure radii are large enough
    $rx = abs($rx); $ry = abs($ry);
    $rx_sq = $rx * $rx;
    $ry_sq = $ry * $ry;
    $x1_sq = $x1 * $x1;
    $y1_sq = $y1 * $y1;

    my $radius_check = ($x1_sq / $rx_sq) + ($y1_sq / $ry_sq);
    if ($radius_check > 1)
    {
        $rx *= sqrt($radius_check);
        $ry *= sqrt($radius_check);
        $rx_sq = $rx * $rx;
        $ry_sq = $ry * $ry;
    }

    # Step 2: Compute (cx1, cy1)

    $sign = ($large_arc == $sweep) ? -1 : 1;
    $sq = (($rx_sq * $ry_sq) - ($rx_sq * $y1_sq) - ($ry_sq * $x1_sq)) /
        (($rx_sq * $y1_sq) + ($ry_sq * $x1_sq));
    $sq = ($sq < 0) ? 0 : $sq;
    $coef = ($sign * sqrt($sq));
    $cx1 = round($coef * (($rx * $y1) / $ry));
    $cy1 = round($coef * -(($ry * $x1) / $rx));

    #   Step 3: Compute (cx, cy) from (cx1, cy1)

    $sx2 = ($x0 + $x) / 2.0;
    $sy2 = ($y0 + $y) / 2.0;

    #   Step 4: Compute angle start and angle extent

    #$ux = ($x0-$cx);
    #$uy = ($y0-$cy);
    #$vx = ($x-$cx);
    #$vy = ($y-$cy);

    #print STDERR "    u: ($ux,$uy) | v: ($vx,$vy)\n";

    $ux = ($x1 - $cx1) / $rx;
    $uy = ($y1 - $cy1) / $ry;
    $vx = (-$x1 - $cx1) / $rx;
    $vy = (-$y1 - $cy1) / $ry;

    $n = sqrt( ($ux * $ux) + ($uy * $uy) );
    $p = $ux; # 1 * ux + 0 * uy
    $sign = ($uy > 0) ? -1 : 1;

    $theta = $sign * acos( $p / $n );
    $theta = $theta * 180 / PI;

    $n = sqrt(($ux * $ux + $uy * $uy) * ($vx * $vx + $vy * $vy));
    $p = $ux * $vx + $uy * $vy;
    $sign = (($ux * $vy - $uy * $vx) > 0) ? -1 : 1;
    $delta = $sign * acos( $p / $n );
    $delta = round($delta * 180 / PI);
    #print STDERR "    delta: $delta\n";

    if ($large_arc == 0 && $delta >= 180) {
        $delta -= 360;
    } elsif ($large_arc == 0 && $delta < -180) {
        $delta += 360;
    } elsif ($large_arc == 1 && $delta <= 180 && $delta > 0) {
        $delta -= 360;
    } elsif ($large_arc == 1 && $delta > -180 && $delta <= 0) {
        $delta += 360;
    }

    #print STDERR "    actually doing arc ($large_arc,$sweep): $cx1, $cy1 $rx,$ry, $theta, $delta, $phi\n";

    return bezier_arc_approximation($cx1, $cy1, $rx, $ry, $theta, $delta, $phi_r, $sx2, $sy2);
}

sub round {
    return int(($_[0])*100+.5)/100;
}

# Taken from http://www.faqts.com/knowledge_base/view.phtml/aid/4313
sub bezier_arc_approximation {
    my ($cx, $cy, $rx, $ry, $start, $extent, $phi_r, $rcx, $rcy) = @_;

    # The resulting coordinates are of the form (x1,y1, x2,y2, x3,y3, x4,y4) such that
    # the curve goes from (x1, y1) to (x4, y4) with (x2, y2) and (x3, y3) as their
    # respective Bézier control points.

    my $nfrag = int(ceil(abs($extent)/90));
    my $fragAngle = $extent/$nfrag;

    my $halfAng = $fragAngle * PI / 360;
    my $kappa = 4 / 3 * (1-cos($halfAng))/sin($halfAng);

    my @ret;

    for my $i (0..($nfrag-1)) {
        my $theta0 = ($start + $i*$fragAngle) * PI / 180;
        my $theta1 = ($start + ($i+1)*$fragAngle) * PI / 180;
        push @ret, [
            rotate($rcx,$rcy,$phi_r, $cx + $rx * cos($theta0), $cy -$ry * sin($theta0)),
            rotate($rcx,$rcy,$phi_r, $cx + $rx * (cos($theta0) - $kappa * sin($theta0)), $cy -$ry * (sin($theta0) + $kappa * cos($theta0))),
            rotate($rcx,$rcy,$phi_r, $cx + $rx * (cos($theta1) + $kappa * sin($theta1)), $cy -$ry * (sin($theta1) - $kappa * cos($theta1))),
            rotate($rcx,$rcy,$phi_r, $cx + $rx * cos($theta1), $cy -$ry * sin($theta1)),
           ];
    }

    return @ret;
}

sub rotate {
    my ($rcx, $rcy, $phi_r, $x, $y) = @_;
    return (($rcx + (cos($phi_r) * $x - sin($phi_r) * $y)), ($rcy + (sin($phi_r) * $x + cos($phi_r) * $y)));
}

sub process_path {
    my $self = shift;
    my ($data) = @_;
    $data =~ s/^\s*//;
    my @parts = split(/([A-Za-z])/, $data);
    # warn("got: '", join("', '", @parts), "'\n");
    shift(@parts); # get rid of junk at start
    my $ytotal = $self->{pdf}->get_value('pageheight');

    my $relative = 0;

    my ($xoffset, $yoffset) = map { $self->{pdf}->get_value($_) } qw(currentx currenty);
    $yoffset = $ytotal-$yoffset;

    my ($last_reflect_x, $last_reflect_y, $need_to_close);

    while (@parts) {
        my $type = shift(@parts);
        my $rest = shift(@parts);

        if ($type eq lc($type)) {
            # warn("using relative coordinates\n");
            $relative++;
        }

        my @coords = grep { /^[\d\.\-]+$/ } split(/[^\d\.\-]+/, $rest||'');
        # warn("got coords: '", join("', '", @coords), "'\n");

        my ($x, $y);

        if (lc($type) eq 'm') { # moveto
            if (@coords % 2) {
                warn("moveto coords must be in pairs, skipping.\n");
                next;
            }

            $need_to_close = 1;

            ($x, $y) = splice(@coords, 0, 2);
            if ($relative) {
                $x += $xoffset;
                $y += $yoffset;
            }
            # warn("move_to($x, $y)\n");
            if ($self->{coords} eq 'svg') {
                $self->{pdf}->move_to($x, $ytotal-$y);
            }
            else {
                $self->{pdf}->move_to($x, $y);
            }

            if (@coords) {
                # more coords == lines
                unshift @parts, ($relative ? 'l' : 'L'), join(',', @coords);
                next;
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 'z') { # closepath
            if ($self->{fill} && $self->{stroke}) {
                $self->{pdf}->close_path_fill_stroke;
            }
            elsif ($self->{fill}) {
                $self->{pdf}->close_path_fill;
            }
            elsif ($self->{stroke}) {
                $self->{pdf}->close_path_stroke;
            }
        }
        elsif (lc($type) eq 'l') { # lineto
            if (@coords % 2) {
                warn("moveto coords must be in pairs, skipping.\n");
                next;
            }

            $need_to_close = 1;

            while(@coords) {
                ($x, $y) = splice(@coords, 0, 2);
                # warn("line: $x, $y\n");
                if ($relative) {
                    $x += $xoffset;
                    $y += $yoffset;
                }
                # warn("line_to($x, $y)\n");
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->line_to($x, $ytotal-$y);
                }
                else {
                    $self->{pdf}->line_to($x, $y);
                }
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 'h') { # horizontal lineto
            $need_to_close = 1;

            while (@coords) {
                $x = shift @coords;
                if ($relative) {
                    $x += $xoffset;
                }
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->line_to($x, $ytotal-$yoffset);
                }
                else {
                    $self->{pdf}->line_to($x, $yoffset);
                }
            }
            $xoffset = $x;
        }
        elsif (lc($type) eq 'v') { # vertical lineto
            $need_to_close = 1;

            while (@coords) {
                $y = shift @coords;
                if ($relative) {
                    $y += $yoffset;
                }
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->line_to($xoffset, $ytotal-$y);
                }
                else {
                    $self->{pdf}->line_to($xoffset, $y);
                }
            }
            $yoffset = $y;
        }
        elsif (lc($type) eq 'c') { # curveto
            if (@coords % 6) {
                warn("curveto coords must be in 6's, skipping.\n");
                next;
            }
            
            $need_to_close = 1;

            while (@coords) {
                my ($x1, $y1, $x2, $y2, $x3, $y3) = splice(@coords, 0, 6);
                if ($relative) {
                    for ($x1, $x2, $x3) {
                        $_ += $xoffset;
                    }
                    for ($y1, $y2, $y3) {
                        $_ += $yoffset;
                    }
                }
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $ytotal-$y1,
                        x2 => $x2, y2 => $ytotal-$y2,
                        x3 => $x3, y3 => $ytotal-$y3,
                    );
                }
                else {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $y1,
                        x2 => $x2, y2 => $y2,
                        x3 => $x3, y3 => $y3,
                    );
                }
                ($last_reflect_x, $last_reflect_y) = ($x2, $y2);
                ($x, $y) = ($x3, $y3);
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 's') { # shorthand/smooth curveto
            if (@coords % 4) {
                warn("shorthand curveto coords must be in 4's, skipping.\n");
                next;
            }
            
            $need_to_close = 1;

            while (@coords) {
                my ($x2, $y2, $x3, $y3) = splice(@coords, 0, 4);
                if ($relative) {
                    $x2 += $xoffset;
                    $x3 += $xoffset;
                    $y2 += $yoffset;
                    $y3 += $yoffset;
                }
                my ($x1, $y1);
                if (defined($last_reflect_x)) {
                    $x1 = $xoffset - ($last_reflect_x - $xoffset);
                    $y1 = $yoffset - ($last_reflect_y - $yoffset);
                }
                else {
                    $x1 = $xoffset;
                    $y1 = $yoffset;
                }
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $ytotal-$y1,
                        x2 => $x2, y2 => $ytotal-$y2,
                        x3 => $x3, y3 => $ytotal-$y3,
                    );
                }
                else {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $y1,
                        x2 => $x2, y2 => $y2,
                        x3 => $x3, y3 => $y3,
                    );
                }
                ($last_reflect_x, $last_reflect_y) = ($x2, $y2);
                ($x, $y) = ($x3, $y3);
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 'q') { # quadratic bezier curveto
            if (@coords % 4) {
                warn("quadratic curveto coords must be in 4's, skipping.\n");
                next;
            }
            
            $need_to_close = 1;

            while (@coords) {
                my ($x1, $y1, $x3, $y3) = splice(@coords, 0, 4);
                if ($relative) {
                    for ($x1, $x3) {
                        $_ += $xoffset;
                    }
                    for ($y1, $y3) {
                        $_ += $yoffset;
                    }
                }
                my ($x2, $y2) = ($x1, $y1);
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $ytotal-$y1,
                        x2 => $x2, y2 => $ytotal-$y2,
                        x3 => $x3, y3 => $ytotal-$y3,
                    );
                }
                else {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $y1,
                        x2 => $x2, y2 => $y2,
                        x3 => $x3, y3 => $y3,
                    );
                }
                ($last_reflect_x, $last_reflect_y) = ($x2, $y2);
                ($x, $y) = ($x3, $y3);
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 't') { # shorthand/smooth quadratic bezier curveto
            if (@coords % 2) {
                warn("shorthand quadratic curveto coords must be in pairs, skipping.\n");
                next;
            }
            
            $need_to_close = 1;

            while (@coords) {
                my ($x3, $y3) = splice(@coords, 0, 2);
                if ($relative) {
                    $x3 += $xoffset;
                    $y3 += $yoffset;
                }
                my ($x1, $y1, $x2, $y2);
                if (defined($last_reflect_x)) {
                    $x1 = $xoffset - ($last_reflect_x - $xoffset);
                    $y1 = $yoffset - ($last_reflect_y - $yoffset);
                }
                else {
                    $x1 = $xoffset;
                    $y1 = $yoffset;
                }
                ($x2, $y2) = ($x1, $y1);
                if ($self->{coords} eq 'svg') {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $ytotal-$y1,
                        x2 => $x2, y2 => $ytotal-$y2,
                        x3 => $x3, y3 => $ytotal-$y3,
                    );
                }
                else {
                    $self->{pdf}->bezier(
                        x1 => $x1, y1 => $y1,
                        x2 => $x2, y2 => $y2,
                        x3 => $x3, y3 => $y3,
                    );
                }
                ($last_reflect_x, $last_reflect_y) = ($x2, $y2);
                ($x, $y) = ($x3, $y3);
            }
            $xoffset = $x; $yoffset = $y;
        }
        elsif (lc($type) eq 'a') { # elliptical arc
            if (@coords % 7) {
                warn("elliptical arc coords must be in 7's, skipping.\n");
                next;
            }
            
            while (@coords) {
                my ($rx, $ry, $rot, $large_arc_flag, $sweep_flag, $x2, $y2) =
                    splice(@coords, 0, 7);

                if ($relative) {
                    $x2 += $xoffset;
                    $y2 += $yoffset;
                }

                # warn("arc($xoffset,$yoffset $rest)\n");

                #print STDERR "arc from $xoffset,$yoffset to $x2,$y2 ($large_arc_flag,$sweep_flag)\n";

                my @curves = convert_from_svg(
                                $xoffset, $yoffset,
                                $rx, $ry,
                                $rot, int($large_arc_flag), int($sweep_flag),
                                $x2, $y2);

                foreach my $curve (@curves) {
                    #$self->{pdf}->move_to($$curve[0],$ytotal-$$curve[1]);
                    #print STDERR "    bezier: ($$curve[0],$$curve[1]) -> ($$curve[6],$$curve[7])\n";
                    if ($self->{coords} eq 'svg') {
                        $self->{pdf}->bezier(
                            x1 => $$curve[2],
                            y1 => $ytotal-$$curve[3],
                            x2 => $$curve[4],
                            y2 => $ytotal-$$curve[5],
                            x3 => $$curve[6],
                            y3 => $ytotal-$$curve[7],
                        );
                    }
                    else {
                        $self->{pdf}->bezier(
                            x1 => $$curve[2],
                            y1 => $ytotal-$$curve[3],
                            x2 => $$curve[4],
                            y2 => $ytotal-$$curve[5],
                            x3 => $$curve[6],
                            y3 => $ytotal-$$curve[7],
                        );
                    }
                }

                ($x, $y) = ($x2, $y2);
            }
            $xoffset = $x; $yoffset = $y;
        }
        else {
            warn("Unknown SVG path command: $type in $data");
        }
    }

    if ($need_to_close) {
        if ($self->{fill} && $self->{stroke}) {
            $self->{pdf}->fill_stroke;
        }
        elsif ($self->{fill}) {
            $self->{pdf}->fill;
        }
        elsif ($self->{stroke}) {
            $self->{pdf}->stroke;
        }
    }
}

sub slide_end_element {
    my ($self, $el) = @_;

    my $name = $el->{LocalName};

    #warn("slide_end_ $name ".join(",",map { $_."=>".$el->{Attributes}{$_}->{Value} } keys %{$el->{Attributes}})."\n");

    $el = $self->{SlideCurrent};

    if ($name =~ /^(point|plain|source[_-]code)$/) {
        # finish bounding box
        my ($x, $y) = $self->{bb}->get_text_pos;
        $self->{bb}->finish;
        $self->{pdf}->set_text_pos($self->{bb}->{x}, $y - 4);
        my $bb = delete $self->{bb};
        $self->{pdf}->print_line("");
    }

    if ($name eq 'title') {
        if ($self->{pagetype} ne 'empty') {
            my ($x, $y) = $self->{bb}->get_text_pos;
            $self->{bb}->finish;
            $self->{pdf}->set_text_pos($self->{bb}->{x}, $y - 4);
            my $bb = delete $self->{bb};
            $self->{pdf}->print_line("");
        }
        # create bookmarks
        if (!$self->{transitional}) {
            my $text = $self->gathered_text;
            $self->{values}->{'slide-title'} = $text;
            $self->push_bookmark(
                $self->{pdf}->add_bookmark(
                    text => $self->{text_encoder}->convert($text),
                    level => 3,
                    parent_of => $self->top_bookmark,
                )
            );
        }
        if ($self->{pagetype} ne 'empty') {
            my ($x, $y) = $self->{pdf}->get_text_pos();
            $self->{pdf}->add_link(
                link => $el->{Attributes}{"{}href"}{Value},
                x => 20, y => $y + $self->{pdf}->get_value('leading'),
                w => 570, h => 24) if exists($el->{Attributes}{"{}href"});
            $self->{pdf}->set_text_pos(60, $y);
        }
        $self->{chars_ok} = 0;
    }
    elsif ($name eq 'slide') {
        $self->pop_bookmark unless $self->{transitional};
    }
    elsif ($name eq 'i' || $name eq 'b' || $name eq 'span' || $name eq 'g' || $name eq 'u') {
        $self->pop_font();
    }
    elsif ($name eq 'point') {
        $self->{chars_ok} = 0;
        my ($x, $y) = $self->{pdf}->get_text_pos();
        $self->{pdf}->add_link(
            link => $el->{Attributes}{"{}href"}{Value},
            x => 20, y => $y + $self->{pdf}->get_value('leading'),
            w => 570, h => 24) if exists($el->{Attributes}{"{}href"});
    }
    elsif ($name eq 'plain') {
        $self->{chars_ok} = 0;
    }
    elsif ($name eq 'source_code' || $name eq 'source-code') {
        $self->{chars_ok} = 0;
        $self->pop_font();
    }
    elsif ($name eq 'image') {
        $self->{image_id}++;
    }
    elsif ($name eq 'colour' || $name eq 'color') {
        $self->pop_font();
    }
    elsif ($name eq 'table') {
        shift @{$self->{extents}};
    }
    elsif ($name eq 'box') {
        shift @{$self->{extents}};
        $self->{pdf}->set_text_pos(@{$self->{boxlast}});
        if (!$self->{transitional}) {
            if ($self->{boxtransition}[0]) {
                shift @{$self->{default_transition}};
            }
            shift @{$self->{boxtransition}};
        }
    }
    elsif ($name eq 'row') {
        $self->{row_number}++;
        $self->{pdf}->set_text_pos($self->{row_start}[0], $self->{max_height});
    }
    elsif ($name eq 'col') {
        $self->{col_number}++;
        $self->{pdf}->print_line("");
        my ($x, $y) = $self->{pdf}->get_text_pos;
        # warn("end-col: $y < $self->{max_height} ???");
        $self->{max_height} = $y if $y < $self->{max_height};
    }
    elsif ($name eq 'text') {
        my $text = $self->gathered_text;
        $self->{chars_ok} = 0;
        $self->{pdf}->print($text);
        $self->{pdf}->restore_graphics_state();
        $self->pop_font();
        $self->pop_font();
    }
    elsif ($name eq 'list') {
        pop @{$self->{list_index}};
    }
    elsif ($name =~ /^(circle|ellipse|line|rect|path)$/) {
        $self->{pdf}->restore_graphics_state();
        $self->pop_font();
    }

    if ($name =~ m/^(table|list|image|source[-_]code)$/ && $el->{Attributes}{'{}caption'}) {
        $self->push_font();
        $self->{pdf}->set_font(face => $self->{normal_font}, italic => 1, size => 14);
        my ($x, $y) = $self->{pdf}->get_text_pos;
        my $indent = 80 * ($self->{extents}[0]{w} / $self->{extents}[-1]{w});
        $self->{pdf}->set_text_pos($self->{bb}?$self->{bb}->{x}:$self->{extents}[0]{x}+$indent, $y);
        $self->{pdf}->print_line("");
        $self->{pdf}->print($el->{Attributes}{'{}caption'}{Value});
        $self->pop_font();
    }


    $self->{SlideCurrent} = $el->{Parent};
}

sub slide_characters {
    my ($self, $chars) = @_;

    return unless $self->{chars_ok};

    $self->{gathered_text} .= $chars->{Data};

    my $name = $self->{SlideCurrent}->{LocalName};
    my $text = $chars->{Data};
    return unless $text && $self->{bb};
    my $leftover = $self->{bb}->print($self->{text_encoder}->convert($text));
    if (defined $leftover && $leftover =~ m/\S/) {
        die "Could not print: $leftover\nof: $text\n";
    }
}

1;
__END__

=head1 NAME

XML::Handler::AxPoint - AxPoint XML to PDF Slideshow generator

=head1 SYNOPSIS

Using SAX::Machines:

  use XML::SAX::Machines qw(Pipeline);
  use XML::Handler::AxPoint;

  Pipeline( XML::Handler::AxPoint->new() )->parse_uri("presentation.axp");

Or using directly:

  use XML::SAX;
  use XML::Handler::AxPoint;

  my $parser = XML::SAX::ParserFactory->parser(
      Handler => XML::Handler::AxPoint->new(
          Output => "presentation.pdf"
          )
      );

  $parser->parse_uri("presentation.axp");

=head1 DESCRIPTION

This module is a port and enhancement of the AxKit presentation tool,
B<AxPoint>. It takes an XML description of a slideshow, and generates
a PDF. The resulting presentations are very nice to look at, possibly
rivalling PowerPoint, and almost certainly better than most other
freeware presentation tools on Unix/Linux.

The presentations support slide transitions, PDF bookmarks, bullet
points, source code (fixed font) sections, images, SVG vector graphics,
tables, colours, bold and italics, hyperlinks, and transition effects
for all the bullet points, source, and image sections.

=head1 SYNTAX

=head2 <slideshow>

This is the outer element, and must always be present.

Optional attributes:

=over 4

=item * default-transition - contains the transition to be used for
each slide in the slideshow. See the details of transitions below.

=item * coordinates - either "svg" or "old". By default the AxPoint
graphics are drawn using SVG-style coordinates, however prior to
cvs id 1.45 the coordinates were inverted due to lazy coding. If
you have presentations prior to this version, or you want
coordinates to start at the top of the screen, specify
coordinates="old".

=back

=head2 <title>

  <slideshow>
    <title>My First Presentation</title>

The title of the slideshow, used on the first (title) slide.

=head2 <metadata>

  <metadata>
     <speaker>Matt Sergeant</speaker>
     <email>matt@axkit.com</email>
     <organisation>AxKit.com Ltd</organisation>
     <link>http://axkit.com/</link>
     <logo scale="0.4">ax_logo.png</logo>
     <background scale="1.1page">redbg.png</background>
     <bullet level="1">n</bullet>
     <bullet level="2">l</bullet>
     <bullet level="3">u</bullet>
     <bullet level="4">F</bullet>
     <numbers level="3">item#$1 -</numbers>
     <numbers level="4">($a)</numbers>
  </metadata>

Metadata for the slideshow. Speaker and Organisation are used on the
first (title) slide, and the email and link are turned into hyperlinks.

The background and logo are used on every slide.

The bullet tags define the bullet characters (taken from the ZapfDingbats
font) to be used for various point levels.

Using the numbers tag, you can customize list numbering. The text contained is
used as-is, with special sequences replaced by the current point number:
C<$1> = plain arabic digits, C<$a>/C<$A> = lower-/uppercase letters,
C<$i>/C<$I> = lower/uppercase roman numbers and $$ = a plain dollar sign.

You are allowed to put <metadata> sections between slides to override settings
for all following slides.

=head2 <slideset>

  <slideset>
    <title>A subset of the show</title>
    <subtitle>And a subtitle for it</subtitle>

A slideset groups slides into relevant subsets, with a title and a new
level in the bookmarks for the PDF.

The title and subtitle tags can have C<href> attributes which turn those
texts into links.

Slidesets may be nested, in which case you can create a
chapter-section-subsection-... structure. Mixing slides and slidesets on
the same level will likewise produce the expected results.

=head2 <slide>

  <slide transition="dissolve">
    <title>Introduction</title>
    <list>
      <point>Perl's XML Capabilities</point>
    </list>
    <source-code>use XML::SAX;</source-code>
  </slide>

The slide tag defines a single slide. Each top level tag in the slide
can have a C<transition> attribute, which either defines a transition
for the entire slide, or for the individual top level items.

The valid settings for transition are:

=over 4

=item replace

The default. Just replace the old page. Use this on top level page items
to make them appear one by one.

=item split

Two lines sweeping across the screen reveal the page

=item blinds

Multiple lines sweep across the screen to reveal the page

=item box

A box reveals the page

=item wipe

A single line sweaping across the screen reveals the page

=item dissolve

The old page dissolves to reveal the new page

=item glitter

The dissolve effect moves from one screen edge to another

=back

For example, to have each point on a slide reveal themselves
one by one:

  <slide>
    <title>Transitioning Bullet Points</title>
    <list>
      <point transition="replace">Point 1</point>
      <point transition="replace">Point 2</point>
      <point transition="replace">Final Point</point>
    </list>
  </slide>

=head2 <list>/<point>

The point specifies a bullet point to place on your slide.

The point may have a C<href> attribute, a C<transition> attribute,
and a C<level> attribute. The C<level> attribute is still supported and defaults to 1.
However, it is recommended to use <list> tags to indicate nesting.
The level can go down as far as you please, though you might need to define bullets
with <bullet> in <metadata> for levels greater than 4.

The list optionally takes a flag, ordered="ordered", to indicate that the points
below should be numbered. <numbers> in <metadata> can be used to customize numbering
style.

=head2 <plain>

The <plain> tag denotes plain text to be put on the page without any bullet point. It takes an optional attribute C<align> with values "left", "center", or
"right".

=head2 <source-code> or <source_code>

The source-code tag identifies a piece of verbatim text in a fixed
font - originally designed for source code.

=head2 <image>

The image tag works in one of two ways. For backwards compatibility
it allows you to specify the URI of the image in the text content
of the tag:

  <image>foo.png</image>

Or for compatibility with SVG, you can use xlink:

  <image xlink:href="foo.png"
         xmlns:xlink="http://www.w3.org/1999/xlink"/>

By default, the image is placed centered in the current column
(which is the middle of the slide if you are not using tables) and
at the current text position. However you can override this using
x and y attributes for absolute positioning. You may also specify
a scale attribute to scale the image.

Scaling specifiers can look like this:

=over 4

=item * 0.5 (single float) denotes a scaling multiplier, 0.5 means "half size".
 The image's DPI value is correctly used.

=item * 1.5em (float + unit) denotes a fixed width/height. Supported units are:
'em', 'ex', 'pt', 'px', 'line', 'page'. ("M" height/width, "x" height/width,
points, pixels, line height/width, page height/width)

=item * 0.5*1.0 (two floats) denotes non-uniform scaling, in this case "half width, but full height"

=item * 1.5em*0.1line (likewise with units)

=back

The supported image formats are those supported by the underlying
pdflib library: gif, jpg, png and tiff.

=head2 <colour> or <color>

The colour tag specifies a colour for the text to be output. To define
the colour, either use the C<name> attribute, using one of the 16 HTML
named colours, or use the C<rgb> attribute and use a hex triplet
like you can in HTML.

=head2 <i>, <b> and <u>

Use these tags for italics, bold and underline within text.

=head2 <span style="...">

Using this tag, you can specify many text attributes in CSS syntax.

=head2 <table>

  <table>
    <row>
      <col width="40%">
      ...
      </col>
      <col width="60%">
      ...
      </col>
    </row>
  </table>

AxPoint has some rudimentary table support, as you can see above. This
is fairly experimental, and does not do any reflowing like HTML - it
only supports fixed column widths and only as percentages. Using a table
allows you to layout a slide in two columns, and also have multi-row
descriptions of source code with bullet points.

=head2 <box>

  <box x="450" y="250" width="150" height="200">
    <plain>Some content, as if this were a full page</plain>
  </box>

The box tag allows you to position arbitrary content anywhere on the page.
Coordinates are specified in PDF-points, i.e., (0,0) is at the bottom left,
and (612,450) is at the top right. Note that you may only specify
this tag at the top level of a slide, and it is recommended to use it before
or after all regular content of that page, but after the title. A slide
may contain any number of box tags, however, and they need not be at the same
place in the source. Note also that the height tag is effectively ignored -
there is no clipping.

=head2 <value>

  <value type="current-slide"/>
  <value type="today" format="%d.%m.%Y"/>

Inserts a special variable. The type attribute selects which one:
slideshow-title, slide-title, logo, background, today, current-slide, total-slides,
current-slideset, speaker, organisation, email, link.

Notes: The "logo" and "background" types insert the image as specified by the corresponding
 tag in <metadata>, using the same size, at the current text position. The
'today' type uses an additional 'format' attribute containing a sprintf() style
format string (optional). The total-slides tag is actually cheating - it reads
the value from the same named tag in <metadata>. This is useful if you have a
preprocessing step to insert the correct value. With all tags, you may encounter
problems if you use them outside of <title>, <point> or <plain>.

=head1 SVG Support

AxPoint has some SVG support so you can do vector graphics on your slides.
Note that the coordinate system is different from the regular coordinate system,
(0,0) is at the left top with positive y values going down, which makes it
easier to import graphics from external sources.

All SVG items allow the C<transition> attribute as defined above.

=head2 <rect>

  <rect x="100" y="100" width="300" height="200"
    style="stroke: blue; stroke-width=5; fill: red"/>

As you can see, AxPoint's SVG support uses CSS to define the style. The
above draws a rectangle with a thick blue line around it, and filled
in red.

=head2 <circle>

  <circle cx="50" cy="100" r="50" style="stroke: black"/>

=head2 <ellipse>

  <ellipse cx="100" cy="50" rx="30" ry="60" style="fill: aqua;"/>

=head2 <line>

  <line x1="50" y1="50" x2="200" y2="200" style="stroke: black;"/>

=head2 <text>

  <text x="200" y="200"
    style="stroke: black; fill: none; font: italic 24pt serif"
  >Some Floating Text</text>

This tag allows you to float text anywhere on the screen.

=head1 BUGS

Please use http://rt.cpan.org/ for reporting bugs.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

Copyright 2002.

=head1 LICENSE

This is free software, distributed under the same terms as Perl itself.

=cut
