package Website;
use strict;
########################################################################
# Website - Perl extension for as engine to render template-driven
# applications, designed to run quickly in CGI and mod_perl environments
########################################################################
my $package = __PACKAGE__;
our $VERSION = '1.14.01';
$| = 1;

#-----  GLOBAL VARS
my %Var; # Variables to replace
my $contentType; # 1=Content-type is already set / 0=it's not set yet
my $begin_block = '<!-- {{BLOCK ';
my $end_block   = '<!-- {{END';
my @block_names = ();
my %print_block;
my %Glob_Args = (); # global arguments
my %Tune_Output = ();
my @Parse_Lines = (); # which lines have to be parsed -> output option


#-----  FORWARD DECLARATIONS & PROTOTYPING
sub Error($);
sub Debug($);

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {};

	$self->{'file'     } = $params{'file'     };
	$self->{'save_as'  } = $params{'save_as'  };
	$self->{'start_seq'} = $params{'start_seq'};
	$self->{'stop_seq' } = $params{'stop_seq' };
	$self->{'tuning'   } = $params{'tuning'   };
	$self->{'debug'    } = $params{'debug'    };

	Debug "$package V$VERSION" if $self->{'debug'};

	foreach ( @{$self->{'tuning'}} ) {
		$Glob_Args{$_} = 1;
		Debug "tuning $_" if $self->{'debug'};
	}

	if ($Glob_Args{'output'}) {
		# try to read the tuning file if it exists
		my ($workdir, $file) = &workdir($self->{'file'});
		my $tune_file = $workdir . '/.ws_' . $file;
		$Glob_Args{_Tuning_File} = $tune_file;

		Debug "Checking for file $tune_file\..." if $self->{'debug'};
		if (-e $tune_file) {
			# use existing tuning file
			Debug "Opening $tune_file\..." if $self->{'debug'};
			open(TUNE_INPUT, $tune_file);
			while(<TUNE_INPUT>) {
				chomp;
				my ($nr, $var) = split /\t/;
				$Tune_Output{$nr} = $var;
			}
			close TUNE_INPUT;
			@Parse_Lines = sort keys %Tune_Output;
			$Glob_Args{_Lo_Row} = $Parse_Lines[0] || 0;
			$Glob_Args{_Hi_Row} = $Parse_Lines[$#Parse_Lines];
			my $row = 0;
			open(WS_F, $self->{'file'});
			while(<WS_F>) {
				print $_ if $row++ < $Glob_Args{_Lo_Row};
			}
			close WS_F;
			$Glob_Args{_Tune_File_Exists} = 1;
		}
		else {
			Debug "$tune_file does not exist" if $self->{'debug'};
		}
	}

	$Glob_Args{_Lo_Row} ||= 0; 
	$Glob_Args{_Hi_Row} ||= 0; 

	bless $self, $type;
}

