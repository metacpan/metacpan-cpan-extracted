package TidyView::Options;

use strict;
use warnings;

# handles the GUI part of representing options

# PerlTidy::Options handles what options that are available, and their 'type', TidyView::Options draws them

# we have, if you will an MVC type pattern with PerlTidy::Options as the model,
# and TidyView::Options as the view. TidyView::Run is the controller

use PerlTidy::Options;
use TidyView::Frame;

use Tk;
use Tk::BrowseEntry;

use Data::Dumper;

use Log::Log4perl qw(get_logger);

=pod

TidyView::Options - responsible for all the rendering tasks of the options supplied from PerlTidy::Options

TidyView::Options and PerlTidy::Options co-operate closely, but TidyView's main focus is to render options and
collect any values a user may place in an options widget. PerlTidy::Options is responsible for knowing what options
tidyview knows about. Currently TidyView::Options is responsible for formatting the string that
ultimately gets written into a .perltidyrc file - mainly because it holds all the values set by the user.

=cut

# each of these holds the widget instances, e.g. every checkbox widget instance is in the %checkButtons hash, etc
my %checkButtons;
my %spinButtons;
my %labEntries;
my %colors;
my %listBoxes;

# the top-level option types e.g. Whitespace control etc
my @sections;

my $sectionActive = 0; # expose this so we can ask what the current section is, so redraws can return to
# the same section

INIT {
 @sections = PerlTidy::Options->getSections(); # ask Perltidy what sections we should draw

 # Old Tk's dont support Tk::Spinbox at all. Hence we have several helper functions that "do
 # the right thing" for each version of Tk. We assign the appropriate set of functions to some
 # typeglobs in the INIT block, as that is the easiest way to check the Tk version just before we
 # get things going. At runtime, a call to __PACKAGE__->typeglobname() will call the right function

 # note that we replace Tk::Spinbox with Tk::Entry if we detect an old Tk->VERSION()

 # Note that this is the reason we introduced the dependency of 'use version' - the overloaded
 # stringification and relational operators make comparing versions trivial.

 if ($^O !~ m/(?:win32|cygwin)/i) {

   require version;

   die $@  if $@;

   import version qw(qv);

   if (qv(Tk->VERSION()) < "804.027") { # is an out-of-date Tk
     *_numericWidget = \&_numericAsTextbox;
   } else {                             # is an up-to-date  Tk
     *_numericWidget = \&_numericAsSpinbox;
   }
 } else { # is windows, which cant distinquish between Version.pm and version.pm,
          # and hence is cursed to use older Tk widgets.
   *_numericWidget = \&_numericAsTextbox;
 }
}

=pod

build($self, %args)

Takes a single argument in the %arg hash - parent, which is the Tk:Frame widget you want the
PerlTidy::Options rendered in. From there it asks a series of questions of PerlTidy::View about
sections and options in sections, and decides how best to render them. The look and feel of much of the
apploaction is controlled from here

=cut

# render the options for the currently selected selection
sub build {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($parent, $startSection) = @args{qw( parent startSection )};

  $logger->logdie("no parent") unless $parent;

  __PACKAGE__->_buildSelectedSections(
				      parent       => $parent,
				      startSection => $startSection,
				     );
}

sub buildFromConfig {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($config, $parent) = @args{qw(config parent)};

  # make sure we delete all the currently selected options
  %checkButtons = ();
  %spinButtons  = ();
  %labEntries   = ();
  %colors       = ();
  %listBoxes    = ();

  foreach my $option (keys %$config) {
    my $section = PerlTidy::Options->getSection(name => $option);

    $logger->logdie("no known section for option $option") unless $section;

    my $type = PerlTidy::Options->getValueType(
					       section => $section,
					       entry   => $option,
					      );

    $logger->logdie("no known value type for option $option in section $section") unless defined $type;

    my $category = __PACKAGE__->_getTypeCategory(type => $type);

    $logger->logdie("unknown category $category for option $option in section $section") unless $category;

    if (      $category eq 'checkbox' ) {
      $checkButtons{$option} = $config->{$option};
      next;
    } elsif ( $category eq 'integer'  ) {
      $spinButtons{$option}  = $config->{$option};
      next;
    } elsif ( $category eq 'string'   ) {
      $labEntries{$option}   = $config->{$option};
      next;
    } elsif ( $category eq 'colour'   ) {
      $colors{$option}       = $config->{$option};
      next;
    } elsif ( $category eq 'list'     ) {
      $listBoxes{$option}    = $config->{$option};
      next;
    }
  }

  # having reset the options, refresh the GUI

  foreach my $slave ($parent->packSlaves()) {
    $slave->packForget();
  }

  __PACKAGE__->build(
		     parent       => $parent,
		     startSection => $sectionActive, # dont redraw with section[0], look at where we are
		    );

  return;
}

