
package Tk::GraphItems::LabeledConnector;

=head1 NAME

Tk::GraphItems::LabeledConnector - Display edges of relation-graphs on a Tk::Canvas

=head1 SYNOPSIS


  require Tk::GraphItems::TextBox;
  require Tk::GraphItems::LabeledConnector;


  my $conn = Tk::GraphItems::LabeledConnector->new(
                                            source => $a_TextBox,
                                            target => $another_TextBox,
                                            label  => 'labeltext'
                                            );
  $conn->colour( 'red' );
  $conn->arrow( 'both' );
  $conn->width( 2 );
  $conn->detach;
  $conn = undef;




=head1 DESCRIPTION

Tk::GraphItems::LabeledConnector extends Tk::GraphItems::Connector with a 'label' option.


=head1 METHODS

B<Tk::GraphItems::LabeledConnector> supports the following additional methods:

=over 4

=item B<new(> source      => $a_GraphItems-Node,
             target      => $a_GraphItems-NodeB,
             label       => 'label text'
             colour      => $a_TkColour,
             width       => $width_pixels,
             arrow       => $where,
             autodestroy => $bool<)>


Create a new LabeledConnector instance and  display it on the Canvas of 'source' and 'target'. See Tk::GraphItems::Connector for details.


=item B<label(> [$labeltext] B<)>

Sets the labels text to $labeltext, if the argument is given. Returns the current label, if called without an argument.


=back

=head1 SEE ALSO

Documentation of Tk::GraphItems::Connector
Documentation of Tk::GraphItems::TextBox 
Examples in Tk/GraphItems/Examples

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
use 5.008;
our $VERSION = '0.12';


use warnings;
use strict;
use Carp;
require Tk::GraphItems::Connector;
our @ISA = ('Tk::GraphItems::Connector');

sub initialize{
    my $self = shift;
    my %args = @_;
    my $labeltext = delete ($args{label}) || '';

    my $can  = $args{source}->get_canvas;

    eval{$self->{label_id} = $can->createText(10,10,
                                              -text   => $labeltext,
                                              -anchor => 'w')};
    if ($@) {
        croak "Connector creation failed: $@";
    }
    $self->SUPER::initialize(%args);
    $self->adjust_label;
    return $self;
}

sub label{
    my $self = shift;
    my $can = $self->get_canvas;
    if (@_) {
        $can->itemconfigure($self->{label_id},-text=>$_[0]);
        return $self;
    } else {
        return $can->itemcget($self->{label_id},'-text');
    }
}

sub set_coords{
    my $self = shift;
    $self->SUPER::set_coords(@_);
    $self->adjust_label;

}
sub adjust_label{
    my $self = shift;
    my $can  = $self->{canvas};
    my $line = $self->{line_id};
    my $label_id = $self->{label_id};
    my @coords = $can->coords($line);
    my $d_x  = $coords[2] - $coords[0];
    my $d_y  = $coords[3] - $coords[1];
    my $center_x = ($coords[0] + $coords[2])/ 2;
    my $center_y = ($coords[1] + $coords[3])/ 2;
    my $term = $d_x **2 /( ($d_x **2 + $d_y**2)|| 0.0001);
    my $xo = sqrt(1 - $term);
    my $yo = sqrt($term);
    my $label_x ;
    my $label_y ;
    my $delta = 10;
    if ($d_x <= 0 && $d_y <= 0){
        $label_x = $center_x + $delta * $xo;
        $label_y = $center_y - $delta * $yo;
        #print "1\n";
    }elsif($d_x <= 0 && $d_y >= 0){
        $label_x = $center_x + $delta * $xo;
        $label_y = $center_y + $delta * $yo;
        #print "2\n";
    }elsif($d_x >= 0 && $d_y >= 0){
        $label_x = $center_x + $delta * $xo;
        $label_y = $center_y - $delta * $yo;
        #print "3\n";
    }elsif($d_x >= 0 && $d_y <= 0){
        $label_x = $center_x + $delta * $xo;
        $label_y = $center_y + $delta * $yo;
        #print "4\n";
    }

    $can->coords($label_id,
                 $label_x,
                 $label_y,
             );

}


sub canvas_items{
    my $self = shift;
    my @c_i = ($self->SUPER::canvas_items);
    push @c_i, $self->{label_id} if $self->{label_id};
    return @c_i;
}

1;




__END__
