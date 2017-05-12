package Text::Amuse::Element;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::Element - Helper for Text::Amuse

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=head3 new($string)

Constructor. Accepts a string to be parsed

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                rawline => '',
                block => '',      # the block it says to belog
                type => 'null', # the type
                string => '',      # the string
                removed => '', # the portion of the string removed
                attribute => '', # optional attribute for desclists
                indentation => 0,
                attribute_type => '',
                style => 'X',
               };
    my %provided;
    foreach my $accessor (keys %$self) {
        if (exists $args{$accessor} and defined $args{$accessor}) {
            $self->{$accessor} = $args{$accessor};
            $provided{$accessor} = 1;
        }
    }
    unless ($provided{indentation}) {
        $self->{indentation} = length($self->{removed});
    }
    bless $self, $class;
}

=head3 rawline

Accessor to the raw input line

=cut

sub rawline {
    my $self = shift;
    return $self->{rawline};
}

sub _reset_rawline {
    my ($self, $line) = @_;
    $self->{rawline} = $line;
}

=head3 will_not_merge

Attribute to mark if an element cannot be further merged

=cut

sub will_not_merge {
    my ($self, $arg) = @_;
    if (defined $arg) {
        $self->{_will_not_merge} = $arg;
    }
    return $self->{_will_not_merge};
}

=head2 ACCESSORS

The following accessors set the value if an argument is provided. 

=head3 block

The block the string belongs

=cut

sub block {
    my $self = shift;
    if (@_) {
        $self->{block} = shift;
    }
    return $self->{block} || $self->type;
}

=head3 type

The type

=cut

sub type {
    my $self = shift;
    if (@_) {
        $self->{type} = shift;
    }
    return $self->{type};
}

=head3 string

The string (without the indentation or the leading markup)

=cut

sub string {
    my $self = shift;
    if (@_) {
        $self->{string} = shift;
    }
    return $self->{string};
}

=head3 removed

The portion of the string stripped out

=cut

sub removed {
    my $self = shift;
    if (@_) {
        die "Read only attribute!";
    }
    return $self->{removed};
}

=head3 style

The block style. Default to C<X>, read only. Used for aliases of tags,
when closing it requires a matching style.

=cut

sub style {
    my $self = shift;
    die "Read only attribute!" if @_;
    return $self->{style};
}

=head3 indentation

The indentation level, as a numerical value

=cut

sub indentation {
    return shift->{indentation};
}


=head2 attribute

Accessor to attribute

=cut

sub attribute {
    return shift->{attribute};
}

=head2 attribute_type

Accessor to attribute_type

=cut

sub attribute_type {
    return shift->{attribute_type};
}

=head2 HELPERS

=head3 is_start_block($blockname)

Return true if the element is a "startblock" of the required block name

=cut

sub is_start_block {
    my $self = shift;
    my $block = shift || "";
    if ($self->type eq 'startblock' and $self->block eq $block) {
        return 1;
    } else {
        return 0;
    }
}

=head3 is_stop_element($element)

Return true if the element is a matching stopblock for the element
passed as argument.

=cut

sub is_stop_element {
    my ($self, $element) = @_;
    if ($element and
        $self->type eq 'stopblock' and
        $self->block eq $element->type and
        $self->style eq $element->style) {
        return 1;
    }
    else {
        return 0;
    }
}

=head3 is_regular_maybe

Return true if the element is "regular", i.e., it just have trailing
white space

=cut

sub is_regular_maybe {
    my $self = shift;
    if ($self->type eq 'li' or
        $self->type eq 'null' or
        $self->type eq 'regular') {
        return 1;
    } else {
        return 0;
    }
}

=head3 can_merge_next 

Return true if the element will merge the next one

=cut

sub can_merge_next {
    my $self = shift;
    return 0 if $self->will_not_merge;
    if ($self->type eq 'stopblock'  or
        $self->type eq 'startblock' or
        $self->type eq 'null'       or
        $self->type eq 'table'      or
        $self->type eq 'newpage'    or
        $self->type eq 'comment') {
        return 0;
    } else {
        return 1;
    }
}

=head3 can_be_merged 

Return true if the element will merge the next one. Only regular strings.

=cut

sub can_be_merged {
    my $self = shift;
    return 0 if $self->will_not_merge;
    if ($self->type eq 'regular' or $self->type eq 'verse') {
        return 1;
    }
    else {
        return 0;
    }
}

=head3 can_be_in_list

Return true if the element can be inside a list

=cut 

sub can_be_in_list {
    my $self = shift;
    if ($self->type eq 'li' or
        $self->type eq 'null', or
        $self->type eq 'regular') {
        return 1;
    } else {
        return 0;
    }
}

=head3 can_be_regular

Return true if the element is quote, center, right

=cut

sub can_be_regular {
    my $self = shift;
    return 0 unless $self->type eq 'regular';
    if ($self->block eq 'quote' or
        $self->block eq 'center' or
        $self->block eq 'right') {
        return 1;
    }
    else {
        return 0;
    }
}


=head3 should_close_blocks

=cut

sub should_close_blocks {
    my $self = shift;
    return 0 if $self->type eq 'regular';
    return 1 if $self->type =~ m/h[1-5]/;
    return 1 if $self->block eq 'example';
    return 1 if $self->block eq 'verse';
    return 1 if $self->block eq 'table';
    return 1 if $self->type eq 'newpage';
    return 0;
}


=head3 add_to_string($string, $other_string, [...])

Append (just concatenate) the given strings to the string attribute.

=cut

sub add_to_string {
    my ($self, @args) = @_;
    my $orig = $self->string;
    $self->_reset_rawline(); # we modify the string, so throw away the rawline
    $self->string(join("", $orig, @args));
}

=head3 append($element)

Append the element passed as argument to this one, setting th raw_line

=cut

sub append {
    my ($self, $element) = @_;
    $self->{rawline} .= $element->rawline;
    my $type = $self->type;
    # greedy elements
    if ($type eq 'example' or $type eq 'verse' or $type eq 'footnote') {
        $self->{string} .= $element->rawline;
    }
    else {
        $self->{string} .= $element->string;
    }

}

=head3 can_append($element)

=cut

sub can_append {
    my ($self, $element) = @_;
    if ($self->can_merge_next && $element->can_be_merged) {
        return 1;
    }
    if ($self->type eq 'footnote' and
        $element->type ne 'footnote' and
        $element->type ne 'null' and
        !$element->should_close_blocks) {
        return 1;
    }
    # same type
    foreach my $type (qw/table versep null/) {
        if ($self->type eq $type and $element->type eq $type) {
            return 1;
        }
    }
    return 0;
}

=head3 become_regular

Set block to empty string and type to regular

=cut

sub become_regular {
    my $self = shift;
    $self->type('regular');
    $self->block('');
}

1;
