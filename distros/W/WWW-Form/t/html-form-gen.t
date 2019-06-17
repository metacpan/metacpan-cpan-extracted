#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 2;

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
    );

    my %fields_values =
    (
        'first_name' => "Josephine",
        'comments' => "</textarea><h1>You have been Exploited! (& more)</h1>",
    );

    my $form = WWW::Form->new(
        \%fields_data,
        \%fields_values,
        [ qw(first_name comments) ],
    );

    # TEST
    is($form->get_form_HTML('action' => "",), <<"EOF");
<form action='' method='post'>
<table>
<tr><td>First Name</td><td><input type='text' name='first_name' id='first_name' value="Josephine" /></td></tr>
<tr><td>Your Comments</td><td><textarea name='comments'>&lt;/textarea&gt;&lt;h1&gt;You have been Exploited! (&amp; more)&lt;/h1&gt;</textarea></td></tr>
</table>
<p><input type='submit' value='Submit' name='submit' />
</p>
</form>
EOF
}

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
        'myhide' =>
        {
            label => "My Hide",
            defaultValue => "hello",
            type => "hidden",
        },
    );

    my %fields_values =
    (
        'first_name' => "Josephine",
        'comments' => "</textarea><h1>You have been Exploited! (& more)</h1>",
        'myhide' => "JohnSmith",
    );

    my $form = WWW::Form->new(
        \%fields_data,
        \%fields_values,
        [ qw(myhide first_name comments) ],
    );

    # TEST
    is($form->get_form_HTML('action' => "",), <<"EOF");
<form action='' method='post'>
<input type='hidden' name='myhide' id='myhide' value="JohnSmith" />
<table>
<tr><td>First Name</td><td><input type='text' name='first_name' id='first_name' value="Josephine" /></td></tr>
<tr><td>Your Comments</td><td><textarea name='comments'>&lt;/textarea&gt;&lt;h1&gt;You have been Exploited! (&amp; more)&lt;/h1&gt;</textarea></td></tr>
</table>
<p><input type='submit' value='Submit' name='submit' />
</p>
</form>
EOF
}
