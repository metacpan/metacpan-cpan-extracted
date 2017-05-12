package Text::Markdown::Slidy;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";
use parent 'Exporter';

our @EXPORT = qw/markdown split_markdown/;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub markdown {
    my ($self, $text) = @_;

    # Detect functional mode, and create an instance for this run
    unless (ref $self) {
        if ( $self ne __PACKAGE__ ) {
            my $ob = __PACKAGE__->new();
                                # $self is text, $text is options
            return $ob->markdown($self, $text);
        }
        else {
            croak('Calling ' . $self . '->markdown (as a class method) is not supported.');
        }
    }
    my @slides = $self->_sections($text);
    join "\n", @slides;
}

sub template {
    my $self = shift;

    $self->{template} ||= qq[<div class="slide">\n%s</div>\n];
}

sub md {
    my $self = shift;

    $self->{md} ||= do {
        require Text::Markdown;
        Text::Markdown->new;
    };
}

sub _process {
    my ($self, $slide_text) = @_;

    my $html  = $self->md->markdown($slide_text);
    sprintf $self->template, $html;
}

sub _sections {
    my ($self, $text) = @_;

    map {$self->_process($_)} split_markdown($text);
}

sub split_markdown {
    my $text = shift;
    $text =~ s/^\A\s+//ms;
    $text =~ s/\s+\z//ms;

    my @slides;
    my @slide_lines;
    my $prev;
    for my $line (split /\r?\n/, $text) {
        if ( $line =~ /^(?:(?:-+)|(?:=+))$/ && $prev) {
            pop @slide_lines;
            push @slides, join("\n", @slide_lines) if @slide_lines;
            @slide_lines = ($prev); # $prev is title;
        }
        push @slide_lines, $line;
        $prev = $line;
    }
    push @slides, join("\n", @slide_lines) if @slide_lines;

    @slides;
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Markdown::Slidy - Markdown converter for HTML slide tools

=head1 SYNOPSIS

    use Text::Markdown::Slidy;

    markdown(<<'MARKDOWN');
    Title1
    ======

    ## sub title
    abcde
    fg

    Title2
    ------
    hoge
    MARKDOWN
    # <div class="slide">
    # <h1>Title1</h1>
    # <h2>sub title<h2>
    #
    # <p>abcde
    # fg</p>
    # </div>
    #
    # <div class="slide">
    # <h2>Title2</h2>
    #
    # <p>hoge</p>
    # </div>

    # split markdown text to slide sections
    my @markdowns_per_section = split_markdown($markdown_text);

=head1 DESCRIPTION

Text::Markdown::Slidy is to convert markdown syntax to HTML slide tools.

=head1 METHODS

=head2 C<< $md = Text::Markdown::Slidy->new(%opt) >>

Constructor.

=head2 C<< $html_text = $md->markdown($markdown_text) >>

=head1 FUNCTIONS

=head2 C<< $html_text = markdown($markdown_text) >>

=head2 C<< @markdowns_per_section = split_markdown($markdown_text) >>

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

