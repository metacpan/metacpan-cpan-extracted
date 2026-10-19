package oEdtk::Config;
use FindBin qw($Bin);
use lib "$Bin";
use strict;
use warnings;

use Config::IniFiles;
use Sys::Hostname;
use oEdtk::logger qw(logger $LOGGERLEVEL $WARN2LOGGER);

use Exporter;
our $VERSION   = 2.1126;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(config_read get_ini_path);
my $_INI_PATH;

# Parsed-ini cache. config_read() re-parsed the ini on every call -- the P00
# micro-profile saw the file parsed 15 times for 9 calls, and the many
# config_read('EDTK_DB') sites re-parse it again each time. Only the parse is
# shared: the section merge and the "$name" expansion stay per caller, and each
# call still builds a fresh hash, so a caller that edits the result cannot
# corrupt the cache. Keyed by the file's (mtime, size), so an edited ini is
# re-read; OEDTK_CONFIG_NOCACHE=1 (or a trailing { cache => 0 }) bypasses it.
my %_INI_SECTIONS;

# The sections of an ini file as a plain snapshot, section => { key => value },
# holding each section's OWN keys: the %{ $allcfg{$_} } spread the merge does
# never sees the DEFAULT fallback. Cached by (path, mtime, size) unless
# $use_cache is false.
sub _ini_sections {
	my ( $path, $use_cache ) = @_;
	my @stat = stat $path;
	if ( $use_cache && @stat ) {
		my $hit = $_INI_SECTIONS{$path};
		return $hit->{'sections'}
			if $hit && $hit->{'mtime'} == $stat[9] && $hit->{'size'} == $stat[7];
	}

	# -fallback => 'DEFAULT' (the fork's option) lets a section fall back to
	# DEFAULT for a key it does not define. The tie is kept verbatim so
	# Config::IniFiles still owns the parsing; the cache only avoids redoing it.
	tie my %allcfg, 'Config::IniFiles',
		( -file => $path, -default => 'DEFAULT', -fallback => 'DEFAULT' )
		or die &logger( -1, "Config file not found or unreadable : $path" );
	my %sections = map { $_ => { %{ $allcfg{$_} } } } keys %allcfg;
	$_INI_SECTIONS{$path} = { mtime => $stat[9], size => $stat[7], sections => \%sections }
		if @stat;
	return \%sections;
}

# Config::IniFiles' val() under -fallback => 'DEFAULT': the section's own value,
# else DEFAULT's, else undef. Backs the hostname redirect below.
sub _section_val {
	my ( $sections, $section, $key ) = @_;
	my $own = $sections->{$section};
	return $own->{$key} if $own && defined $own->{$key};
	my $def = $sections->{'DEFAULT'};
	return $def->{$key} if $def && defined $def->{$key};
	return;
}

sub get_ini_path() {
	return $_INI_PATH;
}

sub config_read {
	my ( $sections, $app );
	my @args = @_;

	# Optional trailing { cache => 0 } forces a fresh parse. No caller passes a
	# hashref today (sections are strings or one array ref), so it is unambiguous.
	my $use_cache = $ENV{OEDTK_CONFIG_NOCACHE} ? 0 : 1;
	if ( @args && ref $args[-1] eq 'HASH' ) {
		my $opt = pop @args;
		$use_cache = 0 if exists $opt->{'cache'} && !$opt->{'cache'};
	}

	if ( ref( $args[0] ) eq 'ARRAY' ) {
		$sections = $args[0];
		$app      = $args[1];
	}
	else {
		$sections = \@args;
	}

	my $mod = __PACKAGE__;
	$mod =~ s/::/\//;
	$mod .= '.pm';
	my $dir = $INC{$mod};
	$dir =~ s/\/[^\/]+$//;
	&logger( 7, "lib \$Bin = $Bin" );

	my $ini;
	if ( -e "$Bin/edtk.ini" ) {
		$ini = "$Bin/edtk.ini";
	}
	elsif ( -e "$dir/iniEdtk/edtk.ini" ) {
		$ini = "$dir/iniEdtk/edtk.ini";
	}
	else {
		$ini = "$dir/iniEdtk/tplate.edtk.ini";

		#warn "INFO: accessing $ini\n";
		&logger( 6, "Accessing $ini" );
	}
	my $uchost = hostname();
	$uchost = uc($uchost);

	my $file_sections;
	for ( ; ; ) {
		die &logger( -1, "Config file not found or unreadable : $ini" ) unless -r $ini;

		#die "ERROR: config file not found or unreadable: $ini\n" unless -r $ini;
		$file_sections = _ini_sections( $ini, $use_cache );
		$_INI_PATH     = $ini;

		my $ini2 = _section_val( $file_sections, $uchost, 'iniEdtk' );
		last if not defined $ini2 or $ini2 eq $ini or $ini2 eq 'local';
		$ini = $ini2;
	}

	# Get the DEFAULT and ENVDESC sections by default, override with the optional
	# sections that we were given, and finally with the hostname section.
	my %cfg = ();
	$cfg{'EDTK_HOST'} = $uchost;
	$cfg{'USERNAME'}  = getlogin || getpwuid($<) || "undef";
	foreach ( 'DEFAULT', 'ENVDESC', @$sections, $uchost ) {
		if ( exists $file_sections->{$_} ) {
			%cfg = ( %cfg, %{ $file_sections->{$_} } );
		}
	}

	# Get current application name
	if ( defined($app) ) {
		$cfg{'EDTK_PRGNAME'} = $app;
	}
	else {
		if ( $0 =~ /([\w\-\.]+)\.p[lm]$/i ) {
			$cfg{'EDTK_PRGNAME'} = $1;
		}
		else {
			$cfg{'EDTK_PRGNAME'} = $0;
		}
	}
	$cfg{'EDTK_PRGPATH'} = $Bin;

	# Expand variables inside other variables, resolving each "$name" through
	# read_hash (the fork's accessor): an absent or undef key yields an empty
	# string rather than an uninitialised-value warning.
	foreach my $key ( keys %cfg ) {
		1 while $cfg{$key} =~ s/\$(\w+)/read_hash(\%cfg, $1)/gsex;
	}

	return \%cfg;
}

