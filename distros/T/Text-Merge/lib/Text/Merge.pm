#!/usr/local/bin/perl -Tw
use strict;

#
# Text::Merge.pm - v.0.36 BETA
#
# (C)1997-2004 by Steven D. Harris. 
# 
# This software is released under the Perl Artistic License
#

=head1 NAME

Text::Merge - v.0.36  General purpose text/data merging methods in Perl. 

=head1 SYNOPSIS

	$merge = new Text::Merge;

	$merge->line_by_line();		# query
	$merge->line_by_line(0);	# turn off
	$merge->line_by_line(1);	# turn on

	$merge->set_delimiters('<<', '>>');            # user defined delims

	$success = $merge->publish($template, \%data);
	$success = $merge->publish($template, \%data, \%actions);
	$success = $merge->publish($template, $item);

	$success = $merge->publish_to($handle, $template, \%data);
	$success = $merge->publish_to($handle, $template, \%data, \%actions);
	$success = $merge->publish_to($handle, $template, $item);

	$text = $merge->publish_text($template, \%data);
	$text = $merge->publish_text($template, \%data, \%actions);
	$text = $merge->publish_text($template, $item);

	$success = $merge->publish_email($mailer, $headers, $template, \%data);
	$success = $merge->publish_email($mailer, $headers, $template, 
							     \%data, \%actions);
	$success = $merge->publish_email($mailer, $headers, $template, $item);

	$datahash = $merge->cgi2data();        # if you used "CGI(:standard)"
	$datahash = $merge->cgi2data($cgi);    # if you just used CGI.pm


=head1 DESCRIPTION

The C<Text::Merge> package is designed to provide a quick, versatile, and extensible way to combine presentation
templates and data structures.  The C<Text::Merge> package attempts to do this by assuming that templates are
constructed with text and that objects consist of data and functions that operate on that data.  C<Text::Merge> 
is very simple, in that it works on one file and one object at a time, although an extension exists to display 
lists (C<Text::Merge::Lists>) and C<Text::Merge> itself could easily be extended further.  

This is not XML and is intended merely to "flatten" the learning curve for non-programmers who design display 
pages for programmers or to provide programmers with a quick way of merging page templates with data sets or 
objects without extensive research.

The templates can be interpreted "line by line" or taken as a whole.


=head2 Technical Details

This object is normally inherited and so the new() function is the constructor.  It just blesses an 
anonymous HASH reference, sets two flags within that HASH, and returns it.  I'm am acutely aware 
of the criticisms of the overuse of OOP (Object Oriented Programming).  This module needs to be OO 
because of its extensibility and encapsulation; I wanted to impose classification of the objects to allow 
the greatest flexibility in context of implementation.  C<Text::Merge> is generally used on web servers, and 
can become integrated quickly into the httpd using mod_perl, hence the encapsulation and inheritance provided 
by the Perl OO model clearly outweighed the constraints thereby imposed.  That's my excuse...what's yours?

There are four public methods for the C<Text::Merge> object: C<publish()>, C<publish_to()>, C<publish_text()>, 
C<publish_email()>.  The first, C<publish()>, sends output to the currently selected file handle (normally 
STDOUT).  The second method, C<publish_text()>, returns the merged output as a text block.  The last method, 
C<publish_email()>, sends the merged output as a formatted e-mail message to the designated mailer.

Support is provided to merge the data and the functions performed on that data with a text template that 
contains substitution tag markup used to designate the action or data conversion.  Data is stored in a HASH 
that is passed by reference to the publishing methods.  The keys of the data hash correspond to the field 
names of the data, and they are associated with their respective values.  Actions (methods) are similarly 
referenced in a hash, keyed by the action name used in the template.

Here is a good example of a publishing call in Perl:

	$obj = new Text::Merge;
	%data = ( 'Name'=>'John Smith', 'Age'=>34, 'Sex'=>'not enough' );
	%actions = ( 'Mock' => \&mock_person,  'Laud' => \&laud_person );
	$obj->publish($template, \%data, \%actions);

In this example, C<mock_person()> and C<laud_person()> would be subroutines that took a single hash reference,
the data set, as an argument.  In this way you can create dynamic or complex composite components and reference 
them with a single tag in the template.  The actions HASH has been found to be useful for default constructs
that can be difficult to code manually, giving page designers an option to work with quickly.


=head2 Markup Tags

Simply put, tags are replaced with what they designate.  A tag generally consists of a prefix, followed by a
colon, then either an action name or a field name followed by zero or more formatting directives seperated
by colons.  In addition, blocks of output can be contained within curly brackets 
in certain contexts for conditional display.

=over 4

=item REF: tags

