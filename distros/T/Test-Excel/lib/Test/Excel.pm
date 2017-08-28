package Test::Excel;

$Test::Excel::VERSION   = '1.40';
$Test::Excel::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Test::Excel - Interface to test and compare Excel files.

=head1 VERSION

Version 1.40

=cut

use strict; use warnings;

use 5.006;
use IO::File;
use Data::Dumper;
use Test::Builder ();
use Scalar::Util 'blessed';
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility qw(int2col col2int);

use parent 'Exporter';
our @ISA    = qw(Exporter);
our @EXPORT = qw(cmp_excel compare_excel cmp_excel_ok cmp_excel_not_ok);

$|=1;

my $ALMOST_ZERO          = 10**-16;
my $IGNORE               = 1;
my $SPECIAL_CASE         = 2;
my $MAX_ERRORS_PER_SHEET = 0;
my $TESTER               = Test::Builder->new;

=head1 DESCRIPTION

This  module is meant to be used for testing  custom  generated  Excel  files, it
provides interfaces to compare_excel two Excel files if they are I<visually> same.

=head1 SYNOPSIS

Using as unit test as below:

    use strict; use warnings;
    use Test::More tests => 2;
    use Test::Excel;

    cmp_excel_ok("1.xls", "1.xls");

    cmp_excel_not_ok("1.xls", "2.xls");

    done_testing();

Using as standalone as below:

    use strict; use warnings;
    use Test::Excel;

    if (compare_excel("1.xls", "1.xls")) {
        print "Excels are similar.\n";
    }
    else {
        print "Excels aren't similar.\n";
    }

=head1 METHODS

=head2 cmp_excel($got, $exp, \%rule, $message)

This function will tell you whether the two Excel files are "visually" different,
ignoring  differences  in  embedded fonts/images and metadata. Both $got and $exp
can be either instances of Spreadsheet::ParseExcel / file path (which is in  turn
passed to the Spreadsheet::ParseExcel constructor). This one  is for use in  TEST
MODE.

    use strict; use warnings;
    use Test::More tests => 1;
    use Test::Excel;

    cmp_excel('foo.xls', 'bar.xls', {}, 'EXCELs are identical.');

    done_testing();

=head2 cmp_excel_ok($got, $exp, \%rule, $message)

Test OK if excel files are identical. Same as cmp_excel().

=head2 cmp_excel_not_ok($got, $exp, \%rule, $message)

Test OK if excel files are NOT identical.

=cut

sub cmp_excel {
    my ($got, $exp, $rule, $message) = @_;

    my $status = compare_excel($got, $exp, $rule);
    $TESTER->ok($status, $message);
}

sub cmp_excel_ok {
    my ($got, $exp, $rule, $message) = @_;

    my $status = compare_excel($got, $exp, $rule);
    $TESTER->ok($status, $message);
}

sub cmp_excel_not_ok {
    my ($got, $exp, $rule, $message) = @_;

    my $status = compare_excel($got, $exp, $rule);
    if ($status == 0) {
        $TESTER->ok(1, $message);
    }
    else {
        $TESTER->ok(0, $message);
    }
}

=head2 compare_excel($got, $exp, \%rule)

This function will tell you whether the two Excel files are "visually" different,
ignoring  differences  in  embedded fonts/images and  metadata. Both  C<$got> and
C<$exp> can be either instances of Spreadsheet::ParseExcel / file path (which  in
turn passed to the Spreadsheet::ParseExcel constructor).

    use strict; use warnings;
    use Test::Excel;

    print "EXCELs are identical.\n" if compare_excel("foo.xls", "bar.xls");

=cut

