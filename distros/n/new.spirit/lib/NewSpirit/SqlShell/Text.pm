package NewSpirit::SqlShell::Text;
use vars qw ( @ISA );

@ISA = qw( NewSpirit::SqlShell );

use strict;
use NewSpirit::SqlShell;
use Text::Wrap;

sub get_verbose			{ shift->{verbose}			}
sub set_verbose			{ shift->{verbose}		= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my ($verbose) = @par{'verbose'};

	$verbose = 1 if not defined $verbose;

	my $self = $class->SUPER::new(@_);
	
	$self->set_verbose($verbose);
	
	return $self;
}

sub print_current_command {
	my $self = shift;

	return if not $self->{echo};

	print "\n";
	
	my $print_command = $self->{current_command};
	
	$print_command = "> $print_command";
	$print_command =~ s!\n!\n> !g;
	
	print "$print_command\n\n";

	1;
}

sub print_query_result_start {
	my $self = shift;
	
	my %par = @_;
	
	my $title_lref = $par{title_lref};
	
	$self->{__query_row_lref}     = [];
	$self->{__query_row_len_lref} = [];
	
	$self->add_query_row ($title_lref);
	
	1;
}

sub add_query_row {
	my $self = shift;
	
	my ($lref) = @_;
	
	push @{$self->{__query_row_lref}}, $lref;
	
	my $i = 0;
	foreach my $col (@{$lref}) {
		$self->{__query_row_len_lref}->[$i] = length($col)
			if length($col) > $self->{__query_row_len_lref}->[$i];
		++$i;
	}
}

sub print_query_result_row {
	my $self = shift;
	
	my %par = @_;
	
	my $row_lref = $par{row_lref};
	$self->add_query_row ($row_lref);
	
	1;
}

sub print_query_result_end {
	my $self = shift;
	
	#-------------------------------------------------------------
	# Ok, now - at the end - we print the whole collected
	# result set. We know the max width of all columns and
	# are able to produce a nice looking table layout.
	#
	# $self->{__query_row_len_lref}
	#	Holds the maximum widths of the corresponding
	#	columns
	#
	# $self->{__query_row_lref}
	#	Holds all the data. The titles of our columns
	#	are storied at index 0, the data begins with
	#	index 1.
	#-------------------------------------------------------------

	my $style = $self->get_preference ('display_style');
	
	if ( $style eq 'row' ) {
		$self->print_query_result_end_row_style;
	} elsif ( $style eq 'boxed' ) {
		$self->print_query_result_end_boxed_style;
	} elsif ( $style eq 'tab' ) {
		$self->print_query_result_end_tab_style;
	} else {
		# automatic detection
		my $length = 2;
		foreach my $l ( @{$self->{__query_row_len_lref}} ) {
			$length += $l + 3;
		}
		my $screen_width = $self->get_screen_width;
		if ( $length > $screen_width ) {
			$self->print_query_result_end_boxed_style;
		} else {
			$self->print_query_result_end_row_style;
		}
	}
}

sub print_query_result_end_row_style {
	my $self = shift;
	
	my $line   = '';

	my $len_lref = $self->{__query_row_len_lref};

	return if not $self->{__query_row_lref} or
	          not @{$self->{__query_row_lref}};

	foreach my $len ( @{$len_lref} ) {
		$line   .= "+-".("-" x $len)."-";
	}
	$line .= "-+\n";
	
	my $cnt = 0;
	foreach my $row ( @{$self->{__query_row_lref}} ) {
		print $line if $cnt == 0;
		my $i = 0;
		foreach my $col ( @{$row} ) {
			printf ("| %-$len_lref->[$i]s ", $col);
			++$i;
		}
		print " |\n";
		print $line if $cnt == 0;
		++$cnt;
	}

	print $line, "\n";
	
	$self->{__query_row_lref}     = [];
	$self->{__query_row_len_lref} = [];
	
	1;
}

