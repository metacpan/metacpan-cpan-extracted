#!/usr/bin/perl
# ABSTRACT: helper module to automate the use of Text::CSV

# vim:tw=100

# Text/AutoCSV.pm

#
# Written by Sébastien Millet
#   March, July, August, September 2016
#   January, February 2017
#

package Text::AutoCSV;
$Text::AutoCSV::VERSION = '1.1.8';
my $PKG = "Text::AutoCSV";

use strict;
use warnings;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(remove_accents);

use Carp;
use Params::Validate qw(validate validate_pos :types);
use List::MoreUtils qw(first_index indexes);
use Fcntl qw(SEEK_SET);
use File::BOM;
use Text::CSV;
use DateTime;
	# DateTime::Format::Strptime 1.70 does not work properly with us.
	# Actually all version as of 1.63 are fine, except 1.70.
use DateTime::Format::Strptime 1.71;
use Class::Struct;
use Unicode::Normalize;
	# lock_keys is used to prevent accessing non existing keys
	# Credits: 3381159 on http://stackoverflow.com
	#          "make perl shout when trying to access undefined hash key"
use Hash::Util qw(lock_keys);

	# FIXME
	# Not needed in release -> should be always commented unless at dev time
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

	# Set to 1 if you wish to turn on debug without touching caller's code
our $ALWAYS_DEBUG = 0;

	# Keep it set to 0 unless you know what you're doing!
	# Note
	#   Taken into account only if debug is set.
my $DEBUG_DATETIME_FORMATS = 0;
	# The below is taken into account only if $DEBUG_DATETIME_FORMATS is set.
	# It'll resqult in even more debug output. It becomes really MASSIVE debug output.
my $DEBUG_DATETIME_FORMATS_EVEN_MORE = 0;

	#
	# Uncomment to replace carp and croak with cluck and confess, respectively
	# Also reachable with perl option:
	#   -MCarp=verbose
	# See 'perldoc Carp'.
	#
#$Carp::Verbose = 1;


# * *************** *
# * BEHAVIOR TUNING *
# * *************** *


# * **************************************************** *
# * ALL THE VARIABLES BELOW ARE RATHER LOW LEVEL.        *
# * IF YOU UPDATE IT, IT WILL LIKELY BREAK THE TEST PLAN *
# * **************************************************** *

my $DEF_SEARCH_CASE = 0;                     # Case insensitive search by default
my $DEF_SEARCH_TRIM = 1;                     # Trim values by default
my $DEF_SEARCH_IGNORE_ACCENTS = 1;           # Ignore accents
my $DEF_SEARCH_IGNORE_EMPTY = 1;             # Ignore empty strings in searches by default
my $DEF_SEARCH_VALUE_IF_NOT_FOUND = undef;   # If not found, returned field value is undef
my $DEF_SEARCH_VALUE_IF_AMBIGUOUS = undef;   # If more than one record found by search (when a
                                             # unique value is expected), return undef
my $DEF_SEARCH_IGNORE_AMBIGUOUS = 1;         # By default, ignore the fact that multiple records are
                                             # found by search and return the first record found

my $DETECT_ENCODING = 1;

my $DEFAULT_IN_ENCODING = 'UTF-8,latin1';

	# By default, input encoding detected is used for output.
	# -> the constant below is used if and only if:
	#   Inbound encoding is unknown
	#   No providing of out_encoding attribute (out_encoding takes precedence when provided)
my $DEFAULT_OUT_ENCODING = 'UTF-8';

my $DEFAULT_ESCAPE_CHAR = '\\';
my $DEFAULT_QUOTE_CHAR = '"';

	#
	# The code that workarounds $FIX_PERLMONKS_823214 (see below) makes sense only under plain
	# Windows.
	#
	# "Plain" Windows?
	#   This code MUST NOT be executed under cygwin because cygwin uses unix line breaks. This is
	#   why we detect /mswin/. Would we detect /win/, we'd catch cygwin, too, and we don't want
	#   that.
	#
my $OS_IS_PLAIN_WINDOWS = !! ($^O =~ /mswin/i);

	#
	# Shall we fix the issue reported as #823214 in PerlMonks? See
	#   http://www.perlmonks.org/?node_id=823214
	#
	# In brief (in case the link above would be broken one day):
	#   Under Windows, output mode set to UTF-16LE produces line breaks made of octets "0d 0a 00",
	#   whereas it should be "0d 00 0a 00".
	#
	# The code also fixes UTF-16BE (but it was not tested).
	#
my $FIX_PERLMONKS_823214 = 1;


# * **** *
# * CODE *
# * **** *


sub ERR_UNKNOWN_FIELD() { 0 }

	# Store meta-data about each column
struct ColData => {
	field_name => '$',
	header_text => '$',
	description => '$',
	dt_format => '$',
	dt_locale => '$'
};

	#
	# Enumeration of ef_type member below
	# Alternative:
	#   use enum (...)
	#
	# But it is not also by default on my distro and installing a package for 3 constants, I find it
	# a bit overkill!
	#
my ($EF_LINK, $EF_FUNC, $EF_COPY) = 0..2;
struct ExtraField => {
	ef_type => '$',
	self_name => '$',
	description => '$',

	check_field_existence => '$',

# For when ef_type is set to $EF_LINK

	link_self_search => '$',
	link_remote_obj => '$',
	link_remote_search => '$',
	link_remote_read => '$',
	link_vlookup_opts => '%',

# For when ef_type is set to $EF_FUNC

	func_sub => '$',

# For when ef_type is set to $EF_COPY

	copy_source => '$',
	copy_sub => '$'

};

my $SEARCH_VALIDATE_OPTIONS = {
	value_if_not_found => {type => UNDEF | SCALAR, optional => 1},
	value_if_found => {type => UNDEF | SCALAR, optional => 1},
	value_if_ambiguous => {type => UNDEF | SCALAR, optional => 1},
	ignore_ambiguous => {type => BOOLEAN, optional => 1},
	case => {type => BOOLEAN, optional => 1},
	trim => {type => BOOLEAN, optional => 1},
	ignore_empty => {type => BOOLEAN, optional => 1},
	ignore_accents => {type => BOOLEAN, optional => 1}
};

sub _is_utf8 {
	my $e = shift;

	return 1 if $e =~ m/^(utf-?8|ucs-?8)/i;
	return 0;
}

	# To replace // in old perls: return the first non-undef value in provided list
sub _get_def {
	for (@_) {
		return $_ if defined($_);
	}
	return undef;
}

sub _print {
	my $self = shift;
	my $t = shift;

	my $infoh = $self->{infoh};
	return if ref $infoh ne 'GLOB';

	print($infoh $t);
}

sub _printf {
	my $self = shift;

	my $infoh = $self->{infoh};
	return if ref $infoh ne 'GLOB';

	printf($infoh @_);
}

sub _print_warning {
	my $self = shift;
	my $warning_message = shift;
	my $dont_wrap = shift;

	my $msg = ($dont_wrap ? $warning_message : "$PKG: warning: $warning_message");
	carp $msg unless $self->{quiet};
}

sub _close_inh {
	my $self = shift;

	close $self->{_inh} if $self->{_close_inh_when_finished};
	$self->{_inh} = undef;
	$self->{_close_inh_when_finished} = undef;
}

sub _close_outh {
	my $self = shift;

	close $self->{outh} if defined($self->{outh}) and $self->{_close_outh_when_finished};
	$self->{outh} = undef;
	$self->{_close_outh_when_finished} = undef;
}

sub _print_error {
	my ($self, $error_message, $dont_stop, $err_code, $err_extra) = @_;

	my $msg = "$PKG: error: $error_message";

	if (defined($err_code) and !$self->{quiet} and $self->{croak_if_error}) {
		if ($err_code == ERR_UNKNOWN_FIELD) {
			my %f = %{$err_extra};
			my @cols;
			for my $n (keys %f) {
				$cols[$f{$n}] = $n;
			}
			$self->_print($self->get_in_file_disp() . " column - field name correspondance:\n");
			$self->_print("COL #  FIELD\n");
			$self->_print("-----  -----\n");
			for my $i (0..$#cols) {
				$self->_printf("%05d  %s\n", $i, (defined($cols[$i]) ? $cols[$i] : ''));
			}
		} else {
			confess "Unknown error code: '$err_code'\n";
		}
	}

	if ($self->{croak_if_error} and !$dont_stop) {
		$self->_close_read(1);
		$self->_close_inh();
		$self->_close_outh();
		$self->_status_reset(1);
		croak $msg;
	}
	$self->_print_warning($msg, 1);
}

	#
	# Return the string passed in argument with all accents removed from characters.
	# Do it in a rather general and reliable way, not tied to latin1.
	# Tested on latin1 and latin2 character sets.
	#
	# Credits:
	#   http://stackoverflow.com/questions/17561839/remove-accents-from-accented-characters
	#
sub remove_accents {
	validate_pos(@_, {type => SCALAR});

	my $s = $_[0];
	my $r = NFKD($s);
	$r =~ s/\p{Nonspacing_Mark}//g;
	return $r;
}

sub _detect_csv_sep {
my $ST_OUTSIDE = 0;
my $ST_INSIDE = 1;

	my ($self, $escape_char, $quote_char, $sep) = @_;

	my $_debugh = $self->{_debugh};
	my $inh = $self->{_inh};
	my $_debug = $self->{_debug};

	delete $self->{_inh_header};

	$escape_char = $DEFAULT_ESCAPE_CHAR unless defined($escape_char);

	$self->_print_error("illegal \$escape_char: '$escape_char' (length >= 2)"), return 0
		if length($escape_char) >= 2;

	$self->_print_error("$PKG: error: illegal \$quote_char '$quote_char' (length >= 2)"), return 0
		if length($quote_char) >= 2;

	$escape_char = '--' if $escape_char eq '';
	$quote_char = '--' if $quote_char eq '';

		#  FIXME (?)
		# Avoid inlined magic values for separator auto-detection.
		# Issue is, as you can see below, the behavior is also hard-coded and not straightforward to
		# render 'tunable' ("," and ";" take precedence over "\t").
	my %Seps = (
		";" => 0,
		"," => 0,
		"\t" => 0
	);

	my $h = <$inh>;
	if ($self->{inh_is_stdin}) {
		$self->{_inh_header} = $h;
		print($_debugh "Input is STDIN => saving header line to re-read it " .
			"later (in-memory)\n") if $_debug;
	} else {
		seek $inh, 0, SEEK_SET;
		print($_debugh "Input is not STDIN => using seek function to rewind " .
			"read head after header line reading\n") if $_debug;
	}

	chomp $h;
	my $status = $ST_OUTSIDE;
	my $l = length($h);
	my $c = 0;
	while ($c < $l) {
		my $ch = substr($h, $c, 1);
		my $chnext = '';
		$chnext = substr($h, $c + 1, 1) if ($c < $l - 1);
		if ($status == $ST_INSIDE) {
			if ($ch eq $escape_char and $chnext eq $quote_char) {
				$c += 2;
			} elsif ($ch eq $quote_char) {
				$status = $ST_OUTSIDE;
				$c++;
			} else {
				$c++;
			}
		} elsif ($status == $ST_OUTSIDE) {
			if ($ch eq $escape_char and ($chnext eq $quote_char or
					exists $Seps{$chnext})) {
				$c += 2;
			} elsif (exists $Seps{$ch}) {
				$Seps{$ch}++;
				$c++;
			} elsif ($ch eq $quote_char) {
				$status = $ST_INSIDE;
				$c++;
			} else {
				$c++;
			}
		}
	}

	if ($Seps{";"} == 0 and $Seps{","} >= 1) {
		$$sep = ",";
		return 1;
	} elsif ($Seps{","} == 0 and $Seps{";"} >= 1) {
		$$sep = ";";
		return 1;
	} elsif ($Seps{","} == 0 and $Seps{";"} == 0 and $Seps{"\t"} >= 1) {
		$$sep = "\t";
		return 1;
	} else {

			# Check the case where there is one unique column, in which case,
			# assume comma separator.
		my $h_no_accnt = remove_accents($h);
		if ($h_no_accnt =~ m/^[[:alnum:]_]+$/i) {
			$$sep = ",";
			return 1;
		}

		$$sep = "";
		if ($_debug) {
			for my $k (keys %Seps) {
				print($_debugh "\$Seps{'$k'} = $Seps{$k}\n");
			}
		}
		return 0;
	}
}

sub _reopen_input {
	my $self = shift;

	my $in_file = $self->{in_file};

	my $inh;
	if (!open($inh, "<", $in_file)) {
		$self->_print_error("unable to open file '$in_file': $!");
		return undef;
	}
	if (!$self->{_leave_encoding_alone}) {

		confess "Oups! _inh_encoding_string undef?"
			unless defined($self->{_inh_encoding_string});

		binmode $inh, $self->{_inh_encoding_string};
	}

	return $inh;
}

	# Abstraction layer, not useful Today, could bring added value when looking into Text::CSV I/O
sub _mygetline {
	my ($csvobj, $fh) = @_;

	return $csvobj->getline($fh);
}

sub _detect_escape_char {
	my ($self, $quote_char, $sep_char, $ref_escape_char, $ref_is_always_quoted) = @_;

	my $in_file = $self->{in_file};
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	$$ref_escape_char = $DEFAULT_ESCAPE_CHAR;
	$$ref_is_always_quoted = undef;

	if ($self->{_int_one_pass}) {
		return;
	}

	$self->_register_pass("detect escape character");

	my $qesc = 0;
	my $inh = $self->_reopen_input();
	if (defined($inh)) {
		while (my $l = <$inh>) {
			chomp $l;

				# Very heuristic criteria...
				# Tant pis.
			$qesc = 1 if $l =~ m/(?<!$sep_char)$quote_char$quote_char(?!$sep_char)/;

		}
		close $inh;
	}
	if ($qesc) {
		$$ref_escape_char = '"';
	} else {
		$$ref_escape_char = '\\' ;
	}

	my $is_always_quoted = 0;
	$inh = $self->_reopen_input();
	if (defined($inh)) {
		my $csv = Text::CSV->new({sep_char => $sep_char,
			allow_whitespace => 1, binary => 1, auto_diag => 0,
			quote_char => $quote_char, escape_char => $$ref_escape_char,
			keep_meta_info => 1,
			allow_loose_escapes => 1});
		$is_always_quoted = 1;
		while (my $ar = _mygetline($csv, $inh)) {
			my @a = @{$ar};
			my $e = $#a;
			for my $i (0..$e) {
				$is_always_quoted = 0 unless $csv->is_quoted($i);
			}
			last unless $is_always_quoted;
		}
		my $is_ok = ($csv->eof() ? 1 : 0);
		close $inh;
	}

	print($_debugh "  is_always_quoted: $is_always_quoted\n") if $_debug;
	$$ref_is_always_quoted = $is_always_quoted;

	return;
}

sub _register_pass {
	my ($self, $pass_name) = @_;
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	$self->{_pass_count}++;

	return unless $_debug;

	print($_debugh "Pass #" . $self->{_pass_count} . " ($pass_name) done\n");
}

sub _update_in_mem_record_count {
	my ($self, $nonexistent_arg) = @_;
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	confess "Hey! what is this second argument?" if defined($nonexistent_arg);

	my $new_count = $#{$self->{_flat}} + 1;

	my $updated_max = 0;
	if ($new_count > $self->get_max_in_mem_record_count()) {
		$self->_set_max_in_mem_record_count($new_count);
		$updated_max = 1;
	}

	$self->{_in_mem_record_count} = $new_count;
	if ($_debug) {
		print($_debugh "_in_mem_record_count updated, set to $new_count");
		print($_debugh " (also updated max)") if $updated_max;
		print($_debugh "\n");
	}
}

sub _detect_inh_encoding {
	my ($self, $enc, $via, $in_file, $detect_enc) = @_;
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	$enc = $DEFAULT_IN_ENCODING if !defined($enc) or $enc eq '';

	my @encodings = split(/\s*,\s*/, $enc);

	confess "Oups! No encoding to try?" if $#encodings < 0;

	print($_debugh "[ST] _detect_inh_encoding(): start\n") if $_debug;

	my $wrn = 0;
	my $m;
	my $m0;
	my $ee;
	for my $e (@encodings) {
		$ee = $e;
		my $viadef = _get_def($via, '');
		$m = ":encoding($e)$viadef";
		$m0 = $m unless defined($m0);

		last unless $detect_enc;

		confess "Oups! in_file not defined?" if !defined($in_file) or $in_file eq '';

		print($_debugh "   Checking encoding '$e' / '$m'\n") if $_debug;
		$wrn = 0;

		$self->_register_pass("check $e encoding");

		my $utf8_bom = 0;
		if (_is_utf8($e)) {
			if (open my $fh, '<:raw', $in_file) {
				my $bom;
				read $fh, $bom, 3;
				if (length($bom) == 3 and $bom eq "\xef\xbb\xbf") {
					if (!defined($via)) {
						$m .= ":via(File::BOM)";
					}
				}
				close $fh;
			}
		}

		my $inh;
		if (!open($inh, "<", $in_file)) {
			$self->_print_error("unable to open file '$in_file': $!");
			return ($encodings[0], $m0);
		}
		binmode $inh, $m;

# TURN OFF WARNINGS OUTPUT

		{
			local $SIG{__WARN__} = sub {
				$wrn++;
					# Uncomment only for debug!
					# Otherwise you'll get quite a good deal of output at each execution :-)
#                print(STDERR @_);
			};
			while (<$inh>) { }
		}

# WARNINGS ARE BACK ON

		close $inh;
		print($_debugh "     '$m' counts $wrn warning(s)\n") if $_debug;

		last if $wrn == 0;
	}

	if ($wrn >= 1) {
		$self->_print_warning("encoding warnings encountered during initial check, " .
			"using '$encodings[0]'");
		return ($encodings[0], $m0);
	}

	confess "Oups! undef encoding string?" unless defined($m);

	print($_debugh "   Detected encoding string '$ee' / '$m'\n") if $_debug;
	return ($ee, $m);
}

	#
	# Each of these functions brings status to the next value (current status + 1).
	# Each of these functions returns 0 if an error occured, 1 if all good
	#
my @status_forward_functions = (
	"_S1_init_input",              # To go from S0 to S1
	"_S2_init_fields_from_header", # To go form S1 to S2
	"_S3_init_fields_extra",       # To go from S2 to S3
	"_S4_read_all_in_mem",         # To go from S3 to S4
);

sub _status_reset {
	my $self = shift;

	validate_pos(@_, {type => SCALAR, optional => 1});
	my $called_from_print_error = _get_def($_[0], 0);

	if (defined($self->{_status}) and $self->{_status} == 4) {
		unless ($called_from_print_error) {
			my $msg = "in-memory CSV content discarded, will have to re-read input";
			$self->_print_warning($msg);
		}
		$self->{_flat} = [ ];
		$self->_update_in_mem_record_count();
	}

	$self->{_status} = 0;
	return 0 if $called_from_print_error;
	return $self->_status_forward('S1');
}

sub _status_forward {
	my $self = shift;

	return $self->___status_move(@_, 1);
}

sub _status_backward {
	my $self = shift;

	return $self->___status_move(@_, -1);
}

	# You should not call ___status_move() in the code, that is why the name is prefixed with 3
	# underscores! Only _status_forward and _status_backward should call it.
sub ___status_move {
	my ($self, $target, $step) = @_;

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	if (!defined($step) or ($step != -1 and $step != 1)) {
		confess "Oups! \$step has a wrong value: '$step'";
	}

	my $n;
	confess "Oups! illegal status string: '$target'" unless ($n) = $target =~ m/^S(\d)$/;

	if ($self->{_read_in_progress}) {
		$self->_print_error("illegal call while read is in progress, " .
			"would lead to infinite recursion", 0);
		confess "Aborted.";
	}

	if ($step == -1) {
		if ($n < $self->{_status}) {
			if ($self->{_status} == 4) {
				print($_debugh "[ST] Requested status $n but will go to status 0\n") if $_debug;
				return $self->_status_reset();
			}
			$self->{_status} = $n ;
			print($_debugh "[ST] New status: ". $self->{_status} . "\n") if $_debug;
		}
		return 1;
	}

	if ($self->{_status} < $n) {
		print($_debugh "[ST] Current status: ". $self->{_status} . "\n") if $_debug;
	}

	if ($self->{_status} <= 1 and $n >= 2 and $self->{_int_one_pass} and
			$self->get_pass_count() >= 1) {
		my $msg = "one_pass set, unable to read input again";
		$self->_print_error($msg), return 0 if $self->{one_pass};
		$self->_print_warning($msg) if !$self->{one_pass};
	}

	while ($self->{_status} < $n) {

		my $funcname = $status_forward_functions[$self->{_status}];
		confess "Oups! Unknown status?" unless defined($funcname);

		print($_debugh "[ST] Now executing $funcname\n") if $_debug;

		if (my $member_function = $self->can($funcname)) {
			return 0 unless $self->$member_function();
		} else {
			confess "Could not find method $funcname in $PKG!";
		}

		$self->{_status} += $step;
		print($_debugh "[ST] New status: ". $self->{_status} . "\n") if $_debug;
	}

	return 1;
}

