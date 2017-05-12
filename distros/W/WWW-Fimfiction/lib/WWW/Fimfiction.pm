package WWW::Fimfiction;

use 5.014;
use strict;
use warnings FATAL => 'all';
use HTML::TreeBuilder;
use LWP::UserAgent;
use HTTP::Cookies;
use XML::Twig;
use Carp 'croak';
use JSON 'decode_json';

our $VERSION = 'v0.3.7';

=head1 NAME

WWW::Fimfiction - CRUD tasks for fimfiction.net

=cut

=head1 SYNOPSIS

	use WWW::Fimfiction;

	my $ua = WWW::Fimfiction->new;

	$ua->login($username, $password);

	$ua->add_chapter($story_id, 'My Fabulous Chapter %i%', $text);

=head1 METHODS

Methods without explicit return values will return the WWW::Fimfiction object. Methods
will croak if something goes wrong.

Bear in mind that the site doesn't take kindly to request spam, so consecutive calls
will have a small delay placed between them so the server doesn't get angry with you.

=head2 new

Makes a new object.

=cut

sub new {
	my $class = shift;

	my $ua = LWP::UserAgent->new( cookie_jar => HTTP::Cookies->new );
	$ua->agent("WWW-Fimfiction/$VERSION ");

	return bless { ua => $ua, last_request => 0 }, $class;
}

sub _ua {
	my $self = shift;
	return $self->{ua};
}

sub _assert_auth {
	my $self = shift;
	unless( $self->{auth} ) {
		croak "Authentication required. Try calling ->login first.";
	}
}

sub _post {
	my $self = shift;

	# Fimfiction will return an error if you try and spam requests,
	# so sleep for a little if there's multiple requests
	my $phase = $self->{last_request} + 2 - time;
	sleep($phase) if $phase > 0;

	my $res = $self->_ua->post(@_);

	if( $res->is_success ) {
		$self->{last_request} = time;
		return $res;
	}
	else {
		croak "Error: " . $res->status_line;
	}
}

sub _get {
	my $self = shift;

	my $res = $self->_ua->get(@_);

	if( $res->is_success ) {
		return $res;
	}
	else {
		croak "Error: " . $res->status_line;
	}
}

=head2 login

Args: ($username, $password)

Authenticates the user. Tasks that manipulate data on the site require authentication,
so you'll have to call this before trying to add/edit/delete stuff.

=cut

sub login {
	my( $self, $username, $password ) = @_;

	my $res = $self->_post('http://www.fimfiction.net/ajax/login.php', {
		username => $username,
		password => $password,
	});

	my $code = $res->decoded_content;

	if( $code eq '0' ) {
		$self->{auth} = $username;
		return $self;
	}
	elsif( $code eq '1' ) {
		croak 'Invalid password';
	}
	elsif( $code eq '2' ) {
		croak 'Invalid username';
	}
	else {
		croak "Bad credentials";
	}
}

=head2 add_chapter

Args: ($story_id, [$chapter_title, $content])

Adds a chapter to the given story. Returns the chapter id.

If provided, additional arguments will be given to edit_chapter().

=cut

sub add_chapter {
	my( $self, $story_id, $chapter_title, $content ) = @_;
	my $chapter_id;

	$self->_assert_auth;

	my $form = { story => $story_id, title => $chapter_title };

	my $res = $self->_post('http://www.fimfiction.net/ajax/modify_chapter.php', $form);

	my $elt = XML::Twig::Elt->parse($res->decoded_content);

	if( my $error = $elt->field('error') ) {
		croak $error;
	}

	unless( $chapter_id = $elt->field('id') ) {
		croak "Unexpected response: " . $res->decoded_content;
	}

	if( defined $content ) {
		$self->edit_chapter($chapter_id, $chapter_title, $content);
	}

	return $chapter_id;
}

=head2 edit_chapter

Args: ($id, $title, $content)

Edits chapter with the given title and content.

=cut

sub edit_chapter {
	my( $self, $id, $title, $content ) = @_;

	$self->_assert_auth;

	my $form = { chapter => $id, title => $title, content => $content };

	my $res = $self->_post('http://www.fimfiction.net/ajax/modify_chapter.php', $form);

	# Reading the XML output here sometimes results in an unexpected error because Fimfiction spits
	# out what XML::Twig considers invalid markup. The data isn't necessary except to check for
	# error messages, so we'll just not bother.
	return $self;
}

=head2 publish_chapter

Args: ($id)

Toggles the publish status of a chapter. Returns 1 or 0 indicating the chapter's new publish status.

=cut

sub publish_chapter {
	my( $self, $id ) = @_;

	$self->_assert_auth;

	my $form = { chapter => $id };

	my $res = $self->_post('http://www.fimfiction.net/ajax/publish_chapter.php', $form);

	my $elt = XML::Twig::Elt->parse($res->decoded_content);

	if( my $error = $elt->field('error') ) {
		croak $error;
	}
	elsif( ( my $status = $elt->field('published') ) ne '' ) {
		return $status;
	}
	else {
		croak "Unexpected response: " . $res->decoded_content;
	}
}

=head2 delete_chapter

Args: ($id)

Deletes a chapter.

=cut

sub delete_chapter {
	my ( $self, $id ) = @_;

	$self->_assert_auth;

	my $form = { chapter => $id, confirm => 'on' };

	# Get the form first, which has a 'noonce' value to confirm deletion (why?)
	my $res = $self->_get("http://www.fimfiction.net/?view=delete_chapter&chapter=$id");

	my $tree = HTML::TreeBuilder->new;
	$tree->parse_content($res->decoded_content);

	$form->{noonce} = $tree->look_down(_tag => 'input', name => 'noonce')->attr('value')
		or croak "Unable to find hidden 'noonce' input field";

	# Do the actual deletion
	$self->_post('http://www.fimfiction.net/index.php?view=delete_chapter', $form);

	return $self;
}

=head2 get_story

Args: ($id)

Returns a hash ref of story metadata.

=cut

sub get_story {
	my( $self, $id ) = @_;

	my $res = $self->_get("http://www.fimfiction.net/api/story.php?story=$id");

	return decode_json($res->decoded_content)->{story};
}

=head1 AUTHOR

Cameron Thornton E<lt>cthor@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2012 Cameron Thornton.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

1;