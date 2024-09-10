
use strict;
use warnings;
use Test::Tk;
use Tk;

# use Tk::GtkSettings;
# applyGtkSettings;

use Test::More tests => 16;
BEGIN { 
	use_ok('Tk::QuickForm::CBaseClass');
	use_ok('Tk::QuickForm::CBooleanItem');
	use_ok('Tk::QuickForm::CColorItem');
	use_ok('Tk::QuickForm::CFileItem');
	use_ok('Tk::QuickForm::CFloatItem');
	use_ok('Tk::QuickForm::CFolderItem');
	use_ok('Tk::QuickForm::CFontItem');
	use_ok('Tk::QuickForm::CListItem');
	use_ok('Tk::QuickForm::CRadioItem');
	use_ok('Tk::QuickForm::CScaleItem');
	use_ok('Tk::QuickForm::CSpinItem');
	use_ok('Tk::QuickForm::CTextItem');
	use_ok('Tk::QuickForm');
};

my @listvalues = sort qw(
	Yellow Red Brown Green Blue Purple Beige Magenta Grey Black Cyan White Orange Pink Violet
);

my @radiovalues = qw (
	Up Down Left Right
);

package MyExternal;

use strict;
use warnings;
	
use base qw(Tk::Frame);
Construct Tk::Widget 'MyExternal';
require Tk::Text;

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	
	my $text = $self->Text(
# 			-class => 'Text',
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('T' => $text);
	$self->ConfigSpecs(
		-validatecall => ['CALLBACK', undef, undef, sub {}],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$text],
	);
	$self->Delegates(
		DEFAULT => [$text],
	);
}

sub get {
	my $self = shift;
	return $self->Subwidget('T')->get('1.0', 'end-1c');
}

sub put {
	my ($self, $content) = @_;
	my $t = $self->Subwidget('T');
	$t->delete('1.0', 'end');
	$t->insert('end', $content);
}

sub validate { return 1 }

sub ValidUpdate {}

package main;

createapp;
$delay = 1000;

my @coltests1 = ();
for (0 .. 9) {
	push @coltests1, "-color1_$_", ['color', "Color1 $_"],
}

my @coltests2 = ();
for (0 .. 9) {
	push @coltests2, "-color2_$_", ['color', "Color2 $_"],
}


my %values = ();
my $form;
if (defined $app) {
	my $rbut;
	my $lbut;
	my $wframe = $app->Frame(-relief => 'groove', -borderwidth => 3)->pack(-expand => 1, -fill => 'both');
	$form = $wframe->QuickForm(
		-acceptempty => 1,
		-postvalidatecall => sub {
			my $flag = shift;
			return unless defined $rbut;
			$rbut->configure(-state => 'disabled') unless $flag;
			$rbut->configure(-state => 'normal') if $flag;
		},
		-tabside => 'left',
		-types => [
			https => ['Tk::QuickForm::CTextItem', -regex => '^https\\:\\/\\/'],
			onoff => ['Tk::QuickForm::CBooleanItem', -offvalue => 'off', -onvalue => 'on'],
			scale10 => ['Tk::QuickForm::CScaleItem', -from => -10, -to => 10],
		],
		-structure => [
			'*page' => 'Arrays',
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
			'*page' => 'Colors',
			'*section' => 'Color tests',
			@coltests1,
			'*column',
			@coltests2,
			'*end'
		],
	)->pack(-side => 'left', -expand => 1, -fill => 'both');
	$form->createForm;
	my $display = $wframe->Frame->pack(-side => 'left', -anchor => 'n');
	my @keys = $form->getKeys;
	my $row = 0;
	for (@keys) {
		my $key = $_;
		my $val = '';
		$values{$key} = \$val;
		$display->Label(-text => $key, -width => 18, -anchor => 'e')->grid(-column => 0, -row => $row);
		$display->Label(-textvariable => \$val, -width => 25, -anchor => 'w')->grid(-column => 1, -row => $row);
		$row ++
	}
	my $bframe = $app->Frame->pack;
	$lbut = $bframe->Button(
		-command => sub {
			my @out = ();
			for (keys %values) {
				my $var = $values{$_};
				push @out, $_, $$var;
			}
			$form->put(@out);
		},
		-text => '<',
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$rbut = $bframe->Button(
		-command => sub {
			my @data = $form->get;
			while (@data) {
				my $key = shift @data;
				my $value = shift @data;
				my $var = $values{$key};
				$$var = $value;
			}
		},
		-text => '>',
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$rbut = $bframe->Button(
		-command => sub {
			my %hash = $form->get;
			for (keys %hash) {
				print "key $_, value ", $hash{$_}, "\n";
			}
		},
		-text => 'Get',
	)->pack(-side => 'left', -padx => 2, -pady => 2);
}

@tests = (
	[sub { return defined $form }, 1, 'created Tk::QuickForm'],
);

starttesting;


