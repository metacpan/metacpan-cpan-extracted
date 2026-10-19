package oEdtk::Utils;

# Generic utilities (docs/integration/PLAN.md, S23). The fork's
# oEdtk::Utils mixed generic helpers with corporate ones; this module keeps the
# generic part only (text cleanup, index format, date and price parsing,
# tracking helpers, small value helpers) and is free of any corporate
# reference. The corporate part -- init() and the INDEX_* accessors, which call
# oEUser::Lib or name corporate schema identifiers -- lives in oEUser::Utils;
# the old names stay available here as delegates. oEUser is an optional
# companion distribution: it is loaded on demand, and a missing one fails
# cleanly rather than breaking the oEdtk load.

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';

# The fork's own test imported delete_useless_whitespaces, but the fork left it
# out of @EXPORT_OK (a latent Exporter error). Both generic text helpers are
# exported here; the fork's remaining exported names are kept unchanged.
our @EXPORT_OK = qw(
	delete_useless_whitespaces IDX_FORMAT kill_non_latin_1_9_chars_in_place
	alert flatten_index_variables max_value parse_jjmmaaaa parse_price
	parse_yyyymmdd scalar_dump track track_begin track_end trim_list
);

our $VERSION = 2.1126;

use Carp         qw(carp croak);
use Cwd          qw(abs_path);
use Data::Dumper qw(Dumper);
use Date::Calc   qw(Days_in_Month);
use Readonly;
use Regexp::Common  qw(whitespace);
use Term::ANSIColor qw(colored);
use Text::CSV_XS    qw(csv);

# The LaTeX index format: pairs of "old LaTeX tag" => "new index field", with
# an optional list offset. The first four fields are only known to LaTeX and
# are therefore skipped by the generic table (see the fork's edtkdoc.cls).
Readonly my $LATEX_INDEX_FORMAT => [
	[ xAppRef => 'applicationReference' ],
	[ xIdLdoc => 'idLotDocuments' ],
	[ thepage => 'pageNumber' ],
	[ thedoc  => 'docNumber' ],
];

Readonly my $INDEX_FORMAT => [
	[ xCPDEST    => 'indexDestCodePostal' ],
	[ xVILDEST   => 'indexDestVille' ],
	[ xIDDEST    => 'indexIdDest' ],
	[ xNOMDEST   => 'indexDestNomPrenom' ],
	[ xIDEMET    => 'indexIdEmetteur' ],
	[ dtedition  => 'date_edition' ],
	[ xTYPPROD   => 'type_production' ],
	[ xPORTADR   => '' ],                      # unused
	[ daddr      => 'adresse',   0 ],
	[ xCLEGEDi   => 'indexClef', 0 ],
	[ daddri     => 'adresse',   1 ],
	[ xCLEGEDii  => 'indexClef', 1 ],
	[ daddrii    => 'adresse',   2 ],
	[ xCLEGEDiii => 'indexClef', 2 ],
	[ daddriii   => 'adresse',   3 ],
	[ xCLEGEDiv  => 'indexClef', 3 ],
	[ daddriv    => 'adresse',   4 ],
	[ edCorp     => 'corporation' ],
	[ xDOCLIB    => 'pdf_filename' ],
	[ xREFIMP    => 'ref_preimprime' ],
	[ daddrv     => 'adresse', 5 ],
	[ xSOURCE    => 'domaine_metier' ],
	[ xOWNER     => 'demandeur_edition' ],
	[ xHOST      => 'serveur_edition' ],
	[ xIDIDX     => 'version_idx' ],
	[ xCATDOC    => 'categorie_doc' ],         # unused
	[ xCODRUPT   => 'code_rupture' ],
	[ xTYPEDOC   => 'type_document' ],
	[ xCLEGEDv   => 'indexClef', 4 ],
	[ xIDPMSIR   => 'id_pers_moral_siret' ],
];

Readonly my $FULL_INDEX_FORMAT => [ @{$LATEX_INDEX_FORMAT}, @{$INDEX_FORMAT} ];

# French month names, as ASCII source (accents expressed with \x escapes).
Readonly my @FRENCH_MONTHS => (
	"janvier", "f\x{e9}vrier", "mars",      "avril",   "mai",      "juin",
	"juillet", "ao\x{fb}t",    "septembre", "octobre", "novembre", "d\x{e9}cembre",
);

Readonly my $TRACK_MODE_BATCH => 'Batch';
Readonly my $TRACK_DOCUMENT   => 'D';
Readonly my $TRACK_WARNING    => 'W';
Readonly my $TRACK_END_MSG    => 'Fin de traitement';

# The document-type value used when the caller does not pass one.
Readonly my $SPACE => "\x20";

# --- text cleanup ----------------------------------------------------------

