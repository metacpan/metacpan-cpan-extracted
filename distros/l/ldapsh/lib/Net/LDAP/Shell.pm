package Net::LDAP::Shell;

$^W = 1;

use strict;
require Exporter;
use Getopt::Long;
use Net::LDAP::Shell::Util qw(debug error entry2ldif);
use Term::ReadLine;
use Net::LDAP::Shell::Parse;

use vars qw($VERSION @EXTRA_LDAP_ATTRS @ISA @EXPORT %LOADED $AUTOLOAD $SHELL);

@ISA = qw(Exporter);
@EXPORT = qw(
	debug
	error
	entry2ldif
	shellSearch
);

$VERSION = 2.00;

@EXTRA_LDAP_ATTRS = qw(numSubordinates);

$| = 1;

#$SIG{'TERM'} = \&signalHandler;
$SIG{'INT'} = \&signalHandler;

=head1 NAME

Net::LDAP::Shell - an interactive LDAP shell

=head1 SYNOPSIS

my $shell = Net::LDAP::Shell->new();
$shell->run();

=head1 DESCRIPTION

B<Net::LDAP::Shell> is the base module for an interactive
LDAP shell, modeled after the Unix CLI but hopefully
nowhere near as complicated.  It has both builtin commands
(found by running 'builtins' on the CLI) and external
commands (?).

You probably want to actually just run 'perldoc ldapsh', 
rather than reading this.

=head1 DESCRIPTION

=over 4

=cut

################################################################################
################################################################################
# normal shell stuff
################################################################################
################################################################################

#################################################################################
# assign

=item assign

Adds a variable.

=cut

sub assign {
	my $shell = shift or die error("assign called without shell");

	my ($var,$value) = @_;

	$shell->{'env'}->{$var} = $value;
}
# assign
#################################################################################

#################################################################################
# command

=item command

Takes the command typed by the user and Does the Right Thing(TM).
Accepts a single typed command as an argument, and returns
the return value of the executed command.

=cut

sub command {
	my $shell = shift or die error("command called without shell");
	my ($word,@oargv,);
	@oargv = @ARGV;

	my @line = @_;
	#$line = shift;
	#@command = parse($line) or return;
	$word = shift @line;
	#$word = shift @command;
	debug("word is $word");

	@ARGV = @line;

	if ($shell->buildins($word)) {
		my $return = eval { $shell->$word() };
		if ($@) {
			warn "$@";
		}
		return $return;
	} else {
		debug("trying to load $word");
		unless (exists $shell->{'commands'}->{$word}) {
			$shell->load($word) or
				return warn error("$word: Command not found");
		}
		#return $shell->{'commands'}->{$word}->($shell);
		my $return = eval { $shell->{'commands'}->{$word}->($shell) };
		if ($@) {
			warn "$@";
		}
		return $return;
	}
}
# command
#################################################################################

#################################################################################
# gnureadline

=item gnureadline

What kind of readline are we?  GNU ReadLine has some special capabilities.

=cut

sub gnureadline {
	my $shell = shift or die error("gnureadline called without shell");

	return($shell->{'TERM'}->ReadLine eq 'Term::ReadLine::Gnu');
}

sub stubreadline {
	my $shell = shift or die error("stubreadline called without shell");

	return($shell->{'TERM'}->ReadLine eq 'Term::ReadLine::Stub');
}

sub perlreadline {
	my $shell = shift or die error("perlreadline called without shell");

	return($shell->{'TERM'}->ReadLine eq 'Term::ReadLine::Perl');
}

# gnureadline
#################################################################################

#################################################################################
# load

=item load

My own little version of autoload.  Once B<command> has found
that a command is not a builtin command, it runs B<load> to try to
autoload the command.  B<load> searches its path (stored
in $CONFIG{'PATH'}) for other commands, and if it finds any it
returns the package of the command; otherwise it returns null.

=cut

