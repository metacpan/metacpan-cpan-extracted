package Text::Conversation;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.050';

use Lingua::StopWords::EN qw(getStopWords);
use Lingua::Stem::Snowball qw(stem);
use String::Approx qw(amatch adistr);

use constant CT_STOPWORDS     => 0;
use constant CT_CONTEXT       => 1;
use constant CT_NICKS         => 2;
use constant CT_IDS           => 3;
use constant CT_CONTEXT_MAX   => 4;
use constant CT_WORDS         => 5;
use constant CT_WORDS_TOTAL   => 6;
use constant CT_DEBUG         => 7;

use constant CTX_ID         => 0;
use constant CTX_NICK       => 1;
use constant CTX_ADDRESSEE  => 2;
use constant CTX_WORDS      => 3;

use constant ID_REFERENT    => 0;
use constant ID_REFERERS    => 1;
use constant ID_TEXT        => 2;
use constant ID_NICK        => 3;

### Manage scrollback.

# The next ID is package static so messages will be unique across all
# threaders.

my $next_id = "a";

sub new {
	my ($class, %args) = @_;

	$args{thread_buffer} ||= 30;

	my $self = bless [
		undef,              # CT_STOPWORDS
		[ ],                # CT_CONTEXT
		{ },                # CT_NICKS
		{ },                # CT_IDS
		$args{thread_buffer} || 30, # CT_CONTEXT_MAX
		{ },                # CT_WORDS
		0,                  # CT_WORDS_TOTAL
		$args{debug} || 0,  # CT_DEBUG
	], $class;

	# Stem stopwords.

	my $stopwords = getStopWords();
	my %stopwords;

	foreach my $stopword (keys %$stopwords) {
#		$stopwords{$self->_word_stem($stopword)}++;
	}

	$self->[CT_STOPWORDS] = \%stopwords;

	return $self;
}

#sub hear {
#	my ($self, $nick, $ident, $host, $text) = @_;
#}
#
#sub see {
#	my ($self, $nick, $ident, $host, $text) = @_;
#}
#
#sub rename {
#	my ($self, $old_nick, $new_nick, $ident, $host) = @_;
#}
#
#sub arrival {
#	my ($self, $nick, $ident, $host) = @_;
#}
#
#sub departure {
#	my ($self, $nick, $ident, $host) = @_;
#}