# Replace illegal latin-1/latin-9 bytes (0x7f..0x9f) with spaces, in place.
# Keeps C0 control characters; circumvents garbage sometimes received in flows.
sub kill_non_latin_1_9_chars_in_place ($strRef) {
	$$strRef =~ s/[\x7f\x80-\x9f]/$SPACE/gsox;
	return;
}

# Join a list with single spaces, collapsing runs of whitespace.
sub trim_list (@l) {
	my $str = join( $SPACE, @l );
	$str =~ s{^\s+}{}sx;
	$str =~ s{\s+\@}{}sox;       # kept verbatim from the fork
	$str =~ s/\s+/$SPACE/gsox;
	return $str;
}

# Remove surrounding whitespace and collapse internal runs to one space.
sub delete_useless_whitespaces ($str) {
	croak 'str undef' if !defined $str;
	$str = $RE{ws}{crop}->subs($str);    # delete surrounding whitespace
	$str =~ s/\s+/\x20/gsxm;             # delete useless whitespace
	return $str;
}

# --- index format ----------------------------------------------------------

# The current index format, as an arrayref of [ old_tag, new_field, offset ].
sub IDX_FORMAT () {
	return $INDEX_FORMAT;
}

# --- date parsing ----------------------------------------------------------

# Return a non-empty error message when (year, month, day) is not a valid date.
sub check_date ( $year, $mon, $dd, $str ) {
	return "bad month number for date '$str'" if $mon < 1 || $mon > 12;
	return "bad day number for date '$str'"
		if $dd < 1 || $dd > Days_in_Month( $year, $mon );
	return '';
}

# Return [ day, "month_name year" ] when the string is dd/mm/yyyy.
sub parse_jjmmaaaa ( $str, $flowFile, $lineNumber ) {
	if ( $str =~ m{^ 0* (\d+) / 0*(\d+) / (\d+) $}sx ) {
		my ( $dd, $mon, $year ) = ( $1, $2, $3 );
		my $error_msg = check_date( $year, $mon, $dd, $str );
		return alert( $flowFile, $lineNumber, $error_msg, [$str] )
			if length $error_msg;
		return [ $dd, "$FRENCH_MONTHS[$mon-1] $year" ];
	}
	return alert( $flowFile, $lineNumber, "cannot parse date '$str'", [$str] );
}

# Return [ day, "month_name year" ] when the string is yyyymmdd.
sub parse_yyyymmdd ( $str, $flowFile, $lineNumber ) {
	if ( $str =~ m{^ (\d\d\d\d) (\d\d) (\d\d) $}sx ) {
		my ( $year, $mon, $dd ) = map { sprintf( '%d', $_ ) } ( $1, $2, $3 );
		my $error_msg = check_date( $year, $mon, $dd, $str );
		return alert( $flowFile, $lineNumber, $error_msg, [$str] )
			if length $error_msg;
		return [ $dd, "$FRENCH_MONTHS[$mon-1] $year" ];
	}
	return alert( $flowFile, $lineNumber, "cannot parse date '$str'", [$str] );
}

# Check that a price is valid; return it unchanged, else alert.
sub parse_price ( $n, $flowFile, $lineNumber ) {
	return $n if $n =~ m{^ [0-9]+(?:\.[0-9]+)? }sox || $n =~ m{^ \.[0-9]+ $}sox;
	return alert( $flowFile, $lineNumber, "cannot parse price '$n'", [$n] );
}

# Conversion of a yyyymmdd date to dd/mm/yyyy.
sub convert_date ($refvar) {
	croak 'refvar undef' if !defined $refvar;
	$refvar =~ s/(\d{4})(\d{2})(\d{2})(.*)/$3\/$2\/$1/oxms;
	return $refvar;
}

# The capitalized month name for a 1-based month number (distinct from the
# lowercase @FRENCH_MONTHS used by the date parsers, as in the fork).
sub month_to_name ($lib_month) {
	my @mons = (
		"Janvier", "F\x{e9}vrier", "Mars",      "Avril",   "Mai",      "Juin",
		"Juillet", "Ao\x{fb}t",    "Septembre", "Octobre", "Novembre", "D\x{e9}cembre",
	);
	$lib_month || croak 'lib_month undef';
	return $mons[ $lib_month - 1 ];
}

# --- helpers ---------------------------------------------------------------

sub my_dumper ($obj) {
	my $res = Dumper($obj);
	$res =~ s{^\$VAR\d+ \s = \s }{}sx;
	return $res;
}

# Add an alert: carp with the flow file, the line number and the objects.
sub alert ( $flowFile, $lineNumber, $msg, @objs ) {
	carp "alert: flowFile='$flowFile' lineNumber='$lineNumber' msg='$msg' objs: "
		. my_dumper( \@objs );
}

