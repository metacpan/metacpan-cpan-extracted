#!/usr/bin/perl
# PODNAME: csvcopy.pl

#
# Written by Sébastien Millet
# 2016, 2017
#

#
# Copy a CSV file using Text::AutoCSV module
#

use strict;
use warnings;

use Getopt::Long qw( :config bundling no_ignore_case );
use Text::AutoCSV;

# I put here the exact same version number as Text::AutoCSV
my $VERSION = '1.2.0';

my $infoh = \*STDERR;

warn "$0 not in the same version as Text::AutoCSV"
  if $VERSION ne $Text::AutoCSV::VERSION;

#
# Manage options
#

#
# Each element of @PARAMS is an array ref made of:
#   0: help option as passed to GetOptions
#   1: option type when displaying option value in verbose mode,
#      can be undef (meaning: not applicable), 'STR', 'BOOL' or 'ARRAYREF'
#      ARRAYREF must be followed by the separator
#   2: Text::AutoCSV attribute of option (undef if not applicable)
#   3: option default value (for display only ; *not* passed to Text::AutoCSV
#      attributes)
#   4: help of option, displayed by -h
#   5: (rarely used): enforce passing attribute to Text::AutoCSV even if option
#      is not in use ; used to enforce attributes values for which this script
#      default value does not match Text::AutoCSV default value
my @PARAMS = (
    [ 'help|h',    undef,  undef, undef, 'print a short help screen' ],
    [ 'Help|hh',   undef,  undef, undef, 'print a bigger help screen' ],
    [ 'version|V', 'BOOL', undef, 'no',  'display version and quit' ],
    [ 'verbose|v', 'BOOL', undef, 'no',  'verbose output' ],
    [
        'id', undef, undef, undef,
        'Don\'t copy, instead, print information about input'
    ],
    [ 'i=s', 'STR', 'in_file',  '<stdin>',  'input file (default: stdin)' ],
    [ 'o=s', 'STR', 'out_file', '<stdout>', 'output file (default: stdout)' ],
    [
        'encoding|e=s', 'STR',
        'encoding',     'UTF-8,latin1',
        'encoding (default: auto-detection)'
    ],
    [
        'sep_char|s=s', 'STR', 'sep_char', '<auto-detect>',
        'CSV separator (default: auto-detection)'
    ],
    [
        'quote_char=s', 'STR',
        'quote_char',   '"',
        'CSV quote character (default: ")'
    ],

    [
        'escape_char=s', 'STR', 'escape_char', '<auto-detect>',
        'CSV escape character (default: auto-detection)'
    ],

    [
        'out_encoding=s', 'STR',
        'out_encoding',   '<same as input>',
        'output encoding (default: same as input)'
    ],

    [
        'out_utf8_bom=i', 'BOOL',
        'out_utf8_bom',   'no',
        'add BOM on UTF-8 output (default: no)'
    ],

    [
        'out_sep_char=s', 'STR', 'out_sep_char',
        '<same as input>',
        'output CSV separator (default: same as input)'
    ],

    [
        'out_quote_char=s', 'STR',
        'out_quote_char',   '<same as input>',
        'output quote char (default: same as input)'
    ],

    [
        'out_escape_char=s', 'STR',
        'out_escape_char',   '<same as input>',
        'output escape char (default: same as input)'
    ],

    [
        'out_always_quote=i',
        'BOOL',
        'out_always_quote',
        '<same as input>',
        "always surround each output field with quote chars\n"
          . "0 to remove feature \"always quote\", 1 to enforce it\n"
          . "(default: same as input)"
    ],

    [
        'out_fields=s',
        'ARRAYREF,',
        'out_fields',
        '<same as input>',
        "list of fields to write to output\n"
          . "you separate field names with ','\n"
          . "as in \"NAME,ADDRESS\"\n"
          . "(default: none)"
    ],

    [
        'out_orderby=s',
        'ARRAYREF,',
        'out_orderby',
        '<same as input)>',
        "list of fields to sort output\n"
          . "you separate field names with ','\n"
          . "as in \"NAME,ADDRESS\"\n"
          . "(default: none)"
    ],

    [
        'dont_mess_with_encoding=i',
        'BOOL',
        'dont_mess_with_encoding',
        'no',
        "if set to 1, completely ignore encoding aspects, meaning,\n"
          . "leave it to perl default\n"
          . "(default: input encoding auto-detection)"
    ],

    [
        'dates=s',
        'ARRAYREF,',
        'fields_dates',
        '<none>',
        "list of fields that must contain a datetime\n"
          . "you can specify multiple fields by separating them with ','\n"
          . "as in \"LASTLOGIN,CREATED\"\n"
          . "(default: none, no datetime expected by default)"
    ],

    [
        'dates_auto=i',
        'BOOL',
        'fields_dates_auto',
        'yes',
        "if set to 0, turn off datetime formats auto-detection\n"
          . "(default: datetime formats auto-detection is on)",
        1
    ],

    [
        'dates_auto_optimize=i',
        'BOOL',
        'fields_dates_auto_optimize',
        'no',
        "if set to 1, turn on datetime format auto-detection optimization,\n"
          . "relevant only if dates_auto is also set (use with caution:\n"
          . "when set, the detection will stop as soon as there's no more\n"
          . "ambiguity. If a following line contains a wrong date as per\n"
          . "detected format, turning on this optimization will detect a\n"
          . "format and later, complain about a wrong date encountered.)\n"
          . "(default: datetime format auto-detection optimization is off)",
        0
    ],

    [
        'dates_formats=s',
        'ARRAYREF||',
        'dates_formats_to_try',
        '<plenty of formats>',
        "list of formats to try when detecting datetime formats\n"
          . "you can specify multiple formats by separating them with ||\n"
          . "as in \"%d-%m-%y||%m-%d-%y\"\n"
          . "formats rely on Strptime syntax\n"
          . "(default: numerous formats are checked)"
    ],

    [
        'dates_formats_supp=s',
        'ARRAYREF||',
        'dates_formats_to_try_supp',
        '<plenty of formats>',
"list of *supplementary* formats to try when detecting datetime formats\n"
          . "you can specify multiple formats by separating them with ||\n"
          . "as in \"%d-%m-%y||%m-%d-%y\"\n"
          . "formats rely on Strptime syntax\n"
          . "(default: none)"
    ],

    [
        'dates_locales=s',
        'STR',
        'dates_locales',
        '<none>',
        "comma-separated list of locales to try when detecting\n"
          . "datetime formats, for example \"fr,en\"\n"
          . "(default: use default perl locale)"
    ],

    [
        'out_dates_format=s',
        'STR',
        'out_dates_format',
        '<same as input>',
        "dates format on output, in Strptime syntax\n"
          . "(default: use format detected on input)"
    ],

    [
        'out_dates_locale=s',
        'STR',
        'out_dates_locale',
        '<same as input>',
        "use only in addition to out_dates_format\n"
          . "dates locale on output\n"
          . "(default: use locale detected on input)"
    ],

    [
        'search_time=i',
        'BOOL',
        'dates_search_time',
        'yes',
        "if set to 0, detect only dates (don't look for times) when \n"
          . "detecting datetime formats\n"
          . "(default: auto-detect date and time)",
        1
    ],

    [
        'links|l=s',
        'STR',
        undef,
        '<no links>',
        "Links input with another CSV file\n"
          . "Argument is formed as \"PREFIX,LOCAL->REMOTE,FILE\"\n"
          . "where PREFIX will be added at beginning at each field of linked\n"
          . "file, where LOCAL is the main input field to read,\n"
          . "where REMOTE is the linked file field to find,\n"
          . "and FILE is the linked file.\n"
          . "Example: \"1:,LOGIN->SHORTNAME,users.csv\"\n"
          . "Options can be appended with \",{ ...options... }\" as in\n"
          . "\",LOGIN->SHORTNAME,users.csv,{ignore_empty => 0}\"\n"
          . "(default: no links)"
    ],

    [
        'croak_if_error=i', 'BOOL',
        'croak_if_error',   'yes',
        "croak if an error occurs in Text::AutoCSV"
    ],

    [ 'debug|d', 'BOOL', '_debug', 'no', 'debug output' ],
);

