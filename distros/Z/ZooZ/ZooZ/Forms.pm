
package ZooZ::Forms;

#
# This package implements all the forms for ZooZ.
# These include:
# 1. new project form.
# 2. configure widget form.
# 3. choose font form.
# 4. choose callback form.
# 5. choose variable form.

use strict;
use Storable;  # remove an error from Tk::CodeText

use ZooZ::Fonts;
use ZooZ::Callbacks;
use ZooZ::Options;
use ZooZ::Generic;
use ZooZ::varRefs;
use ZooZ::TiedVar;

use Tk::Font;
use Tk::Pane;
use Tk::Dialog;
use Tie::Watch;

my (
    %FORMS,        # a list of all forms and their titles.
    %TOPLEVEL,     # to hold the toplevel widgets of all forms.

    # Data for widget configuration
    %CONFDATA,

    # Data for Fonts.
    %FONTDATA,

    # Data for varRefs.
    %VARDATA,

    # Data for callbacks
    %CBDATA,

    # Data for row/col conf.
    %ROWCOLDATA,

    %ignoreOptions,   # options to be hidden from user

    # Tab options. for Notebooks
    @TAB_OPTIONS,

    # Menu configuration for toplevels.
    %MENUDATA,
    @MENUS,
   );

%FORMS = (
	  #newProject      => 'Create New Project',
	  configureWidget => 'Configure Widget',
	  chooseFont      => 'Choose/Create Font',
	  chooseCallback  => 'Choose/Create Callback',
	  chooseVarRef    => 'Choose/Create Variable',
	  configureRowCol => 'Configure Row/Column',
	  configureMenu   => 'Configure Menu',
	 );

# the options to ignore. Those can't (and shouldn't) be
# exposed to the user.
%ignoreOptions = (
		  -class => 1,
		 );

# Sigils for vars.
$VARDATA{SIGIL}= {
		  Scalar => "\$",
		  Array  => "\@",
		  Hash   => "%"
		 };

# Tab options.
@TAB_OPTIONS = qw(-anchor -bitmap -image -label
		  -justify -createcmd -raisecmd
		  -state -underline -wraplength);

###################
#
# This should be called as a static sub.
# It creates toplevels for all the forms.
#
###################

sub createAllForms {
  my $mw = shift;

  for my $form (keys %FORMS) {
    my $t = $mw->Toplevel;

    $t->withdraw;
    $t->title   ($FORMS{$form});
    $t->protocol(WM_DELETE_WINDOW => [$t => 'withdraw']);

    my $setup = "setup_$form";
    ZooZ::Forms->$setup($t);

    $TOPLEVEL{$form} = $t;
  }
}

###############
#
# Setup the form to configure the widgets.
#
###############

sub setup_configureWidget {
  my ($class, $top) = @_;

  # Create a label that is easy to see to tell user what widget
  # is being configured.
  $top->Label(
	      -textvariable => \$CONFDATA{WidgetName},
	      -font         => 'WidgetName',
	      -fg           => 'darkolivegreen',
	      -bg           => 'white',
	      -borderwidth  => 1,
	      -relief       => 'ridge',
	      -pady         => 5,
	     )->pack(qw/-fill x -padx 5 -pady 5/);

  # create the notebook.
  $CONFDATA{NB} = $top->NoteBook(
				 -borderwidth => 1,
				)->pack(qw/-fill both -expand 1/);
  $CONFDATA{NBWIDGET} = $CONFDATA{NB}->add('NBWIDGET', -label => 'Widget Specific');
  $CONFDATA{NBPLACE}  = $CONFDATA{NB}->add('NBPLACE',  -label => 'Placement Specific');
  $CONFDATA{NBEXTRA}  = $CONFDATA{NB}->add('NBEXTRA',  -label => 'Extra Properties');

  # make things a bit nicer
  for (qw/NBPLACE NBWIDGET NBEXTRA/) {
    $CONFDATA{$_}->optionAdd('*Entry.BorderWidth'       => 1);
    $CONFDATA{$_}->optionAdd('*Button.BorderWidth'      => 1);
    $CONFDATA{$_}->optionAdd('*Checkbutton.BorderWidth' => 1);
    $CONFDATA{$_}->optionAdd('*Radiobutton.BorderWidth' => 1);
  }

  # bind for mouse wheel.
  ZooZ::Generic::BindMouseWheel($top, sub {
				  my $r = $CONFDATA{NB}->raised;
				  ($CONFDATA{$r}->packSlaves)[0];
				});
}

###############
#
# Setup the font selection form
#
###############

