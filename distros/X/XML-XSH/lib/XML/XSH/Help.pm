# This file was automatically generated from src/xsh_grammar.xml on 
# Wed Sep 10 17:53:03 2003

package XML::XSH::Help;
use strict;
use vars qw($HELP %HELP);


$HELP=<<'END';
General notes:

  XSH acts as a command interpreter. Individual commands must be separated
  with a semicolon. Each command may be followed by a pipeline redirection
  to capture the command's output. In the interactive shell, backslash may
  be used at the end of line to indicate that the command follows on the
  next line.

  A pipeline redirections may be used either to feed the command's output
  to a unix command or to store it in a XSH string variable.

  In the first case, the syntax is `xsh-command | shell-command ;' where
  `xsh-command' is any XSH command and `shell-command' is any command (or
  code) recognized by the default shell interpreter of the operating system
  (i.e. on UNIX systems by `sh' or `csh', on Windows systems by `cmd').
  Brackets may be used to join more shell commands (may depend on which
  shell is used).

Example: Count attributes of words containing string foo in its name or
  value.

  xsh> ls //words/@* | grep foo | wc

  In order to store a command's output in a string variable, the pipeline
  redirection must take the form `xsh-command |> $variable' where
  `xsh-command' is any XSH command and `$variable' is any valid name for a
  string <variable>variable.