sub print {

	my $self = shift;
	my %Params = @_;

	$Params{'save_as'} ||= $self->{'save_as'};
	$Params{'save_as'} ||= ""; # prevent warning!

	unless ($Params{'save_as'}) {
		print "Content-type: text/html\n\n" unless $Params{'contentType_is_set'};
		$contentType = 1;
	}

	my $time = scalar localtime;

	if ($Params{'save_as'}) {
		Debug "Saving as '" . $Params{'save_as'} . "'...." if $self->{'debug'};
		open(SAVE, ">$Params{'save_as'}") or Error "E1001: $Params{'save_as'} $!";
	}

	my $flag_print = 1;

	my $start_seq = $self->{'start_seq'} || '{{';
	my $stop_seq  = $self->{'stop_seq' } || '}}';

	$begin_block = '<!-- ' . $start_seq . 'BLOCK ';
	$end_block   = '<!-- ' . $start_seq  . 'END'   ;

	if ($self->{'debug'}) {
		Debug "begin_block = $begin_block";
		Debug "end_block = $end_block";
		Debug "tuning $_" foreach keys %Glob_Args;
	}

	if ($Glob_Args{'output'} && !$Glob_Args{_Tune_File_Exists}) {
		Debug "Creating $Glob_Args{_Tuning_File}\..." if $self->{'debug'};
		open(TUNING, ">$Glob_Args{_Tuning_File}") or Debug $!;
	}
	else {
		Debug "I don't create a tuning file..." if $self->{'debug'};
	}

	open(WS_F, $self->{'file'}) or Error "E1000: $self->{'file'} $!";

	my $rowcount = 0;

	if ($Glob_Args{_Lo_Row}) {
		# move file forward
		Debug "Moving fast forward...!" if $self->{'debug'};
		while (<WS_F>) {
			last if ++$rowcount > $Glob_Args{_Lo_Row} - 1;
		}
	}

	while(<WS_F>) {
		if (/$begin_block/) {
			$flag_print = 0; # default!
			my $block_name = (split /$begin_block/)[1];
			   $block_name = (split /$stop_seq/, $block_name)[0];

			# Dynamically row(s)
			if (defined $Glob_Args{"BLOCK_$block_name"}) {
				my $rowline = <WS_F>;
				my $start_seq = $self->{'start_seq'} || '{{';
				my $stop_seq  = $self->{'stop_seq' } || '}}';
				my @varcount = split /$start_seq/, $rowline;

				my $var_counter = 0;
				foreach (keys %Glob_Args) {
					next unless /^BLOCK_$block_name/;
					s/^BLOCK_(.+)$/$1/; my $blockname = $_;
					my $rowline_dynamic = $rowline;
					foreach (sort keys %Var) {
						next unless /^_$blockname\t/;
						my $keyname = (split /\t/)[2];
						$rowline_dynamic =~ s/$start_seq$keyname$stop_seq/$Var{$_}/;
						if ($var_counter++ > ($#varcount -2)) {
							# rowline is now completely rendered
							print $rowline_dynamic;
							$var_counter = 0;
							$rowline_dynamic = $rowline; # reset pattern
						}
					}
				}
			}

			Debug "begin_block $block_name" if $self->{'debug'};

			foreach (@block_names) {
				$flag_print = $print_block{$block_name} 
						if $_ eq $block_name;
			}
		}

		if (/$end_block/) { $flag_print = 1 }

		if ($flag_print) {
			# make replacements and print out
			my $start_seq = $self->{'start_seq'} || '{{';
			my $stop_seq  = $self->{'stop_seq' } || '}}';

			next if /^<!-- $start_seq/; # X NEW

			my $next = 0;
			   $next = 1 if /^<!-- .+ -->$/; # Suppress free comment lines
			   $next = 0 if /^<!-- {{.+}} -->/;
			   next if $next;

			foreach my $Key (keys %Var) {
				my $to_be_replaced = 0;
				if ($Glob_Args{'output'}) {
					$to_be_replaced = 1 if /$start_seq/;
				}

				s/$start_seq$Key$stop_seq/$Var{$Key}/g;

				if ($Glob_Args{'output'}) {
					unless ($Glob_Args{_Lo_Row}) {
						print TUNING 
						sprintf("%08d", $rowcount), "\t$Key\n"
						if $_ !~ /$start_seq/ && $to_be_replaced;
					}
				}
			}

			next if /{%.+%}$/; # supress unresolved lines

			$Params{'save_as'} ? print SAVE : print;
		}
		$rowcount++;

		if ($Glob_Args{_Tune_File_Exists}) {
			next if $#Parse_Lines < 1;
			if ($rowcount > $Parse_Lines[0]) {
				@Parse_Lines = @Parse_Lines[1 .. $#Parse_Lines];
				# At line $rowcount, we will just output the file
				# until we reach line number $Parse_Lines[0] - 2
				while (<WS_F>) {
					last if $rowcount++ > $Parse_Lines[0] - 2;
					print;
				}
				foreach my $Key (keys %Var) {
					s/$start_seq$Key$stop_seq/$Var{$Key}/g;
				}
				print;
			}
		}

		if ($Glob_Args{'output'} && $Glob_Args{_Lo_Row}) {
			last if $rowcount > $Glob_Args{_Hi_Row};
		}

	} # end while

	if ($Glob_Args{'output'}) {
		print while <WS_F>;
	}

	close WS_F;
	close TUNING
		if $Glob_Args{'output'} && !$Glob_Args{_Tune_File_Exists};

	if ($Params{'save_as'}) {
		print SAVE qq~
		<!-- 
		Generated by :  $package V$VERSION
		          at :  $time
		        file :  $self->{'file'}
		     save_as :  $Params{'save_as'}
		you could prevent this output with quiet
		 -->
		~, "\n" unless $Params{'quiet'};
		close SAVE ;
	}
	else {
		unless ($Params{'quiet'}) {
		print qq~
		<!-- 
		Generated by :  $package V$VERSION
		          at :  $time
		        file :  $self->{'file'}
		     save_as :  $Params{'save_as'}
		you could prevent this output with quiet
		 -->
		~, "\n" unless $Params{'quiet'};
		}
	}
}

sub let {
	my $self = shift;

	my $Key   = shift;
	my $Value = shift;
	my $Block = shift || '';

	Debug "$Key = $Value" if $self->{'debug'};

	if ($Block) {
		$Var{"_$Block\t" . sprintf("%08d", $Glob_Args{"BLOCK_$Block"}++) . "\t$Key"} = $Value;
	}
	else {
		$Var{$Key} = $Value;
	}
}

sub block ($$@) {
	my $self = shift;
	my $block_name = shift;
	my %block_args = @_;

	push @block_names, $block_name;
	$print_block{$block_name} = $block_args{'print'};
}

sub workdir ($) {
	my $dir_separator = '/'; # ZZ change this to \ on windows
	my @elems = split /$dir_separator/, $_[0];

	((join $dir_separator, @elems[0 .. $#elems - 1]), $elems[$#elems]);
}

####  Error  #################################################
sub Error ($) {
	print "Content-type: text/html\n\n" unless $contentType;
	print "<b>ERROR</b> ($package): $_[0]\n";
	exit(1);
}

####  Debug  ###################################################
sub Debug ($)  {
	print "Content-type: text/html\n\n" unless $contentType; $contentType++;
	print "<b>[ $package ]</b> $_[0]<br>\n";
}

############################################################
####  Used Warning / Error Codes  ##########################
############################################################
#	Next free W Code: 1000
#	Next free E Code: 1002

1;

__END__

=head1 NAME

Website - Perl extension for as engine to render template-driven applications, 
designed to run quickly in CGI and mod_perl environments

=head1 SYNOPSIS

  use Website;

  my $Website = Website->new( file => 'website-tpl.htm' );

  $Website->let('firstname', 'Reto');
  $Website->let('lastname' , 'Hersiczky');
  $Website->block('demoBlock', print => $ENV{QUERY_STRING} eq 'block=1' ? 1 : 0);

  $Website->print(
	contentType_is_set => 0 ,
	quiet              => 1
  );

  [or]
  my $Website = Website->new(
        file   => 'test.htm',
        tuning => [qw( output speed pretty cache compress )] ,
        debug  => 1
  );


  # ----------------------------------------------
  # -- Extended filling into iterative table rows:
  # ----------------------------------------------

  # Populate three records
	my @table_data = (
		"John	Doe	Washington"	,
		"Foo	Bar	Neverland"	,
		"Tiger	Woods	Florida"	,
		"Stars	Stripes	Bruetten"	,
	);

	my $Website = Website->new(
		file => '/usr/lib/perl5/site_perl/ModPerl/website-tpl.htm' );

	$Website->let('firstname', $q->{'firstname'} );
	$Website->let('lastname' , $q->{'lastname' } );
	$Website->block('demoBlock', print => $q->{'block'} == 1 ? 1 : 0);

	my $i = 0;
	my @rowcolors = ('#e0e0e0', 'white');

	foreach (@table_data) {
		my ($firstname, $lastname, $place) = split /\t/;

		$Website->let('bcol', $rowcolors[$i++ % 2], 'tableRow');

		# -- Assign values to data cells (one table row)
		$Website->let('firstname', $firstname, 'tableRow');
		$Website->let('lastname',  $lastname , 'tableRow');
		$Website->let('place'   ,  $place    , 'tableRow');
	}


	$Website->print( contentType_is_set => 1, quiet => 1 );

=head1 DESCRIPTION

Documentation for Website, please visit http://www.infocopter.com/perl/website-pm.htm

=head2 EXPORT

None by default.


=head1 AUTHOR

Reto Hersiczky, E<lt>retoh@dplanet.chE<gt>

=head1 SEE ALSO

L<perl>.

=cut
