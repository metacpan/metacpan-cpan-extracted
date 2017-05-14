package HTML::SuperForm::Field::Select;

use base 'HTML::SuperForm::Field';
use strict;

sub init {
    my $self = shift;
    my $config = shift;

    unless(exists($config->{label})) {
        $config->{label} = '';
    }
}

sub to_html {
    my $self = shift;
    my $tag = '<select ';
    $tag .= $self->attribute_str();
    $tag .= $self->multiple_str();
    $tag .= $self->disabled_str();
    $tag .= ">\n";

    for my $v (@{$self->values}) {
        $tag .= qq|    <option value="$v"|;
        $tag .= $self->selected_str($v);
        $tag .= '>';
        $tag .= $self->label($v);
        $tag .= "</option>\n"
    }
    $tag .= '</select>';

    $tag = $self->label . " $tag" if $self->has_label();

    return $tag;
}

sub options_html {
    my $self = shift;

    my $options = $self->options;

    my $table = [];
    if($self->{cols}) {
        my $c = 0;
        for my $option (@$options) {
            my $col = $c % $self->{cols};
            my $row = int($c / $self->{cols});
            $table->[$row] ||= [];
            $table->[$row][$col] = $option;
            $c++;
        }
    } elsif($self->{rows}) {
        my $r = 0;
        for my $option (@$options) {
            my $row = $r % $self->{rows};
            my $col = int($r / $self->{rows});
            $table->[$row] ||= [];
            $table->[$row][$col] = $option;
            $r++;
        }
    } else {
        $table->[0] ||= [];
        for my $option (@$options) {
            push(@{$table->[0]}, $option);
        }
    }

    my $tag = qq|<table width="100%" cellpadding="3">\n|;

    for my $row (@{$table}) {
        $tag .= "<tr>";
        for my $col (@{$row}) {
            $tag .= "<td>$col</td>";
        }
        $tag .= "</tr>\n";
    }

    $tag .= "</table>";

    return $tag;
}

sub options {
    my $self = shift;

    my $options = [];
    my $o_object = $self->form->field_object();
    if($self->multiple) {
        $o_object .= "::Checkbox";
    } else {
        $o_object .= "::Radio";
    }
    eval "require $o_object";
    for my $v (@{$self->values}) {
        my $option = $o_object->new(name => $self->name,
                                    label => $self->label($v),
                                    value => $v,
                                    default => $self->selected($v),
				    values_as_labels => $self->values_as_labels
                                    );
        push(@$options, $option);
    }

    return wantarray ? @$options : $options;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Select - Select field used by HTML::SuperForm

=head1 SYNOPSIS

 my $select = HTML::SuperForm::Field::Select->new( name => 'my_select',
                                                   values => [ 1, 2, 3, 4 ],
                                                   labels => { 1 => 'One',
                                                              2 => 'Two',
                                                              3 => 'Three',
                                                              4 => 'Four' },
                                                   multiple => 1);

 print $select;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
