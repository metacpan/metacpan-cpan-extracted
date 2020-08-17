package Test2::Tools::EventDumper;
use strict;
use warnings;

our $VERSION = '0.000012';

use Carp qw/croak/;
use Scalar::Util qw/blessed reftype/;

our @EXPORT = qw/dump_event dump_events/;
use base 'Exporter';

my %QUOTE_MATCH = (
    '{' => '}',
    '(' => ')',
    '[' => ']',
    '/' => '/',
);

my %DEFAULTS = (
    qualify_functions    => 0,
    paren_functions      => 0,
    use_full_event_type  => 0,
    show_empty           => 0,
    add_line_numbers     => 0,
    call_when_can        => 1,
    convert_trace        => 1,
    shorten_single_field => 1,
    clean_fail_messages  => 1,

    field_order => {
        name           => 1,
        pass           => 2,
        effective_pass => 3,
        todo           => 4,
        max            => 5,
        directive      => 6,
        reason         => 7,
        trace          => 9999,
    },
    array_sort_order => 10000,
    other_sort_order => 9000,

    include_fields => undef,
    exclude_fields => {buffered => 1, nested => 1, in_subtest => 1, is_subtest => 1, subtest_id => 1, hubs => 1},

    indent_sequence => '    ',

    adjust_filename => \&adjust_filename,
);

sub adjust_filename {
    my $file = shift;
    $file =~ s{^.*[/\\]}{}g;
    return "match qr{\\Q$file\\E\$}";
}

sub dump_event {
    my ($event, %settings) = @_;

    croak "No event to dump"
        unless $event;

    croak "dump_event() requires a Test2::Event (or subclass) instance, Got: $event"
        unless blessed($event) && $event->isa('Test2::Event');

    my $settings = keys %settings ? parse_settings(\%settings) : \%DEFAULTS;

    my $out = do_event_dump($event, $settings);

    return finalize($out, $settings);
}

sub dump_events {
    my ($events, %settings) = @_;

    croak "No events to dump"
        unless $events;

    croak "dump_events() requires an array reference, Got: $events"
        unless reftype($events) eq 'ARRAY';

    croak "dump_events() requires an array reference of Test2::Event (or subclass) instances, some array elements are not Test2::Event instances"
        if grep { !$_ || !blessed($_) || !$_->isa('Test2::Event') } @$events;

    my $settings = keys %settings ? parse_settings(\%settings) : \%DEFAULTS;

    my $out = do_array_dump($events, $settings);

    return finalize($out, $settings);
}

