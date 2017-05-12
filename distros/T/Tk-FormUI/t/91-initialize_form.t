##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 91-initialize_form.t
## Description: Test the Tk::FormUI module
##----------------------------------------------------------------------------
use Test::More;
use Tk::FormUI;
use Readonly;

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

Readonly::Scalar my $FORM_HASH => {
  title        => qq{Init Test},
  button_label => qq{Submit},
  fields       => [
    {
      type    => qq{Combobox},
      label   => qq{Product},
      key     => qq{product},
      choices => [
        {
          label => qq{Widget ABC},
          value => qq{abcabc-1},
        },
        {
          label => qq{Widget XYZ},
          value => qq{xyzxyz-1},
        },
        {
          label => qq{Widget 123},
          value => qq{123123-1},
        },
      ],
    },
    {
      type    => qq{Entry},
      width   => 10,
      label   => qq{Reading 1},
      key     => qq{data_01},
      default => qq{0.0},
    },
    {
      type    => qq{Radiobutton},
      label   => qq{Result},
      key     => qq{result},
      default => 1,
      choices => [
        {
          label => qq{Pass},
          value => 1,
        },
        {
          label => qq{Fail},
          value => 0,
        },
      ],
    },
  ],
};

Readonly::Scalar my $EXPECTED => {
  product => qq{xyzxyz-1},
  result => 1,
  data_01 => qq{98.6},
  
};

my $result;

## Create the form
my $form = Tk::FormUI->new();
isa_ok($form, 'Tk::FormUI', 'Create form');
## Stop testing if we didn't create the form
BAIL_OUT('Could not create form') unless ($form);

##---------------------------------------
$form->initialize($FORM_HASH);

## Test submitting the form
$form->title(qq{Test - Submit});
$result = $form->show(undef, qq{TEST: 1});

ok(defined($result), 'Form submit detected');

ok(scalar(@{$FORM_HASH->{fields}}) == scalar(keys(%{$result})), 'Received the correct keys');

$form->set_field_data($EXPECTED);
$result = $form->show(undef, qq{TEST: 1});

is_deeply($EXPECTED, $result, 'Received expected values');


done_testing();