package Text::ANSITable;

use 5.010001;
use Carp;
use Log::ger;
use Moo;

use ColorThemeUtil::ANSI qw(item_color_to_ansi);
#use List::Util qw(first);
use Scalar::Util 'looks_like_number';
require # hide from cpanspec
    Win32::Console::ANSI if $^O =~ /Win/;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.610'; # VERSION

# see Module::Features for more details on this
our %FEATURES = (
    set_v => {
        TextTable => 1,
    },

    features => {
        PerlTrove => {
            "Development Status" => "5 - Production/Stable",
            "Environment" => "Console",
            # Framework
            "Intended Audience" => ["Developers"],
            "License" => "OSI Approved :: Artistic License",
            # Natural Language
            # Operating System
            "Programming Language" => "Perl",
            "Topic" => ["Software Development :: Libraries :: Perl Modules", "Utilities"],
            # Typing
        },

        TextTable => {
            can_align_cell_containing_wide_character => 1,
            can_align_cell_containing_color_code     => 1,
            can_align_cell_containing_newline        => 1,
            can_use_box_character                    => 1,
            can_customize_border                     => 1,
            can_halign                               => 1,
            can_halign_individual_row                => 1,
            can_halign_individual_column             => 1,
            can_halign_individual_cell               => 1,
            can_valign                               => 1,
            can_valign_individual_row                => 1,
            can_valign_individual_column             => 1,
            can_valign_individual_cell               => 1,
            can_rowspan                              => 0,
            can_colspan                              => 0,
            can_color                                => 1,
            can_color_theme                          => 1,
            can_set_cell_height                      => 1,
            can_set_cell_height_of_individual_row    => 1,
            can_set_cell_width                       => 1,
            can_set_cell_width_of_individual_column  => 1,
            speed                                    => 'slow',
            can_hpad                                 => 1,
            can_hpad_individual_row                  => 1,
            can_hpad_individual_column               => 1,
            can_hpad_individual_cell                 => 1,
            can_vpad                                 => 1,
            can_vpad_individual_row                  => 1,
            can_vpad_individual_column               => 1,
            can_vpad_individual_cell                 => 1,
        },
    },
);

my $ATTRS = [qw(

                  use_color color_depth use_box_chars use_utf8 columns rows
                  column_filter row_filter show_row_separator show_header
                  show_header cell_width cell_height cell_pad cell_lpad
                  cell_rpad cell_vpad cell_tpad cell_bpad cell_fgcolor
                  cell_bgcolor cell_align cell_valign header_align header_valign
                  header_vpad header_tpad header_bpad header_fgcolor
                  header_bgcolor

          )];
my $STYLES = $ATTRS;
my $COLUMN_STYLES = [qw(

                          type width align valign pad lpad rpad formats fgcolor
                          bgcolor wrap

                  )];
my $ROW_STYLES = [qw(

                       height align valign vpad tpad bpad fgcolor bgcolor

               )];
my $CELL_STYLES = [qw(

                        align valign formats fgcolor bgcolor

                )];

has border_style => (
    is => 'rw',
    trigger => sub {
        require Module::Load::Util;
        my ($self, $val) = @_;
        $self->{border_style_obj} =
            Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefixes=>['BorderStyle::Text::ANSITable', 'BorderStyle', 'BorderStyle::Text::ANSITable::OldCompat']}, $val);
    },
);

has color_theme => (
    is => 'rw',
    trigger => sub {
        require Module::Load::Util;
        my ($self, $val) = @_;
        $self->{color_theme_obj} =
            Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefixes=>['ColorTheme::Text::ANSITable', 'ColorTheme', 'ColorTheme::Text::ANSITable::OldCompat']}, $val);
    },
);

has columns => (
    is      => 'rw',
    default => sub { [] },
    trigger => sub {
        my $self = shift;

        # check that column names are unique
        my %seen;
        for (@{$_[0]}) { die "Duplicate column name '$_'" if $seen{$_}++ }

        $self->{_columns_set}++;
    },
);
has rows => (
    is      => 'rw',
    default => sub { [] },
    trigger => sub {
        my ($self, $rows) = @_;
        $self->_set_default_cols($rows->[0]);
    },
);
has column_filter => (
    is => 'rw',
);
has column_wrap => (
    is => 'rw',
);
has row_filter => (
    is => 'rw',
);
has _row_separators => ( # [index after which sep should be drawn, ...] sorted
    is      => 'rw',
    default => sub { [] },
);
has show_row_separator => (
    is      => 'rw',
    default => sub { 2 },
);
has show_header => (
    is      => 'rw',
    default => sub { 1 },
);

has _column_styles => ( # store per-column styles
    is      => 'rw',
    default => sub { [] },
);
has _row_styles => ( # store per-row styles
    is      => 'rw',
    default => sub { [] },
);
has _cell_styles => ( # store per-cell styles
    is      => 'rw',
    default => sub { [] },
);

# each element of _cond_*styles is a two-element [$cond, ], where $cond is code
# (str|coderef) and the second element is a hashref containing styles.

has _cond_column_styles => ( # store conditional column styles
    is      => 'rw',
    default => sub { [] },
);
has _cond_row_styles => ( # store conditional row styles
    is      => 'rw',
    default => sub { [] },
);
has _cond_cell_styles => ( # store conditional cell styles
    is      => 'rw',
    default => sub { [] },
);

has cell_width => (
    is      => 'rw',
);
has cell_height => (
    is      => 'rw',
);
has cell_pad => (
    is      => 'rw',
    default => sub { 1 },
);
has cell_lpad => (
    is      => 'rw',
);
has cell_rpad => (
    is      => 'rw',
);
has cell_vpad => (
    is      => 'rw',
    default => sub { 0 },
);
has cell_tpad => (
    is      => 'rw',
);
has cell_bpad => (
    is      => 'rw',
);
has cell_fgcolor => (
    is => 'rw',
);
has cell_bgcolor => (
    is => 'rw',
);
has cell_align => (
    is => 'rw',
);
has cell_valign => (
    is => 'rw',
);

has header_align => (
    is      => 'rw',
);
has header_valign => (
    is      => 'rw',
);
has header_vpad => (
    is      => 'rw',
);
has header_tpad => (
    is      => 'rw',
);
has header_bpad => (
    is      => 'rw',
);
has header_fgcolor => (
    is      => 'rw',
);
has header_bgcolor => (
    is      => 'rw',
);

with 'Term::App::Role::Attrs';

