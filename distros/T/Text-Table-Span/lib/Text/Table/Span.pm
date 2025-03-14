package Text::Table::Span;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-20'; # DATE
our $DIST = 'Text-Table-Span'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::AllUtils qw(first firstidx max);

use Exporter qw(import);
our @EXPORT_OK = qw/ generate_table /;

our $_split_lines_func;
our $_pad_func;
our $_length_height_func;

# consts
sub IDX_EXPTABLE_CELL_ROWSPAN()         {0} # number of rowspan, only defined for the rowspan head
sub IDX_EXPTABLE_CELL_COLSPAN()         {1} # number of colspan, only defined for the colspan head
sub IDX_EXPTABLE_CELL_WIDTH()           {2} # visual width. this does not include the cell padding.
sub IDX_EXPTABLE_CELL_HEIGHT()          {3} # visual height. this does not include row separator.
sub IDX_EXPTABLE_CELL_ORIG()            {4} # str/hash
sub IDX_EXPTABLE_CELL_IS_ROWSPAN_TAIL() {5} # whether this cell is tail of a rowspan
sub IDX_EXPTABLE_CELL_IS_COLSPAN_TAIL() {6} # whether this cell is tail of a colspan

# whether an exptable cell is the head (1st cell) or tail (the rest) of a
# rowspan/colspan. these should be macros if possible, for speed.
sub _exptable_cell_is_rowspan_tail { defined($_[0]) &&  $_[0][IDX_EXPTABLE_CELL_IS_ROWSPAN_TAIL] }
sub _exptable_cell_is_colspan_tail { defined($_[0]) &&  $_[0][IDX_EXPTABLE_CELL_IS_COLSPAN_TAIL] }
sub _exptable_cell_is_tail         { defined($_[0]) && ($_[0][IDX_EXPTABLE_CELL_IS_ROWSPAN_TAIL] || $_[0][IDX_EXPTABLE_CELL_IS_COLSPAN_TAIL]) }
sub _exptable_cell_is_rowspan_head { defined($_[0]) && !$_[0][IDX_EXPTABLE_CELL_IS_ROWSPAN_TAIL] }
sub _exptable_cell_is_colspan_head { defined($_[0]) && !$_[0][IDX_EXPTABLE_CELL_IS_COLSPAN_TAIL] }
sub _exptable_cell_is_head         { defined($_[0]) && defined $_[0][IDX_EXPTABLE_CELL_ORIG] }

sub _divide_int_to_n_ints {
    my ($int, $n) = @_;
    my $subtot = 0;
    my $int_subtot = 0;
    my $prev_int_subtot = 0;
    my @ints;
    for (1..$n) {
        $subtot += $int/$n;
        $int_subtot = sprintf "%.0f", $subtot;
        push @ints, $int_subtot - $prev_int_subtot;
        $prev_int_subtot = $int_subtot;
    }
    @ints;
}

sub _vpad {
    my ($lines, $num_lines, $width, $which) = @_;
    return $lines if @$lines >= $num_lines; # we don't do truncate
    my @vpadded_lines;
    my $pad_line = " " x $width;
    if ($which =~ /^b/) { # bottom padding
        push @vpadded_lines, @$lines;
        push @vpadded_lines, $pad_line for @$lines+1 .. $num_lines;
    } elsif ($which =~ /^t/) { # top padding
        push @vpadded_lines, $pad_line for @$lines+1 .. $num_lines;
        push @vpadded_lines, @$lines;
    } else { # center padding
        my $p  = $num_lines - @$lines;
        my $p1 = int($p/2);
        my $p2 = $p - $p1;
        push @vpadded_lines, $pad_line for 1..$p1;
        push @vpadded_lines, @$lines;
        push @vpadded_lines, $pad_line for 1..$p2;
    }
    \@vpadded_lines;
}

sub _get_attr {
    my ($attr_name, $y, $x, $cell_value, $table_args) = @_;

  CELL_ATTRS_FROM_CELL_VALUE: {
        last unless ref $cell_value eq 'HASH';
        my $attr_val = $cell_value->{$attr_name};
        return $attr_val if defined $attr_val;
    }

  CELL_ATTRS_FROM_CELL_ATTRS_ARG:
    {
        last unless defined $x && defined $y;
        my $cell_attrs = $table_args->{cell_attrs};
        last unless $cell_attrs;
        for my $entry (@$cell_attrs) {
            next unless $entry->[0] == $y && $entry->[1] == $x;
            my $attr_val = $entry->[2]{$attr_name};
            return $attr_val if defined $attr_val;
        }
    }

  COL_ATTRS:
    {
        last unless defined $x;
        my $col_attrs = $table_args->{col_attrs};
        last unless $col_attrs;
        for my $entry (@$col_attrs) {
            next unless $entry->[0] == $x;
            my $attr_val = $entry->[1]{$attr_name};
            return $attr_val if defined $attr_val;
        }
    }

  ROW_ATTRS:
    {
        last unless defined $y;
        my $row_attrs = $table_args->{row_attrs};
        last unless $row_attrs;
        for my $entry (@$row_attrs) {
            next unless $entry->[0] == $y;
            my $attr_val = $entry->[1]{$attr_name};
            return $attr_val if defined $attr_val;
        }
    }

  TABLE_ARGS:
    {
        my $attr_val = $table_args->{$attr_name};
        return $attr_val if defined $attr_val;
    }

    undef;
}