sub observe {
	my ($self, $nick, $text) = @_;

	# IRC nicks are case-insensitive.
	$nick = $self->_nick_fix($nick);

	if ($self->[CT_DEBUG]) {
		warn ">>>> <$nick> $text\n";
	}

	# Extract non-stopwords from spoken text.
	#
	# TODO - Determine stopwords dynamically from observed context.  Or
	# perhaps generate stopwords from some logs.
	#
	# Stem the words here, so they go into the system as stems.

	my $words_text = lc($text);
	$words_text =~ s/[^\w\s]+/ /g;

	my %my_words;
	foreach my $word (
		grep { ! exists $self->[CT_STOPWORDS]{$_} }
		map { $self->_word_stem($_) }
		grep { length() > 1 }
		split /\s+/, $words_text
	) {
		$my_words{$word}++;
	}

	my @my_words = keys %my_words;

	# Find explicit addressees.

	my $addressee_text = lc($text);

	my $best_addressee       = "";
	my $best_addressee_score = 0;

	# Nickname starts the line.

	if (
		($addressee_text =~ /^\s*(\S+?)\s*[:,]\s+/) or
		($addressee_text =~ /^\s*(\S+?)-*\s+/) or
		($addressee_text =~ /^\s*t\s+(\S+?)\s+/)
	) {
		my $test = $self->_nick_fix($1);
		if ($self->[CT_DEBUG]) {
			warn "<ad> pre($test)\n";
		}
		my ($best_nick, $best_nick_score) = $self->_nick_exists($test);

		# Best addressee score is 3x because the nick is at the start.
		$best_nick_score *= 3;

		if ($best_nick_score > $best_addressee_score) {
			if ($self->[CT_DEBUG]) {
				warn(
					"<ad> found $test ",
					"($best_nick = $best_nick_score > $best_addressee_score)\n"
				);
			}
			$best_addressee       = $best_nick;
			$best_addressee_score = $best_nick_score;
		}
	}

	# Nickname ends the line.

	if ($addressee_text =~ /[\s,]*(\S+?)[.?!'")\]\}\s]*$/) {
		my $test = $self->_nick_fix($1);
		if ($self->[CT_DEBUG]) {
			warn "<ad> post($test)\n";
		}
		my ($best_nick, $best_nick_score) = $self->_nick_exists($test);

		# Best addressee score is 2x because the nick is at the end.
		$best_nick_score *= 2;

		if ($best_nick_score > $best_addressee_score) {
			if ($self->[CT_DEBUG]) {
				warn(
					"<ad> found $test ",
					"($best_nick = $best_nick_score > $best_addressee_score)\n"
				);
			}
			$best_addressee       = $best_nick;
			$best_addressee_score = $best_nick_score;
		}
	}

	# Nickname occurs somewhere in the middle.

	while ($addressee_text =~ m/\s*,\s*(\S+?)\s*[,!?.]\s*/g) {
		my $test = $self->_nick_fix($1);
		if ($self->[CT_DEBUG]) {
			warn "<ad> in($test)";
		}
		my ($best_nick, $best_nick_score) = $self->_nick_exists($test);

		if ($best_nick_score > $best_addressee_score) {
			if ($self->[CT_DEBUG]) {
				warn(
					"<ad> found $test ",
					"($best_nick = $best_nick_score > $best_addressee_score)\n"
				);
			}
			$best_addressee       = $best_nick;
			$best_addressee_score = $best_nick_score;
		}
	}

	if ($self->[CT_DEBUG]) {
		warn "<ad> best addressee score = $best_addressee_score\n";
	}

	# TODO - If an implied statement goes to nobody, then perhaps it's a
	# continuation of the last statement they said?

	my $seen_them_factor  = 0;
	my $seen_me_factor    = 0;
	my $seen_other_factor = 0;

	my $best_score = 0;
	my $best_index;

	my $index = @{$self->[CT_CONTEXT]};
	while ($index--) {
		my $context = $self->[CT_CONTEXT][$index];
		my $them    = $context->[CTX_NICK];

		# Figure out speaker/them affinity.

		my $affinity = $self->_nick_score($nick, $them);

		my $match_factor = $self->_correlate_statements(
			\@my_words, $context->[CTX_WORDS]
		);

		my $distance_factor = @{$self->[CT_CONTEXT]} - $index;

		my $addressee_score = 0;
		$addressee_score = $best_addressee_score if $them eq $best_addressee;

		# Weigh factors.

		my $weighted_addressee  = $addressee_score  * 30;
		my $weighted_affinity   = $affinity         * 45;  # half addressee
		my $weighted_match      = $match_factor     * 30;
		my $weighted_seen_them  = $seen_them_factor * -3;
		my $weighted_seen_me    = $seen_me_factor   * -3;
		my $weighted_distance   = $distance_factor  * -1;

		# Calculate a weighted score.

		my $score = (
			$weighted_affinity  +
			$weighted_addressee +
			$weighted_match     +
			$weighted_seen_them +
			$weighted_seen_me   +
			$weighted_distance
		);

		if ($score > $best_score) {
			$best_score = $score;
			$best_index = $index;
		}

		my $out = sprintf(
			( "<wf> aff(%9.3f) addr(%9.3f) match(%9.3f) " .
				"sthem(%9.3f) sme(%9.3f) dst(%9.3f) " .
				"score(%9.3f) best(%9.3f) "
			),
			$weighted_affinity, $weighted_addressee, $weighted_match,
			$weighted_seen_them, $weighted_seen_me, $weighted_distance,
			$score, $best_score,
		);

		$out .= substr(
			$self->_id_get_text($context->[CTX_ID]), 0, 156 - length($out) - 2
		);

		if ($self->[CT_DEBUG]) {
			warn $out, "\n";
		}

		# Serious penalties for passing people by.
		if ($nick eq $them) {
			if ($seen_other_factor) {
				$seen_me_factor++;
			}
		}
		else {
			$seen_other_factor++;
		}
	}

	return $self->process_match(
		$best_index, $nick, $text, \%my_words, $best_score
	);
}

sub _context_get_id {
	my ($self, $index) = @_;
	return $self->[CT_CONTEXT][$index][CTX_ID];
}

sub _context_get_nick {
	my ($self, $index) = @_;
	return $self->[CT_CONTEXT][$index][CTX_NICK];
}

### Manage seen nicks.

# Add a nickname to the database, or update the confidence between
# $nick and $addressee of an existing nickname.

sub _nick_add {
	my ($self, $nick, $addressee, $confidence) = @_;

	# Make sure the nick exists.
	unless (exists $self->[CT_NICKS]{$nick}) {
		$self->[CT_NICKS]{$nick} = { };
	}

	if (
		defined($addressee) and
		!exists($self->[CT_NICKS]{$addressee})
	) {
		$self->[CT_NICKS]{$addressee} = { };
	}

	# Decay everybody.  This is a lousy O(N**2) problem.
	foreach my $me (keys %{$self->[CT_NICKS]}) {
		foreach my $them (keys %{$self->[CT_NICKS]{$me}}) {
			$self->_nick_decay_link($me, $them);
		}
	}

	# Average in the new confidence.
	if (defined $addressee) {
		if (exists $self->[CT_NICKS]{$addressee}{$nick}) {
			if ($self->[CT_NICKS]{$addressee}{$nick} < $confidence) {
				$self->[CT_NICKS]{$addressee}{$nick} = $confidence;
			}
		}
		else {
			$self->[CT_NICKS]{$addressee}{$nick} = $confidence;
		}

		if (exists $self->[CT_NICKS]{$nick}{$addressee}) {
			if ($self->[CT_NICKS]{$nick}{$addressee} < $confidence) {
				$self->[CT_NICKS]{$nick}{$addressee} = $confidence;
			}
		}
		else {
			$self->[CT_NICKS]{$nick}{$addressee} = $confidence;
		}
	}
}

sub _nick_decay_link {
	my ($self, $me, $them) = @_;
	$self->[CT_NICKS]{$me}{$them} /= 4;
	if ($self->[CT_NICKS]{$me}{$them} < 1) {
		delete $self->[CT_NICKS]{$me}{$them};
	}
}

sub _nick_del {
	my $nick = shift;
	# Nothing?
}

# The score is the average of the speaker/other and other/speaker
# links.  It must be a number from 0 through 1.

sub _nick_score {
	my ($self, $speaker, $other) = @_;

	# Speaker to other.

	my $total_speaker_to_other = 0;
	my $speaker_to_other = 0;

	if (
		exists($self->[CT_NICKS]{$speaker}) and
		exists($self->[CT_NICKS]{$speaker}{$other})
	) {
		$speaker_to_other = $self->[CT_NICKS]{$speaker}{$other};
		foreach my $audience (keys %{$self->[CT_NICKS]{$speaker}}) {
			$total_speaker_to_other += $self->[CT_NICKS]{$speaker}{$audience};
		}
	}

	# Other from speaker.

	my $total_other_to_speaker = 0;
	my $other_to_speaker = 0;

	if (
		exists($self->[CT_NICKS]{$other}) and
		exists($self->[CT_NICKS]{$other}{$speaker})
	) {
		$other_to_speaker = $self->[CT_NICKS]{$other}{$speaker};
		foreach my $them (keys %{$self->[CT_NICKS]{$other}}) {
			$total_other_to_speaker += $self->[CT_NICKS]{$other}{$them};
		}
	}

	# If the total of the totals is zero, then avoid the division by
	# zero.

	my $total_total = $total_speaker_to_other + $total_other_to_speaker;
	return 0 unless $total_total;

	return( ($speaker_to_other + $other_to_speaker) / $total_total );
}

sub _nick_fix {
	my ($self, $nick) = @_;

	my $fixed_nick = lc($nick);
	$fixed_nick =~ s/^q\[(\S+)]$/$1/;   # q[nick] remove the quotes
	$fixed_nick =~ s/[^A-Za-z0-9]*$//;  # remove trailing junk
	$fixed_nick =~ s/^[^A-Za-z0-9]*//;  # remove leading junk

	# If it's all junk, return it lowercased.
	$fixed_nick = lc($nick) unless length $fixed_nick;

	return $fixed_nick;
}

# Does a nickname exist?  Return a new new nickname and a number
# between 0 and 1 that tells how much the given nickname matches it.

sub _nick_exists {
	my ($self, $nick) = @_;

	# No match if nothing here.  Keeps amatch() from bailing.
	my @known_nicks = keys %{$self->[CT_NICKS]};
	return (undef, 0) unless @known_nicks;

	# Often a nickname is a shortened version of some other.  Sometimes
	# it's an extended version of it.  Other times it's a bastardization
	# of a known nickname.
	#
	# Find all the nicknames that begin with the specified nickname.
	#
	# TODO - If there are none, try string distances?  Is there a better
	# way to hash string distances with lengths?

	my @found = grep /^\Q$nick/, @known_nicks;

	# Never did find nothin'.
	return (undef, 0) unless @found;

	if ($self->[CT_DEBUG]) {
		warn "<ni> $nick matches (@found)\n";
	}

	# Find the best match out of the found matches.  "Best match" is a
	# combination of string distance and ratio of entered nick to match.

	my @proximities = map { 1 - $_ } adistr($nick, @found);

	if ($self->[CT_DEBUG]) {
		warn "<ni> $nick proximities (@proximities)\n";
	}

	my ($best_nick, $best_score) = ("", 0);
	while (@found) {
		die unless @found == @proximities;
		my $match = shift @found;
		my $prox  = shift @proximities;

		# Words closer to the input length score higher.
		# Squared so it diminishes faster.
		my $length_score = (length($nick) / length($match)) ** 2;

		my $score = $prox * $length_score;
		next if $score < $best_score;

		if ($self->[CT_DEBUG]) {
			warn "<ni> $prox * $length_score = $score\n";
		}

		$best_nick  = $match;
		$best_score = $score;
	}

	if ($best_nick) {
		if ($self->[CT_DEBUG]) {
			warn "<ni> $nick = $best_nick ($best_score)\n";
		}
		return ($best_nick, $best_score);
	}

	if ($self->[CT_DEBUG]) {
		warn "<ni> $nick not found\n";
	}
	return (undef, 0);
}

### Manage known IDs.

sub _id_fully_qualified {
	my ($self, $id) = @_;

	my @key;
	while ($id) {
		unshift @key, $id;
		$id = $self->[CT_IDS]{$id}[ID_REFERENT];
	}

	return join "/", @key;
}

sub _id_add {
	my ($self, $id, $referent, $nick, $text) = @_;

	$self->[CT_IDS]{$id} = [
		$referent,  # ID_REFERENT
		[ ],        # ID_REFERERS
		$text,      # ID_TEXT
		$nick,      # ID_NICK
	];

	if ($referent and exists $self->[CT_IDS]{$referent}) {
		push @{$self->[CT_IDS]{$referent}[ID_REFERERS]}, $id;
	}
}

sub _id_del {
	my ($self, $id) = @_;

	my $old = delete $self->[CT_IDS]{$id};

	# Fix the statement's kids to stop pointing at the parent.

	foreach my $referer (@{$old->[ID_REFERERS]}) {
		$self->[CT_IDS]{$referer}[ID_REFERENT] = undef;
	}
}

sub _id_get_referent {
	my ($self, $id) = @_;
	return $self->[CT_IDS]{$id}[ID_REFERENT];
}

sub _id_get_nick {
	my ($self, $id) = @_;

# XXX - Happens when someone explicitly addresses a nickname that
# hasn't appeared yet.
#
# Use of uninitialized value in hash element at ChatThread.pm line 352.

	return $self->[CT_IDS]{$id}[ID_NICK];
}

sub _id_exists {
	my ($self, $id) = @_;
	return exists $self->[CT_IDS]{$id};
}

sub _id_get_text {
	my ($self, $id) = @_;
	return $self->[CT_IDS]{$id}[ID_TEXT];
}

sub _id_list {
	my $self = shift;

	# We do this rather than keys of CT_IDS because it's always
	# guaranteed to be in time order.  That is, referents come before
	# stuff that refers to them.
	return map { $_->[CTX_ID] } @{$self->[CT_CONTEXT]};
}

# Fuzzy match text.
#
# The current idea is to return a number that represents how much of
# @$my_words matches %$their_words;  Each matching word multiplied by
# a per-word score that reflects the uniqueness of that word.

sub _correlate_statements {
	my ($self, $my_words, $their_words) = @_;

	my $match_factor = 0;
	my $total_words  = @$my_words || 1;

	foreach my $my_word (@$my_words) {
		next unless exists $their_words->{$my_word};
		$match_factor += $self->_word_get_score($my_word);
	}

	return $match_factor / $total_words;
}

###

sub process_match {
	my ($self, $index, $nick, $text, $my_words, $confidence) = @_;

	my $id = $next_id++;

	my ($referent, $addressee, $print_addressee);

	if (defined $index) {
		$referent      = $self->_context_get_id($index);
		$addressee     = $self->_context_get_nick($index);

		# If the person refers to themselves, refer them instead to
		# whoever they were talking to previously.
		if ($addressee eq $nick) {
			if ($self->_id_exists($referent)) {
				$referent  = $self->_id_get_referent($referent);
				$addressee = $self->_id_get_nick($referent);
			}
			else {
				$referent = $addressee = undef;
			}
		}
	}

	if (defined $addressee) {
		$print_addressee = $addressee;
	}
	else {
		$print_addressee = "(nobody)";
	}

	if ($self->[CT_DEBUG]) {
		warn "<<<< ($id) $nick -> $print_addressee : $text\n";
	}

	# XXX - _context_add() ?
	push @{$self->[CT_CONTEXT]}, [
		$id,          # CTX_ID
		$nick,        # CTX_NICK
		$addressee,   # CTX_ADDRESSEE
		$my_words,    # CTX_WORDS
		$referent,    # CTX_REFERENT
	];

	my $debug_text = "<$nick> $text";

	$self->_nick_add($nick, $addressee, $confidence);
	$self->_id_add($id, $referent, $nick, $debug_text);
	$self->_words_add($my_words);

	# XXX - _context_prune() ?
	# XXX - Deleting the words here is a cheezy way to decay word
	# importance over time.
	while (@{$self->[CT_CONTEXT]} > $self->[CT_CONTEXT_MAX]) {
		my $old = shift @{$self->[CT_CONTEXT]};
		$self->_nick_del($old->[CTX_NICK]);
		$self->_words_del($old->[CTX_WORDS]);
		$self->_id_del($old->[CTX_ID]);
	}

	return (
		$id,          # new ID
		$referent,    # referent ID
		$debug_text,  # display text
	);
}

### Manage words, for frequency and feature extraction.

sub _word_stem {
	my ($self, $word) = @_;
	my $stem = stem("en", $word);
	return $stem;
}

sub _words_add {
	my ($self, $words) = @_;

	foreach my $word (keys %$words) {
		$self->[CT_WORDS_TOTAL]   += $words->{$word};
		$self->[CT_WORDS]{$word}  += $words->{$word};
	}
}

sub _words_del {
	my ($self, $words) = @_;

	# XXX - Experimenting with building a huge corpus.
	return;

	foreach my $word (keys %$words) {
		$self->[CT_WORDS_TOTAL]   -= $words->{$word};
		$self->[CT_WORDS]{$word}  -= $words->{$word};
		next if $self->[CT_WORDS]{$word} > 0;
		delete $self->[CT_WORDS]{$word};
	}
}

# The word's score increases as its frequency decreases.

sub _word_get_score {
	my ($self, $stem) = @_;

	my $word_count   = $self->[CT_WORDS]{$stem} || 0;
	my $corpus_count = $self->[CT_WORDS_TOTAL]  || 1;

	my $word_score = ($corpus_count - $word_count) / $corpus_count;
	if (exists $self->[CT_STOPWORDS]{$stem}) {
		$word_score /= 2;
	}

	return $word_score;
}

1;

__END__

=head1 NAME

Text::Conversation - Turn a conversation into threads, one line at a time.

=head1 VERSION

version 0.053

=head1 SYNOPSIS

	#!perl

	use warnings;
	use strict;
	use Text::Conversation;

	my $threader = Text::Conversation->new();

	my %messages;

	while (<STDIN>) {
		next unless
			my ($speaker_name, $their_text) = /^(\S+)\s+(\S.*?)\s*$/;

		my ($this_message_id, $referent_message_id) =
			$threader->observe($speaker_name, $their_text);
		$messages{$this_message_id} = "<$speaker_name> $their_text";

		print $messages{$this_message_id}, "\n";
		if ($referent_message_id) {
			print "  refers to: $messages{$referent_message_id}\n";
		}
		else {
			print "  doesn't refer to anything.\n";
		}
	}

=head1 DESCRIPTION

Text::Conversation attempts to thread conversational text one line at
a time.  Given a speaker's ID (often a name, screen name, or other
relatively unique identifier) and the text of their message, it
attempts to find the most likely message they are referring to.  It
will also indicate times when it cannot find a referent.

