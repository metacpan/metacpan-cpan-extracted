package Text::Refer;

=head1 NAME

Text::Refer - parse Unix "refer" files

I<This is Alpha code, and may be subject to changes in its public
interface.  It will stabilize by June 1997, at which point this 
notice will be removed.  Until then, if you have any feedback,
please let me know!>


=head1 SYNOPSIS

Pull in the module:

    use Text::Refer;  

Parse a refer stream from a filehandle:

    while ($ref = input Text::Refer \*FH)  {
	# ...do stuff with $ref...
    }
    defined($ref) or die "error parsing input";

Same, but using a parser object for more control:
    
    # Create a new parser: 
    $parser = new Text::Refer::Parser LeadWhite=>'KEEP';
    
    # Parse:
    while ($ref = $parser->input(\*FH))  {
	# ...do stuff with $ref...
    }
    defined($ref) or die "error parsing input";

Manipulating reference objects, using high-level methods:

    # Get the title, author, etc.:
    $title      = $ref->title;
    @authors    = $ref->author;      # list context
    $lastAuthor = $ref->author;      # scalar context
    
    # Set the title and authors:
    $ref->title("Cyberiad");
    $ref->author(["S. Trurl", "C. Klapaucius"]);   # arrayref for >1 value!
    
    # Delete the abstract:
    $ref->abstract(undef);

Same, using low-level methods:

    # Get the title, author, etc.:
    $title      = $ref->get('T');
    @authors    = $ref->get('A');      # list context
    $lastAuthor = $ref->get('A');      # scalar context
    
    # Set the title and authors:
    $ref->set('T', "Cyberiad");
    $ref->set('A', "S. Trurl", "C. Klapaucius");
    
    # Delete the abstract:
    $ref->set('X');                    # sets to empty array of values

Output:

    print $ref->as_string;


=head1 DESCRIPTION

I<This module supercedes the old Text::Bib.>

This module provides routines for parsing in the contents of
"refer"-format bibliographic databases: these are simple text files
which contain one or more bibliography records.  They are usually found
lurking on Unix-like operating systems, with the extension F<.bib>.  

Each record in a "refer" file describes a single paper, book, or article.  
Users of nroff/troff often employ such databases when typesetting papers.

Even if you don't use *roff, this simple, easily-parsed parameter-value 
format is still useful for recording/exchanging bibliographic 
information.  With this module, you can easily post-process
"refer" files: search them, convert them into LaTeX, whatever.


=head2 Example

Here's a possible "refer" file with three entries:

    %T Cyberiad
    %A Stanislaw Lem
    %K robot fable 
    %I Harcourt/Brace/Jovanovich
    
    %T Invisible Cities
    %A Italo Calvino
    %K city fable philosophy
    %X In this surreal series of fables, Marco Polo tells an
       aged Kublai Khan of the many cities he has visited in 
       his lifetime.  
    
    %T Angels and Visitations
    %A Neil Gaiman 
    %D 1993

The lines separating the records must be I<completely blank>;
that is, they cannot contain anything but a single newline.

See refer(1) or grefer(1) for more information on "refer" files.


=head2 Syntax

I<From the GNU manpage, C<grefer(1)>:>

The  bibliographic  database  is a text file consisting of
records separated by one or more blank lines.  Within each
record  fields  start with a % at the beginning of a line.
Each field has a one character name that immediately  follows  
the  %.  It is best to use only upper and lower case
letters for the names of fields. The name  of  the  field
should  be  followed by exactly one space, and then by the
contents of the field.  Empty  fields  are  ignored.   The
conventional meaning of each field is as follows:

=over 4

=item A

The name of an author. If the name contains a
title such as Jr. at the end, it should	be separated  
from the last name by a comma.  There can be multiple 
occurrences of the A field.  The order is significant. 
It is a good idea always to supply an A field or a Q field.

=item B

For an article that is part of a book, the title of the book

=item C      

The place (city) of publication.

=item D      

The date of publication.  The year should be specified in full.  
If the month is specified, the name rather than the number of 
the month should be used, but only the first three letters are required.   
It is a good idea always to supply a D field; if the date is unknown, 
a value such as "in press" or "unknown" can be used.

