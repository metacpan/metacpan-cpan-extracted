# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 29;
use Cwd;
BEGIN {
    use_ok('Text::BibTeX');
    my $common = getcwd()."/t/common.pl";
    require $common;
}

# ----------------------------------------------------------------------
# entry modification methods

my ($text, $entry, @warnings, @fieldlist);

$text = <<'TEXT';
@article{homer97,
  author = {Homer Simpson and Ned Flanders},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

ok($entry = Text::BibTeX::Entry->new);
ok($entry->parse_s ($text));

ok($entry->type eq 'article');
$entry->set_type ('book');
ok($entry->type eq 'book');

ok($entry->key eq 'homer97');
$entry->set_key ($entry->key . 'a');
ok($entry->key eq 'homer97a');

my @names = $entry->names ('author');
$names[0] = $names[0]->{'last'}[0] . ', ' . $names[0]->{'first'}[0];
$names[1] = $names[1]->{'last'}[0] . ', ' . $names[1]->{'first'}[0];
$entry->set ('author', join (' and ', @names));

my $author;
no_err( sub {
            $author = $entry->get ('author');
            is($author, 'Simpson, Homer and Flanders, Ned');
        });

no_err(
       sub {
           $entry->set (author => 'Foo Bar {and} Co.',
                        title  => 'This is a new title');
           ok($entry->get ('author') eq 'Foo Bar {and} Co.');
           ok($entry->get ('title') eq 'This is a new title');
           ok(slist_equal ([$entry->get ('author', 'title')],
                           ['Foo Bar {and} Co.', 'This is a new title']));
       }
      );

ok(slist_equal ([$entry->fieldlist], [qw(author title journal year)]));
ok($entry->exists ('journal'));

$entry->delete ('journal');
no_err sub {
    @fieldlist = $entry->fieldlist;
    ok(! $entry->exists ('journal'));
    ok(slist_equal (\@fieldlist, [qw(author title year)]));
};

err_like sub { $entry->set_fieldlist ([qw(author title journal year)]); },
  qr/implicitly adding undefined field \"journal\"/i;

no_err sub {
    @fieldlist = $entry->fieldlist;
    ok($entry->exists ('journal'));
    ok(! defined $entry->get ('journal'));
    ok(slist_equal (\@fieldlist, [qw(author title journal year)]));
};

$entry->delete ('journal', 'author', 'year');
no_err sub { @fieldlist = $entry->fieldlist; };
ok(! $entry->exists ('journal'));
ok(! $entry->exists ('author'));
ok(! $entry->exists ('year'));
is(scalar @fieldlist, 1);
is($fieldlist[0] ,'title');

