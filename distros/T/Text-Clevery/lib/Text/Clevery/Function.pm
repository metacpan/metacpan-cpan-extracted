package Text::Clevery::Function;
use strict;
use warnings;

use parent qw(Text::Xslate::Bridge);

use Any::Moose '::Util::TypeConstraints';
use File::Spec;

use Scalar::Util qw(
    blessed
    looks_like_number
);

use Text::Xslate::Util qw(
    p any_in literal_to_value
    mark_raw html_escape
    $STRING
);

use Text::Clevery::Util qw(
    safe_join safe_cat
    make_tag
    true false
    ceil floor
);

my $Bool       = subtype __PACKAGE__ . '.Bool',  as 'Bool';
my $Str        = subtype __PACKAGE__ . '.Str',   as 'Str|Object';
my $Int        = subtype __PACKAGE__ . '.Int',   as 'Int';
my $Array      = subtype __PACKAGE__ . '.Array', as 'ArrayRef';
my $ListLike   = subtype __PACKAGE__ . '.List',  as "$Array|$Str";
my $AssocArray = subtype __PACKAGE__ . '.AssocArray', as 'ArrayRef|HashRef';

require Text::Clevery;
our $EngineClass = 'Text::Clevery';

# Implemented as statements:
# {capture}, {foreach}, {literal}, {section}, {strip}
# {include}
my %function = map { $_ => __PACKAGE__->can($_) || _make_not_impl($_) } qw(
    config_load
    include_php
    insert

    assign
    counter
    cycle
    debug
    eval
    fetch
    html_checkboxes
    html_image
    html_options
    html_radios
    html_select_date
    html_select_time
    html_table
    mailto
    math
    popup
    pupup_init
    textformat
);
__PACKAGE__->bridge(function => \%function);

sub _make_not_impl {
    my($name) = @_;
    return sub { die "Function {$name} is not implemented.\n" };
}

sub _required {
    my($name, $level) = @_;
    my $function = (caller($level ? $level + 1 : 1))[3];
    Carp::croak("Required: '$name' attribute for $function");
}

sub _bad_param {
    my($type, $name, $value) = @_;
    Carp::croak("InvalidValue for '$name': " . $type->get_message($value));
}

sub _parse_args {
    my $args = shift;
    if(@_ % 5) {
        Carp::croak("Oops: " . p(@_));
    }
    while(my($name, $var_ref, $type, $required, $default) = splice @_, 0, 5) {
        if(defined $args->{$name}) {
            my $value = delete $args->{$name};
            $type->check($value)
                or _bad_param($type, $name, $value);
            ${$var_ref} = $value;
        }
        elsif($required){
            _required($name, 1);
        }
        else {
            ${$var_ref} = $default;
        }
    }
    return if keys(%{$args}) == 0;

    if(defined wantarray) {
        return map { $_ => $args->{$_} } sort keys %{$args};
    }
    else {
        if(%{$args}) {
            my $name = (caller 0)[3];
            warnings::warn(misc => "$name: Unknown option(s): "
                . join ", ", sort keys %{$args});
        }
    }
}

sub config_load {
    _parse_args(
        {@_},
        file    => \my $file,    $Str, true,   undef,
        section => \my $section, $Str, false,  undef,
        scope   => \my $scope,   $Str, false, 'local', # or 'parent', 'global'
    );

    require Config::Tiny;
    my $c = Config::Tiny->read($file)
        || Carp::croak(Config::Tiny->errstr);

    my %config;

    my $root = defined($section)
        ? $config{$section} ||= {}
        : \%config;

    while(my($section_name, $section_config) = each %{$c}) {
        my $storage = $section_name eq '_'
            ?  $root
            : ($config{$section_name} ||= {});

        while(my($key, $literal) = each %{$section_config}) {
            $storage->{$key} = literal_to_value($literal);
        }
    }

    my $context = $EngineClass->get_current_context;
    my $top     = $context->_storage->{config} ||= {
        '@global' => {}, # prototype of all the config storages
    };

    if($scope eq 'local') {
        my $this = $context->config;
        %{$this} = (%{$this}, %config);
    }
    else { # TODO: distingwish between 'global' and 'parent'
        require Storable;
        foreach my $this(values %{$top}) {
            %{$this} = (%{$this}, %{ Storable::dclone(\%config) });
        }
    }

    return '';
}

