package Tk::QuickForm;

=head1 NAME

Tk::QuickForm - Quickly set up a form.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.08';

use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'QuickForm';

require Tk::LabFrame;
require Tk::NoteBook;
require Tk::PopColor;
#require Tk::FilePicker;
use Tk::PNG;


=head1 SYNOPSIS

 require Tk::QuickForm;
 my $form= $window->QuickForm(@options,
    -structure => [
       '*page' => 'Page name', #Adds a new page to the notebook. Creates the notebook if needed.
       '*section' => 'Section name', #Adds a new section.
       some_list => ['radio', 'My values', -values => \@listvalues], #Adds an array of radio buttons.
       '*end', #Ends a section or frame.
       '*column', #Starts a new column of fields
       '*expand', #Expand the next entry in height.
    ]
 )->pack;
 $form->createForm;

=head1 DESCRIPTION

This widget allows you to quickly set up a form for the user to fill out or modify.
Attempts are made to make it clear and elegant.

Inherits L<Tk::Frame>. With the B<-structure> option you can define
fields the user can modify as well as its layout. 

With the B<put> and B<get> methods you can set or retrieve values as a hash.

=head1 OPTIONS

=over 4

=item Switch: B<-acceptempty>

Default value 0. If set the validate method will not trigger on
fields containing empty strings.

=item Switch: B<-autovalidate>

By default 1. Validate the form whenever an entry changes value.

=item Switch: B<-fileimage>

Set an image object for I<file> items. By default it is the file icon from Tk.

=item Switch: B<-folderimage>

Set an image object for I<folder> items. By default it is the folder icon from Tk.

=item Switch: B<-fontimage>

Set an image object for I<folder> items. By default it is the I<font_icon.png> in this package.

=item Switch: B<-postvalidatecall>

Set this callback if you want to take action on the validation result.

=item Switch: B<-structure>

You have to set this option. This is the example we use in our testfile:

 [
    *page' => 'Arrays',
    '*section' => 'List',
    -set_list_command => ['list', 'List command test', -values => sub { return @listvalues } ],
    -set_list_values => ['list', 'List values test', -values => \@listvalues],
    '*end',
    '*section' => 'Radio',
    -set_radio_command => ['radio', 'Radio Command test', -values => sub { return @radiovalues }],
    -set_radio_values => ['radio', 'Radio values test', -values => \@radiovalues],
    '*end',
    '*page' => 'Scalars',
    '*section' => 'Numbers',
    -set_boolean => ['boolean', 'Boolean test'],
    -set_float => ['float', 'Float test'],
    -set_integer => ['integer', 'Integer test'],
    '*end',
    '*section' => 'Scale and Spin',
    -set_scale => ['scale', 'Scale test'],
    -set_spin => ['spin', 'Spinbox test'],
    '*end',
    '*section' => 'Files',
    -set_file => ['file', 'File test'],
    -set_folder => ['folder', 'Folder test'],
    '*end',
    '*column',
    '*section' => 'Colors and fonts',
    -set_color => ['color', 'Color test'],
    -set_font => ['font', 'Font test'],
    '*end',
    '*section' => 'Free text',
    -set_text => ['text', 'Text test'],
    '*end',
    '*page' => 'User defined',
    '*section' => 'Scale',
    -set_scale10 => ['scale10', 'Scale 10 test'],
    '*end',
    '*section' => 'Boolean',
    -set_onoff => ['onoff', 'On/Off 10 test', -offvalue => 'Uit', -onvalue => 'Aan'],
    '*end',
    '*section' => 'Text',
    -set_https => ['https', 'Web link'],
   '*end',
    '*page' => 'External',
    '*section' => 'Single column',
    -set_ext1 => ['ext1', 'External color test', 'Tk::QuickForm::CColorItem'],
    '*end',
    '*expand',
    '*section' => 'Double column',
    '*expand',
    -set_ext2 => ['ext2', 'MyExternal',	-height => 8, -width => 40],
    '*end',
 ],

Only available at create time. See below.

=item Switch: B<-types>

Add a list of user defined types.

Only available at create time. See below.

=back

=head1 FILE DIALOG OPTIONS

A number of config variables are forwarded to the file dialog widget used
in this module. Look in L<Tk::FilePicker> and L<Tk::FileBrowser> for their meaning.
They are:

=over 4

=item B<-diriconcall>

=item B<-fileiconcall>

=item B<-linkiconcall>

