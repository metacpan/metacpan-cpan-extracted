#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Text::Fuzzy;
use Lingua::EN::PluralToSingular 'to_singular';

# The location of the Unix dictionary.
my $dict = '/usr/share/dict/words';

# Default maximum edit distance. Five is quite a big number for a
# spelling mistake.
my $max = 5;

GetOptions (
    "dict=s" => \$dict,
    "max=i" => \$max,
);

my @words;
my %words;
my $min_length = 4;
read_dictionary ($dict, \@words, \%words);
# Known mistakes, don't repeat.
my %known;
# Spell-check each file on the command line.
for my $file (@ARGV) {
    open my $input, "<", $file or die "Can't open $file: $!";
    while (<$input>) {
        my @line = split /[^a-z']+/i, $_;
        for my $word (@line) {
	    # Remove leading/trailing apostrophes.
	    $word =~ s/^'|'$//g;
	    my $clean_word = to_singular (lc $word);
	    $clean_word =~ s/'s$//;
            if ($words{$clean_word} || $words{$word}) {
                # It is in the dictionary.
                next;
            }
            if (length $word < $min_length) {
                # Very short words are ignored.
                next;
            }
            if ($word eq uc $word) {
                # Acronym like BBC, IRA, etc.
                next;
            }
            if ($known{$clean_word}) {
                # This word was already given to the user.
                next;
            }
	    if ($clean_word =~ /(.*)ed$/ || $clean_word =~ /(.*)ing/) {
		my $stem = $1;
		if ($words{$stem} || $words{"${stem}e"}) {
		    # Past/gerund of $stem/${stem}e
		    next;
		}
		# Test for doubled end consonants,
		# e.g. "submitted"/"submit".
		if ($stem =~ /([bcdfghjklmnpqrstvwxz])\1/) {
		    $stem =~ s/$1$//;
		    if ($words{$stem}) {
			# Past/gerund of $stem/${stem}e
			next;
		    }
		}
	    }
            my $tf = Text::Fuzzy->new ($clean_word, max => $max);
            my $nearest = $tf->nearest (\@words);
	    # We have set a maximum distance to search for, so we need
	    # to check whether $nearest is defined.
            if (defined $nearest) {
                my $correction = $words[$nearest];
                print "$file:$.: '$word' may be '$correction'.\n";
                $known{$clean_word} = $correction;
            }
            else {
                print "$file:$.: $word may be a spelling mistake.\n";
                $known{$clean_word} = 1;
            }
        }
    }
    close $input or die $!;
}

exit;

sub read_dictionary
{
    my ($dict, $words_array, $words_hash) = @_;    
    open my $din, "<", $dict or die "Can't open dictionary $dict: $!";
    my @words;
    while (<$din>) {
        chomp;
	push @words, $_;
    }
    close $din or die $!;
    # Apostrophe words

    my @apo = qw/

		    let's I'll you'll he'll she'll they'll we'll I'm
		    you're he's she's it's we're they're I've they've
		    you've we've one's isn't aren't doesn't don't
		    won't wouldn't I'd you'd he'd we'd they'd
		    shouldn't couldn't didn't can't

		/;

    # Irregular past participles.
    my @pp = qw/became/;

    push @words, @apo, @pp;
    for (@words) {
        push @$words_array, lc $_;
        $words_hash->{$_} = 1;
        $words_hash->{lc $_} = 1;
    }
}