sub compare_excel {
    my ($got, $exp, $rule) = @_;

    local $SIG{__WARN__} = sub {
        my ($error) = @_;
        warn $error unless ($error =~ /Use of uninitialized value/);
    };

    die("ERROR: Unable to locate file [$got][$!].\n") unless (-f $got);
    die("ERROR: Unable to locate file [$exp][$!].\n") unless (-f $exp);

    _log_message("INFO: Excel comparison [$got] [$exp]\n");

    unless (blessed($got) && $got->isa('Spreadsheet::ParseExcel::WorkBook')) {
        $got = Spreadsheet::ParseExcel::Workbook->Parse($got)
            || die("ERROR: Couldn't create Spreadsheet::ParseExcel::WorkBook instance with: [$got]\n");
    }

    unless (blessed($exp) && $exp->isa('Spreadsheet::ParseExcel::WorkBook')) {
        $exp = Spreadsheet::ParseExcel::Workbook->Parse($exp)
            || die("ERROR: Couldn't create Spreadsheet::ParseExcel::WorkBook instance with: [$exp]\n");
    }

    _validate_rule($rule);

    my $spec          = _get_hashval($rule, 'spec');
    my $error_limit   = _get_hashval($rule, 'error_limit');
    my $sheet         = _get_hashval($rule, 'sheet');
    my @gotWorkSheets = $got->worksheets();
    my @expWorkSheets = $exp->worksheets();

    $spec        = _parse($spec)         if     defined $spec;
    $error_limit = $MAX_ERRORS_PER_SHEET unless defined $error_limit;

    if (scalar(@gotWorkSheets) != scalar(@expWorkSheets)) {
        my $error = "ERROR: Sheets count mismatch. ";
        $error   .= "Got: [".scalar(@gotWorkSheets)."] exp: [".scalar(@expWorkSheets)."]\n";
        _log_message($error);
        return 0;
    }

    my @sheets;
    my $status = 1;
    @sheets = split(/\|/, $sheet) if defined $sheet;

    for (my $i = 0; $i < scalar(@gotWorkSheets); $i++) {
        my $error_on_sheet = 0;
        my $gotWorkSheet   = $gotWorkSheets[$i];
        my $expWorkSheet   = $expWorkSheets[$i];
        my $gotSheetName   = $gotWorkSheet->get_name();
        my $expSheetName   = $expWorkSheet->get_name();

        if (uc($gotSheetName) ne uc($expSheetName)) {
            my $error = "ERROR: Sheetname mismatch. Got: [$gotSheetName] exp: [$expSheetName].\n";
            _log_message($error);
            return 0;
        }

        my ($gotRowMin, $gotRowMax) = $gotWorkSheet->row_range();
        my ($gotColMin, $gotColMax) = $gotWorkSheet->col_range();
        my ($expRowMin, $expRowMax) = $expWorkSheet->row_range();
        my ($expColMin, $expColMax) = $expWorkSheet->col_range();

        _log_message("INFO: [$gotSheetName]:[$gotRowMin][$gotColMin]:[$gotRowMax][$gotColMax]\n");
        _log_message("INFO: [$expSheetName]:[$expRowMin][$expColMin]:[$expRowMax][$expColMax]\n");

        if (defined($gotRowMax) && defined($expRowMax) && ($gotRowMax != $expRowMax)) {
            my $error = "ERROR: Max row counts mismatch in sheet [$gotSheetName]. ";
            $error   .= "Got[$gotRowMax] Expected: [$expRowMax]\n";
            _log_message($error);
            return 0;
        }

        if (defined($gotColMax) &&  defined($expColMax) && ($gotColMax != $expColMax)) {
            my $error = "ERROR: Max column counts mismatch in sheet [$gotSheetName]. ";
            $error   .= "Got[$gotColMax] Expected: [$expColMax]\n";
            _log_message($error);
            return 0;
        }

        my ($swap);
        for (my $row = $gotRowMin; $row <= $gotRowMax; $row++) {
            for (my $col = $gotColMin; $col <= $gotColMax; $col++) {
                my $gotData = $gotWorkSheet->{Cells}[$row][$col]->{Val};
                my $expData = $expWorkSheet->{Cells}[$row][$col]->{Val};

                next if ( defined($spec)
                          && exists($spec->{uc($gotSheetName)}->{$col+1}->{$row+1})
                          && ($spec->{uc($gotSheetName)}->{$col+1}->{$row+1} == $IGNORE) );

                if (defined($gotData) && defined($expData)) {
                    if (($gotData =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/)
                        && ($expData =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/)) {
                        if (($gotData < $ALMOST_ZERO) && ($expData < $ALMOST_ZERO)) {
                            # Can be treated as the same.
                            next;
                        }
                        else {
                            if (defined $rule && scalar(keys %$rule)) {
                                my $compare_with;
                                my $difference = abs($expData - $gotData) / abs($expData);

                                if ( ( defined($spec)
                                       && exists($spec->{uc($gotSheetName)}->{$col+1}->{$row+1})
                                       && ($spec->{uc($gotSheetName)}->{$col+1}->{$row+1} == $SPECIAL_CASE)
                                     ) || (scalar(@sheets) && grep(/$gotSheetName/,@sheets) )) {

                                    _log_message("INFO: [NUMBER]:[$gotSheetName]:[SPC][".
                                                 ($row+1)."][".($col+1)."]:[$gotData][$expData] ... ");
                                    $compare_with = $rule->{sheet_tolerance};
                                }
                                else {
                                    _log_message("INFO: [NUMBER]:[$gotSheetName]:[STD][".(
                                                     $row+1)."][".($col+1)."]:[$gotData][$expData] ... ");
                                    $compare_with = $rule->{tolerance};
                                }

                                if (defined $compare_with && ($compare_with < $difference)) {
                                    _log_message("[FAIL]\n");
                                    $difference = sprintf("%02f", $difference);
                                    $status = 0;
                                }
                                else {
                                    $status = 1;
                                    _log_message("[PASS]\n");
                                }
                            }
                            else {
                                _log_message("INFO: [NUMBER]:[$gotSheetName]:[N/A][".
                                             ($row+1)."][".($col+1)."]:[$gotData][$expData] ... ");
                                if ($expData != $gotData) {
                                    _log_message("[FAIL]\n");
                                    return 0;
                                }
                                else {
                                    $status = 1;
                                    _log_message("[PASS]\n");
                                }
                            }
                        }
                    }
                    else {
                        if (uc($gotData) ne uc($expData)) {
                            _log_message("INFO: [STRING]:[$gotSheetName]:[$expData][$gotData] ... [FAIL]\n");
                            if (defined $rule) {
                                $error_on_sheet++;
                                $status = 0;
                            }
                            else {
                                return 0;
                            }
                        }
                        else {
                            $status = 1;
                            _log_message("INFO: [STRING]:[$gotSheetName]:[STD][".
                                         ($row+1)."][".($col+1)."]:[$gotData][$expData] ... [PASS]\n");
                        }
                    }

                    if ((exists $rule->{swap_check})
                        && defined($rule->{swap_check}) && ($rule->{swap_check})) {
                        if ($status == 0) {
                            $error_on_sheet++;
                            push @{$swap->{exp}->{_number_to_letter($col-1)}}, $expData;
                            push @{$swap->{got}->{_number_to_letter($col-1)}}, $gotData;

                            if (($error_on_sheet >= $error_limit) && ($error_on_sheet % 2 == 0) && !_is_swapping($swap)) {
                                _log_message("ERROR: Max error per sheet reached.[$error_on_sheet]\n");
                                return $status;
                            }
                        }
                    }
                    else {
                        return $status if ($status == 0);
                    }
                }
            } # col

            if (($error_on_sheet > 0) && ($error_on_sheet >= $error_limit) && ($error_on_sheet % 2 == 0) && !_is_swapping($swap)) {
                return $status if ($status == 0);
            }
        } # row

        if (exists($rule->{swap_check}) && defined($rule->{swap_check}) && ($rule->{swap_check})) {
            if (($error_on_sheet > 0) && _is_swapping($swap)) {
                _log_message("WARN: SWAP OCCURRED.\n");
                $status = 1;
            }
        }

        _log_message("INFO: [$gotSheetName]: ..... [OK].\n");
    } # sheet

    return $status;
}