sub setup_chooseFont {
  my ($class, $top) = @_;

  $top->optionAdd("*$_.BorderWidth" => 1) for qw(Button
						 Checkbutton
						 Radiobutton
						 Optionmenu
						 Listbox);

  my $f1 = $top->Frame->pack(qw/-side top -fill both -expand 1/);
  my $f2 = $top->Labelframe(-text      => 'Preview',
			    -height    => 200,
			   )->pack(qw/-side bottom -fill x/);

  my $f3 = $f1->Labelframe(-text   => 'Previously Used Fonts',
			  )->pack(qw/-side left -fill both -expand 1/);
  my $l3 = $f3->Scrolled(qw/Listbox -scrollbars se/,
			 -exportselection => 0,
			 -selectmode      => 'browse',
			)->pack(qw/-fill both -expand 1/);

  my $f4 = $f1->Labelframe(-text => 'Available Families',
			)->pack(qw/-side left -fill both -expand 1/);
  my $l4 = $f4->Scrolled(qw/Listbox -scrollbars se/,
			 -exportselection => 0,
			 -selectmode      => 'browse',
			 -width => 30,
			)->pack(qw/-fill both -expand 1/);

  my $F4 = $f1->Frame->pack(qw/-side left -fill y -expand 0/);
  my $f5 = $F4->Labelframe(-text     => 'Extra Options',
			)->pack(qw/-side top -fill y -expand 1 -anchor n/);

  $_->Subwidget('xscrollbar')->configure(-borderwidth => 1) for $l3, $l4;
  $_->Subwidget('yscrollbar')->configure(-borderwidth => 1) for $l3, $l4;

  # populate family list.
  $l4->insert(end => $_) for sort $top->fontFamilies;

  $F4->Button(-text => 'Ok',
	      -command => sub {
		my $name = "$FONTDATA{family} $FONTDATA{size} $FONTDATA{weight} $FONTDATA{slant} " .
		  ($FONTDATA{underline} ? 'u ' : '') . ($FONTDATA{overstrike} ? 'o': '');
		$name =~ y/ /_/;

		#print "Name is $name.\n";
		# register it unless font already exists.
		unless ($::FONTOBJ->FontExists($name)) {
		  # create it and register it.
		  my $obj = $top->fontCreate($name,
					     map {
					       '-' . $_ =>  $FONTDATA{$_}
					     } qw/family size weight slant underline overstrike/);
		  $::FONTOBJ->add($name, $obj);
		}

		$FONTDATA{localReturn} = $name;
	      })->pack(qw/-side top -padx 5 -pady 0 -fill x/);

  $F4->Button(-text    => 'Cancel',
	      -command => [\&cancelForm, \%FONTDATA],
	     )->pack(qw/-side top -padx 5 -pady 0 -fill x/);

  my $sample         = $f2->Label(-text => "There's More Than One Way To Do It",
				 )->pack(qw/-side top/);

  my $default        = $sample->cget('-font');
  if ($default =~ /\{(.+)\}\s+(\d+)/) {
    $FONTDATA{family}   = $1;
    $FONTDATA{size}     = $2;
  } else {
    $FONTDATA{family}   = '';
    $FONTDATA{size}     = 8;
  }

  $FONTDATA{weight}     = 'normal';
  $FONTDATA{slant}      = 'roman';
  $FONTDATA{underline}  = 0;
  $FONTDATA{overstrike} = 0;

  for my $i (0 .. $l4->size - 1) {
    next unless $l4->get($i) eq $FONTDATA{family};

    $l4->selectionSet($i);
    $l4->see($i);
    last;
  }


  $f5->Label(-text => 'Size',
	    )->grid(-column => 0, -row => 0, -sticky => 'w');
  $f5->Optionmenu(-options => [5 .. 25],
		  -textvariable => \$FONTDATA{size},
		  -command      => [\&configureSampleFont, $sample],
		 )->grid(-column => 1, -row => 0, -sticky => 'ew',
			 -columnspan => 2);

  $f5->Label(-text => 'Weight',
	    )->grid(-column => 0, -row => 1, -sticky => 'w');
  $f5->Radiobutton(-text => 'Normal',
		   -value => 'normal',
		   -variable => \$FONTDATA{weight},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 1, -row => 1, -sticky => 'w');
  $f5->Radiobutton(-text => 'Bold',
		   -value => 'bold',
		   -variable => \$FONTDATA{weight},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 2, -row => 1, -sticky => 'w');

  $f5->Label(-text => 'Slant',
	    )->grid(-column => 0, -row => 2, -sticky => 'w');
  $f5->Radiobutton(-text => 'Normal',
		   -value => 'roman',
		   -variable => \$FONTDATA{slant},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 1, -row => 2, -sticky => 'w');
  $f5->Radiobutton(-text => 'Italic',
		   -value => 'italic',
		   -variable => \$FONTDATA{slant},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 2, -row => 2, -sticky => 'w');

  $f5->Label(-text => 'Underline',
	    )->grid(-column => 0, -row => 3, -sticky => 'w');
  $f5->Checkbutton(-text => 'Yes/No',
		   -variable => \$FONTDATA{underline},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 1, -row => 3, -sticky => 'ew',
			  -columnspan => 2);

  $f5->Label(-text => 'Overstrike',
	    )->grid(-column => 0, -row => 4, -sticky => 'w');
  $f5->Checkbutton(-text => 'Yes/No',
		   -variable => \$FONTDATA{overstrike},
		   -command  => [\&configureSampleFont, $sample],
		  )->grid(-column => 1, -row => 4, -sticky => 'ew',
			  -columnspan => 2);

  # when user selects a registered font, update the other widgets.
  $l3->bind('<1>' => sub {
	      my ($sel) = $l3->curselection;
	      defined $sel or return;

	      $sel    = $l3->get($sel);
	      my $obj = $::FONTOBJ->obj($sel);

	      # update all the vars.
	      for my $o (qw/family size weight slant underline overstrike/) {
		$FONTDATA{$o} = $obj->configure("-$o");
	      }

	      # configure the sample.
	      $sample->configure(-font => $obj);

	      # select the correct entry in the list of available fonts.
	      for my $i (0 .. $l4->size - 1) {
		next unless $l4->get($i) eq $FONTDATA{family};
		$l4->selectionClear(qw/0.0 end/);
		$l4->selectionSet($i);
		$l4->see($i);
		last;
	      }
	    });

  # when user selects a new font, update the sample and some vars.
  $l4->bind('<1>' => sub {
	      my ($sel) = $l4->curselection;
	      defined $sel or return;

	      $l3->selectionClear(qw/0.0 end/);
	      $FONTDATA{family} = $l4->get($sel);
	      configureSampleFont($sample);
	    });

  # to take care of waitVariable.
  $top->protocol(WM_DELETE_WINDOW => sub {
		   $FONTDATA{localReturn} = '';
		 });

  $FONTDATA{list} = $l3;
}

