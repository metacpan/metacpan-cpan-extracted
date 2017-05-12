#!/usr/local/bin/perl -Tw
use strict;

#
# (C) 1997, 1998, 1999 by Steven D. Harris.  
# This software is released under the Perl Artistic License
#

=head1 NAME

Text::Merge::Lists - v.0.30 Text/data merge with lists/table support

=head1 SYNOPSIS

	$filter = new Text::Merge::Lists($template_path);

	$filter->set_max_nesting_depth($intval);


=head1 DESCRIPTION

The C<Text::Merge::Lists> package is designed to extend the C<Text::Merge> package with "list styles" in addition 
to the other formatting methods of fields.  This allows the display of fields that contain "lists" of 
items in addition to the normal "scalar" fields supported by C<Text::Merge>.  See the C<Text::Merge> package 
documentation for more information on templates and merging.

All the features of the C<Text::Merge> package are supported and invoked in an identical fashion.  The only difference 
in your programs to use the C<Text::Merge::Lists> object instead of the C<Text::Merge> object is the constructor, 
which must be invoked with the "Template Path" to the directory containing your various arbitrary lists 
style directories, described later.  See the C<Text::Merge> object for a description of the publishing methods 
available to you.

Lists can be nested, and you can use the C<set_max_nesting_depth()> object method to override 
the default maximum nesting depth of 3.  That is to say, you can only have a list of a list of a list 
by default.  If you want to nest further you will need to adjust this value.  The depth limit here is to
prevent you from clobbering the perl stack (and possibly other memory!) with deep recursion.


=head2 List Structure

A list variable is a reference to an ARRAY of data HASH references or item HASH references.  Basically, the
equivalent of the C<$data> or C<$item> argument to the publishing methods.  If you apply a list style to a 
SCALAR it will be treated as a list of one item.  Undefined lists are not considered empty, but they are
undefined as one would expect.  Here is an example list assignment to the variable C<$fruit_list>:

	$apple = { 'Color'=>'Red', 'Size'=>'medium', 'Shape'=>'round' };
	$pear = { 'Color'=>'Green', 'Size'=>'medium', 'Shape'=>'pear-shaped' };
	$grape = { 'Color'=>'Purple', 'Size'=>'small', 'Shape'=>'round' };
	$fruit_list = [ $apple, $pear, $grape ];


=head2 List Style Syntax

If you have read the C<Text::Merge> module documentation, which is recommended,
then you may be familiar with the syntax for displaying arbitrary fields using different styles,
such as this example for a displaying a numerical value, stored in the C<MyDollars> field, as a decimal
value with two decimal places:

	REF:MyDollars:dollars

There are many display styles available, some of which only apply to I<particular types of data>.  These are
described in detail in the C<Text::Merge> module documentation.

The C<Text::Merge::Lists> object extends the C<Text::Merge> object with support for list (ARRAY) references.  By 
using the list style designators, you can display lists in various contexts, just as you
would any other field value.  The templates for the various lists styles are stored in directories corresponding
to the list style names.  These are located in the path provided to the constructor.

The individual items stored in the lists should be data or item HASH references as described in the C<Text::Merge>
documentation.  These objects have an "ItemType" designator, allowing the individual list styles to display 
each type differently in that context.  These listing templates are plain text files, ending in '.txt' and 
stored in the style directory.  For example, a list style of 'showcase' stored in the templates 
path C</usr/templates/> would have all of it's files stored in the path, C</usr/templates/showcase/>.  If you 
had an item type of 'book' to display in a given list, that template would be stored at 
C</usr/templates/showcase/book.txt>.  The template will be used for each occurrence of the item type
'book' in any list displayed using the 'showcase' style.  In most cases, the listing templates will be output
"end on end" but that may not always be the case as described later.  

The syntax for a reference to an item list field named, C<DisplayItems>, for the example list style of 'showcase' 
would look something like this:

	REF:DisplayItems:list_showcase

Notice the C<list_> portion (that is an 'underscore').  This tells the filter that you want to treat the field
C<DisplayItems> as a list of items and use the 'showcase' list style.  The system will then look-up any templates
it needs for the list in the 'showcase' directory mentioned above.


