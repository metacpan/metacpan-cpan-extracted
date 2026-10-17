package Text::Fab;

use 5.022;
use strict;
use warnings;

our $VERSION = '0.04';

# FreezeThaw is required because Storable::dclone cannot serialize CODE references
# stored in the configuration hash (such as custom sorters, parsers, and callbacks).
use FreezeThaw qw(safeFreeze thaw);

sub dclone ($) { (thaw safeFreeze shift)[0] }

# File-closing priority boundaries
# distance 0 (last closed file)  => -1000.0
# distance 999 (1000th from end) => -1999.0
# distance >= 1000 (overflow)    => -2000.0
our $PRIORITY_FILE_CLOSE_LAST     = -1000.0;
our $PRIORITY_FILE_CLOSE_OVERFLOW = -2000.0;

sub priority_for_file_close {
    my ($self, $dist_from_end) = @_;
    $dist_from_end = 0 unless defined $dist_from_end;
    die "E_TYPE_MISMATCH: Distance from end must be a non-negative integer\n"
        unless $dist_from_end =~ /^\d+$/;

    return -2000.0 if $dist_from_end >= 1000;
    return -1000.0 - $dist_from_end;
}

# =========================================================================
# Default Callbacks (The Pluggable Core Engine)
# =========================================================================

# Locates the next directive boundary.
# A default directive begins with '#' at offset 0 or immediately after a newline.
sub _default_interleaver {
    my ($buffer, $offset) = @_;
    return 0 if $offset == 0 && substr($buffer, 0, 1) eq '#';
    my $pos = index($buffer, "\n#", $offset - 1);
    return $pos == -1 ? undef : $pos + 1;
}

# Translates user-facing directive syntax into primitive method invocations.
# Returns the buffer offset immediately following the directive line.
sub _default_directive_parser {
    my ($fab, $buffer, $offset) = @_;
    my $line_end = index($buffer, "\n", $offset);
    $line_end = length($buffer) if $line_end == -1;

    my $directive_line = substr($buffer, $offset, $line_end - $offset);

    if ($directive_line =~ /^#(\w+)\s*(.*)/) {
        my ($directive, $args) = (lc $1, $2);
        $args =~ s/\s+$//; # Strip trailing whitespace

        if ($directive eq 'target_section') {
            my ($basename, $ns) = ($args =~ /(\w+)(?:\s+in\s+(\w+))?/);
            $fab->out__target_section($basename, $ns);
        }
        elsif ($directive eq 'set') {
            my ($key, $value) = split /=/, $args, 2;
            $fab->cfg__set($key, $value);
        }
        elsif ($directive eq 'append') {
            my ($key, @values) = split /\s+/, $args;
            $fab->cfg__append($key, @values);
        }
        elsif ($directive eq 'set_parents') {
            my ($ns, @parents) = split /\s+/, $args;
            $fab->NS__set_parents($ns, @parents);
        }
        elsif ($directive eq 'emb') {
            # Grammar: #emb <basename> [in <namespace>] [asiffrom <StartNamespace>] [with_blinder <SubName>]
            my ($basename) = ($args =~ /^(\S+)/);
            my ($ns)        = ($args =~ /\bin\s+(\S+)/);
            my ($asiffrom)  = ($args =~ /\basiffrom\s+(\S+)/);
            my ($blinder)   = ($args =~ /\bwith_blinder\s+(\S+)/);

            my %options;
            $options{asiffrom}     = $asiffrom if defined $asiffrom;
            $options{with_blinder} = $blinder  if defined $blinder;

            $fab->out__embed($basename, $ns, \%options);
        }
        elsif ($directive eq 'start_group') {
            $fab->group__start($args);
        }
        elsif ($directive eq 'end_group') {
            $fab->group__end($args);
        }
        elsif ($directive eq 'include') {
            # Syntax: #include [how] <data>
            my ($how, $data);
            if ($args =~ /^(\w+)\s+(.+)/) {
                ($how, $data) = ($1, $2);
            } else {
                ($how, $data) = ('filename', $args);
            }
            $fab->include__text($how, $data);
        }
        elsif ($directive eq 'include_scoped') {
            # Syntax: #include_scoped [how] <data> <flavor>
            # Guarantees rollback of configuration alterations made by the included unit.
            my ($how, $data, $flavor);
            my @tokens = split /\s+/, $args;
            if (@tokens == 3) {
                ($how, $data, $flavor) = @tokens;
            } elsif (@tokens == 2) {
                ($how, $data, $flavor) = ('filename', $tokens[0], $tokens[1]);
            } else {
                die "E_SYNTAX_ERROR: #include_scoped requires <file> <flavor>\n";
            }
            $fab->group__start($flavor);
            eval {
                $fab->include__text($how, $data);
                1;
            } or do {
                my $err = $@;
                $fab->group__end($flavor);
                die $err;
            };
            $fab->group__end($flavor);
        }
        else {
            $fab->_handle_error('unknown_directive', { directive => $directive, line => $directive_line });
        }
    }
    else {
        $fab->_handle_error('malformed_directive', { line => $directive_line });
    }

    # Advance past the trailing newline of the directive
    return ($line_end == length($buffer)) ? $line_end : $line_end + 1;
}

# The default "stomach" - returns non-directive text pass-through unchanged.
sub _default_chunk_preprocessor {
    my ($fab, $chunk) = @_;
    return $chunk;
}

# Detects comment directives. Returning an offset signals the main loop to omit
# flushing the preceding text chunk, fusing it with subsequent chunk(s).
sub _default_comment_recognizer {
    my ($fab, $buffer, $offset) = @_;
    my $line_end = index($buffer, "\n", $offset);
    $line_end = length($buffer) if $line_end == -1;

    my $directive_line = substr($buffer, $offset, $line_end - $offset);
    if ($directive_line =~ /^##/) {
        return ($line_end == length($buffer)) ? $line_end : $line_end + 1;
    }
    return undef;
}

# Fail-fast error handler.
sub _default_error_handler {
    my ($fab, $type, $details) = @_;
    die "Fab Error ($type): $details->{line}\n";
}

# =========================================================================
# Constructor & Main Execution Loop
# =========================================================================

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->{config} = {
        # Meta-configuration declaring value semantics
        'Fab/list_keys'           => { 'Fab/list_keys' => 1 },
        'Fab/hash_keys'           => { 'Fab/hash_keys' => 1 },
        # Sorting closure for hashes: per POD, accepts two arguments via @_
        'Fab/hash_key_sort_order' => sub { $_[0] cmp $_[1] },
        # Call stack prefix hierarchy for scoped filter evaluation
        'Fab/call_stack_prefixes' => ['Fab/'],
        'Fab/callbacks'           => {
            interleaver        => \&_default_interleaver,
            directive_parser   => \&_default_directive_parser,
            chunk_preprocessor => \&_default_chunk_preprocessor,
            comment_recognizer => \&_default_comment_recognizer,
            error_handler      => \&_default_error_handler,
        },
        'Fab/inheritance_graph'   => {},
        'opened_groups'           => [],
    };
    $self->{sections}       = {}; # { namespace => { basename => [ [type, data...], ... ] } }
    $self->{current_target} = ['_main', 'body'];
    $self->{group_stack}    = []; # Stack of active group frames for rollback
    $self->{include_stack}  = []; # Active include path chain for cycle detection

    if ($args{config}) {
        # Merge top-level configuration keys
        %{$self->{config}} = (%{$self->{config}}, %{$args{config}});
    }

    return $self;
}

# Main scanning loop: coordinates the de-interleaver, comment fusion,
# chunk preprocessor, and directive execution.
sub process_string {
    my ($self, $string) = @_;
    my $offset = 0;

    my $callbacks = $self->cfg__get_prefixed('callbacks')
                 // $self->cfg__get('Fab/callbacks')
                 // $self->{config}{'Fab/callbacks'};
    my ($interleaver, $parser, $preprocessor, $comment_recognizer) = 
        @{$callbacks}{qw(interleaver directive_parser chunk_preprocessor comment_recognizer)};

    my $pending_chunk = '';

    while ($offset < length($string)) {
        my $directive_start = $interleaver->($string, $offset);

        if (!defined $directive_start) {
            $pending_chunk .= substr($string, $offset);
            last;
        }

        # Accumulate text slice preceding the directive
        $pending_chunk .= substr($string, $offset, $directive_start - $offset);

        # Check if the matched position represents a comment
        my $comment_end = $comment_recognizer ? $comment_recognizer->($self, $string, $directive_start) : undef;
        if (defined $comment_end) {
            # FUSION: Advance past the comment boundary without flushing $pending_chunk.
            # The accumulated text will merge with subsequent text before preprocessing.
            $offset = $comment_end;
            next;
        }

        # Active directive: flush pending text chunk to the current target section
        $self->_process_chunk($pending_chunk, $preprocessor);
        $pending_chunk = '';

        # Parse and execute directive; resume scan at returned offset
        $offset = $parser->($self, $string, $directive_start);
    }

    # Flush terminal text chunk
    $self->_process_chunk($pending_chunk, $preprocessor) if length $pending_chunk;
}

sub _process_chunk {
    my ($self, $chunk_text, $preprocessor) = @_;
    $chunk_text =~ s/^\n//; # Strip newline residue resulting from \n# interleaving
    return unless length $chunk_text;

    my ($ns, $basename) = @{$self->{current_target}};
    my $processed_chunk = $preprocessor->($self, $chunk_text);
    push @{$self->{sections}{$ns}{$basename}}, ['text', $processed_chunk];
}

sub _handle_error {
    my ($self, $type, $details) = @_;
    my $callbacks = $self->cfg__get_prefixed('callbacks')
                 // $self->cfg__get('Fab/callbacks')
                 // $self->{config}{'Fab/callbacks'};
    my $handler = $callbacks ? $callbacks->{error_handler} : undef;
    if ($handler) {
        $handler->($self, $type, $details);
    } else {
        _default_error_handler($self, $type, $details);
    }
}