# builds the options for selected section, and sets up a callback to use when the section changes
sub _buildSelectedSections {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($parent, $startSection) = @args{qw(parent startSection)};

  my $sectionsFrame = $parent->Frame()->pack(
					     -fill   => 'x',
					     -expand => 0,
					    );

  # TODO - make the text widget (not the listbox widget
  my $browser = $parent->BrowseEntry(
				     -label           => "Formatting Section",
				     -autolimitheight => 1,
				     -autolistwidth   => 1,
				     -browsecmd       => __PACKAGE__->_createDrawSectionCallback($sectionsFrame),
				     -choices         => \@sections,
				     -listheight      => scalar(@sections),
				    )->pack(
					    -side   => 'top',
					    -anchor => 'w',
					    -before => $sectionsFrame,
					   );

  my $startValue = $startSection || 0;

  # set section in drop list to active section (otherwise if floats back to the top by default

  my $thisListbox = $browser->Subwidget('slistbox')->Subwidget('listbox');

  $thisListbox->activate($startValue);

  $thisListbox->focus();

  $thisListbox->see($startValue);

  # after all that we also need to set the entry widget to our current value

  my $thisEntryWidget = $browser->Subwidget('entry');

  $thisEntryWidget->delete(0, 'end');

  $thisEntryWidget->insert(0, $sections[$startValue]);

  __PACKAGE__->_buildAllEntries(
				parent  => $sectionsFrame,
				section => $sections[$startSection || 0],
			       );

  return;
}

# build the options for the requested section, providing a frame for each option set (all the checkboxes together, all lists together etc...)
sub _buildAllEntries {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($parent, $section) = @args{qw(parent section)};

  # we should improve this to support future possible option type - i.e. dont hard-code it - capture it dynamically and ask a question when required
  (my %types) = map {$_ => []} qw(checkbox integer color string list);

  # the basic scheme for drawing the entries for a section is -
  # for each entry type (one of undef, string/flag, a number, color
  # or array, we create a frame that we pack to the left, and file from
  # the top

  # work out which values tyes we have, so we can draw frames for them
  foreach my $entry (PerlTidy::Options->getEntries(section => $section)) {
    my $valueType = PerlTidy::Options->getValueType(
						    section     => $section,
						    entry       => $entry,
						   );

    my $typeClass = __PACKAGE__->_getTypeCategory(type => $valueType);

    push @{$types{$typeClass}}, $entry;
  }

  # TODO - fold long option lists
  # sometimes, in one section, there is a very large number of options of one type
  # We want to spread these across the page a bit. So if there are more than
  # say 10 options of one type (type is the set (checkboxes posIntegers colors strings lists)
  # we create a new frame for each block of 10

  # now we know the value types, create a frame and pack the options with this option type in there
  # creates a frame for this option set, but only if there are any option in the set

  foreach my $type (sort grep {@{$types{$_}} > 0} keys %types) {

    my $typeFrame = TidyView::Frame->new(
					 parent       => $parent,
					 frameOptions => {
							  -relief      => 'sunken',
							  -borderwidth => 5,
							 },
					);

    foreach my $entry (sort @{$types{$type}}) {

      my $entryFrame = TidyView::Frame->new(
					    parent       => $typeFrame,
					    frameOptions => {
							     -relief      => 'flat',
							     -borderwidth => 0,
							    },
					    packOptions  => {
							     -anchor => 'n',
							     -side   => 'top',
							     -fill   => 'x',
							     -expand => 0,
							    },
					   );

      # organise them by their type
      __PACKAGE__->_buildEntry(
			 section => $section,
			 entry   => $entry,
			 parent  => $entryFrame,
			);
    }
  }
  return;
}

# for an individual option, determine the best widget to draw it based on its entry type, and try to
# register its value to update a conveniently provided scalar reference - not all widgets can do this

