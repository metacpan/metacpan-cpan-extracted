#!/ford/thishost/unix/div/ap/bin/perl -w

use blib;
use strict;

use X11::Motif;

my $toplevel = X::Toolkit::initialize("InfoBox");
my $form = give $toplevel -Form;

sub do_create_dialog {
    my($widget, $client, $call) = @_;

    my $shell = $widget->Shell;

    #my $dialog = X::Motif::XmCreateMessageDialog($shell, "Oops");
    #my $dialog = X::Motif::XmCreateErrorDialog($shell, "Oops");
    #my $dialog = X::Motif::XmCreateQuestionDialog($shell, "Oops");
    #my $dialog = X::Motif::XmCreateInformationDialog($shell, "Oops");
    my $dialog = X::Motif::XmCreateFileSelectionDialog($shell, "Oops");

    $dialog->Manage;
}

my $button = give $form -Button, -text => 'Create Dialog', -command => \&do_create_dialog;

handle $toplevel;