=head2 List Style Features

Each list style has various special features that you can use by providing certain files in the list style directory.
These include a C<header>, a C<footer>, a C<default> item, and a message to display if the list is C<empty>.

=over 4

=item List Header

The list header is an HTML fragment contained in a plain text file that is treated by the filter as if it were part of
the original document (as opposed to a list item), it is displayed immediately before the list itself.  It is 
contained in the file C<header.txt> in the list style directory.  This file is optional.


=item List Footer

The list footer is similar to the list header described above.  It is displayed immediately following the list itself.
It is contained in the file C<footer.txt> in the list style directory.  This file is also optional.


=item Default Item Type

You may provide a listing fragment that will be used for any item that does not have a template in the designated
list style directory.  This could be an error message, or it my display information universal to all of your objects.
You can use this item template if all of your items are very similar and you don't want to construct a template for
each item in that style.

The default item template is located in a file called C<default.txt> in the designated list style directory.  This
file is optional.


=item Empty List Message

Similar to a header or footer, the empty list message is a file contained in the designate style directory that is
treated as part of the parent document for display purposes, if no items exist in your list.  If this file is not
provided, then empty lists are constructed as empty strings.  The file name for the empty list message is 
C<empty.txt> in the designated list style directory and is optional.

=back

=head2 Table Style Syntax

In addition to list styles, C<Text::Merge::Lists> also supports HTML table styles.  Table styles are trickier to 
set up than list styles, but the principle is basically the same, and you get the benefit of having more than one
column in your list display.  You maintain full control over the styling of the individual cells and the table
attributes.  All tables are HTML.

The syntax of a table style is very similar to the syntax of a list style, but you need to specify the number of
columns for the table in the tag.  For example:

	REF:ItemList:table4_options

The example listed above would generate a table using the table style defintion, "options", that is four columns 
wide.  The number is required and must be at least 1.  Large numbers (>10) are discouraged because they are 
practically unusable.

A table generated by a table style is basically a "grid" of the specified width with a "filler" cell at the end
of the table if necessary.  The filler cell may be one or more cells wide, up to one less than the specified
table width.  With this in mind, there are more restrictions on the templates required for a table style, as described
later.

Just as is the case with the list styles, individual items stored in the lists should be data or item HASH 
references as described in the C<Text::Merge> documentation.  These objects have an "ItemType" designator, allowing 
the individual table styles to display the cell for each type differently in the same context.  The cell
templates are plain text files, ending in '.txt' and stored in the table style directory.  

For example, a table style of 'options' stored in the templates path C</usr/templates/> would be located at
C</usr/templates/tables/options/>.  If you had an item of type 'choice' to display in a given list, then the
cell template for display of that particular item would be C</usr/templates/tables/options/choice.txt>.  Notice
that the path was created by stringing together the list-styles/template (C</usr/templates>)path, the table 
styles subdirectory (C<tables/>), and the directory and path for the individual style and item type
(C<options/choice.txt>).

If you choose to construct a table style, take care to include all the required elements.  Start and finish your
cell templates with the <TD> and </TD> elements respectively.  Start your header with <TABLE> and end it with
</TABLE>.  Remember that the Text::Merge::Lists methods will insert the <TR> and </TR> elements for rows containing
your cell templates.  Only use <TR> and </TR> in the header and footer files, and if you do be sure to use
only one cell in each row and use the C<TableColumns> field to assign the COLSPAN for that table.  Observing these 
few things should keep your tables functional.


=head2 Table Style Features

Each table style has similar requirements for the files stored in the designated table style directory.
The required files include a C<header>, a C<footer>, a C<filler> template, a C<default> cell template,
and the optional template to use if the list is C<empty>.  The C<header>, C<footer>, and C<empty> templates
will all have access to the data of the calling template, in addition the C<header> and C<footer> templates
will also have the additional field TableColumns set.  Likewise, the C<filler> template will have the FillerColumns
field set, and that must be used to set the COLSPAN of the last table cell as described later.

=over 4

=item Table Header Template

