# -*- cperl -*-
use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture';

use Text::BibTeX qw(:metatypes);
use Text::BibTeX::Error qw(:errclasses);

my $bad = '@article{k, title = foo, author {x}}';

# Errors are stored in the entry as objects
my ($entry, @warnings);
{
   local $SIG{__WARN__} = sub { push @warnings, @_ };
   $entry = Text::BibTeX::Entry->new($bad);
}
ok(!$entry->parse_ok, 'entry with syntax error does not parse ok');
my @errors = $entry->errors;
is(scalar @errors, 2, 'two errors recorded');
isa_ok($errors[0], 'Text::BibTeX::Error');
is($errors[0]->errclass, BTERR_SYNTAX, 'syntax error class');
is($errors[0]->class, 'syntax error', 'class name');
is($errors[0]->severity, 'error', 'severity');
ok($errors[0]->is_serious, 'syntax errors are serious');
ok(!$errors[0]->is_fatal, 'syntax errors are not fatal');
is($errors[0]->line, 1, 'line number');
is($errors[0]->message, 'found "{x}", expected "="', 'message');
is($errors[1]->errclass, BTERR_CONTENT, 'undefined macro is a content warning');
is("$errors[1]", 'line 1, warning: undefined macro "foo"', 'stringification');
ok(!$errors[1]->is_serious, 'content warnings are not serious');

# ...and reported through Perl's warn(), in the traditional format
is(scalar @warnings, 2, 'errors reported as warnings');
is($warnings[0], "line 1, syntax error: found \"{x}\", expected \"=\"\n",
   'warning text');

# Reported by default, even where no warnings pragma is in effect: the
# string eval below is compiled without "use warnings"
{
   my (undef, $err) = capture {
      eval q{ BEGIN { ${^WARNING_BITS} = undef } Text::BibTeX::Entry->new($bad); 1 }
         or die $@;
   };
   like($err, qr/syntax error/, 'reported by default');
}

# Silenced with "no warnings 'Text::BibTeX'"
{
   my (undef, $err) = capture {
      no warnings 'Text::BibTeX';
      $entry = Text::BibTeX::Entry->new($bad);
   };
   is($err, '', "no warnings 'Text::BibTeX' silences errors");
   is(scalar $entry->errors, 2, '...but they are still recorded');
}
{
   my (undef, $err) = capture {
      no warnings;
      Text::BibTeX::Entry->new($bad);
   };
   is($err, '', 'plain "no warnings" silences errors too');
}

# Made fatal with "use warnings FATAL => 'Text::BibTeX'"
{
   use warnings FATAL => 'Text::BibTeX';
   my $e = eval { Text::BibTeX::Entry->new($bad) };
   isa_ok($@, 'Text::BibTeX::Error', 'FATAL warnings throw the error object');
   is($@->message, 'found "{x}", expected "="', '...the first one');
}

# Taken over by a handler
{
   my @seen;
   local $Text::BibTeX::Error::Handler = sub { push @seen, shift };
   my (undef, $err) = capture { Text::BibTeX::Entry->new($bad) };
   is($err, '', 'handler: nothing printed');
   is(scalar @seen, 2, 'handler: called for each error');
   isa_ok($seen[0], 'Text::BibTeX::Error');
}

# Errors go through Perl's STDERR (so they can be redirected in Perl,
# which was impossible when the C library wrote to stdio's stderr)
{
   my $buf = '';
   {
      local *STDERR;
      open STDERR, '>', \$buf or die;
      Text::BibTeX::Entry->new($bad);
      close STDERR;
   }
   like($buf, qr/^line 1, syntax error: found "\{x\}", expected "="$/m,
        'errors can be captured by redirecting STDERR in Perl');
}

# Usage errors are exceptions (they used to exit() the program)
eval { Text::BibTeX::change_case('x', 'foo') };
isa_ok($@, 'Text::BibTeX::Error', 'bad change_case transform');
ok($@->is_fatal, '...is fatal');
like("$@", qr/invalid transform "x".* at \S+ line \d+\.$/, '...with location');
eval { Text::BibTeX::NameFormat->new('fvljq') };
like($@, qr/invalid name format/, 'bad name format croaks');

# Messages have the file name when there is one
{
   my $bib = Text::BibTeX::File->new('t/data/regular.bib');
   my (undef, $err) = capture { $entry = Text::BibTeX::Entry->new($bib) };
   like($err, qr{^t/data/regular\.bib, line 5, warning: undefined macro "junk"$}m,
        'message includes the file name');
   is(($entry->errors)[0]->filename, 't/data/regular.bib', 'filename accessor');
}

# Name warnings carry the item number
{
   my @seen;
   local $Text::BibTeX::Error::Handler = sub { push @seen, shift };
   Text::BibTeX::split_list('John and and Jane', 'and', 'f.bib', 3, 'name');
   is(scalar @seen, 1, 'empty name warning');
   is("$seen[0]", 'f.bib, line 3, name 2, warning: empty name', 'item in message');
   is($seen[0]->item_desc, 'name', 'item_desc');
   is($seen[0]->item, 2, 'item');
}

