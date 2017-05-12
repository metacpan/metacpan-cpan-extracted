package Web::Paste::Simple;

use 5.010;
use Moo;
use MooX::Types::MooseLike::Base qw( Str CodeRef ArrayRef InstanceOf );
use Carp qw( confess );
use JSON qw( from_json to_json );
use HTML::HTML5::Entities qw( encode_entities_numeric );
use constant read_only => 'ro';
use aliased 'Text::Template';
use aliased 'Data::UUID';
use aliased 'Plack::Request';
use aliased 'Plack::Response';
use aliased 'Path::Class::Dir';
use aliased 'Path::Class::File';

BEGIN {
	$Web::Paste::Simple::AUTHORITY = 'cpan:TOBYINK';
	$Web::Paste::Simple::VERSION   = '0.002';
}

has uuid_gen => (
	is      => read_only,
	isa     => InstanceOf[UUID],
	default => sub { UUID->new },
);

has template => (
	is      => read_only,
	isa     => InstanceOf[Template],
	lazy    => 1,
	default => sub {
		return Template->new(
			TYPE   => 'FILEHANDLE',
			SOURCE => \*DATA,
		);
	},
);

has storage => (
	is      => read_only,
	isa     => InstanceOf[Dir],
	default => sub { Dir->new('/tmp/perl-web-paste-simple/') },
);

has codemirror => (
	is      => read_only,
	isa     => Str,
	default => sub { 'http://buzzword.org.uk/2012/codemirror-2.36' },
);

has app => (
	is      => read_only,
	isa     => CodeRef,
	lazy    => 1,
	builder => '_build_app',
);

has modes => (
	is      => read_only,
	isa     => ArrayRef[Str],
	default => sub {
		[qw(
			htmlmixed xml css javascript
			clike perl php ruby python lua haskell
			diff sparql ntriples plsql
		)]
	},
);

has default_mode => (
	is      => read_only,
	isa     => Str,
	default => sub { 'perl' },
);

sub _build_app
{
	my $self = shift;
	
	$self->storage->mkpath unless -d $self->storage;
	confess "@{[$self->storage]} is not writeable" unless -w $self->storage;
		
	return sub {
		my $req = Request->new(shift);
		$self->dispatch($req)->finalize;
	};
}

sub dispatch
{
	my ($self, $req) = @_;
	
	if ($req->method eq 'POST') {
		return $self->create_paste($req);
	}
	elsif ($req->path =~ m{^/([^.]+)}) {
		return $self->retrieve_paste($req, $1);
	}
	elsif ($req->path eq '/') {
		return $self->show_template($req, {});
	}
	else {
		return $self->show_error("Bad URI", 404);
	}
}

sub make_paste_id
{
	my $id = shift->uuid_gen->create_b64;
	$id =~ tr{+/}{-_};
	$id =~ s{=+$}{};
	return $id;
}

sub create_paste
{
	my ($self, $req) = @_;
	my $id = $self->make_paste_id;
	$self->storage->file("$id.paste")->spew(
		to_json( +{ %{$req->parameters} } ),
	);
	return Response->new(
		302,
		[
			'Content-Type' => 'text/plain',
			'Location'     => $req->base . "/$id",
		],
		"Yay!",
	);
}

sub retrieve_paste
{
	my ($self, $req, $id) = @_;
	my $file = $self->storage->file("$id.paste");
	-r $file or return $self->show_error("Bad file", 404);
	my $data = from_json($file->slurp);
	
	exists $req->parameters->{raw}
		? Response->new(200, ['Content-Type' => 'text/plain'], $data->{paste})
		: $self->show_template($req, $data);
}

