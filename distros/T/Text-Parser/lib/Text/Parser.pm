use warnings;
use strict;
use feature ':5.14';

package Text::Parser 0.919;

# ABSTRACT: Simplifies text parsing. Easily extensible to parse any text format.


use Moose;
use MooseX::CoverableModifiers;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Moose::Util 'apply_all_roles', 'ensure_all_roles';
use Moose::Util::TypeConstraints;
use String::Util qw(trim ltrim rtrim eqq);
use Text::Parser::Errors;

enum 'Text::Parser::Types::MultilineType' => [qw(join_next join_last)];
enum 'Text::Parser::Types::TrimType'      => [qw(l r b n)];

no Moose::Util::TypeConstraints;
use FileHandle;
use Try::Tiny;


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
);

around auto_split => sub {
    my ( $orig, $self ) = ( shift, shift );
    __newval_auto_split( $orig, $self, @_ );
    return $orig->($self);
};

sub __newval_auto_split {
    my ( $orig, $self, $newval ) = ( shift, shift, shift );
    return if not defined $newval;
    $self->_clear_all_fields if not $newval and $orig->($self);
    $orig->( $self, $newval );
    ensure_all_roles $self, 'Text::Parser::AutoSplit' if $newval;
}


has auto_trim => (
    is      => 'rw',
    isa     => 'Text::Parser::Types::TrimType',
    lazy    => 1,
    default => 'n',
);


has FS => (
    is      => 'rw',
    isa     => 'RegexpRef',
    lazy    => 1,
    default => sub {qr/\s+/},
);


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
    ensure_all_roles( $self, 'Text::Parser::Multiline' )
        if defined $newval;
    return $orig->( $self, $newval );
}


sub read {
    my $self = shift;
    return if not defined $self->_handle_read_inp(@_);
    $self->__read_and_close_filehandle;
}

sub _handle_read_inp {
    my $self = shift;
    return $self->filehandle if not @_;
    return if not ref( $_[0] ) and not $_[0];
    return $self->filename(@_) if not ref( $_[0] );
    return $self->filehandle(@_);
}