Example: Store the number of all words in a variable named count.

  xsh> count //words |> $count

  `<help> command' gives a list of all XSH commands.

  `<help> type' gives a list of all argument types.

  `<help>' followed by a command or type name gives more information on the
  particular command or argument type.

END

$HELP{'toc'}=[<<'END'];

Help items:
-----------

  toc - this page

  XSH Language Topics:

    Argtypes - Argument Types
    Configuration - Options
    Documents - Files/Documents
    Flow - Flow control
    Information - Retrieving more information
    Manipulation - Tree modification
    Navigation - Tree navigation
    Perl_shell - Interacting with Perl and Shell
    Variables - Variables

  XSH Commands:

    assign, backups, call, catalog, cd, clone, close, copy, count, create,
    debug, def, defs, doc-info, documents, dtd, empty-tags, enc, encoding,
    exec, exit, fold, foreach, help, if, ifinclude, include, indent,
    insert, iterate, keep-blanks, last, lcd, load-ext-dtd, local, locate,
    ls, map, move, namespaces, next, nobackups, nodebug, normalize, open,
    options, parser-completes-attributes, parser-expands-entities,
    parser-expands-xinclude, pedantic-parser, perl, prev, print,
    process-xinclude, pwd, query-encoding, quiet, recovering, redo,
    register-function, register-namespace, register-xhtml-namespace,
    register-xsh-namespace, remove, rename, return, run-mode, save, select,
    set-enc, set-standalone, skip-dtd, sort, stream, strip-whitespace,
    switch-to-new-documents, test-mode, throw, try, undef, unfold, unless,
    unregister-function, unregister-namespace, valid, validate, validation,
    variables, verbose, version, while, xcopy, xinsert, xmove,
    xpath-axis-completion, xpath-completion, xslt, xupdate

  XSH Argument Types:

    command-block, enc-string, expression, filename, id, location,
    node-type, perl-code, xpath

END

$HELP{'command'}=[<<'END'];
List of XSH commands

description:
	     assign, backups, call, catalog, cd, clone, close, copy, count,
	     create, debug, def, defs, doc-info, documents, dtd,
	     empty-tags, enc, encoding, exec, exit, fold, foreach, help,
	     if, ifinclude, include, indent, insert, iterate, keep-blanks,
	     last, lcd, load-ext-dtd, local, locate, ls, map, move,
	     namespaces, next, nobackups, nodebug, normalize, open,
	     options, parser-completes-attributes, parser-expands-entities,
	     parser-expands-xinclude, pedantic-parser, perl, prev, print,
	     process-xinclude, pwd, query-encoding, quiet, recovering,
	     redo, register-function, register-namespace,
	     register-xhtml-namespace, register-xsh-namespace, remove,
	     rename, return, run-mode, save, select, set-enc,
	     set-standalone, skip-dtd, sort, stream, strip-whitespace,
	     switch-to-new-documents, test-mode, throw, try, undef, unfold,
	     unless, unregister-function, unregister-namespace, valid,
	     validate, validation, variables, verbose, version, while,
	     xcopy, xinsert, xmove, xpath-axis-completion,
	     xpath-completion, xslt, xupdate

END


$HELP{'command-block'}=[<<'END'];
command-block argument type

description:
	     XSH command or a block of semicolon-separated commands
	     enclosed within curly brackets.

Example:     Count paragraphs in each chapter

             $i=0;
             foreach //chapter {
               $c=count(./para);
               $i=$i+1;
               print "$c paragraphs in chapter no.$i";
             }

END


$HELP{'type'}=[<<'END'];
List of command argument types

description:
	     command-block, enc-string, expression, filename, id, location,
	     node-type, perl-code, xpath

END


$HELP{'expression'}=[<<'END'];
expression argument type

description:
	     Expression is a string consisting of unquoted characters other
	     than whitespace or semicolon, single quote or double quote
	     characters or quoted characters of any kind (but see also
	     special case of expression - so called here-documents -
	     described below). Quoting means either preceding a single
	     character with a backslash or enclosing a part of the string
	     into single quotes '...' or double quotes "...". Quoting
	     characters are removed from the string so they must be quoted
	     themselves if they are a part of the expression: \\, \' or " '
	     ", \" or ' " '. Unquoted (sub)expressons and (sub)expressions
	     quoted with double-quotes are subject to variable, Perl, and
	     XPath expansions.

	     Variable expansion replaces substrings of the form $id or
	     ${id} with the value of the variable named $id, unless the '$'
	     sign is quoted.

	     Perl expansion evaluates every substring enclosed in between
	     `${{{' and `}}}' as a Perl expresson (in very much the same
	     way as the <perl> command) and replaces the whole thing with
	     the resulting value.

	     XPath interpolation evaluates every substring enclosed in
	     between `${{' and `}}' as an XPath expression (in very much
	     the same way as the <count> command) and substitutes the whole
	     thing with the resul.

	     For convenience, another kind XPath interpolation is performed
	     on expressions. It replaces any substring occuring between
	     `${(' and `)}' with a literal result of XPath evaluation of
	     the string. This means, that if the evaluation results in a
	     node-list, the textual content of its first node is
	     substituted rather than the number of nodes in the node-list
	     (as with `${{ ... }}').

Example:
             echo foo "bar"                        # prints: foo bar
             echo foo"bar"                         # prints: foobar
             echo foo'"bar"'                       # prints: foo"bar"
             echo foo"'b\\a\"r'"                   # prints: foo'b\a"r'
             $a="bar"
             echo foo$a                            # prints: foobar
             echo foo\$a                           # prints: foo$a
             echo '$a'                             # prints: '$a'
             echo "'$a'"                           # prints: 'bar'
             echo "${{//middle-earth/creatures}}"  # prints: 10
             echo '${{//middle-earth/creatures}}'  # prints: ${{//middle-earth/creatures}}
             echo ${{//creature[1]/@name}}         # !!! prints: 1
             echo ${(//creature[1]/@name)}         # prints: Bilbo
             echo ${{{ join(",",split(//,$a)) }}}  # prints: b,a,r

	     There is one more special type of expressions, so called
	     ``here-documents'' following syntax of similar constructs in
	     Bash and Perl. Following a `<<' you specify a string to
	     terminate the quoted material, and all lines following the
	     current line down to the terminating string are the value of
	     the expression. The terminating string is either quoted or
	     unquoted identifier (a word). If quoted, the type of quotes
	     you use determines the treatment of the text, just as in
	     regular quoting, i.e. in case of double quotes, the material
	     contained in the here-document is subject to variable, Perl,
	     and XPath expansions. An unquoted identifier works just like
	     double quotes. There must be no space between the `<<' and the
	     identifier. The terminating string must appear by itself
	     (unquoted and with no surrounding whitespace) on the
	     terminating line.

Example:
             $a="bar"
             echo foo <<END baz;
             xx $a yy
             END
             # prints foo xx bar yy baz
             echo foo <<"END" baz;
             xx $a yy
             END
             # same as above
             echo foo <<'END' baz;
             xx $a yy
             END
             # prints foo xx $a yy baz

END


$HELP{'enc-string'}=[<<'END'];
enc_string argument type

description:
	     An <expression> which interpolates to a valid encoding string,
	     e.g. to utf-8, utf-16, iso-8859-1, iso-8859-2, windows-1250
	     etc.

END


$HELP{'id'}=[<<'END'];
id argument type

description:
	     An identifier, that is, a string beginning with a letter or
	     underscore, and containing letters, underscores, and digits.

END


$HELP{'filename'}=[<<'END'];
Filename argument type

description:
	     An <expression> which interpolates to a valid file name or
	     URL.

END


$HELP{'xpath'}=[<<'END'];
XPath argument type

description:
	     XSH supports arbitrary XPath expression as defined in W3C
	     recommendation at http://www.w3.org/TR/xpath. (Nice
	     interactive XPath tutorials and references can be found at
	     http://www.zvon.org.) In XSH, XPath expressoin may be
	     optionally preceded with a document identifier followed by
	     colon (<id>:xpath). If no document identifier is given, the
	     current document is used.

	     As an extension, the following XPath extension functions are
	     defined in the XSH namespace:

	     `xsh:doc(id-string)' - returns a nodelist consisting of the
	     document node associated in XSH with an identifier given in
	     `id-string'.

	     `xsh:matches(match-string,regexp-string)' - returns `true' if
	     `match-string' matches the regular expression given in
	     `regexp-string'. Otherwise returns `false'.

	     `xsh:grep(node-set, regexp-string)' - returns a node set
	     consisting of nodes of the given `node-set' whose content (as
	     returned by the built-in XPath function `string()') matches
	     the regular expression given in `regexp-string'.

	     `xsh:same(node-set1, node-set2)' - returns `true' if the given
	     node sets both contain the same node (in XPath, this can also
	     be expressed as
	     `count(node-set1|node-set2)+count(node-set1)+count(node-set2)=
	     1').

Example:     Open a document and count all sections containing a subsection

             xsh scratch:/> open v = mydocument1.xml;
             xsh v:/> open k = mydocument2.xml;
             xsh k:/> count //section[subsection]; # searches k
             xsh k:/> count v://section[subsection]; # searches v

END


$HELP{'try'}=[<<'END'];
usage:       try <command-block> catch [[local] $<id>] <command-block>
             
description:
	     Execute <command-block> following the `try' keyword. If an
	     error or exception occures during the evaluation, execute the
	     `catch' <command-block>. If a variable follows `catch' and the
	     `try' block fails, an error message of the exception occured
	     is stored to the variable before the `catch' block is
	     executed. Optionally, the variable name may be preceded with
	     the keyword `local' in order to make the assignment local to
	     the `catch' block (see <local>).

	     The <throw> command and the equivalent perl construction `perl
	     { die "error message" }' allow user to throw custom
	     exceptions.

Example:     Handle parse errors

             try {
               open XML doc=$input;
             } catch {
               try {
                 echo "XML parser failed, trying HTML";
                 open HTML doc=$input;
               } catch local $error {
                 echo "Stopping due to errors: $error";
                 exit 1;
               }
             }

see also:     throw

END


$HELP{'if'}=[<<'END'];
usage:       if <xpath>|<perl-code> <command>
             if <xpath>|<perl-code>
    <command-block> [ elsif <command-block> ]* [ else <command-block> ]
             
description:
	     Execute <command-block> if a given <xpath> or <perl-code>
	     expression evaluates to a non-emtpty node-list, true
	     boolean-value, non-zero number or non-empty literal. If the
	     first test fails, check all possibly following `elsif'
	     conditions and execute the corresponding <command-block> for
	     the first one of them which is true. If none of them succeeds,
	     execute the `else' <command-block> (if any).

Example:     Display node type

             def node_type %n {
               foreach (%n) {
                 if ( . = self::* ) { # XPath trick to check if . is an element
                   echo 'element';
                 } elsif ( . = ../@* ) { # XPath trick to check if . is an attribute
                   echo 'attribute';
                 } elsif ( . = ../processing-instruction() ) {
                   echo 'pi';
                 } elsif ( . = ../text() ) {
                   echo 'text';
                 } elsif ( . = ../comment() ) {
                   echo 'comment'
                 } else { # well, this should not happen, but anyway, ...
                   echo 'unknown-type';
                 }
               }
             }

END


$HELP{'unless'}=[<<'END'];
usage:       unless <xpath>|<perl-code>
    <command>
             unless <xpath>|<perl-code>
    <command-block> [ else <command-block> ]
             
description:
	     Like if but negating the result of the expression.

see also:     if

END


$HELP{'while'}=[<<'END'];
usage:       while <xpath>|<perl-code> <command-block>
             
description:
	     Execute <command-block> as long as the given <xpath> or
	     <perl-code> expression evaluates to a non-emtpty node-list,
	     true boolean-value, non-zero number or non-empty literal.

Example:     The commands have the same results

             xsh> while /table/row remove /table/row[1];
             xsh> remove /table/row;

END


$HELP{'foreach'}=[<<'END'];
usage:       foreach <xpath>|<perl-code> 
    <command>|<command-block>
             
aliases:     for

description:
	     If the first argument is an <xpath> expression, execute the
	     command-block for each node matching the expression making it
	     temporarily the current node, so that all relative XPath
	     expressions are evaluated in its context.

	     If the first argument is a <perl-code>, it is evaluated and
	     the resulting perl-list is iterated setting the variable $__
	     (note that there are two underscores!) to be each element of
	     the list in turn. It works much like perl's foreach, except
	     that the variable used consists of two underscores.

Example:     Move all employee elements in a company element into a staff
	     subelement of the same company

             xsh> foreach //company xmove ./employee into ./staff;

Example:     List content of all XML files in current directory

             xsh> foreach { glob('*.xml') } { open f=$__; list f:/; }

END

$HELP{'for'}=$HELP{'foreach'};

$HELP{'undef'}=[<<'END'];
usage:       undef <expression>
             
aliases:     undefine

description:
	     This command can be used to undefine previously defined XSH
	     subroutines. The <expression> is evaluated as a Perl regular
	     expression. All subroutines whose names match are undefined.
	     Note, that like `def', all `undef' commands are processed
	     during the compilation of the source code, not at run-time, so
	     it doesn't matter how deep in the code is a `undef' command
	     nested.

Example:
             xsh> include my_defs.xsh
             xsh> call my_sub1 //foo;
             xsh> call my_sub2 //bar;
             xsh> undefine 'my_sub.*'
             xsh> # change/edit the definitions in my_defs.xsh and reload
             xsh> include my_defs.xsh

END

$HELP{'undefine'}=$HELP{'undef'};

$HELP{'def'}=[<<'END'];
usage:       def <id> [$<id> | %<id>]* <command-block>
         or
  def <id> [$<id> | %<id>]*;
             
aliases:     define

description:
	     Define a new XSH subroutine named <id>. The subroutine may
	     require zero or more parameters of nodelist or string type.
	     These are declared as a whitespace-separated list of (so
	     called) parametric variables (of nodelist or string type). The
	     body of the subroutine is specified as a <command-block>.
	     Note, that all subroutine declarations are processed during
	     the parsing and not at run-time, so it does not matter where
	     the subroutine is defined.

	     The routine can be later invoked using the <call> command
	     followed by the routine name and parameters. Nodelist
	     parameters must be given as an XPath expressions, and are
	     evaluated just before the subroutine's body is executed.
	     String parameters must be given as (string) <expression>s.
	     Resulting node-lists/strings are stored into the parametric
	     variables before the body is executed. These variables are
	     local to the subroutine's call tree (see also the <local>
	     command). If there is a global variable using the same name as
	     some parametric variable, the original value of the global
	     variable is replaced with the value of the parametric variable
	     for the time of the subroutine's run-time.

	     Note that subroutine has to be declared before it is called
	     with <call>. If you cannot do so, e.g. if you want to call a
	     subroutine recursively, you have to pre-declare the subroutine
	     using a `def' with no <command-block>. There may be only one
	     full declaration (and possibly one pre-declaration) of a
	     subroutine for one <id> and the declaration and
	     pre-declaration has to define the same number of arguments and
	     their types must match.

Example:
             def l3 %v {
               ls %v 3; # list given nodes upto depth 3
             }
             call l3 //chapter;

Example:     Commenting and un-commenting pieces of document

             def comment
                 %n      # nodes to move to comments
                 $mark   # maybe some handy mark to recognize such comments
             {
               foreach %n {
                 if ( . = ../@* ) {
                   echo "Warning: attribute nodes are not supported!";
                 } else {
                   echo "Commenting out:";
                   ls .;
                   local $node = "";
                   ls . |> $node;
                   add comment "$mark$node" replace .;
                 }
               }
             }
             
             def uncomment %n $mark {
               foreach %n {
                 if (. = ../comment()) { # is this node a comment node
                   local $string = substring-after(.,"$mark");
                   add chunk $string replace .;
                 } else {
                   echo "Warning: Ignoring non-comment node:";
                   ls . 0;
                 }
               }
             }
             
             
             # comment out all chapters with no paragraphs
             call comment //chapter[not(para)] "COMMENT-NOPARA";
             
             # uncomment all comments (may not always be valid!)
             $mark="COMMENT-NOPARA";
             call uncomment //comment()[starts-with(.,"$mark")] $mark;

see also:     call return local

END

$HELP{'define'}=$HELP{'def'};

$HELP{'assign'}=[<<'END'];
usage:       assign $<id>=<xpath>
             $<id>=<xpath>
             assign %<id>=<xpath>
             %<id>=<xpath>
             
description:
	     In the first two cases (where dollar sign appears) store the
	     result of evaluation of the <xpath> in a variable named $<id>.
	     In this case, <xpath> is evaluated in a simmilar way as in the
	     case of the <count>: if it results in a literal value this
	     value is used. If it results in a node-list, number of nodes
	     occuring in that node-list is used. Use the `string()' XPath
	     function to obtain a literal values in these cases.

Example:     String expressions

             xsh> $a=string(chapter/title)
             xsh> $b="hallo world"

Example:     Arithmetic expressions

             xsh> $a=5*100
             xsh> $a
             $a=500
             xsh> $a=(($a+5) div 10)
             xsh> $a
             $a=50.5

Example:     Counting nodes

             xsh> $a=//chapter
             xsh> $a
             $a=10
             xsh> %chapters=//chapter
             xsh> $a=%chapters
             xsh> $a
             $a=10

Example:     Some caveats of counting node-lists

             xsh> ls ./creature
             <creature race='hobbit' name="Bilbo"/>
             
             ## WRONG (@name results in a singleton node-list) !!!
             xsh> $name=@name
             xsh> $name
             $name=1
             
             ## CORRECT (use string() function)
             xsh> $name=string(@name)
             xsh> $name
             $name=Bilbo

	     In the other two cases (where percent sign appears) find all
	     nodes matching a given <xpath> and store the resulting
	     node-list in the variable named %<id>. The variable may be
	     later used instead of an XPath expression.

see also:     variables

END


$HELP{'local'}=[<<'END'];
usage:       local $<id> = <xpath>
             local %<id> = <xpath>
             local $<id>|%<id> [ $<id>|%<id> ... ]
             
description:
	     This command acts in a very similar way as <assign> does,
	     except that the variable assignment is done temporarily and
	     lasts only for the rest of the nearest enclosing
	     <command-block>. At the end of the enclosing block or
	     subroutine the original value is restored. This command may
	     also be used without the assignment part and assignments may
	     be done later using the usual <assign> command.

	     Note, that the variable itself is not lexically is still
	     global in the sense that it is still visible to any subroutine
	     called subsequently from within the same block. A local just
	     gives temporary values to global (meaning package) variables.
	     Unlike Perl's `my' declarations it does not create a local
	     variable. This is known as dynamic scoping. Lexical scoping is
	     not implemented in XSH.

	     To sum up for Perl programmers: `local' in XSH works exactly
	     the same as `local' in Perl.

see also:     assign def

END


$HELP{'options'}=[<<'END'];
usage:       options
             
aliases:     flags

description:
	     List current values of all XSH flags and options (such as
	     validation flag or query-encoding).

Example:     Store current settings in your .xshrc

             xsh> options | cat > ~/.xshrc

END

$HELP{'flags'}=$HELP{'options'};

$HELP{'defs'}=[<<'END'];
usage:       defs
             
description:
	     List names and parametric variables for all defined XSH
	     routines.

see also:     def variables

END


$HELP{'ifinclude'}=[<<'END'];
usage:       ifinclude <filename>
             
description:
	     Include a file named <filename> and execute all XSH commands
	     therein unless the file was already included using either
	     <include> of <ifinclude>.

see also:     include

END


$HELP{'include'}=[<<'END'];
usage:       include <filename>
             
aliases:     .

description:
	     Include a file named <filename> and execute all XSH commands
	     therein.

see also:     ifinclude

END

$HELP{'.'}=$HELP{'include'};

$HELP{'call'}=[<<'END'];
usage:       call <id> [<xpath> | <expression>]*
             
description:
	     Call an XSH subroutine named <id> previously created using
	     def. If the subroutine requires some paramters, these have to
	     be specified after the <id>. Node-list parameters are given by
	     means of <xpath> expressions. String parameters have to be
	     string <expression>s.

see also:     def return

END


$HELP{'help'}=[<<'END'];
usage:       help <command>|argument-type
             
aliases:     ?

description:
	     Print help on a given command or argument type.

END

$HELP{'?'}=$HELP{'help'};

$HELP{'exec'}=[<<'END'];
usage:       exec <expression> [<expression> ...]
             
aliases:     system

description:
	     execute the system command(s) in <expression>s.

Example:     Count words in "hallo wold" string, then print name of your
	     machine's operating system.

             exec echo hallo world;                 # prints hallo world
             exec "echo hallo word" | wc; # counts words in hallo world
             exec uname;                            # prints operating system name

END

$HELP{'system'}=$HELP{'exec'};

$HELP{'xslt'}=[<<'END'];
usage:       xslt <id> <filename> <id> [(params|parameters) name=<expression> [name=<expression> ...]]
             
aliases:     transform xsl xsltproc process

description:
	     Load an XSLT stylesheet from a file and use it to transform
	     the document of the first <id> into a new document named <id>.
	     Parameters may be passed to a stylesheet after params keyword
	     in the form of a list of name=value pairs where name is the
	     parameter name and value is an <expression> interpolating to
	     its value. The resulting value is interpretted by XSLT
	     processor as an XPath expression so e.g. quotes surrounding a
	     XPath string have to be quoted themselves to preveserve them
	     during the XSH expression interpolation.

Example:
             xslt src stylesheet.xsl rslt params font="'14pt'" color="'red'"

END

$HELP{'transform'}=$HELP{'xslt'};
$HELP{'xsl'}=$HELP{'xslt'};
$HELP{'xsltproc'}=$HELP{'xslt'};
$HELP{'process'}=$HELP{'xslt'};

$HELP{'documents'}=[<<'END'];
usage:       files
             
aliases:     files docs

description:
	     List open files and their identifiers.

see also:     open close

END

$HELP{'files'}=$HELP{'documents'};
$HELP{'docs'}=$HELP{'documents'};

$HELP{'variables'}=[<<'END'];
usage:       variables
             
aliases:     vars var

description:
	     List all defined variables and their values.

see also:     documents defs

END

$HELP{'vars'}=$HELP{'variables'};
$HELP{'var'}=$HELP{'variables'};

$HELP{'copy'}=[<<'END'];
usage:       copy <xpath> <location> <xpath>
             
aliases:     cp

description:
	     Copies nodes matching the first <xpath> to the destinations
	     determined by the <location> directive relative to the second
	     <xpath>. If more than one node matches the first <xpath> than
	     it is copied to the position relative to the corresponding
	     node matched by the second <xpath> according to the order in
	     which are nodes matched. Thus, the n'th node matching the
	     first <xpath> is copied to the location relative to the n'th
	     node matching the second <xpath>.

	     The possible values for <location> are: after, before, into,
	     replace and cause copying the source nodes after, before, into
	     (as the last child-node). the destination nodes. If replace
	     <location> is used, the source node is copied before the
	     destination node and the destination node is removed.

	     Some kind of type conversion is used when the types of the
	     source and destination nodes are not equal. Thus, text, cdata,
	     comment or processing instruction node data prepend, append or
	     replace value of a destination attribute when copied
	     before,after/into or instead (replace) an attribute, and vice
	     versa.

	     Attributes may be copied after, before or into some other
	     attribute to append, prepend or replace the destination
	     attribute value. They may also replace the destination
	     attribute completely (both its name and value). To copy an
	     attribute from one element to another, simply copy the
	     attribute node into the destination element.

	     Elements may be copied into other elements (which results in
	     appending the child-list of the destination element), or
	     before, after or instead (replace) other nodes of any type
	     except attributes.

Example:     Replace living-thing elements in the document b with the
	     coresponding creature elements of the document a.

             xsh> copy a://creature replace b://living-thing

END

$HELP{'cp'}=$HELP{'copy'};

$HELP{'xcopy'}=[<<'END'];
usage:       xcopy <xpath> <location> <xpath>
             
aliases:     xcp

description:
	     xcopy is similar to <copy>, but copies *all* nodes matching
	     the first <xpath> to *all* destinations determined by the
	     <location> directive relative to the second <xpath>. See
	     <copy> for detailed description of `xcopy' arguments.

Example:     Copy all middle-earth creatures within the document a into
	     every world of the document b.

             xsh> xcopy a:/middle-earth/creature into b://world

END

$HELP{'xcp'}=$HELP{'xcopy'};

$HELP{'lcd'}=[<<'END'];
usage:       lcd <expression>
             
aliases:     chdir

description:
	     Changes the filesystem working directory to <expression>, if
	     possible. If <expression> is omitted, changes to the directory
	     specified in HOME environment variable, if set; if not,
	     changes to the directory specified by LOGDIR environment
	     variable.

END

$HELP{'chdir'}=$HELP{'lcd'};

$HELP{'insert'}=[<<'END'];
usage:       insert <node-type> <expression> [namespace <expression>] <location> <xpath>
             
aliases:     add

description:
	     Works just like xadd, except that the new node is attached
	     only the first node matched.

see also:     xinsert move xmove

END

$HELP{'add'}=$HELP{'insert'};

$HELP{'xinsert'}=[<<'END'];
usage:       xinsert <node-type> <expression> [namespace <expression>] <location> <xpath>
             
aliases:     xadd

description:
	     Use the <expression> to create a new node of a given
	     <node-type> in the <location> relative to the given <xpath>.

	     For element nodes, the format of the <expression> should look
	     like "<element-name att-name='attvalue' ...>". The `<' and `>'
	     characters are optional. If no attributes are used, the
	     expression may simply consist the element name. Note, that in
	     the first case, the quotes are required since the expression
	     contains spaces.

	     Attribute nodes use the following syntax: "att-name='attvalue'
	     [...]".

	     For the other types of nodes (text, cdata, comments) the
	     expression should contain the node's literal content. Again,
	     it is necessary to quote all whitespace and special characters
	     as in any expression argument.

	     The <location> argument should be one of: `after', `before',
	     `into', `replace', `append' or `prepend'. See documentation of
	     the <location> argument type for more detail.

	     The namespace <expression> is only valid for elements and
	     attributes and must evaluate to the namespace URI. In that
	     case, the element or attribute name must have a prefix. The
	     created node is associated with a given namespace.

Example:     Append a new Hobbit element to the list of middle-earth
	     creatures and name him Bilbo.

             xsh> xadd element "<creature race='hobbit' manner='good'>" \
                              into /middle-earth/creatures
             xsh> xadd attribute "name='Bilbo'" \
                              into /middle-earth/creatures/creature[@race='hobbit'][last()]

see also:     insert move xmove

END

$HELP{'xadd'}=$HELP{'xinsert'};

$HELP{'node-type'}=[<<'END'];
Node-type argument type

description:
	     One of: element, attribute, text, cdata, comment, chunk and
	     (EXPERIMENTALLY!) entity_reference. A chunk is a character
	     string which forms a well-balanced peace of XML.

Example:
             add element hobbit into //middle-earth/creatures;
             add attribute 'name="Bilbo"' into //middle-earth/creatures/hobbit[last()];
             add chunk '<hobbit name="Frodo">A small guy from <place>Shire</place>.</hobbit>' 
               into //middle-earth/creatures;

END


$HELP{'location'}=[<<'END'];
Location argument type

description:
	     One of: `after', `before', `into', `append', `prepend',
	     `replace'.

	     NOTE: XSH 1.6 introduces two new values for location argument:
	     `append' and `prepend' and slighlty changes behavior of
	     `after' and `before'!

	     This argument is required by all commands that insert nodes to
	     a document in some way to a destination described by an XPath
	     expression. The meaning of the values listed above is supposed
	     be obvious in most cases, however the exact semantics for
	     location argument values depends on types of both the source
	     node and the target node.

	     `after/before' place the node right after/before the
	     destination node, except for when the destination node is a
	     document node or one of the source nodes is an attribute: If
	     the destination node is a document node, the source node is
	     attached to the end/beginning of the document (remember: there
	     is no "after/before a document"). If both the source and
	     destination nodes are attributes, then the source node is
	     simply attached to the element containing the destination node
	     (remember: there is no order on attribute nodes). If the
	     destination node is an attribute but the source node is of a
	     different type, then the textual content of the source node is
	     appended to the value of the destination attribute (i.e. in
	     this case after/before act just as append/prepend).

	     `append/prepend' appends/prepends the source node to the
	     destination node. If the destination node can contain other
	     nodes (i.e. it is an element or a document node) then the
	     entire source node is attached to it. In case of other
	     destination node types, the textual content of the source node
	     is appended/prepended to the content of the destination node.

	     `into' can also be used to place the source node to the end of
	     an element (in the same way as `append'), to attach an
	     attribute to an element, or, if the destination node is a text
	     node, cdata section, processing-instruction, attribute or
	     comment, to replace its textual content with the textual
	     content of the source node.

	     `replace' replaces the entire destination node with the source
	     node except for the case when the destination node is an
	     attribute and the source node is not. In such a case only the
	     value of the destination attribute is replaced with the
	     textual content of the source node. Note also that document
	     node can never be replaced.

END


$HELP{'move'}=[<<'END'];
usage:       move <xpath> <location> <xpath>
             
aliases:     mv

description:
	     `move' command acts exactly like <copy>, except that it
	     removes the source nodes after a succesfull copy. Remember
	     that the moved nodes are actually different nodes from the
	     original ones (which may not be obvious when moving nodes
	     within a single document into locations that do not require
	     type conversion). So, after the move, the original nodes do
	     not exist neither in the document itself nor any nodelist
	     variable.

	     See <copy> for more details on how the copies of the moved
	     nodes are created.

see also:     copy xmove insert xinsert

END

$HELP{'mv'}=$HELP{'move'};

$HELP{'xmove'}=[<<'END'];
usage:       xmove <xpath> <location> <xpath>
             
aliases:     xmv

description:
	     Like <xcopy>, except that `xmove' removes the source nodes
	     after a succesfull copy. Remember that the moved nodes are
	     actually different nodes from the original ones (which may not
	     be obvious when moving nodes within a single document into
	     locations that do not require type conversion). So, after the
	     move, the original nodes do not exist neither in the document
	     itself nor any nodelist variable.

	     See <xcopy> for more details on how the copies of the moved
	     nodes are created.

	     The following example demonstrates how `xcopy' can be used to
	     get rid of HTML `<font>' elements while preserving their
	     content. As an exercise, try to find out why simple `foreach
	     //font { xmove node() replace . }' would not work here.

Example:     Get rid of all <font> tags

             while //font[1] {
               foreach //font[1] {
                 xmove ./node() replace .;
               }
             }

