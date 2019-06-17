#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 5;

use WWW::Form;

# Test that _getTextAreaHTML escapes its HTML.
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
    );

    my $retrieved_text = $form->_getTextAreaHTML("comments", "");

    # TEST
    is ($retrieved_text,
        q{<textarea name='comments'>&lt;/textarea&gt;&lt;h1&gt;You have been Exploited! (&amp; more)&lt;/h1&gt;</textarea>},
        "Textarea HTML Escape"
       );

    # TEST
    $retrieved_text = $form->_getInputHTML("first_name", "");
    is ($retrieved_text,
        q{<input type='text' name='first_name' id='first_name' value="Josephine" />},
        "First Name HTML Fetch",
    );
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
        'is_female' =>
        {
            type => "checkbox",
            label => "Are you a Female?",
            defaultValue => "Yes.",
            defaultChecked => 0,
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
        'is_female' => 0,
        'first_name' => "\"Ben&Shlomi\" <bas\@hello.com>",
        'comments' => "</textarea><h1>You have been Exploited! (& more)</h1>",
    );

    my $form = WWW::Form->new(
        \%fields_data,
        \%fields_values,
    );

    my $retrieved_text = $form->_getInputHTML("first_name", "");

    # TEST
    is ($retrieved_text,
        q{<input type='text' name='first_name' id='first_name' value="&quot;Ben&amp;Shlomi&quot; &lt;bas@hello.com&gt;" />},
        "First Name Escaping Test",
        );

    $retrieved_text = $form->_getCheckBoxHTML("is_female", "");

    # TEST
    is ($retrieved_text,
        q{<input type='checkbox' name='is_female' id='is_female' value="Yes." />},
        "Checkbox Unset Value"
    );

    %fields_values =
    (
        'is_female' => 1,
        'first_name' => "\"Ben&Shlomi\" <bas\@hello.com>",
        'comments' => "</textarea><h1>You have been Exploited! (& more)</h1>",
    );

    $form = WWW::Form->new(
        \%fields_data,
        \%fields_values,
    );

    $retrieved_text = $form->_getCheckBoxHTML("is_female", "");

    # TEST
    is ($retrieved_text,
        q{<input type='checkbox' name='is_female' id='is_female' value="Yes." checked='checked' />},
        "Checkbox Set Value"
    );
}

