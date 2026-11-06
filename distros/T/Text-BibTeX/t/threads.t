# -*- cperl -*-
use strict;
use warnings;

use Config;
use Test::More;

BEGIN {
   plan skip_all => 'this perl does not support threads' unless $Config{useithreads};
   eval { require threads; threads->import; 1 }
      or plan skip_all => 'threads.pm not available';
}

use Text::BibTeX qw(:macrosubs);

$Text::BibTeX::Error::Handler = sub { };
add_macro_text('thr', 'Parent');
my $text = '@misc{k, author = {Jane Doe and John Smith}, note = thr # " " # jan}';

# Objects holding C structures are not cloned into new threads
my $bib = Text::BibTeX::File->new(\"$text");
my $name = Text::BibTeX::Name->new('Jane Doe');

my @results = map { $_->join } map {
   my $i = $_;
   threads->create(sub {
      add_macro_text('thr', "Thread $i", undef, 0) if $i % 2;
      my @out;
      for (1 .. 50) {
         my $e = Text::BibTeX::Entry->new($text);
         push @out, $e->get('note') . ' | '
            . join(', ', map { $_->format(Text::BibTeX::NameFormat->new('vljf', 1)) } $e->names('author'));
      }
      return $out[-1];
   })
} 1 .. 4;

is_deeply(\@results,
          ['Thread 1 January | Doe, J., Smith, J.',
           'Parent January | Doe, J., Smith, J.',
           'Thread 3 January | Doe, J., Smith, J.',
           'Parent January | Doe, J., Smith, J.'],
          'each thread has its own copy of the macro table');
is(macro_text('thr'), 'Parent', "threads don't change the parent's macros");
my $e = Text::BibTeX::Entry->new($bib);
is($e->key, 'k', "the parent's parser still works");
is($name->format(Text::BibTeX::NameFormat->new('l')), 'Doe', "the parent's names still work");

done_testing;
