#!/ford/thishost/unix/div/ap/bin/perl -w

use strict;
use blib;

use Cwd;
use X11::Motif;
use X11::Motif::URLChooser::File;

my $input_dir = getcwd;

my $font_size = 180;
my $font_family_v_r = '-*-helvetica-medium-r';
my $font_family_v_i = '-*-helvetica-medium-o';
my $font_family_f_r = '-*-courier-medium-r';

my $label_font = "$font_family_v_r-*-*-*-$font_size-*-*-*-*-*-*";
my $menu_font =  "$font_family_v_i-*-*-*-$font_size-*-*-*-*-*-*";
my $input_font = "$font_family_f_r-*-*-*-$font_size-*-*-*-*-*-*";

my $toplevel = X::Toolkit::initialize('Xppcamshaft');
change $toplevel
			-title => q(Parametric Camshaft),
			-allowShellResize => X::True;

$toplevel->set_inherited_resources("*fontList" => $label_font,
				   "*menubar*fontList" => $menu_font,
				   "*XmTextField.fontList" => $input_font,
				   "*XmTextField.height" => 35,
				   "*XmPushButton.height" => 35,
				   "*XmLabel.height" => 35,
				   "*input.prompt.width" => 170,
				   "*input.command.width" => 170,
				   "*menubar*background" => '#d0d0d0',
				   "*background" => '#d0d0d0',
				   "*foreground" => '#000000');

my $form = give $toplevel -Form,
			-resizePolicy => X::Motif::XmRESIZE_ANY;

my $input = give $form -Form,
			-name => 'input',
			-horizontalSpacing => 5,
			-verticalSpacing => 5;

my $dir_label	= give $input -Label,
			-name => 'prompt',
			-text => 'Directory:',
			-alignment => X::Motif::XmALIGNMENT_END;

my $dir		= give $input -Label,
			-recomputeSize => X::False,
			-text => $input_dir;

my $chooser = new X11::Motif::URLChooser("file://localhost$input_dir");

my $file_label	= give $input -Label,
			-name => 'prompt',
			-text => 'Input File:',
			-alignment => X::Motif::XmALIGNMENT_END;

my $file	= give $input -Field,
			-width => 500,
			-command => \&reload_file_if_needed;

my $choose_file	= give $input -Button,
			-text => ' Choose ',
			-command => \&do_choose_file;

my $lobes_label	= give $input -Label,
			-name => 'prompt',
			-text => '';

my $lobes	= give $input -Toggle,
			-text => 'Update Lobes?',
			-alignment => X::Motif::XmALIGNMENT_END;

my $space_1	= give $input -Spacer;

my $hline	= give $input -Separator,
			-height => 20;

my $create_part	= give $input -Button,
			-name => 'command',
			-text => 'Create Camshaft',
			-command => sub { run_ppcamshaft(-create) };

my $part_name	= give $input -Field;

my $mod_part = give $input -Button,
			-name => 'command',
			-text => 'Modify Camshaft',
			-command => sub { run_ppcamshaft(-modify) };

my $view_input	= give $input -Button,
			-recomputeSize => X::False,
			-name => 'command',
			-text => 'View Input File',
			-command => \&do_view_parameters;

my $space_2	= give $input -Spacer;

my $quit	= give $input -Button,
			-name => 'command',
			-text => 'Quit',
			-command => sub { exit };

my $space_3	= give $input -Spacer;

constrain $dir_label	-top => -form,		-left => -form;
constrain $dir		-top => -form,		-left => $dir_label,	-right => -form;

constrain $file_label	-top => $dir,		-left => -form;
constrain $file		-top => $dir,		-left => $file_label,	-right => $choose_file;
constrain $choose_file	-top => $dir,					-right => -form;

constrain $lobes_label	-top => $file,		-left => -form;
constrain $lobes	-top => $file,		-left => $lobes_label;
constrain $space_1	-top => $file,		-left => $lobes,	-right => -form;

constrain $hline	-top => $lobes,		-left => -form,		-right => -form;

constrain $create_part	-top => $hline,		-left => -form;
constrain $part_name	-top => $hline, 	-left => $create_part,	-right => -form;

constrain $mod_part	-top => $create_part,	-left => -form;

