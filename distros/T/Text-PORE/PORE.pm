package Text::PORE;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Carp;
use Text::PORE::Globals;

@Text::PORE::ISA = qw(Exporter);

$Text::PORE::VERSION = '1.02';


##########################################
# render($object, $template, $file_handle)
##########################################
sub render($$$) {
	my ($obj, $tpl, $target) = @_;
	my @errors = ();
	if (ref($obj) ne 'Text::PORE::Object') {
		push (@errors, "The first parameter must be type of Text::PORE::Object.");
	}
	if (ref($tpl) ne 'Text::PORE::Template') {
		push (@errors, "The second parameter must be type of Text::PORE::Template.");
	}
	if (ref($target) ne 'FileHandle') {
		push (@errors, "The third parameter must be type of FileHandle.");
	}
	
	if ($#errors >=0) {
		my $error;
		foreach $error (@errors) {
			carp("$error");
		}
		return -1;
	} else {
		$tpl->render($obj, $target);
	}
}

##########################################
# setTemplateRootDir($templateRoot)
##########################################
sub setTemplateRootDir($) {
	my ($templateRootDir) = shift;
	Text::PORE::Globals::setTemplateRootDir($templateRootDir);
}


1;
__END__

=head1 NAME

Text::PORE - Perl Object Rendering Engine

=over 4

=item pore 

intr.v.

1. To read or study carefully and attentively

The American Heritage® Dictionary of the English Language, Fourth Edition

=back

=head1 SYNOPSIS

How to use PORE to render Perl objects.

	use Text::PORE::Template;
	use Text::PORE::Object;

The Perl object to be rendered:

	$obj = new Text::PORE::Object('name'=>'Joe Smith');
	@chilren = (
		new Text::PORE::Object('name'=>'John Smith', 'age'=>10, 'gender'=>'M'),
		new Text::PORE::Object('name'=>'Jack Smith', 'age'=>15, 'gender'=>'M'),
		new Text::PORE::Object('name'=>'Joan Smith', 'age'=>20, 'gender'=>'F'),
		new Text::PORE::Object('name'=>'Jim Smith', 'age'=>25, 'gender'=>'M'),
	);
	$obj->{'children'} = \@chilren;

The template file (demo.tpl):

	Name: <PORE.render attr=name>
	Children:
	<PORE.list attr=children>
		<PORE.render attr=name>, <PORE.render attr=age>, <PORE.if 
		cond="gender EQ 'M'">Male<PORE.else>Female</PORE.if>
	</PORE.list>

The code that renders the object using this template:

	#
	# create a template
	#
	$tpl = new Text::PORE::Template('file'=>'demo.tpl');
	
	#
	# render the object using the template
	# the result is printed to STDOUT
	#
	my $fh = new FileHandle();
	$fh->open('>& STDOUT');
	Text::PORE::render($obj, $tpl, $fh);
	$fh->close();

The rendering result:

	Name: Joe Smith
	Children:
	
	        John Smith, 10, Male
	
	        Jack Smith, 15, Male
	
	        Joan Smith, 20, Female
	
	        Jim Smith, 25, Male



=head1 ABSTRACT

PORE is a general-purpose template-based object rendering engine. It is intended for producing dynamic
content by rending Perl objects with templates. The template language consists a set of XML tags. The 
template parser is built using byacc. PORE is light and fast. 

=head1 DESCRIPTION

Parallel to the idea of JSP and PHP, PORE was designed to separate data from presentation. 
The data is encapsulated in Perl objects, like Java Beans. The presentation is represented by 
PORE::Template, like JSP files. PORE consists of a templating language that is a set of XML tags 
and a rendering engine that parses templates and generates output using specified Perl objects. 
PORE is suitable for any environment where dynamic content needs to be produced based on Perl objects. 
For instance, it can be used for developing CGI programs, where Perl developers can concentrate on 
writing business logics and data retrieval, while content developers can focus on producing presentation 
layout.

The process of rendering a Perl object involves three steps. 

=head2 Step 1: Create a Perl object using PORE::Object

PORE::Object is essentially a collection of attribute name and value pairs. An attribute value can contain
other PORE::Objects. The example below shows how to create a PORE::Object with three attributes:
username, password and email_address.

	$obj = new Text::PORE::Object(
	'username'=>'ztang', 
	'password'=>'123abc', 
	'email_address'=>'ztang@cpan.org');