=head1 RULE

The paramter C<rule> can be used optionally to apply exception when comparing the
contents. This should be passed in as has ref and may contain keys from the table
below.

    +-----------------+---------------------------------------------------------+
    | Key             | Description                                             |
    +-----------------+---------------------------------------------------------+
    | sheet           | "|" seperated sheet names.                              |
    | tolerance       | Number. Apply to all NUMBERS except on 'sheet'/'spec'.  |
    |                 | e.g. 10**-12                                            |
    | sheet_tolerance | Number. Apply to sheets/ranges in the spec. e.g. 0.20   |
    | spec            | Path to the specification file.                         |
    | swap_check      | Number (optional) (1 or 0). Row swapping check.         |
    |                 | Default is 0.                                           |
    | error_limit     | Number (optional). Limit error per sheet. Default is 0. |
    +-----------------+---------------------------------------------------------+

=head1 SPECIFICATION FILE

Spec  file containing rules used should be in the format mentioned below. Key and
values are space seperated.

    sheet       Sheet1
    range       A3:B14
    range       B5:C5
    sheet       Sheet2
    range       A1:B2
    ignorerange B3:B8

=head1 What is "Visually" Similar?

This module uses the L<Spreadsheet::ParseExcel> module to parse Excel files, then
compares the parsed  data structure for differences.We ignore certain  components
of the Excel file, such as embedded fonts,  images,  forms and  annotations,  and
focus  entirely  on  the layout of each Excel page instead.  Future versions will
likely support font and image comparisons.