# Return a hashref of the index_variables sub-hash, keys prefixed with "index".
sub flatten_index_variables ($h) {
	my $iv    = $h->{'index_variables'};
	my $index = {};
	foreach my $key ( keys %{$iv} ) {
		$index->{"index$key"} = $iv->{$key};
	}
	return $index;
}

# The "max" value (string-wise) in a list.
sub max_value ($l) {
	my $res = $$l[0];
	foreach my $str ( @{$l} ) {
		$res = $str if $str gt $res;
	}
	return $res;
}

# Return the special bytes of a scalar in an easier to read form.
sub scalar_dump ($str) {
	my @res = ();
	my $n   = length($str);
	for ( my $i = 0 ; $i < $n ; $i++ ) {
		my $char = substr( $str, $i, 1 );
		my $ord  = ord($char);
		if ( ( $ord >= 32 ) && ( $ord <= 126 ) && ( $ord != 28 ) && ( $ord != 29 ) ) {
			push @res, $char;
		}
		else {
			push @res, sprintf( "(x%02x)", $ord );
		}
	}
	return join( '', @res );
}

# --- index file inspection (diagnostic helpers) ----------------------------

# The latest .idx1 file in a directory.
sub latest_idx1_in_directory ($dir) {
	opendir( my $dh, $dir ) || croak $!;
	my ( $latest_file, $latest_time ) = ( '', 0 );
	while ( readdir $dh ) {
		my $file = $_;
		if ( $file =~ m{\.idx1$}sx ) {
			my $path  = "$dir/$file";
			my $ctime = ( stat($path) )[9];
			( $latest_file, $latest_time ) = ( $path, $ctime ) if $ctime > $latest_time;
		}
	}
	closedir $dh;
	croak "No file found in '$dir'" unless length $latest_file;
	return $latest_file;
}

# Print the columns of an index file, in a readable form.
sub comment_index_file ($file) {
	$file = '.' unless defined $file;
	$file = latest_idx1_in_directory($file) if -d $file;
	my $aoa = csv( in => $file, sep_char => ';' );
	croak "Problem parsing CSV from '$file': $!" unless defined $aoa;
	my $nCols = scalar @{$FULL_INDEX_FORMAT};
	my $nRows = scalar @{$aoa};
	for ( my $i = 0 ; $i < $nRows ; $i++ ) {
		my $ii    = $i + 1;
		my $row   = $$aoa[$i];
		my $ncols = scalar @{$row};
		carp "Found $ncols columns on row $ii; expected $nCols"
			if $ncols != $nCols;
		print "\nROW $ii/$nRows\n";
		for ( my $j = 0 ; $j < $nCols ; $j++ ) {
			my $jj    = $j + 1;
			my $value = $$row[$j];
			$value = '(undef)' unless defined $value;
			my ( $old_field, $new_field, $index ) = @{ $$FULL_INDEX_FORMAT[$j] };
			$new_field .= "[$index]" if defined $index;
			print "COL $jj/$nCols: $old_field / $new_field: ", colored( $value, 'bold red' ), "\n";
		}
	}
	return;
}

# --- tracking --------------------------------------------------------------

# Return a constant.
sub TRACK_MODE_BATCH () {
	return $TRACK_MODE_BATCH;
}

# Start tracking; return a tracking object. The tracking class (and the main
# toolkit through it) is loaded on demand so that this module stays loadable --
# and banner-free -- without pulling the whole toolkit in.
sub track_begin ( $trackingJob, $user, $tracking_fields, $mode = undef ) {
	$mode = TRACK_MODE_BATCH() unless defined $mode;
	require oEdtk::Main;
	require oEdtk::Tracking;
	return oEdtk::Tracking->new(
		$trackingJob,
		user   => $user,
		entity => oEdtk::Main::oe_corporation_set(),
		keys   => $tracking_fields,
		edmode => $mode,
	);
}

# Track one document.
sub track ( $trk, $l, $type = undef ) {
	$type = $TRACK_DOCUMENT unless defined $type;
	return $trk->track( $type, 1, @{$l} );
}

# End of tracking.
sub track_end ($trk) {
	return $trk->track( $TRACK_WARNING, 1, '', '', '', '', $TRACK_END_MSG );
}

# --- corporate delegates ---------------------------------------------------
# The fork's init() and its INDEX_* accessors call oEUser::Lib or name
# corporate schema identifiers, so they live in oEUser::Utils. The old names
# are kept here and forwarded on demand; a missing oEUser fails with a clear
# message rather than breaking the oEdtk load.
sub _delegate ( $sub, @args ) {
	my $loaded;
	{
		local $SIG{__DIE__};    # a caught die must not reach oEdtk::Tracking's handler
		$loaded = eval { require oEUser::Utils; 1 };
	}
	die "oEdtk::Utils requires the companion distribution oEUser "
		. "(oEUser::Utils is not installed): $@"
		unless $loaded;
	return oEUser::Utils->can($sub)->(@args);
}