sub load {
	my $shell = shift or die error("load called without shell");
	my $command = shift;
	my ($dir,$package,$sub);
	debug("loading $command");

	#debug("entering loop: dir [$dir] command [$command]");
	foreach $dir (@{ $shell->{'CONFIG'}->{'PATH'} }) {
		debug("working on $dir");

		my $path2cmd = $dir . "::$command";

		if (eval {
				# i want:
				# require Shell::Commands::command;
				#eval "require $dir" . "::$command;";
				eval "package $path2cmd; use vars qw(\%CONFIG); require $path2cmd";
				if ($@) {
					warn "'$command' not found or would not compile\n";
					debug("eval require output is [$@]");
					#warn "'$command' failed to compile:
#$@\n";
					return 1;
				} else {
					#return 0;
				}
			}
		) {
			#debug("eval output is [$@]");
			delete $INC{$dir . "::$command"}; # in case it partially loaded
			return;
		} else {
			#print "tmp is $tmp\n";
		}

		debug("defining sub");
		$sub = eval "sub {
package $path2cmd;

my \$shell = shift;
\%CONFIG = \%{ \$shell->{'CONFIG'} };
undef @" . "_;
require $path2cmd;
main();
undef %" . "CONFIG;
}
";
		unless ($@) {
			debug("sub is $sub");
			$shell->{'commands'}->{$command} = $sub;
			#$package = "$dir" . "::$command";
		} else {
			debug("eval output is [$@]");
			undef $sub;
		}
	}
	if ($sub) {
		return $sub;
	} else {
		return;
	}
}
# load
#################################################################################

#################################################################################
# loadhistory

=item loadhistory

Load the history file.

=cut

sub loadhistory {
	my $shell = shift or die error("loadhistory called without shell");

	if ($shell->gnureadline()) {
		$shell->{'TERM'}->ReadHistory($shell->{'histfile'});
	} elsif ($shell->stubreadline()) {
		warn "For history capabilities, install Term::ReadLine::Perl or
Term::ReadLine::Gnu";
	} else {
		if (-e $shell->{'histfile'}) {
			my @history;
			open HISTFILE, $shell->{'histfile'} or
				die "Could not read $shell->{'histfile'}: $!\n";
			while (my $line = <HISTFILE>) {
				chomp $line;
				push @history, $line;
			}
			close HISTFILE;
			$shell->{'TERM'}->SetHistory(@history);
		}
	}
}
# loadhistory
#################################################################################

#################################################################################
# loadprofile

=item loadprofile

Load the profile.

=cut

sub loadprofile {
	my $shell = shift or die error("loadprofile called without shell");

	if (-e $shell->{'profile'}) {
		open PROFILE, $shell->{'profile'} or
			die "Could not read $shell->{'profile'}: $!\n";
		while (my $line = <PROFILE>) {
			chomp $line;
			# just run each of them...
			# this won't work with multiple line commands, i think, but...
			$shell->parse($line);
		}
		close PROFILE;
	}
}
# loadprofile
#################################################################################

#################################################################################
# new

=item new

The constructor for the shell.  Accepts a hash as arguments, containing
anything that is otherwise in the %CONFIG hash.

=cut

