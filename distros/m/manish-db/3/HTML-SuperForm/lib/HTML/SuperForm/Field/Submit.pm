package HTML::SuperForm::Field::Submit;

use base 'HTML::SuperForm::Field';
use strict;

sub init {
    my $self = shift;
    my $config = shift;

    unless(exists($config->{label})) {
        if(exists($config->{default})) {
            $config->{label} = $config->{default};
        } else {
            $config->{label} = "Submit Query";
        }
    }
}

sub to_html {
    my $self = shift;
    my $tag = '<input type="submit"';
    $tag .= $self->attribute_str();
    $tag .= ' value="';
    $tag .= $self->label();
    $tag .= '"';
    $tag .= "/" if $self->well_formed;
    $tag .= '>';

    return $tag;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Submit - Submit field used by HTML::SuperForm

=head1 SYNOPSIS

 my $submit = HTML::SuperForm::Field::Submit->new( name => 'my_submit',
                                                   default => 'Submit' );

 print $submit;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
