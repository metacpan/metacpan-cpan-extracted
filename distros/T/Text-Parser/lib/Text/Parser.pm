use warnings;
use strict;
use feature ':5.14';

package Text::Parser 1.000;

# ABSTRACT: Simplifies text parsing. Easily extensible to parse any text format.


use Moose;
use MooseX::CoverableModifiers;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Moose::Util 'apply_all_roles', 'ensure_all_roles';
use Moose::Util::TypeConstraints;
use String::Util qw(trim ltrim rtrim eqq);
use Text::Parser::Error;
use Text::Parser::Rule;
use Text::Parser::RuleSpec;
use List::MoreUtils qw(natatime first_index);

enum 'Text::Parser::Types::MultilineType' => [qw(join_next join_last)];
enum 'Text::Parser::Types::LineWrapStyle' =>
    [qw(trailing_backslash spice just_next_line slurp custom)];
enum 'Text::Parser::Types::TrimType' => [qw(l r b n)];

subtype 'NonEmptyStr', as 'Str', where { length $_ > 0 },
    message {"$_ is an empty string"};

no Moose::Util::TypeConstraints;
use FileHandle;

has _origclass => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => '',
);


around BUILDARGS => sub {
    my ( $orig, $class ) = ( shift, shift );
    return $class->$orig( @_, _origclass => $class ) if @_ > 1 or not @_;
    my $ptr = shift;
    parser_exception("Invalid parameters to Text::Parser constructor")
        if ref($ptr) ne 'HASH';
    $class->$orig( %{$ptr}, _origclass => $class );
};

sub BUILD {
    my $self = shift;
    ensure_all_roles $self, 'Text::Parser::AutoSplit' if $self->auto_split;
    return if not defined $self->multiline_type;
    ensure_all_roles $self, 'Text::Parser::Multiline';
}


has auto_chomp => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);


has auto_split => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
    trigger => \&__newval_auto_split,
);

sub __newval_auto_split {
    my ( $self, $newval, $oldval ) = ( shift, shift, shift );
    ensure_all_roles $self, 'Text::Parser::AutoSplit' if $newval;
    $self->_clear_all_fields if not $newval and $oldval;
}


has auto_trim => (
    is      => 'rw',
    isa     => 'Text::Parser::Types::TrimType',
    lazy    => 1,
    default => 'n',
);


has custom_line_trimmer => (
    is      => 'rw',
    isa     => 'CodeRef|Undef',
    lazy    => 1,
    default => undef,
);


has FS => (
    is      => 'rw',
    isa     => 'RegexpRef',
    lazy    => 1,
    default => sub {qr/\s+/},
);


has indentation_str => (
    is      => 'rw',
    isa     => 'NonEmptyStr',
    lazy    => 1,
    default => ' ',
);


has line_wrap_style => (
    is      => 'rw',
    isa     => 'Text::Parser::Types::LineWrapStyle|Undef',
    default => undef,
    lazy    => 1,
    trigger => \&_on_line_unwrap,
);

my %MULTILINE_VAL = (
    default            => undef,
    spice              => 'join_last',
    trailing_backslash => 'join_next',
    just_next_line     => 'join_last',
    slurp              => 'join_last',
    custom             => undef,
);

sub _on_line_unwrap {
    my ( $self, $val, $oldval ) = (@_);
    return           if not defined $val and not defined $oldval;
    $val = 'default' if not defined $val;
    return           if $val eq 'custom' and defined $self->multiline_type;
    $self->multiline_type( $MULTILINE_VAL{$val} );
}


has multiline_type => (
    is      => 'rw',
    isa     => 'Text::Parser::Types::MultilineType|Undef',
    lazy    => 1,
    default => undef,
);

around multiline_type => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $oldval = $orig->($self);
    return $oldval if not @_ or eqq( $_[0], $oldval );
    return __newval_multi_line( $orig, $self, @_ );
};

sub __newval_multi_line {
    my ( $orig, $self, $newval ) = ( shift, shift, shift );
    delete $self->{records};    # Bug W/A: role cannot apply if records exists
    ensure_all_roles( $self, 'Text::Parser::Multiline' )
        if defined $newval;
    return $orig->( $self, $newval );
}


has track_indentation => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);


has _obj_rules => (
    is      => 'rw',
    isa     => 'ArrayRef[Text::Parser::Rule]',
    lazy    => 1,
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        _push_obj_rule    => 'push',
        _has_no_obj_rules => 'is_empty',
        _get_obj_rules    => 'elements',
    },
);

sub add_rule {
    my $self = shift;
    $self->auto_split(1) if not $self->auto_split;
    my $rule = Text::Parser::Rule->new(@_);
    $self->_push_obj_rule($rule);
}


sub clear_rules {
    my $self = shift;
    $self->_obj_rules( [] );
    $self->_clear_begin_rule;
    $self->_clear_end_rule;
}


has _begin_rule => (
    is        => 'rw',
    isa       => 'Text::Parser::Rule',
    predicate => '_has_begin_rule',
    clearer   => '_clear_begin_rule',
);

sub BEGIN_rule {
    my $self = shift;
    $self->auto_split(1) if not $self->auto_split;
    my (%opt) = _defaults_for_begin_end(@_);
    $self->_modify_rule( '_begin_rule', %opt );
}

sub _defaults_for_begin_end {
    my (%opt) = @_;
    $opt{dont_record} = 1 if not exists $opt{dont_record};
    delete $opt{if}               if exists $opt{if};
    delete $opt{continue_to_next} if exists $opt{continue_to_next};
    return (%opt);
}

sub _modify_rule {
    my ( $self, $func, %opt ) = @_;
    my $pred = '_has' . $func;
    $self->_append_rule_lines( $func, \%opt ) if $self->$pred();
    my $rule = Text::Parser::Rule->new(%opt);
    $self->$func($rule);
}

sub _append_rule_lines {
    my ( $self, $func, $opt ) = ( shift, shift, shift );
    my $old = $self->$func();
    $opt->{do} = $old->action . $opt->{do};
}


has _end_rule => (
    is        => 'rw',
    isa       => 'Text::Parser::Rule',
    predicate => '_has_end_rule',
    clearer   => '_clear_end_rule',
);

