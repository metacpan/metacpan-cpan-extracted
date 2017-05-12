package main; # keep it simple

# Copyright (C) 2006 OSoft, Inc.
# License: GPL

use Carp;

use warnings;
use strict;

use XML::Twig;

local $Test::Builder::Level = $Test::Builder::Level + 1;

my $book;
my %node;

=head1 Functions

These are in package main.

=head2 open_book

  $book = open_book($package, $file);

=cut

sub open_book {
  my ($package, $file) = @_;
  (-e $file) or die "missing '$file' file!";

  $book = $package->new();
  ok($book, 'constructor');
  ok($book->load_uri($file), 'load');

  $book;
} # end subroutine open_book definition
########################################################################


=head2 check_toc

  check_toc(\@title_list, \@id_list);

=cut

sub check_toc {
  my ($titles, $ids) = @_;
  $ids ||= $titles;

  # setup the data (I'm keeping the nodes list)
  %node = map({$_ => $book->find_toc($_)} @$ids);
  for(my $i = 0; $i < @$titles; $i++) {
    my $id = $ids->[$i];
    ok($node{$id}, 'got node');
    isa_ok($node{$id}, 'dtRdr::TOC');
    is($node{$id}->get_title, $titles->[$i], 'title check');
  }
} # end subroutine check_toc definition
########################################################################

sub expect_test {
  my ($id, $expect) = @_;
  my (undef,undef,$line) = caller;
  my $name = 'line '. $line;
  my $node = $node{$id};
  defined($node) or croak("ack");
  my $content = $book->get_content($node);
  $content = strip_html($content);
  is($content, $expect,               "content  ($name)");
} # end subroutine expect_test definition
########################################################################

sub like_test {
  my ($id, $expect) = @_;

  $expect =~ s/ /\\s+/g;
  $expect = qr/^$expect$/s;
  my (undef,undef,$line) = caller;
  my $name = 'line '. $line;
  my $node = $node{$id};
  defined($node) or croak("ack");
  my $content = $book->get_content($node);
  $content = strip_html2($id, $content);
  like($content, $expect,               "content  ($name)");
} # end subroutine expect_test definition
########################################################################

=head2 wrange_test

  wrange_test($node_id, $start, $end);

=cut

sub wrange_test {
  my ($id, $start, $end) = @_;
  my $node = $node{$id};
  defined($node) or croak("ack");

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is($node->word_start, $start, 'start');
  is($node->word_end, $end, 'end');
} # end subroutine wrange_test definition
########################################################################

sub strip_html {
  my ($content) = @_;
  if(0) {
  $content =~ s{.*<body>}{}s;
  $content =~ s{</body>.*}{}s;
  $content =~ s/<[^>]+>//gs;
  $content =~ s/\s+//gs;
  }
  else {
    my $got = '';
    my $twig = XML::Twig->new(keep_spaces => 0,
      twig_handlers => {
        'body' => sub {
          my ($o, $bit) = @_;
          my $t = $bit->xml_text;
          $got .=  (defined($t) ? $t : '');
        },
      }
    );
    $twig->parse($content);
    $content = $got;
  }
  return($content);
}
########################################################################

=head2 strip_html2

Grab the text from a given pkg:outlineMarker $id

  $content = strip_html2($id, $content);

=cut

sub strip_html2 {
  my ($id, $content) = @_;
  my $got = '';
  my $twig = XML::Twig->new(keep_spaces => 1,
    twig_handlers => {
      qq(pkg:outlineMarker[\@id="$id"]) => sub {
        my ($o, $bit) = @_;
        my $t = $bit->xml_text;
        $got .=  (defined($t) ? $t : '');
      },
    }
  );
  $twig->parse($content);
  return($got);
} # end subroutine strip_html2 definition
########################################################################


