#!/usr/local/bin/perl5.002

# 
# $Log: former.pl,v $
# Revision 1.2  1996/03/27 14:38:57  hickey
# + added server-side include support
# + moved to 0.2 beta
#
# Revision 1.1  1996/03/26 21:59:42  hickey
# Initial revision
#
#
 

$VERSION = '0.2';
$RCSID = '$Id: former.pl,v 1.2 1996/03/27 14:38:57 hickey Exp $';


=head1 NAME

Former - Generic CGI script for processing forms

=head1 SYNOPSIS

http:/cgi-bin/former/forms/form.conf

=head1 DESCRIPTION

Former is a CGI script that is used to produce and process forms
on a WWW server. It has been designed to allow quick and easy 
implementation of forms without the need to rewrite a CGI script
everytime. 

Each form consists of two files: the configuration file and the 
form definition file (FDF). The configuration file holds the basic
state information (i.e. which actions and forms get called in 
what order) and is specified in the URL. The configuration 
file is setup very much like a Windows INI file, and 
is only required to have the [Former] section. A simple
configuration file might be:			       

	[Former]
	
	Form Definition = /www/forms/form.def
	Form = entry
	
	[entry]
	
	Form = reply
	Action = reply

Whenever Former starts up, it must always find the file specified
by the C<Form Definition> in the above. This file is the FDF that
contain the entries for the forms and actions. The FDF file is 
described in the section L<Form Definition File Format>.

After the FDF is read and processed, Former will then determine 
if this is the first time it has executed. If so, it will use
the entries under the [Former] section for processing. If 
Former has executed before, then it will use the name of the 
previous form for the next section that needs to be processed.

In the above example, When Former is first called, it will display
the I<entry> form. In this case, there was no action associated
with the I<entry> form. After the user presses the submit button, 
Former determines that is it had just done the I<entry> form. As 
a result, it begins to process the entries in the [entry] section.
Former always processes the action field first followed by the
form field. In this case, the I<reply> action is performed 
(as it is specified in the FDF), and then the I<reply> form
is sent to the browser. 

In future revisions of Former, the configuration file and FDF
will be the same file. 

=cut


package Former;
  
use Carp;
use Dumper;  
 
# Define field options
$F_required 	= 1;
$F_upcase	= 2;
$F_lowcase	= 4;
$F_blank 	= 8; 


sub new
{
  my ($class, $file, $cgiobj) = @_;
  
  $self = { CGIobj	=>	$cgiobj,
	    Form	=>	{},
  	    Action	=> 	{},
	    Field	=>	{}
	  };

  bless $self, $class;
    
  # die if there is not a form definition
#  croak "Form definition not found: $file" if (! -r $file);
  
  open (DEF, "<$file");
  		     
  while (<DEF>)
  {
    # seperator line?
    next if (/^\s*%%-+%%/);

    # process a form entry 
    /^\s*%%\s*Form:\s*(\w+)\s*%%/oi && do
    {
      $form = $1;   
      undef @sect;
      	      
      do 
      {
	$line = <DEF>;
        push (@sect, $line); 
      } until ($line =~ /^\s*%%\s*Form\s*%%/oi);
      
      $self->{Form}->{$form} = join ('', @sect);
    
    };

    # process an action entry 
    /^\s*%%\s*Action:\s*(\w+)\s*%%/oi && do
    {			  
      $action = $1;	      
      $self->{Action}->{$action} = Former::Action->new;
      
      undef @sect; 
      while ($line !~ /^\s*%%\s*Action\s*%%/i and !eof (DEF)) 
      {			
        $line = <DEF>;

	# did we get a command seperator?
	if ($line =~ /^\s*%\-+%/)
	{
	  $self->{Action}->{$action}->add (join ('', @sect));
	  undef @sect;
	} 
	else
	  { push (@sect, $line) };
      };
    };
    
    /^\s*%%\s*Fields\s*%%/oi && do
    {	       
      while ($line !~ /^\s*%%\s*Fields\s*%%/oi and !eof (DEF))
      {	      
        $line = <DEF>;
        chomp ($line);
        if ($line =~ /^\s*(\w+)\s*:\s*([\w,|\+\-]+)/o)
          { $self->{Field}->{$1} = $self->_process_field_options ($2) };
      };
    };

  };  
  
  $self;
}


=head1 Form Definition File Format