=item B<-msgimage>

=item B<-newfolderimage>

=item B<-reloadimage>

=item B<-warnimage>

=back

=head1 THE STRUCTURE OPTION


The I<-structure> option is a list that basically looks like:

 [
    $switch => $option,
    $key => [$type, $label, @options],
    ...
 ]


B<SWITCHES>

$switch can have the following values:

=over 4

=item B<*page>

Creates a NoteBook widget if needed and adds a page with the name in $option.

=item B<*section>

Creates a new section with the name in $option as label on a L<Tk::LabFrame>.
You can create nested sections.

=item B<*frame>

Similar to B<*section> just does not take a name parameter. Useful for dividing
the space.

=item B<*column>

Starts a new set of colums at row 0; Does not take a parameter.

=item B<*end>

Ends current section. Does not take a parameter.

=item B<*expand>

Verically expands the next item in the list. Does not take a parameter.

=back

B<TYPES>

By default the following types are defined:

=over 4

=item B<boolean>

mycheck => ['boolean', 'My check', @options],

Creates a Checkbutton item.

=item B<color>

mycolor => ['color', 'My color', @options],

Creates an ColorEntry item. See L<Tk::ColorEntry>.

=item B<ext1>

 myexternal => ['ext1', 'My external', 'Full::Class::Name', @options],

Adds an external class. See below at B<USER DEFINED TYPES>.

=item B<ext2> 

 myexternal => ['ext2', 'Full::Class::Name', @options],

Same as B<ext1> except it occupies all columns. See below at B<USER DEFINED TYPES>.

=item B<file>

 myfile => ['file', 'My file', @options],

Creates an Entry item with a button initiating a file dialog.

=item B<float>

 myfloat => ['float', 'My float', @options],

Creates an Entry item that validates a floating value.

=item B<folder>

 mydir => ['folder', 'My folder', @options],

Creates an Entry item with a button initiating a folder dialog.

=item B<font>

 myfont => ['font', 'My font', @options],

Creates an Entry item with a button initiating a font dialog.

=item B<integer>

 myinteger => ['integer', 'My integer', @options],

Creates an Entry item that validates an integer value.

=item B<list>

 mylist => ['list', 'My list', -values => \@values],
 mylist => ['list', 'My list', -values => sub { return @values }],

Creates a ListEntry item. See L<Tk::ListEntry>.

=item B<radio>

 myradio => ['radio', 'My radio', -values => \@values],
 myradio => ['radio', 'My radio', -values => sub { return @values }],

Creates a row of radiobuttons.

=item B<scale>

 myscale => ['scale', 'My scale', @options],

Creates a Scale item.

=item B<spin>

 myspin => ['spin', 'My spin', @options],

Creates a Spinbutton item.

=item B<text>

 mytext => ['text', 'My text', @options],

Creates an Entry item.

=back

B<USER DEFINED TYPES>

The B<-types> option lets you add your own item types.
Specify as follows:

 $window->QuickForm(
	-structure => [..],
	-types => [
		type1 => ['ClassName1', @options1]
		type2 => ['ClassName2', @options2]
	]
	
 );

This may or make not make life easier.

You may prefer to use a class derived from L<Tk::QuickForm::CBaseClass>. However, any class will do as long as:

- It is a valid Tk megawidget

- It accepts a callback option B<-validatecall>,

- It has a B<put>, B<get>, and a B<validate> method.

This also applies to external classes in the B<ext1> and B<ext2> types.