sub new {
	use Net::LDAP::Config;
	my ($shell,$type,%args);
	$type = shift;
	$shell = bless {}, $type;

	$SHELL = $shell;

	%args = @_;

	if ($args{'debug'}) {
		debug('on');
	}

	$args{'source'} ||= "default";

	$shell->{'CONFIG'} = Net::LDAP::Config->new(%args);
	if ($args{'anonymous'}) {
		$shell->{'CONFIG'}->bind();
	} else {
		$shell->{'CONFIG'}->clauth(%args);
	}
	if (error()) { die error(); }
	$shell->{'CONFIG'}->scope(1);
	$shell->{'CONFIG'}->prompt('%S:%b> ');

	$shell->{'TERM'} = new Term::ReadLine('ldapsh', \*STDIN, \*STDERR);

	#my $feats = $shell->{'TERM'}->Features;
	#foreach my $feat (keys %$feats) {
	#	print "$feat $feats->{$feat}\n";
	#}
	#my $atts = $shell->{'TERM'}->Attribs;
	$shell->{'TERMATTRS'} = $shell->{'TERM'}->Attribs;

	# completion stuff
	$shell->{'TERMATTRS'}->{'basic_word_break_characters'} = qq( \t'"\$\@);
	$shell->{'TERMATTRS'}->{'completer_word_break_characters'} = qq( \t'"\$\@);
	require Net::LDAP::Shell::Complete;
	import Net::LDAP::Shell::Complete;

	undef $shell->{'TERMATTRS'}->{completion_entry_function};
	$shell->{'TERMATTRS'}->{attempted_completion_function} =
		\&Net::LDAP::Shell::Complete::attemptCompletion;

	#if ($shell->gnureadline) {
	#	$shell->{'TERMATTRS'}->{'completion_append_character'} = '	';
	#} elsif ($shell->perlreadline) {
	#	$shell->{'TERMATTRS'}->{'completer_terminator_character'} = '	';
	#}

	#print %$atts, "\n";
	#foreach my $attr (keys %$atts) {
	#	print "$attr $atts->{$attr}\n";
	#}


	if ($shell->{'CONFIG'}->base()) {
		$shell->{'CONFIG'}->root($shell->{'CONFIG'}->base() );
	}

	# set our initial search path
	push @{ $shell->{'CONFIG'}->{'PATH'} }, "Net::LDAP::Shell::Commands";

	$shell->{'histfile'} = $ENV{'LDAPSH_HISTFILE'} || $ENV{'HOME'} . '/.ldapsh_history';
	$shell->{'profile'} = $ENV{'LDAPSH_PROFILE'} || $ENV{'HOME'} . '/.ldapshrc';

	$shell->loadprofile();
	$shell->loadhistory();

	return $shell;
}
# new
#################################################################################

#################################################################################
# parse

=item parse

Actually parses the command line.  Accepts a string (the command
as typed by the user) and returns an array.

=cut

sub parse {
	my $shell = shift or die error("parse called without shell");
	my $line = shift;
	debug("parsing [$line]");
	return Net::LDAP::Shell::Parse::parse($line);
}

=cut
	chomp $line;
	unless ($line) { return; }

	my $word;
	my @ary;

	while ($line) {
		$line =~ s/^'([^']+)'\s*// and do {
			$word = $1;
			debug("pulled [$word]");
			push @ary, $word;
			next;
		};
		$line =~ s/^"([^"]+)"\s*// and do {
			$word = $1;
			debug("pulled [$word]");
			push @ary, $word;
			next;
		};
		$line =~ s/^(\S+)\s*// and do {
			$word = $1;
			debug("pulled [$word]");
			push @ary, $word;
			next;
		};
	}

	return @ary;
}
=cut
# parse
#################################################################################

#################################################################################
# prompt

=item prompt

Prints the prompt.  Does various replacements on the $CONFIG{'prompt'}
string to make the prompt meaningful.  This is called at the end of every
completed command.

=cut

sub prompt {
	my $shell = shift or die error("prompt called without shell");
	my $prompt = $shell->{'CONFIG'}->prompt();
	$prompt =~ s/\%S/$shell->{'CONFIG'}->{'source'}/;
	$prompt =~ s/\%s/$shell->{'CONFIG'}->{'server'}/;
	$prompt =~ s/\%b/$shell->{'CONFIG'}->{'base'}/;

	return $prompt;
}
# prompt
#################################################################################

#################################################################################
# resetline

=item resetline

Clears the current line and provides another prompt.  Usually the result
of ^C.

=cut

sub resetline {
	my $shell = shift or die error("resetline called without shell");

	if ($shell->gnureadline()) {
		$shell->{'TERM'}->free_line_state();
		$shell->{'TERM'}->cleanup_after_signal();
	} else {
		# no idea what to do here
	}
}

# resetline
#################################################################################

#################################################################################
# run

=item run

Executes the shell.  Yah, this is probably redundant, but I don't really
care...

=cut