sub setup_chooseCallback {
  # this form let's users add/delete callbacks/subroutines.
  # as a side effect, it returns the name of the
  # selected callback so it can be used to assign
  # callbacks to -command arguments.
  my ($class, $top) = @_;

  my $f1 = $top->Labelframe(-text      => 'Defined Subroutines',
			   )->pack(qw/-side top -fill both -expand 1/);

  my $f2 = $top->Frame->pack(qw/-side bottom -fill x -padx 5 -pady 5/);

  my $l  = $f1->Scrolled(qw/Listbox -scrollbars se/,
			 -selectmode => 'single',
			 -width => 40,
			)->pack(qw/-side left -fill y/);

  eval "require Tk::CodeText";

  my @textWidget = $@ ? ('Text') : ('CodeText',
				    -disablemenu => 1, # no idea
				    -syntax      => 'Perl',
				   );

  my $r  = $f1->Scrolled(@textWidget,
			 -scrollbars => 'se',
			 -width      => 60,
			)->pack(qw/-side left -fill both -expand 1/);

  $r->bind('<Key>' => sub {
	     return unless $CBDATA{selected};

	     $::CALLBACKOBJ->code($CBDATA{selected}, $r->get(qw/0.0 end/));
	   });

  $CBDATA{list} = $l;

  $l->bind('<1>' => sub {
	     my ($sel) = $l->curselection;
	     #defined $sel or return;
	     defined $sel or do {
	       $CBDATA{selected} = '';
	       return;
	     };

	     $sel     = $l ->get($sel);
	     my $code = $::CALLBACKOBJ->code($sel);
	     $r->delete(qw/0.0 end/);
	     $r->insert(end => $code);

	     $CBDATA{selected} = $sel;
	   });

  $f2->Button(-text    => 'Add Subroutine',
	      -height  => 2,
	      -command => sub {
		my $name = $::CALLBACKOBJ->newName;

		unless (exists $CBDATA{newN}) {
		  my $d = $top->DialogBox(-title   => 'New Subroutine',
					  -buttons => [qw/Ok Cancel/],
					  -popover => $top);

		  my $f = $d->Labelframe(-text => 'Enter Unique Subroutine Name',
					)->pack(qw/-fill both -expand 1/);

		  $CBDATA{newN}   = $d;
		  $CBDATA{newN_e} = $f->Entry->pack;
		}

		my $e = $CBDATA{newN_e};

		do {
		  $e->delete(qw/0.0 end/);
		  $e->insert(0.0 => $name);
		  $e->selectionRange(qw/0.0 end/);
		  $e->focus;

		  my $ans = $CBDATA{newN}->Show;
		  return if $ans eq 'Cancel';

		  $name = $e->get;
		  $name =~ s/\W/_/g; # make sure it's legal
		  #$name = 'main::' . $name unless $name =~ /::/;
		  $name =~ s/^(?:.*::)?/main::/;  # only main allowed.
		} while $::CALLBACKOBJ->CallbackExists($name);


		$::CALLBACKOBJ->add($name, <<EOT);
# To rename the sub, use the button below.
sub $name {

}
EOT
  ;

		# add it to listbox.
		$l->insert(end => $name);
		$l->selectionSet('end');

		my $code = $::CALLBACKOBJ->code($name);
		$r->delete(qw/0.0 end/);
		$r->insert(end => $code);

		# select it
		$CBDATA{selected} = $name;

	      })->pack(qw/-side left -fill x -expand 1/);

  # AGAIN: Do I really need this?
  if (0) {
    $f2->Button(-text    => 'Delete Selected Sub',
		-height  => 2,
		-command => sub {
		  my ($sel) = $l->curselection;
		  defined $sel or return;

		  my $nam = $l->get($sel);
		  my $ans = $top->Dialog
		    (-title   => 'Are you sure?',
		     -bitmap  => 'question',
		     -buttons => [qw/Yes No/],
		     -font    => 'Questions',
		     -text    => <<EOT)->Show;
Are you sure you want to delete
callback '$nam' with its
associated code?
EOT
  ;
		  return if $ans eq 'No';
		  $::CALLBACKOBJ->remove($nam);
		  $l->delete($sel);
		  $r->delete(qw/0.0 end/);
		  # TBD: Must check if any widgets are using this
		  #      callback. If so, either fix that, or don't
		  #      delete the callback.
		})->pack(qw/-side left -fill x -expand 1/);
  }

  $f2->Button(-text    => 'Rename Selected Sub',
	      -height  => 2,
	      -command => sub {
		my ($sel) = $l->curselection;
		defined $sel or return;

		my $name = $l->get($sel);

		unless (exists $CBDATA{rename}) {
		  my $d = $top->DialogBox(-title   => 'Rename Callback',
					  -buttons => [qw/Ok Cancel/],
					  -popover => $top);

		  my $f = $d->Labelframe(-text => 'Enter Unique Subroutine Name',
					)->pack(qw/-fill both -expand 1/);

		  $CBDATA{rename}   = $d;
		  $CBDATA{rename_e} = $f->Entry->pack;
		}

		my $e = $CBDATA{rename_e};

		my $oldName = $name;
		$name =~ s/main:://;
		do {
		  $e->delete(qw/0.0 end/);
		  $e->insert(0.0 => $name);
		  $e->selectionRange(qw/0.0 end/);
		  $e->focus;

		  my $ans = $CBDATA{rename}->Show;
		  return if $ans eq 'Cancel';

		  $name = $e->get;
		  $name =~ s/\W/_/g; # make sure it's legal
		  #$name = 'main::' . $name unless $name =~ /::/;
		  $name =~ s/^(?:.*::)?/main::/;  # only main allowed
		} while $::CALLBACKOBJ->CallbackExists($name);
		
		$::CALLBACKOBJ->rename($oldName => $name);
		$l->delete($sel);
		$l->insert($sel => $name);

		my $code = $::CALLBACKOBJ->code($name);
		$code =~ s/\b(sub\s+)$oldName\b/$ {1}$name/;
		$::CALLBACKOBJ->code($name, $code);

		# stick it back
		$r->delete(qw/0.0 end/);
		$r->insert(end => $code);
	      })->pack(qw/-side left -fill x -expand 1/);

  $f2->Button(-text    => 'Return Selected',
	      -height  => 2,
	      -command => sub {
		my ($sel) = $l->curselection;
		defined $sel || return $CBDATA{localReturn} = '';

		$sel      = $l->get($sel) if defined $sel;

		# before we return, eval the subroutine, unless
		# it has been evaled before.
		my $code = $::CALLBACKOBJ->code($sel);

		{
		  no strict;
		  no warnings;

		  $code =~ s/sub \Q$sel/sub /;
		  *{"main::$sel"} = eval "package main; $code";
		}

		$CBDATA{localReturn} = $sel;
	      })->pack(qw/-side left -fill x -expand 1/);

  $f2->Button(-text    => "Return Nothing\n(Unsets binding)",
	      -command => sub {
		$CBDATA{localReturn} = 'UNSET';
	      })->pack(qw/-side left -fill both -expand 1/);

  $f2->Button(-text    => 'Cancel',
	      -height  => 2,
	      -command => [\&cancelForm, \%CBDATA],
	     )->pack(qw/-side left -fill x -expand 1/);

  $l->delete(qw/0.0 end/);
  $l->insert(end => $_) for $::CALLBACKOBJ->listAll;

  # to take care of waitVariable.
  $top->protocol(WM_DELETE_WINDOW => sub {
		   $CBDATA{localReturn} = '';
		 });
}

sub setup_chooseVarRef {
  my ($class, $top) = @_;

  my $f1 = $top->Labelframe(-text      => 'Defined Variables',
			   )->pack(qw/-side top -fill both -expand 1/);
  my $f2 = $top->Frame->pack(qw/-side bottom -fill x -padx 5 -pady 5/);

  my $l  = $f1->Scrolled(qw/Listbox -scrollbars se/,
			 -selectmode  => 'single',
			 -width       => 40,
			 -borderwidth => 1,
			)->pack(qw/-side left -fill both -expand 1/);

  $VARDATA{list} = $l;

  $l->bind('<1>' => sub {
	     my ($sel) = $l->curselection;
	     defined $sel or do {
	       $VARDATA{selected} = '';
	       return;
	     };

	     $VARDATA{selected} = $sel;
	   });

  $f2->Button(-text    => 'New Variable',
	      -height  => 2,
	      -command => sub {
		my $name = $::VARREFOBJ->newName;

		unless (exists $VARDATA{newN}) {
		  my $d = $top->DialogBox(-title   => 'New Variable',
					  -buttons => [qw/Ok Cancel/],
					  -popover => $top);

		  my $f = $d->Labelframe(-text => 'Enter Unique Variable Name',
					)->pack(qw/-fill both -expand 1/);

		  $VARDATA{newN}   = $d;
		  $VARDATA{newN_e} = $f->Entry->pack;
		  $VARDATA{newN_t} = 'Scalar';

		  $f->Radiobutton(-text     => $_,
				  -variable => \$VARDATA{newN_t},
				  -value    => $_,
				 )->pack(qw/-fill x/) for qw/Scalar Array Hash/;
		}

		my $e = $VARDATA{newN_e};

		do {
		  $e->delete(qw/0.0 end/);
		  $e->insert(0.0 => $name);
		  $e->selectionRange(qw/0.0 end/);
		  $e->focus;

		  my $ans = $VARDATA{newN}->Show;
		  return if $ans eq 'Cancel';

		  $name = $e->get;
		} while $::VARREFOBJ->varRefExists($name);

		if ($name =~ /^\w/) {  # add sigil if user didn't specify one.
		  my $type = $VARDATA{newN_t};
		  $name    = $VARDATA{SIGIL}{$type} . $name;
		}

		$::VARREFOBJ->add($name);

		# add it to listbox.
		$l->insert(end => $name);
		$l->selectionSet('end');

		# select it
		$VARDATA{selected} = $name;

	      })->pack(qw/-side left -fill x -expand 1/);

  # do I need this?
  if (0) {
  $f2->Button(-text    => 'Delete Selected Variable',
	      -height  => 2,
	      -command => sub {
		my ($sel) = $l->curselection;
		defined $sel or return;

		my $nam = $l->get($sel);
		my $ans = $top->Dialog
		  (-title   => 'Are you sure?',
		   -bitmap  => 'question',
		   -buttons => [qw/Yes No/],
		   -font    => 'Questions',
		   -text    => <<EOT)->Show;
Are you sure you want to delete
variable '$nam'?
EOT
  ;
		return if $ans eq 'No';
		$::VARREFOBJ->remove($nam);
		$l->delete($sel);

		## TBD: check for any widgets that are using this variable
		##      and update them.
	      })->pack(qw/-side left -fill x -expand 1/);
} # delete button

  $f2->Button(-text    => 'Initialize Variable',
	      -height  => 2,
	      -command => [\&initSelectedVar, $top, $l],
	     )->pack(qw/-side left -fill x -expand 1/);

  $f2->Button(-text    => 'Return Selected',
	      -height  => 2,
	      -command => sub {
		my ($sel)             = $l->curselection;
		$VARDATA{localReturn} = $l->get($sel) if defined $sel;
	      })->pack(qw/-side left -fill x -expand 1/);

  $f2->Button(-text    => "Return Nothing\n(Unsets binding)",
	      -command => sub {
		$VARDATA{localReturn} = 'UNSET';
	      })->pack(qw/-side left -fill both -expand 1/);

  $f2->Button(-text    => 'Cancel',
	      -height  => 2,
	      -command => [\&cancelForm, \%VARDATA],
	     )->pack(qw/-side left -fill x -expand 1/);

  # to take care of waitVariable.
  $top->protocol(WM_DELETE_WINDOW => sub {
		   $VARDATA{localReturn} = '';
		 });

  $l->bind('<Double-1>' => [\&initSelectedVar, $top, $l]);
}