sub END_rule {
    my $self = shift;
    $self->auto_split(1) if not $self->auto_split;
    my (%opt) = _defaults_for_begin_end(@_);
    $self->_modify_rule( '_end_rule', %opt );
}


has _indent_level => (
    is      => 'ro',
    isa     => 'Int|Undef',
    lazy    => 1,
    default => undef,
    writer  => '_set_indent_level',
    reader  => 'this_indent',
);


has _current_line => (
    is       => 'ro',
    isa      => 'Str|Undef',
    init_arg => undef,
    writer   => '_set_this_line',
    reader   => 'this_line',
    clearer  => '_clear_this_line',
    default  => undef,
);


has filename => (
    is        => 'rw',
    isa       => 'Str|Undef',
    lazy      => 1,
    init_arg  => undef,
    default   => undef,
    predicate => '_has_filename',
    clearer   => '_clear_filename',
    trigger   => \&_set_filehandle,
);

sub _set_filehandle {
    my $self = shift;
    return $self->_clear_filename if not defined $self->filename;
    $self->_save_filehandle( $self->__get_valid_fh );
}

sub __get_valid_fh {
    my $self  = shift;
    my $fname = $self->_get_valid_text_filename;
    return FileHandle->new( $fname, 'r' ) if defined $fname;
    $fname = $self->filename;
    $self->_clear_filename;
    $self->_throw_invalid_file_exception($fname);
}

# Don't touch: Override this in Text::Parser::AutoUncompress
sub _get_valid_text_filename {
    my $self  = shift;
    my $fname = $self->filename;
    return $fname if -f $fname and -r $fname and -T $fname;
    return;
}

# Don't touch: Override this in Text::Parser::AutoUncompress
sub _throw_invalid_file_exception {
    my ( $self, $fname ) = ( shift, shift );
    parser_exception("Invalid filename $fname") if not -f $fname;
    parser_exception("Cannot read $fname")      if not -r $fname;
    parser_exception("Not a plain text file $fname");
}


has filehandle => (
    is        => 'rw',
    isa       => 'FileHandle|Undef',
    lazy      => 1,
    init_arg  => undef,
    default   => undef,
    predicate => '_has_filehandle',
    writer    => '_save_filehandle',
    reader    => '_get_filehandle',
    clearer   => '_close_filehandles',
);

sub filehandle {
    my $self = shift;
    return                      if not @_ and not $self->_has_filehandle;
    $self->_save_filehandle(@_) if @_;
    $self->_clear_filename      if @_;
    return $self->_get_filehandle;
}


sub read {
    my $self = shift;
    return if not defined $self->_handle_read_inp(@_);
    $self->_run_begin_end_block('_begin_rule');
    $self->__read_and_close_filehandle;
    $self->_run_begin_end_block('_end_rule');
}

sub _handle_read_inp {
    my $self = shift;
    return $self->filehandle   if not @_;
    return                     if not ref( $_[0] ) and not $_[0];
    return $self->filename(@_) if not ref( $_[0] );
    return $self->filehandle(@_);
}

sub _before_begin {
    my $self = shift;
    $self->forget;
    $self->_preset_vars( $self->_all_preset ) if not $self->_has_no_prestash;
}

sub _after_end {
    my $self = shift;
    my $h    = $self->_hidden_stash;
    $h->{$_} = $self->stashed($_) for ( keys %{$h} );
}

sub _run_begin_end_block {
    my ( $self, $func ) = ( shift, shift );
    $self->_before_begin if $func eq '_begin_rule';
    $self->_run_beg_end__($func);
    $self->_after_end if $func eq '_end_rule';
}

sub _run_beg_end__ {
    my ( $self, $func ) = ( shift, shift );
    my $pred = '_has' . $func;
    return if not $self->$pred();
    my $rule = $self->$func();
    $rule->_run( $self, 0 );
}

sub __read_and_close_filehandle {
    my $self = shift;
    $self->_prep_to_read_file;
    $self->__read_file_handle;
    $self->_final_operations_after_read;
}

sub _prep_to_read_file {
    my $self = shift;
    $self->_reset_line_count;
    $self->_empty_records;
    $self->_clear_abort;
}

sub __read_file_handle {
    my $self = shift;
    my $fh   = $self->filehandle();
    while (<$fh>) {
        last if not $self->__parse_line($_);
    }
}

sub __parse_line {
    my ( $self, $line ) = ( shift, shift );
    $line = $self->_prep_line_for_parsing($line);
    $self->_set_this_line($line);
    $self->save_record($line);
    return not $self->has_aborted;
}

sub _prep_line_for_parsing {
    my ( $self, $line ) = ( shift, shift );
    $self->_next_line_parsed();
    $self->_find_indent_level($line) if $self->track_indentation;
    $line = $self->_line_manip($line);
}

sub _find_indent_level {
    my ( $self, $line ) = ( shift, shift );
    chomp $line;
    length( $self->indentation_str ) >= 2
        ? $self->_find_long_indent_level($line)
        : $self->_singlechar_indent($line);
}

sub _find_long_indent_level {
    my ( $self, $line ) = ( shift, shift );
    my $n = _num_matching( $self->indentation_str, $line );
    $self->_set_indent_level($n);
}