Simple data substitution is achieved with the C<REF:> tag.  Here is an example of the use of a C<REF:> tag
in context, assume we have a key-value pair in our data HASH associating the key 'Animal' with the value of
'turtle':

	The quick brown REF:Animal jumped over the lazy dog.

when filtered, becomes:

	The quick brown turtle jumped over the lazy dog.

The C<REF:> tag designators may also contain one or more format directives.  These are chained left
to right, and act to convert the data before it is displayed.  For example:

	REF:Animal:lower:trunc3

would result in the first three letters of the SCALAR data value associated with Animal in lower case.  See
the section, C<Data Conversions Formats>, for a list of the available SCALAR data formatting directives.  Note 
that some conversions may be incompatible or contradictory.  The system will not necessarily warn you of such 
cases, so be forewarned.

Any C<REF:> tag designator can be surrounded by curly brace pairs containing text that would be included in the
merged response only if the result of the designator is not empty (has a length).  There must be no spaces between 
the tag and the curly braced text.  If line-by-line mode is turned off, then the conditional text block may span
multiple lines.  For example:

	The {quick brown }REF:Animal{ jumps over where the }lazy dog lies.

Might result in:

	The quick brown fox jumps over where the lazy dog lies.

or, if the value associated with the data key 'Animal' was undefined, empty, or zero:

	The lazy dog lies.


=item IF: tags

The C<IF:> tag designators performs a conditional display.  The syntax is as follows:

	IF:FieldName:formats{Text to display}

This designator would result in the string B<Text to display> being returned if the formatted data value is
not empty.  The curly braced portion is required, and no curly braces are allowed before the designator.


=item NEG: tags

The C<NEG:> tag designator is similar to the C<IF:> tag, but the bracketed text is processed only if the
formatted data value is empty (zero length) or zero.  Effectively the C<NEG:> can be thought of as B<if not>.  
Here is an example:

	NEG:FieldName:formats{Text to display if the result is empty.}


=item ACT: tags

The C<ACT:> tag designates that an action is to be performed (a subroutine call) to obtain the result for 
substition.  The key name specified in the designator is used to look up the reference to the appropriate 
subroutine, and the data HASH reference is passed as the sole argument to that subroutine.  The returned 
value is the value used for the substition.

C<ACT:> is intended to be used to insert programmatic components into the document.  It can only specify
action key names and has no equivalent tags to C<IF:> and C<NEG:>.  The curly brace rules for the C<ACT:>
tag are exactly the same as those for the C<REF:> tag.


=item Conditional Text Braces

All tags support conditional text surrounded by curly braces.  If the C<line_by_line()> switch is set, then
the entire tag degignator must be on a single line of text, but if the switch is OFF (default) then the 
conditional text can span multiple lines.  

The two conditional tags, C<IF:> and C<NEG:>, require a single conditional text block, surrounded by curly 
braces, immediately following (suffixing) the field name or format string.  For example:

	IF:SomeField{this text will print}

The C<REF:> and C<ACT:> tags allow for curly braces both at the beginning (prefixing) and at the end 
(suffixing).  For example:

	{Some optional text }REF:SomeValue{ more text.}


=item Command Braces

You may bracket entire constructs (along with any conditional text) with double square brackets to set them
off from the rest of the document.  The square brackets would be removed during substitution:

	The [[IF:VerboseVar{quick, brown }]]fox jumped over the lazy dog.

assuming that 'VerboseVar' represented some data value, the above example would result in one of:

	The quick, brown fox jumped over the lazy dog.
or
	The fox jumped over the lazy dog.


=item Data Conversion Formats