#sub php; # never implemented!
#sub strip

#sub assign

sub counter {
    _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      $Str,      false, 'default',
        start     => \my $start,     $Int,      false,  undef,
        skip      => \my $skip,      $Int,      false,  undef,
        direction => \my $direction, $Str,      false, 'up', # or 'down'
        print     => \my $print,     $Bool,     false, true,
        assign    => \my $assign,    $Str,      false, undef,
    );

    my $storage = $EngineClass->get_current_context->_storage;
    my $this    = $storage->{counter}{$name} ||= {
        count  => defined($start) ? $start : 1,
        skip   => defined($skip)  ? $skip  : 1,
    };

    if($assign) {
        die "cycle: 'assign' is not supported";
    }

    my $retval = $print ? $this->{count} : '';

    if($direction eq 'up') {
        $this->{count} += $this->{skip};
    }
    else {
        $this->{count} -= $this->{skip};
    }

    return $retval;
}

sub cycle {
    _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      $Str,      false, 'default',
        values    => \my $values,    $ListLike, false,  undef,
        print     => \my $print,     $Bool,     false, true,
        advance   => \my $advance,   $Bool,     false, true,
        delimiter => \my $delimiter, $Str,      false, ',',
        assign    => \my $assign,    $Str,      false, undef,
        reset     => \my $reset,     $Bool,     false, false,
    );

    my $storage = $EngineClass->get_current_context->_storage;
    my $this    = $storage->{cycle}{$name} ||= {
        values => [],
        index  => 0,
    };

    if(defined $values) {
        if(ref($values) eq 'ARRAY') {
            @{$this->{values}} = @{$values};
        }
        else {
            @{$this->{values}} = (split /$delimiter/, $values);
            $values = $this->{values};
        }
    }
    else {
        $values = $this->{values};
    }

    if(!@{$values}) {
        _required('values');
    }

    if($reset) {
        $this->{index} = 0;
    }

    if($assign) {
        die "cycle: 'assign' is not supported";
    }

    my $retval = $print
        ? $values->[$this->{index}]
        : '';

    if($advance) {
        if(++$this->{index} >= @{$values}) {
            $this->{index} = 0;
        }
    }

    return $retval;
}

#sub debug
#sub eval
#sub fetch

sub _split_assoc_array {
    my($assoc) = @_;
    my @keys;
    my @values;
    if(ref $assoc eq 'HASH') {
        foreach my $key(sort keys %{$assoc}) {
            push @keys,   $key;
            push @values, $assoc->{$key};
        }
    }
    else {
        foreach my $pair(@{$assoc}) {
            push @keys,   $pair->[0];
            push @values, $pair->[1];
        }
    }
    return(\@keys, \@values);
}

sub html_checkboxes {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      $Str,        false, 'checkbox',
        values    => \my $values,    $Array,      undef, undef,
        output    => \my $output,    $Array,      undef, undef,
        selected  => \my $selected,  $ListLike,   false, [],
        options   => \my $options,   $AssocArray, undef, undef,
        separator => \my $separator, $Str,        false, q{},
        labels    => \my $labels,    $Bool,       false, true,
    );

    if(defined $options) {
        ($values, $output) = _split_assoc_array($options);
    }
    else {
        $values or _required('values');
        $output or _required('output');
    }

    if(ref $selected ne 'ARRAY') {
        $selected = [$selected];
    }

    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];

        my $input = safe_cat(make_tag(
                input => undef,
                type  => 'checkbox',
                name  => $name,
                value => $value,
                any_in($value, @{$selected}) ? (checked => 'checked') : (),
                @extra,
            ), html_escape($output->[$i])),
        ;

        $input = make_tag(label => $input) if $labels;

        push @result, safe_cat( $input, $separator);
    }
    return safe_join("\n", @result);
}