see also:     xcopy move insert xinsert

END

$HELP{'xmv'}=$HELP{'xmove'};

$HELP{'clone'}=[<<'END'];
usage:       clone <id>=<id>
             
aliases:     dup

description:
	     Make a copy of the document identified by the <id> following
	     the equal sign assigning it the identifier of the first <id>.

see also:     open close enc documents

END

$HELP{'dup'}=$HELP{'clone'};

$HELP{'normalize'}=[<<'END'];
usage:       normalize <xpath>
             
description:
	     `normalize' puts all text nodes in the full depth of the
	     sub-tree underneath each node selected by a given <xpath>,
	     into a "normal" form where only structure (e.g., elements,
	     comments, processing instructions, CDATA sections, and entity
	     references) separates text nodes, i.e., there are neither
	     adjacent Text nodes nor empty Text nodes.

END


$HELP{'strip-whitespace'}=[<<'END'];
usage:       strip <xpath>
             
aliases:     strip_whitespace

description:
	     `strip-whitespace' removes all leading and trailing whitespace
	     from given nodes. If applied to an element node, it removes
	     all leading and trailing child text nodes and CDATA sections
	     that consist entirely of whitespace.

END

$HELP{'strip_whitespace'}=$HELP{'strip-whitespace'};

$HELP{'ls'}=[<<'END'];
usage:       ls <xpath> [<expression>]
             
aliases:     list