Here is a list of the data conversion format and the a summary.  Details are undetermined in some cases for
exceptions, but all of the conversion to some satisfactory degree.  These conversion methods will treat all
values as SCALAR values:

	upper	-  converts all lowercase letters to uppercase
	lower	-  converts all uppercase letters to lower
	proper	-  treats the string as a Proper Noun 
	trunc## -  truncate the scalar to ## characters (## is an integer)
	words## -  reduce to ## words seperated by spaces (## is an integer)
	paragraph## -  converts to a paragraph ## columns wide
	indent## - indents plain text ## spaces
	int	-  converts the value to an integer
	float	-  converts the value to a floating point value
	string  -  converts the numeric value to a string (does nothing)
	detab	-  replaces tabs with spaces, aligned to 8-char columns
	html	-  replaces newlines with HTML B<BR> tags
	dollars	-  converts the value to 2 decimal places
	percent	-  converts the value to a percentage
	abbr	-  converts a time value to m/d/yy format
	short	-  converts a time value to m/d/yy H:MMpm format
	time	-  converts a time value to H:MMpm (localtime am/pm)
	24h	-  converts a time value to 24hour format (localtime)
	dateonly - converts a time value to Jan. 1, 1999 format
	date	- same as 'dateonly' with 'time'
	ext	-  converts a time value to extended format:
		        Monday, Januay 12th, 1999 at 12:20pm
	unix	-  converts a time value to UNIX date string format
	escape	-  performs a browser escape on the value (&#123;)
	unescape - performs a browser unescape (numeric only)
	urlencode - performs a url encoding on the value (%3B)
	urldecode - performs a url decoding (reverse of urlencode)

Most of the values are self-explanatory, however a few may need explanation:
	
The C<trunc> format must be suffixed with an integer digit to define at most 
how many characters should be displayed, as in C<trunc14>.

The C<html> format just inserts a <BR> construct at every newline in the 
string.  This allows text to be displayed appropriately in some cases.

The C<escape> format performs an HTML escape on all of the reserved characters
of the string.  This allows values to be displayed correctly on browsers in
most cases.  If your data is not prefiltered, it is usually a good idea to
use B<escape> on strings where HTML formatting is prohibited.  For example
a '$' value would be converted to '&#36;'.

The C<unescape> format does the reverse of an C<escape> format, however it
does not operate on HTML mnemonic escapes, allowing special characters to
remain intact.  This can be used to reverse escapes inherent in the use of
other packages.

The C<urlencode> and C<urldecode> formats either convert a value (text string)
to url encoded format, converting special characters to their %xx equivalent,
or converting to the original code by decoding %xx characters respectively from
the url encoded value.

=back


=head2 Item Support

The publishing methods all require at the very least a template, a data set, and the action set; although
either the data set or the action set or both could be empty or null.  You may also B<bundle> this 
information into a single HASH (suitable for blessing as a class) with the key 'Data' associated with
the data HASH reference, and the key 'Actions' associated with the action HASH reference.  A restatement of
a previous example might look like this:

	$obj = new Text::Merge;
	$data = { 'Name'=>'John Smith', 'Age'=>34, 'Sex'=>'not enough' };
	$actions = { 'Mock' => \&mock_person,  'Laud' => \&laud_person };
	$item = { 'Data' => $data,  'Actions' => $actions };
	$obj->publish($template, $item);

In addition, if you specify a key 'ItemType' in your C<$item> and give it a value, then the item reference
will be handed to any methods invoked by the C<ACT:> tags, rather than just the data hash.  This allows
you to construct B<items> that can be merged with templates.  For example, the following code is valid:

	%data = ( 'Author' => 'various',  'Title' => 'The Holy Bible' );
	%actions = ( 'Highlight' => \&highlight_item );
	$item = { 'ItemType'=>'book', 'Data'=>\%data, 'Actions'=>\%actions };
	bless $item, Some::Example::Class;
	$obj->publish($template, $item);

In this last example, the designator C<ACT:Highlight> would result in the object C<$item> being passed
as the only argument to the subroutine C<highlight_item()> referenced in the action HASH.


=head2 Line by Line Mode

By default, the publishing methods slurp in the entire template and process it as a text block.  This 
allows for multi-line conditional text blocks.  However, in some cases the resulting output may be very 
large, or you may want the output to be generated line by line for some other reason (such as unbuffered 
output).  This is accomplished through the C<line_by_line()> method, which accepts an optional boolean value,
which sets the current setting if specified or returns the current settingif not.  Note that this has the 
most notable impact on the C<publish()> and C<publish_email()> methods, since the results of the merge operations 
are sent to a handle.  If the line by line switch is set, then the C<publish_text()> method will substitute line
by line, but will still return the entire merged document as a single text block (not line by line). 

This is turned OFF by default.


=head2 Templates

Templates consist of text documents that contain special substitution designators as described previously.  The
template arguments passed to the publishing functions can take one of three forms:

=over 4

=item File Handle

This is a FileHandle object not a glob.  You must use the C<FileHandle> package that comes with the Perl distribution
for this type of template argument.  Processing begins at the current file position and continues until the end of 
file condition is reached.

=item File Path

If the argument is a scalar string with no whitespace, it is assumed to be a file path.  The template at that
location will be used when merging the document.

=item Text Block

If the argument is a scalar string that contains whitespace, it is assumed to be the actual text template.  
Substitution will be performed on a locally scoped copy of this argument.  

Note that you should not use this type of template argument if your template is very large and you 
are using line by line mode.  In this case you should use a FileHandle or file path argument.

=back

=head2 Methods

=over 4

=cut

package Text::Merge;
use FileHandle;
use AutoLoader 'AUTOLOAD';

our $NAME = 'Text::Merge';
our $VERSION = '0.36';

our @mon = qw(Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.);
our @month = qw(January February March April May June July August September October November December);
our @weekday = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
our @hex = map { ($_<16) && '%0'.sprintf('%X',$_) || sprintf('%%%2X',$_) } ( 0..255 );

1;


=item new()

This method gives us a blessed hash reference, with the following attribute keys:

	_Text_Merge_LineMode

Other keys can be added by objects which inherit C<Text::Merge>.

=cut
sub new {
	my $class = shift;
	my $ref = {};
	$$ref{_Text_Merge_LineMode} = 0;
	$$ref{_Text_Merge_Delimiter1} = quotemeta('[[');
	$$ref{_Text_Merge_Delimiter2} = quotemeta(']]');
	return bless $ref, $class;
};


=item line_by_line($setting)

This method returns the current setting if the C<$setting> argument is omitted.  Otherwise it resets the
line-by-line mode to the setting requested.  A non-zero value tells the publishing methods to process the
template line by line.  For those methods that output results to a handle, then those results will also be 
echoed line by line.

=cut
sub line_by_line {
	my ($self, $arg) = @_;
	$$self{_Text_Merge_LineMode}=$arg  if defined $arg;
	return $$self{_Text_Merge_LineMode};
};


=item set_delimiters($start, $end)

This method assigns a new command delimiter set for the tags (double 
square brackets by default).  The 'colon' character is not allowed within 
the delimiter, and the delimiter may not be a single curly bracket.  Both 
the C<$start> and C<$end> delimiters must be provided, and they cannot be 
identical.  

=cut
sub set_delimiters {
	my ($self, $start, $end) = @_;
	if (!defined $start || !defined $end ||
		($start && !$end) || (!$start && $end)) {
		warn "invalid delimiters provided to Text::Merge::set_delimiters().\n";
		return 0;
	};
	if ($start =~ /\:/ || $end =~ /\:/) {
		warn "The 'colon' character (:) is not allowed in Text::Merge delimiters.\n";
	};
	if ($start =~ /^[\{\}]$/ || $end =~ /^[\{\}]$/) {
		warn "Neither primary Text::Merge delimiter can be a curly bracket ({) or (}) in Text::Merge::set_delimiters().\n";
	}
	if ($start && !($start cmp $end)) {
		warn "The start and end Text::Merge delmiters must differ in set_delimiters().\n";
	};
	$$self{_Text_Merge_Delimiter1} = quotemeta($start);
	$$self{_Text_Merge_Delimiter2} = quotemeta($end);
};


#
# This is the core filtering engine.  It consists of:
#	text_process() - this method
#	handle_cond() - for conditional text blocks
#	convert_value() - for the formatting of values
#	   and assorted subordinate methods to convert_value()
#
sub text_process {
	my ($self, $text, $item) = @_;
	my $ret = $text;
	my ($open, $close) = 
		($$self{_Text_Merge_Delimiter1},$$self{_Text_Merge_Delimiter2});
	defined $open || ($open = '\[\[');
	defined $close || ($close = '\]\]');
	if (!$item) { warn "Improper call to text_process() in $0.  no item.\n";  return $ret; };
	if (!$ret) { warn "Improper call to text_process() in $0.  no text.\n";  return $ret; };
	$ret && $ret =~ s/$open({(?:[^\{\}]*)\}(?:REF\:|ACT\:)|IF\:|NEG\:)(\w+(?:\:\w+)*)?\{((?:[^\}]|\}(?!$close))*)\}$close/$self->
	 									handle_cond($1,$2,$3,$item)/eg if $open && $close;
	$ret && $ret =~ s/({(?:[^\{\}]*)\}(?:REF\:|ACT\:)|IF\:|NEG\:)(\w+(?:\:\w+)*)?\{([^\{\}]*)\}/$self->
	 									handle_cond($1,$2,$3,$item)/oeg;
	$ret && $ret =~ s/$open(REF|ACT)\:(\w+)((?:\:\w+)*)$close/$self->handle_tag($item,$1,$2,($3 || ''))/eg if $open && $close;
	$ret && $ret =~ s/\b(REF|ACT)\:(\w+)((?:\:\w+)*)\b/$self->handle_tag($item,$1,$2,($3 || ''))/oeg;
	return $ret;
};