sub html_image {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        file    => \my $file,    $Str, true,  undef,
        height  => \my $height,  $Str, false, undef,
        width   => \my $width,   $Str, false, undef,
        basedir => \my $basedir, $Str, false, q{},
        alt     => \my $alt,     $Str, false, q{},
        href    => \my $href,    $Str, false, undef,
        path_prefix
                => \my $path_prefix, $Str, false, '',
    );


    if(!(defined $height and defined $width)) {
        eval {
            require Image::Size;
            if($file =~ m{\A /}xms) {
                my $env = $EngineClass->get_current_context->env;
                $basedir = $env->{DOCUMENT_ROOT} || '.';
            }
            my $image_path = File::Spec->catfile($basedir, $file);
            # it returns (undef, undef, $status_message) on fails
            ($width, $height) = Image::Size::imgsize($image_path);
        };
    }

    my $img = make_tag(
        img    => undef,
        src    => $path_prefix . $file,
        alt    => $alt,
        width  => $width,
        height => $height,
        @extra,
    );
    if(defined $href) {
        $img = make_tag(a => $img, href => $href);
    }
    return $img;
}

sub _build_options {
    my($values, $labels, $selected) = @_;
    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];
        my $label = $labels->[$i];

        if(!(ref($label) eq 'ARRAY' or ref($label) eq 'HASH')) {
            push @result, make_tag(
                option => $label,
                # label => $label,
                value  => $value,
                (any_in($value, @{$selected}) ? (selected => 'selected') : ()),
            );
        }
        else {
            my($v, $l) = _split_assoc_array($label);
            my @group = _build_options($v, $l, $selected);
            push @result, make_tag(
                optgroup => safe_join("\n", "", @group, ""),
                label    => $value,
            );

        }
    }
    return @result;
}

sub html_options {
    my @extra = _parse_args(
        {@_},
        values   => \my $values,   $Array,      undef, undef,
        output   => \my $output,   $Array,      undef, undef,
        selected => \my $selected, $ListLike,   false, [],
        options  => \my $options,  $AssocArray, undef, undef,
        name     => \my $name,     $Str,        false, undef,
    );

    if(defined $options) {
        ($values, $output) = _split_assoc_array($options);
    }
    else {
        $values or _required('values');
        $output or _required('output');
    }

    if(ref $selected ne 'ARRAY') {
        $selected = [$selected];
    }

    my @result = _build_options($values, $output, $selected);

    if(defined $name) {
        return make_tag(
            select => safe_join("\n", '', @result, ''),
            name   => $name,
            @extra,
        );
    }
    else {
        return safe_join("\n", @result);
    }
}

sub html_radios {
    my @extra = _parse_args(
        {@_},
        name      => \my $name,      $Str,        false, "radio",
        values    => \my $values,    $Array,      undef, undef,
        output    => \my $output,    $Array,      undef, undef,
        selected  => \my $selected,  $Str,        false, q{},
        options   => \my $options,   $AssocArray, undef, undef,
        separator => \my $separator, $Str,        false, q{},
        assign    => \my $assign,    $Str,        false, q{},
    );

    if(defined $options) {
        ($values, $output) = _split_assoc_array($options);
    }
    else {
        $values or _required('values');
        $output or _required('output');
    }

    if($assign) {
        die 'html_radios: "assign" is not supported';
    }

    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];
        my $label = $output->[$i];

        my $id = safe_join '_', $name, $value;

        my $radio = safe_cat make_tag(
            input  => undef,
            type   => 'radio',
            name   => $name,
            value  => $value,
            id     => $id,
            ($selected eq $value ? (checked => 'checked') : ()),
            @extra,
        ), $label;
        $radio = make_tag(label => $radio, for   => $id);
        if(length $separator) {
            $radio = safe_cat $radio, $separator;
        }

        push @result, $radio;
    }

    return safe_join "\n", @result;
}

sub _init_time_object {
    my($time) = @_;
    $time = time() if not defined $time;

    if(!(blessed($time) && $time->can('epoch'))) {
        if(looks_like_number($time)) {
            $time = Time::Piece->new($time);
        }
        else {
            # YYY-MM-DD HH:MM:SS style timestamp
            $time = Time::Piece->strptime($time, q{%Y-%m-%d %H:%M:%S});
        }
    }
    return $time;
}

