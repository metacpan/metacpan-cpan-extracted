#
# WebFetch::Output::TT - save data via the Perl Template Toolkit
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Output::TT;

use strict;
use base "WebFetch";

use Carp;
use Template;

# define exceptions/errors
use Exception::Class (
	"WebFetch::Output::TT::Exception::Template" => {
		isa => "WebFetch::TracedException",
		alias => "throw_template",
		description => "error during template processing",
	},

);

=head1 NAME

WebFetch::Output::TT - save data via the Perl Template Toolkit

=cut

# set defaults

our @Options = ( "template=s", "tt_include:s" );
our $Usage = "--template template-file [--tt_include include-path]";

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "cmdline", "output:tt" );

=head1 SYNOPSIS

In perl scripts:

C<use WebFetch::Output::TT;>

From the command line:

C<perl -w -MWebFetch::Output::TT -e "&fetch_main" --
     [...WebFetch input options...] --dir directory
     --dest_format tt --dest dest-path --template tt-file >

=head1 DESCRIPTION

This module saves output via the Perl Template Toolkit.

=item $obj->fmt_handler_tt( $filename )

This function formats the data according to the Perl Template Toolkit
template provided in the --template parameter.

=cut

# Perl Template Toolkit format handler
sub fmt_handler_tt
{
	my $self = shift;
	my $filename = shift;
	my $output;

        # configure and create template object
        my %tt_config = (
                ABSOLUTE => 1,
                RELATIVE => 1,
        );
        if ( exists $self->{tt_include}) {
                $tt_config{INCLUDE_PATH} = $self->{tt_include}
        }
        my $template = Template->new( \%tt_config );

        # process template
        $template->process( $self->{template}, { data => $self->{data}},
		\$output, { binmode => ':utf8'} )
		or throw_template $template->error();

	$self->raw_savable( $filename, $output );
	1;
}

1;
__END__
# POD docs follow

=head1 AUTHOR

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

=head1 SEE ALSO

=for html
<a href="WebFetch.html">WebFetch</a>,
<a href="http://www.template-toolkit.org/>Perl Template Toolkit</a>

=for text
WebFetch, Perl Template Toolkit

=for man
WebFetch, Perl Template Toolkit

=cut