sub _buildEntry {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($parent, $section, $entry) = @args{qw(parent section entry)};

  unless (defined $parent) {
    $logger->warn("invalid parent widget " . Dumper($parent) . "passed");
    return;
  }

  my $valueType = PerlTidy::Options->getValueType(
						  section     => $section,
						  entry       => $entry,
						  asReference => 1,
						 );

  my $valueClass = ref($valueType) || $valueType;

  my $typeClass = __PACKAGE__->_getTypeCategory(type => $valueClass);

  my $defaultValue = PerlTidy::Options->getDefaultValue(entry => $entry);

  $logger->error("no default entry for $entry") unless defined $defaultValue;

  if ( $typeClass eq 'checkbox')          { # simple checkbox required

    $parent->Label(-text => $entry)->pack(
					  -side => 'left',
					 );

    # change to support the -variable option...
    $parent->Checkbutton(
			 -variable => \$checkButtons{$entry},
			)->pack(
				-side => 'right',
				-fill => 'both',
			       );

    unless (defined $checkButtons{$entry}) {
      $checkButtons{$entry} = $defaultValue;
    }

  } elsif ( $typeClass eq 'string' )     { # text box input required

    $parent->Label(-text => $entry)->pack(
					  -side   => 'left',
					  -anchor => 'n',
					 );

    $parent->Entry(-textvariable => \$labEntries{$entry})->pack(
								-side   => 'right',
								-anchor => 'n',
							       );

    $labEntries{$entry} ||= $defaultValue;
  } elsif ( $typeClass eq 'integer') { # integer up/down input required

    $parent->Label(-text => $entry)->pack(
					  -side => 'left',
					 );

    my $value;
    if (exists $spinButtons{$entry} and defined $spinButtons{$entry}) {
      $value = $spinButtons{$entry};
    } else {
      $value = $defaultValue;
    }

    __PACKAGE__->_numericWidget($parent, $entry, $value);

  } elsif ($typeClass eq 'list')      { # dropdown list inpuit required
    $parent->Label(-text => $entry)->pack(
					  -side   => 'left',
					  -anchor => 'n',
					 );

    # some valueTypes are lists of values e.g. (dos, unix, mac) and some are ranges e.g. (0,3)
    # create a list of values if a range
    my $listValue = __PACKAGE__->_mapRangeToList($valueType);

    my $browser = $parent->BrowseEntry(
				       -autolimitheight => 1,
				       -autolistwidth   => 1,
				       -browsecmd       => __PACKAGE__->_generateBrowseListCallback($entry),
				       -choices         => $listValue,
				       -listheight      => scalar(@$listValue),
				      )->pack(
					      -side   => 'right',
					      -anchor => 'w',
					     );

    my $thisListbox = $browser->Subwidget('slistbox')->Subwidget('listbox');

    my $index;
    if (exists $listBoxes{$entry} and defined $listBoxes{$entry}) {
      $index = $listBoxes{$entry};
    } else {
      $index = 0;
    }

    $thisListbox->activate($index);

    $thisListbox->focus();

    $thisListbox->see($index);

    # after all that we also need to set the entry widget to our current value

    my $thisEntryWidget = $browser->Subwidget('entry');

    $thisEntryWidget->delete(0, 'end');

    $thisEntryWidget->insert(0, $index);

  } elsif ( $typeClass eq 'color' )      { # color dialog input required
    $colors{$entry} = $parent->Button(
				      -text    => "Choose $entry color",
				      -command => __PACKAGE__->_generateColorCallback($parent, $entry),
				     )->pack(
					     -side   => 'left',
					     -anchor => 'n',
					    );

  } else                          {
    $logger->logdie("Unsupported value type -> $typeClass");
  }

  return;
}

sub _generateBrowseListCallback {
  my (undef, $entry) = @_;

  return sub {
    my ($browser, $value) = @_;

    my $logger = get_logger((caller(0))[3]);

    $listBoxes{$entry} = $value;

    my $thisListbox = $browser->Subwidget('slistbox')->Subwidget('listbox');

    # uses the fact that all lists are numeric from 0..X

    my $index = (exists $listBoxes{$entry} and defined $listBoxes{$entry}) ? $listBoxes{$entry} : 0;

    $thisListbox->activate($index);

    $thisListbox->focus();

    $thisListbox->see($index);

    # after all that we also need to set the entry widget to our current value

    my $thisEntryWidget = $browser->Subwidget('entry');

    $thisEntryWidget->delete(0, 'end');

    $thisEntryWidget->insert(0, $index);
  };
}