sub _deparse_html_attr {
    my($attr) = @_;
    return if not $attr;

    my($name, $value) = $attr =~ m{
        (\w+) = (\w+ | $STRING)
    }xms or return;

    if($value =~ /\A " (.*) " \z/xms) {
        $value = $1;
    }
    elsif($value =~ /\A ' (.*) ' \z/xms) {
        $value = $1;
    }
    $value =~ s/"/&quot;/g; # ensure " is gone
    $value =~ s/'/&apos;/g; # ensure ' is gone
    return mark_raw($name) => mark_raw($value);
}

sub _build_datetime_options {
    my($field_array, $prefix, $moniker,
       $empty, $values_ref, $names_ref, $selected,
       @extra) = @_;

    my $name = defined($field_array)
        ? safe_cat( $field_array, '[', $prefix, $moniker, ']')
        : safe_cat( $prefix, $moniker);

    if(defined $empty) {
        $names_ref  = [$empty, @{$names_ref}];
        $values_ref = [q{},    @{$values_ref}];
    }

    my $options = html_options(
        values   => $values_ref,
        output   => $names_ref,
        selected => $selected,
    );
    return make_tag(
        select => safe_cat("\n", $options, "\n"),
        name   => $name,

        map { _deparse_html_attr($_) } @extra,
    );
}

sub html_select_date {
    _parse_args(
        {@_},
        prefix             => \my $prefix,             $Str,  false, 'Date_',
        time               => \my $time,               $Str,  false, undef,
        start_year         => \my $start_year,         $Str,  false, undef,
        end_year           => \my $end_year,           $Str,  false, undef,

        display_days       => \my $display_days,       $Bool, false, true,
        display_months     => \my $display_months,     $Bool, false, true,
        display_years      => \my $display_years,      $Bool, false, true,

        month_format       => \my $month_format,       $Str,  false, '%B',   # for strftime
        month_value_format => \my $month_value_format, $Str,  false, '%m',   # for strftime
        day_format         => \my $day_format,         $Str,  false, '%02d', # for sprintf
        day_value_format   => \my $day_value_format,   $Str,  false, '%d',   # for sprintf

        year_as_text       => \my $year_as_text,       $Bool, false, false,
        reverse_years      => \my $reverse_years,      $Bool, false, false,
        field_array        => \my $field_array,        $Str,  false, undef,

        day_size           => \my $day_size,           $Int,  false, undef,
        month_size         => \my $month_size,         $Int,  false, undef,
        year_size          => \my $year_size,          $Int,  false, undef,

        all_extra          => \my $all_extra,          $Str,  false, undef,
        day_extra          => \my $day_extra,          $Str,  false, undef,
        month_extra        => \my $month_extra,        $Str,  false, undef,
        year_extra         => \my $year_extra,         $Str,  false, undef,

        year_empty         => \my $year_empty,         $Str,  false, undef,
        month_empty        => \my $month_empty,        $Str,  false, undef,
        day_empty          => \my $day_empty,          $Str,  false, undef,

        field_order        => \my $field_order,        $Str,  false, 'MDY',
        field_separator    => \my $field_separator,    $Str,  false, "\n",
    );

    require Time::Piece;

    # complex default values
    $time = _init_time_object($time);

    if(not defined $start_year) {
        $start_year = $time->year;
    }
    elsif($start_year =~ /\A [+-]/xms) {
        $start_year = $time->year + $start_year; # relative
    }

    if(not defined $end_year) {
        $end_year = $start_year;
    }
    elsif($end_year =~ /\A [+-]/xms) {
        $end_year = $time->year + $end_year; # relative
    }
    # build HTML
    my %result;

    if($display_months) {
        my @names;
        my @values;
        for my $m(1 .. 12) {
            my $t = Time::Piece->strptime($m, '%m');
            push @names,  $t->strftime($month_format);
            push @values, $t->strftime($month_value_format);
        }
        $result{M} = _build_datetime_options(
            $field_array, $prefix, 'Month',
            $month_empty,
            \@values,
            \@names,
            $time->strftime($month_value_format),
            (defined $month_size ? qq{size='$month_size'} : ()),
            $all_extra,
            $month_extra,
        );
    }

    if($display_days) {
        my @days;
        my @dayvals;
        for my $d(1 .. 31) {
            push @days,    sprintf($day_format, $d);
            push @dayvals, sprintf($day_value_format, $d);
        }
        $result{D} = _build_datetime_options(
            $field_array, $prefix, 'Day',
            $month_empty,
            \@dayvals,
            \@days,
            sprintf($day_value_format, $time->mday), # day of month
            (defined $day_size ? qq{size='$day_size'} : ()),
            $all_extra,
            $day_extra,
        );
    }

    if($display_years) {
        my @years = ($start_year .. $end_year);
        if($reverse_years) {
            @years = reverse @years;
        }
        $result{Y} = _build_datetime_options(
            $field_array, $prefix, 'Year',
            $year_empty,
            \@years,
            \@years,
            $time->year,
            (defined $year_size ? qq{size='$year_size'} : ()),
            $all_extra,
            $year_extra,
        );
    }

    my @order = split //, uc $field_order;
    return safe_join $field_separator, grep { defined } @result{@order};
}