The most common question so far is "How does it work?"  That's often
followed by the leading "Does it just look for another speaker's ID at
the start of the message?"  Text::Conversation uses multiple
heuristics to determine a message's referent.  To be sure, the
presence of another speaker's ID counts for a lot, but so do common
words between two messages.  Consider them similar to quoted text in
an e-mail message.

Text::Conversation also keeps track of people who have spoken to each
other, either explicitly or implicitly.  Chances are good that an
otherwise undirected message is aimed at a person and is part of an
ongoing conversation.

The module also incorporates penalties.  The link between two messages
is degraded more as the module searches farther back in time.
Likewise, there are penalties for referring to messages beyond the
speaker's previous message, or the addressee's.

Text::Conversation is considered by its author to be "beta" quality
code.  The heuristics are often uncannily accurate... if you
steadfastly ignore their shortcomings.  I am trapped in a module
factory.  Please send feedback and patches.

=head1 INTERFACE

So, like, what are the methods?  So far the module only supports
these.  I'm sure others will emerge as people use the module.

=over 2

=item new NAMED_PARAMETERS

Create and return a new Text::Conversation object.  The constructor
takes a few parameters, specified as name/value pairs.  All the
parameters are optional.

Here's a constructor that uses all the parameters.  Unfortunately, the
coder has sillily used all the default values when writing it.

	my $threader = Text::Conversation->new(
		debug         => 0,
		thread_buffer => 30,
	);

