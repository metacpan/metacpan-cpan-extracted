package Text::Fab;

use 5.022;
use strict;
use warnings;

our $VERSION = '0.01';

#use Storable 'dclone'; # For group snapshots (does not support CODE references in data!)
use FreezeThaw qw(safeFreeze thaw); # For group snapshots

sub dclone ($) {(thaw safeFreeze shift)[0]}	# return scalar even in scalar content

# --- Default Callbacks ---
# These are the "smart" components that define the default language.
# A user can replace any of these by setting the config hash.

# Finds the start of the next directive.
sub _default_interleaver {
    my ($buffer, $offset) = @_;
    # A directive is a '#' at the beginning of a line.
    # We search for a newline, then check if it's followed by '#'.
    # A special case handles a '#' at the very start of the buffer.
    return 0 if $offset == 0 && substr($buffer, 0, 1) eq '#';
    my $pos = index($buffer, "\n#", $offset-1);
    return $pos == -1 ? undef : $pos + 1;
}

# Parses a directive and calls the corresponding Fab primitive.
sub _default_directive_parser {
    my ($fab, $buffer, $offset) = @_;
    my $line_end = index($buffer, "\n", $offset);
    $line_end = length($buffer) if $line_end == -1;

    my $directive_line = substr($buffer, $offset, $line_end - $offset);
#    warn("Drctv_ln: <<<$directive_line>>>");

    if ($directive_line =~ /^#(\w+)\s*(.*)/) {
        my ($directive, $args) = (lc $1, $2);
        $args =~ s/\s+$//; # Trim trailing whitespace
#        warn("Drctv: <<<$directive>>>, <<<$args>>>");
        
        # This dispatch table maps the user-facing syntax to the stable
        # internal API of primitive operations.
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
            # The inheritance graph is stored in a structured way in the config.
            $fab->cfg__set("Fab/inheritance_graph/$ns/parents", \@parents);
        }
        elsif ($directive eq 'emb') {
            my ($basename, $ns) = ($args =~ /(\w+)(?:\s+in\s+(\w+))?/);
            $fab->out__embed($basename, $ns, {});
        }
        elsif ($directive eq 'start_group') {
            $fab->group__start($args);
        }
        elsif ($directive eq 'end_group') {
            $fab->group__end($args);
        }
        else {
            $fab->_handle_error('unknown_directive', { directive => $directive, line => $directive_line });
        }
    }
    else {
        $fab->_handle_error('malformed_directive', { line => $directive_line });
    }
    
    return $line_end + 1; # Resume processing after this directive line.
}

# The default "stomach" - processes text chunks between directives.
sub _default_chunk_preprocessor {
    my ($fab, $chunk) = @_;
    # By default, it does nothing but return the text.
    return $chunk;
}

# The default error handler - fail fast.
sub _default_error_handler {
    my ($fab, $type, $details) = @_;
    die "Fab Error ($type): $details->{line}\n";
}

# --- Core Class ---

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    # The entire state of the system is held in these hashes.
    $self->{config} = {
        # Meta-configuration: which keys are lists.
        'Fab/list_keys' => { 'Fab/list_keys' => 1 },
        'Fab/hash_keys' => {},
        'Fab/hash_key_sort_order' => sub { $a cmp $b }, # Default sort for hash keys
        # State for recursive processing.
        'Fab/call_stack_prefixes' => ['Fab/'],
        # The user-configurable components that define the language.
        'Fab/callbacks' => {
            interleaver        => \&_default_interleaver,
            directive_parser   => \&_default_directive_parser,
            chunk_preprocessor => \&_default_chunk_preprocessor,
            error_handler      => \&_default_error_handler,
        },
        # The inheritance graph is just another part of the configuration.
        'Fab/inheritance_graph' => {},
    };
    $self->{sections}       = {}; # { namespace => { basename => \@chunks } }
    $self->{current_target} = ['_main', 'body']; # Default output target.
    $self->{group_stack}    = [];

    # Allow user to provide an initial configuration.
    if ($args{config}) {
        # A real implementation would merge recursively.
        %{$self->{config}} = (%{$self->{config}}, %{$args{config}});
    }

    return $self;
}