sub handle_tag {
	my ($self, $item, $tag, $field, $formats) = @_;
	if ($tag eq 'ACT') { 
		my $text = $self->handle_action($field, $item); 
		return $text;
	};
	$formats && $formats =~ s/^\://g;	
	my @formats = split(/\:/, ($formats || ''));
	my $format;
	my $value = $$item{Data}{$field} || '';
	$value=$$value[0] if ref $value eq 'ARRAY' && ((scalar @$value)==1);
	foreach $format (@formats) { 
		$value = $self->convert_value($value, $format, $item); 
	};
	return $value;
};

sub handle_action {
	my ($self, $field, $item) = @_;
	my $sub = $$item{Actions}{$field} || return '';
	my $arg = $$item{ItemType} && $item || $$item{Data};
	my $result = &{$sub}($arg);
	return $result;
};

# args are:  self, {prefix}TAG:, field+formats, suffix
sub handle_cond {
	my ($self, $pretag, $ident, $suffix, $item) = @_;
	my ($value,$prefix,$tag,$cond) = ('','','','');
	if ($pretag =~ /^\{(.*)\}(\w+\:)$/s) { $prefix=$1;  $tag = $2; } 
	else { $prefix = '';  $tag = $pretag; };
	if ($pretag !~ /ACT:/) { 
		$value = $self->handle_tag($item, $tag, split(/\:/, $ident, 2)); 
	} else { 
		my $func = $$item{Actions}{$ident};
		$value = $func && &$func($$item{ItemType} && $item || $$item{Data}) || ''; 
	};
	$cond = $value;
	$tag eq 'NEG:' && ($cond = !$cond);
	($tag eq 'NEG:' || $tag eq 'IF:') && ($value = '');
	if ((defined $cond) && ($cond || length($cond))) { return $prefix.$value.$suffix; } 
	else { return ''; };
};