Detail information about how to use PORE::Object can be accessed in POD of Text::PORE::Object.

=head2 Step 2: Create a template, a PORE::Template object

To instantiate a PORE::Template object, a filename or a file id must be given.  
This file is text file that contains a set XML tags that can direct the rendering engine to access
attributes of PORE::Objects and to process attributes in certain logical ways. 
There are four basic template directives: 
a render directive (C<<PORE.render>> tag), a list directive (C<<PORE.list>> tag), 
a context directive (C<<PORE.context>> tag), and a condition directive (C<<PORE.cond>> tag).

The example below is a template file called show_user.tpl.

	Username: <PORE.render attr="username">
	Password: <PORE.render attr="password">
	Email Address: <PORE.render attr="email_address">

Here is how to create a PORE::Template object using the template file above.

	$tpl = new Text::PORE::Template('file'=>'show_user.tpl');

For detail information about template directives, please see "TEMPLATE DIRECTIVES" section.

=head2 Step 3: Render the object using the template

PORE has a template parser (or a render engine) that parses the template and replaces template directives
with attribute values of the given PORE::Object. The parser is generated using byacc (Berkeley Yacc),
which is an LALR(1) parser generator. 

To render an object using a template, simply call C<PORE::render($object, $template, $file_handle)>.
The render function takes three arguments: the object to be rendered, a template, and a FileHandle.
The following example shows how to render the object created in step 1 by using the template created
in step 2. The output is C<STDOUT>.

	my $fh = new FileHandle();
	$fh->open('>& STDOUT');
	Text::PORE::render($obj, $tpl, $fh);
	$fh->close();

=head1 CREATING PERL OBJECTS -- PORE::Object

PORE::Object is the superclass of all renderable objects. That is, if you want to render an object, the
object must be an instance of PORE::Object or an instance of its subclass.

The purpose of this class is to provide methods to create and access attributes. Commonly used methods
are C<new> and C<setAttributes()>.

Here are some examples.

	$age = 50;

	$obj = new Text::PORE::Object();
	$obj->setAttribute('name'=>'Joe Smith');
	$obj->setAttribute('age'=>$age);

	$obj = new Text::PORE::Object();
	$obj->setAttributes('name'=>'Joe Smith', 'age'=>$age);

	$obj = new Text::PORE::Object('name'=>'Joe Smith', 'age'=>$age);

	$employer = new Text::PORE::Object('name'=>'Perl.com');
	$obj->setAttribute('employer'=>$employer);

=over 4

=back

For details of how to use PORE::Object, please see its POD.

=head1 CREATING TEMPLATES -- PORE::Template

PORE::Template represents the handle for PORE templates. To instantiate a PORE::Template object,
either a filename of the template or the a template id is required. The instance is then passed to
C<PORE::render()> during the rendering process.

Here are some examples.

	$tpl = new Text::PORE::Template('file'=>'demo.tpl');

	$tpl = new Text::PORE::Template('id'=>'demo');

For details of how to use PORE::Template, please see its POD.
 

=head1 TEMPLATE DIRECTIVES

PORE template directives add the ability to display objects in various ways in a template. 
PORE directives always operate on the current context object. The context object is initially the object 
that the template is applied to, but it can be changed by certain directives. PORE directives have the 
functionality to

	1) display an attribute of the context object,
	2) set the new context object to an attribute of the current context object,
	3) for an attribute of the context object that is a list, loop over all the elements in the list, 
	4) evaluate conditions and base output on the value of a condition.

The following sections will describe these directives individually and give examples.

=head2 Render Directive

The syntax of the render directive is: C<<PORE.render attr="ATTBRIBUTE_NAME">>

The RENDER tag retrieves the attribute ATTRIBUTE_NAME of the context object and renders it. 
The RENDER tag is replaced by the value of the attribute ATTRIBUTE_NAME.

For example, let us say we are applying a template to a Person object whose name is Joe Smith. 

Our template contains the following:

	Name: <PORE.render attr=name>

The template parser would parse this line and output:

	Name: Joe Smith

=head2 Context Directive 

The syntax of the render directive is: C<<PORE.context attr="ATTRIBUTE_NAME">> ... C<</PORE.CONTEXT>>

