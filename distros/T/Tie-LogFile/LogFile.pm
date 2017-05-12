package Tie::LogFile;
#
# $Id: LogFile.pm,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#
use 5.006;
use strict;
use warnings;
use Carp;
use Symbol ();

our $VERSION = 0.1;

our %defaults  = (
	'format'        => '[%d] %m',
	'tformat'       => '',
	'mode'          => '>>',
	'force_newline' => 1,
	'autoflush'     => 0,
);

our %formats = (
	'd' => sub { $_[0]->fmtime },
	'm' => sub { $_[1]         },
	'p' => sub { $$            },
	'c' => sub { $_[0]->count  },
	'%' => sub { '%'           },
);


sub TIEHANDLE {
	my $class    = shift;
	my $filename = shift || return;
	
	if (@_ % 2 != 0) {
		carp "$class must be passed an even number of arguments.";
		return;
	}
	
	my %options = @_;
	
	if ($options{'format'} && $options{'format'} !~ m/%m/) {
		carp "Syntax error in 'format' option, must contain a message tag (%m)\n";
		return;
	}
	
	if ($options{'mode'} && $options{'mode'} !~ m/^>>?$/) {      
		# We don't support no stinking reading, at least for now
		carp __PACKAGE__ . " only supports writing file modes.\n";
		return;
	}
														  
	my $self = Symbol::gensym();   #The lazy way... :)
	
	bless($self, $class);
	
	$$self = {
		%defaults,
		%options,
		count => 0,
	};
	
	open($self, $$self->{'mode'} , $filename) || return;
	
	if ($$self->{'autoflush'}) {
		$self->autoflush($$self->{'autoflush'});
	}
	
	return $self;
}

sub PRINT {
	my $self = shift;
	$self->_print(@_);
}

sub PRINTF {
	my $self = shift;
	my $fmt  = shift;
	my $line = sprintf($fmt, @_);
	$self->_print($line);
}

sub CLOSE {
	my $self = shift;
	close($self);
}

sub UNTIE {
	my $self = shift;
	close($self);
}

sub _print {
	my $self = shift;
	my $msg  = "@_";
	my $line = $$self->{'format'};

	$$self->{'count'}++;
    # This isn't the fastest way to do things, but it's flexible and easy.
    # If people start ccontacting me and asking for more speed, I have a few 
    # ideas, but I don't see that happening.
    $line =~ s/%(_?[%a-zA-Z])/$formats{$1} ? $formats{$1}->($self, $msg) : ''/eg;
 	
 	if ($$self->{'force_newline'}) {
 		$line .= "\n" if $line !~ m/\n$/;
 	}

	print $self $line;
}

sub autoflush {
	my ($self, $af) = @_;
	
	if (defined $af) {
		# set self to autoflush.
		select((select($self), $| = $af)[0]);
		$$self->{'autoflush'} = $af;
	}
	
	return $$self->{'autoflush'};
}
	

sub fmtime {
	my $self = shift;
	
	if ($$self->{'tformat'}) {
		return Tie::LogFile::misc::time2str($$self->{'tformat'});
	} 
	
	return scalar localtime;
}

sub count {
	my $self = shift;
	return $$self->{'count'}; 
}

sub format {
	my $self = shift;
	if (@_) {
		my $new_fmt = shift;
		$$self->{'format'} = $new_fmt;
	}
	return $$self->{'format'};
}

package Tie::LogFile::misc;

use strict;
use warnings;
use Carp;

our $loaded = 0;

sub time2str {
	my $fmt = shift;
	if (!$loaded) {
		load_date_mod() || croak "Couldn't load a date module (Tried Data::Format and POSIX)\n";
	}
	
	return _time_formater($fmt, time);
}

sub load_date_mod {
	
	if (eval "require Date::Format") {
		$loaded = 1;
		*_time_formater = \&Date::Format::time2str;
		return 1;
	} 
	
	if (eval "require POSIX") {
		$loaded = 1;
		*_time_formater = sub { POSIX::strftime($_[0], localtime($_[1])); };
		return 1;
	}
	
	return;
}
	


1;
__END__

=head1 NAME

Tie::LogFile - Simple Log Autoformating

