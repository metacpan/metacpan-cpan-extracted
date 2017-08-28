#!/usr/bin/perl

#
# Sébastien Millet, August 2017
#

#
# tkcsvcopy.pl
#
# GUI interface to Text::AutoCSV.
# Works like csvcopy.pl, but so far, does not manage links.
#

use 5.014;
use utf8;

use strict;
use warnings;

use Tk;
use Tk::FileDialog;
use Tk::ROText;
use Tk::BrowseEntry;
use Tk::DropSite;
use Tk::HList;
use Tk::ItemStyle;
use Tk::ProgressBar;
use Tk::StayOnTop;

use File::HomeDir 'my_home';
use File::Spec::Functions 'catfile';
use DB_File;
use Browser::Open qw( open_browser );

use Text::AutoCSV;

my $VERSION = '0.2';

my $DEFAULT_DB_FILE = '.tkcsvcopy.db';

my @encoding_choices =
  qw(utf-8 utf-16 utf-16le utf16-be utf32 utf-32le utf-32be iso-8859-1
  iso-8859-2 iso-8859-3 iso-8859-4 iso-8859-5 iso-8859-6 iso-8859-7 iso-8859-8 iso-8859-9
  iso-8859-10 iso-8859-11 iso-8859-12 iso-8859-13 iso-8859-14 iso-8859-15);

sub usage {
    print( STDERR <<"EOF" );
Usage:
    tkcsvcopy.pl [OPTIONS...]
Perl/Tk GUI to detect settings of, and copy, CSV files.

  -h, --help    Display this help screen.
      --db DB   Enforce location of DB file to save options.
                By default, store in ~/$DEFAULT_DB_FILE.
      --nodb    Don't use a db for options (options are not persistent).
      --read F  Upon start, display input information of file F.
      --excel   Tune output settings to make MS EXCEL happy.
                Have , as separator, " as quote, " as escape,
                UTF-8 encoding with BOM, and ymd/24h for datetime.
      --excelfr Same as --excel, but ; as separator.
EOF
    return;
}

if ( grep { /^--?h(elp)?$/i } @ARGV ) {
    usage();
    exit 0;
}

#
# * ************* *
# * CONFIGURATION *
# * ************* *
#

my %db;
my $read_it = '';
my $excel   = '';

my $db_absolute_file_name = catfile( my_home(), $DEFAULT_DB_FILE );
if ( @ARGV >= 2 and $ARGV[0] =~ /^--?db/i ) {
    $db_absolute_file_name = $ARGV[1];
    splice @ARGV, 0, 2;
}
if ( @ARGV >= 1 and $ARGV[0] =~ /^--?nodb$/i ) {
    $db_absolute_file_name = '';
    shift @ARGV;
}
if ( @ARGV >= 1 and $ARGV[0] =~ /^--?excel$/i ) {
    $excel = 'en';
    shift @ARGV;
}
if ( @ARGV >= 1 and $ARGV[0] =~ /^--?excelfr$/i ) {
    $excel = 'fr';
    shift @ARGV;
}
if ( @ARGV >= 2 and $ARGV[0] =~ /^--?read$/i ) {
    $read_it = $ARGV[1];
    splice @ARGV, 0, 2;
}

if (@ARGV) {
    print
      ( STDERR ( $ARGV[0] =~ /^-/ ? "Unknown option.\n" : "Trailing option.\n" )
      );
    usage();
    exit 1;
}

tie %db => 'DB_File', $db_absolute_file_name if $db_absolute_file_name ne '';

