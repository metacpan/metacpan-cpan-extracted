package HTML::HTPL::Template;

use HTML::HTPL::Lib;
use HTML::HTPL::Result;
use strict;

sub new {
    my ($class, $filename, $delim) = @_;
    my $text;
    if (UNIVERSAL::isa($filename, 'SCALAR')) {
        $text = $$filename;
    } elsif (UNIVERSAL::isa($filename, 'GLOB')) {
        $text = join("", <$filename>);
        close($filename);
    } else {
        $text = &HTML::HTPL::Lib::readfile($filename);
    }
    bless {'template' => $text, 'vars' => {},
            'delim' => $delim || '#'}, $class;
}

sub vars {
    my ($self, %hash) = @_;

    foreach (keys %hash) {
        $self->{'vars'}->{$_} = $hash{$_};
    }
}

sub zap {
    my $self = shift;
    $self->{'vars'} = {};
}

sub fromresult {
    my ($self, $key, $result) = @_;
    $self->{'vars'}->{$key} = [$result->structured];
}

sub ashtml {
    my $self = shift;
    &HTML::HTPL::Lib::subhash($self->{'template'}, $self->{'delim'},
                       %{$self->{'vars'}});
}

sub asstring {
    my $self = shift;
    $self->ashtml(@_);
}

1;