=item publish($template, $dataref, $actionref)

This is the normal publishing method.  It merges the specified template with the data and
any provided actions.  The output is sent to the currently selected handle, normally STDOUT.

=cut

sub publish { my ($self, @args)=@_;   return $self->publish_to('',@args); };



=item publish_to($handle, $template, $dataref, $actionref)

This is similar to the normal publishing method.  It merges the specified template with the data 
and any provided actions.  The output is sent to the specified C<$handle> or to the currently
selected handle, normally STDOUT, if the C<$handle> argument is omitted.

=cut

sub publish_to {
	my ($self, $handle, $template, $data, $actions) = @_;
	my ($fh,$line,$item);
	($$data{Data} ||  $$data{Actions}) && ($item=$data) || ($item = { 'Data'=>$data, 'Actions'=>$actions });
	if (!$template) { 
		my ($pkg, $fname, $lineno, $sname) = caller;
		warn "No template provided to ".(ref $self)."->publish_to.\n";
		warn "Called by $pkg\:\:$sname, line #$lineno in $fname.\n";
		($pkg, $fname, $lineno, $sname) = caller(1);
		warn "Called by $pkg\:\:$sname, line #$lineno in $fname.\n";
		return 0;
	} elsif ($template =~ /\s/s) {
		if ($handle) {
			print $handle $self->text_process($template, $item);
		} else { print $self->text_process($template, $item); };
		return 1;
	} elsif ((ref $template) =~ /FileHandle/ && ($fh=$template) 
	         || (-f $template) && ($fh = new FileHandle('<'.$template))) {
		if ($$self{_Text_Merge_LineMode}) {
		   foreach $_ (<$fh>) {
		       if ($handle) {
			   print $handle $self->text_process($_, $item);
		       } else { print $self->text_process($_, $item); };
		   };
		} else {
		    if ($handle) {
			print $handle $self->text_process((join('',<$fh>) || ''), $item);
		    } else { print $self->text_process((join('',<$fh>) || ''), $item); };
		};
		($template ne $fh) && $fh->close;
		return 1;
	};
	if (length($template)>50) { $template = substr($template, -30, 30); };
	warn "Illegal template $template provided to ".(ref $self)."->filter.\n";
	return 0;
};



=item publish_text($template, $dataref, $actionref)

This method works similar to the C<publish_to()> method, except it returns the filtered output as text
rather than sending it to the currently selected filehandle.

=cut

sub publish_text {
	my ($self, $template, $data, $actions) = @_;
	my $text = '';
	my ($fh,$line,$item,$ref);
	($$data{Data} ||  $$data{Actions}) && ($item=$data) || ($item = { 'Data'=>$data, 'Actions'=>$actions });
	if (!$template) { 
		my ($pkg, $fname, $lineno, $sname) = caller;
		warn "No template provided to ".(ref $self)."->publish_text.\n";
		warn "Called by $pkg\:\:$sname, line #$lineno in $fname.\n";
		($pkg, $fname, $lineno, $sname) = caller(1);
		warn "Called by $pkg\:\:$sname, line #$lineno in $fname.\n";
		return 0;
	} elsif (($template=~/(?:(?:\r?\n)|\r)/) || (!($ref=ref($template)) && !(-f $template)) ) { 
		return $self->text_process($template, $item); 
	} elsif ( $ref && $ref=~/FileHandle/ && ($fh=$template) || 
		 (-f $template) && ($fh = new FileHandle($template))) {
		if ($$self{_Text_Merge_LineMode}) { 
			foreach (<$fh>) { $text .= $self->text_process($_, $item); }; 
		} else { $text = $self->text_process((join('',<$fh>) || ''), $item); };
		($template ne $fh) && $fh->close;
		return $text;
	};
	warn "Invalid template $template provided to ".(ref $self)."->publish_text()\n";
	return '';
};