The table header is contained in a file named C<header.txt> in the table style directory.  This file B<must contain>
the <TABLE ...> element defintion.  It may also contain full table rows to start off the table.  Because table
styles may be invoked with a variable column count, the field C<TableColumns> is provided to use for a cell in these
table rows, and while limited, it does allow the insertion of header rows.  For example, this might be the contents
of a common header.txt file:

	<TABLE BORDER=1>
		<TR NOSAVE><TD ALIGN=CENTER 
			COLSPAN="REF:TableColumns"><B>Title</B></TD></TR>

Notice the C<REF:TableColumns> portion of the code, which will be replaced with the number of columns in the
table when the table is created.  This allows for a "variable width" header that covers all columns.


=item Table Footer Template

The table footer is contained in a file named C<footer.txt> and is very similar to the C<header.txt> file described
above.  The C<footer.txt> file B<must contain> the </TABLE> element closing out the table.  Before that element, 
any number of optional footer rows can be listed, and they too can use the C<TableColumns> field to span the 
table columns as well.  For example:

	    <TR><TD COLSPAN="REF:TableColumns">This 
			is the last table row.</TD></TR></TABLE>

Notice the C<REF:TableColumns> field used in the the last cell definition, just as is done with the header rows.  Also
notice the </TABLE> listed at the very end.  This basically closes out the table and is required.  You can also include
other HTML after this element if you wish, but it will not be included in the table itself.


=item Table Filler Template

The table filler cell is contained in a file named C<filler.txt> in the table style directory.  This is the template
used for the last cell of a table to fill the empty spaces that may be left if the number of items in the list is
not evenly divisible by the number of columns in the table.  A field named C<FillerColumns> is provided to this 
template and it B<must be used> to specify the COLSPAN of the cell.  This template, as with all other cell templates,
must contain the <TD ...> and </TD> elements of the cell.  This is a simple example filler cell template:

	<TD COLSPAN="REF:FillerColumns"><I>this is filler</I></TD>

The filler cell will be created with a single non-blocking space character (I<&nbsp;>) as content if no 
C<filler.txt> template file exists. 


=item Item Type Cell Template

Each item in the list can be displayed based on its C<ItemType> attribute if a cell template exists in the table style
directory that is named with the item type followed by the '.txt' suffix.  If such a template exists, it will be used
to display the cell using the item data and actions.  Every cell template B<must contain> the <TD...>...</TD> elements
to work properly in the table style.


=item Default Cell Template

The default cell template will be used if there is no cell template for the item type to be displayed.  That is to say,
if no file as described above exists for the item type in question, a file called 'default.txt' will be used to 
display the item.  The  'default.txt' file is required if your table style definition is be robust.


=item Empty Table Template

The empty table template is used if the list exists but contains no items.  The empty table template is contained
in a file in the table style directory named 'empty.txt'.  This template will have access to all the data and actions
of the calling template.  Note that if the 'empty.txt' template is used, then none of the other templates will be
used for that table style and the results of processing 'empty.txt' will be the only thing displayed.

=back

=head2 Methods

These are the methods that extend the basic functions of the C<Text::Merge> object.  Note that we overload 
C<convert_value()> in order to insert our list style format recognition and interpretation.  This is
very elegant and easy to do.

=over 4

=cut

package Text::Merge::Lists;
use Text::Merge;
use FileHandle;

$Text::Merge::Lists::VERSION = '0.30';
@Text::Merge::Lists::ISA = ('Text::Merge');

1;


=item new($liststyles) 

This method constructs a C<Text::Merge::Lists> object.  It basically grabs a new C<Text::Merge> object and then
assigns the liststyles directory (which is required).  If the template path is omitted, an the call
is treated as a normal C<Text::Merge> object request.

=cut
sub new {
	my ($self, $liststyles, $cacheflag) = @_;
	my $ref = Text::Merge::new(@_);
	if (!$liststyles) { return $ref; };
	$$ref{_Text_Merge_Liststyles} = $liststyles;
	if ($cacheflag) { $$ref{_Text_Merge_Lists_Cache} = {}; };
	return $ref;
};


=item convert_value($dataref, $name, $style, $item)

This method catches list styles and handles them, otherwise the C<Text::Merge> method is used.

