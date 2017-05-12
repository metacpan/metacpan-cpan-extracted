package WWW::Mechanize::Plugin::AutoWrite;

=head1 NAME

WWW::Mechanize::Plugin::AutoWrite - WWW::Mechanize plugin that writes the fetched pages to the disk.

=head1 SYNOPSIS

	use WWW::Mechanize;
	use WWW::Mechanize::Plugin::AutoWrite;
	
	my $mech = WWW::Mechanize->new();
	$mech->autowrite->file('/tmp/mech.html');
	
	$mech->get('http://search.cpan.org/');
	# now the contents of the page is written to /tmp/mech.html

or:

	my $mech = WWW::Mechanize->new();
	$mech->autowrite->dir('/tmp/mech/');
	
	$mech->get('http://search.cpan.org/');
	# now the contents of the page are written to /tmp/mech/001.html and the HTTP
	# transaction is logged into /tmp/mech/001.http

	$mech->submit_form(
		'form_name' => 'f',
		'fields'    => {
			'query' => 'WWW::Mechanize::Plugin::AutoWrite',
			'mode'  => 'module', 
		},
	);
	# Now the pages are saved into /tmp/mech/002.html and /tmp/mech/002.http


or:

	my $mech = WWW::Mechanize->new();
	$mech->autowrite->dir('/tmp/mech/');           # Save the whole session
	$mech->autowrite->file('/tmp/mech/last.html'); # Save the last page in a file
	
	$mech->get('http://www.wikipedia.com/');
	# now the contents of the page are written both to /tmp/mech/001.html and 
	# /tmp/mech/last.html
	$mech->follow_link(text => 'Galego');

=head1 DESCRIPTION

L<WWW::Mechanize::Plugin::AutoWrite> overrides the method 
L<WWW::Mechanize::request> with a custom version that records all HTTP
transactions into the disk. This has for effect that every time that a new HTTP
request is made (GET, POST, etc) the contents of the page returned by the server
and the HTTP transaction (the request and the response) are stored into local
file(s) on disk.

If no destination file/folder is provided then this module will act as a noop
and nothing will be written to the disk. It's also possible to provide both a
file and a folder in order to have the HTTP session and the last page saved
simultaneously.

=head1 RATIONALE

The idea is to have the static page loaded into a web browser and to reload the
page as needed. A better idea is to use a browser that has a builtin mechanism
for monitoring changes to local files. The I<epiphany> web browser does this
automatically once a page is loaded through the procotol C<file://>

Another reason for the existence of this module is to be able to trace an HTTP
transaction in order to debug better I<mechanizing> operations performed on
complex web sites.

=head1 ATTRIBUTES

This module can be configured through the attributes enumerated here.

=head2 file

Get/set the name of the file where the last page downloaded (the content's of
the HTTP response) will be saved.

Set this attribute to a false value in order to disable the saving of the last
page downloaded.

=head2 dir

Get/set the name of the folder where the HTTP session (the content's of the HTTP
response as well as the HTTP headers) will be saved.

Set this attribute to a false value in order to disable the saving of the HTTP
session.

=head2 counter

Get/set the counter used no name each file with a unique name when saving the
HTTP session (the counter is used only when L</dir> is set).


It can be useful to reset the counter when multiple sessions need to be saved
into different folders.

	foreach my $entry (@entries) {
		$mech->autowrite->dir("/tmp/$entry/");
		$mech->autowrite->counter(0);
		# Complex mechanize		
		mechanize_process($mech, $entry);
	}

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use File::Slurp qw{ write_file };
use File::Path qw{ mkpath };
use File::Spec;
use File::Basename qw{ fileparse };

use MIME::Types;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		file
		dir
		counter
	)
);


# We need a reference to the original method used by mechanize for the requests.
my $REQUEST_SUB;
BEGIN {
	$REQUEST_SUB = \&WWW::Mechanize::request;
}


# MIME types lookup
my $MIME_TYPES = MIME::Types->new();


=head1 METHODS

This module offers the following public methods:

=cut


#
# Returns the next iteration of the counter. This method initializes the counter
# the first time it's invoked.
#
sub _inc_counter {
	my $self = shift;
	
	if (! defined $self->{'counter'}) {
		$self->{'counter'} = 0;
	}
	
	return ++$self->{'counter'};
}