=item publish_email($mailer, $headers, $filepath, $data, $actions)

This method is similar to C<publish()> but opens a handle to C<$mailer>, and sending the merged data
formatted as an e-mail message.  C<$mailer> may contain the sequences C<RECIPIENT> and/or C<SUBJECT>.  
If either does not exists, it will be echoed at the beginning of the email (in the form of a header), allowing 
e-mail to be passed preformatted.  This is the preferred method; use a mailer that can be told to 
accept the "To:", "Subject:" and "Reply-To:" fields within the body of the passed message and do 
not specify the C<RECIPIENT> or C<SUBJECT> tags in the C<$mailer> string.  Returns false if failed, 
true if succeeded.  The recommended mail program is 'sendmail'.  C<$headers> is a HASH reference, containing
the header information.  Only the following header keys are recognized:

	To
	Subject
	Reply-To
	CC
	From (works for privileged users only)

The values associated with these keys will be used to construct the desired e-mail message header.  Secure 
minded site administrators might put hooks in here, or even better clean the data,  to protect access to 
the system as a precaution, to avoid accidental mistakes perhaps.

Note: the C<$mailer> argument string should begin with the type of pipe required for your request.  For
sendmail, this argument would look something like (note the vertical pipe):

	'|/usr/bin/sendmail -t'

Be careful not to run this with write permission on the sendmail file and forget the process pipe!!!

=cut
sub publish_email {
	my ($self, $mailer, $headers, $filepath, $data, $actions) = @_;
	my ($recipient, $subject, $ccaddr, $replyto, $from, $ctype) = 
		( ($$headers{To} || ''), ($$headers{Subject} || ''), ($$headers{CC} || ''), ($$headers{ReplyTo}), ($$headers{From} || ''), ($$headers{'Content-type'} || $$headers{'Content-Type'} || $$headers{'ContentType'} || '') );
	$mailer && $recipient || (return '');
	my ($toheader, $subheader, $ccheader, $repheader, $fromheader, $typeheader) = ('','','','','','');
	$subject && $subject =~ s/[^\040-\176].*$//gs;		# remove dangerous chars
	$from && $from =~ s/[^\040-\176].*$//gs;		# remove dangerous chars
	$ccaddr && $ccaddr =~ s/[^\040-\176].*$//gs;		# remove dangerous chars
	$replyto && $replyto =~ s/[^\040-\176].*$//gs;	# remove dangerous chars
	$ctype && $ctype =~ s/[^\040-\176].*$//gs;	# remove dangerous chars
	$subject || ($subject = 'Web Notice');
	if ($mailer=~/RECIPIENT/) { $mailer =~ s/RECIPIENT/$recipient/g; } else { $toheader = "To: $recipient\n"; };
	if ($mailer=~/SUBJECT/) { $mailer =~ s/SUBJECT/$subject/g; } else { $subheader = "Subject: $subject\n"; };
	$from && ($fromheader = "From: $from\n");
	$ccaddr && ($ccheader="Cc: $ccaddr\n");
	$replyto && ($repheader="Reply-to: $replyto\n");
    $ctype && ($typeheader="Content-Type: $ctype\n");
	if ($mailer eq 'SMTP') {
		# We will put an SMTP (require Net::SMTP) mailer here
		return 0;
	} else {
		my $fh = new FileHandle($mailer);
		if (!$fh) { return ''; };
		if ($toheader || $subheader || $typeheader || $ccheader) { print $fh $toheader.$fromheader.$subheader.$ccheader.$repheader.$typeheader."\n"; };
		$self->publish_to($fh, $filepath, $data, $actions);
		$fh->close;
		return 1;
	};
};

sub enc_char {
	my $c=shift;
	my $v=ord($c);
	($v<16) && return '%0'.sprintf("%x",$v);
	return '%'.sprintf("%x",$v);
};



=item cgi2data($cgi)

This method converts C<CGI.pm> parameters to a data hash reference suitable
for merging.  The C<$cgi> parameter is a CGI object and is optional, but 
you must have imported the C<:standard> methods from C<CGI.pm> if you omit 
the C<$cgi> paramter.  This method returns a hash reference containing the
parameters as data.  Basically it turns list values into list references and 
puts everything in a hash keyed by field name.

