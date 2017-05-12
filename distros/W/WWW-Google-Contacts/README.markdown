WWW-Google-Contacts
===================

Synopsis
--------

A Perl interface to Google Contacts.

CURRENTLY NOT WORKING
---------------------

This module is currently not working. Some time back, Google obsoleted the authentication method
used by this module.

Patches for updating how authentication is handled are more than welcome!


Usage
-----

    use WWW::Google::Contacts;

    my $google = WWW::Google::Contacts->new(
        username => "your.username",
        password => "your.password",
        protocol => "https",
    );

    # Create a new contact
    my $contact = $google->new_contact;
    $contact->full_name("Emmett Brown");
    $contact->name_prefix("Dr");
    $contact->email('doctor@timetravel.org');
    $contact->hobby("Time travel");
    $contact->jot([ "Went back in time", "Went forward in time", "Became blacksmith" ]),
    $contact->create;  # save it to the server

    # Now search for the given name, and read the jots
    my @contacts = $google->contacts->search({ given_name => "Emmett" });
    foreach my $c ( @contacts ) {
        print "Got the following jots about the good doctor\n";
        foreach my $jot ( @{ $c->jot } ) {
            print "Jot: " . $jot->value . "\n";
        }
        print "And now he goes back to the future\n";
        $c->delete;
    }

    # Print the names of all groups
    my $groups = $google->groups;
    while ( my $group = $groups->next ) {
        print "Title = " . $group->title . "\n";
    }

    # Add the contact to existing group 'Movie stars' and to a new group 'Back to the future'
    my $new_group = $google->new_group({ title => "Back to the future" });
    $new_group->create;  # create on server

    my @groups = $google->groups->search({ title => "Movie stars" });
    my $movie_stars_group = shift @groups;

    $contact->add_group_membership( $new_group );
    $contact->add_group_membership( $movie_stars_group );
    $contact->update;


Description
-----------

This module implements the [the Google Contacts API version 3.0](http://code.google.com/apis/contacts/docs/3.0/developers_guide_protocol.html),
allowing you to easily create, retrieve, update and delete contacts and contact groups you have in your Google account using Perl.

