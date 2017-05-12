# -*- mode: cperl -*-
use strict;
use warnings;
use utf8;

use Test::More tests => 61;
BEGIN { use_ok('Text::Amuse::Preprocessor::Typography') };

use Text::Amuse::Preprocessor::Typography qw/typography_filter
                                             linkify_filter
                                            /;

#########################

is(typography_filter("en", "This is \"my quotation\" and 'this' and that's all"),
   "This is “my quotation” and ‘this’ and that’s all",
   "checking quotes");

is(typography_filter("en", "\n\"my quotation\"\n and \n'this'\n and that's all"),
   "\n“my quotation”\n and \n‘this’\n and that’s all",
   "checking quotes on a line by themselves");

is(typography_filter("en", "\n10-15\n and 11212341234-123412341234\n"),
   "\n10–15\n and 11212341234–123412341234\n",
   "checking en-dash");

is(typography_filter("en", "\n - This is a list\n"),
   "\n - This is a list\n",
   "checking em-dash (don't mess with lists)");

is(typography_filter("en", "\n But - this is not a list\n"),
   "\n But — this is not a list\n",
   "checking em-dash (don't mess with lists)");

is(typography_filter("en", "\n But - this is not a list\n"),
   "\n But — this is not a list\n",
   "checking em-dash (don't mess with lists)");

is(typography_filter("not-exists", "ﬁ ﬂ ﬃ ﬄ ﬀ"),
   "fi fl ffi ffl ff",
   "checking ugly ligatures");

is(typography_filter("en", "''my'' ``quote\""),
   "“my” “quote”",
   "checking ascii quoting"
);

is(typography_filter("en", "\n4-5,56-18\n"), "\n4–5,56–18\n", "numbers");

is(typography_filter("en", "\n4-4-5\n"), "\n4-4-5\n", "en-dash not replaced (sequence)");

is(typography_filter("en", "http://www.sociology.ox.ac.uk/papers/dunn73-93.doc"),
   "http://www.sociology.ox.ac.uk/papers/dunn73-93.doc",
   "en-dash not replaced 2 (url)");

is(typography_filter("en", "http://www.omnipresence.mahost.org/wd-v2-n1-6.htm"),
   "http://www.omnipresence.mahost.org/wd-v2-n1-6.htm",
   "checking en-dash");

is(typography_filter("en", "\n12th\n13th\n1st\n2nd\n3rd\n"),
   "\n12<sup>th</sup>\n13<sup>th</sup>\n1<sup>st</sup>". 
   "\n2<sup>nd</sup>\n3<sup>rd</sup>\n",
   "checking superscripts");

is(typography_filter("en", "\n12th, 13th, (1st and 2nd)"),
   "\n12<sup>th</sup>, 13<sup>th</sup>, (1<sup>st</sup> and 2<sup>nd</sup>)",
   "checking superscripts 2");

is(typography_filter("fi", '"this" and "this"'),
   "”this” and ”this”",
   "finnish quote");

is(typography_filter("fi", "'this' and 'this'"),
   "’this’ and ’this’",
   "finnish half-quote");

is(typography_filter("fi", 'this - and - this'),
   "this – and – this",
   "finnish en-dash");

is(typography_filter("sr", '"this" and "this"'),
   "„this“ and „this“",
   "german quote");

is(typography_filter("hr", '"this" and "this"'),
   "„this” and „this”",
   "croatian quote");

is(typography_filter("hr", "'this' and 'this'"),
   "‚this’ and ‚this’",
   "croatian single quotes");

is(typography_filter("hr", 'this - and - this'),
   "this — and — this",
   "croatian em-dash");

is(typography_filter("sr", "'this' and 'this'"),
   "‚this‘ and ‚this‘",
   "german single quotes");

is(typography_filter("sr", 'this - and - this'),
   "this – and – this",
   "serbian en-dash");

is(typography_filter("hr", "Zo d'axa i Zo d'axa"),
   "Zo d’axa i Zo d\x{2019}axa",
   "keep the apostrophe safe 1");

is(typography_filter("sr", "Zo d'axa i Zo d'axa"),
   "Zo d’axa i Zo d\x{2019}axa",
   "keep the apostrophe safe 1");

   


is(typography_filter("en", ". . .  ..."), '...  ...',"ellipsis");
is(typography_filter("en", "ground. . . ."), 'ground...',"periods2");
is(typography_filter("en", "ground. ... How"), 'ground. ... How',"periods3");

is(typography_filter("en", "hello --- world"), 'hello — world', 'em-dash');
is(typography_filter("en", "'80 '90"), '’80 ’90', '\'numbers');
is(typography_filter("en", "let's do it let's do it\n"), 'let’s do it let’s do it' . "\n", 'apostroph');

is(typography_filter("en", " - first\n - first \n - second \n - third\n"),
   " - first\n - first \n - second \n - third\n",
   "saving the list, en");

is(typography_filter("ru", " - first\n - first \n - second \n - third\n"),
   " - first\n - first \n - second \n - third\n",
   "saving the list, ru");



