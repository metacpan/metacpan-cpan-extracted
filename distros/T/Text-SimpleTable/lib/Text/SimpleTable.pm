# Copyright (C) 2005-2010, Sebastian Riedel.

package Text::SimpleTable;

use strict;
use warnings;

our $VERSION = '2.07';

our %ASCII_BOX = (
	# Top
	TOP_LEFT      => '.-',
	TOP_BORDER    => '-',
	TOP_SEPARATOR => '-+-',
	TOP_RIGHT     => '-.',

	# Middle
	MIDDLE_LEFT      => '+-',
	MIDDLE_BORDER    => '-',
	MIDDLE_SEPARATOR => '-+-',
	MIDDLE_RIGHT     => '-+',

	# Left
	LEFT_BORDER  => '| ',
	SEPARATOR    => ' | ',
	RIGHT_BORDER => ' |',

	# Bottom
	BOTTOM_LEFT      => "'-",
	BOTTOM_SEPARATOR => "-+-",
	BOTTOM_BORDER    => '-',
	BOTTOM_RIGHT     => "-'",

	# Wrapper
	WRAP => '-',
);

our %UTF_BOX = (
	# Top
	TOP_LEFT      => "\x{250c}\x{2500}",
	TOP_BORDER    => "\x{2500}",
	TOP_SEPARATOR => "\x{2500}\x{252c}\x{2500}",
	TOP_RIGHT     => "\x{2500}\x{2510}",

	# Middle
	MIDDLE_LEFT      => "\x{251c}\x{2500}",
	MIDDLE_BORDER    => "\x{2500}",
	MIDDLE_SEPARATOR => "\x{2500}\x{253c}\x{2500}",
	MIDDLE_RIGHT     => "\x{2500}\x{2524}",

	# Left
	LEFT_BORDER  => "\x{2502} ",
	SEPARATOR    => " \x{2502} ",
	RIGHT_BORDER => " \x{2502}",

	# Bottom
	BOTTOM_LEFT      => "\x{2514}\x{2500}",
	BOTTOM_SEPARATOR => "\x{2500}\x{2534}\x{2500}",
	BOTTOM_BORDER    => "\x{2500}",
	BOTTOM_RIGHT     => "\x{2500}\x{2518}",

	# Wrapper
	WRAP => '-',
);

sub new {
    my ($class, @args) = @_;

    # Instantiate
    $class = ref $class || $class;
    my $self = bless {}, $class;

    $self->{chs} = \%ASCII_BOX;

    # Columns and titles
    my $cache = [];
    my $max   = 0;
    for my $arg (@args) {
        my $width;
        my $name;

        if (ref $arg) {
            $width = $arg->[0];
            $name  = $arg->[1];
        }
        else { $width = $arg }

        # Fix size
        $width = 2 if $width < 2;

        # Wrap
        my $title = $name ? $self->_wrap($name, $width) : [];

        # Column
        my $col = [$width, [], $title];
        $max = @{$col->[2]} if $max < @{$col->[2]};
        push @$cache, $col;
    }

    # Padding
    for my $col (@$cache) {
        push @{$col->[2]}, '' while @{$col->[2]} < $max;
    }
    $self->{columns} = $cache;

    return $self;
}