=head2 write_to_file

This method writes the HTTP requests into a file and/or a folder. It's called
automatically by mechanize once the plugin is loaded and configured.

=cut

sub write_to_file {
	my $self = shift;
	my ($mech, $request, $response) = @_;


	# write to a single file if autowrite is set
	if (my $filename = $self->file) {
		# Make sure that the path to the file exists
		my (undef, $folder) = fileparse($filename);
		mkpath($folder);
		
		write_file($filename, $mech->content);
	}


	# write to multiple files in a folder if autowritedir is set
	if (my $foldername = $self->dir) {
		mkpath($foldername);    # works fine with already existing folders
		# my $encoding = $response->content_encoding;

		my $counter = $self->_inc_counter();
		my $file;
		
		# Get the extension of the file based on the mime-type
		my $mime = $MIME_TYPES->type($response->content_type || 'text/plain');
		my ($extension) = defined $mime ? $mime->extensions : ('txt');



		# Write the contents of the page
		$file = File::Spec->catfile(
			$foldername,
			sprintf "%03d.%s", $counter, $extension
		);
		write_file($file, $mech->content);

	
		# Remember that the response has the document body which we don't want at
		# this point. So let's clone the response and get rid of the request's body.
		$response = $response->clone();
		$response->content(undef);

		# Write the HTTP transaction (request "\n" response)
		$file = File::Spec->catfile(
			$foldername,
			sprintf "%03d.http", $counter
		);
		
		write_file($file, $request->as_string, "\n", $response->as_string);
	}
}


#
# NOTE: We are injecting methods into WWW::Mechanize it's evil but it's the only
#       way for a plugin to work.
#
package WWW::Mechanize;

use Scalar::Util qw{ blessed };
use Carp;

=head1 WWW::Mechanize::request

The method L<WWW::Mechanize/request> is overriden by a custom version that will
invoke the original L<WWW::Mechanize/request> and then record the request.

=cut

{

	no warnings qw{ redefine };

	sub request {
		my $self = shift;
		my ($request, @args) = @_;

		# Perform the actual HTTP request
		my $response = $REQUEST_SUB->($self, $request, @args);

		
		# Write the request, response and contents
		if (exists $self->{autowrite}) {
		
			my $autowrite = $self->{autowrite};
			if (_is_an_autowrite($autowrite)) {
				$autowrite->write_to_file($self, $request, $response);
			}
			else {
				croak "Wrong type for member 'autowrite', got ", ref($autowrite) || 'a scalar';
			}
		}
	
		return $response;
	}

}


=head1 WWW::Mechanize::autowrite

This accessor returns the autowrite instance associated with this mechanize
instance. The first time that this method is invoked it will create

=cut

sub autowrite {
	my $self = shift;

	# The first time that this accessor is invoked
	
	# set
	if (@_) {
		my $autowrite = shift;

		if (! _is_an_autowrite($autowrite)) {
			croak "Parameter must be an instance of WWW::Mechanize::Plugin::AutoWrite";
		}

		$self->{'autowrite'} = $autowrite;
	}
	# get
	else {
		if (! exists $self->{'autowrite'}) {
			# Create an autowrite instance on the fly
			$self->{'autowrite'} = WWW::Mechanize::Plugin::AutoWrite->new();
		}
	}
	
	return $self->{'autowrite'};
}


#
# Returns true if the parameter is an instance of 
# WWW::Mechanize::Plugin::AutoWrite.
#
sub _is_an_autowrite {
	my ($autowrite) = @_;
	return
		blessed($autowrite) 
		&& $autowrite->isa('WWW::Mechanize::Plugin::AutoWrite')
	;
}


1;

=head1 COMPATIBILITY

The version 0.04 has a different API and is not backward compatible. This
affects only the configuration of the plugin. The behaviour should be the same.

=head1 SEE ALSO

L<http://search.cpan.org/perldoc?WWW::Mechanize::Plugin::Display>

=head1 AUTHOR

Jozef Kutej, E<lt>jkutej@cpan.orgE<gt>,

Emmanuel Rodriguez, E<lt>potyl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jozef Kutej
Copyright (C) 2008 by Jozef Kutej, Emmanuel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
