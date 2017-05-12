use Test::More tests => 6;
use Test::use::ok;
use strict;
use warnings;

use ok qw(Text::Cloze);

my $text = <<'';
  Down, down, down.  There was nothing else to do, so Alice soon
  began talking again.  `Dinah'll miss me very much to-night, I
  should think!'  (Dinah was the cat.)  `I hope they'll remember
  her saucer of milk at tea-time.  Dinah my dear!  I wish you were
  down here with me!  There are no mice in the air, I'm afraid, but
  you might catch a bat, and that's very like a mouse, you know.
  But do cats eat bats, I wonder?'  And here Alice began to get
  rather sleepy, and went on saying to herself, in a dreamy sort of
  way, `Do cats eat bats?  Do cats eat bats?' and sometimes, `Do
  bats eat cats?' for, you see, as she couldn't answer either
  question, it didn't much matter which way she put it.  She felt
  that she was dozing off, and had just begun to dream that she
  was walking hand in hand with Dinah, and saying to her very
  earnestly, `Now, Dinah, tell me the truth:  did you ever eat a
  bat?' when suddenly, thump! thump! down she came upon a heap of
  sticks and dry leaves, and the fall was over.

my $clozed = <<'';
  Down, down, down.  There was nothing else _______________ do, so Alice soon
  _______________ talking again.  `Dinah'll miss _______________ very much to-night, I
  _______________ think!'  (Dinah was the _______________.)  `I hope they'll remember
  _______________ saucer of milk at _______________.  Dinah my dear!  I _______________ you were
  down here _______________ me!  There are no _______________ in the air, I'm _______________, but
  you might catch _______________ bat, and that's very _______________ a mouse, you know.
  _______________ do cats eat bats, _______________ wonder?'  And here Alice _______________ to get
  rather sleepy, _______________ went on saying to _______________, in a dreamy sort _______________
  way, `Do cats eat _______________?  Do cats eat bats?' _______________ sometimes, `Do
  bats eat _______________?' for, you see, as _______________ couldn't answer either
  question, _______________ didn't much matter which _______________ she put it.  She felt
  that she was dozing off, and had just begun to dream that she
  was walking hand in hand with Dinah, and saying to her very
  earnestly, `Now, Dinah, tell me the truth:  did you ever eat a
  bat?' when suddenly, thump! thump! down she came upon a heap of
  sticks and dry leaves, and the fall was over.


my $cloze = Text::Cloze->new;
isa_ok $cloze, 'Text::Cloze';
isa_ok $cloze, 'CODE';
is $cloze->( $text ), $clozed, "cloze correct";
is [ $cloze->( $text ) ]->[6], 'Tea-time', 'correct time';
is scalar @{[ $cloze->( $text ) ]}, 26, 'correct # of returns';
