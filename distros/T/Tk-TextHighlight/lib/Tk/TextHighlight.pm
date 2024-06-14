=head1 NAME

Tk::TextHighlight - a TextUndo/SuperText widget with syntax highlighting capabilities, can also use Kate languages.

Tk::ROTextHighlight - a Read-only version of this widget.

=head1 SYNOPSIS

=over 4

 use Tk;
 my $haveKateInstalled = 0;
 eval "use Syntax::Highlight::Engine::Kate; \$haveKateInstalled = 1; 1";

 require Tk::TextHighlight;

 my $m = new MainWindow;

 my $e = $m->Scrolled("TextHighlight",
    -syntax => "Perl",
    -scrollbars => "se",
 )->pack(-expand => 1, -fill => "both");

 if ($haveKateInstalled) {
  my ($sections, $kateExtensions) = $e->fetchKateInfo;
  $e->addKate2ViewMenu($sections);
 }
 $m->configure(-menu => $e->menu);
 $m->MainLoop;

=back

=head1 DESCRIPTION

Tk::TextHighlight inherits Tk::TextUndo and all its options and methods.  
Besides syntax highlighting, methods are provided for commenting and 
uncommenting as well as indenting and unindenting a selected area, matching 
pairs of braces, brackets and brackets and curlies and automatic indenting of 
new lines.  The included companion module B<Tk::ROTextHighlight> provides all 
the same functionality in a "readonly" widget for text viewers, etc.  
B<Tk::TextHighlight> also supports highlighting of all the lauguages of the 
B<Syntax::Highlight::Engine::Kate>, if that module is installed.

If you want your widget to be read-only, then B<require Tk::ROTextHighlight>, 
which is based on B<Tk::ROText> instead of B<Tk::TextUndo>.

Syntax highlighting is done through a plugin approach. Adding languages 
is a matter of writing plugin modules. Theoretically this is not limited to 
programming languages.  The plugin approach could also provide the possibility 
for grammar or spell checking in spoken languages.

Currently there is support for B<Bash>, B<HTML>, B<Perl>, B<Pod>, B<Kate>, 
and B<Xresources>.

=head1 OPTIONS

=over 4

=item Name: B<autoindent>

=item Class: B<Autoindent>

=item Switch: B<-autoindent>

Boolean, when you press the enter button, should the next line begin at the 
same position as the current line or not. By default B<false>.

=item Name: B<commentchar>

=item Class: B<Commentchar>

=item Switch: B<-commentchar>

By default "#".

=item Name: B<disablemenu> 

=item Class: B<Disablemenu>

=item Switch: B<-disablemenu>

Boolean, by default 0. In case you don't want the menu under the right mouse 
button to pop up.

=item Name: B<highlightInBackground>

=item Class: B<highlightInBackground>

=item Switch: B<-highlightInBackground>

Whether or not to do highlighting in background freeing up the mouse and 
keyboard for most events (experimental).  May be 1 or 0.  Default 0 (Do not 
highlight in background - block input until highlighting completed).

=item Name: B<indentchar>

=item Class: B<Indentchar>

=item Switch: B<-indentchar>

String to be inserted when the [Tab] key is pressed or when indenting.
Default "\t".

=item Name: B<match>

=item Class: B<Match>

=item Switch: B<-match>

string of pairs for brace/bracket/curlie etc matching. If this description 
doesn't make anything clear, don't worry, the default setting will:

 '[]{}()'

if you don't want matching to be available, simply set it to ''.

=item Name: B<matchoptions>

=item Class: B<Matchoptions>

=item Switch: B<-matchoptions>

Options list for the tag 'Match'. By default:

 [-background => 'red', -foreground => 'yellow']

You can also specify this option as a space separated string. Might come in 
handy for your Xresource files.

 "-background red -foreground yellow"

=item Name: not available

=item Class: not available

=item Switch B<-rules>

Specify the color and font options for highlighting. You specify a list 
looking a bit like this.

 [
     ['Tagname1', @options1],
     ['Tagname2', @options2],
 ]

The names of the tags are depending on the syntax that is highlighted.  
See the language modules for more information about this data structure.

=item Name: rulesdir

=item Class: Rulesdir

=item Switch B<-rulesdir>

Specify the directory where this widget stores its coloring defenitions. 
Files in this directory are stored as "HTML.rules", "Perl.rules" etc.  
By default it is set to '', which means that when you switch syntax 
the highlighting rules are not loaded or stored. The hard coded defaults 
in the language modules will be used.

=item Name: B<syntax>

=item Class: B<Syntax>

=item Switch: B<-syntax>


Specifies the language for highlighting. At this moment the possible 
values are B<None>, B<HTML>, B<Perl>, B<Pod> B<Kate:Language>, 
and B<Xresources>.  Default:  B<None>

If B<Syntax::Highlight::Engine::Kate> is installed, you may specify any 
language that the B<Kate> syntax highlight engine supports.

Alternatively it is possible to specify a reference to your independent plugin. 

=item Name: Not available

=item Class: Not available

=item Switch: B<-updatecall>

Here you can specify a callback that will be executed whenever the insert 
cursor has moved or text has been modified, so your application can keep 
track of position etc. Don't make this callback to heavy, the widget will 
get sluggish quickly.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noPlugInit>

Disables TextHighlight feature of initializing default rules when no B<.rules> 
file present.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noSyntaxMenu>

Don't show the B<Syntax> submenu option in the B<View> submenu of the 
right-click menu.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noSaveRulesMenu>

Don't show the B<Save Rules> submenu option in the B<View> submenu of the 
right-click menu.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noRulesEditMenu>

Don't show the B<Rules Editor> option in the B<View> submenu of the 
right-click menu.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noRulesMenu>

Don't show any of the TextHighlight menu items (combines B<-noSyntaxMenu>, 
B<-noRulesEditMenu>, and B<-noSaveRulesMenu> options.

=back

There are some undocumented options. They are used internally.  
It is propably best to leave them alone.

=head1 METHODS

=over 4

=item B<doAutoIndent>

Checks the indention of the previous line and indents the line where the 
cursor is equally deep.

=item B<highlight>(I<$begin>, I<$end>);

Does syntax highlighting on the section of text indicated by $begin and $end.  
$begin and $end are linenumbers not indexes!

=item B<highlightCheck>>(I<$begin>, I<$end>);

An insert or delete has taken place affecting the section of text between 
$begin and $end.  B<highlightCheck> is being called after and insert or delete 
operation. $begin and $end (again, linenumbers, not indexes) indicate the 
section of text affected. B<highlightCheck> checks what needs to be 
highlighted again and does the highlighting.

=item B<highlightLine>(I<$line>);

Does syntax highlighting on linenumber $line.

=item B<highlightPlug>

Checks wether the appropriate highlight plugin has been loaded. If none or the 
wrong one is loaded, it loads the correct plugin. It returns a reference to 
the plugin loaded.  It also checks wether the rules have changed. If so, it 
restarts highlighting from the beginning of the text.

=item B<highlightPlugInit>