description:
	     List the XML representation of all nodes matching <xpath>. The
	     optional <expression> argument may be provided to specify the
	     depth of XML tree listing. If negative, the tree will be
	     listed to unlimited depth. If the <expression> results in the
	     word `fold', elements marked with the <fold> command are
	     folded, i.e. listed only to a certain depth (this feature is
	     still EXPERIMENTAL!).

	     Unless in quiet mode, this command prints also number of nodes
	     matched on stderr.

	     If the <xpath> parameter is omitted, current context node is
	     listed to the depth of 1.

see also:     count fold unfold

END

$HELP{'list'}=$HELP{'ls'};

$HELP{'count'}=[<<'END'];
usage:       count <xpath>
             
aliases:     print_value get

description:
	     Calculate a given <xpath> expression. If the result is a
	     node-list, return number of nodes in the node-list. If the
	     <xpath> results in a boolean, numeric or literal value, return
	     the value.

END

$HELP{'print_value'}=$HELP{'count'};
$HELP{'get'}=$HELP{'count'};

$HELP{'perl-code'}=[<<'END'];
Perl-code argument type

description:
	     A block of perl code enclosed in curly brackets or an
	     expression which interpolates to a perl expression. Variables
	     defined in XSH are visible in perl code as well. Since, in the
	     interactive mode, XSH redirects output to the terminal, you
	     cannot simply use perl print function for output if you want
	     to filter the result with a shell command. Instead use the
	     predefined perl routine `echo(...)' which is equivalent to
	     Perl's `print $::OUT ...'. The `$::OUT' perl-variable stores
	     the reference to the terminal file handle.

	     For more information about embedded Perl code in XSH,
	     predefined functions etc. see <Perl_shell>.

Example:
             xsh> $i="foo";
             xsh> eval { echo "$i-bar\n"; } # prints foo-bar
             xsh> eval 'echo "\$i-bar\n";'  # exactly the same as above
             xsh> eval 'echo "$i-bar\n";'   # prints foo-bar too, but $i is
                 # interpolated by XSH. Perl actually evaluates echo "foo-bar\n";

END


$HELP{'perl'}=[<<'END'];
usage:       eval <perl-code>
             
aliases:     eval

description:
	     Evaluate a given perl expression.

see also:     count

END

$HELP{'eval'}=$HELP{'perl'};

$HELP{'remove'}=[<<'END'];
usage:       remove <xpath>
             
aliases:     rm prune delete del

description:
	     Remove all nodes matching <xpath>.

Example:     Get rid of all evil creatures.

             xsh> del //creature[@manner='evil']

END

$HELP{'rm'}=$HELP{'remove'};
$HELP{'prune'}=$HELP{'remove'};
$HELP{'delete'}=$HELP{'remove'};
$HELP{'del'}=$HELP{'remove'};

$HELP{'print'}=[<<'END'];
usage:       print <expression> [<expression> ...]
             
aliases:     echo

description:
	     Interpolate and print a given expression(s).

END

$HELP{'echo'}=$HELP{'print'};

$HELP{'sort'}=[<<'END'];
usage:       sort <xpath>|<perl-code> <perl-code> %<id>
             
description:
	     EXPERIMENTAL! This command is not yet guaranteed to remain in
	     the future releases.

	     DOCUMENTATION OBSOLETE! Syntax changed!

	     This command may be used to sort the node-list stored in the
	     node-list variable <id>. First, for each node in the node-list
	     %<id>, the first argument (either a <xpath> or <perl-code>
	     expression), which serves as a sorting criterion, is evaluated
	     in the context of the node and the obtained value is stored
	     together with the node. (In case of <xpath> the result of
	     whatever type is cast to a string). Then perl's sorting
	     algorithm is used to sort the nodelist, consulting the second,
	     <perl-code>, argument to compare nodes. Before the <perl-code>
	     is evaluated, the values obtained from the previous evaluation
	     of the sorting crierion argument on the two nodes being
	     compared are stored into `$a' and `$b' variables in the
	     respective order. The <perl-code> being consulted is supposed
	     to return either -1 (the first node should come first), 0 (no
	     order precedence), or 1 (the second node should come first).
	     Note that Perl provides very convenient operators `cmp' and
	     `<=>' for string and numeric comparison of this kind as shown
	     in the examples below.

	     Remember that `sort' (unlike <assign>, <if>, or <while>)
	     evaluates the first <xpath> argument (the sorting criterion)
	     in a way to obtain a string. Thus you need not to bother with
	     wrapping node-queries with a `string()' function but you must
	     remember to explicitly wrap the expression in `count()' if the
	     number of the nodes is to be the sorting criterion.

Example:     Sort creatures by name (XPath-based sort) in ascending order
	     using current locale settings

             xsh> local %c=/middle-earth[1]/creatures
             xsh> sort @name { use locale; lc($a) cmp lc($b) } %c
             xsh> xmove %c into /middle-earth[1]# replaces the creatures

Example:     Sort (descending order) a node-list by score (Perl-based sort)

             xsh> sort { $scores{ literal('@name') } } { $b <=> $a } %players

END


$HELP{'map'}=[<<'END'];
usage:       map <perl-code> <xpath>
             
aliases:     sed

description:
	     This command provides an easy way to modify node's data
	     (content) using arbitrary Perl code.

	     Each of the nodes matching <xpath> is passes its data to the
	     <perl-code> via the `$_' variable and receives the (possibly)
	     modified data using the same variable.

	     Since element nodes do not really have any proper content
	     (they are only a storage for other nodes), node's name (tag)
	     is used in case of elements. Note, however, that recent
	     versions of XSH provide a special command <rename> with a very
	     similar syntax to `map', that should be used for renaming
	     element, attribute, and processing instruction nodes.

Example:     Capitalises all hobbit names

             xsh> map { $_=ucfirst($_) } //hobbit/@name

Example:     Changes goblins to orcs in all hobbit tales.

             xsh> map { s/goblin/orc/gi } //hobbit/tale/text()

END

$HELP{'sed'}=$HELP{'map'};

$HELP{'rename'}=[<<'END'];
usage:       rename <perl-code> <xpath>
             
description:
	     This command is very similar to the <map> command, except that
	     it operates on nodes' names rather than their data/values. For
	     every element, attribute or processing-instruction matched by
	     the <xpath> expression the following procedure is used: 1) the
	     name of the node is stored into Perl's `$_' variable, 2) the
	     <perl-code> is evaluated, and 3) the (posibly changed) content
	     of the `$_' variable is used as a new name for the node.

Example:     Renames all hobbits to halflings

             xsh> map $_='halfling' //hobbit

Example:     Make all elements and attributes uppercase

             xsh> map { $_=uc($_) } (//*|//@*)

see also:     map

END


$HELP{'close'}=[<<'END'];
usage:       close [<id>]
             
description:
	     Close the document identified by <id>, removing its parse-tree
	     from memory (note also that all nodes belonging to the
	     document are removed from all nodelists they appear in). If
	     <id> is omitted, the command closes the current document.

END


$HELP{'select'}=[<<'END'];
usage:       select <id>
             
description:
	     Make <id> the document identifier to be used in the next xpath
	     evaluation without identifier prefix.

Example:
             xsh> a=mydoc1.xml       # opens and selects a
             xsh> ls /               # lists a
             xsh> b=mydoc2.xml       # opens and selects b
             xsh> ls /               # lists b
             xsh> ls a:/             # lists and selects a
             xsh> select b           # does nothing except selecting b
             xsh> ls /               # lists b

END


$HELP{'open'}=[<<'END'];
usage:       [open [HTML|XML|DOCBOOK] [FILE|PIPE|STRING]] <id>=<expression>
             
description:
	     Load a new XML, HTML or SGML DOCBOOK document from the file
	     (actually arbitrary URL), command output or string provided by
	     the <expression>. In XSH the document is given a symbolic name
	     <id>. To identify the documentin commands like close, save,
	     validate, dtd or enc simply use <id>. In commands which work
	     on document nodes, give <id>: prefix to XPath expressions to
	     point the XPath to the document.

Example:
             xsh> open x=mydoc.xml # open a document
             
             # open a HTML document from the Internet
             xsh> open HTML h="http://www.google.com/?q=xsh"
             # quote file name if it contains whitespace
             xsh> open y="document with a long name with spaces.xml"
             
             # you may omit the word open when loading an XML file/URI.
             xsh> z=mybook.xml
             
             # use HTML or DOCBOOK keywords to load these types
             xsh> open HTML z=index.htm
             
             # use PIPE keyword to read output of a command
             xsh> open HTML PIPE z='wget -O - xsh.sourceforge.net/index.html'
             
             # use z: prefix to identify the document opened with the
             # previous comand in an XPath expression.
             xsh> ls z://chapter/title

END


$HELP{'create'}=[<<'END'];
usage:       create <id> <expression>
             
aliases:     new

description:
	     Create a new document using <expression> to form the root
	     element and associate it with a given identifier.

Example:
             xsh> create t1 root
             xsh> ls /
             <?xml version="1.0" encoding="utf-8"?>
             <root/>
             
             xsh> create t2 "<root id='r0'>Just a <b>test</b></root>"
             xsh> ls /
             <?xml version="1.0" encoding="utf-8"?>
             <root id='r0'>Just a <b>test</b></root>
             xsh> files
             scratch = new_document.xml
             t1 = new_document1.xml
             t2 = new_document2.xml

see also:     open clone

END

$HELP{'new'}=$HELP{'create'};

$HELP{'save'}=[<<'END'];
usage:       save [HTML|XML|XInclude] [FILE|PIPE|STRING] <id> <expression> [encoding <enc-string>]
or
    save <id>
or
    save
             
description:
	     Save the document identified by <id>. Using one of the `FILE',
	     `PIPE', `STRING' keywords the user may choose to save the
	     document to a file send it to a given command's input via a
	     pipe or simply return its content as a string. If none of the
	     keywords is used, it defaults to FILE. If saving to a PIPE,
	     the <expression> argument must provide the coresponding
	     command and all its parameters. If saving to a FILE, the
	     <expression> argument may provide a filename; if omitted, it
	     defaults to the original filename of the document. If saving
	     to a STRING, the <expression> argument is ignored and may
	     freely be omitted.

	     The output format is controlled using one of the XML, HTML,
	     XInclude keywords (see below). If the format keyword is
	     ommited, save it defaults to XML.

	     Note, that a document should be saved as HTML only if it
	     actually is a HTML document. Note also, that the optional
	     encoding parameter forces character conversion only; it is up
	     to the user to declare the document encoding in the
	     appropriate HTML <META> tag.

	     The XInclude keyword automatically implies XML format and can
	     be used to force XSH to save all already expanded XInclude
	     sections back to their original files while replacing them
	     with <xi:include> tags in the main XML file. Moreover, all
	     material included within <include> elements from the
	     http://www.w3.org/2001/XInclude namespace is saved to separate
	     files too according to the `href' attribute, leaving only
	     empty <include> element in the root file. This feature may be
	     used to split the document to new XInclude fragments.

	     The encoding keyword followed by a <enc-string> can be used to
	     convert the document from its original encoding to a different
	     encoding. In case of XML output, the <?xml?> declaration is
	     changed accordingly. The new encoding is also set as the
	     document encoding for the particular document.

Example:     Use save to preview a HTML document in Lynx

             save HTML PIPE mydoc 'lynx -stdin'

see also:     open close enc documents

END


$HELP{'dtd'}=[<<'END'];
usage:       dtd [<id>]
             
description:
	     Print external or internal DTD for a given document. If no
	     document identifier is given, the current document is used.

see also:     valid validate

END


$HELP{'set-enc'}=[<<'END'];
usage:       set-enc <enc-string> [<id>]
             
description:
	     Changes character encoding of a given document. If no document
	     <id> is given, the command applies to the current document.
	     This has two effects: changing the XMLDecl encoding
	     declaration in the document prolog to display the new encoding
	     and making all future <save> operations on the document
	     default to the given charset.

Example:
             xsh> ls
             <?xml version="1.0" encoding="iso-8859-1"?>
             <foo>...</foo>
             xsh> set-enc "utf-8"
             xsh> ls
             <?xml version="1.0" encoding="utf-8"?>
             <foo>...</foo>
             xsh> save # saves the file in UTF-8 encoding

see also:     enc doc-info

END


$HELP{'set-standalone'}=[<<'END'];
usage:       set-standalone <expression> [<id>]
             
description:
	     Changes the value of `standalone' declaration in the XMLDecl
	     prolog of a document. The <expression> should evaluate to
	     either 1 or 0 or `'yes'' or `'no''. The result of applying the
	     command on other values is not specified. If no document <id>
	     is given, the command applies to the current document.

see also:     doc-info

END


$HELP{'enc'}=[<<'END'];
usage:       enc [<id>]
             
description:
	     Print the original document encoding string. If no document
	     identifier is given, the current document is used.

see also:     set-enc

END


$HELP{'validate'}=[<<'END'];
usage:       validate [<id>]
or
validate DTD PUBLIC <expression> [SYSTEM <filename>] <id>
or
validate (DTD|RelaxNG|XSD) FILE <filename> [<id>]
or
validate (DTD|RelaxNG|XSD) STRING <filename> [<id>]
or
validate (RelaxNG|XSD) DOC <id> [<id>]
             
description:
	     This command validates the document identified with <id>
	     against a DTD, RelaxNG or XSD schema and report all validity
	     errors. If no document identifier is given, the current
	     document is used. A DTD can be specified either by its PUBLIC
	     or SYSTEM identifier (or both), or as a STRING. RelaxNG and
	     XSD schemas can be specified either as a filename or url (FILE
	     <filename>), as a string (STRING <expression>), or as a XSH
	     document (DOC <id>). If no schema is specified, validation is
	     performed against the internal or external DTD subset of the
	     document being validated.

Example:
             open mydoc="test.xml"
             # in all examples below, mydoc can be ommited
             validate mydoc; # validate against the documet's DOCTYPE
             validate DTD PUBLIC "-//OASIS//DTD DocBook XML V4.1.2//EN" mydoc
             validate DTD SYSTEM "http://www.oasis-open.org/docbook/xml/4.1.2/docbookx.dtd" mydoc
             validate DTD FILE "http://www.oasis-open.org/docbook/xml/4.1.2/docbookx.dtd" mydoc

