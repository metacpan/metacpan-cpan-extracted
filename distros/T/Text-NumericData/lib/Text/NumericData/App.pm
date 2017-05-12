package Text::NumericData::App;

use Text::NumericData;
use Config::Param;
use Storable;
use strict;

my %shorts = (strict=>'S', text=>'T', numformat=>'N');

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{setup} = shift; # main, parconf, pardef, exclude_pars
	$self->{state} = {};

	# safety check for misspelled keys
	my @known_setup =
	(qw(
		parconf
		pardef
		exclude
		filemode
		pipemode
		pipe_init
		pipe_file
		pipe_prefilter
		pipe_begin
		pipe_line
		pipe_end
		pipe_allend
		pipe_header
		pipe_data
		pipe_first_data
	));
	my @unknown_keys = grep {my $k = $_; not grep {$_ eq $k} @known_setup;} (keys %{$self->{setup}});
	print STDERR "WARNING: Text::NumericData::App got unknown setup keys (@unknown_keys)\n" if @unknown_keys;

	if($self->{setup}{pipemode})
	{
		# Activate pipe processing only on request.
		require Text::ASCIIPipe;
	}

	$self->{setup}{parconf} = {} unless defined $self->{setup}{parconf};
	# Always return.
	$self->{setup}{parconf}{noexit} = 1;

	# Lazyness ... why specify this again and again?
	$self->{setup}{parconf}{copyright} = $Text::NumericData::copyright
		unless defined $self->{setup}{parconf}{copyright};
	$self->{setup}{parconf}{version} = $Text::NumericData::version
		unless defined $self->{setup}{parconf}{version};
	$self->{setup}{parconf}{author} = $Text::NumericData::author
		unless defined $self->{setup}{parconf}{author};

	$self->{setup}{pardef}  = [] unless defined $self->{setup}{pardef};
	my $prob = Config::Param::sane_pardef($self->{setup}{parconf}, $self->{setup}{pardef});
	if($prob ne '')
	{
		print STDERR  "Error in given parameter definiton: $prob\nThis is a fatal programming error.\n";
		return undef;
	}
	# I'm sure this can be done more elegantly.
	$self->add_param('Text::NumericData'
	, \%Text::NumericData::defaults, \%Text::NumericData::help)
		or return undef;
	$self->add_param('Text::NumericData::File'
	, \%Text::NumericData::File::defaults, \%Text::NumericData::File::help)
		or return undef;

	return $self;
}

sub add_param
{
	my $self = shift;
	my ($pkgname, $defaults, $help) = @_;
	for my $pn (keys %{$defaults})
	{
		next if (defined $self->{setup}{exclude} and grep {$_ eq $pn} @{$self->{setup}{exclude}});
		my $help = $help->{$pn};
		$help = "some $pkgname parameter" unless defined $help;
		$help .= " (from $pkgname)";
		my $thisdef =
		{
		  long=>$pn
		, short=>$shorts{$pn}
		# No deep copy here, as the calls to Config::Param get copies of this.
		, value=>$defaults->{$pn}
		, help=>$help
		};
		if(Config::Param::sane_pardef($self->{setup}{parconf}, [$thisdef]) ne '')
		{
			print STDERR "Unexpected failure to sanitize param definiton for $pn.\n";
			return undef;
		}
		push(@{$self->{setup}{pardef}}, $thisdef);
	}
	return 1;
}

sub run
{
	my ($self, $argv, $in, $out) = @_;
	$argv = \@ARGV unless defined $argv;
	$in  = \*STDIN  unless defined $in;
	$out = \*STDOUT unless defined $out;
	binmode $in;
	binmode $out;
	$self->{argv} = $argv;
	$self->{in}  = $in;
	$self->{out} = $out;

	my $errors;
	# Ensure that Config::Param cannot mess with our default values by
	# providing deep copies of configuration. Even if it behaves nice,
	# better safe than sorry.
	$self->{param} = Config::Param::get(
		Storable::dclone($self->{setup}{parconf})
	,	Storable::dclone($self->{setup}{pardef})
	,	$self->{argv}, $errors );

	if(@{$errors})
	{
		print STDERR "Stopping here because of parameter parsing errors.\n";
		return 1;
	}
	return 0 if($self->{param}{help} or $self->{param}{version});

	if($self->{setup}{pipemode})
	{
		if(defined $self->{setup}{pipe_init})
		{
			my $err = $self->{setup}{pipe_init}->($self);
			if($err)
			{
				print STDERR "Pipe init handler failed, aborting.\n";
				return $err;
			}
		}
		if($self->{setup}{filemode})
		{
			# Not wholly sure about that logic, have to really test and then delete this comment.
			while(1)
			{
				$self->new_txd();
				my $ret = $self->{txd}->read_all($self->{in});
				$self->{setup}{pipe_file}->($self)
					if ($ret >= 0 and defined $self->{setup}{pipe_file});
				last if $ret <= 0;
			}
			$self->{setup}{pipe_allend}->($self)
				if defined $self->{setup}{pipe_allend};
			Text::ASCIIPipe::done($self->{out})
				if $self->{txd}{config}{pipemode};
		}
		else
		{
			Text::ASCIIPipe::process
			(
				 handle => $self
				,in     => $self->{in}
				,out    => $self->{out}
				,pre    => $self->{setup}{pipe_prefilter}
				,begin  => defined $self->{setup}{pipe_begin} ? $self->{setup}{pipe_begin} : \&new_txd
				,line   => defined $self->{setup}{pipe_line} ? $self->{setup}{pipe_line} : \&default_line_hook
				,end    => $self->{setup}{pipe_end}
				,allend => $self->{setup}{pipe_allend}
			);
		}
		return 0;
	}
	else
	{
		$self->new_txd();
		return $self->main();
	}
}

