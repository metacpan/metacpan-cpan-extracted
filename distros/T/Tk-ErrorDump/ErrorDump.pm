package Tk::ErrorDump;

use vars qw($VERSION);
$VERSION = '0.02';

use English;
use Tk ();
use base qw(Tk::Toplevel);
use Tk::ROText;

use strict;

Construct Tk::Widget 'ErrorDump';

my $ED_OBJECT;

sub Populate {

    # ErrorDump constructor.  Uses `new' method from base class
    # to create object container then creates the dialog toplevel and the
    # traceback toplevel.

    my($cw, $args) = @_;

    $cw->minsize(1, 1);
    $cw->title('Dump Stack Trace for Error');
    $cw->iconname('Stack Trace');

	my $labframe = $cw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
    my $t_bitmap = $labframe->Label(
        -bitmap         => 'error'
    )->grid(-column => 0, -row => 0, -sticky => 'e');

    my $t_label = $labframe->Label(
        -text           => 'on-the-fly-text',
        -justify => 'left', 
    )->grid(-column => 1, -row => 0, -sticky => 'w', -pady => 4);

    my $t_text = $cw->ROText(
        -relief  => 'sunken',
        -bd      => 2,
        -width   => 60,
        -height  => 20,
     )->pack(-side => 'top', -fill => 'both', -expand => 1);

    my $t_ok = $cw->Button(
        -text    => 'OK',
        -command => [
            sub {
            my $cw = shift;
# execute any cleanup code if it was defined
		   	my $c = $cw->{Configure}{'-dumpcode'};
		   	&$c(undef, @{$cw->{ErrorInfo}}) if defined $c;
			$cw->withdraw;
		    }, $cw,
        ]
    )->pack(-side => 'left', -anchor => 'center', -padx => '3m', -pady => '2m', -expand => 1);

    my $t_save = $cw->Button(
        -text    => 'Save Dump',
        -command => [
            sub {
				shift->Dump;
	    	}, $cw,
        ]
    )->pack(-side => 'left', -anchor => 'center', -padx => '3m', -pady => '2m', -expand => 1);

    $cw->withdraw;

    $cw->Advertise(error_label => $t_label); # advertise dialog widget
    $cw->Advertise(text => $t_text);     # advertise text widget
    $cw->ConfigSpecs(
    	-dumpcode => [PASSIVE => undef, undef, undef],
    	-filtercode => [PASSIVE => undef, undef, undef],
    	-icon => [ PASSIVE => undef, undef, undef ],
    	-defaultfile => [ PASSIVE => undef, undef, undef ]);
    $ED_OBJECT = $cw;
    return $cw;

} # end new, ErrorDialog constructor
#
#	request a Save file, then dump our
#	traceback, then let app dump whatever it needs to
#
sub Dump {
	my ($cw) = @_;
#
#	open saveas dialog
#
	my $dumpfile = $cw->getSaveFile(
		-title => 'Save Project As',
		-initialfile => $ED_OBJECT->{Configure}{'-defaultfile'});
	my $fh;

	print $fh "--- ERROR ---\n",
		(shift @{$cw->{ErrorInfo}}), "\n",
		"---- Begin Traceback ----\n",
		join("\n", @{$cw->{ErrorInfo}}), "\n"
		if ($dumpfile && open($fh, ">>$dumpfile"));

# execute any cleanup code if it was defined
   	my $c = $cw->{Configure}{'-dumpcode'};
   	&$c($fh, @{$cw->{ErrorInfo}}) 
   		if (defined($c) && (ref $c) && (ref $c eq 'CODE'));
   	close $fh;
   	$cw->withdraw;
}

sub Tk::Error {

    # Post a dialog box with the error message and give the user a chance
    # to see a more detailed stack trace.

    my($w, $error, @msgs) = @_;

    my $grab = $w->grab('current');
    $grab->Unbusy if (defined $grab);
#
#	create widget if not exists
#
    $w->ErrorDump if not defined $ED_OBJECT;
	my $cw = $ED_OBJECT;
#
#	apply filter if defined
#
   	my $c = $cw->{Configure}{'-filtercode'};
   	($error, @msgs) = &$c($error, @msgs)
   		if (defined($c) && (ref $c) && (ref $c eq 'CODE'));

	$cw->{ErrorInfo} = [ ($error, @msgs) ];
	my $lbl = $cw->Subwidget('error_label');
	$lbl->configure(-text => $error);
    my $t = $cw->Subwidget('text');
    my $icon = $cw->{Configure}{-icon};
	$cw->Icon(-image => $icon) if $icon;
    $t->bell;
	$t->configure(-background => 'white');

    chop $error;
    $t->delete('0.0', 'end');
    $t->insert('end', "\n");
    $t->mark('set', 'ltb', 'end');
    $t->insert('end', "--- Begin Traceback ---\n$error\n");
    my $msg;
    for $msg (@msgs) {
		$t->insert('end', "$msg\n");
    }
    $t->yview('ltb');
    $cw->deiconify;
    $cw->raise();

#    $w->break if ($ans =~ /skip/i);

} # end Tk::Error


1;


__END__


=cut

=head1 NAME

Tk::ErrorDump - An alternative to Tk::Error or Tk::ErrorDialog

=head1 SYNOPSIS

    use Tk::ErrorDump;

	my $errdlg = $mw->ErrorDump(
		-icon => $my_icon,
		-defaultfile => '*.tkd',
		-dumpcode => \&err_dlg_dump	# dump internal info
		-filtercode => \&filter_dump	# filter dump info
		[ the usual frame options ]
	);

    icon     - an app specific icon for the popup error dialog;
    	default is std. Tk icon

    defaultfile - the default filename (maybe wildcarded) used in the
    	getSaveFile dialog to create the dump file

    dumpcode - a CODE reference called after an error is intercepted
    	and the ErrorDump dialog is presented. It is passed a filehandle
    	to which the app can write any app-specific dump information

    filtercode - a CODE reference called before the ErrorDump dialog is 
    	presented. It is passed the error message and stack trace, and
    	returns them as an array. Intended to provide application
    	the opportunity to filter the error info before display.


=head1 DESCRIPTION

[ NOTE: This module is derived directly from Tk::ErrorDialog...
	tho you probably can't tell it anymore ]

An error dialog that traps Tk errors, then displays the error and
stack trace in a ROText widget, and gives the user the opportunity
to save that information in a file. In addition, the application
can provide a callback which is invoked after the dialog is
presented, and to which the dumpfile handle (if any) is passed,
in order for the application to dump any internal diagnostic
information, and/or execute cleanup code.

=head1 PREREQUISITES

Tk::ROText

Tk::getSaveFile

=head1 CAVEATS

None so far...

=head1 AUTHORS

Dean Arnold, darnold@presicient.com

Original Tk::ErrorDialog by Stephen O. Lidie,
	Lehigh University Computing Center. lusol@Lehigh.EDU

=head1 HISTORY 

December 29, 2003 : Converted from Tk::ErrorDialog

=cut