# Return the value bound to a key of a configuration hash, or an empty string
# when the key is absent or carries an undef value (a warning is issued in both
# cases). Ported from the fork (PLAN S60); it backs the "$name" expansion above.
sub read_hash {
	my ( $href, $key ) = @_;
	if ( exists $href->{$key} ) {
		return $href->{$key} if defined $href->{$key};
		warn "Key '$key' has an undef value in the configuration hash\n";
	}
	else {
		warn "Key '$key' does not exist in the configuration hash\n";
	}
	return '';
}

1;

=head1 NAME

oEdtk::Config - read the oEdtk configuration (edtk.ini)

=head1 SYNOPSIS

    use oEdtk::Config qw(config_read get_ini_path);

    my $cfg = config_read('EDTK_DB');
    my $dsn = $cfg->{'EDTK_DBI_DSN'};

=head1 DESCRIPTION

The configuration reader for the whole toolkit. It locates the F<edtk.ini>
file (with a hostname redirect loop), merges the C<DEFAULT>, C<ENVDESC>, the
requested and the hostname sections into one hash, adds C<EDTK_HOST>,
C<USERNAME>, C<EDTK_PRGNAME> and C<EDTK_PRGPATH>, and expands C<$name>
references found inside the values. Each call returns a fresh hash.

The parsing is memoised by the file's C<(path, mtime, size)>; set
C<OEDTK_CONFIG_NOCACHE=1>, or pass a trailing options hashref with C<cache> set
to 0, to force a re-parse.

=head1 FUNCTIONS

=head2 config_read

    my $cfg = config_read(@sections);
    my $cfg = config_read([@sections], $app);

Read the configuration and return a hash reference of merged sections.
C<@sections> is the list of extra sections to merge (C<DEFAULT> and C<ENVDESC>
are always merged), optionally given as an array reference together with an
application name that sets C<EDTK_PRGNAME>.

=head2 get_ini_path

    my $path = get_ini_path();

Return the path of the ini file used by the last C<config_read> call.

The private helpers C<_ini_sections> and C<_section_val>, and the C<read_hash>
accessor, back the caching, the C<DEFAULT> fallback and the C<$name> expansion;
they are not part of the public API.

=head1 CONFIGURATION

The lexicon of the keys the shipped template F<tplate.edtk.ini> sets, by section, with what
each drives and the values that change behaviour. A C<$name> value (for example
C<$EDTK_DIR_BASE>) is expanded by C<config_read>; a key with no listed values is free-form.

=head2 The C<[DEFAULT]> section

=over

=item C<iniEdtk>

Redirect the read to another ini file; also read from the host-name section. The literal
C<local> disables the redirect.

=item C<EDTK_CORP>

Corporation name printed in the generated documents.

=item C<EDTK_DICO>

Main dictionary (accents, entities) loaded by the text layer.

=item C<EDTK_DICO_POST>

Postal-code dictionary.

=item C<EDTK_SNIP_ADDR>