sub _num_matching {
    my ( $ch, $line ) = ( shift, shift );
    my $it = natatime( length($ch), ( split //, $line ) );
    my ( $i, @x ) = ( 0, $it->() );
    while ( $ch eq join( '', @x ) ) {
        ( $i, @x ) = ( $i + 1, $it->() );
    }
    return $i;
}

sub _singlechar_indent {
    my ( $self, $line ) = ( shift, shift );
    my $n = first_index { $_ ne $self->indentation_str } ( split //, $line );
    $self->_set_indent_level($n);
}

sub _line_manip {
    my ( $self, $line ) = ( shift, shift );
    return $self->_def_line_manip($line)
        if not defined $self->custom_line_trimmer;
    my $cust = $self->custom_line_trimmer;
    return $cust->($line);
}

sub _def_line_manip {
    my ( $self, $line ) = ( shift, shift );
    chomp $line if $self->auto_chomp;
    return $self->_trim_line($line);
}

sub _trim_line {
    my ( $self, $line ) = ( shift, shift );
    return $line        if $self->auto_trim eq 'n';
    return trim($line)  if $self->auto_trim eq 'b';
    return ltrim($line) if $self->auto_trim eq 'l';
    return rtrim($line);
}

sub _final_operations_after_read {
    my $self = shift;
    $self->_close_filehandles if $self->_has_filename;
    $self->_clear_this_line;
    $self->_set_indent_level(undef) if $self->track_indentation;
}


sub last_record {
    my $self  = shift;
    my $count = $self->_num_records();
    return if not $count;
    return $self->_access_record( $count - 1 );
}


has records => (
    isa        => 'ArrayRef[Any]',
    is         => 'ro',
    lazy       => 1,
    default    => sub { return []; },
    auto_deref => 1,
    init_arg   => undef,
    traits     => ['Array'],
    predicate  => '_has_records_attrib',
    handles    => {
        get_records    => 'elements',
        push_records   => 'push',
        pop_record     => 'pop',
        _empty_records => 'clear',
        _num_records   => 'count',
        _access_record => 'accessor',
    },
);


has _stashed_vars => (
    is      => 'ro',
    isa     => 'HashRef[Any]',
    default => sub { {} },
    lazy    => 1,
    traits  => ['Hash'],
    handles => {
        _clear_stash    => 'clear',
        _stashed        => 'elements',
        _has_stashed    => 'exists',
        _forget         => 'delete',
        has_empty_stash => 'is_empty',
        _get_vars       => 'get',
        _preset_vars    => 'set',
    }
);

sub forget {
    my $self = shift;
    return $self->_forget_stashed(@_) if @_;
    $self->_clear_stash;
}

sub _forget_stashed {
    my $self = shift;
    foreach my $s (@_) {
        $self->_forget($s)       if $self->_has_stashed($s);
        $self->_del_prestash($s) if $self->_has_prestash($s);
    }
}

sub stashed {
    my $self = shift;
    return $self->_get_vars(@_) if @_;
    return $self->_stashed;
}

sub has_stashed {
    my $self = shift;
    return 1 if $self->_has_stashed(@_);
    return $self->_has_prestash(@_);
}

has _hidden_stash => (
    is      => 'ro',
    isa     => 'HashRef[Any]',
    default => sub { {} },
    lazy    => 1,
    traits  => ['Hash'],
    handles => {
        prestash         => 'set',
        _all_preset      => 'elements',
        _has_prestash    => 'exists',
        _has_no_prestash => 'is_empty',
        _del_prestash    => 'delete',
    }
);


has lines_parsed => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    init_arg => undef,
    default  => 0,
    traits   => ['Counter'],
    handles  => {
        _next_line_parsed => 'inc',
        _reset_line_count => 'reset',
    }
);


has abort => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
    traits  => ['Bool'],
    reader  => 'has_aborted',
    handles => {
        abort_reading => 'set',
        _clear_abort  => 'unset'
    },
);


has _is_wrapped => (
    is      => 'rw',
    isa     => 'CodeRef|Undef',
    default => undef,
    lazy    => 1,
);

has _unwrap_routine => (
    is      => 'rw',
    isa     => 'CodeRef|Undef',
    default => undef,
    lazy    => 1,
);

sub custom_line_unwrap_routines {
    my $self = shift;
    $self->_prep_for_custom_unwrap_routines;
    my ( $is_wr, $un_wr ) = _check_custom_unwrap_args(@_);
    $self->_is_wrapped($is_wr);
    $self->_unwrap_routine($un_wr);
}

sub _prep_for_custom_unwrap_routines {
    my $self = shift;
    my $s    = $self->line_wrap_style();
    parser_exception("Line wrap style already set to $s")
        if defined $s and 'custom' ne $s;
    $self->line_wrap_style('custom');
}

my $unwrap_prefix = "Bad call to custom_line_unwrap_routines: ";




sub save_record {
    my ( $self, $record ) = ( shift, shift );
    ( $self->_has_no_rules )
        ? $self->push_records($record)
        : $self->_run_through_rules;
}

sub _has_no_rules {
    my $self = shift;
    return 0 if Text::Parser::RuleSpec->class_has_rules( $self->_origclass );
    return $self->_has_no_obj_rules;
}

sub _run_through_rules {
    my $self = shift;
    my (@crules) = Text::Parser::RuleSpec->class_rules( $self->_origclass );
    foreach my $rule ( @crules, $self->_get_obj_rules ) {
        next if not $rule->_test($self);
        $rule->_run( $self, 0 );
        last if not $rule->continue_to_next;
    }
}


my %IS_LINE_CONTINUED = (
    default            => \&_def_is_line_continued,
    spice              => \&_spice_is_line_contd,
    trailing_backslash => \&_tbs_is_line_contd,
    just_next_line     => \&_jnl_is_line_contd,
    slurp              => \&_def_is_line_continued,
    custom             => undef,
);

my %JOIN_LAST_LINE = (
    default            => \&_def_join_last_line,
    spice              => \&_spice_join_last_line,
    trailing_backslash => \&_tbs_join_last_line,
    just_next_line     => \&_jnl_join_last_line,
    slurp              => \&_def_join_last_line,
    custom             => undef,
);

sub is_line_continued {
    my $self = shift;
    return 0 if not defined $self->multiline_type;
    my $routine = $self->_get_is_line_contd_routine;
    parser_exception("is_wrapped routine not defined")
        if not defined $routine;
    $routine->( $self, @_ );
}

sub _val_of_line_wrap_style {
    my $self = shift;
    defined $self->line_wrap_style ? $self->line_wrap_style : 'default';
}

sub _get_is_line_contd_routine {
    my $self = shift;
    my $val  = $self->_val_of_line_wrap_style;
    ( $val ne 'custom' )
        ? $IS_LINE_CONTINUED{$val}
        : $self->_is_wrapped;
}

sub join_last_line {
    my $self    = shift;
    my $routine = $self->_get_join_last_line_routine;
    parser_exception("unwrap_routine not defined")
        if not defined $routine;
    $routine->( $self, @_ );
}

sub _get_join_last_line_routine {
    my $self = shift;
    my $val  = $self->_val_of_line_wrap_style;
    ( $val ne 'custom' )
        ? $JOIN_LAST_LINE{$val}
        : $self->_unwrap_routine;
}

sub _def_is_line_continued {
    my $self = shift;
    return 0
        if $self->multiline_type eq 'join_last'
        and $self->lines_parsed() == 1;
    return 1;
}

sub _spice_is_line_contd {
    my $self = shift;
    substr( shift, 0, 1 ) eq '+';
}

sub _tbs_is_line_contd {
    my $self = shift;
    substr( trim(shift), -1, 1 ) eq "\\";
}

sub _jnl_is_line_contd {
    my $self = shift;
    return 0 if $self->lines_parsed == 1;
    return length( trim(shift) ) > 0;
}

sub _def_join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    return $last . $line;
}