sub new {
	my ($class, @args) = @_;

	@args = validate(@args,
		{   in_file => {type => SCALAR, optional => 1},
			infoh => {type => UNDEF | GLOBREF, default => \*STDERR, optional => 1},
			verbose => {type => BOOLEAN, default => 0, optional => 1},
			quiet => {type => BOOLEAN, optional => 1},
			croak_if_error => {type => BOOLEAN, default => 1, optional => 1},
			inh => {type => GLOBREF, optional => 1},
			in_csvobj => {type => OBJECT, optional => 1},
			sep_char => {type => SCALAR, optional => 1},
			quote_char => {type => SCALAR, optional => 1},
			escape_char => {type => SCALAR, optional => 1},
			has_headers => {type => BOOLEAN, default => 1, optional => 1},
			out_has_headers => {type => UNDEF | BOOLEAN, default => undef, optional => 1},
			fields_ar => {type => ARRAYREF, optional => 1},
			fields_hr => {type => HASHREF, optional => 1},
			fields_column_names => {type => ARRAYREF, optional => 1},
			search_case => {type => SCALAR, optional => 1},
			search_trim => {type => SCALAR, optional => 1},
			search_ignore_empty => {type => SCALAR, optional => 1},
			search_ignore_accents => {type => SCALAR, optional => 1},
			search_ignore_ambiguous => {type => SCALAR, optional => 1},
			search_value_if_not_found => {type => SCALAR, optional => 1},
			search_value_if_found => {type => SCALAR, optional => 1},
			search_value_if_ambiguous => {type => SCALAR, optional => 1},
			walker_hr => {type => CODEREF, optional => 1},
			walker_ar => {type => CODEREF, optional => 1},
			read_post_update_hr => {type => CODEREF, optional => 1},
			write_filter_hr => {type => CODEREF, optional => 1},
			out_filter => {type => CODEREF, optional => 1},
			write_fields => {type => ARRAYREF, optional => 1},
			out_fields => {type => ARRAYREF, optional => 1},
			out_file => {type => SCALAR, optional => 1},
			out_always_quote => {type => BOOLEAN, optional => 1},
			out_sep_char => {type => SCALAR, optional => 1},
			out_quote_char => {type => SCALAR, optional => 1},
			out_escape_char => {type => SCALAR, optional => 1},
			out_dates_format => {type => SCALAR, optional => 1},
			out_dates_locale => {type => SCALAR, optional => 1},
			encoding => {type => SCALAR, optional => 1},
			via => {type => SCALAR, optional => 1},
			out_encoding => {type => SCALAR, optional => 1},
			dont_mess_with_encoding => {type => BOOLEAN, optional => 1},
			one_pass => {type => BOOLEAN, optional => 1},
			no_undef => {type => BOOLEAN, optional => 1},
			fields_dates => {type => ARRAYREF, optional => 1},
			fields_dates_auto => {type => BOOLEAN, optional => 1},
			dates_formats_to_try => {type => ARRAYREF, optional => 1},
			dates_formats_to_try_supp => {type => ARRAYREF, optional => 1},
			dates_ignore_trailing_chars => {type => BOOLEAN, optional => 1},
			dates_search_time => {type => BOOLEAN, optional => 1},
			dates_locales => {type => SCALAR, optional => 1},
			out_utf8_bom => {type => SCALAR, optional => 1},
			dates_zeros_ok => {type => SCALAR, default => 1, optional => 1},
			_debug => {type => BOOLEAN, default => 0, optional => 1},
			_debug_read => {type => BOOLEAN, default => 0, optional => 1},
			_debug_extra_fields => {type => BOOLEAN, optional => 1},
			_debugh => {type => UNDEF | GLOBREF, optional => 1}
		}
	);

	my $self = { @args };

	my @fields = keys %{$self};

# croak_if_error

	my $croak_if_error = $self->{croak_if_error};

# verbose and _debug management

	$self->{_debugh} = $self->{infoh} if !defined($self->{_debugh});
	$self->{_debug} = 1 if $ALWAYS_DEBUG;
	my $_debug = $self->{_debug};
	$self->{verbose} = 1 if $_debug;
	my $verbose = $self->{verbose};

	my $_debugh = $self->{_debugh};

	bless $self, $class;

# fields_ar, fields_hr

	if (defined($self->{fields_ar}) +
			defined($self->{fields_hr}) +
			defined($self->{fields_column_names})
		>= 2) {
		$self->_print_error("mixed use of fields_ar, fields_hr and fields_column_names. " .
			"Use one at a time.");
	}
	if (defined($self->{fields_ar}) and !defined($self->{fields_hr})) {
		my @f = @{$self->{fields_ar}};
		my %h;
		for my $e (@f) {
			$h{$e} = "^$e\$";
		}
		$self->{fields_hr} = \%h;
	}
	if (!$self->{has_headers}) {
		if (defined($self->{fields_ar})) {
			$self->_print_error("fields_ar irrelevant if CSV file has no headers");
			return undef;
		}
		if (defined($self->{fields_hr})) {
			$self->_print_error("fields_hr irrelevant if CSV file has no headers");
			return undef;
		}
	}

# in_file or inh

	$self->{_flat} = [ ];

	$self->{_read_update_after_hr} = { };
	$self->{_write_update_before_hr} = { };

	$self->_update_in_mem_record_count();

	return undef unless $self->_status_reset();

	$self->_debug_show_members() if $_debug;

	if ($self->{dates_zeros_ok}) {
		$self->{_refsub_is_datetime_empty} = sub {
			my $v = $_[0];
			if ($v !~ m/[1-9]/) {
				return 1 if $v =~ m/^[^0:]*0+[^0:]+0+[^0:]+0+/;
			}
			return 0;
		}
	}

	return $self;
};

	#
	# Return 0 if error, 1 if all good
	#
	# Do all low level activities associated to input:
	#   I/O init
	#   Detect encoding
	#   Detect CSV separator
	#   Detect escape character
	#
sub _S1_init_input {
	my $self = shift;

	my $croak_if_error = $self->{croak_if_error};
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	$self->{in_file} = '' unless defined($self->{in_file});
	$self->{_close_inh_when_finished} = 0;

	$self->{_leave_encoding_alone} = $self->{dont_mess_with_encoding}
		if defined($self->{dont_mess_with_encoding});

	$self->{_int_one_pass} = _get_def($self->{one_pass}, 0);
	my $in_file_disp;


#
# LOW LEVEL INIT STEP 1 OF 4
#
# Manage I/O (= in most cases, open input file...)
#

	if (defined($self->{inh})) {
		$self->{_leave_encoding_alone} = 1 unless defined($self->{dont_mess_with_encoding});
		$in_file_disp = _get_def($self->{in_file}, '<?>');
		$self->{_int_one_pass} = 1 unless defined($self->{one_pass});
		$self->{_inh} = $self->{inh};
	} else {
		$self->{_leave_encoding_alone} = 0 unless defined($self->{dont_mess_with_encoding});
		my $in_file = $self->{in_file};
		my $inh;
		if ($in_file eq '') {
			$inh = \*STDIN;
			$self->{inh_is_stdin} = 1;
			$self->{_int_one_pass} = 1 unless defined($self->{one_pass});
			$in_file_disp = '<stdin>';
		} else {
			if (!open($inh, '<', $in_file)) {
				$self->_print_error("unable to open file '$in_file': $!");
				return 0;
			}
			$in_file_disp = $in_file;
			$self->{_close_inh_when_finished} = 1;
		}
		$self->{_inh} = $inh;
	}

	confess "Oups! in_file_disp not defined?" unless defined($in_file_disp);
	$self->{_in_file_disp} = $in_file_disp;


#
# LOW LEVEL INIT STEP 2 OF 4
#
# "Detection" of encoding
#
# WARNING
#   As explained in the manual, it is a very partial and limited detection...
#

	unless ($self->{_leave_encoding_alone}) {
		unless ($self->{_init_input_already_called}) {
			my ($e, $m) = $self->_detect_inh_encoding($self->{encoding}, $self->{via},
				$self->{in_file}, ($self->{_int_one_pass} ? 0 : $DETECT_ENCODING));
			$self->{_inh_encoding} = $e;
			$self->{_inh_encoding_string} = $m;
		}

		binmode $self->{_inh}, $self->{_inh_encoding_string};
		print($_debugh "Input encoding: '" . $self->{_inh_encoding} . "' / '" .
			$self->{_inh_encoding_string} . "'\n") if $_debug;

	}

	$self->{out_file} = '' unless defined($self->{out_file});


#
# LOW LEVEL INIT STEP 3 OF 4
#
# Detection of CSV separator and escape character
#

	my $sep_char;
	my $escape_char = $self->{escape_char};
	$self->{quote_char} = $DEFAULT_QUOTE_CHAR unless defined($self->{quote_char});
	my $quote_char = $self->{quote_char};
	unless (defined($self->{in_csvobj})) {
		if (defined($self->{sep_char})) {
			$sep_char = $self->{sep_char};
			print($_debugh "-- $in_file_disp: CSV separator set to \"") if $_debug;
		} else {
				# The test below (on _init_input_already_called) shoud be useless.
				# Left for the sake of robustness.
			unless ($self->{_init_input_already_called}) {
				if (!$self->_detect_csv_sep($escape_char, $quote_char, \$sep_char)) {
					$self->_print_error("'$in_file_disp': cannot detect CSV separator");
					return 0;
				}
				print($_debugh "-- $in_file_disp: CSV separator detected to \"") if $_debug;
				$self->{sep_char} = $sep_char;
			}
		}
		print($_debugh ($sep_char eq "\t" ? '\t' : $sep_char) . "\"\n") if $_debug;

		my $is_always_quoted;
		unless (defined($self->{escape_char})) {
			$self->_detect_escape_char($quote_char, $sep_char, \$escape_char, \$is_always_quoted);
			$self->{escape_char} = $escape_char;
			$self->{_is_always_quoted} = $is_always_quoted;
		}

		$self->{_in_csvobj} = Text::CSV->new({sep_char => $sep_char,
			allow_whitespace => 1, binary => 1, auto_diag => 0,
			quote_char => $quote_char, escape_char => $escape_char,
			allow_loose_escapes => 1});
		unless (defined($self->{_in_csvobj})) {
			$self->_print_error("error creating input Text::CSV object");
			return 0;
		}

	} else {
		$self->{_in_csvobj} = $self->{in_csvobj};
	}

	$self->{_init_input_already_called} = 1;

	return 1;
}

sub get_in_file_disp {
	my $self = shift;

	validate_pos(@_);

	my $in_file_disp = _get_def($self->{_in_file_disp}, '?');
	return $in_file_disp;
}

sub get_sep_char {
	my $self = shift;

	validate_pos(@_);

	return $self->{sep_char};
}

sub get_escape_char {
	my $self = shift;

	validate_pos(@_);

	return $self->{escape_char};
}

sub get_in_encoding {
	my $self = shift;

	validate_pos(@_);

	return _get_def($self->{_inh_encoding}, '');
}

sub get_is_always_quoted {
	my $self = shift;

	validate_pos(@_);

	return $self->{_is_always_quoted};
}

sub get_pass_count {
	my $self = shift;

	validate_pos(@_);

	return _get_def($self->{_pass_count}, 0);
}

sub get_in_mem_record_count {
	my $self = shift;

	validate_pos(@_);

	return ($self->{_in_mem_record_count}, 0);
}

sub get_max_in_mem_record_count {
	my $self = shift;

	validate_pos(@_);

	return _get_def($self->{_max_in_mem_record_count}, 0);
}

sub _set_max_in_mem_record_count {
	my $self = shift;

	validate_pos(@_, {type => SCALAR});

	$self->{_max_in_mem_record_count} = $_[0];
}

sub get_fields_names {
	my $self = shift;

	validate_pos(@_);

	return () unless $self->_status_forward('S3');
	return @{$self->{_columns}};
}

sub get_field_name {
	my $self = shift;

	validate_pos(@_, {type => SCALAR});

	my ($n) = @_;

	return undef unless $self->_status_forward('S3');
	return $self->{_columns}->[$n];
}

sub get_coldata {
	my $self = shift;

	validate_pos(@_);

	return () unless $self->_status_forward('S3');
	my @ret;
	for (@{$self->{_coldata}}) {
		push @ret, [
			$_->field_name,
			$_->header_text,
			$_->description,
			$_->dt_format,
			$_->dt_locale];
	}

	return @ret;
}

sub get_stats {
	my $self = shift;

	validate_pos(@_);

	return () unless defined($self->{_stats});
	return %{$self->{_stats}};
}

sub _debug_show_members {
	my ($self) = @_;
	my $_debugh = $self->{_debugh};
	my @a = @{$self->{fields_ar}} if defined($self->{fields_ar});
	my @c = @{$self->{fields_column_names}} if defined($self->{fields_column_names});
	my %h = %{$self->{fields_hr}} if defined($self->{fields_hr});

	print($_debugh "-- _debug_show_members() start\n");
	print($_debugh "   croak_if_error $self->{croak_if_error}\n");
	print($_debugh "   verbose        $self->{verbose}\n");
	print($_debugh "   _debug         $self->{_debug}\n");
	print($_debugh "   _debug_read    $self->{_debug_read}\n");
	print($_debugh "   infoh          $self->{infoh}\n");
	print($_debugh "   _debugh        $_debugh\n");
	print($_debugh "   inh:           $self->{_inh}\n");
	print($_debugh "   in_file_disp   " . $self->get_in_file_disp() . "\n");
	print($_debugh "   _in_csvobj     $self->{_in_csvobj}\n");
	print($_debugh "   has_headers    $self->{has_headers}\n");
	print($_debugh "   fields_ar:\n");
	for my $e (@a) {
		print($_debugh "      '$e'\n");
	}
	print($_debugh "   fields_hr:\n");
	for my $e (keys %h) {
		print($_debugh "      '$e' => '$h{$e}'\n");
	}
	print($_debugh "   fields_column_names:\n");
	for my $e (@c) {
		print($_debugh "      '$e'\n");
	}
	print($_debugh "-- _debug_show_members() end\n");
}

	#
	# Check headers in CSV header line
	# Used to increase robustness by relying on header title rather than
	# column number.
	#
	# Return 1 if success (all fields found), 0 otherwise.
	#
sub _process_header {
	my $self = shift;
	my @headers = @{shift(@_)};
	my %fields_h = %{shift(@_)};
	my $retval = shift;

	my @tmp = keys %{$retval};

	my $in_file_disp = $self->get_in_file_disp();

	confess '$_[4] must be an empty by-ref hash' if $#tmp >= 0;

	my $e = 0;
	for my $k (keys %fields_h) {
		my $v = $fields_h{$k};

		my @all_idx = indexes { /$v/i } @headers;
		if ($#all_idx >= 1) {
			$self->_print_error("file $in_file_disp: " .
				"more than one column matches the criteria '$v'");
			$e++;
		}
		my $idx = first_index { /$v/i } @headers;
		if ($idx < 0) {
			$self->_print_error("file $in_file_disp: unable to find field '$v'");
			$e++;
		} else {
			$retval->{$k} = $idx;
		}
	}

	return ($e >= 1 ? 0 : 1);
}

sub set_walker_hr {
	my $self = shift;
	validate_pos(@_, {type => UNDEF | CODEREF, optional => 1});

	my ($walker_hr) = @_;

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');
	$self->{walker_hr} = $walker_hr;

	return $self;
}

sub set_walker_ar {
	my $self = shift;
	validate_pos(@_, {type => UNDEF | CODEREF, optional => 1});

	my ($walker_ar) = @_;

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');
	$self->{walker_ar} = $walker_ar;

	return $self;
}


# * *************************************** *
# * BEGINNING OF DATE FORMAT DETECTION CODE *
# * *************************************** *


	#
	# The '%m.%d.%y' is not at its "logical" location. It is done to make sure the order in which
	# entries are written does not impact the result.
	#
	# It could occur because there is some code that correlates an entry containing %y with another
	# one that would contain %Y. The %Y will be called the master, the %y will be called the slave.
	# It is important to match such entries, otherwise an identified format with %y would always be
	# ambiguous with the same written with %Y.
	#
	# IMPORTANT
	#   The list below is written almost as-is in the POD at the bottom of this file.
	#
my @DATES_DEFAULT_FORMATS_TO_TRY = (
	'',
	'%Y-%m-%d',
	'%Y.%m.%d',
	'%Y/%m/%d',

	'%m.%d.%y',

	'%m-%d-%Y',
	'%m.%d.%Y',
	'%m/%d/%Y',
	'%d-%m-%Y',
	'%d.%m.%Y',
	'%d/%m/%Y',

	'%m-%d-%y',
	'%m/%d/%y',
	'%d-%m-%y',
	'%d.%m.%y',
	'%d/%m/%y',

	'%Y%m%d%H%M%S',

# Localizaed formats

	'%b %d, %Y',
	'%b %d %Y',
	'%b %d %T %Z %Y',
	'%d %b %Y',
	'%d %b, %Y'
);

	#
	# IMPORTANT
	#   Under Linux, $START is useless. Strptime will match a format exactly as it is, and a tring
	#   like "01/01/16 13:00:00" won't match with "%T". Under Windows, Strptime is capable of doing
	#   a match by ignoring characters at the beginning, thus "01/01/2016 13:00:00" for example will
	#   return success when matched against "%T".
	#   Possibly it has to do with versionning of Strptime, not Linux versus Windows as such. Any
	#   way, this difference had to be dealt with.
	#
	# The flexibility under Windows would screw the code logic so I had to add the prefix string
	# below, to avoid unexpected success on match.
	#
my $START = '<';

struct RecordCounter => {
	count_ok => '$',
	count_ko => '$',
	has_searched_time => '$',

	format => '$',
	locale => '$',

	has_found_time => '$',
	format_with_addition_of_time => '$',
	locale_with_addition_of_time => '$',
	parser_with_addition_of_time => '$'
};

struct Format => {
	id => '$',
	format => '$',
	locale => '$',
	parser => '$',
	index_slave => '$',
	index_master => '$'
};

sub _col_dispname {
	my ($self, $n) = @_;

	my $col;

		#
		# IMPORTANT
		#
		# We cannot execute here a command like
		#   $self->_status_forward('S3');
		# (to ensure _columns is well defined) because _col_dispname is called by
		# _detect_dates_formats that is in turn called by _S3_init_fields_extra. A call to
		# _status_forward would trigger a never-ending call loop.
		#
	my $cols = _get_def($self->{'_columns'}, $self->{'_S2_columns'});

	if ($self->{has_headers}) {
		$col = $cols->[$n];
		$col = "<UNDEF>" unless defined($col);
	} else {
		$col = "[$n]";
	}
	return $col;
}

	# Used by test plan only...
sub _dds {
	my $self = shift;

	return undef unless $self->_status_forward('S3');
	return undef unless defined($self->{_dates_detailed_status});
	return $self->{_dates_detailed_status};
}

sub _detect_dates_formats {
	my $self = shift;

	return if $self->{_detect_dates_formats_has_run};
	$self->{_detect_dates_formats_has_run} = 1;
	my @fields_dates = @{$self->{fields_dates}} if defined($self->{fields_dates});
	return unless @fields_dates or $self->{fields_dates_auto};

	if ($self->{_int_one_pass}) {
		$self->_print_error("date format detection disallowed when one_pass is set");
		return;
	}

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};
	my $debug_fmt = ($_debug and $DEBUG_DATETIME_FORMATS);

	$self->_register_pass("detect date format");