sub initSelectedVar {
  my $l   = pop;
  my $top = pop;
  my $sel = $l->curselection;

  return unless defined $sel;
  my $var = $l->get($sel);
  $var =~ s/^(.)//;  # the sigil.
  my $s = $1;

  unless ($VARDATA{initForm}) {
    my $t = $VARDATA{initForm} = $top->DialogBox(-title   => 'Initialize Variable',
						 -buttons => [qw/Ok Cancel/],
						 -popover => $top);

    $t->bind('<Return>' => ''); # remove default.

    # create a frame for each type of variable.
    {
      my $f = $VARDATA{initScalarF} = $t->Frame;
      $f->Label(-text   => 'Enter Value',
		-anchor => 'w',
	       )->pack(qw/-fill x/);

      $VARDATA{initScalarV} = $f->Entry->pack(qw/-fill x/);
    }

    {
      my $f = $VARDATA{initArrayF} = $t->Frame;
      $f->Label(-text   => 'Enter Values One Per Line',
		-anchor => 'w',
	       )->pack(qw/-fill x/);
      $VARDATA{initArrayV} = $f->Scrolled(Text        =>
					  -scrollbars => 'e',
					 )->pack(qw/-fill both -expand 1/);
    }

    {
      my $f = $VARDATA{initHashF} = $t->Frame;
      $f->Label(-anchor  => 'w',
		-justify => 'left',
		-text    => <<EOT)->grid(-columnspan => 2);
Enter key value pairs.
Each line on the left will define a key and
each line on the right will define the corresponding value.
EOT
  ;
      $f->Label(-text => 'Keys',
		-font => 'OptionText',
	       )->grid(-row => 1, -column => 0, -sticky => 'w');
      $f->Label(-text => 'Values',
		-font => 'OptionText',
	       )->grid(-row => 1, -column => 1, -sticky => 'w');
      my $t1 = $f->Scrolled(Text        =>
			    -scrollbars => 'e',
			    -width      => 20,
			    -bd         => 1,
			    -wrap       => 'none',
			   )->grid(-row => 2, -column => 0);
      my $t2 = $f->Scrolled(Text        =>
			    -scrollbars => 'e',
			    -width      => 20,
			    -bd         => 1,
			    -wrap       => 'none',
			   )->grid(-row => 2, -column => 1);

      # define bindings such that the tab key
      # jumps between the two texts.
      # must jump to same location.
      $VARDATA{initHashK} = $t1->Subwidget('text');
      $VARDATA{initHashV} = $t2->Subwidget('text');
      $_->bindtags([$_, 'Tk::Text']) for $VARDATA{initHashK}, $VARDATA{initHashV};

      $VARDATA{initHashK}->bind('<Tab>' => sub {
				  my $loc = $VARDATA{initHashK}->index('insert');
				  my $end = $VARDATA{initHashV}->index('end');
				  $loc =~ s/\..*//;
				  $end =~ s/\..*//;

				  $VARDATA{initHashV}->insert(end => "\n") for $end .. $loc;
				  $VARDATA{initHashV}->focus;
				  $VARDATA{initHashV}->markSet(insert => "$loc.0");
				  Tk::break;
				});
      $VARDATA{initHashV}->bind('<Tab>' => sub {
				  my $loc = $VARDATA{initHashV}->index('insert');
				  $loc =~ s/\..*//;
				  $VARDATA{initHashK}->insert(end => "\n")
				    if $VARDATA{initHashK}->get("$loc.0") =~ /\S/ &&
				      $VARDATA{initHashK}->get(($loc+1).".0") !~ /\S/;
				  $VARDATA{initHashK}->focus;
				  $VARDATA{initHashK}->markSet(insert => ($loc+1) . ".0");
				  Tk::break;
				});

    }
  }

  my $f = $s eq "\$" ? 'initScalarF' : $s eq '@' ? 'initArrayF' : 'initHashF';

  # populate with the any old values.
  {
    no strict;

    if ($f =~ /Scalar/) {
      $VARDATA{initScalarV}->delete(qw/0 end/);
      $VARDATA{initScalarV}->insert(0, $ {"main::$var"});
    } elsif ($f =~ /Array/) {
      $VARDATA{initArrayV}->delete(qw/0.0 end/);
      $VARDATA{initArrayV}->insert(end => "$_\n") for @{"main::$var"};
    } else { # hash
      $VARDATA{$_}->delete(qw/0.0 end/) for qw/initHashK initHashV/;
      for my $k (sort keys %{"main::$var"}) {
	$VARDATA{initHashK}->insert(end => "$k\n");
	$VARDATA{initHashV}->insert(end => $ {"main::$var"}{$k} . "\n");
      }
    }
  }

  $VARDATA{$_}->packForget for qw/initScalarF initArrayF initHashF/;
  $VARDATA{$f}->pack(qw/-fill both -expand 1/);

  my $ans = $VARDATA{initForm}->Show;

  return if $ans eq 'Cancel';

  # set the value.
  {
    no strict;

    if ($f =~ /Scalar/) {
      $ {"main::$var"} = $VARDATA{initScalarV}->get;
    } elsif ($f =~ /Array/) {
      @ {"main::$var"} = split /\n/ => $VARDATA{initArrayV}->get(qw/0.0 end/);
    } else { # hash
      %{"main::$var"} = ();
      my @k = split /\n/ => $VARDATA{initHashK}->get(qw/0.0 end/);
      for my $i (1 .. @k) {
	my $v = $VARDATA{initHashV}->get("$i.0", "$i.end");
	$ {"main::$var"}{$k[$i - 1]} = $v;
      }
    }
  }
}

