=head1 NAME

Text::SpellChecker - OO interface for spell-checking a block of text

=head1 SYNOPSIS

    use Text::SpellChecker;
    ($Text::SpellChecker::pre_hl_word,
     $Text::SpellChecker::post_hl_word) = (qw([ ]));

    my $checker = Text::SpellChecker->new(text => "Foor score and seven yeers ago");

    while (my $word = $checker->next_word) {
        print $checker->highlighted_text, 
            "\n", 
            "$word : ",
            (join "\t", @{$checker->suggestions}),
            "\nChoose a new word : ";
        chomp (my $new_word = <STDIN>);
        $checker->replace(new_word => $new_word) if $new_word;
    }

    print "New text : ".$checker->text."\n";

--or-- 

    use CGI;
    use Text::SpellChecker;
    my $q = new CGI;
    print $q->header,
          $q->start_html,
          $q->start_form(-method=>'POST',-action=>$ENV{SCRIPT_NAME});

    my $checker = Text::SpellChecker->new(
        text => "Foor score and seven yeers ago",
        from_frozen => $q->param('frozen') # will be false the first time.
    ); 

    $checker->replace(new_word => $q->param('replacement')) 
        if $q->param('replace');

    if (my $word = $checker->next_word) {
        print $q->p($checker->highlighted_text),
            $q->br, 
            qq|Next word : "$word"|, 
            $q->br,
            $q->submit(-name=>'replace',-value=>'replace with:'),
            $q->popup_menu(-name=>'replacement',-values=>$checker->suggestions),
            $q->submit(-name=>'skip');
    } else {
        print "Done.  New text : ".$checker->text;
    }

    print $q->hidden(-name => 'frozen',
                     -value => $checker->serialize,
                     -override => 1), 
          $q->end_form, 
          $q->end_html;


=head1 DESCRIPTION

This module is a thin layer above either Text::Aspell or Text::Hunspell (preferring
the latter if available), and allows one to spellcheck a body of text.

Whereas Text::(Hu|A)spell deals with words, Text::Spellchecker deals with blocks of text.
For instance, we provide methods for iterating through the text, serializing the object (thus
remembering where we left off), and highlighting the current misspelled word within
the text.

=head1 METHODS

=over 4

=item $checker = Text::SpellChecker->new(text => $text, from_frozen => $serialized_data, lang => $lang, options => $options)

Send either the text or a serialized object to the constructor.  
Optionally, the language of the text can also be passed.
If no language is passed, $ENV{LANG} will be used, if it is set.
If it is not set, the default language will be "en_US".

$options are checker-specific options (see below).

=item $checker = new_from_frozen($serialized_data)

This is provided separately, so that it may be
overridden for alternative serialization techniques.

=item $str=$checker->serialize

Represent the object in its current state.

=item $checker->reset

Reset the checker to the beginning of the text, and clear the list of ignored words.

=item $word = $checker->next_word

Returns the next misspelled word.

=item $checker->current_word

Returns the most recently returned word.

=item $checker->replace(new_word => $word)

Replace the current word with $word.

=item $checker->ignore_all

Ignore all subsequent occurences of the current word.

=item $checker->replace_all(new_word => $new_word)

Replace all subsequent occurences of the current word with a new word.

=item $checker->suggestions

Returns a reference to a list of alternatives to the
current word in a scalar context, or the list directly
in a list context.

=item $checker->text

Returns the current text (with corrections that have been
applied).

=item $checker->highlighted_text

Returns the text, but with the current word surrounded by $Text::SpellChecker::pre_hl_word and
$Text::SpellChecker::post_hl_word.

=item $checker->set_options

Set checker-specific options.  Currently only aspell supports setting options, e.g.

    $checker->set_options(aspell => { "extra-dicts" => "nl" } );

=back

=head1 CONFIGURATION OPTIONS

=over

=item $Text::SpellChecker::pre_hl_word

Set this to control the highlighting of a misspelled word.

=item $Text::SpellChecker::post_hl_word

Set this to control the highlighting of a misspelled word.

=item $Text::SpellCheckerDictionaryPath{Hunspell}

Set this to the hunspell dictionary path.  By default /usr/share/hunspell.

This directory should have $lang.dic and $lang.aff files.
 
=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 TODO

Add word to custom dictionary

=head1 SEE ALSO

Text::Aspell, Text::Hunspell

=head1 AUTHOR

Brian Duggan <bduggan@matatu.org>

=cut

package Text::SpellChecker;
use Carp;
use Storable qw(freeze thaw);
use MIME::Base64;
use warnings;
use strict;

our $VERSION = '0.14';

our $pre_hl_word = qq|<span style="background-color:red;color:white;font-weight:bold;">|;
our $post_hl_word = "</span>";
our %SpellersAvailable;
BEGIN {
    %SpellersAvailable = (
        Aspell   => do { eval{require Text::Aspell};   $@ ? 0 : 1},
        Hunspell => do { eval{require Text::Hunspell}; $@ ? 0 : 1},
    );
    unless (grep { $_ } values %SpellersAvailable) {
        die "Could not load Text::Aspell or Text::Hunspell.  At least one must be installed";
    };
}
our %DictionaryPath = (
    Hunspell => q[/usr/share/hunspell]
);