sub run {
	my $shell = shift or die error("run called without shell");
	my $line;
	#while ($line = <STDIN>) {
	#while ($line = $shell->{'TERM'}->readline($shell->prompt())) {
	#print "prompt is '$str'\n";
	$line = $shell->{'TERM'}->readline($shell->prompt());
	#$shell->{'TERM'}->addhistory($line);
	while (defined $line) {
		if ($line) {
			$shell->{'TERM'}->addhistory($line);
		}
		#chomp $line;
		$shell->parse($line);
		#$shell->prompt();
		$line = $shell->{'TERM'}->readline($shell->prompt());
	}
	$shell->{'CONFIG'}->{'ldap'}->unbind;
}
# run
#################################################################################

#################################################################################
# search

=item search

An ldapsearch command which must be called as an object method;
it takes its config info from the %CONFIG hash and performs a search.
It returns a list of entries if any are found, and returns null if none
are.  It sets B<error> if an error was found.

=cut

sub search {
	my $shell = shift or die error("search called without shell");
	my ($attrs,$results);
	unless ($attrs = $shell->{'CONFIG'}->attrs()) {
		$attrs = [ qw(*) ];
	}

	debug("scope: $shell->{'CONFIG'}->{'scope'}, filter: $shell->{'CONFIG'}->{'filter'}, base: $shell->{'CONFIG'}->{'base'}");

	$results = $shell->{'CONFIG'}->{'ldap'}->search(
		'base'	=> $shell->{'CONFIG'}->base(),
		'filter'	=> $shell->{'CONFIG'}->filter(),
		'scope'	=> $shell->{'CONFIG'}->scope(),
		'attrs'	=> $attrs,
	);

	$results->code and error($results->error()), return;

	if ($results->all_entries > 0) {
		return $results->all_entries;
	} else {
		return;
	}
}
# search
#################################################################################

#################################################################################
# teardown

=item teardown

Clean up everything and close.

=cut

sub teardown {
	my $shell = shift or die error("teardown called without shell");
	$shell->{'CONFIG'}->{'ldap'}->unbind;
	$shell->writehistory();
	exit;
}
# teardown
#################################################################################

#################################################################################
# term

=item term

Return the ReadLine object.

=cut

sub term {
	my $shell = shift or die error("term called without shell");

	return $shell->{'TERM'};
}
# term
#################################################################################

#################################################################################
# termattrs

=item termattrs

Return the ReadLine attributes

=cut

sub termattrs {
	my $shell = shift or die error("term called without shell");

	return $shell->{'TERMATTRS'};
}
# termattrs
#################################################################################

#################################################################################
# writehistory

=item writehistory

Write the history file.

=cut

sub writehistory {
	my $shell = shift or die error("writehistory called without shell");

	if ($shell->gnureadline()) {
		$shell->{'TERM'}->WriteHistory($shell->{'histfile'});
	} elsif ($shell->stubreadline()) {
		warn "For history capabilities, install Term::ReadLine::Perl or
Term::ReadLine::Gnu";
	} else {
		eval {
			# there might not be a GetHistory function...
			my @history = $shell->{'TERM'}->GetHistory();
			my $i = 0;
			open HISTFILE, "> $shell->{'histfile'}" or
				die "Could not read $shell->{'histfile'}: $!\n";
			foreach my $line (@history) {
				# no idea why, but GetHistory returns a list full of duplicates
				# this just dedupes them
				unless ($i % 2) {
					print HISTFILE $line . "\n";
				}
				$i++;
			}
			close HISTFILE;
		}
	}
}
# writehistory
#################################################################################

#################################################################################
# shellSearch

=item shellSearch

An ldapsearch command which can be called independently, and is
exported for use by external commands.  Otherwise it is exactly
equivalent to the B<search> method.

=cut

sub shellSearch {
	#my %CONFIG = @_;
	my %config = @_;
	my ($attrs,$results);
	#unless ($attrs = $CONFIG{'attrs'}) {
	#	$attrs = [ qw(*) ];
	#}

	my $CONFIG = $SHELL->{'CONFIG'};

	my %args = (
		'base'		=> $config{'base'}		|| $CONFIG->base,
		'filter'	=> $config{'filter'}	|| $CONFIG->filter,
		'scope'		=> $config{'scope'}		|| $CONFIG->scope,
	);
	if ($config{'attrs'} or $CONFIG->attrs) {
		$args{'attrs'}= $config{'attrs'} || $CONFIG->attrs;
	}
	$results = $CONFIG->ldap->search(%args);

	if ($results->code) {
		if ($results->code == 0x04) {
			error("Too many results returned");
		} else {
			error($results->error()), return;
		}
	}

	if ($results->all_entries > 0) {
		return $results->all_entries;
	} else {
		return;
	}
}
# shellSearch
#################################################################################