"debug" turns on a lot of warnings that most people won't be
interested in to begin with.  They may become curious and enable it
after they come to realize the module often does a lousy job of
threading.  Please roll 1d4, and subtract that number from your Sanity
if you enable debugging.

"thread_buffer" sets the number of messages that the module keeps in
its short-term memory.  These messages are the ones considered when
looking for referents.  If you're looking for an analogy, consider it
the number of messages that fit or your terminal, and you can't scroll
back.  When someone says something peculiar, and you skim your screen
for what the heck they're talking about, there's only "thread_buffer"
number of messages visible.

The thread buffer shouldn't be too large.  Messages are penalized the
farther back they are in time, so a huge buffer just consumes memory
with little or no gain.  The default of 30 lines seems sane today.

=item observe SPEAKER_ID, SPEAKER_TEXT

Ask Text::Conversation to observe a "spoken" message.  observe()
returns two values: the unique ID of this new message, and the ID of
the message the speaker is most likely referring to.  If we're lucky,
the referent ID is actually meaningful.

Oh, if Text::Conversation decides they're just spouting into the void
(that is, what they've said doesn't refer to anything in its
short-term memory), then the referent ID is undefined.  I hope the
example in the SYNOPSIS adequately portrays this behavior.

	my ($new_message_id, $referent_id) = $threader->observe(
		$screen_name, $what_they_said
	);

	if (defined $referent_id) {
		print "They're referring to message '$referent_id'.\n";
	}
	else {
		print "Uh-oh.  $screen_name is on their soapbox again.\n";
	}

