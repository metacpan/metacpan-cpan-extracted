
package WWW::EchoNest::Config;

use 5.010;
use strict;
use warnings;
use Carp;
use File::Path qw[ make_path ];
use File::Spec::Functions;

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use WWW::EchoNest::Preferences   qw( user_api_key );
use WWW::EchoNest::Functional    qw(
                                       update
                                       make_getters_and_setters
                                  );


my %fields =
    (
     api_key                   => WWW::EchoNest::Preferences::user_api_key,
     api_host                  => 'developer.echonest.com',
     api_selector              => 'api',
     api_version               => 'v4',
     user_agent                => "WWW::EchoNest/$WWW::EchoNest::VERSION",
     trace_api_calls           => 1,
     mp3_bitrate               => 128,
     timeout                   => 30,
     show_progress             => 0,
     codegen_binary_override   => '/home/brian/bin/codegen.Linux-i686',
    );

# See WWW::EchoNest::Functional for the def of this sub.
make_getters_and_setters(keys %fields);

sub new {
    my $class           = $_[0];
    my $args_ref        = $_[1];

    my $self = {};
    $self->{$_} = $fields{$_} for (keys %fields);
    $self->{$_} = $args_ref->{$_} for (keys %$args_ref);

    return bless ( $self, $class );
}

sub _fields   {   return keys %fields;       }
sub _reset    {   update( $_[0], \%fields );   }



1;

__END__

=head1 NAME

WWW::EchoNest::Config



=head1 METHODS

=head2 new

Returns a new WWW::EchoNest::Catalog instance

=head2 get_api_key

  Returns the value of the API_KEY field.

=head2 get_trace_api_calls

  Returns the value of the TRACE_API_CALLS field.

=head2 get_api_host

  Returns the value of the API_HOST field.

=head2 get_api_selector

  Returns the value of the API_SELECTOR field.

=head2 get_api_version

  Returns the value of the API_VERSION field.

=head2 get_user_agent

  Returns the value of the HTTP_USER_AGENT field.

=head2 get_timeout

  Returns the value of the CALL_TIMEOUT field.

=head2 get_show_progress

  Returns the value of the SHOW_PROGRESS field.

=head2 get_mp3_bitrate

  Returns the value of the MP3_BITRATE field.

=head2 get_codegen_binary_override

  Returns the value of the CODEGEN_BINARY_OVERRIDE field.

=head2 get_test_files

  Returns a list of file paths to be used during testing.

=head2 set_api_key

  Sets the value of the ECHO_NEST_API_KEY field.

=head2 set_trace_api_calls

  Sets the value of the TRACE_API_CALLS field.

=head2 set_api_host

  Sets the value of the API_HOST field.

=head2 set_api_selector

  Sets the value of the API_SELECTOR field.

=head2 set_api_version

  Sets the value of the API_VERSION field.

=head2 set_user_agent

  Sets the value of the HTTP_USER_AGENT field.

=head2 set_timeout

  Sets the value of the CALL_TIMEOUT field.

=head2 set_show_progress

  Sets the value of the SHOW_PROGRESS field.

=head2 set_mp3_bitrate

  Sets the value of the MP3_BITRATE field.

=head2 set_codegen_binary_override

  Sets the value of the CODEGEN_BINARY_OVERRIDE field.

=head2 set_test_files

  Sets the list of file paths to use during testing.



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 BUGS

Please report bugs to: L<http://bugs.launchpad.net/~libwww-echonest-perl>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
