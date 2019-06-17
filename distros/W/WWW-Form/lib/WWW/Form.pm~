package WWW::Form;

use strict;
use warnings;

use 5.014;

use Data::Dumper;
use CGI;

our $VERSION = "1.19";

=head1 NAME

WWW::Form - Object-oriented module for HTML form input validation and display

=head1 SYNOPSIS

Simple and extendable module that allows developers to handle HTML form
input validation and display flexibly and consistently.

=head1 DESCRIPTION

This module:

=over

=item * provides functionality to handle all of the various types of HTML
form inputs

=item * handles populating form inputs with user entered data or progammer
specified default values

=item * provides support for validation of user entered input

=item * handles presenting customizable error feedback to users

=item * should be easy to extend, the WWW::Form module is designed to be
inherited from, so you can add your own features

=item * Can be used in both mod_perl and CGI environments

=back

The most time consuming part (and it's not too bad) of WWW::Form usage is
creating the data structure used for instantiating a WWW::Form object. Once you
have a WWW::Form object instance configured, almost all your work is done as it
will have enough information to handle a variety of HTML form-related tasks.

Before we get too involved in the details, let's take a look at a sample
usage of the WWW::Form module in a typical setting. The following example
uses CGI instead of mod_perl, so if you're using mod_perl, certain pieces
of the code would look a little different. The WWW::Form module is used
the same way in both environments (CGI or mod_perl), though.

A sample usage:

    #!/usr/bin/perl
    use strict;
    use warnings;

    use CGI;
    use WWW::Form;

    # Used by WWW::Form to perform various validations on user entered input
    use WWW::FieldValidator;

    # Define values for form input name attributes as constants
    use constant EMAIL_FIELD_NAME => 'emailAddress';
    use constant PASSWORD_FIELD_NAME => 'password';

    # Gets us access to the HTTP request data
    my $q = CGI->new();

    # Hash ref of HTTP vars, would be $r->param() if you're using mod_perl
    my $params = $q->Vars() || {};

    my $form = WWW::Form->new(
        get_form_fields(),
        $params,
        [&EMAIL_FIELD_NAME, &PASSWORD_FIELD_NAME]
    );

    # Check to see that the form was submitted by the user if you're using
    # mod_perl, instead of $ENV{REQUEST_METHOD} you'd have $r->method()
    if ($form->is_submitted($ENV{REQUEST_METHOD})) {

        # Validate user entered data
        $form->validate_fields();

        # If the data was good, do something
        if ($form->is_valid()) {
            # Do some stuff with params because we know the user entered data
            # passed all of its validation
        }
    }


    # Display the HTML web page
    print <<HTML;
    Content-Type: text/html

    <html>
    <head>
    <title>A Simple HTML Form</title>
    </head>
    <body>
    HTML

        # Display the HTML form content
        print $form->get_form_HTML(action => './form_test.pl');

    print <<HTML;
    </body>
    </html>
    HTML


    # Returns data structure suitable for passing to WWW::Form object
    # constructor, the keys will become the names of the HTML form inputs
    sub get_form_fields {
        my %fields = (
            &EMAIL_FIELD_NAME => {
                label        => 'Email address',
                defaultValue => 'you@emailaddress.com',
                type         => 'text',
                validators   => [WWW::FieldValidator->new(
                    WWW::FieldValidator::WELL_FORMED_EMAIL,
                    'Make sure email address is well formed'
                )]
            },
            &PASSWORD_FIELD_NAME => {
                label        => 'Password',
                defaultValue => '',
                type         => 'password',
                validators   => [WWW::FieldValidator->new(
                    WWW::FieldValidator::MIN_STR_LENGTH,
                    'Password must be at least 6 characters',
                    6
                )]
            }
        );
        return \%fields;
    }

=head2 Creating WWW::Form Objects

The WWW::Form constructor takes three parameters.  The first parameter called
$fieldsData, is a hash reference that describes how the form should be built.
$fieldsData should be keyed with values that are suitable for using as the
value of the form inputs' name HTML attributes.  That is, if you call a key of
your $fieldsData hash 'full_name', then you will have some type of form input
whose name attribute will have the value 'full_name'. The values of the
$fieldsData keys (i.e., $fieldsData->{$fieldName}) should also be hash
references.  This hash reference will be used to tell the WWW::Form module
about your form input.  All of these hash references will be structured
similarly, however, there are a couple of variations to accommodate the various
types of form inputs.  The basic structure is as follows:

 {
     # UI presentable value that will label the form input
     label => 'Your name',
     # If set, the form input will be pre-populated with this value
     # you could hard code a default value or use a value retrieved
     # from a data base table, for example
     defaultValue => 'Homer Simpson',
     # The type of form input, i.e. text, checkbox, textarea, etc.
     # (more on this later)
     type => 'text',
     # An array ref of various validations that should be performed on the
     # user entered input
     validators => [],
     # A hash ref that contains extra HTML attributes to add to the
     # container.
     container_attributes => {},
     # A hint that will be displayed to the user near the control and its
     # label to guide him what to fill in that control. (optional)
     hint => 'text',
     # A hash ref that contains extra HTML attributes to add to the
     # container of the hint.
     hint_container_attributes => {},
 }

So to create a WWW::Form object with one text box you would have the
following data structure:

 my $fields = {
     emailAddress => {
         label        => 'Email address',
         defaultValue => 'you@emailaddress.com',
         type         => 'text',
         validators   => [WWW::FieldValidator->new(
             WWW::FieldValidator::WELL_FORMED_EMAIL,
             'Make sure email address is well formed
         )],
         container_attributes => { 'class' => "green",},
         hint => "Fill in a valid E-mail address",
         hint_container_attributes => { 'style' => "border : double", },
     }
 };

You could then say the following to create that WWW::Form object:

  my $form = WWW::Form->new($fields);

Now let's talk about the second parameter.  If a form is submitted, the second
parameter is used.  This parameter should be a hash reference of HTTP POST
parameters. So if the previous form was submitted you would instantiate the
WWW::Form object like so:

  my $params = $r->param(); # or $q->Vars if you're using CGI
  my $form   = WWW::Form->new($fields, $params);

At this point, let me briefly discuss how to specify validators for your form
inputs.

The validators keys in the $fieldsData->{$fieldName} hash reference can be
left empty, which means that the user entered input does not need to be
validated at all, or it can take a comma separated list of WWW::FieldValidator
objects.  The basic format for a WWW::FieldValidator constructor is as follows:

  WWW::FieldValidator->new(
      $validatorType,
      $errorFeedbackIfFieldNotValid,
      # Optional, depends on type of validator, if input is entered validation
      # is run, if nothing is entered input is OK
      $otherVarThatDependsOnValidatorType,
      $isOptional
  )

The FieldValidator types are:

  WWW::FieldValidator::WELL_FORMED_EMAIL
  WWW::FieldValidator::MIN_STR_LENGTH
  WWW::FieldValidator::MAX_STR_LENGTH
  WWW::FieldValidator::REGEX_MATCH
  WWW::FieldValidator::USER_DEFINED_SUB

So to create a validator for a field that would make sure the input of said
field was a minimum length, if any input was entered, you would have:

  WWW::FieldValidator->new(
      WWW::FieldValidator::MIN_STR_LENGTH,
      'String must be at least 6 characters',
      6, # input must be at least 6 chars
      # input is only validated if user entered something if field left blank,
      # it's OK
      1 # field is optional
  )

Now for the third parameter.  The third parameter is simply an array reference
of the keys of the $fieldsData hash, but the order of elements in the array
ref should be the order that you want your form inputs to be displayed in.
This array ref is used by the get_form_HTML method to return a form block that
can be displayed in an HTML page.

  # The third parameter will be used to generate an HTML form whose inputs
  # will be in the order of their appearance in the array ref, note this is
  # the constructor format you should use when instantiating form objects
  my $form = WWW::Form->new(
      $fieldsData,
      $params,
      ['name', 'emailAddress', 'password']
  );

=head2 How To Create All The Various Form Inputs

The following form input types are supported by the WWW::Form module (these
values should be used for the 'type' key of your $fieldsData->{$fieldName}
hash ref):

  text
  password
  hidden
  file
  checkbox
  radio
  select
  textarea

The following structure can be used for text, password, hidden, file, and
textarea form inputs:

  $fieldName => {
      label => 'Your name',
      defaultValue => 'Homer Simpson',
      type => 'text', # or file, password, hidden, textarea
      validators => []
  }

The following structure should be used for radio and select form inputs:

The data structure for input types radio and select use an array of hash
references called optionsGroup.  The optionsGroup label is what will be
displayed in the select box or beside the radio button, and the optionsGroup
value is the value that will be in the hash of HTTP params depending on what
the user selects.  To pre-select a select box option or radio button, set its
defaultValue to a value that is found in the optionsGroup hash ref. For
example, if you wanted the option 'Blue' to be selected by default in the
example below, you would set defaultValue to 'blue'.

  $fieldName => {
      label => 'Favorite color',
      defaultValue => '',
      type => 'select',
      optionsGroup => [
          {label => 'Green', value => 'green'},
          {label => 'Red',   value => 'red'},
          {label => 'Blue',  value => 'blue'}
      ],
      validators => []
  }

The following structure should be used for checkboxes:

Note: All checkbox form inputs need a defaultValue to be specified, this is
the value that will be used if the checkbox is checked when the form is
submitted.  If a checkbox is not checked then there will not be an entry for
it in the hash of HTTP POST params.  If defaultChecked is 1 the checkbox will
be selected by default, if it is 0 it will not be selected by default.

  $fieldName => {
      label => 'Do you like spam?',
      defaultValue => 'Yes, I love it!',
      defaultChecked => 0, # 1 or 0
      type => 'checkbox',
      validators => []
  }

=head1 FUNCTION REFERENCE

NOTE: All methods are available using
internalCapsStyle and underscore_separated_style. So 'isSubmitted' is also
available as 'is_submitted', and 'getFieldHTMLRow' is also available as
'get_field_HTML_row', and so on and so forth.

Many convenience methods for displaying HTML form data including
form inputs, labels, and error feedback are provided. You do not need to use
these methods to display your form inputs, but they should be
flexible enough to handle most cases.


=head2 new

Creates a WWW::Form object.  $fieldsData is a hash reference that describes
your WWW::Form object. (See instantiating a WWW::Form object above.)
$fieldsValues (i.e., $params below) has keys identical to $fieldsData.
$fieldsValues is a hash reference of HTTP POST variables.  $fieldsOrder is
an array reference of $fieldsData keys that is used to determine the order
that form inputs are displayed in when getFormHTML() is called.  If you don't
use this parameter you should use the other public methods provided and
display your form inputs by hand.

  Example:

  my $params = $r->param() || {};
  my $form = WWW::Form->new($fieldsData, $params, $fieldsOrder);

=cut

sub new {
    my $class = shift;

    # Hash that contains various bits of data in regard to the form fields,
    # i.e. the form field's label, its input type (e.g. radio, text, textarea,
    # select, etc.) validators to check the user entered input against a
    # default value to use before the form is submitted and an option group
    # hash if the type of the form input is select or radio this hash should
    # be keyed with the values you want to use for the name attributes of your
    # form inputs
    my $fieldsData = shift;

    # Values to populate value keys of field hashes with generally this will
    # be a hash of HTTP params needs to have the same keys as fieldsData
    my $fieldValues = shift || {};

    # Array ref of field name keys that should be in the order that you want
    # to display your form inputs
    my $fieldsOrder = shift || [];

    my $self = {};

    $self->{fieldsOrder} = $fieldsOrder;

    bless($self, $class);

    # Set up a fields hash ref for the fields, so we will not need
    # autovivificatiopn later
    $self->{fields} = {};

    # Creates and populates fields hash
    $self->_setFields($fieldsData, $fieldValues);

    return $self;
}


=head2 validateFields

Validates field's values input according to the validators
(WWW::FieldValidators) that were specified when the WWW::Form object was
created.  This will also set error feedback as necessary for form inputs that
are not valid.

Returns hash reference of all the fields that are valid (generally you don't
need to use this for anything though because if all the validation passes you
can just use your hash ref of HTTP $params, i.e. $r->param()).

  Example:

  if ($form->isSubmitted($r->method)) {
      # validate fields because form was POSTed
      $form->validateFields();
  }

=cut

sub validateFields {
    my $self   = shift;

    # Initialize hash of valid fields
    my %validFields = ();

    # Init isValid property to 1 that is, the form starts out as being valid
    # until an invalid field is found, at which point the form gets set to
    # invalid (i.e., $self->{isValid} = 0)
    $self->{isValid} = 1;

    # Go through all the fields and look to see if they have any validators,
    # if so check the validators to see if the input is valid, if the field
    # has no validators then the field is always valid
    foreach my $fieldName (keys %{$self->{fields}}) {

        # Look up hash ref of data for the current field name
        my $field = $self->getField($fieldName);

        my $fieldValue = $self->getFieldValue($fieldName);

        # If this field has any validators, run them
        if (scalar(@{$field->{validators}}) > 0) {

            # Keeps track of how many validators pass
            my $validValidators = 0;

            # Check the field's validator(s) to see if the user input is valid
            foreach my $validator (@{$field->{validators}}) {

                if ($validator->validate($fieldValue)) {
                    # Increment the validator counter because the current
                    # validator passed, i.e. the form input was good
                    $validValidators++;
                }
                else {
                    # Mark field as invalid so error feedback can be displayed
                    # to the user
                    $field->{isValid} = 0;

                    # Mark form as invalid because at least one input is not
                    # valid
                    $self->{isValid} = 0;

                    # Add the validators feedback to the array of feedback for
                    # this field
                    push @{$field->{feedback}}, $validator->{feedback};
                }
            }

            # Only set the field to valid if ALL of the validators pass
            if (scalar(@{$field->{validators}}) == $validValidators) {
                $field->{isValid} = 1;
                $validFields{$fieldName} = $fieldValue;
            }
        }
        else {
            # This field didn't have any validators so it's ok
            $field->{isValid} = 1;
            $validFields{$fieldName} = $fieldValue;
        }
    }

    # Return hash ref of valid fields
    return \%validFields;
}

=head2 validate_fields

An alias for validateFields.

=cut

*validate_fields = \&validateFields;


=head2 getFields

Returns hash ref of fields data.

  Example:

  my $fields = $form->getFields();

=cut

sub getFields {
    my $self = shift;
    return $self->{fields};
}

=head2 get_fields

An alias for getFields.

=cut

*get_fields = \&getFields;


=head2 resetFields

Resets values and default values for all fields

  Example:

  $form->resetFields(include_defaults => 1);

=cut

sub resetFields {
    my ($self, %args) = @_;
    my $fields = $self->getFields();

    for my $fieldName (keys %$fields) {
        $self->setFieldValue($fieldName, '');

        $self->getField($fieldName)->{defaultValue} = ''
            if ($args{include_defaults});
    }
}

=head2 reset_fields

An alias for resetFields.

=cut

*reset_fields = \&resetFields;


=head2 getField

Returns hash ref of field data that describes the form input that corresponds
to the passed $fieldName ($fieldName should be a value of a key in the
$fieldsData hash ref you used to construct your WWW::Form instance).

  Example:

  my $field = $form->getField('address');

=cut

sub getField {
    my $self      = shift;
    my $fieldName = shift;
    return $self->{fields}{$fieldName};
}

=head2 get_field

An alias for getField.

=cut

*get_field = \&getField;


=head2 getFieldErrorFeedback

Returns an array of all the error feedback (if any) for the specified
$fieldName.

  Example:

  my $name_feedback = $form->getFieldErrorFeedback('fullName');

=cut

sub getFieldErrorFeedback {
    my $self      = shift;
    my $fieldName = shift;

    my $field = $self->getField($fieldName);

    if ($field->{feedback}) {
        return @{$field->{feedback}};
    }
    else {
        return ();
    }
}

=head2 get_field_error_feedback

An alias for getFieldErrorFeedback.

=cut

*get_field_error_feedback = \&getFieldErrorFeedback;


=head2 getFieldsOrder

Returns array ref of field names in the order that they will be displayed.

  Example:

  $form->getFieldsOrder();

=cut

sub getFieldsOrder {
    my $self = shift;
    return $self->{fieldsOrder};
}

=head2 get_fields_order

An alias for getFieldsOrder.

=cut

*get_fields_order = \&getFieldsOrder;


=head2 getFieldValue

Returns the current value of the specified $fieldName.

  Example:

  $form->getFieldValue('comments');

=cut

sub getFieldValue {
    my $self      = shift;
    my $fieldName = shift;
    return $self->getField($fieldName)->{value};
}

=head2 get_field_value

An alias for getFieldValue.

=cut

*get_field_value = \&getFieldValue;


=head2 isFieldValid

Returns 1 or 0 depending on whether or not the specified field name is valid.

  Example:

  $form->isFieldValid('zip_code');

=cut

sub isFieldValid {
    my $self      = shift;
    my $fieldName = shift;

    return $self->getField($fieldName)->{isValid};
}

=head2 is_field_valid

An alias for isFieldValid.

=cut

*is_field_valid = \&isFieldValid;


=head2 getFieldValidators

Returns array ref of validators for the passed field name.

  Example:

  $validators = $form->getFieldValidators($fieldName);

=cut

sub getFieldValidators {
    my ($self, $fieldName) = @_;
    return $self->getField($fieldName)->{validators};
}

=head2 get_field_validators

An alias for getFieldValidators.

=cut

*get_field_validators = \&getFieldValidators;


=head2 getFieldType

Returns value of a field's 'type' key for the specified $fieldName.

Example:

  my $input_type = $form->getFieldType('favoriteColor');

=cut

sub getFieldType {
    my $self      = shift;
    my $fieldName = shift;
    return $self->getField($fieldName)->{type};
}

=head2 get_field_type

An alias for getFieldType.

=cut

*get_field_type = \&getFieldType;


=head2 getFieldLabel

Returns the label associated with the specified $fieldName.

  Example:

  my $ui_label = $form->getFieldLabel('favoriteBand');

=cut

sub getFieldLabel {
    my $self  = shift;
    my $fieldName = shift;

    my $field = $self->getField($fieldName);

    if ($self->getFieldType($fieldName) eq 'checkbox') {
        return "<label for='$fieldName'>" . $field->{label} . '</label>';
    }
    else {
        return $field->{label};
    }
}

=head2 get_field_label

An alias for getFieldLabel.

=cut

*get_field_label = \&getFieldLabel;


=head2 getFieldHint

Returns the hint associated with the specified $fieldName or undef if it
does not exist.

  Example:

  my $hint = $form->getFieldHint('favoriteBand');

=cut

sub getFieldHint {
    my $self  = shift;
    my $fieldName = shift;

    my $field = $self->getField($fieldName);

    return $field->{hint};
}

=head2 get_field_hint

An alias for getFieldHint.

=cut

*get_field_hint = \&getFieldHint;


=head2 setFieldValue

Sets the value of the specified $fieldName to $value.  You might use this if
you need to convert a user entered value to some other value.

  Example:

  $form->setFieldValue('fullName', uc($form->getFieldValue('fullName')));

=cut

sub setFieldValue {
    my $self      = shift;
    my $fieldName = shift;
    my $newValue  = shift;

    if (my $field = $self->getField($fieldName)) {
        $field->{value} = $newValue;
        #warn("set field value for field: $fieldName to '$new_value'");
    }
    else {
        #warn("could not find field for field name: '$fieldName'");
    }
}

=head2 set_field_value

An alias for setFieldValue.

=cut

*set_field_value = \&setFieldValue;


=head2 isValid

Returns true if all form fields are valid or false otherwise.

  Example:

  if ($form->isSubmitted($r->method)) {
      # validate fields because form was POSTed
      $form->validateFields($params);

      # now check to see if form inputs are all valid
      if ($form->isValid()) {
          # do some stuff with $params because we know
          # the validation passed for all the form inputs
      }
  }

=cut

sub isValid {
    my $self = shift;
    return $self->{isValid};
}

=head2 is_valid

An alias for isValid.

=cut

*is_valid = \&isValid;


=head2 isSubmitted

Returns true if the HTTP request method is POST.  If for some reason you're
using GET to submit a form then this method won't be of much help.  If
you're not using POST as the method for submitting your form you may want
to override this method in a subclass.

  Example:

  # Returns true if HTTP method is POST
  if ($form->isSubmitted($r->method())) {
      print "You submitted the form.";
  }

=cut

sub isSubmitted {
    my $self = shift;

    # The actual HTTP request method that the form was sent using
    my $formRequestMethod = shift;

    # This should be GET or POST, defaults to POST
    my $formMethodToCheck = shift || 'POST';

    if ($formRequestMethod eq $formMethodToCheck) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 is_submitted

An alias for isSubmitted.

=cut

*is_submitted = \&isSubmitted;



# Private method
#
# Populates fields hash for each field of the form
sub _setFields {
    my $self        = shift;
    my $fieldsData  = shift;
    my $fieldValues = shift;

    # TODO :
    # Create a _setField() method that will encapsulate the functionality
    # inside the loop. This will enable adding more variables to each field
    # in the sub-classes more easily.

    foreach my $fieldName (keys %{$fieldsData}) {
        $self->_setField(
            'name' => $fieldName,
            'params' => $fieldsData->{$fieldName},
            'value' => $fieldValues->{$fieldName}
        );
    }
}

sub _getFieldInitParams
{
    my $self = shift;

    my %args = (@_);

    my $fieldName = $args{name};
    my $params = $args{params};
    my $user_given_field_value = $args{value};

    # This is the output parameters that we eventually place under
    # $out_params->. It is declared it so it can later be filled
    # in by a different function other
    my $out_params = {};

    # Use the supplied field value if one is given. Generally the supplied
    # data will be a hash of HTTP POST data
    my $fieldValue = '';

    # Only use the default value of a check box if the form has been
    # submitted, that is, the default value should be the value that you
    # want to show up in the POST data if the checkbox is selected when
    # the form is submitted
    if ($params->{type} eq 'checkbox') {

        # If the checkbox was selected then we're going to use the default
        # value for the checkbox input's value in our WWW::Form object, if
        # the checkbox was not selected and the form was submitted that
        # variable will not show up in the hash of HTTP variables
        if ($user_given_field_value) {
            $fieldValue = $params->{defaultValue};
        }

        # See if this checkbox should be checked by default
        $out_params->{defaultChecked} =
            $params->{defaultChecked};
    }
    else {
        # If a key exists in the $fieldValues hashref, use that value
        # instead of the default, we generally want to favor displaying
        # user entered values than defaults
        if (defined($user_given_field_value)) {
            $fieldValue = $user_given_field_value;
        }
        else {
            $fieldValue = $params->{defaultValue};
        }
    }

    # Value suitable for displaying to users as a label for a form input,
    # e.g. 'Email address', 'Full name', 'Street address', 'Phone number',
    # etc.
    $out_params->{label} = $params->{label};

    # Holds the value that the user enters after the form is submitted
    $out_params->{value} = $fieldValue;

    # The value to pre-populate a form input with before the form is
    # submitted, the only exception is a checkbox form input in the case
    # of a checkbox, the default value will be the value of the checkbox
    # input if the check box is selected and the form is submitted, see
    # form_test.pl for an example
    $out_params->{defaultValue} =
        $params->{defaultValue};

    # The validators for this field, validators are used to test user
    # entered form input to make sure that it the user entered data is
    # acceptable
    $out_params->{validators} =
        \@{$params->{validators}};

    # Type of the form input, i.e. 'radio', 'text', 'select', 'checkbox',
    # etc. this is mainly used to determine what type of HTML method
    # should be used to display the form input in a web page
    $out_params->{type} = $params->{type};

    # If any validators fail, this property will contain the error
    # feedback associated with those failing validators
    $out_params->{feedback} = [];

    # If the input type is a select box or a radio button then we need an
    # array of labels and values for the radio button group or select box
    # option groups
    if (my $optionsGroup = $params->{optionsGroup}) {
        $out_params->{optionsGroup} = \@{$optionsGroup};
    }

    # Arbitrary HTML attributes that will be used when the field's input
    # element is displayed.
    $out_params->{extraAttributes} =
        ($params->{extraAttributes} || "");

    # Add the hint
    # 2004-Jan-04 - Added by Shlomi Fish:
    #  Ben, no. Actually it's a hint that will always be displayed below
    #  the table row to instruct the users what to input there. For instance
    #  +----------+---------------------------+
    #  |  City:   | [================]        |
    #  +----------+---------------------------+
    #  |  Input the city in which you live    |
    #  |  in.                                 |
    #  +---------------------------------------
    #  So "Input the city..." would be the hint.
    if (my $hint = $params->{hint})
    {
        $out_params->{hint} = $hint;
    }

    # Add the container_attributes. These are HTML attributes that would
    # be added to the rows of this HTML row.
    if (my $attribs = $params->{container_attributes})
    {
        $out_params->{container_attributes} = $attribs;
    }

    # Add the hint_container_attributes. These are HTML attributes that
    # would  be added to the Hint row of this HTML row.
    if (my $attribs = $params->{hint_container_attributes})
    {
        $out_params->{hint_container_attributes} = $attribs;
    }

    return $out_params;
}

# This function should not be left alone in sub-classing.
# Instead override _getFieldInitParams() to add your own parameters
# there.
sub _setField
{
    my $self = shift;

    my %args = (@_);

    my $params = $self->_getFieldInitParams(%args);

    $self->{fields}{$args{name}} = $params;

    return $self;
}

=head2 asString

Returns a string representation of the current instance.

  Example:

  &LOG->debug("WWW::Form instance: " . $form->asString());

=cut

sub asString {
    my $self = shift;
    return Data::Dumper::Dumper($self);
}

=head2 as_string

An alias for asString.

=cut

*as_string = \&asString;

sub _getFieldType
{
    my $self = shift;
    my $fieldName = shift;

    return $self->getField($fieldName)->{type};
}

#-----------------------------------------------------------------------------
# Convenience methods for displaying HTML form data including form inputs,
# labels, and error feedback
#
# Note: You do not need to use these methods to display your form inputs, but
# they should be reasonably flexible enough to handle most cases
#-----------------------------------------------------------------------------

=head2 getFieldFormInputHTML

Returns an HTML form input for the specified $fieldName. $attributesString is
an (optional) arbitrary string of HTML attribute key='value' pairs that you
can use to add attributes to the form input, such as size='20' or
onclick='someJSFunction()', and so forth.

  Example:

  $html .= $form->getFieldFormInputHTML(
      'password',
      " size='6' class='PasswordInput' "
  );

=cut

sub getFieldFormInputHTML {
    my $self = shift;

    # The value of the HTML name attribute of the form field
    my $fieldName = shift;

    # A string that can contain an arbitrary number of HTML attribute
    # name=value pairs, this lets you apply CSS classes to form inputs
    # or control the size of your text inputs, for example
    my $attributesString = shift || '';

    my $type = $self->_getFieldType($fieldName);

    if ($type =~ /text$|password|hidden|file/) {

        return $self->_getInputHTML($fieldName, $attributesString);

    }
    elsif ($type eq 'checkbox') {

        return $self->_getCheckBoxHTML($fieldName, $attributesString);

    }
    elsif ($type eq 'radio') {

        return $self->_getRadioButtonHTML($fieldName, $attributesString);

    }
    elsif ($type eq 'select') {

        return $self->_getSelectBoxHTML($fieldName, $attributesString);

    }
    elsif ($type eq 'textarea') {

        return $self->_getTextAreaHTML($fieldName, $attributesString);
    }
}

=head2 get_field_form_input_HTML

An alias for getFieldFormInputHTML.

=cut

*get_field_form_input_HTML = \&getFieldFormInputHTML;


=head2 getFieldLabelTdHTML

Returns the opening tag of the <td> element that belongs to the label.

=cut

sub getFieldLabelTdHTML
{
    return "<td>";
}

=head2 getFieldInputTdHTML

Returns the opening tag of the <td> element that belongs to the control.

=cut

sub getFieldInputTdHTML
{
    return "<td>";
}

=head2 renderFieldHTMLRow

    $html .=
        $self->renderFieldHTMLRow(
            'fieldName' => "name",
            'attributesString' => " class=\"hello\"",
            'tr_attr_string' => " class=\"control\"",
        );

This function renders the field HTML row and returns the HTML.

=cut

sub renderFieldHTMLRow
{
    my $self = shift;
    my (%args) = (@_);
    my $fieldName = $args{'fieldName'};
    my $attributesString = $args{'attributesString'};
    my $tr_attr_string = $args{'trAttrString'};
    return
        "<tr${tr_attr_string}>" . $self->getFieldLabelTdHTML($fieldName) .
        $self->getFieldLabel($fieldName) . "</td>" .
        $self->getFieldInputTdHTML($fieldName) . $self->getFieldFormInputHTML(
            $fieldName,
            $attributesString
        )
        . "</td></tr>\n";
}

=head2 renderHintHTMLRow

    $html .= $self->renderHintHTMLRow('name');

    or

    $html .= $self->renderHintHTMLRow(
        'name',
        form_args => {
            hint_container_attributes => {
                class => 'FormBlueBackground'
            }
        }
    );

This function renders the hint HTML row of the specified field and returns the
HTML.

=cut

sub renderHintHTMLRow
{
    my $self = shift;
    my $fieldName = shift;
    my (%func_args) = (@_);

    my $field = $self->getField($fieldName);

    my $tr_attributes = $self->_getTrAttributes($fieldName);

    my $form_args = $func_args{'form_args'};

    my $hint = $self->getFieldHint($fieldName);

    if (defined($hint)) {
        my %hint_attributes = ();
        my $hint_attributes = $form_args->{'hint_container_attributes'};

        if (defined($hint_attributes)) {
            %hint_attributes = (%hint_attributes, %$hint_attributes);
        }

        %hint_attributes = (%hint_attributes, %$tr_attributes);

        if (exists($field->{hint_container_attributes})) {
            %hint_attributes = (%hint_attributes, %{$field->{hint_container_attributes}});
        }

        my $hint_attr_string = $self->_render_attributes(\%hint_attributes);
        return "<tr${hint_attr_string}><td colspan=\"2\">$hint</td></tr>\n";
    }
    else
    {
        return "";
    }
}

sub _getTrAttributes
{
    my $self = shift;
    my $fieldName = shift;

    my %tr_attributes = ();

    my $field = $self->getField($fieldName);

    if (exists($field->{container_attributes})) {
        %tr_attributes = (%tr_attributes, %{$field->{container_attributes}});
    }
    return \%tr_attributes;
}

sub _render_attributes {
    my $self = shift;
    my $attribs = shift;

    # We sort the keys to produce reproducible output on perl 5.8.1 and above
    # where the order of the hash keys is not deterministic
    return join("",
            map { " $_=\"" . $self->_escapeValue($attribs->{$_}) . "\"" }
                (sort {$a cmp $b} keys(%$attribs))
            );
}

sub _getTrAttrString
{
    my $self = shift;
    my $fieldName = shift;
    return $self->_render_attributes($self->_getTrAttributes($fieldName));
}

=head2 getFieldHTMLRow

    $self->getFieldHTMLRow(
         $fieldName,
        'attributesString' => $attributesString,
        'form_args' => \%form_args,
    );

Returns HTML to display in a web page.  $fieldName is a key of the $fieldsData
hash that was used to create a WWW::Form object.

Arguments:

attributesString - Optional arbitrary string of HTML attribute key='value'
pairs that you can use to add attributes to the form input.

form_args - The parameters passed to getFormHtml(). This function
will extract the hint_container_attributes value if it's set.  More at
renderHintHTMLRow().

The only caveat for using this method is that it must be called between
<table> and </table> tags.  It produces the following output:

  <!-- NOTE: The error feedback row(s) are only displayed if the field -->
  <!-- input was not valid -->
  <tr>
  <td colspan="2">$errorFeedback</td>
  </tr>
  <tr>
  <td>$fieldLabel</td>
  <td>$fieldFormInput</td>
  </tr>

=cut

sub getFieldHTMLRow {
    my $self = shift;
    my $fieldName = shift;

    if ($self->_getFieldType($fieldName) eq "hidden")
    {
        return $self->_getHiddenFieldHTMLRow($fieldName);
    }

    my %func_args = (@_);
    my $attributesString = $func_args{'attributesString'};
    my $form_args = $func_args{'form_args'};

    my $field = $self->getField($fieldName);

    $attributesString ||= $field->{extraAttributes};

    my @feedback = $self->getFieldErrorFeedback($fieldName);

    my $html = "";

    my $tr_attr_string = $self->_getTrAttrString($fieldName);

    foreach my $error (@feedback) {
        $html .= "<tr${tr_attr_string}><td colspan='2'>"
            . "<span style='color: #ff3300'>$error</span>"
            . "</td></tr>\n";
    }

    $html .= $self->renderFieldHTMLRow(
        'fieldName' => $fieldName,
        'attributesString' => $attributesString,
        'trAttrString' => $tr_attr_string,
        );

    $html .=
        $self->renderHintHTMLRow(
            $fieldName,
            'form_args' => $form_args,
        );

    return $html;
}

=head2 get_field_HTML_row

An alias for getFieldHTMLRow.

=cut

*get_field_HTML_row = \&getFieldHTMLRow;

=head2 getFieldHTMLRowNoHidden

This method is identical to C<getFieldHTMLRow()> except that it returns
an empty string if the field type is "hidden". This method can be used if
you are rendering the hidden elements outside the main form table. This prevents
hidden inputs from being displayed twice.

=cut

sub getFieldHTMLRowNoHidden
{
    my $self = shift;
    my $fieldName = shift;

    if ($self->_getFieldType($fieldName) eq "hidden")
    {
        return "";
    }
    else
    {
        return $self->getFieldHTMLRow($fieldName);
    }
}

=head2 get_field_HTML_row_no_hidden

An alias for getFieldHTMLRowNoHidden.

=cut

*get_field_HTML_row_no_hidden = \&getFieldHTMLRowNoHidden;

=head2 getFieldFeedbackHTML

Returns HTML error content for each vaildator belonging to $fieldName that
doesn't pass validation.

Returns following HTML:

  <div class='feedback'>
  $validatorOneErrorFeedback
  </div>
  <div class='feedback'>
  $validatorTwoErrorFeedback
  </div>
  <div class='feedback'>
  $validatorNErrorFeedback
  </div>

Note: If you use this, you should implement a CSS class named 'feedback' that
styles your error messages appropriately.

  Example:

  $html .= $form->getFieldFeedbackHTML('emailAddress');

=cut

sub getFieldFeedbackHTML {
    my $self      = shift;
    my $fieldName = shift;

    my @feedback = $self->getFieldErrorFeedback($fieldName);

    my $feedbackHTML = '';

    foreach my $fieldFeedback (@feedback) {
        $feedbackHTML .= "<div class='feedback'>\n";
        $feedbackHTML .= $fieldFeedback . "\n</div>\n";
    }

    return $feedbackHTML;
}

=head2 get_field_feedback_HTML

An alias for getFieldFeedbackHTML.

=cut

*get_field_feedback_HTML = \&getFieldFeedbackHTML;


=head2 startForm

Returns an opening HTML form tag.

Arguments:

name - Value of HTML name attribute.

action - Value of action HTML attribute.

attributes - Optional hash ref of HTML attribute name value pairs.

is_file_upload - Optional, boolean, should be true if your form contains
file inputs.

  Example:

  $form->start_form(
      action => '/some_script.pl',
      name   => 'MyFormName',
      attributes => {class => 'MyFormClass'}
  );

Returns HTML similar to:

  <form action='/some_script.pl'
        method='post'
        name='MyFormName'
        id='MyFormName'
        class='MyFormClass'>

=cut

sub startForm {
    my ($self, %args) = @_;

    my $method = $args{method} || 'post';
    my $attributes = $args{attributes} || {};

    my $name_attributes = '';
    if ($args{name}) {
        $name_attributes = " name='$args{name}' id='$args{name}'";
    }

    my $html = "<form action='$args{action}'"
        . " method='$method'$name_attributes";

    # If this form contains a file input then set the enctype attribute
    # to multipart/form-data
    if ($args{is_file_upload}) {
        $html .= " enctype='multipart/form-data'";
    }

    for my $attribute (keys %{$attributes}) {
        $html .= " $attribute='$attributes->{$attribute}'";
    }

    # Chop off last space if there is one
    $html =~ s/\s$//;

    return $html . '>';
}

=head2 start_form

An alias for startForm.

=cut

*start_form = \&startForm;


=head2 endForm

Returns HTML to close form.

  Example:

  $html .= $form->endForm();

=cut

sub endForm {
    my $self = shift;
    return '</form>';
}

=head2 end_form

An alias for endForm.

=cut

*end_form = \&endForm;


=head2 getFormHTML

Loops through the fieldsOrder array and builds markup for each form input
in your form.

Returns HTML markup that when output will display your form.

This method outputs a basic form layout that should be reasonably useful
"out-of-the-box".  If you have more complex form presentation requirements
you may use the various HTML display methods to customize your form's
presentation.  Subclassing may also be useful for customizing form displays.

Arguments:

action - Value of form's action attribute.

name - Value that will be used for form's name and id attribute.

attributes - hashref of key value pairs that can be used to add arbitrary
attributes to the opening form element.

submit_label - Optional label for your form's submit button.

submit_name -  Optional Value of your submit button's name attribute. This
value will also be used for your submit button's id attribute.

submit_type - Optional string value, defaults to submit, if you want to use an
image submit button pass submit_type as 'image'.

submit_src - Optional unless submit_type is 'image' then an image src should
be specified with submit_src, e.g. submit_src => './img/submit_button.png'.

submit_class - Optional string that specifies a CSS class.

submit_attributes -  Optional hash ref of arbitrary name => 'value'
HTML attributes.

is_file_upload - Optional boolean that should be true if your form contains
a file input.

hint_container_attributes - Optional HTML attributes for all the table rows
containing the hints.

buttons - Use this if you want your form to have multiple submit buttons.  See
API documentation for getSubmitButtonHTML() for more info on this parameter.

  Example:

  print $form->getFormHTML(
      action => './my_form.pl',
      name => 'LoginForm',
      attributes => {
          class => 'FormBlueBackground'
      },
      submit_label => 'Login',
      is_file_upload => 1
  );

=cut

sub getFormHTML {
    my ($self, %args) = @_;

    my $html = $self->startForm(%args) . "\n";

    $html .= $self->getHiddenFieldsHTML();
    $html .= "<table>\n";

    # Go through all of our form fields and build an HTML input for each field
    for my $fieldName (@{$self->getFieldsOrder()}) {
        #warn("field name is: $fieldName");
        $html .= $self->getFieldHTMLRowNoHidden(
            $fieldName,
            'form_args' => \%args,
        );
    }

    $html .= "</table>\n";

    unless ($args{submit_label}) {
        $args{submit_label} = 'Submit';
    }

    unless ($args{submit_name}) {
        $args{submit_name} = 'submit';
    }

    # Add submit button
    $html .= "<p>" . $self->_getSubmitButtonHTML(%args) . "</p>\n";

    return $html . $self->endForm() . "\n";
}

=head2 get_form_HTML

An alias for getFormHTML.

=cut

*get_form_HTML = \&getFormHTML;

=head2 getHiddenFieldsHTML

Returns HTML to render all hidden inputs in the form.

=cut

sub getHiddenFieldsHTML
{
    my $self = shift;

    return
        join("",
            (map { $self->_getInputHTML($_, "") . "\n" }
            grep { $self->_getFieldType($_) eq "hidden" }
            (@{$self->getFieldsOrder()}))
        );
}

=head2 get_hidden_fields_HTML

An alias for getHiddenFieldsHTML.

=cut

*get_hidden_fields_HTML = \&getHiddenFieldsHTML;

sub _getHiddenFieldHTMLRow
{
    my $self = shift;
    my $fieldName = shift;
    return "<tr style=\"display:none\">\n" .
        "<td></td>\n" .
        "<td>" . $self->_getInputHTML($fieldName, "") ."</td>\n" .
        "</tr>\n";
}

#-----------------------------------------------------------------------------
# More private methods
#-----------------------------------------------------------------------------

# Returns HTML to display a form text input.
sub _getInputHTML {
    my $self             = shift;
    my $fieldName        = shift;
    my $attributesString = shift;

    my $field = $self->getField($fieldName);

    my $inputHTML = "<input type='$field->{type}'"
		. " name='$fieldName' id='$fieldName' value=\"";

    my $value_to_put;
    if ($field->{type} eq 'checkbox') {
        $value_to_put = $field->{defaultValue};
    }
    else {
        $value_to_put = $field->{value};
    }
    $inputHTML .= $self->_escapeValue($value_to_put);

    $inputHTML .= "\"" . $attributesString  . " />";

    return $inputHTML;
}


=head2 getSubmitButtonHTML

Used by get_form_HTML to get HTML to display a type of a submit button.

Returns string of HTML.

Arguments:
submit_type - 'submit' or 'image', defaults to 'submit' if not specified.

submit_src - If type is 'image', this specifies the image to use.

submit_label - Optional label for the button, defaults to 'Submit'.

submit_class - Optional value for class attribute.

submit_attributes - Optional hash ref of name => value pairs used to specify
arbitrary attributes.

buttons - Optional, array reference of hash refs of the previous arguments.
You can use this parameter if you want your form to have multiple submit
buttons.

=cut

sub getSubmitButtonHTML {
    my ($class, %args) = @_;

    if (exists($args{buttons})) {
        my $xhtml;
        foreach my $button (@{$args{buttons}}) {
            $xhtml .= $class->_getSubmitButtonHTML(%$button);
        }
        return $xhtml;
    }

    my $type = $args{submit_type} || 'submit';

    # Optional param that specifies an image for the submit button, this
    # should only be used if the type is 'image'
    my $img_src = $args{submit_src} || '';

    my $label = $args{submit_label} || 'Submit';

    my $xhtml = "<input type='$type'";

    # If the type was specified as 'image' add the src attribute, otherwise
    # add a value attribute
    if ($type eq 'image') {
        # Warn the developer if type is 'image' and a src key wasn't specified
        unless ($img_src) {
            warn(
                "Won't be able to display image submit button properly" .
                " because src for image was not specified"
	        );
        }

        $xhtml .= " src='$img_src'";
    }
    else {
        $xhtml .= " value='$label'";
    }

    my $attributes = $args{submit_attributes} || {};

    if ($args{submit_class}) {
        # Add class attribute if it's there
        $xhtml .= " class='$args{submit_class}'";
        # Add id attribute that uses same value as class, eventually should
        # use separate params, though!
        $xhtml .= " id='$args{submit_class}'";
    }

    if ($args{submit_name}) {
        $xhtml .= " name='$args{submit_name}'";

    }

    # Add any other attribute name value pairs that the developer may want to
    # enter
    for my $attribute (keys %{$attributes}) {
        $xhtml .= " $attribute='$attributes->{$attribute}'";
    }

    $xhtml =~ s/\s$//; # Remove trailing whitespace
    $xhtml .= " />\n";
    return $xhtml;
}


# We have lots of names for this method.  It used to be private, but now it's
# public.
*_get_submit_button_HTML = \&getSubmitButtonHTML;

=head2 get_submit_button_HTML

An alias for getSubmitButtonHTML.

=cut

*get_submit_button_HTML = \&getSubmitButtonHTML;
*_getSubmitButtonHTML = \&getSubmitButtonHTML;


# Returns HTML to display a checkbox.
sub _getCheckBoxHTML {
    my $self             = shift;
    my $fieldName        = shift;
    my $attributesString = shift;

    my $field = $self->getField($fieldName);

    if ($self->getFieldValue($fieldName) || $field->{defaultChecked}) {
        $attributesString .= " checked='checked'";
    }

    return $self->_getInputHTML($fieldName, $attributesString);
}

# Returns a radio button group
sub _getRadioButtonHTML {
    my $self             = shift;
    my $fieldName        = shift;
    my $attributesString = shift;

    my $field = $self->getField($fieldName);

    # Get the select boxes' list of options
    my $group = $field->{optionsGroup};

    my $inputHTML = '';

    if ($group) {
        foreach my $option (@{$group}) {
            $inputHTML .= '<label>';

            # Reset for each radio button in the group
            my $isChecked = '';

            my $value = $option->{value};
            my $label = $option->{label};

            if ($value eq $self->getFieldValue($fieldName)) {
                $isChecked = " checked='checked'";
            }

	    $inputHTML .= "<input type='$field->{type}'"
	        . " name='$fieldName'";

        $inputHTML .= " value=\"". $self->_escapeValue($value) . "\" ";
	    $inputHTML .= $attributesString
            . $isChecked
            . " /> $label</label><br />";
        }
    }
    else {
        warn(
            "No option group found for radio button group named: '$fieldName'"
        );
    }
    return $inputHTML;
}

# Returns HTML to display a textarea.
sub _getTextAreaHTML {
    my $self             = shift;
    my $fieldName        = shift;
    my $attributesString = shift;

    my $field = $self->getField($fieldName);

    my $textarea = "<textarea name='" . $fieldName . "'"
		. $attributesString;

    $textarea .= ">";
    $textarea .= $self->_escapeValue($field->{value});
    $textarea .= "</textarea>";

    return $textarea;
}

# Returns HTML to display a select box.
sub _getSelectBoxHTML {
    my $self             = shift;
    my $fieldName        = shift;
    my $attributesString = shift;

    my $html = "<select name='$fieldName'" . "$attributesString>\n";

    # Get the select boxes' list of options
    my $group = $self->getField($fieldName)->{optionsGroup};

    if ($group) {
        foreach my $option (@{$group}) {
            my $value = $option->{value};
            my $label = $option->{label};

            # If the current user value is equal to the current option value
            # then the current option should be selected in the form
            my $isSelected;

            if ($value eq $self->getField($fieldName)->{value}) {
                $isSelected = " selected='selected'";
            }
            else {
                $isSelected = "";
            }
            $html .= "<option value=\"" . $self->_escapeValue($value)
				. "\"${isSelected}>$label</option>\n";
        }
    }
    else {
        warn("No option group found for select box named: '$fieldName'");
    }

    $html .= "</select>\n";
    return $html;
}

sub _escapeValue {
    my $self = shift;
    my $string = shift;
    return CGI::escapeHTML($string);
}

1;

__END__

=head1 SEE ALSO

WWW::FieldValidator

To see some demos of WWW::Form and WWW::FieldValidator point your web browser
to:

  http://www.benschmaus.com/cgi-bin/perl/form_test.pl

or

  http://benschmaus.com/cgi-bin/perl/form_test_subclass_example.pl


The following modules are related to WWW::Form and WWW::FieldValidator, you
might want to check them out.

Data::FormValidator

Embperl::Form::Validate

Rose::HTML::Form

HTML::Form

=head1 AUTHOR

Ben Schmaus

If you find this module useful or have any suggestions or comments please send
me an email at perlmods@benschmaus.com.

=head1 CHANGELOG

July 2, 2003

Code formatting and cleanup.

Adds support for file inputs.

July 3, 2003

Adds code examples to documentation for public methods.

September 25, 2003

Adds new methods including: resetFields(), isFieldValid(), and
getFieldValidators().

Changes _setFields method to handle empty user values.  That is, in previous
releases, if a form is submitted and the value for a field is empty, the
value of the field will be set to the field's default value if it has one.
This release updates _setFields to prefer submitted values over default
values.

Fixes some pdoc stuff.

September 26, 2003

More pdoc changes.

January 10, 2004

Adds support for displaying multiple submit buttons.

Adds new public method: getSubmitButtonHTML.

Adds support for escaping the value of HTML input 'value' attributes.

January 5, 2005

Adds README file to distribution.

Makes some minor documentation changes.

March 29, 2005

Merged the changes from the repository.

Fixed the MANIFEST.

June 8, 2006

Updates docs.

Adds new methods for dealing with hidden form inputs.

November 18, 2006 - WWW::Form 1.17

Adds support for select boxes with 'multiple' attribute set.  Note that this
needs to be tested in a mod_perl environment.

Fixed CondTestMore to adapt it to the new Test::More.

Removed test.pl in favor of t/00-load.t.

Moved the modules under lib/ to improve the kwalitee.

Moved CondTestMore under t/lib (kwalitee).

Moved form_test.pl to the examples/ directory (kwalitee.)

Added a LICENSE section to the PODs.

Added t/pod.t (kwalitee).

Added t/pod-coverage.t and made the POD have full coverage (for the kwalitee.)

August 23, 2008 - WWW::Form 1.18

Added a rudimentary test to test for valid emails.

Fixed http://rt.cpan.org/Ticket/Display.html?id=32211 .

=head1 TODO

Add more helpful error logging.

Give this module a better namespace?

=head2 Extension Ideas

Write a subclass that supports a templating library like Text::MicroMason
or Text::Template.

Add functionality for generating and performing client side validation.

=head1 THANKS

Thanks to Shlomi Fish for suggestions and code submissions.

=head1 BUGS

Please report them. :)

Bug reports can be filed at:

https://developer.berlios.de/bugs/?group_id=2352

Or you can send email to perlmods at benschmaus dot com.

=head1 SVN

WWW::Form source code can be obtained via anonymous svn access at:

http://svn.berlios.de/wsvn/web-cpan/www-form

=head1 LICENSE

This program is free software.  You may copy or redistribute it under the same
terms as Perl itself.

=cut