is(typography_filter("fi", "\n - first \n - second \n - third\n"),
   "\n - first \n - second \n - third\n",
   "saving the list, fi");

is(typography_filter("hr", "\n - first \n - second \n - third\n"),
   "\n - first \n - second \n - third\n",
   "saving the list, hr");

is(typography_filter("sr", "\n - first \n - second \n - third\n"),
   "\n - first \n - second \n - third\n",
   "saving the list, sr");

is(typography_filter("ru", "\"хотите присоединиться к ордену Библиотекарей\""),
   "«хотите присоединиться к ордену Библиотекарей»",
   "checking russian double quotes 1");

is(typography_filter("ru", "\"хотите \"присоединиться\" к ордену Библиотекарей\""),
   "«хотите «присоединиться» к ордену Библиотекарей»",
   "checking russian double quotes 2");


is(typography_filter("ru", "'хотите присоединиться к ордену Библиотекарей'"),
   "‘хотите присоединиться к ордену Библиотекарей’",
   "checking russian single quotes 1");

is(typography_filter("ru", "'хотите присоединиться '18 к ордену Библиотекарей'"),
   "‘хотите присоединиться ’18 к ордену Библиотекарей’",
   "checking russian single quotes 2");

is(typography_filter("ru", "'хотите 'присоединиться' '18 к ордену Библиотекарей'"),
   "‘хотите ‘присоединиться’ ’18 к ордену Библиотекарей’",
   "checking russian single quotes 3");

is(typography_filter("ru", "\"'хотите'\" 'присоединиться' '18 к ордену Библиотекарей'"),
   "«‘хотите’» ‘присоединиться’ ’18 к ордену Библиотекарей’",
   "checking russian mixed");

is(typography_filter("ru", "ордену - ордену"),
   "ордену — ордену",
   "checking russian em-dash");
   

is(linkify_filter("Retrieved on February 2, 2011 from http://j12.org/spunk/library/writers/meltzer/sp001500.html"),
   "Retrieved on February 2, 2011 from [[http://j12.org/spunk/library/writers/meltzer/sp001500.html][j12.org]]",
   "checking linkifier");

is(linkify_filter("Retrieved on December 22, 2011 from http://libertarian-labyrinth.org/archive/The_Great_Debacle"),
   "Retrieved on December 22, 2011 from [[http://libertarian-labyrinth.org/archive/The_Great_Debacle][libertarian-labyrinth.org]]", "checking linkifier 2");

is(linkify_filter("<br>http://www.nancho.net/advisors/anaes.html<br>"),
   "<br>[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>",
   "Checking linkifier 3");

is(linkify_filter("http://www.nancho.net/advisors/anaes.html<br>http://www.nancho.net/advisors/anaes.html<br>"),
   "[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>[[http://www.nancho.net/advisors/anaes.html][www.nancho.net]]<br>",
   "Checking linkifier 4");

# spanish

is(typography_filter("es", "This is \"ómy quotationÓ\" and 'Óthisó' and that's all"),
   "This is «ómy quotationÓ» and ‘Óthisó’ and that’s all",
   "checking quotes 1 es");

is(typography_filter("es", "This is \"my quotation\" and 'this' and that's all"),
   "This is «my quotation» and ‘this’ and that’s all",
   "checking quotes");

is(typography_filter("es", "\n\"my quotation\"\n and \n'this'\n and that's all"),
   "\n«my quotation»\n and \n‘this’\n and that’s all",
   "checking quotes on a line by themselves");

is(typography_filter("es", "\"This is a 'quotation'.\""),
   "«This is a ‘quotation’.»", "checking nested quotes (es)");

is(typography_filter("es", "\"This is a 'quotation'\"."),
   "«This is a ‘quotation’».", "checking nested quotes (2) (es)");

is(typography_filter("es",
		     "sólo Sólo sólobla blasólo sólobla blasólo blasólobla",),
   "sólo Sólo sólobla blasólo sólobla blasólo blasólobla",
   "Checking solo");

is(typography_filter("es", "\n - This is a list\n"),
   "\n - This is a list\n",
   "checking em-dash (don't mess with lists)");

is(typography_filter("es", "\n But - this is not a list\n"),
   "\n But — this is not a list\n",
   "checking em-dash (don't mess with lists)");

is(typography_filter("es", "the - second - example, the -ósecondÓ- example"),
   "the — second — example, the — ósecondÓ — example",
   "Checking em dash");

is(typography_filter("es", "\n-hello\n\n- hello"),
   "\n— hello\n\n— hello",
   "dialogs es");

is(typography_filter("es", "hello.\" hell'o\""),
   "hello.» hell’o»",
   "period falls out of the quotation");

is(typography_filter("es", " \"?hello?\"\n\"?hello?\" \"l'amour\" 'amour'"),
   " «?hello?»\n«?hello?» «l’amour» ‘amour’",
   "Tricky case");

is(typography_filter("es", " (\"?hello?\") (\"hello\"): \"hello\""),
   " (»?hello?») («hello»): «hello»",
   "Tricky case: impossible to fix, first chunk is wrong");