=back

=head1 SEE ALSO

The heck if I know.  Suggest something.

=head1 BUGS

Text::Conversation is considered beta code.  Thank Ford it's not
alpha!  The threading heuristics are interesting, and sometimes they
are surprisingly effective, but they aren't perfect.

This module's locale is hardcoded for English.  Please send patches to
support your native tongue if you cannot read this.

Consecutive messages by the same author, where the subsequent messages
begin with conjunctions, are most likely a monologue.  The subsequent
messages are more likely to address the same destination as the first
one.  LotR suggested this.  And I believe he's right.

At least in Perl-related IRC channels there is a convention whereby
people "correct" previous messages by stating simple substitutions.
For example:

	<bynari> my butt hurts
	<bynari> s/butt/head/

The second message states that the previous message was in error, and
"butt" should be replaced with "head".

The module doesn't consider periods of time where a speaker is not
present.  It will happily link someone's message to a thread they
couldn't possibly have known about.  Be careful fixing this one:
Someone may arrive and immediately refer to a thread that occurred
before they left.

If an unaddressed message matches a message farther back in a thread,
perhaps they're referring to something farther along that branch.

	01 <one> A lot of creatures really don't know how to deal with a
			glue trap.  They do that tarbaby thing with increasing
			desperation.
	02 <two> yeah.  so, imagine bambi stuck to one.
	03 <three> I am imagining my neighbors in a glue
			trap...frantically rolling around trying to get free yet picking
			up various objects in their struggle ... (hey...this sounds
			familiar...)
	04 <two> hee
	05 <one> Like that game!
	06 <three> Yeah! But with our NEIGHBORS!
	07 <three> (comic relief IN MY MIND)