Loads and initalizes a highlighting plugin. First it checks the value of the 
B<-syntax> option to see which plugin should be loaded. Then it checks wether 
a set of rules is defined to this plugin in the B<-rules> option. If not, it 
tries to obtain a set of rules from disk using B<rulesFetch>.  If this fails 
as well it will use the hardcoded rules from the syntax plugin.

=item B<highlightPurge>(I<$line>);

Tells the widget that the text from linenumber $line to the end of the text is 
not to be considered highlighted any more.

=item B<highlightVisual>

Calls B<visualEnd> to see what part of the text is visible on the display, and 
adjusts highlighting accordingly.

=item B<linenumber>(I<$index>);

Returns the linenumber part of an index. You may also specify indexes like 
'end' or 'insert' etc.

=item B<matchCheck>

Checks wether the character that is just before the 'insert'-mark should be 
matched, and if so, should it match forwards or backwards.  
It then calls B<matchFind>.

=item B<matchFind>(I<$direction>, I<$char>, I<$match>, I<$start>, I<$stop>);

Matches $char to $match, skipping nested $char/$match pairs, and displays the 
match found (if any).

=item B<rulesEdit>

Pops up a window that enables the user to set the color and font options 
for the current syntax.

=item B<rulesFetch>

Checks wether the file 

 $text->cget('-rulesdir') . '/' . $text->cget('-syntax') . '.rules'

exists, and if so attempts to load this as a set of rules.

=item B<rulesSave>

Saves the currently loaded rules as

 $text->cget('-rulesdir') . '/' . $text->cget('-syntax') . '.rules'

=item B<selectionComment>

Comment currently selected text.

=item B<selectionIndent>

Indent currently selected text.

=item B<selectionModify>

Used by the other B<selection...> methods to do the actual work.

=item B<selectionUnComment>

Uncomment currently selected text.

=item B<selectionUnIndent>

Unindent currently selected text.

=item B<setRule(rulename,colorattribute,color)>

Allows altering of individual rules by the programmer.

=item B<fetchKateInfo>

Fetches 3 hashrefs containing information about the installed Kate highlight 
engine (if installed).  The three hashrefs contain in order:  The first can be 
passed to the B<addkate2viewmenu()> method to add the B<Kate> languages to the 
Syntax.View menu.  the keys are "Kate::language" and the values are what's 
needed to instantiate Kate for that language.  the 2nd is a list of file-
extension pattern suitable for matching against file-names and the values are 
the reccomended Kate language for that file-extension.  It will return 
B<(undef, undef, undef)>  if B<Kate> is not installed.

=item B<addKate2ViewMenu($sections)>

Inserts the list of B<Kate>-supported languages to the widget's Syntax.View 
right-mousebutton popup menu along with the basic TextHight-supported choices. 
These choices can then be selected to change the current language-highlighting 
used in the text in the widget.  B<$sections> is a hash-ref normally returned 
as the 1st item in the list returned by B<fetchKateInfo>.  NOTE:  No menu 
items will be added if B<Kate> is not installed or if B<-noRulesMenu> or 
B<-noSyntaxMenu> is set!

=back

=head1 SYNTAX HIGHLIGHTING

This section is a brief description of how the syntax highlighting 
process works.

B<Initiating plugin>

The highlighting plugin is only then initiated when it is needed. When some 
highlighting needs to be done, the widget calls B<highlightPlug> to retrieve 
a reference to the plugin. 

B<highlightPlug> checks wether a plugin is present. Next it will check whether 
the B<-rules> option has been specified or wether the B<-rules> option 
has changed.  If no rules are specified in B<-rules>, it will look for a 
pathname in the B<-rulesdir> option. If that is found it will try to load a 
file called '*.rules', where * is the value of B<-syntax>. 

If no plugin is present, or the B<-syntax> option has changed value, 
B<highlightPlug> loads the plugin. and constructs optionally giving it 
a reference to the found rules as parameter. if no rules 
are specified, the plugin will use its internal hardcoded defaults.

B<Changing the rules>

A set of rules is a list, containing lists of tagnames, followed by options.  
If you want to see what they look like, you can have a look at the constructors 
of each plugin module. Every plugin has a fixed set of tagnames it can handle.

There are two ways to change the rules.

You can invoke the B<rulesEdit> method, which is also available through the 
B<View> menu. The result is a popup in which you can specify color and font 
options for each tagname. After pressing 'Ok', the edited rules will 
be applied.  If B<-rulesdir> is specified, the rules will be saved on disk as 
I<rulesdir/syntax.rules>.

You can also use B<configure> to specify a new set of rules. In this you have 
ofcause more freedom to use all available tag options. For more details about 
those there is a nice section about tag options in the Tk::Text documentation.  
After the call to B<configure> it is wise to call B<highlightPlug>.

B<Highlighting text>

Syntax highlighting is done in a lazy manor. Only that piece of text is 
highlighted that is needed to present the user a pretty picture. This is 
done to minimize use of system resources. Highlighting is running on the 
foreground. Jumping directly to the end of a long fresh loaded textfile may 
very well take a couple of seconds.

Highlighting is done on a line to line basis. At the end of each line the
highlighting status is saved in the list in B<-colorinf>, so when highlighting
the next line, the B<highlight> method of B<TextHighlight> will know how 
to begin.

The line that needs highlighting is offered to the B<highlight> method of 
the plugin. This method returns a list of offset and tagname pairs.  
Take for example the following line of perl code.

 my $mother = 'older than i am';

The B<highlight> method of the Perl plugin will return the following list;

 (2 => 'Reserved',    #'my' is a reserved word
  1 => 'DEFAULT',     #Space
  7 => 'Variable',    #$mother
  1 => 'DEFAULT',     #Space
  1 => 'Operator',    #'='
  1 => 'DEFAULT',     #Space
  17 => 'String',     #'older than i am'
  1 => 'DEFAULT',)    #;

The B<highlight> method of TextHighlight will then mark positions 0 to 2 as 
'Reserved', positions 2 to 3 as 'DEFAULT', positions 3 to 10 as 'Variable', etc.

=head1 WRITING PLUGINS

After writing a couple of plugins myself i have come to a couple of guidelines 
about how to set them up. If you are interested in adding support for your 
own syntax highlighting problem or language this section is of interest to you.

B<From scratch>

If you choose to build a plugin completely from scratch, your module needs 
to meet the following requirements.

 - If you want to write a formal addition to Tk::TextHighlight, 
   your plugin must be in the namespace 
   Tk::TextHighlight::YourSyntax.

 - The constructor is called 'new', and it should accept 
   a reference a reference to a list of rules as parameters.

 - The following methods will be called upon by Tk::TextHighlight:  
   highlight, stateCompare, rules, setSate, getState, syntax.

More information about those methods is available in the documentation of 
Tk::TextHighlight::None and Tk::TextHighlight::Template.

B<Inheriting Tk::TextHighlight::Template>

