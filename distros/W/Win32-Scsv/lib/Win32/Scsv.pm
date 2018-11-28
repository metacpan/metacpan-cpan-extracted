package Win32::Scsv;
$Win32::Scsv::VERSION = '0.41';
use 5.026;
use warnings;

=head1 NAME

Win32::Scsv - Convert from and to *.xls, *.csv using Win32::OLE

=head1 SYNOPSIS

    use Win32::Scsv qw(set_handle_ole xls_2_csv xls_all_csv);

    set_handle_ole;

    xls_2_csv('Test1.xls'     => 'dummy.csv');
    xls_2_csv('Abc.xls%Tab01' => 'data01.csv', { cpy => 'all' });          # copy values *AND* format...
    xls_2_csv('Abc.xls%Tab02' => 'data02.csv', { cpy => 'val' });          # copy only values...
    xls_2_csv('Abc.xls%Tab03' => 'data03.csv');                            # ...same as { cpy => 'val' }, which is the default...
    xls_2_csv('Abc.xls%Tab04' => 'data04.csv', { rmc => [ 'CR', 'LF' ] }); # remove CRLF from all cells...
    xls_2_csv('Abc.xls%Tab05' => 'data05.csv', { clc => 1 });              # force recalculation...

    xls_all_csv('Abc.xls' => 'result_*.csv', { cpy => 'all' });            # copy all sheets in one operation...

    csv_2_xls('dummy.csv' => 'New.xlsx%Tab9', {
      'tpl' => 'Template.xls',
      'prt' => 1,
      'csz' => [
         ['H:H' => 13.71],
         ['A:D' => 3],
      ],
      'fmt'  => [
         ['A:A' => '#,##0.000'],
         ['B:B' => '\\<@\\>'],
         ['C:C' => 'dd/mm/yyyy hh:mm:ss'],
      ],
    });

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut

use Win32::OLE;
use Win32::OLE::Variant;
use Carp;
use File::Spec;
use File::Copy;
use File::Slurp;
use Win32::File qw();

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(
  set_handle_obj set_handle_ole set_handle_quit get_hwnd
  set_size_pos set_size_min set_size_max
  xls_2_csv xls_all_csv xls_lst_csv csv_2_xls csv_lst_xls
  get_book get_ver get_handle get_lang
  get_last_row get_last_col XLRef get_sno
  set_style_R1C1 set_style_default trf_style_R1C1
);

my $CXL_OpenXML  =    51; # xlOpenXMLWorkbook
my $CXL_PasteVal = -4163; # xlPasteValues
my $CXL_PasteAll = -4104; # xlPasteAll
my $CXL_Csv      =     6; # xlCSV
my $CXL_CalcMan  = -4135; # xlCalculationManual
my $CXL_Previous =     2; # xlPrevious
my $CXL_ByRows   =     1; # xlByRows
my $CXL_ByCols   =     2; # xlByColumns
my $CXL_R1C1     = -4150; # xlR1C1
my $CXL_Part     =     2; # xlPart
my $CXL_Normal   = -4143; # xlNormal
my $CXL_Maxi     = -4137; # xlMaximized
my $CXL_Mini     = -4140; # xlMinimized

my $VAR_False    = Variant(VT_BOOL, 0);
my $VAR_True     = Variant(VT_BOOL, 1);

my @C01_Lang = (
  [ 'EN' => 'SUM(1)',   '1' ],
  [ 'DE' => 'SUMME(1)', '1' ],
  [ 'FR' => 'SOMME(1)', '1' ],
);

my %C02_Func = (
  'SUM'   => { DE => 'SUMME',     FR => 'SOMME'    },
  'SUMIF' => { DE => 'SUMMEWENN', FR => 'SOMME.SI' },
);

my $glb_handle;
my $glb_lang;
my $glb_ver;
my $glb_refst;

my @glb_sno;

sub get_sno {
    \@glb_sno;
}

sub set_handle_obj {
    if ($glb_handle) {
        croak "MSG-0010: Excel handle already active";
    }

    $glb_handle = _fetch_excel_obj();
    _fetch_handle();
}

sub set_handle_ole {
    if ($glb_handle) {
        croak "MSG-0020: Excel handle already active";
    }

    $glb_handle = _fetch_excel_ole();
    _fetch_handle();
}

