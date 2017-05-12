package HTML::HTPL::Select;
use HTML::HTPL::Lib;
use strict;

sub new {
    my $class = shift;
    my $self = {'name' => shift, &HTML::HTPL::Sys::safetags(@_), 'rows' => []};
    bless $self, $class;
}

sub add {
    my ($self) = shift;
    while (@_) {
        my $key = shift;
        my $value = (shift) || $key;
        push(@{$self->{'rows'}}, [$value, $key]);
    }
}

sub adddefault {
    my ($self, $key, $value) = @_;
    $value ||= $key;
    push(@{$self->{'rows'}}, [$key, $value]);
    $self->default($key);
}

sub default {
    my ($self, $key) = @_;
    return $self->{'default'} unless(defined($key));
    $self->{'default'} = $key;
}

sub set {
    my ($self) = @_;
    while (@_) {
        my $prop = lc(shift);
        my $val = shift;
        $self->{$prop} = $val;
    }
}

sub ashtml {
    my $self = shift;
    my $attr;
    $attr = " MULTIPLE" if ($self->{'multi'});
    my $rows = $self->{'size'};
    $rows = scalar(@{$self->{'rows'}}) if ($rows < 0);
    $attr .= " SIZE=$rows" if ($rows > 1);
    $attr = substr($attr, 1);
    my $name = $self->{'name'};
    my $default = $self->{'default'};
    my $hash = {'name' => $name, 'attr' => $attr, 'noout' => 1};
    $hash->{'default'} = $default if ($default);
    my @elems = map {@$_;} @{$self->{'rows'}};
    HTML::HTPL::Lib::html_selectbox($hash, @elems);
}

1;