Example:
             validate RelaxNG FILE "test.rng" mydoc
             validate RelaxNG STRING $relaxschema mydoc
             open rng="test.rng"
             validate RelaxNG DOC rng mydoc

Example:
             validate XSD FILE "test.xsd" mydoc
             validate XSD STRING $xsdschema mydoc
             open xsd="test.xsd"
             validate XSD DOC xsd mydoc

see also:     valid dtd

END


$HELP{'valid'}=[<<'END'];
usage:       valid [validation-scheme] [<id>]
             
description:
	     Check and report the validity of the document <id> with
	     respect to a DTD, RelaxNG, or XSD schemas specified in
	     `validation-scheme' (see <validate> for information, on how
	     `validation-scheme' may be specified). Prints "yes" if the
	     document is valid and "no" otherwise. If no document
	     identifier is given, the current document is used. If no
	     `validation-scheme' is specified, the validity against the DTD
	     subset is checked.

see also:     validate dtd

END


$HELP{'exit'}=[<<'END'];
usage:       exit [<expression>]
             
aliases:     quit

description:
	     Exit xsh immediately, optionally with the exit-code resulting
	     from a given expression.

	     WARNING: No files are saved on exit.

END

$HELP{'quit'}=$HELP{'exit'};

$HELP{'process-xinclude'}=[<<'END'];
usage:       process_xinclude [<id>]
             
aliases:     process_xinclude process-xincludes process_xincludes xinclude xincludes load_xincludes load-xincludes load_xinclude load-xinclude

description:
	     Process any xinclude tags in the document <id>.

see also:     parser-expands-xinclude

END

$HELP{'process_xinclude'}=$HELP{'process-xinclude'};
$HELP{'process-xincludes'}=$HELP{'process-xinclude'};
$HELP{'process_xincludes'}=$HELP{'process-xinclude'};
$HELP{'xinclude'}=$HELP{'process-xinclude'};
$HELP{'xincludes'}=$HELP{'process-xinclude'};
$HELP{'load_xincludes'}=$HELP{'process-xinclude'};
$HELP{'load-xincludes'}=$HELP{'process-xinclude'};
$HELP{'load_xinclude'}=$HELP{'process-xinclude'};
$HELP{'load-xinclude'}=$HELP{'process-xinclude'};

$HELP{'cd'}=[<<'END'];
usage:       cd [<xpath>]
             
aliases:     chxpath

description:
	     Change current context node (and current document) to the
	     first node matching a given <xpath> argument.

END

$HELP{'chxpath'}=$HELP{'cd'};

$HELP{'pwd'}=[<<'END'];
usage:       pwd
             
description:
	     Print XPath leading to the current context node. This is
	     equivalent to `locate .'.

see also:     locate

END


$HELP{'locate'}=[<<'END'];
usage:       locate <xpath>
             
description:
	     Print canonical XPaths leading to nodes matched by a given
	     <xpath>.

see also:     pwd

END


$HELP{'xupdate'}=[<<'END'];
usage:       xupdate <id> [<id>]
             
description:
	     Modify the current document or the document specified by the
	     second <id> argument according to XUpdate commands of the
	     first <id> document. XUpdate is a XML Update Language which
	     aims to be a language for updating XML documents.

	     XUpdate langauge is described in XUpdate Working Draft at
	     http://www.xmldb.org/xupdate/xupdate-wd.html.

	     XUpdate output can be generated for example by Python xmldiff
	     utility from http://www.logilab.org/xmldiff/. Unfortunatelly,
	     there are few bugs (or, as I tend to say In case of Python,
	     white-space problems) in their code, so its XUpdate output is
	     not always correct.

END


$HELP{'verbose'}=[<<'END'];
usage:       verbose
             
description:
	     Turn on verbose messages (default).

	     This is equivalent to setting `$QUIET' variable to 0.

see also:     quiet

END


$HELP{'test-mode'}=[<<'END'];
usage:       test-mode
             
aliases:     test_mode

description:
	     Switch into test mode in which no commands are actually
	     executed and only command syntax is checked.

	     This is equivalent to setting `$TEST_MODE' variable to 1.

see also:     run-mode

END

$HELP{'test_mode'}=$HELP{'test-mode'};

$HELP{'run-mode'}=[<<'END'];
usage:       run-mode
             
aliases:     run_mode

description:
	     Switch into normal XSH mode in which all commands are
	     executed.

	     This is equivalent to setting `$TEST_MODE' variable to 0.

see also:     test-mode

END

$HELP{'run_mode'}=$HELP{'run-mode'};

$HELP{'debug'}=[<<'END'];
usage:       debug
             
description:
	     Turn on debugging messages.

	     This is equivalent to setting `$DEBUG' variable to 1.

see also:     nodebug

END


$HELP{'nodebug'}=[<<'END'];
usage:       nodebug
             
description:
	     Turn off debugging messages.

	     This is equivalent to setting `$DEBUG' variable to 0.

see also:     debug

END


$HELP{'version'}=[<<'END'];
usage:       version
             
description:
	     Prints program version plus version numbers of the most
	     important libraries used.

END


$HELP{'validation'}=[<<'END'];
usage:       validation <expression>
             
description:
	     Turn on validation during the parse process if the
	     <expression> is non-zero or off otherwise. In XSH version 1.6
	     and later, defaults to off.

	     This command is equivalent to setting the `$VALIDATION'
	     variable.

END


$HELP{'recovering'}=[<<'END'];
usage:       recovering <expression>
             
description:
	     Turn on recovering parser mode if the <expression> is non-zero
	     or off otherwise. Defaults to off. Note, that the in the
	     recovering mode, validation is not performed by the parser
	     even if the validation flag is on and that recovering mode
	     flag only influences parsing of XML documents (not HTML).

	     The recover mode helps to efficiently recover documents that
	     are almost well-formed. This for example includes documents
	     without a close tag for the document element (or any other
	     element inside the document).

	     This command is equivalent to setting the `$RECOVERING'
	     variable.

END


$HELP{'parser-expands-entities'}=[<<'END'];
usage:       parser_expands_entities <expression>
             
aliases:     parser_expands_entities

description:
	     Enable the entity expansion during the parse process if the
	     <expression> is non-zero, disable it otherwise. If entity
	     expansion is off, any external parsed entities in the document
	     are left as entities. Defaults to on.

	     This command is equivalent to setting the
	     `$PARSER_EXPANDS_ENTITIES' variable.

END

$HELP{'parser_expands_entities'}=$HELP{'parser-expands-entities'};

$HELP{'keep-blanks'}=[<<'END'];
usage:       keep_blanks <expression>
             
aliases:     keep_blanks

description:
	     Allows you to turn off XML::LibXML's default behaviour of
	     maintaining whitespace in the document. Non-zero expression
	     forces the XML parser to preserve all whitespace.

	     This command is equivalent to setting the `$KEEP_BLANKS'
	     variable.

END

$HELP{'keep_blanks'}=$HELP{'keep-blanks'};

$HELP{'pedantic-parser'}=[<<'END'];
usage:       pedantic_parser <expression>
             
aliases:     pedantic_parser

description:
	     If you wish, you can make XML::LibXML more pedantic by passing
	     a non-zero <expression> to this command.

	     This command is equivalent to setting the `$PEDANTIC_PARSER'
	     variable.

END

$HELP{'pedantic_parser'}=$HELP{'pedantic-parser'};

$HELP{'parser-completes-attributes'}=[<<'END'];
usage:       parser-completes-attributes <expression>
             
aliases:     complete_attributes complete-attributes parser_completes_attributes

description:
	     If the expression is non-zero, this command allows XML parser
	     to complete the elements attributes lists with the ones
	     defaulted from the DTDs. By default, this option is enabled.

	     This command is equivalent to setting the
	     `$PARSER_COMPLETES_ATTRIBUTES' variable.

END

$HELP{'complete_attributes'}=$HELP{'parser-completes-attributes'};
$HELP{'complete-attributes'}=$HELP{'parser-completes-attributes'};
$HELP{'parser_completes_attributes'}=$HELP{'parser-completes-attributes'};

$HELP{'indent'}=[<<'END'];
usage:       indent <expression>
             
description:
	     If the value of <expression> is 1, format the XML output while
	     saving a document by adding some nice ignorable whitespace. If
	     the value is 2 (or higher), XSH will act as in case of 1, plus
	     it will add a leading and a trailing linebreak to each text
	     node.

	     Note, that since the underlying C library (libxml2) uses a
	     hardcoded indentation of 2 space characters per indentation
	     level, the amount of whitespace used for indentation can not
	     be altered on runtime.

	     This command is equivalent to setting the `$INDENT' variable.

END


$HELP{'empty-tags'}=[<<'END'];
usage:       empty-tags <expression>
             
aliases:     empty_tags

description:
	     If the value of <expression> is 1 (non-zero), empty tags are
	     serialized as a start-tag/end-tag pair (`<foo></foo>'). This
	     option affects both <ls> and <save> and possibly other
	     commands. Otherwise, they are compacted into a short-tag form
	     (`<foo/>'). Default value is `0'.

	     This command is equivalent to setting the `$EMPTY_TAGS'
	     variable.

END

$HELP{'empty_tags'}=$HELP{'empty-tags'};

$HELP{'skip-dtd'}=[<<'END'];
usage:       skip-dtd <expression>
             
aliases:     skip_dtd

description:
	     If the value of <expression> is 1 (non-zero), DTD DOCTYPE
	     declaration is omitted from any serialization of XML documents
	     (including <ls> and <save>). Default value is `0'.

	     This command is equivalent to setting the `$SKIP_DTD'
	     variable.

END

$HELP{'skip_dtd'}=$HELP{'skip-dtd'};

$HELP{'parser-expands-xinclude'}=[<<'END'];
usage:       parser_expands_xinclude <expression>
             
aliases:     parser_expands_xinclude

description:
	     If the <expression> is non-zero, the parser is allowed to
	     expand XIinclude tags imidiatly while parsing the document.

	     This command is equivalent to setting the
	     `$PARSER_EXPANDS_XINCLUDE' variable.

see also:     process-xinclude

END

$HELP{'parser_expands_xinclude'}=$HELP{'parser-expands-xinclude'};

$HELP{'load-ext-dtd'}=[<<'END'];
usage:       load_ext_dtd <expression>
             
aliases:     load_ext_dtd

description:
	     If the expression is non-zero, XML parser loads external DTD
	     subsets while parsing. By default, this option is enabled.

	     This command is equivalent to setting the `$LOAD_EXT_DTD'
	     variable.

END

$HELP{'load_ext_dtd'}=$HELP{'load-ext-dtd'};

$HELP{'encoding'}=[<<'END'];
usage:       encoding <enc-string>
             
description:
	     Set the default output character encoding.

	     This command is equivalent to setting the `$ENCODING'
	     variable.

END


$HELP{'query-encoding'}=[<<'END'];
usage:       query-encoding <enc-string>
             
aliases:     query_encoding

description:
	     Set the default query character encoding.

	     This command is equivalent to setting the `$QUERY_ENCODING'
	     variable.

END

$HELP{'query_encoding'}=$HELP{'query-encoding'};

$HELP{'quiet'}=[<<'END'];
usage:       quiet
             
description:
	     Turn off verbose messages.

	     This command is equivalent to setting the `$QUIET' variable.

see also:     verbose

END


$HELP{'switch-to-new-documents'}=[<<'END'];
usage:       switch-to-new-documents <expression>
             
aliases:     switch_to_new_documents

description:
	     If non-zero, XSH changes current node to the document node of
	     a newly open/created files every time a new document is opened
	     or created with <open> or <create>. Default value for this
	     option is 1.

	     This command is equivalent to setting the
	     `$SWITCH_TO_NEW_DOCUMENTS' variable.

END

$HELP{'switch_to_new_documents'}=$HELP{'switch-to-new-documents'};

$HELP{'backups'}=[<<'END'];
usage:       backups
             
description:
	     Enable creating backup files on save (default).

	     This command is equivalent to setting the `$BACKUPS' variable
	     to 1.

see also:     nobackups

END


$HELP{'nobackups'}=[<<'END'];
usage:       nobackups
             
description:
	     Disable creating backup files on save.

	     This command is equivalent to setting the `$BACKUPS' variable
	     to 0.

see also:     nobackups

END


$HELP{'fold'}=[<<'END'];
usage:       fold <xpath> [<expression>]
             
description:
	     This feature is still EXPERIMENTAL! Fold command may be used
	     to mark elements matching the <xpath> with a `xsh:fold'
	     attribute from the `http://xsh.sourceforge.net/xsh/'
	     namespace. When listing the DOM tree using `<ls> <xpath>
	     fold', elements marked in this way are folded to the depth
	     given by the <expression> (default depth is 0 = fold
	     immediately).

Example:
             xsh> fold //chapter 1
             xsh> ls //chapter[1] fold
             <chapter id="intro" xsh:fold="1">
               <title>...</title>
               <para>...</para>
               <para>...</para>
             </chapter>

see also:     unfold ls

END


$HELP{'unfold'}=[<<'END'];
usage:       unfold <xpath>
             
description:
	     This feature is still EXPERIMENTAL! Unfold command removes
	     `xsh:fold' attributes from all elements matching a given
	     <xpath> created by previous usage of <fold>. Be aware, that
	     `xmlns:xsh' namespace declaration may still be present in the
	     document even when all elements are unfolded.

see also:     fold ls

END


$HELP{'redo'}=[<<'END'];
usage:       redo [<expression>]
             
description:
	     The redo command restarts a loop block without evaluating the
	     conditional again. The optional <expression> argument may
	     evaluate to a positive integer number that indicates which
	     level of the nested loops should be restarted. If omitted, it
	     defaults to 1, i.e. the innermost loop.

	     Using this command outside a loop causes an immediate run-time
	     error.

Example:     Restart a higher level loop from an inner one

             while ($i<100) { 
               # ...
               foreach //para {
                 # some code
                 if $param { 
                   redo; # redo foreach loop
                 } else {
                   redo 2; # redo while loop
                 }
               }
             }