sub tq { # test quoter -- shorthand for all of that hash stuff
  my ($v) = @_;
  my @d;
  if(ref($v)) {
    @d = @$v;
  }
  else {
    $v =~ s/^ //;
    $v =~ s/ $//;
    @d = split(/ +/, $v);
  }
  my @map = qw(node string lwing rwing lands start end);
  (@d == @map) or die;
  # needed a shorthand for '' in qw
  $_ = (($_ eq '-') ? '' : $_) for @d;
  my %stuff = map({$map[$_] => $d[$_]} 0..$#map);
  $stuff{$_} = $node{$stuff{$_}} for qw(node lands);
  return(%stuff);
}

sub find_test {
  my %d;
  if(1 == @_) { # string
    %d = tq(@_);
  }
  else {
    %d = @_;
  }

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my (undef,undef,$line) = caller;
  my $name = $d{testname} || 'line '. $line;

  my $node = $d{node};
  my $range = $book->locate_string($node, $d{string}, $d{lwing}, $d{rwing});

  ok(eval{$range->isa('dtRdr::Range')}, "isa      ($name)");
  is($range->node->id, $d{lands}->id,   "lands in ($name)") or return;
  is($range->a, $d{start},              "start    ($name)");
  is($range->b, $d{end},                "end      ($name)");
  return($range);
}
########################################################################

=head2 highlight

  my $hl = highlight($range);

=cut

sub highlight {
  my ($range) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $highlight = dtRdr::Highlight->claim($range);
  isa_ok($highlight, 'dtRdr::Highlight');
  $book->add_highlight($highlight);
  return($highlight);
} # end subroutine highlight definition
########################################################################

sub mk_note {
  my ($range) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $note = dtRdr::Note->claim($range);
  isa_ok($note, 'dtRdr::Note');
  $book->add_note($note);
  return($note);
} # end subroutine mk_note definition
########################################################################

sub mk_bookmark {
  my ($range) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $note = dtRdr::Bookmark->claim($range);
  isa_ok($note, 'dtRdr::Bookmark');
  $book->add_bookmark($note);
  return($note);
} # end subroutine mk_bookmark definition
########################################################################

=head2 highlight_test

  highlight_test($node_id, $string);

=cut

sub highlight_test {
  my ($id, $string) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $node = $node{$id};
  my $content = eval { $book->get_content($node)};
  unless(ok(! $@, "survived get_content")) {
    warn 'oops ' . $@;
    return;
  }

  if($ENV{"DBG_$id"}) {
    # XXX really needs to use a dtRdr::Logger->dump(...) or something
    open(my $f, '>:utf8', '/tmp/thecontent');
    print $f $content;
  }

  my $found = '';
  my $twig = XML::Twig->new(
    keep_spaces => 1, # required!
    twig_handlers => {
      span => sub {
        my ($o, $bit) = @_;
        my $class = $bit->att('class');
        # warn "class: $class"; 
        ($class =~ m/^dr_highlight /) or return;
        my $t = $bit->xml_text; # we're expecting &lt; &amp; as xml
        $found .=  (defined($t) ? $t : '');
      },
    });
  $twig->parse($content);
  $found =~ s/\s+/ /gs;
  is($found, $string, 'highlighted the right string');
} # end subroutine highlight_test definition
########################################################################

=head2 note_test

  note_test($id, $string);

=cut

sub note_test {
  my ($id, $string) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $node = $node{$id};
  my $content = eval { $book->get_content($node)};
  unless(ok(! $@, "survived get_content")) {
    warn 'oops ' . $@;
    return;
  }

  if($ENV{"DBG_$id"}) {
    # XXX really needs to use a dtRdr::Logger->dump(...) or something
    open(my $f, '>:utf8', '/tmp/thecontent');
    print $f $content;
  }

  my $found = '';
  my $note_count = 0;
  my $twig = XML::Twig->new(
    keep_spaces => 1, # required!
    twig_handlers => {
      span => sub {
        my ($o, $bit) = @_;
        my $class = $bit->att('class');
        # warn "class: $class"; 
        ($class =~ m/^dr_note /) or return;
        my $t = $bit->xml_text; # we're expecting &lt; &amp; as xml
        $found .=  (defined($t) ? $t : '');
      },
      a => sub {
        my ($o, $bit) = @_;
        my $href = $bit->att('href');
        $href or return;
        # TODO check for ID here or something
        ($href =~ m#^dr://.*\.drnt$#) and ($note_count++);
      }
    });
  $twig->parse($content);
  $found =~ s/\s+/ /gs;
  is($found, $string, 'noted the right string');
  is($note_count, 1, 'found an href');
} # end subroutine note_test definition
########################################################################

sub bookmark_test {
  my ($id, $string) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $node = $node{$id};
  my $content = eval { $book->get_content($node)};
  unless(ok(! $@, "survived get_content")) {
    warn 'oops ' . $@;
    return;
  }

  if($ENV{"DBG_$id"}) {
    # XXX really needs to use a dtRdr::Logger->dump(...) or something
    open(my $f, '>:utf8', '/tmp/thecontent');
    print $f $content;
  }

  my $found = '';
  my $bm_count = 0;
  my $twig = XML::Twig->new(
    keep_spaces => 1, # required!
    twig_handlers => {
      span => sub {
        my ($o, $bit) = @_;
        my $class = $bit->att('class');
        # warn "class: $class"; 
        ($class =~ m/^dr_bookmark /) or return;
        my $t = $bit->xml_text; # we're expecting &lt; &amp; as xml
        $found .=  (defined($t) ? $t : '');
      },
      a => sub {
        my ($o, $bit) = @_;
        my $href = $bit->att('href');
        $href or return;
        # TODO check for ID here or something
        ($href =~ m#^dr://.*\.drbm$#) and ($bm_count++);
      }
    });
  $twig->parse($content);
  $found =~ s/\s+/ /gs;
  is($found, $string, 'noted the right string');
  is($bm_count, 1, 'found an href');
} # end subroutine bookmark_test definition
########################################################################

# vim:ts=2:sw=2:et:sta
1;
