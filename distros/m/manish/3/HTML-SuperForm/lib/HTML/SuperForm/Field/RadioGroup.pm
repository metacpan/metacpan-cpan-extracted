package HTML::SuperForm::Field::RadioGroup;

use base 'HTML::SuperForm::Field::Select';
use strict;

sub init {
    my $self = shift;
    my $config = shift;

    $config->{multiple} = 0;
    $self->{cols} = delete $config->{cols};
    $self->{rows} = delete $config->{rows};
}

sub to_html {
    my $self = shift;
    return $self->options_html;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::RadioGroup - RadioGroup field used by HTML::SuperForm

=head1 SYNOPSIS

 my $radio_group = HTML::SuperForm::Field::RadioGroup->new( name => 'my_radio_group',
                                                            values => [ 1, 2, 3, 4 ],
                                                            labels => { 1 => 'One',
                                                                        2 => 'Two',
                                                                        3 => 'Three',
                                                                        4 => 'Four' },
                                                            rows => 2);

 print $radio_group;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