###############
#
# Setup the form to configure the menus.
#
###############

sub setup_configureMenu {
  my ($class, $top) = @_;

  # Create a label that is easy to see to tell user what widget
  # is being configured.
  $top->Label(
	      -textvariable => \$MENUDATA{FormName},
	      -font         => 'WidgetName',
	      -fg           => 'darkolivegreen',
	      -bg           => 'white',
	      -borderwidth  => 1,
	      -relief       => 'ridge',
	      -pady         => 5,
	     )->grid(-row        => 0,
		     -column     => 0,
		     -columnspan => 2,
		     -sticky     => 'ew');

  my $hl = $top->Scrolled(HList       =>
			  -scrollbars => 'se',
			  -bg         => 'white',
			  -header     => 1,
			  -columns    => 4,
			 )->grid(-row     => 1,
				 -column  => 0,
				 -rowspan => 2,
				 -sticky  => 'nsew',
				);

  $hl->header(create => 0, -relief => 'raised', -text => 'Label');
  $hl->header(create => 1, -relief => 'raised', -text => 'Type');
  $hl->header(create => 2, -relief => 'raised', -text => 'Accelerator');
  $hl->header(create => 3, -relief => 'raised', -text => 'Command');

  my $det = $top->Labelframe(-text => 'Details',
			    )->grid(-row    => 1,
				    -column => 1,
				    -sticky => 'ns',
				   );
#  my $but = $top->Frame->grid(-row    => 1,
#			      -column => 2,
#			      -sticky => 'ns',
#			     );
  my $but = $top->Frame->grid(-row    => 2,
			      -column => 1,
			      -sticky => 'ns',
			     );

  # create the buttons.
  $but->Button(-text => 'Add',
	      )->pack(qw/-side left -fill x -expand 1/);
  $but->Button(-text => 'Delete Selected',
	      )->pack(qw/-side left -fill x -expand 1/);

  # now the details.
  

  $top->gridRowconfigure   (1, -weight => 1);
  $top->gridColumnconfigure(0, -weight => 1);

  $MENUDATA{HL} = $hl;

  # bind for mouse wheel.
  ZooZ::Generic::BindMouseWheel($top, sub {
				  my $r = $CONFDATA{NB}->raised;
				  ($CONFDATA{$r}->packSlaves)[0];
				});
}

#########################
#
# This should be called as a static sub
#
#########################

# IS THIS NECESSARY?
sub displayForm {
  my $form = shift;

  return unless exists $TOPLEVEL{$form};
  my $t = $TOPLEVEL{$form};

  $t->deiconify;
}

##########################
#
# This deletes the form associated with the
# deleted widget. It also hides the propertis window.
#
##########################

sub deleteWidget {
  my ($class,
      $projid,
      $name) = @_;

  $TOPLEVEL{configureWidget}->withdraw;
  delete $CONFDATA{$projid}{$name};
}

sub changeWidgetName {
  my ($self, $v) = @_;

  $self->Store($v);

  my $args                = $self->Args('-store');
  my ($p, $n, $l, $i, $c) = @$args;

  my $col = $p->renameWidget($$n, $v) ? $c : 'red';
  $l->configure(-bg => $col);

  if ($col eq $c) { # went fine.
    # now must fix up the frame hashes.
    $CONFDATA{FORMS}{$i}{$v} = delete $CONFDATA{FORMS}{$i}{$$n};
    $CONFDATA{WidgetName}    = $v;

    $$n = $v;
  }
}

sub configureMenu {
  my ($class,
      $project,
      $projid,
      $name,
      $widget,
     ) = @_;

  $MENUDATA{FormName} = $project->{PROJNAME} . '.' . $name;

  $TOPLEVEL{configureMenu}->deiconify;
#  $TOPLEVEL{configureMenu}->grab;
#  $TOPLEVEL{configureMenu}->waitVariable(\$FONTDATA{localReturn});
#  $TOPLEVEL{configureMenu}->grabRelease;
#  $TOPLEVEL{configureMenu}->withdraw;

#  return $FONTDATA{localReturn};
}

###########################
#
# This method pops up the widget configuration form
#
###########################