sub _get_exptable_cell_lines {
    my ($table_args, $exptable, $row_heights, $column_widths,
        $bottom_borders, $intercol_width, $y, $x) = @_;

    my $exptable_cell = $exptable->[$y][$x];
    my $cell   = $exptable_cell->[IDX_EXPTABLE_CELL_ORIG];
    my $text   = ref $cell eq 'HASH' ? $cell->{text} : $cell;
    my $align  = _get_attr('align', $y, $x, $cell, $table_args) // 'left';
    my $valign = _get_attr('valign', $y, $x, $cell, $table_args) // 'top';
    my $pad    = $align eq 'left' ? 'r' : $align eq 'right' ? 'l' : 'c';
    my $vpad   = $valign eq 'top' ? 'b' : $valign eq 'bottom' ? 't' : 'c';
    my $height = 0;
    my $width  = 0;
    for my $ic (1..$exptable_cell->[IDX_EXPTABLE_CELL_COLSPAN]) {
        $width += $column_widths->[$x+$ic-1];
        $width += $intercol_width if $ic > 1;
    }
    for my $ir (1..$exptable_cell->[IDX_EXPTABLE_CELL_ROWSPAN]) {
        $height += $row_heights->[$y+$ir-1];
        $height++ if $bottom_borders->[$y+$ir-2] && $ir > 1;
    }

    my @datalines = map { $_pad_func->($_, $width, $pad, ' ', 'truncate') }
        ($_split_lines_func->($text));
    _vpad(\@datalines, $height, $width, $vpad);
}

