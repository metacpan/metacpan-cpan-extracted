package OnSearch;

BEGIN { use Config; unshift @INC, ('.', './OnSearch'); }

use 5.006;
use strict;
use warnings;
use Errno;
use Carp qw(croak);

require Exporter;
require DynaLoader;

our @EXPORT = qw($VERSION @ISA $CWD browser_die browser_warn
		 user_warn catch_signal ignore_signal);
our @ISA = qw(Exporter DynaLoader);
our $VERSION = '0.001';
our ($CWD) = (`pwd` =~ m|(.*)\n|);

use OnSearch::AppConfig;
use OnSearch::WebLog;

my $cfg = OnSearch::AppConfig->new;
unless ($cfg -> have_config) {
    if (-f "$CWD/onsearch.cfg") {
	$cfg -> read_config ("$CWD/onsearch.cfg");
    } elsif (-f "$CWD/../onsearch.cfg") {
	$cfg -> read_config ("$CWD/../onsearch.cfg");
    }
}

sub my_die {
    my ($err) = @_;

    ###
    ###  Caused by Storable's eval, which will use Carp instead.
    ###
    return if $err =~ /Can't locate Log\/Agent\.pm/;

    my $i = 1;
    my ($package, $filename, $line, $subroutine, $hasargs,
     $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
###
###  If WebLog is not loadable or there's no $CONFIG, then
###  re-open or dup STDERR.
###
###  The first call to "require" causes a significant delay.
### 
    eval { require OnSearch::WebLog; } unless %OnSearch::WebLog::;
    if ($@ || (!$cfg->WebLogDir)) {
	if (fileno (STDERR)) {
	    open ERROR, ">&STDERR";
	} else {
	    open ERROR, ">&=2";
	}
	if (! fileno (ERROR) || (fileno (ERROR) != 2)) {
	    `perl -e 'print STDERR "$err"'`;
	    exit ($?);
	}
	($package, $filename, $line, $subroutine, $hasargs,
	 $wantarray, $evaltext, $is_require, $hints, $bitmask)
	    = caller(1);
	print ERROR "my_warn: $err from $filename line $line\n";
    } else {
	OnSearch::WebLog::clf ('error', "$err from $filename line $line");
    }
}

sub my_warn {
    my $err = $_[0];
    my $frame = 1;
    my ($package, $filename, $line, $subroutine, $hasargs,
	$wantarray, $evaltext, $is_require, $hints, $bitmask);
    my $tracemsg = '';
###
###  If WebLog is not loadable or there's no $CONFIG, then try to 
###  re-open or dup STDERR.
###
###  The first call to "require" causes a significant delay.
### 
    eval { require OnSearch::WebLog; } unless %OnSearch::WebLog::;
    if ($@|| (!$cfg->WebLogDir)) {
	if (fileno (STDERR)) {
	    open ERROR, ">&STDERR";
	} else {
	    open ERROR, ">&=2";
	}
	if (! fileno (ERROR) || (fileno (ERROR) != 2)) {
	    `perl -e 'print STDERR "$err"'`;
	    exit ($?);
	}
	($package, $filename, $line, $subroutine, $hasargs,
	 $wantarray, $evaltext, $is_require, $hints, $bitmask)
	    = caller(1);
	print ERROR "my_warn: $err from $filename line $line\n";
    } else {
	while (1) {
	    ($package, $filename, $line, $subroutine, $hasargs,
	     $wantarray, $evaltext, $is_require, $hints, $bitmask)
		= caller($frame++);
	    last unless (defined $filename && defined $line);
	    $tracemsg .= ",\n from $filename line $line";
	}
	OnSearch::WebLog::clf ('warning', "$err $tracemsg.");
    }
}

$SIG{__DIE__} = \&my_die;
$SIG{__WARN__} = \&my_warn;

sub browser_die {
    my $msg = $_[0];
    eval { require OnSearch::UI; };
    if (@!) { die "@!"; }
    my $ui = OnSearch::UI -> new;
    $ui -> process_error ($msg) -> wprint;
    die "$msg";
}

sub browser_warn {
    my $msg = $_[0];
    eval { require OnSearch::UI; };
    if (@!) { die "@!"; }
    my $ui = OnSearch::UI -> new;
    $ui -> process_error ($msg) -> wprint;
    warn "$msg";
}

sub user_warn {
    my $msg = $_[0];
    eval { require OnSearch::UI; };
    if (@!) { die "@!"; }
    my $ui = OnSearch::UI -> new;
    $ui -> brief_warning ($msg) -> wprint;
}

sub catch_signal {
    my $sig = shift;
    warn "OnSearch: SIG$sig PID $$.";
    $SIG{$sig} = \&catch_signal;
}

#
# The Web server won't ignore some signals, so catch them here.
#
sub ignore_signal {
    my $sig = shift;
    $SIG{$sig} = \&ignore_signal;
}

sub term {
    warn "OnSearch: SIGTERM PID $$.";
    kill ('KILL', $$);
  }

$SIG{CHLD} = \&catch_signal;
$SIG{TERM} = \&term;

1;

__END__

=head1 NAME

OnSearch - Perl libraries for OnSearch search engine.

=head1 DESCRIPTION

The OnSearch libraries provide the functions to search documents for
words and phrases, display matching documents, record results of
searches, and save user preferences.

=head1 EXPORTS

OnSearch.pm exports the following variables and subroutines.

=head2 $VERSION

The OnSearch library version number.

=head2 @ISA

Superclass information.

=head2 $CWD

OnSearch's current working directory.

=head2 browser_die (I<message>)

Terminates the application with a warning printed to the Web browser.

=head2 browser_warn (I<message>)

Prints a warning message in the browser and also records the message in 
the OnSearch Web log.

=head2 user_warn (I<message>)

Print a brief warning message in the Web browser about a user error.

=head2 catch_signal (I<signum>)

Record a signal from the operating system in the OnSearch Web log.

=head2 ignore_signal (I<signum>)

Ignore a signal from the operating system.

=head1 VERSION AND COPYRIGHT

$Id: OnSearch.pm,v 1.13 2005/08/13 05:20:35 kiesling Exp $

Written by Robert Kiesling <rkies@cpan.org> and licensed under the same 
terms a Perl.  Refer to the file, "Artistic," for information.

=head1 SEE ALSO

L<OnSearch::UI(3)>, L<OnSearch::AppConfig(3)>, L<OnSearch::StringSearch(3)>, 
L<OnSearch::Base64(3)>, L<OnSearch::VFile(3)>, L<OnSearch::Regex(3)>,
L<OnSearch::CGIQuery(3)>, L<OnSearch::Results(3)>, L<OnSearch::Search(3)>,
L<onindex(8)>
