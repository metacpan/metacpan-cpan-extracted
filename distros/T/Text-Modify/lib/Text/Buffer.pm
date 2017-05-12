package Text::Buffer;

use strict;
use vars qw($VERSION $DEBUG);

use Carp;

BEGIN {
	$VERSION = '0.4';
	$DEBUG = 1;
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
				 _debug    => 0,
				 _buffer   => [],
				 _currline => 0,
				 _modified => 0,
				 _autonewline => "unix",
				 _newline  => "\n"
	};

	bless( $self, $class );

	my %opts = @_;
	if ($opts{debug}) { $self->{_debug} = $opts{debug}}
	$self->_debug("Instantiated new object $class");
	if ( $opts{file} ) {
		$self->{file} = $opts{file};
		$self->load();
	}
	elsif ( $opts{array} ) {
		if ( ref( $opts{array} ) eq "ARRAY" ) {
			foreach ( @{ $opts{array} } ) {
				$self->append($_);
			}
		}
		$self->setModified(1);
	}
	foreach (qw(autonewline)) {
		$self->{"_$_"} = $opts{$_} if exists($opts{$_});
	}

	return $self;
}

sub load {
	my $self = shift;
	my $file = shift || $self->{file};
	if ( !$file ) {
		$self->_setError("No file to load specified");
		return undef;
	}
	$self->_debug("Loading file $file");
	if ( open( FIL, $file ) ) {
		$self->_debug("clearing buffer and adding $file to buffer");
		$self->clear();
		while (<FIL>) {
			$self->append($_);
		}
		close(FIL);
		$self->_clearModified();
		return 1;
	}
	else {
		$self->_setError("Failed to load file $file");
		return undef;
	}
	return 0;
}

sub save {
	my $self = shift;
	my $file = shift || $self->{file};
	if ( !$file ) {
		$self->_setError("No file to save to specified");
		return undef;
	}

	if ( $self->{file} && $file eq $self->{file} && !$self->isModified() ) {
		$self->_debug("Buffer not modified, not saving to file $file");
		return 1;
	}
	else {
		$self->_debug(
				   "Saving " . $self->getLineCount() . " lines to file $file" );
	}

	if ( open( FIL, ">$file" ) ) {
		$self->_debug("saving buffer to $file");
		$self->goto('top');
		my $str = $self->get();
		my $cnt = 0;
		while ( defined($str) ) {
			$self->_debug("saving: '$str'");
			$cnt++;
			print FIL $str;
			$str = $self->next();
		}
		close(FIL);
		return $cnt;
	}
	else {
		$self->_setError("Failed to load file $file");
		return undef;
	}

	return 0;
}

sub clear {
	my $self = shift;
	@{ $self->{_buffer} } = ();
	$self->{_currline} = 0;
	return 1;
}

#=============================================================
# Public Methods
#=============================================================
# Navigation methods
#-------------------------------------------------------------

# Internal method returning the resulting array position (starting at 0)
sub _translateLinePos {
	my $self    = shift;
	my $linenum = shift || return undef;
	my $curr    = $self->{_currline};      # Resulting line to return
	if ( $linenum =~ /^[0-9]+$/ ) {
		$curr = $linenum - 1;
	}
	elsif ( $linenum =~ /^[+-]\d+$/ ) {
		eval "\$curr=$curr$linenum";
	}
	elsif ( $linenum =~ /^(start|top|first)$/ ) {
		$curr = 0;
	}
	elsif ( $linenum =~ /^(end|bottom|last)$/ ) {
		$curr = $self->getLineCount() - 1;
	}
	else {
		$self->_debug("Could not translate: $linenum");
		return undef;
	}

	# do sanity check now
	if ( $curr < 0 || $curr >= $self->getLineCount() ) {
		$self->_debug(
					"Failed sanity check, current line would be out of bounds");
		return undef;
	}

	return $curr;
}

