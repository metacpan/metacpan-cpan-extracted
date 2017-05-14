package CGI::Form;

require 5.001;
use CGI::Carp;
use Exporter;
use CGI::Request;

@ISA = ('CGI::Request','Exporter');
$revision='$Id: Form.pm,v 2.75 1996/2/15 04:54:10 lstein Exp $';
($VERSION=$revision)=~s/.*(\d+\.\d+).*/$1/;

$URL_ENCODED = 'application/x-www-form-urlencoded';
$MULTIPART = 'multipart/form-data';
@EXPORT_OK = qw(URL_ENCODED MULTIPART);

=head1 NAME

CGI::Form - Build Smart HTML Forms on Top of the CGI:: Modules

=head1 ABSTRACT

This perl library uses perl5 objects to make it easy to create
Web fill-out forms and parse their contents.  This package
defines CGI objects, entities that contain the values of the
current query string and other state variables.
Using a CGI object's methods, you can examine keywords and parameters
passed to your script, and create forms whose initial values
are taken from the current query (thereby preserving state
information).

=head1 INSTALLATION:

To use this package, install it in your perl library path (usually
/usr/local/lib/perl5/ and add the following to your perl CGI script:

   Use CGI::Form;

=head1 DESCRIPTION

=head2 CREATING A NEW FORM OBJECT AND PROCESSING PARAMETERS:

       $query = new CGI::Form;

This will parse the input (from both POST and GET methods) and store
it into a perl5 object called $query.  This method is inherited from
L<CGI::Request>.  See its manpage for details.  Similarly, CGI::Form
uses CGI::Request to get and set named query parameters, e.g.

    @values = $query->param('foo');

	      -and-

    $query->param('foo','an','array','of','values');
or whatever!

=head2 CALLING CGI::Form FUNCTIONS THAT TAKE MULTIPLE ARGUMENTS

In versions of Form.pm prior to 2.8, it could get difficult to remember
the proper order of arguments in CGI function calls that accepted five
or six different arguments.  As of 2.8, there's a better way to pass
arguments to the various CGI functions.  In this style, you pass a
series of name=>argument pairs, like this:

   $field = $query->radio_group(-name=>'OS',
                                -values=>[Unix,Windows,Macintosh],
                                -default=>'Unix');

The advantages of this style are that you don't have to remember the
exact order of the arguments, and if you leave out a parameter, in
most cases it will default to some reasonable value.  If you provide
a parameter that the method doesn't recognize, it will usually do
something useful with it, such as incorporating it into the HTML form
tag.  For example if Netscape decides next week to add a new
JUSTIFICATION parameter to the text field tags, you can start using
the feature without waiting for a new version of CGI.pm:

   $field = $query->textfield(-name=>'State',
                              -default=>'gaseous',
                              -justification=>'RIGHT');

This will result in an HTML tag that looks like this:

	<INPUT TYPE="textfield" NAME="State" VALUE="gaseous"
               JUSTIFICATION="RIGHT">

Parameter names are case insensitive: you can use -name, or -Name or
-NAME.  You don't have to use the hyphen if you don't want to.  After
creating a CGI object, call the B<use_named_parameters()> method with
a nonzero value.  This will tell CGI.pm that you intend to use named
parameters exclusively:

   $query = new CGI;
   $query->use_named_parameters(1);
   $field = $query->radio_group('name'=>'OS',
                                'values'=>['Unix','Windows','Macintosh'],
                                'default'=>'Unix');

Actually, CGI.pm only looks for a hyphen in the first parameter.  So
you can leave it off subsequent parameters if you like.  Something to
be wary of is the potential that a string constant like "values" will
collide with a keyword (and in fact it does!) While Perl usually
figures out when you're referring to a function and when you're
referring to a string, you probably should put quotation marks around
all string constants just to play it safe.

=head2 CREATING A SELF-REFERENCING URL THAT PRESERVES STATE INFORMATION:

    $myself = $query->self_url
    print "<A HREF=$myself>I'm talking to myself.</A>

self_url() will return a URL, that, when selected, will reinvoke
this script with all its state information intact.  This is most
useful when you want to jump around within the document using
internal anchors but you don't want to disrupt the current contents
of the form(s).  Something like this will do the trick.

     $myself = $query->self_url
     print "<A HREF=$myself#table1>See table 1</A>
     print "<A HREF=$myself#table2>See table 2</A>
     print "<A HREF=$myself#yourself>See for yourself</A>

This method is actually defined in L<CGI::Base>, but is passed
through here for compatability with CGI.pm

=head2 CREATING THE HTTP HEADER:

	print $query->header;

             -or-

        print $query->header('image/gif');

header() returns the Content-type: header.
you can provide your own MIME type if you choose,
otherwise it defaults to text/html.

This method is provided for compatability with CGI.pm B<only>.  It 
is much better to use the SendHeaders() method of L<CGI::Base>.

B<NOTE:> This is a temporary method that will be replaced by
the CGI::Response module as soon as it is released.

=head2 GENERATING A REDIRECTION INSTRUCTION

	print $query->redirect('http://somewhere.else/in/movie/land');

redirect the browser elsewhere.  If you use redirection like this,
you should B<not> print out a header as well.

This method is provided for compatability with CGI.pm B<only>.  New
scripts should use CGI::Base's redirect() method instead.

=head2 CREATING THE HTML HEADER:

   print $query->start_html(-title=>'Secrets of the Pyramids',
                            -author=>'fred@capricorn.org',
                            -base=>'true',
                            -BGCOLOR=>"#00A0A0"');

   -or-

   print $query->start_html('Secrets of the Pyramids',
                            'fred@capricorn.org','true',
                            'BGCOLOR="#00A0A0"');

This will return a canned HTML header and the opening <BODY> tag.  
All parameters are optional.   In the named parameter form, recognized
parameters are -title, -author and -base (see below for the
explanation).  Any additional parameters you provide, such as the
Netscape unofficial BGCOLOR attribute, are added to the <BODY> tag.

Positional parameters are as follows:

=over 4

=item B<Parameters:>

=item 1.

The title

=item 2.

The author's e-mail address (will create a <LINK REV="MADE"> tag if present

=item 3.

A 'true' flag if you want to include a <BASE> tag in the header.  This
helps resolve relative addresses to absolute ones when the document is moved, 
but makes the document hierarchy non-portable.  Use with care!

=item 4, 5, 6...

Any other parameters you want to include in the <BODY> tag.  This is a good
place to put Netscape extensions, such as colors and wallpaper patterns.

=back

=head2 ENDING THE HTML DOCUMENT:

	print $query->end_html

This ends an HTML document by printing the </BODY></HTML> tags.

=head1 CREATING FORMS:

I<General note>  The various form-creating methods all return strings
to the caller, containing the tag or tags that will create the requested
form element.  You are responsible for actually printing out these strings.
It's set up this way so that you can place formatting tags
around the form elements.

I<Another note> The default values that you specify for the forms are only
used the B<first> time the script is invoked.  If there are already values
present in the query string, they are used, even if blank.  If you want
to change the value of a field from its previous value, call the param()
method to set it.

I<Yet another note> By default, the text and labels of form elements are
escaped according to HTML rules.  This means that you can safely use
"<CLICK ME>" as the label for a button.  However, it also interferes with
your ability to incorporate special HTML character sequences, such as &Aacute;,
into your fields.  If you wish to turn off automatic escaping, call the
autoEscape() method with a false value immediately after creating the CGI object:

   $query = new CGI::Form;
   $query->autoEscape(undef);
			     

=head2 CREATING AN ISINDEX TAG

   print $query->isindex($action);

Prints out an <ISINDEX> tag.  Not very exciting.  The optional
parameter specifies an ACTION="<URL>" attribute.

=head2 STARTING AND ENDING A FORM

    print $query->startform($method,$action,$encoding);
      <... various form stuff ...>
    print $query->endform;

startform() will return a <FORM> tag with the optional method,
action and form encoding that you specify.  The defaults are:
	
    method: POST
    action: this script
    encoding: application/x-www-form-urlencoded

The encoding method tells the browser how to package the various
fields of the form before sending the form to the server.  Two
values are possible:

=over 4

=item B<application/x-www-form-urlencoded>

This is the older type of encoding used by all browsers prior to
Netscape 2.0.  It is compatible with many CGI scripts and is
suitable for short fields containing text data.

=item B<multipart/form-data>

This is the newer type of encoding introduced by Netscape 2.0.
It is suitable for forms that contain very large fields or that
are intended for transferring binary data.  Most importantly,
it enables the "file upload" feature of Netscape 2.0 forms.

Forms that use this type of encoding are not easily interpreted
by CGI scripts unless they use CGI.pm or another library designed
to handle them.

=back

For your convenience, Form.pm defines two subroutines that contain
the values of the two alternative encodings:

    use CGI::Form(URL_ENCODED,MULTIPART);

For compatability, the startform() method uses the older form of
encoding by default.  If you want to use the newer form of encoding
by default, you can call B<start_multipart_form()> instead of
B<startform()>.
	
endform() returns a </FORM> tag.  

=head2 CREATING A TEXT FIELD

    print $query->textfield(-name=>'field_name',
	                    -default=>'starting value',
	                    -size=>50,
	                    -maxlength=>80);
	-or-

    print $query->textfield('field_name','starting value',50,80);

textfield() will return a text input field.  

=over 4

=item B<Parameters>

=item 1.

The first parameter is the required name for the field (-name).  

=item 2.

The optional second parameter is the default starting value for the field
contents (-default).  

=item 3.

The optional third parameter is the size of the field in
      characters (-size).

=item 4.

The optional fourth parameter is the maximum number of characters the
      field will accept (-maxlength).

=back

As with all these methods, the field will be initialized with its 
previous contents from earlier invocations of the script.
When the form is processed, the value of the text field can be
retrieved with:

       $value = $query->param('foo');

If you want to reset it from its initial value after the script has been
called once, you can do so like this:

       $query->param('foo',"I'm taking over this value!");

=head2 CREATING A BIG TEXT FIELD

   print $query->textarea(-name=>'foo',
	 		  -default=>'starting value',
	                  -rows=>10,
	                  -columns=>50);

	-or

   print $query->textarea('foo','starting value',10,50);

textarea() is just like textfield, but it allows you to specify
rows and columns for a multiline text entry box.  You can provide
a starting value for the field, which can be long and contain
multiple lines.

=head2 CREATING A PASSWORD FIELD

   print $query->password_field(-name=>'secret',
				-value=>'starting value',
				-size=>50,
				-maxlength=>80);
	-or-

   print $query->password_field('secret','starting value',50,80);

password_field() is identical to textfield(), except that its contents 
will be starred out on the web page.

=head2 CREATING A FILE UPLOAD FIELD

    print $query->filefield(-name=>'uploaded_file',
	                    -default=>'starting value',
	                    -size=>50,
	 		    -maxlength=>80);
	-or-

    print $query->filefield('uploaded_file','starting value',50,80);

filefield() will return a file upload field for Netscape 2.0 browsers.
In order to take full advantage of this I<you must use the new 
multipart encoding scheme> for the form.  You can do this either
by calling B<startform()> with an encoding type of B<$CGI::MULTIPART>,
or by calling the new method B<start_multipart_form()> instead of
vanilla B<startform()>.

=over 4

=item B<Parameters>

=item 1.

The first parameter is the required name for the field (-name).  

=item 2.

The optional second parameter is the starting value for the field contents
to be used as the default file name (-default).

The beta2 version of Netscape 2.0 currently doesn't pay any attention
to this field, and so the starting value will always be blank.  Worse,
the field loses its "sticky" behavior and forgets its previous
contents.  The starting value field is called for in the HTML
specification, however, and possibly later versions of Netscape will
honor it.

=item 3.

The optional third parameter is the size of the field in
characters (-size).

=item 4.

The optional fourth parameter is the maximum number of characters the
field will accept (-maxlength).

=back

When the form is processed, you can retrieve the entered filename
by calling param().

       $filename = $query->param('uploaded_file');

In Netscape Beta 1, the filename that gets returned is the full local filename
on the B<remote user's> machine.  If the remote user is on a Unix
machine, the filename will follow Unix conventions:

	/path/to/the/file

On an MS-DOS/Windows machine, the filename will follow DOS conventions:

	C:\PATH\TO\THE\FILE.MSW

On a Macintosh machine, the filename will follow Mac conventions:

	HD 40:Desktop Folder:Sort Through:Reminders

In Netscape Beta 2, only the last part of the file path (the filename
itself) is returned.  I don't know what the release behavior will be.

The filename returned is also a file handle.  You can read the contents
of the file using standard Perl file reading calls:

	# Read a text file and print it out
	while (<$filename>) {
	   print;
        }

        # Copy a binary file to somewhere safe
        open (OUTFILE,">>/usr/local/web/users/feedback");
	while ($bytesread=read($filename,$buffer,1024)) {
	   print OUTFILE $buffer;
        }

=head2 CREATING A POPUP MENU

   print $query->popup_menu('menu_name',
                            ['eenie','meenie','minie'],
                            'meenie');

      -or-

   %labels = ('eenie'=>'your first choice',
              'meenie'=>'your second choice',
              'minie'=>'your third choice');
   print $query->popup_menu('menu_name',
                            ['eenie','meenie','minie'],
                            'meenie',\%labels);

	-or (named parameter style)-

   print $query->popup_menu(-name=>'menu_name',
			    -values=>['eenie','meenie','minie'],
	                    -default=>'meenie',
	                    -labels=>\%labels);

popup_menu() creates a menu.

=over 4

=item 1.

The required first argument is the menu's name (-name).

=item 2.

The required second argument (-values) is an array B<reference>
containing the list of menu items in the menu.  You can pass the
method an anonymous array, as shown in the example, or a reference to
a named array, such as "\@foo".

=item 3.

The optional third parameter (-default) is the name of the default
menu choice.  If not specified, the first item will be the default.
The values of the previous choice will be maintained across queries.

=item 4.

The optional fourth parameter (-labels) is provided for people who
want to use different values for the user-visible label inside the
popup menu nd the value returned to your script.  It's a pointer to an
associative array relating menu values to user-visible labels.  If you
leave this parameter blank, the menu values will be displayed by
default.  (You can also leave a label undefined if you want to).

=back

When the form is processed, the selected value of the popup menu can
be retrieved using:

      $popup_menu_value = $query->param('menu_name');

=head2 CREATING A SCROLLING LIST

   print $query->scrolling_list('list_name',
                                ['eenie','meenie','minie','moe'],
                                ['eenie','moe'],5,'true');
      -or-

   print $query->scrolling_list('list_name',
                                ['eenie','meenie','minie','moe'],
                                ['eenie','moe'],5,'true',
                                \%labels);

	-or-

   print $query->scrolling_list(-name=>'list_name',
                                -values=>['eenie','meenie','minie','moe'],
                                -default=>['eenie','moe'],
	                        -size=>5,
	                        -multiple=>'true',
                                -labels=>\%labels);

scrolling_list() creates a scrolling list.  

=over 4

=item B<Parameters:>

=item 1.

The first and second arguments are the list name (-name) and values
(-values).  As in the popup menu, the second argument should be an
array reference.

=item 2.

The optional third argument (-default) can be either a reference to a
list containing the values to be selected by default, or can be a
single value to select.  If this argument is missing or undefined,
then nothing is selected when the list first appears.  In the named
parameter version, you can use the synonym "-defaults" for this
parameter.

=item 3.

The optional fourth argument is the size of the list (-size).

=item 4.

The optional fifth argument can be set to true to allow multiple
simultaneous selections (-multiple).  Otherwise only one selection
will be allowed at a time.

=item 5.

The optional sixth argument is a pointer to an associative array
containing long user-visible labels for the list items (-labels).
If not provided, the values will be displayed.

When this form is procesed, all selected list items will be returned as
a list under the parameter name 'list_name'.  The values of the
selected items can be retrieved with:

      @selected = $query->param('list_name');

=back

=head2 CREATING A GROUP OF RELATED CHECKBOXES

   print $query->checkbox_group(-name=>'group_name',
                                -values=>['eenie','meenie','minie','moe'],
                                -default=>['eenie','moe'],
	                        -linebreak=>'true',
	                        -labels=>\%labels);

   print $query->checkbox_group('group_name',
                                ['eenie','meenie','minie','moe'],
                                ['eenie','moe'],'true',\%labels);

   HTML3-COMPATIBLE BROWSERS ONLY:

   print $query->checkbox_group(-name=>'group_name',
                                -values=>['eenie','meenie','minie','moe'],
	                        -rows=2,-columns=>2);
    

checkbox_group() creates a list of checkboxes that are related
by the same name.

=over 4

=item B<Parameters:>

=item 1.

The first and second arguments are the checkbox name and values,
respectively (-name and -values).  As in the popup menu, the second
argument should be an array reference.  These values are used for the
user-readable labels printed next to the checkboxes as well as for the
values passed to your script in the query string.

=item 2.

The optional third argument (-default) can be either a reference to a
list containing the values to be checked by default, or can be a
single value to checked.  If this argument is missing or undefined,
then nothing is selected when the list first appears.

=item 3.

The optional fourth argument (-linebreak) can be set to true to place
line breaks between the checkboxes so that they appear as a vertical
list.  Otherwise, they will be strung together on a horizontal line.

=item 4.

The optional fifth argument is a pointer to an associative array
relating the checkbox values to the user-visible labels that will will
be printed next to them (-labels).  If not provided, the values will
be used as the default.

=item 5.

B<HTML3-compatible browsers> (such as Netscape) can take advantage 
of the optional 
parameters B<-rows>, and B<-columns>.  These parameters cause
checkbox_group() to return an HTML3 compatible table containing
the checkbox group formatted with the specified number of rows
and columns.  You can provide just the -columns parameter if you
wish; checkbox_group will calculate the correct number of rows
for you.

To include row and column headings in the returned table, you
can use the B<-rowheader> and B<-colheader> parameters.  Both
of these accept a pointer to an array of headings to use.
The headings are just decorative.  They don't reorganize the
interpetation of the checkboxes -- they're still a single named
unit.

=back

When the form is processed, all checked boxes will be returned as
a list under the parameter name 'group_name'.  The values of the
"on" checkboxes can be retrieved with:

      @turned_on = $query->param('group_name');

=head2 CREATING A STANDALONE CHECKBOX

    print $query->checkbox(-name=>'checkbox_name',
			   -checked=>'checked',
		           -value=>'ON',
		           -label=>'CLICK ME');

	-or-

    print $query->checkbox('checkbox_name','checked','ON','CLICK ME');

checkbox() is used to create an isolated checkbox that isn't logically
related to any others.

=over 4

=item B<Parameters:>

=item 1.

The first parameter is the required name for the checkbox (-name).  It
will also be used for the user-readable label printed next to the
checkbox.

=item 2.

The optional second parameter (-checked) specifies that the checkbox
is turned on by default.  Synonyms are -selected and -on.

=item 3.

The optional third parameter (-value) specifies the value of the
checkbox when it is checked.  If not provided, the word "on" is
assumed.

=item 4.

The optional fourth parameter (-label) is the user-readable label to
be attached to the checkbox.  If not provided, the checkbox name is
used.

=back

The value of the checkbox can be retrieved using:

    $turned_on = $query->param('checkbox_name');

=head2 CREATING A RADIO BUTTON GROUP

   print $query->radio_group(-name=>'group_name',
			     -values=>['eenie','meenie','minie'],
                             -default=>'meenie',
			     -linebreak=>'true',
			     -labels=>\%labels);

	-or-

   print $query->radio_group('group_name',['eenie','meenie','minie'],
                                          'meenie','true',\%labels);


   HTML3-COMPATIBLE BROWSERS ONLY:

   print $query->checkbox_group(-name=>'group_name',
                                -values=>['eenie','meenie','minie','moe'],
	                        -rows=2,-columns=>2);

radio_group() creates a set of logically-related radio buttons
(turning one member of the group on turns the others off)

=over 4

=item B<Parameters:>

=item 1.

The first argument is the name of the group and is required (-name).

=item 2.

The second argument (-values) is the list of values for the radio
buttons.  The values and the labels that appear on the page are
identical.  Pass an array I<reference> in the second argument, either
using an anonymous array, as shown, or by referencing a named array as
in "\@foo".

=item 3.

The optional third parameter (-default) is the name of the default
button to turn on. If not specified, the first item will be the
default.  You can provide a nonexistent button name, such as "-" to
start up with no buttons selected.

=item 4.

The optional fourth parameter (-linebreak) can be set to 'true' to put
line breaks between the buttons, creating a vertical list.

=item 5.

The optional fifth parameter (-labels) is a pointer to an associative
array relating the radio button values to user-visible labels to be
used in the display.  If not provided, the values themselves are
displayed.

=item 6.

B<HTML3-compatible browsers> (such as Netscape) can take advantage 
of the optional 
parameters B<-rows>, and B<-columns>.  These parameters cause
radio_group() to return an HTML3 compatible table containing
the radio group formatted with the specified number of rows
and columns.  You can provide just the -columns parameter if you
wish; radio_group will calculate the correct number of rows
for you.

To include row and column headings in the returned table, you
can use the B<-rowheader> and B<-colheader> parameters.  Both
of these accept a pointer to an array of headings to use.
The headings are just decorative.  They don't reorganize the
interpetation of the radio buttons -- they're still a single named
unit.

=back

When the form is processed, the selected radio button can
be retrieved using:

      $which_radio_button = $query->param('group_name');

=head2 CREATING A SUBMIT BUTTON 

   print $query->submit(-name=>'button_name',
		        -value=>'value');

	-or-

   print $query->submit('button_name','value');

submit() will create the query submission button.  Every form
should have one of these.

=over 4

=item B<Parameters:>

=item 1.

The first argument (-name) is optional.  You can give the button a
name if you have several submission buttons in your form and you want
to distinguish between them.  The name will also be used as the
user-visible label.  Be aware that a few older browsers don't deal with this correctly and
B<never> send back a value from a button.

=item 2.

The second argument (-value) is also optional.  This gives the button
a value that will be passed to your script in the query string.

=back

You can figure out which button was pressed by using different
values for each one:

     $which_one = $query->param('button_name');


=head2 CREATING A RESET BUTTON

   print $query->reset

reset() creates the "reset" button.  Note that it restores the
form to its value from the last time the script was called, 
NOT necessarily to the defaults.

=head2 CREATING A DEFAULT BUTTON

   print $query->defaults('button_label')

defaults() creates a button that, when invoked, will cause the
form to be completely reset to its defaults, wiping out all the
changes the user ever made.

=head2 CREATING A HIDDEN FIELD

	print $query->hidden(-name=>'hidden_name',
	                     -default=>['value1','value2'...]);

		-or-

	print $query->hidden('hidden_name','value1','value2'...);

hidden() produces a text field that can't be seen by the user.  It
is useful for passing state variable information from one invocation
of the script to the next.

=over 4

=item B<Parameters:>

=item 1.

The first argument is required and specifies the name of this
field (-name).

=item 2.  

The second argument is also required and specifies its value
(-default).  In the named parameter style of calling, you can provide
a single value here or a reference to a whole list

=back

Fetch the value of a hidden field this way:

     $hidden_value = $query->param('hidden_name');

Note, that just like all the other form elements, the value of a
hidden field is "sticky".  If you want to replace a hidden field with
some other values after the script has been called once you'll have to
do it manually:

     $query->param('hidden_name','new','values','here');

=head2 CREATING A CLICKABLE IMAGE BUTTON

     print $query->image_button(-name=>'button_name',
			        -src=>'/source/URL',
			        -align=>'MIDDLE');	

	-or-

     print $query->image_button('button_name','/source/URL','MIDDLE');

image_button() produces a clickable image.  When it's clicked on the
position of the click is returned to your script as "button_name.x"
and "button_name.y", where "button_name" is the name you've assigned
to it.

=over 4

=item B<Parameters:>

=item 1.

The first argument (-name) is required and specifies the name of this
field.

=item 2.

The second argument (-src) is also required and specifies the URL

=item 3.
The third option (-align, optional) is an alignment type, and may be
TOP, BOTTOM or MIDDLE

=back

Fetch the value of the button this way:
     $x = $query->param('button_name.x');
     $y = $query->param('button_name.y');

=head1 DEBUGGING:

If you are running the script
from the command line or in the perl debugger, you can pass the script
a list of keywords or parameter=value pairs on the command line or 
from standard input (you don't have to worry about tricking your
script into reading from environment variables).
You can pass keywords like this:

    your_script.pl keyword1 keyword2 keyword3

or this:

   your_script.pl keyword1+keyword2+keyword3

or this:

    your_script.pl name1=value1 name2=value2

or this:

    your_script.pl name1=value1&name2=value2

or even as newline-delimited parameters on standard input.

When debugging, you can use quotes and backslashes to escape 
characters in the familiar shell manner, letting you place
spaces and other funny characters in your parameter=value
pairs:

   your_script.pl name1='I am a long value' name2=two\ words

=head2 DUMPING OUT ALL THE NAME/VALUE PAIRS

The dump() method produces a string consisting of all the query's
name/value pairs formatted nicely as a nested list.  This is useful
for debugging purposes:

    print $query->dump
    

Produces something that looks like:

    <UL>
    <LI>name1
        <UL>
        <LI>value1
        <LI>value2
        </UL>
    <LI>name2
        <UL>
        <LI>value1
        </UL>
    </UL>

You can pass a value of 'true' to dump() in order to get it to
print the results out as plain text, suitable for incorporating
into a <PRE> section.

=head1 FETCHING ENVIRONMENT VARIABLES

All the environment variables, such as REMOTE_HOST and HTTP_REFERER,
are available through the CGI::Base object.  You can get at these
variables using with the cgi() method (inherited from CGI::Request):

    $query->cgi->var('REMOTE_HOST');

=head1 AUTHOR INFORMATION

This code is copyright 1995 by Lincoln Stein and the Whitehead 
Institute for Biomedical Research.  It may be used and modified 
freely.  I request, but do not require, that this credit appear
in the code.

Address bug reports and comments to:
lstein@genome.wi.mit.edu

=head1 A COMPLETE EXAMPLE OF A SIMPLE FORM-BASED SCRIPT


	#!/usr/local/bin/perl
     
        use CGI::Form;
 
        $query = new CGI::Form;

 	print $query->header;
 	print $query->start_html("Example CGI.pm Form");
 	print "<H1> Example CGI.pm Form</H1>\n";
 	&print_prompt($query);
 	&do_work($query);
	&print_tail;
 	print $query->end_html;
 
 	sub print_prompt {
     	   my($query) = @_;
 
     	   print $query->startform;
     	   print "<EM>What's your name?</EM><BR>";
     	   print $query->textfield('name');
     	   print $query->checkbox('Not my real name');
 
     	   print "<P><EM>Where can you find English Sparrows?</EM><BR>";
     	   print $query->checkbox_group('Sparrow locations',
 				 [England,France,Spain,Asia,Hoboken],
 				 [England,Asia]);
 
     	   print "<P><EM>How far can they fly?</EM><BR>",
            	$query->radio_group('how far',
 		       ['10 ft','1 mile','10 miles','real far'],
 		       '1 mile');
 
     	   print "<P><EM>What's your favorite color?</EM>  ";
     	   print $query->popup_menu('Color',['black','brown','red','yellow'],'red');
 
     	   print $query->hidden('Reference','Monty Python and the Holy Grail');
 
     	   print "<P><EM>What have you got there?</EM>  ";
     	   print $query->scrolling_list('possessions',
 			 ['A Coconut','A Grail','An Icon',
 			  'A Sword','A Ticket'],
 			 undef,
 			 10,
 			 'true');
 
     	   print "<P><EM>Any parting comments?</EM><BR>";
     	   print $query->textarea('Comments',undef,10,50);
 
     	   print "<P>",$query->reset;
     	   print $query->submit('Action','Shout');
     	   print $query->submit('Action','Scream');
     	   print $query->endform;
     	   print "<HR>\n";
 	}
 
 	sub do_work {
     	   my($query) = @_;
     	   my(@values,$key);

     	   print "<H2>Here are the current settings in this form</H2>";

     	   foreach $key ($query->param) {
 	      print "<STRONG>$key</STRONG> -> ";
 	      @values = $query->param($key);
 	      print join(", ",@values),"<BR>\n";
          }
 	}
 
 	sub print_tail {
     	   print <<END;
 	<HR>
 	<ADDRESS>Lincoln D. Stein</ADDRESS><BR>
 	<A HREF="/">Home Page</A>
 	END
 	}

=head1 BUGS

This module doesn't do as much as CGI.pm, and it takes longer to load.
Such is the price of flexibility.

=head1 SEE ALSO

L<URI::URL>, L<CGI::Request>, L<CGI::MiniSvr>, L<CGI::Base>, L<CGI>

=cut

%OVERLOAD = ('""'=>'dump');

#### Method: new
# The new routine.  This will check the current environment
# for an existing query string, and initialize itself, if so.
####
sub new {
    my($package) = @_;
    my $self = new CGI::Request;	# this does all the dirty work
    bless $self,$package;		# rebless it into our own package

    # Special case.  Erase everything if there is a field named
    # .defaults.
    if ($self->param('.defaults')) {
	undef %{$self};
	undef $CGI::Base::QUERY_STRING;
    }

    # Another special case -- clear out our default submission
    # button flag if present;
    $self->delete('.submit');
    $self;
}

#### Method: autoEscape
# If you won't to turn off the autoescaping features,
# call this method with undef as the argument
####
sub autoEscape {
    my($self,$escape) = @_;
    $self->{'dontescape'}=!$escape;
}

#### Method: dump
# Returns a string in which all the known parameter/value 
# pairs are represented as nested lists, mainly for the purposes 
# of debugging.  You can specify the PRE flag to get straight
# text.
####
sub dump {
    my($self) = @_;
    my($param,$value,@result);
    return unless $self->param;
    push(@result,"<UL>");
    foreach $param ($self->param) {
	my($name)=$self->escapeHTML($param);
	push(@result,"<LI><STRONG>$param</STRONG>");
	push(@result,"<UL>");
	foreach $value ($self->param($param)) {
	    $value = $self->escapeHTML($value);
	    push(@result,"<LI>$value");
	}
	push(@result,"</UL>");
    }
    push(@result,"</UL>\n");
    return join("\n",@result);
}

#### Method: header
# Print a Content-type: style header
# Uses Base.pm to do the dirty work.
####
sub header {
    local($self,$type) = @_;
    return &CGI::Base::ContentTypeHdr($type) . "\r\n";
}


################################
# METHODS USED IN BUILDING FORMS
################################

#### Method: isindex
# Just prints out the isindex tag.
# Parameters:
#  $action -> optional URL of script to run
# Returns:
#   A string containing a <ISINDEX> tag
sub isindex {
    my($self,$action) = @_;
    $action = $action ? qq/ACTION="$action"/ : '';
    return "<ISINDEX $action>";
}

#### Method: startform
# Start a form
sub startform {
    my($self,@p) = @_;

    my($method,$action,$enctype,@other) = 
	$self->rearrange([METHOD,ACTION,ENCTYPE],@p);

    $method = $method || 'POST';
    $enctype = $enctype || $URL_ENCODED;
    $action = $action ? qq/ACTION="$action"/ : '';
    return qq/<FORM METHOD="$method" $action ENCTYPE=$enctype @other>\n/;
}

#### Method: start_multipart_form
# synonym for startform
sub start_multipart_form {
    my($self,@p) = @_;
    my($method,$action,$enctype,@other) = 
	$self->rearrange([METHOD,ACTION,ENCTYPE],@p);
    $self->startform($method,$action,$enctype || $MULTIPART,@other);
}

#### Method: endform
# End a form
sub endform {
    return "</FORM>\n";
}

#### Method: start_html
# Canned HTML header
#
# Parameters:
# $title -> (optional) The title for this HTML document
# $author -> (optional) e-mail address of the author
# $base -> (option) if set to true, will enter the BASE address of this document
#          for resolving relative references.
# @other_stuff -> (optional) other parameters you want to include in <BODY>
####
sub start_html {
    my($self,@p) = @_;
    my($title,$author,$base,@other) = 
	$self->rearrange([TITLE,AUTHOR,BASE],@p);

    # strangely enough, the title needs to be escaped as HTML
    # while the author needs to be escaped as a URL
    $title = $self->escapeHTML($title || 'Untitled Document');
    $author = $self->escapeHTML($author);
    my(@result);
    push(@result,"<HTML><HEAD><TITLE>$title</TITLE>");
    push(@result,"<LINK REV=MADE HREF=\"mailto:$author\">") if $author;
    push(@result,"<BASE HREF=\"http://".$self->server_name.":".$self->server_port.$self->script_name."\">") if $base;

    push(@result,"</HEAD><BODY @other>");
    return join("\n",@result);
}

#### Method: end_html
# End an HTML document.
# Trivial method for completeness.  Just returns "</BODY>"
####
sub end_html {
    return "</BODY></HTML>";
}

#### Method: textfield
# Parameters:
#   $name -> Name of the text field
#   $default -> Optional default value of the field if not
#                already defined.
#   $size ->  Optional width of field in characaters.
#   $maxlength -> Optional maximum number of characters.
# Returns:
#   A string containing a <INPUT TYPE="text"> field
#
sub textfield {
    my($self,@p) = @_;
    my($name,$default,$size,$maxlength,@other) = 
	$self->rearrange([NAME,DEFAULT,SIZE,MAXLENGTH],@p);

    my($current) = defined($self->param($name)) ? $self->param($name) : $default;

    $current = $self->escapeHTML($current) || '';
    $name = $self->escapeHTML($name) || '';
    my($s) = defined($size) ? qq/SIZE=$size/ : '';
    my($m) = defined($maxlength) ? qq/MAXLENGTH=$maxlength/ : '';
    return qq/<INPUT TYPE="text" NAME="$name" VALUE="$current" $s $m @other>/;
}

#### Method: filefield
# Parameters:
#   $name -> Name of the file upload field
#   $size ->  Optional width of field in characaters.
#   $maxlength -> Optional maximum number of characters.
# Returns:
#   A string containing a <INPUT TYPE="file"> field

sub filefield {
    my($self,@p) = @_;

    my($name,$default,$size,$maxlength,@other) = 
	$self->rearrange([NAME,DEFAULT,SIZE,MAXLENGTH],@p);
    my($current);

    ($current,$default) = ('','');
    $current = defined($self->param($name)) ? $self->param($name) : $default;
    $name = $self->escapeHTML($name);
    my($s) = defined($size) ? qq/SIZE=$size/ : '';
    my($m) = defined($maxlength) ? qq/MAXLENGTH=$maxlength/ : '';
    return qq/<INPUT TYPE="file" NAME="$name" VALUE="$current" $s $m @other>/;
}

#### Method: password
# Create a "secret password" entry field
# Parameters:
#   $name -> Name of the field
#   $default -> Optional default value of the field if not
#                already defined.
#   $size ->  Optional width of field in characters.
#   $maxlength -> Optional maximum characters that can be entered.
# Returns:
#   A string containing a <INPUT TYPE="password"> field
#
sub password_field {
    my ($self,@p) = @_;

    my($name,$default,$size,$maxlength,@other) = 
	$self->rearrange([NAME,DEFAULT,SIZE,MAXLENGTH],@p);

    my($current) =  defined($self->param($name)) ? $self->param($name) : $default;
    $name=$self->escapeHTML($name);
    $current=$self->escapeHTML($current);
    my($s) = defined($size) ? qq/SIZE=$size/ : '';
    my($m) = defined($maxlength) ? qq/MAXLENGTH=$maxlength/ : '';
    return qq/<INPUT TYPE="password" NAME="$name" VALUE="$current" $s $m @other>/;
}

#### Method: textarea
# Parameters:
#   $name -> Name of the text field
#   $default -> Optional default value of the field if not
#                already defined.
#   $rows ->  Optional number of rows in text area
#   $columns -> Optional number of columns in text area
# Returns:
#   A string containing a <TEXTAREA></TEXTAREA> tag
#
sub textarea {
    my($self,@p) = @_;
    
    my($name,$default,$rows,$cols,@other) =
	$self->rearrange([NAME,DEFAULT,ROWS,[COLS,COLUMNS]],@p);

    my($current)= defined($self->param($name)) ? $self->param($name) : $default;
    $name=$self->escapeHTML($name);
    $current=$self->escapeHTML($current);
    my($r) = "ROWS=$rows" if $rows;
    my($c) = "COLS=$cols" if $cols;
    return qq{<TEXTAREA NAME="$name" $r $c @other>$current</TEXTAREA>};
}

#### Method: submit
# Create a "submit query" button.
# Parameters:
#   $label -> (optional) Name for the button.
#   $value -> (optional) Value of the button when selected.
# Returns:
#   A string containing a <INPUT TYPE="submit"> tag
####
sub submit {
    my($self,@p) = @_;

    my($label,$value,@other) = $self->rearrange([NAME,VALUE],@p);

    $label=$self->escapeHTML($label);
    $value=$self->escapeHTML($value);

    my($name) = 'NAME=".submit"';
    $name = qq/NAME="$label"/ if $label;
    $value = $value || $label;
    my($val) = '';
    $val = qq/VALUE="$value"/ if $value;
    return qq/<INPUT TYPE="submit" $name $val @other>/;
}

#### Method: reset
# Create a "reset" button.
# Parameters:
#   $label -> (optional) Name for the button.
# Returns:
#   A string containing a <INPUT TYPE="reset"> tag
####
sub reset {
    my($self,@p) = @_;
    my($label,@other) = $self->rearrange([NAME],@p);
    $label=$self->escapeHTML($label);
    my($value) = $label ? qq/VALUE="$label"/ : '';

    return qq/<INPUT TYPE="reset" $value @other>/;
}

#### Method: defaults
# Create a "defaults" button.
# Parameters:
#   $label -> (optional) Name for the button.
# Returns:
#   A string containing a <INPUT TYPE="submit" NAME=".defaults"> tag
#
# Note: this button has a special meaning to the initialization script,
# and tells it to ERASE the current query string so that your defaults
# are used again!
####
sub defaults {
    my($self,@p) = @_;

    my($label,@other) = $self->rearrange([NAME],@p);

    $label=$self->escapeHTML($label);
    $label = $label || "Defaults";
    my($value) = qq/VALUE="$label"/;
    return qq/<INPUT TYPE="submit" NAME=".defaults" $value @other>/;
}

#### Method: checkbox
# Create a checkbox that is not logically linked to any others.
# The field value is "on" when the button is checked.
# Parameters:
#   $name -> Name of the checkbox
#   $checked -> (optional) turned on by default if true
#   $value -> (optional) value of the checkbox, 'on' by default
#   $label -> (optional) a user-readable label printed next to the box.
#             Otherwise the checkbox name is used.
# Returns:
#   A string containing a <INPUT TYPE="checkbox"> field
####
sub checkbox {
    my($self,@p) = @_;

    my($name,$checked,$value,$label,@other) = 
	$self->rearrange([NAME,[CHECKED,SELECTED,ON],VALUE,LABEL],@p);

    if ($self->inited) {
	$checked = $self->param($name) ? 'CHECKED' : '';
	$value = $self->param($name) || $value || 'on';
    } else {
	$checked = defined($checked) ? 'CHECKED' : '';
	$value = $value || 'on';
    }
    my($the_label) = $label || $name;
    $name = $self->escapeHTML($name);
    $value = $self->escapeHTML($value);
    $the_label = $self->escapeHTML($the_label);
    return <<END;
<INPUT TYPE="checkbox" NAME="$name" VALUE="$value" $checked @other>$the_label
END
}

#### Method: checkbox_group
# Create a list of logically-linked checkboxes.
# Parameters:
#   $name -> Common name for all the check boxes
#   $values -> A pointer to a regular array containing the
#             values for each checkbox in the group.
#   $settings -> (optional)
#             1. If a pointer to a regular array of checkbox values,
#             then this will be used to decide which
#             checkboxes to turn on by default.
#             2. If a scalar, will be assumed to hold the
#             value of a single checkbox in the group to turn on. 
#   $linebreak -> (optional) Set to true to place linebreaks
#             between the buttons.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing a series of <INPUT TYPE="checkbox"> fields
####
sub checkbox_group {

    my($self,@p) = @_;
    my($name,$values,$defaults,$linebreak,$labels,$rows,$columns,$rowheaders,$colheaders,@other) =
	$self->rearrange([NAME,[VALUES,VALUE],[DEFAULTS,DEFAULT],
			  LINEBREAK,LABELS,ROWS,[COLUMNS,COLS],
			  ROWHEADERS,COLHEADERS],@p);

    my($checked,$break,$result,$label);

    my(%checked) = $self->previous_or_default($name,$defaults);

    $break = $linebreak ? "<BR>" : '';
    $name=$self->escapeHTML($name);

    # Create the elements
    my(@elements);
    foreach (@$values) {
	$checked = $checked{$_} ? 'CHECKED' : '';
	$label = $_;
	$label = $labels->{$_} if defined($labels) && $labels->{$_};
	$label = $self->escapeHTML($label);
	$_ = $self->escapeHTML($_);
	push(@elements,qq/<INPUT TYPE="checkbox" NAME="$name" VALUE="$_" $checked @other>$label $break/);
    }
    return "@elements" unless $columns;
    return _tableize($rows,$columns,$rowheaders,$colheaders,@elements);
}

#### Method: radio_group
# Create a list of logically-linked radio buttons.
# Parameters:
#   $name -> Common name for all the buttons.
#   $values -> A pointer to a regular array containing the
#             values for each button in the group.
#   $default -> (optional) Value of the button to turn on by default.  Pass '-'
#               to turn _nothing_ on.
#   $linebreak -> (optional) Set to true to place linebreaks
#             between the buttons.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing a series of <INPUT TYPE="radio"> fields
####
sub radio_group {
    my($self,@p) = @_;

    my($name,$values,$default,$linebreak,$labels,$rows,$columns,$rowheaders,$colheaders,@other) =
	$self->rearrange([NAME,[VALUES,VALUE],DEFAULT,LINEBREAK,LABELS,
			  ROWS,[COLUMNS,COLS],
			  ROWHEADERS,COLHEADERS],@p);
    my($result,$checked);

    if (defined($self->param($name))) {
	$checked = $self->param($name);
    } else {
	$checked = $default;
    }
    # If no check array is specified, check the first by default
    $checked = $values->[0] unless $checked;
    $name=$self->escapeHTML($name);

    my(@elements);
    foreach (@{$values}) {
	my($checkit) = $checked eq $_ ? 'CHECKED' : '';
	my($break) = $linebreak ? '<BR>' : '';
	my($label) = $_;
	$label = $labels->{$_} if defined($labels) && $labels->{$_};
	$label = $self->escapeHTML($label);
	$_=$self->escapeHTML($_);
	push(@elements,qq/<INPUT TYPE="radio" NAME="$name" VALUE="$_" $checkit @other>$label $break/);
    }
    return "@elements" unless $columns;
    return _tableize($rows,$columns,$rowheaders,$colheaders,@elements);
}

# Internal procedure - don't use
sub _tableize {
    my($rows,$columns,$rowheaders,$colheaders,@elements) = @_;
    my($result);

    $rows = int(0.99 + @elements/$columns) unless $rows;
    # rearrange into a pretty table
    $result = "<TABLE>";
    my($row,$column);
    unshift(@$colheaders,'') if @$colheaders && @$rowheaders;
    $result .= "<TR><TH>" . join ("<TH>",@{$colheaders}) if @{$colheaders};
    for ($row=0;$row<$rows;$row++) {
	$result .= "<TR>";
	$result .= "<TH>$rowheaders->[$row]" if @$rowheaders;
	for ($column=0;$column<$columns;$column++) {
	    my $index = $column*$rows + $row;
	    next if $index >= @elements;
	    $result .= "<TD>" . $elements[$index];
	}
    }
    $result .= "</TABLE>";
    return $result;
}

#### Method: popup_menu
# Create a popup menu.
# Parameters:
#   $name -> Name for all the menu
#   $values -> A pointer to a regular array containing the
#             text of each menu item.
#   $default -> (optional) Default item to display
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing the definition of a popup menu.
####
sub popup_menu {
    my($self,@p) = @_;

    my($name,$values,$default,$labels,@other) =
	$self->rearrange([NAME,[VALUES,VALUE],[DEFAULT,DEFAULTS],LABELS],@p);
    my($result,$selected);

    if (defined($self->param($name))) {
	$selected = $self->param($name);
    } else {
	$selected = $default;
    }

    $name=$self->escapeHTML($name);
    $result = qq/<SELECT NAME="$name" @other>\n/;
    foreach (@{$values}) {
	my($selectit) = defined($selected) ? ($selected eq $_ ? 'SELECTED' : '' ) : '';
	my($label) = $_;
	$label = $labels->{$_} if defined($labels) && $labels->{$_};
	my($value) = $self->escapeHTML($_);
	$label=$self->escapeHTML($label);
	$result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
    }

    $result .= "</SELECT>\n";
    return $result;
}

#### Method: scrolling_list
# Create a scrolling list.
# Parameters:
#   $name -> name for the list
#   $values -> A pointer to a regular array containing the
#             values for each option line in the list.
#   $defaults -> (optional)
#             1. If a pointer to a regular array of options,
#             then this will be used to decide which
#             lines to turn on by default.
#             2. Otherwise holds the value of the single line to turn on.
#   $size -> (optional) Size of the list.
#   $multiple -> (optional) If set, allow multiple selections.
#   $labels -> (optional)
#             A pointer to an associative array of labels to print next to each checkbox
#             in the form $label{'value'}="Long explanatory label".
#             Otherwise the provided values are used as the labels.
# Returns:
#   A string containing the definition of a scrolling list.
####
sub scrolling_list {
    my($self,@p) = @_;
    my($name,$values,$defaults,$size,$multiple,$labels,@other)
	= $self->rearrange([NAME,[VALUES,VALUE],
			    [DEFAULTS,DEFAULT],SIZE,MULTIPLE,LABELS],
			   @p);

    my($result);
    $size = $size || scalar(@{$values});

    my(%selected) = $self->previous_or_default($name,$defaults);

    my($is_multiple) = $multiple ? 'MULTIPLE' : '';
    my($has_size) = $size ? "SIZE=$size" : '';
    $name=$self->escapeHTML($name);
    $result = qq/<SELECT NAME="$name" $has_size $is_multiple @other>\n/;
    foreach (@{$values}) {
	my($selectit) = $selected{$_} ? 'SELECTED' : '';
	my($label) = $_;
	$label = $labels->{$_} if defined($labels) && $labels->{$_};
	$label=$self->escapeHTML($label);
	my($value)=$self->escapeHTML($_);
	$result .= "<OPTION $selectit VALUE=\"$value\">$label\n";
    }
    $result .= "</SELECT>\n";
    return $result;
}

#### Method: hidden
# Parameters:
#   $name -> Name of the hidden field
#   @default -> (optional) Initial values of field (may be an array)
# Returns:
#   A string containing a <INPUT TYPE="hidden" NAME="name" VALUE="value">
####
sub hidden {
    my($self,@p) = @_;

    # this is the one place where we departed from our standard
    # calling scheme, so we have to special-case (darn)
    my(@result,@value);
    my($name,$default,@other) = $self->rearrange([NAME,[DEFAULT,VALUE,VALUES]],@p);
    if (!$self->param($name)) {
	if (defined($default) && ref($default) && (ref($default) eq 'ARRAY')) {
	    @value = @{$default};
	} else {
	    @value = ($default,@other);
	}
    } else {
	@value = $self->param($name);
    }

    $name=$self->escapeHTML($name);
    foreach (@value) {
	$_=$self->escapeHTML($_);
	push(@result,qq/<INPUT TYPE="hidden" NAME="$name" VALUE="$_">/);
    }
    return join("\n",@result);
}

#### Method: image_button
# Parameters:
#   $name -> Name of the button
#   $src ->  URL of the image source
#   $align -> Alignment style (TOP, BOTTOM or MIDDLE)
# Returns:
#   A string containing a <INPUT TYPE="image" NAME="name" SRC="url" ALIGN="alignment">
####
sub image_button {
    my($self,@p) = @_;

    my($name,$src,$alignment,@other) =
	$self->rearrange([NAME,SRC,ALIGN],@p);

    my($align) = $alignment ? "ALIGN=\U$alignment" : '';
    $name=$self->escapeHTML($name);
    return qq/<INPUT TYPE="image" NAME="$name" SRC="$src" $align @other>/;
}

#### Method: use_named_parameters
# Force CGI.pm to use named parameter-style method calls
# rather than positional parameters.  The same effect
# will happen automatically if the first parameter
# begins with a -.
sub use_named_parameters {
    my($self,$use_named) = @_;
    return $self->{'.named'} unless defined ($use_named);

    # stupidity to avoid annoying warnings
    return $self->{'.named'}=$use_named;
}

sub inited {
    return 1 if $CGI::Base::QUERY_STRING;
    undef;
}

# Escape HTML -- used internally
sub escapeHTML {
    my($self,$toencode) = @_;
    return undef unless defined($toencode);
    return $toencode if $self->{'dontescape'};
    my(@encode) = CGI::Base::html_escape($toencode);
    return $encode[0];
}

sub self_url {
    my $uri = $_[0]->cgi->get_uri;
    if ($CGI::Base::QUERY_STRING && $uri!~/\?/) {
	$uri .= "?$CGI::Base::QUERY_STRING";
    }
    $uri;
}

# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# 1. The first parameter begins with a -
# 2. The use_named_parameters() method returns true
sub rearrange {
    my($self,$order,@param) = @_;
    return ('') x $#$order unless @param;
    return @param unless $param[0]=~/^-/ 
	|| $self->use_named_parameters;

    my $i;
    for ($i=0;$i<@param;$i+=2) {
	$param[$i]=~s/^\-//;     # get rid of initial - if present
	$param[$i]=~tr/a-z/A-Z/; # parameters are upper case
    }
    
    my(%param) = @param;		# convert into associative array
    my(@return_array);
    
    my($key);
    foreach $key (@$order) {
	my($value);
	# this is an awful hack to fix spurious warnings when the
	# -w switch is set.
	if (ref($key) && ref($key) eq 'ARRAY') {
	    foreach (@$key) {
		$value = $param{$_} unless $value;
		delete $param{$_};
	    }
	} else {
	    $value = $param{$key};
	}
	delete $param{$key};
	push(@return_array,$value);
    }

    return (@return_array,$self->make_attributes(%param));
}

sub make_attributes {
    my($self,%att) = @_;
    return () unless %att;
    my(@att);
    foreach (keys %att) {
	push(@att,qq/$_="$att{$_}"/);
    }
    return @att;
}

sub previous_or_default {
    my($self,$name,$defaults) = @_;
    my(%selected);

    if ($self->inited) {
	grep($selected{$_}++,$self->param($name));
    } elsif (defined($defaults) && ref($defaults) && 
	     (ref($defaults) eq 'ARRAY')) {
	grep($selected{$_}++,@{$defaults});
    } else {
	$selected{$defaults}++ if defined($defaults);
    }

    return %selected;
}

sub URL_ENCODED {$URL_ENCODED;}
sub MULTIPART {$MULTIPART;}

$VERSION; # so that require() returns true


