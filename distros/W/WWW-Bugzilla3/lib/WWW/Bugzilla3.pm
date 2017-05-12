#!/usr/bin/perl

# $Id: Bugzilla3.pm 28 2008-10-07 10:09:30Z swined $

package WWW::Bugzilla3;

use warnings;
use strict;

use Carp;
use RPC::XML::Client;
use URI::Escape;

our $VERSION = '0.71';


=head1 NAME

WWW::Bugzilla3 - perl bindings for Bugzilla 3.0 api

=head1 VERSION

v0.71

=head1 SYNOPSIS

	use WWW::Bugzilla3;

	my $bz = new WWW::Bugzilla3(site => 'bugz.somesite.org');
	$bz->login('user@host.org', 'PaSsWoRd');
	...

=head1 FUNCTIONS

=cut

sub _post($$) {
	my ($self, $u, $c) = @_;
        my $wrq = new HTTP::Request(POST => $u);
        $wrq->content($c);
        my $wrs = $self->{rpc}->useragent->request($wrq);
	return $wrs->content;
}

=head2 new()

Creates new Bugzilla3 object.
	 
=cut

sub new($%) {
	my ($class, %param) = @_;
	croak "Cannot create $class without 'site'\n" unless $param{site};
	$param{site} = 'http://' . $param{site} unless $param{site} =~ m|^https?://|i;
	$param{site} .= "/" unless $param{site} =~ /\/$/;
	$param{rpcurl} = $param{site} . 'xmlrpc.cgi';
	$param{rpc} = RPC::XML::Client->new($param{rpcurl});
	$param{rpc}->error_handler(sub { croak shift });
	$param{rpc}->fault_handler(sub { croak shift->{faultString}->value });
	$param{rpc}->useragent->cookie_jar({});
	bless \%param, $class;
	return \%param;
}

=head2 login

	in: login, password
	out: user_id  

Logs into bugzilla.  
	
=cut

sub login($$$) {
	shift->{rpc}->simple_request('User.login', { 
		'login' => shift, 
		'password' => shift,
	})->{id};
}

=head2 logout

Logs out. Does nothing if you are not logged in.
	
=cut

sub logout($) {
	shift->{rpc}->simple_request('User.logout');
}

=head2 offer_account_by_email

	in: email

Sends an email to the user, offering to create an account. The user will have to click on a URL in the email, and choose their password and real name.
	
=cut

sub offer_account_by_email($$) {
	shift->{rpc}->simple_request('User.offer_account_by_email', { 
		email => shift,
	});
}

=head2 create_user
	
	in: email, full_name, password
	out: user_id

Creates a user account directly in Bugzilla. Returns id of newly created user.
	
=cut

sub create_user($$$$) {
	shift->{rpc}->simple_request('User.create', {
		email => shift,
		full_name => shift,
		password => shift,
	})->{id};
}

=head2 get_selectable_products

	out: ids

Returns an array of the ids of the products the user can search on.	
	
=cut

sub get_selectable_products($) {
	@{shift->{rpc}->simple_request('Product.get_selectable_products')->{ids}};
}

=head2 get_enterable_products

	out: ids

Returns an array of the ids of the products the user can enter bugs against.
	
=cut

sub get_enterable_products($) {
	@{shift->{rpc}->simple_request('Product.get_enterable_products')->{ids}};
}

=head2 get_accessible_products

	out: ids

Returns an array of the ids of the products the user can search or enter bugs against.	
	
=cut

sub get_accessible_products($) {
	@{shift->{rpc}->simple_request('Product.get_accessible_products')->{ids}};
}

=head2 get_products

	in: ids
	out: products

Returns an array of hashes. Each hash describes a product, and has the following items: id, name, description, and internals. 
Internals is an internal representation of the product and can be changed by bugzilla at any time.
	
=cut

sub get_products($@) {
	my ($self, @ids) = @_;
	@{$self->{rpc}->simple_request('Product.get_products', {
		'ids' => \@ids,
	})->{products}};
}

=head2 version
	
	out: version

Returns bugzilla version.
	
=cut

sub version($) {
	shift->{rpc}->simple_request('Bugzilla.version')->{version};
}

=head2 timezone

	out: timezone

Returns the timezone of the server Bugzilla is running on.  
	
=cut

sub timezone($) {
	shift->{rpc}->simple_request('Bugzilla.timezone')->{timezone};
}

