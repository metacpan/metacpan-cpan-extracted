package HTML::HTPL::Graph;

use HTML::HTPL::Table;
use HTML::HTPL::Lib;
use HTML::HTPL::Sys qw(call);
use strict;

sub new {
    my $self = {};
    bless $self, shift;
    $self->set(@_);
    $self;
}

sub set {
    my $self = shift;
    my %hash = @_;
    foreach (keys %hash) {
        $self->{lc($_)} = $hash{$_};
    }
}

sub astable {
    my $self = shift;
    my @data;
    my @labels = @{$self->{'labels'}};
    my $dataref = $self->{'data'};
    if (UNIVERSAL::isa($dataref, 'ARRAY')) {
        @data = @$dataref;
    } elsif (UNIVERSAL::isa($dataref, 'HASH')) {
        my $label;
        my @vector;
        @data = ();
        while (keys %$dataref) {
            foreach (keys %$dataref) {
                push(@vector, shift @{$dataref->{$_}});
                delete($dataref->{$_}) if (!@{$dataref->{$_}});
            }
            push(@data, \@vector);
        }
    }
    my $ref = $self->{'dual'};
    if (UNIVERSAL::isa($ref, 'HASH')) {
        $ref = [ %$ref ];
    }
    if (UNIVERSAL::isa($ref, 'ARRAY')) {
        my @pairs = @$ref;
        @data = ();
        @labels = ();
        foreach (@pairs) {
            push(@data, $_->[1]);
            push(@labels, $_->[0]);
        }
    }
    return unless (@data);
    my $max = &mymax(@data) || 1;
    my $cols = $self->{'cols'};
    my $width = $self->{'width'} || 400;
    my $unit = $max / $cols if ($cols);


    my @colors = @{$self->{'colors'}};
    unless (@colors) {
        my $item = $data[0];
        my $card = scalar(@$item);
        my $c;
        @colors = map {'#' . sprintf("%02x%02x%02x", 
          $c = int(0xFF * ($_ - 1) / $card), $c, $c);} (1 .. $card);
    }
    my $textcol = $self->{'text'};
    my $disp = ($textcol ? sub 
           {return qq!&nbsp;<FONT COLOR="$textcol">$_</FONT>!;}
                  : sub {return "&nbsp;$_";});
    my $gif = $self->{'gif'} || 'pixel.gif';
    my $draw = $self->{'draw'} || sub {return qq!<IMG SRC="$gif" WIDTH=$_ HEIGHT=1>!;};
    my $fmt = $self->{'fmt'} || "%d";
    my $cfmt = (UNIVERSAL::isa($fmt, 'CODE') ? $fmt :
             sub {return sprintf($fmt, $_);});
    my $i;


    my $table = new HTML::HTPL::Table('cols' => 2);
    if ($cols) {
        my $ct = new HTML::HTPL::Table('cellpadding' => 0, 'border' => 0,
         'width' => $width, 'cellspacing' => 0, 'cols' => $cols);
        my $w = $width / $cols;
        my ($x, @v);
        foreach $x (1 .. $cols) {
            push(@v, {'data' => &call($cfmt, (($x - 1) / $cols * $max)),
                      'cattr' => {'width' => $w}});
        }
        my $el = pop @v;
        my $tiny = new HTML::HTPL::Table('cellspacing' => 0, 'border' => 0,
              'cellpadding' => 0, 'cols' => 2, 'width' => $w);
        my $el2 = {'data' => &call($cfmt, $max), 
             'cattr' => {'align' => 'right'}};
        $tiny->add($el->{'data'}, $el2);
        push(@v, {'data' => $tiny->ashtml, 'cattr' => {'width' => $w}});
        $ct->add(@v);
        $table->add(['&nbsp;', $ct->ashtml]);
    }
    foreach $i ((0 .. $#data)) {
        my @these;
        if (UNIVERSAL::isa($data[$i], 'ARRAY')) {
            my @cols = @colors;
            my (@dat, $datum);
            foreach $datum (@{$data[$i]}) {
                my $col = shift @cols;
                push(@cols, $col);
                push(@dat, [$datum, $col]);
            }
            @these = sort {$a->[0] <=> $b->[0]} @dat;
        } else {
            my $col = shift @colors;
            push(@colors, $col);
            @these = ([$data[$i], $col]);
        }

        my (@cells, @cells2);
        my $tillnow = 0;
        my $datum;
        foreach (@these) {
            my ($datum, $col) = @$_;
            my $this = int($datum * $width / $max);
            if ($this > $tillnow) {
                push(@cells, {'data' => &call($draw, $this - $tillnow,), 
                       'cattr' => {'bgcolor' => $col}});
                $tillnow = $this;
            }
        }
        my $row = new HTML::HTPL::Table('cellpadding' => 0,
                          'cellspacing' => 0, 'border' => 0,
                          'cols' => $#cells + 2);

        $row->add(@cells, &call($disp, &call($cfmt, $datum)));
        $table->add([&call($disp, $labels[$i]), $row->ashtml]);
        
    }
    my @legend = @{$self->{'legend'}};
    if (@legend) {
        my @cols = @colors;
        my @cells = ();
        my @cells2 = ();
        my $per = int(100 / scalar(@legend));
        foreach (@legend) {
            my $col = shift @colors;
            push(@cells, {'cattr' => {'bgcolor' => $col, 
                   'width' => "$per%"},
                   'data' => qq!<FONT COLOR="$textcol">$_</FONT>!});
            push(@cells2, {'cattr' => {'width' => "$per%"},
                   'data' => qq!<FONT COLOR="$col">$_</FONT>!});
        }
        my $legend = new HTML::HTPL::Table('cols' => scalar(@legend),
               'border' => 2, 'width' => $width, 'cellpadding' => 2);
        $legend->add(@cells);
        $legend->add(@cells2);
        $table->add("&nbsp;", $legend->ashtml);
    }
    $table;
}

sub ashtml {
    my $self;
    my $table = $self->astable || return undef;
    $table->ashtml;
}

sub mymax {
    if (!$#_) {
        return &mymax(@{$_[0]}) if (UNIVERSAL::isa($_[0], 'ARRAY'));
        return $_[0];
    }
    my $start = &mymax(shift);
    foreach (@_) {
        my $val = &mymax($_);
        $start = $val if ($val > $start);
    }
    $start;
}

1;