#################################################################################
# signalHandler
sub signalHandler {
	my $signal = shift;

	for ($signal) {
		/INT/ and do {
			$SHELL->resetline();
		};
	}
	#warn "got signal $signal\n";
}
# signalHandler
#################################################################################

#################################################################################
# buildins

=item buildins

Constructs the builtin commands on demand.  Returns null on failure
and returns the command on success.

=cut

sub buildins {
	my $shell = shift or die error("buildins called without shell");

	my $cmd = shift;

	# make sure all of our commands are defined
	$shell->{'BUILTINS'} ||= {
		'builtins'	=> <<'END_OF_FUNC',
		sub builtins {
			my $shell = shift or die error("builtins called without shell");

			my ($optresult,$usage,$help,$helptext);
			$usage = "builtins\n";
			$optresult = GetOptions(
				'help'	=> \$help,
			);

			$helptext = "Prints out a list of available built-in commands.\n";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			my @cmds = (keys %{ $shell->{'BUILTINS'} },
				keys %{ $shell->{'definedbuiltins'} });

			print join("\n",sort @cmds),"\n";

			return 0;
		}
END_OF_FUNC

		'cd'	=> <<'END_OF_FUNC',
		sub cd {
			my $shell = shift or die error("cd called without shell");
			my (%config,$results,$rdn,$entry,$oscope,$obase);

			my ($optresult,$usage,$help,$helptext);
			$usage = "cd\n";
			$optresult = GetOptions(
				'help'	=> \$help,
			);

			$helptext =
"Allows changing of directories.  Similarly to Unix filesystems,
'..' and '.' are understood.  Also, 'cd /' takes you back to the
base you originally connected with.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$help;
				return 0;
			}

			$rdn = shift @ARGV || '/';
			for ($rdn) {
				/^\.$/ and do
				{
					debug("got .");
				};
				/^\.\.$/ and do {
					$oscope = $shell->{'CONFIG'}->{'scope'};
					$obase = $shell->{'CONFIG'}->{'base'};
					$shell->{'CONFIG'}->{'scope'} = 0;

					debug("got ..");
					$shell->{'CONFIG'}->{'filter'} = 'objectclass=*';
					$shell->{'CONFIG'}->{'base'} =~ s/^[^,]+,\s*//;
					debug(".. is $shell->{'CONFIG'}->{'base'}");

					if ($shell->search()) {
						debug("found .. as $shell->{'CONFIG'}->{'base'}");
						$shell->{'CONFIG'}->{'scope'} = $oscope;
					} else {
						warn "$shell->{'CONFIG'}->{'base'}: not found\n";
						$shell->{'CONFIG'}->{'base'} =~ $obase;
					}
					return;
				}; /^\/$/ and do {
					debug("got /");
					$oscope = $shell->{'CONFIG'}->{'scope'};
					$obase = $shell->{'CONFIG'}->{'base'};
					$shell->{'CONFIG'}->{'scope'} = 0;

					if ($shell->{'CONFIG'}->{'root'}) {
						$shell->{'CONFIG'}->{'base'} = $shell->{'CONFIG'}->{'root'};
					} else {
						warn "/: unset\n";
					}
					$shell->{'CONFIG'}->{'scope'} = $oscope;
					return;
				};
			}

			if ($rdn =~ /^(.+),([^,]+)$/) {
				$shell->{'CONFIG'}->{'base'} = "$1,$shell->{'CONFIG'}->{'base'}";
				$shell->{'CONFIG'}->{'filter'} = $2;
			} else {
				$shell->{'CONFIG'}->{'filter'} = $rdn;
			}

			my @entries = $shell->search() or warn("$rdn: not found\n");

			if ($entry = shift @entries) {
				$shell->{'CONFIG'}->{'base'} = $entry->dn;
			}
			return;
		}
END_OF_FUNC
		
		'config'	=> <<'END_OF_FUNC',
		sub config {
			my $shell = shift or die error("config called without shell");

			my ($verbose,@skipvars,$optresult,$usage,$help,$helptext);
			$usage = "config [--verbose]\n";
			$optresult = GetOptions(
				'verbose'		=> \$verbose,
				'help'		=> \$help,
			);

			$helptext =
"Prints out the current config.  If you want to change any
of these variables, use 'export'.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			@skipvars = qw(password);

			foreach my $var (sort keys %{ $shell->{'CONFIG'} }) {
				if (grep /$var/, @skipvars) { next unless $verbose; }
				unless ($shell->{'CONFIG'}->{$var}) {
					next;
				}
				if (ref $shell->{'CONFIG'}->{$var}) {
					for (ref $shell->{'CONFIG'}->{$var}) {
						/ARRAY/ and do {
							print "$var = [\n\t",
								join("\n\t",@{$shell->{'CONFIG'}->{$var}}),
								"\n]\n";
						};
						/HASH/ and do {
							print "$var = {\n",
								map { "\t$_ => $shell->{'CONFIG'}->{$var}->{$_}\n" } 
									keys %{$shell->{'CONFIG'}->{$var}},
								"}\n";
						};
					}
				} else {
					print "$var = $shell->{'CONFIG'}->{$var}\n";
				}
			}
		}
END_OF_FUNC
		
		'debugging'	=> <<'END_OF_FUNC',
		sub debugging {
			my $shell = shift or die error("debugging called without shell");
			my ($optresult,$usage,$help,$helptext);
			$usage = "debugging [--help] [on|off]\n";
			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Turns debugging on or off.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			my $arg = shift @ARGV or do {
				if ($shell->debug()) {
					print "debugging on\n";
				} else {
					print "debugging off\n";
				}
				return;
			};
			if ($arg eq 'on') {
				return debug('on');
			} elsif ($arg eq 'off') {
				return debug('off');
			} else {
				warn $usage;
				return 1;
			}
		}
END_OF_FUNC
		
		'pwd'	=> <<'END_OF_FUNC',
		sub pwd {
			my $shell = shift or die error("pwd called without shell");
			my ($optresult,$usage,$help,$helptext);
			$usage = "pwd [--help]\n";
			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Prints the current working directory.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			print "$shell->{'CONFIG'}->{'base'}\n";
		}
END_OF_FUNC
		
		'exit'	=> <<'END_OF_FUNC',
		sub exit {
			my $shell = shift or die error("exit called without shell");
			my ($optresult,$usage,$help,$helptext);
			$usage = "exit [--help]\n";
			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Exits.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			$shell->teardown();
			#exit;
		}
END_OF_FUNC
		
		'quit'	=> <<'END_OF_FUNC',
		sub quit {
			my $shell = shift or die error("quit called without shell");
			my ($optresult,$usage,$help,$helptext);
			$usage = "quit [--help]\n";
			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Quits.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			#$shell->{'CONFIG'}->{'ldap'}->unbind;
			$shell->teardown();
			#exit;
		}
END_OF_FUNC

		'reload'	=> <<'END_OF_FUNC',
		sub reload {
			my $shell = shift or die error("reload called without shell");

			my ($optresult,$usage,$help,$helptext);
			$usage = "reload [--help] [module]\n";
			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Attempts to reload a specified module or Net::LDAP::Shell.
By default, it reloads Net::LDAP::Shell, but you can
also specify another module, in colon-notation (i.e.,
Net::LDAP::Shell::Commands::ls, not Net/LDAP/Shell/Commands/ls.pm).

This is not guaranteed to work, especially if you have reloaded
a module from another location for debugging.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			my ($mod,$package,$cmd);
			if ($package = shift @ARGV) {
				debug("reloading $package\n");
				$cmd = $package;
				$cmd =~ s/.+:://;

				if (exists $shell->{'commands'}->{$cmd}) {
					delete $shell->{'commands'}->{$cmd};
				}
				if ($package =~ /::/) {
					$mod = $package;
					$mod =~ s/::/\//g;
					$mod =~ s/$/.pm/;
				} else {
					$mod = $package;
					$package =~ s/\//::/g;
					$package =~ s/\.pm//;
				}
				if (exists $INC{$mod}) {
					delete $INC{$mod};
					#eval "require $package;";
					#if ($@)
					#{
					#	warn "Reload of $package failed: $@\n";
					#}
				} else {
					warn "Could not find package $package ($mod).\n";
					map { print "$_ => $INC{$_}\n"; } sort keys %INC;
				}
			} else {
				delete $shell->{'definedbuiltins'};
				delete $shell->{'BUILTINS'};
				delete $INC{'Net/LDAP/Shell.pm'};
				eval "require Net::LDAP::Shell;";
				if ($@) {
					warn "Reload of $package failed: $@\n";
				}
			}
		}
END_OF_FUNC

		'export'	=> <<'END_OF_FUNC',
		sub export {
			my $shell = shift or die error("export called without shell");

			my ($optresult,$usage,$help,$helptext);
			$usage = 
"export [--help] <variable>=<value> [<variable>=<value>] [..]
";

			$optresult = GetOptions(
				'help'		=> \$help,
			);

			$helptext =
"Allows you to set the value of a config variable.  You can
either reset the value of an existing variable (such as
'base' or 'prompt') or you can create a new variable.

Currently these variables are not available to you on the
command line, so they are only used by other commands you run.

If you modify existing config variables, it is recommended you
know what you are doing before you do so.
";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			my ($var,$value);

			foreach (@ARGV) {
				/^([^=]+)=(.+)$/;
				($var,$value) = ($1,$2);
				$shell->{'CONFIG'}->{$var} = $value;
			}
		}
END_OF_FUNC

		'set'	=> <<'END_OF_FUNC',
		sub set {
			my $shell = shift or die error("set called without shell");

			my ($optresult,$usage,$help,$helptext,$operation);
			$usage = "set\n";
			$optresult = GetOptions(
				'help'	=> \$help,
				'operation=s'	=> \$operation,
			);

			$helptext = "Sets ReadLine options:
	-o <vi|emacs>
\n";

			unless ($optresult) {
				warn $usage;
				return 1;
			}

			if ($help) {
				print $usage,$helptext;
				return 0;
			}

			my $something = 0;

			for ($operation) {
				/emacs/ and do {
					$shell->{'TERMATTRS'}->{'editing_mode'} = 1;
					next;
				};
				/vi/ and do {
					$shell->{'TERMATTRS'}->{'editing_mode'} = 0;
					next;
				};

				print "Unknown editing mode '$operation'\n";
				return 1;
			}

			return 0;
		}
END_OF_FUNC
		
	};

	# now do the actual work of compiling the commands
	if (exists $shell->{'definedbuiltins'}->{$cmd}) {
		debug("$cmd is already compiled");
		return $shell->{'definedbuiltins'}->{$cmd};
	} elsif (exists $shell->{'BUILTINS'}->{$cmd}) {
		debug("building $cmd");
		eval $shell->{'BUILTINS'}->{$cmd};
		if ($@)
		{
			warn "$cmd: Failed to load: $@\n";
		}
		else
		{
			$shell->{'definedbuiltins'}->{$cmd} = $cmd;
			delete $shell->{'BUILTINS'}->{$cmd};
		}
		debug("built $cmd");
		return $cmd;
	} else {
		debug("builtin $cmd not found");
		return;
	}
}
# buildins
#################################################################################

=back

=head1 BUGS

See L<ldapsh>.

=head1 SEE ALSO

L<ldapsh>,
L<Net::LDAP>

=head1 AUTHOR

Luke A. Kanies, luke@madstop.com

=for html <hr>

I<$Id: Shell.pm,v 1.16 2004/03/25 19:59:15 luke Exp $>

=cut

1;