=item E      

For  an article that is part of a book, the name of an editor of the book.  
Where the work has editors and no authors, the names of the editors should 
be  given as A fields and , (ed) or , (eds)  should  be
appended to the last author.

=item G      

US Government ordering number.

=item I      

The publisher (issuer).

=item J

For an article in a journal, the name of the journal.

=item K  

Keywords to be used for searching.

=item L  

Label.

B<NOTE:> Uniquely identifies the entry.  For example, "Able94".

=item N 

Journal issue number.

=item O      

Other information.  This is usually printed at the end of the reference.

=item P      

Page number.  A range of pages can be specified as m-n.

=item Q

The name of the author, if the author is not a person.   
This will only be used if there are no A fields.  There can only be one 
Q field.

B<NOTE:> Thanks to Mike Zimmerman for clarifying this for me:
it means a "corporate" author: when the "author" is listed
as an organization such as the UN, or RAND Corporation, or whatever.


=item R      

Technical report number.

=item S      

Series name.

=item T      

Title.  For an article in a book or journal, this should be the title 
of the article.

=item V      

Volume number of the journal or book.

=item X      

Annotation.

B<NOTE:> Basically, a brief abstract or description.

=back

For all fields except A and E, if there is more than one occurrence
of a particular field in a record, only the last such field will be used.

If accent strings are used, they should follow the character 
to be accented.  This means that the AM macro must  be
used  with  the -ms macros.  Accent strings should not be
quoted: use one \ rather than two.


=head2 Parsing records from "refer" files

You will nearly always use the C<input()> constructor to create
new instances, and nearly always as shown in the L<"SYNOPSIS">.  

Internally, the records are parsed by a parser object; if you 
invoke the class method C<Text::Refer::input()>, a special default parser 
is used, and this will be good enough for most tasks.  However, for
more complex tasks, feel free to use L<"class Text::Refer::Parser">
to build (and use) your own fine-tuned parser, and C<input()> from
that instead.



=head1 CLASS Text::Refer

Each instance of this class represents a single record in a "refer" file.

=cut

use strict;
use vars (qw($VERSION $QUIET $GroffFields));


#------------------------------
#
# GLOBALS
#
#------------------------------

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.106 $, 10;

# Suppress warnings?
$QUIET = 0;

# Legal fields for different situations:
$GroffFields  = '[A-EGI-LN-TVX]';    # groff

# The default parser:
my $Parser = new Text::Refer::Parser;




#==============================

=head2 Construction and input

=over 4

=cut

#------------------------------------------------------------

=item new 

I<Class method, constructor.>
Build an empty "refer" record.

=cut

sub new {
    my $type = shift;
    bless {}, $type;
}

#------------------------------------------------------------

=item input FILEHANDLE

I<Class method.>
Input a new "refer" record from a filehandle.  The default parser
is used:

    while ($ref = input Text::Refer \*STDIN) {
	# ...do stuff with $ref...
    }

Do I<not> use this as an instance method; it will not re-init the object
you give it.

=cut

sub input {
    shift;
    $Parser->input(@_);
}

=back

=cut




#==============================

=head2 Getting/setting attributes

=over 4

=cut

#------------------------------------------------------------

=item attr ATTR, [VALUE]

I<Instance method.>
Get/set the attribute by its one-character name, ATTR.
The VALUE is optional, and may be given in a number of ways:

=over 4

=item *

B<If the VALUE is given as undefined>, the attribute will be deleted:

    $ref->attr('X', undef);        # delete the abstract

=item *

B<If a defined, non-reference scalar VALUE is given,> it is used to 
replace the existing values for the attribute with that I<single> value:

    $ref->attr('T', "The Police State Rears Its Ugly Head");
    $ref->attr('D', 1997);

=item *

B<If an arrayref VALUE is given,> it is used to replace the existing values
for the attribute with I<all elements of that array:>

    $ref->attr('A', ["S. Trurl", "C. Klapaucius"]);

