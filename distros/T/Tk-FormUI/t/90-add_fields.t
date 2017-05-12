##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 90-add_fields.t
## Description: Test the Tk::FormUI module
##----------------------------------------------------------------------------
use Test::More;
use Tk::FormUI;
use Readonly;
Readonly::Scalar my $NAME => qq{Joseph Blough};

## From http://wiki.cpantesters.org/wiki/CPANAuthorNotes the 
## "Why are you testing (and failing) my Tk-ish module without an X server?"
## Tk now will load without an X Server, so we need to check that we
## have a server before running any tests
my $mw = eval { MainWindow->new };
if ($mw)
{
  ## MainWindow successfully created, 
  ## Destory the window, and continue with tests
  $mw->destroy;
  note(qq{Successfully created a Tk MainWindow, we must have an X-Server});
}
else
{
  ## Could not create MainWindow, skip the tests 
  plan(skip_all => 'No X Server detected');
}

my $result;

## Create the form
my $form = Tk::FormUI->new(title => qq{Test Form},);
isa_ok($form, 'Tk::FormUI', 'Create form');
## Stop testing if we didn't create the form
BAIL_OUT('Could not create form') unless ($form);

##---------------------------------------
my $field = $form->add_field(
  label => 'Name',
  key   => 'name',
  type  => $Tk::FormUI::ENTRY,
  default => $NAME,
  );
ok(defined($field), 'Create entry field');

##---------------------------------------

## Test canceling the form
$form->title(qq{Test - Cancel});
$result = $form->show(undef, qq{TEST: 0});
ok(!defined($result), 'Form cancel detected');
##---------------------------------------

## Test submitting the form
$form->title(qq{Test - Submit});
$result = $form->show(undef, qq{TEST: 1});
ok(defined($result), 'Form submit detected');

##---------------------------------------
ok(exists($result->{name}), 'Received the correct key');

is($result->{name}, $NAME, 'Received the correct value');
##---------------------------------------

$field = $form->add_field(
  label   => 'Gender',
  key     => 'sex',
  type    => $Tk::FormUI::RADIOBUTTON,
  choices => [
    { label => qq{Male},    value => qq{male},},
    { label => qq{Female},  value => qq{female},},
  ],
);
ok(defined($field), 'Create radiobutton field');
##---------------------------------------

$form->title(qq{Test - Radio - H});
$result = $form->show(undef, qq{TEST: 1});
##---------------------------------------

$field = $form->add_field(
  label   => 'Favorite Color',
  key     => 'color',
  type    => $Tk::FormUI::RADIOBUTTON,
  max_per_line => 1,
  choices => [
    { label => qq{Red},    value => qq{red},},
    { label => qq{Green},  value => qq{green},},
    { label => qq{Blue},   value => qq{blue},},
  ],
);
ok(defined($field), 'Create 2nd radiobutton field');
##---------------------------------------

$form->title(qq{Test - Radio - V});
$result = $form->show(undef, qq{TEST: 1});
##---------------------------------------

$field = $form->add_field(
  label   => 'Grocery List',
  key     => 'groceries',
  type    => $Tk::FormUI::CHECKBOX,
  max_per_line => 2,
  choices => [
    { label => qq{Eggs},    value => qq{eggs},},
    { label => qq{Bread},   value => qq{bread},},
    { label => qq{Milk},    value => qq{milk},},
  ],
);
ok(defined($field), 'Create checkbox field');

##---------------------------------------
$form->title(qq{Test - Checkbox - H});
$result = $form->show(undef, qq{TEST: 1});

##---------------------------------------

$field = $form->add_field(
  label   => 'Horizontal Boxes',
  key     => 'sample',
  type    => $Tk::FormUI::CHECKBOX,
  default => [1,],
  choices => [
    { label => qq{Zero},  value => 0,},
    { label => qq{One},   value => 1,},
    { label => qq{Two},   value => 2,},
  ],
);
ok(defined($field), 'Create checkbox field');

##---------------------------------------
$form->title(qq{Test - Checkbox - V});
$result = $form->show(undef, qq{TEST: 1});


done_testing();