# The implementation is not very elegant, but gets the job done very well
sub draw {
    my $self = shift;

    # Shortcut
    return unless $self->{columns};

    my $rows    = @{$self->{columns}->[0]->[1]} - 1;
    my $columns = @{$self->{columns}} - 1;
    my $output  = '';

    # Top border
    for my $j (0 .. $columns) {

        my $column = $self->{columns}->[$j];
        my $width  = $column->[0];
        my $text   = $self->{chs}->{TOP_BORDER} x $width;

        if (($j == 0) && ($columns == 0)) {
            $text = "$self->{chs}->{TOP_LEFT}$text$self->{chs}->{TOP_RIGHT}";
        }
        elsif ($j == 0)        { $text = "$self->{chs}->{TOP_LEFT}$text$self->{chs}->{TOP_SEPARATOR}" }
        elsif ($j == $columns) { $text = "$text$self->{chs}->{TOP_RIGHT}" }
        else                   { $text = "$text$self->{chs}->{TOP_SEPARATOR}" }

        $output .= $text;
    }
    $output .= "\n";

    my $title = 0;
    for my $column (@{$self->{columns}}) {
        $title = @{$column->[2]} if $title < @{$column->[2]};
    }

    if ($title) {

        # Titles
        for my $i (0 .. $title - 1) {

            for my $j (0 .. $columns) {

                my $column = $self->{columns}->[$j];
                my $width  = $column->[0];
                my $text   = $column->[2]->[$i] || '';

                $text .= " " x ($width - _length($text));

                if (($j == 0) && ($columns == 0)) {
                    $text = "$self->{chs}->{LEFT_BORDER}$text$self->{chs}->{RIGHT_BORDER}";
                }
                elsif ($j == 0) { $text = "$self->{chs}->{LEFT_BORDER}$text$self->{chs}->{SEPARATOR}" }
                elsif ($j == $columns) { $text = "$text$self->{chs}->{RIGHT_BORDER}" }
                else                   { $text = "$text$self->{chs}->{SEPARATOR}" }

                $output .= $text;
            }

            $output .= "\n";
        }

        # Title separator
        $output .= $self->_draw_hr;

    }

    # Rows
    for my $i (0 .. $rows) {

        # Check for hr
        if (!grep { defined $self->{columns}->[$_]->[1]->[$i] } 0 .. $columns)
        {
            $output .= $self->_draw_hr;
            next;
        }

        for my $j (0 .. $columns) {

            my $column = $self->{columns}->[$j];
            my $width  = $column->[0];
            my $text = (defined $column->[1]->[$i]) ? $column->[1]->[$i] : '';

            $text .= " " x ($width - _length($text));

            if (($j == 0) && ($columns == 0)) {
                $text = "$self->{chs}->{LEFT_BORDER}$text$self->{chs}->{RIGHT_BORDER}";
            }
            elsif ($j == 0)        { $text = "$self->{chs}->{LEFT_BORDER}$text$self->{chs}->{SEPARATOR}" }
            elsif ($j == $columns) { $text = "$text$self->{chs}->{RIGHT_BORDER}" }
            else                   { $text = "$text$self->{chs}->{SEPARATOR}" }

            $output .= $text;
        }

        $output .= "\n";
    }

    # Bottom border
    for my $j (0 .. $columns) {

        my $column = $self->{columns}->[$j];
        my $width  = $column->[0];
        my $text   = $self->{chs}->{BOTTOM_BORDER} x $width;

        if (($j == 0) && ($columns == 0)) {
            $text = "$self->{chs}->{BOTTOM_LEFT}$text$self->{chs}->{BOTTOM_RIGHT}";
        }
        elsif ($j == 0) { $text = "$self->{chs}->{BOTTOM_LEFT}$text$self->{chs}->{BOTTOM_SEPARATOR}" }
        elsif ($j == $columns) { $text = "$text$self->{chs}->{BOTTOM_RIGHT}" }
        else                   { $text = "$text$self->{chs}->{BOTTOM_SEPARATOR}" }

        $output .= $text;
    }

    $output .= "\n";

    return $output;
}

sub boxes {
    my $self = shift;

    $self->{chs} = \%UTF_BOX;

    return $self;
}

sub hr {
    my $self = shift;

    for (0 .. @{$self->{columns}} - 1) {
        push @{$self->{columns}->[$_]->[1]}, undef;
    }

    return $self;
}

sub row {
    my ($self, @texts) = @_;
    my $size = @{$self->{columns}} - 1;

    # Shortcut
    return $self if $size < 0;

    for (1 .. $size) {
        last if $size <= @texts;
        push @texts, '';
    }

    my $cache = [];
    my $max   = 0;

    for my $i (0 .. $size) {

        my $text   = shift @texts;
        my $column = $self->{columns}->[$i];
        my $width  = $column->[0];
        my $pieces = $self->_wrap($text, $width);

        push @{$cache->[$i]}, @$pieces;
        $max = @$pieces if @$pieces > $max;
    }

    for my $col (@{$cache}) { push @{$col}, '' while @{$col} < $max }

    for my $i (0 .. $size) {
        my $column = $self->{columns}->[$i];
        my $store  = $column->[1];
        push @{$store}, @{$cache->[$i]};
    }

    return $self;
}

sub _draw_hr {
    my $self    = shift;
    my $columns = @{$self->{columns}} - 1;
    my $output  = '';

    for my $j (0 .. $columns) {

        my $column = $self->{columns}->[$j];
        my $width  = $column->[0];
        my $text   = $self->{chs}->{MIDDLE_BORDER} x $width;

        if (($j == 0) && ($columns == 0)) {
            $text = "$self->{chs}->{MIDDLE_LEFT}$text$self->{chs}->{MIDDLE_RIGHT}";
        }
        elsif ($j == 0) { $text = "$self->{chs}->{MIDDLE_LEFT}$text$self->{chs}->{MIDDLE_SEPARATOR}" }
        elsif ($j == $columns) { $text = "$text$self->{chs}->{MIDDLE_RIGHT}" }
        else                   { $text = "$text$self->{chs}->{MIDDLE_SEPARATOR}" }
        $output .= $text;
    }

    $output .= "\n";

    return $output;
}