The actual CGI form is defined in the form definition file (FDF). This file
contains three types of sections: L<Form Format>, L<Action Format>, and L<Field Format>. There can be 
multiple form and action sections, but only one field section. Each of the
sections will be described in detail below.

To keep the FDF from getting too cluttered, you can use a seperator line to
keep the sections from getting mixed together. The seperator line looks like:

	%%-----------------------------%%

The number of dashes is trivial; just as long as there is more than 1. This 
line should not be confused with the action seperator line (more later). 

=head1 Form Format

A form section looks like the following:

	%%Form:NAME%%
	
	HTML code and form definitions
	
	%%Form%%
	
The C<NAME> is the symbolic name that this form is known as. It is the same
name that is used in the configuration file to call the form. 

What is included between the two C<%%Form%%> lines is standard HTML. The
only exception is for the form elements. Each type of form element is 
described below. 

=cut
	      

###########################################################################
###     Display form
###########################################################################

sub display_form
{
  my ($self, $name) = @_;
  my $form = $self->{CGIobj};		  

  print $form->header;
  print $form->start_html;		   
  
  print $form->startform ('POST', $form->script_name . $form->path_info);
  print $form->hidden ('FormerStage', $name);
    	   		      				
  # process server-side includes
  $self->{Form}->{$name} =~ s/<--!#exec[^>]+-->/$self->_process_include ($&, $form)/gei;
      			   
  while ($self->{Form}->{$name} =~ /%%\s*([^%][^%]+)\s*%%/o)
  {
    # get the next field and print what is before it
    $field = $1;
    print $`;
    $self->{Form}->{$name} = $';
    	 
    			 
=head2 Text Entry

=item + Text

	%%Text:NAME:SIZE,MAXLENGTH%%

The generic text entry box is created with the Text definition. This
creates a text entry that is associated with C<NAME>. The C<SIZE> and
C<MAXLENGTH> are optional and need not be specified. If C<SIZE> and 
C<MAXLENGTH> are not specifed, then the final colon does not need to
exist. 
		       
=back
=cut

    # parse the field portion
    $field =~ /^Text:(\w+):?(\w*),?(\w*)/io && do 
    { 
      print $form->textfield (
		-name 		=>	$1, 
       		-default	=>	$form->param ($1) || undef, 
       		-size		=>	$2,
       		-maxlength	=>	$3 );
    };  

=item + Textarea

	%%Textarea:NAME:ROWS,COLS%%

The Textarea definition creates a multi-row text entry box. C<ROWS> and 
C<COLS> are mandatory for Textarea. This release does not support any 
default values for the Textarea definition. 

=back
=cut
  
    $field =~ /^Textarea:(\w+):(\w*),?(\w*)/io && do 
    { 
      print $form->textarea (
		-name 		=>	$1, 
       		-default	=>	$form->param ($1) || undef, 
       		-rows		=>	$2,
       		-columns	=>	$3 );
    };  

=item + Password

	%%Password:NAME:SIZE,MAXLENGTH%%

The Password definition is exactly the same as the Text definition. Using
the Password definition allows text to be entered, but not seen in the 
text field.

=back
=cut
  
    $field =~ /^Password:(\w+):?(\w*),?(\w*)/io && do 
    { 
      print $form->password_field (
		-name 		=>	$1, 
       		-default	=>	$form->param ($1) || undef, 
       		-size		=>	$2,
       		-maxlength	=>	$3 );
    };  
	  
=head2 Lists, Checkboxes, Menus, and Radio Buttons

The basic form for all these definitions is

	%%TYPE:NAME:OPTIONS
	{val1}label1
	{val2}label2
	{val3}label3
	%%

The C<TYPE> field must be one of I<Popup>, I<List>, I<Checkbox>, or I<Radio>.
C<NAME> is the name of the field on the form. C<OPTIONS> is specific for each
field type, and should conform to the specifications below. If there are not
any options specified, the colon between C<NAME> and C<OPTIONS> can be 
omitted.

The value-label pairs are as they are shown above. The values are always 
surrounded by curly braces ({}) --even when used in the C<OPTIONS> field--
followed by the label that should be associated with the value. 

=item + Popup

This type produces a popup menu on the HTML form. C<OPTIONS> in this case
specify the default label to show when the form is displayed. The value for
the the default label must be surrounded by curly braces ({}).

=back
=cut

    $field =~ /^Popup:(\w+):?(.*)/io && do
    { 
      my ($default, $vals, $labs);
      	       
      # store default values first.
      $default = $2;
      ($vals, $labs) = $self->_split_list ($');
      $default =~ s/\{(.+)\}/$1/;
    			     
      print $form->popup_menu (
      		-name 		=>	$1,
       		-default	=>	$default || $form->param ($1) || undef, 
		-values		=>	$vals,
		-labels		=>	$labs );
    };

=item + List

The List type will produce a scrolling listbox. The C<OPTIONS> parameter
is specified as: 

	{VAL}SHOW MULTIPLE

The C<VAL> is optional and should contain the default value for the list.
If a default value is not being specified, the curly braces ({}) should not
be supplied. Multiple default values can be specified one after another;
each value must be delimited by curly braces. C<SHOW> allows the number
of entries to be shown to be specified. If C<MULTIPLE> is specified, 
then the resulting scrolling list will allow multiple selections. The 
C<MULTIPLE> field is specified by using the word "mult" (case insensitive)
after the C<SHOW> paremeter.

=back
=cut

    $field =~ /^List:(\w+):?(.*)/io && do
    {	
      my ($default, $vals, $labs, $options);
      my ($multiple, $show);
      
      # process the options
      $options = $2;	   
      ($vals, $labs) = $self->_split_list ($');
      
      # default selections
      while ($options =~ /\{([^{]+)\}/go)
        { push (@$default, $1) };
      $options =~ s/\{.*\}//g;

      # multiple?
      $multiple = ($options =~ /\s*mult\s*/io);
      $options =~ s/\s*mult\s*//gi;
      
      # number to show should be all that is left.
      $show = $options;
      
      print $form->scrolling_list (
      		-name 		=>	$1,
       		-default	=>	$default || $form->param ($1) || undef, 
		-size		=>	$show,
		-multiple	=>	$multiple,
		-values		=>	$vals,
		-labels		=>	$labs );
    };

=item + Checkbox

This is used to create a single checkbox or a group of checkboxes that 
correspond to a single field for the displayed form. The C<OPTIONS>
parameter is specified as:

	{VAL}COLS,ROWS BREAK

The default values are specified the same way as L<List> default values. 
The C<ROWS> and C<COLS> are for HTML3 browsers, but are most of the time
ignored on older browsers. The C<BREAK> parameter is used to place line
breaks between each checkbox. It is enabled by using the word "break"
(case insensitive) after the rows and columns parameters.

=back
=cut
    
    $field =~ /^Checkbox:(\w+):?(.*)/io && do
    {			       	      
      my ($default, $vals, $labs, $options);
      my ($rows, $cols, $break);

      # process the options
      $options = $2;	   
      ($vals, $labs) = $self->_split_list ($');
      
      # default selections
      while ($options =~ /\{([^{]+)\}/g)
        { push (@$default, $1) };
      $options =~ s/\{.*\}//g;

      # break?
      $break = ($options =~ /\s*break\s*/i);
      $options =~ s/\s*break\s*//gi;
      
      # process any row/col info
      if ($options =~ /,/)
        { ($cols, $rows) = split (/,/, $options) }
       else
        { $cols = $options if ($options > 0) };
      
      print $form->checkbox_group (
      		-name 		=>	$1,
       		-default	=>	$default || $form->param ($1) || undef, 
		-rows		=>	$rows,
		-columns	=>	$cols,
		-linebreak	=>	$break,
		-values		=>	$vals,
		-labels		=>	$labs );
    };

=item + Radio

The radio button specification is exactly like that of the checkbox specification.
The C<OPTIONS> parameter is specified in the same manner.

=back
=cut

    $field =~ /^Radio:(\w+):?(.*)/io && do
    {			       	      
      my ($default, $vals, $labs, $options);
      my ($rows, $cols, $break);

      # process the options
      $options = $2;	   
      ($vals, $labs) = $self->_split_list ($');
      
      # default selections
      while ($options =~ /\{([^{]+)\}/g)
        { push (@$default, $1) };
      $options =~ s/\{.*\}//g;

      # break?
      $break = ($options =~ /\s*break\s*/i);
      $options =~ s/\s*break\s*//gi;
      
      # process any row/col info
      if ($options =~ /,/)
        { ($cols, $rows) = split (/,/, $options) }
       else
        { $cols = $options if ($options > 0) };
      
      print $form->radio_group (
      		-name 		=>	$1,
       		-default	=>	$default || $form->param ($1) || undef, 
		-rows		=>	$rows,
		-columns	=>	$cols,
		-linebreak	=>	$break,
		-values		=>	$vals,
		-labels		=>	$labs );
    };
    
=head2 Action Buttons

The action buttons allow you to specify the submit and reset buttons for 
a form. The action buttons take two forms: submit and reset. The submit
button sends the information entered into the form to the server to be 
processed by a CGI script. The reset button causes the form to be 
reloaded with the values it had before any changes were made.

=item + Submit

This action produces the submit button, and places C<TEXT> as the 
description on the button. The submit definition is as follows:

	%%Submit:NAME:TEXT%%

The C<NAME> is used to allow multiple submit buttons on the same
form. C<TEXT> allows the button to be titled with the specified
text. If C<TEXT> is not specified, then the colon can be omitted
and the C<NAME> will be used to title the button. 

=back
=cut

    $field =~ /^Submit:(\w+):?(.*)/io && do 
    { 
      print $form->submit (
		-name 		=>	$1, 
       		-value		=>	$2 );
    };  

=item + Reset
			 
	%%Reset:TEXT%%

Create the reset button. Use C<TEXT> as the decription on the 
button.

=back
=cut
  
    $field =~ /^Reset:?(.*)/io && do 
    { 			    
      if ($1)
        { print $form->defaults ($1) }
       else
        { print $form->reset };
    };  

=head2 Miscellaneous 

=item + Hidden

	%%Hidden:NAME:VALUE%%

The hidden definition allows additional information to be include into
the form. C<NAME> is how the information will be accessed from the
CGI script. C<VALUE> if defined will be what the value is set to 
no matter what the value currently is.

=back
=cut
  
    $field =~ /^Hidden:(\w+):?(.*)/io && do 
    {  
      
      print $form->hidden (
		-name		=>	$1,
		-default	=>	$2 || $form->param ($1) );
    };  
  
  };
  
  # print the remainder of the form
  print $self->{Form}->{$name};
  
  print $form->endform;
  print $form->end_html;
}


sub perform_action
{
  my ($self, $name) = @_;
  my ($curr_form);

  foreach $obj (@{$self->{Action}->{$name}})
  {
    $curr_form = $obj->doit ($self->{CGIobj}) || $curr_form;
  };		 
  
  $curr_form;
}  
 

=head1 Field Format

B<Fields are not fully implemented in this release.>

The Field section allows attributes to be set to a particular field
in a form. Below is a list of currently implemented field attributes:

=over 8
=item + Required

Does not allow a form to proceed until the field has an entry.

=item + Upcase

Converts the contents of the field to uppercase.

=item + Lowcase

Converts the contents of the field to lowercase.

=item + Blank

Undefined at this time. 
=back

The Field section looks like:


	%%Fields%%
	
	FIELD:ATTR
	FIELD:ATTR ATTR
	FIELD:ATTR,ATTR
	
	%%Fields%%


C<FIELD> is the name of the field to associate C<ATTR> with. Multiple
C<ATTR>s can be seperated by anything (space, comma, colon, flat colon,
etc.).

=cut

    
sub process_fields
{
  my ($self, $form) = @_;
  my (@fields, $field);
  
  # This is the first invokation of former
  return if (! $form->param ('FormerStage'));
    
  @fields = $form->param;
  foreach $field (@fields)
  {			      
    # Field was never defined.
    next if (! exists $self->{Field}->{$field});
    
    print %{$self->{Field}},"\n";		    
    if (($self->{Field}->{$field} & $F_required) and ! $form->param ($field))
    {
      $self->display_form ($form->param ('FormerStage'));
      exit;
    };
 
    if ($self->{Field}->{$field} & $F_upcase)
      { $form->param ($field, uc ($form->param ($field))) };

    if ($self->{Field}->{$field} & $F_lowcase)
      { $form->param ($field, lc ($form->param ($field))) };
    
    if ($self->{Field}->{$field} & $F_blank)
    {
    
    
    };
    
    
       
  };
    
}


# 
# private methods
#

sub _process_field_options
{
  my ($self, $options) = @_;
  my $opt = 0;
  			
  $opt |= $F_required if ($options =~ /req/i);
  $opt |= $F_upcase if ($options =~ /upc/i);
  $opt |= $F_lowcase if ($options =~ /low?c/i);
  					  
  return ($opt);
}   

				       
sub process_include
{
  my ($self, $include, $form) = @_;
  my ($cmd, $html);

  ($cmd) = ($include =~ m/cmd="(.+)"/io);
  
  # Execute the given command. 
  open (INCLUDE, "$cmd |");
  $html = join ('', <INCLUDE>);
  close (INCLUDE);
  
  return ($html);
}


			  
sub _split_list
{
  my ($self, $list) = @_;
  my (@values, %labels);
  
  foreach $datum (split (/\n/, $list))
  {
    if (($datum =~ /\{(.+)\}(.*)/) != 0)	
    {
      push (@values, $1);
      $labels{$1} = $2;
    };
  }      
  	   
  return (\@values, \%labels);
}
  
  


package Former::Action;

				  
=head1 Action Format

The action format section specifies how what actions are to be performed
when a form has been submitted. Each action can consist of a number of 
commands (command sets). Below is an example of an action section.

	%%Action: NAME%%

	COMMAND ARGS
	%----%
	COMMAND
	%----%
	COMMAND ARGS
	  DATA
	%----%
		
	%%Action%%

Action sections start with the C<%%Action:NAME%%> line. The C<NAME> 
specify a title for this action. C<NAME> is how this action is
refered to in the configuration file. 

Each command is seperated by a command seperation line (C<%---%>). This 
line should not be confused with the general seperator line that have 
two percent marks (%) at each end. As with the general seperator line,
the number of dashes does not matter, as long as there is one or more. 

When the command has a data area (such as the Mailto action), the 
fields in the CGI form can be substituted into the data area. The
fields must be delimited with two percent marks on either side of 
the field name. The substitution begins and ends with the percent
marks, so the field can be embedded into the data area with no
disruptive effects.

The entire definition is complete when the C<%%Action%%> line is given. 

Below are the supported commands in this revision of Former.

=cut


sub new
{
  my ($class) = @_;

  $self = [];
   
  bless $self, $class;
}

       
sub add
{
  my ($self, $action) = @_;
  my ($obj);

  # remove any whitespace (\n) at the front of the action.
  $action =~ s/^\s*//;
      
  if ($action =~ /^mailto:/i)
    { $obj = Former::Action::Mailto->new ($action) }
  elsif ($action =~ /^sendback:/i)
    { $obj = Former::Action::Sendback->new ($action) }
  elsif ($action =~ /^store:/i)
    { $obj = Former::Action::Store->new ($action) };    
    
  push (@$self, $obj);
}

	 
sub subst_form 
{
  my ($self, $text, $form) = @_;
  my (%fields, $f);
  
  # convert form variables to an assoc. array
  foreach $f ($form->param)
    { $fields{$f} = $form->param ($f) };
  		 
  $self->subst_fields ($text, %fields);
}


sub subst_fields
{
  my ($self, $text, %fields) = @_;
  
  $text =~ s/%%([^%]+)%%/$fields{$1}/ge;
  $text;
}		    


sub return_code
{
  my ($self, %args) = @_;

    
}


package Former::Action::Mailto;
@ISA = qw(Former::Action);

use Mail::Send;
	 
=head2 Mailto

The Mailto action allows an email message to be generated. The format is 
very simple and straight forward. The format is as follows:

	Mailto: EMAIL
	RFC822 HEADERS
	
	BODY OF MESSAGE
	%---%

C<EMAIL> specifies a list of email address (seperated by commas) to send
the message. The next couple of lines consist of standard RFC822 headers.
The most common headers that will be used will consist of:

	Subject: SUBJECT
	From: EMAIL
	Return-Receipt-To: EMAIL
	Cc: EMAIL
	Bcc: EMAIL

After the headers there must be at least one blank line to seperate the 
headers from the body of the message. You may include CGI fields in the 
body of the message. 

=cut


sub new
{
  my ($class, $mesg) = @_;
      		   
  bless \$mesg, $class;
}


  
sub doit
{
  my ($self, $form) = @_;
  my ($h, @headers, $msg, $body, %fields);
  my $mail = new Mail::Send;
  
  # process header lines
  $$self =~ /\n\s*\n/;
  $body = $';
  @headers = split (/\n/, $`);
   foreach $h (@headers)
   {		    
     if ($h =~ /^mailto\s*:\s*(.+)/i)
       { $mail->to ($1); next }
     elsif ($h =~ /^subject\s*:\s*(.+)/i)
       { $mail->subject ($1); next }
     elsif ($h =~ /^cc\s*:\s*(.+)/i)
       { $mail->cc ($1); next }
     elsif ($h =~ /bcc\s*:\s*(.+)/i)
       { $mail->bcc ($1); next }
     else
     {
       $h =~ /^(.+)\s*:\s*(.+)/;
       $mail->add ($1, $2);
     };
   };
			
  # now process the body       	       
  $body = $self->subst_form ($body, $form);
    
  $msg = $mail->open;
  print $msg $body;
  $msg->close;
}



