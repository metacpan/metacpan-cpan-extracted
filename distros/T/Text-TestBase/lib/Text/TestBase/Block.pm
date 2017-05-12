package Text::TestBase::Block;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    ro => [qw/name description/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
        _section_order => [],
        %args
    }, $class;
}

sub has_section {
    my ($self, $key) = @_;
    return exists($self->{_value_map}->{$key});
}

sub get_section {
    my ($self, $key) = @_;
    my $value = $self->{_value_map}->{$key};
    return undef unless defined $value;
    return wantarray ? @$value : $value->[0];
}

sub get_sections {
    my ($self, $key) = @_;
    map { $self->{_value_map}->{$_} } $self->get_section_names();
}

sub get_section_names {
    my ($self, $key) = @_;
    @{$self->{_section_order}};
}

sub get_filter {
    my ($self, $key) = @_;
    $self->{_filter_map}->{$key};
}

sub get_lineno {
    my $self = shift;
    return $self->{_lineno};
}

sub push_section {
    my ($self, $key, $value, $filters) = @_;
    $self->{_filter_map}->{$key} = $filters;
    $self->{_value_map}->{$key} = [$value];
    push @{$self->{_section_order}}, $key;
}

sub set_section {
    my ($self, $key, @values) = @_;
    $self->{_value_map}->{$key} = [@values];
}

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ s/.*:://;
    my $self = shift;
    return if $AUTOLOAD eq 'DESTROY';
    unless ($self->has_section($AUTOLOAD)) {
        Carp::croak("There is no $AUTOLOAD' section in the block.");
    }
    $self->get_section($AUTOLOAD);
}

1;
__END__

=head1 NAME

Text::TestBase::Block - Block object for Text::TestBase

=head1 METHODS

=over 4

=item $block->has_section(): Bool

=item $block->get_section($section_name: Str) : Str

Get a section body by $section_name.

=item $block->get_sections() : List of Str

Get a list of sections in arrayref.

=item $block->get_filter($section_name: Str) : ArrayRef[Str]

Get a filter list for $section_name.

=back