At the time of this writing, this conversation threaded like this:

	01 <one> A lot of creatures....
		02 <two> yeah.  so, ....
		03 <three> I am imagining ....
		04 <two> hee
			05 <one> Like that game!
				07 <three> (comic relief....
		06 <three> Yeah! But....

It should instead thread like this:

	01 <one> A lot of creatures....
		02 <two> yeah.  so, ....
			03 <three> I am imagining ....
				04 <two> hee
				05 <one> Like that game!
					06 <three> Yeah! But....
					07 <three> (comic relief....

The problem occurs in the rule where "If a message's referent is by
the same speaker, then set the current referent to the referent of the
previous message."  In the broken case, 06 refers to 03 (by the same
person), so it's "fixed" to point to 01 (because 03 refers to that).

There are probably other things.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Text-Conversation

=head1 REPOSITORY

http://github.com/rcaputo/text-conversation
http://gitorious.org/text-conversation

=head1 OTHER RESOURCES

http://search.cpan.org/dist/Text-Conversation/

=head1 AUTHORS

Rocco Caputo  conceived of and created Text::Conversation with initial
feedback and coments from the residents of various channels on
irc.perl.org.

=head1 LICENSE

Except where otherwise noted, Text::Conversation is Copyright
2005-2013 by Rocco Caputo.  All rights are reserved.
Text::Conversation is free software.  You may modify and/or
redistribute it under the same terms as Perl itself.

=cut