=head1 How to find out what failed the comparison?

By turning the environment variable DEBUG ON would spit out PASS/FAIL comparison.

e.g. $/> $DEBUG=1 perl your_script.pl

=cut

#
#
# PRIVATE METHODS

sub _column_row {
    my ($cell) = @_;

    return unless defined $cell;

    die("ERROR: Invalid cell address [$cell].\n") unless ($cell =~ /([A-Za-z]+)(\d+)/);

    return ($1, $2);
}

sub _letter_to_number {
    my ($letter) = @_;

    return col2int($letter);
}

sub _number_to_letter {
    my ($number) = @_;

    return int2col($number);
}

sub _cells_within_range {
    my ($range) = @_;

    return unless defined $range;

    die("ERROR: Invalid range [$range].\n") unless ($range =~ /(\w+\d+):(\w+\d+)/);

    my $from = $1;
    my $to   = $2;
    my ($min_col, $min_row) = Test::Excel::_column_row($from);
    my ($max_col, $max_row) = Test::Excel::_column_row($to);

    $min_col = Test::Excel::_letter_to_number($min_col);
    $max_col = Test::Excel::_letter_to_number($max_col);

    my $cells = [];
    for (my $row = $min_row; $row <= $max_row; $row++) {
        for (my $col = $min_col; $col <= $max_col; $col++) {
            push @{$cells}, { col => $col, row => $row };
        }
    }

    return $cells;
}