We use an arrayref since an empty array would be impossible to distinguish
from the next two cases, where the goal is to "get" instead of "set"...

=back


This method returns the current (or new) value of the given attribute,
just as C<get()> does:

=over 4

=item *

B<If invoked in a I<scalar> context,> the method will return the
I<last> value (this is to mimic the behavior of I<groff>).  Hence,
given the above, the code:

    $author = $ref->attr('A');

will set C<$author> to C<"C. Klapaucius">.

=item *

B<If invoked in an I<array> context,> the method will return the list 
of I<all> values, in order.  Hence, given the above, the code:

    @authors = $ref->attr('A');

will set C<@authors> to C<("S. Trurl", "C. Klapaucius")>.

=back


I<Note:> this method is used as the basis of all "named" access 
methods; hence, the following are equivalent in every way:

    $ref->attr(T => $title)    <=>   $ref->title($title);
    $ref->attr(A => \@authors) <=>   $ref->author(\@authors);
    $ref->attr(D => undef)     <=>   $ref->date(undef);
    $auth  = $ref->attr('A')   <=>   $auth  = $ref->author;
    @auths = $ref->attr('A')   <=>   @auths = $ref->author;

=cut

sub attr {
    my ($self, $attr, $values) = @_;
    if (@_ > 2) {
	# set the "values"...
	#   undef        => empty array
	#   non-arrayref => array of one element
	#   arrayref     => that array
	$values = defined($values) ? $values : [];
	$self->set($attr, (ref($values) ? @$values : ($values)));
    }
    $self->get($attr);
}

#------------------------------------------------------------

=item author, book, city, ... [VALUE]

I<Instance methods.>
For every one of the standard fields in a "refer" record, this
module has designated a high-level attribute name:

   A  author     G  govt_no      N  number        S  series   
   B  book       I  publisher    O  other_info    T  title     
   C  city       J  journal      P  page          V  volume    
   D  date       K  keywords     Q  corp_author   X  abstract  
   E  editor     L  label        R  report_no    

Then, for each field I<F> with high-level attribute name I<FIELDNAME>,
the method C<FIELDNAME()> works as follows:

    $ref->attr('F', @args)     <=>   $ref->FIELDNAME(@args)

Which means:

    $ref->attr(T => $title)    <=>   $ref->title($title);
    $ref->attr(A => \@authors) <=>   $ref->author(\@authors);
    $ref->attr(D => undef)     <=>   $ref->date(undef);
    $auth  = $ref->attr('A')   <=>   $auth  = $ref->author;
    @auths = $ref->attr('A')   <=>   @auths = $ref->author;

See the documentation of C<attr()> for the argument list.

=cut

sub author      { shift->attr('A',@_) }
sub book        { shift->attr('B',@_) }
sub city        { shift->attr('C',@_) }
sub date        { shift->attr('D',@_) }
sub editor      { shift->attr('E',@_) }
sub govt_no     { shift->attr('G',@_) }
sub publisher   { shift->attr('I',@_) }
sub journal     { shift->attr('J',@_) }
sub keywords    { shift->attr('K',@_) }
sub label       { shift->attr('L',@_) }
sub number      { shift->attr('N',@_) }
sub other_info  { shift->attr('O',@_) }
sub page        { shift->attr('P',@_) }
sub corp_author { shift->attr('Q',@_) }
sub report_no   { shift->attr('R',@_) }
sub series      { shift->attr('S',@_) }
sub title       { shift->attr('T',@_) }
sub volume      { shift->attr('V',@_) }
sub abstract    { shift->attr('X',@_) }

#------------------------------------------------------------

=item get ATTR

I<Instance method.>
Get an attribute, by its one-character name.  
In an array context, it returns all values (empty if none):

    @authors = $ref->get('A');      # returns list of all authors

In a scalar context, it returns the I<last> value (undefined if none):

    $author = $ref->get('A');       # returns the last author

=cut

sub get {
    my ($self, $attr) = @_;
    my $vals = $self->{$attr} || [];
    (wantarray ? @$vals : $vals->[-1]);
}

#------------------------------------------------------------

=item set ATTR, VALUES...