# Slurps or accepts literal text, enforcing cycle detection on active files.
sub include__text {
    my ($self, $how, $data) = @_;

    if ($how eq 'filename') {
        # Check active recursion stack for cycle prevention
        my %active = map { $_ => 1 } @{$self->{include_stack}};
        if ($active{$data}) {
            die "E_CYCLIC_INCLUDE: Circular inclusion detected for file '$data'\n";
        }

        open my $fh, '<', $data
            or die "E_FILE_READ_ERROR: Cannot read include file '$data': $!\n";
        my $content = do { local $/; <$fh> };
        close $fh;

        push @{$self->{include_stack}}, $data;
        eval {
            $self->process_string($content);
            1;
        } or do {
            my $err = $@;
            pop @{$self->{include_stack}};
            die $err;
        };
        pop @{$self->{include_stack}};
    }
    else {
        $self->process_string($data);
    }
}

# =========================================================================
# Output Control Primitives
# =========================================================================

# Redirects preprocessor output stream; autovivifies section if non-existent.
sub out__target_section {
    my ($self, $basename, $namespace) = @_;
    $namespace //= $self->{current_target}->[0] // '_main';
    $self->{current_target} = [$namespace, $basename];
    $self->{sections}{$namespace}{$basename} //= [];
}

# Initializes or clears section contents without necessarily redirecting output.
sub out__create_section {
    my ($self, $basename, $namespace) = @_;
    $namespace //= $self->{current_target}->[0] // '_main';
    $self->{sections}{$namespace}{$basename} = [];
}

# Appends an unresolved embed promise to the current target section.
sub out__embed {
    my ($self, $basename, $namespace, $options) = @_;
    my ($target_ns, $target_basename) = @{$self->{current_target}};
    $namespace //= $target_ns;
    push @{$self->{sections}{$target_ns}{$target_basename}},
        ['embed', $namespace, $basename, $options // {}];
}

# Converts text chunks of a section into a single string using cyclic joiners.
sub out__get_joined {
    my ($self, $spec, $joiners, $options) = @_;
    die "E_TYPE_MISMATCH: out__get_joined requires an array reference for joiners\n"
        unless ref $joiners eq 'ARRAY';

    my ($ns, $basename) = split /:/, $spec;
    my $all_chunks = $self->{sections}{$ns}{$basename};
    return '' unless defined $all_chunks && @$all_chunks;

    my @text_parts = map { $_->[1] } grep { $_->[0] eq 'text' } @$all_chunks;
    return $self->_join_list(\@text_parts, $joiners, $options);
}

# =========================================================================
# Configuration Primitives
# =========================================================================

sub cfg__set {
    my ($self, $key, @values) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        if (@values == 1 && ref $values[0] eq 'ARRAY') {
            $self->{config}{$key} = $values[0];
        } else {
            $self->{config}{$key} = [ @values ];
        }
    }
    elsif ($type eq 'hash') {
        if (@values == 1 && ref $values[0] eq 'HASH') {
            $self->{config}{$key} = $values[0];
        } elsif (@values % 2 == 0) {
            $self->{config}{$key} = { @values };
        } else {
            die "E_TYPE_MISMATCH: Odd number of elements provided to set hash key '$key'\n";
        }
    }
    else {
        # Scalar keys strictly accept at most one value
        if (@values > 1) {
            die "E_TYPE_MISMATCH: Scalar key '$key' accepts at most one value\n";
        }
        $self->{config}{$key} = @values ? $values[0] : undef;
    }
}

sub cfg__append {
    my ($self, $key, @values) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        $self->{config}{$key} //= [];
        die "E_TYPE_MISMATCH: List key '$key' does not contain an ARRAY ref\n"
            unless ref $self->{config}{$key} eq 'ARRAY';
        push @{$self->{config}{$key}}, @values;
    }
    elsif ($type eq 'hash') {
        $self->{config}{$key} //= {};
        die "E_TYPE_MISMATCH: Expected HASH ref for hash key '$key'\n"
            unless ref $self->{config}{$key} eq 'HASH';

        my %pairs;
        if (@values == 1 && ref $values[0] eq 'HASH') {
            %pairs = %{$values[0]};
        } elsif (@values % 2 == 0) {
            %pairs = @values;
        } else {
            die "E_TYPE_MISMATCH: Odd number of elements provided to append to hash key '$key'\n";
        }

        while (my ($k, $v) = each %pairs) {
            $self->{config}{$key}{$k} = $v;
        }
    }
    else {
        $self->{config}{$key} = ($self->{config}{$key} // '') . join('', @values);
    }
}

sub cfg__prepend {
    my ($self, $key, @values) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        $self->{config}{$key} //= [];
        die "E_TYPE_MISMATCH: List key '$key' does not contain an ARRAY ref\n"
            unless ref $self->{config}{$key} eq 'ARRAY';
        unshift @{$self->{config}{$key}}, @values;
    }
    elsif ($type eq 'hash') {
        die "E_TYPE_MISMATCH: Cannot prepend values to hash key '$key'\n";
    }
    else {
        $self->{config}{$key} = join('', @values) . ($self->{config}{$key} // '');
    }
}

sub cfg__get {
    my ($self, $key, $offset) = @_;
    my $type = $self->_get_key_type($key);

    if (@_ > 2) {
        if ($type eq 'list') {
            my $list = $self->{config}{$key};
            return undef unless defined $list;
            die "E_TYPE_MISMATCH: Expected ARRAY ref for list key '$key'\n"
                unless ref $list eq 'ARRAY';
            return $list->[$offset];
        }
        elsif ($type eq 'hash') {
            my $hash = $self->{config}{$key};
            return undef unless defined $hash;
            die "E_TYPE_MISMATCH: Expected HASH ref for hash key '$key'\n"
                unless ref $hash eq 'HASH';
            return $hash->{$offset};
        }
        else {
            die "E_TYPE_MISMATCH: Element offset requested on non-list key '$key'\n";
        }
    }

    # Returning container reference allows structural inspection and traversal
    return $self->{config}{$key};
}

# Pops count elements from a list or deletes specified keys from a hash.
sub cfg__pop {
    my ($self, $key, @args) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        die "E_TYPE_MISMATCH: cfg__pop on list key accepts at most one argument (count)\n"
            if @args > 1;
        my $count = @args ? $args[0] : 1;
        my $list = $self->{config}{$key};
        return wantarray ? () : undef unless defined $list;
        die "E_TYPE_MISMATCH: Expected ARRAY ref for key '$key'\n"
            unless ref $list eq 'ARRAY';
        die "E_LONG_POP: Cannot pop $count elements from list '$key' of size " . scalar(@$list) . "\n"
            if $count > @$list;

        my @popped = splice @$list, -$count;
        return wantarray ? @popped : $popped[-1];
    }
    elsif ($type eq 'hash') {
        return wantarray ? () : undef unless @args;
        my $hash = $self->{config}{$key};
        return wantarray ? () : undef unless defined $hash;
        die "E_TYPE_MISMATCH: Expected HASH ref for key '$key'\n"
            unless ref $hash eq 'HASH';

        my @deleted_values = delete @{$hash}{@args};
        return wantarray ? @deleted_values : $deleted_values[0];
    }
    else {
        die "E_TYPE_MISMATCH: cfg__pop cannot be called on scalar key '$key'\n";
    }
}

sub cfg__prepend_elt {
    my ($self, $key, $offset, $value) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        $self->{config}{$key} //= [];
        my $list = $self->{config}{$key};
        die "E_TYPE_MISMATCH: Expected ARRAY ref for list key '$key'\n"
            unless ref $list eq 'ARRAY';
        splice @$list, $offset, 0, $value;
        return;
    }
    elsif ($type eq 'hash') {
        die "E_TYPE_MISMATCH: cfg__prepend_elt on hash requires [key, value] pair\n"
            unless ref $value eq 'ARRAY' && @$value == 2;
        $self->{config}{$key} //= {};
        my $hash = $self->{config}{$key};
        die "E_TYPE_MISMATCH: Expected HASH ref for hash key '$key'\n"
            unless ref $hash eq 'HASH';
        $hash->{$value->[0]} = $value->[1];
        return;
    }
    else {
        die "E_TYPE_MISMATCH: cfg__prepend_elt called on scalar key '$key'\n";
    }
}