=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $types = delete $args->{'-types'};

	$self->SUPER::Populate($args);

	$self->{LABELS} = {};
	$self->{OPTIONS} = {};
	$self->{TYPES} = {
		boolean => ['Tk::QuickForm::CBooleanItem', -onvalue => 1, -offvalue => 0],
		color => ['Tk::QuickForm::CColorItem'],
		file => ['Tk::QuickForm::CFileItem', -image => '-fileimage'],
		float => ['Tk::QuickForm::CFloatItem', ],
		folder => ['Tk::QuickForm::CFolderItem', -image => '-folderimage'],
		font => ['Tk::QuickForm::CFontItem', -image => '-fontimage'],
		'integer' => ['Tk::QuickForm::CTextItem', -regex => '^-?\d+$'],
		list => ['Tk::QuickForm::CListItem'],
		radio => ['Tk::QuickForm::CRadioItem'],
		scale => ['Tk::QuickForm::CScaleItem', -from => 0, -to => 100],
		spin => ['Tk::QuickForm::CSpinItem', -from => 0, -to => 100, -regex => '^-?\d+$'],
		text => ['Tk::QuickForm::CTextItem'],
	};
	if (defined $types) {
		while (@$types) {
			my $opt = shift @$types;
			my $val = shift @$types;
			$self->{TYPES}->{$opt} = $val; 
		}
	}

	$self->gridColumnconfigure(0, -weight => 1);
	$self->gridColumnconfigure(1, -weight => 1);

	my $fil_icon = $self->Pixmap(-file => Tk->findINC('file.xpm'));
	my $dir_icon = $self->Pixmap(-file => Tk->findINC('folder.xpm'));
	my $fon_icon = $self->Photo(-file => Tk->findINC('font_icon.png'), -format => 'PNG');
	
	$self->ConfigSpecs(
		-acceptempty => ['PASSIVE', undef, undef, 0],
		-autovalidate => ['PASSIVE', undef, undef, 1],
		-background => ['SELF', 'DESCENDANTS'],
		-colorhistoryfile => ['PASSIVE'],
		-diriconcall => ['PASSIVE'],
		-fileiconcall => ['PASSIVE'],
		-fileimage => ['PASSIVE', undef, undef, $fil_icon],
		-folderimage => ['PASSIVE', undef, undef, $dir_icon],
		-fontimage => ['PASSIVE', undef, undef, $fon_icon],
		-linkiconcall => ['PASSIVE'],
		-listcall => ['CALLBACK', undef, undef, sub {}],
		-msgimage => ['PASSIVE'],
		-newfolderimage => ['PASSIVE'],
		-postvalidatecall => ['CALLBACK', undef, undef, sub {}],
		-reloadimage => ['PASSIVE'],
		-structure => ['PASSIVE', undef, undef, []],
		-tabside => ['PASSIVE', undef, undef, 'top'],
		-warnimage => ['PASSIVE'],
		DEFAULT => ['SELF'],
	);
}

=head1 METHODS

=over 4

=cut

