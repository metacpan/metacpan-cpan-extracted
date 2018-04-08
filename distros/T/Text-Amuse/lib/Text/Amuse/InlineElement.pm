package Text::Amuse::InlineElement;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::InlineElement - Helper for Text::Amuse

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=head2 new(%args)

Constructor. Accepts the following named arguments (which are also
accessors)

=over 4

=item type

The element type

=item string

The raw string

=item last_position

The offset of the last character in the parsed string

=item tag

The name of the tag

=item fmt

C<ltx> or C<html>

=back

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                type => '',
                string => '',
                last_position => 0,
                tag => '',
                fmt => '',
               };
    foreach my $k (keys %$self) {
        if (defined $args{$k}) {
            $self->{$k} = $args{$k};
        }
        delete $args{$k};
    }
    die "Extra arguments passed %args" if %args;
    die "Missing type for <$self->{string}>" unless $self->{type};
    unless ($self->{fmt} eq 'ltx' or $self->{fmt} eq 'html') {
        die "Missing format $self->{fmt} for <$self->{string}>"
    }
    bless $self, $class;
}

sub type {
    my ($self, $type) = @_;
    if ($type) {
        $self->{type} = $type;
    }
    return $self->{type};
}

sub last_position {
    shift->{last_position};
}

sub string {
    shift->{string};
}

=head2 append($element)

Append the provided string to the self's one and update the
last_position.

=cut

sub append {
    my ($self, $element) = @_;
    $self->{string} .= $element->string;
    $self->{last_position} = $element->last_position;
}

sub tag {
    shift->{tag};
}

sub fmt {
    shift->{fmt};
}

=head2 stringify

Main method to get the desired output from the element.

=cut

sub stringify {
    my $self = shift;
    my $type = $self->type;
    my $string = $self->string;
    if ($type eq 'text') {
        if ($self->is_latex) {
            $string = $self->escape_tex($string);
            $string = $self->_ltx_replace_ldots($string);
            $string = $self->_ltx_replace_slash($string);
            return $string;
        }
        elsif ($self->is_html) {
            return $self->escape_all_html($string);
        }
        else {
            die "Not reached";
        }
    }
    if ($type eq 'safe') {
        return $self->verbatim_string($string);
    }
    if ($type eq 'verbatim') {
        if ($string =~ /\A<verbatim>(.*)<\/verbatim>\z/s) {
            $string = $1;
            return $self->verbatim_string($string);
        }
        else {
            die "<$string> doesn't match verbatim!";
        }
    }
    elsif ($type eq 'anchor') {
        my $anchor = $string;
        $anchor =~ s/[^A-Za-z0-9]//g;
        die "Bad anchor " . $string unless length($anchor);
        if ($self->is_latex) {
            return "\\hyperdef{amuse}{$anchor}{}\%\n";
        }
        elsif ($self->is_html) {
            return qq{<a id="text-amuse-label-$anchor" class="text-amuse-internal-anchor"><\/a>\n}
        }
        else {
            die "Not reached";
        }
    }
    elsif ($type eq 'open' or $type eq 'close') {
        my $out = $self->_markup_table->{$self->tag}->{$type}->{$self->fmt};
        die "Missing markup for $self->fmt $type $self->tag" unless $out;
        return $out;
    }
    elsif ($type eq 'nobreakspace') {
        if ($self->is_latex) {
            return '~';
        }
        elsif ($self->is_html) {
            return '&#160;'
        }
    }
    elsif ($type eq 'br') {
        if ($self->is_latex) {
            return "\\forcelinebreak ";
        }
        else {
            my $leading = '';
            if ($string =~ m/\A(\s+)/) {
                $leading = $1;
            }
            return "$leading<br />";
        }
    }
    elsif ($type eq 'bigskip') {
        if ($self->is_latex) {
            return "\n\\bigskip";
        }
        else {
            my $leading = '';
            if ($string =~ m/\A(\s+)/) {
                $leading = $1;
            }
            return "$leading<br />";
        }
    }
    elsif ($type eq 'verbatim_code') {
        # remove the prefixes
        warn qq{<code> is already verbatim! in "$string"\n} if $string =~ m{<verbatim>.+</verbatim>};
        if ($string =~ /\A=(.+)=\z/s) {
            $string = $1;
        }
        elsif ($string =~ /\A<code><verbatim>(.*)<\/verbatim><\/code>\z/s) {
            $string = $1;
        }
        elsif ($string =~ /\A<code>(.*)<\/code>\z/s) {
            $string = $1;
        }
        else {
            die "$string doesn't match the <code> pattern!";
        }
        if (length $string) {
            return $self->_markup_table->{code}->{open}->{$self->fmt}
              . $self->verbatim_string($string)
              . $self->_markup_table->{code}->{close}->{$self->fmt};
        }
        else {
            return '';
        }
    }
    else {
        die "Unrecognized type " . $type . " for " . $string;
    }
}

