
package Tie::STDERR;

use strict;

my $stderr = '';		### here we store the STDERR output

my $need_apache_cleanup = 0;
if (defined $ENV{'MOD_PERL'})
	{ $need_apache_cleanup = 1; }

sub TIEHANDLE
	{
	my $class = shift;
	bless {}, $class;
	}
sub PRINT
	{
	my $self = shift;
	$stderr .= join	'', @_;
	}

my $default_user = 'root';			### change this to 'root'
my $default_subject = 'STDERR output detected';	### change this to your Subject
my $default_mail = '| /usr/lib/sendmail -t';	### default command
my $run_function = undef;
my $append_scalar = undef;

my ($user, $subject, $command);

sub error_id {
	my @localtime = localtime;
	sprintf "%04d%02d%02d-%02d%02d%02d-%05d", $localtime[5] + 1900,
		$localtime[4] + 1, @localtime[3, 2, 1, 0], $$;
	}

sub process_result {
	### local *STDERR; untie *STDERR;
	local $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
	if ($stderr ne '')
		{
		if (defined $run_function)
			{ &$run_function($stderr); }
		elsif (defined $append_scalar)
			{ $$append_scalar .= $stderr; }
		elsif (defined $command)
			{
			open OUT, $command;
			print OUT $stderr;
			}
		else
			{
			open OUT, $default_mail;
			### print STDERR "Sending bug by email\n";
			my $now = error_id;
			print OUT "To: $user\nSubject: $subject\n\nOutput to STDERR detected in $0:\n", $stderr, "\n\nTime: $now\n\n";
			print OUT "\%ENV:\n";
			for (sort keys %ENV) { print OUT "$_ = $ENV{$_}\n"; }
			}
		close OUT;
		$stderr = '';
		}
	}

END {
	process_result();
	}
sub register_apache_cleanup {
	eval 'use Apache; my $r = Apache->request; $r->register_cleanup(\&process_result); ';
	}
sub import {
	### print STDERR "Tie::STDERR::import(@_) called\n";
	my $class = shift;

	if (@_ and not defined $_[0])	### explicit undef
		{
		$^W = 0;
		untie *STDERR if ref tied *STDERR eq 'Tie::STDERR';
		$run_function = undef; $append_scalar = undef;
		return;
		}

	### return if -t STDERR or -t STDOUT;

	unless (ref tied *STDERR eq 'Tie::STDERR')
		{
		tie *STDERR, __PACKAGE__;

		$SIG{__WARN__} = sub { print STDERR @_; };

		$SIG{__DIE__} = sub { print STDERR @_; };
		}

	($user, $subject, $command) = ($default_user, $default_subject, undef);

	return unless @_;

	if (ref $_[0] eq 'CODE')
		{ $run_function = $_[0]; }
	elsif (ref $_[0] eq 'SCALAR')
		{ $append_scalar = $_[0]; }
	else {
		my $arg = shift;
		if ($arg =~ /^\s*([|>].*)/s)
			{ $command = $1; }
		else
			{
			$arg =~ s/\n$//;
			$user = $arg;
			$arg = shift;
			if (defined $arg)
				{ $arg =~ s/\n$//; $subject = $arg; }
			}
		}
	if ($need_apache_cleanup) {
		register_apache_cleanup();
		}
	}

$Tie::STDERR::VERSION = '0.26';

1;

__END__

=head1 NAME

Tie::STDERR - Send output of your STDERR to a process or mail

=head1 SYNOPSIS

	use Tie::STDERR;
	if (;

	use Tie::STDERR 'root';
	
	use Tie::STDERR 'root', 'Errors in the script';
	
	use Tie::STDERR '>> /tmp/log';
	
	use Tie::STDERR '| mail -s Error root';

	use Tie::STDERR \&func;
	
	use Tie::STDERR \$append_to_scalar;

=head1 DESCRIPTION

Sends all output that would otherwise go to STDERR either by email to
root or whoever is responsible, or to a file or a process, or calls
your function at the end of the script. This way you can easily change
the destination of your error messages from B<inside> of your script.
The mail will be sent or the system command or Perl function run only
if there actually is some output detected -- something like cron would
do.

The behaviour of the module is directed via the arguments to use, as
shown above. If you do not give arguments, an e-mail to root is sent.
You can give up to two scalars -- name of the recipient and the
subject of the email. Argument that starts with | will send the output 
to a process. If it starts with > or >>, it will be written (appended)
to a file. If the argument is explicit undef, if will untie previous
tieness. Reference to a functions registers a callback Perl function
that will be passed the string of the data sent to STDERR during your
script and reference to scalar registers scalar, to which this data
will be appended.

The module will catch all output, including your explicit prints to
STDERR, warnings about undefined values, dies and even dies as
a result of compilation error. You do not need any special
treatment/functions -- Tie::STDERR will catch all. However, if you run
external command (system, ``), stderr output from that process won't
be caught. It is because we tie Perl's STDERR fileglob, not the
external filehandle. This has the advantage that you can say

	{
	local *STDERR; untie *STDERR;
	print STDERR "Now we go directly to STDERR\n";
	}

My main goal was to provide a tool that could be used easily,
especially (but not only) for CGI scripts. My assumption is that the
CGI scripts should run without anything being sent to STDERR (and
error_log, where it mixes up with other messages, even if you use
CGI::Carp). We've found it usefull to get delivered the error and
warning messages together with any relevant information (%ENV) via
email.

Under mod_perl/Apache::Registry, Tie::STDERR tries to work as with
normal scripts -- sends the message at the end of each request. This
is done by registering a cleanup handler. If you

	use Tie::STDERR 'arguments';

in your scripts, everything is fine, because the new parameters are
reset each time the script is run. However, if you use some home grown
module like we do (CGI::BuildPage, wrapper around CGI) that uses
Tie::STDERR, that use will only be called once, during the compilation
of the module and the arguments are not reset and the cleanup handler
will not be registered. So next time your Apache::Registry script uses
this CGI::BuildPage or however you call it, you won't probably get
receive the e-mail. The solution is to call explicitely function
Tie::STDERR::register_apache_cleanup in your module -- I've put it
into the new method that is called in every reasonable script.
(This is however subject to change. Let me know if you find better
solution or if this explanation is unclear.)

=head1 BUGS

The Tie::STDERR catches the compile time errors, but it doesn't get
the reason, only the fact that there was an error. I do not know how
to fix this.

=head1 VERSION

0.26

=head1 AUTHOR

(c) 1998 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic

=cut