For many highlighting problems Tk::TextHighlight::Template 
provides a nice basis to start from. Your code could look like this:

 package Tk::TextHighlight::MySyntax;
 
 use strict;
 use base('Tk::TextHighlight::Template');
 
 sub new {
    my ($proto, $wdg, $rules) = @_;
    my $class = ref($proto) || $proto;

Next, specify the set of hardcoded rules.

    if (not defined($rules)) {
       $rules =  [
          ['Tagname1', -foreground => 'red'],
          ['Tagname1', -foreground => 'red'],
       ];
    };

Call the constructor of Tk::TextHighlight::Template and bless your object.

    my $self = $class->SUPER::new($rules);

So now we have the SUPER class avalable and we can start defining 
a couple of things.

You could add a couple of lists, usefull for keywords etc.

    $self->lists({
        'Keywords' => ['foo', 'bar'],
        'Operators' => ['and', 'or'],
    });

For every tag you have to define a corresponding callback like this.

    $self->callbacks({
        'Tagname1' => \&Callback1,
        'Tagname2' => \&Callback2,
    });

You have to define a default tagname like this:

    $self->stackPush('Tagname1');

Perhaps do a couple of other things but in the end, wrap up the new method.

    
    bless ($self, $class);
    return $self;
 }

Then you need define the callbacks that are mentioned in the B<callbacks> 
hash. When you just start writing your plugin i suggest you make them look 
like this:

 sub callback1 {
    my ($self $txt) = @_;
    return $self->parserError($txt); #for debugging your later additions
 }

Later you add matching statements inside these callback methods. For instance, 
if you want I<callback1> to parse spaces it is going to look like this:


 sub callback1 {
    my ($self $txt) = @_;
    if ($text =~ s/^(\s+)//) { #spaces
        $self->snippetParse($1, 'Tagname1'); #the tagname here is optional
        return $text;
    }
    return $self->parserError($txt); #for debugging your later additions
 }

If I<callback1> is the callback that is called by default, you have to add 
the mechanism for checking lists to it. Hnce, the code will look like this:

 sub callback1 {
    my ($self $txt) = @_;
    if ($text =~ s/^(\s+)//) { #spaces
        $self->snippetParse($1, 'Tagname1'); #the tagname here is optional
        return $text;
    }
    if ($text =~ s/^([^$separators]+)//) {	#fetching a bare part
        if ($self->tokenTest($1, 'Reserved')) {
            $self->snippetParse($1, 'Reserved');
        } elsif ($self->tokenTest($1, 'Keyword')) {
            $self->snippetParse($1, 'Keyword');
        } else { #unrecognized text
            $self->snippetParse($1);
        }
        return $text
    }
    return $self->parserError($txt); #for debugging your later additions
 }

Have a look at the code of Tk::TextHighlight::Bash. Things should clear up.  
Then, last but not least, you need a B<syntax> method.

B<Using another module as basis>

An example of this approach is the Perl syntax module.

Also with this approach you will have to meet the minimum criteria 
as set out in the B<From scratch> section.

=head1 CONTRIBUTIONS

If you have written a plugin, i will be happy to include it in the next release 
of Tk::TextHighlight. If you send it to me, please have it accompanied with the 
sample of code that you used for testing.

=head1 AUTHOR

This module is Copyright (C) 2007-2024 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README file.

This is a derived work from Tk::CodeText, by Hans Jeuken 
(haje at toneel.demon.nl)

Thanks go to Mr. Hans Jeuken for his great work in making this and the Kate 
modules possible.  He did the hard work!

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2024 Jim Turner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 TODO

=over 4

=item Add additional language modules. I am going to need help on this one.  
We currently support all the original B<Tk::CodeText> languages (included) plus 
all those supported by B<Syntax::Highlight::Engine::Kate>, if it's installed.

=item The sample files in the test suite should be set up so that conformity 
with the language specification can actually be verified.

=back

=head1 SEE ALSO

=over 4

=item L<Tk::Text>, L<Tk::TextUndo>, L<Tk::Text::SuperText>, 
L<Tk::TextHighlight::Bash>, L<Tk::CodeText>, 
L<Syntax::Highlight::Perl::Improved>, L<Syntax::Highlight::Engine::Kate>

=back

=cut

package Tk::TextHighlight;

use vars qw($VERSION);
$VERSION = '1.2';
use base qw(Tk::Derived Tk::TextUndo);
use Tk qw(Ev);
use strict;
use Storable;
use File::Basename;

my $blockHighlight = 0;     #USED TO PREVENT RECURSIVE CALLS TO RE-HIGHLIGHT!
my $nodoEvent = 0;          #USED TO PREVENT REPEATING (RUN-AWAY) SCROLLING!
Construct Tk::Widget 'TextHighlight';

sub Populate {
	my ($cw,$args) = @_;
	$cw->SUPER::Populate($args);
	$cw->ConfigSpecs(
		-autoindent => [qw/PASSIVE autoindent Autoindent/, 0],
		-match => [qw/PASSIVE match Match/, '[]{}()'],
		-matchoptions	=> [qw/METHOD matchoptions Matchoptions/, 
			[-background => 'red', -foreground => 'yellow']],
		-indentchar => [qw/PASSIVE indentchar Indentchar/, "\t"],
		-disablemenu => [qw/PASSIVE disablemenu Disablemenu/, 0],
		-commentchar => [qw/PASSIVE commentchar Commentchar/, "#"],
		-colorinf => [qw/PASSIVE undef undef/, []],
		-colored => [qw/PASSIVE undef undef/, 0],
		-syntax	=> [qw/PASSIVE syntax Syntax/, 'None'],
		-rules	=> [qw/PASSIVE undef undef/, undef],
		-rulesdir	=> [qw/PASSIVE rulesdir Rulesdir/, ''],
		-updatecall	=> [qw/PASSIVE undef undef/, sub {}],
		-noRulesMenu => [qw/PASSIVE undef undef/, 0],       #JWT: ADDED FEATURE.
		-noSyntaxMenu => [qw/PASSIVE undef undef/, 0],      #JWT: ADDED FEATURE.
		-noRulesEditMenu => [qw/PASSIVE undef undef/, 0],   #JWT: ADDED FEATURE.
		-noSaveRulesMenu => [qw/PASSIVE undef undef/, 0],   #JWT: ADDED FOR BACKWARD COMPATABILITY.
		-noPlugInit => [qw/PASSIVE undef undef/, 0],        #JWT: ADDED FOR BACKWARD COMPATABILITY.
		-highlightInBackground => [qw/PASSIVE undef undef/, 0],    #JWT: SELF-EXPLANATORY.
		DEFAULT => [ 'SELF' ],
	);
	$cw->bind('<Configure>', sub { $cw->highlightVisual });
	$cw->bind('<Shift-Return>', sub { $cw->doAutoIndent(0) });
	$cw->bind('<Return>', sub { $cw->doAutoIndent(1) });
	$cw->markSet('match', '0.0');
	$cw->bind('<Control-p>', \&jumpToMatchingChar);
	$cw->bind('<Shift-BackSpace>', \&doShiftBackSpace);   #DOESN'T SEEM TO WORK?!?!?!
	$cw->bind('<Shift-Tab>', \&deleteToEndofLine);   #DOESN'T SEEM TO WORK?!?!?!
	$cw->bind('<Shift-Insert>', \&doShiftInsert);   #DOESN'T SEEM TO WORK?!?!?!
}

