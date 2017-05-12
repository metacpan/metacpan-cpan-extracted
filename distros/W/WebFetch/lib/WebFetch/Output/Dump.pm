#
# WebFetch::Output::Dump - save data in Perl structure dump
#
# Copyright (c) 1998-2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Output::Dump;

use strict;
use base "WebFetch";

use Carp;
use Scalar::Util qw( blessed );
use Date::Calc qw(Today Delta_Days Month_to_Text);
use LWP::UserAgent;
use Data::Dumper;

# define exceptions/errors
use Exception::Class (
);

=head1 NAME

WebFetch::Output::Dump - save data in a Perl structure dump

=cut

# set defaults
our ( @url, $cat_priorities, $now, $nowstamp );

our @Options = ();
our $Usage = "";

# configuration parameters
our $num_links = 5;

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "output:dump" );

=head1 SYNOPSIS

In perl scripts:

C<use WebFetch::Output::Dump;>

From the command line:

C<perl -w -MWebFetch::Output::Dump -e "&fetch_main" -- --dir directory
     --format dump --save save-path [...WebFetch output options...]>

=head1 DESCRIPTION

This is an output module for WebFetch which simply outputs a Perl
structure dump from C<Data::Dumper>.  It can be read again by a Perl
script using C<eval>.

=item $obj->fmt_handler_dump( $filename )

This function dumps the data into a string for saving by the WebFetch::save()
function.

=cut

# Perl structure dump format handler
sub fmt_handler_dump
{
	my ( $self, $filename ) = @_;

	$self->raw_savable( $filename, Dumper( $self->{data}));
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
<a href="WebFetch.html">WebFetch</a>

=for text
WebFetch

=for man
WebFetch

=cut