#
# Why re-opening the input?
# I tried two other ways that never worked on some OSes (like freebsd) and/or with older perl
# versions.
#
# 1) The "tell" tactic
#    Recording at the beginning of the function the file position with
#      my $pos = tell($self->{inh});
#    ... and then recalling with a seek instruction is the most logical.
#    But it didn't work = sometimes, reading would go back to first row (the headers) instead
#    of the second row, could not figure out why (it would work on my Ubuntu 16.04 / perl 5.22, but
#    would fail with other OSes and/or perl versions).
#
# 2) The "complete rewind" tactic
#    I then undertook to do (at the end of detection function):
#      seek $inh, 0, SEEK_SET;
#      $incsv->getline($inh) if $self->{has_headers};
#    based on the assumption that a seek to zero would behave differently from a seek to an
#    arbitrary position.
#    But still, it would sometimes fail....
#

	my $inh = $self->_reopen_input();
	my $incsv = $self->{_in_csvobj};
	_mygetline($incsv, $inh) if $self->{has_headers};

	my $formats_to_try = $self->{dates_formats_to_try};
	my $ignore_trailing_chars = $self->{dates_ignore_trailing_chars};
	my $search_time = $self->{dates_search_time};
	my $localizations = $self->{dates_locales};

	my %regular_named_fields = %{$self->{_regular_named_fields}};

	my $refsub_is_datetime_empty = $self->{_refsub_is_datetime_empty};

	my @fields_to_detect_format;
	if (defined($self->{fields_dates})) {
		my $count_field_not_found = 0;
		my %column_seen;
		for my $f (@{$self->{fields_dates}}) {
			if (!exists $regular_named_fields{$f}) {
				$self->_print_error("fields_dates: unknown field: '$f'",
					1, ERR_UNKNOWN_FIELD, { %regular_named_fields } );
				$count_field_not_found++;
				next;
			}
			my $n = $regular_named_fields{$f};
			if (exists $column_seen{$n}) {
				$self->_print_warning("field '$f' already seen");
				next;
			}
			$column_seen{$n} = 1;
			push @fields_to_detect_format, $n;
		}
		$self->_print_error("non existent field(s) encountered, aborted") if $count_field_not_found;
	} elsif ($self->{fields_dates_auto}) {
		my @k = keys %regular_named_fields;
		@fields_to_detect_format = (0..$#k);
	} else {
		confess "Hey! check this code, man";
	}

		#
		# FIXME?
		#   Sort by column number of not?
		#
		# At this moment in time, the author inclines to answer "yes".
		# But I must admit it is rather arbitrary decision for now.
		#
	@fields_to_detect_format = sort { $a <=> $b } @fields_to_detect_format;

	my @dates_formats_supp = @{$self->{dates_formats_to_try_supp}}
		if defined($self->{dates_formats_to_try_supp});

	$formats_to_try = [ @DATES_DEFAULT_FORMATS_TO_TRY ] unless defined($formats_to_try);
	$formats_to_try = [ @{$formats_to_try}, @dates_formats_supp ];
	my %seen;
	my $f2 = [ ];
	for (@${formats_to_try}) {
		push @{$f2}, $_ unless exists($seen{$_});
		$seen{$_} = undef;
	}
	$formats_to_try = $f2;

	$ignore_trailing_chars = 1 unless defined($ignore_trailing_chars);
	$search_time = 1 unless defined($search_time);

	my $stop = ($ignore_trailing_chars ? '' : '>');

#
# The code below (from # AMB to # AMB-END) aims to remove ambiguity that comes from %Y versus %y.
# That is: provided you have (among others) the formats to try
#   '%d-%m-%Y'
# and
#   '%d-%m-%y'
# then if parsing 4-digit-year dates (like '31-12-2016'), the two formats will work and you'll end
# up with an ambiguity. To be precise, there'll be no ambiguity if the date is followed by a time,
# but if the date is alone, both formats will work.
#
# Thanks to the below code, the member 'index_slave' (and its counterpart index_master) is populated
# and later, if such an ambiguity is detected, the upper case version (the one containing upper case
# '%Y') will be kept and the other one will be discarded.
#
# NOTE
#   Such an ambiguity can exist only when ignore_trailing_chars is set. Otherwise, the remaining two
#   digits make the date parsing fail in the '%y' case.
#
# The other members of the 'Format' object are used to work "normally", independently from this
# ambiguity removal feature.
#

		# WIP = Work In Progress...
	my @formats_wip;
	my @locales = split(/,\s*/, $localizations) if defined($localizations);
	for my $f (@{$formats_to_try}) {
		my $has_localized_item = ($f =~ m/%a|%A|%b|%B|%c|%\+/ ? 1 : 0);
		unless (@locales and $has_localized_item) {
			push @formats_wip, [$f, ''];
			next;
		}
		push @formats_wip, [$f, $_] foreach @locales;
	}

# AMB
	my @formats;
	my %mates;
	for my $i (0..$#formats_wip) {
		my $fstr = $formats_wip[$i]->[0];
		my $floc = $formats_wip[$i]->[1];

			# FIXME
			# Will not manage correctly a string like
			#   '%%Y'
			# that means (when used with Strptime), the litteral string '%Y' with no substitution.
			# Such cases will be complicated to fix, as it'll require to do a kind-of
			# Strptime-equivalent parsing of the string, and I find it a bit overkill.
			#
			# I prefer to push back in caller world saying
			#   "Hey, if using constructs like '%%Y', you'll be in trouble."
		my $m = $fstr;
		$m =~ s/%y//ig;
		$m .= $floc;

		my $index_slave = -1;
		my $index_master = -1;
		if (exists $mates{$m}) {
			my $alt_fstr = $formats_wip[$mates{$m}]->[0];
			my $m_lower = ($fstr =~ m/%y/ ? 1 : 0);
			my $m_upper = ($fstr =~ m/%Y/ ? 1 : 0);
			my $a_lower = ($alt_fstr =~ m/%y/ ? 1 : 0);
			my $a_upper = ($alt_fstr =~ m/%Y/ ? 1 : 0);

				# We ignore the weird cases where we'd have both %y and %Y in a format string.

			if (!$m_lower and $m_upper and $a_lower and !$a_upper) {
				$index_slave = $mates{$m};
				$formats[$mates{$m}]->index_master($i);
			} elsif ($m_lower and !$m_upper and !$a_lower and $a_upper) {
				$index_master = $mates{$m};
				$formats[$mates{$m}]->index_slave($i);
			}

		} else {
			$mates{$m} = $i;
		}

		my %strptime_opts = (pattern => $START . $fstr . $stop);
		$strptime_opts{locale} = $floc if $floc ne '';
		my $format = Format->new(
			id => "$i",
			format => $fstr,
			locale => $floc,
			parser => ($fstr ne '' ?
				DateTime::Format::Strptime->new(%strptime_opts) :
				undef),
			index_slave => $index_slave,
			index_master => $index_master
		);
		push @formats, $format;
	}
	for my $i (0..$#formats) {
		my $format = $formats[$i];

			# If a master could be itself the slave of another entry, that'd make it a hierarchical
			# relation tree with multiple levels. It is not possible, only a direct, unique
			# master-slave relation can be managed here.
		confess "Inonsistent data, check this module's code urgently!"
			if $format->index_slave >= 0 and $format->index_master >= 0;

		if ($format->index_slave >= 0) {
			my $mate = $formats[$format->index_slave];
			if ($mate->index_master != $i or $mate->index_slave != -1) {
				confess "Inonsistent data (2), check this module's code urgently!"
			}
		}

		if ($format->index_master >= 0) {
			my $mate = $formats[$format->index_master];
			if ($mate->index_slave != $i or $mate->index_master != -1) {
				confess "Inonsistent data (3), check this module's code urgently!"
			}
		}

	}
	if ($debug_fmt) {
		for (@formats) {
			my ($idx, $rel) = (-1, "");
			$idx = $_->index_slave, $rel = "S: " if $_->index_slave >= 0;
			$idx = $_->index_master, $rel = "M: " if $_->index_master >= 0;
			printf($_debugh "%-18s  %s  %2d", "'" . $_->format . "'", $rel, $idx);
			print($_debugh ": '" . $formats[$idx]->format . "'") if $idx >= 0;
			print($_debugh "\n");
		}
	}
# AMB-END

	my %records;
	my $record_number;
	my $count_gotit = 0;
	my $count_ambiguous = 0;
	my $count_nodate = 0;
	my $count_empty = 0;
	my $has_signaled_can_start_recording_data = 0;
	$self->{_line_after_which_recording_can_start} = 0;

		#
		# Seems a weird optimization here, but it is very important.
		# In some cases, divides execution time (to detect date format on big files
		# containing numerous fields) by 10.
		#
		# When evaluates to true, it means the input column has no identified date format, meaning,
		# no further check to do.
		#
	my @cache_nodate;

	while (my $f = _mygetline($incsv, $inh)) {
		$record_number++;

		if ($debug_fmt) {
			print($_debugh "RECORD $record_number:\n");
			for (0 .. @$f - 1) { printf($_debugh "  %02d: '%s'\n", $_, $f->[$_]); }
		}

		for my $n (@fields_to_detect_format) {
			next if $cache_nodate[$n];

			my $v = $f->[$n];
			$v = '' unless defined($v);
			next if $v eq '';
			next if defined($refsub_is_datetime_empty) and $refsub_is_datetime_empty->($v);

			if ($debug_fmt) {
				my $col = $self->_col_dispname($n);
				print($_debugh "Line $record_number, column '$col':\n");
			}

			for my $fmt (@formats) {
				my $fid = $fmt->id;
				my $fstr = $fmt->format;

				$self->_debug_output_fmt('** pre ', $fmt, $records{$n}->{$fid}) if $debug_fmt;

				$records{$n}->{$fid} = RecordCounter->new(
					count_ok => 0,
					count_ko => 0,
					has_searched_time => 0,

					format => undef,
					locale => undef,

					has_found_time => 0,
					format_with_addition_of_time => undef,
					locale_with_addition_of_time => undef,
					parser_with_addition_of_time => undef
				) unless defined($records{$n}->{$fid});

				unless ($records{$n}->{$fid}->count_ko) {
					my $is_ok = &_try_parser($fmt, $records{$n}->{$fid}, $START . $v . $stop);

					if (!$is_ok) {
						my $give_up_time = 0;
						if ($records{$n}->{$fid}->count_ko == 0 and
							$records{$n}->{$fid}->has_searched_time and
							$records{$n}->{$fid}->has_found_time) {
							$give_up_time = (defined($fmt->parser) and
								defined($fmt->parser->parse_datetime($START . $v . $stop))
								?
								1 : 0);
							if ($give_up_time) {
								$records{$n}->{$fid}->has_found_time(0);
								$is_ok = 1;
							}
						}
					}

					if ($is_ok or !$ignore_trailing_chars) {
						my $incr = (defined($fmt->parser) and $is_ok ? 1: 0);

						unless ($records{$n}->{$fid}->has_searched_time) {
							$records{$n}->{$fid}->has_searched_time(1);

							croak "Inconsistent status! Issue in module code not in caller's!"
								if $records{$n}->{$fid}->count_ok != 0;

							if ($search_time) {

								print($_debugh "  Search time in '$v', format '$fstr'\n")
									if $debug_fmt;

								my $t = $self->_guess_time_format($fstr, $fmt->locale, $v, $stop);
								$records{$n}->{$fid}->has_found_time((defined($t) ? 1 : 0));
								if (defined($t)) {
									$records{$n}->{$fid}->format_with_addition_of_time($t->[0]);
									$records{$n}->{$fid}->locale_with_addition_of_time($t->[1]);
									$records{$n}->{$fid}->parser_with_addition_of_time($t->[2]);
									$incr = 1;
								} elsif ($fstr eq '') {
									$records{$n}->{$fid}->count_ko(1);
								}
							} elsif ($fstr eq '') {
								$records{$n}->{$fid}->count_ko(1);
							}

						}

						$records{$n}->{$fid}->count_ok($records{$n}->{$fid}->count_ok + $incr);

						$records{$n}->{$fid}->count_ko($records{$n}->{$fid}->count_ko + 1)
							if !$incr and !$is_ok;

						if ($incr) {
								# We remove the slave if master is fine.
								# Depending on the order in which parsing got done, the master could
								# pop up first, or the slave, that is why we need manage both cases.
							if ($fmt->index_slave >= 0 or $fmt->index_master >= 0) {
								my $has_slave = ($fmt->index_slave >= 0 ? 1 : 0);
								my $idx = ($has_slave ? $fmt->index_slave : $fmt->index_master);
								my $mate = $formats[$idx]->id;
								if (exists $records{$n}->{$mate}) {
									if ($has_slave) {
										if ($records{$n}->{$mate}->count_ko == 0) {
												# I am the master: I remove the slave
											$records{$n}->{$mate}->count_ko(1);
										}
									} else {
										if ($records{$n}->{$mate}->count_ko == 0 and
												$records{$n}->{$mate}->count_ok >= 1 and
												$records{$n}->{$fid}->count_ko == 0) {
											$records{$n}->{$fid}->count_ko(1);
										}
									}
								}
							}
						}

					} else {
						$records{$n}->{$fid}->count_ko($records{$n}->{$fid}->count_ko + 1);
					}
				}

				$self->_debug_output_fmt('   post', $fmt, $records{$n}->{$fid}) if $debug_fmt;

			}
		}

		$count_gotit = 0;
		$count_ambiguous = 0;
		$count_empty = 0;
		for my $n (@fields_to_detect_format) {
			next if $cache_nodate[$n];

			my $candidate = 0;
			my $tt = 0;
			for my $fmt (@formats) {
				my $fid = $fmt->id;
				my $rec = $records{$n}->{$fid};
				next unless defined($rec);

				my $ok = $rec->count_ok;
				my $ko = $rec->count_ko;

				confess "Oups. Check this module code urgently!" if $ok == 0 and $ko == 0;
				$tt += $ok + $ko;

				$candidate++ if $ok >= 1 and $ko == 0;
			}
			if ($candidate == 1) {
				$count_gotit++;
			} elsif ($candidate >= 2) {
				$count_ambiguous++;
			} elsif ($tt != 0) {
				$count_nodate++;
				$cache_nodate[$n] = 1;
			} else {
				$count_empty++;
			}
		}

		if ($debug_fmt) {
			print($_debugh "\$count_gotit = $count_gotit\n");
			print($_debugh "\$count_ambiguous = $count_ambiguous\n");
			print($_debugh "\$count_nodate = $count_nodate\n");
			print($_debugh "\$count_empty = $count_empty\n");
		}

		my $can_start_recording_data = 0;
		$can_start_recording_data = 1
			if $count_gotit + $count_ambiguous + $count_nodate >= 1 and
			   !$count_ambiguous and !$count_empty;

		if ($can_start_recording_data and !$has_signaled_can_start_recording_data) {
			$has_signaled_can_start_recording_data = 1;

			print($_debugh "Can start recording (all dates formats detection closed) " .
				"after record #$record_number\n") if $_debug;

			$self->{_line_after_which_recording_can_start} = $record_number;
			last unless $self->{fields_dates_auto};
		}
	}

	close $inh;

	my %dates_detailed_status;
	my @dates_formats;
	my $check_empty = 0;
	my $check_nodate = 0;
	my $check_ambiguous = 0;
	my $check_gotit = 0;
	for my $n (@fields_to_detect_format) {
		my @formats_ok;
		my $tt = 0;
		for my $fid (sort keys %{$records{$n}}) {
			my $rec = $records{$n}->{$fid};
			if ($rec->count_ok >= 1 and $rec->count_ko == 0) {

				my ($fstr, $floc) = ($rec->format, $rec->locale);
				($fstr, $floc) = (
					$rec->format_with_addition_of_time,
					$rec->locale_with_addition_of_time
				) if $rec->has_found_time;

				push @formats_ok, [$fstr, $floc];
			}
			$tt += $rec->count_ok + $rec->count_ko;
		}
		my $is_ok = 0;
		my $format;
		my $locale = '';
		if ($#formats_ok < 0 and $tt == 0) {
			$format = "Z";
			$check_empty++;
		} elsif ($#formats_ok < 0) {
			$format = "N";
			$check_nodate++;
		} elsif ($#formats_ok > 0) {
			$format = "A";
			$check_ambiguous++;
		} else {
			$is_ok = 1;
			$format = $formats_ok[0]->[0];
			$locale = $formats_ok[0]->[1];
			$check_gotit++;
		}
		my $col = $self->_col_dispname($n);

		$dates_detailed_status{$col} = $format unless exists $dates_detailed_status{$col};
		$dates_formats[$n] = [ $format, $locale ] if $is_ok and !defined($dates_formats[$n]);
	}
	$dates_detailed_status{'.'} = $self->{_line_after_which_recording_can_start};

	if ($check_empty != $count_empty or $check_nodate != $count_nodate or
		$check_ambiguous != $count_ambiguous or $check_gotit != $count_gotit) {
			# The below condition can happen with an empty CSV (empty file (no header) or
			# only a header line).
		unless (!$count_empty and !$check_nodate and !$count_nodate and
			!$check_ambiguous and !$count_ambiguous and !$check_gotit and !$count_gotit) {
			print(STDERR "\$check_empty = $check_empty\n");
			print(STDERR "\$count_empty = $count_empty\n");
			print(STDERR "\$check_nodate = $check_nodate\n");
			print(STDERR "\$count_nodate = $count_nodate\n");
			print(STDERR "\$check_ambiguous = $check_ambiguous\n");
			print(STDERR "\$count_ambiguous = $count_ambiguous\n");
			print(STDERR "\$check_gotit = $check_gotit\n");
			print(STDERR "\$count_gotit = $count_gotit\n");
			confess "Oups! Check immediately this module code, man!";
		}
	}

	if ($debug_fmt) {
			# A very detailed debug output
		for my $n (@fields_to_detect_format) {
			my $col = $self->_col_dispname($n);
			print($_debugh "$col\n");
			printf($_debugh "  %-25s %3s %3s\n", "format", "OK", "KO");
			for my $fid (sort keys %{$records{$n}}) {
				my $rec = $records{$n}->{$fid};
				my $cc = '';
				$cc = "(" . $rec->locale . ")" if defined($rec->locale) and $rec->locale ne '';
				printf($_debugh "  %-25s %3d %3d\n",
					$rec->format . $cc, $rec->count_ok, $rec->count_ko);
			}
		}
	}
		# Not a typo - displaying it IN ADDITION to debug output above is done on purpose...
	if ($_debug) {
			# A shorter (as compared to above) output of outcome of DateTime detection
		print($_debugh "Result of DateTime detection:\n");
		printf($_debugh "%-3s %-25s %-30s %s\n", '###', 'FIELD', 'DATETIME FORMAT',
			'DATETIME LOCALE');
		for my $n (@fields_to_detect_format) {
			my ($fmt, $loc) = ('<undef>', '<undef>');
			if (defined($dates_formats[$n])) {
				($fmt, $loc) = @{$dates_formats[$n]}[0, 1];
			}
			printf($_debugh "%03d %-25s %-30s %s\n", $n, $self->_col_dispname($n), $fmt, $loc);
		}
	}

	if (!$self->{fields_dates_auto}) {
		my $e = 0;
		for my $n (@fields_to_detect_format) {
			next if defined($dates_formats[$n]);
			$self->_print_error("unable to detect DateTime format of field '" .
				$self->_col_dispname($n) . "'", 1);
			$e++;
		}
		$self->_print_error("$e field(s) encountered with unknown DateTime format") if $e;
	}

	$self->{_dates_detailed_status} = { %dates_detailed_status };
	$self->{_dates_formats} = [ @dates_formats ];
}

sub _debug_output_fmt {
	my ($self, $prefix, $fmt, $rec) = @_;

	my $_debugh = $self->{_debugh};

	my ($fstr, $floc) = ($fmt->format, $fmt->locale);
	($fstr, $floc) = (
		'<+T>' . $rec->format_with_addition_of_time,
		$rec->locale_with_addition_of_time
	) if defined($rec) and $rec->has_found_time;

	my $locstr = '';
	$locstr = "(" . $floc . ")" if defined($floc) and $floc ne '';

	my $tmpok = $rec->count_ok if defined($rec);
	$tmpok = '<undef>' unless defined($tmpok);
	my $tmpko = $rec->count_ko if defined($rec);
	$tmpko = '<undef>' unless defined($tmpko);

	print($_debugh "$prefix (format '$fstr$locstr': OK = $tmpok, KO = $tmpko)\n");
}

	# When no parse can be done (parser to test is undef), return 1
sub _try_parser {
	my ($fmt, $rec, $value_to_parse) = @_;

	my $parser = $fmt->parser;
	$parser = $rec->parser_with_addition_of_time if $rec->has_found_time;

	my $is_ok = 1;
	$is_ok = (defined($parser->parse_datetime($value_to_parse)) ? 1 : 0) if $parser;

	unless (defined($rec->format)) {
		$rec->format($fmt->format);
		$rec->locale($fmt->locale);
	}

	return $is_ok;
}

sub _guess_time_format {

	# IMPORTANT
	#   Formats are tested in the order of the list below, and the first one that succeeds stops the
	#   tests.
	#   That makes the order of the elements important: %R would match any value that'd also match
	#   %T, that'd cause to return %R whereas %T would be possible. Same with AM/PM formats. Thus
	#   the longest patterns appear first.
my @T = (
	'%I:%M:%S %p',
	'%I:%M %p',
	'%I:%M:%S%p',
	'%I:%M%p',
	'%T',
	'%R'
);

	my ($self, $format, $locale, $v, $stop) = @_;

	my $_debugh = $self->{_debugh};
	my $debug_fmt = ($self->{_debug} and $DEBUG_DATETIME_FORMATS);

	return undef if $format =~ /:/;

	my $sep;
	if ($format eq '') {
		$sep = '';
	} else {
		unless ((undef, $sep) = $v =~ /(^|\d([^0-9:]+))(\d{1,2}):(\d{1,2})(\D|$)/) {
			if ($v =~ /\d{4}:\d{2}(\D|$)/) {
				$sep = '';
			} else {

				print($_debugh "_guess_time_format(): separator candidate not found in '$v'\n")
					if $debug_fmt;

				return undef;
			}
		}
	}
	$sep = '' unless defined($sep);

		#
		# IMPORTANT
		#
		# The code below allows to successfully detect DateTime format when
		# the first lines contain things like:
		#   Jan 20 2017  2:00AM
		# that could lead to a separator set to '  ' while actually it should be ' '. In this case
		# if the double-space is kept, then a later value of
		#   Jan 20 2017 10:00AM
		# won't be parsed.
		#
		# See t/11-bugfix.t, BUG 5, for an explanation of why the line below.
		#

		# More generic code, but will also break some separators like '    ' (4 spaces)
#    $sep = substr($sep, 0, length($sep) - 1) if length($sep) >= 2 and substr($sep, -2) eq '  ';
	$sep = ' ' if $sep eq '  ';

	if ($debug_fmt) {
		print($_debugh "  _guess_time_format(): Searching time in '$v'\n");
	}

	for my $t (@T) {
		my $increased_format = "$format$sep$t";

		print($_debugh "  _guess_time_format(): Trying format '$increased_format'\n") if $debug_fmt;

		my %opts = (pattern => $START . $increased_format . $stop);
		$opts{locale} = $locale if defined($locale) and $locale ne '';
		my $parser_of_increased_format = DateTime::Format::Strptime->new(%opts);
		next unless defined($parser_of_increased_format->parse_datetime($START . $v . $stop));

		if ($debug_fmt) {
			print($_debugh "  _guess_time_format(): found time in '$v'\n");
			print($_debugh "    Initial format:   '$format'\n");
			print($_debugh "    Increased format: '$increased_format'\n");
		}

		return [$increased_format, $locale, $parser_of_increased_format];
	}
	return undef;
}