sub __read_and_close_filehandle {
    my $self = shift;
    $self->_prep_to_read_file;
    $self->__read_file_handle;
    $self->_clear_this_line;
    $self->_close_filehandles if $self->_has_filename;
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
    $self->_next_line_parsed();
    $line = $self->_def_line_manip($line);
    $self->__try_to_parse($line);
    return not $self->has_aborted;
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

sub __try_to_parse {
    my ( $self, $line ) = @_;
    $self->_set_this_line($line);
    try { $self->save_record($line); }
    catch { die $_; };
}


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

# Don't touch: Override this is Text::Parser::AutoUncompress
sub _throw_invalid_file_exception {
    my ( $self, $fname ) = ( shift, shift );
    die invalid_filename( name => $fname ) if not -f $fname;
    die file_not_readable( name => $fname ) if not -r $fname;
    die file_not_plain_text( name => $fname );
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
    return if not @_ and not $self->_has_filehandle;
    $self->_save_filehandle(@_) if @_;
    $self->_clear_filename if @_;
    return $self->_get_filehandle;
}


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


sub save_record {
    my ( $self, $record ) = ( shift, shift );
    $self->push_records($record);
}


has _current_line => (
    is       => 'ro',
    isa      => 'Str|Undef',
    init_arg => undef,
    writer   => '_set_this_line',
    reader   => 'this_line',
    clearer  => '_clear_this_line',
    default  => undef,
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


has records => (
    isa        => 'ArrayRef[Any]',
    is         => 'ro',
    lazy       => 1,
    default    => sub { return []; },
    auto_deref => 1,
    init_arg   => undef,
    traits     => ['Array'],
    handles    => {
        get_records    => 'elements',
        push_records   => 'push',
        pop_record     => 'pop',
        _empty_records => 'clear',
        _num_records   => 'count',
        _access_record => 'accessor',
    },
);


sub last_record {
    my $self  = shift;
    my $count = $self->_num_records();
    return if not $count;
    return $self->_access_record( $count - 1 );
}


sub is_line_continued {
    my $self = shift;
    return 0 if not defined $self->multiline_type;
    return 0
        if $self->multiline_type eq 'join_last'
        and $self->lines_parsed() == 1;
    return 1;
}


sub join_last_line {
    my $self = shift;
    my ( $last, $line ) = ( shift, shift );
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

version 0.919

=head1 SYNOPSIS

    use Text::Parser;

    my $parser = Text::Parser->new();
    $parser->read(shift);
    print $parser->get_records, "\n";

The above code reads the first command-line argument as a string, and assuming it is the name of a text file, it will print the content of the file to C<STDOUT>. If the string is not the name of a text file it will throw an exception and exit.

    package MyParser;

    use Moose;
    extends 'Text::Parser';
    # use parent 'Text::Parser'; 
    # This will also work, but the Moose based class may be easier to implement

    sub save_record {
        my $self = shift;
        ## ...
    }

    package main;

    my $parser = MyParser->new(auto_split => 1, auto_chomp => 1, auto_trim => 'b');
    $parser->read(shift);
    foreach my $rec ($parser->get_records) {
        ## ...
    }

The above example shows how C<Text::Parser> could be easily extended to parse a specific text format.

=head1 RATIONALE

Text parsing is perhaps the single most common thing that almost every Perl program does. Yet we don't have a lean, flexible, text parsing utility. Ideally, the developer should only have to specify the "grammar" of the text file she intends to parse. Everything else, like C<open>ing a file handle, C<close>ing the file handle, tracking line-count, joining continued lines into one, reporting any errors in line continuation, trimming white space, splitting each line into fields, etc., should be automatic.

Unfortunately however, most file parsing code looks like this:

    open FH, "<$fname";
    my $line_count = 0;
    while (<FH>) {
        $line_count++;
        chomp;
        $_ = trim $_;  ## From String::Util
        my (@fields) = split /\s+/;
        # do something for each line ...
    }
    close FH;

Note that a developer may have to repeat all of the above if she has to read another file with different content or format. And if the target text format allows line-wrapping with a continuation character, it isn't easy to implement it well with this C<while> loop.

With C<Text::Parser>, developers can focus on specifying the grammar and simply use the C<read> method. Just extend this class with C<extends> (or inherit using C<parent> pragma), and override one method (C<L<save_record|/save_record>>). Voila! you have a parser. L<These examples|/EXAMPLES> illustrate how easy this can be.

=head1 OVERVIEW

C<Text::Parser> is a format-agnostic text parsing base class. Derived classes can specify the format-specific syntax they intend to parse.

=head1 CONSTRUCTOR

=head2 new

Takes optional attributes as in example below. See section L<ATTRIBUTES|/ATTRIBUTES> for a list of the attributes and their description.

    my $parser = Text::Parser->new(
        auto_chomp      => 0,
        multiline_type  => 'join_last',
        auto_trim       => 'b',
        auto_split      => 1,
        FS              => qr/\s+/,
    );

=head1 ATTRIBUTES

The attributes below can be used as options to the C<new> constructor. Each attribute has an accessor with the same name.

=head2 auto_chomp

Read-write attribute. Takes a boolean value as parameter. Defaults to C<0>.

    print "Parser will chomp lines automatically\n" if $parser->auto_chomp;

=head2 auto_split

Read-write boolean attribute. Defaults to C<0> (false). Indicates if the parser will automatically split every line into fields.

If it is set to a true value, each line will be split into fields, and a set of methods (a quick list L<here|/"Other methods available on auto_split">) become accessible within the C<L<save_record|/save_record>> method. These methods are documented in L<Text::Parser::AutoSplit>.

=head2 auto_trim

Read-write attribute. The values this can take are shown under the C<L<new|/new>> constructor also. Defaults to C<'n'> (neither side spaces will be trimmed).

    $parser->auto_trim('l');       # 'l' (left), 'r' (right), 'b' (both), 'n' (neither) (Default)

=head2 FS

Read-write attribute that can be used to specify the field separator along with C<auto_split> attribute. It must be a regular expression reference enclosed in the C<qr> function, like C<qr/\s+|[,]/> which will split across either spaces or commas. The default value for this argument is C<qr/\s+/>.

The name for this attribute comes from the built-in C<FS> variable in the popular L<GNU Awk program|https://www.gnu.org/software/gawk/gawk.html>.

    $parser->FS( qr/\s+\(*|\s*\)/ );

C<FS> I<can> be changed in your implementation of C<save_record>. But the changes would take effect only on the next line.

=head2 multiline_type

If the target text format allows line-wrapping with a continuation character, the C<multiline_type> option tells the parser to join them into a single line. When setting this attribute, one must re-define L<two more methods|/"FOR MULTI-LINE TEXT PARSING">. See L<these examples|/"Example 4 : Multi-line parsing">.

By default, the read-write C<multiline_type> attribute has a value of C<undef>, i.e., the target text format will not have wrapped lines. It can be set to either C<'join_next'> or C<'join_last'>.

    $parser->multiline_type(undef);
    $parser->multiline_type('join_next');

    my $mult = $parser->multiline_type;
    print "Parser is a multi-line parser of type: $mult" if defined $mult;

=over 4

=item *

If the target format allows line-wrapping I<to the B<next>> line, set C<multiline_type> to C<join_next>. L<This example|/"Continue with character"> illustrates this case.

=item *

If the target format allows line-wrapping I<from the B<last>> line, set C<multiline_type> to C<join_last>. L<This simple SPICE line-joiner|/"Simple SPICE line joiner"> illustrates this case.

=item *

To "slurp" a file into a single string, set C<multiline_type> to C<join_last>. In this special case, you don't need to re-define the C<L<is_line_continued|/is_line_continued>> and C<L<join_last_line|/join_last_line>> methods. See L<this trivial line-joiner|/"Trivial line-joiner"> example.

=back

=head1 METHODS

These are meant to be called from the C<::main> program or within subclasses. In general, don't override them - just use them.

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

B<Note:> To extend the class to other text formats, override C<L<save_record|/save_record>>.

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

=head2 lines_parsed

Takes no arguments. Returns the number of lines last parsed. Every call to C<read>, causes the value to be auto-reset.

    print $parser->lines_parsed, " lines were parsed\n";

=head2 has_aborted

Takes no arguments, returns a boolean to indicate if text reading was aborted in the middle.

    print "Aborted\n" if $parser->has_aborted();

=head2 get_records

Takes no arguments. Returns an array containing all the records saved by the parser.

    foreach my $record ( $parser->get_records ) {
        $i++;
        print "Record: $i: ", $record, "\n";
    }

=head2 pop_record

Takes no arguments and pops the last saved record.

    my $last_rec = $parser->pop_record;
    $uc_last = uc $last_rec;
    $parser->save_record($uc_last);

=head2 last_record

Takes no arguments and returns the last saved record. Leaves the saved records untouched.

    my $last_rec = $parser->last_record;

=head1 FOR USE IN SUBCLASS ONLY

Do NOT override these methods. They are valid only within a subclass, inside the user-implementation of methods described under L<OVERRIDE IN SUBCLASS|/"OVERRIDE IN SUBCLASS">. 

=head2 this_line

Takes no arguments, and returns the current line being parsed. For example:

    sub save_record {
        # ...
        do_something($self->this_line);
        # ...
    }

=head2 abort_reading

Takes no arguments. Returns C<1>. To be used only in the derived class to abort C<read> in the middle. See L<this example|/"Example 3 : Aborting without errors">.

    sub save_record {
        # ...
        $self->abort_reading if some_condition($self->this_line);
        # ...
    }

=head2 push_records

This is useful if one needs to implement an C<include>-like command in some text format. The example below illustrates this.

    package OneParser;
    use Moose;
    extends 'Text::Parser';

    my save_record {
        # ...
        # Under some condition:
        my $parser = AnotherParser->new();
        $parser->read($some_file)
        $parser->push_records($parser->get_records);
        # ...
    }

=head2 Other methods available on C<auto_split>

When the C<L<auto_split|/auto_split>> attribute is on, (or if it is turned on later), the following additional methods become available:

=over 4

=item *

L<NF|Text::Parser::AutoSplit/NF>

=item *

L<fields|Text::Parser::AutoSplit/fields>

=item *

L<field|Text::Parser::AutoSplit/field>

=item *

L<field_range|Text::Parser::AutoSplit/field_range>

=item *

L<find_field|Text::Parser::AutoSplit/find_field>

=item *

L<find_field_index|Text::Parser::AutoSplit/find_field_index>

=item *

L<splice_fields|Text::Parser::AutoSplit/splice_fields>

=back

=head1 OVERRIDE IN SUBCLASS

The following methods should never be called in the C<::main> program. They are meant to be overridden (or re-defined) in a subclass.

=head2 save_record

This method should be re-defined in a subclass to parse the target text format. To save a record, the re-defined implementation in the derived class must call C<SUPER::save_record> (or C<super> if you're using L<Moose>) with exactly one argument as a record. If no arguments are passed, C<undef> is stored as a record.

For a developer re-defining C<save_record>, in addition to C<L<this_line|/"this_line">>, six additional methods become available if the C<auto_split> attribute is set. These methods are described in greater detail in L<Text::Parser::AutoSplit>, and they are accessible only within C<save_record>.

B<Note:> Developers may store records in any form - string, array reference, hash reference, complex data structure, or an object of some class. The program that reads these records using C<L<get_records|/get_records>> has to interpret them. So developers should document the records created by their own implementation of C<save_record>.

=head2 FOR MULTI-LINE TEXT PARSING

These methods need to be re-defined by only multiline derived classes, i.e., if the target text format allows wrapping the content of one line into multiple lines. In most cases, you should re-define both methods. As usual, the C<L<this_line|/"this_line">> method may be used while re-defining them.

=head3 is_line_continued

This takes a string argument and returns a boolean indicating if the line is continued or not. See L<Text::Parser::Multiline> for more on this.

The return values of the default method provided with this class are:

    multiline_type    |    Return value
    ------------------+---------------------------------
    undef             |         0
    join_last         |    0 for first line, 1 otherwise
    join_next         |         1

=head3 join_last_line

This method takes two strings, joins them while removing any continuation characters, and returns the result. The default implementation just concatenates two strings and returns the result without removing anything (not even chomp). See L<Text::Parser::Multiline> for more on this.

=head1 EXAMPLES

=head2 Example 1 : A simple CSV Parser

We will write a parser for a simple CSV file that reads each line and stores the records as array references. This example is oversimplified, and does B<not> handle embedded newlines.

    package Text::Parser::CSV;
    use Moose;
    extends 'Text::Parser';
    use Text::CSV;

    my $csv;
    sub save_record {
        my ($self, $line) = @_;
        $csv //= Text::CSV->new({ binary => 1, auto_diag => 1});
        $csv->parse($line);
        $self->SUPER::save_record([$csv->fields]);
    }

That's it! Now in C<main::> you can write something like this:

    use Text::Parser::CSV;
    
    my $csvp = Text::Parser::CSV->new();
    $csvp->read(shift @ARGV);
    foreach my $aref ($csvp->get_records) {
        my (@arr) = @{$aref};
        print "@arr\n";
    }

The above program reads the content of a given CSV file and prints the content out in space-separated form.

=head2 Example 2 : Error checking

I<Note:> Read the documentation for C<L<Exceptions>> to learn about creating, throwing, and catching exceptions in Perl 5. All of the methods of creating, throwing, and catching exceptions described in L<Exceptions> are supported.

You I<can> throw exceptions from C<save_record> in your subclass, for example, when you detect a syntax error. The C<read> method will C<close> all filehandles automatically as soon as an exception is thrown. The exception will pass through to C<::main> unless you catch and handle it in your derived class.

Here is an example showing the use of an exception to detect a syntax error in a file:

    package My::Text::Parser;
    use Exception::Class (
        'My::Text::Parser::SyntaxError' => {
            description => 'syntax error',
            alias => 'throw_syntax_error', 
        },
    );
    
    use Moose;
    extends 'Text::Parser';

    sub save_record {
        my ($self, $line) = @_;
        throw_syntax_error(error => 'syntax error') if _syntax_error($line);
        $self->SUPER::save_record($line);
    }

=head2 Example 3 : Aborting without errors

We can also abort parsing a text file without throwing an exception. This could be if we got the information we needed. For example:

    package SomeParser;
    use Moose;
    extends 'Text::Parser';

    sub BUILDARGS {
        my $pkg = shift;
        return {auto_split => 1};
    }

    sub save_record {
        my ($self, $line) = @_;
        return $self->abort_reading() if $self->field(0) eq '**ABORT';
        return $self->SUPER::save_record($line);
    }

Above is shown a parser C<SomeParser> that would save each line as a record, but would abort reading the rest of the file as soon as it reaches a line with C<**ABORT> as the first word. When this parser is given the following file as input:

    somefile.txt:

    Some text is here.
    More text here.
    **ABORT reading
    This text is not read
    This text is not read
    This text is not read
    This text is not read

You can now write a program as follows:

    use SomeParser;

    my $par = SomeParser->new();
    $par->read('somefile.txt');
    print $par->get_records(), "\n";

The output will be:

    Some text is here.
    More text here.

=head2 Example 4 : Multi-line parsing

Some text formats allow users to split a line into several lines with a line continuation character (usually at the end or the beginning of a line).

=head3 Trivial line-joiner

Below is a trivial example where all lines are joined into one:

    use strict;
    use warnings;
    use Text::Parser;

    my $join_all = Text::Parser->new(auto_chomp => 1, multiline_type => 'join_last');
    $join_all->read('input.txt');
    print $join_all->get_records(), "\n";

Another trivial example is L<here|Text::Parser::Multiline/SYNOPSIS>.

=head3 Continue with character

(Pun intended! ;-))

In the above example, all lines are joined (indiscriminately). But most often text formats have a continuation character that specifies that the line continues to the next line, or that the line is a continuation of the I<previous> line. Here's an example parser that treats the back-slash (C<\>) character as a line-continuation character:

    package MyMultilineParser;
    use Moose;
    extends 'Text::Parser';
    use strict;
    use warnings;

    sub new {
        my $pkg = shift;
        $pkg->SUPER::new(multiline_type => 'join_next');
    }

    sub is_line_continued {
        my $self = shift;
        my $line = shift;
        chomp $line;
        return $line =~ /\\\s*$/;
    }

    sub join_last_line {
        my $self = shift;
        my ($last, $line) = (shift, shift);
        chomp $last;
        $last =~ s/\\\s*$/ /g;
        return $last . $line;
    }

    1;

In your C<main::>

    use MyMultilineParser;
    use strict;
    use warnings;

    my $parser = MyMultilineParser->new();
    $parser->read('multiline.txt');
    print "Read:\n"
    print $parser->get_records(), "\n";

Try with the following input F<multiline.txt>:

    Garbage In.\
    Garbage Out!

When you run the above code with this file, you should get:

    Read:
    Garbage In. Garbage Out!

=head3 Simple SPICE line joiner

Some text formats allow a line to indicate that it is continuing from a previous line. For example L<SPICE|https://bwrcs.eecs.berkeley.edu/Classes/IcBook/SPICE/> has a continuation character (C<+>) on the next line, indicating that the text on that line should be joined with the I<previous> line. Let's show how to build a simple SPICE line-joiner. To build a full-fledged parser you will have to specify the rich and complex grammar for SPICE circuit description.

    use TrivialSpiceJoin;
    use Moose;
    extends 'Text::Parser';

    use constant {
        SPICE_LINE_CONTD => qr/^[+]\s*/,
        SPICE_END_FILE   => qr/^\.end/i,
    };

    sub new {
        my $pkg = shift;
        $pkg->SUPER::new(auto_chomp => 1, multiline_type => 'join_last');
    }

    sub is_line_continued {
        my ( $self, $line ) = @_;
        return 0 if not defined $line;
        return $line =~ SPICE_LINE_CONTD;
    }
    
    sub join_last_line {
        my ( $self, $last, $line ) = ( shift, shift, shift );
        return $last if not defined $line;
        $line =~ s/^[+]\s*/ /;
        return $line if not defined $last;
        return $last . $line;
    }

    sub save_record {
        my ( $self, $line ) = @_;
        return $self->abort_reading() if $line =~ SPICE_END_FILE;
        $self->SUPER::save_record($line);
    }

Try this parser with a SPICE deck with continuation characters and see what you get. Try having errors in the file. You may now write a more elaborate method for C<save_record> above and that could be used to parse a full SPICE file.

=head1 THINGS TO BE DONE

Future versions are expected to include:

=over 4

=item *

progress-bar support

=item *

parsing from a buffer

=item *

automatically uncompress input

=item *

I<suggestions welcome ...>

=back

Interested contributors welcome.

=head1 SEE ALSO

=over 4

=item *

L<FileHandle>

=item *

L<Text::Parser::Errors>

=item *

L<Moose::Manual::Exceptions::Manifest>

=item *

L<Exceptions>

=item *

L<Dispatch::Class>

=item *

L<Text::Parser::Multiline>

=item *

L<Text::CSV>

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