sub html_select_time {
    _parse_args(
        {@_},
        prefix             => \my $prefix,             $Str,  false, 'Time_',
        time               => \my $time,               $Str,  false, undef,

        display_hours      => \my $display_hours,      $Bool, false, true,
        display_minutes    => \my $display_minutes,    $Bool, false, true,
        display_seconds    => \my $display_seconds,    $Bool, false, true,
        display_meridian   => \my $display_meridian,   $Bool, false, true, # am/pm

        use_24_hours       => \my $use_24_hours,       $Bool, false, true,
        minute_interval    => \my $minute_interval,    $Int,  false, 1,
        second_interval    => \my $second_interval,    $Int,  false, 1,
        field_array        => \my $field_array,        $Str,  false, undef,

        all_extra          => \my $all_extra,          $Str,  false, undef,
        hour_extra         => \my $hour_extra,         $Str,  false, undef,
        minute_extra       => \my $minute_extra,       $Str,  false, undef,
        second_extra       => \my $second_extra,       $Str,  false, undef,
        meridian_exra      => \my $meridian_extra,     $Str,  false, undef,

        hour_empty         => \my $hour_empty,         $Str,  false, undef,
        minute_empty       => \my $minute_empty,       $Str,  false, undef,
        second_empty       => \my $second_empty,       $Str,  false, undef,
        meridian_empty     => \my $meridian_empty,     $Str,  false, undef,

        field_separator    => \my $field_separator,    $Str,  false, "\n",
    );

    require Time::Piece;

    # complex default values
    $time = _init_time_object($time);

    # build HTML
    my @result;
    if($display_hours) {
        my $hour_format = $use_24_hours ? '%H' : '%I';

        my @hours;
        for my $i($use_24_hours ? (0 .. 23) : (1 .. 12)) {
            push @hours, sprintf('%02d', $i);
        }
        push @result, _build_datetime_options(
            $field_array, $prefix, 'Hour',
            $hour_empty,
            \@hours,
            \@hours,
            $time->strftime($hour_format),
            $all_extra,
            $hour_extra,
        );
    }

    if($display_minutes) {
        my @minutes;
        for(my $i = 0; $i < 60; $i += $minute_interval) {
            push @minutes, sprintf('%02d', $i);
        }
        my $selected = sprintf '%02d',
            int($time->day_of_month / $minute_interval) * $minute_interval;

        push @result, _build_datetime_options(
            $field_array, $prefix, 'Minute',
            $minute_empty,
            \@minutes,
            \@minutes,
            $selected,
            $all_extra,
            $minute_extra,
        );
    }

    if($display_seconds) {
        my @seconds;
        for(my $i = 0; $i < 60; $i += $second_interval) {
            push @seconds, sprintf('%02d', $i);
        }

        my $selected = sprintf '%02d',
            int($time->second / $second_interval) * $second_interval;
        push @result, _build_datetime_options(
            $field_array, $prefix, 'Second',
            $second_empty,
            \@seconds,
            \@seconds,
            $selected,
            $all_extra,
            $second_extra,
        );
    }

    if($display_meridian && !$use_24_hours) {
        my $meridian_format = '%p';

        push @result, _build_datetime_options(
            $field_array, $prefix, 'Meridian',
            $meridian_empty,
            [qw(am pm)],
            [qw(AM PM)],
            lc($time->strftime($meridian_format)),
            $all_extra,
            $meridian_extra,
        );
    }

    return safe_join $field_separator, @result;
}