=cut
sub cgi2data {
	my ($self, $cgi) = @_;
	my $data = {};
	my ($k,$v,@v);
	my @keys = $cgi ? $cgi->param : param();
	foreach $k ($cgi->param) {
		@v = $cgi ? $cgi->param($k) : param($k);
		$v = (@v>1) ? [@v] : $v[0];
		$$data{$k} = $v;
	}
	return $data;
};


#
# local conversion function for output of each of the various styles
# OK, this isn't going to "local" anymore, other programs all want to use
# it, so we have to let them.  Don't forget to document!
#
sub convert_value {
	my ($self, $value, $style) = @_;
    $value ||= '';
	($_=$style) || ($_ = 'string');
	/^upper/i &&     (return uc($value || '')) ||
	/^lower/i &&     (return lc($value || '')) ||
	/^proper/i &&    (return propnoun($value || '')) ||
	/^trunc(?:ate)?(\d+)/ && (return substr(($value||''), 0, $1)) ||
	/^words(\d+)/ && (return frstword(($value||''), $1)) ||
	/^para(?:graph)?(\d+)/ && (return paratext(($value||''), $1)) ||
	/^indent(\d+)/ && (return indtext(($value||''), $1)) ||
	/^int/i &&       (return (defined $value ? int($value) : 0)) ||
	/^float/i &&     (return (defined $value && sprintf('%f',($value || 0))) || '') ||
	/^string/i &&    (return $value) ||
	/^detab/i &&	 (return de_tab($value)) ||		# Convert tabs to spaces in a string
	/^html/i &&	 (return htmlconv($value)) ||		# Convert text to HTML
	/^dollars/i &&   (return (defined $value && length($value) && sprintf('%.2f',($value || 0)) || '')) ||
	/^percent/i &&   (return (($value<0.2) && sprintf('%.1f%%',($value*100)) || sprintf('%d%%',int($value*100)))) ||
	/^abbr/i &&      (return abbrdate($value)) ||		# abbreviated date only
	/^short/i &&     (return shrtdate($value)) ||		# short date/time
	/^time/i &&      (return timeoday($value)) ||	# time of day only (localtime am/pm)
	/^24h/i &&       (return time24hr($value)) ||		# time of day 23:59 format (localtime0
	/^dateonly/i &&  (return dateonly($value)) ||		# same as full date, but no meridian time
	/^date/i &&      (return fulldate($value)) ||		# full date
	/^ext/i &&       (return extdate($value)) ||		# extended date
	/^unix/i &&      (return scalar localtime($value)) ||
	/^urlencode/i && (return urlenc($value)) ||		# URL encoded
	/^urldecode/i && (return urldec($value)) ||		# URL decoded
	/^escape/i &&    (return brsresc($value)) ||		# Browser Escape
	/^unescape/i &&  (return brsruesc($value)) ||		# Browser Un-Escape
	/^list$/ &&	 (return (ref $value) && '     '.join("\n     ", @$value)."\n" || '     '.$value."\n") ||
	return "  {{{ style $style not supported }}}  ";
};


sub browser_escape { return brsresc(@_); };
sub browser_unescape { return brsruesc(@_); };
sub html_convert { return htmlconv(@_); };

__END__

sub htmlconv {
	my $text=shift;
	$text || return '';
	$text =~ s/\r?\n/\n\<BR\>/g;
	return $text;
};