sub new_txd
{
	my $self = shift;
	require Text::NumericData::File if $self->{setup}{filemode};

	$self->{txd} = $self->{setup}{filemode}
		? Text::NumericData::File->new($self->{param})
		: Text::NumericData->new($self->{param});

	$self->{state}{data} = 0;
}


sub default_line_hook
{
	my $self = shift;
	my $prefix = undef;
	if(!$self->{state}{data})
	{
		if($self->{txd}->line_check($_[0]))
		{
			$self->{state}{data} = 1;
			$prefix = $self->{setup}{pipe_first_data}->($self, @_)
				if defined $self->{setup}{pipe_first_data};
		}
		else
		{
			$self->{setup}{pipe_header}->($self, @_)
				if defined $self->{setup}{pipe_header};
			return;
		}
	}
	# If still here, $self->{state}{data} == 1 is implied.
	$self->{setup}{pipe_data}->($self, @_)
		if defined $self->{setup}{pipe_data};
	$_[0] = ${$prefix}.$_[0]
		if defined $prefix;
}

sub error
{
	my $self = shift;
	print STDERR "$_[0]\n" if defined $_[0];
	return defined $_[1] ? $_[1] : -1;
}

1;

__END__

=head1 NAME

Text::NumericData::App - tools for applications using Text::NumericData

=head1 SYNOPSYS

	# usage of the application
	my $app = SomeApp->new();
	# arguments optional, defaults shown
	exit $app->run(\@ARGV, \*STDIN, \*STDOUT);

	# The application itself.
	package SomeApp;

	use Text::NumericData;
	use Text::NumericData::App;

	our @ISA = ('Text::NumericData::App');

	sub new
	{
		my $class = shift;
		# All settings optional.
		%setup =
		(
			 parconf=>{info=>'a program that sets the second column to a given value'}
			,pardef=>['value',42,'','value to set second column to']
			# Optionally bar some parameters of Text::NumericData from command line.
			,exclude_pars=>['strict']
		);
		return $class->SUPER::new(\%setup);
	}

	sub main
	{
		my $self = shift;
		# Conveniently use common parameter hash.
		# Could use something custom, though.
		my $txd = Text::NumericData->new($self->{param});
		my $data = 0;
		while(my $line = <$self->{in}>)
		{
			unless($data)
			{
				# Separate header and data.
				if($txd->line_check($line)){ $data = 1; }
				else{ print {$self->{out}} $line; }
			}
			if($data)
			{
				my $d = $txd->line_data($_);
				$d->[1] = $self->{param}{value};
				print {$self->{out}} ${$txd->data_line($d)};
			}
		}
		return 0;
	}

=head2 Pipe processing mode

	package SomeApp;

	use Text::NumericData;
	use Text::NumericData::App;

	our @ISA = ('Text::NumericData::App');

	sub new
	{
		my $class = shift;
		# All settings optional.
		%setup =
		(
			 parconf=>{info=>'a program that sets the second column to a given value'}
			,pardef=>['value',42,'','value to set second column to']
			# Activate pipe mode via Text::ASCIIPipe.
			# See documentation about meaning of handler functions.
			,pipemode=>1
			# Handlers optional, but when you specify none,
			# nothing happens.
			# $self handle is implicit --- please hand in methods!
			,pipe_init   =>   \&init # once before real action
			# another option: work on raw line before parsing
			# might return true value to skip further processing
			#,pipe_preparse => \&check_line
			,pipe_begin  =>  \&begin # new file
			,pipe_header => \&process_header
			,pipe_first_data => \&process_first_data
			,pipe_data   => \&process_data
			# override generic handler that would call the three above
			#,pipe_line   =>   \&process_line
			,pipe_end    =>    \&end # file end
			,pipe_allend => \&allend # total end
		);
		return $class->SUPER::new(\%setup);
	}

	# This shall return non-zero on error.
	# Other handlers are doomed to be successful.
	sub init
	{
		my $self = shift;
		$self->{some_state} = 17;
		return 0;
	}

	sub begin
	{
		my $self = shift;
		# Create fresh Text::NumericData handle.
		$self->new_txd(); # This would happen by default, too.
	}

	sub process_header
	{
		my $self = shift;
		# Do something with $self->{txd} or $_[0] ...
	}

	sub process_first_data
	{
		my $s = "# This will be inserted before first data line.\n";
		return \$s;
	}

	sub process_data
	{
		my $self = shift;
		my $d = $txd->line_data($_[0]);
		$d->[1] = $self->{param}{value};
		$_[0] = ${$txd->data_line($d)};
	}

	sub end
	{
		# nothing of interest, could give some report
	}

	sub allend
	{
		# see above
	}

