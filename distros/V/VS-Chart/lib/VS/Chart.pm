package VS::Chart;

use strict;
use warnings;

use Cairo;
use Carp qw(croak);
use Scalar::Util qw(refaddr);

use VS::Chart::Dataset;
use VS::Chart::RowIterator;

our $VERSION = "0.08";

my %Datasets;
my %NextRow;
my %MaxCache;
my %MinCache;
my %SpanCache;

sub _clear_cache {
    my $self = shift;
    my $id = refaddr $self;

    delete $MaxCache{$id};
    delete $MinCache{$id};
    delete $SpanCache{$id};

    1;
}

sub new {
    my ($pkg, %attrs) = @_;
    
    my $defaults = 1 - (delete $attrs{no_defaults} || 0);
    
    my $self = bless {
        _defaults => $defaults,
        %attrs,
    }, $pkg;

    $Datasets{refaddr $self} = [];
    $NextRow{refaddr $self} = 0;
    
    return $self;
}

sub has {
    my ($self, $key) = @_;
    return exists $self->{$key};
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

sub set {
    my ($self, %attrs) = @_;
    
    while (my ($key, $value) = each %attrs) {
        if ($key eq 'min') {
            $self->_clear_cache;
            my $min = $self->_min;
            $self->{_min} = $value if $value < $min;
            next;
        }
        elsif ($key eq 'max') {
            $self->_clear_cache;
            my $max = $self->_max;
            $self->{_max} = $value if $value > $max;        
            next;
        }
        elsif ($key eq 'y_grid_steps') {
            $value = 1 if $value < 1;
            $value = 10 if $value > 10;
        }
    
        if ($key =~ /^(\d+)\s*:\s*(.*)$/) {
            my $id = $1;
            $key = $2;
            my $ds = $self->_dataset($id);
            if (defined $ds) {
                $ds->set($key => $value);
            }
        }
        else {
            $self->{$key} = $value;            
        }
    }
}

sub dataset {
    my ($self, $id) = @_;
    return $self->_dataset($id, 0);
}

sub _dataset {
    my ($self, $idx, $create) = @_;
    my $ptr = refaddr $self;
    return $Datasets{$ptr}->[$idx] if defined $Datasets{$ptr}->[$idx];
    return undef if !$create;
    
    $Datasets{$ptr}->[$idx] = VS::Chart::Dataset->new();
    
    return $self->_dataset($idx);
}

sub _datasets {
    my ($self) = @_;
    return $Datasets{refaddr $self};
};

sub rows {
    my ($self) = @_;
    
    return $NextRow{refaddr $self};
}

sub add {
    my ($self, @data) = @_;    
    
    my $id = refaddr $self;
    
    delete $self->{_max};
    delete $self->{_min};

    $self->_clear_cache;
    
    my $row = $self->rows;

    if (ref $data[0]) {
        $self->set(x_column => 1);
    }
    
    for (my $ds = 0; $ds < @data; $ds++) {
        my $dataset = $self->_dataset($ds, 1);
        $dataset->insert($row, $data[$ds]);
    }
    
    $NextRow{$id}++;
    
    1;
}

sub _max {
    my ($self) = @_;
    
    return $self->{_max} if exists $self->{_max};

    my $id = refaddr $self;
    return $MaxCache{$id} if exists $MaxCache{$id};
    
    my $datasets = $self->_datasets;
    return 0 unless @$datasets;

    my $x_column = $self->get("x_column") || 0;
    
    my $max = $datasets->[$x_column]->max;
    for (($x_column + 1)..@$datasets - 1) {
        my $ds_max = $datasets->[$_]->max;
        next if !defined $ds_max;
        $max = $ds_max if $ds_max > $max;
    }
    
    $MaxCache{$id} = $max;
    
    return $max;
}

sub _min {
    my ($self) = @_;
    
    return $self->{_min} if exists $self->{_min};

    my $id = refaddr $self;
    return $MinCache{$id} if exists $MinCache{$id};
    
    my $datasets = $self->_datasets;
    return 0 unless @$datasets;

    my $x_column = $self->get("x_column") || 0;
    my $min = $datasets->[$x_column]->min;
    for (($x_column + 1)..@$datasets - 1) {
        my $ds_min = $datasets->[$_]->min;
        next if !defined $ds_min;
        $min = $ds_min if $ds_min < $min;
    }
    
    $MinCache{$id} = $min;
    
    return $min;
}

sub _span {
    my ($self) = @_;

    my $id = refaddr $self;
    return $SpanCache{$id} if exists $SpanCache{$id};
    
    my $span = $self->_max - $self->_min;
    $SpanCache{$id} = $span;

    return $span;
}

sub _row_iterator {
    my ($self) = @_;
    my $x_column = $self->get("x_column") || 0;
    if ($x_column) {
        return VS::Chart::RowIterator->new($self->_dataset(0)->data);
    }
    return VS::Chart::RowIterator->new([1..$self->rows]);
}

sub _offset {
    my ($self, $value) = @_;
    
    if ($value < $self->_min || $value > $self->_max) {
        croak "Value '${value}' is outside value range (", $self->_min, ", ", $self->_max, ")"; 
    }

    return ($value - $self->_min) / $self->_span;
}

sub _offsets {
    my ($self, @values) = @_;
    
    my $min = $self->_min;
    my $span = $self->_span;

    for (@values) {
        $_ = ($_ - $min) / $self->_span;
    }
    
    return @values;
}

{
    use Module::Pluggable
        search_path => [qw(VS::Chart::Renderer)],
        require     => 1,
        sub_name    => 'renderers',
        inner       => 0;
    
    my %Renderer;
    BEGIN {
        for (__PACKAGE__->renderers) {
            if ($_->can("type")) {
                my $type = lc($_->type);
                $Renderer{$type} = $_;
            }
        }
    }
    
    sub supported_types {
        return sort keys %Renderer;
    }
    
    my %Create = (
        'png' => sub {
            my $self = shift;
            return Cairo::ImageSurface->create("argb32", $self->get("width"), $self->get("height"));
        },
        'svg' => sub {
            my ($self, $path) = @_;
            return Cairo::SvgSurface->create($path, $self->get("width"), $self->get("height"));
        },
        'pdf' => sub {
            my ($self, $path) = @_;
            return Cairo::PdfSurface->create($path, $self->get("width"), $self->get("height"));
        },
    );

    my %Save = (
        'png' => sub {
            my ($surface, $target) = @_;
            
            if (ref $target eq "CODE") {
                $surface->write_to_png_stream($target)
            }
            else {
                $surface->write_to_png($target);
            }
        },
        'svg' => sub {
        },
        'pdf' => sub {
        },
    );
    
    sub render {
        my ($self, %args) = @_;

        croak "Missing argument 'type'" if !exists $args{type};
        my $type = $args{type};
        croak "Unsupported chart type: $type" if !exists $Renderer{$type};

        croak "Missing argument 'to'" if !exists $args{to};
        my $to = $args{to};

        my $as;
        if (exists $args{as}) {
            $as = $args{as};
        }
        else {
            ($as) = $to =~ /\.(\w+)$/;
            $as = lc $as;
        }

        croak "Unsupported output: $as" if !exists $Create{$as};
        
        local $self->{width} = 640 unless $self->{width};
        local $self->{height} = 480 unless $self->{height};
        local $self->{width} = $args{width} if $args{width};
        local $self->{height} = $args{height} if $args{height};
            
        my $renderer        = $Renderer{$type}->new;
        my @default_keys    = $renderer->set_defaults($self);
        
        my $surface = $Create{$as}->($self, $to);
        $renderer->render($self, $surface);
        $Save{$as}->($surface, $to);
    }
}

1;
__END__

=head1 NAME

VS::Chart - Simple module to create beautifully looking charts

=head1 SYNOPSIS

 use VS::Chart;

 my $chart = VS::Chart->new;

 .. Add data to $chart here ...
 $chart->add(@row);

 $chart->render( type => "line", as => "png", to => "my_chart.png" );

=head1 PHILOSOPHY

=over 4

=item *

Simple interface

=item *

Defaults should look great

=item *

DWIW

=item *

Extendable implementation

=back

=head1 DESCRIPTION

This module produces charts from data. Such charts might be line, pie and boxes. Currently only 
linecharts are implemented. The renderer uses Cairo Graphics (L<http://www.cairographics/>), a
graphics library for creating vector graphics, to produce crisp and correct output. Currently 
we limit output support to PNG, PDF and SVG altho Cairo may support more.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( %ATTRIBUTES, [ no_defaults => 1 ] )
 
Creates a new chart definition and sets any attributes passed in I<%ATTRIBUTES>. 
If I<no_defaults> is specified the chart will not be populated with default values 
when rendered.

=item supported_types

Returns a list of supported renderers.

=back

=head2 INSTANCE METHODS

=over 4

=item set ( %ATTRIBUTES )

Sets a number of attributes. It is possible to set an attribute for a specific dataset by prepending the key 
with E<lt>column<gt>:. Columns starts at 0.

=item get ( ATTRIBUTE )

Get the value of an attribute.

=item has ( ATTRIBUTE )

Check if an attribute exists.

=item add ( @ROW )

Adds the data in I<@ROW> to the chart. If the first element is a I<Date::Simple> object the first column will be 
marked as the index column provider and sorted accordingly when rendered.

=item render ( type => TYPE, to => PATH | CODE, [ as => FORMAT ] )

Renders the chart using the renderer specified by I<TYPE> and saves the 
output as I<PATH>. By default the I<FORMAT> is B<png> but B<pdf> or B<svg> may
be used instead.

If the format is B<png> it's possible to pass a CODE reference instead of a path in I<to>. This will be called 
with the reference itself as the first argument and data as second. It may be called several times during rendering.

=item dataset ( COLUMN )

Returns the C<VS::Chart::Dataset>-instance representing the data for the given column. Return undef 
if no such column has been added yet via add.

=item rows

Returns the number of rows of data added to the chart.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-vs-chart@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 SUPPORT

Commercial support is available from Versed Solutions. Contact author for details.

=head1 AUTHOR

Claes Jakobsson, Versed Solutions C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2008, Versed Solutions C<< <info@versed.se> >>. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