sub _generateColorCallback {
  my (undef, $parent, $entry) = @_;

  return sub {
    $colors{$entry} = $parent->chooseColor(-title => $entry);
  };
}

sub _createDrawSectionCallback {
  my (undef, $sectionFrame) = @_;

  return sub {
    my (undef, $section) = @_;

    my $logger = get_logger((caller(0))[3]);

    ($sectionActive) = ($section =~ m/^(\d+)\./);
    $sectionActive--;

    # empty all widgets from old section from the section frame,
    # then draw widgets for new section in the section frame.

    foreach my $slave ($sectionFrame->packSlaves()) {
      $slave->destroy();
    }

    __PACKAGE__->_buildAllEntries(
				  parent  => $sectionFrame,
				  section => $section,
				 );
  };
}

=pod

asembleOptions(undef, %args) - responsible for formatting the user-selected options into
a format usable as a .perltidyrc file. Returns a string suitable for writing to a .perltidyrc file.

Removes any options that have the same value as the perltidy default, to minimise the length of the
resulting .perltidyrc file

Takes one argument currently in the %args hash - separator. Used to spearate the options in formatting.
Most commonly set to "\n" so that options appear one-per-line - additionally, if it is "\n", then additional
comments appear in the resultant string. Should probably be set to a whitespace of sime kind. If not supplied,
separator defaults to ' '.

=cut

sub assembleOptions {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($separator) = @args{qw(separator)};

  $separator ||= ' ';

  my $optionString = '';

  # add a nice comment for the file-based output
  $optionString .= "\n# ON-OFF style options\n\n" if $separator eq "\n";

  # values in the %checkButtons
  $optionString .= __PACKAGE__->_generateCheckboxOptions($separator);

  $optionString .= "\n# Numeric-value style options\n\n" if $separator eq "\n";

  # values in the %spinButtons are the value spun too
  $optionString .= join('',
			map  { "--$_=$spinButtons{$_} $separator" }
			grep {__PACKAGE__->_differentToDefault(
							       name         => $_,
							       currentValue => $spinButtons{$_},
							      )}
			sort keys %spinButtons);

  $optionString .= "\n# Text-value style options\n\n" if $separator eq "\n";

  # values in the %labEntries are the value entered by the user (or the default) only assemble those that are defined
  # and not '' (0 and '0' are OK (true but 0) values

  $optionString .= join('',
			map  { defined($labEntries{$_}) and $labEntries{$_} ne '' ? "--$_='$labEntries{$_}' $separator" : "" }
			grep {__PACKAGE__->_differentToDefault(
							       name         => $_,
							       currentValue => $labEntries{$_},
							      )}
			sort keys %labEntries);

  $optionString .= "\n# Color options\n\n" if $separator eq "\n";

  # values in the %colors are the value selected in the dialogue, or the button widget - output scalars only
  $optionString .= join('',
			map  { "--$_=$colors{$_} $separator" }
			grep { not ref($colors{$_}) and __PACKAGE__->_differentToDefault(
											 name         => $_,
											 currentValue => $colors{$_},
											)}
			sort keys %colors);

  $optionString .= "\n# List-selection style options\n\n" if $separator eq "\n";

  # values in the %listBoxes are the value selected in the dropdown or the default
  $optionString .= join('',
			map  { "--$_=$listBoxes{$_} $separator" }
			grep {__PACKAGE__->_differentToDefault(
							       name         => $_,
							       currentValue => $listBoxes{$_},
							      )}
			sort keys %listBoxes);

  return $optionString;
}

=pod

storeUnsupportOptions(undef, %args) - responsible for storing away any optiosn specified that
supported by the GUI - these are options that support perltidy itself, or debugging thereof.
Because these arent supported in the GUI, they get forgot, as ther are no widgets to hold them.
However we still need them when writing the perltidy options back out.

=cut

my %unsupportedOptions;

sub storeUnsupportedOptions {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($rawOptions) = @args{qw(rawOptions)};

  foreach my $option (keys %$rawOptions) {
    if (PerlTidy::Options->getSection(name => $option) =~ m/^(?:0|13)./) { # from unsupported section
      $unsupportedOptions{$option} = delete $rawOptions->{$option};
    }
  }
}

=pod