# * ********************************* *
# * END OF DATE FORMAT DETECTION CODE *
# * ********************************* *


	# Take the string of a header in $_ and replace it with the corresponding field name
sub _header_to_field_name {
	$_ = remove_accents($_);
	s/[^[:alnum:]_]//gi;
	s/^.*$/\U$&/;
}

	# Return 0 if error, 1 if all good
sub _S2_init_fields_from_header {
	my $self = shift;

	my $has_headers = $self->{has_headers};
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	my $in_file_disp = $self->get_in_file_disp();

	my $inh = $self->{_inh};
	my $incsv = $self->{_in_csvobj};

	$self->{_row_read} = 0;

	my @columns;
	my @headers;
	if ($has_headers) {

		print($_debugh "$PKG: '$in_file_disp': will parse header line to get column names\n")
			if $self->{_debug_read};

		$self->{_row_read}++;

		print($_debugh "$PKG: '$in_file_disp': will read line #" . $self->{_row_read} . "\n")
			if $self->{_debug_read};

		if (defined($self->{_inh_header})) {
			my $l = $self->{_inh_header};
			my $inmemh;
			if (!open ($inmemh, '<', \$l)) {
				$self->_print_error("can't open header line in-memory. CSV read aborted.");
				return 0;
			}
			@headers = @{_mygetline($incsv, $inmemh)};
		} else {
			my $r = _mygetline($incsv, $inh);
			@headers = @{$r} if defined($r);
		}
		print($_debugh "Line " . $self->{_row_read} . ":\n--\n" . join('::', @headers) . "\n--\n")
			if $self->{_debug_read};
	}

	if ($has_headers and !defined($self->{fields_column_names})) {
		my %indexes;
		if (defined($self->{fields_hr})) {
			if (!$self->_process_header(\@headers, $self->{fields_hr}, \%indexes)) {
				$self->_print_error("missing headers. CSV read aborted.");
				return 0;
			}
			if ($_debug) {
				print($_debugh "   \%indexes:\n");
				for my $k (sort keys %indexes) {
					print($_debugh "   \t$k => $indexes{$k}\n");
				}
			}
			for (sort keys %indexes) {
				next if $_ eq '';
				$columns[$indexes{$_}] = $_;
			}
		} else {
			@columns = @headers;
			map { _header_to_field_name } @columns;
		}
	}

	@columns = @{$self->{fields_column_names}} if defined($self->{fields_column_names});

		# Avoid undef in column names... I prefer empty strings
	@columns = map { defined($_) ? $_ : '' } @columns;

	if ($_debug) {
		print($_debugh "-- CSV headers management\n");
		if (@columns) {
			printf($_debugh "   %-3s %-40s %-40s\n", 'COL', 'CSV Header', 'Hash Key');
			for my $i (0..$#columns) {
				my $h = '';
				$h = $headers[$i] if defined($headers[$i]);
				printf($_debugh "   %03d %-40s %-40s\n", $i, "'$h'", "'$columns[$i]'");
			}
		} else {
			print($_debugh "   No headers\n");
		}
	}

	my %regular_named_fields;
	for my $i (0..$#columns) {
		$regular_named_fields{$columns[$i]} = $i if defined($columns[$i]) and $columns[$i] ne '';
	}
	$self->{_regular_named_fields} = { %regular_named_fields };
	$self->{_S2_columns} = [ @columns ];
	$self->{_S2_headers} = [ @headers ] if $has_headers;

	return 1;
}

sub out_header {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => SCALAR});

	my ($field, $header) = @_;
	$self->{_out_headers} = { } unless exists $self->{_out_headers};

	$self->_print_warning("out_header: field $field already set")
		if exists $self->{_out_headers}->{$field};

	$self->{_out_headers}->{$field} = $header;

	return $self;
}

	# Return 0 if error, 1 if all good
sub _S3_init_fields_extra {
	my $self = shift;

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	my $verbose = $self->{verbose};

	my $has_headers = $self->{has_headers};

	my %named_fields = %{$self->{_regular_named_fields}};
	my @columns = @{$self->{_S2_columns}};
	my @headers = @{$self->{_S2_headers}} if $has_headers;

	my @extra_fields_indexes;
	my @extra_fields_definitions_list = @{$self->{_extra_fields}} if exists $self->{_extra_fields};
	my %extra_fields_definitions;

	my @coldata;
	for my $i (0..$#columns) {
		my $col = $columns[$i];
		my $h = $headers[$i] if $has_headers;
		push @coldata, ColData->new(
			field_name => $col,
			header_text => $h,
			description => ''
		);
	}

	for my $edef (@extra_fields_definitions_list) {
		my $c = $edef->check_field_existence;
		if (defined($c)) {
			unless (exists $named_fields{$c}) {
				$self->_print_error("unknown field '" . $edef->check_field_existence . "'",
					0, ERR_UNKNOWN_FIELD, { %named_fields } );
				next;
			}
		}

		my @e_eclated = $edef;

		if ($edef->ef_type == $EF_LINK and $edef->link_remote_read eq '*') {
			my @cols = $edef->link_remote_obj->get_fields_names();

			@e_eclated = ();
			my %nf = %named_fields;

			for my $c (@cols) {

				my $ex_base = $edef->self_name . $c;
				my $ex_target = $ex_base;
				my $i = 1;
				while (exists $nf{$ex_target}) {
					$i++;
					$ex_target = $ex_base . '_' . $i;
				}

				my $e = ExtraField->new(
					ef_type => $EF_LINK,
					self_name => $ex_target,
					description => $edef->description . " ($c)",

					link_self_search => $edef->link_self_search,
					link_remote_obj => $edef->link_remote_obj,
					link_remote_search => $edef->link_remote_search,
					link_remote_read => $c,

					link_vlookup_opts => $edef->link_vlookup_opts
				);
				push @e_eclated, $e;
				$nf{$ex_target} = undef;
			}
		}

		for my $e1 (@e_eclated) {
			if (exists $named_fields{$e1->self_name}) {
				$self->_print_error("extra field: duplicate field name: '" . $e1->self_name . "'");
				next;
			}

			my $index_of_new_element = $#columns + 1;
			push @extra_fields_indexes, $index_of_new_element;
			$columns[$index_of_new_element] = $e1->self_name;
			$named_fields{$e1->self_name} = $index_of_new_element;
			$extra_fields_definitions{$e1->self_name} = $e1;

			push @headers, $e1->self_name if $has_headers;
			push @coldata, ColData->new(
				field_name => $e1->self_name,
				header_text => $e1->self_name,
				description => $e1->description
			);
		}

	}
	$self->{_headers} = [ @headers ] if $has_headers;
	$self->{_extra_fields_indexes} = [ @extra_fields_indexes ];
	$self->{_columns} = [ @columns ];
	$self->{_extra_fields_definitions} = { %extra_fields_definitions };

	$self->{_named_fields} = { %named_fields };

	$self->_detect_dates_formats();

	$self->{_read_update_after_ar} = [ ];
	$self->{_write_update_before_ar} = [ ];
	my @dates_formats = @{$self->{_dates_formats}} if defined($self->{_dates_formats});
	for my $i (0..$#columns) {
		my $dt_format;
		my $dt_locale;
		if (defined($dates_formats[$i])) {
			$dt_format = $dates_formats[$i]->[0];
			$dt_locale = $dates_formats[$i]->[1];
		}
		$coldata[$i]->dt_format($dt_format);
		$coldata[$i]->dt_locale($dt_locale);

		next unless defined($dt_format);

		my %opts_in;
		$opts_in{locale} = $dt_locale if defined($dt_locale) and $dt_locale ne '';

		my $obj_strptime_in = DateTime::Format::Strptime->new(pattern => $dt_format, %opts_in);

		my %opts_out;
		my $loc_out = (exists $self->{out_dates_locale} ? $self->{out_dates_locale} : $dt_locale);
		$opts_out{locale} = $loc_out if defined($loc_out) and $loc_out ne '';
		my $obj_strptime_out = DateTime::Format::Strptime->new(
			pattern => (exists $self->{out_dates_format} ? $self->{out_dates_format} :$dt_format),
			%opts_out
		);

		my $refsub_is_datetime_empty = $self->{_refsub_is_datetime_empty};
		my $in_file_disp = $self->get_in_file_disp();

		$self->{_read_update_after_ar}->[$i] = sub {
			return undef if !defined($_) or $_ eq '' or
				(defined($refsub_is_datetime_empty) and $refsub_is_datetime_empty->($_));

			my $s = $_[0];
			my $field = _get_def($_[1], '<?>');

			my $dt = $obj_strptime_in->parse_datetime($_);

			if ($_debug and $DEBUG_DATETIME_FORMATS and $DEBUG_DATETIME_FORMATS_EVEN_MORE) {
				print($_debugh "-- Record " . $s->get_recnum() .
					", field '$field':\n   String parsed: '$_'\n   Parse format:  '$dt_format'\n" .
					"   DateTime obj:  <" . (defined($dt) ? $dt . '' : 'undef') . ">\n");
			}

			if (!defined($dt)) {
				my $recnum = $s->get_recnum();
				if ($verbose) {
					$s->_print("$PKG: " .
						"$in_file_disp: record $recnum: field $field: unable to parse DateTime\n");
					$s->_print("$PKG:   field:  '$_'\n");
					$s->_print("$PKG:   format: '$dt_format'\n");
					$s->_print("$PKG:   " .
						"locale: '" . ($dt_locale eq '' ? '<none>' : $dt_locale) . "'\n");
					$s->_print("$PKG: " .
						"Probable cause: when detecting DateTime format, $PKG will stop reading\n");
					$s->_print("$PKG: " .
						"input as soon as the format is worked out. If a value found later\n");
					$s->_print("$PKG: " .
						"turns out to use another DateTime format, it'll generate a DateTime\n");
					$s->_print("$PKG: parse error, as is the case now.\n");
					$s->_print_error("unable to parse DateTime");
				} else {
					$s->_print_error("$in_file_disp: record $recnum: field $field: " .
						"unable to parse DateTime '$_'");
				}
			}

			return $dt;
		};
		$self->{_write_update_before_ar}->[$i] = sub {
			return '' unless defined($_);
			return $_ if !ref($_);
			return $_ unless $_->isa('DateTime');

			my $str = $obj_strptime_out->format_datetime($_);

			if (!defined($str)) {
				my $s = $_[0];
				my $recnum = $s->get_recnum();
				my $field = _get_def($_[1], '<?>');
				$s->_print_error("$in_file_disp: record $recnum: field $field: " .
					"unable to print DateTime '$_'")
			}

			return $str;
		};
	}

	$self->{_coldata} = [ @coldata ];

	my @loop = (
		['_read_update_after_hr',   '_read_update_after_ar',   'read post'],
		['_write_update_before_hr', '_write_update_before_ar', 'write pre']
	);
	for my $ii (0..$#loop) {
		my $l = $loop[$ii];

		my $ht = $self->{$l->[0]};
		my @subrefs = @{$self->{$l->[1]}};
		for my $field (keys %{$ht}) {
			unless (exists $named_fields{$field}) {
				$self->_print_error($l->[2] . ": unknown field '$field'",
					0, ERR_UNKNOWN_FIELD, { %named_fields } );
				next;
			}

			my $i = $named_fields{$field};

			my @allsubs;
			push @allsubs, @{$ht->{$field}};
			if (defined($subrefs[$i])) {
				unshift @allsubs, $subrefs[$i] if $ii == 0;
				push @allsubs, $subrefs[$i] if $ii == 1;
			}

			my $finalsub = sub {
				for my $s (@allsubs) {
					$_ = $s->(@_);
				}
				return $_;
			};
			$subrefs[$i] = $finalsub;

		}
		$self->{$l->[1]} = [ @subrefs ];
	}

	my $tmp = _get_def($self->{out_fields}, $self->{write_fields});
	my @wf = @{$tmp} if defined($tmp);
	my $count_field_not_found = 0;
	for (@wf) {
		next if !defined($_) or $_ eq '' or exists $named_fields{$_};
		$count_field_not_found++;
		$self->_print_error("out_fields: unknown field '$_'",
			1, ERR_UNKNOWN_FIELD, { %named_fields } );
	}
	if ($count_field_not_found) {
		$self->_print_error("non existent field(s) encountered");
		delete $self->{out_fields};
		delete $self->{write_fields};
	}

	my %sh = %{$self->{_out_headers}} if defined($self->{_out_headers});
	$count_field_not_found = 0;
	for (keys %sh) {
		next if !defined($_) or $_ eq '' or exists $named_fields{$_};
		$count_field_not_found++;
		$self->_print_error("out_header: unknown field '$_'",
			1, ERR_UNKNOWN_FIELD, { %named_fields } );
	}
	$self->_print_error("non existent field(s) encountered") if $count_field_not_found;

	return 1;
}

	#
	# Return 0 if there's no more records (error or eof reached), 1 if a record got read
	# successfully.
	#
	# If return value is 1:
	#   $$ref_ar and $$ref_hr are set to array ref and hash ref of the record, respectively
	#
	# If return value is 0:
	#   $$ref_ar and $$ref_hr are set to undef if an error occured
	#   $$ref_ar and $$ref_hr are set to a scalar if eof reached
	#
sub _read_one_record_from_input {
	my ($self, $ref_ar, $ref_row_hr) = @_;

	my $_debug = $self->{_debug};
	my $_debug_extra_fields = $self->{_debug_extra_fields};
	my $_debugh = $self->{_debugh};

	my $in_file_disp = $self->get_in_file_disp();

	my $incsv = $self->{_in_csvobj};
	my $ar;

	print($_debugh "$PKG: '$in_file_disp': will read line #" . ($self->{_row_read} + 1) . "\n")
		if $self->{_debug_read};

	unless ($ar = _mygetline($incsv, $self->{_inh})) {
		if (!$incsv->eof()) {
			my ($code, $str, $pos) = $incsv->error_diag();
			$self->_print_error("$code: $str, record " . $incsv->record_number . ", position $pos");
			$$ref_ar = undef;
			$$ref_row_hr = undef;
		} else {
			$$ref_ar = 1;
			$$ref_row_hr = 1;
		}

		$self->_close_inh();

		return 0;
	}

	$self->{_row_read}++;

	my %named_fields = %{$self->{_named_fields}};

	if ($self->{_debug_read}) {
		print($_debugh "Line " . $self->{_row_read} . ":\n--\n");
		for (sort keys %named_fields) {
			my $c = _get_def($ar->[$named_fields{$_}], '<undef>');
			print($_debugh "   $_ => '" . $c . "'\n");
		}
	}

	my $columns_ar = $self->{_columns};

	my $no_undef = $self->{no_undef};
	if ($no_undef) {
		for (0..$#{$columns_ar}) {
			$ar->[$_] = '' unless defined($ar->[$_]);
		}
	}

	my $row_hr = { };
	$row_hr->{$_} = $ar->[$self->{_regular_named_fields}->{$_}]
		foreach keys %{$self->{_regular_named_fields}};

	my $rpost = $self->{_read_update_after_ar};
	for my $i (0..$#{$columns_ar}) {
		my $subref = $rpost->[$i];
		next unless defined($subref);

		do {
			my $field = $columns_ar->[$i];
			local $_ = $ar->[$i];
			my $new_val = $subref->($self, $field);
			$ar->[$i] = $new_val;
			$row_hr->{$field} = $new_val if defined($field);
		}

	}

	for my $i (@{$self->{_extra_fields_indexes}}) {
		my $name = $columns_ar->[$i];
		my $e = $self->{_extra_fields_definitions}->{$name};

		print($_debugh "Extra field: #$i: $name\n") if $_debug_extra_fields;

		my $value;
		if ($e->ef_type == $EF_LINK) {

			print($_debugh "  linked field\n") if $_debug_extra_fields;

			my $remobj = $e->link_remote_obj;
			$value = $remobj->vlookup(
				$e->link_remote_search,
				$ar->[$named_fields{$e->link_self_search}],
				$e->link_remote_read,
				$e->link_vlookup_opts
			);

		} elsif ($e->ef_type == $EF_FUNC) {

			print($_debugh "  computed field\n") if $_debug_extra_fields;

			$value = $e->func_sub->($name, $row_hr, $self->{_stats});

		} elsif ($e->ef_type == $EF_COPY) {

			print($_debugh "  copy field\n") if $_debug_extra_fields;

			my $input = $row_hr->{$e->copy_source};
			$input = '' if !defined($input) and $no_undef;
			if (defined($e->copy_sub)) {
				local $_ = $input;
				$value = $e->copy_sub->();
			} else {
				$value = $input;
			}

			print($_debugh "    in: '$input', out: '$value'\n") if $_debug_extra_fields;

		} else {
			confess "Unknown ef_type '" . $e->ef_type . "', check this module' code urgently!";
		}

		$value = '' if !defined($value) and $no_undef;
		$ar->[$i] = $value;
		$row_hr->{$name} = $value;

		print($_debugh "  $name => '$value'\n") if $_debug_extra_fields;

	}

	if (defined($self->{read_post_update_hr})) {
		$self->{read_post_update_hr}->($row_hr, $self->{_stats}, $self->get_recnum());
		$ar->[$named_fields{$_}] = $row_hr->{$_} foreach keys %named_fields;
	}

	lock_keys(%$row_hr) if $self->{croak_if_error};

	$self->{walker_ar}->($ar, $self->{_stats}, $self->get_recnum())
		if defined($self->{walker_ar});
	$self->{walker_hr}->($row_hr, $self->{_stats}, $self->get_recnum())
		if defined($self->{walker_hr});

	$$ref_ar = $ar;
	$$ref_row_hr = $row_hr;

	return 1;
}

sub _open_read {
	my $self = shift;

	my $verbose = $self->{verbose};
	my $in_file_disp = $self->get_in_file_disp();

	$self->{_stats} = { };
	$self->{_read_in_progress} = 1;

	$self->_print("-- $in_file_disp reading start\n") if $verbose;
}

sub _close_read {
	my $self = shift;
	my $keep_quiet = shift;

	my $verbose = $self->{verbose};
	my $in_file_disp = $self->get_in_file_disp();

	$self->{_read_in_progress} = 0;

	if ($verbose and !$keep_quiet) {
		$self->_print("-- $in_file_disp reading end: " . $self->{_row_read} . " row(s) read\n");
		for my $k (sort keys %{$self->{_stats}}) {
			$self->_printf("   %7d %s\n", $self->{_stats}->{$k}, $k);
		}
	}
}

	# Return 0 if error, 1 if all good
sub _S4_read_all_in_mem {
	my $self = shift;

	$self->_register_pass("_S4_read_all_in_mem()");

	$self->_open_read();

	my $ar;
	my $row_hr;
	while ($self->_read_one_record_from_input(\$ar, \$row_hr)) {

		push @{$self->{_flat}}, $ar;

	}

	my $retcode = (defined($ar) ? 1 : 0);
	$self->_update_in_mem_record_count();

	$self->_close_read();

	return $retcode;
}

sub _chain_array {
	return split(/\s*->\s*/, $_[0]);
}

sub _chain_str {
	return join('->', @_);
}

sub field_add_link {
	my $self = shift;

	validate_pos(@_, {type => UNDEF | SCALAR}, {type => SCALAR}, {type => SCALAR | OBJECT},
		{type => HASHREF, optional => 1});

	my ($new_field, $chain, $obj, $param_opts) = @_;

	my $croak_if_error = $self->{croak_if_error};
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	my @c = _chain_array($chain);
	$new_field = $c[2] unless defined($new_field);

	print($_debugh "Registering new linked field, new_field = '$new_field', chain = '$chain'\n")
		if $_debug;

	unless (@c == 3 and $c[2] ne '') {
		$self->_print_error("wrong links chain parameter: '$chain', " .
			"look for CHAIN in Text::AutoCSV manual for help");
		return undef;
	}

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');

	my @tmp = %{$param_opts} if $param_opts;
	my %opts = validate(@tmp, $SEARCH_VALIDATE_OPTIONS);

	my $target_name = '';
	if (ref $obj eq '') {
		my $in_file = $obj;
		$target_name = $in_file;

			#
			# TODO (?)
			#
			#   Take into account the fact that the OS' file system is case insensitive. At the
			#   moment, two different strings (even if identical in a case insensitive comparison)
			#   will be managed as being distinct.
			#   I put a question mark in this TO DO - after all, the user of this module had better
			#   use same case when dealing with multiple links of the same file.
			#
			#   Also, tuning this module' behavior depending on the OS' characteristics would be not
			#   ideal, it'd add a level of complexity to understand how it works and what to expect.
			#
		if (exists $self->{_obj} and exists $self->{_obj}->{$in_file}) {

			print(
				$_debugh
				"field_add_link: file '$in_file': re-using existing Text::AutoCSV object\n"
			) if $_debug;

			$obj = $self->{_obj}->{$in_file};
		} else {

			print($_debugh "field_add_link: file '$in_file': creating new Text::AutoCSV object\n")
				if $_debug;

			$self->{_obj} = { } unless exists $self->{_obj};

				#
				# The created Text::AutoCSV must be created with the same search options as what is
				# currently found in $self.
				#
				# Why?
				#   Because the link is populated doing a vlookup on the remote object ($obj below),
				#   not on $self. Therefore, if we don't "propagate" search options from $self to
				#   $obj, search tunnings won't work as user would expect.
				#
			my %search_opts;
			for (qw(search_case search_trim search_ignore_empty search_ignore_accents
				search_value_if_not_found search_value_if_ambiguous search_ignore_ambiguous)) {
					# We assign depending on whether or not the attribute EXISTS - the definedness
					# is not appropriate, in case an attribute would have been assigned to undef.
				$search_opts{$_} = $self->{$_} if exists $self->{$_};
			}

			$obj = Text::AutoCSV->new(
				in_file => $in_file,
				verbose => $self->{verbose},
				infoh => $self->{infoh},
				_debug => $self->{debug},
				_debugh => $self->{debugh},
				%search_opts
			);
			$self->{_obj}->{$in_file} = $obj;
		}
	} else {
		$target_name = '(object)';
		print($_debugh "field_add_link: Text::AutoCSV object provided\n") if $_debug;
	}

	$self->{_extra_fields} = [ ] unless exists $self->{_extra_fields};

	push @{$self->{_extra_fields}}, ExtraField->new(
		ef_type => $EF_LINK,
		self_name => $new_field,
		description => "link: $target_name, chain: $chain",
		check_field_existence => $c[0],

		link_self_search => $c[0],
		link_remote_obj => $obj,
		link_remote_search => $c[1],
		link_remote_read => $c[2],

		link_vlookup_opts => \%opts
	);

	return $self;
}