The CONTEXT tag switches the context object from the current context object to the attribute of the 
current context object given in ATTRIBUTE_NAME. The changed context is in effect for the scope of 
the text enclosed between the open and close tags. 
All attributes referred to in this body refer to the new context object. 
After the CONTEXT tag is closed, the original context object is restored. For example, Joe Smith's age
is 50 and his employer is Perl.com.

Our template contains the following:

	Name: <PORE.render attr=name>
	<PORE.context attr=employer>
	Employer Name: <PORE.render attr=name>
	Employer URL: <PORE.render attr=url>
	</PORE.context>
	Age: <PORE.render attr=age>

The first render tag refers to the name attribute of the Joe Smith object. 
The context tag then switches the context object to the object referenced by the employer attribute. 
Since the second render tag is enclosed within the context tag body, the name attribute now refers 
to the employer object. After the context tag is closed, the context object is restored to 
the Joe Smith object.

The following is the output:

	Name: Joe Smith
	
	Employer Name: Perl.com
	Employer URL: http://www.perl.com

	Age: 50

Because a new context object must always be an attribute of the previous context object, 
the template system can only access the object to which it is originally applied and 
objects somehow related to that original object. If one wishes to render more than one disparate objects 
using the template system, one can create an object whose purpose is to unify these objects.

=head2 List Directive 

The syntax of the list directive is: C<<PORE.LIST ATTR="ATTRIBUTE_NAME">> ... C<</PORE.LIST>>

The LIST tag retrieves from the object the attribute ATTRIBUTE_NAME, which is a list of objects. 
It loops through the objects in the list, and for each it sets the object to be the context object 
and then operates on the text within that context. So, the text is processed by the template parser 
n times, where n is the length of the list of objects. If ATTRIBUTE_NAME is not a list, 
the template parser returns an error. For example, Joe Smith has four children.

Our template contains the following:

	Name: <PORE.render attr=name>
	Children:
	<PORE.list attr=children>
		<PORE.render attr=name>, <PORE.render attr=age>
	</PORE.list>

Here is the output:

	Name: Joe Smith
	Children:
	
	        John Smith, 10, Male
	
	        Jack Smith, 15, Male
	
	        Joan Smith, 20, Female
	
	        Jim Smith, 25, Male

=head2 Condition Directive 

The syntax of the condition directive is:

	<PORE.IF COND=expr> ...true text... </PORE.IF>
	<PORE.IF COND=expr> ...true text... <PORE.ElSE> ...false text... </PORE.IF>

The IF tag allows the template to output different text depending on the boolean value of 
the expression expr. If expr evaluates to a true value, only true text is output, otherwise false text 
is output.

Expressions have their own special syntax similar to that of the C language. 
The only place expressions occur is in the IF COND parameter. 
An expression is a quote-delimited string consisting of operators and operands.

=head3 Operands

There are two types of operands, attributes and literals. Attributes refer to the attributes of the 
context object, and are used as we have been using them in our previous examples. 
Literals are constant values are always delimited by quotes. All literals are treated as strings, 
whether they consist of numbers, letters, or any other type of character. 

Here are some attributes:

	name
	age

Here are some literals:

	"Joe Smith"
	'50'
	""

The last literal, the empty string, has a boolean value of FALSE. Every other string has a TRUE value.

In HTML, parameter values need to be surrounded by quotes if they contain non-alphabetic characters, 
which is certainly a characteristic of expressions. However, we also need to use quotes within the 
expression to distinguish literals. This gives us the problem of nested quotes. 
The solution is to use a different style of quotes for the entire expression and for literals. 
Which style is used for which is not important.

=head3 Operators

The PORE expression syntax contains most of the standard operators:

	+ - * /:         Arithmetic operators
	= != > < >= <=:  Numeric comparison operators
	EQ EQS:          String comparison operators
	AND OR NOT:      Boolean operators
	( ):             Grouping operators

Since the expression language has no way of distinguishing type, 
(values of attributes and literals are strings), it is the operators themselves that determine 
how they will be treated. Arithmetic operators and numeric comparison operators convert their operands to 
numbers and then act on them. The C<!=> is the inequality operator. The C<=> is the equality operator, 
not the assignment operator. Otherwise, numeric operators behave exactly as they do in C. 
Here are a few examples:

	gross - net > "3000"
	percent * "100" != "50"