sub _spice_join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    chomp $last;
    $line =~ s/^[+]\s*/ /;
    $last . $line;
}

sub _tbs_join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    chomp $last;
    $last =~ s/\\\s*$//;
    rtrim($last) . ' ' . ltrim($line);
}

sub _jnl_join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    chomp $last;
    return $last . $line;
}


__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser - Simplifies text parsing. Easily extensible to parse any text format.

=head1 VERSION

version 1.000

=head1 SYNOPSIS

The following prints the content of the file (named in the first argument) to C<STDOUT>.

    use Text::Parser;

    my $parser = Text::Parser->new();
    $parser->read(shift);
    print $parser->get_records, "\n";

The above code prints after reading the whole file, which can be slow if you have large fules. This following prints contents immediately.

    my $parser = Text::Parser->new();
    $parser->add_rule(do => 'print', dont_record => 1);
    ($#ARGV > 0) ? $parser->filename(shift) : $parser->filehandle(\*STDIN);
    $parser->read();       # Runs the rule for each line of input file

Also, the third line there allows this program to read from a file name specified on command-line, or C<STDIN>. In effect, this makes this Perl code a good replica of the UNIX C<cat>.

Here is an example with a simple rule that extracts the first error in the logfile and aborts reading further:

    my $parser = Text::Parser->new();
    $parser->add_rule(
        if => '$1 eq "ERROR:"',
            # $1 is a positional identifier for first 'field' on the line
        do => '$this->abort_reading; return $_;'
            # $this is copy of $parser accessible from within the rule
            # abort_reading() tells parser to stop reading further
            # Returned values are saved as records. Any data structure can be saved.
            # $_ contains the full line as string, including any whitespaces
    );
    
    # Returns the first line starting with "ERROR:"
    $parser->read('/path/to/logfile');

    print "Some errors were found:\n" if $parser->get_records();

See L<this important note|Text::Parser::Manual::ExtendedAWKSyntax/"Important note about quotes"> about using single quotes instead of double quotes.

Here is an example that parses a table with field separators indicated by C<|> character:

    use Data::Dumper 'Dumper';
    my $table_parser = Text::Parser->new( FS => qr/\s*[|]\s*/ );
    $table_parser->add_rule(
        if          => '$this->NF == 0',
        dont_record => 1
    );
    $table_parser->add_rule(
        if => '$this->lines_parsed == 1',
        do => '~columns = [$this->fields()];'
    );
    $table_parser->add_rule(
        if => '$this->lines_parsed > 1',
        do =>  'my %rec = ();
                foreach my $i (0..$#{~columns}) {
                    my $k = ~columns->[$i];
                    $rec{$k} = $this->field($i);
                }
                return \%rec;',
    );
    $table_parser->read('table.txt');
    print Dumper($table_parser->get_records()), "\n";

In the above example you see the use of a L<stashed variable|/"METHODS FOR ACCESSING STASHED VARIABLES"> named C<~columns>. Note that the sigil used here is not a Perl sigil, but is converted to native Perl code. In the above case, each record is a hash with fixed number of fields.

More complex file-formats can be read and contents stored in a data-structure or an object. Here is an example:

    use strict;
    use warnings;

    package ComplexFormatParser;
    
    use Text::Parser::RuleSpec;  ## provides applies_rule + other sugar, imports Moose
    extends 'Text::Parser';

    # This rule ignores all comments
    applies_rule ignore_comments => (
        if          => 'substr($1, 0, 1) eq "#"', 
        dont_record => 1, 
    );

    # An attribute of the parser class. 
    has current_section => (
        is         => 'rw', 
        isa        => 'Str', 
        default    => undef, 
    );

    applies_rule get_header => (
        if          => '$1 eq "SECTION"', 
        do          => '$this->current_section($2);',  # $this : this parser object
        dont_record => 1, 
    );

    # ... More can be done

    package main;
    use ComplexFormatParser;

    my $p = ComplexFormatParser->new();
    $p->read('myfile.complex.fmt');

=head1 RATIONALE

The L<need|Text::Parser::Manual/MOTIVATION> for this class stems from the fact that text parsing is the most common thing that programmers do, and yet there is no lean, simple way to do it in Perl. Most programmers still write boilerplate code with a C<while> loop.

Instead C<Text::Parser> allows programmers to parse text with simple, self-explanatory L<rules|Text::Parser::Manual::ExtendedAWKSyntax>, whose structure is very similar to L<AWK|https://books.google.com/books/about/The_AWK_Programming_Language.html?id=53ueQgAACAAJ>, but extends beyond the capability of AWK.

I<B<Sidenote:>> Incidentally, AWK is L<one of the ancestors of Perl|http://history.perl.org/PerlTimeline.html>! One would have expected Perl to do way better than AWK. But while you can use Perl to do what AWK already does, that is usually limited to one-liners like C<perl -lane>. Even C<perl -lan script.pl> is not meant for serious projects. And it seems that L<some people still prefer AWK to Perl|https://aplawrence.com/Unixart/awk-vs.perl.html>. This is not looking good.

=head1 OVERVIEW

With C<Text::Parser>, a developer can focus on specifying a grammar and then simply C<read> the file. The C<L<read|/read>> method automatically runs each rule collecting records from the text input into an internal array. Finally, C<L<get_records|/get_records>> can retrieve the records.

Since C<Text::Parser> is a class, a programmer can subclass it to parse very complex file formats. L<Text::Parser::RuleSpec> provides intuitive rule sugar. Use of L<Moose> is encouraged. And data from parsed files can be turned into very complex data-structures or even objects. In this case, you wouldn't need to use C<get_records>.

With B<L<Text::Parser>> programmers have the elegance and simplicity of AWK combined with the power of Perl at their disposal.

=head1 CONSTRUCTOR

=head2 new

Takes optional attributes as in example below. See section L<ATTRIBUTES|/ATTRIBUTES> for a list of the attributes and their description.

    my $parser = Text::Parser->new();

    my $parser2 = Text::Parser->new( line_wrap_style => 'trailing_backslash' );

=head1 ATTRIBUTES

The attributes below can be used as options to the C<new> constructor. Each attribute has an accessor with the same name.

=head2 auto_chomp

Read-write attribute. Takes a boolean value as parameter. Defaults to C<0>.

    print "Parser will chomp lines automatically\n" if $parser->auto_chomp;

=head2 auto_split

Read-write boolean attribute. Defaults to C<0> (false). Indicates if the parser will automatically split every line into fields.

If it is set to a true value, each line will be split into fields, and L<a set of methods|/"METHODS USED ONLY IN RULES AND SUBCLASSES"> become accessible to C<L<save_record|/save_record>> or the rules.

=head2 auto_trim

Read-write attribute. The values this can take are shown under the C<L<new|/new>> constructor also. Defaults to C<'n'> (neither side spaces will be trimmed).

    $parser->auto_trim('l');       # 'l' (left), 'r' (right), 'b' (both), 'n' (neither) (Default)

=head2 custom_line_trimmer

Read-write attribute which can be set to a custom subroutine that trims each line before applying any rules or saving any records. The function is expected to take a single argument containing the complete un-trimmed line, and is expected to return a manipulated line.

    sub _cust_trimmer {
        my $line = shift;
        chomp $line;
        return $line;
    }

    $parser->custom_line_trimmer(\&_cust_trimmer);

B<Note:> If you set this attribute, you are entirely responsible for the trimming. Poorly written routines could causing the C<auto_split> operation to misbehave.

By default it is undefined.

=head2 FS

Read-write attribute that can be used to specify the field separator to be used by the C<auto_split> feature. It must be a regular expression reference enclosed in the C<qr> function, like C<qr/\s+|[,]/> which will split across either spaces or commas. The default value for this attribute is C<qr/\s+/>.

The name for this attribute comes from the built-in C<FS> variable in the popular L<GNU Awk program|https://www.gnu.org/software/gawk/gawk.html>. The ability to use a regular expression is an upgrade from AWK.

    $parser->FS( qr/\s+\(*|\s*\)/ );

C<FS> I<can> be changed from within a rule. Changes made even within a rule would take effect on the immediately next line read.

=head2 indentation_str

This can be used to set the indentation character or string. By default it is a single space C< >. But you may want to set it to be a tab (C<\t>) or perhaps some other character like a hyphen (C<->) or even a string (C<   -E<gt>>). This attribute is used only if C<L<track_indentation|/track_indentation>> is set.

=head2 line_wrap_style

Read-write attribute used as a quick way to select from commonly known line-wrapping styles. If the target text format allows line-wrapping this attribute allows the programmer to write rules as if they were on a single line.

    $parser->line_wrap_style('trailing_backslash');

Allowed values are:

    trailing_backslash - very common style ending lines with \
                         and continuing on the next line

    spice              - used for SPICE syntax, where the (+)
                         + symbol continues content of last line

    just_next_line     - used in simple text files written to be
                         humanly-readable. New paragraphs start
                         on a new line after a blank line.

    slurp              - used to "slurp" the whole file into
                         a single line.

    custom             - user-defined style. User must specify
                         value of multiline_type and define
                         two custom unwrap routines using the
                         custom_line_unwrap_routines method
                         when custom is chosen.

When C<line_wrap_style> is set to one of these values, the value of C<multiline_type> is automatically set to an appropriate value. Read more about L<handling the common line-wrapping styles|/"Common line-wrapping styles">.

=head2 multiline_type

Read-write attribute used mainly if the programmer wishes to specify custom line-unwrapping methods. By default, this attribute is C<undef>, i.e., the target text format will not have wrapped lines.

    $parser->line_wrap_style('custom');
    $parser->multiline_type('join_next');

    my $mult = $parser->multiline_type;
    print "Parser is a multi-line parser of type: $mult" if defined $mult;

Allowed values for C<multiline_type> are described below, but it can also be set back to C<undef>.

=over 4

=item *

If the target format allows line-wrapping I<to the B<next>> line, set C<multiline_type> to C<join_next>.

=item *

If the target format allows line-wrapping I<from the B<last>> line, set C<multiline_type> to C<join_last>.

=back

To know more about how to use this, read about L<specifying custom line-unwrap routines|/"Specifying custom line-unwrap routines">.

=head2 track_indentation

This boolean attribute enables tracking of the number of indentation characters are there at the beginning of each line. In some text formats, this is a very important information that can indicate the depth of some data. By default, this is false. When set to a true value, you can get the number of indentation characters on a given line with the C<L<this_indent|/this_indent>> method.

    $parser->track_indentation(1);

Now you can use C<this_indent> method in the rules:

    $parser->add_rule(if => '$this->this_indent > 0', do => '~num_indented ++;')

=head1 METHODS FOR SPECIFYING RULES

These are meant to be called from the C<::main> program or within subclasses.

=head2 add_rule

Takes a hash as input. The keys of this hash must be the attributes of the L<Text::Parser::Rule> class constructor and the values should also meet the requirements of that constructor.

    $parser->add_rule(do => '', dont_record => 1);                 # Empty rule: does nothing
    $parser->add_rule(if => 'm/li/, do => 'print', dont_record);   # Prints lines with 'li'
    $parser->add_rule( do => 'uc($3)' );                           # Saves records of upper-cased third elements

Calling this method without any arguments will throw an exception. The method internally sets the C<auto_split> attribute.

=head2 clear_rules

Takes no arguments, returns nothing. Clears the rules that were added to the object.

    $parser->clear_rules;

This is useful to be able to re-use the parser after a C<read> call, to parse another text with another set of rules. The C<clear_rules> method does clear even the rules set up by C<L<BEGIN_rule|/BEGIN_rule>> and C<L<END_rule|/END_rule>>.

=head2 BEGIN_rule

Takes a hash input like C<add_rule>, but C<if> and C<continue_to_next> keys will be ignored.

    $parser->BEGIN_rule(do => '~count = 0;');

=over 4

=item *

Since any C<if> key is ignored, the C<do> key is required. Multiple calls to C<BEGIN_rule> will append to the previous calls; meaning, the actions of previous calls will be included.

=item *

The C<BEGIN_rule> is mainly used to initialize some variables.

=item *

By default C<dont_record> is set true. User I<can> change this and set C<dont_record> as false, thus forcing a record to be saved even before reading the first line of text.

=back

=head2 END_rule

Takes a hash input like C<add_rule>, but C<if> and C<continue_to_next> keys will be ignored. Similar to C<BEGIN_rule>, but the actions in the C<END_rule> will be executed at the end of the C<read> method.

    $parser->END_rule(do => 'print ~count, "\n";');

=over 4

=item *

Since any C<if> key is ignored, the C<do> key is required. Multiple calls to C<END_rule> will append to the previous calls; meaning, the actions of previous calls will be included.

=item *

The C<END_rule> is mainly used to do final processing of collected records.

=item *

By default C<dont_record> is set true. User I<can> change this and set C<dont_record> as false, thus forcing a record to be saved after the end rule is processed.

=back

=head1 METHODS USED ONLY IN RULES AND SUBCLASSES

These methods can be used only inside rules, or methods of a subclass. Some of these methods are available only when C<auto_split> is on. They are listed as follows:

=over 4

=item *

L<NF|Text::Parser::AutoSplit/NF> - number of fields on this line

=item *

L<fields|Text::Parser::AutoSplit/fields> - all the fields as an array of strings ; trailing C<\n> removed

=item *

L<field|Text::Parser::AutoSplit/field> - access individual elements of the array above ; negative arguments count from back

=item *

L<field_range|Text::Parser::AutoSplit/field_range> - array of fields in the given range of indices ; negative arguments allowed

=item *

L<join_range|Text::Parser::AutoSplit/join_range> - join the fields in the range of indices ; negative arguments allowed

=item *

L<find_field|Text::Parser::AutoSplit/find_field> - returns field for which a given subroutine is true ; each field is passed to the subroutine in C<$_>

=item *

L<find_field_index|Text::Parser::AutoSplit/find_field_index> - similar to above, except it returns the index of the field instead of the field itself

=item *

L<splice_fields|Text::Parser::AutoSplit/splice_fields> - like the native Perl C<splice>

=back

Other methods described below are also to be used only inside a rule, or inside methods called by the rules.

=head2 abort_reading

Takes no arguments. Returns C<1>. Aborts C<read>ing any more lines, and C<read> method exits gracefully as if nothing unusual happened.

    $parser->add_rule(
        do          => '$this->abort_reading;',
        if          => '$1 eq "EOF"', 
        dont_record => 1, 
    );

=head2 this_indent

Takes no arguments, and returns the number of indentation characters found at the front of the current line. This can be called from within a rule:

    $parser->add_rule( if => '$this->this_indent > 0', );

=head2 this_line

Takes no arguments, and returns the current line being parsed. For example:

    $parser->add_rule(
        if => 'length($this->this_line) > 256', 
    );
    ## Saves all lines longer than 256 characters

Inside rules, instead of using this method, one may also use C<$_>:

    $parser->add_rule(
        if => 'length($_) > 256', 
    );

=head1 METHODS FOR READING INPUT

=head2 filename

Takes an optional string argument containing the name of a file. Returns the name of the file that was last opened if any. Returns C<undef> if no file has been opened.

    print "Last read ", $parser->filename, "\n";

The value stored is "persistent" - meaning that the method remembers the last file that was C<L<read|/read>>.

    $parser->read(shift @ARGV);
    print $parser->filename(), ":\n",
          "=" x (length($parser->filename())+1),
          "\n",
          $parser->get_records(),
          "\n";

A C<read> call with a filehandle, will clear the last file name.

    $parser->read(\*MYFH);
    print "Last file name is lost\n" if not defined $parser->filename();

=head2 filehandle

Takes an optional argument, that is a filehandle C<GLOB> (such as C<\*STDIN>) or an object of the C<FileHandle> class. Returns the filehandle last saved, or C<undef> if none was saved.

    my $fh = $parser->filehandle();

Like C<L<filename|/filename>>, C<filehandle> is also "persistent". Its old value is lost when either C<filename> is set, or C<read> is called with a filename.

    $parser->read(\*STDOUT);
    my $lastfh = $parser->filehandle();          # Will return glob of STDOUT

=head2 read

Takes a single optional argument that can be either a string containing the name of the file, or a filehandle reference (a C<GLOB>) like C<\*STDIN> or an object of the C<L<FileHandle>> class.

    $parser->read($filename);         # Read the file
    $parser->read(\*STDIN);           # Read the filehandle

The above could also be done in two steps if the developer so chooses.

    $parser->filename($filename);
    $parser->read();                  # equiv: $parser->read($filename)

    $parser->filehandle(\*STDIN);
    $parser->read();                  # equiv: $parser->read(\*STDIN)

The method returns once all records have been read, or if an exception is thrown, or if reading has been aborted with the C<L<abort_reading|/abort_reading>> method.

Any C<close> operation will be handled (even if any exception is thrown), as long as C<read> is called with a file name parameter - not if you call with a file handle or C<GLOB> parameter.

    $parser->read('myfile.txt');      # Will close file automatically

    open MYFH, "<myfile.txt" or die "Can't open file myfile.txt at ";
    $parser->read(\*MYFH);            # Will not close MYFH
    close MYFH;

=head1 METHODS FOR HANDLING RECORDS

=head2 get_records

Takes no arguments. Returns an array containing all the records saved by the parser.

    foreach my $record ( $parser->get_records ) {
        $i++;
        print "Record: $i: ", $record, "\n";
    }

=head2 last_record

Takes no arguments and returns the last saved record. Leaves the saved records untouched.

    my $last_rec = $parser->last_record;

=head2 pop_record

Takes no arguments and pops the last saved record.

    my $last_rec = $parser->pop_record;

=head2 push_records

Takes an array as input, and stores each element as a separate record. Returns the number of elements in the new array.

    $parser->push_records(qw(insert these as separate records));

=head1 METHODS FOR ACCESSING STASHED VARIABLES

Stashed variables can be data structures or simple scalar variables stored as elements in the parser object. Hence they are accessible across different rules. Stashed variables start with a tilde (~). So you could set up rules like these:

    $parser->BEGIN_rule( do => '~count=0;' );
    $parser->add_rule( if => '$1 eq "SECTION"', do => '~count++;' );

In the above rule C<~count> is a stashed variable. Internally this is just a hash element with key named C<count>. After the C<read> call is over, this variable can be accessed.

    $parser->read('some_text_file.txt');
    print "Found ", $parser->stashed('count'), " sections in file.\n";

Stashed variables that are created entirely within the rules are forgotten at the beginning of the next C<read> call. This means, you can C<read> another text file and don't have to bother to clear out the stashed variable C<~count>.

    $parser->read('another_text_file.txt');
    print "Found ", $parser->stashed('count'), " sections in file.\n";

In contrast, stashed variables created by calling C<prestash> continue to persist for subsequent calls of C<read>, unless an explicit call to C<forget> names these pre-stashed variables.

    $parser->prestash( max_err => 100 );
    $parser->BEGIN_rule( do => '~err_count = 0;' );
    $parser->add_rule(
        if               => '$1 eq "ERROR:" && ~err_count < ~max_err',
        do               => '~err_count++;', 
        continue_to_next => 1, 
    );
    $parser->add_rule(
        if => '$1 eq "ERROR:" && ~err_count == ~max_err',
        do => '$this->abort_reading;', 
    );
    $parser->read('first.log');
    print "Top 100 errors:\n", $parser->get_records, "\n";
    
    $parser->read('another.log');         # max_err is still set to 100, but err_count is forgotten and reset to 0 by the BEGIN_rule
    print "Top 100 errors:\n", $parser->get_records, "\n";

=head2 forget

Takes an optional list of string arguments which must be the names of stashed variables. This method forgets those stashed variables for ever. So be sure you really intend to do this. In list context, this method returns the values of the variables whose names were passed to the method. In scalar context, it returns the last value of the last stashed variable passed.

    my $pop_and_forget_me = $parser->forget('forget_me_totally', 'pop_and_forget_me');

Inside rules, you could simply C<delete> the stashed variable like this:

    $parser->add_rule( do => 'delete ~forget_me;' );

The above C<delete> statement works because the stashed variable C<~forget_me> is just a hash key named C<forget_me> internally. Using this on pre-stashed variables, will only temporarily delete the variable. It will be present in subsequent calls to C<read>. If you want to delete it completely call C<forget> with the pre-stashed variable name as an argument.

When no arguments are passed, it clears all stashed variables (not pre-stashed).

    $parser->forget;

Note that when C<forget> is called with no arguments, pre-stashed variables are not deleted and are still accessible in subsequent calls to C<read>. To forget a pre-stashed variable, it needs to be explicitly named in a call to forget. Then it is forgotten.

A call to C<forget> method is done without any arguments, right before C<read> starts reading a new text input. That is how we can reset the values of stashed variables, but still retain pre-stashed variables.

=head2 has_empty_stash

Takes no arguments and returns a true value if the stash of variables is empty (i.e., no stashed variables are present). If not, it returns a boolean false.

    if ( not $parser->has_empty_stash ) {
        my $myvar = $parser->stashed('myvar');
        print "myvar = $myvar\n";
    }

=head2 has_stashed

Takes a single string argument and returns a boolean indicating if there is a stashed variable with that name or not:

    if ( $parser->has_stashed('stashed_var') ) {
        print "Here is what stashed_var contains: ", $parser->stashed('stashed_var');
    }

Inside rules you could check this with the C<exists> keyword:

    $parser->add_rule( if => 'exists ~stashed_var' );

=head2 prestash

Takes an even number of arguments, or a hash, with variable name and value as pairs. This is useful to preset some stash variables before C<read> is called so that the rules have some variables accessible inside them. The main difference between pre-stashed variables created via C<prestash> and those created in the rules or using C<stashed> is that the pre-stashed ones are static.

    $parser->prestash(pattern => 'string');
    $parser->add_rule( if => 'my $patt = ~pattern; m/$patt/;' );

You may change the value of a C<prestash>ed variable inside any of the rules.

=head2 stashed

Takes an optional list of string arguments each with the name of a stashed variable you want to query, i.e., get the value of. In list context, it returns their values in the same order as the queried variables, and in scalar context it returns the value of the last variable queried.

    my (%var_vals) = $parser->stashed;
    my (@vars)     = $parser->stashed( qw(first second third) );
    my $third      = $parser->stashed( qw(first second third) ); # returns value of last variable listed
    my $myvar      = $parser->stashed('myvar');

Or you could do this:

    use Data::Dumper 'Dumper';

    if ( $parser->has_empty_stash ) {
        print "Nothing on my stash\n";
    } else {
        my %stash = $parser->stashed;
        print Dumper(\%stash), "\n";
    }

=head1 MISCELLANEOUS METHODS

=head2 lines_parsed

Takes no arguments. Returns the number of lines last parsed. Every call to C<read>, causes the value to be auto-reset.

    print $parser->lines_parsed, " lines were parsed\n";

=head2 has_aborted

Takes no arguments, returns a boolean to indicate if text reading was aborted in the middle.

    print "Aborted\n" if $parser->has_aborted();

=head2 custom_line_unwrap_routines

This method should be used only when the line-wrapping supported by the text format is not already among the L<known line-wrapping styles supported|/"Common line-wrapping styles">.

Takes a hash argument with required keys C<is_wrapped> and C<unwrap_routine>. Used in setting up L<custom line-unwrapping routines|/"Specifying custom line-unwrap routines">.

Here is an example of setting custom line-unwrapping routines:

    $parser->multiline_type('join_last');
    $parser->custom_line_unwrap_routines(
        is_wrapped => sub {     # A method that detects if this line is wrapped or not
            my ($self, $this_line) = @_;
            $this_line =~ /^[~]/;
        }, 
        unwrap_routine => sub { # A method to unwrap the line by joining it with the last line
            my ($self, $last_line, $this_line) = @_;
            chomp $last_line;
            $last_line =~ s/\s*$//g;
            $this_line =~ s/^[~]\s*//g;
            "$last_line $this_line";
        }, 
    );

Now you can parse a file with the following content:

    This is a long line that is wrapped around with a custom
    ~ character - the tilde. It is unusual, but hey, we're
    ~ showing an example.

When C<$parser> gets to C<read> this, these three lines get unwrapped and processed by the rules, as if it were a single line.

L<Text::Parser::Multiline> shows another example with C<join_next> type.

=head1 METHODS THAT MAY BE OVERRIDDEN IN SUBCLASSES

The following methods should never be called in the C<::main> program. They may be overridden (or re-defined) in a subclass.

Starting version 0.925, users should never need to override any of these methods to make their own parser.

=head2 save_record

The default implementation takes a single argument, runs any rules, and saves the returned value as a record in an internal array. If nothing is returned from the rule, C<undef> is stored as a record.

B<Note>: Starting C<0.925> version of C<Text::Parser> it is not required to override this method in your derived class. In most cases, you should use the rules.

B<Importnant Note:> Starting version C<1.0> of C<Text::Parser> this method will be deprecated to improve performance. So avoid inheriting this method.

=head2 is_line_continued

The default implementation of this routine:

    multiline_type    |    Return value
    ------------------+---------------------------------
    undef             |         0
    join_last         |    0 for first line, 1 otherwise
    join_next         |         1

In earlier versions of L<Text::Parser> you had no way but to subclass L<Text::Parser> to change the routine that detects if a line is wrapped. Now you can instead select from a list of known C<line_wrap_style>s, or even set custom methods for this.

=head2 join_last_line

The default implementation of this routine takes two string arguments, joins them without any C<chomp> or any other operation, and returns that result.

In earlier versions of L<Text::Parser> you had no way but to subclass L<Text::Parser> to select a line-unwrapping routine. Now you can instead select from a list of known C<line_wrap_style>s, or even set custom methods for this.

=head1 THINGS TO DO FURTHER

Future versions are expected to include features to:

=over 4

=item *

read and parse from a buffer

=item *

automatically uncompress input

=item *

I<suggestions welcome ...>

=back

Contributions and suggestions are welcome and properly acknowledged.

=head1 HANDLING LINE-WRAPPING

Different text formats sometimes allow line-wrapping to make their content more human-readable. Handling this can be rather complicated if you use native Perl, but extremely easy with L<Text::Parser>.

=head2 Common line-wrapping styles

L<Text::Parser> supports a range of commonly-used line-unwrapping routines which can be selected using the C<L<line_wrap_style|Text::Parser/"line_wrap_style">> attribute. The attribute automatically sets up the parser to handle line-unwrapping for that specific text format.

    $parser->line_wrap_style('trailing_backslash');
    # Now when read runs the rules, all the back-slash
    # line-wrapped lines are auto-unwrapped to a single
    # line, and rules are applied on that single line

When C<read> reads each line of text, it looks for any trailing backslash and unwraps the line. The next line may have a trailing back-slash too, and that too is unwrapped. Once the fully-unwrapped line has been identified, the rules are run on that unwrapped line, as if the file had no line-wrapping at all. So say the content of a line is like this:

    This is a long line wrapped into multiple lines \
    with a back-slash character. This is a very common \
    way to wrap long lines. In general, line-wrapping \
    can be much easier on the reader's eyes.

When C<read> runs any rules in C<$parser>, the text above appears as a single line to the rules.

=head2 Specifying custom line-unwrap routines

I have included the common types of line-wrapping styles known to me. But obviously there can be more. To specify a custom line-unwrapping style follow these steps:

=over 4

=item *

Set the C<L<multiline_type|/"multiline_type">> attribute appropriately. If you do not set this, your custom unwrapping routines won't have any effect.

=item *

Call C<L<custom_line_unwrap_routines|/"custom_line_unwrap_routines">> method. If you forget to call this method, or if you don't provide appropriate arguments, then an exception is thrown.

=back

L<Here|/"custom_line_unwrap_routines"> is an example with C<join_last> value for C<multiline_type>. And L<here|Text::Parser::Multiline/"SYNOPSIS"> is an example using C<join_next>. You'll notice that in both examples, you need to specify both routines. In fact, if you don't 

=head2 Line-unwrapping in a subclass

You may subclass C<Text::Paser> to parse your specific text format. And that format may support some line-wrapping. To handle the known common line-wrapping styles, set a default value for C<line_wrap_style>. For example: 

=over 4

=item *

Set a default value for C<line_wrap_style>. For example, the following uses one of the supported common line-unwrap methods. has '+line_wrap_style' => (  default => 'spice',  );

=back

* Setup custom line-unwrap routines with C<unwraps_lines> from L<Text::Parser::RuleSpec>.

    use Text::Parser::RuleSpec;
    extends 'Text::Parser';

    has '+line_wrap_style' => ( default => 'slurp', is => 'ro');
    has '+multiline_type'  => ( is => 'ro' );

Of course, you don't I<have> to make them read-only.

To setup custom line-unwrapping routines in a subclass, you can use the C<L<unwraps_lines_using|Text::Parser::RuleSpec/"unwraps_lines_using">> syntax sugar from L<Text::Parser::RuleSpec>. For example:

    package MyParser;

    use Text::Parser::RuleSpec;
    extends 'Text::Parser';

    has '+multiline_type' => (
        default => 'join_next',
        is => 'ro', 
    );

    unwraps_lines_using(
        is_wrapped     => \&_my_is_wrapped_routine, 
        unwrap_routine => \&_my_unwrap_routine, 
    );

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser::Manual> - Read this manual to learn how to do cool things with this class

=item *

L<Text::Parser::Error> - there is a change in how exceptions are thrown by this class. Read this page for more information.

=item *

L<The AWK Programming Language|https://books.google.com/books/about/The_AWK_Programming_Language.html?id=53ueQgAACAAJ> - by B<A>ho, B<W>einberg, and B<K>ernighan.

=item *

L<Text::Parser::Multiline> - how to read line-wrapped text input

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://github.com/balajirama/Text-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords H.Merijn Brand - Tux Mohammad S Anwar

=over 4

=item *

H.Merijn Brand - Tux <h.m.brand@xs4all.nl>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=cut