# Inputs that used to crash or abort the old C library
{
   local $Text::BibTeX::Error::Handler = sub { };
   my $e = Text::BibTeX::Entry->new('@string{foo = "Foo"}');
   $e = Text::BibTeX::Entry->new;
   ok($e->parse_s('@preamble{ "x" # foo }', 1), 'preamble with macro, preserved (used to abort)');
   is(join('|', map { $_->text } $e->value->values), 'x|foo', '...values kept');

   for my $n ('Smith,, John', ',John Smith', ',,,', 'John,', ', , ,', 'a, b, c, d,,',
              '{', '}', '{{{', 'and', ' and and ', ',and,') {
      my $name = Text::BibTeX::Name->new($n);
      my $f = Text::BibTeX::NameFormat->new('vljf', 1);
      ok(defined $name->format($f), "malformed name '$n' (used to crash)");
   }
   my @names = Text::BibTeX::split_list('a  and  and   b', 'and');
   is(scalar @names, 3, 'doubled spaces around "and" (used to abort)');
   is_deeply([Text::BibTeX::split_list('John and and Jane', 'and')],
             ['John', undef, 'Jane'], 'consecutive "and"');
   $e = Text::BibTeX::Entry->new('@article{k, author = {John and and Jane}}');
   is(scalar(my @n = $e->names('author')), 3, 'names() with an empty name');
   is($n[1]->format(Text::BibTeX::NameFormat->new('fvlj')), '', '...formats as empty');
}

# Errors know the entry key and where Text::BibTeX was called from;
# name warnings from Entry->names number the names from 1
{
   my @seen;
   local $Text::BibTeX::Error::Handler = sub { push @seen, shift };
   my $e = Text::BibTeX::Entry->new('@misc{thekey, title = undefinedmac, author = {Smith and Jones, A, B, C}}');
   is($seen[0]->key, 'thekey', 'error knows the entry key');
   is($seen[0]->caller_file, __FILE__, 'caller_file');
   ok($seen[0]->caller_line > 0, 'caller_line');
   unlike("$seen[0]", qr/ at \S+ line/, 'non-fatal errors are not stringified with the caller');
   @seen = ();
   $e->names('author');
   is("$seen[0]", 'line 1, name 2, warning: too many commas in name (removing extras)',
      'second name is "name 2"');
}

# A name with no last name (eg. a stray leading comma) keeps its other
# parts and is warned about
{
   my @seen;
   local $Text::BibTeX::Error::Handler = sub { push @seen, shift };
   my $e = Text::BibTeX::Entry->new("\@misc{k,\n  author = {, M.F. and Smith, John}}");
   my @n = $e->names('author');
   is(scalar(my @f = $n[0]->part('first')), 1, 'leading comma: first name kept');
   is($n[0]->part('first'), 'M.F.', '...as the first name');
   ok(!defined $n[0]->part('last'), '...and no last name');
   is("$seen[0]", 'line 2, name 1, warning: name has no last name', 'warned about');
   is(scalar @seen, 1, 'other names are fine');
   is($n[1]->part('last'), 'Smith', 'next name unaffected');
}

# Inputs which BibTeX accepts: an entry with no fields, and "@comment"
# not followed by a braced comment (BibTeX ignores the word and treats
# what follows as text between entries)
{
   my $read = sub {
      my $text = shift;
      my @seen;
      local $Text::BibTeX::Error::Handler = sub { push @seen, shift };
      open my $fh, '<', \$text or die;
      my $bib = Text::BibTeX::File->new($fh);
      my @entries;
      while (my $e = Text::BibTeX::Entry->new($bib)) { push @entries, $e }
      return (\@entries, \@seen);
   };

   my ($e, $seen) = $read->("\@misc{nofields}\n\@misc{after, title={After}}\n");
   is(scalar @$seen, 0, 'entry with no fields: no error');
   is(join(',', map { $_->key } @$e), 'nofields,after', '...both entries read');
   ok($e->[0]->parse_ok, '...and parsed ok');
   is(scalar(my @f = $e->[0]->fieldlist), 0, '...with no fields');

   ($e, $seen) = $read->("\@comment some text here\n\@misc{after, title={After}}\n");
   is(scalar @$seen, 0, 'bare @comment: no error or junk warning');
   is(join(',', map { $_->key // '' } @$e), 'after', '...is skipped, the next entry is read');

   ($e, $seen) = $read->("\@misc{a, title={A}}\n\@comment at the end\n");
   is(scalar @$seen, 0, 'bare @comment at the end of the input');
   is(scalar @$e, 1, '...gives no entry');

   ($e, $seen) = $read->("\@comment{braced}\n\@comment(parens)\n\@misc{after, title={After}}\n");
   is(join(',', map { $_->metatype } @$e), join(',', BTE_COMMENT, BTE_COMMENT, BTE_REGULAR),
      'braced and parenthesised comments are still comment entries');

   ($e, $seen) = $read->("\@comment two\nlines\n\n\@misc{bad, title foo}\n");
   is($seen->[0] && $seen->[0]->line, 4, 'line numbers after a bare @comment are right');

   # ...but an unterminated braced comment is still an error, not a bare
   # comment (it would swallow the rest of the file silently)
   ($e, $seen) = $read->("\@comment{never closed\n\@misc{after, title={After}}\n");
   like($seen->[0] // '', qr/syntax error: at end of input/, 'unterminated @comment{ is still an error');
}

# Reusing an entry object starts a fresh error list
{
   local $Text::BibTeX::Error::Handler = sub { };
   my $e = Text::BibTeX::Entry->new;
   $e->parse_s($bad);
   ok(scalar $e->errors >= 1, 'errors from first parse');
   $e->parse_s('@misc{ok, title = {fine}}');
   is(scalar $e->errors, 0, 'no errors carried over to the next parse');
}

# An exception thrown while reading a tied handle propagates
{
   package DyingHandle;
   sub TIEHANDLE { bless {}, shift }
   sub READ { die "read failed\n" }
   sub CLOSE { 1 }
   package main;

   local *DIE;
   tie *DIE, 'DyingHandle';
   local $Text::BibTeX::Error::Handler = sub { };
   my $bib = Text::BibTeX::File->new(\*DIE);
   eval { Text::BibTeX::Entry->new($bib) };
   is($@, "read failed\n", 'exception from tied READ is rethrown');
}

done_testing;