Address-snipping dictionary.

=item C<EDTK_SNIP_RATE>

Address-snipping rate; C<0> disables snipping.

=item C<EDTK_LANG>

Language, i.e. the dictionary section to read, such as C<EN> or C<FR>.

=item C<EDTK_LOG_LVL>

Log sensitivity read by L<oEdtk::logger> (its C<$LOGGERLEVEL>); C<4> is the mainline default.

=back

=head2 The C<[ENVDESC]> section

Directories, file stems, extensions and timeouts. Every path is written relative to
C<EDTK_DIR_BASE> (default C<$EDTK_PRGPATH>, the running script's directory) and to
C<EDTK_PRGNAME> (injected at runtime).

=over

=item C<EDTK_DIR_BASE>

Root of the whole path tree; defaults to C<$EDTK_PRGPATH>.

=item C<EDTK_DIR_APP>, C<EDTK_DIR_SCRIPT>

Application root and the per-application script directory.

=item C<EDTK_DIR_CONFIG>

Configuration files and dictionaries.

=item C<EDTK_DIR_APPTMP>, C<EDTK_DIR_DB>

Temporary work area and database files.

=item C<EDTK_DIR_DATA_IN>

Input flux directory.

=item C<EDTK_DIR_LIB>, C<EDTK_DIR_TMPLATE>

Shared libraries and document templates.

=item C<EDTK_DIR_OUTMNGR>, C<EDTK_DIR_EDOCMNGR>, C<EDTK_DIR_DOCLIB>

Output, EDMS transit and document library.

=item C<EDTK_DIR_LOG>, C<EDTK_DIR_DOCSCRIPT>

Logs and the per-application document area.

=item C<EDTK_DOCLIB_LOCK>

Document-library lock file.

=item C<EDTK_FDATAIN>, C<EDTK_FDATAOUT>, C<EDTK_FDATWORK>

Input, output and work file stems.

=item C<EDTK_TYPE_ENV>

Environment label, prefixed to mail subjects by L<oEdtk::Messenger>; C<Dev> (the default),
C<Test> or C<Production>.

=item C<EDTK_OUTMNGR_MERGE>

Whether the outgoing-routeur output is merged; C<no> (the default) or C<yes>.

=item C<EDTK_PRGNAME>

Running program name; injected by C<config_read>, not normally set.

=item C<EDTK_VCS_LOCATION>

Version-control location recorded in outputs.

=item C<EDTK_WATERMARKTEXT>

Watermark stamped on generated documents.

=item C<EDTK_BIN_PERL>

Path to the Perl interpreter used when bundling.

=item C<EDTK_EXT_COMP_OMGR>

Extension of the routeur-composed files; C<omgr>.

=item C<EDTK_EXT_COMPO>

Extension of a composed file; defaults to C<$EDTK_EXT_LATEX>.

=item C<EDTK_EXT_DATA>, C<EDTK_EXT_DEFAULT>

Data-file extension (C<DAT>) and default extension (C<$EDTK_EXT_PDF>).

=item C<EDTK_EXT_EXCEL>, C<EDTK_EXT_LATEX>, C<EDTK_EXT_PCL>, C<EDTK_EXT_PDF>, C<EDTK_EXT_PERL>, C<EDTK_EXT_WORK>

Extension per artefact type: C<xls>, C<tex>, C<pcl>, C<pdf>, C<pl>, C<txt>.

=item C<EDTK_WAITRUN>

Seconds to wait for a child process; default C<8>.

=item C<EDTK_XLS_MAX_ROW>

Maximum rows read from an XLS sheet; default C<30000>.

=back

=head2 The C<[EDTK_DB]> section

Database DSNs, credentials, retention, primary-key mode and bulk-load tuning.

=over

=item C<EDTK_DBI_DSN> (with C<_USER>, C<_PASS>)

Active DSN and credentials of the main database.

=item C<EDTK_DBI_DSN_BAK> (with C<_USER>, C<_PASS>)

DSN and credentials of the backup database.

=item C<EDTK_DBI_PARAM>

DSN of the parameter database.

=item C<EDTK_DBI_ACQUIT>, C<EDTK_DBI_DISTRIB>, C<EDTK_DBI_DISTRIB_STATS>, C<EDTK_DBI_OUTMNGR>, C<EDTK_DBI_OUTMNGR_STATS>, C<EDTK_DBI_TRACKING>

Logical table names of the acquittal, distribution, distribution-stats, outgoing,
outgoing-stats and tracking tables.

=item C<EDTK_MAX_USER_KEY>

Number of user tracking keys accepted; C<10> in the mainline, C<5> in the fork.

=item C<EDTK_TRACKING_KEYS>

Comma-separated extra tracking columns.

=item C<EDTK_TRACK_MODE>

Tracking back-end: C<SQLite> (the default) or C<none> to switch tracking off.

=item C<EDTK_TRACK_SIG>

Which signals the tracker catches: C<warn> (all) or C<halt> (die only); C<no> disables.

=item C<EDTK_DB_MAX_DAYS_KEPT>, C<EDTK_DB_MAX_DAYS_KEPT_STATS>, C<EDTK_DB_MAX_DAYS_TRACKED>, C<EDTK_DB_MAX_DAYS_AGREGED>

Retention in days of the main, stats, tracking and aggregated tables; C<2>, C<100>, C<400>
and C<600>.

=item C<EDTK_DB_CHECK_AUTO>

Enables the automatic consistency check; C<NO> (the default) or C<YES>.

=item C<EDTK_DB_CHECK_MONTH_DAY>

Day of month for the automatic check; default C<15>.

=item C<EDTK_DB_PK_IDJOB>

Keep C<ed_idjob> in the INDEX primary key: C<yes> (mainline behaviour), any other value
builds the schema without it (fork).

=item C<EDTK_DB_IDJOB_DEFAULT>

Value written to C<ed_idjob> when the key is kept; left empty until the S51 gate.

=item C<EDTK_DB_FetchHashKeyName>

Case-folding of the fetched column names (C<FetchHashKeyName>); C<NAME_uc> by default.

=item C<EDTK_DB_COPY_ENCODING>

Source encoding of the CSV bulk-load path: C<UTF8> declares a file already in UTF-8 so it is
not double-encoded, empty keeps the legacy Latin-1 behaviour.

=item C<EDTK_DB_DEFER_INDEX_RATIO>, C<EDTK_DB_DEFER_INDEX_MIN_ROWS>

Opt-in index-deferral policy of the PostgreSQL bulk load; empty means off, and when set the
defaults are C<0.1> and C<10000>.

=item C<EDTK_DB_BURST_MO>

ELT staging threshold in MiB on PostgreSQL: C<50> by default, C<0> disables the path, and an
empty or invalid value falls back to 50.

=back

=head2 The C<[EDTK_STATS]> section

=over

=item C<EDTK_DBI_STATS>, C<EDTK_DSN_STATS> (with C<_USER>, C<_PASS>)

DSN and credentials of the statistics database; they default to the main DSN.

=item C<EDTK_STATS_TRACKING>, C<EDTK_STATS_OUTMNGR>, C<EDTK_STATS_DISTRIB>, C<EDTK_STATS_ACQUIT>

Statistics table names.

=item C<EDTK_STATS_MANUFACT>

Manufacturer filter of the outgoing statistics: a comma- or space-separated list of
C<ED_IDMANUFACT> codes, empty (the default) reports them all.

=item C<EDTK_CSV_HEADER_METADATA>, C<EDTK_CSV_HEADER_DISTRIB>

Column order of the CSV exports.

=item C<EDTK_STATS_SQL00> through C<EDTK_STATS_SQL12>, C<EDTK_STATS_SQL90>

Named canned SQL queries of the statistics panel; C<EDTK_STATS_SQL90> may name a F<.sql>
file (C<$EDTK_PRGPATH/sql/...>).

=back

=head2 The C<[MAIL]> section

=over

=item C<EDTK_MAIL_TO>, C<EDTK_MAIL_TST>

Production and test recipients.

=item C<EDTK_MAIL_SENDER>

Envelope sender.

=item C<EDTK_MAIL_SUBJ>

Subject template; C<%date> and C<%time> are substituted.

=item C<EDTK_MAIL_SMTP>

SMTP relay host.

=item C<EDTK_MAIL_REFER>, C<EDTK_MAIL_OMGR>

Body templates of the recap and outgoing mail.

=item C<EDTK_MAIL_LIST_1> through C<EDTK_MAIL_LIST_5>

Named distribution lists.

=back

=head2 The C<[COMPO]> section

The LaTeX back-end.

=over

=item C<EDTK_BIN_COMPO>

Directory holding the TeX binaries.

=item C<EDTK_COMPO>

The composition command, e.g. C<pdflatex -halt-on-error>.

=item C<EDTK_COMPO_CMD_PDF>, C<EDTK_COMPO_CMD_DVI>, C<EDTK_COMPO_CMD_DVIPDF>

Per-format composition commands.

=item C<EDTK_COMPO_LIB>

Path to the F<edtkdoc.cls> class file.

=item C<EDTK_FILIERES_RECTO_VERSO>

Channels whose index is padded to an even page count; empty means none.

=item C<EDTK_CMD_RUN_BG_NOWAIT>

Non-blocking background composition; empty is blocking, a set value is non-blocking.

=item C<EDTK_LINE_CUTOFF>

Maximum number of characters before a newline in generated documents; empty falls back to
C<120>.

=item C<EDTK_RP_KILL_NON_LATIN>

Strip the non-Latin-1 (DEL and C1) characters from input records; off by default.

=item C<EDTK_IDLDOC_FORMAT>

Document batch-id format: C<UUID> (the default, a 36-character UUID), or C<LEGACY> / C<old>
(the 16-digit id, case-insensitive).

=item C<EDTK_COMPO_ASYNC>

Asynchronous composition; commented out in the template, C<yes> or C<no>.

=back

=head2 The C<[EDOCMNGR]> section

EDMS/GED indexing and transfer.

=over

=item C<EDMS_INDEX_COLS>

Columns of the EDMS index.

=item C<EDMS_DATE_FORMAT>

Date format used in the index; C<%Y/%m/%d>.

=item C<EDMS_IDX_FORMAT>

Index format: C<DOCUBASE> (the default) or C<SCOPMASTER>.

=item C<EDMS_IDX_HEADER>

Index header line, C<;>-separated.

=item C<EDMS_ACTIVATE_HEADER_ALFRESCO>

Emit the Alfresco header line; C<YES> or C<NO>.

=item C<EDMS_FTP_HOST>, C<EDMS_FTP_PORT>, C<EDMS_FTP_USER>, C<EDMS_FTP_PASS>

FTP(S) transfer target.

=item C<EDMS_FTP_DIR_IDX>, C<EDMS_FTP_DIR_DOCS>

Remote index and document directories.

=item C<EDTK_EDOCS_LINK>

Base URL of the document link.

=item C<EDMS_HTML_HOST>

HTML host used to build the lookup URL.

=item C<EDMS_URL_LOOKUP>

Lookup URL template, with C<%s> and C<%d> placeholders.

=item C<EDMS_BIN_GS>, C<EDMS_BIN_PDFTK>

Ghostscript and pdftk binaries.

=back

=head2 The C<[SERVICES]> section

Optional network services. All are inactive by default: an empty value keeps the mainline
behaviour.

=over

=item C<NWS_EMAILING_URI>

E-mailing service base URL; empty means unused (C</emails> is appended).

=item C<EMAILING_TEMPLATE>, C<EMAILING_USER_AGENT>

E-mailing template name and User-Agent string; empty falls back to each client's shipped
default.

=item C<KEYCLOAK_URL>, C<KEYCLOAK_CLIENT_ID>, C<KEYCLOAK_SECRET_ID>

Keycloak token endpoint and client credentials; all three are required together.

=item C<KEYCLOAK_REALM>

Keycloak realm path element; empty uses the client's shipped default.

=item C<DISSEMINATION_PLAN_URL>

Dissemination-plan service URL; empty skips the step.

=item C<EDTK_SSL_VERIFY>

TLS peer and host-name verification: C<1> (the default, safe) or C<0> for a service fronted
by a private CA.

=item C<EDTK_SSL_CA_PATH>

CA bundle, a file or a directory; empty uses the system trust store.

=item C<EDTK_ACQUIT_API>

Named acquittal callable, C<Module::function>; empty means no API acquittal.

=item C<EDTK_MAIL_ACQ>

Recipients of the acquittal recap report; empty means no report.

=item C<APIECM_URL>, C<APIECM_APIKEY_EDITIQUE>

ECM API base URL and the static editique API key; empty leaves the ECM injector unusable.

=back

=head2 The host-name section

A worked example of an override section, whose name is always uppercase. A section matching
C<uc(hostname())> is merged last, so it wins, and its C<iniEdtk> key can redirect the whole
read.

A few keys the code reads are not shipped in the template and stay optional: C<EDTK_DICO_COUNTRY>
(the country dictionary), C<EDTK_DICO_XLAT> (LaTeX character translation),
C<EDTK_XML_CATALOG_FILES> (XML catalogs, read from the C<[MAIL]> section),
C<EDTK_DB_STORAGE_ENGINE> (the MySQL storage engine, C<MyISAM> by default), and
C<EDTK_ENTIRE_YEARS_KEPT> / C<EDTK_STATS_DAYS_FROM> (retention and history windows).

=head1 AUTHOR

The oEdtk team.

=cut