sub init                { return _delegate( 'init',                @_ ) }
sub INDEX_CLEF_GED      { return _delegate( 'INDEX_CLEF_GED',      @_ ) }
sub INDEX_ADRESSE_LISTE { return _delegate( 'INDEX_ADRESSE_LISTE', @_ ) }
sub INDEX_ID_MNT_NUMABA { return _delegate( 'INDEX_ID_MNT_NUMABA', @_ ) }
sub INDEX_ID_EMETTEUR   { return _delegate( 'INDEX_ID_EMETTEUR',   @_ ) }
sub INDEX_ID_PM_SIRET   { return _delegate( 'INDEX_ID_PM_SIRET',   @_ ) }

1;

=head1 NAME

oEdtk::Utils - generic text, index, date and tracking helpers

=head1 SYNOPSIS

    use oEdtk::Utils qw(delete_useless_whitespaces IDX_FORMAT);

    my $clean = delete_useless_whitespaces("  a   b  ");    # "a b"
    my $fmt   = IDX_FORMAT();

=head1 DESCRIPTION

Generic helpers ported from the fork's C<oEdtk::Utils> at S23: text cleanup
(C<delete_useless_whitespaces>, C<kill_non_latin_1_9_chars_in_place>,
C<trim_list>), the index format (C<IDX_FORMAT>), date and price parsing
(C<parse_jjmmaaaa>, C<parse_yyyymmdd>, C<parse_price>, C<convert_date>,
C<month_to_name>), tracking (C<track_begin>, C<track>, C<track_end>,
C<TRACK_MODE_BATCH>) and small value helpers (C<flatten_index_variables>,
C<max_value>, C<scalar_dump>, C<alert>).

The corporate part of the fork's module -- C<init> and the C<INDEX_*> accessors,
which call L<oEUser::Lib> or name corporate schema identifiers -- lives in
L<oEUser::Utils>. Their old names are kept here as delegates: they forward to
the companion distribution, which is loaded on demand, and a missing oEUser
fails with a clear message. This module itself never depends on oEUser.

=head1 FUNCTIONS

=head2 delete_useless_whitespaces

    my $clean = delete_useless_whitespaces($string);

Remove the surrounding whitespace and collapse internal runs to a single space.
Croaks on an undef argument.

=head2 IDX_FORMAT

    my $format = IDX_FORMAT();

Return the current index format, an array reference of C<[ old_tag, new_field,
offset ]> entries.

=head2 kill_non_latin_1_9_chars_in_place

    kill_non_latin_1_9_chars_in_place(\$string);

Replace, in place, the DEL and C1 control bytes of C<$string> with spaces.

=head2 alert

    alert($flow_file, $line_number, $message, @objects);

Carp an alert carrying the flow file, the line number and the objects.

=head2 flatten_index_variables

    my $index = flatten_index_variables($record);

Return a hash reference of the C<index_variables> sub-hash, each key prefixed
with C<index>.

=head2 max_value

    my $max = max_value(\@values);

Return the greatest value of the list reference, compared as strings.

=head2 parse_jjmmaaaa

    my $parts = parse_jjmmaaaa($string, $flow_file, $line_number);

Parse a dd/mm/yyyy string into C<[ day, "month_name year" ]>, or raise an alert
and return.

=head2 parse_price

    my $price = parse_price($number, $flow_file, $line_number);

Return the price unchanged when it is valid, otherwise raise an alert.

=head2 parse_yyyymmdd

    my $parts = parse_yyyymmdd($string, $flow_file, $line_number);

Parse a yyyymmdd string into C<[ day, "month_name year" ]>, or raise an alert
and return.

=head2 scalar_dump

    my $readable = scalar_dump($string);

Render the non-printable bytes of C<$string> as hexadecimal escapes, for display.

=head2 track

    track($tracking, \@fields, $type);

Track one document on the given tracking object, with an optional event type.

=head2 track_begin

    my $tracking = track_begin($job, $user, \@fields, $mode);

Start tracking and return the tracking object. The tracking class and the
toolkit are loaded on demand.

=head2 track_end

    track_end($tracking);

Record the end-of-run tracking event on the given object.

=head2 trim_list

    my $string = trim_list(@parts);

Join the list with single spaces, collapsing runs of whitespace.

The unexported helpers C<check_date>, C<convert_date>, C<month_to_name>,
C<my_dumper>, C<latest_idx1_in_directory>, C<comment_index_file>,
C<TRACK_MODE_BATCH> and C<_delegate>, and the corporate accessors C<init> and the
C<INDEX_*> names, are not part of the public API; the accessors delegate on
demand to the companion C<oEUser::Utils>.

=head1 AUTHOR

The oEdtk team.

=cut