my $init = "_initialized_$VERSION";
if ( !$db{$init} ) {
    %db = (
        in_file                     => '',
        sep_char                    => ',',
        sep_char_detect             => 1,
        quote_char                  => '"',
        escape_char                 => '"',
        escape_char_detect          => 1,
        encoding                    => 'utf-8, iso-8859-1',
        encoding_detect             => 1,
        fields_dates_auto_optimize  => 1,
        dates_formats_to_try        => '%Y-%m-%d %H:%M:%S',
        dates_formats_to_try_detect => 1,
        dates_locales               => 'en,fr',
        dates_locales_detect        => 1,

        out_file                  => '',
        out_sep_char              => ',',
        out_sep_char_useinput     => 1,
        out_quote_char            => '"',
        out_quote_char_useinput   => 1,
        out_escape_char           => '"',
        out_escape_char_useinput  => 1,
        out_encoding              => 'utf-8',
        out_encoding_useinput     => 1,
        out_always_quote          => 'no',
        out_always_quote_useinput => 1,
        out_dates_format          => '%Y-%m-%d %T',
        out_dates_format_useinput => 1,
        out_dates_locale          => 'en',
        out_dates_locale_useinput => 1,
        out_utf8_bom              => 0,

        $init => 1
    );
}
if ( $read_it ne '' ) {
    $read_it =~ s/^\s+|\s+$//g;
    my $w = $read_it;

    $db{in_file} = $read_it;

    $w .= '-copy' unless $w =~ s/(\.[^.]+)$/-copy$1/;
    $db{out_file} = $w if $read_it ne $w;
}
if ( $excel ne '' ) {
    $db{out_sep_char}              = ( $excel eq 'fr' ? ';' : ',' );
    $db{out_sep_char_useinput}     = 0;
    $db{out_quote_char}            = '"';
    $db{out_quote_char_useinput}   = 0;
    $db{out_escape_char}           = '"';
    $db{out_escape_char_useinput}  = 0;
    $db{out_encoding}              = 'utf-8';
    $db{out_encoding_useinput}     = 0;
    $db{out_always_quote}          = 'no';
    $db{out_always_quote_useinput} = 0;
    $db{out_dates_format}          = '%Y-%m-%d %T';
    $db{out_dates_format_useinput} = 0;
    $db{out_dates_locale}          = 'en';
    $db{out_dates_locale_useinput} = 0;
    $db{out_utf8_bom}              = 1;
}

#
# * *********************** *
# * MAIN WINDOW BUILD START *
# * *********************** *
#

my $main_window = MainWindow->new();

$main_window->title('TK CSV COPY');

#
# Menu
#

my $menubar = $main_window->Menu( -type => "menubar" );

my $menubar_file = $main_window->Menu( -type => "normal" );
$menubar_file->add( "command", -label => "Quit", -command => sub { exit; } );

$menubar->add( "cascade", -menu => $menubar_file, -label => "File" );

my $menubar_help = $main_window->Menu( -type => "normal" );
$menubar_help->add(
    "command",
    -label   => "strptime help on Internet",
    -command => \&c_strptime
);
$menubar_help->add("separator");
$menubar_help->add( "command", -label => "About...", -command => \&c_about );

$menubar->add( "cascade", -menu => $menubar_help, -label => "Help" );

$main_window->configure( -menu => $menubar );

#
# Main window frames and shared options definition.
#

#my %fropts = (-relief => 'ridge', -borderwidth => 4);
my %fropts     = ();
my $FONTSIZE   = 8;
my $BUTTONPADX = 2;

my %butopts = ( -font => [ -size => $FONTSIZE, -weight => 'bold' ] );
my %entopts = (
    -background         => 'white',
    -disabledbackground => 'dark grey',
    -readonlybackground => 'dark gray',
    -relief             => 'flat',
    -font               => [ -size => $FONTSIZE, -weight => 'normal' ]
);
my %entcharwidth = ( -width => 3 );
my %labopts      = ( -font  => [ -size => $FONTSIZE ] );
my %stdpad       = ( -padx  => 2, -pady => 2 );
my %chkopts   = ();
my @hlistopts = {
    -background => 'white',
    -font       => [ -size => $FONTSIZE, -weight => 'normal' ]
};
push @hlistopts,
  {
    -background => '#F6F6F6',
    -font       => [ -size => $FONTSIZE, -weight => 'normal' ]
  };

