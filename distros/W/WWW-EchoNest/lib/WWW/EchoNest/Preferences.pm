# This class reads values from Environment variables and configuration files
# and communicates this information to the rest of the EchoNest classes.
#
package WWW::EchoNest::Preferences;

use 5.010;
use strict;
use warnings;
use Carp;
use File::Path qw( make_path );
use File::Spec::Functions;

BEGIN {
    our @EXPORT       = ();
    our @EXPORT_OK    = qw(
                              echonest_dir
                              log_filename
                              preferences_file
                              user_api_key
                              set_user_api_key
                         );
}
use parent qw[ Exporter ];

my $ECHONEST_DIRNAME    = '.echonest';
my $PREF_FILE           = 'preferences.txt';
my $LOG_FILENAME        = 'log.yml';
my $home_dir            = $ENV{HOME};

# Untaint home_dir
if ( $home_dir =~ /^ ( [[:alpha:][:digit:][:punct:]]+ ) $/x ) {
    $home_dir = $1;
}
my $echonest_dir = catfile( $home_dir, $ECHONEST_DIRNAME );
    
# Attempt to create our .echonest directory
eval {
    make_path( $echonest_dir );
};
croak "Could not make $echonest_dir: $@" if $@;

# Set the full path to the logfile
my $log_file_path = catfile( $echonest_dir, $LOG_FILENAME );

# Process preferences.txt -- all fields in this file take precedence
my $preferences_file = catfile( $echonest_dir, $PREF_FILE );
if ( -e -f $preferences_file ) {
    open( my $PREF, '<', $preferences_file )
        or croak "Could not open $preferences_file: $!";
    while (<$PREF>) {
        if ( /^log=( [[:alpha:][:digit:][:punct:]]+ )$/x ) {
            $log_file_path = $1;
        }
    }
}

sub echonest_dir           { $echonest_dir         }
sub log_filename           { $log_file_path        }
sub preferences_file       { $preferences_file     }



# Look for an 'ECHO_NEST_API_KEY' environment variable and untaint it
my $user_api_key = $ENV{ECHO_NEST_API_KEY};
if ( defined($user_api_key)
     and $user_api_key =~ /^ ( [[:alpha:][:digit:]]+ ) $/x ) {
    $user_api_key = $1;
} else {
    my $reason = <<'REASON';
Could not read ECHO_NEST_API_KEY env var.
Your api key may need to be hardcoded into WWW/EchoNest/Preferences.pm.
REASON
    carp $reason;
}
sub user_api_key       { $user_api_key }
sub set_user_api_key   { $user_api_key = $_[0] }


1;

__END__



=head1 NAME

WWW::EchoNest::Preferences

=head1 SYNOPSIS
    
  A class to encapsulate user preferences for WWW::EchoNest modules.

=head1 METHODS

  All methods call the correspondingly-named method of Log::Log4perl.

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
