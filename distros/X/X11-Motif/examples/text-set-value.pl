#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;

use strict;
use X11::Motif;

my $toplevel = X::Toolkit::initialize("Example");

my $form = give $toplevel -Form;

my $label = give $form -Button, -text => "label: ", -command => \&do_set_field;
my $field = give $form -Field;

arrange $form -fill => 'xy', -left => [ $label, $field ];

handle $toplevel;

sub do_set_field {
    my($w, $client, $call) = @_;

    change $field -value => 5;
}