sub links {
	my $self = shift;

	validate_pos(@_, {type => UNDEF | SCALAR}, {type => SCALAR}, {type => SCALAR | OBJECT},
		{type => HASHREF, optional => 1});

	my $prefix_field = shift;
	my $chain = shift;
	my ($obj, $param_opts) = @_;

	my @c = _chain_array($chain);

	if (@c != 2 or $c[0] eq '' or $c[1] eq '') {
		$self->_print_error("wrong links chain parameter: '$chain', " .
			"look for JOINCHAIN in Text::AutoCSV manual for help");
		return undef;
	}

	$prefix_field = '' unless defined($prefix_field);
	my $chain2 = _chain_str(@c, '*');

	return $self->field_add_link($prefix_field, $chain2, @_);
}

sub field_add_computed {
	my $self = shift;

	validate_pos(@_, {type => SCALAR}, {type => CODEREF});
	my ($new_field, $func) = @_;

	my $croak_if_error = $self->{croak_if_error};

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	print($_debugh "Registering new computed field, new_field = '$new_field'\n") if $_debug;

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');

	push @{$self->{_extra_fields}}, ExtraField->new(
		ef_type => $EF_FUNC,
		self_name => $new_field,
		description => "computed",

		func_sub => $func
	);

	return $self;
}

sub field_add_copy {
	my $self = shift;

	validate_pos(@_, {type => SCALAR}, {type => SCALAR}, {type => CODEREF, optional => 1});
	my ($new_field, $copy_source, $func) = @_;

	my $croak_if_error = $self->{croak_if_error};

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	print($_debugh "Registering field copy, new_field = '$new_field' copied from '$copy_source'\n")
		if $_debug;

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');

	push @{$self->{_extra_fields}}, ExtraField->new(
		ef_type => $EF_COPY,
		self_name => $new_field,
		description => "copy of $copy_source " . (defined($func) ? '(with sub)' : '(no sub)'),
		check_field_existence => $copy_source,

		copy_source => $copy_source,
		copy_sub => $func
	);

	return $self;
}

sub in_map {
	my $self = shift;

	return $self->read_update_after(@_);
}

sub read_update_after {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => CODEREF});

	my ($field, $subref) = @_;

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');

	print($_debugh "Registering read_post_update subref for field '$field'\n") if $_debug;

	$self->{_read_update_after_hr}->{$field} = [ ]
		unless defined($self->{_read_update_after_hr}->{$field});

	push @{$self->{_read_update_after_hr}->{$field}}, $subref;

	return $self;
}

sub out_map {
	my $self = shift;

	return $self->write_update_before(@_);
}

sub write_update_before {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => CODEREF});

	my ($field, $subref) = @_;

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	return undef unless $self->_status_forward('S2');
	return undef unless $self->_status_backward('S2');

	print($_debugh "Registering write_pre_update subref for field '$field'\n") if $_debug;

	$self->{_write_update_before_hr}->{$field} = [ ]
		unless defined($self->{_write_update_before_hr}->{$field});

	push @{$self->{_write_update_before_hr}->{$field}}, $subref;

	return $self;
}

sub reset_next_record_hr {
	my $self = shift;

	validate_pos(@_);

	$self->{_current_record} = undef;

	return $self;
}

sub _create_internal_column_name_from_its_number {
	return sprintf("__%04i__", $_[0]);
}

sub _ar_to_hr {
	my $self = shift;

	validate_pos(@_, {type => ARRAYREF});

	my ($ar) = @_;
	my $last_elem_index = scalar(@{$ar}) - 1;

	my $nr = $self->{_named_fields};
	my %h;
	my %n_seen;
	for (keys %{$nr}) {
		$h{$_} = $ar->[$nr->{$_}];
		undef $n_seen{$nr->{$_}};
	}
	for my $i (0..$last_elem_index) {
		if (!exists($n_seen{$i})) {
			my $k = _create_internal_column_name_from_its_number($i);
			$h{$k} = $ar->[$i] if !exists $h{$k};
		}
	}

	lock_keys(%h) if $self->{croak_if_error};

	return \%h;
}

sub get_next_record_hr {
	my $self = shift;

	validate_pos(@_, {type => SCALARREF, optional => 1});

	my $refkey = $_[0];

	return undef unless $self->_status_forward('S4');

	if (!defined($self->{_current_record})) {
		$self->{_current_record} = 0;
	} else {
		$self->{_current_record}++;
	}

	my $ar = $self->{_flat}->[$self->{_current_record}];
	if (!defined($ar)) {
		$self->{_current_record} = undef;
		$$refkey = undef;
		return undef;
	}

	$$refkey = $self->{_current_record};

	return $self->_ar_to_hr($ar);
}

sub read {
	my $self = shift;

	validate_pos(@_);

	return undef unless $self->_status_backward('S3');
	return undef unless $self->_status_forward('S3');

	$self->_register_pass("read()");

	$self->_open_read();

	my $ar;
	my $row_hr;
	while ($self->_read_one_record_from_input(\$ar, \$row_hr)) {
		# Ben oui quoi... qu'est-ce que l'on peut bien faire d'autre ?
	}

	$self->_close_read();
	return undef unless defined($ar);

	return undef unless $self->_status_reset();

	return $self;
}

	#
	# Initially, _read_all_in_mem was intended for the test plan.
	#
	# Turned out to be sometimes useful for user, thus, is no longer private since 1.1.5.
	# Private version below is kept for compatibility.
	#
sub read_all_in_mem {
	my $self = shift;

	return $self->_read_all_in_mem();
}

sub _read_all_in_mem {
	my $self = shift;

	return 0 unless $self->_status_backward('S3');
	return 0 unless $self->_status_forward('S4');

	return $self;
}

sub print_id {
	my $self = shift;

	$self->_printf("-- " . $self->get_in_file_disp() . ":\n");
	$self->_printf("sep_char:         " . $self->get_sep_char() . "\n");
	$self->_printf("escape_char:      " . $self->get_escape_char() . "\n");
	$self->_printf("in_encoding:      " . $self->get_in_encoding() . "\n");
	$self->_printf("is_always_quoted: " . ($self->get_is_always_quoted() ? 'yes' : 'no') . "\n");

	my @coldata = $self->get_coldata();
	my @disp;
	push @disp, [ '#', 'FIELD', 'HEADER', 'EXT DATA', 'DATETIME FORMAT', 'DATETIME LOCALE' ];
	push @disp, [ map { my $s = $_; $s =~ s/./-/g; $s } @{$disp[0]} ];
	for my $i (0..$#coldata) {
		my $col = $coldata[$i];

		my @row;
		push @row, "$i";
		push @row, (defined($col->[$_]) ? ($col->[$_] . '') : '') for (0..4);
		map { s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g } @row;
		push @disp, [ @row ];
	}
	my $n = @{$disp[-1]};
	my @max = (-1) x $n;
	for my $l (@disp) {
		do { $max[$_] = length($l->[$_]) if $max[$_] < length($l->[$_]) } for (0 .. $n - 1);
	}
	my $s = join(' ', map { "%-${_}s" } @max);
	$self->_print("\n");
	$self->_printf("$s\n", @{$_}) for (@disp);
}

sub set_out_file {
	my $self = shift;
	validate_pos(@_, {type => SCALAR});

	my ($out_file) = @_;
	$self->{out_file} = $out_file;

	return $self;
}

	# Subrefs set with out_map
sub _execute_write_update_before {
	my ($self, $ar) = @_;

	my $columns_ar = $self->{_columns};

	my $wpre = $self->{_write_update_before_ar};
	for my $i (0..$#{$columns_ar}) {
		my $subref = $wpre->[$i];
		next unless defined($subref);

		do {
			local $_ = $ar->[$i];
			my $field = $columns_ar->[$i];
			my $new_val = $subref->($self, $field);
			$ar->[$i] = $new_val;
		}

	}
}

	# Take into account write_fields if it got set
sub _apply_write_fields {
	my ($self, $ar) = @_;

	my @final;

	my $tmp = _get_def($self->{out_fields}, $self->{write_fields});
	my @wf = @{$tmp} if defined($tmp);

	return unless @wf;

	my %named_fields = %{$self->{_named_fields}};
	for my $i (0..$#wf) {
		my $field = $wf[$i];
		my $tmp = $ar->[$named_fields{$field}] if defined($field) and $field ne '';

			# Put here any post-processing of value
			# WARNING
			#   $tmp can be undef
		# ...

		$final[$i] = $tmp;
	}
	$_[1] = [ @final ];
}

sub write {
	my $self = shift;

	validate_pos(@_);

	return undef unless $self->_status_forward('S3');

	my $verbose = $self->{verbose};
	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	my $out_file = $self->{out_file};

	my %stats;

	$self->_print("-- $out_file writing start\n") if $verbose;
	my $rows_written = 0;

	my $outh = $self->{outh};

	$self->{_close_outh_when_finished} = 0;
	unless (defined($outh)) {
		if ($out_file eq '') {
			$outh = \*STDOUT;
		} else {
			unless (open($outh, '>', $out_file)) {
				$self->_print_error("unable to open file '$out_file': $!");
				return undef;
			}
			$self->{_close_outh_when_finished} = 1;
		}
		$self->{outh} = $outh;
	}

	unless ($self->{_leave_encoding_alone}) {
		my $enc = (defined($self->{_inh_encoding}) ?
				$self->{_inh_encoding} :
				$DEFAULT_OUT_ENCODING);

			# out_encoding option takes precedence
		$enc = $self->{out_encoding} if defined($self->{out_encoding});
		my $m = ":encoding($enc)";
		if (_is_utf8($enc) and $self->{out_utf8_bom}) {
			$m .= ':via(File::BOM)';
		}

		if ($OS_IS_PLAIN_WINDOWS and $FIX_PERLMONKS_823214) {
				# Tested with UTF-16LE, NOT tested with UTF-16BE (it should be the same story)
			$m = ":raw:perlio:$m:crlf" if $enc =~ /^utf-?16/i;
		}

		binmode $outh, $m;
		print($_debugh "Encoding string used for output: $m\n") if $_debug;
	}

	my $escape_char = $self->{escape_char};
	my $quote_char = $self->{quote_char};

	my %opts;
	$opts{binary} = 1;
	$opts{eol} = "\n";

	$opts{sep_char} = $self->{sep_char} if defined($self->{sep_char});
	$opts{sep_char} = $self->{out_sep_char} if defined($self->{out_sep_char});

	$opts{quote_char} = $self->{quote_char} if defined($self->{quote_char});
	$opts{quote_char} = $self->{out_quote_char} if defined($self->{out_quote_char});

	$opts{escape_char} = $self->{escape_char} if defined($self->{escape_char});
	$opts{escape_char} = $self->{out_escape_char} if defined($self->{out_escape_char});

	$opts{always_quote} = $self->{_is_always_quoted};
	$opts{always_quote} = $self->{out_always_quote} if defined($self->{out_always_quote});

	my $csvout = Text::CSV->new({ %opts });
	if (!defined($csvout)) {
		$self->_print_error("error creating output Text::CSV object");
		return undef;
	}

	my $write_filter_hr = _get_def($self->{out_filter}, $self->{write_filter_hr});

	if (($self->{has_headers} and
				!(defined($self->{out_has_headers}) and !$self->{out_has_headers}))
			or $self->{out_has_headers}) {
		my $ar = [ ];
		if ($self->{has_headers}) {
			$ar = $self->{_headers};
		} else {
			my $nf = $self->{_named_fields};
			$ar->[$nf->{$_}] = $_ for (keys %{$nf});
		}

		if (exists $self->{_out_headers}) {
			my $h = $self->{_out_headers};
			for (keys %{$self->{_named_fields}}) {
				if (exists $h->{$_}) {
					$ar->[$self->{_named_fields}->{$_}] = $h->{$_};
				}
			}
		}

		$self->_apply_write_fields($ar);

		$csvout->print($outh, $ar);
		$rows_written++;
	}

	my $do_status_reset = 0;


#
# FIXME!!!
#
# Instead of this duplication of code, provide AutoCSV with a "create iterator sub" feature to
# iterate over all records, whatever is going on behind the scene (in-memory or read input).
#
# Such an iterator would also benefit to module users.
#


	if ($self->{_status} == 4) {

			#
			# The content is available in-memory: we write from what we have in-memory then...
			#

		for my $k ($self->get_keys()) {
			my $hr = $self->get_row_hr($k);
			if (defined($write_filter_hr)) {
				next unless $write_filter_hr->($hr);
			}
			my $ar = [ @{$self->get_row_ar($k)} ];

			$self->_execute_write_update_before($ar);
			$self->_apply_write_fields($ar);

			$csvout->print($outh, $ar);
			$rows_written++;
		}

	} else {

			#
			# No in-memory content available: we read and write in parallel.
			#

		$self->_register_pass("write()");

		$self->_open_read();
		my $ar;
		my $row_hr;
		while ($self->_read_one_record_from_input(\$ar, \$row_hr)) {
			if (defined($write_filter_hr)) {
				next unless $write_filter_hr->($row_hr, \%stats, $self->get_recnum());
			}
			$ar = [ @{$ar} ];

			$self->_execute_write_update_before($ar);
			$self->_apply_write_fields($ar);

			$csvout->print($outh, $ar);
			$rows_written++;
		}
		$self->_close_read();

		$do_status_reset = 1
	}

	$self->_close_outh();

	if ($verbose) {
		$self->_print("-- $out_file writing end: $rows_written row(s) written\n");
		for my $k (sort keys %stats) {
			$self->_printf("   %7d %s\n", $stats{$k}, $k);
		}
	}

	if ($do_status_reset) {
		return undef unless $self->_status_reset();
	}
	return $self;
}



#
# * *** ***************************************************************************
# * *** ***************************************************************************
# * OBJ ***************************************************************************
# * *** ***************************************************************************
# * *** ***************************************************************************
#

#
# The subs below assume Text::AutoCSV can be in status S4 = all in memory.
#


sub get_keys {
	my $self = shift;
	validate_pos(@_);

	return undef unless $self->_status_forward('S4');

	my $last_key = @{$self->{_flat}} - 1;
	my @r = (0..$last_key);

	return @r;
}

sub get_row_ar {
	my $self = shift;
	validate_pos(@_, {type => SCALAR});
	my ($key) = @_;

	return undef unless $self->_status_forward('S4');

	unless (defined($key)) {
		$self->_print_error("get_row_ar(): \$key is not defined!");
		return undef;
	}

	$self->_print_error("unknown row '$key'") unless defined($self->{_flat}->[$key]);
	return $self->{_flat}->[$key];
}

sub get_row_hr {
	my $self = shift;
	validate_pos(@_, {type => SCALAR});
	my ($key) = @_;

	my $ar = $self->get_row_ar($key);
	return undef unless defined($ar);

	return $self->_ar_to_hr($ar);
}

	#
	# Could be made much more efficient (directly read $self->{_flat} instead of calling get_row_hr
	# that itself calls get_row_ar).
	# I leave it as is because get_hr_all is not good practice (it is not scalable), it was
	# primarily done to ease test plan.
	#
	# By the way I may make it one day not available by default, requesting caller to tune some
	# variable (like { $Text::AutoCSV::i_am_the_test_plan = 1 }) to expose it.
	#
sub get_hr_all {
	my $self = shift;
	validate_pos(@_);

	my @resp;
	$self->reset_next_record_hr();
	while (my $hr = $self->get_next_record_hr()) {
		push @resp, $hr;
	}
	return @resp;
}

sub get_recnum {
	my $self = shift;
	validate_pos(@_);

	return -1 unless $self->{_read_in_progress};
	return _get_def($self->{_row_read}, -1);
}

sub _check_for_search {
	my ($self, $field) = @_;
	return undef unless $self->_status_forward('S4');

	return 1 if exists $self->{_named_fields}->{$field};
	$self->_print_error("search: unknown field '$field'",
		0, ERR_UNKNOWN_FIELD, $self->{_named_fields});
}

sub get_cell {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => SCALAR});
	my ($key, $field) = @_;

	return undef unless $self->_check_for_search($field);
	my $row = $self->get_row_hr($key);
	return $row unless defined($row);
	return $row->{$field};
}

sub get_values {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => UNDEF | CODEREF, optional => 1});
	my ($field, $filter_subref) = @_;

	return undef unless $self->_check_for_search($field);

	my @values;
	$self->reset_next_record_hr();
	while (my $hr = $self->get_next_record_hr()) {
		if (defined($filter_subref)) {
			local $_ = $hr->{$field};
			next unless $filter_subref->();
		}
		push @values, $hr->{$field};
	}
	return @values;
}

sub _get_hash_and_projector {
	my ($self, $field, $arg_opts) = @_;

	my $_debug = $self->{_debug};
	my $_debugh = $self->{_debugh};

	my %opts = %{$arg_opts} if defined($arg_opts);

	my $opt_case = _get_def($opts{'case'}, $self->{search_case}, $DEF_SEARCH_CASE);
	my $opt_trim = _get_def($opts{'trim'}, $self->{search_trim}, $DEF_SEARCH_TRIM);
	my $opt_ignore_empty = _get_def($opts{'ignore_empty'}, $self->{search_ignore_empty},
		$DEF_SEARCH_IGNORE_EMPTY);
	my $opt_ignacc = _get_def($opts{'ignore_accents'}, $self->{search_ignore_accents},
		$DEF_SEARCH_IGNORE_ACCENTS);

	my $opts_stringified = $opt_case . $opt_trim . $opt_ignore_empty . $opt_ignacc;
	my $hash_name = "_h${field}_${opts_stringified}";
	my $projector_name = "_p${field}_${opts_stringified}";

	if (exists $self->{$hash_name} and exists $self->{$projector_name}) {
		print($_debugh "Search by key '$field': using existing hash and projector (" .
			"$hash_name, $projector_name)\n") if $_debug;
		return ($hash_name, $projector_name);
	} elsif (exists $self->{$hash_name} or exists $self->{$projector_name}) {
		confess "Man, check your $PKG module code now!";
	}

	print($_debugh "Search by key '$field': building hash\n") if $_debug;

#
# Projectors
#
# The projector contains subs to derivate the search key from the field value.
# At the moment it is used to manage with case / without case searches and with trim / without trim
# searches (meaning, ignoring spaces at beginning and end of fields)
#
# Why naming it a projector?
#   Because if you run it twice on a value, the second run should produce the same result, meaning:
#   p(p(x)) = p(x) whatever x
#

	my @projectors;

		# Add case removal in the projector function list
	push @projectors, sub { return lc(shift); } unless $opt_case;

		# Add trim in the projector function list
	if ($opt_trim) {
		push @projectors,
		sub {
			my $v = shift;
			$v =~ s/^\s+|\s+$//g;
			return $v;
		};
	}

		# Add remove_accents in the projector function list
	push @projectors, sub { return remove_accents(shift); } if $opt_ignacc;

	my $projector = sub {
		my $v = _get_def($_[0], '');
		$v = $_->($v) foreach (@projectors);
		return $v;
	};

#
# Filter
#
# As opposed to projectors above (where a search key is transformed), the idea now is to ignore
# certain keys when doing a search.
# At the moment, used to manage searches with / without empty values.
#
# That is to say: shall we use empty value as a regular value to search on, as in
#   my @results = $self->search('FIELDNAME', '');
# ?
#
# Right now we don't use an array-based construct, that'd allow to chain filters with one another
# (as we now have only one filter to deal with), later, we may use an array of filters, as done with
# projectors...
#

	my $filter;
	if ($opt_ignore_empty) {
		$filter = sub { return $_[0] ne ''; }
	} else {
		$filter = sub { return 1; }
	}

	my %h;
	my $k;
	$self->reset_next_record_hr();
	while (my $hr = $self->get_next_record_hr(\$k)) {
		my $kv = $hr->{$field};
		my $p = $projector->($kv);
		unless ($filter->($p)) {
			print($_debugh "Ignoring key value '$p' in hash build\n") if $_debug;
			next;
		}
		push @{$h{$p}}, $k;
	}
	for (keys %h) {
		@{$h{$_}} = sort { $a <=> $b } @{$h{$_}};
	}

	$self->{_hash_build_count}++;
	$self->{$hash_name} = { %h };
	$self->{$projector_name} = $projector;
	return ($hash_name, $projector_name);
}