my %opts_vals;
my %opts;
for my $p (@PARAMS) {
    my $k = opt_to_key( $p->[0] );
    undef $opts_vals{$k};
    $opts{ $p->[0] } = \$opts_vals{$k};
}

veryshortusage() unless GetOptions(%opts);

usage()   if ( $opts_vals{'help'} );
usage(1)  if ( $opts_vals{'Help'} );
version() if ( $opts_vals{'version'} );
if (@ARGV) {
    print( $infoh "Trailing options\n" );
    veryshortusage();
}
my $verbose = $opts_vals{'verbose'};

my $opt_name_max_length = -1;
for my $p (@PARAMS) {
    my $l = length( opt_to_disp( $p->[0], 1 ) );
    $opt_name_max_length = $l if $l > $opt_name_max_length;
}

for my $p (@PARAMS) {
    next if ( !defined $p->[1] ) or $p->[1] !~ m/^ARRAYREF/;

    my $sep;
    ($sep) = $p->[1] =~ m/^ARRAYREF(.*)$/;
    if ( ( !defined $sep ) or $sep eq '' ) {
        die "Invalid ARRAYREF value for option '$p', check \@PARAMS!";
    }
    my $optname = opt_to_key( $p->[0] );
    my $optval  = $opts_vals{$optname};
    next unless defined $optval;

    $opts_vals{$optname} = [ split( quotemeta($sep), $optval ) ];
}