sub CreateClass {
	my $self = shift;
	my $holder = shift;
	my $class = shift;
	eval "require $class";
	while ($class =~ s/.*[\:\:]//) {}
	return $holder->$class(@_);
}

=item B<createForm>

Call this method after you created the B<Tk::QuickForm> widget.
It will create all the pages, sections and entries.

=cut

sub createForm {
	my $self = shift;
	my @holderstack = ({
		offset => 0,
		holder => $self,
		row => 0,
		type => 'root',
	});
	my $notebook;
	my $popcolor;

	my $structure = $self->cget('-structure');
	my @options = @$structure;
	my $labelwidth = 0;
	while (@options) {
		my $key = shift @options;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @options;
			next;
		}
		next if ($key eq '*end') or ($key eq '*column') or ($key eq '*expand') or ($key eq '*frame');
		my $conf = shift @options;
		my $l = length $conf->[1];
		unless ($conf->[0] eq 'ext2') { $labelwidth = $l if $l > $labelwidth; }
	}

	my %options = ();
	my %labels = ();
	my @padding = (-padx => 2, -pady => 2);

	@options = @$structure;
	while (@options) {
		my $key = shift @options;

		if ($key eq '*page') {
			my $label = shift @options;
			my $holder = $holderstack[0]->{holder};
			my $row = $holderstack[0]->{row};
			unless (defined $notebook) {
				$holder->gridRowconfigure($row, -weight => 1);
				$notebook = $holder->NoteBook(
# 					-borderwidth => 1,
				)->grid(
					-column => 0, 
					-row => $row, 
					-columnspan => 2, 
					-sticky => 'nsew'
				);
				$self->{NOTEBOOK} = $notebook;
			}
			my $page = $notebook->add($label, -label => $label);
			my $h = $page->Frame->pack(-fill => 'x');
			$h->gridColumnconfigure(1, -weight => 1);
			$holderstack[0]->{row} ++;
			unshift @holderstack, {
				holder => $h,
				offset => 0,
				row => 0,
				type => 'page',
			};

		} elsif ($key eq '*section') {
			my $label = shift @options;
			my $h = $holderstack[0];
			my $offset = $h->{offset};
			my $lf = $h->{holder}->LabFrame(
				-label => $label,
				-labelside => 'acrosstop',
			)->grid(@padding, -column => 0 + $offset, -row => $h->{row}, -columnspan => 2, -sticky => 'nsew');
			$lf->gridColumnconfigure(1, -weight => 1);
			$holderstack[0]->{row} ++;
			unshift @holderstack, {
				holder => $lf,
				offset => 0,
				row => 0,
				type => 'section',
			};
			
		} elsif ($key eq '*frame') {
			my $h = $holderstack[0];
			my $offset = $h->{offset};
			my $f = $h->{holder}->Frame->grid(@padding, 
				-column => 0 + $offset, 
				-row => $h->{row}, 
				-columnspan => 2, 
				-sticky => 'nsew',
			);
			$f->gridColumnconfigure(1, -weight => 1);
			$holderstack[0]->{row} ++;
			unshift @holderstack, {
				holder => $f,
				offset => 0,
				row => 0,
				type => 'frame',
			};
			
		} elsif ($key eq '*column') {
			my $offset = $holderstack[0]->{offset};
			$offset = $offset + 2;
			$holderstack[0]->{offset} = $offset;
			$holderstack[0]->{row} = 0;
			my $h = $holderstack[0]->{holder};
			$h->gridColumnconfigure(1 + $offset, -weight => 1);
		} elsif ($key eq '*end') {
			if ($holderstack[0]->{type} eq 'page') {
				$notebook = undef
			}
			if  (@holderstack > 1) {
				shift @holderstack
			} else {
				warn "Holder stack is already empty"
			}
		} elsif ($key eq '*expand') {
			my $holder = $holderstack[0]->{holder};
			my $row = $holderstack[0]->{row};
			my $count = 0;
			while (defined $holderstack[$count]) {
				my $htype = $holderstack[$count]->{type};
				if ($htype eq 'page') {
					my $h = $holderstack[$count]->{holder};
					$h->packForget;
					$h->pack(-expand => 1, -fill => 'both');
					last
				}
				$count ++;
			} 
			$holder->gridRowconfigure($row, -weight => 1);
			
		} else {
			my $conf = shift @options;
			my @opt = @$conf;
			my $type = shift @opt;
			my $row = $holderstack[0]->{row};
			my $holder = $holderstack[0]->{holder};
			my $offset = $holderstack[0]->{offset};

			if ($type eq 'color') {
				my $file = $self->cget('-colorhistoryfile');
				$popcolor = $self->PopColor() unless defined $popcolor;
				push @opt, -popcolor => $popcolor, -historyfile => $file;
			}


			if ($type eq 'ext1') {
				my $label = shift @opt;
				my $class = shift @opt;
				my $l = $holder->Label(
					-width => $labelwidth, 
					-text => $label, 
					-anchor => 'e'
				)->grid(@padding,
					-column => 0 + $offset,
					-row => $row, 
					-sticky => 'e'
				);
				my $w = $self->CreateClass($holder, $class, -quickform => $self, -validatecall => ['validate', $self], @opt);
				$w->grid(
					-column => 1 + $offset,
					-row => $row, 
					-sticky => 'nsew',
					-padx => 2,
					-pady => 2
				);
				$options{$key} = $w;
				$labels{$key} = $l;
			} elsif ($type eq 'ext2') {
					# $label is now actually the reference to the external object
					# $values is now actually a boolean scalar to instruct the widget to expand
					my $class = shift @opt;
					my $w = $self->CreateClass($holder, $class, -validatecall => ['validate', $self], @opt);
					$w->grid(
					-column => 0, 
					-row => $row, 
					-columnspan => 2 + $offset,
					-sticky => 'nsew',
					-padx => 2,
					-pady => 2
				);
				$options{$key} = $w;
			} else {
				my $label = shift @opt;
				my $l = $holder->Label(
					-width => $labelwidth,
					-text => $label,
					-anchor => 'e'
				)->grid(@padding,
					-column => 0 + $offset, 
					-row => $row, -sticky => 'e'
				);
				my $t = $self->{TYPES}->{$type};
				my @o = @$t;
				my $class = shift @o;
				my %opthash = (@o);
				while (@opt) {
					my $key = shift @opt;
					my $value = shift @opt;
					$opthash{$key} = $value;
				}
				$opthash{'-validatecall'} = ['validate', $self];
				my $img = $opthash{'-image'};
				if ((defined $img) and ($img =~ /^-/)) {
					$opthash{'-image'} = $self->cget($img)
				}

				if (exists $opthash{'-values'}) {
					my $values = $opthash{'-values'};
					if ((ref $values) and ($values =~/^CODE/))  {
						my @vals = &$values;
						$opthash{'-values'} = \@vals;
					}
				}
				
				my $widg = $self->CreateClass($holder, $class, %opthash, -quickform => $self)->grid(
					-column => 1 + $offset, 
					-row => $row,
					-sticky => 'nsew', 
					-padx => 2, -pady => 2
				);

				$options{$key} = $widg;
				$labels{$key} = $l;
				$holderstack[0]->{row} ++;
			}
		}
	}
	$self->{OPTIONS} = \%options;
	$self->{LABELS} = \%labels;
	$self->{NOTEBOOK} = $notebook;
	$self->after(10, ['validate', $self]);
	return $notebook;
}