sub _get_hash_build_count {
	my $self = shift;

	return _get_def($self->{_hash_build_count}, 0);
}

sub search {
	my $self = shift;
	validate_pos(@_,
		{type => SCALAR}, {type => UNDEF | SCALAR}, {type => UNDEF | HASHREF, optional => 1});
	my ($field, $value, $param_opts) = @_;

	my $croak_if_error = $self->{croak_if_error};

		#
		# FIXME?
		#   A bit overkill to check options each time search is called...
		#   To be thought about.
		#

	my @tmp = %{$param_opts} if $param_opts;
	my %opts = validate(@tmp, $SEARCH_VALIDATE_OPTIONS);

	return undef unless $self->_check_for_search($field);

#    $self->_print_error("undef value in search call") if !defined($value);
	$value = '' unless defined($value);

	my ($hash_name, $projector_name) = $self->_get_hash_and_projector($field, \%opts);

	my $ret = $self->{$hash_name}->{$self->{$projector_name}->($value)};

	return $ret if defined($ret);
	return [ ];
}

sub search_1hr {
	my $self = shift;
	validate_pos(@_,
		{type => SCALAR}, {type => UNDEF | SCALAR}, {type => UNDEF | HASHREF, optional => 1});
	my ($field, $value, $arg_opts) = @_;

	my $r = $self->search($field, $value, $arg_opts);

	return undef unless defined($r->[0]);

	my $opts = _get_def($arg_opts, { });
	my $opt_ignore_ambiguous = _get_def($opts->{'ignore_ambiguous'},
		$self->{'search_ignore_ambiguous'}, $DEF_SEARCH_IGNORE_AMBIGUOUS);

	return undef if @{$r} >= 2 and !$opt_ignore_ambiguous;
	return $self->get_row_hr($r->[0]);
}

sub vlookup {
	my $self = shift;
	validate_pos(@_, {type => SCALAR}, {type => UNDEF | SCALAR}, {type => SCALAR},
		{type => UNDEF | HASHREF, optional => 1});
	my ($searched_field, $value, $target_field, $arg_opts) = @_;

	my $r = $self->search($searched_field, $value, $arg_opts);
	return undef unless $self->_check_for_search($target_field);

	my $opts = _get_def($arg_opts, { });
	unless (defined($r->[0])) {
		return (exists $opts->{'value_if_not_found'} ? $opts->{'value_if_not_found'} :
			$self->{'search_value_if_not_found'});
	} elsif (@{$r} >= 2) {
		my $opt_ignore_ambiguous = _get_def($opts->{'ignore_ambiguous'},
			$self->{'search_ignore_ambiguous'}, $DEF_SEARCH_IGNORE_AMBIGUOUS);
		return (exists $opts->{'value_if_ambiguous'} ? $opts->{'value_if_ambiguous'} :
			$self->{'search_value_if_ambiguous'}) if !$opt_ignore_ambiguous;
	}

	return $opts->{value_if_found} if exists $opts->{value_if_found};
	return $self->{search_value_if_found} if exists $opts->{search_value_if_found};

	my $hr = $self->get_row_hr($r->[0]);

	return $hr->{$target_field};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::AutoCSV - helper module to automate the use of Text::CSV

=head1 VERSION

version 1.1.8

=head1 SYNOPSIS

By default, Text::AutoCSV will detect the following characteristics of the input:

- The separator, among ",", ";" and "\t" (tab)

- The escape character, among '"' (double-quote) and '\\' (backslash)

- Try UTF-8 and if it fails, fall back on latin1

- Read the header line and compute field names

- If asked to (see L</fields_dates_auto>), detect any field that contains a DateTime value, trying
20 date formats, possibly followed by a time (6 time formats tested)

- If asked to (see L</fields_dates>), detect DateTime format of certain fields, croak if no DateTime
format can be worked out

- Fields identified as containing a DateTime value (L</fields_dates_auto> or L</fields_dates>) are
stored as DateTime objects by default

Text::AutoCSV also provides methods to search on fields (using cached hash tables) and it can
populate the value of "remote" fields, made from joining 2 CSV files with a key-value search

=head2 General

	use Text::AutoCSV;

	Text::AutoCSV->new()->write();    # Read CSV data from std input, write to std output

	Text::AutoCSV->new(in_file => 'f.csv')->write(); # Read CSV data from f.csv, write to std output

		# Read CSV data from f.csv, write to g.csv
	Text::AutoCSV->new(in_file => 'f.csv', out_file => 'g.csv')->write();

		# "Rewrite" CSV file by printing out records as a list (separated by line breaks) of field
		# name followed by its value.
	my $csv = Text::AutoCSV->new(in_file => 'in.csv', walker_hr => \&walk);
	my @cols = $csv->get_fields_names();
	$csv->read();
	sub walk {
		my %rec = %{$_[0]};
		for (@cols) {
			next if $_ eq '';
			print("$_ => ", $rec{$_}, "\n");
		}
		print("\n");
	}

=head2 OBJ-ish functions

		# Identify column internal names with more flexibility as the default mechanism
	my $csv = Text::AutoCSV->new(in_file => 'zips.csv',
		fields_hr => {'CITY' => '^(city|town)', 'ZIPCODE' => '^zip(code)?$'});
		# Get zipcode of Claix
	my $z = $csv->vlookup('CITY', ' claix    ', 'ZIPCODE');

	my $csv = Text::AutoCSV->new(in_file => 'zips.csv');
		# Get zipcode of Claix
	my $z = $csv->vlookup('CITY', ' claix    ', 'ZIPCODE');
		# Same as above, but vlookup is strict for case and spaces around
	my $csv = Text::AutoCSV->new(in_file => 'zips.csv', search_case => 1, search_trim => 0);
	my $z = $csv->vlookup('CITY', 'Claix', 'ZIPCODE');

		# Create field 'MYCITY' made by taking pers.csv' ZIP column value, looking it up in the
		# ZIPCODE columns of zips.csv, taking CITY colmun value and naming it 'MYCITY'. Output is
		# written in std output.
		# If a zipcode is ambiguous, say it.
	Text::AutoCSV->new(in_file => 'pers.csv')
		->field_add_link('MYCITY', 'ZIP->ZIPCODE->CITY', 'zips.csv',
			{ ignore_ambiguous => 0, value_if_ambiguous => '<duplicate zipcode found!>' })->write();

		# Note the above can also be written using Text::AutoCSV level attributes:
	Text::AutoCSV->new(in_file => 'pers.csv',
		search_ignore_ambiguous => 0, search_value_if_ambiguous => '<duplicate zipcode found!>')
		->field_add_link('MYCITY', 'ZIP->ZIPCODE->CITY', 'zips.csv')->write();

		# Create 'MYCITY' field as above, then display some statistics
	my $nom_compose = 0;
	my $zip_not_found = 0;
	Text::AutoCSV->new(in_file => 'pers.csv', walker_hr => \&walk)
		->field_add_link('MYCITY', 'ZIP->ZIPCODE->CITY', 'zips.csv')->read();
	sub walk {
		my $hr = shift;
		$nom_compose++ if $hr->{'NAME'} =~ m/[- ]/;
		$zip_not_found++ unless defined($hr->{'MYCITY'});
	}
	print("Number of persons with a multi-part name: $nom_compose\n");
	print("Number of persons with unknown zipcode: $zip_not_found\n");

=head2 Updating

	Text::AutoCSV->new(in_file => 'names.csv', out_file => 'ucnames.csv',
		read_post_update_hr => \&updt)->write();
	sub updt { $_[0]->{'LASTNAME'} =~ s/^.*$/\U&/; }

	Text::AutoCSV->new(in_file => 'squares.csv', out_file => 'checkedsquares.csv',
		out_filter => \&wf)->write();
	sub wf { return ($_[0]->{'X'} ** 2 == $_[0]->{'SQUAREOFX'}); }

		# Add a field for the full name, made of the concatenation of the
		# first name and the last name.
		# Also display stats about empty full names.
	Text::AutoCSV->new(in_file => 'dirpeople.csv', out_file => 'dirwithfn.csv', verbose => 1)
		->field_add_computed('FULLNAME', \&calc_fn)->write();
	sub calc_fn {
		my ($field, $hr, $stats) = @_;
		my $fn = $hr->{'FIRSTNAME'} . ' ' . uc($hr->{'LASTNAME'});
		$stats->{'empty full name'}++ if $fn eq ' ';
		return $fn;
	}

		# Read a file with a lot of columns and keep only 2 columns in output
	Text::AutoCSV->new(in_file => 'big.csv', out_file => 'addr.csv',
		out_fields => ['NAME', 'ADDRESS'])
		->out_header('ADDRESS', 'Postal Address')
		->write();

=head2 Datetime management

		# Detect any field containing a DateTime value and convert it to yyyy-mm-dd whatever the
		# input format is.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', fields_dates_auto => 1,
		out_dates_format => '%F')->write();

		# Detect any field containing a DateTime value and convert it to a US DateTime whatever the
		# input format is.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', fields_dates_auto => 1,
		out_dates_format => '%b %d, %Y, %I:%M:%S %p', out_dates_locale => 'en')->write();

		# Find dates of specific formats and convert it into yyyy-mm-dd
	Text::AutoCSV->new(in_file => 'raw.csv', out_file => 'cooked.csv',
		dates_formats_to_try => ['%d_%m_%Y', '%m_%d_%Y', '%Y_%m_%d'],
		out_dates_format => '%F')->write();

		# Take the dates on columns 'LASTLOGIN' and 'CREATIONDATE' and convert it into French dates
		# (day/month/year).
		# Text::AutoCSV will croak if LASTLOGIN or CREATIONDATE do not contain a DateTime format.
		# By default, Text::AutoCSV will try 20 different formats.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv',
		fields_dates => ['LASTLOGIN', 'CREATIONDATE'], out_dates_format => '%d/%m/%Y')->write();

		# Convert 2 DateTime fields into unix standard epoch
		# Write -1 if DateTime is empty.
	sub toepoch { return $_->epoch() if $_; -1; }
	Text::AutoCSV->new(in_file => 'stats.csv', out_file => 'stats-epoch.csv',
		fields_dates => ['ATIME', 'MTIME'])
		->in_map('ATIME', \&toepoch)
		->in_map('MTIME', \&toepoch)
		->write();

		# Do the other way round from above: convert 2 fields containing unix standard epoch into a
		# string displaying a human-readable DateTime.
	my $formatter = DateTime::Format::Strptime->new(pattern => 'DATE=%F, TIME=%T');
	sub fromepoch {
		return $formatter->format_datetime(DateTime->from_epoch(epoch => $_)) if $_ >= 0;
		'';
	}
	$csv = Text::AutoCSV->new(in_file => 'stats-epoch.csv', out_file => 'stats2.csv')
		->in_map('ATIME', \&fromepoch)
		->in_map('MTIME', \&fromepoch)
		->write();

=head2 Miscellaneous

	use Text::AutoCSV 'remove_accents';
		# Output 'Francais: etre elementaire, Tcheque: sluzba dum' followed by a new line.
	print remove_accents("Français: être élémentaire, Tchèque: služba dům"), "\n";

=for Pod::Coverage ERR_UNKNOWN_FIELD

=head1 NAME

Text::AutoCSV - helper module to automate the use of Text::CSV

=head1 METHODS

=head2 new

	my $csv = Text::AutoCSV->new(%attr);

(Class method) Returns a new instance of Text::AutoCSV. The object attributes are described by the
hash C<%attr> (can be empty).

Currently the following attributes are available:

=over 4

=item Preliminary note about L</fields_hr>, L</fields_ar> and L</fields_column_names> attributes

By default, Text::AutoCSV assumes the input has a header and will use the field values of this first
line (the header) to work out the column internal names. These internal names are used everywhere in
Text::AutoCSV to designate columns.

The values are transformed as follows:

- All accents are removed using the exportable function L</remove_accents>.

- Any non-alphanumeric character is removed (except underscore) and all letters are switched to
upper case. The regex to do this is

	s/[^[:alnum:]_]//gi; s/^.*$/\U$&/;

Thus a header line of

	'Office Number 1,Office_2,Personal Number'

will produce the internal column names

	'OFFICENUMBER1' (first column)

	'OFFICE_2' (second column)

	'PERSONALNUMBER' (third column).

The attribute L</fields_hr>, L</fields_ar> or L</fields_column_names> (only one of the three is
useful at a time) allows to change this behavior.

B<NOTE>

The removal of accents is *not* a conversion to us-ascii, see L</remove_accents> for details.

=item Preliminary note about fields reading

Functions that are given a field name (L</get_cell>, L</vlookup>, L</field_add_copy>, ...) raise an
error if the field requested does not exist.

B<SO WILL THE HASHREFS GIVEN BY Text::AutoCSV:> when a function returns a hashref (L</search_1hr>,
L</get_row_hr>, ...), the hash is locked with the C<lock_keys> function of C<Hash::Util>. Any
attempt to read a non-existing key from the hash causes a croak. This feature is de-activated if you
specified C<croak_if_error =E<gt> 0> when creating Text::AutoCSV object.

=item in_file

The name of the file to read CSV data from.

If not specified or empty, read standard input.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv');

=item inh

File handle to read CSV data from.
Normally you don't want to specify this attribute.

C<inh> is useful if you don't like the way Text::AutoCSV opens the input file for you.

Example:

	open my $inh, "producecsv.sh|";
	my $csv = Text::AutoCSV->new(inh => $inh);

=item encoding

Comma-separated list of encodings to try to read input.

Note that finding the correct encoding of any given input is overkill. This script just tries
encodings one after the other, and selects the first one that does not trigger a warning during
reading of input. If all produce warnings, select the first one.

The encoding chosen is used in output, unless attribute L</out_encoding> is specified.

Value by default: 'UTF-8,latin1'

B<IMPORTANT>

If one tries something like C<encoding =E<gt> 'latin1,UTF-8'>, it'll almost never detect UTF-8
because latin1 rarely triggers warnings during reading. It tends to be also true with encodings like
UTF-16 that can remain happy with various inputs (sometimes resulting in Western languages turned
into Chinese text).

Ultimately this attribute should be used with a unique value. The result when using more than one
value can produce weird results and should be considered B<experimental>.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'w.csv', encoding => 'UTF-16');

=item via

Adds a C<via> to the file opening instruction performed by Text::AutoCSV. You don't want to use it
under normal circumstances.

The value should start with a ':' character (Text::AutoCSV won't add one for you).

Value by default: none

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', via => ':raw:perlio:UTF-32:crlf');

=item dont_mess_with_encoding

If true, just ignore completely encoding and don't try to alter I/O operations with encoding
considerations (using C<binmode> instruction). Note that if inh attribute is specified, then
Text::AutoCSV will consider the caller manages encoding for himself and dont_mess_with_encoding will
be automatically set, too.

B<IMPORTANT>

This attribute does not mean perl will totally ignore encoding and would consider character strings
as bytes for example. The meaning of L</dont_mess_with_encoding> is that Text::AutoCSV itself will
totally ignore encoding matters, and leave it entirely to Perl' default.

Value by default:

	0 if inh attribute is not set
	1 if inh attribute is set

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', dont_mess_with_encoding => 1);

=item sep_char

Specify the CSV separator character. Turns off separator auto-detection. This attribute is passed as
is to C<Text::CSV-E<gt>new()>.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', sep_char => ';');

=item quote_char

Specify the field quote character. This attribute is passed as is to C<Text::CSV-E<gt>new()>.

Value by default: double quote ('"')

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', quote_char => '\'');

=item escape_char

Specify the escape character. Turns off escape character auto-detection. This attribute is passed as
is to C<Text::CSV-E<gt>new()>.

Value by default: backslash ('\\')

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', escape_char => '"');

=item in_csvobj

Text::CSV object to use.
Normally you don't want to specify this attribute.

By default, Text::AutoCSV will manage creating such an object and will work hard to detect the
parameters it requires.

Defining C<in_csvobj> attribute turns off separator character and escape character auto-detection.

Using this attribute workarounds Text::AutoCSV philosophy a bit, but you may need it in case
Text::AutoCSV behavior is not suitable for Text::CSV creation.

Example:

	my $tcsv = Text::CSV->new();
	my $acsv = Text::AutoCSV->new(in_file => 'in.csv', in_csvobj => $tcsv);

=item has_headers

If true, Text::AutoCSV assumes the input has a header line.

Value by default: 1

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', has_headers => 0);

=item fields_hr

(Only if input has a header line) Hash ref that contains column internal names along with a regular
expression to find it in the header line.
For example if you have:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv',
		fields_hr => {'PHONE OFFICE' => '^office phone nu',
		              'PHONE PERSONAL' => '^personal phone nu'});

And the header line is

	'Personal Phone Number,Office Phone Number'

the column name 'PHONE OFFICE' will designate the second column and the column name 'PHONE PERSONAL'
will designate the first column.

You can choose column names like 'Phone Office' and 'Phone Personal' as well.

The regex search is case insensitive.

=item fields_ar

(Only if input has a header line) Array ref that contains column internal names. The array is used
to create a hash ref of the same kind as L</fields_hr>, by wrapping the column name in a regex. The
names are surrounded by a leading '^' and a trailing '$', meaning, the name must match the entire
field name.

For example

	fields_ar => ['OFFICENUMBER', 'PERSONALNUMBER']

is strictly equivalent to

	fields_hr => {'OFFICENUMBER' => '^officenumber$', 'PERSONALNUMBER' = '^personalnumber$'}

The regex search is case insensitive.

C<fields_ar> is useful if the internal names are identical to the file column names. It avoids
repeating the names over and over as would happen if using L</fields_hr> attribute.

I<NOTE>

You might wonder why using fields_ar as opposed to Text::AutoCSV default' mechanism. There are two
reasons for that:

1- Text::AutoCSV removes spaces from column names, and some people may want another behavior. A
header name of 'Phone Number' will get an internal column name of 'PHONENUMBER' (default behavior,
if none of fields_hr, fields_ar and fields_column_names attributes is specified), and one may prefer
'PHONE NUMBER' or 'phone number' or whatsoever.

2- By specifying a list of columns using either of fields_hr or fields_ar, you not only map column
names as found in the header line to internal column names: you also I<request> these columns to be
available. If one of the requested columns cannot be found, Text::AutoCSV will croak (default) or
print an error and return an undef object (if created with C<croak_if_error =E<gt> 0>).

=item fields_column_names

Array ref of column internal names, in the order of columns in file. This attribute works like the
C<column_names> attribute of Text::CSV. It'll just assign names to columns one by one, regardless of
what the header line contains. It'll work also if the file has no header line.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv',
		fields_column_names => ['My COL1', '', 'My COL3']);

=item out_file

Output file when executing the L</write> method.

If not specified or empty, write to standard output.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv');

=item outh

File handle to write CSV data to when executing the L</write> method.
Normally you don't want to specify this attribute.

C<outh> is useful if you don't like the way Text::AutoCSV opens the output file for you.

Example:

	my $outh = open "myin.csv', ">>";
	my $csv = Text::AutoCSV->new(in_file => 'in.csv', has_headers => 0, outh => $outh);

=item out_encoding

Enforce the encoding of output.

Value by default: input encoding

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv',
		out_encoding => 'UTF-16');

=item out_utf8_bom

Enforce BOM (Byte-Order-Mark) on output, when it is UTF8. If output encoding is not UTF-8, this
attribute is ignored.

B<NOTE>

UTF-8 needs no BOM (there is no Byte-Order in UTF-8), and in practice, UTF8-encoded files rarely
have a BOM.

Using this attribute is not recommended. It is provided for the sake of completeness, and also to
produce Unicode files Microsoft EXCEL will be happy to read.

At first sight it would seem more logical to make EXCEL happy with something like this:

	out_encoding => 'UTF-16'

But... While EXCEL will identify UTF-16 and read it as such, it will not take into account the BOM
found at the beginning. In the end the first cell will have 2 useless characters prepended. The only
solution the author knows to workaround this issue if to use UTF-8 as output encoding, and enforce a
BOM. That is, use:

	..., out_encoding => 'UTF-8', out_utf8_bom => 1, ...

=item out_sep_char

Enforce the output CSV separator character.

Value by default: input separator

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', out_sep_char => ',');

=item out_quote_char

Enforce the output CSV quote character.

Value by default: input quote character

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', out_quote_char => '"');

=item out_escape_char

Enforce the output CSV escape character.

Value by default: input escape character

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv',
		out_escape_char_char => '\\');

=item out_always_quote

If true, quote all fields of output (set always_quote of Text::CSV).

If false, don't quote all fields of output (don't set C<always_quote> of Text::CSV).

Value by default: same as what is found in input

While reading input, Text::AutoCSV works out whether or not all fields were quoted. If yes, then the
output Text::CSV object has the always_quote attribute set, if no, then the output Text::CSV object
does not have this attribute set.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', out_always_quote => 1);