sub brsresc {
	$_=shift;  
	s/([\<\&\#\"\'\>])/'&#'.ord($1).';'/eg;
	return $_;
};

sub brsruesc { 
	$_=shift;  
	s/\&\#(\d+)\;/chr($1)/eg;  
	s/\&gt\;/\>/g;
	s/\&lt\;/\</g;
	s/\&amp\;/\&/g;
	s/\&quot\;/\"/g;
	return $_; 
};

sub propnoun {
	my $val = shift;
	$val =~ s/(^\w|\b\w)/uc($1)/eg;
	return $val;
};

sub frstword {
	my ($val, $ct) = @_;
	($ct>0) || return '';
	my @sentence = split(/\s+/, $val);
	my (@words) = splice(@sentence,0,$ct);
	return join(' ', @words);
};

sub paratext {
	my ($input, $cols) = @_;
	$input =~ s/\s+$//;
	$input || return '';
	my $rem = $cols;
	my @words = split(/\s/, $input);
	my @newwords;
	my ($word, $newword, $oldword);
	my $text = '';
	foreach $word (@words) {
		my $len = length($word);
		while ($len > $cols) {
			$text .= substr($word, 0, $rem)."\n";	
			$word = substr($word, $rem);
			$rem = $cols;
			$len = length($word);
		};
		if ($len > $rem) { 
		    if ($word =~ /\-/) {
			@newwords = split(/\-/, $word);
			$oldword = pop @newwords;
			$word = '';
			foreach $newword (@newwords) {
				if (length($newword)<$rem) {
					$rem -= length($newword)+1;
				    	$text .= $newword.'-';
				} else { $word .= $newword.'-'; };
			};
			$word .= $oldword;
			$len = length($word);
		    };
		    $text .= "\n";  $rem = $cols; 
		};
		$text .= $word;
		$rem -= $len;
		if ($rem > 2) { $text .= ' ';  --$rem; }
		else { $text .= "\n";  $rem = $cols; };
	};
	if ($rem ne $cols) { $text .= "\n"; };
	return $text;
};

sub indtext {
	my ($val, $ind) = @_;
	return join("\n", map { (' ' x $ind).$_ } split(/\n/, $val));
};

sub meridtim {
	my ($hour,$min) = @_;
	my $meridian = 'am';
	if ($hour > 11) { $meridian = 'pm';  $hour -= 12; };
	if (!$hour) { $hour = 12; };
	if (($min=int($min)) < 10) { $min = '0'.$min; };
	return $hour.':'.$min.$meridian;
};

sub abbrdate { 
	my $val = shift; 
	$val || return '';
	my @date = localtime(int($val));
	return ($date[4]+1).'/'.$date[3].'/'.substr(($date[5]+1900),-2,2);
};

sub shrtdate { 
	my $val = shift; 
	$val || return '';
	my @date = localtime(int($val));
	return ($date[4]+1).'/'.$date[3].'/'.substr(($date[5]+1900),-2,2).' '.meridtim($date[2],$date[1]);
};

sub timeoday { 
	my $val = shift; 
	$val || return '';
	my @date = localtime(int($val));
	return meridtim($date[2],$date[1]);
};

sub time24hr { 
	my $val = shift; 
	$val || return '';
	my @date = localtime(int($val));
	my ($hour,$min,$sec) = ($date[2],$date[1],$date[0]);
	($hour = int($hour)) < 10 && ($hour = '0'.$hour);
	($min = int($min)) < 10 && ($min = '0'.$min);
	($sec = int($sec)) < 10 && ($sec = '0'.$sec);
	return $hour.':'.$min.':'.$sec;
};

sub dateonly {
	my $val = shift;
	$val || return '';
	my @date = localtime(int($val));
	my $mon = $Text::Merge::mon[$date[4]];
	return $mon.' '.$date[3].', '.($date[5]+1900);
};

sub fulldate { 
	my $val = shift;
	$val || return '';
	my @date = localtime(int($val));
	my $mon = $Text::Merge::mon[$date[4]];
	return $mon.' '.$date[3].', '.($date[5]+1900).' '.meridtim($date[2],$date[1]);
};

sub extdate { 
	my $val = shift;
	$val || return '';
	my @date = localtime(int($val));
	my $wday = $Text::Merge::weekday[$date[6]];
	my $mon = $Text::Merge::month[$date[4]];
	my $suff = 'th';
	my $mday = $date[3];
	if ($mday < 4  || $mday > 20) {
		$_ = ($mday % 10);
		($_ == 1) && ($suff = 'st')  ||  ($_ == 2) && ($suff = 'nd')  ||  ($_ == 3) && ($suff = 'rd');
	};
	return $wday.', '.$mon.' '.$mday.$suff.', '.($date[5]+1900).' at '.meridtim($date[2],$date[1]);
};



sub urlenc {
	my $text = shift;
	$text =~ s/([^\w\-\/\.\:\@])/$Text::Merge::hex[ord($1)]/eg;   
	return $text;
};

sub urldec {
	my $text = shift;
	$text && $text =~ s/\%([a-f0-9]{2})/chr(hex($1))/ieg;
	return $text;
};

sub de_tab {
	# our assumptions:  
	#	+ newline is $\
	#	+ tabs are 8 chars wide
	my $text = shift;
	$text || return $text;
	my $newtext = '';
	my $match = '';
	while ($text && $text =~ s/^([^\t]*)\t//) {
		$match = $1 || '';
		$newtext .= $match;
		$newtext .= ' ' x (8-(length($newtext)%8));
	};
	$newtext .= $text if $text;
	return $newtext;
};



=back

=head1 PREREQUISITES

This module was written and tested in Perl 5.005 and runs with C<-Tw> set and C<use strict>.  It 
requires use of the package C<FileHandle> which is part of the standard perl distribution.

=head1 AUTHOR

This software is released under the Perl Artistic License.  Derive what you wish, as you wish, but please
attribute releases and include derived source code.  (C) 1997-2004 by Steven D. Harris, perl@nullspace.com

=cut