sub DefineTypes {
	my $self = shift;
	while (@_) {
		my $type = shift;
		my $conf = shift;
		$self->{TYPES}->{$type} = $conf;
	}
}

=item B<get>I<(?$key?)>

Returns the value of $key. $key is the name of the item in the form.
Returns a hash with all values if $key is not specified.

=cut

sub get {
	my ($self, $key) = @_;
	my $opt = $self->{OPTIONS};
	return $opt->{$key}->get if (defined $key) and (exists $opt->{$key});
	if (defined $key) {
		warn "Invalid key $key";
		return
	}
	my @get = ();
	for (keys %$opt) {
		push @get, $_, $opt->{$_}->get
	}
	return @get
}

sub getFilePicker {
	my $self = shift;
	my $pick = $self->Subwidget('picker');
	return $pick if defined $pick;

	my %options = ();
	for ('-diriconcall', '-fileiconcall', '-linkiconcall', '-msgimage', '-newfolderimage', '-reloadimage', '-warnimage') {
		my $opt = $self->cget($_);
		$options{$_} = $opt if defined $opt
	}
	$pick = $self->FilePicker(%options);
	$self->Advertise('picker', $pick);
	return $pick;
}

sub getKeys {
	my $self = shift;
	my $opt = $self->{OPTIONS};
	return sort keys %$opt;
}

sub getLabel {
	my ($self, $name) = @_;
	return $self->{LABELS}->{$name};
}

sub getNotebook {	return $_[0]->{NOTEBOOK} }

sub getWidget {
	my ($self, $name) = @_;
	return $self->{OPTIONS}->{$name};
}

sub pick {
	my $self = shift;
	my $pick = $self->getFilePicker;
	$pick->pick(@_);
}

sub pickFile {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 0,
		-showfolders => 1,
		-showfiles => 1,
		-selectmode => 'single',
		-selectstring => 'Select',
		-title => 'Select file',
		%args,
	);
}

sub pickFolder {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 0,
		-showfolders => 1,
		-showfiles => 0,
		-selectmode => 'single',
		-selectstring => 'Select',
		-title => 'Select folder',
		%args,
	);
}

=item B<put>(%values)

Sets the values in the tabbed form

=cut

sub put {
	my $self = shift;
	my $opt = $self->{OPTIONS};
	while (@_) {
		my $key = shift;
		my $value = shift;
		if (exists $opt->{$key}) {
			$opt->{$key}->put($value)
		} else {
			warn "Invalid key $key"
		}
	}
}

=item B<validate>

=over 4

validates all entries in the form and returns true if
all successfull.

=back

=cut

sub validate {
	my ($self, $key) = @_;
	my $opt = $self->{OPTIONS};
	my $valid = 1;
	for (keys %$opt) {
		my $w = $opt->{$_};
		next if ($self->cget('-acceptempty') and ($w->get eq ''));
		$valid = 0 unless $w->validate;
	}
	$self->Callback('-postvalidatecall', $valid);
	return $valid
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::QuickForm::CBaseClass>

=item L<Tk::QuickForm::CBooleanItem>

=item L<Tk::QuickForm::CColorItem>

=item L<Tk::QuickForm::CFileItem>

=item L<Tk::QuickForm::CFloatItem>

=item L<Tk::QuickForm::CFolderItem>

=item L<Tk::QuickForm::CFontItem>

=item L<Tk::QuickForm::CListItem>

=item L<Tk::QuickForm::CRadioItem>

=item L<Tk::QuickForm::CScaleItem>

=item L<Tk::QuickForm::CSpinItem>

=item L<Tk::QuickForm::CTextItem>

=back

=cut

1;

__END__
