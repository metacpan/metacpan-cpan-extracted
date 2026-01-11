package Wordsmith::Claude::Mode;

use 5.020;
use strict;
use warnings;

=head1 NAME

Wordsmith::Claude::Mode - Built-in rewriting mode definitions

=head1 SYNOPSIS

    use Wordsmith::Claude::Mode;

    # Get instruction for a mode
    my $instruction = Wordsmith::Claude::Mode->get_instruction('eli5');

    # Check if mode exists
    if (Wordsmith::Claude::Mode->exists('pirate')) { ... }

    # List all modes
    my @modes = Wordsmith::Claude::Mode->all_modes;

    # Get modes by category
    my @fun_modes = Wordsmith::Claude::Mode->modes_in_category('fun');

=head1 DESCRIPTION

Defines all built-in rewriting modes with their instructions.

=head1 MODES

=cut

our %MODES;
BEGIN {
    %MODES = (
        # Complexity modes
        eli5 => {
            category    => 'complexity',
            description => 'Explain Like I\'m 5 - very simple language',
            instruction => 'Rewrite this so a 5-year-old could understand it. Use very simple words, short sentences, and fun comparisons. Avoid any technical terms.',
        },
        eli10 => {
            category    => 'complexity',
            description => 'Explain Like I\'m 10 - simple but more detail',
            instruction => 'Rewrite this for a 10-year-old. Use simple language but you can include more detail. Explain any tricky concepts with relatable examples.',
        },
        technical => {
            category    => 'complexity',
            description => 'Add technical precision and jargon',
            instruction => 'Rewrite this with more technical precision. Use proper terminology, be specific, and add relevant technical details where appropriate.',
        },

        # Tone modes
        formal => {
            category    => 'tone',
            description => 'Professional, business-appropriate',
            instruction => 'Rewrite this in a formal, professional tone. Use proper grammar, avoid contractions, and maintain a respectful, business-appropriate style.',
        },
        casual => {
            category    => 'tone',
            description => 'Relaxed, conversational',
            instruction => 'Rewrite this in a casual, conversational tone. Use contractions, simple words, and write like you\'re chatting with a friend.',
        },
        friendly => {
            category    => 'tone',
            description => 'Warm and approachable',
            instruction => 'Rewrite this in a warm, friendly tone. Be approachable, positive, and personable while keeping the message clear.',
        },
        professional => {
            category    => 'tone',
            description => 'Polished and authoritative',
            instruction => 'Rewrite this in a polished, authoritative tone. Sound confident and knowledgeable while remaining clear and accessible.',
        },

        # Length/Format modes
        concise => {
            category    => 'format',
            description => 'Trim to essentials',
            instruction => 'Rewrite this as concisely as possible. Remove all unnecessary words. Keep only the essential meaning.',
        },
        expand => {
            category    => 'format',
            description => 'Add detail and explanation',
            instruction => 'Expand this with more detail and explanation. Add context, examples, and elaboration to make it more comprehensive.',
        },
        bullets => {
            category    => 'format',
            description => 'Convert to bullet points',
            instruction => 'Rewrite this as a bulleted list. Break down the key points into clear, scannable bullets.',
        },
        summarize => {
            category    => 'format',
            description => 'Brief summary',
            instruction => 'Summarize this in 1-2 sentences. Capture only the main point.',
        },

        # Fun styles
        pirate => {
            category    => 'fun',
            description => 'Talk like a pirate',
            instruction => 'Rewrite this as a pirate would say it. Use "arr", "me hearties", "ye", "avast", nautical terms, and pirate slang. Be dramatic and swashbuckling!',
        },
        shakespeare => {
            category    => 'fun',
            description => 'In the Bard\'s tongue',
            instruction => 'Rewrite this in Shakespearean English. Use "thee", "thou", "hath", "doth", "forsooth", "prithee", and other Early Modern English. Be poetic and dramatic.',
        },
        yoda => {
            category    => 'fun',
            description => 'Speak like Yoda',
            instruction => 'Rewrite this as Yoda would speak. Invert the sentence structure (object-subject-verb), add wisdom, and include phrases like "hmm" and references to the Force.',
        },
        corporate => {
            category    => 'fun',
            description => 'Corporate buzzword speak',
            instruction => 'Rewrite this using maximum corporate buzzwords. Include "synergy", "leverage", "paradigm shift", "circle back", "deep dive", "move the needle", "bandwidth", etc. Sound like a parody of business jargon.',
        },
        valley => {
            category    => 'fun',
            description => 'Valley girl speak',
            instruction => 'Rewrite this as a valley girl would say it. Use "like", "totally", "oh my god", "literally", "I can\'t even", uptalk patterns, and enthusiastic exclamations.',
        },
        noir => {
            category    => 'fun',
            description => 'Hard-boiled detective narration',
            instruction => 'Rewrite this as a hard-boiled noir detective narration. Be cynical, world-weary, use metaphors, and channel Raymond Chandler.',
        },
        uwu => {
            category    => 'fun',
            description => 'Cute internet speak',
            instruction => 'Rewrite this in uwu speak. Replace r and l with w, add "uwu", "owo", ":3", asterisk actions like *nuzzles*, and make it cutesy.',
        },
        genz => {
            category    => 'fun',
            description => 'Gen Z slang',
            instruction => 'Rewrite this using Gen Z slang. Use "no cap", "fr fr", "slay", "bussin", "its giving", "lowkey/highkey", "based", "rent free", etc. Keep it authentic.',
        },

        # Utility modes
        proofread => {
            category    => 'utility',
            description => 'Fix grammar and spelling',
            instruction => 'Proofread and correct this text. Fix any grammar, spelling, and punctuation errors. Improve clarity where needed but preserve the original meaning and tone.',
        },
        active => {
            category    => 'utility',
            description => 'Convert to active voice',
            instruction => 'Rewrite this using active voice. Remove passive constructions and make the writing more direct and engaging.',
        },
        gender_neutral => {
            category    => 'utility',
            description => 'Use gender-neutral language',
            instruction => 'Rewrite this using gender-neutral language. Use "they/them", "people", "folks", etc. instead of gendered terms.',
        },
    );
}

