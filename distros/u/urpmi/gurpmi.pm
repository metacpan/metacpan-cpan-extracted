package gurpmi;

#- Copyright (C) 2005 MandrakeSoft SA
#- Copyright (C) 2005-2010 Mandriva SA

#- This is needed because text printed by Gtk3 will always be encoded
#- in UTF-8; we first check if LC_ALL is defined, because if it is,
#- changing only LC_COLLATE will have no effect.
use POSIX ();
use locale;
my $collation_locale = $ENV{LC_ALL};
if ($collation_locale) {
    $collation_locale =~ /UTF-8/ or POSIX::setlocale(POSIX::LC_ALL(), "$collation_locale.UTF-8");
} else {
    $collation_locale = POSIX::setlocale(POSIX::LC_COLLATE());
    $collation_locale =~ /UTF-8/ or POSIX::setlocale(POSIX::LC_COLLATE(), "$collation_locale.UTF-8");
}

use urpm;
use strict;
use Gtk3;
use urpm::util 'member';
use urpm::msg;
use urpm::args;
use urpm::select;
use Locale::gettext;

Locale::gettext::bind_textdomain_codeset('urpmi', 'UTF8');
URPM::bind_rpm_textdomain_codeset();

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(create_scrolled_window fatal but cancel_n_quit quit add_button_box new_label N);

=head1 NAME

gurpmi - Graphical routines for gurpmi GUI

=head1 DESCRIPTION

C<gurpmi> is used by gurpmi* executables to manipulate packages and media
on a Mageia Linux distribution.

=head2 The urpm class

=over 4

=cut

urpm::select::add_packages_to_priority_upgrade_list(qw(gurpmi perl-Glib perl-Glib-Object-Introspection perl-Gtk3));

sub usage () {
    print urpm::args::copyright('gurpmi', [ '1999-2010', 'Mandriva' ])
	. "    gurpmi <rpm> [ <rpm>... ]
" . N("Options:") . "\n"
 . N("  --help         - print this help message.
") . N("  --auto         - non-interactive mode, assume default answers to questions.
") . N("  --auto-select  - automatically select packages to upgrade the system.
") . N("  --force        - force invocation even if some packages do not exist.
") . N("  --verify-rpm   - verify rpm signature before installation
                   (--no-verify-rpm disables it, default is enabled).
") . N("  --media        - use only the given media, separated by comma.
") . N("  -p             - allow search in provides to find package.
") . N("  -P             - do not search in provides to find package.
") . N("  --root         - use another root for rpm installation.
") . N("  --test         - only verify if the installation can be achieved correctly.
") . N("  --searchmedia  - use only the given media to search requested packages.
");
    exit 0;
}

#- fatal gurpmi initialisation error (*not* fatal urpmi errors)
sub fatal { my $s = $_[0]; print STDERR "$s\n"; exit 1 }

=item parse_command_line()

Parse command line,
puts options in %gurpmi::options and puts bare names (not rpm filenames) in @gurpmi::names

=cut

sub parse_command_line() {
    my @all_rpms;
    our %options;
    our @names;

    # keep a copy for gurpmi2
    {
        local @ARGV = @ARGV;
        urpm::args::parse_cmdline(urpm => { options => \%options });
    }

    # Expand *.urpmi arguments
    my @ARGV_expanded;
    foreach my $a (@ARGV) {
	if ($a =~ /\.urpmi$/) {
	    open my $fh, '<', $a or do { warn "Can't open $a: $!\n"; next };
	    push @ARGV_expanded, map { chomp; $_ } <$fh>;
	    close $fh;
	} else {
	    push @ARGV_expanded, $a;
	}
    }
    foreach (@ARGV_expanded) {
	next if /^-/;
	if (-f $_) {
	    push @all_rpms, $_;
	} else {
	    push @names, $_;
	}
	
    }
    $::auto_select || @all_rpms + @names
	or fatal(N("No packages specified"));
    return @all_rpms;
}

sub but($) { "    $_[0]    " }

=item quit()

Quits top level gtk+ main loop or, if not such a loop, terminates with 1 as exit code

=cut

sub quit() {
    if (Gtk3->main_level) {
        Gtk3->main_quit;
    } else {
        # just exit if not in main loop (eg: while starting the GUI)
        exit 1;
    }
}

=item cancel_n_quit()

Quits gtk+ main loop and terminates with 1 as exit code

=cut

sub cancel_n_quit() {
    Gtk3->main_quit;
    exit(1);
}

=item add_button_box($vbox, @buttons)

Packs the buttons in an horizontal ButtonBox, on edges.

=cut

sub add_button_box {
    my ($vbox, @buttons) = @_;
    my $hbox = Gtk3::HButtonBox->new;
    $vbox->pack_start($hbox, 0, 0, 0);
    $hbox->set_layout('edge');
    $_->set_alignment(0.5, 0.5), $hbox->add($_) foreach @buttons;
}

=item new_label($msg)

Creates a new Gtk3::Label widget.
If messages is too big, it's wrapped in a scrolled window

=cut

sub new_label {
    my ($msg) = @_;
    my $label = Gtk3::Label->new($msg);
    $label->set_line_wrap(1);
    $label->set_alignment(0.5, 0.5);
    if (($msg =~ tr/\n/\n/) > 5) {
	my $sw = create_scrolled_window($label, [ 'never', 'automatic' ]);
	$sw->set_size_request(-1,200);
	return $sw;
    } else {
	return $label;
    }
}

=item create_scrolled_window($W, $o_policy, $o_viewport_shadow)

Creates a scrolled window around the $W widget

=cut

# copied from ugtk3:
sub create_scrolled_window {
    my ($W, $o_policy, $o_viewport_shadow) = @_;
    my $w = Gtk3::ScrolledWindow->new(undef, undef);
    $w->set_policy($o_policy ? @$o_policy : ('automatic', 'automatic'));
    if (member(ref($W), qw(Gtk3::Layout Gtk3::Html2::View Gtk3::Text Gtk3::TextView Gtk3::TreeView))) {
	$w->add($W);
    } else {
	$w->add_with_viewport($W);
    }
    $o_viewport_shadow and $w->get_child->set_shadow_type($o_viewport_shadow);
    $W->can('set_focus_vadjustment') and $W->set_focus_vadjustment($w->get_vadjustment);
    $W->set_left_margin(6) if ref($W) =~ /Gtk3::TextView/;
    $W->show;
    if (ref($W) =~ /Gtk3::TextView|Gtk3::TreeView/) {
	my $f = Gtk3::Frame->new;
	$w->show; # unlike ugtk3, we'd to do this explicitely...
	$f->set_shadow_type('in');
     $f->add($w);
     $f;
    } else {
	$w;
    }
}

=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2015 Mageia

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;