=item out_has_headers

If true, when writing output, write a header line on first line.

If false, when writing output, don't write a header line on first line.

Value by default: same as has_headers attribute

Example 1

Read standard input and write to standard output, removing the header line.

	Text::AutoCSV->new(out_has_headers => 0)->write();

Example 2

Read standard input and write to standard output, adding a header line.

	Text::AutoCSV->new(fields_column_names => ['MYCOL1', 'MYCOL2'], out_has_headers => 1)->write();

=item no_undef

If true, non-existent column values are set to an empty string instead of undef. It is also done on
extra fields that happen to have an undef value (for example when the target of a linked field is
not found).

Note this attribute does not work on callback functions output set with L</in_map>: for example
empty DateTime values (on fields identified as containing a date/time, see C<dates_*> attributes
below) are set to C<undef>, even while C<no_undef> is set. Indeed setting it to an empty string
while non-empty values would contain a Datetime object would not be clean. An empty value in a
placeholder containing an object must be undef.

Since version 1.1.5 of Text::AutoCSV, C<no_undef> is examined when sending parameter ($_) to
L</in_map> callback: an undef value is now passed as is (as undef), unless C<no_undef> is set. If
C<no_undef> is set, and field value is undef, then $_ is set to the empty string ('') when calling
callback defined by L</in_map>. This new behavior was put in place to be consistent with what is
being done with DateTime values.

Value by default: 0

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', no_undef => 1);

=item read_post_update_hr

To be set to a ref sub. Each time a record is read from input, call C<read_post_update_hr> to update
the hash ref of the record. The sub is called with 2 arguments: the hash ref to the record value and
the hash ref to stats.

The stats allow to count events and are printed in the end of reading in case Text::AutoCSV is
called in verbose mode (C<verbose =E<gt> 1>).

For example, the C<read_post_update_hr> below will turn column 'CITY' values in upper case and count
occurences of empty cities in stat display:

	Text::AutoCSV->new(in_file => 'addresses.csv', read_post_update_hr => \&updt, verbose => 1)
		->write();
	sub updt {
		my ($hr, $stats) = @_;
		$hr->{'CITY'} =~ s/^.*$/\U$&/;
		$stats->{'empty city encountered'}++ if $hr->{'CITY'} eq '';
	}

B<IMPORTANT>

You cannot create a field this way. To create a field, you have to use the member functions
L</field_add_link>, L</field_add_copy> or L</field_add_computed>.

B<NOTE>

If you wish to manage some updates at field level, consider registering update functions with
L</in_map> and L</out_map> member functions. These functions register callbacks that work at field
level and with $_ variable (thus the callback function invoked is AutoCSV-agnostic).

L</in_map> updates a field after read, L</out_map> updates the field content before writing it.

=item walker_hr

To set to a sub ref that'll be executed each time a record is read from input. It is executed after
L</read_post_update_hr>. The sub is called with 2 arguments: the hash ref to the record value and
the hash ref to stats.

Note L</read_post_update_hr> is meant for updating record fields just after reading, whereas
L</walker_hr> is read-only.

The stats allow to count events and are printed in the end of reading in case Text::AutoCSV is
called in verbose mode (C<verbose =E<gt> 1>). If the L</verbose> attribute is not set, the stats are
not displayed, however you can get stats by calling the get_stats function.

The example below will count in the stats the number of records where the 'CITY' field is empty.
Thanks to C<verbose =E<gt> 1> attribute, at the end of reading the stats are displayed.

	my $csv = Text::AutoCSV->new(in_file => 'addresses.csv', walker_hr => \&walk1,
		verbose => 1)->read();
	sub walk1 {
		my ($hr, $stats) = @_;
		$stats->{'empty city'}++ if $hr->{'CITY'} eq '';
	}

=item walker_ar

To set to a sub ref that'll be executed each time a record is read from input. It is executed after
L</read_post_update_hr>. The sub is called with 2 arguments: the array ref to the record value and
the hash ref to stats.

Note L</read_post_update_hr> is meant for updating record fields just after reading, whereas
C<walker_hr> is read-only.

The stats allow to count events and are printed in the end of reading in case Text::AutoCSV is
called in verbose mode (C<verbose =E<gt> 1>). If the L</verbose> attribute is not set, the stats are
lost.

The array ref contains values in their natural order in the CSV. To be used with the column names,
you have to use L</get_fields_names> member function.

The example below will count in the stats the number of records where the 'CITY' field is empty.
Thanks to C<verbose =E<gt> 1> attribute, at the end of reading the stats are displayed. It produces
the exact same result as the example in walker_hr attribute, but it uses walker_ar.

	use List::MoreUtils qw(first_index);
	my $csv = Text::AutoCSV->new(in_file => 'addresses.csv', walker_ar => \&walk2, verbose => 1);
	my @cols = $csv->get_fields_names();
	my $idxCITY = first_index { /^city$/i } @cols;
	die "No city field!??" if $idxCITY < 0;
	$csv->read();
	sub walk2 {
		my ($ar, $stats) = @_;
		$stats->{'empty city'}++ if $ar->[$idxCITY] eq '';
	}

=item write_filter_hr

Alias of L</out_filter>.

=item out_filter

To be set to a ref sub. Before writing a record to output, C<out_filter> is called and the record
gets writen only if C<out_filter> return value is true. The sub is called with 1 argument: the hash
ref to the record value.

For example, if you want to output only records where the 'CITY' column value is Grenoble:

	Text::AutoCSV->new(in_file => 'addresses.csv', out_file => 'grenoble.csv',
		out_filter => \&filt)->write();
	sub filt {
		my $hr = shift;
		return 1 if $hr->{'CITY'} =~ /^grenoble$/i;
		return 0;
	}

=item write_fields

Alias of L</out_fields>.

=item out_fields

Set to an array ref. List fields to write to output.

Fields are written in their order in the array ref, the first CSV column being the first element in
the array, and so on. Fields not listed in B<out_fields> are not written in output.

You can use empty field names to have empty columns in output.

Example:

	Text::AutoCSV->new(in_file => 'allinfos.csv', out_file => 'only-addresses.csv',
		out_fields => [ 'NAME', 'ADDRESS' ] )->write();

=item search_case

If true, searches are case sensitive by default. Searches are done by the member functions
L</search>, L</search_1hr>, L</vlookup>, and linked fields (L</field_add_link>).

The search functions can also be called with the option L</case>, that takes precedence over the
object-level C<search_case> attribute value. See L</vlookup> help.

Value by default: 0 (by default searches are case insensitive)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', search_case => 1);

=item search_trim

If true, searches ignore the presence of leading or trailing spaces in values.

The search functions can also be called with the option L</trim>, that takes precedence over the
object-level C<search_trim> attribute value. See L</vlookup> help.

Value by default: 1 (by default searches ignore leading and trailing spaces)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', search_trim => 0);

=item search_ignore_empty

If true, empty fields are not included in the search indexes.

The search functions can also be called with the option L</ignore_empty>, that takes precedence over
the object-level C<search_ignore_empty> attribute value. See L</vlookup> help.

Value by default: 1 (by default, search of the value '' will find nothing)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', search_ignore_empty => 0);

=item search_ignore_accents

If true, accents are ignored by search indexes.

The search functions can also be called with the option L</ignore_accents>, that takes precedence
over the object-level C<search_ignore_accents> attribute value. See L</vlookup> help.

Value by default: 1 (by default, accents are ignored by search functions)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', search_ignore_accents => 0);

=item search_value_if_not_found

When a search is done with a unique value to return (field_add_link member function behavior or
return value of vlookup), default value of option L</value_if_not_found>. See L</vlookup>.

=item search_value_if_found

When a search is done with a unique value to return (field_add_link member function behavior or
return value of vlookup), default value of option L</value_if_found>. See L</vlookup>.

B<IMPORTANT>

This attribute is extremly unusual. Once you've provided it, all vlookups and the target field value
of fields created with field_add_link will all be populated with the value provided with this
option.

Don't use it unless you know what you are doing.

=item search_ignore_ambiguous

When a search is done with a unique value to return (field_add_link member function behavior or
return value of search_1hr and vlookup), default value of option L</ignore_ambiguous>. See
L</vlookup>.

=item search_value_if_ambiguous

When a search is done with a unique value to return (field_add_link member function behavior or
return value of vlookup), default value of option L</value_if_ambiguous>. See L</vlookup>.

=item fields_dates

Array ref of field names that contain a date.

Once the formats of these fields is known (auto-detection by default), each of these fields will get
a specific L</in_map> sub that converts the text in a DateTime object and a L</out_map> sub that
converts back from DateTime to text.

B<NOTE>

The L</out_map> given to a DateTime field is "defensive code": normally, L</in_map> converts text
into a DateTime object and L</out_map> does the opposite, it takes a DateTime object and converts it
to text. If ever L</out_map> encounters a value that is not a DateTime object, it'll just stringify
it (evaluation in a string context), without calling its DateTime formatter.

If the format cannot be detected for a given field, output an error message and as always when an
error occurs, croak (unless L</croak_if_error> got set to 0).

Value by default: none

Example:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv',
		fields_dates => ['LASTLOGIN', 'CREATIONDATE']);

=item fields_dates_auto

Boolean value. If set to 1, will detect dates formats on all fields. Fields in which a DateTime
format got detected are then managed as if they had been being listed in L</fields_dates> attribute:
they get an appropriate L</in_map> sub and a L</out_map> sub to convert to and from DateTime (see
L</fields_dates> attribute above).

C<fields_dates_auto> looks for DateTime on all fields, but it expects nothing: it won't raise an
error if no field is found that contains DateTime.

Value by default: 0

Example:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv', fields_dates_auto => 1);

=item dates_formats_to_try

Array ref of string formats.

Text::AutoCSV has a default built-in list of 20 date formats to try and 6 time formats (also it'll
combine any date format with any time format).

C<dates_formats_to_try> will replace Text::AutoCSV default format-list will the one you specify, in
case the default would not produce the results you expect.

The formats are written in Strptime format.

Value by default (see below about the role of the pseudo-format ''):

	[ '',
	'%Y-%m-%d',
	'%Y.%m.%d',
	'%Y/%m/%d',
	'%m.%d.%y',
	'%m-%d-%Y',
	'%m.%d.%Y',
	'%m/%d/%Y',
	'%d-%m-%Y',
	'%d.%m.%Y',
	'%d/%m/%Y',
	'%m-%d-%y',
	'%m/%d/%y',
	'%d-%m-%y',
	'%d.%m.%y',
	'%d/%m/%y',
	'%Y%m%d%H%M%S',
	'%b %d, %Y',
	'%b %d %Y',
	'%b %d %T %Z %Y',
	'%d %b %Y',
	'%d %b, %Y' ]

B<IMPORTANT>

The empty format (empty string) has a special meaning: when specified, Text::AutoCSV will be able to
identify fields that contain only a time (not preceeded by a date).

B<Note>

Format identification is over only when there is no more ambiguity. So the usual pitfall of US
versus French dates (month-day versus day-month) gets resolved only when a date is encountered that
disambiguates it (a date of 13th of the month or later).

Example with a weird format that uses underscores to separate elements, using either US (month, day,
year), French (day, month, year), or international (year, month, day) order:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv',
		dates_formats_to_try => ['%d_%m_%Y', '%m_%d_%Y', '%Y_%m_%d']);

=item dates_formats_to_try_supp

Same as L</dates_formats_to_try> but instead of replacing the default list of formats used during
detection, it is added to this default list.

You want to use this attribute if you need a specific DateTime format while continuing to benefit
from the default list.

B<IMPORTANT>

Text::AutoCSV will identify a given Datetime format only when there is no ambiguity, meaning, one
unique Datetime format matches (all other failed). Adding a format that already exists in the
default list will prevent the format from being identified, as it'll always be ambiguous. See
L</dates_formats_to_try> for the default list of formats.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv',
		dates_formats_to_try_supp => ['%d_%m_%Y', '%m_%d_%Y', '%Y_%m_%d']);

=item dates_ignore_trailing_chars

If set to 1, DateTime auto-detection will ignore trailing text that may follow detected
DateTime-like text.

Value by default: 1 (do ignore trailing chars)

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv', dates_ignore_trailing_chars => 0);

=item dates_search_time

If set to 1, look for times when detecting DateTime format. That is, whenever a date format
candidate is found, a longer candidate that also contains a time (after the date) is tested.

Value by default: 1 (do look for times when auto-detecting DateTime formats)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv', dates_search_time => 0);

=item dates_locales

Comma-separated string of locales to test when detecting DateTime formats. Ultimately, Text::AutoCSV
will try all combinations of date formats, times and locales.

Value by default: none (use perl default locale)

Example:

	my $csv = Text::AutoCSV->new(in_file => 'logins.csv', dates_locales => 'fr,de,en');

=item dates_zeros_ok

Boolean. If true, a date made only of 0s is regarded as being empty.

For example if C<dates_zeros_ok> is False, then a date like 0000-00-00 will be always incorrect (as
the day and month are out of bounds), therefore a format like '%Y-%m-%d' will never match for the
field.

Conversely if C<dates_zeros_ok> is true, then a date like 0000-00-00 will be processed as if being
the empty string, thus the detection of format will work and when parsed, this "full of zeros" dates
will be processed the same way as the empty string (= value will be undef).

B<IMPORTANT>

"0s dates" are evaluated to undef when parsed, thus when converted back to text (out_map), they are
set to an empty string, not to the original value.

Value by default: 1

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', dates_zeros_ok => 0);

=item out_dates_format

Enforce the format of dates in output, for all fields that contain a DateTime value.

The format is written in Strptime format.

Value by default: none (by default, use format detected on input)

Example:

		# Detect any field containing a DateTime value and convert it to yyyy-mm-dd whatever the
		# input format is.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', fields_dates_auto => 1,
		out_dates_format => '%F')->write();

=item out_dates_locale

Taken into account only if L</out_dates_format> is used.

Sets the locale to apply on L</out_dates_format>.

Value by default: none (by default, use the locale detected on input)

Example:

		# Detect any field containing a DateTime value and convert it to a US DateTime whatever the
		# input format is.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv', fields_dates_auto => 1,
		out_dates_format => '%b %d, %Y, %I:%M:%S %p', out_dates_locale => 'en')->write();

=item croak_if_error

If true, stops the program execution in case of error.

B<IMPORTANT>

Value by default: 1

If set to zero (C<croak_if_error =E<gt> 0>), errors are displayed as warnings. This printing can
then be affected by setting the L</quiet> attribute.

=item verbose

If true, get Text::AutoCSV to be a bit talkative instead of speaking only when warnings and errors
occur. Verbose output is printed to STDERR by default, this can be tuned with the L</infoh>
attribute.

Value by default: 0

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', verbose => 1);

=item infoh

File handle to display program's verbose output. Has effect *mainly* with attribute
C<verbose =E<gt> 1>.

Note B<infoh> is used to display extra information in case of error (if a field does not exist,
Text::AutoCSV will display the list of existing fields). If you don't want such output, you can set
C<infoh> to undef.

Value by default: \*STDERR

Example:

	open my $infoh, ">", "log.txt";
	my $csv = Text::AutoCSV->new(in_file => 'in.csv', infoh => $infoh);

=item quiet

If true, don't display warnings and errors, unless croaking.

If L</croak_if_error> attribute is set (as per default), still, Text::AutoCSV will produce output
(on STDERR) when croaking miserably.

When using C<croak_if_error =E<gt> 0>, errors are processed as warnings and if L</quiet> is set (in
addition to L</croak_if_error> being set to 0), there'll be no output. Note this way of working is
not recommended, as things can go wrong without any notice to the caller.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', quiet => 1);

=item one_pass

If true, Text::AutoCSV will perform one reading of the input. If other readings are triggered, it'll
raise an error and no reading will be done. Should that be the case (you ask Text::AutoCSV to do
something that'll trigger more than one reading of input), Text::AutoCSV will croak as is always the
case if an error occurs.

Normally Text::AutoCSV will do multiple reads of input to work out certain characteristics of the
CSV: guess of encoding and guess of escape character.

Also if member functions like L</field_add_link>, L</field_add_copy>, L</field_add_computed>,
L</read> or L</write> are called after input has already been read, it'll trigger further reads as
needed.

If one wishes a unique read of the input to occur, one_pass attribute is to be set.

When true, encoding will be assumed to be the first one in the provided list (L</encoding>
attribute), if no encoding attribute is provided, it'll be the first one in the default list, to
date, it is UTF-8.

When true, and if attribute L</escape_char> is not set, escape_char will be assumed to be '\\'
(backslash).

By default, one_pass is set if inh attribute is set (caller provides the input file handle of input)
or if input file is stdin (in_file attribute not set or set to an empty string).

Value by default:

	0 if inh attribute is not set and in_file attribute is set to a non empty string
	1 if inh attribute is set or in_file is not set or set to an empty string

Example:

	my $csv = Text::AutoCSV->new(in_file => 'in.csv', one_pass => 1);

=back

=head2 read

	$csv->read();

Read input entirely.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Callback functions (when defined) are invoked, in the following order:

L</read_post_update_hr>, intended to do updates on fields values after each record read

L</walker_ar>, called after each record read, with an array ref of fields values

L</walker_hr>, called after each record read, with a hash ref of fields values

Example:

		# Do nothing - just check CSV can be read successfully
	Text::AutoCSV->new(in_file => 'in.csv')->read();

=head2 read_all_in_mem

	$csv->read_all_in_mem();

Created in version 1.1.5. Before, existed only as _read_all_in_mem, meaning, was private.

Read input entirely, as with L</read> function, but enforcing content to be kept in-memory.

Having the content kept in-memory is implied by search functions (L</vlookup> for example). With
C<read_all_in_mem> you can enforce this behavior without doing a fake search.

=head2 reset_next_record_hr

	$csv->reset_next_record_hr();

Reset the internal status to start from the beginning with L</get_next_record_hr>. Used in
conjunction with L</get_next_record_hr>.

=head2 get_next_record_hr

	my $hr = $csv->get_next_record_hr(\$opt_key);

Get the next record content as a hash ref. C<$hr> is undef when the end of records has been reached.

When specified, C<$opt_key> is set to the current (returned) record key.

B<NOTE>

You do not need to call L</reset_next_record_hr> once before using C<get_next_record_hr>.

Therefore L</reset_next_record_hr> is useful only if you wish to restart from the beginning before
you've reached the end of the records.

B<NOTE bis>

L</walker_hr> allows to execute some code each time a record is read, and it better fits with
Text::AutoCSV philosophy. Using a loop with C<get_next_record_hr> is primarily meant for
Text::AutoCSV internal usage. Also when using this mechanism, you get very close to original
Text::CSV logic, that makes Text::AutoCSV less useful.

B<Return value>

A hashref of the record, or undef once there's no more record to return.

Example:

	while (my $hr = $csv->get_next_record_hr()) {
		say Dumper($hr);
	}

=head2 write

	$csv->write();

Write input into output.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

- If the content is not in-memory at the time write() is called:

Each record is read (with call of L</read_post_update_hr>, L</walker_ar> and L</walker_hr>) and then
written. The read-and-write is done in sequence, each record is written to output before the next
record is read from input.

- If the content is in-memory at the time write() is called:

No L</read> operation is performed, instead, records are directly written to output.

If defined, L</out_filter> is called for each record. If the return value of L</out_filter> is
false, the record is not written.

Example:

		# Copy input to output.
		# As CSV is parsed in-between, this copy also checks a number of characteristics about the
		# input, as opposed to a plain file copy operation.
	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv')->write();

=head2 out_header

	$csv->out_header($field, $header);

Set the header text of C<$field> to C<$header>.

By default, the input header value is rewritten as is to output. C<out_header> allows you to change
it.

B<Return value>

Returns the object itself.

Example:

	Text::AutoCSV->new(in_file => 'in.csv', out_file => 'out.csv')
		->out_header('LOGIN', 'Login')
		->out_header('FULLNAME', 'Full Name')
		->write();

=head2 print_id

	$csv->print_id();

Print out a description of input. Write to \*STDERR by default or to L</infoh> attribute if set.

The description consists in a list of a few characteristics (CSV separator and the like) followed by
the list of columns with the details of each.

Example of output:

If you go to the C<utils> directory of this module and execute the following:

	./csvcopy.pl -i f1.csv -l "1:,A->B,f2.csv" --id

You will get this output:

	-- f1.csv:
	sep_char:         ,
	escape_char:      \
	in_encoding:      UTF-8
	is_always_quoted: no

	# FIELD     HEADER    EXT DATA                            DATETIME FORMAT DATETIME LOCALE
	- -----     ------    --------                            --------------- ---------------
	0 TIMESTAMP timestamp                                     %Y%m%d%H%M%S
	1 A         a
	2 B         b
	3 C         c
	4 D         d                                             %d/%m/%Y
	5 1:SITE    1:SITE    link: f2.csv, chain: A->B->* (SITE)
	6 1:B       1:B       link: f2.csv, chain: A->B->* (B)

=head2 field_add_computed

	$csv->field_add_computed($new_field, $subref);

C<$new_field> is the name of the created field.

C<$subref> is a reference to a sub that'll calculate the new field value.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Add a field calculated from other fields values. The subref runs like this:

	sub func {
			# $new_field is the name of the field (allows to use one subref for more than one field
			# calculation).
			# $hr is a hash ref of fields values.
			# $stats is a hash ref that gets printed (if Text::AutoCSV is created with verbose => 1)
			# in the end.
		my ($new_field, $hr, $stats) = @_;

		my $field_value;
		# ... compute $field_value

		return $field_value;
	}

Example:

		# Add a field for the full name, made of the concatenation of the
		# first name and the last name.
	Text::AutoCSV->new(in_file => 'dirpeople.csv', out_file => 'dirwithfn.csv', verbose => 1)
		->field_add_computed('FULLNAME', \&calc_fn)->write();
	sub calc_fn {
		my ($new_field, $hr, $stats) = @_;
		die "Man, you are in serious trouble!" unless $new_field eq 'FULLNAME';
		my $fn = $hr->{'FIRSTNAME'} . ' ' . uc($hr->{'LASTNAME'});
		$stats->{'empty full name'}++ if $fn eq ' ';
		return $fn;
	}

=head2 field_add_copy

	$csv->field_add_copy($new_field, $src_field, $opt_subref);

C<$new_field> if the name of the new field.

C<$src_field> is the name of the field being copied.

C<$opt_subref> is optional. It is a reference to a sub that takes one string (the value of
C<$src_field>) and returns a string (the value assigned to C<$new_field>).

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

C<field_add_copy> is a special case of L</field_add_computed>. The advantage of C<field_add_copy> is
that it relies on a sub that is Text::AutoCSV "unaware", just taking one string as input and
returning another string as output.

B<IMPORTANT>

The current field value is passed to C<field_add_copy> in $_.

A call to

	$csv->field_add_copy($new_field, $src_field, $subref);

is equivalent to

	$csv->field_add_computed($new_field, \&subref2);
	sub subref2 {
		my (undef, $hr) = @_;
		local $_ = $hr->{$src_field};
		return $subref->();
	}

Example of a field copy + pass copied field in upper case and surround content with <<>>:

	my $csv = Text::AutoCSV->new(in_file => 'dirpeople.csv', out_file => 'd2.csv');
	$csv->field_add_copy('UCLAST', 'LASTNAME', \&myfunc);
	$csv->write();
	sub myfunc { s/^.*$/<<\U$&>>/; $_; }

Note that the calls can be chained as most member functions return the object itself upon success.
The example above is equivalent to:

	Text::AutoCSV->new(in_file => 'dirpeople.csv', out_file => 'd2.csv')
		->field_add_copy('UCLAST', 'LASTNAME', \&myfunc)
		->write();
	sub myfunc { s/^.*$/<<\U$&>>/; $_; }

=head2 field_add_link

	$csv->field_add_link($new_field, $chain, $linked_file, \%opts);

C<$new_field> is the name of the new field.

C<$chain> is the CHAIN of the link, that is: 'LOCAL->REMOTE->PICK' where:

C<LOCAL> is the field name to read the value from.

C<REMOTE> is the linked field to find the value in. This field belongs to $linked_file.

C<PICK> is the field from which to read the value of, in the record found by the search. This field
belongs to $linked_file.

If $new_field is undef, the new field name is the name of the third field of $chain (PICK).

C<$linked_file> is the name of the linked file, that gets read in a Text::AutoCSV object created
on-the-fly to do the search on. C<$linked_file> can also be a Text::AutoCSV object that you created
yourself, allowing for more flexibility. Example:

	my $lcsv = Text::AutoCSV->new(in_file => 'logins.csv', case => 1);
	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', $lcsv);

C<\%opts> is a hash ref of optional attributes. The same values can be provided as with vlookup.

=over 4

=item trim

If set to 1, searches will ignore leading and trailing spaces. That is, a C<LOCAL> value of ' x '
will match with a C<REMOTE> value of 'x'.

If option is not present, use L</search_value_if_not_found> attribute of object (default value: 1).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ trim => 0 });