I<Instance method.>
Set an attribute, by its one-character name.  

    $ref->set('A', "S. Trurl", "C. Klapaucius");

An empty array of VALUES deletes the attribute:

    $ref->set('A');       # deletes all authors

No useful return value is currently defined.

=cut

sub set {
    my $self = shift;
    my $attr = shift;
    if (@_) { $self->{$attr} = [@_] }
    else    { delete $self->{$attr} }
    1;
}

=back

=cut


#==============================

=head2 Output

=over 4

=cut

#------------------------------------------------------------
#
# _wrap STRING
#
# Split string into lines not exceeding 80 chars in length.

my $SMIN = 50;     # don't split at nonwords before this position
my $SMAX = 75;     # max line length

sub _wrap {
    pos($_[0]) = 0;
    $_[0] =~ s{\G (         # from current position...
        (.{1,$SMAX})(?:\n|\Z) # next line (if of legal length), plus EOL
        |                     # or,
        (.{$SMIN,$SMAX}\W)    # longest prefx of MIN-MAX chars endng in nonword
        |                     # or,
        (.{$SMAX})            # the first MAX chars
       )
    }{ 
       (defined($2) ? $2 : $1) . "\n"   # replace with text followed by \n
    }gexo;
    chop $_[0] if (substr($_[0], -1, 1) eq "\n");        # get rid of final \n
    1;
}

#-----------------------------------------------------q-------

=item as_string [OPTSHASH]

I<Instance method.>
Return the "refer" record as a string, usually for printing:

    print $ref->as_string;

The options are:

=over 4

=item Quick 

If true, do it quickly, but unsafely.  
I<This does no fixup on the values at all:> they are output as-is.  
That means if you used parser-options which destroyed any of the 
formatting whitespace (e.g., C<Newline=TOSPACE> with C<LeadWhite=KILLALL>), 
there is a risk that the output object will be an invalid "refer" record.  

=back

The fields are output with %L first (if it exists), and then the 
remaining fields in alphabetical order.  The following "safety measures" 
are normally taken:

=over 4

=item *

Lines longer than 76 characters are wrapped (if possible, at a non-word
character a reasonable length in, but there is a chance that they will
simply be "split" if no such character is available).

=item *

Any occurences of '%' immediately after a newline are preceded by a 
single space.

=back

These safety measures are slightly time-consuming, and are silly if you
are merely outputting a "refer" object which you have read in verbatim 
(i.e., using the default parser-options) from a valid "refer" file.
In these cases, you may want to use the B<Quick> option.
    
=cut

sub as_string {
    my ($self, %opts) = @_;
    my ($key, $val);

    # Figure out the keys to use, and put them in order:
    my @keys = sort grep {(length == 1) && ($_ ne 'L')} (keys %$self);
    defined($self->{'L'}) && unshift(@keys, 'L');

    # Output:
    my @lines;
    foreach $key (@keys) {
	foreach $val (@{$self->{$key}}) {
	    unless ($opts{Quick}) {
		### print "UNWRAPPED = [$val]\n";
		_wrap($val);             # make sure no line exceeds 80 chars
		### print "WRAPPED   = [$val]\n";
		$val =~ s/\n%/\n %/g;    # newlines must NOT be followed by %
		$val =~ s/\n+\Z//;       # strip trailing newlines
	    }
	    push @lines, join('', '%', $key, ' ', $val, "\n");
	}
    }
    join '', @lines;
}

=back

=cut





#==============================
#
package Text::Refer::Parser;
#
#==============================

=head1 CLASS Text::Refer::Parser

Instances of this class do the actual parsing.


=head2 Parser options

The options you may give to C<new()> are as follows:

=over 4

=item ForgiveEOF

Normally, the last record in a file must end with a blank line, or
else this module will suspect it of being incomplete and return an
error.  However, if you give this option as true, it will allow
the last record to be terminated by an EOF.

=item GoodFields

By default, the parser accepts any (one-character) field name that is
a printable ASCII character (no whitespace).  Formally, this is:

    [\041-\176]

