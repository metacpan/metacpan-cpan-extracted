#!/usr/bin/perl

#-----------------------------------------------------------------------------
# Use this program to get a feel for how to use WWW::Form and
# WWW::FieldValidator
#
# This program must be placed in a web accessible and CGI executable location
# in order for it to run properly
#-----------------------------------------------------------------------------

use strict;
use warnings;

use CGI;
use Data::Dumper;

# both of these need to be installed to run this test program
use WWW::Form;
use WWW::FieldValidator;

# gets us access to the HTTP request data
my $q = CGI->new();

# hash ref of HTTP vars
my $params = $q->Vars();

# this gets us our Form object
my $form = WWW::Form->new(getFormFields(), $params, getFieldsOrder());

# display the HTML form test page
printHTMLPage();

#-----------------------------------------------------------------------------
# Start subroutines needed to build form test page
#-----------------------------------------------------------------------------

sub printHTMLPage {

print <<HTML;
Content-Type: text/html

<html>
<head>
<title>Form Test Page</title>
</head>
<body>
HTML
    print "<p>WWW::Form version: $WWW::Form::VERSION<br />";
    print "WWW::FieldValidator version: $WWW::FieldValidator::VERSION</p>";

    print "HTTP POST Variables<pre>" . Data::Dumper::Dumper($params) .
        "</pre>";

    # uncomment the following Data::Dummper line if you
    # want to look at the internal structure of the Form module
    #print "Form object\n<pre>" . Data::Dumper::Dumper($form) . "</pre>";

    print "\n<h2>" . getFormStatusMessage() . "</h2>\n";

    print $form->getFormHTML(
        action => 'form_test.pl',
        is_file_upload => 1,
    );

print <<HTML;
</body>
</html>
HTML
}

# uses the isSubmitted, validateFields, and isValid methods of WWW::Form
# object
sub getFormStatusMessage() {
    # init status message to display in the form test web page
    my $formStatusMessage = 'Form has not been submitted';

    # check to see that the form was submitted
    if ($form->isSubmitted($ENV{REQUEST_METHOD})) {

        # the form was POSTed so validate the user entered input
        $form->validateFields();

        # update our status message depending on whether or not the form data
        # was good if the form data is good then do some stuff
        if ($form->isValid()) {
            $formStatusMessage = 'Form was submitted and the data is good';
        }
        else {
            $formStatusMessage = 'Form was submitted and the data is bad';
        }
    }
    return $formStatusMessage;
}

# Returns data structure suitable for passing to WWW::Form object constructor
# this example covers how to handle all of the various types of form inputs
# with WWW::Form
sub getFormFields {
    my $pass = $params->{password} || "";
    my %fields = (
        emailAddress => {
            label        => 'Email address',
            defaultValue => '',
            type         => 'text',
            validators   => [
                WWW::FieldValidator->new(
                    WWW::FieldValidator::WELL_FORMED_EMAIL,
                    'Make sure email address is well formed'
                )
            ]
        },
        name => {
            label        => 'Full name',
            defaultValue => '',
            type         => 'text',
            validators   => [
                WWW::FieldValidator->new(
                    WWW::FieldValidator::MIN_STR_LENGTH,
                    'Please enter your name (at least 3 characters)',
                    3
                )
            ]
        },
        aHiddenInput => {
            label        => '',
            defaultValue => 'Hey, I am a hidden form input, nice to meet you!',
            type         => 'hidden',
            validators   => []
        },
        password => {
            label        => 'Password',
            defaultValue => '',
            type         => 'password',
            validators   => [
                WWW::FieldValidator->new(
                    WWW::FieldValidator::MIN_STR_LENGTH,
                    'Password must be at least 6 characters',
                    6
                )
            ]
        },
        passwordConfirm => {
            label        => 'Confirm password',
            defaultValue => '',
            type         => 'password',
            validators   => [
                WWW::FieldValidator->new(
                    WWW::FieldValidator::MIN_STR_LENGTH,
                    'Password confirm must be at least 6 characters',
                    6
                ),
                WWW::FieldValidator->new(
                    WWW::FieldValidator::REGEX_MATCH,
                    'Passwords must match', '^' . $pass . '$'
                )
            ]
        },
        uploadFile => {
            label => 'Select a file to upload',
            defaultValue => '',
            type => 'file',
            validators => []
        },
        spam => {
            label          => 'Do we have your permission to send you spam?',
            defaultValue   => 'Yes, spam me.',
            defaultChecked => 0, # set to 1 to check by default
            type           => 'checkbox',
            validators     => []
        },
        comments => {
            label        => 'Comments',
            defaultValue => '',
            type         => 'textarea',
            validators   => [
                WWW::FieldValidator->new(
                    WWW::FieldValidator::MIN_STR_LENGTH,
                    "If you're going to say something, how about at least 10" .
                    " characters?",
                    10,
                    1 # Optional field
                )
            ]
        },
        favoriteColor => {
            label        => 'Favorite color',
            # set to 'green', 'red', or 'blue' to set default option group
            defaultValue => '',
            type         => 'select',
            optionsGroup => [
                {label => 'Green', value => 'green'},
                {label => 'Red',   value => 'red'},
                {label => 'Blue',  value => 'blue'}
            ],
            validators   => []
        },
        breakfastBreads => {
            label        => 'What Breakfast Breads Do You Like?',
            defaultValue => '',
            type         => 'select',
            optionsGroup => [
                {label => 'Bagel', value => 'bagel'},
                {label => 'Muffin',   value => 'muffin'},
                {label => 'Toast',  value => 'toast'}
            ],
            extraAttributes => " multiple='multiple' size='3' ",
            validators   => []
        },
        elvisOrBeatles => {
            label        => 'Do you like Elvis or the Beatles',
            # uncomment to leave group unchecked by default
            defaultValue => 'I am a Beatles dude(tte)',
            type         => 'radio',
            optionsGroup => [
                {
                    label => 'I like Elvis',
                    value => "I am an Elvis dude(tte)"
                },
                {
                    label => 'I like the Beatles',
                    value => "I am a Beatles dude(tte)"
                }
            ],
            validators   => []
        }
    );
    return \%fields;
}

# Array ref that is used to display form inputs in the order specified by this
# array ref, elements of this array should correspond to keys of getFormFields
sub getFieldsOrder {
    my @fields_order = qw(
        name
        emailAddress
        aHiddenInput
        password
        passwordConfirm
        uploadFile
        comments
        favoriteColor
        breakfastBreads
        elvisOrBeatles
        spam
    );
    return \@fields_order;
}