my $frame_top =
  $main_window->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $frame_top_L = $frame_top->Frame(%fropts)
  ->pack( -side => 'left', -expand => 1, -fill => 'both' );
my $frame_top_R = $frame_top->Frame(%fropts)
  ->pack( -side => 'left', -expand => 1, -fill => 'both' );
my $frame_middle1 = $main_window->Frame(%fropts)
  ->pack( -side => 'top', -expand => 1, -fill => 'both' );
my $frame_middle2 = $main_window->Frame(%fropts)
  ->pack( -side => 'top', -expand => 0, -fill => 'x' );
my $frame_bottom =
  $main_window->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );

my $PADLEFT = ' ' x 8;

sub cmd_update_enabled_disabled {
    my ( $widget_checkbutton, $conf_var_name ) = @_;
    $widget_checkbutton->configure(
        -state => ( $db{ $_[1] } ? 'disabled' : 'normal' ) );
    return;
}

#
# Top left frame (input tuning)
#

$frame_top_L->Label(
    -text       => 'input',
    -background => 'dark gray',
    -foreground => 'white',
    %labopts, -font => [ -weight => 'bold' ]
)->pack( -side => 'top', -fill => 'x', -padx => 1 );

my $frtopl_inp =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
$frtopl_inp->Label( -text => 'File ', %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_in_file =
  $frtopl_inp->Entry( -textvariable => \$db{in_file}, %entopts )
  ->pack( -side => 'left', %stdpad, -expand => 1, -fill => "x" );
$frtopl_inp->Button(
    -text    => '...',
    -command => \&c_browse_input,
    %butopts
)->pack( -side => 'left', -padx => $BUTTONPADX, %stdpad );

my $frtopl_sep =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_sep_char = $frtopl_sep->Entry(
    -textvariable => \$db{sep_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_sep->Label( -text => 'Separator char ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopl_sep->Label( -text => "${PADLEFT}Detect", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_sep_char_detect = $frtopl_sep->Checkbutton(
    -variable => \$db{sep_char_detect},
    -command =>
      [ \&cmd_update_enabled_disabled, $ctrl_sep_char, 'sep_char_detect' ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopl_quo =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_quote_char = $frtopl_quo->Entry(
    -textvariable => \$db{quote_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_quo->Label( -text => 'Quote char ', %labopts )
  ->pack( -side => 'right', %stdpad );

my $frtopl_esc =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_escape_char = $frtopl_esc->Entry(
    -textvariable => \$db{escape_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_esc->Label( -text => 'Escape char ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopl_esc->Label( -text => "${PADLEFT}Detect", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_escape_char_detect = $frtopl_esc->Checkbutton(
    -variable => \$db{escape_char_detect},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_escape_char, 'escape_char_detect'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopl_enc =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_encoding = $frtopl_enc->BrowseEntry(
    -variable   => \$db{encoding},
    -width      => 24,
    -background => 'white',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_enc->Label( -text => 'Encoding(s) * ', %labopts )
  ->pack( -side => 'right', %stdpad );
$ctrl_encoding->choices( [ '', @encoding_choices ] );
$frtopl_enc->Label( -text => "${PADLEFT}Detect ** ", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_encoding_detect = $frtopl_enc->Checkbutton(
    -variable => \$db{encoding_detect},
    -command =>
      [ \&cmd_update_enabled_disabled, $ctrl_encoding, 'encoding_detect' ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopl_opt =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_fields_dates_auto_optimize = $frtopl_opt->Checkbutton(
    -variable => \$db{fields_dates_auto_optimize},
    %chkopts
)->pack( -side => 'right' );
$frtopl_opt->Label( -text => 'Fast datetime format detection ', %labopts )
  ->pack( -side => 'right', %stdpad );

my $frtopl_dt =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_dates_formats_to_try = $frtopl_dt->Entry(
    -textvariable => \$db{dates_formats_to_try},
    -width        => 26,
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_dt->Label( -text => 'Datetime format(s) *  *** ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopl_dt->Label( -text => "${PADLEFT}Default", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_dates_formats_to_try_detect = $frtopl_dt->Checkbutton(
    -variable => \$db{dates_formats_to_try_detect},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_dates_formats_to_try,
        'dates_formats_to_try_detect'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopl_loc =
  $frame_top_L->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_dates_locales = $frtopl_loc->Entry(
    -textvariable => \$db{dates_locales},
    -width        => 12,
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopl_loc->Label( -text => 'Datetime locale(s) *  **** ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopl_loc->Label( -text => "${PADLEFT}Default", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_dates_locale_detect = $frtopl_loc->Checkbutton(
    -variable => \$db{dates_locales_detect},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_dates_locales,
        'dates_locales_detect'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopl_rea =
  $frame_top_L->Frame(%fropts)->pack( -side => 'bottom', -fill => 'x' );
my $button_read = $frtopl_rea->Button(
    -text    => 'Display input information',
    -command => [ \&c_execute, 'read' ],
    %butopts
)->pack( -expand => 1, -fill => 'x', -padx => $BUTTONPADX, %stdpad );

#
# Top right frame (output tuning)
#

$frame_top_R->Label(
    -text       => 'output',
    -background => 'dark gray',
    -foreground => 'white',
    %labopts, -font => [ -weight => 'bold' ]
)->pack( -expand => 1, -side => 'top', -fill => 'x', -padx => 1 );

my $frtopr_1 =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
$frtopr_1->Label( -text => 'File ', %labopts )
  ->pack( -side => 'left', %stdpad );
my $entry_output =
  $frtopr_1->Entry( -textvariable => \$db{out_file}, %entopts )
  ->pack( -side => 'left', -expand => 1, -fill => 'x', %stdpad );
$frtopr_1->Button(
    -text    => '...',
    -command => \&c_browse_output,
    %butopts
)->pack( -side => 'left', -padx => $BUTTONPADX, %stdpad );

my $frtopr_sep =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_sep_char = $frtopr_sep->Entry(
    -textvariable => \$db{out_sep_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_sep->Label( -text => 'Separator char ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopr_sep->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_sep_char_useinput = $frtopr_sep->Checkbutton(
    -variable => \$db{out_sep_char_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_sep_char,
        'out_sep_char_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_quo =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_quote_char = $frtopr_quo->Entry(
    -textvariable => \$db{out_quote_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_quo->Label( -text => 'Quote char ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopr_quo->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_quote_char_useinput = $frtopr_quo->Checkbutton(
    -variable => \$db{out_quote_char_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_quote_char,
        'out_quote_char_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_esc =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_escape_char = $frtopr_esc->Entry(
    -textvariable => \$db{out_escape_char},
    %entcharwidth,
    -justify => 'right',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_esc->Label( -text => 'Escape char ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopr_esc->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_escape_char_useinput = $frtopr_esc->Checkbutton(
    -variable => \$db{out_escape_char_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_escape_char,
        'out_escape_char_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_enc =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_encoding = $frtopr_enc->BrowseEntry(
    -variable   => \$db{out_encoding},
    -width      => 14,
    -background => 'white',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_enc->Label( -text => 'Encoding ', %labopts )
  ->pack( -side => 'right', %stdpad );
$ctrl_out_encoding->choices( \@encoding_choices );
$frtopr_enc->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_encoding_useinput = $frtopr_enc->Checkbutton(
    -variable => \$db{out_encoding_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_encoding,
        'out_encoding_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_bom =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_utf8_bom = $frtopr_bom->Checkbutton(
    -variable => \$db{out_utf8_bom},
    %chkopts
)->pack( -side => 'right' );
$frtopr_bom->Label( -text => 'If UTF-8, write UTF-8 BOM ', %labopts )
  ->pack( -side => 'right', %stdpad );

my $frtopr_iaq =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_always_quote = $frtopr_iaq->BrowseEntry(
    -variable   => \$db{out_always_quote},
    -width      => 6,
    -background => 'white',
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_iaq->Label( -text => 'Always quote ', %labopts )
  ->pack( -side => 'right', %stdpad );
$ctrl_out_always_quote->choices( [ '', 'yes', 'no' ] );
$frtopr_iaq->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_always_quote_useinput = $frtopr_iaq->Checkbutton(
    -variable => \$db{out_always_quote_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_always_quote,
        'out_always_quote_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_dt =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_dates_format = $frtopr_dt->Entry(
    -textvariable => \$db{out_dates_format},
    -width        => 26,
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_dt->Label( -text => 'Datetime format *** ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopr_dt->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_dates_format_useinput = $frtopr_dt->Checkbutton(
    -variable => \$db{out_dates_format_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_dates_format,
        'out_dates_format_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_loc =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $ctrl_out_dates_locale = $frtopr_loc->Entry(
    -textvariable => \$db{out_dates_locale},
    -width        => 6,
    %entopts
)->pack( -side => 'right', %stdpad );
$frtopr_loc->Label( -text => 'Datetime locale **** ', %labopts )
  ->pack( -side => 'right', %stdpad );
$frtopr_loc->Label( -text => "${PADLEFT}Use input", %labopts )
  ->pack( -side => 'left', %stdpad );
my $ctrl_out_dates_locale_useinput = $frtopr_loc->Checkbutton(
    -variable => \$db{out_dates_locale_useinput},
    -command  => [
        \&cmd_update_enabled_disabled, $ctrl_out_dates_locale,
        'out_dates_locale_useinput'
    ],
    %chkopts
)->pack( -side => 'left', %stdpad );

my $frtopr_wri =
  $frame_top_R->Frame(%fropts)->pack( -side => 'top', -fill => 'x' );
my $button_copy = $frtopr_wri->Button(
    -text    => 'Copy input -> output',
    -command => [ \&c_execute, 'write' ],
    %butopts
)->pack( -expand => 1, -fill => 'x', -padx => $BUTTONPADX, %stdpad );

#
# Middle frame (information display)
#

my $hl = $frame_middle1->Scrolled(
    'HList',
    -scrollbars       => "se",
    -relief           => 'flat',
    -header           => 1,
    -columns          => 7,
    -selectbackground => 'white',
    %{ $hlistopts[0] }
)->pack( -expand => 1, -fill => 'both', %stdpad );
my $col = 0;
for ( 'N', 'Field', 'Header', 'ML', 'Datetime format', 'Datetime locale' ) {
    $hl->header( 'create', $col++, -text => $_ );
}

my $stdout_box = $frame_middle2->Scrolled(
    'ROText',
    -scrollbars => "e",
    -relief     => 'flat',
    -font => [ -family => 'courier', -size => $FONTSIZE, -weight => 'normal' ],
    -height => 8
)->pack( -expand => 1, -fill => "x", %stdpad );
my $trick = $stdout_box->Subwidget('scrolled');
tie *STDERR, ref $trick, $stdout_box;

# Found here:
#   https://stackoverflow.com/questions/20964361/perl-tk-drag-drop-folder-from-windows-explorer
$frame_middle1->DropSite(
    -dropcommand => [ \&accept_drop, $frame_middle2 ],

    # FIXME
    #   Got to use tkdnd, seems more portable
    -droptypes => ['Local'],
);
$frame_middle2->DropSite(
    -dropcommand => [ \&accept_drop, $frame_middle2 ],

    # FIXME
    #   See FIXME above
    -droptypes => ['Local'],
);

sub accept_drop {
    my $frame = shift;

    my $file_name = $frame->SelectionGet( -selection => 'CLIPBOARD' );
    $file_name =~ s/\n.*$//m;
    set_text( $ctrl_in_file, $file_name );
    c_execute('read');
    return;
}

#
# Bottom frame (some footer text)
#

$frame_bottom->Label(
    -text =>
      ' * Comma-separated list    ** Try UTF-8, fall back on iso-8859-1    '
      . '*** strptime format, see Help menu    **** 2-letter country codes',
    %labopts
)->pack( -side => 'left', %stdpad );

#
# * ********************* *
# * MAIN WINDOW BUILD END *
# * ********************* *
#

# The below is done to enable or disable controls, based on whether or not their
# "control" widget ('detect' or 'use input') is checked.

cmd_update_enabled_disabled( $ctrl_sep_char,    'sep_char_detect' );
cmd_update_enabled_disabled( $ctrl_escape_char, 'escape_char_detect' );
cmd_update_enabled_disabled( $ctrl_encoding,    'encoding_detect' );
cmd_update_enabled_disabled( $ctrl_dates_formats_to_try,
    'dates_formats_to_try_detect' );
cmd_update_enabled_disabled( $ctrl_dates_locales, 'dates_locales_detect' );

cmd_update_enabled_disabled( $ctrl_out_sep_char,   'out_sep_char_useinput' );
cmd_update_enabled_disabled( $ctrl_out_quote_char, 'out_quote_char_useinput' );
cmd_update_enabled_disabled( $ctrl_out_escape_char,
    'out_escape_char_useinput' );
cmd_update_enabled_disabled( $ctrl_out_encoding, 'out_encoding_useinput' );
cmd_update_enabled_disabled( $ctrl_out_always_quote,
    'out_always_quote_useinput' );
cmd_update_enabled_disabled( $ctrl_out_dates_format,
    'out_dates_format_useinput' );
cmd_update_enabled_disabled( $ctrl_out_dates_locale,
    'out_dates_locale_useinput' );

if ( $read_it ne '' ) {
    c_execute('read');
}

MainLoop;

exit;

#
# SUBS
#

sub c_strptime {
    open_browser(
"http://search.cpan.org/~drolsky/DateTime-Format-Strptime-1.74/lib/DateTime/Format/Strptime.pm#STRPTIME_PATTERN_TOKENS"
    );
    return;
}

#
# See
#   http://www.perlmonks.org/?node_id=224185
# about centering window.
#
sub window_center {
    my $w = shift;

    $w->withdraw();    # Hide the window while we move it about
    $w->update();      # Make sure width and height are current
                       # Center window
    my $xpos = int( ( $w->screenwidth - $w->width ) / 2 );
    my $ypos = int( ( $w->screenheight - $w->height ) / 2 );
    $w->geometry("+$xpos+$ypos");
    $w->deiconify();    # Show the window again

    return;
}

sub c_about {

    state $count_about = 0;

    return if $count_about;
    $count_about++;

    my $w = $main_window->Toplevel;
    $w->title("About tkcsvcopy.pl");
    $w->Label(
        -text => <<"EOF" ,
TK CSV COPY version $VERSION
Copy CSV files, modifying some CSV-level (separator) or higher-level (date
format) throughout the copy.

Copyright 2017 Sébastien Millet <milletseb\@laposte.net>
EOF
        -font => [ -size => 12 ]
    )->pack( -side => "top", -padx => 8 );
    $w->Button(
        -text    => "Ok",
        -font    => [ -size => 12 ],
        -command => sub { $w->destroy(); }
    )->pack( -side => "bottom", -pady => 8 );
    $w->resizable( 0, 0 );
    $w->OnDestroy( sub { $count_about--; } );

    window_center($w);

    return;
}

sub set_text {
    my ( $text_widget, $new_value ) = @_;

    $text_widget->delete( '0.0', 'end' );
    $text_widget->insert( 'end', $new_value );

    return;
}

sub c_browse_input {
    my $types = [ [ 'CSV Files', '.csv' ], [ 'All Files', '*' ] ];
    my $file_name = $main_window->getOpenFile( -filetypes => $types );

    return if ( !defined $file_name ) or $file_name eq '';

    set_text( $ctrl_in_file, $file_name );

    return;
}

sub c_browse_output {
    my $types = [ [ 'CSV Files', '.csv' ], [ 'All Files', '*' ] ];
    my $file_name = $main_window->getSaveFile(
        -filetypes        => $types,
        -defaultextension => 'csv'
    );

    return if ( !defined $file_name ) or $file_name eq '';

    set_text( $entry_output, $file_name );

    return;
}

sub reset_display {
    $stdout_box->delete( '0.0', 'end' );
    $hl->delete('all');

    return;
}

sub get_text_autocsv_opts {

    my %table = (
        'in_file'                    => '',
        'sep_char'                   => 'sep_char_detect',
        'quote_char'                 => '',
        'escape_char'                => 'escape_char_detect',
        'encoding'                   => 'encoding_detect',
        'dates_formats_to_try@'      => 'dates_formats_to_try_detect',
        'dates_locales'              => 'dates_locales_detect',
        'out_file'                   => '',
        'out_sep_char'               => 'out_sep_char_useinput',
        'out_quote_char'             => 'out_quote_char_useinput',
        'out_escape_char'            => 'out_escape_char_useinput',
        'out_encoding'               => 'out_encoding_useinput',
        'out_always_quote!'          => 'out_always_quote_useinput',
        'out_dates_format'           => 'out_dates_format_useinput',
        'out_dates_locale'           => 'out_dates_locale_useinput',
        'out_utf8_bom'               => '',
        'fields_dates_auto_optimize' => ''
    );

    my $e    = 0;
    my $what = $_[0];

    my @senses = [ 'in_file', 'input' ];
    push @senses, [ 'out_file', 'output' ] if $what eq 'write';
    for my $i (@senses) {
        my $val = $db{ $i->[0] };
        if ( ( !defined $val ) or $val =~ /^\s*$/ ) {
            print( STDERR "Error: you must specify an $i->[1].\n" );
            $e++;
        }
    }

    my %opts;

    #    %opts = (dates_ignore_trailing_chars => 0);

    for my $k ( sort keys %table ) {
        my $f = $k;
        $f =~ s/[\@!]$//;

        next if $table{$k} ne '' and $db{ $table{$k} };
        next if $what eq 'read'  and $f =~ /^out_/;

        my $v = $db{$f} // '';
        $v = [ split( /\s*,\s*/, $v ) ] if $k =~ /\@$/;
        if ( $k =~ /!$/ ) {
            if ( $v =~ /^yes$/i ) {
                $v = 1;
            }
            elsif ( $v =~ /^no$/i ) {
                $v = 0;
            }
            else {
                print( STDERR "Error: $f must be either 'yes' or 'no'.\n" );
                $v = 0;
                $e++;
            }
        }
        if ( ( !ref $v ) and length($v) == 2 and substr( $v, 0, 1 ) eq "\\" ) {
            $v = eval "\"$v\"" or die $@;
        }
        $opts{$f} = $v;
    }

# If the user wishes to specify their own formats, then we leave the time identification up
# to them, too.
    $opts{dates_search_time} = 0 if exists $opts{dates_formats_to_try};

    return if $e;

    return %opts;
}

sub update_table_fields {
    my $coldata = $_[0];
    my @fields;
    @fields = @$coldata if defined $coldata;

    my @style_align_right;
    my @style_align_left;
    for ( 0 .. 1 ) {
        push @style_align_right,
          $hl->ItemStyle(
            'text',
            -anchor => 'e',
            %{ $hlistopts[$_] }
          );
        push @style_align_left,
          $hl->ItemStyle(
            'text',
            -anchor => 'w',
            %{ $hlistopts[$_] }
          );
    }

    my @correspondance = ( 0, 1, 5, 3, 4 );
    for my $if ( 0 .. $#fields ) {
        my $f = $fields[$if];

        my $e = $hl->addchild("");
        $hl->itemCreate(
            $e, 0,
            -itemtype => 'text',
            -text     => "$if",
            -style    => $style_align_right[ $if % 2 ]
        );
        for my $i ( 0 .. 4 ) {
            $hl->itemCreate(
                $e, $i + 1,
                -itemtype => 'text',
                -text     => $f->[ $correspondance[$i] ],
                -style    => $style_align_left[ $if % 2 ]
            );
        }
    }

    return;
}

sub output_err {
    my $err = shift;

    return 0 if !$err;

    $err =~ s/\n.*//sm;
    $err =~ s/(\S) at \S.* line \d+\.$/$1/;
    print( STDERR "$err\n" );
    return 1;
}

my $p_fw;     ## no critic (ControlStructures::ProhibitUnreachableCode)
my $p_bar;    ## no critic (ControlStructures::ProhibitUnreachableCode)
my ( $p_cur_row, $p_nb_rows ); ## no critic (ControlStructures::ProhibitUnreachableCode)

sub c_execute {
    my $what = $_[0];
    die "FATAL: internal error" if $what !~ /^read|write$/;
    my $writing = ( $what eq 'write' );

    reset_display();
    my %opts = get_text_autocsv_opts($what);
    return if !%opts;

    $stdout_box->insert( 'end', "Reading...\n" );
    $main_window->Busy();
    $main_window->update();

    if ($writing) {
        $p_cur_row = 0;
        $p_fw = $main_window->Toplevel( -title => 'Copying...' );
        $p_fw->geometry('250x20');
        $p_fw->resizable( 0, 0 );
        window_center($p_fw);
        $p_bar = $p_fw->ProgressBar(
            -from        => 0,
            -to          => 1,
            -blocks      => 1,
            -troughcolor => 'white',
            -foreground  => 'dark blue'
        )->pack( -expand => 1, -fill => 'both' );
        $p_fw->focus();

        $p_fw->protocol( 'WM_DELETE_WINDOW', \&Tk::NoOp );
        $p_fw->stayOnTop();

        # Do it a first time to refresh display
        p_bar_update();
    }

    reset_display();
    my $coldata;

    eval {
        my $csv = Text::AutoCSV->new(
            fields_dates_auto => 1,
            verbose           => 1,
            walker_hr         => \&p_bar_update,
            %opts
        );

        # The below will trigger the detection of CSV characteristics.
        # It can be long, if detecting Datetime formats across all fields.
        $coldata = [ $csv->get_coldata() ];

        $p_nb_rows = $csv->get_nb_rows() // 0;

        $p_bar->configure( -to => ( $p_nb_rows < 1 ? 1 : $p_nb_rows ) )
          if $writing;

        $stdout_box->insert( 'end', '-- ' . $csv->get_in_file_disp() . "\n" );
        $stdout_box->insert( 'end',
            'number of records: ' . ( $p_nb_rows - 1 ) . "\n" );
        my $c = Text::AutoCSV::_render( $csv->get_sep_char() ); ## no critic (Subroutines::ProtectPrivateSubs)
        $stdout_box->insert( 'end', 'sep_char:          ' . $c . "\n" );
        $stdout_box->insert( 'end',
            'escape_char:       ' . $csv->get_escape_char() . "\n" );
        $stdout_box->insert( 'end',
            'encoding:          ' . $csv->get_in_encoding() . "\n" );
        $stdout_box->insert( 'end',
                'is always quoted:  '
              . ( $csv->get_is_always_quoted() ? 'yes' : 'no' )
              . "\n" );

        if ($writing) {
            $stdout_box->insert( 'end', "\n" );
            update_table_fields($coldata);
            $csv->write();
        }

        1;
    };
    output_err($@);

    do {
        $p_fw->destroy();
        $p_fw = undef;
    } if $writing;

    update_table_fields($coldata) if !$writing;
    $main_window->Unbusy();

    return;
}

sub p_bar_update {
    $p_cur_row++;
    if ( $p_cur_row % 50 == 0 ) {
        $p_bar->value($p_cur_row);
        $main_window->update();
    }

    return;
}

