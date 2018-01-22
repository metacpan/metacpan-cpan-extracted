package XS::Logger;
$XS::Logger::VERSION = '0.001';
use strict;
use warnings;

# ABSTRACT: a basic logger implemented in XS

use XSLoader ();
use Exporter ();

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(DEBUG_LOG_LEVEL INFO_LOG_LEVEL WARN_LOG_LEVEL ERROR_LOG_LEVEL FATAL_LOG_LEVEL DISABLE_LOG_LEVEL);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

XSLoader::load(__PACKAGE__);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XS::Logger - a basic logger implemented in XS

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use XS::Logger;

    # simple mode

    $XS::Logger::PATH_FILE = "/var/log/xslogger.log"; # default file path

    XS::Logger::info( "something to log" );
    XS::Logger::warn( "something to warn" );
    XS::Logger::error( "something to warn" );

    XS::Logger::die( "something to log & die" );
    XS::Logger::panic( "something to log & panic" );
    XS::Logger::fatal( "something to log & fatal" );
    XS::Logger::debug( "something to debug" );

    # object oriented mode

    my $log = XS::Logger->new( { color => 1, path => q{/var/log/xslogger.log} } );

    $log->info(); # one empty line
    $log->info( "something to log" );
    $log->info( "a number %d", 42 );
    $log->info( "a string '%s'", "banana" );

    $log->warn( ... );
    $log->error( ... );
    $log->die( ... );
    $log->panic( ... );
    $log->fatal( ... );
    $log->debug( ... );

=head1 DESCRIPTION

XS::Logger provides a light and friendly logger for your application.

=head1 NAME

XS::Logger - basic logger using XS

=head1 Usage

=head1 Log Levels

By default all logs message are displayed but you can limit the number of informations logged
by setting a log level.

For example: setting a log level = INFO_LOG_LEVEL, will disable all the 'debug' informations preserving
all other loggged events.

Setting the level can be done at construction time or run time

    use XS::Logger qw{:all}; # import all log levels

    my $log = XS::Logger->new( {
                                  level  => DEBUG_LOG_LEVEL
                                       # or INFO_LOG_LEVEL
                                       # or WARN_LOG_LEVEL
                                       # or ERROR_LOG_LEVEL
                                       # or FATAL_LOG_LEVEL
                                       # or DISABLE_LOG_LEVEL
                                  color  => 1,
                                  path   => q{/var/log/xslogger.log
                                }
                               } );

     $log->get_level() == XS::Logger::INFO_LOG_LEVEL or ...;

     $log->set_level( XS::Logger::WARN_LOG_LEVEL() ); # only warnings, error and fatal events are logged

=head1 LICENSE
   ...

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
