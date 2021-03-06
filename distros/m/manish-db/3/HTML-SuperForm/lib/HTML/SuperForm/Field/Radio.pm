package HTML::SuperForm::Field::Radio;

use base 'HTML::SuperForm::Field';
use strict;

sub init {
    my $self = shift;
    my $config = shift;

    unless(exists($config->{value})) {
        $config->{value} = 1;
    }

    if(exists($config->{checked})) {
        $config->{default} = delete $config->{checked};
    }

    if($config->{default} || $config->{default} eq $config->{value}) {
        $config->{default} = $config->{value};
    } else {
        $config->{default} = undef;
    }
}

sub to_html {
    my $self = shift;

    my $tag = qq|<input type="radio"|;
    $tag .= $self->attribute_str();
    $tag .= $self->checked_str($self->value()); 
    $tag .= $self->disabled_str();
    $tag .= "/" if $self->well_formed;
    $tag .= ">";

    $tag .= " " . $self->label() if $self->has_label();

    return $tag;

}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Radio - Radio field used by HTML::SuperForm

=head1 SYNOPSIS

 my $radio = HTML::SuperForm::Field::Radio->new( name => 'my_radio',
                                                 default => 1,
                                                 value => 'hello' );

 print $radio;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