sub _markup_table {
    return {
            'em' => {
                     open => {
                              html => '<em>',
                              ltx => "\\emph{"
                             },
                     close => {
                               html => '</em>',
                               ltx => '}',
                              }
                    },
            'strong' => {
                         open => {
                                  html => '<strong>',
                                  ltx => "\\textbf{"
                                 },
                         close => {
                                   html => '</strong>',
                                   ltx => '}',
                                  }
                        },
            'code' => {
                       open => {
                                html => '<code>',
                                ltx => "\\texttt{",
                             },
                     close => {
                               html => '</code>',
                               ltx => '}',
                              }
                    },
            'strike' => {
                         open => {
                                  html => '<strike>',
                                  ltx => "\\sout{"
                                 },
                         close => {
                                   html => '</strike>',
                                   ltx => '}',
                                  }
                        },
            'del' => {
                      open => {
                               html => '<del>',
                               ltx => "\\sout{"
                             },
                     close => {
                               html => '</del>',
                               ltx => '}',
                              }
                    },
            'sup' => {
                     open => {
                              html => '<sup>',
                              ltx => "\\textsuperscript{"
                             },
                     close => {
                               html => '</sup>',
                               ltx => '}',
                              }
                    },
            'sub' => {
                      open => {
                               html => '<sub>',
                               ltx => "\\textsubscript{"
                             },
                     close => {
                               html => '</sub>',
                               ltx => '}',
                              }
                    },
           };
}

sub _ltx_replace_ldots {
    my ($self, $string) = @_;
    my $ldots = "\\dots{}";
    $string =~ s/\.{3,4}/$ldots/g ;
    $string =~ s/\x{2026}/$ldots/g;
    return $string;
}

sub _ltx_replace_slash {
    my ($self, $string) = @_;
    $string =~ s!/!\\Slash{}!g;
    return $string;
}

=head2 escape_all_html($string)

HTML escape

=cut

sub escape_all_html {
    my ($self, $string) = @_;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&#x27;/g;
    return $string;
}

=head2 escape_tex

Escape the string for LaTeX output

=cut

sub escape_tex {
    my ($self, $string) = @_;
    $string =~ s/\\/\\textbackslash{}/g;
    $string =~ s/#/\\#/g ;
    $string =~ s/\$/\\\$/g;
    $string =~ s/%/\\%/g;
    $string =~ s/&/\\&/g;
    $string =~ s/_/\\_/g ;
    $string =~ s/\{/\\{/g ;
    $string =~ s/\}/\\}/g ;
    $string =~ s/\\textbackslash\\\{\\\}/\\textbackslash{}/g;
    $string =~ s/~/\\textasciitilde{}/g ;
    $string =~ s/\^/\\^{}/g ;
    $string =~ s/\|/\\textbar{}/g;
    return $string;
}


=head2 is_latex

Shortcut to check if the format is latex

=head2 is_html

Shortcut to check if the format is html

=cut

sub is_latex {
    shift->fmt eq 'ltx';
}

sub is_html {
    shift->fmt eq 'html';
}

=head2 unroll

Convert the close_inline open_inline symbols (= and *) into elements
an open/close type and the tag properly set.

=cut

sub unroll {
    my $self = shift;
    my @new;
    my %map = (
               '=' => [qw/code/],
               '*' => [qw/em/],
               '**' => [qw/strong/],
               '***' => [qw/strong em/],
              );
    if ($self->type eq 'open_inline') {
        push @new, map { +{ type => 'open', tag => $_ } } @{$map{$self->tag}};
    }
    elsif ($self->type eq 'close_inline') {
        push @new, map { +{ type => 'close', tag => $_ } } reverse @{$map{$self->tag}};
    }
    else {
        die "unroll can be called only on close_inline/open_inline, not " . $self->type . " " . $self->string;
    }
    return map { __PACKAGE__->new(%$_, string => '', fmt => $self->fmt) } @new;
}

=head2 verbatim_string($string)

Escape the string according to the element format

=cut

sub verbatim_string {
    my ($self, $string) = @_;
    if ($self->is_latex) {
        return $self->escape_tex($string);
    }
    elsif ($self->is_html) {
        return $self->escape_all_html($string);
    }
    else {
        die "Not reached";
    }
}

1;
