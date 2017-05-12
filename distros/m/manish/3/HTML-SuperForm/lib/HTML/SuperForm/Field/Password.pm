package HTML::SuperForm::Field::Password;

use base 'HTML::SuperForm::Field';
use strict;

sub to_html {
    my $self = shift;
    my $tag = '<input type="password"';
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

HTML::SuperForm::Field::Password - Password field used by HTML::SuperForm

=head1 SYNOPSIS

 my $password = HTML::SuperForm::Field::Password->new( name => 'my_password',
                                                       default => 'asdf' );

 print $password;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