sub configure    #ADDED 20081027 TO RE-CHECK RULE COLORS WHEN BACKGROUND CHANGES
{
	my $cw = shift;
	my $plug = $cw->Subwidget('formatter');	
	if ($plug)
	{
		for (my $i=0;$i<$#{_};$i++)
		{
			if ($_[$i] =~ /\-(?:bg|background)/o)
			{			
				my $oldBg = $cw->cget($_[$i]);
				unless ($_[$i+1] eq $oldBg)
				{
					#IF CHANGING BACKGROUND, MUST RESET RULE COLORS TO PREVENT 
					#COLOR CONTRAST ILLEGABILITIES!
					$cw->SUPER::configure($_[$i] => $_[$i+1]);
					$cw->configure('-rules' => undef);
					$cw->highlightPlug;
					last;
				}
			}
		}
	}		
	$cw->SUPER::configure(@_);	
}

sub jumpToMatchingChar  #ADDED 20060630 JWT TO CAUSE ^p TO WORK LIKE VI & SUPERTEXT - JUMP TO MATCHING CHARACTER!
{
	my $cw = shift;
	$cw->markSet('insert', $cw->index('insert'));
	my $pm = -1;
	eval { $pm = $cw->index('MyMatch'); };
	if ($pm >= 0)
	{
		my $prevMatch = $cw->index('insert');
		$prevMatch .= '.0'  unless ($prevMatch =~ /\./o);
		$cw->markSet('insert', $cw->index('MyMatch'));
		$cw->see('insert');
		$cw->markSet('MyMatch', $prevMatch);
	}
}

sub doShiftBackSpace
{
	my $cw = shift;
	my $curPos = $cw->index('insert');
	my $leftPos = $cw->index('insert linestart');
	$cw->delete($leftPos, $curPos)  unless ($curPos <= $leftPos);
}

sub deleteToEndofLine
{
	my ($cw) = @_;
	if ($cw->compare('insert','==','insert lineend'))
	{
		$cw->delete('insert')
	}
	else
	{
		$cw->delete('insert','insert lineend')
	}
}

sub doShiftDelete
{
	my $cw = shift;
	(my $curPos = $cw->index('insert')) =~ s/\..*$//o;
	my $startPos = ($curPos > 1) ? $cw->index('insert - 1 line lineend')
			: $cw->index('1.0');
	my $endPos = $cw->index('insert lineend');
	$cw->delete($startPos, $endPos); #  unless ($startPos <= $endPos);
}

sub doShiftInsert
{
	my $cw = shift;
	my $insPos = $cw->index('insert lineend');
	$cw->insert($insPos, "\n");
}

sub ClassInit   #JWT: ADDED FOR VI-LIKE Control-P JUMP TO MATCHING BRACKET FEATURE.
{
	my ($class,$w) = @_;
	
	$class->SUPER::ClassInit($w);

	# reset default Tk::Text binds
	$w->bind($class,	'<Control-p>', sub {} );
	$w->bind($class,	'<Alt-Tab>', 'insertTabChar' );    #ADDED TO ALLOW INSERTION OF TABS OR SPACES!
	$w->bind($class, '<Shift-BackSpace>', 'doShiftBackSpace' );   #DOESN'T SEEM TO WORK?!?!?!
	$w->bind($class, '<Shift-Delete>', 'doShiftDelete' );
	$w->bind($class, '<Control-Delete>', 'deleteToEndofLine' );
	$w->bind($class, '<Control-Tab>', 'deleteToEndofLine' );   #DOESN'T SEEM TO WORK?!?!?!
	$w->bind($class,	'<Tab>', 'insertTab' );    #ADDED TO ALLOW INSERTION OF TABS OR SPACES!
	$w->bind($class, '<Control-BackSpace>', 'doShiftBackSpace' );
	return $class;
}

sub clipboardCopy {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->SUPER::clipboardCopy(@_);
	}
}

sub clipboardCut {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->SUPER::clipboardCut(@_);
	}
}

sub clipboardPaste {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->tagRemove('sel', '1.0', 'end');
		return;
	}
	$cw->SUPER::clipboardPaste(@_);
}

sub delete {
	my $cw = shift;
	my $begin = $_[0];
	if (defined($begin)) {
		$begin = $cw->linenumber($begin);
	} else { 
		$begin = $cw->linenumber('insert');
	};
	my $end = $_[1];
	if (defined($end)) {
		$end = $cw->linenumber($end);
	} else { 
		$end = $begin;
	};
	$cw->SUPER::delete(@_);
	$cw->highlightCheck($begin, $end);
}