sub print_query_result_end_boxed_style {
	my $self = shift;
	
	my $len_lref   = $self->{__query_row_len_lref};
	my $data_lref  = $self->{__query_row_lref};
	my $title_lref = $data_lref->[0];

	return if not $self->{__query_row_lref} or
	          not @{$self->{__query_row_lref}};
	
	# first compute max length of column titles
	my $title_length = 0;
	foreach my $l ( @{$data_lref->[0]} ) {
		$title_length = length($l) if length($l) > $title_length;
	}
	
	# now compute max length of data columns
	my $data_length = 0;
	foreach my $l ( @{$len_lref} ) {
		$data_length = $l if $l > $data_length;
	}

	my $screen_width = $self->get_screen_width;

	if ( $screen_width < $title_length+$data_length+7 ) {
		$data_length = $screen_width - $title_length - 7;
	}

	my $line   = '';
	foreach my $len ( $title_length, $data_length ) {
		$line   .= "+-".("-" x $len)."-";
	}
	$line .= "+\n";
	
	my $cnt = 0;
	foreach my $row ( @{$data_lref} ) {
		++$cnt;
		next if $cnt == 1;	# skip titles

		print $line;
		my $i = 0;
		foreach my $col ( @{$row} ) {
			if ( length($col) > $data_length ) {
				my $title = $title_lref->[$i];
				while ( $col =~ m/(.{0,$data_length})\n?/g and $1 ) {
					printf (
						"| %-${title_length}s | %-${data_length}s |\n",
						$title, $1
					);
					$title = '';
				}
			} else {
				printf (
					"| %-${title_length}s | %-${data_length}s |\n",
					$title_lref->[$i], $col
				);
			}
			++$i;
		}
		print $line;
		print "\n";
		++$cnt;
	}

	$self->{__query_row_lref}     = [];
	$self->{__query_row_len_lref} = [];
	
	1;
}

sub print_query_result_end_tab_style {
	my $self = shift;
	
	return if not $self->{__query_row_lref} or
	          not @{$self->{__query_row_lref}};

	foreach my $row ( @{$self->{__query_row_lref}} ) {
		print join ("\t", map { s/\t/\\t/g; s/\n/\\n/g; $_ } @{$row}),"\n";
	}
	
	$self->{__query_row_lref}     = [];
	$self->{__query_row_len_lref} = [];
	
	1;
}

sub print_error {
	my $self = shift;

	my ($msg, $comment) = @_;

	print STDERR "ERROR: $msg\n";
	print STDERR "       $comment\n" if $comment;
	
	1;
}

sub info {
	my $self = shift;
	return if not $self->get_verbose;	
	my @p = @_;
	print STDERR "% ", join ("\n%> ", map { s/\n/\n%> /g; $_ } @p ), "\n";
	1;
}

sub error_summary {
	my $self = shift;
	
	return if not @{$self->{errors}};

	$self->info ("Error Summary:",
		     "--------------");
	$self->info ("Found ".@{$self->{errors}}." errors!");
	print "\n";
	
	my $num = 0;
	foreach my $err ( @{$self->{errors}} ) {
		++$num;
		$self->info (
			wrap ("CMD:\t", "\t",$err->{command}."\n"),
			wrap ("MSG:\t", "\t",$err->{msg})
		);
		print "\n";
	}
}

sub print_help_header {
	my $self = shift;
	
	print "Help Page:\n";
	print "==========\n\n";
}

sub print_help_footer {
	my $self = shift;
	
	print "\n";
}

sub cmd_reload {
	my $self = shift;
	
	$self->SUPER::cmd_reload;

	$self->info ("reloading NewSpirit::SqlShell::Text");
	do "NewSpirit/SqlShell/Text.pm";
}

sub get_screen_width {
	my $self = shift;
	
	# $data_length must be smaller than pref:screen_width
	my $screen_width = $self->get_preference('screen_width');
	
	if ( not $screen_width ) {
		# autosize
		eval {
			require Term::ReadKey;
			($screen_width) = Term::ReadKey::GetTerminalSize();
		};
		if ( $@ ) {
			$self->info ("Warning: could not determine screen width! Set to 79.");
			$screen_width = 79;
		}
	}

	return $screen_width;
}