sub show_template
{
	my ($self, $req, $data) = @_;
	my $page = $self->template->fill_in(
		HASH => {
			DATA       => encode_entities_numeric($data->{paste} // ''),
			MODE       => encode_entities_numeric($data->{mode}  // $self->default_mode),
			MODES      => $self->modes,
			PACKAGE    => ref($self),
			VERSION    => $self->VERSION,
			CODEMIRROR => $self->codemirror,
			APP        => $self,
			REQUEST    => $req,
		},
	);
	Response->new(200, ['Content-Type' => 'text/html'], $page);
}

sub show_error
{
	my ($self, $err, $code) = @_;
	Response->new(($code//500), ['Content-Type' => 'text/plain'], "$err\n");
}


1;

=head1 NAME

Web::Paste::Simple - simple PSGI-based pastebin-like website

=head1 SYNOPSIS

	#!/usr/bin/plackup
	use Web::Paste::Simple;
	Web::Paste::Simple->new(
		storage    => Path::Class::Dir->new(...),
		codemirror => "...",
		template   => Text::Template->new(...),
	)->app;

=head1 DESCRIPTION

Web::Paste::Simple is a lightweight PSGI app for operating a
pastebin-like website. It provides syntax highlighting via the
L<CodeMirror|http://codemirror.net/> Javascript library. It
should be fast enough for deployment via CGI.

It does not provide any authentication facilities or similar,
instead relying on you to use subclassing/roles or L<Plack>
middleware to accomplish such things.

=head2 Constructor

=over

=item C<< new(%attrs) >>

Standard Moose-style constructor.

This class is not based on Moose though; instead it uses L<Moo>.

=back

=head2 Attributes

The following attributes are defined:

=over

=item C<storage>

A L<Path::Class::Dir> indicating the directory where pastes
should be stored. Pastes are kept indefinitely. Each is a single
file.

=item C<codemirror>

Path to the CodeMirror syntax highlighter as a string. For example,
if CodeMirror is available at C<< http://example.com/js/lib/codemirror.js >>
then this string should be C<< http://example.com/js >> with no trailing
slash.

This defaults to an address on my server, but for production sites,
I<please> set up your own copy: it only takes a couple of minutes;
just a matter of unzipping a single archive. I offer no guarantees
about the continued availability of my copy of CodeMirror.

Nothing is actually done with this variable, but it's passed to the
template.

=item C<template>

A L<Text::Template> template which will be used for I<all> HTML output.
The following variables are available to the template...

=over

=item *

C<< $DATA >> - the text pasted on the curent page (if any), already HTML escaped

=item *

C<< $MODE >> - the currently selected syntax highlighting mode (if any), already HTML escaped

=item *

C<< @MODES >> - all configured highlighting modes

=item *

C<< $CODEMIRROR >> - the path to codemirror

=item *

C<< $APP >> - the blessed Web::Paste::Simple object

=item *

C<< $REQUEST >> - a blessed L<Plack::Request> for the current request

=item *

C<< $PACKAGE >> - the string "Web::Paste::Simple"

=item *

C<< $VERSION >> - the Web::Paste::Simple version number

=back

The default template is minimal, but works.

=item C<modes>

The list of CodeMirror highlighting modes to offer to the user.

Nothing is actually done with this variable, but it's passed to the
template.

=item C<default_mode>

The default highlighting mode.

=item C<uuid_gen>

A L<Data::UUID> object used to generate URIs. The default should be fine.

=back

=head2 Methods

The following methods may be of interest to people subclassing
L<Web::Paste::Simple>.

=over

=item C<app>

Technically this is another attribute, but one that should not be set
in the constructor. Call this method to retrieve the L<PSGI> coderef.

This coderef is built by C<_build_app> (a Moo lazy builder).

=item C<dispatch>

Basic request router/dispatcher. Given a L<Plack::Request>, returns a
L<Plack::Response>.

=item C<create_paste>

Given a L<Plack::Request> corresponding to an HTTP C<POST> request,
saves the paste and returns a L<Plack::Reponse>. The response may
be an arror message, success message, or (as per the current
implementation) a redirect to the paste's URI.

=item C<retrieve_paste>

Given a L<Plack::Request> and a paste ID, returns a L<Plack::Response>
with a representation of the paste, or an error message.

=item C<show_error>

Given an error string and optionally an HTTP status code, returns a
L<Plack::Response>.

=item C<show_template>

Given a L<Plack::Request> and a hashref of data (possibly including
C<paste> and C<mode> keys) returns a L<Plack::Response> with the rendered
template, and the pasted data plugged into it.

=item C<make_paste_id>

Returns a unique ID string for a paste. The current implementation is
a base64-encoded UUID.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Paste-Simple>.

=head1 SEE ALSO

L<Plack>,
L<Moo>,
L<CodeMirror|http://codemirror.net/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

__DATA__
<!doctype html>
<title>{$PACKAGE} {$VERSION}</title>
<link rel="stylesheet" href="{$CODEMIRROR}/lib/codemirror.css">
<script src="{$CODEMIRROR}/lib/codemirror.js"></script>
{
	for my $m (@MODES) {
		$OUT .= qq[<script src="$CODEMIRROR/mode/$m/$m.js"></script>\n]
	}
}
<form action="" method="post">
	<div>
		<select name="mode" onchange="change_mode();">
			{
				for my $m (@MODES) {
					$OUT .= qq[<option @{[$m eq $MODE ? 'selected':'']}>$m</option>\n]
				}
			}
		</select>
		<input type="submit" value=" Paste ">
		<br>
		<textarea name="paste">{$DATA}</textarea>
	</div>
</form>
<script>
var ta = document.getElementsByTagName("textarea");
var editor = CodeMirror.fromTextArea(ta[0], \{
	lineNumbers: true,
	matchBrackets: true,
	indentUnit: 4,
	mode: "{$MODE}",
\});
function change_mode () \{
	var s = document.getElementsByTagName("select");
	editor.setOption("mode", s[0].options[s[0].selectedIndex].value);
\}
</script>