sub generate_table {
    require Module::Load::Util;
    require Text::NonWideChar::Util;

    my %args = @_;
    my $rows = $args{rows} or die "Please specify rows";
    my $bs_name = $args{border_style} // 'ASCII::SingleLineDoubleAfterHeader';
    my $cell_attrs = $args{cell_attrs} // [];

    my $bs_obj = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>"BorderStyle"}, $bs_name);

  DETERMINE_CODES: {
        my $color = $args{color};
        my $wide_char = $args{wide_char};

        # split_lines
        if ($color) {
            require Text::ANSI::Util;
            $_split_lines_func = sub { Text::ANSI::Util::ta_add_color_resets(split /\R/, $_[0]) };
        } else {
            $_split_lines_func = sub { split /\R/, $_[0] };
        }

        # pad & length_height
        if ($color) {
            if ($wide_char) {
                require Text::ANSI::WideUtil;
                $_pad_func           = \&Text::ANSI::WideUtil::ta_mbpad;
                $_length_height_func = \&Text::ANSI::WideUtil::ta_mbswidth_height;
            } else {
                require Text::ANSI::Util;
                $_pad_func           = \&Text::ANSI::Util::ta_pad;
                $_length_height_func = \&Text::ANSI::Util::ta_length_height;
            }
        } else {
            if ($wide_char) {
                require Text::WideChar::Util;
                $_pad_func           = \&Text::WideChar::Util::mbpad;
                $_length_height_func = \&Text::WideChar::Util::mbswidth_height;
            } else {
                require String::Pad;
                require Text::NonWideChar::Util;
                $_pad_func           = \&String::Pad::pad;
                $_length_height_func = \&Text::NonWideChar::Util::length_height;
            }
        }
    }

    # XXX when we allow cell attrs right_border and left_border, this will
    # become array too like $exptable_bottom_borders.
    my $intercol_width = length(" " . $bs_obj->get_border_char(3, 1) . " ");

    my $exptable = []; # [ [[$orig_rowidx,$orig_colidx,$rowspan,$colspan,...], ...], [[...], ...], ... ]
    my $exptable_bottom_borders = []; # idx=exptable rownum, val=bool
    my $M = 0; # number of rows in the exptable
    my $N = 0; # number of columns in the exptable
  CONSTRUCT_EXPTABLE: {
        # 1. the first step is to construct a 2D array we call "exptable" (short
        # for expanded table), which is like the original table but with all the
        # spanning rows/columns split into the smaller boxes so it's easier to
        # draw later. for example, a table cell with colspan=2 will become 2
        # exptable cells. an m-row x n-column table will become M-row x N-column
        # exptable, where M>=m, N>=n.

        my $rownum;

        # 1a. first substep: construct exptable and calculate everything except
        # each exptable cell's width and height, because this will require
        # information from the previous substeps.

        $rownum = -1;
        for my $row (@$rows) {
            $rownum++;
            my $colnum = -1;
            $exptable->[$rownum] //= [];
            push @{ $exptable->[$rownum] }, undef
                if (@{ $exptable->[$rownum] } == 0 ||
                defined($exptable->[$rownum][-1]));
            #use DDC; say "D:exptable->[$rownum] = ", DDC::dump($exptable->[$rownum]);
            my $exptable_colnum = firstidx {!defined} @{ $exptable->[$rownum] };
            #say "D:rownum=$rownum, exptable_colnum=$exptable_colnum";
            if ($exptable_colnum == -1) { $exptable_colnum = 0 }
            $exptable_bottom_borders->[$rownum] //= $args{separate_rows} ? 1:0;

            for my $cell (@$row) {
                $colnum++;
                my $text;

                my $rowspan = 1;
                my $colspan = 1;
                if (ref $cell eq 'HASH') {
                    $text = $cell->{text};
                    $rowspan = $cell->{rowspan} if $cell->{rowspan};
                    $colspan = $cell->{colspan} if $cell->{colspan};
                } else {
                    $text = $cell;
                    my $el;
                    $el = first {$_->[0] == $rownum && $_->[1] == $colnum && $_->[2]{rowspan}} @$cell_attrs;
                    $rowspan = $el->[2]{rowspan} if $el;
                    $el = first {$_->[0] == $rownum && $_->[1] == $colnum && $_->[2]{colspan}} @$cell_attrs;
                    $colspan = $el->[2]{colspan} if $el;
                }

                my @widths;
                my @heights;
                for my $ir (1..$rowspan) {
                    for my $ic (1..$colspan) {
                        my $exptable_cell;
                        $exptable->[$rownum+$ir-1][$exptable_colnum+$ic-1] = $exptable_cell = [];

                        if ($ir == 1 && $ic == 1) {
                            $exptable_cell->[IDX_EXPTABLE_CELL_ROWSPAN]     = $rowspan;
                            $exptable_cell->[IDX_EXPTABLE_CELL_COLSPAN]     = $colspan;
                            $exptable_cell->[IDX_EXPTABLE_CELL_ORIG]        = $cell;
                        } else {
                            $exptable_cell->[IDX_EXPTABLE_CELL_IS_ROWSPAN_TAIL] = 1 if $ir > 1;
                            $exptable_cell->[IDX_EXPTABLE_CELL_IS_COLSPAN_TAIL] = 1 if $ic > 1;
                        }
                        #use DDC; dd $exptable; say ''; # debug
                    }

                    my $val;
                    $val = _get_attr('bottom_border', $rownum+$ir-1, undef, undef, \%args); $exptable_bottom_borders->[$rownum+$ir-1] = $val if $val;
                    $val = _get_attr('top_border'   , $rownum+$ir-1, undef, undef, \%args); $exptable_bottom_borders->[$rownum+$ir-2] = $val if $val;
                    $exptable_bottom_borders->[0] = 1 if $rownum+$ir-1 == 0 && $args{header_row};

                    $M = $rownum+$ir if $M < $rownum+$ir;
                }

                $exptable_colnum += $colspan;
                $exptable_colnum++ while defined $exptable->[$rownum][$exptable_colnum];

            } # for a row
            $N = $exptable_colnum if $N < $exptable_colnum;
        } # for rows

        # 1b. calculate the heigth and width of each exptable cell (as required
        # by the text, or specified width/height when we allow cell attrs width,
        # height)

        for my $exptable_rownum (0..$M-1) {
            for my $exptable_colnum (0..$N-1) {
                my $exptable_cell = $exptable->[$exptable_rownum][$exptable_colnum];
                next if _exptable_cell_is_tail($exptable_cell);
                my $rowspan = $exptable_cell->[IDX_EXPTABLE_CELL_ROWSPAN];
                my $colspan = $exptable_cell->[IDX_EXPTABLE_CELL_COLSPAN];
                my $cell = $exptable_cell->[IDX_EXPTABLE_CELL_ORIG];
                my $text = ref $cell eq 'HASH' ? $cell->{text} : $cell;
                my $lh = $_length_height_func->($text);
                #use DDC; say "D:length_height[$exptable_rownum,$exptable_colnum] = (".DDC::dump($text)."): ".DDC::dump($lh);
                my $tot_intercol_widths = ($colspan-1) * $intercol_width;
                my $tot_interrow_heights = 0; for (1..$rowspan-1) { $tot_interrow_heights++ if $exptable_bottom_borders->[$exptable_rownum+$_-1] }
                #say "D:interrow_heights=$tot_interrow_heights";
                my @heights = _divide_int_to_n_ints(max(0, $lh->[1] - $tot_interrow_heights), $rowspan);
                my @widths  = _divide_int_to_n_ints(max(0, $lh->[0] - $tot_intercol_widths ), $colspan);
                for my $ir (1..$rowspan) {
                    for my $ic (1..$colspan) {
                        $exptable->[$exptable_rownum+$ir-1][$exptable_colnum+$ic-1][IDX_EXPTABLE_CELL_HEIGHT]  = $heights[$ir-1];
                        $exptable->[$exptable_rownum+$ir-1][$exptable_colnum+$ic-1][IDX_EXPTABLE_CELL_WIDTH]   = $widths [$ic-1];
                    }
                }
            }
        } # for rows

    } # CONSTRUCT_EXPTABLE
    #use DDC; dd $exptable; # debug
    #print "D: exptable size: $M x $N (HxW)\n"; # debug
    #use DDC; print "bottom borders: "; dd $exptable_bottom_borders; # debug

  OPTIMIZE_EXPTABLE: {
        # TODO

        # 2. we reduce extraneous columns and rows if there are colspan that are
        # too many. for example, if all exptable cells in column 1 has colspan=2
        # (or one row has colspan=2 and another row has colspan=3), we might as
        # remove 1 column because the extra column span doesn't have any
        # content. same case for extraneous row spans.

        # 2a. remove extra undefs. skip this. doesn't make a difference.
        #for my $exptable_row (@{ $exptable }) {
        #    splice @$exptable_row, $N if @$exptable_row > $N;
        #}

        1;
    } # OPTIMIZE_EXPTABLE
    #use DDC; dd $exptable; # debug

    my $exptable_column_widths  = []; # idx=exptable colnum
    my $exptable_row_heights    = []; # idx=exptable rownum
  DETERMINE_SIZE_OF_EACH_EXPTABLE_COLUMN_AND_ROW: {
        # 3. before we draw the exptable, we need to determine the width and
        # height of each exptable column and row.
        #use DDC;
        for my $ir (0..$M-1) {
            my $exptable_row = $exptable->[$ir];
            $exptable_row_heights->[$ir] = max(
                1, map {$_->[IDX_EXPTABLE_CELL_HEIGHT] // 0} @$exptable_row);
        }

        for my $ic (0..$N-1) {
            $exptable_column_widths->[$ic] = max(
                1, map {$exptable->[$_][$ic] ? $exptable->[$_][$ic][IDX_EXPTABLE_CELL_WIDTH] : 0} 0..$M-1);
        }
    } # DETERMINE_SIZE_OF_EACH_EXPTABLE_COLUMN_AND_ROW
    #use DDC; print "column widths: "; dd $exptable_column_widths; # debug
    #use DDC; print "row heights: "; dd $exptable_row_heights; # debug

    # each elem is an arrayref containing characters to render a line of the
    # table, e.g. for element [0] the row is all borders. for element [1]:
    # [$left_border_str, $exptable_cell_content1, $border_between_col,
    # $exptable_cell_content2, ...]. all will be joined together with "\n" to
    # form the final rendered table.
    my @buf;

  DRAW_EXPTABLE: {
        # 4. finally we draw the (exp)table.

        my $y = 0;

        for my $ir (0..$M-1) {

          DRAW_TOP_BORDER:
            {
                last unless $ir == 0;
                my $b_y = $args{header_row} ? 0 : 6;
                my $b_topleft    = $bs_obj->get_border_char($b_y, 0);
                my $b_topline    = $bs_obj->get_border_char($b_y, 1);
                my $b_topbetwcol = $bs_obj->get_border_char($b_y, 2);
                my $b_topright   = $bs_obj->get_border_char($b_y, 3);
                last unless length $b_topleft || length $b_topline || length $b_topbetwcol || length $b_topright;
                $buf[$y][0] = $b_topleft;
                for my $ic (0..$N-1) {
                    my $cell_right = $ic < $N-1 ? $exptable->[$ir][$ic+1] : undef;
                    my $cell_right_has_content = defined $cell_right && _exptable_cell_is_head($cell_right);
                    $buf[$y][$ic*4+2] = $bs_obj->get_border_char($b_y, 1, $exptable_column_widths->[$ic]+2); # +1, +2, +3
                    $buf[$y][$ic*4+4] = $ic == $N-1 ? $b_topright : ($cell_right_has_content ? $b_topbetwcol : $b_topline);
                }
                $y++;
            } # DRAW_TOP_BORDER

            # DRAW_DATA_OR_HEADER_ROW
            {
                # draw leftmost border, which we always do.
                my $b_y = $ir == 0 && $args{header_row} ? 1 : 3;
                for my $i (1 .. $exptable_row_heights->[$ir]) {
                    $buf[$y+$i-1][0] = $bs_obj->get_border_char($b_y, 0);
                }

                my $lines;
                for my $ic (0..$N-1) {
                    my $cell = $exptable->[$ir][$ic];

                    # draw cell content. also possibly draw border between
                    # cells. we don't draw border inside a row/colspan.
                    if (_exptable_cell_is_head($cell)) {
                        $lines = _get_exptable_cell_lines(
                            \%args, $exptable, $exptable_row_heights, $exptable_column_widths,
                            $exptable_bottom_borders, $intercol_width, $ir, $ic);
                        for my $i (0..$#{$lines}) {
                            $buf[$y+$i][$ic*4+0] = $bs_obj->get_border_char($b_y, 1);
                            $buf[$y+$i][$ic*4+1] = " ";
                            $buf[$y+$i][$ic*4+2] = $lines->[$i];
                            $buf[$y+$i][$ic*4+3] = " ";
                        }
                        #use DDC; say "D: Drawing exptable_cell($ir,$ic): ", DDC::dump($lines);
                    }

                    # draw rightmost border, which we always do.
                    if ($ic == $N-1) {
                        my $b_y = $ir == 0 && $args{header_row} ? 1 : 3;
                        for my $i (1 .. $exptable_row_heights->[$ir]) {
                            $buf[$y+$i-1][$ic*4+4] = $bs_obj->get_border_char($b_y, 2);
                        }
                    }

                }
            } # DRAW_DATA_OR_HEADER_ROW
            $y += $exptable_row_heights->[$ir];

          DRAW_ROW_SEPARATOR:
            {
                last unless $ir < $M-1;
                last unless $exptable_bottom_borders->[$ir];
                my $b_y = $ir == 0 && $args{header_row} ? 2 : 4;
                my $b_betwrowleft    = $bs_obj->get_border_char($b_y, 0);
                my $b_betwrowline    = $bs_obj->get_border_char($b_y, 1);
                my $b_betwrowbetwcol = $bs_obj->get_border_char($b_y, 2);
                my $b_betwrowright   = $bs_obj->get_border_char($b_y, 3);
                last unless length $b_betwrowleft || length $b_betwrowline || length $b_betwrowbetwcol || length $b_betwrowright;
                my $b_betwrowbetwcol_notop = $bs_obj->get_border_char($b_y, 4);
                my $b_betwrowbetwcol_nobot = $bs_obj->get_border_char($b_y, 5);
                my $b_betwrowbetwcol_noleft  = $bs_obj->get_border_char($b_y, 6);
                my $b_betwrowbetwcol_noright = $bs_obj->get_border_char($b_y, 7);
                my $b_yd = $ir == 0 && $args{header_row} ? 2 : 3;
                my $b_datarowleft    = $bs_obj->get_border_char($b_yd, 0);
                my $b_datarowbetwcol = $bs_obj->get_border_char($b_yd, 1);
                my $b_datarowright   = $bs_obj->get_border_char($b_yd, 2);
                for my $ic (0..$N-1) {
                    my $cell             = $exptable->[$ir][$ic];
                    my $cell_right       = $ic < $N-1 ? $exptable->[$ir][$ic+1] : undef;
                    my $cell_bottom      = $ir < $M-1 ? $exptable->[$ir+1][$ic] : undef;
                    my $cell_rightbottom = $ir < $M-1 && $ic < $N-1 ? $exptable->[$ir+1][$ic+1] : undef;

                    # leftmost border
                    if ($ic == 0) {
                        $buf[$y][0] = _exptable_cell_is_rowspan_tail($cell_bottom) ? $b_datarowleft : $b_betwrowleft;
                    }

                    # along the width of cell content
                    if (_exptable_cell_is_rowspan_head($cell_bottom)) {
                        $buf[$y][$ic*4+2] = $bs_obj->get_border_char($b_y, 1, $exptable_column_widths->[$ic]+2);
                    }

                    my $char;
                    if ($ic == $N-1) {
                        # rightmost
                        if (_exptable_cell_is_rowspan_tail($cell_bottom)) {
                            $char = $b_datarowright;
                        } else {
                            $char = $b_betwrowright;
                        }
                    } else {
                        # between cells
                        if (_exptable_cell_is_colspan_tail($cell_right)) {
                            if (_exptable_cell_is_colspan_tail($cell_rightbottom)) {
                                if (_exptable_cell_is_rowspan_tail($cell_bottom)) {
                                    $char = "";
                                } else {
                                    $char = $b_betwrowline;
                                }
                            } else {
                                $char = $b_betwrowbetwcol_notop;
                            }
                        } else {
                            if (_exptable_cell_is_colspan_tail($cell_rightbottom)) {
                                $char = $b_betwrowbetwcol_nobot;
                            } else {
                                if (_exptable_cell_is_rowspan_tail($cell_bottom)) {
                                    if (_exptable_cell_is_rowspan_tail($cell_rightbottom)) {
                                        $char = $b_datarowbetwcol;
                                    } else {
                                        $char = $b_betwrowbetwcol_noleft;
                                    }
                                } elsif (_exptable_cell_is_rowspan_tail($cell_rightbottom)) {
                                    $char = $b_betwrowbetwcol_noright;
                                } else {
                                    $char = $b_betwrowbetwcol;
                                }
                            }
                        }
                    }
                    $buf[$y][$ic*4+4] = $char;

                }
                $y++;
            } # DRAW_ROW_SEPARATOR

          DRAW_BOTTOM_BORDER:
            {
                last unless $ir == $M-1;
                my $b_y = $ir == 0 && $args{header_row} ? 7 : 5;
                my $b_botleft    = $bs_obj->get_border_char($b_y, 0);
                my $b_botline    = $bs_obj->get_border_char($b_y, 1);
                my $b_botbetwcol = $bs_obj->get_border_char($b_y, 2);
                my $b_botright   = $bs_obj->get_border_char($b_y, 3);
                last unless length $b_botleft || length $b_botline || length $b_botbetwcol || length $b_botright;
                $buf[$y][0] = $b_botleft;
                for my $ic (0..$N-1) {
                    my $cell_right = $ic < $N-1 ? $exptable->[$ir][$ic+1] : undef;
                    $buf[$y][$ic*4+2] = $bs_obj->get_border_char($b_y, 1, $exptable_column_widths->[$ic]+2);
                    $buf[$y][$ic*4+4] = $ic == $N-1 ? $b_botright : (_exptable_cell_is_colspan_tail($cell_right) ? $b_botline : $b_botbetwcol);
                }
                $y++;
            } # DRAW_BOTTOM_BORDER

        }
    } # DRAW_EXPTABLE

    for my $row (@buf) { for (@$row) { $_ = "" if !defined($_) } } # debug. remove undef to "" to save dump width
    #use DDC; dd \@buf;
    join "", (map { my $linebuf = $_; join("", grep {defined} @$linebuf)."\n" } @buf);
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
{
    no warnings 'once';
    *table = \&generate_table;
}

1;
# ABSTRACT: (DEPRECATED) Text::Table::Tiny + support for column/row spans

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Span - (DEPRECATED) Text::Table::Tiny + support for column/row spans

=head1 VERSION

This document describes version 0.009 of Text::Table::Span (from Perl distribution Text-Table-Span), released on 2021-02-20.

=head1 SYNOPSIS

You can either specify column & row spans in the cells themselves, using
hashrefs:

 use Text::Table::Span qw/generate_table/;

 my $rows = [
     # header row
     ["Year",
      "Comedy",
      "Drama",
      "Variety",
      "Lead Comedy Actor",
      "Lead Drama Actor",
      "Lead Comedy Actress",
      "Lead Drama Actress"],

     # first data row
     [1962,
      "The Bob Newhart Show (NBC)",
      {text=>"The Defenders (CBS)", rowspan=>3},
      "The Garry Moore Show (CBS)",
      {text=>"E. G. Marshall, The Defenders (CBS)", rowspan=>2, colspan=>2},
      {text=>"Shirley Booth, Hazel (NBC)", rowspan=>2, colspan=>2}],

     # second data row
     [1963,
      {text=>"The Dick Van Dyke Show (CBS)", rowspan=>2},
      "The Andy Williams Show (NBC)"],

     # third data row
     [1964,
      "The Danny Kaye Show (CBS)",
      {text=>"Dick Van Dyke, The Dick Van Dyke Show (CBS)", colspan=>2},
      {text=>"Mary Tyler Moore, The Dick Van Dyke Show (CBS)", colspan=>2}],

     # fourth data row
     [1965,
      {text=>"four winners (Outstanding Program Achievements in Entertainment)", colspan=>3},
      {text=>"five winners (Outstanding Program Achievements in Entertainment)", colspan=>4}],

     # fifth data row
     [1966,
      "The Dick Van Dyke Show (CBS)",
      "The Fugitive (ABC)",
      "The Andy Williams Show (NBC)",
      "Dick Van Dyke, The Dick Van Dyke Show (CBS)",
      "Bill Cosby, I Spy (CBS)",
      "Mary Tyler Moore, The Dick Van Dyke Show (CBS)",
      "Barbara Stanwyck, The Big Valley (CBS)"],
 ];
 print generate_table(
     rows => $rows,
     header_row => 1,
     separate_rows => 1,
     #border_style => 'ASCII::SingleLineDoubleAfterHeader', # module in BorderStyle::* namespace, without the prefix. default is ASCII::SingleLineDoubleAfterHeader
 );

Or, you can also use the C<cell_attrs> option:

 use Text::Table::Span qw/generate_table/;

 my $rows = [
     # header row
     ["Year",
      "Comedy",
      "Drama",
      "Variety",
      "Lead Comedy Actor",
      "Lead Drama Actor",
      "Lead Comedy Actress",
      "Lead Drama Actress"],

     # first data row
     [1962,
      "The Bob Newhart Show (NBC)",
      "The Defenders (CBS)",,
      "The Garry Moore Show (CBS)",
      "E. G. Marshall, The Defenders (CBS)",
      "Shirley Booth, Hazel (NBC)"],

     # second data row
     [1963,
      "The Dick Van Dyke Show (CBS)",
      "The Andy Williams Show (NBC)"],

     # third data row
     [1964,
      "The Danny Kaye Show (CBS)"],

     # fourth data row
     [1965,
      "four winners (Outstanding Program Achievements in Entertainment)",
      "five winners (Outstanding Program Achievements in Entertainment)"],

     # fifth data row
     [1966,
      "The Dick Van Dyke Show (CBS)",
      "The Fugitive (ABC)",
      "The Andy Williams Show (NBC)",
      "Dick Van Dyke, The Dick Van Dyke Show (CBS)",
      "Bill Cosby, I Spy (CBS)",
      "Mary Tyler Moore, The Dick Van Dyke Show (CBS)",
      "Barbara Stanwyck, The Big Valley (CBS)"],
 ];
 print generate_table(
     rows => $rows,
     header_row => 1,
     separate_rows => 1,
     #border_style => 'ASCII::SingleLineDoubleAfterHeader', # module in BorderStyle::* namespace, without the prefix. default is ASCII::SingleLineDoubleAfterHeader
     cell_attrs => [
         # rownum (0-based int), colnum (0-based int), attributes (hashref)
         [1, 2, {rowspan=>3}],
         [1, 4, {rowspan=>2, colspan=>2}],
         [1, 5, {rowspan=>2, colspan=>2}],
         [2, 1, {rowspan=>2}],
         [3, 2, {colspan=>2}],
         [3, 3, {colspan=>2}],
         [4, 1, {colspan=>3}],
         [4, 2, {colspan=>4}],
     ],
 );

will output something like:

 .------+------------------------------+---------------------+------------------------------+------------------------------+------------------+------------------------------+----------------------.
 | Year | Comedy                       | Drama               | Variety                      | Lead Comedy Actor            | Lead Drama Actor | Lead Comedy Actress          | Lead Drama Actress   |
 +======+==============================+=====================+==============================+==============================+==================+==============================+======================+
 | 1962 | The Bob Newhart Show (NBC)   | The Defenders (CBS) | The Garry Moore Show (CBS)   | E. G. Marshall                                  | Shirley Booth                                       |
 +------+------------------------------+                     +------------------------------+ The Defenders (CBS)                             | Hazel (NBC)                                         |
 | 1963 | The Dick Van Dyke Show (CBS) |                     | The Andy Williams Show (NBC) |                                                 |                                                     |
 +------+                              |                     +------------------------------+-------------------------------------------------+-----------------------------------------------------+
 | 1964 |                              |                     | The Danny Kaye Show (CBS)    | Dick Van Dyke                                   | Mary Tyler Moore                                    |
 |      |                              |                     |                              | The Dick Van Dyke Show (CBS)                    | The Dick Van Dyke Show (CBS)                        |
 +------+------------------------------+---------------------+------------------------------+-------------------------------------------------+-----------------------------------------------------+
 | 1965 | four winners                                                                      | five winners                                                                                          |
 +------+------------------------------+---------------------+------------------------------+------------------------------+------------------+------------------------------+----------------------+
 | 1966 | The Dick Van Dyke Show (CBS) | The Fugitive (ABC)  | The Andy Williams Show (NBC) | Dick Van Dyke                | Bill Cosby       | Mary Tyler Moore             | Barbara Stanwyck     |
 |      |                              |                     |                              | The Dick Van Dyke Show (CBS) | I Spy (CBS)      | The Dick Van Dyke Show (CBS) | The Big Valley (CBS) |
 `------+------------------------------+---------------------+------------------------------+------------------------------+------------------+------------------------------+----------------------'

If you set the C<border_style> argument to C<"UTF8::SingleLineBoldHeader">:

 print generate_table(
     rows => $rows,
     border_style => "UTF8::SingleLineBoldHeader",
     ...
 );

then the output will be something like this:

 ┏━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┓
 ┃ Year ┃ Comedy                       ┃ Drama               ┃ Variety                      ┃ Lead Comedy Actor            ┃ Lead Drama Actor ┃ Lead Comedy Actress          ┃ Lead Drama Actress   ┃
 ┡━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━┩
 │ 1962 │ The Bob Newhart Show (NBC)   │ The Defenders (CBS) │ The Garry Moore Show (CBS)   │ E. G. Marshall                                  │ Shirley Booth                                       │
 ├──────┼──────────────────────────────┤                     ├──────────────────────────────┤ The Defenders (CBS)                             │ Hazel (NBC)                                         │
 │ 1963 │ The Dick Van Dyke Show (CBS) │                     │ The Andy Williams Show (NBC) │                                                 │                                                     │
 ├──────┤                              │                     ├──────────────────────────────┼─────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤
 │ 1964 │                              │                     │ The Danny Kaye Show (CBS)    │ Dick Van Dyke                                   │ Mary Tyler Moore                                    │
 │      │                              │                     │                              │ The Dick Van Dyke Show (CBS)                    │ The Dick Van Dyke Show (CBS)                        │
 ├──────┼──────────────────────────────┴─────────────────────┴──────────────────────────────┼─────────────────────────────────────────────────┴─────────────────────────────────────────────────────┤
 │ 1965 │ four winners                                                                      │ five winners                                                                                          │
 ├──────┼──────────────────────────────┬─────────────────────┬──────────────────────────────┼──────────────────────────────┬──────────────────┬──────────────────────────────┬──────────────────────┤
 │ 1966 │ The Dick Van Dyke Show (CBS) │ The Fugitive (ABC)  │ The Andy Williams Show (NBC) │ Dick Van Dyke                │ Bill Cosby       │ Mary Tyler Moore             │ Barbara Stanwyck     │
 │      │                              │                     │                              │ The Dick Van Dyke Show (CBS) │ I Spy (CBS)      │ The Dick Van Dyke Show (CBS) │ The Big Valley (CBS) │
 └──────┴──────────────────────────────┴─────────────────────┴──────────────────────────────┴──────────────────────────────┴──────────────────┴──────────────────────────────┴──────────────────────┘

=head1 DESCRIPTION

B<DEPRECATION NOTICE:> This module has been renamed to L<Text::Table::More>.
Please use the new name.

This module is like L<Text::Table::Tiny> (0.04) with added support for
column/row spans, and border style.

=for Pod::Coverage ^(.+)$

=head1 PER-ROW ATTRIBUTES

=head2 align

String. Value is either C<"left">, C<"middle">, C<"right">. Specify text
alignment of cells. Override table argument, but is overridden by per-column or
per-cell attribute of the same name.

=head2 valign

String. Value is either C<"top">, C<"middle">, C<"bottom">. Specify vertical
text alignment of cells. Override table argument, but is overridden by
per-column or per-cell attribute of the same name.

=head2 bottom_border

Boolean.

=head2 top_border

Boolean.

=head1 PER-COLUMN ATTRIBUTES

=head2 align

String. Value is either C<"left">, C<"middle">, C<"right">. Specify text
alignment of cells. Override table argument and per-row attribute of the same
name, but is overridden by per-cell attribute of the same name.

=head2 valign

String. Value is either C<"top">, C<"middle">, C<"bottom">. Specify vertical
text alignment of cells. Override table argument and per-row attribute of the
same name, but is overridden by per-cell attribute of the same name.

=head1 PER-CELL ATTRIBUTES

=head2 align

String. Value is either C<"left">, C<"middle">, C<"right">. Override table
argument, per-row attribute, and per-column attribute of the same name.

=head2 valign

String. Value is either C<"top">, C<"middle">, C<"bottom">. Specify vertical
text alignment of cells. Override table argument, per-row attribute, and
per-column attribute of the same name.

=head2 colspan

Positive integer. Default 1.

=head2 rowspan

Positive integer. Default 1.

=head1 FUNCTIONS

=head2 generate_table

Usage:

 my $table_str = generate_table(%args);

Arguments:

=over

=item * rows

Array of arrayrefs (of strings or hashrefs). Required. Each array element is a
row of cells. A cell can be a string like C<"foo"> specifying only the text
(equivalent to C<<{ text=>"foo" >>) or a hashref which allows you to specify a
cell's text (C<text>) as well as attributes like C<rowspan> (int, >= 1),
C<colspan> (int, >= 1), etc. See L</PER-CELL ATTRIBUTES> for the list of known
per-cell attributes.

Currently, C<top_border> and C<bottom_border> needs to be specified for the
first column of a row and will take effect for the whole row.

Alternatively, you can also specify cell attributes using L</cell_attrs>
argument.

=item * header_row

Boolean. Optional. Default 0. Whether to treat the first row as the header row,
which means draw a separator line between it and the rest.

=item * border_style

Str. Optional. Default to C<ASCII::SingleLineDoubleAfterHeader>. This is Perl
module under the L<BorderStyle> namespace, without the namespace prefix. To see
how a border style looks like, you can use the CLI L<show-border-style> from
L<App::BorderStyleUtils>.

=item * align

String. Value is either C<"left">, C<"middle">, C<"right">. Specify horizontal
text alignment of cells. Overriden by overridden by per-row, per-column, or
per-cell attribute of the same name.

=item * valign

String. Value is either C<"top">, C<"middle">, C<"bottom">. Specify vertical
text alignment of cells. Overriden by overridden by per-row, per-column, or
per-cell attribute of the same name.

=item * row_attrs

Array of records. Optional. Specify per-row attributes. Each record is a
2-element arrayref: C<< [$row_idx, \%attrs] >>. C<$row_idx> is zero-based. See
L</PER-ROW ATTRIBUTES> for the list of known attributes.

=item * col_attrs

Array of records. Optional. Specify per-column attributes. Each record is a
2-element arrayref: C<< [$col_idx, \%attrs] >>. C<$col_idx> is zero-based. See
L</PER-COLUMN ATTRIBUTES> for the list of known attributes.

=item * cell_attrs

Array of records. Optional. Specify per-cell attributes. Each record is a
3-element arrayref: C<< [$row_idx, $col_idx, \%attrs] >>. C<$row_idx> and
C<$col_idx> are zero-based. See L</PER-CELL ATTRIBUTES> for the list of known
attributes.

Alternatively, you can specify a cell's attribute in the L</rows> argument
directly, by specifying a cell as hashref.

=item * separate_rows

Boolean. Optional. Default 0. If set to true, will add a separator between data
rows. Equivalent to setting C<bottom_border> or C<top_border> attribute to true
for each row.

=item * wide_char

Boolean. Optional. Default false. Turn on wide character support. Cells that
contain wide Unicode characters will still be properly aligned. Note that this
requires optional prereq L<Text::WideChar::Util> or L<Text::ANSI::WideUtil>.

=item * color

Boolean. Optional. Default false. Turn on color support. Cells that contain ANSI
color codes will still be properly aligned. Note that this requires optional
prereq L<Text::ANSI::Util> or L<Text::ANSI::WideUtil>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Span>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Span>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-Table-Span/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::TextTable> contains a comparison and benchmark for modules
that generate text table.

HTML E<lt>TABLEE<gt> element,
L<https://www.w3.org/TR/2014/REC-html5-20141028/tabular-data.html>,
L<https://www.w3.org/html/wiki/Elements/table>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