=head1 SYNOPSIS

  use Tie::LogFile;
  my $logfile = '/var/log/foo';
  
  tie(*LOG, 'Tie::LogFile', $logfile,
  	format  => '%c (%p) [%d] %m',
  	tformat => '%X %x')           or die $!;
  	
  print LOG "Starting Run";
  # Do stuff...
  print LOG "Did @stuff";
  # Clean up
  print LOG "Exiting";
  
  close(LOG) or die "Couldn't close $logfile\n";
  
=head1 DESCRIPTION

This module provides a quick and simple way to print out a log file with a 
repetative format.  In many of my projects I had something like this:

 sub logit {
 	print $LOG scalar localtime, @_;
 }
 
This is less than flexible, and still lends itself to loglines that do not follow
the logs format.  The Tie::LogFile module is format based, when you first tie (really 
create) the filehandle, you have the option of giving the format you wish the log 
lines to follow.  The format is in the same format as printf.  See the formats 
section for more information.

=head1 Tieing The Handle

The basic form of the C<tie> call is as follows:

 tie *HANDLE, 'Tie::LogFile', '/path/to/log';

If this is foreign to you, you might want to take a look at the perltie manpage.  After
the required arguements, there are several options that can be passed:

=over 

=item * format


The format option allows one to set the general format for the log file.  The syntax of 
this option is in the same vain as C<sprintf>, but with it's own set of tags.  The most
basic of these tags is %d for the time/date stamp, and %m for the log message.  The tags 
are case sensitive.  The default format is "[%d] %m".  At the minimum, the %m tag much be 
specified.

=item * tformat

Sets the time format printed for the C<%d> top level tag.  This format is passed directly
to C<Date::Format::time2str()> if you have Data::Format installed, otherwise it is passed 
to C<POSIX::strftime()>.  If no format is set, then neither module is used, and the C<%d> 
tag is filled with the output of C<scalar localtime>.  

=item * mode

By default Tie::LogFile opens the logfile using the C<E<gt>E<gt>> file mode, you can change 
with the mode option.  However, at least for now, Tie::LogFile only supports C<E<gt>> and 
C<E<gt>E<gt>>.

=item * force_newline

By default Tie::LogFile makes sure that there is a newline at the end of every print, this 
this behavior can be changed with the C<force_newline> option.

=item * autoflush

By default Tie::LogFile does not autoflush the filehandle.  Autoflush can be turned on
with this option.

=back

=head1 Log Formatting

In it's intial release, Tie::LogFile supports 5 formatting tags.  Anyone with a good idea
for a tag is encouraged to try it out, and tell the author.  Any good tags will make it 
into furture revisions.

The included tags are:

=over

=item * %m

The log message, this is what ever you pass to print or printf.  This tag is the only 
manditory tag.

=item * %d

The date/time stamp.  You can alter the format of this, by using the C<tformat> option.

=item * %p

The process ID (C<$$>).

=item * %c

Tie::LogFile maintains a count of the number of lines it prints, use %c to include that count
in your log files.

=item * %%

A literal '%'.

=back

=head2 Including your own tags.

There is an easy interface for defining your own tags for the format option.  The
C<%Tie::LogFile::formats> hash contains a coderef for each tag.  For example the default 
definition for the C<%p> tag is something like:

 $Tie::LogFile::formats{'p'} = sub { $$ };
 
You can override include tags, as in this very confusing tag:

 $Tie::LogFile::formats{'d'} = sub { scalar localtime(rand(1000000000)) };

Or define new tags, such as:

 $Tie::LogFile::formats{'u'} = sub { POSIX::uname() };
 
The subs in the formats hash are passed two things, $_[0] is the tied typeglob, while
$_[1] is the logline being printed.  For example:

 $Tie::LogFile::formats{'l'} = sub { length $_[1] };

=head1 BUGS

No know bugs, but bugs are always a possibility.

=head1 TODO

=over 

=item * Reading from the handle.

=item * More Speed.

=back

=head1 AUTHOR

Chris Reinhardt, E<lt>ctriv@dyndns.orgE<gt>

=head1 SEE ALSO

L<Date::Format>, L<POSIX>, L<perltie>, L<perl>.

=cut