see also:     foreach while iterate next last

END


$HELP{'next'}=[<<'END'];
usage:       next [<expression>]
             
description:
	     The next command is like the continue statement in C; it
	     starts the next iteration of an enclosing loop. The optional
	     <expression> argument may evaluate to a positive integer
	     number that indicates which level of the nested loops should
	     be restarted. If omitted, it defaults to 1, i.e. the innermost
	     loop.

	     Using this command outside a loop causes an immediate run-time
	     error.

see also:     foreach while iterate redo last prev

END


$HELP{'prev'}=[<<'END'];
usage:       prev [<expression>]
             
description:
	     This command is only allowed inside an `iterate' loop. It
	     returns the iteration one step back, to the previous node on
	     the iterated axis. The optional <expression> argument may be
	     used to indicate to which level of nested loops the command
	     applies to.

see also:     iterate redo last next

END


$HELP{'last'}=[<<'END'];
usage:       last [<expression>]
             
description:
	     The last command is like the break statement in C (as used in
	     loops); it immediately exits an enclosing loop. The optional
	     <expression> argument may evaluate to a positive integer
	     number that indicates which level of the nested loops to quit.
	     If this argument is omitted, it defaults to 1, i.e. the
	     innermost loop.

	     Using this command outside a subroutine causes an immediate
	     run-time error.

see also:     foreach while iterate next last

END


$HELP{'return'}=[<<'END'];
usage:       return
             
description:
	     This command immediatelly stops the execution of a procedure
	     it occurs in and returns the execution to the place of the
	     script from which the subroutine was called.

	     Using this command outside a subroutine causes an immediate
	     run-time error.

see also:     def call

END


$HELP{'throw'}=[<<'END'];
usage:       throw <expression>
             
description:
	     This command throws and exception containing error message
	     given by the obligatory <expression> argument. If the
	     exception is not handled by some surrounding <try> block, the
	     execution is stopped immediatelly and the error message is
	     printed.

	     Note: There is a special class of internal exceptions with
	     error message starting with a word 'UNCATCHABLE'. Such
	     exceptions are not trapped by <try> constructions and should
	     be avoided in ordinary XSH scripts.

see also:     try

END


$HELP{'catalog'}=[<<'END'];
usage:       catalog <expression>
             
description:
	     Will use a given catalog file as a catalog during all parsing
	     processes. Using a catalog will significantly speed up parsing
	     processes if many external ressources are loaded into the
	     parsed documents (such as DTDs or XIncludes)

END


$HELP{'iterate'}=[<<'END'];
usage:       iterate <xpath> <command-block>
             
description:
	     Iterate works very much like the XPath variant of <foreach>,
	     except that `iterate' evaluates the <command-block> as soon as
	     a new node matching a given <xpath> is found. As a limitation,
	     the <xpath> expresion used with `iterate' may only consist of
	     one XPath step, i.e. it cannot contain an XPath step separator
	     `/'.

	     What are the benefits of `iterate' over a <foreach> loop,
	     then? Well, under some circumstances it is efficiency, under
	     other there are none. To clarify this, we have to dive a bit
	     deeper into the details of XPath implementation. By
	     definition, the node-list resulting from evaluation of an
	     XPath has to be ordered in the canonical document order. That
	     means that an XPath implementation must contain some kind of a
	     sorting algorithm. This would not itself be much trouble if a
	     relative document order of two nodes of a DOM tree could be
	     determined in a constant time. Unfortunately, the libxml2
	     library, used behind XSH, does not implement mechanisms that
	     would allow this complexity restriction (which is, however,
	     quite natural and reasonable approach if all the consequences
	     are considered). Thus, when comparing two nodes, libxml2
	     traverses the tree to find their nearest common ancestor and
	     at that point determines the relative order of the two
	     subtrees by trying to seek one of them in a list of right
	     siblings of the other. This of course cannot be handled in a
	     constant time. As a result, the sorting algorithm, reasonably
	     efficient for a constant time comparison (polynomial of a
	     degree < 1.5) or small node-lists, becomes rather unusable for
	     huge node-lists with linear time comparison (still polynomial
	     but of a degree > 2).

	     The `iterate' command provides a way to avoid sorting the
	     resulting nodelist by limiting allowed XPath expression to one
	     step (and thus one axis) at a time. On the other hand, since
	     `iterate' is implemented in Perl, a proxy object glueing the C
	     and Perl layers has to be created for every node the iterator
	     passes by. This (plus some extra subroutine calls) makes it
	     about two to three times slower compared to a similar
	     tree-traversing algorithm used by libxml2 itself during XPath
	     evaluation.

	     Our experience shows that `iterate' beats <foreach> in
	     performance on large node-lists (>=1500 nodes, but your milage
	     may vary) while <foreach> wins on smaller node-lists.

	     The following two examples give equivallent results. However,
	     the one using iterate may be faster esp. if the number of
	     nodes being counted is very large.

Example:     Count inhabitants of the kingdom of Rohan in productive age

             cd rohan/inhabitants;
             iterate child::*[@age>=18 and @age<60] { perl $productive++ };
             echo "$productive inhabitants in productive age";

