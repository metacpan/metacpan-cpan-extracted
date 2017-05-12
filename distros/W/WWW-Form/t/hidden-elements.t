#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 1;

use WWW::Form;

{
    my %fields_data =
    (
        'first_name' =>
        {
            label => "First Name",
            defaultValue => "Joe",
            type => "text",
        },
        'comments' =>
        {
            label => "Your Comments",
            defaultValue => "Enter your comments here.",
            type => "textarea",
        },
        'id' =>
        {
            label => "ID",
            defaultValue => "6500",
            type => "hidden",
        },
    );

    my %fields_values =
    (
        'first_name' => "Josephine",
        'comments' => "</textarea><h1>You have been Exploited! (& more)</h1>",
        'id' => "10200",
    );

    my $form = WWW::Form->new(
        \%fields_data,
        \%fields_values,
        [ qw(id first_name comment) ],
    );
 
    # TEST
    is ($form->getFieldHTMLRow('id'), <<"EOF", "Expecting a display:none default row HTML");
<tr style="display:none">
<td></td>
<td><input type='hidden' name='id' id='id' value="10200" /></td>
</tr>
EOF
}