=head2 File-based pipe processing

	package SomeApp;

	use Text::NumericData;
	use Text::NumericData::App;

	our @ISA = ('Text::NumericData::App');

	sub new
	{
		my $class = shift;
		# All settings optional.
		%setup =
		(
			 parconf=>{info=>'a program that sets the second column to a given value'}
			,pardef=>['value',42,'','value to set second column to']
			# operate on whole file at a time
			,filemode=>1
			# Note that pipe mode does not add that much functionality,
			# the piped reading is built into the Text::NumericData::File class
			# already.  There's only a basic loop checking special return values.
			,pipemode=>1
			,pipe_init   => \&init
			,pipe_file   => \&process_file
			,pipe_allend => \&allend
		);
		return $class->SUPER::new(\%setup);
	}

	# This shall return non-zero on error.
	# Other handlers are doomed to be successful.
	sub init
	{
		my $self = shift;
		$self->{some_state} = 17;
		return 0;
	}

	# This is supposed to return nozero error if program should abort.
	sub process_file
	{
		my $self = shift;
		# Do something with $self->{txd}, which has the current file read in.
		return 0; # all fine
	}

	sub allend
	{
		# Whatever you see fit to do here.
	}

=head1 DESCRIPTION

This is wholly intended for building the standard txd* tools, but might be useful for you, too. It glues together Text::NumericData and Config::Param to quickly deploy a command line program that offers a standard parameter set. The setting of pipemode triggers the L<Text::ASCIIPipe>
processing pattern.

It merges your parameter definitions with the ones from L<Text::NumericData>, parses command line using L<Config::Param>, and also ensures binary mode for input/output (as L<Text::NumericData> tries to treat line ends explicitly).

=head2 Line-based mode

This creates an instance of Text::NumericData as $self->{txd} and is intended to process files line-by-line.

=head2 File-based mode

This creates an instance of Text::NumericData::File as $self->{txd} and is intended to read files into $self->{txd} before processing as a whole.

=head1 MEMBERS

This base class defines some members that you should know about

=over 4

=item B<run>

This is the method that actually runs the program which is fleshed out in a subclass from L<Text::NumericData::App>. It takes 3 optional arguments: ref to command line argument array (defaults to \@ARGV), ref to input (defaults to \*STDIN), ref to output (defaults to \*STDOUT). Those are stored in $self->{argv}, $self->{in} and $self->{out}, respectively.

=item B<param>

Paramater hash from Config::Param, defining the parameter space for your program including Text::NumericData.

=item B<txd>

An instance of either L<Text::NumericData> or L<Text::NumericData::Lines> (depending on filemode setting). The default pipemode file-begin handler refreshes this one.

=item B<new_txd>

The refresh method: Replace $self->{txd} by a new instance. The default pipe_begin callback calls this to give you something to work with. It's also called before running main() when not in pipemode.

=item B<argv>, B<in>, B<out>

The places where run method stores the currently active argument array and input/output handles.

=item B<setup>

Well, actually, you defined that: This is the configuration hash handed to the constructor, extended a bit by this (additional setup of Config::Param, for example).

=item B<state>

A general-purpose hash with some state information. Of interest might be $self->{state}{data}, which indicates if we hit the data section of the file. But if you need to handle that explicitly, you'll manage your own state.

=item B<default_line_hook>

Method that runs when you do not override pipe_line.

=item B<error>

Simple wrapper to print out a message and return a given value or -1 per default. This is to cut down such code in main or init methods:

	if($some_bad_thing)
	{
		print STDERR "Some error occured!\n";
		return $bad_return_value;
	}

to

	return $self->error("Some error occured", $bad_return_value)
		if $some_bad_thing;

So it doesn't do much yet. It might carry an error count and do something with it.

=back

=cut