=cut
sub convert_value {
	my ($self, $value, $style, $item) = @_;
	if (!$$self{_Text_Merge_Liststyles} ||
	     $style !~ /^(list|table\d+)\_(\w+)$/) { return Text::Merge::convert_value(@_); };
	my ($liststyle, $listtype) = ($2, $1);
	return $self->handle_list_style($value, $listtype, $liststyle, $item);
};


=item set_max_nesting_depth($intval) 

This method assigns the maximum nesting depth for lists.  The default maximum depth is 3.

=cut
sub set_max_nesting_depth {
	my ($self, $ival) = @_;
	if ($ival >= 0) { $$self{'_Text_Merge_Lists_MaxDepth'} = $ival; } 
	else { $$self{'_Text_Merge_Lists_MaxDepth'} = 3; };
};


=item sort_method($methodstr, $listref)

This method returns the sorted list by processing the C<$methodstr> for each item
in the list.  A common C<$methodstr> might look something like:

	$method = 'REF:SomeField reverse numeric';

Which would perform a reverse numeric sort on the list.  Basically a merge is
performed on the $methodstr and the sort algorithm is sensitive to the keyword
designators: C<reverse> and C<numeric>, which must appear at the end of the 
sort method string.

These must be items, where the data is contained in the 'Data' field.  For
instance:

	$item = { 'ItemType' => 'someitem',
		  'Data' => { 'field1' => 'val1',
			      'field2' => 'val2' } };

=cut
sub sort_method {
	my ($self, $method, $items) = @_;
	my $sorted = [];
	my ($field, $style);
	my $value = $method;
	return (wantarray ? @$sorted : $sorted) if !$items || !ref $items;
	$value =~ s/\s(?:reverse|numeric)//g;
	if ($value && $method =~ /numeric/) {
		@$sorted = sort { ($self->publish_text($value,$$a{'Data'},$$a{'Actions'}) || 0) <=> 
		                 ($self->publish_text($value,$$b{'Data'},$$b{'Actions'}) || 0) } @$items;	
	} elsif ($value) {
		@$sorted = sort { $self->publish_text($value,$$a{'Data'},$$a{'Actions'}) cmp 
		                 $self->publish_text($value,$$b{'Data'},$$b{'Actions'}) } @$items;	
	} else { @$sorted = sort { $a->id cmp $b->id } @$items; };
	if ($method =~ /reverse/) { @$sorted = reverse(@$sorted); };
	return (wantarray ? @$sorted : $sorted);
};



sub slurp {
	my ($file) = @_;
	my $text = '';
	my $fh = new FileHandle("<$file");
	if (!$fh) { warn "Unable to open $file for input in slurp().\n"; } 
	else {  while (defined $fh && ($_=<$fh>)) { $text.=$_; };  $fh->close;  };
	return $text;
};

sub list_style_template {
	my ($path, $cache, $type) = @_;
	my $ind = lc($type);
	$cache && (defined ($_=$$cache{$ind})) && return $_;
	my $file = (-f ($_=$path.$type.'.txt') && $_) || (-f ($_=$path.$type.'.TXT') && $_) ||
		   (-f ($_=$path.$ind.'.txt') && $_) || (-f ($_=$path.uc($type).'.txt') && $_) ||
		   (-f ($_=$path.uc($type).'.TXT') && $_) || (-f ($_=$path.$ind.'.TXT') && $_) || '';
	$cache && return ($$cache{$ind}=$file);
	$cache = '';
	$file || ($type =~ /^(?:header|footer|divider|empty|default)/i) || 
		warn "No list style template found for $path, $cache, $type\n";
	return $file;
};

