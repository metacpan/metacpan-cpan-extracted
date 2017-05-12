# WebFetch::Input::PerlStruct.pm
# push a Perl structure with pre-parsed news into WebFetch
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Input::PerlStruct;

use strict;
use base "WebFetch";

# define exceptions/errors
use Exception::Class (
	"WebFetch::Input::PerlStruct::Exception::NoStruct" => {
		isa => "WebFetch::Exception",
		alias => "throw_nostruct",
		description => "no 'content' structure was provided",
	},

	"WebFetch::Input::PerlStruct::Exception::BadStruct" => {
		isa => "WebFetch::Exception",
		alias => "throw_badstruct",
		description => "content of 'content' was not recognizable",
	},

);

our @Options = ( );
our $Usage = "";

# configuration parameters

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "input:perlstruct" );

sub fetch
{
	my ( $self ) = @_;

	# get the content from the provided perl structure
	if ( !defined $self->{content}) {
		throw_nostruct "content struct does not exist";
	}
	if ( ref($self->{content})->isa( "WebFetch::Data::Store" )) {
		$self->{data} = $self->{content};
		return;
	} elsif ( ref($self->{content}) eq "HASH" ) {
		if (( exists $self->{content}{fields})
			and ( exists $self->{content}{records})
			and ( exists $self->{content}{wk_names}))
		{
			$self->data->{fields} = $self->{content}{fields};
			$self->data->{wk_names} = $self->{content}{wk_names};
			$self->data->{records} = $self->{content}{records};
			return;
		}
	}
	throw_badstruct "content should be a WebFetch::Data::Store";
}

1;
__END__
# POD docs follow

=head1 NAME

WebFetch::Input::PerlStruct - accepts a Perl structure with pre-parsed news

=head1 SYNOPSIS

In perl scripts:

C<use WebFetch::Input::PerlStruct;>

C<$obj = new WebFetch::Input::PerlStruct (
	"content" => content_struct,
	"dir" => output_dir,
	"dest" => output_file,
	"dest_format" => output_format,	# used to select WebFetch output module
	[ "group" => file_group_id, ]
	[ "mode" => file_mode_perms, ]
	[ "quiet" => 1 ]);>

I<Note: WebFetch::Input::PerlStruct is a Perl interface only.
It does not support usage from the command-line.>

=head1 DESCRIPTION

This module accepts a perl structure with pre-parsed news
and pushes it into the WebFetch infrastructure.

The webmaster of a remote site only needs to arrange for a cron job to
update a WebFetch Export file, and let others know the URL to reach
that file.
(On the exporting site, it is most likely they'll use
WebFetch::SiteNews to export their own news.)
Then you can use the WebFetch::Input::PerlStruct module to read the
remote file and generate and HTML summary of the news.

After WebFetch::Input::PerlStruct runs,
the file specified in the --file parameter will be created or replaced.
If there already was a file by that name, it will be moved to
a filename with "O" (for old) prepended to the file name.

Most of the parameters listed are inherited from WebFetch.
See the WebFetch module documentation for details.

=head1 THE CONTENT STRUCTURE

The $content_struct parameter may be in either of two formats.

If $content_struct is a hash reference containing entries called
"fields", "wk_names" and "records", then it is assumed to be already
in the format of the "data" element of the WebFetch Embedding API.

Otherwise, it must be a reference to an array of hashes.
Each of the hashes represents a separate news item,
in the order they should be displayed.

The field names should be consistent through all records.
WebFetch uses the field names from the first record and assumes the
remainder are identical.

The names of the fields are chosen by the calling function.
If an array called "wk_names" is provided then it used to map
well-known field names of the WebFetch Embedding API to field names in
this data.
Otherwise, meaning can only be applied to field names if they already
match WebFetch's well-known field names.

=head1 AUTHOR

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

=head1 SEE ALSO

=for html
<a href="WebFetch.html">WebFetch</a>

=for text
WebFetch

=for man
WebFetch

=cut