constrain $view_input	-top => $mod_part,	-left => -form;
constrain $space_2	-top => $mod_part,	-left => $view_input,	-right => $quit;
constrain $quit		-top => $mod_part,				-right => -form;

constrain $space_3	-top => => $quit,	-left => -form,		-right => -form,
			-bottom => -form;

my $editor = X::Motif::XmCreateScrolledText($form, 'editor',
			-rows => 15,
			-columns => 80,
			-editable => X::False,
			-editMode => X::Motif::XmMULTI_LINE_EDIT,
			-scrollHorizontal => X::True);
change $editor -managed => X::True;

my $view = $editor->Parent;
change $view -managed => X::False;

constrain $input	-top => -form,
			-bottom => -form,
			-left => -form,
			-right => -form;

constrain $view		-bottom => [ -form, 5 ],
			-left => [ -form, 5 ],
			-right => [ -form, 5 ];

handle $toplevel;

sub do_destroy_self {
    my($w) = @_;
    $w->XtDestroyWidget();
}

sub popup_error {
    my($message, $title) = @_;

    if (!defined $title) {
	$title = 'Error Message';
    }

    give $toplevel -Dialog,
			-type => -information,
			-title => $title,
			-ok => \&do_destroy_self,
			-message => $message;
}

sub do_view_parameters {
    my($w) = @_;

    if ($view->IsManaged) {
	# If the input file is currently displayed (i.e. managed), then
	# it needs to be *removed* from the display.  The button label
	# should change to 'view' because the next push will display the
	# the input file.

	change $w -text => 'View Input File';
	constrain $view -top => -none;
	constrain $input -bottom => -form;
	change $view -managed => X::False;
    }
    else {
	# If the input file is not displayed (i.e. unmanaged), then the
	# input file needs to be loaded (perhaps) and displayed.  The
	# button label needs to be changed because when the input file
	# is displayed pressing the button will hide it, not display it.

	reload_file_if_needed();

	change $w -text => 'Hide Input File';
	constrain $input -bottom => -none;
	constrain $view -top => $input;
	change $view -managed => X::True;
    }
}

my $old_path;

sub get_current_input_file {
    my $path = $input_dir;

    $path .= '/' if ($path !~ m|/$|);
    $path .= X::Motif::XmTextFieldGetString($file);

    $path;
}

sub validate_input_file {
    my($path) = @_;

    if (-f $path && -r $path) {
	return 1;
    }

    if (-d $path) {
	popup_error("You must choose an input file,\nnot a directory.", "Not a file");
    }
    elsif (! -r $path) {
	popup_error(<<"EOT", "No input");
The the input file:

  $path

doesn't exist.
EOT
    }

    return 0;
}

sub reload_file_if_needed {
    my $path = get_current_input_file();

    if (validate_input_file($path) &&
	(!defined $old_path || $old_path ne $path))
    {
	$old_path = $path;
	my $value = '';

	if (open(INPUT, "<$path")) {
	    while (<INPUT>) {
		$value .= $_;
	    }
	    close(INPUT);
	}

	X::Motif::XmTextSetString($editor, $value);
    }
}

sub do_choose_file {
    my $url = $chooser->choose();	    # pop open the URL selection dialog

    if (defined $url) {			    # undefined if user hit cancel
	$input_dir = $url;
	$input_dir =~ s|^[^/:]*://[^/]*||;  # strip the "type://hostname" from the URL
	$input_dir =~ s|/([^/]*)$||;	    # now strip the filename (but save in $1)

	# only switch file names if the user entered a file name,
	# i.e. allow people to change directories without having to
	# re-select a file name.

	if ($1 ne '') {
	    X::Motif::XmTextFieldSetString($file, $1);
	}

	change $dir -text => $input_dir;
	reload_file_if_needed();
    }
}

sub run_ppcamshaft {
    my($mode) = @_;

    my $name = X::Motif::XmTextFieldGetString($part_name);
    my $path = get_current_input_file();
    my $update = (query $lobes -set) ? ' -update-lobes' : '';

    if (validate_input_file($path)) {
	print "RUNNING: ppcamshaft $mode$update -name='$name' -input='$path'\n";
    }
}