# The main processing loop, driven by the callbacks.
sub process_string {
    my ($self, $string) = @_;
    my $offset = 0;
    
    my $callbacks = $self->cfg__get_prefixed('Fab/callbacks');
    my ($interleaver, $parser, $preprocessor) = 
        @{$callbacks}{qw(interleaver directive_parser chunk_preprocessor)};

    while ($offset < length($string)) {
        my $directive_start = $interleaver->($string, $offset);

        if (!defined $directive_start) {
            $self->_process_chunk(substr($string, $offset), $preprocessor);
            last;
        }

        my $chunk_text = substr($string, $offset, $directive_start - $offset);
        $self->_process_chunk($chunk_text, $preprocessor);
        
        $offset = $parser->($self, $string, $directive_start);
    }
}

sub _process_chunk {
    my ($self, $chunk_text, $preprocessor) = @_;
    # Remove leading newline that results from splitting by `\n#`.
    $chunk_text =~ s/^\n//;
    return unless length $chunk_text;
    
    my ($ns, $basename) = @{$self->{current_target}};
    my $processed_chunk = $preprocessor->($self, $chunk_text);
    push @{$self->{sections}{$ns}{$basename}}, ['text', $processed_chunk];
}

sub _handle_error {
    my ($self, $type, $details) = @_;
    my $handler = $self->cfg__get_prefixed('Fab/callbacks')->{error_handler};
    $handler->($self, $type, $details);
}

# --- Primitive API (the stable interface for parsers) ---