sub handle_list_style {
	my ($self, $list, $type, $style, $parent) = @_;
	my $text = '';
	my $cache = $$self{_Text_Merge_Lists_Cache};
	my $depth = $$self{_Text_Merge_Lists_Depth} || 0;
	if ($depth>($$self{_Text_Merge_Lists_MaxDepth} || 3)) {
		warn "Maximum nested lists depth exceeded.\n";
		return '';
	}
	$$self{'_Text_Merge_Lists_Depth'}=++$depth;
	$style =~ s/\W//g;
	my $width = 0;
	if ($type =~ /^table(\d+)$/i) { $width = $1;  ($width < 1) && ($width = 1);  $type='table'; };
	if (!$style) { die "Illegal style provided...very bad, this should not happen."; };
	if ($cache) {
		my $cind = $type.'_'.$style;
		$cache && $$cache{$cind} || ($$cache{$cind} = {});
		$cache = $$cache{$cind};
	};
	my $itemct = 0;
	my $path = $$self{_Text_Merge_Liststyles};
	($type eq 'table') && ($path .= 'tables/');  
	$path .= $style.'/';
	if (!-d $path) { return "<I>Invalid $type style $style</I>"; };
	if ($list) {
	    (ref $list)=~/ARRAY/ || ($list = [$list]);
	    if (@$list) {
		if ($type =~ /^list$/i) {
			$text = $self->handle_list_templates($path, $list, $parent, $cache);
		} elsif ($type eq 'table') {
			$text = $self->handle_table_templates($path, $list, $parent, $cache, $width);
		};
	    } else {
		my $message = list_style_template($path, $cache, 'empty');
		if ($message) { $text = $self->publish_text($message,$parent); };
	    };
	};
	$$self{'_Text_Merge_Lists_Depth'}--;
	return $text;
};

sub handle_list_templates {
	my ($self, $path, $list, $parent, $cache) = @_;
	my $text = '';
	my $item = '';
	my $header = list_style_template($path, $cache, 'header');
	my $footer = list_style_template($path, $cache, 'footer');
	my $divider = list_style_template($path, $cache, 'divider');
	if ($header) { $text .= $self->publish_text($header,$parent); }; 
	my $itemct = 0;
	foreach $item (@$list) {
		if ($item && ($_=$$item{ItemType} || 'default')) {
			my $stylefile = list_style_template($path, $cache, ($$item{ItemType} || 'default'));
			if (!$stylefile) { $stylefile = list_style_template($path, $cache, 'default'); };
			if ($stylefile) { 
				$itemct++ && $divider && ($text .= $self->publish_text($divider,$item)); 
				$text .= $self->publish_text($stylefile,$item); 
			};
		};
	};
	if ($footer) { $text .= $self->publish_text($footer,$parent); };
	return $text;
};


sub handle_table_templates {
	my ($self, $path, $list, $parent, $cache, $width) = @_;
	my $text = '';
	my $item = '';
	my $header = list_style_template($path, $cache, 'header');
	my $footer = list_style_template($path, $cache, 'footer');
	my $filler = list_style_template($path, $cache, 'filler');
	if ($$parent{Data}) { $$parent{Data}{TableColumns} = $width; } else { $$parent{TableColumns} = $width; };
	if ($header) { $text .= $self->publish_text($header,$parent); }; 
	my $itemct = 0;
	foreach $item (@$list) {
		if ($item && ($_=$$item{ItemType} || 'default')) {
			my $stylefile = list_style_template($path, $cache, ($$item{ItemType} || 'default'));
			if (!$stylefile) { $stylefile = list_style_template($path, $cache, 'default'); };
			if ($stylefile) { 
				if (!($itemct % $width)) { $text .= ($itemct && '</TR>' || '')."\n<TR>"; };
				$itemct++;
				$text .= $self->publish_text($stylefile,$item); 
			};
		};
	};
	if ( $itemct ) {
		my $fw = ($itemct % $width);
		if ($fw && ($fw=$width-$fw)) {
			if ($$parent{Data}) { $$parent{Data}{FillerColumns} = $fw; } 
			else { $$parent{FillerColumns} = $fw; };
			$filler && ($text .= $self->publish_text($filler, $parent));
		};
		$text .= "</TR>\n";
	};
	if ($footer) { $text .= $self->publish_text($footer,$parent); };
	return $text;
};


=back

=head1 PREREQUISITES

This module inherits and extends the C<Text::Merge> module by this author.
This module was written and tested under perl 5.005 and runs with C<-Tw> set and C<use strict>. 

=head1 AUTHOR

This software is released under the Perl Artistic License.  Modify as you please, but please 
attribute releases and include all derived source code.  (C) 1997, 1998, 1999, by Steven D. Harris, 
sharris@nullspace.com

=cut


