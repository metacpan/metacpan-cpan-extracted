############################################################
#
#   $Id: SelfDestruct.pm,v 1.20 2006/01/12 22:45:11 nicolaw Exp $
#   Util::SelfDestruct - Conditionally prevent execution of a script
#
#   Copyright 2005,2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Util::SelfDestruct;
# vim:ts=4:sw=4:tw=78

BEGIN {
	use strict;
	use Carp qw(cluck croak);
	use Cwd qw(abs_path);
	use Fcntl qw(:DEFAULT :flock);

	use constant DEBUG => $ENV{'DEBUG'} ? 1 : 0;
	use constant PROGRAM_NAME => -e abs_path($0) ? abs_path($0) : undef;
	use constant HOME => -d (getpwuid($>))[7] ? (getpwuid($>))[7] : $ENV{HOME};
	use constant RC_FILE => HOME.'/.selfdestruct';

	use vars qw($VERSION $PARAM);
	$VERSION = '1.21' || sprintf('%d.%02d', q$Revision$ =~ /(\d+)/g);
	$PARAM = {};
}

END {
	if (my ($action,$context) = _whatActionToTake($PARAM)) {
		if ($action eq 'unlink' && !exists $PARAM->{ABORT}) {
			if (unlink(PROGRAM_NAME)) {
				cluck(__PACKAGE__.": $context");
			} else {
				croak(sprintf('Failed to unlink %s during self destruct: %s',
						PROGRAM_FILE,$!));
			}
		}
	}
}

sub import {
	my $class = shift;

	my %alias = (
			'delete'      => 'unlink',
			'erase'       => 'unlink',
		);
	my %struct = (
			'unlink' => 'bool',
			'after'  => 'value',
			'before' => 'value',
		);

	while (my $k = lc(shift(@_))) {
		$k = $alias{$k} if exists $alias{$k};
		if ($struct{$k} eq 'bool') {
			$PARAM->{$k}++;
		} else {
			$PARAM->{$k} = lc(shift(@_));
			if ($k eq 'before') {
				$PARAM->{$k} = _mungeDateTime($PARAM->{$k},'000000');
			} elsif ($k eq 'after') {
				$PARAM->{$k} = _mungeDateTime($PARAM->{$k},'235959');
			}
			delete $PARAM->{$k} unless defined $PARAM->{$k};
		}
	}

	if ((exists $PARAM->{'before'} || exists $PARAM->{'after'}) &&
		exists $PARAM->{'now'}) {
		$PARAM->{ABORT}++;
		croak "The 'now' flag cannot be used in conjunction with the ",
			"'before' or 'after' options";
	}

	DUMP('$PARAM',$PARAM);

	if (my ($action,$context) = _whatActionToTake($PARAM)) {
		if ($action eq 'die') {
			croak(__PACKAGE__.": $context");
		}
	}
	_writeExecHistory() unless exists $PARAM->{'unlink'};
}

sub _writeExecHistory {
	return _processExecHistory('write');
}

sub _readExecHistory {
	return _processExecHistory('read');
}

sub _processExecHistory {
	my $action = shift || 'read';

	my $matchInFile = 0;
	my $programName = PROGRAM_NAME;
	my $mode = (-e RC_FILE ? '+<' : '+>');

	if (open(FH,$mode,RC_FILE) && flock(FH,LOCK_EX)) {
		#seek(FH, 0, 0);
		while (my $str = <FH>) {
			chomp $str;;
			if ($str eq $programName) {
				$matchInFile++;
				last;
			}
		}
		if ($action eq 'write' && !$matchInFile) {
			print FH "$programName\n";
		}
		(flock(FH,LOCK_UN) && close(FH)) ||
			cluck(sprintf("Unable to close file handle FH for file %s: %s", RC_FILE,$!));

	} else {
		croak(sprintf("Unable to open file handle FH with exclusive lock for file '%s': %s",
				RC_FILE,$!));
	}

	return $matchInFile;
}

sub _whatActionToTake {
	my $param = shift;
	return undef if $param->{ABORT};

	my $context = '';
	my $action = exists $param->{'unlink'} ? 'unlink' : 'die';
	my $now = _unixtime2isodate(time());

	# No specific timing
	if (!exists $param->{'after'} && !exists $param->{'before'}) {
		if (exists $param->{'unlink'}) {
			$context = 'unlink after execution';
		} elsif (_readExecHistory() > 0) {
			$context = 'die on subsequent execution (only allow execution once)';
		} else {
			$action = '';
		}

	} elsif ((exists $param->{'after'} && exists $param->{'before'})
		&& $now > $param->{'after'} && $now < $param->{'before'}) {
		$context = "$now > $param->{after} and $now < $param->{before}";

	} elsif ((exists $param->{'after'} && !exists $param->{'before'})
		&& $now > $param->{'after'}) {
		$context = "$now > $param->{after}";

	} elsif ((exists $param->{'before'} && !exists $param->{'after'})
		&& $now < $param->{'before'}) {
		$context = "$now < $param->{before}";

	} else {
		$action = '';
	}

	return ($action,$context);
}