Example:     Using XPath

             $productive=count(rohan/inhabitants/*[@age>=18 and @age<60]);
             echo "$productive inhabitants in productive age";

	     Use e.g. `| time cut' pipe-line redirection to benchmark a XSH
	     command on a UNIX system.

see also:     foreach next prev last

END


$HELP{'register-namespace'}=[<<'END'];
usage:       register-namespace <expression> <expression>
             
aliases:     regns

description:
	     Registers the first argument as a prefix for the namespace
	     given in the second argument. The prefix can later be used in
	     XPath expressions.

END

$HELP{'regns'}=$HELP{'register-namespace'};

$HELP{'unregister-namespace'}=[<<'END'];
usage:       unregister-namespace <expression>
             
aliases:     unregns

description:
	     Unregisters given namespace prefix previously registered using
	     <register-namespace>. The prefix can no longer be used in
	     XPath expressions unless declared within the current scope of
	     the queried document.

END

$HELP{'unregns'}=$HELP{'unregister-namespace'};

$HELP{'register-xhtml-namespace'}=[<<'END'];
usage:       register-xhtml-namespace <expression>
             
aliases:     regns-xhtml

description:
	     Registers a prefix for the XHTML namespace. The prefix can
	     later be used in XPath expressions.

END

$HELP{'regns-xhtml'}=$HELP{'register-xhtml-namespace'};

$HELP{'register-xsh-namespace'}=[<<'END'];
usage:       register-xsh-namespace <expression>
             
aliases:     regns-xsh

description:
	     Registers a new prefix for the XSH namespace. The prefix can
	     later be used in XPath expressions. Note, that XSH namespace
	     is by default registered with `xsh' prefix. This command is
	     thus, in general, useful only when some document uses `xsh'
	     prefix for a different namespace.

END

$HELP{'regns-xsh'}=$HELP{'register-xsh-namespace'};

$HELP{'register-function'}=[<<'END'];
usage:       register-function <expression> <perl-code>
             
aliases:     regfunc

description:
	     EXPERIMENTAL! Register given perl code as a new XPath
	     extension function under a name provided in the first argument
	     (<expression>). XML::LibXML DOM API may be used in the perl
	     code for object processing. If the name contains a colon, then
	     the first part before the colon must be a registered namespace
	     prefix (see <register-namespace>) and the function is
	     registered within the corresponding namespace.

END

$HELP{'regfunc'}=$HELP{'register-function'};

$HELP{'unregister-function'}=[<<'END'];
usage:       unregister-function <expression>
             
aliases:     unregfunc

description:
	     EXPERIMENTAL! Unregiseter XPath extension function of a given
	     name previously registered using <register-function>.

END

$HELP{'unregfunc'}=$HELP{'unregister-function'};

$HELP{'stream'}=[<<'END'];
usage:       stream input [FILE|PIPE|STRING] <expression>
                      output [FILE|PIPE|STRING] <expression>
                      select <xpath> <command-block>
                    [ select <xpath> <command-block> ... ]
             
description:
	     EXPERIMENTAL! This command provides a memory efficient (though
	     slower) way to process selected parts of an XML document with
	     XSH. A streaming XML parser (SAX parser) is used to parse the
	     input. The parser has two states which will be refered to as A
	     and B below. The initial state of the parser is A.

	     In the state A, only a limited vertical portion of the DOM
	     tree is built. All XML data comming from the input stream
	     other than start-tags are immediatelly copied to the output
	     stream. If a new start-tag of an element arrives, a new node
	     is created in the tree. All siblings of the newly created node
	     are removed. Thus, in the state A, there is exactly one node
	     on every level of the tree. After a node is added to the tree,
	     all the <xpath> expressions following the `select' keyword are
	     checked. If none matches, the parser remains in state A and
	     copies the start-tag to the output stream. Otherwise, the
	     first expression that matches is remembered and the parser
	     changes its state to B.

	     In state B the parser builds a complete DOM subtree of the
	     element that was last added to the tree before the parser
	     changed its state from A to B. No data are sent to the output
	     at this stage. When the subtree is complete (i.e. the
	     corresponding end-tag for its topmost element is encountered),
	     the <command-block> of instructions following the <xpath>
	     expression that matched is invoked with the root element of
	     the subtree as the current context node. The commands in
	     <command-block> are allowed to transform the whole element
	     subtree or even to replace it with a different DOM subtree or
	     subtrees. They must, however, preserve the element's parent as
	     well as all its ancestor nodes intact. Failing to do so can
	     result in an error or unpredictable results.

	     After the subtree processing <command-block> returns, all
	     subtrees that now appear in the DOM tree in the place of the
	     original subtree are serialized to the output stream. After
	     that, they are deleted and the parser returns to state A.

	     Note that this type of processing highly limits the amount of
	     information the XPath expressions can use. First notable fact
	     is that elements can not be selected by their content. The
	     only information present in the tree at the time of the XPath
	     evaluation is the element's name and attributes plus the same
	     information for all its ancestors. There is nothing known yet
	     about possible child nodes of the element as well as of the
	     node's position within its siblings.

END


$HELP{'namespaces'}=[<<'END'];
usage:       namespaces [<xpath>]
             
description:
	     For each node matching given <xpath> lists all namespaces that
	     are valid in its scope in the form of `xmlns:prefix="uri"'
	     declarations. If no <xpath> is given, lists namespaces in the
	     scope of the current node.

END


$HELP{'xpath-completion'}=[<<'END'];
usage:       xpath_completion <expression>
             
aliases:     xpath_completion

description:
	     If the <expression> is non-zero, enable the TAB completion for
	     <xpath> expansions in the interactive shell mode, disable it
	     otherwise. Defaults to on.

	     This command is equivalent to setting the `$XPATH_COMPLETION'
	     variable.

END

$HELP{'xpath_completion'}=$HELP{'xpath-completion'};

$HELP{'xpath-axis-completion'}=[<<'END'];
usage:       xpath-axis-completion <expression>
             
aliases:     xpath_axis_completion

description:
	     The following values are allowed: `always', `never',
	     `when-empty'. Note, that all other values (including 1) work
	     as `never'!

	     If the <expression> evaluates to `always', TAB completion for
	     XPath expressions always includes axis names.

	     If the <expression> evaluates to `when-empty', the TAB
	     completion list for XPath expressions includes axis names only
	     if no element name matches the completion.

	     If the <expression> evaluates to `never', the TAB completion
	     list for XPath expressions never includes axis names.

	     The default value for this optio is `always'.

	     This command is equivalent to setting the
	     `$XPATH_AXIS_COMPLETION' variable.

END

$HELP{'xpath_axis_completion'}=$HELP{'xpath-axis-completion'};

$HELP{'doc-info'}=[<<'END'];
usage:       doc-info [<expression>]
             
aliases:     doc_info

description:
	     In the present implementation, this command displays
	     information provided in the `<?xml ...?>' declaration of a
	     document: `version', `encoding', `standalone', plus
	     information about level of `gzip' compression of the original
	     XML file.

see also:     set-enc set-standalone

END

$HELP{'doc_info'}=$HELP{'doc-info'};

$HELP{'Documents'}=[<<'END'];
Files/Documents
---------------

  XSH is intended to query and manipulate XML and HTML documents. Use one
  of the `open/open-*/create' commands to load an XML or HTML document from
  a local file, external URL (such as http:// or ftp://), string or pipe.
  While loading, XSH parses and optionally validates (see <validation> and
  <load-ext-dtd>) the document. Parsed documents are stored in memory as
  DOM trees, that can be <navigated>navigated and <manipulated>manipulated
  quite similarly to a local filesystem.

  Every opened document is associated with an identifier (<id>), that is a
  symbolic name for the document in XSH and can be used for example as a
  prefix of <xpath>.

  In the current version, XSH is only able to save documents locally. To
  store a document on any other location, use <ls> command and pipe
  redirection to feed the XML representation of the document to any
  external program that is able to store it on a remote location.

Example: Store XSH document DOC on a remote machine using Secure Shell

  xsh> ls DOC:/ | ssh my.remote.org 'cat > test.xml'


Related commands:
  backups, catalog, clone, close, create, documents, nobackups, open,
  process-xinclude, save, select, stream, switch-to-new-documents

END

$HELP{'Navigation'}=[<<'END'];
Tree navigation
---------------

  With XSH, it is possible to browse <document trees>document trees as if
  they were a local filesystem, except that <XPath>XPath expressions are
  used instead of ordinary UNIX paths.

  Current position in the document tree is called the current node. Current
  node's XPath may be queried with <pwd> command. In the interactive shell,
  current node is also displayed in the command line prompt. Remember, that
  beside <cd> command, current node (and document) is silently changed by
  all variant of <open> command, <create> command and temporarily also by
  the node-list variant of the <foreach> statement.

  Documents are specified in a similar way as harddrives on DOS/Windows(TM)
  systems (except that their names are not limitted to one letter in XSH),
  i.e. by a prefix of the form doc: where doc is the <id> associated with
  the document.

  To mimic the filesystem navigation as closely as possible, XSH contains
  several commands named by analogy of UNIX filesystem commands, such as
  <cd>, <ls> and <pwd>.

Example:
  xsh scratch:/> open docA="testA.xml"
  xsh docB:/> open docB="testB.xml"
  xsh> pwd
  docB:/
  xsh docB:/> cd docA:/article/chapter[title='Conclusion']
  xsh docA:/article/chapter[5]> pwd
  docA:/article/chapter[5]
  xsh docA:/article/chapter[5]> cd previous-sibling::chapter
  xsh docA:/article/chapter[4]> cd ..
  xsh docA:/article> select docB
  xsh docB:/>


Related commands:
  cd, fold, locate, ls, pwd, register-function, register-namespace,
  register-xhtml-namespace, register-xsh-namespace, select, unfold,
  unregister-function, unregister-namespace

END

$HELP{'Manipulation'}=[<<'END'];
Tree modification
-----------------

  XSH provides mechanisms not only to browse and inspect the DOM tree but
  also to modify its content by providing commands for copying, moving, and
  deleting its nodes as well as adding completely new nodes or XML
  fragments to it. It is quite easy to learn these commands since their
  names or aliases mimic their well-known filesystem analogies. On the
  other hand, many of these commands have two versions one of which is
  prefixed with a letter "x". This "x" stands for "cross", thus e.g.
  <xcopy> should be read as "cross copy". Let's explain the difference on
  the example of <xcopy>.

  When you copy, you have to specify what are you copying and where are you
  copying to, so you have to specify the source and the target. XSH is very
  much XPath-based so, XPath is used here to specify both of them. However,
  there might be more than one node that satisfies an XPath expression. So,
  the rule of thumb is that the "cross" variant of a command places one and
  every of the source nodes to the location of one and every destination
  node, while the plain variant works one-by-one, placing the first source
  node to the first destination, the second source node to the second
  destination, and so on (as long as there are both source nodes and
  destinations left).

Example:
  xsh> create a "<X><A/><Y/><A/></X>";
  xsh> create b "<X><B/><C/><B/><C/><B/></X>";
  xsh> xcopy a://A replace b://B;
  xsh> copy b://C before a://A;
  xsh> ls a:/;
  <?xml version="1.0" encoding="utf-8"?>
  <X><C/><A/><Y/><C/><A/></X>
  
  xsh> ls b:/;
  <?xml version="1.0" encoding="utf-8"?>
  <X><A/><A/><C/><A/><A/><C/><A/><A/></X>

  As already indicated by the example, another issue of tree modification
  is the way in which the destination node determines the target location.
  Should the source node be placed before, after, or into the resulting
  node? Should it replace it completely? This information has to be given
  in the <location> argument that usually precedes the destination XPath.

  Now, what happens if source and destination nodes are of incompatible
  types? XSH tries to avoid this by implicitly converting between node
  types when necessary. For example, if a text, comment, and attribute node
  is copied into, before or after an attribute node, the original value of
  the attribute is replaced, prepended or appended respectively with the
  textual content of the source node. Note however, that element nodes are
  never converted into text, attribute or any other textual node. There are
  many combinations here, so try yourself and see the results.

  You may even use some more sofisticated way to convert between node
  types, as shown in the following example, where an element is first
  commented out and than again uncommented. Note, that the particular
  approach used for resurrecting the commented XML material works only for
  well-balanced chunks of XML.

Example: Using string variables to convert between different types of nodes

  create doc <<EOF;
  <?xml version='1.0'?>
  <book>
    <chapter>
      <title>Intro</title>
    </chapter>
    <chapter>
      <title>Rest</title>
    </chapter>
  </book>
  EOF
  
  # comment out the first chapter
  ls //chapter[1] |> $chapter_xml;
  add comment $chapter_xml replace //chapter[1];
  ls / 0;
  # OUTPUT:
  <?xml version="1.0"?>
  <book>
  <!--  <chapter>
      <title>Intro</title>
    </chapter>
  -->
    <chapter>
      <title>Rest</title>
    </chapter>
  </book>
  
  
  # un-comment the chapter
  $comment = string(//comment()[1]);
  add chunk $comment replace //comment()[1];
  ls / 0;
  # OUTPUT:
  <?xml version="1.0"?>
  <book>
    <chapter>
      <title>Intro</title>
    </chapter>
  
    <chapter>
      <title>Rest</title>
    </chapter>
  </book>


Related commands:
  clone, copy, insert, map, move, normalize, process-xinclude, remove,
  rename, set-enc, set-standalone, strip-whitespace, xcopy, xinsert, xmove,
  xslt, xupdate

END

$HELP{'Flow'}=[<<'END'];
Flow control
------------

  What a scripting language XSH would be had it not some kind of
  conditional statements, loops and other stuff that influences the way in
  which XSH commands are processed.

  Most notable XSH's feature in this area is that some of the basic flow
  control statements, namely <if>, <unless>, <while> and <foreach> have two
  variants, an XPath-based one and a Perl-based one. The XPath-based
  variant uses <xpath> expressions to specify the condition or node-lists
  to iterate, while the other one utilizes <perl-code> for this purpose.
  See descriptions of the individual statements for more detail.


Related commands:
  call, def, exit, foreach, if, ifinclude, include, iterate, last, next,
  prev, redo, return, run-mode, stream, test-mode, throw, try, undef,
  unless, while

END

$HELP{'Information'}=[<<'END'];
Retrieving more information
---------------------------

  Beside the possibility to browse the DOM tree and list some parts of it
  (as described in <Navigation>), XSH provides commands to obtain other
  information related to open documents as well as the XSH interpreter
  itself. These commands are listed bellow.


Related commands:
  count, defs, doc-info, documents, dtd, enc, help, locate, ls, namespaces,
  options, print, pwd, valid, validate, variables, version

END

$HELP{'Argtypes'}=[<<'END'];
Argument Types
--------------

  XSH commands accept different types of arguments, such as usual strings
  (<expression>) or <XPath expressions>XPath expressions. Notably, these
  two types and types based on them support string variable interpolation.
  See documentation of the individual types for more information.

END

$HELP{'Variables'}=[<<'END'];
Variables
---------

  In the current version, XSH supports two types of variables: string
  (scalar) variables and node-list variables. Perl programmers that might
  miss some other kinds of variables (arrays or hashes) may use the support
  for <interacting with Perl>interacting with Perl to access these types
  (see some examples below).

  These two kinds of variables differ syntactically in the prefix: string
  variables are prefixed with a dollar sign (`$') while node-list variables
  are prefixed with a percent sign (`%').

  String Variables
  ----------------

    Every string variable name consists of a dollar sign (`$') prefix and
    an <id>, that has to be unique among other scalar variables, e.g.
    `$variable'. Values are assigned to variables either by simple
    <assignments>assignments of the form `$variable = <xpath>' or by
    capturing the output of some command with a variable redirection of the
    form `command |> $variable'.

    String variables may be used in <string expressions>string expressions,
    <XPath expressions>XPath expressions, or even in perl-code as $<id> or
    ${<id>}. In the first two cases, variables act as macros in the sense
    that all variables occurences are replaced by the corresponding values
    before the expression itself is evaluated.

    To display current value of a variable, use the <print> command,
    <variables> command or simply the variable name:

Example:
    xsh> $b="chapter";
    xsh> $file="${b}s.xml";
    xsh> open f=$file;
    xsh> ls //$b[count(descendant::para)>10]
    xsh> print $b
    chapter
    xsh> $b
    $b='chapter';
    xsh> variables
    $a='chapters.xml';
    $b='chapter';

  Node-list Variables
  -------------------

    Every string variable name consists of a percent sign (`%') prefix and
    an <id>, that has to be unique among other node-list variables, e.g.
    `%variable'.

    Node-list variables can be used to store lists of nodes that result
    from evaluating an XPath. This is especially useful when several
    changes are performed on some set of nodes and evaluating the XPath
    expression repeatedly would take too long. Other important use is to
    remember a node that would otherwise be extremely hard or even
    impossible to locate by XPath expressions after some changes to the
    tree structure are made, since such an XPath cannot be predicted in
    advance.

    Although node-list variables act just like XPath expressions that would
    result in the same node-list, for implementation reasons it is not
    possible to use node-list variables as parts of complex XPath
    expressions except for one case. They may be only used at the very
    beginning of an XPath expression. So while constructions such as
    `%creatures[4]', `%creatures[@race='elf']', or
    `%creatures/parents/father' do work as expected,
    `string(%creatures[2]/@name)' `//creature[%creatures[2]/@name=@name]',
    or `%creatures[@race='elf'][2]' do not. In the first two cases it is
    because node-list variables cannot be evaluated in the middle of an
    XPath expression. The third case fails because this construction
    actually translates into a sequence of evaluations of
    `self::*[@race='elf'][2]' for each node in the `%creatures' node-list,
    which is not equivallent to the intended expression as the `[2]' filter
    does not apply to the whole result of `%creatures[@race='elf']' at once
    but rather to the partial results.

    Fortunatelly, it is usually possible to work around these unsupported
    constructions quite easily. This is typically done by introducing some
    more variables as well as using the <foreach> statement. The following
    example should provide some idea on how to do this:

Example:
    # work around for $name=string(%creatures[2]/@name)
    xsh> foreach %creatures[2] $name=string(@name)
    # work around for ls //creature[%creatures[2]/@name=@name]
    xsh> ls //creature[$name=@name]
    # work around for ls %creatures[@race='elf'][2]
    xsh> %elves = %creatures[@race='elf']
    xsh> ls %elves[2]

    Remember, that when a node is deleted from a tree it is at the same
    time removed from all node-lists it occurs in. Note also, that unlike
    string variables, node-list variables can not be (and are not intended
    to be) directly accessed from Perl code.

  Accessing Perl Variables
  ------------------------

    All XSH string variables are usual Perl scalar variables from the
    `XML::XSH::Map' namespace, which is the default namespace for any Perl
    code evaluated from XSH. Thus it is possible to arbitrarily intermix
    XSH and Perl assignments:

Example:
    xsh> ls //chapter[1]/title
    <title>Introduction</title>
    xsh> $a=string(//chapter[1]/title)
    xsh> eval { $b="CHAPTER 1: ".uc($a); }
    xsh> print $b
    CHAPTER 1: INTRODUCTION

    If needed, it is, however, possible to use any other type of Perl
    variables by means of evaluating a corresponding perl code. The
    following example demonstrates using Perl hashes to collect and print
    some simple racial statistics about the population of Middle-Earth:

Example:
    foreach a:/middle-earth/creature { 
      $race=string(@race);
      eval { $races{$race}++ };
    }
    print "Middle-Earth Population (race/number of creatures)"
    eval { 
      echo map "$_/$races{$_}\n",
        sort ($a cmp $b), keys(%races); 
    };


Related commands:
  assign, local

END

$HELP{'Configuration'}=[<<'END'];
Options
-------

  The following commands are used to modify the default behaviour of the
  XML parser or XSH itself. Some of the commands are switch between two
  different modes according to a given expression (which is expected to
  result either in zero or non-zero value). Other commands also working as
  a flip-flop have their own explicit counterpart (e.g. <verbose> and
  <quiet> or <debug> and <nodebug>). This misconsistency is due to
  historical reasons.

  The <encoding> and <query-encoding> options allow to specify character
  encoding that should be expected from user as well as the encoding to be
  used by XSH on output. This is particularly useful when you work with
  UTF-8 encoded documents on a console which supports only 8-bit
  characters.

  The <options> command displays current settings by means of XSH commands.
  Thus it can not only be used to review current values, but also to store
  them future use, e.g. in ~/.xshrc file.

Example:
  xsh> options | cat > ~/.xshrc


Related commands:
  backups, debug, empty-tags, encoding, indent, keep-blanks, load-ext-dtd,
  nobackups, nodebug, options, parser-completes-attributes,
  parser-expands-entities, parser-expands-xinclude, pedantic-parser,
  query-encoding, quiet, recovering, register-function, register-namespace,
  register-xhtml-namespace, register-xsh-namespace, run-mode, skip-dtd,
  switch-to-new-documents, test-mode, unregister-function,
  unregister-namespace, validation, verbose, xpath-axis-completion,
  xpath-completion

END

$HELP{'Perl_shell'}=[<<'END'];
Interacting with Perl and Shell
-------------------------------

  To allow more complex tasks to be achieved, XSH provides ways for
  interaction with the Perl programming language and the system shell.

  Calling Perl
  ------------

    Perl is a language optimized for scanning arbitrary text files,
    extracting information from those text files, and printing reports
    based on that information. It's also a good language for many system
    management tasks. The language is intended to be practical (easy to
    use, efficient, and complete). XSH itself is written in Perl, so it is
    extremely easy to support this language as an extension to XSH.

    Perl <expressions or blocks of code>expressions or blocks of code can
    either be simply evaluated with the <perl> command, used to do quick
    changes to nodes of the DOM tree (see <map> command), used to provide
    list of strings to iterate over in a <foreach> loop, or to specify more
    complex conditions for <if>, <unless>, and <while> statements.

    To prevent conflict between XSH internals and the evaluated perl code,
    XSH runs such code in the context of a special namespace
    `XML::XSH::Map'. As described in the section <Variables>, XSH string
    variables may be accessed and possibly assigned from Perl code in the
    most obvious way, since they actually are Perl variables defined in the
    `XML::XSH::Map' namespace.

    The interaction between XSH and Perl actually works also the other way
    round, so that you may call back XSH from the evaluated Perl code. For
    this, Perl function `xsh' is defined in the `XML::XSH::Map' namespace.
    All parameters passed to this function are interpreted as XSH commands.
    To simplify evaluation of XPath expressions, another three functions:
    The first one, named `count', returns the same value as would be
    printed by <count> command in XSH on the same XPath expression. The
    second function, named `literal', returns the result of XPath
    evaluation as if the whole expression was wrapped with the XPath
    `string()' function. In other words, `literal('doc:expression')'
    returns the same value as `count('doc:string(expression)')'. The third
    function, named `xml_list', returns the result of the XPath search as a
    XML string which is equivallent to the output of a <ls> on the same
    XPath expression (without indentation and without folding or any other
    limitation on the depth of the listing).

    In the following examples we use Perl to populate the Middle-Earth with
    Hobbits whose names are read from a text file called `hobbits.txt',
    unless there are some Hobbits in Middle-Earth already.

Example: Use Perl to read text files

    unless (//creature[@race='hobbit']) {
      perl 'open $file, "hobbits.txt"';
      perl '@hobbits=<$file>';
      perl 'close $file';
      foreach { @hobbits } {
        insert element "<creature name='$__' race='hobbit'>"
          into m:/middle-earth/creatures;
      }
    }

Example: The same code as a single Perl block

    perl {
      unless (count(//creature[@race='hobbit'])) {
        open my $file, "hobbits.txt";
        foreach (<$file>) {
          xsh(qq{insert element "<creature name='$_' race='hobbit'>"
            into m:/middle-earth/creatures});
        }
        close $file;
      }
    };

  Writing your own XPath extension functions in Perl
  --------------------------------------------------

    XSH allows the user to extend the set of XPath functions by providing
    an extension function written in Perl. This can be achieved using the
    <register-function> command. The perl code implementing an extension
    function works as a usual perl routine accepting its arguments in `@_'
    and returning the result. The following conventions are used:

    The arguments passed to the perl implementation by the XPath engine are
    either simple scalars or `XML::LibXML::NodeList' objects, depending on
    the types of the XPath arguments. The implementation is responsible for
    checking the argument number and types. The implementation may use
    arbitrary `XML::LibXML' methods to process the arguments and return the
    result. (`XML::LibXML' perl module documentation can be found for
    example at
    http://search.cpan.org/author/PHISH/XML-LibXML-1.54/LibXML.pm).

    The implementation SHOULD NOT, however, MODIFY the document. Doing so
    could not only confuse the XPath engine but result in an critical error
    (such as segmentation fault).

    Calling XSH commands from extension function implementations is not
    currently allowed.

    The perl code must return a single value, which can be of one of the
    following types: a simple scalar (a number or string),
    `XML::LibXML::Boolean' object reference (result is a boolean value),
    `XML::LibXML::Literal' object reference (result is a string),
    `XML::LibXML::Number' object reference (resulat is a float),
    `XML::LibXML::Node' (or derived) object reference (result is a nodeset
    consisting of a single node), or `XML::LibXML::NodeList' (result is a
    nodeset). For convenience, simple (non-blessed) array references
    consisting of `XML::LibXML::Node' objects can also be used for a
    nodeset result instead of a `XML::LibXML::NodeList'.

  Calling the System Shell
  ------------------------

    In the interactive mode, XSH interprets all lines starting with a
    exclamation mark (`!') as shell commands and invokes the system shell
    to interpret them (this is to mimic FTP command-line interpreters).

Example:
    xsh> !ls -l
    -rw-rw-r--    1 pajas    pajas        6355 Mar 14 17:08 Artistic
    drwxrwxr-x    2 pajas    users         128 Sep  1 10:09 CVS
    -rw-r--r--    1 pajas    pajas       14859 Aug 26 15:19 ChangeLog
    -rw-r--r--    1 pajas    pajas        2220 Mar 14 17:03 INSTALL
    -rw-r--r--    1 pajas    pajas       18009 Jul 15 17:35 LICENSE
    -rw-rw-r--    1 pajas    pajas         417 May  9 15:16 MANIFEST
    -rw-rw-r--    1 pajas    pajas         126 May  9 15:16 MANIFEST.SKIP
    -rw-r--r--    1 pajas    pajas       20424 Sep  1 11:04 Makefile
    -rw-r--r--    1 pajas    pajas         914 Aug 26 14:32 Makefile.PL
    -rw-r--r--    1 pajas    pajas        1910 Mar 14 17:17 README
    -rw-r--r--    1 pajas    pajas         438 Aug 27 13:51 TODO
    drwxrwxr-x    5 pajas    users         120 Jun 15 10:35 blib
    drwxrwxr-x    3 pajas    users        1160 Sep  1 10:09 examples
    drwxrwxr-x    4 pajas    users          96 Jun 15 10:35 lib
    -rw-rw-r--    1 pajas    pajas           0 Sep  1 16:23 pm_to_blib
    drwxrwxr-x    4 pajas    users         584 Sep  1 21:18 src
    drwxrwxr-x    3 pajas    users         136 Sep  1 10:09 t
    -rw-rw-r--    1 pajas    pajas          50 Jun 16 00:06 test
    drwxrwxr-x    3 pajas    users         496 Sep  1 20:18 tools
    -rwxr-xr-x    1 pajas    pajas        5104 Aug 30 17:08 xsh

    To invoke a system shell command or program from the non-interactive
    mode or from a complex XSH construction, use the <exec> command.

    Since UNIX shell commands are very powerful tool for processing textual
    data, XSH supports direct redirection of XSH commands output to system
    shell command. This is very similarly to the redirection known from
    UNIX shells, except that here, of course, the first command in the
    pipe-line colone is an XSH command. Since semicolon (`;') is used in
    XSH to separate commands, it has to be prefixed with a backslash if it
    should be used for other purposes.

Example: Use grep and less to display context of `funny'

    xsh> ls //chapter[5]/para | grep funny | less

Example: The same on Windows 2000/XP systems

    xsh> ls //chapter[5]/para | find "funny" | more


Related commands:
  exec, lcd, map, perl, rename

END

$HELP{'commands'}=$HELP{'command'};

1;
__END__

