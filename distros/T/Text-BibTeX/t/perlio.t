# -*- cperl -*-
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempfile);
use Encode qw(encode);

use Text::BibTeX;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $text = <<'BIB';
@string{pub = "Größe Verlag"}
@article{café,
  author = {Émile Zola and Jürgen Habermas},
  title  = {Ünïcode} # " in " # pub,
  year   = 2001,
}
@book{second, title = {Two}}
BIB

sub read_all {
   my $bib = shift;
   my @entries;
   local $Text::BibTeX::Error::Handler = sub { push @{$_[0]{_t}}, 1 };
   while (my $e = Text::BibTeX::Entry->new($bib)) {
      push @entries, $e if $e->metatype == BTE_REGULAR;
   }
   return @entries;
}

sub check_entries {
   my ($label, @e) = @_;
   is(scalar @e, 2, "$label: two entries");
   is($e[0]->key, 'café', "$label: UTF-8 key");
   is($e[0]->get('title'), 'Ünïcode in Größe Verlag', "$label: UTF-8 value");
   is($e[1]->key, 'second', "$label: second entry");
}

# In-memory filehandle (did not work with the stdio-based parser)
{
   my $bytes = encode('UTF-8', $text);
   open my $fh, '<', \$bytes or die;
   my $bib = Text::BibTeX::File->new($fh);
   check_entries('in-memory handle', read_all($bib));
}

# A scalar reference as the "filename"
{
   my $bytes = encode('UTF-8', $text);
   check_entries('scalar ref', read_all(Text::BibTeX::File->new(\$bytes)));
}

# A handle with an :encoding layer delivers characters
{
   my ($tfh, $tname) = tempfile(UNLINK => 1);
   binmode $tfh;
   print $tfh encode('ISO-8859-1', $text);
   close $tfh;

   open my $fh, '<:encoding(ISO-8859-1)', $tname or die;
   check_entries(':encoding layer', read_all(Text::BibTeX::File->new($fh, { filename => $tname })));

   # ...or the "encoding" option does the same for a filename
   check_entries('encoding option',
                 read_all(Text::BibTeX::File->new($tname, { encoding => 'ISO-8859-1' })));

   # Read as UTF-8 it is invalid: bytes are replaced, with a warning
   my @w;
   local $Text::BibTeX::Error::Handler = sub { push @w, shift };
   my $bib = Text::BibTeX::File->new($tname);
   my $e;
   $e = Text::BibTeX::Entry->new($bib) until $e && $e->metatype == BTE_REGULAR;
   is($e->key, "caf\x{FFFD}", 'invalid UTF-8 replaced by U+FFFD');
   ok((grep { $_->message =~ /invalid UTF-8/ } @w), '...with a warning');

   # ...and in bytes mode it is passed through untouched
   $bib = Text::BibTeX::File->new($tname, { binmode => 'bytes' });
   $e = undef;
   $e = Text::BibTeX::Entry->new($bib) until $e && $e->metatype == BTE_REGULAR;
   is($e->key, "caf\xE9", 'bytes mode: raw bytes');
   ok(!utf8::is_utf8($e->key), 'bytes mode: byte string');
}

# Bytes mode on UTF-8 input gives UTF-8 encoded byte strings (as before)
{
   my $bytes = encode('UTF-8', $text);
   my $bib = Text::BibTeX::File->new(\$bytes, { binmode => 'bytes' });
   my ($e) = read_all($bib);
   is($e->key, encode('UTF-8', 'café'), 'bytes mode: UTF-8 bytes');
}

# A byte order mark is ignored
{
   my $bytes = "\xEF\xBB\xBF" . encode('UTF-8', $text);
   my @w;
   local $Text::BibTeX::Error::Handler = sub { push @w, shift };
   my $bib = Text::BibTeX::File->new(\$bytes);
   my $e = Text::BibTeX::Entry->new($bib);
   is($e->type, 'string', 'BOM skipped');
   is(scalar(grep { $_->message =~ /junk/ } @w), 0, '...without a junk warning');
}

# A tied filehandle
{
   package StringHandle;
   sub TIEHANDLE { my ($c, $s) = @_; bless { s => $s }, $c }
   sub READ {
      my ($self, undef, $len) = @_;
      my $chunk = substr($self->{s}, 0, 7, '');     # small, odd chunks
      $_[1] = $chunk;
      return length $chunk;
   }
   sub EOF { length($_[0]{s}) == 0 }
   sub CLOSE { 1 }
   package main;

   local *TIED;
   tie *TIED, 'StringHandle', encode('UTF-8', $text);
   check_entries('tied handle', read_all(Text::BibTeX::File->new(\*TIED)));
}

# Entry->parse with a raw filehandle
{
   local $Text::BibTeX::Error::Handler = sub { };
   my $bytes = encode('UTF-8', $text);
   open my $fh, '<', \$bytes or die;
   my @e;
   while (my $e = Text::BibTeX::Entry->new('mem.bib', $fh)) {
      push @e, $e if $e->metatype == BTE_REGULAR;
   }
   check_entries('Entry->parse', @e);
}

# eof() reflects what the parser has consumed
{
   local $Text::BibTeX::Error::Handler = sub { };
   my $bytes = encode('UTF-8', $text);
   my $bib = Text::BibTeX::File->new(\$bytes);
   my $n = 0;
   until ($bib->eof) {
      my $e = Text::BibTeX::Entry->new($bib) or last;
      $n++;
   }
   is($n, 3, 'eof() loop reads every entry');
}

# Macros are shared between files by default, or private on request
{
   Text::BibTeX::delete_macro('pub');
   my $first = '@string{pub = "First"}';
   my $second = '@misc{k, publisher = pub}';
   read_all(Text::BibTeX::File->new(\$first));
   my ($e) = read_all(Text::BibTeX::File->new(\$second));
   is($e->get('publisher'), 'First', 'macros shared between files');

   my $third = '@string{pub = "Third"} @misc{k, publisher = pub, month = jan}';
   ($e) = read_all(Text::BibTeX::File->new(\$third, { private_macros => 1 }));
   is($e->get('publisher'), 'Third', 'private macros: own definitions');
   is($e->get('month'), 'January', 'private macros: global macros visible');
   ($e) = read_all(Text::BibTeX::File->new(\$second));
   is($e->get('publisher'), 'First', 'private macros do not leak');
   Text::BibTeX::delete_macro('pub');
}

# Writing a file in utf-8 mode writes UTF-8
{
   my (undef, $tname) = tempfile(UNLINK => 1);
   my $out = Text::BibTeX::File->new($tname, { mode => '>' });
   my $e = Text::BibTeX::Entry->new;
   $e->set_metatype(BTE_REGULAR);
   $e->set_type('article');
   $e->set_key('ключ');
   $e->set(title => 'Größe');
   $e->write($out);
   $out->close;
   open my $fh, '<:raw', $tname or die;
   my $written = do { local $/; <$fh> };
   like($written, qr/\Q@{[encode('UTF-8', '@article{ключ,')]}\E/, 'key written as UTF-8');
   like($written, qr/\Q@{[encode('UTF-8', 'title = {Größe}')]}\E/, 'value written as UTF-8');
}

done_testing;