=head2 legal_values
	
	in: field, product_id
	out: values

Returns an array of values that are allowed for a particular field.
	
=cut

sub legal_values($$$) {
	@{shift->{rpc}->simple_request('Bug.legal_values', {
		field => shift,
		product_id => shift,
	})->{'values'}};
}

=head2 get_bugs

	in: ids
	out: bugs

Gets information about particular bugs in the database. ids is an array of numbers and strings. Returns an array of hashes. Each hash contains the following items:
	id - The numeric bug_id of this bug.
	alias - The alias of this bug. If there is no alias or aliases are disabled in this Bugzilla, this will be an empty string.
	summary - The summary of this bug.
	creation_time - When the bug was created.
	last_change_time - When the bug was last changed.
	
=cut

sub get_bugs($@) {
	my ($self, @ids) = @_;
	@{$self->{rpc}->simple_request('Bug.get_bugs', {
		'ids' => \@ids,
	})->{bugs}};
}

=head2 create_bug 

This allows you to create a new bug in Bugzilla. If you specify any invalid fields, they will be ignored. If you specify any fields you are not allowed to set, they will just be set to their defaults or ignored.
Some params must be set, or an error will be thrown. These params are marked Required.
Some parameters can have defaults set in Bugzilla, by the administrator. If these parameters have defaults set, you can omit them. These parameters are marked Defaulted.
Clients that want to be able to interact uniformly with multiple Bugzillas should always set both the params marked Required and those marked Defaulted, because some Bugzillas may not have defaults set for Defaulted parameters, and then this method will throw an error if you don't specify them.
The descriptions of the parameters below are what they mean when Bugzilla is being used to track software bugs. They may have other meanings in some installations.

	product (string) Required - The name of the product the bug is being filed against. 
	component (string) Required - The name of a component in the product above. 
	summary (string) Required - A brief description of the bug being filed. 
	version (string) Required - A version of the product above; the version the bug was found in. 
	description (string) Defaulted - The initial description for this bug. Some Bugzilla installations require this to not be blank. 
	op_sys (string) Defaulted - The operating system the bug was discovered on. 
	platform (string) Defaulted - What type of hardware the bug was experienced on. 
	priority (string) Defaulted - What order the bug will be fixed in by the developer, compared to the developer's other bugs. 
	severity (string) Defaulted - How severe the bug is. 
	alias (string) - A brief alias for the bug that can be used instead of a bug number when accessing this bug. Must be unique in all of this Bugzilla. 
	assigned_to (username) - A user to assign this bug to, if you don't want it to be assigned to the component owner. 
	cc (array) - An array of usernames to CC on this bug. 
	qa_contact (username) - If this installation has QA Contacts enabled, you can set the QA Contact here if you don't want to use the component's default QA Contact. 
	status (string) - The status that this bug should start out as. Note that only certain statuses can be set on bug creation. 
	target_milestone (string) - A valid target milestone for this product.

In addition to the above parameters, if your installation has any custom fields, you can set them just by passing in the name of the field and its value as a string.
Returns one element, id. This is the id of the newly-filed bug.

=cut

sub create_bug($%) {
	my ($self, %p) = @_;
	my $rs = $self->{rpc}->simple_request('Bug.create', \%p)->{id};
}

=head2 named_search

	in: name
	out: ids

Execute saved search. Returns list of bugs.

=cut

sub named_search($$) {
	shift->search(cmdtype => 'runnamed', namedcmd => shift);
}

=head2 search

Execute search. Returns list of bugs.

=cut

sub search($%) {
	my ($self, %param) = @_;
	$param{ctype} = 'atom';
	my $r = $self->_post($self->{site} . 'buglist.cgi', join '&', 
		map { uri_escape($_) . "=" . uri_escape($param{$_}) } keys %param);
	return grep s/^.*<id>.*?\?id=(\d+)<\/id>.*$/$1/, split "\n", $r;
}

=head2 ua

	out: useragent

Returns LWP::UserAgent object user for communications with bugzilla.

=cut

sub ua($) {
	shift->{rpc}->useragent;
}

1;

=head1 AUTHOR

Alexey Alexandrov, C<< <swined at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-bugzilla3 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Bugzilla3>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WWW::Bugzilla3

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Bugzilla3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Bugzilla3>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Bugzilla3>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Bugzilla3>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Alexey Alexandrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