sub doAutoIndent {
	my $cw = shift;
	my $doAutoIndent = shift;
	return  unless ($doAutoIndent);

	if ($cw->cget('-autoindent')) {
		my $i = $cw->index('insert linestart');
		if ($cw->compare($i, ">", '0.0')) {
			my $s = $cw->get("$i - 1 lines", "$i - 1 lines lineend");
#			if ($s =~ /\S/)  #JWT: UNCOMMENT TO CAUSE SUBSEQUENT BLANK LINES TO NOT BE AUTOINDENTED.
#			{
				#$s =~ /^(\s+)/;  #CHGD. TO NEXT 20060701 JWT TO FIX "e" BEING INSERTED INTO LINE WHEN AUTOINDENT ON?!
				$s =~ /^(\s*)/o;
				if ($1) {
					$cw->insert('insert', $1);
				}
				$cw->insert('insert', $cw->cget('-indentchar'))
						if ($s =~ /[\{\[\(]\s*$/o);   #ADDED 20060701 JWT - ADD AN INDENTION IF JUST OPENED A BLOCK!
#			}
		}
	}
}

sub EditMenuItems {
	my $cw = shift;
	return [
		@{$cw->SUPER::EditMenuItems},
		["command"=>'Select', -command => [$cw => 'adjustSelect']],
		"-",
		["command"=>'Comment', -command => [$cw => 'selectionComment']],
		["command"=>'Uncomment', -command => [$cw => 'selectionUnComment']],
		"-",
		["command"=>'Indent', -command => [$cw => 'selectionIndent']],
		["command"=>'Unindent', -command => [$cw => 'selectionUnIndent']],
	];
}

sub EmptyDocument {
	my $cw = shift;
	my @r = $cw->SUPER::EmptyDocument(@_);
	$cw->highlightPurge(1);
	return @r
}

sub highlight {
	my ($cw, $begin, $end) = @_;
#	return $begin  if ($blockHighlight);   #PREVENT RECURSIVE CALLING WHILST ALREADY REHIGHLIGHTING!
	$blockHighlight = 1;
	if (not defined($end)) { $end = $begin + 1};
	#save selection and cursor position
	my @sel = $cw->tagRanges('sel');
#	my $cursor = $cw->index('insert'); 
	#go over the source code line by line.
	while ($begin < $end) {
		$cw->highlightLine($begin);
		$begin++; #move on to next line.
	};
	#restore original cursor and selection
#	$cw->markSet('insert', $cursor);
#1	if ($sel[0]) {
#1		$cw->tagRaise('sel');   #JWT:REMOVED 20060703 SO THAT HIGHLIGHTING STAYS ON SELECTED STUFF AFTER SELECTION MOVES OVER UNTAGGED TEXT.
#1	};
	$blockHighlight = 0;
	return $begin;
}

sub highlightCheck {
	my ($cw, $begin, $end) = @_;
	my $col = $cw->cget('-colored');
	my $cli = $cw->cget('-colorinf');
	if ($begin <= $col) {
		#The operation occurred in an area that was highlighted already
		if ($begin < $end) {
			#it was a multiline operation, so highlighting is not reliable anymore
			#restart hightlighting from the beginning of the operation.
			$cw->highlightPurge($begin);
		} else {
			#just re-highlight the modified line.
			my $hlt = $cw->highlightPlug;
			my $i = $cli->[$begin];
			$cw->highlight($begin);
			if (($col < $cw->linenumber('end')) and (not $hlt->stateCompare($i))) {
			#the proces ended inside a multiline token. try to fix it.
				$cw->highlightPurge($begin);
			}
		};
		$cw->matchCheck;
	} else {
		$cw->highlightVisual;
	}
}

sub highlightLine {
	my ($cw, $num) = @_;
	my $hlt = $cw->highlightPlug;
	my $cli = $cw->cget('-colorinf');
	my $k = $cli->[$num - 1];
	$hlt->stateSet(@$k);
#	remove all existing tags in this line
	my $begin = "$num.0"; my $end = $cw->index("$num.0 lineend");
	my $rl = $hlt->rules;
	foreach my $tn (@$rl) {
		$cw->tagRemove($tn->[0], $begin, $end);
	}	
	my $txt = $cw->get($begin, $end); #get the text to be highlighted
	my @v;
	if ($txt) { #if the line is not empty
		my $pos = 0;
		my $start = 0;
		my @h = $hlt->highlight("$txt\n");     #JWT:  ADDED "\n" TO MAKE KATE WORK!
		while (@h ne 0) {
			$start = $pos;
			$pos += shift @h;
			my $tag = shift @h;
			$cw->tagAdd($tag, "$num.$start", "$num.$pos");
		};
		$cw->DoOneEvent(2)  unless ($nodoEvent
				|| !$cw->cget('-highlightInBackground'));       #DON'T PREVENT USER-INTERACTION WHILE RE-HILIGHTING!
	};
	$cli->[$num] = [ $hlt->stateGet ];
}

sub highlightPlug {
	my $cw = shift;
	my $plug = $cw->Subwidget('formatter');
	my $syntax = $cw->cget('-syntax');
	$syntax =~ s/\:\:.*$//o;
	my $rules = $cw->cget('-rules');
	if (not defined($plug)) {
		$plug = $cw->highlightPlugInit;
	} elsif (ref($syntax)) {
		if ($syntax ne $plug) {
			$plug = $cw->highlightPlugInit;
		}
	} elsif ($syntax ne $plug->syntax) {
		$cw->rulesDelete;
		$plug = $cw->highlightPlugInit;
		$cw->highlightPurge(1);
	} elsif (defined($rules)) {
#		if ($rules ne $plug->rules) {   #JWT: CHGD TO NEXT TO PREVENT INFINITE RECURSION WHEN "None" HIGHLIGHTER IS USED!
		if ($#{$rules} >= 0 && $rules ne $plug->rules) {
			$cw->rulesDelete;
			$plug->rules($rules);
			$cw->rulesConfigure;
			$cw->highlightPurge(1);
		}
	} else {
		$cw->rulesDelete;
		$cw->highlightPlugInit;
		$cw->highlightPurge(1);
	}
	return $plug
}

sub highlightPlugInit {
	my $cw = shift;
	my $syntax = $cw->cget('-syntax');
	if (not defined($cw->cget('-rules'))) { $cw->rulesFetch };
	my $plug;
	my $lang = '';
	if (ref($syntax)) {
		$plug = $syntax;
	} else {
	$lang = $1  if ($syntax =~ s/\:\:(.*)$//o);
		my @opt = ();
		if (my $rules = $cw->cget('-rules')) {
			push(@opt, $rules);
		}
		my $evalStr = "require Tk::TextHighlight::$syntax; \$plug = new Tk::TextHighlight::$syntax("
			.($lang ? "'$lang', " : '') . "\@opt);";
		eval $evalStr;
		#JWT: ADDED UNLESS 20060703 TO PROPERLY INITIALIZE RULES FROM PLUGIN, IF NO .rules FILE DEFINED.
		unless ($@ || !defined($plug) || !defined($plug->rules)
				|| $cw->cget('-noPlugInit'))
		{
			my $rules = $plug->rules;
			$cw->configure(-rules => \@$rules);
		}
	}
	$cw->Advertise('formatter', $plug);
	$cw->rulesConfigure;
	my $bg = $cw->cget(-background);
	my ($red, $green, $blue) = $cw->rgb($bg);   #JWT: NEXT 11 ADDED 20070802 TO PREVENT INVISIBLE TEXT!
	my @rgb = sort {$b <=> $a} ($red, $green, $blue);
	my $max = $rgb[0]+$rgb[1];  #TOTAL BRIGHTEST 2.
	my $daytime = 1;
	my $currentrules = $plug->rules;
	if ($max <= 52500) {   #IF BG COLOR IS DARK ENOUGH, FORCE RULES WITH NORMAL BLACK-
		$daytime = 0;     #FOREGROUND TO WHITE TO AVOID COLOR CONTRAST ILLEGABILITIES.
		#print "-NIGHT 65!\n";
		for (my $k=0;$k<=$#{$currentrules};$k++)
		{
			if ($currentrules->[$k]->[2] eq 'black')
			{
				$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],'white');
			}
		};
	}
	for (my $k=0;$k<=$#{$currentrules};$k++)
	{
		if (defined($currentrules->[$k]->[2]) and $currentrules->[$k]->[2] eq $bg)
		{
			#RULE FOREGROUND COLOR == BACKGROUND, CHANGE TO BLACK OR WHITE TO KEEP READABLE!
			$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],($daytime ? 'black' : 'white'));
		}
	};
	$cw->update;
	unless ($cw->cget('-noSyntaxMenu'))  #JWT:  ADDED TO ENSURE VIEW RADIO-BUTTON PROPERLY INITIALIZED/SET.
	{
		my @kateMenus;
		my $ViewSyntaxMenu = $cw->menu->entrycget('View','-menu')->entrycget('Syntax','-menu');
		my $lastMenuIndex = $ViewSyntaxMenu->index('end');

		#WE MUST FETCH THE VARIABLE REFERENCE USED BY THE "View" MENU RADIO-BUTTONS SO 
		#THAT OUR NEW RADIO BUTTONS SHARE SAME VARIABLE (OTHERWISE, WILL HAVE >1 LIT AT
		#SAME TIME!

		my $var;
		foreach my $i (0..$lastMenuIndex)
		{
			if ($ViewSyntaxMenu->type($i) =~ /radiobutton/o)
			{
				$var = $ViewSyntaxMenu->entrycget($i, '-variable');
				tie $$var,'Tk::Configure',$cw,'-syntax';
				unless (ref($syntax))
				{
					$$var = $lang ? ($syntax.'::'.$lang) : $syntax;
				}
				last;
			}
		}
	}
	return $plug;
}

sub highlightPlugList {
	my $cw = shift;
	my @ml = ();
	my $haveKate = 0;
	foreach my $d (@INC) {
		my @fl = <$d/Tk/TextHighlight/*.pm>;
		foreach my $file (@fl) {
			my ($name, $path, $suffix) = fileparse($file, "\.pm");
			if ($name eq 'Kate') {   #JWT:ADDED THIS PART OF CONDITIONAL 20160118:
				eval 'use Syntax::Highlight::Engine::Kate; $haveKate = 1; 1'  unless ($haveKate);
				if ($haveKate) {
					unless (grep { ($name eq $_) } @ml) { push(@ml, $name); };
				}
#CHGD. TO NEXT 20160119:			} elsif (($name ne 'None') and ($name ne 'Template')) {
			} elsif ($name !~ /^(?:None|Template|RulesEditor)/o) {
				#avoid duplicates
				unless (grep { ($name eq $_) } @ml) { push(@ml, $name); };
			}
		}
	}
	return sort @ml;
}

sub highlightPurge {
	my ($cw, $line) = @_;
	$cw->configure('-colored' => $line);
	my $cli = $cw->cget('-colorinf');
	if (@$cli) { splice(@$cli, $line) };
	$cw->highlightVisual;
}

sub highlightVisual {
	my $cw = shift;
	return  if ($blockHighlight);
	my $end = $cw->visualend;
	my $col = $cw->cget('-colored');
	if ($col < $end) {
		$col = $cw->highlight($col, $end);
		$cw->configure(-colored => $col);
	};
	$cw->matchCheck;
}

sub insert {
	my $cw = shift;
	my $pos = shift;
	$pos = $cw->index($pos);
	my $begin = $cw->linenumber("$pos - 1 chars");
	$cw->SUPER::insert($pos, @_);
	$cw->highlightCheck($begin, $cw->linenumber("insert lineend"));
}

sub Insert {
	my $cw = shift;
	$cw->SUPER::Insert(@_);
	$cw->see('insert');
}

sub InsertKeypress {
	my ($cw,$char) = @_;
	if ($char ne '') {
		my $index = $cw->index('insert');
		my $line = $cw->linenumber($index);
		if ($char =~ /^\S$/o and !$cw->OverstrikeMode and !$cw->tagRanges('sel')) {
			my $undo_item = $cw->getUndoAtIndex(-1);
			if (defined($undo_item) &&
				($undo_item->[0] eq 'delete') &&
				($undo_item->[2] == $index)
			) {
				$cw->Tk::Text::insert($index,$char);
				$undo_item->[2] = $cw->index('insert');
				$cw->highlightCheck($line, $line);
				$cw->see('insert');   #ADDED 20060703 TO ALLOW USER TO SEE WHAT HE'S TYPING PAST END OF LINE (THIS IS BROKEN IN TEXTUNDO TOO).
				return;
			}
		}
		$cw->addGlobStart;
		$cw->Tk::Text::InsertKeypress($char);
		$cw->addGlobEnd;
	}
}

sub linenumber {
	my ($cw, $index) = @_;
	if (not defined($index)) { $index = 'insert'; }
	my $id = $cw->index($index);
	my ($line, $pos ) = split(/\./o, $id);
	return $line;
}

sub Load {
	my $cw = shift;
	my @r = $cw->SUPER::Load(@_);
	$cw->highlightVisual;
	return @r;
}

sub matchCheck {
	my $cw = shift;
	my $c = $cw->get('insert', 'insert + 1 chars');
	my $p = $cw->index('match');
	if ($p ne '0.0') {
		$cw->tagRemove('Match', $p, "$p + 1 chars");
		$cw->markSet('match', '0.0');
		$cw->markUnset('MyMatch');
	}
	if ($c) {
		my $v = $cw->cget('-match');
		my $p = index($v, $c);
		if ($p ne -1) { #a character in '-match' has been detected.
			my $count = 0;
			my $found = 0;
			if ($p % 2) {
				my $m = substr($v, $p - 1, 1);
				$cw->matchFind('-backwards', $c, $m, 
					$cw->index('insert'),
#					$cw->index('@0,0'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
					$cw->index('0.0'),
				);
			} else {
				my $m = substr($v, $p + 1, 1);
#				print "searching -forwards, $c, $m\n";
				$cw->matchFind('-forwards', $c, $m,
					$cw->index('insert + 1 chars'),
#					$cw->index($cw->visualend . '.0 lineend'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
					$cw->index('end'),
				);
			}
		}
	}
	$cw->updateCall;
}

sub matchFind {
	my ($cw, $dir, $char, $ochar, $start, $stop) = @_;
	#first of all remove a previous match highlight;
	my $pattern = "\\$char|\\$ochar";
	my $found = 0;
	my $count = 0;
	while ((not $found) and (my $i = $cw->search(
		$dir, '-regexp', '-nocase', '--', $pattern, $start, $stop
	))) {
		my $k = $cw->get($i, "$i + 1 chars");
#		print "found $k at $i and count is $count\n";
		if ($k eq $ochar) {
			if ($count > 0) {
#				print "decrementing count\n";
				$count--;
				if ($dir eq '-forwards') {
					$start = $cw->index("$i + 1 chars");
				} else {
					$start = $i;
				}
			} else {
#				print "Found !!!\n";
				$cw->markSet('match', $i);
				$cw->tagAdd('Match', $i, "$i + 1 chars");
				$cw->markSet('MyMatch', $i);
				$cw->tagRaise('Match');
				$found = 1;
			}
		} elsif ($k eq $char) {
#			print "incrementing count\n";
			$count++;
			if ($dir eq '-forwards') {
				$start = $cw->index("$i + 1 chars");
			} else {
				$start = $i;
			}
		} elsif ($i eq $start) {
			$found = 1;
		}
	}
}

sub matchoptions {
	my $cw = shift;
	if (my $o = shift) {
		my @op = ();
		if (ref($o)) {
			@op = @$o;
		} else {
			@op = split(/\s+/o, $o);
		}
		$cw->tagConfigure('Match', @op);
	}
}


sub PostPopupMenu {
	my $cw = shift;
	my @r;
	if (not $cw->cget('-disablemenu')) {
		@r = $cw->SUPER::PostPopupMenu(@_);		
	}
}

sub rulesConfigure {
	my $cw = shift;
	if (my $plug = $cw->Subwidget('formatter')) {
		my $rules = $plug->rules;
		my @r = @$rules;
		foreach my $k (@r) {
			$cw->tagConfigure(@$k);
		};
		$cw->configure(-colored => 1, -colorinf => [[ $plug->stateGet]]);
	}
}

sub setRule     #ADDED 20060530 JWT TO PERMIT CHANGING INDIVIDUAL RULES.
{
	my $cw = shift;
	my @rule = @_;

	if (my $plug = $cw->Subwidget('formatter'))
	{
		my $rules = $plug->rules;
		my @r = @$rules;
		for (my $k=0;$k<=$#r;$k++)
		{
			if ($rule[0] eq $r[$k]->[0])
			{
				@{$r[$k]} = @rule;
			}
		};
		$cw->configure(-rules => \@r);
	}
}

sub rulesDelete {
	my $cw = shift;
	if (my $plug = $cw->Subwidget('formatter')) {
		my $rules = $plug->rules;
		foreach my $r (@$rules) {
			$cw->tagDelete($r->[0]);
		}
	}
}


sub rulesEdit {
	my $cw = shift;
	require Tk::TextHighlight::RulesEditor;
	$cw->RulesEditor(
		-class => 'Toplevel',
	);
}

sub rulesFetch {
	my $cw = shift;
	my $dir = $cw->cget('-rulesdir');
	my $syntax = $cw->cget('-syntax');
	$cw->configure(-rules => undef);
#	print "rulesFetch called\n";
	my $result = 0;
	if ($dir and (-e "$dir/$syntax.rules")) {
		my $file = "$dir/$syntax.rules";
#		print "getting $file\n";
		if (my $rl = retrieve("$dir/$syntax.rules")) {
#			print "configuring\n";
			$cw->configure(-rules => $rl);
			$result = 1;
		}
	}
	return $result;
}

sub rulesSave {
	my $cw = shift;
	my $dir = $cw->cget('-rulesdir');
#	print "rulesSave called\n";
	if ($dir) {
		my $syntax = $cw->cget('-syntax');
		my $file = "$dir/$syntax.rules";
		store($cw->cget('-rules'), $file);
	}
}

sub scan {
	my $cw = shift;
	my @r = $cw->SUPER::scan(@_);
	$cw->highlightVisual;
	return @r;
}

sub selectionModify {
	my ($cw, $char, $mode) = @_;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges eq 2) {
		my $start = $cw->index($ranges[0]);
		my $end = $cw->index($ranges[1]);
#		print "doing from $start to $end\n";
		while ($cw->compare($start, "<", $end)) {
#			print "going to do something\n";
			if ($mode) {
				if ($cw->get("$start linestart", "$start linestart + 1 chars") eq $char) {
					$cw->delete("$start linestart", "$start linestart + 1 chars");
				}
			} else {
				$cw->insert("$start linestart", $char)
			}
			$start = $cw->index("$start + 1 lines");
		}
		$cw->tagAdd('sel', @ranges);
	}
}

# SelectTo --
# This procedure is invoked to extend the selection, typically when
# dragging it with the mouse. Depending on the selection mode (character,
# word, line) it selects in different-sized units. This procedure
# ignores mouse motions initially until the mouse has moved from
# one character to another or until there have been multiple clicks.
#
# Arguments:
# w - The text window in which the button was pressed.
# index - Index of character at which the mouse button was pressed.
sub SelectTo
{
	my ($w, $index, $mode)= @_;
	$Tk::selectMode = $mode if defined ($mode);
	my $cur = $w->index($index);
	my $anchor = $w->index('insert');
	$Tk::mouseMoved = ($w->compare($cur,'!=',$anchor)) ? 1 : 0;
	$Tk::selectMode = 'char' unless (defined $Tk::selectMode);
	$mode = $Tk::selectMode;
	my ($first,$last);
	if ($mode eq 'char') {
		if ($w->compare($cur,'<','anchor')) {
			$first = $cur;
			$last = 'anchor';
		} else {
			$first = 'anchor';
			$last = $cur
		}
	} elsif ($mode eq 'word') {
		if ($w->compare($cur,'<','anchor')) {
			$first = $w->index("$cur wordstart");
			$last = $w->index('anchor - 1c wordend')
		} else {
			$first = $w->index('anchor wordstart');
			$last = $w->index("$cur wordend")
		}
	} elsif ($mode eq 'line') {		if ($w->compare($cur,'<','anchor')) {
			$first = $w->index("$cur linestart");
			$last = $w->index('anchor - 1c lineend + 1c')
		} else {
			$first = $w->index('anchor linestart');
			$last = $w->index("$cur lineend + 1c")
		}
	}
	if ($Tk::mouseMoved || $Tk::selectMode ne 'char') {
		$w->tagRemove('sel','1.0',$first);
		$w->tagAdd('sel',$first,$last);
		$w->tagRemove('sel',$last,'end');
		$w->idletasks;
	}
}

sub adjustSelect {
	my ($w) = @_;
	my $Ev = $w->XEvent;
	$w->SelectTo($Ev->xy,'char');
}

sub selectionComment {
	my $cw = shift;
	$cw->selectionModify($cw->cget('-commentchar'), 0);
}

sub selectionIndent {
	my $cw = shift;
	$cw->selectionModify($cw->cget('-indentchar'), 0);
}

sub selectionUnComment {
	my $cw = shift;
	$cw->selectionModify($cw->cget('-commentchar'), 1);
}

sub selectionUnIndent {
	my $cw = shift;
	$cw->selectionModify($cw->cget('-indentchar'), 1);
}

sub syntax {
	my $cw = shift;
	if (@_) {
		my $name = shift;
		my $fm;
		eval ("require Tk::TextHighlight::$name;	\$fm = new Tk::TextHighlight::$name(\$cw);");
		$cw->Advertise('formatter', $fm);
		$cw->configure('-langname' => $name);
	}
	return $cw->cget('-langname');
}

sub yview {
	my $cw = shift;
	my @r = ();
	if (@_) {
		@r = $cw->SUPER::yview(@_);
		if ($_[1] > 0) {   #ONLY RE-HIGHLIGHT IF SCROLLING DOWN (PREV. LINES ALREADY HIGHLIGHTED)!
			my ($p) = caller;
			$nodoEvent = 1  if ($p =~ /scroll/io);   #THIS PREVENTS REPEATING (RUN-AWAY) SCROLLING!
			$cw->highlightVisual;
		}
	} else {
		@r = $cw->SUPER::yview;
	}
	return @r;
}

sub see {
	my $cw = shift;
	my @r = $cw->SUPER::see(@_);
	$cw->highlightVisual;
	return @r
}

sub updateCall {
	my $cw = shift;
	my $call = $cw->cget('-updatecall');
	&$call;
	$nodoEvent = 0;
}

sub ViewMenuItems {
	my $cw = shift;
	my $s;
	tie $s,'Tk::Configure',$cw,'-syntax';
	my @stx = ('None', $cw->highlightPlugList);
	my @rad = (['command' => 'Reset', -command => sub {
		$cw->configure('-rules' => undef);
		$cw->highlightPlug;
	}]);
	foreach my $n (@stx) {
		push(@rad, [
			'radiobutton' => $n,
			-variable => \$s,
			-value => $n,
			-command => sub {
				$cw->configure('-rules' => undef);
				$cw->highlightPlug;
			}
		]);
	}
	my $dir = $cw->cget('-rulesdir');
	my $syntax = $cw->cget('-syntax');
	my $menuExt = \@{$cw->SUPER::ViewMenuItems};
	unless ($cw->cget('-noRulesMenu'))
	{
		push (@{$menuExt},
				['cascade'=>'Syntax',
					-menuitems => [@rad],
				])  unless ($cw->cget('-noSyntaxMenu'));
		push (@{$menuExt},
				['command'=>'Rules Editor',
					-command => sub { $cw->rulesEdit },
				])  unless ($cw->cget('-noRulesEditMenu'));
		push (@{$menuExt},
				['command'=>'Save Rules',
					-command => sub { $cw->rulesSave },
				])  if (!$cw->cget('-noSaveRulesMenu') && $dir 
						&& (-w $dir));
	}
	return $menuExt;
}

sub visualend {
	my $cw = shift;
	my $end = $cw->linenumber('end - 1 chars');
	my ($first, $last) = $cw->Tk::Text::yview;
	my $vend = int($last * $end) + 2;
	if ($vend > $end) {
		$vend = $end;
	}
	return $vend;
}

sub fetchKateInfo   #FETCH LISTS OF KATE LANGUAGES AND FILE EXTENSION PATTERNS W/O KATE:
{
	#IT IS NECESSARY TO FETCH THIS INFORMATION W/O USING KATE METHODS SINCE WE MAY NOT
	#HAVE CREATED A KATE OBJECT WHEN THIS IS NEEDED!
	#We return 3 hash-references:  1st can be passed to addkate2viewmenu() to add the 
	#Kate languages to the Syntax.View menu.  the keys are "Kate::language" and the 
	#values are what's needed to instantiate Kate for that language.  the 2nd is 
	#a list of file-extension pattern suitable for matching against file-names and 
	#the values are the reccomended Kate language for that file-extension.

	my $cw = shift;

	my (%sectionHash, %extHash, %syntaxHash);

	foreach my $i (@INC)
	{
		if (-e "$i/Syntax/Highlight/Engine/Kate.pm"
				&& open KATE, "$i/Syntax/Highlight/Engine/Kate.pm")
		{
			my $inExtensions = 0;
			my $inSyntaxes = 0;
			my $inSections = 0;
			while (<KATE>)
			{
				chomp;
				$inExtensions = 1  if (/\$self\-\>\{\'extensions\'\}\s*\=\s*\{/o);
				$inSections = 1  if  (/\$self\-\>\{\'sections\'\}\s*\=\s*\{/o);
				$inSyntaxes = 1  if  (/\$self\-\>\{\'syntaxes\'\}\s*\=\s*\{/o);
				if ($inSections)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[/o)
					{
						$inSections = $1;
						@{$sectionHash{$inSections}} = ();
					}
					elsif (/\'([^\']+)\'\s*\,/o)
					{
						push (@{$sectionHash{$inSections}}, $1);
					}
					elsif (/\}\;/o)
					{
						$inSections = 0;
					}
				}
				elsif ($inExtensions)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[\'([^\']+)\'/o)
					{
						my $one = '^'.$1.'$';
						my $two = $2;
						$one =~ s/\./\\\./o;
						$one =~ s/\*/\.\*/go;
						$extHash{$one} = "Kate::$two";
					}
					elsif (/\}\;/o)
					{
						$inExtensions = 0;
					}
				}
				elsif ($inSyntaxes)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[\'([^\']+)\'/o)
					{
						$syntaxHash{$1} = $2;
					}
					elsif (/\}\;/o)
					{
						$inSyntaxes = 0;
						close KATE;
						last;
					}
				}
			}
			close KATE;
			last;
		}
	}
	return (\%sectionHash, \%extHash, \%syntaxHash);
}