sub _color_theme_item_color_to_ansi {
    my ($self, $item, $args, $is_bg) = @_;
    item_color_to_ansi(
        ($self->{color_theme_obj}->get_item_color($item, $args) // undef), # because sometimes get_item_color() might return an empty list
        $is_bg)
        // '';
}

sub BUILD {
    my ($self, $args) = @_;

    if ($ENV{ANSITABLE_STYLE_SETS}) {
        require JSON::MaybeXS;
        my $sets = JSON::MaybeXS::decode_json($ENV{ANSITABLE_STYLE_SETS});
        croak "ANSITABLE_STYLE_SETS must be an array"
            unless ref($sets) eq 'ARRAY';
        for my $set (@$sets) {
            if (ref($set) eq 'ARRAY') {
                $self->apply_style_set($set->[0], $set->[1]);
            } else {
                $self->apply_style_set($set);
            }
        }
    }

    if ($ENV{ANSITABLE_STYLE}) {
        require JSON::MaybeXS;
        my $s = JSON::MaybeXS::decode_json($ENV{ANSITABLE_STYLE});
        for my $k (keys %$s) {
            my $v = $s->{$k};
            croak "Unknown table style '$k' in ANSITABLE_STYLE environment, ".
                "please use one of [".join(", ", @$STYLES)."]"
                    unless grep { $_ eq $k } @$STYLES;
            $self->{$k} = $v;
        }
    }

    # pick a default border style
    unless ($self->{border_style}) {
        my $bs;

        my $use_utf8 = $self->use_utf8;

        # even though Term::Detect::Software decides that linux virtual console
        # does not support unicode, it actually can display some uni characters
        # like single borders, so we use it as the default here instead of
        # singleo_ascii (linux vc doesn't seem to support box_chars).
        my $emu_eng  = $self->detect_terminal->{emulator_engine} // '';
        my $linux_vc = $emu_eng eq 'linux' && !defined($ENV{UTF8});
        if ($linux_vc) {
            $use_utf8 = 1;
            $bs = 'UTF8::SingleLineOuterOnly';
        }
        # use statement modifier style to avoid block and make local work
        local $self->{use_utf8} = 1 if $linux_vc;

        # we only default to utf8 border if user has set something like
        # binmode(STDOUT, ":utf8") to avoid 'Wide character in print' warning.
        unless (defined $ENV{UTF8}) {
            require PerlIO;
            my @layers = PerlIO::get_layers(STDOUT);
            $use_utf8 = 0 unless grep { $_ eq 'utf8' } @layers;
        }

        if (defined $ENV{ANSITABLE_BORDER_STYLE}) {
            $bs = $ENV{ANSITABLE_BORDER_STYLE};
        } elsif (defined $ENV{BORDER_STYLE}) {
            $bs = $ENV{BORDER_STYLE};
        } elsif ($use_utf8) {
            $bs //= 'UTF8::BrickOuterOnly';
        } elsif ($self->use_box_chars) {
            $bs = 'BoxChar::SingleLineOuterOnly';
        } else {
            $bs = 'ASCII::SingleLineOuterOnly';
        }

        $self->border_style($bs);
    }

    # pick a default color theme
    unless ($self->{color_theme}) {
        my $ct;
        if (defined $ENV{ANSITABLE_COLOR_THEME}) {
            $ct = $ENV{ANSITABLE_COLOR_THEME};
        } elsif ($self->use_color) {
            my $bg = $self->detect_terminal->{default_bgcolor} // '';
            if ($self->color_depth >= 2**24) {
                $ct = 'Standard::Gradation' .
                    ($bg eq 'ffffff' ? 'WhiteBG' : '');
            } else {
                $ct = 'Standard::NoGradation' .
                    ($bg eq 'ffffff' ? 'WhiteBG' : '');;
            }
        } else {
            $ct = 'NoColor';
        }
        $self->color_theme($ct);
    }

    unless (defined $self->{wide}) {
        $self->{wide} = eval { require Text::ANSI::WideUtil; 1 } ? 1:0;
    }
    require Text::ANSI::Util;
    $self->{_func_add_color_resets} = \&Text::ANSI::Util::ta_add_color_resets;
    if ($self->{wide}) {
        require Text::ANSI::WideUtil;
        $self->{_func_length_height} = \&Text::ANSI::WideUtil::ta_mbswidth_height;
        $self->{_func_pad}           = \&Text::ANSI::WideUtil::ta_mbpad;
        $self->{_func_wrap}          = \&Text::ANSI::WideUtil::ta_mbwrap;
    } else {
        $self->{_func_length_height} = \&Text::ANSI::Util::ta_length_height;
        $self->{_func_pad}           = \&Text::ANSI::Util::ta_pad;
        $self->{_func_wrap}          = \&Text::ANSI::Util::ta_wrap;
    }
}

sub _set_default_cols {
    my ($self, $row) = @_;
    return if $self->{_columns_set}++;
    $self->columns([map {"col$_"} 0..@$row-1]) if $row;
}

sub add_row {
    my ($self, $row, $styles) = @_;
    croak "Row must be arrayref" unless ref($row) eq 'ARRAY';
    push @{ $self->{rows} }, $row;
    $self->_set_default_cols($row) unless $self->{_columns_set}++;
    if ($styles) {
        my $i = @{ $self->{rows} }-1;
        for my $s (keys %$styles) {
            $self->set_row_style($i, $s, $styles->{$s});
        }
    }
    $self;
}

sub add_row_separator {
    my ($self) = @_;
    my $idx = @{$self->{rows}}-1;
    # ignore duplicate separators
    push @{ $self->{_row_separators} }, $idx
        unless @{ $self->{_row_separators} } &&
            $self->{_row_separators}[-1] == $idx;
    $self;
}

sub add_rows {
    my ($self, $rows, $styles) = @_;
    croak "Rows must be arrayref" unless ref($rows) eq 'ARRAY';
    $self->add_row($_, $styles) for @$rows;
    $self;
}

sub _colnum {
    my $self = shift;
    my $colname = shift;

    return $colname if looks_like_number($colname);
    my $cols = $self->{columns};
    for my $i (0..@$cols-1) {
        return $i if $cols->[$i] eq $colname;
    }
    croak "Unknown column name '$colname'";
}

sub get_cell {
    my ($self, $rownum, $col) = @_;

    $col = $self->_colnum($col);

    $self->{rows}[$rownum][$col];
}

sub set_cell {
    my ($self, $rownum, $col, $val) = @_;

    $col = $self->_colnum($col);

    my $oldval = $self->{rows}[$rownum][$col];
    $self->{rows}[$rownum][$col] = $val;
    $oldval;
}

sub get_column_style {
    my ($self, $col, $style) = @_;

    $col = $self->_colnum($col);
    $self->{_column_styles}[$col]{$style};
}

sub set_column_style {
    my $self = shift;
    my $col  = shift;

    $col = $self->_colnum($col);

    my %sets = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

    for my $style (keys %sets) {
        my $val = $sets{$style};
        croak "Unknown per-column style '$style', please use one of [".
            join(", ", @$COLUMN_STYLES) . "]" unless grep { $_ eq $style } @$COLUMN_STYLES;
        $self->{_column_styles}[$col]{$style} = $val;
    }
}

sub get_cond_column_styles {
    my $self = shift;
    $self->{_cond_column_styles};
}

#sub set_cond_column_style {
#    my ($self, $styles) = @_;
#    $self->{_cond_column_styles} = $styles;
#}

sub add_cond_column_style {
    my $self = shift;
    my $cond = shift;
    if (ref($cond) ne 'CODE') {
        croak "cond must be a coderef";
    }

    my $styles;
    if (ref($_[0]) eq 'HASH') {
        $styles = shift;
    } else {
        $styles = { @_ };
    }

    for my $style (keys %$styles) {
        croak "Unknown per-column style '$style', please use one of [".
            join(", ", @$COLUMN_STYLES) . "]" unless grep { $_ eq $style } @$COLUMN_STYLES;
    }

    push @{ $self->{_cond_column_styles} }, [$cond, $styles];
}

#sub clear_cond_column_styles {
#    my $self = shift;
#    $self->{_cond_column_styles} = [];
#}

sub get_eff_column_style {
    my ($self, $col, $style) = @_;

    $col = $self->_colnum($col);

    # the result of calculation is cached here
    if (defined $self->{_draw}{eff_column_styles}[$col]) {
        return $self->{_draw}{eff_column_styles}[$col]{$style};
    }

    my $cols = $self->{columns};
    my %styles;

    # apply conditional styles
  COND:
    for my $ei (0..@{ $self->{_cond_column_styles} }-1) {
        my $e = $self->{_cond_column_styles}[$ei];
        local $_ = $col;
        my $res = $e->[0]->(
            $self,
            col     => $col,
            colname => $cols->[$col],
        );
        next COND unless $res;
        if (ref($res) eq 'HASH') {
            $styles{$_} = $res->{$_} for keys %$res;
        }
        $styles{$_} = $e->[1]{$_} for keys %{ $e->[1] };
    }

    # apply per-column styles
    my $rss = $self->{_column_styles}[$col];
    if ($rss) {
        $styles{$_} = $rss->{$_} for keys %$rss;
    }

    $self->{_draw}{eff_column_styles}[$col] = \%styles;

    $styles{$style};
}

sub get_row_style {
    my ($self, $row, $style) = @_;

    $self->{_row_styles}[$row]{$style};
}

sub set_row_style {
    my $self = shift;
    my $row  = shift;

    my %sets = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

    for my $style (keys %sets) {
        my $val = $sets{$style};
        croak "Unknown per-row style '$style', please use one of [".
            join(", ", @$ROW_STYLES) . "]" unless grep { $_ eq $style } @$ROW_STYLES;
        $self->{_row_styles}[$row]{$style} = $val;
    }
}

sub get_cond_row_styles {
    my $self = shift;
    $self->{_cond_row_styles};
}

#sub set_cond_row_style {
#    my ($self, $styles) = @_;
#    $self->{_cond_row_styles} = $styles;
#}

sub add_cond_row_style {
    my $self = shift;
    my $cond = shift;
    if (ref($cond) ne 'CODE') {
        croak "cond must be a coderef";
    }

    my $styles;
    if (ref($_[0]) eq 'HASH') {
        $styles = shift;
    } else {
        $styles = { @_ };
    }

    for my $style (keys %$styles) {
        croak "Unknown per-row style '$style', please use one of [".
            join(", ", @$ROW_STYLES) . "]" unless grep { $_ eq $style } @$ROW_STYLES;
    }

    push @{ $self->{_cond_row_styles} }, [$cond, $styles];
}

#sub clear_cond_row_styles {
#    my $self = shift;
#    $self->{_cond_row_styles} = [];
#}

sub get_eff_row_style {
    my ($self, $row, $style) = @_;

    # the result of calculation is cached here
    if (defined $self->{_draw}{eff_row_styles}[$row]) {
        return $self->{_draw}{eff_row_styles}[$row]{$style};
    }

    my $rows = $self->{rows};
    my %styles;

    # apply conditional styles
  COND:
    for my $ei (0..@{ $self->{_cond_row_styles} }-1) {
        my $e = $self->{_cond_row_styles}[$ei];
        local $_ = $row;
        my $res = $e->[0]->(
            $self,
            row      => $row,
            row_data => $rows->[$row],
        );
        next COND unless $res;
        if (ref($res) eq 'HASH') {
            $styles{$_} = $res->{$_} for keys %$res;
        }
        $styles{$_} = $e->[1]{$_} for keys %{ $e->[1] };
    }

    # apply per-row styles
    my $rss = $self->{_row_styles}[$row];
    if ($rss) {
        $styles{$_} = $rss->{$_} for keys %$rss;
    }

    $self->{_draw}{eff_row_styles}[$row] = \%styles;

    $styles{$style};
}

sub get_cell_style {
    my ($self, $row, $col, $style) = @_;

    $col = $self->_colnum($col);
    $self->{_cell_styles}[$row][$col]{$style};
}

sub set_cell_style {
    my $self = shift;
    my $row  = shift;
    my $col  = shift;

    $col = $self->_colnum($col);

    my %sets = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

    for my $style (keys %sets) {
        my $val = $sets{$style};
        croak "Unknown per-cell style '$style', please use one of [".
            join(", ", @$CELL_STYLES) . "]" unless grep { $_ eq $style } @$CELL_STYLES;
        $self->{_cell_styles}[$row][$col]{$style} = $val;
    }
}

sub get_cond_cell_styles {
    my $self = shift;
    $self->{_cond_cell_styles};
}

#sub set_cond_cell_style {
#    my ($self, $styles) = @_;
#    $self->{_cond_cell_styles} = $styles;
#}

sub add_cond_cell_style {
    my $self = shift;
    my $cond = shift;
    if (ref($cond) ne 'CODE') {
        croak "cond must be a coderef";
    }

    my $styles;
    if (ref($_[0]) eq 'HASH') {
        $styles = shift;
    } else {
        $styles = { @_ };
    }

    for my $style (keys %$styles) {
        croak "Unknown per-cell style '$style', please use one of [".
            join(", ", @$CELL_STYLES) . "]" unless grep { $_ eq $style } @$CELL_STYLES;
    }

    push @{ $self->{_cond_cell_styles} }, [$cond, $styles];
}

#sub clear_cond_cell_styles {
#    my $self = shift;
#    $self->{_cond_cell_styles} = [];
#}

sub get_eff_cell_style {
    my ($self, $row, $col, $style) = @_;

    # the result of calculation is cached here
    if (defined $self->{_draw}{eff_cell_styles}[$row][$col]) {
        return $self->{_draw}{eff_cell_styles}[$row][$col]{$style};
    }

    my $rows = $self->{rows};
    my %styles;

    # apply conditional styles
  COND:
    for my $ei (0..@{ $self->{_cond_cell_styles} }-1) {
        my $e = $self->{_cond_cell_styles}[$ei];
        local $_ = $rows->[$row][$col];
        my $res = $e->[0]->(
            $self,
            content  => $_,
            col      => $col,
            row      => $row,
            row_data => $rows->[$row],
        );
        next COND unless $res;
        if (ref($res) eq 'HASH') {
            $styles{$_} = $res->{$_} for keys %$res;
        }
        $styles{$_} = $e->[1]{$_} for keys %{ $e->[1] };
    }

    # apply per-cell styles
    my $css = $self->{_cell_styles}[$row][$col];
    if ($css) {
        $styles{$_} = $css->{$_} for keys %$css;
    }

    $self->{_draw}{eff_cell_styles}[$row][$col] = \%styles;

    $styles{$style};
}

sub apply_style_set {
    my $self = shift;
    my $name = shift;
    $name =~ /\A[A-Za-z0-9_]+(?:::[A-Za-z0-9_]+)*\z/
        or croak "Invalid style set name, please use alphanums only";
    {
        my $name = $name;
        $name =~ s!::!/!g;
        require "Text/ANSITable/StyleSet/$name.pm"; ## no critic: Modules::RequireBarewordIncludes
    }
    my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
    my $obj = "Text::ANSITable::StyleSet::$name"->new(%args);
    $obj->apply($self);
}

sub list_border_styles {
    require Module::List;
    my ($self) = @_;

    my $mods = Module::List::list_modules(
        "BorderStyle::", {list_modules=>1, recurse=>1});
    my @res;
    for (sort keys %$mods) {
        s/\ABorderStyle:://;
        push @res, $_;
    }
    @res;
}

sub list_color_themes {
    require Module::List;
    my ($self) = @_;

    my $mods = Module::List::list_modules(
        "ColorTheme::", {list_modules=>1, recurse=>1});
    my @res;
    for (sort keys %$mods) {
        s/\AColorTheme:://;
        push @res, $_;
    }
    @res;
}

sub list_style_sets {
    require Module::List;
    require Module::Load;
    require Package::MoreUtil;

    my ($self, $detail) = @_;

    my $prefix = (ref($self) ? ref($self) : $self ) .
        '::StyleSet'; # XXX allow override
    my $all_sets = $self->{_all_style_sets};

    if (!$all_sets) {
        my $mods = Module::List::list_modules("$prefix\::",
                                              {list_modules=>1, recurse=>1});
        $all_sets = {};
        for my $mod (sort keys %$mods) {
            #$log->tracef("Loading style set module '%s' ...", $mod);
            Module::Load::load($mod);
            my $name = $mod; $name =~ s/\A\Q$prefix\:://;
            my $summary = $mod->summary;
            # we don't have meta, so dig it ourselves
            my %ct = Package::MoreUtil::list_package_contents($mod);
            my $args = [sort grep {!/\W/ && !/\A(new|summary|apply)\z/}
                            keys %ct];
            $all_sets->{$name} = {name=>$name, summary=>$summary, args=>$args};
        }
        $self->{_all_style_sets} = $all_sets;
    }

    if ($detail) {
        return $all_sets;
    } else {
        return (sort keys %$all_sets);
    }
}

# read environment variables for style, this will only be done once per object
sub _read_style_envs {
    my $self = shift;

    return if $self->{_read_style_envs}++;

    if ($ENV{ANSITABLE_COLUMN_STYLES}) {
        require JSON::MaybeXS;
        my $ss = JSON::MaybeXS::decode_json($ENV{ANSITABLE_COLUMN_STYLES});
        croak "ANSITABLE_COLUMN_STYLES must be a hash"
            unless ref($ss) eq 'HASH';
        for my $col (keys %$ss) {
            my $ci = $self->_colnum($col);
            my $s = $ss->{$col};
            for my $k (keys %$s) {
                my $v = $s->{$k};
            croak "Unknown column style '$k' (for column $col) in ".
                "ANSITABLE_COLUMN_STYLES environment, ".
                    "please use one of [".join(", ", @$COLUMN_STYLES)."]"
                        unless grep { $_ eq $k } @$COLUMN_STYLES;
                $self->{_column_styles}[$ci]{$k} //= $v;
            }
        }
    }

    if ($ENV{ANSITABLE_ROW_STYLES}) {
        require JSON::MaybeXS;
        my $ss = JSON::MaybeXS::decode_json($ENV{ANSITABLE_ROW_STYLES});
        croak "ANSITABLE_ROW_STYLES must be a hash"
            unless ref($ss) eq 'HASH';
        for my $row (keys %$ss) {
            my $s = $ss->{$row};
            for my $k (keys %$s) {
                my $v = $s->{$k};
            croak "Unknown row style '$k' (for row $row) in ".
                "ANSITABLE_ROW_STYLES environment, ".
                    "please use one of [".join(", ", @$ROW_STYLES)."]"
                        unless grep { $_ eq $k } @$ROW_STYLES;
                $self->{_row_styles}[$row]{$k} //= $v;
            }
        }
    }

    if ($ENV{ANSITABLE_CELL_STYLES}) {
        require JSON::MaybeXS;
        my $ss = JSON::MaybeXS::decode_json($ENV{ANSITABLE_CELL_STYLES});
        croak "ANSITABLE_CELL_STYLES must be a hash"
            unless ref($ss) eq 'HASH';
        for my $cell (keys %$ss) {
            croak "Invalid cell specification in ANSITABLE_CELL_STYLES: ".
                "$cell, please use 'row,col'"
                    unless $cell =~ /^(.+),(.+)$/;
            my $row = $1;
            my $col = $2;
            my $ci = $self->_colnum($col);
            my $s = $ss->{$cell};
            for my $k (keys %$s) {
                my $v = $s->{$k};
            croak "Unknown cell style '$k' (for cell $row,$col) in ".
                "ANSITABLE_CELL_STYLES environment, ".
                    "please use one of [".join(", ", @$CELL_STYLES)."]"
                        unless grep { $_ eq $k } @$CELL_STYLES;
                $self->{_cell_styles}[$row][$ci]{$k} //= $v;
            }
        }
    }
}

# determine which columns to show (due to column_filter)
sub _calc_fcols {
    my $self = shift;

    my $cols = $self->{columns};
    my $cf   = $self->{column_filter};

    my $fcols;
    if (ref($cf) eq 'CODE') {
        $fcols = [grep {$cf->($_)} @$cols];
    } elsif (ref($cf) eq 'ARRAY') {
        $fcols = [grep {defined} map {looks_like_number($_) ?
                                          $cols->[$_] : $_} @$cf];
    } else {
        $fcols = $cols;
    }
    $self->{_draw}{fcols} = $fcols;
}

# calculate widths/heights of header, store width settings, column [lr]pads
sub _calc_header_height {
    my $self = shift;

    my $cols  = $self->{columns};
    my $fcols = $self->{_draw}{fcols};

    my $fcol_widths = []; # index = [colnum]
    my $header_height = 1;
    my $fcol_lpads  = []; # index = [colnum]
    my $fcol_rpads  = []; # ditto
    my $fcol_setwidths  = []; # index = [colnum], from cell_width/col width
    my $frow_setheights = []; # index = [frownum], from cell_height/row height

    my %seen;
    my $lpad = $self->{cell_lpad} // $self->{cell_pad}; # tbl-lvl leftp
    my $rpad = $self->{cell_rpad} // $self->{cell_pad}; # tbl-lvl rightp
    for my $i (0..@$cols-1) {
        next unless grep { $_ eq $cols->[$i] } @$fcols;
        next if $seen{$cols->[$i]}++;

        $fcol_setwidths->[$i] = $self->get_eff_column_style($i, 'width') //
            $self->{cell_width};
        my $wh = $self->_opt_calc_cell_width_height(undef, $i, $cols->[$i]);
        $fcol_widths->[$i] = $wh->[0];
        $header_height = $wh->[1]
            if !defined($header_height) || $header_height < $wh->[1];
        $fcol_lpads->[$i] = $self->get_eff_column_style($i, 'lpad') //
            $self->get_eff_column_style($i, 'pad') // $lpad;
        $fcol_rpads->[$i] = $self->get_eff_column_style($i, 'rpad') //
            $self->get_eff_column_style($i, 'pad') // $rpad;
    }

    $self->{_draw}{header_height}   = $header_height;
    $self->{_draw}{fcol_lpads}      = $fcol_lpads;
    $self->{_draw}{fcol_rpads}      = $fcol_rpads;
    $self->{_draw}{fcol_setwidths}  = $fcol_setwidths;
    $self->{_draw}{frow_setheights} = $frow_setheights;
    $self->{_draw}{fcol_widths}     = $fcol_widths;
}

# determine which rows to show, calculate vertical paddings of data rows, store
# height settings
sub _calc_frows {
    my $self = shift;

    my $rows = $self->{rows};
    my $rf   = $self->{row_filter};
    my $frow_setheights = $self->{_draw}{frow_setheights};

    my $frow_tpads  = []; # index = [frownum]
    my $frow_bpads  = []; # ditto
    my $frows = [];
    my $frow_separators = [];
    my $frow_orig_indices = []; # needed when accessing original row data

    my $tpad = $self->{cell_tpad} // $self->{cell_vpad}; # tbl-lvl top pad
    my $bpad = $self->{cell_bpad} // $self->{cell_vpad}; # tbl-lvl botom pad
    my $i = -1;
    my $j = -1;
    for my $row (@$rows) {
        $i++;
        if (ref($rf) eq 'CODE') {
            next unless $rf->($row, $i);
        } elsif ($rf) {
            next unless grep { $_ == $i } @$rf;
        }
        $j++;
        push @$frow_setheights, $self->get_eff_row_style($i, 'height') //
            $self->{cell_height};
        push @$frows, [@$row]; # 1-level clone, for storing formatted values
        push @$frow_separators, $j if grep { $_ == $i } @{ $self->{_row_separators} };
        push @$frow_tpads, $self->get_eff_row_style($i, 'tpad') //
            $self->get_eff_row_style($i, 'vpad') // $tpad;
        push @$frow_bpads, $self->get_eff_row_style($i, 'bpad') //
            $self->get_eff_row_style($i, 'vpad') // $bpad;
        push @$frow_orig_indices, $i;
    }

    $self->{_draw}{frows}             = $frows;
    $self->{_draw}{frow_separators}   = $frow_separators;
    $self->{_draw}{frow_tpads}        = $frow_tpads;
    $self->{_draw}{frow_bpads}        = $frow_bpads;
    $self->{_draw}{frow_orig_indices} = $frow_orig_indices;
}

# detect column type from data/header name. assign default column align, valign,
# fgcolor, bgcolor, formats.
sub _detect_column_types {
    my $self = shift;

    my $cols = $self->{columns};
    my $rows = $self->{rows};

    my $fcol_detect = [];
    my %seen;
    for my $i (0..@$cols-1) {
        my $col = $cols->[$i];
        my $res = {};
        $fcol_detect->[$i] = $res;

        # optim: skip detecting columns we're not showing
        next unless grep { $_ eq $col } @{ $self->{_draw}{fcols} };

        # but detect from all rows, not just ones we're showing
        my $type = $self->get_eff_column_style($col, 'type');
        my $subtype;
      DETECT:
        {
            last DETECT if $type;
            if ($col =~ /^(can|is|has|does)_|\?$/) {
                $type = 'bool';
                last DETECT;
            }

            require Parse::VarName;
            my @words = map {lc} @{ Parse::VarName::split_varname_words(
                varname=>$col) };
            for my $w (qw/date time ctime mtime utime atime stime/) {
                if (grep { $_ eq $w } @words) {
                    $type = 'date';
                    last DETECT;
                }
            }

            my $pass = 1;
            for my $j (0..@$rows) {
                my $v = $rows->[$j][$i];
                next unless defined($v);
                do { $pass=0; last } unless looks_like_number($v);
            }
            if ($pass) {
                $type = 'num';
                if ($col =~ /(pct|percent(?:age))\b|\%/) {
                    $subtype = 'pct';
                }
                last DETECT;
            }
            $type = 'str';
        } # DETECT

        $res->{type} = $type;
        if ($type eq 'bool') {
            $res->{align}   = 'center';
            $res->{valign}  = 'center';
            $res->{fgcolor} = $self->{color_theme_obj}->get_item_color('bool_data');
            $res->{formats} = [[bool => {style => $self->{use_utf8} ?
                                             "check_cross" : "Y_N"}]];
        } elsif ($type eq 'date') {
            $res->{align}   = 'middle';
            $res->{fgcolor} = $self->{color_theme_obj}->get_item_color('date_data');
            $res->{formats} = [['date' => {}]];
        } elsif ($type =~ /\A(num|float|int)\z/) {
            $res->{align}   = 'right';
            $res->{fgcolor} = $self->{color_theme_obj}->get_item_color('num_data');
            if (($subtype//"") eq 'pct') {
                $res->{formats} = [[num => {style=>'percent'}]];
            }
        } else {
            $res->{fgcolor} = $self->{color_theme_obj}->get_item_color('str_data');
            $res->{wrap}    = $ENV{WRAP} // 1;
        }
    }

    #use Data::Dump; print "D:fcol_detect: "; dd $fcol_detect;
    $self->{_draw}{fcol_detect} = $fcol_detect;
}

# calculate width and height of a cell, but skip calculating (to save some
# cycles) if width is already set by frow_setheights / fcol_setwidths.
sub _opt_calc_cell_width_height {
    my ($self, $frownum, $col, $text) = @_;

    $col = $self->_colnum($col);
    my $setw  = $self->{_draw}{fcol_setwidths}[$col];
    my $calcw = !defined($setw) || $setw < 0;
    my $seth  = defined($frownum) ?
        $self->{_draw}{frow_setheights}[$frownum] : undef;
    my $calch = !defined($seth) || $seth < 0;

    my $wh;
    if ($calcw) {
        $wh = $self->{_func_length_height}->($text);
        $wh->[0] = -$setw if defined($setw) && $setw<0 && $wh->[0] < -$setw;
        $wh->[1] = $seth if !$calch;
        $wh->[1] = -$seth if defined($seth) && $seth<0 && $wh->[1] < -$seth;
    } elsif ($calch) {
        my $h = 1; $h++ while $text =~ /\n/go;
        $h = -$seth if defined($seth) && $seth<0 && $h < -$seth;
        $wh = [$setw, $h];
    } else {
        $wh = [$setw, $seth];
    }
    #say "D:_opt_calc_cell_width_height(", $frownum//"undef", ", $col) = $wh->[0], $wh->[1]";
    $wh;
}

sub _apply_column_formats {
    my $self = shift;

    my $cols  = $self->{columns};
    my $frows = $self->{_draw}{frows};
    my $fcols = $self->{_draw}{fcols};
    my $fcol_detect = $self->{_draw}{fcol_detect};

    my %seen;
    for my $i (0..@$cols-1) {
        next unless grep { $_ eq $cols->[$i] } @$fcols;
        next if $seen{$cols->[$i]}++;
        my @fmts = @{ $self->get_eff_column_style($i, 'formats') //
                          $fcol_detect->[$i]{formats} // [] };
        if (@fmts) {
            require Data::Unixish::Apply;
            my $res = Data::Unixish::Apply::apply(
                in => [map {$frows->[$_][$i]} 0..@$frows-1],
                functions => \@fmts,
            );
            croak "Can't format column $cols->[$i]: $res->[0] - $res->[1]"
                unless $res->[0] == 200;
            $res = $res->[2];
            for (0..@$frows-1) { $frows->[$_][$i] = $res->[$_] // "" }
        } else {
            # change null to ''
            for (0..@$frows-1) { $frows->[$_][$i] //= "" }
        }
    }
}

sub _apply_cell_formats {
    my $self = shift;

    my $cols  = $self->{columns};
    my $rows  = $self->{rows};
    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};
    my $frow_orig_indices = $self->{_draw}{frow_orig_indices};

    for my $i (0..@$frows-1) {
        my %seen;
        my $origi = $frow_orig_indices->[$i];
        for my $j (0..@$cols-1) {
            next unless grep { $_ eq $cols->[$j] } @$fcols;
            next if $seen{$cols->[$j]}++;

            my $fmts = $self->get_eff_cell_style($origi, $j, 'formats');
            if (defined $fmts) {
                require Data::Unixish::Apply;
                my $res = Data::Unixish::Apply::apply(
                    in => [ $frows->[$i][$j] ],
                    functions => $fmts,
                );
                croak "Can't format cell ($origi, $cols->[$j]): ".
                    "$res->[0] - $res->[1]" unless $res->[0] == 200;
                $frows->[$i][$j] = $res->[2][0] // "";
            }
        } # col
    }
}

sub _calc_row_widths_heights {
    my $self = shift;

    my $cols  = $self->{columns};
    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};

    my $frow_heights = [];
    my $fcol_widths  = $self->{_draw}{fcol_widths};
    my $frow_orig_indices = $self->{_draw}{frow_orig_indices};

    my $height = $self->{cell_height};
    my $tpad = $self->{cell_tpad} // $self->{cell_vpad}; # tbl-lvl tpad
    my $bpad = $self->{cell_bpad} // $self->{cell_vpad}; # tbl-lvl bpad
    my $cswidths = [map {$self->get_eff_column_style($_, 'width')} 0..@$cols-1];
    for my $i (0..@$frows-1) {
        my %seen;
        my $origi = $frow_orig_indices->[$i];
        my $rsheight = $self->get_eff_row_style($origi, 'height');
        for my $j (0..@$cols-1) {
            next unless grep { $_ eq $cols->[$j] } @$fcols;
            next if $seen{$cols->[$j]}++;

            my $wh = $self->_opt_calc_cell_width_height($i,$j,$frows->[$i][$j]);

            $fcol_widths->[$j]  = $wh->[0] if $fcol_widths->[$j] < $wh->[0];
            $frow_heights->[$i] = $wh->[1] if !defined($frow_heights->[$i])
                || $frow_heights->[$i] < $wh->[1];
        } # col
    }
    $self->{_draw}{frow_heights}  = $frow_heights;
}

sub _wrap_wrappable_columns {
    my $self = shift;

    my $cols  = $self->{columns};
    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};
    my $fcol_detect    = $self->{_draw}{fcol_detect};
    my $fcol_setwidths = $self->{_draw}{fcol_setwidths};

    my %seen;
    for my $i (0..@$cols-1) {
        next unless grep { $_ eq $cols->[$i] } @$fcols;
        next if $seen{$cols->[$i]}++;

        if (($self->get_eff_column_style($i, 'wrap') // $self->{column_wrap} //
                 $fcol_detect->[$i]{wrap}) &&
                     defined($fcol_setwidths->[$i]) &&
                         $fcol_setwidths->[$i]>0) {
            for (0..@$frows-1) {
                $frows->[$_][$i] = $self->{_func_wrap}->(
                    $frows->[$_][$i], $fcol_setwidths->[$i]);
            }
        }
    }
}

sub _calc_table_width_height {
    my $self = shift;

    my $cols  = $self->{columns};
    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};
    my $fcol_widths  = $self->{_draw}{fcol_widths};
    my $fcol_lpads   = $self->{_draw}{fcol_lpads};
    my $fcol_rpads   = $self->{_draw}{fcol_rpads};
    my $frow_tpads   = $self->{_draw}{frow_tpads};
    my $frow_bpads   = $self->{_draw}{frow_bpads};
    my $frow_heights = $self->{_draw}{frow_heights};

    my $w = 0;
    $w += 1 if length($self->{border_style_obj}->get_border_char(char=>'v_l'));
    my $has_vsep = length($self->{border_style_obj}->get_border_char(char=>'v_i'));
    for my $i (0..@$cols-1) {
        next unless grep { $_ eq $cols->[$i] } @$fcols;
        $w += $fcol_lpads->[$i] + $fcol_widths->[$i] + $fcol_rpads->[$i];
        if ($i < @$cols-1) {
            $w += 1 if $has_vsep;
        }
    }
    $w += 1 if length($self->{border_style_obj}->get_border_char(char=>'v_r'));
    $self->{_draw}{table_width}  = $w;

    my $h = 0;
    $h += 1 if length($self->{border_style_obj}->get_border_char(char=>'rd_t')); # top border line
    $h += $self->{header_tpad} // $self->{header_vpad} //
        $self->{cell_tpad} // $self->{cell_vpad};
    $h += $self->{_draw}{header_height} // 0;
    $h += $self->{header_bpad} // $self->{header_vpad} //
        $self->{cell_bpad} // $self->{cell_vpad};
    $h += 1 if length($self->{border_style_obj}->get_border_char(char=>'rv_l'));
    for my $i (0..@$frows-1) {
        $h += ($frow_tpads->[$i] // 0) +
            ($frow_heights->[$i] // 0) +
                ($frow_bpads->[$i] // 0);
        $h += 1 if $self->_should_draw_row_separator($i);
    }
    $h += 1 if length($self->{border_style_obj}->get_border_char(char=>'ru_b'));
    $self->{_draw}{table_height}  = $h;
}

# if there are text columns with no width set, and the column width is wider
# than terminal, try to adjust widths so it fit into the terminal, if possible.
# return 1 if widths (fcol_widths) adjusted.
sub _adjust_column_widths {
    my $self = shift;

    # try to find wrappable columns that do not have their widths set. currently
    # the algorithm is not proper, it just targets columns which are wider than
    # a hard-coded value (30). it should take into account the longest word in
    # the content/header, but this will require another pass at the text to
    # analyze it.

    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};
    my $fcol_setwidths = $self->{_draw}{fcol_setwidths};
    my $fcol_detect    = $self->{_draw}{fcol_detect};
    my $fcol_widths    = $self->{_draw}{fcol_widths};
    my %acols;
    my %origw;
    for my $i (0..@$fcols-1) {
        my $ci = $self->_colnum($fcols->[$i]);
        next if defined($fcol_setwidths->[$ci]) && $fcol_setwidths->[$ci]>0;
        next if $fcol_widths->[$ci] < 30;
        next unless $self->get_eff_column_style($ci, 'wrap') //
            $self->{column_wrap} // $fcol_detect->[$ci]{wrap};
        $acols{$ci}++;
        $origw{$ci} = $fcol_widths->[$ci];
    }
    return 0 unless %acols;

    # only do this if table width exceeds terminal width
    my $termw = $self->term_width;
    return 0 unless $termw > 0;
    my $excess = $self->{_draw}{table_width} - $termw;
    return 0 unless $excess > 0;

    # reduce text columns proportionally
    my $w = 0; # total width of all to-be-adjusted columns
    $w += $fcol_widths->[$_] for keys %acols;
    return 0 unless $w > 0;
    my $reduced = 0;
  REDUCE:
    while (1) {
        my $has_reduced;
        for my $ci (keys %acols) {
            last REDUCE if $reduced >= $excess;
            if ($fcol_widths->[$ci] > 30) {
                $fcol_widths->[$ci]--;
                $reduced++;
                $has_reduced++;
            }
        }
        last if !$has_reduced;
    }

    # reset widths
    for my $ci (keys %acols) {
        $fcol_setwidths->[$ci] = $fcol_widths->[$ci];
        $fcol_widths->[$ci] = 0; # reset
    }

    # wrap and set setwidths so it doesn't grow again during recalculate
    for my $ci (keys %acols) {
        next unless $origw{$ci} != $fcol_widths->[$ci];
        for (0..@$frows-1) {
            $frows->[$_][$ci] = $self->{_func_wrap}->(
                $frows->[$_][$ci], $fcol_setwidths->[$ci]);
        }
    }

    # recalculate column widths
    $self->_calc_row_widths_heights;
    $self->_calc_table_width_height;
    1;
}

# filter columns & rows, calculate widths/paddings, format data, put the results
# in _draw (draw data) attribute.
sub _prepare_draw {
    my $self = shift;

    $self->{_draw} = {};

    $self->_read_style_envs;
    $self->_calc_fcols;
    $self->_calc_header_height;
    $self->_calc_frows;
    $self->_detect_column_types;
    $self->_apply_column_formats;
    $self->_apply_cell_formats;
    $self->_wrap_wrappable_columns;
    $self->_calc_row_widths_heights;
    $self->_calc_table_width_height;
    $self->_adjust_column_widths;
}

# push string into the drawing buffer. also updates "cursor" position.
sub draw_str {
    my $self = shift;
    # currently x position is not recorded because this involves doing
    # ta_mbswidth() (or ta_mbswidth_height()) for every string, which is rather
    # expensive. so only the y position is recorded by counting newlines.

    for (@_) {
        my $num_nl = 0;
        $num_nl++ while /\r?\n/og;
        push @{$self->{_draw}{buf}}, $_;
        $self->{_draw}{y} += $num_nl;
    }
    $self;
}

sub draw_theme_color {
    my $self = shift;
    my $c = $self->_color_theme_item_color_to_ansi(@_);
    $self->draw_str($c) if length($c);
}

sub get_color_reset {
    my $self = shift;
    return "" unless $self->use_color;
    return "" if $self->{color_theme_obj}->get_struct->{_no_color};
    "\e[0m";
}

sub draw_color_reset {
    my $self = shift;
    my $c = $self->get_color_reset;
    $self->draw_str($c) if length($c);
}

# draw border character(s). drawing border character involves setting border
# color, aside from drawing the actual characters themselves. arguments are list
# of (y, x, n) tuples where y and x are the row and col number of border
# character, n is the number of characters to print. n defaults to 1 if not
# specified.
sub draw_border_char {
    my $self = shift;
    my $args; $args = shift if ref($_[0]) eq 'HASH';

    while (my ($name, $n) = splice @_, 0, 2) {
        $n //= 1;
        if (!$self->{use_color}) {
            # save some CPU cycles
        } elsif ($args) {
            $self->draw_theme_color('border',
                                    {table=>$self, border=>[$name, $n], %$args});
        } else {
            $self->draw_theme_color('border',
                                    {table=>$self, border=>[$name, $n]});
        }
        $self->draw_str($self->{border_style_obj}->get_border_char(char=>$name, repeat=>$n));
        $self->draw_color_reset;
    }
}

sub _should_draw_row_separator {
    my ($self, $i) = @_;

    return $i < @{$self->{_draw}{frows}}-1 &&
        (($self->{show_row_separator}==2 && (grep { $_ == $i } @{ $self->{_draw}{frow_separators} }))
             || $self->{show_row_separator}==1);
}

# apply align/valign, apply padding, apply default fgcolor/bgcolor to text,
# truncate to specified cell's width & height
sub _get_cell_lines {
    my $self = shift;
    #say "D: get_cell_lines ".join(", ", map{$_//""} @_);
    my ($text, $width, $height, $align, $valign,
        $lpad, $rpad, $tpad, $bpad, $color) = @_;

    my @lines;
    push @lines, "" for 1..$tpad;
    my @dlines = split(/\r?\n/, $text);
    @dlines = ("") unless @dlines;
    my ($la, $lb);
    $valign //= 'top';
    if ($valign =~ /^[Bb]/o) { # bottom
        $la = $height-@dlines;
        $lb = 0;
    } elsif ($valign =~ /^[MmCc]/o) { # middle/center
        $la = int(($height-@dlines)/2);
        $lb = $height-@dlines-$la;
    } else { # top
        $la = 0;
        $lb = $height-@dlines;
    }
    push @lines, "" for 1..$la;
    push @lines, @dlines;
    push @lines, "" for 1..$lb;
    push @lines, "" for 1..$bpad;

    $align //= 'left';
    my $pad = $align =~ /^[Ll]/o ? "right" :
        ($align =~ /^[Rr]/o ? "left" : "center");

    for (@lines) {
        $_ = (" "x$lpad) . $self->{_func_pad}->($_, $width, $pad, " ", 1) . (" "x$rpad);
        if ($self->{use_color}) {
            # add default color
            s/\e\[0m(?=.)/\e[0m$color/g if length($color);
            $_ = $color . $_;
        }
    }

    \@lines;
}

sub _get_header_cell_lines {
    my ($self, $i) = @_;

    my $ct = $self->{color_theme};

    my $tmp;
    my $fgcolor;
    if (defined $self->{header_fgcolor}) {
        $fgcolor = item_color_to_ansi($self->{header_fgcolor});
    } elsif (defined $self->{cell_fgcolor}) {
        $fgcolor = item_color_to_ansi($self->{cell_fgcolor});
    #} elsif (defined $self->{_draw}{fcol_detect}[$i]{fgcolor}) {
    #    $fgcolor = item_color_to_ansi($self->{_draw}{fcol_detect}[$i]{fgcolor});
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('header')) {
        $fgcolor = $tmp;
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('cell')) {
        $fgcolor = $tmp;
    } else {
        $fgcolor = "";
    }

    my $bgcolor;
    if (defined $self->{header_bgcolor}) {
        $bgcolor = item_color_to_ansi($self->{header_bgcolor}, 'bg');
    } elsif (defined $self->{cell_bgcolor}) {
        $bgcolor = item_color_to_ansi($self->{cell_bgcolor}, 'bg');
    } elsif (defined $self->{_draw}{fcol_detect}[$i]{bgcolor}) {
        $bgcolor = item_color_to_ansi($self->{_draw}{fcol_detect}[$i]{bgcolor}, 'bg');
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('header_bg', undef, 'bg')) {
        $bgcolor = $tmp;
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('cell_bg', undef, 'bg')) {
        $bgcolor = $tmp;
    } else {
        $bgcolor = "";
    }

    my $align =
        $self->{header_align} //
            $self->{cell_align} //
                $self->{_draw}{fcol_detect}[$i]{align} //
                    'left';
    my $valign =
        $self->{header_valign} //
            $self->{cell_valign} //
                $self->{_draw}{fcol_detect}[$i]{valign} //
                    'top';

    my $lpad = $self->{_draw}{fcol_lpads}[$i];
    my $rpad = $self->{_draw}{fcol_rpads}[$i];
    my $tpad = $self->{header_tpad} // $self->{header_vpad} // 0;
    my $bpad = $self->{header_bpad} // $self->{header_vpad} // 0;

    #use Data::Dump; print "D:header cell: "; dd {i=>$i, col=>$self->{columns}[$i], fgcolor=>$fgcolor, bgcolor=>$bgcolor};
    my $res = $self->_get_cell_lines(
        $self->{columns}[$i],            # text
        $self->{_draw}{fcol_widths}[$i], # width
        $self->{_draw}{header_height},   # height
        $align, $valign,                 # aligns
        $lpad, $rpad, $tpad, $bpad,      # paddings
        $fgcolor . $bgcolor);
    #use Data::Dump; print "D:res: "; dd $res;
    $res;
}

sub _get_data_cell_lines {
    my ($self, $y, $x) = @_;

    my $ct   = $self->{color_theme};
    my $oy   = $self->{_draw}{frow_orig_indices}[$y];
    my $cell = $self->{_draw}{frows}[$y][$x];
    my $args = {table=>$self, rownum=>$y, colnum=>$x, data=>$cell,
                orig_data=>$self->{rows}[$oy][$x]};

    my $tmp;
    my $fgcolor;
    if (defined ($tmp = $self->get_eff_cell_style($oy, $x, 'fgcolor'))) {
        $fgcolor = item_color_to_ansi($tmp);
    } elsif (defined ($tmp = $self->get_eff_row_style($oy, 'fgcolor'))) {
        $fgcolor = item_color_to_ansi($tmp);
    } elsif (defined ($tmp = $self->get_eff_column_style($x, 'fgcolor'))) {
        $fgcolor = item_color_to_ansi($tmp);
    } elsif (defined ($tmp = $self->{cell_fgcolor})) {
        $fgcolor = item_color_to_ansi($tmp);
    } elsif (defined ($tmp = $self->{_draw}{fcol_detect}[$x]{fgcolor})) {
        $fgcolor = item_color_to_ansi($tmp);
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('cell', $args)) {
        $fgcolor = $tmp;
    } else {
        $fgcolor = "";
    }

    my $bgcolor;
    if (defined ($tmp = $self->get_eff_cell_style($oy, $x, 'bgcolor'))) {
        $bgcolor = item_color_to_ansi($tmp, 'bg');
    } elsif (defined ($tmp = $self->get_eff_row_style($oy, 'bgcolor'))) {
        $bgcolor = item_color_to_ansi($tmp, 'bg');
    } elsif (defined ($tmp = $self->get_eff_column_style($x, 'bgcolor'))) {
        $bgcolor = item_color_to_ansi($tmp, 'bg');
    } elsif (defined ($tmp = $self->{cell_bgcolor})) {
        $bgcolor = item_color_to_ansi($tmp, 'bg');
    } elsif (defined ($tmp = $self->{_draw}{fcol_detect}[$x]{bgcolor})) {
        $bgcolor = item_color_to_ansi($tmp, 'bg');
    } elsif ($tmp = $self->_color_theme_item_color_to_ansi('cell_bg', $args, 'bg')) {
        $bgcolor = $tmp;
    } else {
        $bgcolor = "";
    }

    my $align =
        $self->get_eff_cell_style($oy, $x, 'align') //
            $self->get_eff_row_style($oy, 'align') //
                $self->get_eff_column_style($x, 'align') //
                    $self->{cell_align} //
                        $self->{_draw}{fcol_detect}[$x]{align} //
                            'left';
    my $valign =
        $self->get_eff_cell_style($oy, $x, 'valign') //
            $self->get_eff_row_style($oy, 'valign') //
                $self->get_eff_column_style($x, 'valign') //
                    $self->{cell_valign} //
                        $self->{_draw}{fcol_detect}[$x]{valign} //
                            'top';
    #say "D:y=$y, x=$x, align=$align, valign=$valign";

    my $lpad = $self->{_draw}{fcol_lpads}[$x];
    my $rpad = $self->{_draw}{fcol_rpads}[$x];
    my $tpad = $self->{_draw}{frow_tpads}[$y];
    my $bpad = $self->{_draw}{frow_bpads}[$y];

    my $res = $self->_get_cell_lines(
        $cell,                            # text
        $self->{_draw}{fcol_widths}[$x],  # width
        $self->{_draw}{frow_heights}[$y], # height
        $align, $valign,                  # aligns
        $lpad, $rpad, $tpad, $bpad,       # paddings
        $fgcolor . $bgcolor);
    $res;
}

sub draw {
    my ($self) = @_;

    $self->_prepare_draw;

    $self->{_draw}{buf} = []; # output buffer
    $self->{_draw}{y} = 0; # current line

    my $cols  = $self->{columns};
    my $fcols = $self->{_draw}{fcols};
    my $frows = $self->{_draw}{frows};
    my $frow_heights    = $self->{_draw}{frow_heights};
    my $frow_tpads      = $self->{_draw}{frow_tpads};
    my $frow_bpads      = $self->{_draw}{frow_bpads};
    my $fcol_lpads      = $self->{_draw}{fcol_lpads};
    my $fcol_rpads      = $self->{_draw}{fcol_rpads};
    my $fcol_widths     = $self->{_draw}{fcol_widths};

    # draw border top line
    {
        last unless length($self->{border_style_obj}->get_border_char(char=>'rd_t'));
        my @b;
        push @b, 'rd_t', 1;
        for my $i (0..@$fcols-1) {
            my $ci = $self->_colnum($fcols->[$i]);
            push @b, 'h_t',
                $fcol_lpads->[$ci] + $fcol_widths->[$ci] + $fcol_rpads->[$ci];
            push @b, 'hd_t', 1 if $i < @$fcols-1;
        }
        push @b, 'ld_t', 1;
        $self->draw_border_char(@b);
        $self->draw_str("\n");
    }

    # draw header
    if ($self->{show_header}) {
        my %seen;
        my $hcell_lines = []; # index = [fcolnum]
        if (@$fcols) {
            for my $i (0..@$fcols-1) {
                my $ci = $self->_colnum($fcols->[$i]);
                if (defined($seen{$i})) {
                    $hcell_lines->[$i] = $hcell_lines->[$seen{$i}];
                }
                $seen{$i} = $ci;
                $hcell_lines->[$i] = $self->_get_header_cell_lines($ci);
            }
        } else {
            # so we can still draw header
            $hcell_lines->[0] = [""];
        }
        #use Data::Dump; print "D:hcell_lines: "; dd $hcell_lines;
        for my $l (0..@{ $hcell_lines->[0] }-1) {
            $self->draw_border_char('v_l');
            for my $i (0..@$fcols-1) {
                $self->draw_str($hcell_lines->[$i][$l]);
                $self->draw_color_reset;
                $self->draw_border_char('v_i') unless $i == @$fcols-1;
            }
            $self->draw_border_char('v_r');
            $self->draw_str("\n");
        }
    }

    # draw header-data row separator
    if ($self->{show_header} && length($self->{border_style_obj}->get_border_char(char=>'rv_l'))) {
        my @b;
        push @b, 'rv_l', 1;
        for my $i (0..@$fcols-1) {
            my $ci = $self->_colnum($fcols->[$i]);
            push @b, 'h_i',
                $fcol_lpads->[$ci] + $fcol_widths->[$ci] + $fcol_rpads->[$ci];
            push @b, 'hv_i', 1 unless $i==@$fcols-1;
        }
        push @b, 'lv_r', 1;
        $self->draw_border_char(@b);
        $self->draw_str("\n");
    }

    # draw data rows
    {
        for my $r (0..@$frows-1) {
            #$self->draw_str("r$r");
            my $dcell_lines = []; # index = [fcolnum]
            my %seen;
            if (@$fcols) {
                for my $i (0..@$fcols-1) {
                    my $ci = $self->_colnum($fcols->[$i]);
                    if (defined($seen{$i})) {
                        $dcell_lines->[$i] = $dcell_lines->[$seen{$i}];
                    }
                    $seen{$i} = $ci;
                    $dcell_lines->[$i] = $self->_get_data_cell_lines($r, $ci);
                }
            } else {
                # so we can still print row
                $dcell_lines->[0] = [" "];
            }
            #use Data::Dump; print "TMP: dcell_lines: "; dd $dcell_lines;
            for my $l (0..@{ $dcell_lines->[0] }-1) {
                $self->draw_border_char({rownum=>$r}, 'v_l');
                for my $i (0..@$fcols-1) {
                    $self->draw_str($dcell_lines->[$i][$l]);
                    $self->draw_color_reset;
                    $self->draw_border_char({rownum=>$r}, 'v_i')
                        unless $i == @$fcols-1;
                }
                $self->draw_border_char({rownum=>$r}, 'v_r');
                $self->draw_str("\n");
            }

            # draw separators between row
            if ($self->_should_draw_row_separator($r)) {
                my @b;
                push @b, 'rv_l', 1;
                for my $i (0..@$fcols-1) {
                    my $ci = $self->_colnum($fcols->[$i]);
                    push @b, 'h_i',
                        $fcol_lpads->[$ci] + $fcol_widths->[$ci] +
                            $fcol_rpads->[$ci];
                    push @b, ($i==@$fcols-1 ? 'lv_r' : 'hv_i'), 1;
                }
                $self->draw_border_char({rownum=>$r}, @b);
                $self->draw_str("\n");
            }
        } # for frow
    }

    # draw border bottom line
    {
        last unless length($self->{border_style_obj}->get_border_char(char=>'ru_b'));
        my @b;
        push @b, 'ru_b', 1;
        for my $i (0..@$fcols-1) {
            my $ci = $self->_colnum($fcols->[$i]);
            push @b, 'h_b',
                $fcol_lpads->[$ci] + $fcol_widths->[$ci] + $fcol_rpads->[$ci];
            push @b, 'hu_b', 1 unless $i == @$fcols-1;
        }
        push @b, 'lu_b', 1;
        $self->draw_border_char(@b);
        $self->draw_str("\n");
    }

    join "", @{$self->{_draw}{buf}};
}

1;
# ABSTRACT: Create nice formatted tables using extended ASCII and ANSI colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable - Create nice formatted tables using extended ASCII and ANSI colors

=head1 VERSION

This document describes version 0.610 of Text::ANSITable (from Perl distribution Text-ANSITable), released on 2025-02-24.

=head1 SYNOPSIS

 use 5.010;
 use Text::ANSITable;

 # don't forget this if you want to output utf8 characters
 binmode(STDOUT, ":utf8");

 my $t = Text::ANSITable->new;

 # set styles
 $t->border_style('UTF8::SingleLineBold');  # if not, a nice default is picked
 $t->color_theme('Standard::NoGradation');  # if not, a nice default is picked

 # fill data
 $t->columns(["name"       , "color" , "price"]);
 $t->add_row(["chiki"      , "yellow",    2000]);
 $t->add_row(["lays"       , "green" ,    7000]);
 $t->add_row(["tao kae noi", "blue"  ,   18500]);

 # draw it!
 print $t->draw;

Samples of output:

=head1 DESCRIPTION

This module is yet another text table formatter module like L<Text::ASCIITable>
or L<Text::SimpleTable>, with the following differences:

=over

=item * Colors and color themes

ANSI color codes will be used by default (even 256 and 24bit colors), but will
degrade to lower color depth and black/white according to terminal support.

=item * Box-drawing characters

Box-drawing characters will be used by default, but will degrade to using normal
ASCII characters if terminal does not support them.

=item * Unicode and wide character support

Border styles using Unicode characters (double lines, bold/heavy lines, brick
style, etc). Columns containing wide characters stay aligned. (Note: support for
wide characters requires L<Text::ANSI::WideUtil> which is currently set as an
optional prereq, so you'll need to install it explicitly or set your CPAN client
to install 'recommends' prereq).

=back

Compared to Text::ASCIITable, it uses C<lower_case> method/attr names instead of
C<CamelCase>, and it uses arrayref for C<columns> and C<add_row>. When
specifying border styles, the order of characters are slightly different. More
fine-grained options to customize appearance.

=for Pod::Coverage ^(BUILD|draw_.+|get_color_reset)$

=begin HTML

<p><img src="http://blogs.perl.org/users/steven_haryanto/ansitable1.png" /></p>

<p><img src="http://blogs.perl.org/users/steven_haryanto/ansitable2.png" /></p>

<p><img src="http://blogs.perl.org/users/steven_haryanto/ansitable3.png" /></p>

<p><img src="http://blogs.perl.org/users/steven_haryanto/ansitable4.png" /></p>

<p><img src="http://blogs.perl.org/users/steven_haryanto/ansitable5.png" /></p>

=end HTML

=head1 DECLARED FEATURES

Features declared by this module:

=head2 From feature set PerlTrove

Features from feature set L<PerlTrove|Module::Features::PerlTrove> declared by this module:

=over

=item * Development Status

Value: "5 - ProductionE<sol>Stable".

=item * Environment

Value: "Console".

=item * Intended Audience

Value: ["Developers"].

=item * License

Value: "OSI Approved :: Artistic License".

=item * Programming Language

Value: "Perl".

=item * Topic

Value: ["Software Development :: Libraries :: Perl Modules","Utilities"].

=back

=head2 From feature set TextTable

Features from feature set L<TextTable|Module::Features::TextTable> declared by this module:

=over

=item * can_align_cell_containing_color_code

Value: yes.

=item * can_align_cell_containing_newline

Value: yes.

=item * can_align_cell_containing_wide_character

Value: yes.

=item * can_color

Can produce colored table.

Value: yes.

=item * can_color_theme

Allow choosing colors from a named set of palettes.

Value: yes.

=item * can_colspan

Value: no.

=item * can_customize_border

Let user customize border character in some way, e.g. selecting from several available borders, disable border.

Value: yes.

=item * can_halign

Provide a way for user to specify horizontal alignment (leftE<sol>middleE<sol>right) of cells.

Value: yes.

=item * can_halign_individual_cell

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual cells.

Value: yes.

=item * can_halign_individual_column

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual columns.

Value: yes.

=item * can_halign_individual_row

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual rows.

Value: yes.

=item * can_hpad

Provide a way for user to specify horizontal padding of cells.

Value: yes.

=item * can_hpad_individual_cell

Provide a way for user to specify different horizontal padding of individual cells.

Value: yes.

=item * can_hpad_individual_column

Provide a way for user to specify different horizontal padding of individual columns.

Value: yes.

=item * can_hpad_individual_row

Provide a way for user to specify different horizontal padding of individual rows.

Value: yes.

=item * can_rowspan

Value: no.

=item * can_set_cell_height

Allow setting height of rows.

Value: yes.

=item * can_set_cell_height_of_individual_row

Allow setting height of individual rows.

Value: yes.

=item * can_set_cell_width

Allow setting height of rows.

Value: yes.

=item * can_set_cell_width_of_individual_column

Allow setting height of individual rows.

Value: yes.

=item * can_use_box_character

Can use terminal box-drawing character when drawing border.

Value: yes.

=item * can_valign

Provide a way for user to specify vertical alignment (topE<sol>middleE<sol>bottom) of cells.

Value: yes.

=item * can_valign_individual_cell

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual cells.

Value: yes.

=item * can_valign_individual_column

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual columns.

Value: yes.

=item * can_valign_individual_row

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual rows.

Value: yes.

=item * can_vpad

Provide a way for user to specify vertical padding of cells.

Value: yes.

=item * can_vpad_individual_cell

Provide a way for user to specify different vertical padding of individual cells.

Value: yes.

=item * can_vpad_individual_column

Provide a way for user to specify different vertical padding of individual columns.

Value: yes.

=item * can_vpad_individual_row

Provide a way for user to specify different vertical padding of individual rows.

Value: yes.

=item * speed

Subjective speed rating, relative to other text table modules.

Value: "slow".

=back

For more details on module features, see L<Module::Features>.

=head1 REFERRING TO COLUMNS

Columns can be referred to be integer number (0-based) or name (string). You
should not have integer numbers as column names because that will be confusing.
Example:

 $t->columns(["col1", "col2", "col3"]); # col1=0, col2=1, col3=2
 $t->add_row([...]);
 ...

 # set visible columns
 $t->column_filter([1,2,1]); # col2, col3, col2
 $t->column_filter(["col2","col3","col2"]); # same thing

See also: L</REFERRING TO ROWS>.

=head1 REFERRING TO ROWS

Rows are referred to by integer number (0-based).

 $t->columns(["name", "age", "gender"]);
 $t->add_row(["marty", ...]); # first row (0)
 $t->add_row(["wendy", ...]); # second row (1)
 $t->add_row(["charlotte", ...]); # third row (2)

 # set visible rows
 $t->row_filter([0,2]); # marty & charlotte

See also: L</REFERRING TO COLUMNS>.

=head1 BORDER STYLES

To list available border styles, just list the C<BorderStyle::*> modules. You
can use the provided method:

 say $_ for $t->list_border_styles;

Or you can also try out borders using the provided
L<ansitable-list-border-styles> script.

To choose border style, set the C<border_style> attribute to an available border
style name (which is the BorderStyle::* module name without the prefix) with
optional arguments.

 # during construction
 my $t = Text::ANSITable->new(
     ...
     border_style => "UTF8::SingleLineBold",
     ...
 );

 # after the object is constructed
 $t->border_style("UTF8::SingleLineBold");
 $t->border_style("Test::CustomChar=character,x");
 $t->border_style(["Test::CustomChar", {character=>"x"}]);

If no border style is selected explicitly, a nice default will be chosen. You
can also set the C<ANSITABLE_BORDER_STYLE> or C<BORDER_STYLE> environment
variable to set the default.

To create a new border style, see L<BorderStyle>.

=head1 COLOR THEMES

To list available color themes, just list the C<ColorTheme::*> modules (usually
you want to use color themes specifically created for Text::ANSITable in
C<ColorTheme::Text::ANSITable::*> namespace). You can use the provided method:

 say $_ for $t->list_color_themes;

Or you can also run the provided L<ansitable-list-color-themes> script.

To choose a color theme, set the C<color_theme> attribute to an available color
theme (which is the ColorTheme::* module name without the prefix) with optional
arguments:

 # during construction
 my $t = Text::ANSITable->new(
     ...
     color_theme => "Standard::NoGradation",
     ...
 );

 # after the object is constructed
 $t->color_theme("Standard::NoGradation");
 $t->color_theme(["Lens::Darken", {theme=>"Standard::NoGradation"}]);

If no color theme is selected explicitly, a nice default will be chosen. You can
also set the C<ANSITABLE_COLOR_THEME> environment variable to set the default.

To create a new color theme, see L<ColorTheme> and an existing
C<ColorTheme::Text::ANSITable::*> module.

=head1 COLUMN WIDTHS

By default column width is set just so it is enough to show the widest data.
This can be customized in the following ways (in order of precedence, from
lowest):

=over

=item * table-level C<cell_width> attribute

This sets width for all columns.

=item * conditional column styles

The example below sets column width to 10 for columns whose names matching
C</[acm]time/>, else sets the column width to 20.

 $t->add_cond_column_style(sub {  /[acm]time/ }, width => 10);
 $t->add_cond_column_style(sub { !/[acm]time/ }, width => 20);

=item * per-column C<width> style

 $t->set_column_style('colname', width => 20);

=back

You can use negative number to mean I<minimum> width.

=head1 ROW HEIGHTS

This can be customized in the following ways (in order of precedence, from
lowest):

=over

=item * table-level C<cell_height> attribute

This sets height for all rows.

=item * conditional row styles

The example below sets row height to 2 for every odd rows, and 1 for even rows.

 $t->add_cond_row_style(sub { $_ % 2 == 0 }, height => 2);
 $t->add_cond_row_style(sub { $_ % 2      }, height => 1);

=item * per-row C<height> style

 $t->set_row_style(1, height => 2);

=back

You can use negative number to mean I<minimum> height.

=head1 CELL (HORIZONTAL) PADDING

By default cell (horizontal) padding is 1. This can be customized in the
following ways (in order of precedence, from lowest):

=over

=item * table-level C<cell_pad> attribute

This sets left and right padding for all columns.

=item * table-level C<cell_lpad> and C<cell_rpad> attributes

They set left and right padding for all columns, respectively.

=item * conditional column C<pad> style

 $t->add_cond_column_style($cond, pad => 0);

=item * conditional column C<lpad>/C<rpad> style

 $t->add_cond_column_style($cond, lpad => 1, rpad => 2);

=item * per-column C<pad> style

 $t->set_column_style($colname, pad => 0);

=item * per-column C<lpad>/C<rpad> style

 $t->set_column_style($colname, lpad => 1);
 $t->set_column_style($colname, rpad => 2);

=back

=head1 ROW VERTICAL PADDING

Default vertical padding is 0. This can be changed in the following ways (in
order of precedence, from lowest):

=over

=item * table-level C<cell_vpad> attribute

This sets top and bottom padding for all rows.

=item * table-level C<cell_tpad>/C<cell_bpad> attributes

They set top/bottom padding separately for all rows.

=item * conditional row C<vpad> style

Example:

 $t->add_cond_row_style($cond, vpad => 1);

=item * per-row C<vpad> style

Example:

 $t->set_row_style($rownum, vpad => 1);

When adding row:

 $t->add_row($rownum, {vpad=>1});

=item * per-row C<tpad>/C<bpad> style

Example:

 $t->set_row_style($rownum, tpad => 1);
 $t->set_row_style($rownum, bpad => 2);

When adding row:

 $t->add_row($row, {tpad=>1, bpad=>2});

=back

=head1 CELL COLORS

By default data format colors are used, e.g. cyan/green for text (using the
default color scheme, items C<num_data>, C<bool_data>, etc). In absense of that,
C<cell_fgcolor> and C<cell_bgcolor> from the color scheme are used. You can
customize colors in the following ways (ordered by precedence, from lowest):

=over

=item * table-level C<cell_fgcolor> and C<cell_bgcolor> attributes

Sets all cells' colors. Color should be specified using 6-hexdigit RGB which
will be converted to the appropriate terminal color.

Can also be set to a coderef which will receive ($rownum, $colname) and should
return an RGB color.

=item * conditional column C<fgcolor> and C<bgcolor> style

Example:

 $t->add_cond_column_style($cond, fgcolor => 'fa8888', bgcolor => '202020');

=item * per-column C<fgcolor> and C<bgcolor> styles

Example:

 $t->set_column_style('colname', fgcolor => 'fa8888');
 $t->set_column_style('colname', bgcolor => '202020');

=item * conditional row C<fgcolor> and C<bgcolor> style

Example:

 $t->add_cond_row_style($cond, fgcolor => 'fa8888', bgcolor => '202020');

=item * per-row C<fgcolor> and C<bgcolor> styles

Example:

 $t->set_row_style($rownum, {fgcolor => 'fa8888', bgcolor => '202020'});

When adding row/rows:

 $t->add_row($row, {fgcolor=>..., bgcolor=>...});
 $t->add_rows($rows, {bgcolor=>...});

=item * conditional cell C<fgcolor> and C<bgcolor> style

 $t->add_cond_cell_style($cond, fgcolor=>..., bgcolor=>...);

=item * per-cell C<fgcolor> and C<bgcolor> styles

Example:

 $t->set_cell_style($rownum, $colname, fgcolor => 'fa8888');
 $t->set_cell_style($rownum, $colname, bgcolor => '202020');

=back

For flexibility, all colors can be specified as coderef. See L</"COLOR THEMES">
for more details.

=head1 CELL (HORIZONTAL AND VERTICAL) ALIGNMENT

By default, numbers are right-aligned, dates and bools are centered, and the
other data types (text including) are left-aligned. All data are top-valigned.
This can be customized in the following ways (in order of precedence, from
lowest):

=over

=item * table-level C<cell_align> and C<cell_valign> attribute

=item * conditional column C<align> and <valign> styles

 $t->add_cond_column_style($cond, align=>..., valign=>...);

=item * per-column C<align> and C<valign> styles

Example:

 $t->set_column_style($colname, align  => 'middle'); # or left, or right
 $t->set_column_style($colname, valign => 'top');    # or bottom, or middle

=item * conditional row C<align> and <valign> styles

 $t->add_cond_row_style($cond, align=>..., valign=>...);

=item * per-row C<align> and C<valign> styles

=item * conditional cell C<align> and <valign> styles

 $t->add_cond_cell_style($cond, align=>..., valign=>...);

=item * per-cell C<align> and C<valign> styles

 $t->set_cell_style($rownum, $colname, align  => 'middle');
 $t->set_cell_style($rownum, $colname, valign => 'top');

=back

=head1 CELL FORMATS

The per-column- and per-cell- C<formats> style regulates how to format data. The
value for this style setting will be passed to L<Data::Unixish::Apply>'s
C<apply()>, as the C<functions> argument. So it should be a single string (like
C<date>) or an array (like C<< ['date', ['centerpad', {width=>20}]] >>).

L<Data::Unixish::Apply> is an optional prerequisite, so you will need to install
it separately if you need this feature.

To see what functions are available, install L<App::dux> and then run C<dux -l>.
Functions of interest to formatting data include: C<bool>, C<num>, C<sprintf>,
C<sprintfn>, C<wrap>, C<ANSI::*> (in L<Data::Unixish::ANSI> distribution),
(among others).

=head1 CONDITIONAL STYLES

As an alternative to setting styles for specific {column,row,cell}, you can also
create conditional styles. You specify a Perl code for the condition, then if
the condition evaluates to true, the corresponding styles are applied to the
corresponding {column,row,cell}.

To add a conditional style, use the C<add_cond_{column,row,cell}_style> methods.
These methods accept condition code as its first argument and one or more styles
in the subsequent argument(s). For example:

 $t->add_cond_row_style(sub { $_ % 2 }, bgcolor=>'202020');

The above example will set row bgcolor for odd rows. You can add more
conditional styles:

 $t->add_cond_row_style(sub { $_ % 2 == 0 }, bgcolor=>'404040');

All the conditions will be evaluated and the applicable styles will be merged
together. For example, if we add a third conditional row style:

 $t->add_cond_row_style(sub { $_ % 10 == 0 }, height=>2, fgcolor=>'ffff00');

then every tenth row will have its height set to 2, fgcolor set to ffff00, and
bgcolor set to 404040 (from the second conditional).

Condition coderef will be called with these arguments:

 ($self, %args)

Available keys in C<%args> for conditional column styles: C<col> (int, column
index), C<colname> (str, column name). Additionally, C<$_> will be set locally
to the column index.

Available keys in C<%args> for conditional row styles: C<row> (int, row index),
C<row_data> (array). Additionally, C<$_> will be set locally to the row index.

Available keys in C<%args> for conditional cell styles: C<content> (str), C<col>
(int, column index), C<row> (int, row index). Additionally, C<$_> will be set
locally to the cell content.

Coderef should return boolean indicating whether style should be applied to a
particular column/row/cell. When returning a true value, coderef can also return
a hashref to return additional styles that will be merged/applied too.

=head1 STYLE SETS

A style set is just a collection of style settings that can be applied.
Organizing styles into style sets makes applying the styles simpler and more
reusable.

More than one style sets can be applied.

Style set module accepts arguments.

For example, the L<Text::ANSITable::StyleSet::AltRow> style set defines this:

 has odd_bgcolor  => (is => 'rw');
 has even_bgcolor => (is => 'rw');
 has odd_fgcolor  => (is => 'rw');
 has even_fgcolor => (is => 'rw');

 sub apply {
     my ($self, $table) = @_;

     $table->add_cond_row_style(sub {
         my ($t, %args) = @_;
         my %styles;
         if ($_ % 2) {
             $styles{bgcolor} = $self->odd_bgcolor
                 if defined $self->odd_bgcolor;
             $styles{fgcolor} = $self->odd_fgcolor
                 if defined $self->odd_bgcolor;
         } else {
             $styles{bgcolor} = $self->even_bgcolor
                 if defined $self->even_bgcolor;
             $styles{fgcolor} = $self->even_fgcolor
                 if defined $self->even_bgcolor;
         }
         \%styles;
     });
 }

To apply this style set:

 $t->apply_style_set("AltRow", odd_bgcolor=>"003300", even_bgcolor=>"000000");

To create a new style set, create a module under C<Text::ANSITable::StyleSet::>
like the above example. Please see the other existing style set modules for more
examples.

=head1 ATTRIBUTES

=head2 columns

Array of str. Must be unique.

Store column names. Note that when drawing, you can omit some columns, reorder
them, or display some more than once (see C<column_filter> attribute).

Caveat: Since, for convenience, a column can be referred to using its name or
position, weird/unecxpected thing can happen if you name a column with a number
(e.g. 0, 1, 2, ...). So don't do that.

=head2 rows => ARRAY OF ARRAY OF STR

Store row data. You can set this attribute directly, or add rows incrementally
using C<add_row()> and C<add_rows()> methods.

=head2 row_filter => CODE|ARRAY OF INT

When drawing, only show rows that match this. Can be an array containing indices
of rows which should be shown, or a coderef which will be called for each row
with arguments C<< ($row, $rownum) >> and should return a bool value indicating
whether that row should be displayed.

Internal note: During drawing, rows will be filtered and put into C<<
$t->{_draw}{frows} >>.

=head2 column_filter => CODE|ARRAY OF STR

When drawing, only show columns that match this. Can be an array containing
names of columns that should be displayed (column names can be in different
order or duplicate, column can also be referred to with its numeric index). Can
also be a coderef which will be called with C<< ($colname, $colnum) >> for
every column and should return a bool value indicating whether that column
should be displayed. The coderef version is more limited in that it cannot
reorder the columns or instruct for the same column to be displayed more than
once.

Internal note: During drawing, column names will be filtered and put into C<<
$t->{_draw}{fcols} >>.

=head2 column_wrap => BOOL

Set column wrapping for all columns. Can be overriden by per-column C<wrap>
style. By default column wrapping will only be done for text columns and when
width is explicitly set to a positive value.

=head2 use_color => BOOL

Whether to output color. Default is taken from C<NO_COLOR> environment variable,
C<COLOR> environment variable, or detected via C<(-t STDOUT)>. If C<use_color>
is set to 0, an attempt to use a colored color theme (i.e. anything that is not
the C<no_color> theme) will result in an exception.

(In the future, setting C<use_color> to 0 might opt the module to use
normal/plain string routines instead of the slower ta_* functions from
L<Text::ANSI::Util>; this also means that the module won't handle ANSI escape
codes in the content text.)

=head2 color_depth => INT

Terminal's color depth. Either 16, 256, or 2**24 (16777216). Default will be
retrieved from C<COLOR_DEPTH> environment or detected using L<Term::Detect>.

=head2 use_box_chars => BOOL

Whether to use box drawing characters. Drawing box drawing characters can be
problematic in some places because it uses ANSI escape codes to switch to (and
back from) line drawing mode (C<"\e(0"> and C<"\e(B">, respectively).

Default is taken from C<BOX_CHARS> environment variable, or 1. If
C<use_box_chars> is set to 0, an attempt to use a border style that uses box
drawing chararacters will result in an exception.

=head2 use_utf8 => BOOL

Whether to use Unicode (UTF8) characters. Default is taken from C<UTF8>
environment variable, or detected using L<Term::Detect>, or guessed via L<LANG>
environment variable. If C<use_utf8> is set to 0, an attempt to select a border
style that uses Unicode characters will result in an exception.

(In the future, setting C<use_utf8> to 0 might opt the module to use the
non-"mb_*" version of functions from L<Text::ANSI::Util>, e.g. C<ta_wrap()>
instead of C<ta_mbwrap()>, and so on).

=head2 wide => BOOL

Whether to support wide characters. The default is to check for the existence of
L<Text::ANSI::WideUtil> (an optional prereq). You can explicitly enable or
disable wide-character support here.

=head2 border_style => STR

Border style name to use. This is a module name in the
C<BorderStyle::Text::ANSITable::*>, C<BorderStyle::*>, or
C<BorderStyle::Text::ANSITable::OldCompat::*> namespace, without the prefix.
See the L<BorderStyle> specification on how to create a new border style.

=head2 color_theme => STR

Color theme name to use. This is a module name in the
C<ColorTheme::Text::ANSITable::*>, C<ColorTheme::*>, or
C<ColorTheme::Text::ANSITable::OldCompat::*> namespace, without the prefix. See
the L<ColorTheme> and an example existing color theme module like
L<ColorTheme::Text::ANSITable::Standard::Gradation> specification on how to
create a new border style.

=head2 show_header => BOOL (default: 1)

When drawing, whether to show header.

=head2 show_row_separator => INT (default: 2)

When drawing, whether to show separator lines between rows. The default (2) is
to only show separators drawn using C<add_row_separator()>. If you set this to
1, lines will be drawn after every data row. If you set this attribute to 0, no
lines will be drawn whatsoever.

=head2 cell_width => INT

Set width for all cells. Can be overriden by per-column C<width> style.

=head2 cell_height => INT

Set height for all cell. Can be overriden by per-row C<height> style.

=head2 cell_align => STR

Set (horizontal) alignment for all cells. Either C<left>, C<middle>, or
C<right>. Can be overriden by per-column/per-row/per-cell C<align> style.

=head2 cell_valign => STR

Set (horizontal) alignment for all cells. Either C<top>, C<middle>, or
C<bottom>. Can be overriden by per-column/per-row/per-cell C<align> style.

=head2 cell_pad => INT

Set (horizontal) padding for all cells. Can be overriden by per-column C<pad>
style.

=head2 cell_lpad => INT

Set left padding for all cells. Overrides the C<cell_pad> attribute. Can be
overriden by per-column C<lpad> style.

=head2 cell_rpad => INT

Set right padding for all cells. Overrides the C<cell_pad> attribute. Can be
overriden by per-column C<rpad> style.

=head2 cell_vpad => INT

Set vertical padding for all cells. Can be overriden by per-row C<vpad> style.

=head2 cell_tpad => INT

Set top padding for all cells. Overrides the C<cell_vpad> attribute. Can be
overriden by per-row C<tpad> style.

=head2 cell_bpad => INT

Set bottom padding for all cells. Overrides the C<cell_vpad> attribute. Can be
overriden by per-row C<bpad> style.

=head2 cell_fgcolor => RGB|CODE

Set foreground color for all cells. Value should be 6-hexdigit RGB. Can also be
a coderef that will receive %args (e.g. rownum, col_name, colnum) and should
return an RGB color. Can be overriden by per-cell C<fgcolor> style.

=head2 cell_bgcolor => RGB|CODE

Like C<cell_fgcolor> but for background color.

=head2 header_fgcolor => RGB|CODE

Set foreground color for all headers. Overrides C<cell_fgcolor> for headers.
Value should be a 6-hexdigit RGB. Can also be a coderef that will receive %args
(e.g. col_name, colnum) and should return an RGB color.

=head2 header_bgcolor => RGB|CODE

Like C<header_fgcolor> but for background color.

=head2 header_align => STR

=head2 header_valign => STR

=head2 header_vpad => INT

=head2 header_tpad => INT

=head2 header_bpad => INT

=head1 METHODS

=head2 $t = Text::ANSITable->new(%attrs) => OBJ

Constructor.

=head2 $t->list_border_styles => LIST

Return the names of available border styles. Border styles will be searched in
C<BorderStyle::*> modules.

=head2 $t->list_color_themes => LIST

Return the names of available color themes. Color themes will be searched in
C<ColorTheme::*> modules.

=head2 $t->list_style_sets => LIST

Return the names of available style sets. Style set names are retrieved by
listing modules under C<Text::ANSITable::StyleSet::*> namespace.

=head2 $t->get_border_style($name) => HASH

Can also be called as a static method: C<<
Text::ANSITable->get_border_style($name) >>.

=head2 $t->get_color_theme($name) => HASH

Can also be called as a static method: C<<
Text::ANSITable->get_color_theme($name) >>.

=head2 $t->add_row(\@row[, \%styles]) => OBJ

Add a row. Note that row data is not copied, only referenced.

Can also add per-row styles (which can also be done using C<row_style()>).

=head2 $t->add_rows(\@rows[, \%styles]) => OBJ

Add multiple rows. Note that row data is not copied, only referenced.

Can also add per-row styles (which can also be done using C<row_style()>).

=head2 $t->add_row_separator() => OBJ

Add a row separator line.

=head2 $t->get_cell($rownum, $col) => VAL

Get cell value at row #C<$rownum> (starts from zero) and column named/numbered
C<$col>.

=head2 $t->set_cell($rownum, $col, $newval) => VAL

Set cell value at row #C<$rownum> (starts from zero) and column named/numbered
C<$col>. Return old value.

=head2 $t->get_column_style($col, $style) => VAL

Get per-column style for column named/numbered C<$col>.

=head2 $t->set_column_style($col, $style=>$val[, $style2=>$val2, ...])

Set per-column style(s) for column named/numbered C<$col>. Available values for
C<$style>: C<align>, C<valign>, C<pad>, C<lpad>, C<rpad>, C<width>, C<formats>,
C<fgcolor>, C<bgcolor>, C<type>, C<wrap>.

=head2 $t->get_cond_column_styles => ARRAY

Get all the conditional column styles set so far.

=head2 $t->add_cond_column_style($cond, $style=>$val[, $style2=>$val2 ...])

Add a new conditional column style. See L</"CONDITIONAL STYLES"> for more
details on conditional style.

=for comment | =head2 $t->clear_cond_column_styles | Clear all the conditional column styles.

=head2 $t->get_eff_column_style($col, $style) => VAL

Get "effective" column style named C<$style> for a particular column. Effective
column style is calculated from all the conditional column styles and the
per-column styles then merged together. This is the per-column style actually
applied.

=head2 $t->get_row_style($rownum) => VAL

Get per-row style for row numbered C<$rownum>.

=head2 $t->set_row_style($rownum, $style=>$newval[, $style2=>$newval2, ...])

Set per-row style(s) for row numbered C<$rownum>. Available values for
C<$style>: C<align>, C<valign>, C<height>, C<vpad>, C<tpad>, C<bpad>,
C<fgcolor>, C<bgcolor>.

=head2 $t->get_cond_row_styles => ARRAY

Get all the conditional row styles set so far.

=head2 $t->add_cond_row_style($cond, $style=>$val[, $style2=>$val2 ...])

Add a new conditional row style. See L</"CONDITIONAL STYLES"> for more details
on conditional style.

=for comment | =head2 $t->clear_cond_row_styles | Clear all the conditional row styles.

=head2 $t->get_eff_row_style($rownum, $style) => VAL

Get "effective" row style named C<$style> for a particular row. Effective row
style is calculated from all the conditional row styles and the per-row styles
then merged together. This is the per-row style actually applied.

=head2 $t->get_cell_style($rownum, $col, $style) => VAL

Get per-cell style named C<$style> for a particular cell. Return undef if there
is no per-cell style with that name.

=head2 $t->set_cell_style($rownum, $col, $style=>$newval[, $style2=>$newval2, ...])

Set per-cell style(s). Available values for C<$style>: C<align>, C<valign>,
C<formats>, C<fgcolor>, C<bgcolor>.

=head2 $t->get_cond_cell_styles => ARRAY

Get all the conditional cell styles set so far.

=head2 $t->add_cond_cell_style($cond, $style=>$val[, $style2=>$val2 ...])

Add a new conditional cell style. See L</"CONDITIONAL STYLES"> for more details
on conditional style.

=for comment | =head2 $t->clear_cond_cell_styles | Clear all the conditional cell styles.

=head2 $t->get_eff_cell_style($rownum, $col, $style) => VAL

Get "effective" cell style named C<$style> for a particular cell. Effective cell
style is calculated from all the conditional cell styles and the per-cell styles
then merged together. This is the per-cell style actually applied.

=head2 $t->apply_style_set($name, %args)

Apply a style set. See L</"STYLE SETS"> for more details.

=head2 $t->draw => STR

Render table.

=head1 FAQ

=head2 General

=head3 I don't see my data!

This might be caused by you not defining columns first, e.g.:

 my $t = Text::ANSITable->new;
 $t->add_row([1,2,3]);
 print $t->draw;

You need to do this first before adding rows:

 $t->columns(["col1", "col2", "col3"]);

=head3 All the rows are the same!

 my $t = Text::ANSITable->new;
 $t->columns(["col"]);
 my @row;
 for (1..3) {
     @row = ($_);
     $t->add_row(\@row);
 }
 print $t->draw;

will print:

 col
 3
 3
 3

You need to add row in this way instead of adding the same reference everytime:

     $t->add_row([@row]);

=head3 Output is too fancy! I just want to generate some plain (Text::ASCIITable-like) output to be copy-pasted to my document.

 $t->use_utf8(0);
 $t->use_box_chars(0);
 $t->use_color(0);
 $t->border_style('ASCII::SingleLine');

and you're good to go. Alternatively you can set environment UTF8=0,
BOX_CHARS=0, COLOR=0, and ANSITABLE_BORDER_STYLE=ASCII::SingleLine.

=head3 Why am I getting 'Wide character in print' warning?

You are probably using a utf8 border style, and you haven't done something like
this to your output:

 binmode(STDOUT, ":utf8");

=head3 My table looks garbled when viewed through pager like B<less>!

That's because B<less> by default escapes ANSI color and box_char codes. Try
using C<-R> option of B<less> to display ANSI color codes raw.

Or, try not using colors and box_char border styles:

 $t->use_color(0);
 $t->use_box_chars(0);

Note that as of this writing, B<less -R> does not interpret box_char codes so
you'll need to avoid using box_char border styles if you want your output to
display properly under B<less>.

=head3 How do I hide some columns/rows when drawing?

Use the C<column_filter> and C<row_filter> attributes. For example, given this
table:

 my $t = Text::ANSITable->new;
 $t->columns([qw/one two three/]);
 $t->add_row([$_, $_, $_]) for 1..10;

Doing this:

 $t->row_filter([0, 1, 4]);
 print $t->draw;

will show:

  one | two | three
 -----+-----+-------
    1 |   1 |     1
    2 |   2 |     2
    5 |   5 |     5

Doing this:

 $t->row_filter(sub { my ($row, $idx) = @_; $row->[0] % 2 }

will display:

  one | two | three
 -----+-----+-------
    1 |   1 |     1
    3 |   3 |     3
    5 |   5 |     5
    7 |   7 |     7
    9 |   9 |     9

Doing this:

 $t->column_filter([qw/two one 0/]);

will display:

  two | one | one
 -----+-----+-----
    1 |   1 |   1
    2 |   2 |   2
    3 |   3 |   3
    4 |   4 |   4
    5 |   5 |   5
    6 |   6 |   6
    7 |   7 |   7
    8 |   8 |   8
    9 |   9 |   9
   10 |  10 |  10

Doing this:

 $t->column_filter(sub { my ($colname, $idx) = @_; $colname =~ /t/ });

will display:

  two | three
 -----+-------
    1 |     1
    2 |     2
    3 |     3
    4 |     4
    5 |     5
    6 |     6
    7 |     7
    8 |     8
    9 |     9
   10 |    10

=head2 Formatting data

=head3 How do I format data?

Use the C<formats> per-column style or per-cell style. For example:

 $t->set_column_style('available', formats => [[bool=>{style=>'check_cross'}],
                                               [centerpad=>{width=>10}]]);
 $t->set_column_style('amount'   , formats => [[num=>{decimal_digits=>2}]]);
 $t->set_column_style('size'     , formats => [[num=>{style=>'kilo'}]]);

See L<Data::Unixish::Apply> and L<Data::Unixish> for more details on the
available formatting functions.

=head3 How does the module determine column data type?

Currently: if column name has the word C<date> or C<time> in it, the column is
assumed to contain B<date> data. If column name has C<?> in it, the column is
assumed to be B<bool>. If a column contains only numbers (or undefs), it is
B<num>. Otherwise, it is B<str>.

=head3 How does the module format data types?

Currently: B<num> will be right aligned and applied C<num_data> color (cyan in
the default theme). B<date> will be centered and applied C<date_data> color
(gold in the default theme). B<bool> will be centered and formatted as
check/cross symbol and applied C<bool_data> color (red/green depending on
whether the data is false/true). B<str> will be applied C<str_data> color (no
color in the default theme).

Other color themes might use different colors.

=head3 How do I force column to be of a certain data type?

For example, you have a column named C<deleted> but want to display it as
B<bool>. You can do:

 $t->set_column_style(deleted => type => 'bool');

=head3 How do I wrap long text?

The C<wrap> dux function can be used to wrap text (see: L<Data::Unixish::wrap>).
You'll want to set C<ansi> and C<mb> both to 1 to handle ANSI escape codes and
wide characters in your text (unless you are sure that your text does not
contain those):

 $t->set_column_style('description', formats=>[[wrap => {width=>60, ansi=>1, mb=>1}]]);

=head3 How do I highlight text with color?

The C<ansi::highlight> dux function can be used to highlight text (see:
L<Data::Unixish::ANSI::highlight>).

 $t->set_column_style(2, formats => [[highlight => {pattern=>$pat}]]);

=head3 I want to change the default bool cross/check sign representation!

By default, bool columns are shown as cross/check sign. This can be changed,
e.g.:

 $t->set_column_style($colname, type    => 'bool',
                                formats => [[bool => {style=>"Y_N"}]]);

See L<Data::Unixish::bool> for more details.

=head3 How do I do conditional cell formatting?

There are several ways.

First, you can use the C<cond> dux function through C<formats> style. For
example, if the cell contains the string "Cuti", you want to color the cell
yellow. Otherwise, you want to color the cell red:

 $t->set_column_style($colname, formats => [
     [cond => {
         if   => sub { $_ =~ /Cuti/ },
         then => ["ansi::color", {color=>"yellow"}],
         else => ["ansi::color", {color=>"red"}],
     }]
 ]);

Another way is to use the C<add_cond_{cell,row,column}> methods. See
L</"CONDITIONAL STYLES"> for more details. An example:

 $t->add_cond_row_style(sub {
     my %args = @_;
     $args{colname} =~ /Cuti/ ? {bgcolor=>"ffff00"} : {bgcolor=>"ff0000"};
 });

And another way is to use (or create) style set, which is basically a packaging
of the above ways. An advantage of using style set is, because you do not
specify coderef directly, you can specify it from the environment variable. See
L</"STYLE SETS"> for more details.

=head2 Border

=head3 How to hide borders?

There is currently no C<show_border> attribute. Choose border styles like
C<ASCII::Space>, C<ASCII::None>, C<UTF8::None>:

 $t->border_style("UTF8::None");

=head3 Why are there 'ASCII::None' as well 'UTF8::None' and 'BoxChar::None' border styles?

Because of the row separator, that can still be drawn if C<add_row_separator()>
is used. See next question.

=head3 I want to hide borders, and I do not want row separators to be shown!

The default is for separator lines to be drawn if drawn using
C<add_row_separator()>, e.g.:

 $t->add_row(['row1']);
 $t->add_row(['row2']);
 $t->add_row_separator;
 $t->add_row(['row3']);

The result will be:

   row1
   row2
 --------
   row3

However, if you set C<show_row_separator> to 0, no separator lines will be drawn
whatsoever:

   row1
   row2
   row3

=head3 I want to separate each row with a line!

Set C<show_row_separator> to 1, or alternatively, set
C<ANSITABLE_STYLE='{"show_row_separator":1}>.

=head2 Color

=head3 How to disable colors?

Set C<use_color> attribute or C<COLOR> environment to 0.

=head3 How to specify colors using names (e.g. red, 'navy blue') instead of RGB?

Use modules like L<Graphics::ColorNames>.

=head3 I'm not seeing colors when output is piped (e.g. to a pager)!

The default is to disable colors when (-t STDOUT) is false. You can force-enable
colors by setting C<use_color> attribute or C<COLOR> environment to 1.

=head3 How to enable 256 colors? I'm seeing only 16 colors.

Use terminal emulators that support 256 colors, e.g. Konsole, xterm,
gnome-terminal, PuTTY/pterm (but the last one has minimal Unicode support).
Better yet, use Konsole or Konsole-based emulators which supports 24bit colors.

=head3 How to enable 24bit colors (true color)?

Currently only B<Konsole> and the Konsole-based B<Yakuake> terminal emulator
software support 24bit colors.

=head3 How to force lower color depth? (e.g. I use Konsole but want 16 colors)

Set C<COLOR_DEPTH> to 16.

=head3 How to change border gradation color?

The default color theme applies vertical color gradation to borders from white
(ffffff) to gray (444444). To change this, set C<border1> and C<border2> theme
arguments:

 $t->color_theme_args({border1=>'ff0000', border2=>'00ff00'}); # red to green

=head3 I'm using terminal emulator with white background, the texts are not very visible!

Try using the "*_whitebg" themes, as the other themes are geared towards
terminal emulators with black background.

=head3 How to set different background colors for odd/even rows?

Aside from doing C<< $t->set_row_style($rownum, bgcolor=>...) >> for each row,
you can also do this:

 $t->cell_bgcolor(sub { my ($self, %args) = @_; $args{rownum} % 2 ? '202020' : undef });

Or, you can use conditional row styles:

 $t->add_cond_row_style(sub { $_ % 2 }, {bgcolor=>'202020'});

Or, you can use the L<Text::ANSITable::StyleSet::AltRow> style set:

 $t->apply_style_set(AltRow => {even_bgcolor=>'202020'});

=head1 ENVIRONMENT

=head2 COLOR => BOOL

Can be used to set default value for the C<color> attribute.

=head2 COLOR_DEPTH => INT

Can be used to set default value for the C<color_depth> attribute.

=head2 BOX_CHARS => BOOL

Can be used to set default value for the C<box_chars> attribute.

=head2 UTF8 => BOOL

Can be used to set default value for the C<utf8> attribute.

=head2 COLUMNS => INT

Can be used to override terminal width detection.

=head2 ANSITABLE_BORDER_STYLE => STR

Can be used to set default value for C<border_style> attribute. Takes precedence
over L<BORDER_STYLE>.

=head2 BORDER_STYLE => STR

Can be used to set default value for C<border_style> attribute. See also
C<ANSITABLE_BORDER_STYLE>.

=head2 ANSITABLE_COLOR_THEME => STR

Can be used to set default value for C<border_style> attribute.

=head2 ANSITABLE_STYLE => str(json)

Can be used to set table's most attributes. Value should be a JSON-encoded hash
of C<< attr => val >> pairs. Example:

 % ANSITABLE_STYLE='{"show_row_separator":1}' ansitable-list-border-styles

will display table with row separator lines after every row.

=head2 WRAP => BOOL

Can be used to set default value for the C<wrap> column style.

=head2 ANSITABLE_COLUMN_STYLES => str(json)

Can be used to set per-column styles. Interpreted right before draw(). Value
should be a JSON-encoded hash of C<< col => {style => val, ...} >> pairs.
Example:

 % ANSITABLE_COLUMN_STYLES='{"2":{"type":"num"},"3":{"type":"str"}}' ansitable-list-border-styles

will display the bool columns as num and str instead.

=head2 ANSITABLE_ROW_STYLES => str(json)

Can be used to set per-row styles. Interpreted right before draw(). Value should
be a JSON-encoded a hash of C<< rownum => {style => val, ...} >> pairs.
Example:

 % ANSITABLE_ROW_STYLES='{"0":{"bgcolor":"000080","vpad":1}}' ansitable-list-border-styles

will display the first row with blue background color and taller height.

=head2 ANSITABLE_CELL_STYLES => str(json)

Can be used to set per-cell styles. Interpreted right before draw(). Value
should be a JSON-encoded a hash of C<< "rownum,col" => {style => val, ...} >>
pairs. Example:

 % ANSITABLE_CELL_STYLES='{"1,1":{"bgcolor":"008000"}}' ansitable-list-border-styles

will display the second-on-the-left, second-on-the-top cell with green
background color.

=head2 ANSITABLE_STYLE_SETS => str(json)

Can be used to apply style sets. Value should be a JSON-encoded array. Each
element must be a style set name or a 2-element array containing style set name
and its arguments (C<< [$name, \%args] >>). Example:

 % ANSITABLE_STYLE_SETS='[["AltRow",{"odd_bgcolor":"003300"}]]'

will display table with row separator lines after every row.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSITable>.

=head1 SEE ALSO

=head2 Border styles

For collections of border styles, search for C<BorderStyle::*> modules.

=head2 Color themes

For collections of color themes, search for C<ColorTheme::*> modules.

=head2 Other table-formatting CPAN modules

L<Text::ASCIITable> is one of the most popular table-formatting modules on CPAN.
There are a couple of "extensions" for Text::ASCIITable:
L<Text::ASCIITable::TW>, L<Text::ASCIITable::Wrap>; Text::ANSITable can be an
alternative for all those modules since it can already handle wide-characters as
well as multiline text in cells.

L<Text::TabularDisplay>

L<Text::Table>

L<Text::SimpleTable>

L<Text::UnicodeTable::Simple>

L<Table::Simple>

L<Acme::CPANModules::TextTable> catalogs text table modules.

=head2 Front-ends

L<Text::Table::Any> and its CLI L<texttable> can use Text::ANSITable as one of
the backends.

=head2 Other related modules

L<App::TextTableUtils> includes utilities like L<csv2ansitable> or
L<json2ansitable> which can convert a CSV or array-of-array structure to a table
rendered using Text::ANSITable.

=head2 Other

Unix command B<column> (e.g. C<column -t>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Mario Zieschang Steven Haryanto

=over 4

=item *

Mario Zieschang <mario@zieschang.info>

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=back

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