sub _mungeDateTime {
	my $str = shift || '';
	my $padding = shift || '000000';

	(my $isodate = $str) =~ s/\D//g;
	if ((length($str) - length($isodate) < 10) &&
		(my ($year,$mon,$mday,$hour,$min,$sec) =
		$isodate =~ /^\s*(19\d{2}|2\d{3})(0[1-9]|1[12])(0[1-9]|[12][0-9]|3[01])
					(?:([01][0-9]|2[0-3])([0-5][0-9])([0-5][0-9]))?\s*$/x)) {
		if (defined $hour) {
			return $isodate;
		} elsif ($padding =~ /^([01][0-9]|2[0-3])([0-5][0-9])([0-5][0-9])$/) {
			return "$isodate$padding";
		}
	}

	return undef;
}

sub _unixtime2isodate {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
		 = localtime(shift() || time());
	$year += 1900; $mon++;
	my $isodate = sprintf('%04d%02d%02d%02d%02d%02d',
					$year,$mon,$mday,$hour,$min,$sec);
	return $isodate;
}

sub TRACE {
	return unless DEBUG;
	warn(shift());
}

sub DUMP {
	return unless DEBUG;
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}

1;

=pod

=head1 NAME

Util::SelfDestruct - Conditionally prevent execution of a script

=head1 SYNOPSIS

 # Immediately prevent execution of script by dying on invocation
 # if it has already been executed once before. (The default behavior
 # is to self destruct by dying, unless instructed otherwise).
 use Util::SelfDestruct;
  
 # Delete the script after it is executed
 use Util::SelfDestruct('unlink');
  
 # Prevent execution of the script by dying if it
 # is executed after Dec 17th 2005 at 6pm
 use Util::SelfDestruct(after => '2005-12-17 18h00m00s');
  
 # Delete the script after execution, if it is executed
 # between 1st Dec 2005 and 17th Dec 2005 at 4:05pm
 use Util::SelfDestruct('unlink', 
                        after => '2005-12-01',
                        before => '2005-12-17 16:05:00',
                   );

=head1 DESCRIPTION

This module will prevent execution of your script by either dying or
deleting (unlinking) the script from disk after it is executed. This
can be useful if you have written a script for somebody that must
never be executed more than once. A database upgrade script for example.

The 'self destruct' mechanism can be achieved through deleting the
script so that it cannot be executed again, or by dying (terminating
the scripts execution).

=head2 Die Method (default)

This is the default, and safest behaviour. This allows the script to be
executed once. If it is executed again, it will immediately die during the
initial compilation phase, preventing the script from fully executing.

To do this, the Util::SelfDestruct needs to know if the calling
script has ever been executed before. It does this by writing a memo
to a file called C<.selfdestruct> in the user's home directory whenever
the script is executed. It can therefore find out if the script has
been run before during subsequent invocations.

=head2 Unlink Method

This method should be used with caution. To specify the unlink method,
add the C<unlink> boolean flag as an import paramter (see examples in
the synopsis above). Aliases for the C<unlink> flag are C<erase> and
C<delete>.

This method will allow the script to execute, but then delete the file
during the cleanup phase after execution. (Specifically during the
execution of the END{} in the Util::SelfDestruct module).

=head2 Before & After Qualifiers

The default behavior of Util::SelfDestruct is to only allow a script to
execute once, through either deletion of the script itself, or by dying
on all subsqeuent invocations after it's first execution.

Instead of this default behaviour, the C<before> and C<after> options allow
conditional timing of when the script will self destruct. Specifying
C<before> will cause the script to self destruct if executed before the
specified date and time. Likewise, the C<after> option will cause the
script to self destruct if executed after the specified date. They can also
be used in conjunction with eachother to specify a finite time frame.

Examples of valid date time formats are as follows:

 YYYYMMDDHHMMSS
 YYYYMMDD
 
 YYYY-MM-DD HH:MM:SS
 YYYY-MM-DD

Any non-numeric characters will be removed from the date time string before
it is parsed. This allows more pleasing formatting to be used.

If only a date is specified and not a time, 00:00:00 is assumed in the case
of the C<before> option, and 23:59:59 is assumes in the case of the C<after>
option.

=head1 VERSION

$Id: SelfDestruct.pm,v 1.20 2006/01/12 22:45:11 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2005,2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

__END__