sub addKate2ViewMenu    #ADD ALL KATE-LANGUAGES AS OPTIONS TO THE "View" MENU:
{
	my $cw = shift;
	my $sectionHash = shift;

	return undef  if ($cw->cget('-noRulesMenu') || $cw->cget('-noSyntaxMenu'));

	my $ViewSyntaxMenu = $cw->menu->entrycget('View','-menu')->entrycget('Syntax','-menu');
	my $lastMenuIndex = $ViewSyntaxMenu->index('end');

	#WE MUST FETCH THE VARIABLE REFERENCE USED BY THE "View" MENU RADIO-BUTTONS SO 
	#THAT OUR NEW RADIO BUTTONS SHARE SAME VARIABLE (OTHERWISE, WILL HAVE >1 LIT AT
	#SAME TIME!

	my $var;
	my $kateIndx = 'end';
	foreach my $i (0..$lastMenuIndex)
	{
		if ($ViewSyntaxMenu->type($i) =~ /radiobutton/o)
		{
			$var = $ViewSyntaxMenu->entrycget($i, '-variable');
			tie $$var,'Tk::Configure',$cw,'-syntax';
			if ($ViewSyntaxMenu->entrycget($i, '-label') eq 'Kate')
			{
				$ViewSyntaxMenu->delete($i);   #REMOVE THE "Kate" ENTRY, SINCE WE'RE ADDING KATE STUFF SEPARATELY!
#UNCOMMENT TO INSERT KATE MENUS IN ALPHABETICAL ORDER IN VIEW MENU:				$kateIndx = $i;    #SAVE IT'S MENU-LOCATION SO WE CAN INSERT THE KATE MENU TREE THERE.
				last;
			}
		}
	}

	#NOW ADD OUR "KATE" RADIO-BUTTONS!

	my ($nextMenu, $menuTitle);
	foreach my $sect (sort keys %{$sectionHash})
	{
		$nextMenu = $ViewSyntaxMenu->Menu;
		foreach my $lang (@{$sectionHash->{$sect}})
		{
			$menuTitle = "Kate::$lang";
			$nextMenu->radiobutton( -label => $menuTitle,
					-variable => $var,
					-value => $menuTitle,
					-command => sub
			{
				$cw->configure('-rules' => undef);
				$cw->highlightPlug;
			}
			);
		}
		$ViewSyntaxMenu->insert($kateIndx, 'cascade', -label => "Kate: $sect...",
				-menu => $nextMenu);
		++$kateIndx  if ($kateIndx =~ /^\d/o);
	}
}

sub insertTab
{
	my ($w) = @_;
#	$w->Insert("\t");
	$w->Insert($w->cget('-indentchar'));
	$w->focus;
	$w->break
}

sub insertTabChar
{
	my ($w) = @_;
	$w->Insert("\t");
	$w->focus;
	$w->break
}

1;

__END__