However, when compiling parser options, you can supply your own regular 
expression for validating (one-character) field names.
(I<note:> you must supply the square brackets; they are there to remind 
you that you should give a well-formed single-character expression).
One standard expression is provided for you: 

    $Text::Refer::GroffFields  = '[A-EGI-LN-TVX]';  # legal groff fields

Illegal fields which are encounterd during parsing result in a syntax error.

B<NOTE:> You really shouldn't use this unless you absolutely need to.
The added regular expression test slows down the parser.


=item LeadWhite

In many "refer" files, continuation lines (the 2nd, 3rd, etc. lines of a 
field) are written with leading whitespace, like this:

    %T Incontrovertible Proof that Pi Equals Three
       (for Large Values of Three)
    %A S. Trurl
    %X The author shows how anyone can use various common household 
       objects to obtain successively less-accurate estimations of 
       pi, until finally arriving at a desired integer approximation,
       which nearly always is three.                 

This leading whitespace serves two purposes: (1) it makes it impossible 
to mistake a continuation line for a field, since % can no longer be the 
first character, and (2) it makes the entries easier to read.
The C<LeadWhite> option controls what is done with this whitespace:

    KEEP	- default; the whitespace is untouched
    KILLONE	- exactly one character of leading whitespace is removed
    KILLALL	- all leading whitespace is removed

See the section below on "using the parser options" for hints and warnings.


=item Newline

The C<Newline> option controls what is done with the newlines that
separate adjacent lines in the same field:

    KEEP	- default; the newlines are kept in the field value
    TOSPACE	- convert each newline to a single space
    KILL	- the newlines are removed

See the section below on "using the parser options" for hints and warnings.


=back

Default values will be used for any options which are left unspecified.


=head2 Notes on the parser options

The default values for C<Newline> and C<LeadWhite> will preserve the
input text exactly.

The C<Newline=TOSPACE> option, when used in conjunction with the
C<LeadWhite=KILLALL> option, effectively "word-wraps" the text of
each field into a single line.

B<Be careful!> If you use the C<Newline=KILL> option with
either the C<LeadWhite=KILLONE> or the C<LeadWhite=KILLALL> option,
you could end up eliminating all whitespace that separates the word
at the end of one line from the word at the beginning of the next line.


=head2 Public interface

=over 4

=cut

use strict;
use Carp;

#------------------------------------------------------------

sub error {
    my $self = shift;
    warn "refer: l.$.: ".join('',@_)."\n" unless $Text::Refer::QUIET;
    return (wantarray ? () : undef);
}

#------------------------------------------------------------

=item new PARAMHASH

I<Class method, constructor.>
Create and return a new parser.  See above for the L<"parser options">
which you may give in the PARAMHASH.

=cut