=head1 CLASS METHODS

=head2 get_instruction

    my $instruction = Wordsmith::Claude::Mode->get_instruction('eli5');

Returns the instruction text for a mode, or undef if mode doesn't exist.

=cut

sub get_instruction {
    my ($class, $mode) = @_;
    return unless exists $MODES{$mode};
    return $MODES{$mode}{instruction};
}

=head2 exists

    if (Wordsmith::Claude::Mode->exists('pirate')) { ... }

Returns true if the mode exists.

=cut

sub exists {
    my ($class, $mode) = @_;
    return exists $MODES{$mode};
}

=head2 all_modes

    my @modes = Wordsmith::Claude::Mode->all_modes;

Returns list of all mode names.

=cut

sub all_modes {
    return sort keys %MODES;
}

=head2 get_description

    my $desc = Wordsmith::Claude::Mode->get_description('eli5');

Returns the description for a mode.

=cut

sub get_description {
    my ($class, $mode) = @_;
    return unless exists $MODES{$mode};
    return $MODES{$mode}{description};
}

=head2 get_category

    my $cat = Wordsmith::Claude::Mode->get_category('pirate');  # 'fun'

Returns the category for a mode.

=cut

sub get_category {
    my ($class, $mode) = @_;
    return unless exists $MODES{$mode};
    return $MODES{$mode}{category};
}

=head2 modes_in_category

    my @fun = Wordsmith::Claude::Mode->modes_in_category('fun');

Returns all modes in a category.

=cut

sub modes_in_category {
    my ($class, $category) = @_;
    return sort grep { $MODES{$_}{category} eq $category } keys %MODES;
}

=head2 all_categories

    my @cats = Wordsmith::Claude::Mode->all_categories;

Returns list of all category names.

=cut

sub all_categories {
    my %cats = map { $MODES{$_}{category} => 1 } keys %MODES;
    return sort keys %cats;
}

=head2 mode_info

    my $info = Wordsmith::Claude::Mode->mode_info('eli5');
    # { category => 'complexity', description => '...', instruction => '...' }

Returns full info hashref for a mode.

=cut

sub mode_info {
    my ($class, $mode) = @_;
    return unless exists $MODES{$mode};
    return { %{$MODES{$mode}} };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