sub goto {
	my $self = shift;
	my $goto = shift;
	my $curr = $self->_translateLinePos($goto);

	if ( !defined($curr) ) {
		$self->_setError("Invalid line position: $goto");
		return undef;
	}

	$self->_debug(   "goto $goto succeeded from array pos "
				   . $self->{_currline}
				   . " to $curr" );
	$self->{_currline} = $curr;
	return $self->getLineNumber();
}

sub getLineCount {
	my $self = shift;
	return ( $#{ $self->{_buffer} } + 1 );
}

sub getLineNumber {
	my $self = shift;
	$self->_debug(   "line is "
				   . ( $self->{_currline} + 1 )
				   . ", array pos is $self->{_currline}" );
	return ( $self->{_currline} + 1 );
}

sub isEOF { return shift->isEndOfBuffer() }

sub isEndOfBuffer {
	my $self = shift;
	return ( $self->{_currline} >= $self->getLineCount() );
}
sub isEmpty { return ( shift->getLineCount() == 0 ) }

sub isModified     { return shift->{_modified}; }
sub setModified    { my $self = shift; $self->_debug("Marking buffer modified"); $self->{_modified} = 1; }
sub _clearModified { my $self = shift; $self->_debug("Marking buffer unmodified"); $self->{_modified} = 0; }

sub setAutoNewline {
	my $self = shift;
	my $newline = shift;
	if (!$newline || $newline eq "off" || $newline eq "none") { 
		$self->{_autonewline} = ""; $self->{_newline} = "";
	}
	elsif ($newline eq "\n" || lc($newline) eq "unix") {
		$self->{_autonewline} = "unix"; $self->{_newline} = "\n";
	}
	elsif ($newline eq "\r" || lc($newline) eq "mac") {
		$self->{_autonewline} = "mac"; $self->{_newline} = "\r";
	}
	elsif ($newline eq "\r\n" || lc($newline) eq "windows") {
		$self->{_autonewline} = "windows"; $self->{_newline} = "\r\n";
	}
	else {
		$self->{_autonewline} = "other"; $self->{_newline} = "$newline";
	}
	return 1;
}

sub getAutoNewline {
	my $self = shift;
	return $self->{_newline};
}

sub next {
	my $self = shift;
	my $num  = shift || 1;

	#FIXME should return all lines as array in array context
	if ( !$self->goto("+$num") ) {
		return undef;
	}
	return $self->get();
}

sub previous {
	my $self = shift;
	my $num  = shift || 1;

	#FIXME should return all lines as array in array context
	if ( !$self->goto("-$num") ) {
		return undef;
	}
	return $self->get();
}

#-------------------------------------------------------------
# Searching methods
#-------------------------------------------------------------
sub find {
	my $self = shift;
	my $match = shift || return undef;
	# TODO Add a more sophisticated interface, like 
	# find(regex => "\d+", startat => 'top', wrap => 1)
	my $wrap = shift;
	$match = $self->escapeRegexString($match);
	$self->{_findstart} = 1;	# Start at top, unless startline is defined
	$self->{_findlast}  = undef;
	$self->{_findregex} = $match;
	$self->{_findwrap}  = $wrap;
	$self->goto($self->{_findstart});
	return $self->findNext();
}

sub findNext {
	my $self = shift;
	my $match = $self->{_findregex};
	return undef if !$match;
	# Continue from current-line + 1 (avoid matchloop)
	if (defined($self->{_findlast})) { $self->goto($self->{_findlast} + 1); }
	my $line = $self->get();
	my $MAXCOUNT = $self->getLineCount(); 
	my $count = 0;
	while (defined($line) && $count++ <= $MAXCOUNT) {
		$self->_debug("Finding $match in line: '$line'");
		if ($line =~ /$match/) {
			if (defined($self->{_findlast}) && $self->{_currline} eq $self->{_findlast}) {
				$self->_debug("Ohoh, should not have found same match again");
				return undef;
			}
			$self->{_findlast} = $self->getLineNumber();
			$self->_debug("Found match $match in line $self->{_findlast}");
			return $self->getLineNumber();
		}
		$line = $self->next();
		if ($self->isEOF() && $self->{_findwrap}) {
			$self->goto('top');
			$line = $self->get();
		}
	}
	return undef;
}

sub findPrevious {
	return undef;
}

#-------------------------------------------------------------
# Viewing/Editing methods
#-------------------------------------------------------------
sub get {
	my $self    = shift;
	my $linenum = shift;
	if ( defined($linenum) ) { $linenum = $self->_translateLinePos($linenum) }
	else { $linenum = $self->{_currline} }
	if ( !defined($linenum) ) {
		$self->_setError("Invalid line position");
		return undef;
	}
	my $line = $self->_appendAutoNewline(${ $self->{_buffer} }[$linenum]);
	$self->_debug( "get line $linenum in array: "
				   . ( defined($line) ? $line : "*undef*" ) );
	return $line;
}

sub set {
	my $self    = shift;
	my $line    = shift;
	my $linenum = shift;
	if ( defined($linenum) ) { $linenum = $self->translateLinePos($linenum) }
	else { $linenum = $self->{_currline} }
	if ( !defined($line) ) {
		$self->_setError("Cannot set undefined data for line $linenum");
		return undef;
	}
	$self->_debug("set line $linenum in array: $line");
	if ( !defined( ${ $self->{_buffer} }[$linenum] )
		 || ${ $self->{_buffer} }[$linenum] ne $line )
	{
		$self->setModified();
	}

	${ $self->{_buffer} }[$linenum] = $line;
	return 1;
}

# Insert before start of buffer
sub insert {
	my $self = shift;
	unshift( @{ $self->{_buffer} }, @_ );
	return 1;
}

sub append {
	my $self = shift;
	push( @{ $self->{_buffer} }, @_ );
	return 1;
}

sub delete {
	my $self = shift;
	splice( @{ $self->{_buffer} }, $self->{_currline}, 1 );
	return $self->get();
}

sub dumpAsString {
	my $self = shift;
	return
	  join( "", map { ( defined($_) ? $_ : "*undef*" ) } @{ $self->{_buffer} } )
	  if ( $self->{_buffer} )
	  && ( ref( $self->{_buffer} ) eq "ARRAY" )
	  && $#{ $self->{_buffer} } >= 0;
	return "";
}

sub replaceString {
	my $self  = shift;
	my ($match,$with) = @_;
	my $str = $self->get();
	return undef if !defined($str);
	$self->_debug( "Doing string replacement of '$match' with '$with' on string: $str" );
	my $pos = 0;
	my $index = 0;
	my $count = 0;
	my $MAXCOUNT = 1000;
	while ($pos < length($str) && ($index = index($str,$match,$pos)) >= $pos && $count++ < $MAXCOUNT) {
		# myfoobar, foo is at index 2, foo is replaced by bar, 
		$self->_debug("Found $match at $index (pos was $pos)");
		$str = substr($str,0,$index) . $with . substr($str,$index + length($match));
		$pos = $index + length($with);
		$self->_debug("String is now $str, pos is $pos");
	}
	if ($count == $MAXCOUNT) { $self->setError("Maximum loopcount reached"); return undef; }
	if ($count) {
		$self->set($str);
	}
	return $count;
}

sub replaceWildcard {
	my $self  = shift;
	my ($match,$with,$opts) = @_;
	# Replace wildcards with apropriate regex terms
	# map '*' to '.*?'
	# map '?' to '.'
	# leave other things the same, but escape / and ()
	$self->_debug("Doing wildcard replacement of '$match' with '$with'" );
	$match = $self->escapeRegexString($match,"*.");
	$match =~ s/\?/./g;
	$match =~ s/\*/\\S*/g;
	$self->_debug("After wildcard expansion: $match (was $_[1])");
	return $self->replaceRegex($match, $with, $opts);
}

sub replaceRegex {
	my $self  = shift;
	my $match = shift;
	my $with  = shift;
	my $opts  = shift;
	if ( !defined($opts) ) { $opts = "g"; }
	my $count;
	my $str = $self->get();
	return undef if !defined($str);
	# Be sure to escape our used seperation char for s//
	$with =~ s?(^|[^\\])/?$1\\/?g;
	$self->_debug(
"Doing regex replacement of '$match' with '$with' (opts: $opts) on string: $str" );
	eval "\$count = (\$str =~ s/$match/$with/$opts)";

	if ($count) {
		$self->set($str);
	}
	return $count;
}

# replace is an alias for replaceRegex
sub replace { shift->replaceRegex(@_); }

#=============================================================
# Utility functions / class methods
#=============================================================
sub convertWildcardToRegex {
	my $self = shift;
	my $string = shift || return "";
	$self->_debug("convert wildcard '$string'");
	$string = $self->escapeRegexString($string,"?*");
	$string =~ s/\?/./g;
	$string =~ s/\*/.*/g;
#	$string =~ s/([\(\)\/])/\\$1/g;
	$self->_debug("converted to regex: $string");
	return $string;
}

sub escapeRegexString {
	# We need to escape all regex specific chars
	# ignore chars will not be escaped
	my $self = shift;
	my $string = shift || return "";
	my $ignorechars = shift || "";
	my $regexchars = '\\/()[]{}+.*?'; #'
	my $escapechars = "";
	$self->_debug("escape string: '$string'   ignoring: '$ignorechars'  regex: '$regexchars'\n");
	# Build a hash of chars to ignore and
	my %chars = (map { $_ => 1 } split(//,$ignorechars));
	# Now remove all unused ignored chars
	foreach (split(//,$regexchars)) { $escapechars .= '\\' . $_ if !$chars{$_} }
	$string =~ s/([$escapechars])/\\$1/g;
	$self->_debug("escape: '$escapechars', string: '$string'");
	return $string;
}

sub convertStringToRegex {
	return shift->escapeRegexString(@_);
}

#-------------------------------------------------------------
# ErrorHandling Methods
#-------------------------------------------------------------
sub _setError { my $self = shift; $self->{error} = shift; }
sub isError { return ( shift->{'error'} ? 1 : 0 ); }

sub getError {
	my $self  = shift;
	my $error = $self->{error};
	$self->_clearError();
	return $error;
}
sub _clearError { shift->{error} = ""; }

#=============================================================
# Private Methods
#=============================================================
# Only internal function for debug output
sub _appendAutoNewline {
	my $self = shift;
	my $text = shift;
	return $text if (!$self->{_autonewline} || !$text);
	my $newline = $self->{_newline} || "";
	$text =~ s/[\r\n]+$//;
	$self->_debug("appended autonewline " . $self->{_autonewline}. "'$newline' to '$text'");
	return "$text$newline";
}

sub _debuglevel {
	my $self = shift;
	my $level = shift;
	if (ref($self) eq __PACKAGE__) {
		if (defined($level)) { $self->{_debug} = $level; }
		$level = $self->{_debug};
#		print "Object debug is $level (" . ref($self) . ")\n";
	} else {
		if (defined($level)) { $DEBUG = $level; }
		$level = $DEBUG;
#		print "Class debug is $level (" . ref($self) . ")\n";
	}
	return $level;
}

sub _debug {
	my $self = shift;
	my $lvl = $self->_debuglevel();
	if ( $self->_debuglevel() ) {
		print "[DEBUG$lvl] @_\n";
	}
}

1;
__END__

=head1 NAME

Text::Buffer - oo-style interface for handling a line-based text buffer

=head1 SYNOPSIS

  use Text::Buffer;

  my $text = new Text::Buffer(-file=>'my.txt');

  $text->goto(5);                   # goto line 5
  $text->delete();                  # return the whole buffer as string
  $text->replace("sad","funny");    # replace sad with funny in this line
  my $line = $text->next();         # goto next line
  $text->set($line);                # exchange current line with $line
  $text->next();                    # goto next line
  $text->insert("start of story");  # Insert text at start of buffer
  $text->append("end of story");    # Append text at end of buffer

=head1 DESCRIPTION

C<Text::Buffer> provides a mean of handling a text buffer with an 
oo-style interface.

It provides basic navigation/editing functionality with an very easy
interface. Generally a B<Text::Buffer> object is created by using
B<new>. Without an options this will create an empty text buffer. 
Optionally a file or reference to an array can be provided to load
this into the buffer. 

	my $text = new Text::Buffer();

Now the basic methods for navigation (goto, next, previous), searching
(find, findNext, findPrevious) or viewing/editing (get, set, delete, 
insert, append and replace).

	$text->goto("+1");
	my $line = $text->get();
	$line =~ s/no/NO/g;
	$text->set($line);

=head1 Methods

=over 8

=item new

    $text = new Text::Buffer(%options);

This creates a new object, starting with an empty buffer unless the
B<-file> or B<-array> options are provided. The available
attributes are:

=over 8

=item file FILE

File to open and read into the buffer. The file will read immediatly
and is closed after reading, as it is read completly into the buffer.
Be sure to have enough free memory available when opening large files.

=item array \@ARRAY

The contents of array will by copied into the buffer. Creates the buff
This specifies one or more prompts to scan for.  For a single prompt,
the value may be a scalar; for more, or for matching of regular
expressions, it should be an array reference.  For example,

    array => \@test
    array => ['first line','second line']

=item autonewline [unix | mac | windows | SPECIAL]

With this option the automatic appending (and replacement) of line-endings
can be altered. E.g. if unix is defined, all lines (upon read) will be
altered to end with \n.

=back

=item setAutoNewline 

Set the automatic line-end character(s). See option autonewline for
possible values.

=item getAutoNewline

Get the current newline character(s) set. E.g. return "\n" for type unix.

=item load

	$text = new Text::Buffer(file => "/tmp/foo.txt")
    $text->load();
    $text->load("/tmp/bar.txt");

Load the specified file (first argument or the one during new with -file option)
into the buffer, which is cleared before loading.

=item save

	$text = new Text::Buffer(file => "/tmp/foo.txt")
	# ... do some modifications here ...
    $text->save();
    $text->save("/tmp/bar.txt");

Load the specified file (first argument or the one during new with -file option)
into the buffer, which is cleared before loading

=item goto

    $text->goto(5);
    $text->goto("+2");

Sets the current line to edit in the buffer. Returns undef if the requested 
line is out of range. When supplying a numeric value (matching [0-1]+) the
line is set to that absolut position. The prefixes + and - denote a relative
target line. The strings "top" or "start" and "bottom" or "end" are used for
jumping to the start or end of the buffer.
The first line of the buffer is B<1>, not zero.

=item next

    $text->next();
    $text->next(2);

Accepts the same options as goto, which is performed with the option 
provided and the new line is returned. In array context returns all lines
from the current to the new line (expect the current line).
Undef is returned if the position is out of range.

=item previous

Same as B<next>, but in the other editing direction (to start of buffer).

=item get

    my $line = $text->get();
	
Get the current line from the buffer.

=item set ($string)

    $text->set("Replace with this text");
	
Replace the current line in the buffer with the supplied text.

=item insert ($string)

    $text->insert("top of the flops");

Adds the string to the top of the buffer.

=item append

Same as B<insert>, but adds the string at the end of the buffer.

=item replace

	my $count = $text->replace("foo","bar");

Replace the string/regex supplied as the first argument with the
string from the second argument. Returns the number of occurences.
The example above replaces any occurence of the string B<foo> with
B<bar>.

=item replaceString

	my $count = $text->replaceString(".foo$","bar");

Replace the a literal string supplied as the first argument with the
string from the second argument. No regex escapes are required, 
the string will be used as provided (e.g. dot is a dot).
Returns the number of occurences replaced.

The example above replaces any occurence of the string B<.foo$> with
B<bar>.

=item replaceRegex

	my $count = $text->replaceRegex("foo\s+foo","bar");

Replace the regex supplied as the first argument with the
string from the second argument. Returns the number of occurences.

For the replacement string match variables (e.g. $1) can be used
for replacement.

The example above replaces any occurence of the string B<foo  foo> with
B<bar>.

=item replaceWildcard

	my $count = $text->replaceWildcard("*foo?","bar");

Replace a wildcard string as the first argument with the string
from the second argument. Wildcard B<*> (asterisk, meaning match all 
characters) and B<?> (questionmark, meaning match one character)
will be expanded and the expanded string replaced with the
replacement string provided as the second argument.
Returns the number of occurences replaced.

The example above replaces any occurence of the string B<abcfoo2>
(as regex /^.*?foo./) with B<bar>.

=item delete

	$text->delete();
	my $nextline = $this->delete(); 

Deletes the current editing line and gets the next line (which will have
the same line number as the deleted now). 

=item clear

	$text->clear();

Resets the buffer to be empty. No save is performed.

=item getLineCount

Returns the number of lines in the buffer. Returns 0 if buffer is empty.

=item getLineNumber

Returns the current line position in the buffer (always starting at 1).

=item isModified

Returns 1 if the buffer has been modified, by using any of the
editing methods (replace, set, insert, append, ...)

=item setModified

Manually set the buffer to be modified, which will force the next save, even 
if no changes have been performed on the buffer.

=item isEmpty

Returns 1 if the buffer is currently empty.

=item isEOF

=item isEndOfBuffer

	while (!$text->isEndOfBuffer()) { $text->next(); }

Returns 1 if the current position is at the end of file.

=item find

	my $linenum = $text->find("/regex/");

Search for the supplied string/regex in the buffer (starting at top of
buffer). Even if 2 matches are found in the same line, find always returns
the next found line and 0 if no more lines are found.

=item findNext

	my $linenum = $text->findNext();

Repeats the search on the next line, search to the end of the buffer.

=item findPrevious

	my $linenum = $text->findPrevious();

Repeats the search on the previous line, searching to the top of the buffer.

=item convertStringToRegex

	$text->convertStringToRegex("No * have ?");
	Text::Modify->convertStringToRegex("a brace (is a brace)?");

Helper function to convert a string into a regular expression matching
the same string (espacing chars). The regex string returned matches
the strings as provided.

This function can be called as a class method too.

=item convertWildcardToRegex

	$text->convertWildcardToRegex("we need ?? beers");
	Text::Modify->convertWildcardToRegex("foo? or more *bar");

Helper function to convert a wildcard string into a regular expression
matching the wildcard (having whitespace as a word boundary).

This function can be called as a class method too.

=item escapeRegexString

	Text::Modify->escapeRegexString();

Helper function to escape regex special chars and treat them as normal 
characters for matchin.

This function can be called as a class method too.

=item isError

=item getError

	if ($text->isError()) { print "Error: " . $text->getError() . "\n"; }

Simple error handling routines. B<isError> returns 1 if an internal error
has been raised. B<getError> returns the textual error.

=item dumpAsString

	print $text->dumpAsString();

Returns (dumps) the whole buffer as a string. Can be used to directly
write to a file or postprocess manually.

=back

=head1 BUGS

There definitly are some, if you find some, please report them, by
contacting the author.

=head1 LICENSE

This software is released under the same terms as perl itself. 
You may find a copy of the GPL and the Artistic license at 

   http://www.fsf.org/copyleft/gpl.html
   http://www.perl.com/pub/a/language/misc/Artistic.html

=head1 AUTHOR

Roland Lammel (lammel@cpan.org)

=cut
