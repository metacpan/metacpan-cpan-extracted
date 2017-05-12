package Pee::FileRunner;

#use strict;
use Pee::Tokenizer;
use vars qw($VERSION $PEE_SCRATCH);

$VERSION = "1.03";

# delimiters to be used for regexp
my @delimiters = ('<\?', '\?>');

# CONSTRUCTOR
# new Pee::Tokenizer ($filename, \%options)
sub new { 
	my $self = {};
	$self->{FILE} = $_[1];
	$self->{OPTIONS} = ($_[2])? $_[2] : {};
	bless ($self);
	return $self;
}


sub safe_escape {
	my $escaped = $_[0];

	$escaped =~ s/\\/\\\\/g;
	$escaped =~ s/\n/\\n/g;
	$escaped =~ s/\t/\\t/g;
	$escaped =~ s/'/\\'/g;
	$escaped =~ s/"/\\"/g;
	$escaped =~ s/\$/\\\$/g;
	$escaped =~ s/\%/\\\%/g;
	$escaped =~ s/\@/\\\@/g;
	$escaped =~ s/&/\\&/g;
	$escaped =~ s/`/\\`/g;
	$escaped =~ s/\|/\\\|/g;

	return $escaped;
}


sub compile {
	my $self = $_[0];
	my $opt = $self->{OPTIONS};
	
	# read in the whole file
	if (!open (F, $self->{FILE})) {
		$self->{errmsg} = "Unable to open file: $!";
		return 0;
	}

	my $buffer;
	while (<F>) {  # Do String Resource Substitution Here
		$buffer .= $_;
	}
	close (F);

	my $tokenizer = Pee::Tokenizer->new($buffer);
	my $r = 0;
	my $token;

	my $done_header = 0;
	my $extracted;

	while (($r = $tokenizer->getNextToken(\$token)) != -1) {

		if ($r == 0) {	# normal block
			# convert into 'print' statement

#			if (!$done_header) {
				# print the header as well
#				$extracted .= 'print "Content-type: text/html\n\n";';
#				$done_header = 1;
#			}

			$token = &safe_escape($token);
#			$extracted .= "print qq|\n$token|;\n";
			$extracted .= "print \"$token\";\n";
		}
		else {	# code block
			my $block = $token;
			$block =~ s/$delimiters[0](.*)$delimiters[1]/$1/s;
			if ($block =~ /^-.*$/s) {
				# comment block
				next;
			}
			elsif ($block =~ /^=(.*)$/s) {
#				my $tmp = eval $1;
				$extracted .= 'print ('."$1);\n";
#				print $tmp if ($tmp);
			}
			elsif ($block =~ /^!\s*(\S*)\s+(.*)$/sm) {
				# special commands
				my $command = $1;
				my $args = $2;

				# trim trailing white space
				$args =~ s/\s*$//;
				if ($command =~ /include/i) {
					if ($args !~ /^\//) {
						# relative path specified
						if ($self->{FILE} =~ /^(.*)\/[^\/]*$/) {
							$args = "$1/$args";
						}
					}

					my $included = $self->PeeInclude($args);
					if (defined ($included)) {
						$extracted .= $included;
					}
					else {
						return 0;
					}
				}
			}
			else {
#				eval $block;
				$extracted .= $block;
			}
		}
	}

	if ($opt->{debug} && $opt->{scratchdir}) {
		write_scratch ($opt->{scratchdir}, $self->{FILE}, $extracted);
	}

	$self->{extracted} = $extracted;
	return 1;
}


# FileRunner::run ($namespace)
# $namespace is 'main' if not specified
sub run {
	local $SIG{__WARN__} = sub { print STDERR "Pee::FileRunner warning: $_[0]\n" };
	local $SIG{__DIE__} = sub { die @_ if $^S; print STDERR "Pee::FileRunner error: $_[0]\n"; };
	my $self = $_[0];
	my $ns = ($_[1] or 'main');

	# Need to return 1 explicitly at the very end to overcome the problem
	# that 'print' returns 0 when run under FCGI
	return 1 if (eval "package $ns;\n\n".$self->{extracted}."\n1;");

	$self->{errmsg} = $@;
	return 0;
}


sub PeeInclude {
	return undef if (!$_[0] || !$_[1]);
	my $self = shift;
	my $args = shift;

#	my $basedir;
#	if ($self->{FILE} =~ /^(.*)\/[^\/]*$/) {
#		$basedir = $1;
#	}
#	else {
#		$self->{errmsg} = "Include directive: Unable to get base directory.";
#		return undef;
#	}

#	my $new = Pee::FileRunner->new("$basedir/$args");
	my $new = Pee::FileRunner->new($args);
	if ($new->compile()) {
		my $extracted = $new->{extracted};
		return $extracted;
	}
	else {
		$self->{errmsg} = "Include directive: Unable to include \"$args\": $new->{errmsg}\n";
		return undef;
	}
}



sub write_scratch {
	my ($dir, $filename, $buf) = @_;

	return if (!-w $dir);

	$filename =~ s/\//_/g;

	open (SCRATCH, ">$dir/$filename") or warn "writing scratch: $!\n";
	print SCRATCH $buf;
	close (SCRATCH);
}
