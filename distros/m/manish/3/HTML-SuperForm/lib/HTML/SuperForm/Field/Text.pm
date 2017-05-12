package HTML::SuperForm::Field::Text;

use base 'HTML::SuperForm::Field';
use strict;

sub to_html {
    my $self = shift;
    my $tag = '<input type="text"';
    $tag .= $self->attribute_str();
    $tag .= ' value="';
    $tag .= $self->value();
    $tag .= '"';
    $tag .= $self->readonly_str();
    $tag .= $self->disabled_str();
    $tag .= "/" if $self->well_formed;
    $tag .= '>';

    $tag = $self->label() . " $tag" if $self->has_label();

    return $tag;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Text - Text field used by HTML::SuperForm

=head1 SYNOPSIS

 my $text = HTML::SuperForm::Field::Text->new( name => 'my_text',
                                               default => 'default text' );

 print $text;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