# Calc display width of utf8 on/off strings
sub _length {
    if (utf8::is_utf8($_[0])) {
        my $code = do {
            local @_;
            if ($Unicode::GCString::VERSION or eval "require Unicode::GCString; 1") {
                sub { utf8::is_utf8($_[0]) ? Unicode::GCString->new($_[0])->columns : length $_[0] };
            }
            elsif ($Text::VisualWidth::VERSION or eval "require Text::VisualWidth::UTF8; 1") {
                sub { utf8::is_utf8($_[0]) ? Text::VisualWidth::UTF8::width($_[0]) : length $_[0] };
            }
            elsif ($Text::VisualWidth::PP::VERSION or eval "require Text::VisualWidth::PP; 1") {
                sub { utf8::is_utf8($_[0]) ? Text::VisualWidth::PP::width($_[0]) : length $_[0] };
            }
            else {
                sub { length $_[0] };
            }
        };

        no strict 'refs';
        no warnings 'redefine';
        *{"Text::SimpleTable::_length"} = $code;
        goto $code;
    }

    return length $_[0];
}

# Wrap text
sub _wrap {
    my ($self, $text, $width) = @_;

    my @cache;
    my @parts = split "\n", $text;
    my $chs_width = _length($self->{chs}->{WRAP});

    for my $part (@parts) {

        while (_length($part) > $width) {
            my $subtext;
            unless (utf8::is_utf8($part)) {
                $subtext = substr $part, 0, $width - $chs_width, '';
            }
            else {
                my $subtext_width = $width - $chs_width;
                my $substr_len;
                while (($substr_len = _length(substr $part, 0, $subtext_width)) > $width - $chs_width) {
                    --$subtext_width;
                }
                $subtext = substr $part, 0, $subtext_width, '';
            }
            push @cache, "$subtext$self->{chs}->{WRAP}";
        }

        push @cache, $part if defined $part;
    }

    return \@cache;
}

1;
__END__

=encoding utf8

=head1 NAME

Text::SimpleTable - Simple Eyecandy ASCII Tables

=head1 SYNOPSIS

    use Text::SimpleTable;

    my $t1 = Text::SimpleTable->new(5, 10);
    $t1->row('foobarbaz', 'yadayadayada');
    print $t1->draw;

    .-------+------------.
    | foob- | yadayaday- |
    | arbaz | ada        |
    '-------+------------'

    my $t2 = Text::SimpleTable->new([5, 'Foo'], [10, 'Bar']);
    $t2->row('foobarbaz', 'yadayadayada');
    $t2->row('barbarbarbarbar', 'yada');
    print $t2->draw;

    .-------+------------.
    | Foo   | Bar        |
    +-------+------------+
    | foob- | yadayaday- |
    | arbaz | ada        |
    | barb- | yada       |
    | arba- |            |
    | rbar- |            |
    | bar   |            |
    '-------+------------'

    my $t3 = Text::SimpleTable->new([5, 'Foo'], [10, 'Bar']);
    $t3->row('foobarbaz', 'yadayadayada');
    $t3->hr;
    $t3->row('barbarbarbarbar', 'yada');
    print $t3->draw;

    .-------+------------.
    | Foo   | Bar        |
    +-------+------------+
    | foob- | yadayaday- |
    | arbaz | ada        |
    +-------+------------+
    | barb- | yada       |
    | arba- |            |
    | rbar- |            |
    | bar   |            |
    '-------+------------'

    print $t3->boxes->draw;

    ┌───────┬────────────┐
    │ Foo   │ Bar        │
    ├───────┼────────────┤
    │ foob- │ yadayaday- │
    │ arbaz │ ada        │
    ├───────┼────────────┤
    │ barb- │ yada       │
    │ arba- │            │
    │ rbar- │            │
    │ bar   │            │
    └───────┴────────────┘

=head1 DESCRIPTION

Simple eyecandy ASCII tables.

=head1 METHODS

L<Text::SimpleTable> implements the following methods.

=head2 C<new>

    my $t = Text::SimpleTable->new(5, 10);
    my $t = Text::SimpleTable->new([5, 'Col1', 10, 'Col2']);

=head2 C<draw>

    my $ascii = $t->draw;

=head2 C<hr>

    $t = $t->hr;

=head2 C<row>

    $t = $t->row('col1 data', 'col2 data');

=head2 C<boxes>

    $t = $t->boxes;

C<boxes> switches the output generated by C<draw> to use the unicode box drawing characters. The last 
example above may not render nicely on some devices. 

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>.

=head1 MAINTAINER

Marcus Ramberg C<mramberg@cpan.org>.

=head1 CREDITS

In alphabetical order:

Brian Cassidy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010, Sebastian Riedel.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
