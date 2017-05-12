#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 3;

use WWW::FieldValidator;

{
    my $validator =
        WWW::FieldValidator->new(
            WWW::FieldValidator::WELL_FORMED_EMAIL,
            'Please make sure you enter a well formed email address'
        );

    # TEST
    ok ($validator, "email validator initialised");

    # TEST
    ok ($validator->validate(q{shlomif@iglu.org.il}), "Email 1");

    # TEST
    ok ($validator->validate(q{john@abd-def.com}), "Email with hyphens");
}