$opts_vals{dates_auto} = 0
  if ( !defined $opts_vals{dates_auto} )
  and defined $opts_vals{dates};

#
# Print out options value (if verbose is set and not with --id)
#

for my $p (@PARAMS) {
    next unless defined $p->[2];

    my $v = $opts_vals{ opt_to_key( $p->[0] ) };
    my $vstr;
    $vstr = do {
        if ( !defined $v ) { $p->[3] // '<undef>' }
        elsif ( $p->[1] eq 'BOOL' ) { $v ? 'yes' : 'no' }
        elsif ( $p->[1] eq 'STR' ) { $v }
        elsif ( $p->[1] =~ m/^ARRAYREF/ ) { '[' . join( '], [', @{$v} ) . ']' }
        else                              { undef }
    };
    die "\$vstr is undef, not allowed condition" unless defined($vstr);

    my $opt_disp = opt_to_disp( $p->[0], 1 );

    printf( $infoh "%-${opt_name_max_length}s %s %s\n",
        $opt_disp, ( defined($v) ? '*' : '.' ), $vstr )
      if $verbose and ( !$opts_vals{'id'} );

}

#
# Work out Text::AutoCSV attributes and create object
#

my %opts_autocsv;
for my $p (@PARAMS) {
    my $attribute = $p->[2];
    next unless defined($attribute);

    my $v = $opts_vals{ opt_to_key( $p->[0] ) };

    $v = $p->[5] if ( !defined $v ) and defined $p->[5];

    $opts_autocsv{$attribute} = $v if defined($v);
}

my $csv = Text::AutoCSV->new(%opts_autocsv);

#
# Manage links
#

if ( defined( $opts_vals{'links'} ) ) {
    my ( $prefix, $local, $remote, $file, $opts_read );
    unless ( ( $prefix, $local, $remote, $file, undef, $opts_read ) =
        $opts_vals{'links'} =~
        m/^([^,]*),([^,]+)->([^,]+),([^,]+)(,(\{.*\}))?$/ )
    {
        print( $infoh "Invalid links string\n" );
        veryshortusage();
    }
    $opts_read = '' unless defined($opts_read);

    print( $infoh
            "** links with $file:\n   prefix: $prefix\n   local field: $local\n"
          . "   remote field: $remote\n   options: $opts_read\n" )
      if $verbose;

    my $opts = {};
    if ( $opts_read ne '' ) {
        $opts = eval $opts_read; ## no critic (BuiltinFunctions::ProhibitStringyEval)
        if ( defined($@) or length($@) or ref($opts) ne 'HASH' ) {
            print( $infoh "Invalid links options\n" );
            veryshortusage();
        }
    }
    $csv->links( $prefix, "${local}->${remote}", $file, $opts );
}

#
# Final: ask $csv object to do the work
#

my $funcname = ( $opts_vals{'id'} ? 'print_id' : 'write' );
my $funcref = $csv->can($funcname);
die "Text::AutoCSV has no member function $funcname !!?"
  unless defined($funcref);
$csv->$funcref();

#
# End of main code.
# Below are the subs.
#

sub veryshortusage {
    print $infoh <<'EOF';
Try 'csvcopy.pl --help' for more information.
EOF

    exit 1;
}

sub version {
    print $infoh "csvcopy.pl $VERSION\n";
    exit 0;
}

sub usage {
    my $bigger = shift;

    print $infoh <<'EOF';
csvcopy.pl [OPTIONS...]
  Copy source to destination, doing CSV parsing in-between.

EOF

    my $max = -1;
    for (@PARAMS) {
        my $l = length( opt_to_disp( $_->[0] ) );
        $max = $l if $l > $max;
    }
    for my $opt (@PARAMS) {
        printf( $infoh "  %-${max}s ", opt_to_disp( $opt->[0] ) );
        die "\nPlease write a help for this option!" unless $opt->[4];
        print $infoh
          join( "\n" . ( ' ' x ( $max + 3 ) ), split( /\n/, $opt->[4] ) );
        print $infoh "\n";
    }
    print( $infoh "\n" );

    exit 0 unless $bigger;

    print $infoh <<'EOF';
* ENCODING
  Input encoding "auto-detection" is very basic and could be called "hack it".
  It just tries UTF-8 and if any issues found (= reading triggers at least one
  warning), it falls back to latin1.
  Note that when providing the --encoding option, you can put a list (comma
  separated) of encodings to try: the selected one will be the first with
  which no warning occurs. If all produce warnings, the first one is selected.

  Example:
    csvcopy.pl -i myfile.csv -e "UTF-8,UTF-16LE"
    It'll try UTF-8 and if a warning occurs, try UTF-16LE. If UTF-16LE also
    produces a warning, it'll finally choose UTF-8.

* CSV SEPARATOR
  The CSV separator is detected among ",", ";" and "\t" (tab)

* CSV ESCAPE CHARACTER
  The CSV escape character is detected among "\\" (one backslash) and "\""
  (one ")

* EXAMPLES:
  csvcopy.pl -i a.csv -o t.csv --out_escape_char "\\" --out_sep_char "," --out_always_quote 1 --out_encoding UTF-8
    Copy a.csv into t.csv, enforcing backslash as escape char, comma as
    separator, always quoting fields, and encoding output (whatever input
    encoding is) to UTF-8.

  csvcopy.pl -i a.csv -o t.csv --out_dates_format "%FT%T"
    Copy a.csv into t.csv, enforcing yyyy-mm-ddThh:MM:ss format for any column
    that contains a datetime.

  csvcopy.pl -i a.csv -o t.csv --out_dates_format "%b %d, %Y, %I:%M:%S %p" --out_dates_locale "en"
    Copy a.csv into t.csv, enforcing US datetime format.

  csvcopy.pl -i f1.csv -o linked.csv --links "1:,A->B,f2.csv,{case=>1}"
    Links f2.csv to f1.csv by mathcing f1'A field with f2'B field, case sensitive match.
EOF
    exit 0;
}

sub opt_to_key {
    my $k = shift;
    $k =~ s/[|=].*//;
    return $k;
}

sub opt_to_disp {
    my $opt   = shift;
    my $ltrim = shift;    # ltrim = left-trim only

    $opt =~ s/[=].*//;
    my $short_opt_seen = 0;
    my $r              = '';
    for ( split( /\|/, $opt ) ) {
        if ( length($_) == 1 ) {
            $r              = ", " . $r if length($r) >= 1;
            $r              = "-$_" . $r;
            $short_opt_seen = 1;
        }
        else {
            $r .= ", " if length($r) >= 1;
            $r .= "--$_";
        }
    }
    $r = '    ' . $r if ( !$short_opt_seen ) and ( !$ltrim );
    return $r;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

csvcopy.pl

=head1 VERSION

version 1.2.0

=head1 AUTHOR

Sébastien Millet <milletseb@laposte.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016, 2017 by Sébastien Millet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
