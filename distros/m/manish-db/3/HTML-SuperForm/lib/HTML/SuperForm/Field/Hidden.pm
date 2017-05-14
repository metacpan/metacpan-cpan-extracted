package HTML::SuperForm::Field::Hidden;

use base 'HTML::SuperForm::Field';
use strict;

sub to_html {
    my $self = shift;
    my $tag = '<input type="hidden"';
    $tag .= $self->attribute_str();
    $tag .= ' value="';
    $tag .= $self->value();
    $tag .= '"';
    $tag .= "/" if $self->well_formed;
    $tag .= '>';

    return $tag;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Hidden - Hidden field used by HTML::SuperForm

=head1 SYNOPSIS

 my $hidden = HTML::SuperForm::Field::Hidden->new( name => 'my_hidden',
                                                   default => 'value' );

 print $hidden;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