sub configureWidget {
  my ($class,    # called as a method.
      $project,  # actual project widget.
      $parent,   # parent widget
      $projid,   # project ID
      $name,     # Widget name (unique)
      $widget,   # widget itself (preview, really)
      $Woptions, # hash of widget options.
      $Poptions, # hash of placement options.
      $Eoptions, # hash of extra options.
      $noforce,  # If window is not viewable, it won't show if this is 1.
      $scroll,   # Whether widget is scrollable or not.
     ) = @_;

  $CONFDATA{WidgetName} = $name;

  # create the frame for this widget if we haven't done that before.
  # should create one frame per widget per project.
  unless (exists $CONFDATA{FORMS}{$projid}{$name}) {

    # frame for widget options.
    my $f = $CONFDATA{NBWIDGET}->Scrolled('Pane',
					  -sticky     => 'nsew',
					  -scrollbars => 'e',
					  -gridded    => 'xy');

    # frame for extra options.
    my $h = $CONFDATA{NBEXTRA}->Scrolled('Pane',
					 -sticky     => 'nsew',
					 -scrollbars => 'e',
					);

    # frame for placement options.
    my $g = $CONFDATA{NBPLACE}->Scrolled('Pane',
					 -sticky     => 'nsew',
					 -scrollbars => 'e',
					);

    # configure the scrollbar's appearance.
    $_->Subwidget('yscrollbar')->configure(-borderwidth => 1) for $f, $g, $h;

    # save the frames.
    $CONFDATA{FORMS}{$projid}{$name} = [$f, $g, $h];

    # populate the widget options frame
    {
      my $f = $f->Frame->pack(qw/-side top -fill x/);

      { # The name
	my $name2 = $name;

	my $label = ZooZ::Options->addOptionGrid('Name',
						 'Name',
						 $f,
						 0,
						 0,
						 \$name2,
						 'tan',
						);

	Tie::Watch->new(
			-variable => \$name2,
			-store    => [\&changeWidgetName,
				      $project,
				      \$name,
				      $label,
				      $projid,
				      'tan'],
		       );
      }

      # If it's a toplevel, add a title.
      if (ref($widget) eq 'Tk::Toplevel') { # The name
	my $title = $widget->title;#$project->{PROJNAME};

	my $label = ZooZ::Options->addOptionGrid('Title',
						 'Title',
						 $f,
						 1,
						 0,
						 \$title,
						 'tan',
						);

	Tie::Watch->new(
			-variable => \$title,
			-store    => sub {
			  my ($self, $v) = @_;

			  $self->Store($v);
			  $widget->title($title);
			},
			#[\&changeWidgetName,
			#	      $project,
			#	      \$name,
			#	      $label,
			#	      $projid,
			#	      'tan'],
		       );
      }
      #$f->gridRowconfigure(1, -minsize => 10);

      my @conf = grep @$_ > 2, $widget->configure;
      my $row  = 2;
      for my $c (@conf) {
	my $option = $c->[0];

	next if exists $ignoreOptions{$option};

	# default value.
	$Woptions->{$option} ||= $c->[4];

	###
	### IMPORTANT: If it's -variable, then reset the value to nothing.
	###            This prevents a 'panic' crash in ptk.
	###            Not sure I understand why.

	$Woptions->{$option} = '' if $option eq '-variable' || $option eq '-textvariable';

	my @extra;   # additional options to be passed to ZooZ::Options::addOptionGrid

#	if ($option eq '-font') {
#	  $widget->configure(-font => 'Default');
#	  @extra = ($::FONTOBJ);

#	} elsif ($option eq '-command') {
#	  @extra = ($::CALLBACKOBJ);

#	} elsif ($option =~ /^-(?:text)?variable$/) {
#	  @extra = ($::VARREFOBJ);

#	} else {
#	  @extra = ();
#	}

	if ($option eq '-textvariable') {
	  @extra = (\$Woptions->{-text});
	}

	my $label = ZooZ::Options->addOptionGrid($option,
						 $option,   # might want to change this?
						 $f,
						 $row,
						 0,
						 \$Woptions->{$option},
						 @extra,
						);

	# Now tie the variable so we can instantly see the changes.
	tie $Woptions->{$option} =>
	  'ZooZ::TiedVar', $widget, $c->[4], 'configure', $option, $label;

	$row++;
      }

      $f->gridColumnconfigure(0,      -weight => 1);

      # Handle special tabs for special widgets.
      # For notebooks, add tab to add/delete pages.
      if (main::NOTEBOOK_SUPPORT && ref($widget) eq 'Tk::NoteBook') {
	# add one tab.
	# A notebook is allowed to have at least one tab.
	my $defaultTabName  = 'Tab1';
	my $defaultTabLabel = 'Tab 1';
	my $tab1 = $widget->add($defaultTabName => -label => $defaultTabLabel);

	# make room for it in the preview.
	$tab1  ->GeometryRequest(100, 100);
	$widget->Resize;

	# create the toplevel.
	$f->Button(-text    => 'Manage Pages',
		   -command => sub {
		     unless (exists $CONFDATA{NBCONF}{$projid}{$name}) {
		       my $t = $f->toplevel->Toplevel;
		       $t->withdraw;
		       $t->title   ("Notebook Configuration - $name");
		       $t->protocol(WM_DELETE_WINDOW => [$t => 'withdraw']);

		       # populate it.
		       my $lf = $t->Labelframe(-text => 'Current Pages',
					      )->pack(qw/-fill both -side left -expand 1/);
		       my $rf = $t->Labelframe(-text => 'Add Page',
					      )->pack(qw/-fill both -side right -expand 1/);

		       my $lb = $lf->Scrolled(Listbox     =>
					      -scrollbars => 'se',
					      -selectmode => 'single',
					     )->pack(qw/-fill both -expand 1/);

		       $lf->Button(-text    => 'Delete Selected Page',
				   -command => sub {
				     my ($ind) = $lb->curselection;
				     defined $ind or return;
				     my $sel   = $lb->get($ind);

				     my @pages = $widget->pages;

				     print "There are ", scalar @pages, " pages ($ind).\n";
				     # Can't delete if there is only one page.
				     if (@pages == 1) {
				       ZooZ::Generic::popMessage
					   (-over  => $::MW,
					    -msg   => "Must keep at least one tab!",
					    -font  => 'Level',
					    -bg    => 'White',
					    -delay => 1500);
				       return;
				     }

				     # delete the page.
				     # should I prompt the user to confirm?
				     # this will delete all children of the page.

				     delete $CONFDATA{NBCONF}{$projid}{$name}{TABS}{$sel};
				     $widget->delete($sel);

				     # remove it from the lb.
				     $lb->delete($ind);

				     @pages = $widget->pages;
				     print "Now there are ", scalar @pages, " pages.\n";
				   })->pack(qw/-fill x -expand 1/);

		       $CONFDATA{NBCONF}{$projid}{$name} = {
							    TOP   => $t,
							    LB    => $lb,
							    OPTS  => {},
							    TABS  => {
								      $defaultTabName => [$defaultTabLabel, $tab1],
								     }
							   };

		       my $o = $CONFDATA{NBCONF}{$projid}{$name}{OPTS};

		       my $p = $rf->Scrolled('Pane',
					     -sticky     => 'nsew',
					     -scrollbars => 'e',
					    )->pack(qw/-fill both -expand 1/);

		       my $row = 0;
		       for my $option (Name => @TAB_OPTIONS) {

			 ZooZ::Options->addOptionGrid($option,
						      $option,
						      $p,
						      $row++,
						      0,
						      \$o->{$option},
						     );
		       }

		       $rf->Button(-text    => 'Add Page',
				   -command => sub {
				     return unless $o->{Name};

				     # does the page exist?
				     my @pages = $widget->pages;
				     if (grep $_ eq $o->{Name}, @pages) {
				       ZooZ::Generic::popMessage
					   (-over  => $::MW,
					    -msg   => "Page '$o->{Name}' already exists!",
					    -font  => 'Level',
					    -bg    => 'White',
					    -delay => 1500);
				       return;
				     }

				     # add it.
				     my $tab = $widget->add($o->{Name}, map {
				       $_ ne 'Name' && $o->{$_} ? ($_ => $o->{$_}) : ()
				     } keys %$o);

				     # make room for it in the preview.
				     $tab   ->GeometryRequest(100, 100);
				     $widget->Resize;

				     $CONFDATA{NBCONF}{$projid}{$name}{TABS}{$o->{Name}} = [$o->{-label}, $tab];
				     $lb->insert(end => $o->{Name});

				   })->pack(qw/-fill x/);

		       # When a user clicks on a listbox entry, the options are updated.
		       $lb->bind('<1>' => sub {
				   my ($sel) = $lb->curselection;
				   defined $sel or return;
				   $sel    = $lb->get($sel);

				   #my $tabs = $CONFDATA{NBCONF}{$projid}{$name}{TABS};
				   $o->{Name} = $sel;
				   $o->{$_}   = $widget->pagecget($sel, $_) for @TAB_OPTIONS;
				 });

		       $p->gridRowconfigure($row, -weight => 1);

		       ZooZ::Generic::BindMouseWheel($t, $p);
		     }

		     # update the listbox.
		     my $ref = $CONFDATA{NBCONF}{$projid}{$name};
		     $ref->{LB}->delete(qw/0 end/);
		     $ref->{LB}->insert(end => $_) for keys %{$ref->{TABS}};

		     $ref->{TOP}->deiconify;
		     #$top->waitVisibility;

		   })->grid(-row        => $row,
			    -column     => 0,
			    -sticky     => 'nsew',
			    -columnspan => 3,
			    -pady       => 10,
			    -pady       => 5,
			   );

	# Check if we have menu builder support enabled.
      } elsif (main::MENU_BUILDER_SUPPORT && ref($widget) eq 'Tk::Toplevel') {
	$MENUS[$projid]{ENABLED} = 0;

	my $lf;
	my $cb = $f->Checkbutton(-text     => 'Add Menu',
				 -variable => \$MENUS[$projid]{ENABLED},
				 -command  => sub {
				   if ($MENUS[$projid]{ENABLED}) {
				     $_->configure(-state => 'normal')   for $lf->children;
				   } else {
				     $_->configure(-state => 'disabled') for $lf->children;
				   }
				 });

	$lf = $f->Labelframe(#-text => 'Menus',
			     -labelwidget => $cb,
			     -relief      => 'ridge',
			    )->grid(-row        => $row+1,
				    -column     => 0,
				    -sticky     => 'nsew',
				    -columnspan => 3,
				   );

	$lf->Button(-text    => 'Configure Menu',
		    -command => [\&configureMenu, __PACKAGE__, $project, $projid, $name, $widget],
		   )->pack(qw/-fill both -expand 1/);

	# initially .. set everything to disabled state.
	$_->configure(-state => 'disabled') for $lf->children;
      }

    }

    # populate the placement options frame.
    if (defined $Poptions) {
      my $f1 = $g->Labelframe(-text => "Stick to Which Container's Edge",
			     )->pack(qw/-side top -fill both -expand 0/);
      my $f2 = $g->Labelframe(-text => "Internal Padding",
			     )->pack(qw/-side top -fill both -expand 0/);
      my $f3 = $g->Labelframe(-text => "External Padding",
			     )->pack(qw/-side top -fill both -expand 0/);
      my $f4 = $g->Labelframe(-text => 'Apply Same Settings to ...',
			     )->pack(qw/-side top -fill both -expand 0/);

      for my $ref ([qw/North n/],
		   [qw/South s/],
		   [qw/East  e/],
		   [qw/West  w/]
		  ) {

	$Poptions->{$ref->[1]} ||= '';

	$f1->Checkbutton(-text        => $ref->[0],
			 -onvalue     => $ref->[1],
			 -offvalue    => '',
			 -borderwidth => 1,
			 -variable    => \$Poptions->{$ref->[1]},
			 -font        => 'OptionText',
			 -command  => sub {
			   $Poptions->{-sticky} = join '' => @{$Poptions}{qw/n s e w/};
			 })->pack(qw/-side top -anchor w/);
      }

      tie $Poptions->{-sticky} =>
	'ZooZ::TiedVar', $widget, '', 'grid', '-sticky';

      my $row = 0;
      for my $ref (['Horizontal', '-ipadx'],
		   ['Vertical',   '-ipady'],
		  ) {

	$Poptions->{$ref->[1]} ||= 0;

	my $label = ZooZ::Options->addOptionGrid(
						 $ref->[1],
						 $ref->[0],
						 $f2,
						 $row,
						 0,
						 \$Poptions->{$ref->[1]},
						);

	tie $Poptions->{$ref->[1]} =>
	  'ZooZ::TiedVar', $widget, 0, 'grid', $ref->[1], $label;

	$row++;
      }

      $row = 0;
      for my $ref (['Horizontal', '-padx'],
		   ['Vertical',   '-pady'],
		  ) {

	$Poptions->{$ref->[1]} ||= 0;

	my $label = ZooZ::Options->addOptionGrid(
						 $ref->[1],
						 $ref->[0],
						 $f3,
						 $row,
						 0,
						 \$Poptions->{$ref->[1]},
						);

	tie $Poptions->{$ref->[1]} =>
	  'ZooZ::TiedVar', $widget, 0, 'grid', $ref->[1], $label;

	$row++;
      }

      $_->gridColumnconfigure(0, -weight => 1) for $f2, $f3;
      $_->gridColumnconfigure(1, -weight => 5) for $f2, $f3;

      my $duplicate = 'All Widgets';
      $f4->BrowseEntry(
		       -choices => [
				    'All Widgets',
				    'Similar Widgets',
				    'All Widgets in Same Row',
				    'All Widgets in Same Column',
				    'Similar Widgets in Same Row',
				    'Similar Widgets in Same Column',
				   ],
		       -state   => 'readonly',
		       -variable => \$duplicate,
		       -disabledforeground => 'black',
		      )->pack(qw/-side top -fill x -padx 10 -pady 10/);
      $f4->Button(-text    => 'Apply',
		  -command => [$project, 'duplicatePlacementOptions', \$duplicate],
		 )->pack(qw/-fill x/);
    }

    # populate the extra options frame
    if (defined $Eoptions) {
      # First, the scrollbars options.
      my $f1 = $h->Labelframe(-text => 'Scrollbars',
			     )->pack(qw/-side top -fill both -expand 0/);

      $Eoptions->{$_} = 0  for qw/SCROLLON HOPTIONAL VOPTIONAL/;
      $Eoptions->{$_} = '' for qw/HSCROLLLOC VSCROLLLOC/;

      my $scrollCB = $f1->Checkbutton(-text     => 'Enable Scrollbars',
				      -variable => \$Eoptions->{SCROLLON},
				      -font     => 'OptionText',
				     )->pack(qw/-side top/);

      my $f11 = $f1->Frame(-relief      => 'sunken',
			   -borderwidth => 1,
			  )->pack(qw/-side top -fill both -expand 1/);

      $f11->Label(-text => 'Horizontal',
		 )->grid(-column => 0, -row => 1, -sticky => 'w');

      $f11->Checkbutton(-text     => 'Display Only if Needed',
			-variable => \$Eoptions->{HOPTIONAL},
			-font     => 'OptionText',
		       )->grid(-column => 1,
			       -row    => 1,
			       -sticky => 'w',
			       -columnspan => 3,
			      );
      $f11->Radiobutton(-text     => 'North',
			-value    => 'n',
			-variable => \$Eoptions->{HSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 1,
			       -row    => 2,
			       -sticky => 'ew');
      $f11->Radiobutton(-text     => 'South',
			-value    => 's',
			-variable => \$Eoptions->{HSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 2,
			       -row    => 2,
			       -sticky => 'ew');
      $f11->Radiobutton(-text     => 'None',
			-value    => '',
			-variable => \$Eoptions->{HSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 3,
			       -row    => 2,
			       -sticky => 'ew');

      $f11->Label(-text => 'Vertical',
		 )->grid(-column => 0, -row => 3, -sticky => 'w');

      $f11->Checkbutton(-text     => 'Display Only if Needed',
			-variable => \$Eoptions->{VOPTIONAL},
			-font     => 'OptionText',
		       )->grid(-column => 1,
			       -row    => 3,
			       -sticky => 'w',
			       -columnspan => 3,
			      );
      $f11->Radiobutton(-text     => 'East',
			-value    => 'e',
			-variable => \$Eoptions->{VSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 1,
			       -row    => 4,
			       -sticky => 'ew');
      $f11->Radiobutton(-text     => 'West',
			-value    => 'w',
			-variable => \$Eoptions->{VSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 2,
			       -row    => 4,
			       -sticky => 'ew');
      $f11->Radiobutton(-text     => 'None',
			-value    => '',
			-variable => \$Eoptions->{VSCROLLLOC},
			-font     => 'OptionText',
		       )->grid(-column => 3,
			       -row    => 4,
			       -sticky => 'ew');

      $f11->gridColumnconfigure(0, -weight => 1);

      # start with all disabled.
      $_->configure(-state => 'disabled') for $f11->children;

      # Tie the variables.
      # Whenever the SCROLLON value changes, enable/disable the options.
      Tie::Watch->new(
		      -variable => \$Eoptions->{SCROLLON},
		      -store    => [\&scrollState, $Eoptions, $widget, $f11],
		     );

      # Show appropriate scrollbars when chosen.
      Tie::Watch->new(
		      -variable => \$Eoptions->{HSCROLLLOC},
		      -store    => [\&addScrolls, $Eoptions, $widget],
		     );

      Tie::Watch->new(
		      -variable => \$Eoptions->{VSCROLLLOC},
		      -store    => [\&addScrolls, $Eoptions, $widget],
		     );

      # is it scrollable?
      $scrollCB->configure(-state => 'disabled') unless $scroll;
    }

  }

  # configure the window title
  my $top = $TOPLEVEL{configureWidget};
  $top->title("Configure Widget - Project $projid");

  return if $noforce && !$top->ismapped;

  # display the correct frames in the notebook.
  $_->packForget for map $_->packSlaves => (
					    $CONFDATA{NBPLACE},
					    $CONFDATA{NBWIDGET},
					    $CONFDATA{NBEXTRA}
					   );

  $_->pack(qw/-fill both -expand 1/) for @{$CONFDATA{FORMS}{$projid}{$name}};

  # set the state of the tabs.
  $CONFDATA{NB}->pageconfigure(NBPLACE => -state => defined $Poptions ? 'normal' : 'disabled');
  $CONFDATA{NB}->pageconfigure(NBEXTRA => -state => defined $Eoptions ? 'normal' : 'disabled');

  # pop-up the window if we have to.
  unless ($top->ismapped) {
    $top->deiconify;
    $top->geometry($top->reqwidth . 'x500');
  }
  $top->raise;
}

sub scrollState {
  my ($self, $val) = @_;

  $self->Store($val);

  my $args = $self->Args('-store');
  my $o    = shift @$args;
  my $w    = shift @$args;

  $_->configure(-state => $val ? 'normal' : 'disabled')
    for map $_->children => @$args;

  $w->configure(-scrollbars => $val ? "$o->{HSCROLLLOC}$o->{VSCROLLLOC}" : '');
}

sub addScrolls {
  my ($self, $val) = @_;

  $self->Store($val);
  my $args = $self->Args('-store');

  my ($o, $w) = @$args;
  my $h = $o->{HSCROLLLOC};
  my $v = $o->{VSCROLLLOC};

  $w->configure(-scrollbars => "$h$v");
}

sub chooseFont {
  my ($class, $ref) = @_;

  # update the list.
  {
    $FONTDATA{list}->delete(qw/0 end/);
    $FONTDATA{list}->insert(end => $_) for
      'Default', grep $_ ne 'Default' => sort $::FONTOBJ->listAll;
  }

  $FONTDATA{localReturn} = '';
  $TOPLEVEL{chooseFont}->deiconify;
  $TOPLEVEL{chooseFont}->grab;
  $TOPLEVEL{chooseFont}->waitVariable(\$FONTDATA{localReturn});
  $TOPLEVEL{chooseFont}->grabRelease;
  $TOPLEVEL{chooseFont}->withdraw;

  return $FONTDATA{localReturn};
}

sub chooseVar {
  my ($class, $ref) = @_;

  # update the list.
  {
    $VARDATA{list}->delete(qw/0 end/);
    $VARDATA{list}->insert(end => $_) for $::VARREFOBJ->listAll;
  }

  $VARDATA {localReturn} = '';
  $TOPLEVEL{chooseVarRef}->deiconify;
  $TOPLEVEL{chooseVarRef}->grab;
  $TOPLEVEL{chooseVarRef}->waitVariable(\$VARDATA{localReturn});
  $TOPLEVEL{chooseVarRef}->grabRelease;
  $TOPLEVEL{chooseVarRef}->withdraw;

  return $VARDATA{localReturn};
}

sub chooseCallback {
  my ($class, $ref) = @_;

  # update the list.
  {
    $CBDATA{list}->delete(qw/0 end/);
    $CBDATA{list}->insert(end => $_) for $::CALLBACKOBJ->listAll;
  }

  $CBDATA  {localReturn} = '';
  $TOPLEVEL{chooseCallback}->deiconify;
  $TOPLEVEL{chooseCallback}->grab;
  $TOPLEVEL{chooseCallback}->waitVariable(\$CBDATA{localReturn});
  $TOPLEVEL{chooseCallback}->grabRelease;
  $TOPLEVEL{chooseCallback}->withdraw;

  return $CBDATA{localReturn};
}

sub configureSampleFont {
  my $sample = shift;

  $sample->configure(
		     -font => [$FONTDATA{family},
			       $FONTDATA{size},
			       $FONTDATA{weight},
			       $FONTDATA{slant},
			       $FONTDATA{underline}  ? 'underline'  : (),
			       $FONTDATA{overstrike} ? 'overstrike' : ()],
		    );

}

sub cancelForm {
  my $h = shift;

  $h->{localReturn} = '';
}

sub cancelAllForms {
  cancelForm($_) for \%VARDATA, \%CBDATA, \%FONTDATA;
}

sub setup_configureRowCol {
  my ($class, $top) = @_;

  $ROWCOLDATA{title} =
    $top->Label(-font   => [helvetica => 12],
		-fg     => 'darkolivegreen',
		-bg     => 'white',
		-bd     => 1,
		-relief => 'ridge',
		-pady   => 5,
	       );
}

sub configureRowCol {
  my ($class,
      $projid,    # project id.
      $hier,      # current hierarchy
      $widget,    # preview top.
      $rowORcol,  # whether 'row' or 'col'
      $index,     # row or col number.
      $options,   # options hash
     ) = @_;

  unless (exists $ROWCOLDATA{$projid}{$hier}{$rowORcol}[$index]) {
    my $f = $TOPLEVEL{configureRowCol}->Frame;

    # populate it.
    my $row = 0;
    for my $ref (
		 ['Extra Space Greediness', '-weight',  0],
		 ['Minimum Size',           '-minsize', 0],
		 ['Extra Padding',          '-pad',     0],
		) {

      $options->[$index]{$ref->[1]} ||= $ref->[2];

      my $label = ZooZ::Options->addOptionGrid($ref->[1],
					       $ref->[0],
					       $f,
					       $row,
					       0,
					       \$options->[$index]{$ref->[1]},
					      );

      my $default = $options->[$index]{$ref->[1]};

      tie $options->[$index]{$ref->[1]}, 'ZooZ::TiedVar', $widget, $default,
	($rowORcol eq 'row' ? 'gridRowconfigure' :
	 'gridColumnconfigure'),
	   $ref->[1], $label, [$index];

      # update the value. This will call the callback.
      $options->[$index]{$ref->[1]} = $options->[$index]{$ref->[1]};

      $row++;
    }

    $ROWCOLDATA{$projid}{$hier}{$rowORcol}[$index] = $f;
  }

  my $top = $TOPLEVEL{configureRowCol};
  $_->packForget for $top->packSlaves;

  # fix and pack the title.
  $ROWCOLDATA{title}->pack(qw/-fill both -expand 1/);
  $ROWCOLDATA{title}->configure(-text => "Configuring $hier \u$rowORcol $index");

  # now pack the form.
  $ROWCOLDATA{$projid}{$hier}{$rowORcol}[$index]->pack(qw/-fill both -expand 1/);
  $top->title("Configure \u$rowORcol $index - Project $projid");

  $top->deiconify;
  $top->update;
  $top->geometry($top->reqwidth . 'x' . $top->reqheight);
  $top->raise;
}

1;
