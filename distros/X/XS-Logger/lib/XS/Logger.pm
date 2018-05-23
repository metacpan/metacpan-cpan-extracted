package XS::Logger;
$XS::Logger::VERSION = '0.005';
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

version 0.005

=head1 SYNOPSIS

    use XS::Logger;

    # simple mode

    $XS::Logger::PATH_FILE = "/var/log/xslogger.log"; # default file path

    XS::Logger::info(  "something to log" );
    XS::Logger::warn(  "something to warn" );
    XS::Logger::error( "your error message: %d", 404 );

    XS::Logger::die(   "something to log & die" );
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

=for HTML <p><img src="https://travis-ci.org/atoomic/XS-Logger.svg?branch=released" width="81" height="18" alt="Travis CI" /></p>

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
                                  path   => q{/var/log/xslogger.log,
                                  quiet  => 1, # default value=0, disable messages on stderr in addition to the log itself
                                }
                               } );

     $log->get_level() == XS::Logger::INFO_LOG_LEVEL or ...;

     $log->set_level( XS::Logger::WARN_LOG_LEVEL() ); # only warnings, error and fatal events are logged

=head1 Notice

This is a very early development stage and some behavior might change before the release of a more stable build.

=head1 LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
