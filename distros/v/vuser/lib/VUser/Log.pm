package VUser::Log;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Log.pm,v 1.8 2006-01-04 21:57:48 perlstalker Exp $

use VUser::ExtLib qw(strip_ws);
our $VERSION = "0.3.0";

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARN
		    LOG_NOTICE LOG_INFO LOG_DEBUG LOG_ERROR
		    );
our %EXPORT_TAGS = (
		    levels => [qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR
				  LOG_WARN LOG_NOTICE LOG_INFO LOG_DEBUG
				  LOG_ERROR)]
		    );

sub LOG_EMERG  { 8 }
sub LOG_ALERT  { 7 }
sub LOG_CRIT   { 6 }
sub LOG_ERR    { 5 }
sub LOG_ERROR  { 5 }
sub LOG_WARN   { 4 }
sub LOG_NOTICE { 3 }
sub LOG_INFO   { 2 }
sub LOG_DEBUG  { 1 }

my @levels = ('', 'DEBUG', 'INFO', 'NOTICE', 'WARN',
	      'ERROR', 'CRIT', 'ALERT', 'EMERG');

sub new
{
    my $class = shift;
    my $cfg = shift;
    my $ident = shift;
    my $config_sec = shift || 'vuser';

    my $self = {'ident' => 'vuser',
		'level' => LOG_NOTICE
		};

    my $log_type = strip_ws($cfg->{$config_sec}{'log type'});
    if (not defined $log_type
	or $log_type eq 'stderr'
	or $log_type eq '') {
	bless $self, $class;
    } else {
	# Try to load a previously unknown log module.
	eval "require VUser::Log::$log_type;";
	die "Unable to load logging module $log_type: $@\n" if $@;
	bless $self, "VUser::Log::$log_type";
    }

    my $level = lc(strip_ws($cfg->{$config_sec}{'log level'}));
    if    ($level eq 'emerg') { $self->level(LOG_EMERG); }
    elsif ($level eq 'alert') { $self->level(LOG_ALERT); }
    elsif ($level eq 'crit')  { $self->level(LOG_CRIT); }
    elsif ($level =~ /^err(or)?$/) { $self->level(LOG_ERR); }
    elsif ($level eq 'warn') { $self->level(LOG_WARN); }
    elsif ($level eq 'notice') { $self->level(LOG_NOTICE); }
    elsif ($level eq 'info') { $self->level(LOG_INFO); }
    elsif ($level eq 'debug') { $self->level(LOG_DEBUG); }
    else { $self->level(LOG_NOTICE); }

    $self->ident($ident) if ($ident);

    $self->init($cfg);

    return $self;
}

sub init {}

# $log->log($message)
# $log->log(PRIORITY, $message)
# $log->log(PRIORITY, $pattern, @args)
sub log
{
    my $self = shift;

    my $priority = LOG_NOTICE;
    my $pattern = '%s';
    my @args = ();
    
    if (scalar @_ == 0) {
	warn "No log message";
	return;
    } elsif (scalar @_ == 1) {
    } elsif (scalar @_ == 2) {
	$priority = shift;
    } else {
	$priority = shift;
	$pattern = shift;
    }

    # Remove trailing newline from pattern. We'll add that later.
    $pattern =~ s/(\\n|\n)$//;

    @args = @_;

    if ($priority >= $self->level) {
	my $msg = sprintf($pattern, @args);
	chomp $msg;
	$self->write_msg($priority, $msg);
    }
}

sub write_msg
{
    my $self = shift;
    my ($level, $msg) = @_;

    print STDERR sprintf ('%s: %s: ', $self->ident, $levels[$level]);
    print STDERR ($msg, "\n");
}

sub add_member
{
    my $self = shift;
    my $member = shift;
    my $value = shift;

    $self->{$member} = $value;
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $self = shift;
    my $value = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;

    if (exists $self->{$name}) {
	$self->{$name} = $value if defined $value;
	return $self->{$name};
    } else {
	warn "Unknown method: $name\n";
	return undef;
    }
}

sub DESTROY {}
sub version { return $VERSION; }

1;

__END__

=head1 NAME

VUser::Log - Logging support for vuser

=head1 SYNOPSIS

 use VUser::Log qw(:levels);
 my $log = new VUser::Log($cfg, $ident);
 my $msg = "Hello World";
 $log->log($msg); # Log $msg at level LOG_NOTICE
 $log->log(LOG_DEBUG, $msg); # Log $msg at level LOG_DEBUG
 $log->log(LOG_DEBUG, 'Crap! %s', $msg); # Logs 'Crap! Hello World'

=head1 DESCRIPTION

Generic logging module for vuser.

=head2 Creating a New VUser::Log

 $log = VUser::Log->new($cfg, $ident);
 $log = VUser::Log->new($cfg, $ident, $section);

=over 4

=item $cfg

A reference to a tied Config::IniFiles hash.

=item $ident

The identifier for this log object. This will be used to tag each log line
as being from this object. This is similar to how syslog behaves.

=item $section

This tells VUser::Log which section of the configuration (represented by
I<$cfg>) to look for settings in. If not specified, I<vuser> will be used.

=back

=head2 Logging

When you decided that it's time to log some info you call the VUser::Log
object's log() method. log() can be called in one of three ways.

=over 4

=item 1

 $log->log($level, $pattern, @args);

$level is the log level to use. You can import the LOG_* constants into
your namespace with C<use VUser::Log qw(:levels);>.

$pattern is a formatting pattern as used by printf().

@args are the value for any placeholders in $pattern.

=item 2

 $log->log($level, $message);

You can omit the pattern and simply pass a text string to log.

=item 3

 $log->log($message);

You can even omit the log level and the message will be logged with a level
of LOG_NOTICE.

=back

=head2 Log Levels

The levels are, in increasing order of importance: I<DEBUG>, I<INFO>,
I<NOTICE>, I<WARN>, I<ERROR>, I<CRIT>, I<ALERT>, I<EMERG>. I<ERR> is
provided as a synonym for I<ERROR>.

You can import the LOG_* constants for use where ever log levels are
needed by using C<use VUser::Log qw(:levels)>.

=head2 Use in Extensions

Extensions do not need to create a new VUser::Log object. You can simply
use $main::log or do something like this:

 my $log;
 sub init
 {
     ...
     $log = $main::log;
     ...
 }

After that, you can use $log anywhere in your extension.

=head1 CONFIGURATION

 [vuser]
 # The log system to use.
 log type = Syslog
 log level = notice

B<Note:> Each log module will have it's own configuration.

=head1 LOGGING MODULES

VUser::Log uses subclasses to do the actual logging.

=head2 REQUIRED METHODS

Subclasses of VUser::Log must override, at least, these methods.

=over 4

=item init

Any module specific initialization should be done here. init() takes only
one argument, a reference to the config hash created by Config::IniFiles.

=item write_msg

This method will do the actual writting of the log messages. It takes two
parameters, the log level and the message.

=back

=head1 AUTHORS

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