#
# new
#
# parameters :
#   text : the text we're checking
#   from_frozen : serialized class data to use instead of using text
#
sub new {
    my ($class,%args) = @_;
    return $class->new_from_frozen($args{from_frozen}) if $args{from_frozen};
    bless {
            text => $args{text},
            ignore_list => {},    # keys of this hash are words to be ignored
            ( lang => $args{lang} ) x !!$args{lang},
            ( options => $args{options} ) x !!$args{options},
    }, $class;
}

sub set_options {
    my ($self, %opts) = @_;
    $self->{options} = \%opts;
}

sub reset {
    my $self = shift;
    $self->{position} = undef;
    $self->{ignore_list} = {};
}

# Ignore all remaining occurences of the current word.

sub ignore_all {
    my $self = shift;
    my $word = $self->current_word or croak "Can't ignore all : no current word";
    $self->{ignore_list}{$word} = 1;
}

# Replace all remaining occurences with the given word

sub replace_all {
    my ($self,%args) = @_;
    my $new_word = $args{new_word} or croak "no replacement given";
    my $current = $self->current_word;
    $self->replace(new_word => $new_word);
    my $saved_position = $self->{position};
    while (my $next = $self->next_word) {
         next unless $next eq $current;
         $self->replace(new_word => $new_word);
    }
    $self->{position} = $saved_position;
}

#
# new_from_frozen
#
# Alternative handy constructor using serialized object.
#
sub new_from_frozen {
    my $class = shift;
    my $frozen = shift;
    my $self = thaw(decode_base64($frozen)) or croak "Couldn't unthaw $frozen";
    unless (ref $self =~ /Spellchecker/i) {
        bless $self, $class;
    }
    return $self;
}

#
# next_word
# 
# Get the next misspelled word. 
# Returns false if there are no more.
#
sub next_word {
    my $self = shift;
    pos $self->{text} = $self->{position};
    my $word;
    my $sp = $self->_hunspell || $self->_aspell || die "Could not make a speller with Text::Hunspell or Text::Aspell.";
    while ($self->{text} =~ m/\b(\p{L}+(?:'\p{L}+)?)/g) {
        $word = $1;
        next if $self->{ignore_list}{$word};
        last if !$sp->check($word);
    }
    unless ($self->{position} = pos($self->{text})) {
        $self->{current_word} = undef;
        return undef;
    }
    $self->{suggestions} = [ $sp->suggest($word) ];
    $self->{current_word} = $word;
    return $word;
}

#
# Private method returning a Text::Aspell object
#
sub _aspell {
    my $self = shift;
    return unless $SpellersAvailable{Aspell};

    unless ( $self->{aspell} ) {
        $self->{aspell} = Text::Aspell->new;
        $self->{aspell}->set_option( lang => $self->{lang} ) 
                if $self->{lang};
        if (my $opts = $self->{options}{aspell}) {
            $self->{aspell}->set_option( $_ => $opts->{$_} ) for keys %$opts
        }
    }

    return $self->{aspell};
}

sub _hunspell {
    my $self = shift;
    return unless $SpellersAvailable{Hunspell};
    unless ( -d $DictionaryPath{Hunspell} ){
        warn "Could not find hunspell dictionary directory $DictionaryPath{Hunspell}.";
        return;
    }
    my $env_lang;
    ($env_lang) = $ENV{LANG} =~ /^([^\.]*)/ if $ENV{LANG};
    my $lang = $self->{lang} || $env_lang || "en_US";
    my $dic = sprintf("%s/%s.dic", $DictionaryPath{Hunspell}, $lang );
    my $aff = sprintf("%s/%s.aff", $DictionaryPath{Hunspell}, $lang );
    -e $dic or do {
        warn "Could not find $dic";
        return;
    };
    -e $aff or do {
        warn "could not find $aff";
        return;
    };

    unless ( $self->{hunspell} ) {
        $self->{hunspell} = Text::Hunspell->new($aff,$dic);
    }

    return $self->{hunspell};
}

#
# replace - replace the current word with a new one.
#
# parameters :
#   new_word - the replacement for the current word
#
sub replace {
    my ($self,%args) = @_;
    my $new_word = $args{new_word} or croak "no replacement given";
    my $word = $self->current_word or croak "can't replace with $new_word : no current word";
    $self->{position} -= length($word); # back up : we'll recheck this word, but that's okay.
    substr($self->{text},$self->{position},length($word)) = $new_word;
}

#
# highlighted_text
# 
# Get the text with the current misspelled word highlighted.
#
sub highlighted_text {
    my $self = shift;
    my $word = $self->current_word;
    return $self->{text} unless ($word and $self->{position});
    my $text = $self->{text};
    substr($text,$self->{position} - length($word),length($word)) = "$pre_hl_word$word$post_hl_word";
    return $text;
}

#
# Some accessors
#
sub text         { return $_[0]->{text}; }
sub suggestions  { 
    return unless $_[0]->{suggestions};
    return wantarray 
                ? @{$_[0]->{suggestions}} 
                :   $_[0]->{suggestions} 
                ;  
}
sub current_word { return $_[0]->{current_word};  }

#
# Handy serialization method.
#
sub serialize {
   my $self = shift;

   # remove mention of Aspell object, if any
   my %copy = %$self;
   delete $copy{aspell};
   delete $copy{hunspell};

   return encode_base64 freeze \%copy;
}

1;