The string operators C<EQ> and C<EQS> treat their operands as strings. C<EQ> tests if two strings are equal 
disregarding case whereas C<EQS> tests if two strings are exactly equal (the S stands for "sensitive"). 
C<EQS> is distinct from C<=> in that C<=> only evaluates whether its operands are equal numerically, 
whether or not the actual string values differ; thus "10" and "10.00" are C<=> but not C<EQ>.

C<AND>, C<OR>, and C<NOT> behave like the standard boolean operators. Parentheses group expressions as they do in C.

=head3 Examples

Using the Joe Smith object, our template contains: 

	Testing: +, -, *, /, <, >, <=, >=, =, !=
	    Age: <PORE.render attr="age">
	=============================
	<PORE.if cond="age < '60'">Younger than 60</PORE.if>
	<PORE.if cond="age + '10' > '60'">Older than 50<PORE.else>10 years later not old than 60</PORE.if>
	<PORE.if cond="age - '10' <= '40'">10 years ago younger or same as 40</PORE.if>
	<PORE.if cond="age * '2' >= '100'">Twice the age is older or same as 100</PORE.if>
	<PORE.if cond="age / '2' = '25'">Half the age equals to 25</PORE.if>
	<PORE.if cond="age != '51'">Not equals to 51</PORE.if>
	
	Testing: eq, eqs
	    Name: <PORE.render attr="name">
	===============================
	<PORE.if cond="name eqs 'Joe Smith'">Name is Joe Smith.</PORE.if>
	<PORE.if cond="name eqs 'joe smith'">Name is joe smith.<PORE.else>Name is not joe smith.</PORE.if>
	<PORE.if cond="name eq 'joe smith'">If case insensitive, name is same as joe smith.</PORE.if>
	
	Testing: and, or, not, (, )
	    Age: <PORE.render attr="age">
	    Name: <PORE.render attr="name">
	===============================
	<PORE.if cond="(name eqs 'Joe Smith') and (age < '60')">Name is Joe Smith and younger than 60.</PORE.if>
	<PORE.if cond="(name eqs 'Joe Smith') or (age > '60')">Name is Joe Smith or older than 60.</PORE.if>
	<PORE.if cond="(name eqs 'John Doe') or (age < '60')">Name is Johe Doe or younger than 60.</PORE.if>
	<PORE.if cond="NOT(name eqs 'John Doe') and  NOT(age > '60')">Name is not Johe Doe and not older than 60.</PORE.if>

The output:

	Testing: +, -, *, /, <, >, <=, >=, =, !=
	    Age: 50
	=============================
	Younger than 60
	10 years later not old than 60
	10 years ago younger or same as 40
	Twice the age is older or same as 100
	Half the age equals to 25
	Not equals to 51
	
	Testing: eq, eqs
	    Name: Joe Smith
	===============================
	Name is Joe Smith.
	Name is not joe smith.
	If case insensitive, name is same as joe smith.
	
	Testing: and, or, not, (, )
	    Age: 50
	    Name: Joe Smith
	===============================
	Name is Joe Smith and younger than 60.
	Name is Joe Smith or older than 60.
	Name is Johe Doe or younger than 60.
	Name is not Johe Doe and not older than 60.

=head1 METHODS

=over 4

=item render()

Usage:

	Text::PORE::render($object, $template, $file_handle);

This method takes three arguments. The first one must be a PORE::Object. 
The second one must be a PORE::Template. And the third one must be a FileHandle.
The method renders the object using the template. The output is specified by the file handle.

The following example renders C<$obj> using C<$tpl>. The output is C<STDOUT>.

	my $fh = new FileHandle();
	$fh->open('>& STDOUT');
	Text::PORE::render($obj, $tpl, $fh);
	$fh->close();

=item setTemplateRootDir()

Usage:

	Text::PORE::setTemplateRootDir($templateRootDir);

This method sets the template root directory. This directory is needed when 
C<new Text::PORE::Template('id'=>>C<$template_id)> is called.

For details of how to create PORE::Template, please see POD of PORE::Template.

=back

=head1 THE PARSER

The parser of PORE (PORE::Parser) is generated using byacc (Berkeley Yacc), version 1.8.2. 

=head1 SEE ALSO

perl(1), perlre(1), byacc(1)

=head1 AUTHOR

Zhengrong Tang, ztang@cpan.org

=head1 HISTORY and CREDITS

PORE was original developed in early 1997 by Zhengrong Tang, Keith Arner and Serene Taleb-Agha.

=head1 COPYRIGHT

Copyright 2004 by Zhengrong Tang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
