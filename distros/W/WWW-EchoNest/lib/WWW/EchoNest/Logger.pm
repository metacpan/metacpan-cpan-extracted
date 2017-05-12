
package WWW::EchoNest::Logger;

use 5.010;
use strict qw( vars refs );
use warnings;
use File::Path qw( make_path );
use File::Spec::Functions;
use Carp;

BEGIN {
    our @EXPORT        = qw( get_logger );
    our @EXPORT_OK     = qw( get_logger set_log_level );
}
use parent qw( Exporter );

use WWW::EchoNest::Preferences qw(
                                     log_filename
                                );

our $LOGGING = 0;

# Attempt to load Log::Log4perl...
# If you don't install this module from the CPAN, you will not be able to log.
eval {
    use Log::Log4perl qw[ :levels ];
    use Log::Log4perl::Appender::File;
};
if ($@) {
    carp <<'MISSING';
You do not have Log::Log4perl installed.
Logging to ~/.echonest/log.yml is disabled.
All messages will be logged to STDERR instead.
Go to http://cpan.org to install Log::Log4perl, then go to
http://www.perl.com/pub/2002/09/11/log4perl.html for a quick tutorial.
MISSING
} else {
    $LOGGING = 1;
}


BEGIN {
    my $conf_str = <<'CONF';
log4perl.logger.WWW::EchoNest      = LOG_LEVEL, appendr
log4perl.appender.appendr          = Log::Log4perl::Appender::File
log4perl.appender.appendr.filename = LOG_FILENAME
log4perl.appender.appendr.utf8     = 1
log4perl.appender.appendr.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.appendr.layout.ConversionPattern = ---%ntime: %d%nfile: %F%nsub: %M%nline: %L%n%m%n
CONF

    my %level_for =
        (
         DEBUG    => 0,
         INFO     => 1,
         WARN     => 2,
         ERROR    => 3,
         FATAL    => 4,
        );
    
    my $log_level = 'INFO';
    set_log_level($log_level);

    sub get_logger {
        my ($pkg) = caller;
        return Log::Log4perl->get_logger( $pkg );
    }

    sub set_log_level {
        $log_level = uc $_[0];
        
        if ( ! exists $level_for{$log_level} ) {
            croak "Unrecognized log level ($log_level)\nAcceptable types are: "
                  . join( q[ ], keys %level_for );
        }
        
        my $conf_str_alias    = $conf_str;
        my $log_filename      = WWW::EchoNest::Preferences::log_filename;
        $conf_str_alias       =~ s/LOG_LEVEL/$log_level/;
        $conf_str_alias       =~ s/LOG_FILENAME/$log_filename/;

        unlink $log_filename;

        Log::Log4perl::init( \$conf_str_alias );
    }
    
    sub log_level {
        return $log_level;
    }

    # Return a boolean value indicating whether messages should be logged at a
    # given level
    sub p_log {
        my $level = uc $_[0];
        
        if ( ! exists $level_for{$log_level} ) {
            croak "Unrecognized log level ($log_level)\nAcceptable types are: "
                  . join( q[ ], keys %level_for );
        }
        
        $level_for{$level} >= $level_for{$log_level};
    }
}

sub debug {
    my $logger = shift;
    if ($LOGGING) {
        $logger->debug(@_);
    } elsif ( p_log('DEBUG') ) {
        print STDERR @_;
    }
}

sub info {
    my $logger = shift;
    if ($LOGGING) {
        $logger->info(@_);
    } elsif ( p_log('INFO') ) {
        print STDERR @_;
    }
}

sub warn {
    my $logger = shift;
    if ($LOGGING) {
        $logger->warn(@_);
    } elsif ( p_log('WARN') ) {
        print STDERR @_;
    }
}

sub error {
    my $logger = shift;
    if ($LOGGING) {
        $logger->error(@_);
    } elsif ( p_log('ERROR') ) {
        print STDERR @_;
    }
}

sub fatal {
    my $logger = shift;
    if ($LOGGING) {
        $logger->fatal(@_);
    } elsif ( p_log('FATAL') ) {
        print { STDERR } @_;
    }
}



1;

__END__

=head1 NAME

WWW::EchoNest::Logger
For internal use only!

=head1 SYNOPSIS
    
  A wrapper around Log::Log4perl for WWW::EchoNest modules.

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

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