package Former::Action::Sendback;
@ISA = qw(Former::Action);

=head2 Sendback

This command will simply provide a way to specify which form
to send back to the browser. It is simply invoked by saying:

	Sendback: FORM

Where C<FORM> is the symbolic name of the form desired to
be sent. 

=cut


sub new					 
{
  my ($class, $command) = @_;
  
  $command =~ s/^\s*Sendback:\s*(\w+)\s*/$1/i;
  bless \$command, $class;
}


sub doit 
{
  my ($self, $form) = @_;
  
  return $$self;
}


package Former::Action::Store;
@ISA = qw(Former::Action);

=head2 Store

The C<Store> action will allow the data that has been collected
to be placed in a database or a file. The format for this group
of commands is as follows:

	Store:TYPE:ARGS
	
	Text/data to store
	
	%------------%

C<TYPE> is one of the following types. C<ARGS> are the arguments
that the C<TYPE> needs to have specified. 

=cut


sub new 
{
  my ($class, $data) = @_;
  
  if ($data =~ /^store:file:/i)
    { return (Former::Action::Store::File->new ($data)) }
  elsif ($data =~ /^store:msql:/i )
    { return (Former::Action::Store::Msql->new ($data)) };
    
}



  
package Former::Action::Store::File;
@ISA = qw(Former::Action::Store Former::Action);

