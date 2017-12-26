package Text::Amuse::Beamer;
use strict;
use warnings;
use utf8;
# use Data::Dumper;

=head1 NAME

Text::Amuse::Beamer - Beamer output for Text::Amuse

=head1 DESCRIPTION

Parse the L<Text::Amuse::Output> LaTeX result and convert it to a
beamer documentclass body, wrapping the text into frames.

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head1 METHODS

=head2 new(latex => \@latex_chunks)

=head2 latex

Accessor to the latex arrayref passed at the constructor.

=head2 process

Return the beamer body as a string.

=cut

sub new {
    my ($class, %args) = @_;
    die "Missing latex" unless $args{latex};
    my $self = { latex => [ @{$args{latex}} ] };
    bless $self, $class;
}

sub latex {
    return shift->{latex};
}

sub process {
    my $self = shift;
    my $latex = $self->latex;
    my @out;
    # these chunks correspond to the various elements found, so if
    # it's an heading, it's guaranteed to be this way.

    my ($in_frame, $in_text, @current, $current_title);
    # print Dumper($latex);
    foreach my $piece (@$latex) {
        $piece =~ s/\\footnoteB?\{/\\footnote[frame]{/g;
        if ($piece =~ /\A\s*\\(
                           part|
                           chapter|
                           section|
                           subsection|
                           subsubsection)
                       (\[\{(.+)\}\])?
                       ({(.+)}\s*\z)
                      /x) {
            my $type = $1;
            $in_frame = $3 || $5;
            if (@current) {
                push @out, { title => $current_title || '',
                             body => [@current] };
                @current = ();
            }
            push @out, "\\" . $type . '{' . $in_frame . '}' . "\n\n";
            $current_title = $in_frame;
        }
        elsif (defined $in_frame) {
            push @current, $piece;
        }
    }
    # flush;
    if ($in_frame && @current) {
        push @out, { title => $current_title,
                     body => [@current] };
    }
    return $self->_render(\@out);
}

sub _render {
    my ($self, $list) = @_;
    my @out;
  ELEMENT:
    foreach my $el (@$list) {
        if (ref($el)) {
            my $body = join('', @{$el->{body}});
            if ($body =~ m/^%\s+no\s*slides?\s*$/im) {
                # and remove the previous element with the chapter
                pop @out if @out;
                next ELEMENT;
            }
            push @out, "\n\\begin{frame}[fragile]{$el->{title}}\n", $body,
              "\\end{frame}\n\n";
        }
        else {
            push @out, $el;
        }
    }
    if (@out) {
        return join('', @out);
    }
    else {
        return '';
    }
}


1;