sub out__target_section { my ($self, $basename, $namespace) = @_; $namespace //= $self->{current_target}->[0]; $self->{current_target} = [$namespace, $basename]; $self->{sections}{$namespace}{$basename} //= []; }
sub out__embed { my ($self, $basename, $namespace, $options) = @_; my ($target_ns, $target_basename) = @{$self->{current_target}}; $namespace //= $target_ns; push @{$self->{sections}{$target_ns}{$target_basename}}, ['embed', $namespace, $basename, $options]; }
sub cfg__set { my ($self, $key, $value) = @_; $self->{config}{$key} = $value; }
sub cfg__append { my ($self, $key, @values) = @_; if ($self->{config}{'Fab/list_keys'}{$key}) { push @{$self->{config}{$key}}, @values; } else { $self->{config}{$key} .= join('', @values); } }
sub cfg__get { my ($self, $key) = @_; return $self->{config}{$key}; }
sub cfg__get_prefixed { my ($self, $key) = @_; for my $prefix (reverse @{$self->{config}{'Fab/call_stack_prefixes'}}) { my $full_key = $prefix . $key; return $self->{config}{$full_key} if exists $self->{config}{$full_key}; } return $self->{config}{$key}; }
sub group__start { my ($self, $flavor) = @_; push @{$self->{group_stack}}, { config => dclone($self->{config}) }; }
sub group__end { my ($self, $flavor) = @_; my $snapshot = pop @{$self->{group_stack}} or die; $self->{config} = $snapshot->{config};}
sub cfg__pop {
    my ($self, $key, @args) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        die "cfg__pop on a list key accepts at most one argument (a count)" if @args > 1;
        my $count = @args ? $args[0] : 1;
        my $list = $self->{config}{$key} or return;
        die "cfg__pop expected array reference for key '$key'" unless ref $list eq 'ARRAY';
        die "cfg__pop cannot pop $count elements from list of size " . scalar(@$list) if $count > @$list;
        my @popped = splice @$list, -$count;
        return wantarray ? @popped : $popped[-1];
    }
    elsif ($type eq 'hash') {
        # Silently a no-op if no keys are provided.
        return wantarray ? () : undef unless @args;
        my @keys_to_delete = @args;
        my $hash = $self->{config}{$key} or return;
        die "cfg__pop expected hash reference for key '$key'" unless ref $hash eq 'HASH';
        my @deleted_values = delete @{$hash}{@keys_to_delete};
        return wantarray ? @deleted_values : $deleted_values[0];
    }
    else {
        # This branch handles scalars. A pop on a scalar is only valid with no args.
        die "cfg__pop with arguments can only be called on list or hash keys" if @args;
        die "cfg__pop called on non-list/non-hash key '$key'";
    }
}
sub cfg__prepend_elt {
    my ($self, $key, $offset, $value) = @_;
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        $self->{config}{$key} //= [];
        my $list = $self->{config}{$key};
        die "cfg__prepend_elt expected array reference for key '$key'" unless ref $list eq 'ARRAY';
        splice @$list, $offset, 0, $value;
        return;
    }
    elsif ($type eq 'hash') {
        die "cfg__prepend_elt on hash requires value to be an array reference of a [key, value] pair"
            unless ref $value eq 'ARRAY' && @$value == 2;
        $self->{config}{$key} //= {};
        my $hash = $self->{config}{$key};
        die "cfg__prepend_elt expected hash reference for key '$key'" unless ref $hash eq 'HASH';
        $hash->{$value->[0]} = $value->[1];
        return;
    }
    else {
        die "cfg__prepend_elt called on non-list/non-hash key '$key'";
    }
}
sub cfg__get_joined {
    my ($self, $key, $joiners, $options) = @_;
    die "cfg__get_joined requires an array reference for joiners"
        unless ref $joiners eq 'ARRAY';
    my $type = $self->_get_key_type($key);

    if ($type eq 'list') {
        my $list = $self->{config}{$key} or return '';
        die "cfg__get_joined expected array reference for key '$key'" unless ref $list eq 'ARRAY';
        return $self->_join_list($list, $joiners, $options);
    }
    elsif ($type eq 'hash') {
       my $hash = $self->{config}{$key} or return '';
       my @sorted_keys = $self->_get_sorted_hash_keys($key);
       my $intra_pair_joiner = $joiners->[0];
       my @inter_pair_joiners = @$joiners > 1 ? @$joiners[1..$#$joiners] : ($#$joiners == 0 ? [$joiners->[0]] : []);
       my @joined_pairs = map { $_ . $intra_pair_joiner . $hash->{$_} } @sorted_keys;
       return $self->_join_list(\@joined_pairs, \@inter_pair_joiners, $options);
    }
    else {
        die "cfg__get_joined called on non-list/non-hash key '$key'";
    }
}
sub out__get_joined {
    my ($self, $spec, $joiners, $options) = @_;
    die "out__get_joined requires an array reference for joiners"
        unless ref $joiners eq 'ARRAY';
    my ($ns, $basename) = split /:/, $spec;
    my $all_chunks = $self->{sections}{$ns}{$basename} or return '';
    my @text_parts = map { $_->[1] } grep { $_->[0] eq 'text' } @$all_chunks;
    return $self->_join_list(\@text_parts, $joiners, $options);
}

# --- Private Helpers ---
sub _get_key_type {
    my ($self, $key) = @_;
    return 'hash' if $self->{config}{'Fab/hash_keys'}{$key};
    return 'list' if $self->{config}{'Fab/list_keys'}{$key};
    return 'scalar';
}
sub _get_sorted_hash_keys {
    my ($self, $key) = @_;
    my $hash = $self->{config}{$key} or return ();
    die "_get_sorted_hash_keys expected hash reference for key '$key'" unless ref $hash eq 'HASH';
    my $sorter = $self->{config}{'Fab/hash_key_sort_order'};
    return sort { $sorter->($a, $b) } (keys %$hash);
}
sub _hash_to_sorted_list {
    my ($self, $key) = @_;
    my $hash = $self->{config}{$key} or return [];
    my @sorted_keys = $self->_get_sorted_hash_keys($key);
    return [ map { $_, $hash->{$_} } @sorted_keys ];
}
sub _join_list {
    my ($self, $list, $joiners, $options) = @_;
    $options //= {};
    my $num_elements = scalar @$list;
    return '' unless $num_elements;
    return $list->[0] if $num_elements == 1;

    my $num_joiners_to_use = $num_elements - 1;
    if (my $mod = $options->{permitted_joiners_modulo}) {
        die "Join operation violates permitted_joiners_modulo rule (want multiple of $mod, got $num_joiners_to_use)"
            if $num_joiners_to_use % $mod != 0;
    }

    my $output = $list->[0];
    for my $i (1 .. $num_joiners_to_use) {
        $output .= $joiners->[($i - 1) % @$joiners] . $list->[$i];
    }
    return $output;
}

# --- Assembly Phase ---

sub assemble {
    my ($self, $root_spec) = @_;
    my ($ns, $basename) = split /:/, $root_spec;
    my $output = $self->_expand_section($ns, $basename, {});
    chomp($output); # Trim final trailing newline.
#    $output =~ s/\s+$//;	# Maybe better (but what for?!) ???
    return $output;
}

sub _expand_section {
    my ($self, $ns, $basename, $seen) = @_;
    my $id = "$ns:$basename";
    die "Circular dependency for section '$id'" if $seen->{$id};
    local $seen->{$id} = 1;

    my $chunks = $self->_resolve_section($ns, $basename);
    return "" unless $chunks;

    my $output = "";
    for my $chunk (@$chunks) {
        my ($type, @data) = @$chunk;
        if ($type eq 'text') {
            $output .= $data[0];
        } elsif ($type eq 'embed') {
            $output .= $self->_expand_section($data[0], $data[1], $seen);
        }
    }
    return $output;
}

sub _resolve_section {
    my ($self, $ns, $basename) = @_;
    return $self->{sections}{$ns}{$basename}
        if exists $self->{sections}{$ns} && exists $self->{sections}{$ns}{$basename};

    my $parents_key = "Fab/inheritance_graph/$ns/parents";
    # FIX: Correctly dereference the array reference of parents.
    for my $parent_ns (@{$self->{config}{$parents_key} || []}) {
        my $chunks = $self->_resolve_section($parent_ns, $basename);
        return $chunks if $chunks;
    }
    return undef;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Fab - A powerful, general-purpose document expansion framework (currently exists mostly as uncomplete documentation and a beginning of a stub of implementation)

=head1 SYNOPSIS

    # -- File: config.fab --   Example of merging multiple files (with almost no content!)
    # Declare which configuration keys will be treated as lists
    #append Fab/list_keys chapters, css_files

    # Set some configuration variables
    #set site_title=My Awesome Book
    #append css_files global.css, theme.css

    # Define the inheritance graph for our namespaces
    #set_parents ChapterLayout BaseLayout
    #set_parents Book _main # The final book inherits from _main's structure

    # -- File: main.fab --
    # The main assembly script. The default output target is '_main:body'.
    #append chapters chapter1, chapter2, chapter3 # Build the chapter list

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

Configuration values can be B<scalars> or B<lists>. A special list, C<Fab/list_keys>, is used to declare which keys should be treated as lists by the primitive operations.

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

=item B<< C<#start_group E<lt>flavor_nameE<gt>> >>

Begins a scope. A certain set of keys in the B<Configuration> hash are snapshotted. The C<flavor_name> is used to look up the list of Configuration keys to memorize/restore.

=item B<< C<#end_group [E<lt>flavor_nameE<gt>]> >>

If a C<flavor_name> is provided, it must be a flavor of an already opened group . All changes made to the observed configuration keys are B<undone>. If the optional name is not given, closes the most recently opened scope.

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

Sets the value of a key.

=item C<cfg__append( $key, @values )>

Appends one or more items to a list key, or appends a string value to a scalar key.

=item C<cfg__prepend( $key, @values )>

Prepends one or more items to a list key, or prepends a string value to a scalar key.

=item C<cfg__get( $key, [$offset] )>

Retrieves the value of a scalar key, or of an element of a list key.

=item C<cfg__get_joined( $key, \@joiners, \%options )>

A powerful utility that retrieves a list-type key and joins its elements into a single string. The C<@joiners> array provides one or more separators that are cycled through when joining. The C<%options> can control complex formatting, for example specify permitted numbers of joiners modulo C<scalar @joiners>. (E.g., if “joiners come in pairs”, then the number of emitted joiners must be even!)

=back

An analogous C<out__get_joined> exists for converting a sections (representable as a list of text-parts and embed-promises) into a single string.

Additionally, one can use C<cfg__pop($key, [$count])>, C<cfg__prepend_elt( $key, $offset, $value )> etc. on a list key. (The parser for directive may implement only the flavors with C<$offset> in 0 and -1 only, e.g., “as if” in C<cfg__prepend_last( $key, $value )> etc.)
C<cfg__pop()> also can be used to C<delete()> one or more subkeys from a hash value (then the C<$count> is replaced by the list of these keys).

=head3 Working with Hashes

In addition to scalars and lists, the framework supports hashes as a first-class
configuration data type. This is controlled by two special configuration keys:

=over 4

=item B<C<Fab/hash_keys>>

Analogous to C<Fab/list_keys>, this is a hash whose keys are the names of
configuration variables that should be treated as hashes by the primitive
operations.

    # In a config file:
    #append Fab/hash_keys my_parameters

=item B<C<Fab/hash_key_sort_order>>

This key holds a subroutine reference that defines how the keys of a hash
should be sorted when the hash needs to be treated as an ordered list (e.g.,
for C<cfg__get_joined>). The subroutine receives two keys as
arguments. The default is standard string comparison.

    # In Perl code, to set numeric sorting:
    $fab->cfg__set('Fab/hash_key_sort_order', sub { $_[0] <=> $_[1] });

=back

=head2 Grouping and C<uplevel> Primitives

=over 4

=item C<group__start( $flavor_name )>

Starts a scoped group.

=item C<group__end( [$flavor_name] )>

Ends a scoped group.

=item C<group__postpone( $depth, $method_name, @args )>

Schedules a C<Text::Fab> method call to be executed just before a group at a specific relative depth is closed. (Since the stack of group names is available in the configuration hash keyed as C<opened_groups>, the parser for directives may allow more user-friendly UI, such as specifying “a path” to this group, as in “the last-but-one C<x> group before the last two C<y> groups.)

=back

=head2 Configuration Prefix API

For recursive processing, the Configuration contains a stack of prefixes at C<Fab/call_stack_prefixes>. Primitives are provided to safely interact with keys relative to this stack. (We list only the most basic retreaval primitives; the rest follows the same principle.)

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

As C<cfg__set_prefixed()>, but goes back C<$level> steps on the stack of prefixes. This matches retreaval via C<cfg__get_prefixed()>.

=item C<cfg__set_prefixed_uplevel_fixup( $level, $key, @values )>

As C<cfg__set_prefixed_uplevel()>, but first runs “fixup”: copying the preceding value at C<$level> to the levels between this one and the current level — stopping when value is found on a particular level. This matches retreaval via C<cfg__get_prefixed()>: this call won’t change the results on the levels between C<$level> and the current one.

=back

=head1 ADVANCED TOPICS

=head2 Input Processing and Recursion

The primitive to support the C<#include> directive is C<include__text($how, $data)>. If C<$how> is C<filename>, the file C<$data> is searched for and slurped; if not, C<$data> is the input string to be processed. A special form C<#include_scoped> ensures that configuration changes made by the included file are temporary by wrapping the call in a group named by the last argument.

Recursive processing (e.g., using one C<Text::Fab> “process” to filter data for another) is managed entirely within the Configuration hash. A stack of configuration prefixes is maintained in C<Fab__call_stack_prefixes> (which usually starts as just C<Fab/>). When a named recursive filter is invoked, its name is pushed to the filer name stack C<Fab__call_stack_filter_name>. This also pushes a certain prefix onto C<Fab__call_stack_prefixes>. Since it is the last prefix on this stack which is actually used by C<Text::Fab> for its operation, this allows a special predefined configuration (e.g., C<Fab/myList2ScalarFilter>) to take precedence without conflicting with the “normal” operation of the Fab.

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

Here C<SubName> provides a completely customizable analog of the previous call. Instead of (or in addition to) obscuring the part of DAG which is not reachable from C<StartNamespace>, the output of this user-defined subroutine obscures an arbitrary subset of the DAG. It receives the entire current embedding stack (each entry is the currently executed embedding promise) together with the start namespace, the used blinder name, and the output of the blinder for each level. It return a dynamic list of namespaces to "blind" for this specific resolution and any sub-resolutions (which may happen during processing of this embedded section).

=back

=head2 Support of Control-Flow-Like constructs (conditionals and/or loops)

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

=head2 Support of Caching configuration-related data

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

C<E_TYPE_UNDECLARED>: A type-specific operation is used on a key whose type has not been declared.

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

=head2 B<< Control Flow Errors (C<E_Control>) >>

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

B<The default configuration schema> under the C<Fab/> key.

=back

=head2 EXPORT

None by default.

=head1 TODO

B<The error messages are not yet in the described format.>

Docs are not cleaned up (mark these by “???”!); and parts are still missing.

The implementation (when it exists) has not been cleaned up yet.

B<MISS:> input__end($n) with $n==0 ending the current input stream, or also $n enclosing streams.  Or maybe better end up to a given
name of a group?

B<MISS:> need to specify what happens with a group on input__end(): survives / should be closed before / close-if-still-open.  (May be
not needed if closing is group-controlled.

B<MISS:> input__end_to($group_type): end input of the files opened up to the the opened-latest-group of the given type.

  Likewise for “closing enclosed groups”???  Join together into 1 API by introducing suitable groups???

May run forever!  Even the language of group__start, group_end, group__postpone (with the arguments to the last command
restricted to these 3 calls) is Turing complete — one can implement a 2-counters machine with this.

B<MISS:> _-prefixed versions of config__*() which check the prefix _ __ ___ of the key and make it read/write only.

B<MISS:> pipelining preprocessor with “filters”: filters consists of 3 components: preprocessor, massaging of promises, and the
concatenator of the resulting candidates-for-sections.

When undoing, undo data should be guarded, at least up to the exit.

Uplevel w.r.t. the recursion stack should be recalculated into the usual uplevels; a special do-nothing group may be used.

allow not 1 active preprocessor engine, but a stack of them, chained, and have a cfg__pop() primitive method.

Macros are templates marked as OK-to-be-not-executed.

Hash to mark macros as “types”, with per-type-warning configurable?  Which way to hash, types to macros, or macros to types, or
pairs???

An extra parameter $is_replay for the syntax callbacks for the non-first pass.  (Probably, the boundary of the preceding pass cannot
be part of this???

hash keys.  Setting/getting them employs a serialization method, by default JSON???

B<uplevel should allow execution AFTER the group is closed>

There should be an indicator that a method is called “from” before/after uplevel.  If uplevel is called “uplevel”ed, it should
only register the requests,; at end of the enclosing processing of the uplevevel-ed stuff, these postponed commands should be
executed (reversing order again???).

  Should reversing of order be customizable, and in which order one should put the inverted group and the non-inverted group????
  Probably better to have more than 2 types, and for every “type” have the pre/post specified, and whether upleveling from the
  group reverses the order???

  The type is a Unicode string starting with either PRE-, or post-, and sorting as if it is appended by ".000"… with an infinite
  number of characters '0' (but before the possible suffix "-inv".  Then sorting lexicographically (with actual closing happening
  between PRE- and post-, and -inv groups inverted gives the order of execution.  (Still: inversion of postponed postpones???)

  When sorting, one can literally pad by ".0"* up to the maximal length of the name of existening groups + 1!

    Note that "string#" comes before "string" for any value of "string", and different strings “sort differently”!

C<#unset> — but maybe it is going to make undo harder???

Recursive invocation is needed for massaging data between different level:

  • The hash
  • Input file names
  • Input strings
  • Output sections

A top→down approach to recognizing the “reconfiguration directives”: but cannot
we support a bottom→up approach too, when the preprocessor recognizes interlaced
directives?  How to deal with recursion: return an indicator that the state
changed?  But it is changing permanently, one needs to filter out changes — but how
the internal calls know the filters needed for the enclosing calls???

the preprocessor needs a guarantee that it is going to be reentered (to postpone operations).  A special call at end???

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

Copyright (C) 2025 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