clearUnsupportedOptions(undef) - responsible for clearing away any options that were parsed
by perltidy, but for which we dont hold widgets for. Usually this is done just after reading
and parsing a new perltidy options file.

=cut

sub clearUnsupportedOptions {
  %unsupportedOptions = ();
}

sub assembleUnsupportedOptions {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($separator) = @args{qw(separator)};

  $separator ||= ' ';

  my $unsupportedOptionsString = '';

  # add a nice comment for the file-based output
  $unsupportedOptionsString .= "\n# options not supported by tidyview\n\n" if $separator eq "\n";

  foreach my $option (keys %unsupportedOptions) {
    my $type = __PACKAGE__->_getTypeCategory(type => PerlTidy::Options->getType(entry => $option));

    if ($type eq 'checkbox') {
      $unsupportedOptionsString .= "--$option $separator";
    } else {
      $unsupportedOptionsString .= "--$option=$unsupportedOptions{$option} $separator";
    }
  }

  return $unsupportedOptionsString;
}

# checkboxes need somewhat more specialised procesing in order to get their output right
sub _generateCheckboxOptions {
  my (undef, $separator) = @_;

  my $optionString = '';

  # output option string for values in the %checkButtons that differ from default
  foreach my $key (sort keys %checkButtons) {
    # if the option is the same as the default, we dont both outputting anything

    next unless __PACKAGE__->_differentToDefault(
						 name         => $key,
						 currentValue => $checkButtons{$key},
						);

    $optionString .= '--';

    # if the option is 0 or undef, then we need to output it as --noXXX, otherwise --XXX
    $optionString .= 'no-' unless $checkButtons{$key};

    $optionString .= "$key $separator";
  }

  return $optionString;
}

# Functions to support various versions of Tk widgets.

# older Tk's dont have a Spinbox, use a Textbox
sub _numericAsTextbox {
  my (undef, $parent, $entry, $value) = @_;

  my $numericWidget = $parent->Entry(-textvariable => \$labEntries{$entry})->pack(
										  -side   => 'right',
										  -anchor => 'n',
										 );

  $listBoxes{$entry} = $value;

  return $numericWidget;
}

# modern Tk's have this handy widget for numeric values
sub _numericAsSpinbox {
  my (undef, $parent, $entry, $value) = @_;

  my $numericWidget = $parent->Spinbox(-from            => 0,
				       -increment       => 1,
				       -text            => 10,
				       -to              => 1000,
				       -validatecommand => 0,
				       -textvariable    => \$spinButtons{$entry},
				      )->pack(
					      -side => 'right',
					     );

  $spinButtons{$entry} = $value;

  return $numericWidget;
}

# there are a few places where we need to map the type to a GUI widget - this function helps place all the
# different value types in one place

sub _getTypeCategory {
  my (undef, %args) = @_;

  my $logger = get_logger((caller(0))[3]);

  my ($type) = @args{qw(type)};

  if ( not defined $type or not $type or $type eq '!' ) {
    return 'checkbox';
  } elsif ($type =~ m/^(?:=s)$/) { # we dont support :s optional strings for now
    return 'string';
  } elsif ($type =~ m/^(?:=i)$/) { # we dont support :i optional integers for now
    return 'integer';
  } elsif ($type eq 'ARRAY') {
    return 'list';
    #     } elsif ($type eq 'color') {
    #       push @{$types{colors}}, $entry;
  } else {
    $logger->logdie("unknown entry type $type");
  }
}

# converts ranges of [x, y] to arrayref of [x, x+1, ..., y-1, y]
sub _mapRangeToList {
  my (undef, $range) = @_;

  if (ref($range) eq 'ARRAY'      and
      @$range == 2                and
      $range->[0] =~ m/^(?:\d+)$/ and
      $range->[1] =~ m/^(?:\d+)$/ and
      $range->[0] < $range->[1]) { # check the range is well-formed
    return [($range->[0]..$range->[1])];
  } {
    return $range;
  }
}

sub _differentToDefault {
  my (undef, %args) = @_;

  my ($name, $currentValue) = @args{qw(name currentValue)};

  return 1 unless defined $name; # say its different, cause we cant compare it to anything

  return 1 unless defined $currentValue; # different to any possible default

  my $defaultValue = PerlTidy::Options->getDefaultValue(entry => $name);

  return 1 unless defined $defaultValue; # doesnt have a default, hence is always different

  return $defaultValue ne $currentValue; # compare everything as a string
}

1;