sub set_handle_quit {
    unless ($glb_handle) {
        croak "MSG-0030: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->Quit;
}

END {
    if ($glb_handle) {
        $glb_handle->Quit;
    }
}

sub _fetch_handle {
    $glb_lang   = _fetch_lang();
    $glb_ver    = _fetch_ver();
    $glb_refst  = $glb_handle->{ReferenceStyle};
}

sub get_hwnd {
    unless ($glb_handle) {
        croak "MSG-0040: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{hwnd};
}

sub set_size_min {
    unless ($glb_handle) {
        croak "MSG-0050: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{WindowState} = $CXL_Mini;
}

sub set_size_max {
    unless ($glb_handle) {
        croak "MSG-0060: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{WindowState} = $CXL_Maxi;
}

sub set_size_pos {
    my ($param) = @_;
    $param //= {};

    my $lx = $param->{'lx'};
    my $ly = $param->{'ly'};

    my $px = $param->{'px'};
    my $py = $param->{'py'};

    unless ($glb_handle) {
        croak "MSG-0070: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{WindowState} = $CXL_Normal;

    $glb_handle->{Width}  = $lx if defined $lx;
    $glb_handle->{Height} = $ly if defined $ly;

    $glb_handle->{Left}   = $px if defined $px;
    $glb_handle->{Top}    = $py if defined $py;
}

sub get_handle { $glb_handle }
sub get_lang   { $glb_lang   }
sub get_ver    { $glb_ver    }

sub _fetch_excel_obj {
    # use existing instance if Excel is already running
    eval { Win32::OLE->GetActiveObject('Excel.Application') };
}

sub _fetch_excel_ole {
    # create a new OLE instance
    Win32::OLE->new('Excel.Application', sub { $_[0]->Quit });
}

sub _fetch_ver {
    unless ($glb_handle) {
        croak "MSG-0080: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    my $num = $glb_handle->Version;

    my $ver =
      $num eq '16.0' ? '2016' :
      $num eq '15.0' ? '2013' :
      $num eq '14.0' ? '2010' :
      $num eq '12.0' ? '2007' :
      $num eq '11.0' ? '2003' :
      $num eq '10.0' ? '2002' :
      $num eq  '9.0' ? '2000' :
      $num eq  '8.0' ? '1997' :
      $num eq  '7.0' ? '1995' : '?'.$num;

    return $ver;
}

sub _fetch_lang {
    unless ($glb_handle) {
        croak "MSG-0090: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{DisplayAlerts}       = 0;
    $glb_handle->{AskToUpdateLinks}    = 0;
    $glb_handle->{Calculation}         = $CXL_CalcMan;
    $glb_handle->{CalculateBeforeSave} = $VAR_False;

    my %L1;

    my $tmp_xls_book = $glb_handle->Workbooks->Add
      or croak "MSG-0100: Can't Workbooks->Add";

    my $tmp_xls_sheet = $tmp_xls_book->Worksheets(1)
      or croak "MSG-0110: Can't find Sheet '1' in new Workbook";

    my $line;

    $line = 0;

    for (@C01_Lang) { $line++;
        $tmp_xls_sheet->Cells(1, $line)->{'Formula'} = '='.$_->[1];
    }

    $tmp_xls_sheet->Calculate;

    $line = 0;

    for (@C01_Lang) { $line++;
        if ($tmp_xls_sheet->Cells(1, $line)->{'Value'} eq $_->[2]) {
            $L1{$_->[0]}++;
        }
    }

    $tmp_xls_book->Close;

    my @L2 = sort keys %L1;

    if (@L2 == 0) {
        croak "MSG-0120: Can't find any language in (".join(', ', map { "'$_->[0]'" } @C01_Lang).")";
    }

    unless (@L2 == 1) {
        croak "MSG-0130: Found more than one language (".join(', ', map { "'$_'" } @L2).")";
    }

    return $L2[0];
}

# Comment by Klaus Eichner, 02-Oct-2016:
# **************************************
#
# I have added 3 new functions set_style_R1C1(), set_style_default() and trf_style_R1C1().
#
# Why, you might ask...
#
# ...because I had big problems with my German version of Excel crashing when using
# a non-trivial formula with Perl / Win32::OLE...
#
# ...it turned out that the default references (Style "A1")
# was too much to handle for my German Excel. In order for Excel not to crash,
# one better switches to the relative style ("R[-1]C[2]")
#
# Here is the StackOverflow article that got me on the right track:
#
# http://stackoverflow.com/questions/1674987/how-do-i-set-excel-formulas-with-win32ole#1675036
#
# >> Without the quotes I get an errormessage: Win32::OLE(0.1709) error 0x80020009:
# >> "Ausnahmefehler aufgetreten" in PROPERTYPUT "FormulaR1C1" at
# >> C:\Dokumente und Einstellungen\pp\Eigene Dateien\excel.pl line 113
# >> Just to check, you now have... $sheet->Range( 'G4' )->{FormulaR1C1} = '=SUMME(R[-3]C:R[-1]C)';
# >> @ Joel : Yes. Update: considering Joel's commend, neither of the two formula works.
# >> With the help of the perl-community.de I have now a solution: I have to set
# >> $excel->{ReferenceStyle} = $xl->{xlR1C1};
# >> and use Z1S1 instead of R1C1
# >> =SUMME(Z(-2)S:Z(-1)S)
# >> But it looks like that in the German version I have to choose between the A1 and the Z1S1 (R1C1) notation.
# >> Sounds like this was your problem all along - strange.
#
# ...as for the French version of Excel, the following sums it up quite nicely:
#
# http://www.office-archive.com/4-excel/0262612dc88a206e.htm
#
# >> all our french-VBA code was translated to english-VBA.
# >> If you really want to stick to L1C1 references, beware of:
# >> "[" and "]" => "(" and ")"
# >> ";" => ","
# >> and of course "L" => "R"

sub set_style_R1C1 {
    unless ($glb_handle) {
        croak "MSG-0140: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{ReferenceStyle} = $CXL_R1C1;
}

sub set_style_default {
    unless ($glb_handle) {
        croak "MSG-0150: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{ReferenceStyle} = $glb_refst;
}

sub trf_style_R1C1 {
    unless ($glb_handle) {
        croak "MSG-0160: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    my @result;

    for (@_) {
        my $t2;

        if (m{\A = (.*) \z}xms) {
            my $func_gen = uc($1);

            if ($glb_lang eq 'EN') {
                $t2 = $func_gen;
            }
            else {
                my $item = $C02_Func{$func_gen} // croak "MSG-0170: Can't find function '$func_gen'";
                $t2 = $item->{$glb_lang}        // croak "MSG-0180: Can't find function '$func_gen', language '$glb_lang'";
            }
        }
        elsif (m{\A < ([^>]*) > \z}xms) {
            my $adr_gen = uc($1);

            if ($glb_lang eq 'EN') {
                $t2 = $adr_gen;
            }
            elsif ($glb_lang eq 'DE') {
                $t2 = $adr_gen =~ s{R}'Z'xmsgr =~ s{C}'S'xmsgr =~ s{\[}'('xmsgr =~ s{\]}')'xmsgr;
            }
            elsif ($glb_lang eq 'FR') {
                $t2 = $adr_gen =~ s{R}'L'xmsgr                 =~ s{\[}'('xmsgr =~ s{\]}')'xmsgr;
            }
            else {
                croak "MSG-0190: Invalid language '$glb_lang'";
            }
        }
        elsif ($_ eq ',') {
            if ($glb_lang eq 'EN') {
                $t2 = ',';
            }
            elsif ($glb_lang eq 'DE') {
                $t2 = ';';
            }
            elsif ($glb_lang eq 'FR') {
                $t2 = ';';
            }
            else {
                croak "MSG-0200: Invalid language '$glb_lang'";
            }
        }
        else {
            croak "MSG-0210: Can't parse parameter '$_'";
        }

        push @result, $t2;
    }

    return @result;
}

sub get_last_row {
   my $proxy = $_[0]->UsedRange->Find({
     What            => '*',
     SearchDirection => $CXL_Previous,
     SearchOrder     => $CXL_ByRows,
   });

   $proxy ? $proxy->{'Row'} : 0;
}

sub get_last_col {
   my $proxy = $_[0]->UsedRange->Find({
     What            => '*',
     SearchDirection => $CXL_Previous,
     SearchOrder     => $CXL_ByCols,
   });

   $proxy ? $proxy->{'Column'} : 0;
}

sub get_book {
    my $prm_xls_name = $_[0];

    unless (-f $prm_xls_name) {
        croak "MSG-0220: Input name '$prm_xls_name' not found";
    }

    unless ($glb_handle) {
        croak "MSG-0230: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{DisplayAlerts}       = 0;
    $glb_handle->{AskToUpdateLinks}    = 0;
    $glb_handle->{Calculation}         = $CXL_CalcMan;
    $glb_handle->{CalculateBeforeSave} = $VAR_False;

    my $prm_xls_abs = $prm_xls_name eq '' ? '' : File::Spec->rel2abs($prm_xls_name) =~ s{/}'\\'xmsgr;

    my $wrk_xls_book = $glb_handle->Workbooks->Open($prm_xls_abs)
       or croak "MSG-0240: Can't Workbooks->Open '$prm_xls_abs'";

    return $wrk_xls_book;
}

sub xls_2_csv   { _x2c('S', @_) }
sub xls_all_csv { _x2c('A', @_) }
sub xls_lst_csv { _x2c('L', @_) }

sub _x2c {
    my $prm_mode = $_[0]; # can be 'S' (= Single), 'L' (= List) or 'A' (= All)
    my ($prm_xls_name, $prm_xls_sheet) = $_[1] =~ m{\A ([^%]*) % ([^%]*) \z}xms ? ($1, $2) : ($_[1], undef);

    unless (-f $prm_xls_name) {
        croak "MSG-0250: Input name '$prm_xls_name' not found";
    }

    my ($prm_xls_stem, $prm_xls_ext) =
      $prm_xls_name eq ''                            ? ('', '')     :
      $prm_xls_name =~ m{\A (.*) \. (xls x?) \z}xmsi ? ($1, lc($2)) :
      croak "MSG-0260: xls_name '$prm_xls_name' does not have an Excel extension of the right type (*.xls, *.xlsx)";

    my $prm_xls_abs = $prm_xls_name eq '' ? '' : File::Spec->rel2abs($prm_xls_name) =~ s{/}'\\'xmsgr;

    unless ($glb_handle) {
        croak "MSG-0270: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{DisplayAlerts}       = 0;
    $glb_handle->{AskToUpdateLinks}    = 0;
    $glb_handle->{Calculation}         = $CXL_CalcMan;
    $glb_handle->{CalculateBeforeSave} = $VAR_False;

    # ************************************************
    # ** Here we load the Excel file into Memory... **
    # ************************************************

    my $wrk_xls_book = $glb_handle->Workbooks->Open($prm_xls_abs)
       or croak "MSG-0280: Can't Workbooks->Open '$prm_xls_abs'";

    my @PList;
    my $ta_dir;
    my $ta_leaf;

    if ($prm_mode eq 'A') {
        my $def_csv_name = $_[2];
        my $def_csv_abs  = $def_csv_name eq '' ? '' : File::Spec->rel2abs($def_csv_name) =~ s{/}'\\'xmsgr;

        my ($def_dir, $def_leaf) = $def_csv_abs =~ m{\A (.+) [\\/] ([^\\/]+) _ \* \. csv \z}xmsi ? ($1, $2) :
          croak "MSG-0290: Can't parse (dir/_*.csv) from csv_abs = '$def_csv_abs'";

        $ta_dir  = $def_dir;
        $ta_leaf = $def_leaf;

        unless (-d $def_dir) {
            croak "MSG-0300: Output directory '$def_dir' not found";
        }

        my $def_p_fmt = [];
        my $def_p_cpy = 'val';
        my $def_p_rmc = [];
        my $def_p_clc = 0;

        if ($_[3]) {
            for (sort keys $_[3]->%* ) {
                my $v = $_[3]->{$_};

                if    ($_ eq 'fmt') { $def_p_fmt = $v }
                elsif ($_ eq 'cpy') { $def_p_cpy = $v }
                elsif ($_ eq 'rmc') { $def_p_rmc = $v }
                elsif ($_ eq 'clc') { $def_p_clc = $v }
                else {
                    croak "MSG-0310: Invalid option ('$_')";
                }
            }
        }

        if (defined $prm_xls_sheet) {
            croak "MSG-0320: Can't have a sheet name ('...%$prm_xls_sheet') when requesting all sheets";
        }

        for (1..$wrk_xls_book->Sheets->Count) {
            my $def_csv_sht = $def_leaf.'_'.sprintf('%03d', $_).'.csv';

            push @PList, {
              'sht' => $_,
              'nam' => $def_csv_sht,
              'csv' => $def_dir.'\\'.$def_csv_sht,
              'fmt' => $def_p_fmt,
              'cpy' => $def_p_cpy,
              'rmc' => $def_p_rmc,
              'clc' => $def_p_clc,
            };
        }

        # remove all existing *.CSV files
        for (sort(read_dir($def_dir))) {
            my $def_full = $def_dir.'\\'.$_;

            next unless -f $def_full;
            next unless m{\A \Q$def_leaf\E _ \d+ \. csv \z}xmsi;

            unlink $def_full or croak "MSG-0330: Can't unlink csv_leaf '$def_full' because $!";
        }
    }
    elsif ($prm_mode eq 'L') {
        if (defined $prm_xls_sheet) {
            croak "MSG-0340: Can't have a sheet name ('...%$prm_xls_sheet') when requesting list sheets";
        }

        for ($_[2]->@*) {
            my $def_sheet    = $_->[0];
            my $def_csv_name = $_->[1];
            my $def_csv_abs  = $def_csv_name eq '' ? '' : File::Spec->rel2abs($def_csv_name) =~ s{/}'\\'xmsgr;

            my $def_p_fmt = [];
            my $def_p_cpy = 'val';
            my $def_p_rmc = [];
            my $def_p_clc = 0;

            if ($_->[2]) {
                for my $key (sort keys $_->[2]->%* ) {
                    my $v = $_->[2]{$key};

                    if    ($key eq 'fmt') { $def_p_fmt = $v }
                    elsif ($key eq 'cpy') { $def_p_cpy = $v }
                    elsif ($key eq 'rmc') { $def_p_rmc = $v }
                    elsif ($key eq 'clc') { $def_p_clc = $v }
                    else {
                        croak "MSG-0350: Invalid option ('$key') for csv = '$def_csv_name'";
                    }
                }
            }

            my $def_csv_sht = $def_csv_abs =~ m{\A (.+) [\\/] ([^\\/]+) \z}xms ? $1 : '';

            push @PList, {
              'sht' => $def_sheet,
              'nam' => $def_csv_sht,
              'csv' => $def_csv_abs,
              'fmt' => $def_p_fmt,
              'cpy' => $def_p_cpy,
              'rmc' => $def_p_rmc,
              'clc' => $def_p_clc,
            };

            # remove the CSV file (if it exists)
            if (-e $def_csv_abs) {
                unlink $def_csv_abs or croak "MSG-0360: Can't unlink csv_abs '$def_csv_abs' because $!";
            }
        }
    }
    elsif ($prm_mode eq 'S') {
        my $def_csv_name = $_[2];
        my $def_csv_abs  = $def_csv_name eq '' ? '' : File::Spec->rel2abs($def_csv_name) =~ s{/}'\\'xmsgr;

        my $def_p_fmt = [];
        my $def_p_cpy = 'val';
        my $def_p_rmc = [];
        my $def_p_clc = 0;

        if ($_[3]) {
            for (sort keys $_[3]->%* ) {
                my $v = $_[3]->{$_};

                if    ($_ eq 'fmt') { $def_p_fmt = $v }
                elsif ($_ eq 'cpy') { $def_p_cpy = $v }
                elsif ($_ eq 'rmc') { $def_p_rmc = $v }
                elsif ($_ eq 'clc') { $def_p_clc = $v }
                else {
                    croak "MSG-0370: Invalid option ('$_')";
                }
            }
        }

        $prm_xls_sheet //= 1;

        my $def_csv_sht = $def_csv_abs =~ m{\A (.+) [\\/] ([^\\/]+) \z}xms ? $1 : '';

        push @PList, {
          'sht' => $prm_xls_sheet,
          'nam' => $def_csv_sht,
          'csv' => $def_csv_abs,
          'fmt' => $def_p_fmt,
          'cpy' => $def_p_cpy,
          'rmc' => $def_p_rmc,
          'clc' => $def_p_clc,
        };

        # remove the CSV file (if it exists)
        if (-e $def_csv_abs) {
            unlink $def_csv_abs or croak "MSG-0390: Can't unlink csv_abs '$def_csv_abs' because $!";
        }
    }
    else {
        croak "MSG-0400: Assertion failure -- prm_mode = '$prm_mode', but extected ('A', 'L' or 'S')";
    }

    @glb_sno = ();

    for (@PList) {
        my $wrk_xls_snum = $_->{'sht'};
        my $wrk_csv_nam  = $_->{'nam'};
        my $wrk_csv_abs  = $_->{'csv'};
        my $def_p_fmt    = $_->{'fmt'};
        my $def_p_cpy    = $_->{'cpy'};
        my $def_p_rmc    = $_->{'rmc'};
        my $def_p_clc    = $_->{'clc'};

        my $wrk_xls_sheet = $wrk_xls_book->Worksheets($wrk_xls_snum)
           or croak "MSG-0410: Can't find Sheet '$wrk_xls_snum' in Workbook '$prm_xls_abs'";

        if ($prm_mode eq 'A') {
            push @glb_sno, [ $wrk_xls_snum, $wrk_xls_sheet->Name, $wrk_csv_nam ];
        }

        my $dat_special =
          $def_p_cpy eq 'val' ? $CXL_PasteVal :
          $def_p_cpy eq 'all' ? $CXL_PasteAll :
          croak "MSG-0420: Invalid parameter cpy => ('$def_p_cpy'), expected ('val' or 'all') in Sheet ($wrk_xls_snum)";

        my @dat_list_rmc;

        for (@$def_p_rmc) {
            if    (lc($_) eq 'tab') {
                push @dat_list_rmc, [ "\x{09}" => '~!' ];
            }
            elsif (lc($_) eq 'cr') {
                push @dat_list_rmc, [ "\x{0a}" => '~*' ];
            }
            elsif (lc($_) eq 'lf') {
                push @dat_list_rmc, [ "\x{0d}" => '~+' ];
            }
            else {
                croak "MSG-0430: Invalid option rmc ('$_') in Sheet ($wrk_xls_snum)";
            }
        }

        my $wrk_csv_book  = $glb_handle->Workbooks->Add  or croak "MSG-0440: Can't Workbooks->Add";
        my $wrk_csv_sheet = $wrk_csv_book->Worksheets(1) or croak "MSG-0450: Can't find Sheet '1' in new Workbook";

        $wrk_xls_sheet->Activate;
        $wrk_xls_sheet->{'Visible'} = $VAR_True;

        if ($def_p_clc) {
            $wrk_xls_sheet->Calculate;
        }

        $wrk_xls_sheet->Cells->AutoFilter; # This should, I hope, get rid of any AutoFilter...
        $wrk_xls_sheet->Cells->Copy;

        $wrk_csv_sheet->Activate;
        $wrk_csv_sheet->{'Visible'} = $VAR_True;
        $wrk_csv_sheet->Range('A1')->PasteSpecial($dat_special); # $CXL_PasteVal or $CXL_PasteAll

        for (@dat_list_rmc) {
            $wrk_csv_sheet->Cells->Replace({
              What        => $_->[0],
              Replacement => $_->[1],
              LookAt      => $CXL_Part,
              SearchOrder => $CXL_ByRows,
              MatchCase   => $VAR_False,
            });
        }

        $wrk_csv_sheet->Columns($_->[0])->{NumberFormat} = $_->[1] for @$def_p_fmt;

        $wrk_csv_book->SaveAs($wrk_csv_abs, $CXL_Csv);
        $wrk_csv_book->Close;
    }

    $wrk_xls_book->Close;

    if ($prm_mode eq 'A') {
        my $tmp_csv_abs = $ta_dir.'\\'.$ta_leaf.'_'.sprintf('%03d', 0).'.csv';

        open my $ofh, '>', $tmp_csv_abs or croak "MSG-0460: Can't open > '$tmp_csv_abs' because $!";

        say {$ofh} 'SNo;Sheet;File';

        for (@glb_sno) {
            say {$ofh} '', ($_->[0] =~ m{\A \d+ \z}xms ? sprintf('S%03d', $_->[0]) : 'T'.$_->[0]), ';', $_->[1], ';', $_->[2];
        }

        close $ofh;
    }
}

sub csv_2_xls   { _c2x('S', @_) }
sub csv_lst_xls { _c2x('L', @_) }

sub _c2x {
    my $prm_mode = $_[0]; # can be 'S' (= Single) or 'L' (= List)

    my ($prm_xls_name, $prm_xls_sheet) = $_[2] =~ m{\A ([^%]*) % ([^%]*) \z}xms ? ($1, $2) : ($_[2], undef);

    my ($prm_xls_stem, $prm_xls_ext) =
      $prm_xls_name eq ''                            ? ('', '')     :
      $prm_xls_name =~ m{\A (.*) \. (xls x?) \z}xmsi ? ($1, lc($2)) :
      croak "MSG-0470: xls_name '$prm_xls_name' does not have an Excel extension of the right type (*.xls, *.xlsx)";

    my $prm_def_tpl = '';

    my @PList;

    if ($prm_mode eq 'L') {
        if (defined $prm_xls_sheet) {
            croak "MSG-0480: Can't have a sheet name ('...%$prm_xls_sheet') when requesting list sheets";
        }

        for ($_[1]->@* ) {
            my $def_csv_name = $_->[0];
            my $def_sheet    = $_->[1];
            my $def_csv_abs  = $def_csv_name eq '' ? '' : File::Spec->rel2abs($def_csv_name) =~ s{/}'\\'xmsgr;

            my $def_p_fmt = [];
            my $def_p_csz = [];
            my $def_p_prt = 0;

            for my $key (sort keys $_->[2]->%* ) {
                my $v = $_->[2]->{$key};

                if    ($key eq 'fmt') { $def_p_fmt = $v }
                elsif ($key eq 'csz') { $def_p_csz = $v }
                elsif ($key eq 'prt') { $def_p_prt = $v }
                else {
                    croak "MSG-0490: Invalid option ('$key') for csv = '$def_csv_name'";
                }
            }

            my $def_csv_sht = $def_csv_abs =~ m{\A (.+) [\\/] ([^\\/]+) \z}xms ? $1 : '';

            push @PList, {
              'sht' => $def_sheet,
              'nam' => $def_csv_sht,
              'csv' => $def_csv_abs,
              'fmt' => $def_p_fmt,
              'csz' => $def_p_csz,
              'prt' => $def_p_prt,
            };
        }

        if ($_[3]) {
            for (sort keys $_[3]->%* ) {
                my $v = $_[3]->{$_};

                if    ($_ eq 'tpl') { $prm_def_tpl = $v }
                else {
                    croak "MSG-0500: Invalid option ('$_')";
                }
            }
        }
    }
    elsif ($prm_mode eq 'S') {
        my $def_csv_name = $_[1];
        my $def_csv_abs  = $def_csv_name eq '' ? '' : File::Spec->rel2abs($def_csv_name) =~ s{/}'\\'xmsgr;

        my $def_p_fmt = [];
        my $def_p_csz = [];
        my $def_p_prt = 0;

        if ($_[3]) {
            for my $key (sort keys $_[3]->%* ) {
                my $v = $_[3]{$key};

                if    ($key eq 'fmt') { $def_p_fmt   = $v }
                elsif ($key eq 'csz') { $def_p_csz   = $v }
                elsif ($key eq 'prt') { $def_p_prt   = $v }
                elsif ($key eq 'tpl') { $prm_def_tpl = $v }
                else {
                    croak "MSG-0510: Invalid option ('$key') for csv = '$def_csv_name'";
                }
            }
        }

        $prm_xls_sheet //= 1;

        my $def_csv_sht = $def_csv_abs =~ m{\A (.+) [\\/] ([^\\/]+) \z}xms ? $1 : '';

        push @PList, {
          'sht' => $prm_xls_sheet,
          'nam' => $def_csv_sht,
          'csv' => $def_csv_abs,
          'fmt' => $def_p_fmt,
          'csz' => $def_p_csz,
          'prt' => $def_p_prt,
        };
    }
    else {
        croak "MSG-0530: Assertion failure -- prm_mode = '$prm_mode', but extected ('A', 'L' or 'S')";
    }

    my $dat_format =
      $prm_xls_ext eq 'xls'  ? $CXL_Normal  :
      $prm_xls_ext eq 'xlsx' ? $CXL_OpenXML :
      croak "Msg-0540: Assertion failure ext = ('$prm_xls_ext') not in ('xls', 'xlsx')";

    my $prm_xls_abs = $prm_xls_name eq '' ? '' : File::Spec->rel2abs($prm_xls_name) =~ s{/}'\\'xmsgr;

    unless ($glb_handle) {
        croak "MSG-0550: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    my $prm_tpl_abs = $prm_def_tpl eq '' ? '' : File::Spec->rel2abs($prm_def_tpl) =~ s{/}'\\'xmsgr;

    unless ($glb_handle) {
        croak "MSG-0560: No Excel handle active -- maybe you forgot to call set_handle_obj or set_handle_ole";
    }

    $glb_handle->{DisplayAlerts}       = 0;
    $glb_handle->{AskToUpdateLinks}    = 0;
    $glb_handle->{Calculation}         = $CXL_CalcMan;
    $glb_handle->{CalculateBeforeSave} = $VAR_False;

    if ($prm_def_tpl eq '*') {
        if (-e $prm_xls_abs) {
            unlink $prm_xls_abs or croak "MSG-0570: Can't unlink '$prm_xls_abs' because $!";
        }

        my $tmp_xls_book = $glb_handle->Workbooks->Add
          or croak "MSG-0580: Can't Workbooks->Add";

        $tmp_xls_book->SaveAs($prm_xls_abs, $dat_format);
        $tmp_xls_book->Close;
    }
    elsif ($prm_def_tpl eq '') {
        unless (-f $prm_xls_abs) {
            croak "MSG-0590: xls_name ('$prm_xls_abs') does not exist and template was not specified";
        }
    }
    else {
        if (-e $prm_xls_abs) {
            unlink $prm_xls_abs or croak "MSG-0600: Can't unlink '$prm_xls_abs' because $!";
        }

        unless (-f $prm_tpl_abs) {
            croak "MSG-0610: Can't find template '$prm_tpl_abs'";
        }

        copy $prm_tpl_abs, $prm_xls_abs
          or croak "MSG-0620: Can't copy tpl_name to xls_name ('$prm_tpl_abs', '$prm_xls_abs')";
    }

    # Force "$xls_abs" to be RW -- i.e. remove the RO flag, if any...
    # ***************************************************************

    {
        my $aflag;

        unless (Win32::File::GetAttributes($prm_xls_abs, $aflag)) {
            croak "MSG-0630: Can't get attributes from '$prm_xls_abs'";
        }

        if ($aflag & Win32::File::READONLY()) {
            unless (Win32::File::SetAttributes($prm_xls_abs, ($aflag & ~Win32::File::READONLY()))) {
                croak "MSG-0640: Can't set attribute ('RW') for '$prm_xls_abs'";
            }
        }
    }

    # ************************************************
    # ** Here we load the Excel file into Memory... **
    # ************************************************

    my $wrk_xls_book = $glb_handle->Workbooks->Open($prm_xls_abs)
      or croak "MSG-0650: Can't Workbooks->Open '$prm_xls_abs'";

    for (@PList) {
        my $wrk_xls_snum = $_->{'sht'};
        my $wrk_csv_nam  = $_->{'nam'};
        my $wrk_csv_abs  = $_->{'csv'};
        my $def_p_fmt    = $_->{'fmt'};
        my $def_p_csz    = $_->{'csz'};
        my $def_p_prt    = $_->{'prt'};

        my $wrk_xls_sheet3 = $wrk_xls_book->ActiveSheet
           or croak "MSG-0660: Can't find ActiveSheet in Workbook '$prm_xls_abs'";

        my $wrk_xls_sheet1 = $wrk_xls_book->Worksheets($wrk_xls_snum)
           or croak "MSG-0670: Can't find Sheet '$wrk_xls_snum' in Workbook '$prm_xls_abs'";

        $wrk_xls_sheet1->Unprotect; # unprotect the sheet in any case...
        $wrk_xls_sheet1->Activate; # "...->Activate" is necessary in order to allow "...Range('A1')->Select" later to be effective

        my $wrk_window = $glb_handle->ActiveWindow;

        $wrk_window->{ScrollColumn} = 1;
        $wrk_window->{ScrollRow}    = 1;

        my $pos_row = $wrk_window->{ScrollRow};
        my $pos_col = $wrk_window->{ScrollColumn};

        # Here we copy the contents of the *.csv file into the *.xls file...
        # ******************************************************************

        my $wrk_csv_book = $glb_handle->Workbooks->Open($wrk_csv_abs)
          or croak "MSG-0680: Can't Workbooks->Open csv_abs '$wrk_csv_abs'";

        my $wrk_csv_sheet2 = $wrk_csv_book->Worksheets(1)
          or croak "MSG-0690: Can't find Sheet #1 in csv_abs '$wrk_csv_abs'";

        $wrk_xls_sheet1->Cells->ClearContents;
        $wrk_csv_sheet2->Cells->Copy;
        $wrk_xls_sheet1->Range('A1')->PasteSpecial($CXL_PasteVal);
        $wrk_xls_sheet1->Cells->EntireColumn->AutoFit;

        $wrk_csv_book->Close;

        $wrk_xls_sheet1->Columns($_->[0])->{NumberFormat} = $_->[1] for @$def_p_fmt;
        $wrk_xls_sheet1->Columns($_->[0])->{ColumnWidth}  = $_->[1] for @$def_p_csz;

        $wrk_xls_sheet1->Cells($pos_row, $pos_col)->Select;

        if ($def_p_prt) {
            $wrk_xls_sheet1->Protect({
              DrawingObjects => $VAR_True,
              Contents       => $VAR_True,
              Scenarios      => $VAR_True,
            });
        }

        $wrk_xls_sheet3->Activate;
    }

    $wrk_xls_book->SaveAs($prm_xls_abs, $dat_format); # ...always use SaveAs(), never use Save() here ...
    $wrk_xls_book->Close;
}

sub XLRef {
    my ($col, $row) = @_;
    $row //= '';

    my $c3 = int(($col - 1 - 26) / (26 * 26)); my $rem = $col - $c3 * 26 * 26;
    my $c2 = int(($rem - 1) / 26);
    my $c1 = $rem - $c2 * 26;

    return ($c3 == 0 ? '' : chr($c3 + 64)).($c2 == 0 ? '' : chr($c2 + 64)).chr($c1 + 64).$row;
}

1;