sub finalize {
    my ($out, $settings) = @_;

    $out =~ s[(\s+)$][join '' => grep { $_ eq "\n" } split //, $1]msge;

    if ($settings->{add_line_numbers}) {
        my $line = 1;
        my $count = length( 0 + map { 1 } split /\n/, $out );
        $out =~ s/^/sprintf("L%0${count}i: ", $line++)/gmse;
        $out =~ s/^L\d+: $//gms;
    }

    return $out;
}

sub parse_settings {
    my $settings = shift;

    my %out;
    my %clone = %$settings;

    for my $field (qw/field_order include_fields exclude_fields/) {
        next unless exists  $clone{$field}; # Nothing to do.
        next unless defined $clone{$field}; # Do not modify an undef

        # Remove it from the clone
        my $order = delete $clone{$field};

        croak "settings field '$field' must be either an arrayref or hashref, got: $order"
            unless ref($order) =~ m/^(ARRAY|HASH)$/;

        my $count = 1;
        $out{$field} = ref($order) eq 'HASH' ? $order : {map { $_ => $count++ } @$order};
    }

    return {
        %DEFAULTS,
        %clone,
        %out,
    };
}

sub do_event_dump {
    my ($event, $settings) = @_;

    my ($ps, $pe) = ($settings->{qualify_functions} || $settings->{paren_functions}) ? ('(', ')') : (' ', '');
    my $qf = $settings->{qualify_functions} ? "Test2::Tools::Compare::" : "";

    my $start = "${qf}event${ps}" . render_event($event, $settings);

    my @fields = get_fields($event, $settings);

    my @rows = map { get_rows($event, $_, $settings) } @fields;
    shift @rows while @rows && !@{$rows[0]}; # Strip leading empty rows

    my $nest = "";
    if (@rows == 0) {
        $start .= " => {";
    }
    elsif (@rows == 1 && $settings->{shorten_single_field} && !$rows[0]->[3]) {
        $start .= " => {";
        my ($row) = @rows;
        $nest = quote_key($row->[1]) . " => $row->[2]";
    }
    else {
        $start .= " => sub {\n";

        for my $row (@rows) {
            unless (@$row) {
                $nest .= "\n";
                next;
            }

            my ($func, $field, $qval, $comment) = @$row;
            my $key = quote_key($field);
            $nest .= "${qf}${func}${ps}${key} => ${qval}${pe};";
            $nest .= " # $comment" if $comment;
            $nest .= "\n";
        }

        $nest =~ s/^/$settings->{indent_sequence}/mg;
    }

    return "${start}${nest}}${pe}";
}

sub do_array_dump {
    my ($array, $settings) = @_;

    my ($ps, $pe) = ($settings->{qualify_functions} || $settings->{paren_functions}) ? ('(sub ', ')') : (' ', '');
    my $qf = $settings->{qualify_functions} ? "Test2::Tools::Compare::" : "";

    my $out = "${qf}array${ps}\{\n";

    my $nest = "";
    my $not_first = 0;
    for my $event (@$array) {
        $nest .= "\n" if $not_first++;
        $nest .= do_event_dump($event, $settings) . ";\n"
    }
    $nest .= "${qf}end();\n";
    $nest =~ s/^/$settings->{indent_sequence}/mg;

    $out .= $nest;
    $out .= "}${pe}";

    return $out;
}

sub quote_val {
    my ($val, $settings) = @_;

    return 'undef' unless defined $val;

    return $val if $val =~ m/^\d+$/;

    return 'match qr{^\\n?Failed test}'
        if $settings->{clean_fail_messages} && $val =~ m/^\n?Failed test/;

    return quote_str(@_);
}

sub quote_key {
    my ($val, $settings) = @_;

    return $val if $val =~ m/^\d+$/;
    return $val if $val =~ m/^\w+$/;

    return quote_str(@_);
}

sub quote_str {
    my ($val, $settings) = @_;

    my $use_qq = 0;
    $use_qq = 1 if $val =~ s/\n/\\n/g;
    $use_qq = 1 if $val =~ s/\r/\\r/g;
    $use_qq = 1 if $val =~ s/[\b]/\\b/g;

    my @delims = ('"', grep {$QUOTE_MATCH{$_}} qw<{ ( [ />);
    unshift @delims => "'" unless $use_qq;
    my ($s1) = grep { $val !~ m/\Q$_\E/ } @delims;

    unless($s1) {
        $s1 = $delims[0];
        $val =~ s/$s1/\\$s1/g;
    }

    my $s2 = $QUOTE_MATCH{$s1} || $s1;

    $use_qq = 0 if $s1 eq '"';

    my $qq = ($QUOTE_MATCH{$s1} || $use_qq) ? 'qq' : '';

    return "${qq}${s1}${val}${s2}";
}

sub render_event {
    my ($event, $settings) = @_;
    my $type = blessed($event);

    return quote_key("+$type", $settings)
        if $settings->{use_full_event_type}
        || $type !~ m/^Test2::Event::(.+)$/;

    return quote_key($1, $settings);
}

sub get_fields {
    my ($event, $settings) = @_;

    my @fields = grep { $_ !~ m/^_/ } keys %$event;

    push @fields => keys %{$settings->{include_fields}}
        if $settings->{include_fields};

    my %seen;
    my $exclude = $settings->{exclude_fields} || {};
    @fields = grep { !$seen{$_}++ && !$exclude->{$_} } @fields;

    @fields = grep { exists $event->{$_} && defined $event->{$_} && length $event->{$_} } @fields
        unless $settings->{show_empty};

    return sort {
        my $a_has_array = ref($event->{$a}) eq 'ARRAY';
        my $b_has_array = ref($event->{$b}) eq 'ARRAY';

        my $av = $a_has_array ? $settings->{array_sort_order} : ($settings->{field_order}->{$a} || $settings->{other_sort_order});
        my $bv = $b_has_array ? $settings->{array_sort_order} : ($settings->{field_order}->{$b} || $settings->{other_sort_order});

        return $av <=> $bv || $a cmp $b;
    } @fields;
}

sub get_rows {
    my ($event, $field, $settings) = @_;

    return ['field', $field, 'DNE()']
        unless exists $event->{$field};

    my ($func, $val);
    if ($settings->{call_when_can} && $event->can($field)) {
        $func = 'call';
        $val = $event->$field;
    }
    else {
        $func = 'field';
        $val = $event->{$field};
    }

    if ($settings->{convert_trace} && $field eq 'trace' && blessed($val) && ($val->isa('Test2::Util::Trace') || $val->isa('Test2::EventFacet::Trace'))) {
        my $file = $settings->{adjust_filename}->($val->file);
        return (
            [],
            [ 'prop', 'file', $file ],
            [ 'prop', 'line', $val->line ],
        );
    }

    my $ref = ref $val;

    return [ $func, $field, quote_val($val, $settings) ]
        unless $ref;

    return ( [], [ $func, $field, do_array_dump($val, $settings) ] )
        if $ref eq 'ARRAY' && !grep { !blessed($_) || !$_->isa('Test2::Event') } @$val;

    return [ $func, $field, 'T()', "Unknown value: " . (blessed($val) || $ref) ];
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::EventDumper - *DEPRECATED* Tool for dumping Test2::Event structures.

=head1 DEPRECATED

This deprecation release is made in advance of a new Test2::API release that
provides a better intercept() tool that returns a structure that makes testing
better. Verifying events as event types is no longer recommended as tools can
and will change what events they generate regularly. What you want to test is
what assertions were made, what diags were generated, etc, without looking at
specific event types.

=head1 DESCRIPTION

This tool allows you to dump L<Test2::Event> instances (including subclasses).
The dump format is the L<Test2::Tools::Compare> event DSL. There are many
configuration options available to tweak the output to meet your needs.

=head1 SYNOPSYS

    use strict;
    use warnings;
    use Test2::Bundle::Extended;
    use Test2::API qw/intercept/;

    use Test2::Tools::EventDumper;

    my $events = intercept {
        ok(1, 'a');
        ok(2, 'b');
    };

    my $dump = dump_events $events;
    print "$dump\n";

The above will print this:

    array {
        event Ok => sub {
            call 'name' => 'a';
            call 'pass' => '1';
            call 'effective_pass' => '1';

            prop file => match qr{\Qbasic.t\E};
            prop line => '12';
        };

        event Ok => sub {
            call 'name' => 'b';
            call 'pass' => '1';
            call 'effective_pass' => '1';

            prop file => match qr{\Qbasic.t\E};
            prop line => '13';
        };
        end();
    }

B<Note>: There is no newline at the end of the string, '}' is the last
character.

=head1 EXPORTS

=over 4

=item dump_event($event)

=item dump_event $event => ( option => 1 )

This can be used to dump a single event. The first argument must always be an
L<Test2::Event> instance.

All additional arguments are key/value pairs treated as dump settings. See the
L</SETTINGS> section for details.

=item dump_events($arrayref)

=item dump_events $arrayref => ( option => 1 )

This can be used to dump an arrayref of events. The first argument must always
be an arrayref full of L<Test2::Event> instances.

All additional arguments are key/value pairs treated as dump settings. See the
L</SETTINGS> section for details.

=back

=head1 SETTINGS

All settings are listed with their default values when possible.

=over 4

=item qualify_functions => 0

This will cause all functions such as C<array> and C<call> to be fully
qualified, turning them into C<Test2::Tools::Compare::array> and
C<Test2::Tools::Compare::call>. This also turns on the
C<< paren_functions => 1 >> option. which forces the use of parentheses.

=item paren_functions => 0

This forces the use of parentheses in functions.

Example:

    call 'foo' => sub { ... };

becomes:

    call('foo' => sub { ... });

=item use_full_event_type => 0

Normally events in the C<Test2::Event::> namespace are shortened to only
include the postfix part of the name:

    event Ok => sub { ... };

When this option is turned on the full event package will be used:

    event '+Test2::Event::Ok' => sub { ... };

=item show_empty => 0

Normally empty fields are skipped. Empty means any field that does not exist,
is undef, or set to ''. 0 does not count as empty. When this option is turned
on all fields will be shown.

=item add_line_numbers => 0

When this option is turned on, all lines will be prefixed with a label
containing the line number, for example:

    L01: array {
    L02:     event Ok => sub {
    L03:         call 'name' => 'a';
    L04:         call 'pass' => '1';
    L05:         call 'effective_pass' => '1';

    L07:         prop file => match qr{\Qt/basic.t\E};
    L08:         prop line => '12';
    L09:     };

    L11:     event Ok => sub {
    L12:         call 'name' => 'b';
    L13:         call 'pass' => '1';
    L14:         call 'effective_pass' => '1';

    L16:         prop file => match qr{\Qt/basic.t\E};
    L17:         prop line => '13';
    L18:     };
    L19:     end();
    L20: }

These labels do not change the code in any meaningful way, it will still run in
C<eval> and it will still produce the same result. These labels can be useful
during debugging. Labels will not be added to otherwise empty lines as such
labels break on perls older than 5.14.

=item call_when_can => 1

This option is turned on by default. When this option is on the C<call()>
function will be used in favor of the C<field()> when the field name also
exists as a method for the event.

=item convert_trace => 1

This option is turned on by default. When this option is on the C<trace> field
is turned into 2 checks, one for line, and one for filename.

Example:

    prop file => match qr{\Qt/basic.t\E};
    prop line => '12';

Without this option trace looks like this:

    call 'trace' => T(); # Unknown value: Test2::Util::Trace

Which is not useful.

=item shorten_single_field => 1

When true, events with only 1 field to display will be shortened to look like
this:

    event Note => {message => 'XXX'};

Instead of this:

    event Note => sub {
        call message => 'XXX';
    };

=item clean_fail_messages => 1

When true, any value that matches the regex C</^Failed test/> will be turned
into a C<match qr/^Failed test/> check. This is useful for diagnostics messages
that are automatically created.

=item field_order => { ... }

This allows you to assign a sort weight to fields (0 is ignored). Lower values
are displayed first.

Here are the defaults:

    field_order => {
        name           => 1,
        pass           => 2,
        effective_pass => 3,
        todo           => 4,
        max            => 5,
        directive      => 6,
        reason         => 7,
        trace          => 9999,
    }

Anything not listed gets the value from the 'other_sort_order' parameter.

=item other_sort_order => 9000

This is the sort weight for fields not listed in C<field_order>.

=item array_sort_order => 10000

This is the sort weight for any field that contains an array of event objects.
For example the C<subevents> field in subtests.

=item include_fields => [ ... ]

Fields that should always be listed if present (or if 'show_empty' is true).
This is not set by default.

=item exclude_fields => [ ... ]

Fields that should never be listed. To override the defaults set this to a new
arrayref, or to undef to clear the defaults.

defaults:

    exclude_fields => [qw/buffered nested/]

=item indent_sequence => '    '

How to indent each level. Normally 4 spaces are used. You can set this to
C<"\t"> if you would prefer tabs. You can also set this to any valid string
with varying results.

=item adjust_filename => sub { ... }

This is used when the C<convert_trace> option is true. This should be a coderef
that modifies the filename to something portable. It should then return a
string to be inserted after C<< 'field' => >>.

Here is the default:

    sub {
        my $file = shift;
        $file =~ s{^.*[/\\]}{}g;
        return "match qr{\\Q$file\\E}";
    },

This default strips off all of the path from the filename. After stripping the
filename it puts it into a C<match()> check with the '\Q' and '\E' quoting
construct to make it safer.

The default is probably adequate for most use cases.

=back

=head1 SOURCE

The source code repository for Test2-Tools-EventDumper can be found at
F<http://github.com/Test-More/Test2-Tools-EventDumper/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