sub _parse {
    my ($spec) = @_;

    return unless defined $spec;

    die("ERROR: Unable to locate spec file [$spec][$!].\n") unless (-f $spec);

    my $data   = undef;
    my $sheet  = undef;
    my $handle = IO::File->new($spec) || die("ERROR: Couldn't open file [$spec][$!].\n");

    while (my $row = <$handle>) {
        chomp($row);
        next unless ($row =~ /\w/);
        next if     ($row =~ /^#/);

        if ($row =~ /^sheet\s+(.*)/i) {
            $sheet = $1;
        }
        elsif (defined($sheet) && ($row =~ /^range\s+(.*)/i)) {
            my $cells = Test::Excel::_cells_within_range($1);
            foreach (@{$cells}) {
                $data->{uc($sheet)}->{$_->{col}+1}->{$_->{row}} = $SPECIAL_CASE;
            }
        }
        elsif (defined($sheet) && ($row =~ /^ignorerange\s+(.*)/i)) {
            my $cells = Test::Excel::_cells_within_range($1);
            foreach (@{$cells}) {
                $data->{uc($sheet)}->{$_->{col}+1}->{$_->{row}} = $IGNORE;
            }
        }
        else {
            die("ERROR: Invalid format data [$row] found in spec file.\n");
        }
    }

    $handle->close();

    return $data;
}

sub _get_hashval {
    my ($hash, $key) = @_;

    return unless (defined $hash && defined $key);
    die "_get_hashval(): Not a hash." unless (ref($hash) eq 'HASH');

    return unless (exists $hash->{$key});
    return $hash->{$key};
}

sub _is_swapping {
    my ($data) = @_;

    return 0 unless defined $data;

    foreach (keys %{$data->{exp}}) {
        my $exp = $data->{exp}->{$_};
        my $out = $data->{out}->{$_};

        return 0 if grep(/$exp->[0]/,@{$out});
    }

    return 1;
}

sub _log_message {
    my ($message) = @_;

    return unless defined($message);

    print {*STDOUT} $message if ($ENV{DEBUG});
}

sub _validate_rule {
    my ($rule) = @_;

    return unless defined $rule;

    die("ERROR: Invalid RULE definitions. It has to be reference to a HASH.\n")
        unless (ref($rule) eq 'HASH');

    my ($keys, $valid);
    $keys = scalar(keys(%{$rule}));
    return if (($keys == 1) && exists($rule->{message}));

    die("ERROR: Rule has more than 8 keys defined.\n")
        if $keys > 8;

    $valid = {'message'         => 1,
              'sheet'           => 2,
              'spec'            => 3,
              'tolerance'       => 4,
              'sheet_tolerance' => 5,
              'error_limit'     => 6,
              'swap_check'      => 7,
              'test'            => 8,};
    foreach (keys %{$rule}) {
        die("ERROR: Invalid key found in the rule definitions.\n")
            unless exists($valid->{$_});
    }

    if ((exists($rule->{spec}) && defined($rule->{spec}))
        || (exists($rule->{sheet}) && defined($rule->{sheet}))) {
        die("ERROR: Missing key sheet_tolerance in the rule definitions.\n")
            unless (exists($rule->{sheet_tolerance}) && defined($rule->{sheet_tolerance}));
        die("ERROR: Missing key tolerance in the rule definitions.\n")
            unless (exists($rule->{tolerance}) && defined($rule->{tolerance}));
    }
    else {
        if ( (exists($rule->{sheet_tolerance}) && defined($rule->{sheet_tolerance}))
             || (exists($rule->{tolerance}) && defined($rule->{tolerance})) ) {
            die("ERROR: Missing key sheet/spec in the rule definitions.\n")
                unless ((exists($rule->{sheet}) && defined($rule->{sheet}))
                        || (exists($rule->{spec}) && defined($rule->{spec})));
        }
    }
}

=head1 NOTES

It should be clearly noted that this module does not claim to provide  fool-proof
comparison of generated Excels. In fact there are still a number of ways in which
I want to expand the existing comparison functionality. This module  is no longer
 actively being developed as I moved to another company.This work was part of one
of my project. Having said, I would be more than happy to add new features if its
requested. Any suggestions / ideas most welcome.

=head1 CAVEATS

Testing of large Excels can take a long time, this is because, well, we are doing
a lot of computation. In fact, this   module   test  suite includes tests against
several  large  Excels,  however I am not including those in this distibution for
obvious reasons.

=head1 BUGS

None that I am aware of.Of course, if you find a bug, let me know, and I would do
my best  to fix it.  This is still a very early version, so it is always possible
that I have just "gotten it wrong" in some places.

=head1 SEE ALSO

=over 4

=item L<Spreadsheet::ParseExcel>  -  I  could  not have written this without this
module.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item John McNamara (author of Spreadsheet::ParseExcel).

=item Kawai Takanori (author of Spreadsheet::ParseExcel::Utility).

=item Stevan Little (author of Test::PDF).

=back

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Test-Excel>

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-test-excel at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Excel>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Excel

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Excel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Excel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Excel>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Excel/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it  and/or modify it under
the  terms  of the the Artistic License (2.0). You may  obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::Excel