sub _html_table_attr {
    my($attrs, $n) = @_;
    return _deparse_html_attr(
        ref($attrs) eq 'ARRAY'
            ? $attrs->[ $n % @{$attrs} ] # cycle
            : $attrs
    );
}

sub html_table {
    _parse_args(
        {@_},
        loop       => \my $loop,       $Array,    true,  undef,
        cols       => \my $cols,       $ListLike, false, undef,
        rows       => \my $rows,       $Int,      false, undef,
        inner      => \my $inner,      $Str,      false, 'cols', # or 'rows'
        caption    => \my $caption,    $Str,      false, undef,
        table_attr => \my $table_attr, $Str,      false, q{border="1"},
        th_attr    => \my $th_attr,    $ListLike, false, undef,
        tr_attr    => \my $tr_attr,    $ListLike, false, undef,
        td_attr    => \my $td_attr,    $ListLike, false, undef,
        trailpad   => \my $trailpad,   $Str,      false, mark_raw('&nbsp;'),
        hdir       => \my $hdir,       $Str,      false, 'right', # or 'left'
        vdir       => \my $vdir,       $Str,      false, 'down',  # or 'up'
    );

    my $loop_count = @{$loop};

    my $cols_count;
    if(looks_like_number($cols)) {
        $cols_count = $cols;
        undef $cols;
    }
    elsif(ref $cols eq 'ARRAY') {
        $cols_count = @{$cols};
    }
    elsif(defined $cols){
        $cols       = [ split /,/, $cols ];
        $cols_count = @{$cols};
    }
    else {
        $cols_count = 3;
    }

    if(not defined $rows) {
        $rows = ceil($loop_count / $cols_count);
    }
    elsif(not defined $cols) {
        if(defined $rows) {
            $cols_count = ceil($loop_count / $rows);
        }
    }

    # build HTML
    my @table;
    if(defined $caption) {
        push @table, make_tag caption => $caption;
    }

    if(defined $cols) {
        if($hdir ne 'right') {
            $cols = [reverse @{$cols}];
        }
        my @h;
        for(my $r = 0; $r < $cols_count; $r++) {
            push @h, make_tag(th => $cols->[$r],
                _html_table_attr($th_attr, $r));
        }
        my $tr = make_tag(tr => safe_cat("\n", @h, "\n"));
        push @table, make_tag thead => safe_join("\n", '', $tr, '');
    }

    my @tbody;
    for(my $r = 0; $r < $rows; $r++) {
        my $rx = ($vdir eq 'down')
            ? $r * $cols_count
            : ($rows - 1 - $r) * $cols_count;

        my @d;
        for(my $c = 0; $c < $cols_count; $c++) {
            my $x = ($hdir eq 'right')
                ? $rx + $c
                : $rx + $cols_count - 1 - $c;
            if($inner ne 'cols') {
                $x = floor($x / $cols_count) + ($x % $cols_count) * $rows;
            }

            push @d, make_tag
                td => ($x < $loop_count ? $loop->[$x] : $trailpad),
                _html_table_attr($td_attr, $r);
        }

        push @tbody, make_tag(tr => safe_cat(@d),
            _html_table_attr($tr_attr, $r));
    }

    if(@tbody) {
        push @table, make_tag(tbody => safe_join "\n", '', @tbody, '');
    }
    return make_tag
        table => safe_join("\n", '', @table, ''),
        _deparse_html_attr($table_attr);
}

#sub mailto
#sub math
#sub popup
#sub popup_init
#sub textformat

no Any::Moose '::Util::TypeConstraints';
1;
__END__

=head1 NAME

Text::Clevery::Function - Smarty compatible template functions

=head1 FUNCTION

=head2 config_load

=head2 counter

=head2 cycle

=head2 html_checkboxes

=head2 html_image

=head2 html_options

=head2 html_radios

=head2 html_select_date

=head2 html_select_time

=head2 html_table

=head2 mailto

Not supported.

=head2 math

Not supported.

=head2 popup

Not supported.

=head2 popup_init

Not supported.

=head2 textformat

Not supported.

=head1 SEE ALSO

L<Text::Clevery>

=cut
