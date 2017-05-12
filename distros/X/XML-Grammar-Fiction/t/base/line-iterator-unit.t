use strict;
use warnings;

use utf8;

use Test::More tests => 10;

use XML::Grammar::FictionBase::FromProto::Parser::LineIterator;

{
    # Taken from:
    # Project Gutenberg - The Adventures of Sherlock Holmes by
    # Sir Arthur Conan Doyle.
    # http://www.gutenberg.org/files/1661/1661-h/1661-h.htm#2
    my $text = <<"EOF";
I had called upon my friend, Mr. Sherlock Holmes, one day in the autumn of
last year and found him in deep conversation with a very stout,
florid-faced, elderly gentleman with fiery red hair. With an apology for my
intrusion, I was about to withdraw when Holmes pulled me abruptly into the
room and closed the door behind me.

“You could not possibly have come at a better time, my dear Watson,” he said
cordially.

“I was afraid that you were engaged.”

“So I am. Very much so.”

“Then I can wait in the next room.”

“Not at all. This gentleman, Mr. Wilson, has been my partner and helper in many
of my most successful cases, and I have no doubt that he will be of the utmost
use to me in yours also.”

The stout gentleman half rose from his chair and gave a bob of greeting, with a
quick little questioning glance from his small fat-encircled eyes.

“Try the settee,” said Holmes, relapsing into his armchair and putting his
fingertips together, as was his custom when in judicial moods. “I know, my dear
Watson, that you share my love of all that is bizarre and outside the
conventions and humdrum routine of everyday life. You have shown your relish
for it by the enthusiasm which has prompted you to chronicle, and, if you will
excuse my saying so, somewhat to embellish so many of my own little
adventures.”

“Your cases have indeed been of the greatest interest to me,” I observed.

“You will remember that I remarked the other day, just before we went into the
very simple problem presented by Miss Mary Sutherland, that for strange effects
    and extraordinary combinations we must go to life itself, which is always
far more daring than any effort of the imagination.”

“A proposition which I took the liberty of doubting.”

“You did, Doctor, but none the less you must come round to my view, for
otherwise I shall keep on piling fact upon fact on you until your reason breaks
down under them and acknowledges me to be right. Now, Mr. Jabez Wilson here has
been good enough to call upon me this morning, and to begin a narrative which
promises to be one of the most singular which I have listened to for some time.
You have heard me remark that the strangest and most unique things are very
often connected not with the larger but with the smaller crimes, and
occasionally, indeed, where there is room for doubt whether any positive crime
has been committed. As far as I have heard, it is impossible for me to say
whether the present case is an instance of crime or not, but the course of
events is certainly among the most singular that I have ever listened to.
Perhaps, Mr. Wilson, you would have the great kindness to recommence your
narrative. I ask you not merely because my friend Dr. Watson has not heard the
opening part but also because the peculiar nature of the story makes me anxious
to have every possible detail from your lips. As a rule, when I have heard some
slight indication of the course of events, I am able to guide myself by the
thousands of other similar cases which occur to my memory. In the present
instance I am forced to admit that the facts are, to the best of my belief,
unique.”

The portly client puffed out his chest with an appearance of some little pride
and pulled a dirty and wrinkled newspaper from the inside pocket of his
greatcoat. As he glanced down the advertisement column, with his head thrust
forward and the paper flattened out upon his knee, I took a good look at the
man and endeavoured, after the fashion of my companion, to read the indications
which might be presented by his dress or appearance.

EOF

    my $parser =
        XML::Grammar::FictionBase::FromProto::Parser::LineIterator->new;

    $parser->setup_text($text);

    # TEST
    is (${$parser->curr_line_ref()},
        qq{I had called upon my friend, Mr. Sherlock Holmes, one day in the autumn of\n},
        "curr_line_ref() returns the right value.",
    );

    # TEST
    is (pos(${$parser->curr_line_ref()}), 0,
        "The pos() of the line is set at the right value."
    );

    # TEST
    is ($parser->curr_pos(), 0, "->pos() returns the right value.");

    # TEST
    ok (scalar($parser->at_line_start()),
        "Parser is at line start.");

    {
        my ($l_ref, $pos) = $parser->curr_line_and_pos();

        # TEST
        is ($$l_ref,
            qq{I had called upon my friend, Mr. Sherlock Holmes, one day in the autumn of\n},
            "Line ref of ->curr_line_and_pos() is OK."
        );

        # TEST
        is ($pos, 0, "Pos of ->curr_line_and_pos() is OK.")
    }

    my $verdict = ${$parser->curr_line_ref()} =~ m{\G.*?(my f[^d]*d)}g;

    my $match = $1;

    # TEST
    ok ($verdict, 'Matched.');
    # TEST
    is ($match, 'my friend', 'Match is correct');
    # TEST
    is (substr(${$parser->curr_line_ref()}, $parser->curr_pos()),
        qq{, Mr. Sherlock Holmes, one day in the autumn of\n},
        'curr_pos() is correct.'
    );

    # TEST
    ok (!$parser->at_line_start(), "Not at line start.");
}
