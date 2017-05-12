package WebService::EveOnline;

use strict;
use warnings;

use base qw/ WebService::EveOnline::Base /;

our $VERSION = "0.62";
our $AGENT = 'WebService::EveOnline';
our $EVE_API = "http://api.eve-online.com/";
our $DEBUG_MODE = $ENV{EVE_DEBUG_ON} || undef;

=head1 NAME

WebService::EveOnline -- a wrapper intended to (eventually) provide a 
useful interface to the MMORPG game, "Eve Online"

(N.B. Export EVE_USER_ID and EVE_API_KEY to your environment before installing 
to run all tests.) 

Please have a look at the example scripts:

  * examples/show_characters
  * examples/show_corporation  
  * examples/show_transactions
  * examples/skills_overview

They will get you started a lot quicker than the documentation (patches welcome!) ever will,
which is mostly reference.

=head1 VERSION

0.61 - This is an incomplete implementation of the Eve Online API, but is a starting point.

=head1 SYNOPSIS

    use WebService::EveOnline;
    
    my $eve = WebService::EveOnline->new({
        user_id => <user_id>,
        api_key => '<api_key>'
    });
    
    my $character = $eve->character('<character_name or ID>');
    
    print $character->name . " has " .
     $character->balance . " ISK in the pot\n";

    foreach $char ($eve->characters) {
        print $char->name . " has " . scalar($character->skills) .
              " skills.";
    }

    See example scripts for more ways of using the interface.

=head1 DESCRIPTION

L<WebService::EveOnline> (essentially) presents a nice programatic sugar over the
top of the pretty cronky API that CCP games provide. The idea is that an 
interested party (e.g. me) can keep track of what's going on with my characters
in a similar manner to what EveMON does.

There is currently no item data provided with this interface (although the API 
exposes no item data anyway, it'd be nice to have at some point).

Also, no map or wallet information is supported although this will be added as
a priority over the coming weeks.

=cut

=head2 Initialising

WebService::EveOnline is instantiated with a 'standard' (so much as these 
things are) call to "new". Usually, at this point you would pass down a
hashref that contained the keys "user_id" and "api_key" as demonstrated in the
synopsis.

You MUST specify your user_id and api_key parameters in order to get the API to
work, even if you're only interested in returning data where they are not 
normally required by the API.

You may also specify the following parameters:

cache_type: Defaults to 'SQLite'. For now, please keep the default.
cache_dbname: Database to use to store cached skill data.
cache_user: Username of the database to use. Do not use yet.
cache_pass: Password of the database to use. Do not use yet.
cache_init: Set this to 'no' to disable caching. Not recommended.
cache_maxage: Maximum time (in seconds) to wait before a cache rebuild.

Currently, only SQLite databases are supported. Using another database should
be fairly straightforward to add in, but isn't available yet.

You can specify ":memory" as the cache_dbname to build the cache in memory if
required.

=head1 API

API reference as follows:

=cut

=head2 new
   
Set up the initial object by calling the new method on it. It is important to
pass a valid user id and api key (available from http://api.eve-online.com/)
or this module will not do anything useful. That is does anything useful at
all is debatable, but it does let me print out my favourite character's account
balance, so that's pretty much all I want/need it to do at the moment... :-)

    my $eve = WebService::EveOnline->new({
        user_id => <user_id>,
        api_key => '<api_key>'
    });

=cut

=head2 SEE ALSO 

Please look at the individual WebService::EveOnline::API::* modules for
documentation on how to extract other data from the API.

L<WebService::EveOnline::API::Character>
L<WebService::EveOnline::API::Skills>
L<WebService::EveOnline::API::Transactions>
L<WebService::EveOnline::API::Journal>
L<WebService::EveOnline::API::Map>

=cut

=head2 "ONE-LINERS"

By setting the environment variables EVE_USER_ID and EVE_API_KEY, it is possible
to write short(ish) 'one-liners' returning data from your account like this:

 perl -MWebService::EveOnline \
 -e'print WebService::EveOnline->new->character('name')->account_balance'
 
 perl -MWebService::EveOnline \
 -e'print map{$_->character_name."\n"}WebService::EveOnline->new->characters'

=cut

sub new {
    my ($class, $params) = @_;

    # this is surprisingly handy, as it allows for one-liners assuming
    # the environment variables are appropriately set:
    $params->{user_id} ||= $ENV{EVE_USER_ID};
    $params->{api_key} ||= $ENV{EVE_API_KEY};

    unless (ref($params) eq "HASH" && $params->{user_id} && $params->{api_key}) {
        die("Cannot instantiate without a user_id/api_key!\nPlease visit $EVE_API if you still need to get one.");
    }

    return bless(WebService::EveOnline::Base->new($params), $class);
}


=head1 BUGS

If you don't happen to have my specific user_id and api_key, you milage may 
*seriously* vary. I've not been playing Eve Online all that long, and there 
are probably dozens of edge cases I need to look at and resolve.

Contributions/patches/suggestions are all gratefully received.

A public subversion repository is available at:

  http://theantipop.org/eve

Please report any bugs or feature requests to C<bug-webservice-eveonline at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-EveOnline>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 MOTIVATION

Frankly, whilst the Eve Online API is better than nothing, it's pretty horrible
to work with. I wanted to concentrate on my code rather than parsing results, so
I decided to hide the gory details away in a nice module I didn't have to look at
much. Having said that, by no means is this code considered anything other than a
quick and dirty hack that does precisely the job I want it to do (and no more).

=head1 AUTHOR

Chris Carline, C<< <chris at carline.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Chris Carline, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub _debug {
    my ($class, $params) = @_;

    $params ||= {};
    $params->{_debug} = 1;
    $WebService::EveOnline::DEBUG_MODE = 1;
    warn "Switching on debugging statements:\n";
    
    return new($class, $params);
}

1;