# Joins list elements or sorted hash pairs using cyclic joiner delimiters.
sub cfg__get_joined {
    my ($self, $key, $joiners, $options) = @_;
    die "E_TYPE_MISMATCH: cfg__get_joined requires an array reference for joiners\n"
        unless ref $joiners eq 'ARRAY';
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        my $list = $self->{config}{$key};
        return '' unless defined $list && @$list;
        die "E_TYPE_MISMATCH: Expected ARRAY ref for key '$key'\n"
            unless ref $list eq 'ARRAY';
        return $self->_join_list($list, $joiners, $options);
    }
    elsif ($type eq 'hash') {
        my $hash = $self->{config}{$key};
        return '' unless defined $hash && %$hash;
        my @sorted_keys = $self->_get_sorted_hash_keys($key);
        # joiners[0] binds key to value; joiners[1..] cycles between pairs
        my $intra_pair_joiner = $joiners->[0] // '';
        my @inter_pair_joiners = @$joiners > 1 ? @$joiners[1..$#$joiners] : [$intra_pair_joiner];
        my @joined_pairs = map { $_ . $intra_pair_joiner . ($hash->{$_} // '') } @sorted_keys;
        return $self->_join_list(\@joined_pairs, \@inter_pair_joiners, $options);
    }
    else {
        die "E_TYPE_MISMATCH: cfg__get_joined called on scalar key '$key'\n";
    }
}

# =========================================================================
# Configuration Prefix & Uplevel API
# =========================================================================

# Inspects only the topmost prefix on the call stack (CURRENT_PREFIX/$key).
sub cfg__get_prefixed {
    my ($self, $key) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    my $prefix = @$prefixes ? $prefixes->[-1] : '';
    return $self->{config}{$prefix . $key};
}

# Scans downward through the call stack prefixes from newest to oldest,
# falling back to the unprefixed base key.
sub cfg__get_prefixed_scan {
    my ($self, $key) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    for my $prefix (reverse @$prefixes) {
        my $full_key = $prefix . $key;
        return $self->{config}{$full_key} if exists $self->{config}{$full_key};
    }
    return $self->{config}{$key};
}

# Skips $level prefixes from the top of the call stack before initiating a downward scan.
sub cfg__get_uplevel_scan {
    my ($self, $level, $key) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    my $max_idx = $#$prefixes;

    die "E_UPLEVEL_TOO_DEEP: Level $level exceeds call stack prefix depth (" . scalar(@$prefixes) . ")\n"
        if $level < 0 || $level > $max_idx;

    my $start_idx = $max_idx - $level;
    for my $i (reverse 0 .. $start_idx) {
        my $full_key = $prefixes->[$i] . $key;
        return $self->{config}{$full_key} if exists $self->{config}{$full_key};
    }
    return $self->{config}{$key};
}

# Sets $key under the current (topmost) prefix.
sub cfg__set_prefixed {
    my ($self, $key, @values) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    die "E_UPLEVEL_TOO_DEEP: Call stack prefixes is empty\n" unless @$prefixes;
    my $prefix = $prefixes->[-1];
    $self->cfg__set($prefix . $key, @values);
}

# Sets $key under the prefix located $level steps back on the call stack.
sub cfg__set_prefixed_uplevel {
    my ($self, $level, $key, @values) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    my $max_idx = $#$prefixes;

    die "E_UPLEVEL_TOO_DEEP: Level $level exceeds call stack prefix depth (" . scalar(@$prefixes) . ")\n"
        if $level < 0 || $level > $max_idx;

    my $target_prefix = $prefixes->[$max_idx - $level];
    $self->cfg__set($target_prefix . $key, @values);
}

# Propagates the pre-existing value at $level downward to intermediate levels
# between $level and current, stopping if an intermediate level already defines
# $key, thus insulating downstream consumers from the modification at $level.
sub cfg__set_prefixed_uplevel_fixup {
    my ($self, $level, $key, @values) = @_;
    my $prefixes = $self->{config}{'Fab/call_stack_prefixes'} // [];
    my $max_idx = $#$prefixes;

    die "E_UPLEVEL_TOO_DEEP: Level $level exceeds call stack prefix depth (" . scalar(@$prefixes) . ")\n"
        if $level < 0 || $level > $max_idx;

    my $target_idx = $max_idx - $level;
    my $target_prefix = $prefixes->[$target_idx];

    if (exists $self->{config}{$target_prefix . $key}) {
        my $old_val = $self->{config}{$target_prefix . $key};
        # Propagate forward toward current, halting if already shadowed
        for my $i ($target_idx + 1 .. $max_idx) {
            my $inter_prefix = $prefixes->[$i];
            last if exists $self->{config}{$inter_prefix . $key};
            $self->cfg__set($inter_prefix . $key, ref($old_val) ? dclone($old_val) : $old_val);
        }
    }

    $self->cfg__set($target_prefix . $key, @values);
}

# =========================================================================
# Grouping & Scoping Primitives
# =========================================================================

sub group__start {
    my ($self, $flavor) = @_;
    $flavor = undef if defined $flavor && !length $flavor;

    # Verify nesting constraints against the enclosing group flavor
    if (defined $flavor && @{$self->{group_stack}}) {
        my $parent_flavor = $self->{group_stack}->[-1]{flavor};
        my $allowed = $self->{config}{"Fab/group_nesting/$flavor/allowed_parents"}
                   // (ref($self->{config}{'Fab/group_nesting'}) eq 'HASH'
                       ? $self->{config}{'Fab/group_nesting'}{$flavor}{allowed_parents}
                       : undef);
        if ($allowed && ref $allowed eq 'ARRAY') {
            my %is_allowed = map { $_ => 1 } @$allowed;
            if (!$is_allowed{$parent_flavor // ''}) {
                die "E_INVALID_GROUP_NESTING: Flavor '$flavor' is not allowed inside '" . ($parent_flavor // 'undef') . "'\n";
            }
        }
    }

    my $frame = {
        flavor            => $flavor,
        postponed_by_prio => {},
    };

    # Selective vs full snapshotting: check if flavor restricts tracked keys
    my $flavor_keys = defined($flavor)
        ? ($self->{config}{"Fab/group_flavors/$flavor/keys"}
           // (ref($self->{config}{'Fab/group_flavors'}) eq 'HASH'
               ? $self->{config}{'Fab/group_flavors'}{$flavor}{keys}
               : undef))
        : undef;

    if ($flavor_keys && ref $flavor_keys eq 'ARRAY') {
        my %snap;
        for my $k (@$flavor_keys) {
            if (exists $self->{config}{$k}) {
                $snap{$k} = ref($self->{config}{$k}) ? dclone($self->{config}{$k}) : $self->{config}{$k};
            }
        }
        $frame->{keys} = $flavor_keys;
        $frame->{snapshot} = \%snap;
    } else {
        # Default: snapshot entire configuration space
        $frame->{snapshot} = dclone($self->{config});
    }

    push @{$self->{group_stack}}, $frame;
    $self->{config}{'opened_groups'} = [ map { $_->{flavor} } @{$self->{group_stack}} ];
}

sub group__end {
    my ($self, $flavor) = @_;
    $flavor = undef if defined $flavor && !length $flavor;

    if (!@{$self->{group_stack}}) {
        die "E_DANGLING_END_GROUP: #end_group called with no open group\n";
    }

    # Keep $top on the stack during unwinding so depth 0 targets this closing group
    my $top = $self->{group_stack}->[-1];

    if (defined $flavor) {
        if (!defined $top->{flavor} || $top->{flavor} ne $flavor) {
            my $actual = $top->{flavor} // '<unnamed>';
            die "E_MISMATCHED_END_GROUP: End group flavor '$flavor' does not match currently open group '$actual'\n";
        }
    }

    $top->{is_closing}       = 1;
    $top->{is_undone}        = 0;
    $top->{current_priority} = undef;
    $top->{extra_prio}       = {};

    # Calculate initial array of sorted indices
    my @priorities = sort { $a <=> $b } keys %{$top->{postponed_by_prio} // {}};
    my @errors;

    my $do_rollback = sub {
        return if $top->{is_undone};
        $top->{is_undone} = 1;
        eval {
            if ($top->{keys}) {
                for my $k (@{$top->{keys}}) {
                    if (exists $top->{snapshot}{$k}) {
                        $self->{config}{$k} = $top->{snapshot}{$k};
                    } else {
                        delete $self->{config}{$k};
                    }
                }
            } else {
                $self->{config} = $top->{snapshot};
            }
            $self->{config}{'opened_groups'} = [
                map { $_->{flavor} } @{$self->{group_stack}}[0 .. $#{$self->{group_stack}} - 1]
            ];
            1;
        } or do {
            push @errors, $@;
        };
    };

    while (@priorities || %{$top->{extra_prio}} || (!$top->{is_undone} && (!@priorities || $priorities[0] >= 0))) {
        # Snapshot rollback boundary (priority 0.0)
        if (!$top->{is_undone} && (!@priorities || $priorities[0] >= 0)) {
            $do_rollback->();
        }

        # Check if the extra hash has entries needing recalculation of @priorities
        if (%{$top->{extra_prio}}) {
            for my $new_p (keys %{$top->{extra_prio}}) {
                $top->{postponed_by_prio}{$new_p} //= [];
                push @{$top->{postponed_by_prio}{$new_p}}, @{$top->{extra_prio}{$new_p}};
            }
            %{$top->{extra_prio}} = ();
            @priorities = sort { $a <=> $b } keys %{$top->{postponed_by_prio}};
            next;
        }

        last unless @priorities;

        my $p = $priorities[0];
        $top->{current_priority} = $p;

        # Run through the current internal array
        my $bucket = $top->{postponed_by_prio}{$p};
        if ($bucket && @$bucket) {
            my $call = shift @$bucket;
            eval {
                $self->_execute_postponed($call);
                1;
            } or do {
                push @errors, $@;
            };

            # If an action in the past or a non-existing priority was staged,
            # recalculation of @priorities triggers at the top of the loop.
            next;
        }

        # Internal array is exhausted: shift from indices and delete hash entry
        shift @priorities;
        delete $top->{postponed_by_prio}{$p};
        $top->{current_priority} = undef;
    }

    # Ensure rollback ran even if no actions were registered >= 0
    $do_rollback->();

    # Pop group frame from group_stack
    pop @{$self->{group_stack}};
    $self->{config}{'opened_groups'} = [ map { $_->{flavor} } @{$self->{group_stack}} ];

    die $errors[0] if @errors;
}

# Schedules an action to be executed during group__end at relative $depth.
# $priority < 0  => PRE-undo (runs before snapshot rollback in group-local scope)
# $priority >= 0 => POST-undo (runs after snapshot rollback in restored enclosing scope)
# $how: 'append' or 'prepend' (resolves execution order among equal priorities)
sub group__postpone {
    my ($self, $depth, $priority, $how, $method, @args) = @_;

    $depth = 0 unless defined $depth;
    $priority = 0.0 + $priority;
    $how = lc($how // 'append');

    die "E_TYPE_MISMATCH: Postpone order must be 'append' or 'prepend'\n"
        unless $how eq 'append' || $how eq 'prepend';

    die "E_TYPE_MISMATCH: Postponed action requires a method name or code reference\n"
        unless defined $method && (length($method) || ref($method) eq 'CODE');

    my $idx = $#{$self->{group_stack}} - $depth;
    if ($idx < 0 || $idx > $#{$self->{group_stack}}) {
        die "E_UPLEVEL_TOO_DEEP: Cannot postpone to group at relative depth $depth (stack size " . scalar(@{$self->{group_stack}}) . ")\n";
    }

    my $target_frame = $self->{group_stack}->[$idx];
    my $action = [$method, @args];

    # If the group is actively unwinding in group__end:
    if ($target_frame->{is_closing}) {
        # Fast path: insertion into an existing internal array in the present or future
        if (exists $target_frame->{postponed_by_prio}{$priority}
            && (!defined $target_frame->{current_priority} || $priority >= $target_frame->{current_priority}))
        {
            if ($how eq 'append') {
                push @{$target_frame->{postponed_by_prio}{$priority}}, $action;
            } else {
                unshift @{$target_frame->{postponed_by_prio}{$priority}}, $action;
            }
            return;
        }

        # Otherwise: insertion is in the past, or into a non-existing priority.
        # Route to the extra hash for on-demand recalculation.
        $target_frame->{extra_prio}{$priority} //= [];
        if ($how eq 'append') {
            push @{$target_frame->{extra_prio}{$priority}}, $action;
        } else {
            unshift @{$target_frame->{extra_prio}{$priority}}, $action;
        }
        return;
    }

    # Normal registration before group__end:
    $target_frame->{postponed_by_prio}{$priority} //= [];
    if ($how eq 'append') {
        push @{$target_frame->{postponed_by_prio}{$priority}}, $action;
    } else {
        unshift @{$target_frame->{postponed_by_prio}{$priority}}, $action;
    }
}

sub _execute_postponed {
    my ($self, $call) = @_;
    my ($method, @args) = @$call;
    if (ref($method) eq 'CODE') {
        $method->($self, @args);
    } else {
        $self->$method(@args);
    }
}

# =========================================================================
# Namespace & Inheritance Primitives
# =========================================================================

# Sets parents for $ns, validating that no directed cycle is introduced.
sub NS__set_parents {
    my ($self, $ns, @parents) = @_;

    for my $p (@parents) {
        if ($p eq $ns) {
            die "E_CYCLIC_INHERITANCE: Namespace '$ns' cannot be its own parent\n";
        }
    }

    # Cycle detection via depth-first reachability search:
    # Adding edge $ns -> @parents creates a cycle if and only if $ns is already
    # reachable from any candidate parent in @parents.
    my $would_cycle;
    $would_cycle = sub {
        my ($current, $target, $visited) = @_;
        return 1 if $current eq $target;
        return 0 if $visited->{$current}++;

        my $p_list = ($current eq $ns)
            ? \@parents
            : ($self->cfg__get("Fab/inheritance_graph/$current/parents")
               // (ref($self->{config}{'Fab/inheritance_graph'}) eq 'HASH'
                   ? $self->{config}{'Fab/inheritance_graph'}{$current}{parents}
                   : undef)
               // []);

        for my $next_p (@$p_list) {
            return 1 if $would_cycle->($next_p, $target, $visited);
        }
        return 0;
    };

    for my $p (@parents) {
        my %visited;
        if ($would_cycle->($p, $ns, \%visited)) {
            die "E_CYCLIC_INHERITANCE: Adding parent '$p' to '$ns' creates a cycle in the inheritance DAG\n";
        }
    }

    $self->cfg__set("Fab/inheritance_graph/$ns/parents", \@parents);
}

# =========================================================================
# Private Helpers
# =========================================================================

sub _get_key_type {
    my ($self, $key) = @_;
    return 'hash' if $self->{config}{'Fab/hash_keys'}{$key};
    return 'list' if $self->{config}{'Fab/list_keys'}{$key};
    return 'scalar';
}

sub _get_sorted_hash_keys {
    my ($self, $key) = @_;
    my $hash = $self->{config}{$key} or return ();
    die "E_TYPE_MISMATCH: Expected HASH ref for key '$key'\n" unless ref $hash eq 'HASH';
    my $sorter = $self->{config}{'Fab/hash_key_sort_order'} // sub { $_[0] cmp $_[1] };
    return sort { $sorter->($a, $b) } (keys %$hash);
}

sub _join_list {
    my ($self, $list, $joiners, $options) = @_;
    $options //= {};
    my $num_elements = scalar @$list;
    return '' unless $num_elements;
    return $list->[0] if $num_elements == 1;

    my $num_joiners_to_use = $num_elements - 1;
    if (my $mod = $options->{permitted_joiners_modulo}) {
        die "Join operation violates permitted_joiners_modulo rule (want multiple of $mod, got $num_joiners_to_use)\n"
            if $num_joiners_to_use % $mod != 0;
    }

    my $output = $list->[0];
    for my $i (1 .. $num_joiners_to_use) {
        $output .= $joiners->[($i - 1) % @$joiners] . $list->[$i];
    }
    return $output;
}

# =========================================================================
# Assembly Phase (DAG Traversal, Resolution, Blinding, & Expansion)
# =========================================================================

sub assemble {
    my ($self, $root_spec) = @_;
    my ($ns, $basename) = split /:/, $root_spec, 2;
    if (!defined $basename) {
        $basename = $ns;
        $ns = '_main';
    }

    my $embed_stack = []; # Accumulates frames: { section, options, blinder_output }
    my $blinded = {};     # Set of namespaces obscured in the current branch

    my $output = $self->_expand_section($ns, $basename, {}, $embed_stack, $blinded);
    chomp($output);
    return $output;
}

sub _expand_section {
    my ($self, $ns, $basename, $seen, $embed_stack, $blinded) = @_;
    my $id = "$ns:$basename";

    # Detect recursive embed loops along the current resolution branch
    if ($seen->{$id}) {
        die "E_CIRCULAR_EMBED: Circular dependency detected for section '$id'\n";
    }
    my %next_seen = (%$seen, $id => 1);

    my $chunks = $self->_resolve_section($ns, $basename, $blinded);
    if (!defined $chunks) {
        die "E_EMBED_NOT_FOUND: Section '$id' cannot be resolved in inheritance DAG\n";
    }

    my $output = '';
    for my $chunk (@$chunks) {
        my ($type, @data) = @$chunk;
        if ($type eq 'text') {
            $output .= $data[0];
        }
        elsif ($type eq 'embed') {
            my ($target_ns, $target_basename, $options) = @data;
            $options //= {};

            # POD: asiffrom initiates resolution directly from the specified context
            my $start_ns = $options->{asiffrom} // $target_ns;

            # POD: with_blinder dynamically obscures an arbitrary subset of the DAG.
            # Invokes callback with full embedding stack, start namespace, and blinder name.
            my %local_blinded = %$blinded;
            my @obscured_namespaces;
            if (my $blinder_name = $options->{with_blinder}) {
                my $blinder_sub = $self->{config}{"Fab/blinders/$blinder_name"};
                if ($blinder_sub && ref $blinder_sub eq 'CODE') {
                    @obscured_namespaces = $blinder_sub->($self, {
                        embed_stack     => $embed_stack,
                        start_namespace => $start_ns,
                        blinder_name    => $blinder_name,
                        target_section  => "$start_ns:$target_basename",
                    });
                    $local_blinded{$_} = 1 for @obscured_namespaces;
                }
            }

            # Propagate updated embedding stack down to sub-resolutions
            my $next_embed_stack = [
                @$embed_stack,
                {
                    section        => "$start_ns:$target_basename",
                    options        => $options,
                    blinder_output => \@obscured_namespaces,
                }
            ];

            $output .= $self->_expand_section($start_ns, $target_basename, \%next_seen, $next_embed_stack, \%local_blinded);
        }
    }

    return $output;
}

# Recursively searches for $basename starting at $ns and traversing parents.
# Invariant: A blinded namespace has its OWN section definition masked, but
# resolution continues upward to its parents in the DAG.
sub _resolve_section {
    my ($self, $ns, $basename, $blinded, $visited_ns) = @_;
    $visited_ns //= {};

    # Avoid redundant traversals across diamond inheritance topologies
    return undef if $visited_ns->{$ns}++;

    # Check for direct section definition if $ns is not blinded
    if (!$blinded->{$ns}) {
        if (exists $self->{sections}{$ns} && exists $self->{sections}{$ns}{$basename}) {
            return $self->{sections}{$ns}{$basename};
        }
    }

    # Continue fallback search through ancestors in the inheritance graph
    my $parents_key = "Fab/inheritance_graph/$ns/parents";
    my $parents = $self->{config}{$parents_key}
               // (ref($self->{config}{'Fab/inheritance_graph'}) eq 'HASH'
                   ? $self->{config}{'Fab/inheritance_graph'}{$ns}{parents}
                   : undef)
               // [];

    for my $parent_ns (@$parents) {
        my $chunks = $self->_resolve_section($parent_ns, $basename, $blinded, $visited_ns);
        return $chunks if defined $chunks;
    }

    return undef;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Fab - A powerful, general-purpose document expansion framework (currently Control Flow, Loops, Caching, Root Directives unimplemented, and the test suite not checked by humans;)

=head1 SYNOPSIS

    # -- File: config.fab --   Example of merging multiple files (with almost no content!)
    # Declare which configuration keys will be treated as lists
    #append Fab/list_keys chapters css_files

    # Set some configuration variables
    #set site_title=My Awesome Book
    #append css_files global.css theme.css

    # Define the inheritance graph for our namespaces
    #set_parents ChapterLayout BaseLayout
    #set_parents Book _main # The final book inherits from _main's structure

    # -- File: main.fab --
    # The main assembly script. The default output target is '_main:body'.
    #append chapters chapter1 chapter2 chapter3 # Build the chapter list

    #emb title
    #emb table_of_contents
    #emb all_chapters
    #emb footer

    # -- File: components.fab --
    # Define reusable components in namespaces
    #target_section title in ChapterLayout
        <h1>#emb _main:title</h1> # Note: Fully qualified name
    #end_section

    #target_section all_chapters in ChapterLayout
        #= FOREACH chapter IN C('chapters') ... # (Chunk Preprocessor syntax)
            #emb @chapter:body
        #= END #
    #end_section

    #target_section footer in BaseLayout
        <footer>Copyright 2025</footer>
    #end_section

=head1 DESCRIPTION

C<Text::Fab> is not a templating engine; it is a framework for building your own. At its core, it is more or less a minimal "dumb" state machine that exposes a stable API of primitive operations. Most of the "smart" logic for parsing syntax, processing text, and creating complex control structures is delegated to user-configurable components. (However, a certain minimal level of smartness is a — switchable off — default to handle the most common cases.) As a result, it knows nothing about the processed “language”'s syntax or semantics.

The main design goal is that all state of C<Fab> is explicitly introspectable: there is no hidden magic. The entire state of the system is contained in the Configuration hash and the collection of already constructed Output Sections. What you see is what you get.

The Fab’s purpose is to factor out I<the common needs> of all the
configurable-on-the-fly document processing engines; more precisely, it
focuses on the needs orthogonal to the particular syntax of a particular
problem domain.  (This architecture aims to overcome the experiences with
designing “simple” configurable systems — which turn out to be not
scalable, so all the approaches to make them operable crumble under their own
weight.)

In short: this attempts to abstract out all the complexity of scalable
configurability.  The resulting “tools” support architecture with a
top→down approach to recognizing the “reconfiguration directives”.

B<————————————————————————————————————>

By default, C<Text::Fab> reads input and filters it through a specified preprocessing engine (which defaults to pass-through-unchanged) to the standard output. Its power comes from executing the interleaved-in-the-input B<directives> that are tools for B<controlling the processing engine>, B<reshuffling content>, and B<templating>.

The process is straightforward: C<Text::Fab> asks a B<De-Interleaver> callback "Where is the next control directive?". It then (optionally, see below) passes the text chunk before that location to a B<Chunk Preprocessor> (the "stomach"). Finally, it allows the Parser to execute the directive (typically, the Parser would convert the details of the directive into calls to zero or more of C<Text::Fab>'s primitive API methods to alter its internal state). This cycle repeats until the input is exhausted.

Furthermore, as an extra configurable step, the De-Interleaver may need to report that a particular directive “is a comment-to-ignore”. In this case, Fab would postpone processing the text chunk before that location, instead merging it with the following chunk(s) before passing to the Pre-Processor. So the process’ cycle is: the B<De-Interleaver> finds the next directive. The B<Comment Recognizer> may then optionally identify a comment, allowing for the fusion of the preceding and succeeding text chunks. Depending on this: now — or later — this final chunk is then passed to the B<Chunk Preprocessor>. Finally, the B<Parser> executes the directive found above, which may alter the system's state for the next cycle.

Finally, this “structured” (see below) pre-processed data created this way is “merged” into the final output text stream following flexible “hierarchical” rules.

=head1 THE PROCESSING MODEL

First of all, the inclusion mechanism handles a stack of currently opened-for-processing files; these files are “combined as usual” into one input stream. In addition to this, the Fab uses three more data collections.

The configuration directives may affect how the preprocessor handles the chunks of its input, whether “the comments interleaved into the stream” split these chunks etc., and may modify how the “directinves interleaved into the input stream” are recongnized (and even what these directives mean). The grouping directives control which changes to configuration are undone and when. The output directives may insert into the output section "an order to inline another section" (a promise, which is not executed until much later). Another kind of output directive allows switching the target section for the output of the preprocessor.

(It makes sense to also focus on specific parts of the Configuration Hash: the B<Control Stack> which manages conditional handling and looping, B<Grouping Stack> which handles undoing changes to configuration, and B<Caching Engine> which helps to avoid the penalties of constantly recalculating data dependent only on the configuration stack.)

After all the sections has been constructed, they may be “joined arbitrarily” into the final document. This assembly process is controlled by the rules how to choose a named section if “multiple flavors” have been defined. This allows a flexible hierarchical system of “overridable templates”. Such templates together with the rules of “namespace resolution” build the B<logic of processing> that ultimately generates the final document(s).

=head2 The Configuration Hash

The heart of C<Text::Fab> is a single Configuration hash. It is a live data structure that directives can modify during processing. It controls everything, from user-defined variables to the very components (parsers, etc.) that define the language's behavior. By default, all internal configuration used by the framework itself is stored under the C<Fab/> top-level key. (Later we are going to discuss how to modify this default, and how this prefix changes during the input processing. However, in examples below we assume that this hasn't been changed.)

Configuration values can be B<scalars>, B<lists>, or B<hashes>. Special hashes, C<Fab/list_keys> and C<Fab/hash_keys>, are used to declare which keys should be treated as lists or hashes by the primitive operations. Both register themselves in C<new()>.

=head2 The Output Sections

A section is a named buffer that holds already preprocessed content. A section's name is a pair of strings: a B<namespace> and a B<basename> (e.g., C<Chapter1:body>). The default namespace is C<_main>.

It makes sense to imagine that a section consists of two interleaved lists, each of its specific type of content:

=over 4

=item 1.

Plain text chunks, which have been processed by the Chunk Preprocessor.

=item 2.

C<embed> placeholders, which are promises to inline another section during the final Assembly Phase. This other section is described by its basename as well as some extra data (these data is used in the calculation of its namespace, which is going to be performed later).

=back

=head2 Grouping: Scoped/Undoable Configuration Changes

(Below, we assume a particular C<#>-based format for directives. The actual operation is agnostic of this format.)

=over 4

=item B<< C<#start_group [flavor_name]> >>

Begins a scope. A certain set of keys in the B<Configuration> hash are snapshotted.
The C<flavor_name> is used to look up the list of Configuration keys to memorize/restore
under C<Fab/group_flavors/$flavor_name/keys> (an array reference). If this key list is
not defined for the flavor, the default behavior is to snapshot the entire Configuration hash.
Validates nesting constraints against the enclosing group flavor via
C<Fab/group_nesting/$flavor/allowed_parents>, halting with C<E_INVALID_GROUP_NESTING> if violated.

=item B<< C<#end_group [flavor_name]> >>

If a C<flavor_name> is provided, it must match the flavor of the currently open group;
otherwise, processing halts with C<E_MISMATCHED_END_GROUP>. All changes made to the
observed configuration keys are B<undone>. If the optional name is not given, closes the
most recently opened scope. Calling C<#end_group> with no open scope halts with C<E_DANGLING_END_GROUP>.
Executes all postponed undo actions and restores the configuration snapshot.

=back

B<Note:> The nesting behavior of groups (e.g., whether flavor C<A> must be nested within flavor C<B>) is itself controlled by the Configuration hash.

=head1 PRIMITIVE API REFERENCE

These are the low-level methods on the C<Text::Fab> object that user-defined Parsers can call. The user-facing directives (like C<#set>) are defined by the Parser, whose role is to convert these directives into calls to the C<Text::Fab> methods listed below.

=head2 Output Control Primitives

=over 4

=item C<out__target_section( $basename, $namespace )>

Redirects subsequent output to the specified section. Creates the section if it does not exist.

=item C<out__create_section( $basename, $namespace )>

Creates a section, clearing its content if it already exists.

=item C<out__embed( $basename, $namespace, \%options )>

Places an C<embed> placeholder into the current target section. The C<%options> hash can contain advanced features like C<asiffrom> or C<with_blinder>.

=back

=head2 Configuration Primitives

=over 4

=item C<cfg__set( $key, @values )>

Sets the value of a key. For a B<scalar key>, accepts at most one value (empty C<@values> sets
C<undef>, exactly one value sets the scalar). Passing more than one value halts with
C<E_TYPE_MISMATCH>. For a B<list key>, C<@values> sets the list elements (or accepts a single
array reference). For a B<hash key>, C<@values> accepts an even-sized list of key-value pairs or
a single hash reference; an odd number of items halts with C<E_TYPE_MISMATCH>.

=item C<cfg__append( $key, @values )>

Appends one or more items to a list key, appends a string value to a scalar key, or merges an
even-sized list of key-value pairs (or a hash reference) into a hash key. Appending an odd number
of items to a hash key halts with C<E_TYPE_MISMATCH>.

=item C<cfg__prepend( $key, @values )>

Prepends one or more items to a list key (preserving their order at the front of the list),
or prepends a string value to a scalar key. Calling C<cfg__prepend> on a hash key is prohibited
and halts with C<E_TYPE_MISMATCH>.

=item C<cfg__get( $key, [$offset] )>

When C<$offset> is omitted, returns the scalar value, array reference, or hash reference.
When C<$offset> is provided, acts as an array index for list keys, or as a sub-key for hash keys.
Passing C<$offset> on a scalar key halts with C<E_TYPE_MISMATCH>.

=item C<cfg__get_joined( $key, \@joiners, \%options )>

A powerful utility that retrieves a list-type or hash-type key and joins its elements into a single
string. The C<@joiners> array provides one or more separators that are cycled through when joining.
For hashes, joiner 0 binds key to value while subsequent joiners cycle between pairs. The C<%options>
can control complex formatting, for example specify permitted numbers of joiners modulo
C<scalar @joiners>. (E.g., if “joiners come in pairs”, then the number of emitted joiners must be even!)

=back

An analogous C<out__get_joined> exists for converting a section (representable as a list of text-parts and embed-promises) into a single string.

Additionally, one can use C<cfg__pop($key, [$count])>, C<cfg__prepend_elt( $key, $offset, $value )> etc. on a list key.
C<cfg__pop()> also can be used to C<delete()> one or more subkeys from a hash value (then the C<$count> is replaced by the list of these keys).
(The parser for directive may implement only the flavors with C<$offset> in 0 and -1 only, e.g., “as if” in C<cfg__prepend_last( $key, $value )> etc.)

=head3 Working with Hashes

In addition to scalars and lists, the framework supports hashes as a first-class
configuration data type. This is controlled by two special configuration keys:

=over 4

=item B<C<Fab/hash_keys>>

Analogous to C<Fab/list_keys>, this is a hash whose keys are the names of
configuration variables that should be treated as hashes by the primitive
operations.

    # In a config file (registering a hash name):
    #append Fab/hash_keys my_parameters 1

=item B<C<Fab/hash_key_sort_order>>

This key holds a subroutine reference that defines how the keys of a hash
should be sorted when the hash needs to be treated as an ordered list (e.g.,
for C<cfg__get_joined>). The subroutine receives two keys as
arguments. The default is standard string comparison.

    # In Perl code, to set numeric sorting:
    $fab->cfg__set('Fab/hash_key_sort_order', sub { $_[0] <=> $_[1] });

=back

=head2 Grouping and Postponement Primitives

=over 4

=item C<group__start( [$flavor_name] )>

Starts a scoped group.

=item C<group__end( [$flavor_name] )>

Ends a scoped group.

=item C<group__postpone( $depth, $priority, $how, $method_name, @args )>

Schedules a C<Text::Fab> method call (or code reference) to run when the group at relative depth
C<$depth> is closed. All postponed actions have strict B<undo semantics>: failure in one action does
not abort the remaining undo actions or snapshot rollback.
C<$priority> is a real number:
Priorities C<< < 0 >> execute B<PRE-undo> while the group scope is still active.
Priority C<0.0> is the snapshot rollback point where configuration is restored.
Priorities C<< >= 0 >> execute B<POST-undo> in the restored enclosing scope.
C<$how> must be C<'append'> or C<'prepend'> to define execution order among actions with equal priority.

The closing frame remains active on the stack during unwinding, so actions can target the closing
group at depth 0 or parent groups at depth > 0. Insertions into existing current/future priority
buckets are consumed directly by the active loop without recalculation. Insertions into the past
(time-machine actions) or into non-existing priorities trigger on-demand recalculation of the priority array.

(The parser for directives may allow more user-friendly UI, such as specifying “a path” to this group, as in “the last-but-one C<x> group before the last two C<y> groups.)

=item C<priority_for_file_close( [$dist_from_end] )>

Calculates file-closing priority based on distance from the end: distance 0 (last closed file)
is C<-1000.0>, distance 999 is C<-1999.0>, and distance C<< >= 1000 >> is C<-2000.0> (overflow).

=back

=head2 Input and Inclusion Primitives

=over 4

=item C<include__text( $how, $data )>

Processes included input. If C<$how> is C<'filename'>, C<$data> is read from disk and processed.
Recursion is tracked on an inclusion stack; attempting to include a file currently in progress
halts with C<E_CYCLIC_INCLUDE>. An unreadable file halts with C<E_FILE_READ_ERROR>.
If C<$how> is not C<'filename'>, C<$data> is processed directly as an in-memory string.

=back

=head2 Namespace and Inheritance Primitives

=over 4

=item C<NS__set_parents( $namespace, @parents )>

Registers the list of immediate parent namespaces for C<$namespace> in the inheritance DAG
(stored under C<Fab/inheritance_graph/$namespace/parents>). Before writing, the inheritance graph
is validated for cycles; adding a parent that would create a directed cycle halts with
C<E_CYCLIC_INHERITANCE>.

=back

=head2 Configuration Prefix API

For recursive processing, the Configuration contains a stack of prefixes at C<Fab/call_stack_prefixes>. Primitives are provided to safely interact with keys relative to this stack.

(We list only the most basic retreaval primitives; the rest follows the same principle.)

=over 4

=item C<cfg__get_prefixed( $key )>

Retrieves the value of $key using only the current, most recent prefix (i.e., C<CURRENT_PREFIX/$key>).

=item C<cfg__get_prefixed_scan( $key )>

Retrieves the value of C<$key> by searching for it under each prefix in the call stack, from most recent to least recent.

=item C<cfg__get_uplevel_scan( $level, $key )>

Retrieves the value of C<$key> by first popping C<$level> prefixes from the call stack and then performing a prefixed search.

=item C<cfg__set_prefixed( $key, @values )>

Sets the value of C<$key> using the I<current> (most recent) prefix.

=back

For setting things “uplevel on this stack”, there are two methods matching two types of access:

=over 4

=item C<cfg__set_prefixed_uplevel( $level, $key, @values )>

As C<cfg__set_prefixed()>, but goes back C<$level> steps on the stack of prefixes.  This matches retreaval via C<cfg__get_prefixed()>.

=item C<cfg__set_prefixed_uplevel_fixup( $level, $key, @values )>

As C<cfg__set_prefixed_uplevel()>, but first runs “fixup”: copying the preceding value at C<$level> to the levels between this one
and the current level — stopping when value is found on a particular level.  This matches retreaval via C<cfg__get_prefixed()>: this
call won’t change the results of these calls on the levels between C<$level> and the current one.

=back

=head1 ADVANCED TOPICS

=head2 Input Processing and Recursion

The primitive to support the C<#include> directive is C<include__text($how, $data)>. If C<$how> is C<filename>, the file C<$data> is searched for and slurped; if not, C<$data> is the input string to be processed. A special form C<#include_scoped> ensures that configuration changes made by the included file are temporary by wrapping the call in a group named by the last argument.

Recursive processing (e.g., using one C<Text::Fab> “process” to filter data for another) is managed entirely within the Configuration hash. A stack of configuration prefixes is maintained in C<Fab/call_stack_prefixes> (which usually starts as just C<Fab/>). When a named recursive filter is invoked, its name is pushed to the filter name stack C<Fab/call_stack_filter_name>. This also pushes a certain prefix onto C<Fab/call_stack_prefixes>. Since it is the last prefix on this stack which is actually used by C<Text::Fab> for its operation, this allows a special predefined configuration (e.g., C<Fab/myList2ScalarFilter>) to take precedence without conflicting with the “normal” operation of the Fab.

The C<uplevel> family of configuration directives operates with respect to both the group stack and this call stack, allowing for powerful, controlled communication between different layers of processing.

=head2 Namespace Resolution and Inheritance of output sections

The inheritance system is a layer of logic built on top of the primitive operations. It is controlled entirely by the Configuration hash. Here we illustrate the API by how the corresponding directives may look like. The API has an extra prefix C<NS__>, and omits the UI verbiage.

=over 4

=item B<< C<#set_parents E<lt>namespaceE<gt> E<lt>parent1E<gt> E<lt>parent2E<gt> ...> >>

A user-facing directive that calls C<cfg__set> on a key within the Configuration that stores the inheritance DAG. For example, it might set C<Fab/inheritance_graph/MyNamespace/parents> to C<[Parent1, Parent2]>.

=back

The B<Assembly Phase> uses this graph to resolve embed placeholders in the output sections; below we denote them as C<#emb>. The resolution can be controlled with extra data:

=over 4

=item B<< C<#emb E<lt>basenameE<gt> in E<lt>namespaceE<gt> asiffrom E<lt>StartNamespaceE<gt>> >>

This performs a "static" embed. It resolves the namespace of the section by starting the search directly from C<StartNamespace>'s context. When this context is not the root, this makes it "blind" to any “override sections” up the tree/DAG. C<StartNamespace> defaults to the root namespace in the DAG — which typically contains the most specific overrides.

=item B<< C<#emb E<lt>basenameE<gt> ... with_blinder E<lt>SubNameE<gt>> >>

Here C<SubName> provides a completely customizable analog of the previous call, looked up as
a subroutine reference under C<Fab/blinders/$SubName>. Instead of (or in addition to) obscuring
the part of DAG which is not reachable from C<StartNamespace>, the output of this user-defined
subroutine obscures an arbitrary subset of the DAG. Blinding a namespace masks that namespace's
own section definitions from satisfying the embed, while allowing inheritance traversal to continue
through its parents in the DAG. It receives the entire current embedding stack (each entry is the
currently executed embedding promise) together with the start namespace, the used blinder name,
and the output of the blinder for each level. It returns a dynamic list of namespaces to "blind"
for this specific resolution and any sub-resolutions (which may happen during processing of this
embedded section).

=back

=head2 Support of Control-Flow-Like constructs (conditionals and/or loops) [Planned]

To simplify support of matched nested control-constructs in the user-defined parser, Fab maintains 6 stacks of matched lengths. Because of this match, they should be modified only via the corresponding API. E.g., the last elements of these lists describe:

=over 4

=item *

The C<type> of the last encountered starter of the construct. (Set by C<control__start()>)

=item *

The (optional) text C<label> for the construct. (Likewise. Defined for “loop-like” constructs only.)

=item *

Are we in a C<skipping> or not (“live”) branch/flavor of the construct. (With the value 2 if the processing were skipping even before meeting the start of the construct. Set likewise at start, then may be changed.)

=item *

The C<offset> of the start of the body (for “loop-like” constructs only). (This may be the file offset for C<seek()>able files, otherwise offset in a suitable buffer.)

=item *

Other useful C<offsets> (for support of various loop-related targets for analogues of C<goto>) packed into a hash.

=item *

The C<loop_counter> (defined for “loop-like” constructs only). Changed (in a parser-specified ways) on “jump” calls.

=item *

Which C<targetToSeek> we are trying to find in the “skipping” mode now.

=back

There is also the list of the indices C<Fab/control__loop_indices> of “loop-like” constructs in this stack.

Essentially, when encountering the start of an analogue of C<if/elsif/else/endif>, the parser may registers its type, as well as whether the start is in the “skipping” mode via C<ctrl__start(TYPE,IS_skipping,LABEL)>. Likewise, every flip of the skipping mode is registered with C<ctrl__skipping(IS_skipping)> (this is going to be ignored if the current skipping state is 2; likewise, Fab knows when to set the state 2 automatically at start). When the end of the construct is encountered, these data may be popped by C<ctrl__end(TYPE)> (with C<TYPE> given for error-checking only).

The latest “skipping” state determines whether the preprocessor calls are skipped, and it is also given as an argument to the
de-interlacer and parser callbacks. It also affects the state of loops nested inside “skipped” input.

These Control Stacks are reset when a new input file is included and restored when processing of that file completes.

The API to deal with these stacks is:

=over 4

=item C<control__start( $type, $is_skipping, $label)>

Pushes a new frame onto the Control Stack.

=over 8

=item *

C<$type> and C<$label> are stored directly.

=item *

The initial C<skipping_state> for the new frame is computed as follows: if the parent frame (if one exists) is already in any skipping state, the new frame's state is set to "skipping-on-entry" (state 2). Otherwise, the new frame's skipping state is set based on the boolean C<$is_skipping> (C<true> -> "skipping", C<false> -> "live").

=back

=item C<control__set_skipping( 'flip' | $boolean )>

Modifies the C<skipping_state> of the current control block.

=over 8

=item *

If the argument is C<'flip'>, the state toggles between "live" and "skipping", but only if the current state is not "skipping-on-entry" (state 2).

=item *

If a boolean is provided, the state is set accordingly, again respecting the immutability of the "skipping-on-entry" state. This is called by the Parser for constructs like C<#elif>.

=back

=item C<control__end( $expected_type )>

Pops the top frame from the Control Stack. For error-checking, the Parser must provide the C<$expected_type>. (Typically, this is used for loop-like constructs only when they are in “skipping mode”; see the next API.) C<Fab/control__loop_indices> is changed accordingly.

=item control__define_invalidation_pointer($expected_type)

Mark the next position as “First postion not in the loop”. When this position “is activated”, or the jump is performed past this position (or before the starting position), the effect should be the same as C<control__end( $expected_type )>.

=item C<control__set_pointer( $pointer_name, [$before}, [$force] )>

Records the current position in the input stream (file or buffer) (if C<$before>, this is the position I<before the directive>) and stores it under C<$pointer_name> in the "Custom Pointers" hash of the current control block. This is the B<sole mechanism> for defining loop start points, C<continue> targets, or any other labeled position. For all loop-like constructs, the Parser is expected to call this at the beginning of the loop body to define a C<'body_start'> pointer.

These pointers B<form I<the structural geometry> of the loop>. One must keep in mind that Fab may assume that this geometry is I<not modified> (only I<enhanced> by definition of new pointers) during “each pass” of a particular “instance of processing” this loop. (Here our terminology is a bit dense. If the current loop is nested inside another loop, it can be B<entered> many times — leading to different I<instances of processing this loop>. In each instance the body may be I<looped over> in several B<passes>.)

By default, this condition is auto-enforced: this call is ignored on the “replay passes” of “loop-like” constructs (i.e., if the current portion of the loop’s body “has already been read” — inside the current I<instance>). This filtering may be disabled by the C<$force> flag. (A similar flag C<$is_replay> is passed to the parser — just in case.)

=item C<control__jump_to( $pointer_name, [$block_label] , [$incr_loop_counter])>

This is the primitive for all control flow transfers. It instructs the C<Fab> core's main processing loop to B<change its read position>.

=over 8

=item *

If C<$block_label> is given, it walks up the Control Stack to find the frame with that primary label. If not, it uses the current (top-most) frame.

=item *

It looks up C<$pointer_name> in that frame's C<pointers> hash.

=item *

If found, it commands the main loop to immediately stop scanning at the current location and resume reading from the retrieved pointer's location (either by seeking in a file or switching to a buffer at a specific offset).

=item *

If not found, it adds a new C<targetToSeek> name, sets the current execution state to "skipping" (this essentially initiates the forward scan).

=back

The C<loop_counter> is incremented by the number in C<$incr_loop_counter> (when the target is found).

=back

=head2 Support of Caching configuration-related data [Planned]

Sometimes a callback may need a computationally expensive combination of individual entries from a configuration hash. (On may
thingk of a regular expression depending on several values in this hash.) To avoid recalculating it every time, the callback may
use the logic like this:

    unless ($cache_at_count == (my $new_cnt = $fab->{config}{cnt__parser_REx})) {
      $cache = my_recalc_cache($Fab);
      $cache_at_count = $new_cnt;
    }

This assumes that C<$fab-E<gt>{config}{cnt__parser_REx}> changes every time one of the variables used by C<my_recalc_cache()> is updated
(or restored). To support this, one register each of these variables with the “dependent counter” C<cnt__parser_REx> using the API:

=over 4

=item * config__append_dependent_counter($counter_key, $KEY1, ...)

=back

(I<Warning:> the implementation is free to change the counter back when a group is undone if it knows all the relevant-and-changed
variables were properly undone. So (theoretically) one cannot rely on the counter to increase-on-modification.

=head1 A tacit assumption — caveat usor

B<Summary:> Before starting a design using C<Text::Fab>, check that inside your preprocessor, the internal representation of the partially processed input can be easily enough kept in the Configuration Hash. We assume that this is going to hold as far as the preprocessor “proceeds with a well-defined I<processing pipeline>”.

---

In many cases one needs to allow the configuration driving the logic of work of a preprocessor to be changeable by a directive at any time. (For example, a text in one programming language may inline a text in another programming language!)

The design of Fab’s API can make this (seem to be?) hard: (due it its up→down approach to the search of directives) the directive above would B<interrupt> the input to the preprocessor; — but sometimes the preprocessor may need a non-local view on the input to decide how to deal with it. “Just seeing what comes I<before> the directive”, then “Just seeing what comes I<after> the directive” (in a separate invocation!) may be not enough for such a non-local view.

On the other hand, one should be ready for the situation when I<the input after> this directive B<should> be handled differently than I<the input before> this directive. So if the target domain I<requires> handling such situations, then I<any implementation> of such a preprocessor B<must> be ready to deal with such hiccups when processing the input (either by handling the update of its config, or bulking out with an error message). While doing this with a bottom→up design may  seem easier, the experience shows that often it is prohibitively hard to implement.  (E.g., when nested constructions are dealt with by recursive calls, the calls to C<reconfigure_me()> would happen deep inside the stack of recursive calls!)

B<In short:> to implement such a design through C<Text::Fab> the only possible complication is: how to I<preserve the internal representation> of the “preceding not-yet-fully-digested input” within the preprocessor “when the preprocessor is reentered” after handling such a directive?

With the bottom→up approach (when the preprocessor may “call some API” to handle the directive) this is easy: it is easy to make sure that such a call may update “the configuration” of the preprocessor while keeping “the internal representation of the already-read-input-to-preprocess” fully intact. However, when the preprocessor is controlled from a Fab, what happens instead of “calling the API” is: “exit the preprocessor”, then somebody else (the Fab!) calling the API, then “reenter the preprocessor again”. Therefore when the preprocessor can see that the chunk it obtained is a part of “some larger construct” (so it is not ready to be C<flush()>'ed to the output section yet), it must preserve its internal state “somewhere”, then read it back when it is reentered (B<if> it is ever reentered).  This is B<the price to pay> for (a lot of) work offloaded to Fab.

B<CONCLUSION:>

=over 4

=item 1.

In such situations the preprocessor needs a guarantee that it is going to be reentered;

=item 2.

Its internal data should be easily translatable to/from formats supported by the configuration hash.

=back

(Indeed, this hash is the only supported storage provided by Fab’s API.)

In other words: the preprocessor cannot be stateless now, but as far as the state may be (de)serialized easily, it is not a big deal. So oen possible tacit assumption about designs using C<Text::Fab> may be:

=over 4

=item

The preprocessing is hierarchical, each level of hierarchy of not-yet-fully-processed-input may be put into a value suitable for the Configuration Hash, and the B<steps remaining> to finish processing these data are not affected by the directive above.

=back

B<————————————————————————————————————>

Next, inspect how not-stateless but still “easy to implement” preprocessors may look like.

B<Example B:> We have a text which may contain nested “blocks”, each block made of one or more paragraphs. The nesting is defined by the indent level (as in Python). The “class” of each block is determined by inspecting the immediate start of the its first paragraph, as well as inspecting the immediate end of the last paragraph of block (provided this last paragraph is “on the same indent level as the start” — so it is not in a nested subblock).

In addition to this we allow #define directives which take a whole line — but are not considered as interrupting the logic of indentation-which-defines-nested-depth.

B<Implementation:> To implement “reenteracy”, the stored data consists of the stack of already-preprocessed text of non-yet-finished blocks. When preprocessing a chunk of input finishes a block, the preprocessor can inspect its start and end, determine its class, C<pop()>'s the known “intermediate textural representation” from the stack, and converts it to the final representation in the way suitable for this class. When this was the outermost block, the result is put into the output section. Otherwise it is appended to the preceding entry on the stack (the containing block).

B<————————————————————————————————————>

B<Example H:> As above, but the rules for massaging a block depend not only on its class, but also on the classes of its parents.  This requires “the most general” I<hierarchical model> of the pipeline of not-yet-fully-processed input.

In this case again the handled data may be C<flush()>'ed to an output section only when the outermost encountered block is terminated. Until then, one should maintain the stack of “live blocks” (not yet terminated), as well as a forest of “dead” (already terminated, but waiting the finite processing) blocks. Each terminated block has its class and the list of content, elements are either “a literal text” (preprocessed-except-the-final-step), or another (nested) terminated sub-block. The live blocks are likewise, but the class is not yet fully known, and the last nested sub-block may be live.

How to preserve this in the Configuration Hash? We have a planar rooted tree with vertices assigned the class (or C<undef> for live vertices), and leaves containing “a plain text”. When C<flush()>'ing to an output section, we essentially scan depth-first through the vertices, maintaining the stack of classes (they correspond to the path from the root to the current vertex). So the only bookkeeping data in addition to the stack of classes is the (parallel) stack of “where the currently-not-yet-finished sub-block ends”. (So we can C<pop()> the stack of classes when this end is reached.)

So if we store the leaves in the depth-first order, we need to interlace this list with markers “start sub-block of the class C<CLASS> ending at position C<POS>” (or introduce nested C<start> and C<end> markers). To design an easy representation, suppose that the semantic of “massaging the blocks” allows introdution of empty "plain text leaves" between every two adjacent sub-vertices; then we may assume that “end-subblock” entries are represented by out-of-bound elements (e.g., C<undef>), and the plain text leaves are alternating with “start subblock” entries in the stored list, as in flattened list of the following form:

    0thLlvTxt1
      Blk1
        1stLvl1Txt11
          Blk11
            2ndLvl1Txt111
          undef
        1stLvl1Txt12
          Blk12
            2ndLvl1Txt121
          undef
        1stLvl1Txt13
      undef
    0thLlvTxt2
      Blk2
        1stLvl1Txt21
          Blk21
            2ndLvl1Txt211
          undef
        1stLvl1Txt22
          Blk22
            2ndLvl1Txt221
          undef
        1stLvl1Txt23
      undef
    0thLlvTxt3

Observe alternation C<Txt>/C<BlkClass>/C<Txt>/C<BlkClass>/C<Txt>/… after every C<undef>. It is trivial to process such a list when C<flush()>'ing. When filling the list, one should additionally maintain a stack of positions in this list where live block starts, so one can change a placeholder-for-its-class to the calculated class when the end-of-block is found. (Other than this, all the results of pre-processing the input land at the end of the list.)

B<————————————————————————————————————>

B<Example A:> Consider a macroprocessor for macros with arguments; assume that the argument-separators and argument-terminators for a macro on a certain level of nesting may be contained in the output of nested-deeper macros. So one needs to expand the deeper macros I<before> the handling of enclosing macros is finished. Can one support directives occuring deep inside the nested arguments — but we assume they cannot be contained in the macro-expansions?

Here the data may be even easier than in the preceding example. Since the output produced up to the start of the outermost no-yet-terminated macro may be C<flash()>'ed, the stack of unprocessed data may contain the ID of the outermost no-yet-terminated macro, the list of its completed arguments, then the already expanded prefix of the current argument, then the ID of the next no-yet-terminated macro, the list of its completed arguments etc. In addition to this list, it is enough to have the list of offsets at which the IDs of the macros live.

When a terminator of a macro is found, one pops from the list above the macro ID and the completed arguments, and performs the macrosubstitution. There are two ways to proceed with this string: it is either appended to “the already expanded prefix of the current argument” (as above) of the enclosed macro (if the expansion should not be macro-re-expanded) — and optionally scanned for macro-argument-delimiter or -terminator, or it is prepended to the buffer containing the not-yet-processed input (otherwise). The desired choice is determined by the semantic of the macro-expansion.

B<————————————————————————————————————>

B<Example E:> As above, but the directives may appear as the result of macro-expansion.

This case is much more involved, since it seems it is too late for the Fab to inspect the internal state of the macro-processor. So the preprocessor should scan its output itself: it has the full access to the B<De-Interlacer/Parser/etc> callbacks designed to detect the directives.

B<WARNING:> However, the directives are not designed to work with not-yet-completed buffers. For best result, De-Interlacer should return “the high-water mark”: the offset before which the directives cannot appear — so there is no sense to rescan this part when the buffer is extended.

=head1 ERROR REFERENCE

The preprocessor will halt with one of the following error codes if a fatal condition is met.

=head2 B<< Parsing and Input Errors (C<E_Input>) >>

=over 4

=item *

C<E_SYNTAX_ERROR>: A directive does not conform to the grammar.

=item *

C<E_FILE_READ_ERROR>: An C<#include>d file cannot be opened or read.

=item *

C<E_CYCLIC_INCLUDE>: An C<#include> chain references a file that is already being processed.

=back

=head2 B<< Grouping Errors (C<E_Group>) >>

=over 4

=item *

C<E_MISMATCHED_END_GROUP>: An C<#end_group E<lt>flavorE<gt>> does not match the currently open group.

=item *

C<E_DANGLING_END_GROUP>: An C<#end_group> is found with no matching C<#start_group>.

=item *

C<E_INVALID_GROUP_NESTING>: An attempt to nest groups in a way forbidden by the Configuration.

=item *

C<E_UPLEVEL_TOO_DEEP>: An C<uplevel> directive targets a group or call stack level that does not exist.

=back

=head2 B<< Configuration Errors (C<E_Config>) >>

=over 4

=item *

C<E_TYPE_MISMATCH>: A list-specific operation is attempted on a scalar key, or vice-versa.

=item *

C<E_LONG_POP>: Popping too many elements.

=back

=head2 B<< Namespace and Assembly Errors (C<E_Assembly>) >>

=over 4

=item *

C<E_CYCLIC_INHERITANCE>: An C<#set_parents> directive creates a loop in the inheritance DAG.

=item *

C<E_UNDEFINED_PARENT>: An C<#set_parents> directive refers to a non-existent namespace.

=item *

C<E_ROOT_NOT_FOUND>: A section specified via C<#set_root> does not exist.

=item *

C<E_NO_ROOTS_SPECIFIED>: The assembly phase is triggered, but no roots were ever defined.

=item *

C<E_EMBED_NOT_FOUND>: A section referenced by an C<#emb> placeholder cannot be resolved.

=item *

C<E_CIRCULAR_EMBED>: An C<#emb> chain results in a loop during the final assembly.

=back

=head2 B<< Control Flow Errors (C<E_Control>) [Planned] >>

=over 4

=item *

C<E_MISMATCHED_CONTROL_END>: An end directive (e.g., C<#endif>) was encountered, but the currently open control block is of a different type (e.g., a C<#for> loop).

=item *

C<E_DANGLING_CONTROL_END>: An end directive was encountered when the Control Stack was empty.

=item *

C<E_UNCLOSED_CONTROL_BLOCK>: The end of an input file was reached while one or more control blocks were still open.

=item *

C<E_POINTER_NOT_FOUND>: A C<control__jump_to> call referenced a pointer name that has not been defined in the target control block.

=item *

C<E_BLOCK_LABEL_NOT_FOUND>: A C<control__jump_to> call referenced a block label that does not exist on the Control Stack, and was not found before the end of the enclosing block.

B<Payload:> C<(target_pointer_name, block_label)>

=back

B<[PLACEHOLDERS]>

Future sections will detail the full APIs and default implementations for:

=over 4

=item *

B<The Parser:> How it interacts with the main loop and calls primitives.

=item *

B<Chunk Preprocessors:> The interface for the "stomach".

=item *

B<Blinder Subroutines:> The data structures passed to them.

=item *

B<The default configuration schema> under the C<Fab/> key:

=over 8

=item C<Fab/callbacks>

A hash reference containing the operational engine callbacks: C<interleaver>, C<directive_parser>,
C<chunk_preprocessor>, C<comment_recognizer>, and C<error_handler>. The C<comment_recognizer> callback
receives C<($fab, $buffer, $offset)> and returns the offset after the comment line if recognized (defaulting
to lines prefixed with C<##>), which triggers chunk fusion across the comment boundary.

=back

=back

=head2 EXPORT

None by default.

=head1 TODO

The default mode of process is equivalent to writing to a buffer C<__default__>, and at the end executing the file

	= = = = = filterbuffer(raw) __default__

Doing the same abstraction once more, the buffer with that contents may be also created dynamically, then loaded via filterbuffer().
On the gripping hand, this may be also

	= = = = = filterbuffer(raw) __default__pre
	= = = = = filterbuffer(raw) __default__
	= = = = = filterbuffer(raw) __default__post

With (initially) empty buffers C<__default__pre> and C<__default__post> (to which one has a chance to write later!).  And what one
writes to these buffers may be triplicated likewise.  Etc.

For postponed actions need an extra argument "ignore errors": with 2 would just put into eval, with 1 converted to a warning,
negative values stop the remaining undo actions for that many frames (with -2 stopping for the current frame and one more).

One needs to prohibit C<__get()>ing a reference.  Use C<__getref>() when you expect a reference (but no checks for reference are
performed).

B<MISS:> C<input__end($n)> with C<$n==0> ending the current input stream, or also C<$n> enclosing streams.

B<MISS:> need to specify what happens with a group on C<input__end()>: survives / should be closed before / close-if-still-open.

B<MISS:> C<input__end_to($group_type)>: end input of the files opened up to the the opened-latest-group of the given type.

  Likewise for “closing enclosed groups”???  Join together into 1 API by introducing suitable groups???

    May run forever???  Even the language if group__start, group_end, group__postpone (with the arguments to the last command
    restricted to these 3 calls) is probably Turing complete???

B<MISS:> _-prefixed versions of C<config__*()> which check the prefix C<_ __ ___> of the key and make it read/write only.

B<MISS:> pipelining preprocessor with “filters”: filters consists of 3 components: preprocessor, massaging of promises, and the
concatenator of the resulting candidates-for-sections.

Uplevel w.r.t. the recursion stack should be recalculated into the usual uplevels; a special do-nothing group may be used.

allow not 1 active preprocessor engine, but a stack of them, chained, and have a C<cfg__pop()> primitive method.

Macros are templates marked as OK-to-be-ignored.

Hash to mark macros as “types”, with per-type-warning configurable?  Which way to hash, types to macros, or macros to types, or
pairs???

An extra parameter C<$is_replay> for the syntax callbacks for the non-first pass.  (Probably, the boundary of the preceding pass cannot
be part of this???

hash keys.  Setting/getting them employs a serialization method, by default JSON???

     !!!!!!!!!!!!!!!!!!!!!!!!!!!!	THIS IS TOO DANGEROUS.
					Access control to Fab/* keys should be guarded by ungettable/settable types of values ???

C<#unset> — but maybe it is going to make undo harder???

Recursive invocation is needed for massaging data between different levels:

    • The hash
    • Input file names
    • Input strings
    • Output sections

A top→down approach to recognizing the “reconfiguration directives”: but cannot
we support a bottom→up approach too, when the preprocessor recognizes interlaced
directives?  How to deal with recursion: return an indicator that the state
changed?  But it is changing permanently, one needs to filter out changes — but how
the internal calls know the filters needed for the enclosing calls???

the preprocessor needs a guarantee that it is going to be reentered

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ilya Zakharevich, E<lt>ilyaz@cpan.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025, 2026 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
