package gurpm::RPMProgressDialog;

#- Copyright (C) 2005 MandrakeSoft SA
#- Copyright (C) 2005-2010 Mandriva SA
#- Copyright (C) 2011-2017 Mageia

# Sharing code from gurpmi2 && Rpmdrake::gurpm
# Gtk3 only (no ugtk3/mygtk3) as it's used by gurpmi too...
#

=head1 SYNOPSIS

gurpm::RPMProgressDialog is a widget for gurpmi, rpmdrake (drakx already has its own)
that presents a global progress bar.

=head1 USAGE

How to use:

 my $w = gurpm::RPMProgressDialog->new:
 #$w->change_widget(Gtk3::Box->new);
 label(N("Preparing packages installation..."));
 ... # compute packages to install/remove...
 $w->init_progressbar;
 urpm::main_loop::run($urpm, $state, $nb, \@ask_unselect, {
       trans_log => \&gurpm::RPMProgressDialog::callback_download,
       pre_check_sig => \&gurpm::RPMProgressDialog::pre_check_sig,
       inst => \&gurpm::RPMProgressDialog::callback_inst,
       trans => \&gurpm::RPMProgressDialog::callback_inst,
       uninst => \&gurpm::RPMProgressDialog::callback_inst,
       ....

=head1 DESCRIPTION

=cut

use strict;
use Gtk3;
use urpm::download;
use urpm::msg 'N';
use urpm::util qw(max member);
use Scalar::Util qw(weaken);

our @ISA = qw(Gtk3::Window);

sub title {
    $::auto_select ? N("Distribution Upgrade") : N("Packages installation");
}

# package variable needed in order to simplify callbacks
my ($mainw, $urpm, $old_main_window);

my $progressbar_size = 450;
my ($progress_nb, $download_nb, $index);


=head2 Creators

=over 4

=item gurpm::RPMProgressDialog->new($urpm, $o_quit)

Creates a new Progress Dialog.

Arguments are an urpm object and a quit routine reference.

=cut


sub new {
    my ($self, $global_urpm, $o_quit, $o_no_modal) = @_;
    # my $w = ugtk3->new($title, %options, default_width => 600, width => 600);
    my $w = $mainw = bless(Gtk3::Window->new('toplevel'), $self);

    $old_main_window = $::main_window;
    $::main_window = $w;
    $w->set_border_width(12);
    $w->set_title($w->title);
    $w->signal_connect(destroy => $o_quit) if $o_quit;
    $w->set_position('center_always');
    $w->set_default_size($progressbar_size, 60);
    # for matchbox window manager during install:
    if (!$o_no_modal) {
	$w->set_type_hint('dialog');
	$w->set_modal(1);
    }
    $w->{mainbox} = Gtk3::VBox->new(0, 5);
    $w->add($w->{mainbox});
    $urpm = $global_urpm;

    # Prevent cycle:
    weaken($urpm); # fixes GC but not ideal
    weaken($mainw);
    weaken($::main_window);

    bless($w, $self);
}

=back

=head2 Methods

=over 4

=item change_widget($w, $box_widget)

Replaces the contents of the main window with the specified box
(avoids popup multiplication)

=cut

sub change_widget {
    my ($w, $mainbox) = @_;
    $w->remove($w->{mainbox});
    $w->add($w->{mainbox} = $mainbox);
    $w->show_all;
}

=item label($w, $o_text)

sets the window to a please-wait message

=cut

sub label {
    my ($w, $o_text) = @_;
    my $wait_vbox = Gtk3::VBox->new(0, 5);
    my $label = Gtk3::Label->new($o_text || N("Please wait..."));
    $label->set_alignment(0.5, 0.5);
    $wait_vbox->pack_start($label, 1, 1, 0);
    $w->change_widget($wait_vbox);
    $w->sync;
}


# From ugtk3.pm/mygtk3.pm:
sub gtk_new_Label_Left {
    my ($text) = @_;
    my $w = Gtk3::Label->new($text);
    $w->set_alignment(0, 0);
    $w;
}

=item init_progressbar($w)

Put a progress bar in the dialog.

=cut

sub init_progressbar {
    my ($w) = @_;
    my $vbox = Gtk3::VBox->new(0, 5);

    my $global_label = gtk_new_Label_Left('<b>' . $w->title . '</b>');
    $global_label->set_use_markup(1);
    $vbox->pack_start($global_label, 0, 0, 0);

    my $global_progressbar = $w->{global_progressbar} = Gtk3::ProgressBar->new;
    $vbox->pack_start($global_progressbar, 0, 0, 0);

    $vbox->pack_start($w->{progresslabel} = gtk_new_Label_Left('-'), 1, 1, 0);

    my $progressbar = Gtk3::ProgressBar->new;
    $progressbar->set_size_request($progressbar_size, -1);
    $vbox->pack_start($progressbar, 0, 0, 0);
    $w->{progressbar} = $progressbar;
    $progress_nb = $download_nb = $index = 0;

    $w->change_widget($vbox);
}

=item set_progresslabel($w, $text)

Update the progress label

=cut

sub set_progresslabel {
    my ($w, $text) = @_;
    $w->{progresslabel}->set_label($text);
}

=item set_progressbar($w, $local_ratio)

Update the progress bar

=cut

sub set_progressbar {
    my ($w, $local_ratio) = @_;
    if ($progress_nb || $download_nb) { # this happens when computing transaction
	$w->{global_progressbar}->set_fraction(($download_nb + $progress_nb - 1 + $local_ratio) / 2 / $urpm->{nb_install});
    }
    $w->{progressbar}->set_fraction($local_ratio);
}

=item validate_cancel($self, $cancel_msg, $cancel_cb)

Add a "Cancel" button, with $cancel_msg as label, calling
$cancel_cb when clicked.

=cut

sub validate_cancel {
    my ($self, $cancel_msg, $cancel_cb) = @_;
    if (!$self->{cancel}) {
	$self->{hbox_cancel} = Gtk3::HButtonBox->new;
	$self->{hbox_cancel}->add($self->{cancel} = Gtk3::Button->new($cancel_msg));
	$self->{mainbox}->add($self->{hbox_cancel});
	$self->{cancel}->signal_connect('clicked' => \&$cancel_cb);
	$self->{hbox_cancel}->show_all;
    }
    $self->{cancel}->set_sensitive(1);
    $self->{cancel}->show;
}

=item invalidate_cancel($self)

Disable the "Cancel" button if any.

=cut

sub invalidate_cancel {
    my ($self) = @_;
    $self->{cancel} and $self->{cancel}->set_sensitive(0);
}

=item invalidate_cancel($self)

Disable the "Cancel" button if any.

=cut


sub invalidate_cancel_forever {
    my ($self) = @_;
    $self->{hbox_cancel} or return;
    $self->{hbox_cancel}->destroy;
}


=item sync($w)

tell Gtk+ to refresh the dialog content if needed.

=cut

sub sync {
    my ($w) = @_;
    $w->show;
    Gtk3::main_iteration while Gtk3::events_pending;
}

=item gurpm::RPMProgressDialog::get_something_done()

Whether some package has been installed or removed

=cut

sub get_something_done() {
    $progress_nb;
}

=item canceled($w)

Whether downloading has been canceled or not.

=cut

sub canceled {
    my ($w) = @_;
    $w->{canceled};
}

=back

=head2 Callbacks

=over 4

=item callback_pre_check_sig()

This callback is called when checking packages before installing them.

Its purpose is to display installation progress in the dialog.

=cut

sub callback_pre_check_sig {
    $mainw->set_progresslabel(N("Verifying package signatures..."));
    $mainw->sync;
}

=item callback_inst($urpm, $type, $id, $subtype, $amount, $total)

This callback is called when a new RPM DB transaction is created and
when packages are installed.

Its purpose is to display installation progress in the dialog.

=cut

sub callback_inst {
    my ($urpm, $type, $id, $subtype, $amount, $total) = @_;
    my $pkg = defined $id ? $urpm->{depslist}[$id] : undef;
    if ($subtype eq 'start') {
	if ($type eq 'trans') {
	    $index = 0;
	    $mainw->set_progresslabel(N("Preparing..."));
	} else {
	    my $msg;
	    if ($type eq 'uninst') {
		$msg = N("Removing package `%s' ...", $urpm->{trans}->Element_fullname($index));
	    } else {
		$progress_nb++;
		$msg = N("Installing package `%s' (%s/%s)...", $pkg->name, $progress_nb, $urpm->{nb_install});
	    }
	    $index++;
	    $download_nb = max($download_nb, $progress_nb);
	    $mainw->set_progressbar(0);
	    $mainw->set_progresslabel($msg);
	}
    } elsif ($subtype eq 'progress') {
	$mainw->set_progressbar($amount / $total);
    }
    $mainw->sync;
}

=item callback_download($mode, $file, $percent, $total, $eta, $speed)

This callback is called when packages are downloaded prior being installed
in a RPM transaction.

Its purpose is to display download progress in the dialog.

=cut

sub callback_download {
    my ($mode, $file, $percent, $total, $eta, $speed) = @_;

    urpm::download::sync_logger($mode, $file, $percent, $total, $eta, $speed);

    if (member($mode, 'start', 'progress')) {
	$file =~ s|/*\s*$||; $file =~ s|.*/||;
	$mainw->set_progresslabel(N("Downloading package `%s'...", $file) . "\n" .
				  &urpm::download::progress_text($mode, $percent, $total, $eta, $speed));
    }
    if ($mode eq 'start') {
	$mainw->validate_cancel(N("Cancel"), \&callback_cancel);
	$download_nb++;
	$mainw->set_progressbar(0);
	select(undef, undef, undef, 0.1); #- hackish
    } elsif ($mode eq 'progress') {
	$mainw->set_progressbar($percent / 100);
    } elsif ($mode eq 'end') {
	$mainw->set_progressbar(1);
    } elsif ($mode eq 'error') {
	#- error is 3rd argument, saved in $percent
	push @{$urpm->{download_errors}}, N("...retrieving failed: %s", $percent);
    }
    $mainw->sync;
}

=item callback_cancel()

This callback is to be called when canceling packages download.

=cut

sub callback_cancel {
    $mainw->{canceled} = 1;
}


sub DESTROY {
    my ($self) = @_;
    undef $mainw;
    undef $urpm;
    $::main_window = $old_main_window;

    $self = undef;
}


=back

=head1 Copyright

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut

1;