=item case

If set to 1, searches will take the case into account. That is, a C<LOCAL> value of 'X' will B<not>
match with a C<REMOTE> value of 'x'.

If option is not present, use L</search_case> attribute of object (default value: 0).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ case => 1 });

=item ignore_empty

If set to 1, empty values won't match. That is, a C<LOCAL> value of '' will not match with a
C<REMOTE> value of ''.

If option is not present, use L</search_ignore_empty> attribute of object (default value: 1).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ ignore_empty => 0 });

=item value_if_not_found

If the searched value is not found, the value of the field is undef, that produces an empty string
at write time. Instead, you can specify the value.

If option is not present, use L</search_value_if_not_found> attribute of object (default value:
undef).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ value_if_not_found => '<not found!>' });

=item value_if_found

If the searched value is found, you can specify the value to return.

If option is not present, use L</search_value_if_found> attribute of object (default value: none).

B<NOTE>

Although the C<PICK> field is ignored when using this option, you must specify it any way.

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ value_if_not_found => '0', value_if_found => '1' });

=item value_if_ambiguous

If the searched value is found in more than one record, the value of the field is undef, that
produces an empty string at write time. Instead, you can specify the value.

If option is not present, use L</search_value_if_ambiguous> attribute of object (default value:
undef).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ value_if_ambiguous => '<ambiguous!>' });

=item ignore_ambiguous

Boolean value. If ignore_ambiguous is true and the searched value is found in more than one record,
then, silently fall back on returning the value of the first record. Obviously if
C<ignore_ambiguous> is true, then the value of L</value_if_ambiguous> is ignored.

If option is not present, use L</search_ignore_ambiguous> attribute of object (default value: 1).

Example:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ ignore_ambiguous => 1 });

Example with multiple options:

	$csv->field_add_link('NAME', 'ID->LOGIN->DISPLAYNAME', 'logins.csv',
		{ value_if_not_found => '?', ignore_ambiguous => 1 });

=back

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Example of field_add_link usage:

	my $nom_compose = 0;
	my $zip_not_found = 0;
	Text::AutoCSV->new(in_file => 'pers.csv', walker_hr => \&walk)
		->field_add_link('MYCITY', 'ZIP->ZIPCODE->CITY', 'zips.csv')->read();
	sub walk {
		my $hr = shift;
		$nom_compose++ if $hr->{'NAME'} =~ m/[- ]/;
		$zip_not_found++ unless defined($hr->{'MYCITY'});
	}
	print("Number of persons with a multi-part name: $nom_compose\n");
	print("Number of persons with unknown zipcode: $zip_not_found\n");

=head2 links

	$csv->links($prefix, $chain, $linked_file, \%opts);

C<$prefix> is the name to add to joined fields

C<$chain> is the JOINCHAIN of the link, that is: 'LOCAL->REMOTE' where:

C<LOCAL> is the field name to read the value from.

C<REMOTE> is the linked field to find the value in. This field belongs to $linked_file.

As opposed to L</field_add_link>, there is no C<PICK> part, as all fields of target are read.

As opposed to Text::AutoCSV habits of croaking whenever a field name is duplicate, here, the
duplicates are resolved by appending _2 to the joined field name if it already exists. If _2 already
exists, too, then _3 is appended instead, and so on, until a non-duplicate is found. This mechanism
is executed given the difficulty to control all field names when joining CSVs.

C<$linked_file> and C<\%opts> work exactly the same way as for L</field_add_link>, see
L</field_add_link> for help.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

B<NOTE>

This function used to be called C<join> but got renamed to avoid clash with perl' builtin C<join>.

Example:

	Text::AutoCSV->new(in_file => 'pers.csv', out_file => 'pers_with_city.csv')
		->links('Read from zips.csv:', 'ZIP->ZIPCODE', 'zips.csv')->write();

=head2 get_in_encoding

	my $enc = $csv->get_in_encoding();

Return the string of input encoding, for example 'latin2' or 'UTF-8', etc.

=head2 get_in_file_disp

	my $f = $csv->get_in_file_disp();

Return the printable name of in_file.

=head2 get_sep_char

	my $s = $csv->get_sep_char();

Return the string of the input CSV separator character, for example ',' or ';'.

=head2 get_escape_char

	my $e = $csv->get_escape_char();

Return the string of the input escape character, for example '"' or '\\'.

=head2 get_is_always_quoted

	my $a = $csv->get_is_always_quoted();

Return 1 if all fields of input are always quoted, 0 otherwise.

=head2 get_coldata

	my @cd = get_coldata();

Return an array that describes each column, from the first one (column 0) to the last.

Each element of the array is itself an array ref that contains 5 elements:

	0: Name of the field (as accessed in *_hr functions)
	1: Content of the field in the header line (if input has a header line)
	2: Column content type, shows some meta-data of fields created with field_add_* functions
	3: Datetime format detected, if ever, in the format Strptime
	4: Locale of DateTime format detected, if ever

=head2 get_pass_count

	my $n = $csv->get_pass_count();

Return the number of input readings done. Useful only if you're interested in Text::AutoCSV
internals.

=head2 get_in_mem_record_count

	my $m = $csv->get_in_mem_record_count();

Return the number of records currently stored in-memory. Useful only if you're interested in
Text::AutoCSV internals.

=head2 get_max_in_mem_record_count

	my $mm = $csv->get_max_in_mem_record_count();

Return the maximum number of records ever stored in-memory. Indeed this number can decrease: certain
functions like field_add* member-functions discard in-memory content. Useful only if you're
interested in Text::AutoCSV internals.

=head2 get_fields_names

	my @f = $csv->get_fields_names();

Return an array of the internal names of the columns.

=head2 get_field_name

	my $name = $csv->get_field_name($n);

Return the C<$n>-th column name, the first column being number 0.

Example:

		# Get the field name of the third column
	my $col = $csv->get_field_name(2);

=head2 get_stats

	my %stats = $csv->get_stats();

Certain callback functions provide a parameter to record event count: L</field_add_computed>,
L</read_post_update_hr>, L</walker_ar> and L</walker_hr>. By default, these stats are displayed if
Text::AutoCSV got created with attribute C<verbose =E<gt> 1>. get_stats() returns the statistics
hash of the object.

B<IMPORTANT>

As opposed to most functions that trigger input reading automatically (search functions and other
get_* functions), C<get_stats> just returns you the stats as it is, regardless of whether some
execution already occured.

=head2 set_walker_ar

	$csv->set_walker_ar($subref);

Normally one wants to define it at object creation time using L</walker_ar> attribute.
C<set_walker_ar> allows to assign the attribute walker_ar after object creation.

See attribute L</walker_ar> for help about the way C<$subref> should work.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Example:

		# Calculate the total of the two first columns, the first column being money in and the
		# second one being money out.
	my ($actif, $passif) = (0, 0);
	$csv->set_walker_ar(sub { my $ar = $_[0]; $actif += $ar->[0]; $passif += $ar->[1]; })->read();
	print("Actif =  $actif\n");
	print("Passif = $passif\n");

=head2 set_walker_hr

	$csv->set_walker_hr($subref);

Normally one wants to define it at object creation time using L</walker_hr> attribute.
C<set_walker_hr> allows to assign the attribute L</walker_hr> after object creation.

See attribute L</walker_hr> for help about the way C<$subref> should work.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Example:

	my $csv = Text::AutoCSV->new(in_file => 'directory.csv', verbose => 1);

	# ...

	$csv->set_walker_hr(
		sub {
			my ($hr, $stat) = @_;
			$stat{'not capital name'}++, return if $hr->{'NAME'} ne uc($hr->{'NAME'});
			$stat{'name is capital letters'}++;
		}
	)->read();

=head2 set_out_file

	$csv->set_out_file($out_file);

Normally one wants to define it at object creation time using L</out_file> attribute.
C<set_out_file> allows to assign the attribute L</out_file> after object creation. It is set to
C<$out_file> value.

B<Return value>

Returns the object itself in case of success.
Returns undef if error.

Example:

	$csv->set_out_file('mycopy.csv')->write();

=head2 get_keys

	my @allkeys = $csv->get_keys();

Returns an array of all the record keys of input. A record key is a unique identifier that
designates the record.

At the moment it is just an integer being the record number, the first one (that comes after the
header line) being of number 0. For example if $csv input is made of one header line and 3 records
(that is, a 4-line file typically, if no record contains a line break), $csv->get_keys() returns

	(0, 1, 2)

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_hr_all

	my @allin = $csv->get_hr_all();

Returns an array of all record contents of the input, each record being a hash ref.

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_row_ar

	my $row_ar = $csv->get_row_ar($record_key);

Returns an array ref of the record designated by C<$record_key>.

Example:

		# Get content (as array ref) of last record
	my @allkeys = $csv->get_keys();
	my $lastk = $allkeys[-1];
	my $lastrec_ar = $csv->get_row_ar($lastk);

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_row_hr

	my $row_hr = $csv->get_row_hr($record_key);

Returns a hash ref of the record designated by C<$record_key>.

Example:

		# Get content (as hash ref) of first record
	my @allkeys = $csv->get_keys();
	my $firstk = $allkeys[0];
	my $firstrec_hr = $csv->get_row_hr($firstk);

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_cell

	my $val = $csv->get_cell($record_key, $field_name);

Return the value of the cell designated by its record key (C<$record_key>) and field name
(C<$field_name>).

Example:

	my @allkeys = $csv->get_keys();
	my $midk = $allkeys[int($#allkeys / 2)];
	my $midname = $csv->get_cell($midk, 'NAME');

Note the above example is equivalent to:

	my @allkeys = $csv->get_keys();
	my $midk = $allkeys[int($#allkeys / 2)];
	my $midrec_hr = $csv->get_row_hr($midk);
	my $midname = $midrec_hr->{'NAME'};

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_values

	my @vals = $csv->get_values($field_name, $opt_filter_subref);

Return an array made of the values of the given field name (C<$field_name>), for every records, in
the order of the records.

C<$opt_filter_subref> is an optional subref. If defined, it is called with every values in turn (one
call per value) and only values for which C<$opt_filter_subref> returned True are included in the
returned array. Call to C<$opt_filter_subref> is done with $_ to pass the value.

Example:

	my @logins = $csv->get_values('LOGIN");

This is equivalent to:

	my @allkeys = $csv->get_keys();
	my @logins;
	push @logins, $csv->get_cell($_, 'LOGIN') for (@allkeys);

Example bis

		# @badlogins is the list of logins that contain non alphanumeric characters
	my @badlogins = Text::AutoCSV->new(in_file => 'logins.csv')
		->get_values('LOGIN', sub { m/[^a-z0-9]/ });

This is equivalent to:

		# @badlogins is the list of logins that contain non alphanumeric characters
		# This method leads to carrying all values of a given field across function calls...
	my @badlogins = grep { m/[^a-z0-9]/ } (
		Text::AutoCSV->new(in_file => 'logins.csv')->get_values('LOGIN')
	);

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

=head2 get_recnum

	my $r = $csv->get_recnum();

Returns the current record identifier, if a reading is in progress. If no read is in progress,
return undef.

=head2 in_map

=head2 read_update_after

C<read_update_after> is an alias of C<in_map>.

	$csv->in_map($field, $subref);

After reading a record from input, update C<$field> by calling C<$subref>. The value is put in
C<$_>.  Then the field value is set to the return value of C<$subref>.

This feature is originally meant to manage DateTime fields: the input and output CSVs carry text
content, and in-between, the values dealt with are DateTime objects.

See L</out_map> for an example.

=head2 out_map

=head2 write_update_before

C<write_update_before> is an alias of C<out_map>.

	$csv->out_map($field, $subref);

Before writing C<$field> field content into the output file, pass it through C<out_map>. The value
is put in C<$_>. Then the return value of C<$subref> is written in the output.

Example:

Suppose you have a CSV file with the convention that a number surrounded by parenthesis is negative.
You can register corresponding L</in_map> and L</out_map> functions. During the processing of data,
the field content will be just a number (positive or negative), while in input and in output, it'll
follow the "negative under parenthesis" convention.

In the below example, we rely on convention above and add a new field converted from the original
one, that follows the same convention.

	sub in_updt {
		return 0 if !defined($_) or $_ eq '';
		my $i;
		return -$i if ($i) = $_ =~ m/^\((.*)\)$/;
		$_;
	}
	sub out_updt {
		return '' unless defined($_);
		return '(' . (-$_) . ')' if $_ < 0;
		$_;
	}
	sub convert {
		return ;
	}
	Text::AutoCSV->new(in_file => 'trans-euros.csv', out_file => 'trans-devises.csv')
		->in_map('EUROS', \&in_updt)
		->out_map('EUROS', \&out_updt)
		->out_map('DEVISE', \&out_updt)
		->field_add_copy('DEVISE', 'EUROS', sub { sprintf("%.2f", $_ * 1.141593); } )
		->write();

=head2 search

	my $found_ar = $csv->search($field_name, $value, \%opts);

Returns an array ref of all records keys where the field C<$field_name> has the value C<$value>.

C<\%opts> is an optional hash ref of options for the search. See help of L</vlookup> about options.

B<IMPORTANT>

An unsuccessful search returns an empty array ref, that is, [ ]. Thus you B<cannot> check for
definedness of C<search> return value to know whether or not the search found something.

On the other hand, you can always examine the value C<search(...)-E<gt>[0]>, as search is always an
array ref. If the search found nothing, then, C<search(...)-E<gt>[0]> is not defined.

B<IMPORTANT bis>

If not yet done, this function causes the input to be read entirely and stored in-memory.

Example:

	my $linux_os_keys_ar = $csv->search('OS', 'linux');

=head2 search_1hr

	my $found_hr = $csv->search_1hr($field_name, $value, \%opts);

Returns a hash ref of the first record where the field C<$field_name> has the value C<$value>.

C<\%opts> is an optional hash ref of options for the search. See help of L</vlookup> about options.

Note the options L</value_if_not_found> and L</value_if_ambiguous> are ignored. If not found, return
undef. If the result is ambiguous (more than one record found) and ignore_ambiguous is set to a
false value, return undef.

The other options are taken into account as for any search: L</ignore_ambiguous>, L</trim>,
L</case>, L</ignore_empty>.

B<IMPORTANT>

As opposed to L</search>, an unsuccessful C<search_1hr> will return C<undef>.

B<IMPORTANT bis>

If not yet done, this function causes the input to be read entirely and stored in-memory.

Example:

	my $hr = $csv->search_1hr('LOGIN', $login);
	my $full_name = $hr->{'FIRSTNAME'} . ' ' . $hr->{'LASTNAME'};

=head2 vlookup

	my $val = $csv->vlookup($searched_field, $value, $target_field, \%opts);

Find the first record where C<$searched_field> contains C<$value> and out of this record, returns
the value of C<$target_field>.

C<\%opts> is optional. It is a hash of options for C<vlookup>:

=over 4

=item trim

If true, ignore spaces before and after the values to search.

If option is not present, use L</search_trim> attribute of object (default value: 1).

=item case

If true, do case sensitive searches.

If option is not present, use L</search_case> attribute of object (default value: 0).

=item ignore_empty

If true, ignore empty values in the search. The consequence is that you won't be able to find
empty values by searching it.

If option is not present, use L</search_ignore_empty> attribute of object (default value: 1).

=item ignore_accents

If true, ignore accents in searches. For exampe, if C<ignore_accents> is set, a string like
"élémentaire" will match "elementaire".

If option is not present, use L</search_ignore_accents> attribute of object (default value: 1).

B<NOTE>

This option uses the function L</remove_accents> to build its internal hash tables. See
L</remove_accents> help for more details.

=item value_if_not_found

Return value if vlookup finds nothing.

If option is not present, use L</search_value_if_not_found> attribute of object (default value:
undef).

=item value_if_found

Return value if vlookup finds something.

If option is not present, use L</search_value_if_found> attribute of object (default value: none).

This option is to just check whether a value exists, regardless of the target value found.

B<NOTE>

Although the B<$target_field> is ignored when using this option, you must specify it any way.

=item value_if_ambiguous

Return value if vlookup find more than one result. Tune it only if ignore_ambiguous is unset.

If option is not present, use L</search_value_if_ambiguous> attribute of object (default value:
undef).

=item ignore_ambiguous

If true, then if more than one result is found, silently return the first one.

If option is not present, use L</search_ignore_ambiguous> attribute of object (default value: 1).

=back

B<IMPORTANT>

If not yet done, this function causes the input to be read entirely and stored in-memory.

Example:

	my $name = $csv->vlookup('LOGIN', $id, 'NAME', { value_if_not_found => '<login not found>' });

=head2 remove_accents

	my $t = $csv->remove_accents($s);

Take the string C<$s> as argument and return the string without accents. Uses a Unicode
decomposition followed by removal of every characters that have the Unicode property
C<Nonspacing_Mark>.

B<NOTE>

Only accents are removed. It is not a C<whatever-encoding -E<gt> us-ascii> conversion. For example,
the French B<œ> character (o followed by e) or the German B<ß> (eszett) are kept as is.

B<NOTE bis>

Tested with some latin1 and latin2 characters.

B<NOTE ter>

There is no language-level transformation during accents removal. For example B<Jürgen> is returned
as B<Jurgen>, not B<Juergen>.

This function is not exported by default.

Example:

	use Text::AutoCSV qw(remove_accents);
	my $s = remove_accents("Français: être élémentaire, Tchèque: služba dům");
	die "This script will never die" if $s ne 'Francais: etre elementaire, Tcheque: sluzba dum';

=head1 AUTHOR

Sébastien Millet <milletseb@laposte.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016, 2017 by Sébastien Millet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