sub new {
    my ($class, %params) = @_;
    my $self = \%params;
    $self->{Class}      ||= 'Text::Refer';
    $self->{Newline}    ||= 'KEEP';
    $self->{LeadWhite}  ||= 'KEEP';
    $self->{GoodFields} ||= '[\041-\176]';

    # Compile allowed fields:
    my $gf = substr($self->{GoodFields}, 1);
    ($self->{Fields} = join('', map {chr($_)} 0..255)) =~ s{[^$gf}{}g;

    # The EOL character:
    if    ($self->{Newline} eq 'KILL')    {    $self->{EOL} = ""   }
    elsif ($self->{Newline} eq 'TOSPACE') {    $self->{EOL} = " "  }
    else                                  {    $self->{EOL} = "\n" }
    
    bless $self, $class;
}

#------------------------------------------------------------

=item create [CLASS]

I<Instance method.>
What class of objects to create.
The default is C<Text::Refer>.

=cut

sub create {
    my ($self, $class) = @_;
    $self->{Class} = $class if $class;
    $self->{Class};
}

#------------------------------------------------------------

=item input FH

I<Instance method.>
Create a new object from the next record in a "refer" stream.
The actual class of the object is given by the C<class()> method.

Returns the object on success, '0' on I<expected> end-of-file,
and undefined on error.

Having two false values makes parsing very simple: just C<input()>
records until the result is false, then check to see if that last result
was 0 (end of file) or undef (failure).

=cut

sub input {
    my ($self, $fh) = @_;
    my $line;             # the next line
    my $field;            # last key read in, or undef
    local($/) = "\n";     # in case our caller has been naughty


    # Get options into scalars for faster usage:
    my $LeadWhite  = $self->{LeadWhite};
    my $EOL        = $self->{EOL};

    # Skip blank lines until (legal) EOF or record:
    while (1) {
	defined($_ = <$fh>) or return 0;
	chomp;
	last if length($_);          # break if we hit a nonblank line
    }

    # Start new object:
    my $ref = $self->create->new;
    $ref->{LineNo} = $.;
    
    # Read record lines until (unexpected) EOF or done:
    while (1) {
	if (/^%(.)\s?(.*)$/) {             # start new field...
	    (index($self->{Fields}, ($field = $1)) >= 0) or
		return $self->error("bad record field '$field' in <$_>");
	    push @{$ref->{$field} ||= []}, $2; 
	}
	elsif (defined($field)) {          # add line to previous field...

	    # Muck about with leading whitespace (implicit else is KEEP):
	    if ($LeadWhite eq 'KILLONE') {      # kill first leading white:
		s/^\s//;
	    } elsif ($LeadWhite eq 'KILLALL') { # kill all leading white:
		s/^\s+//;
	    }

	    # Add separator and new line to existing value:
	    $ref->{$field}[-1] .= ($EOL . $_);
	}
	else {                             # yow! line not inside record!
	    return $self->error("line outside record: <$_>");
	}
    } continue {
	defined($_ = <$fh>) or do {        # unexpected EOF... forgive it?
	    $self->{ForgiveEOF}? last : return $self->error("unexpected EOF")};
	chomp;
	last if ($_ eq '');           # blank line means end of record
    }

    # Done!
    $ref;
}

=back

=cut


#------------------------------------------------------------

=head1 NOTES

=head2 Under the hood

Each "refer" object has instance variables corresponding to the actual
field names (C<'T'>, C<'A'>, etc.).  Each of these is a reference to
an array of the actual values.

Notice that, for maximum flexibility and consistency (but at the cost of
some space and access-efficiency), the semantics of "refer" records do
not come into play at this time: since everything resides in an array,
you can have as many %K, %D, etc. records as you like, and given them
entirely different semantics. 

For example, the Library Of Boring Stuff That Everyone Reads (LOBSTER) uses 
the unused %Y as a "year" field.  The parser accomodates this
case by politely not choking on LOBSTER .bibs (although why you would
want to eat a lobster bib instead of the lobster is beyond me...).


=head2 Performance

Tolerable.  On my 90MHz/32 MB RAM/I586 box running Linux 1.2.13 and Perl5.002,
it parses a typical 500 KB "refer" file (of 1600 records) as follows:

     8 seconds of user time for input and no output
    10 seconds of user time for input and "quick" output
    16 seconds of user time for input and "safe" output

So, figure the individual speeds are:

    input:            200 records ( 60 KB) per second.
    "quick" output:   800 records (240 KB) per second.
    "safe" output:    200 records ( 60 KB) per second.

By contrast, a C program which does the same work is about 8 times as fast.  
But of course, the C code is 8 times as large, and 8 times as ugly...  C<:-)>


=head2 Note to serious bib-file users

I actually do not use "refer" files for *roffing... I used them as a
quick-and-dirty database for WebLib, and that's where this code comes
from.  If you're a serious user of "refer" files, and this module doesn't
do what you need it to, please contact me: I'll add the functionality
in.


=head1 BUGS

Some combinations of parser-options are silly.



=head1 CHANGE LOG

$Id: Refer.pm,v 1.106 1997/04/22 18:41:41 eryq Exp $

=over 4

=item Version 1.101

Initial release.  Adapted from Text::Bib.

=back


=head1 AUTHOR

Copyright (C) 1997 by Eryq, 
F<eryq@enteract.com>,
F<http://www.enteract.com/~eryq>.


=head1 NO WARRANTY

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For a copy of the GNU General Public License, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

1;