#use File::Lock;

=item + Store:File

This module will append the text to a specified file. At this
time, there is no file locking capabilities on the file being
written. 

=back
=cut

 
sub new 
{
  my ($class, $data) = @_;
  
  $data =~ s/^store:file://i;
  
  bless \$data, $class;
}		       


sub doit
{
  my ($self, $form) = @_;
  my ($data, @lines, $file);
  
  # now process the text
  $data = $self->subst_form ($$self, $form);
  		    
  @lines = split (/\n/, $data);
  $file = shift @lines;
  open (FILE, ">>$file");
  print FILE @lines;
  close (FILE);
}




package Former::Action::Store::Msql;
@ISA = qw(Former::Action::Store Former::Action);

use Msql;
    
=item + Store:Msql

The module will allow access to a mSQL database. When using this
command, the following structure must be used:

	Store:Msql:HOST,DATABASE
	SQL statement
	%-----%

C<HOST> is the hostname of the machine which has the database 
server running. C<DATABASE> is the SQL database name that the 
SQL statement should be preformed on. The data portion of 
the command (SQL statement) is a valid SQL statement that will
be sent to the mSQL server after the field substitution has 
occured.

=back
=cut

sub new 
{
  my ($class, $data) = @_;
  	    
  $data =~ /^store:msql:([^,]+),(.+)\n/i;
  if (defined $2)
    { $host = $1; $database = $2 }
   else
    { $host = 'localhost'; $database = $2 };
  ($query = $data) =~ s/^store:.+\n//i;
  							
  $dbh = Connect Msql $host, $database;
  $self = { DB		=> $dbh,
  	    Query	=> $query 
	  };
	  
  bless $self, $class;
}


sub doit
{
  my ($self, $form) = @_;
  my ($query);
  
  # now process the query
  $query = $self->subst_form ($self->{Query}, $form);       	       
  					      
  $self->{DB}->Query ($query);
  
  return;
}
  





package main;
		     
		     
use CGI;  
use ConfigFile;
#use Dumper;

$form = new CGI;

# load the configuration file
$config = new ConfigFile $form->path_info;

# read the form definition file			     
$fdf = new Former $config->Parameter ('Former', 'Form Definition'), $form;
	       
# process the fields to ensure that they fit with the options
# $fdf->process_fields ($form); 
								
# first we perform the action, then send the next form.
$action = $config->Parameter ($form->param ('FormerStage') || 'Former', 'Action');
if ($action)
  { $nextform = $fdf->perform_action ($action) };
  
$fdf->display_form ($nextform || $config->Parameter ($form->param ('FormerStage') || 'Former', 'Form'));

# we are now done, so exit!
exit;


