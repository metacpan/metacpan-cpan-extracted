package Text::Greeking;
$Text::Greeking::VERSION = '0.15';
use 5.006;
use strict;
use warnings;

# make controllable eventually.
my @punc   = split('', '..........??!');
my @inpunc = split('', ',,,,,,,,,,;;:');
push @inpunc, ' --';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    srand;
    $self->init;
}

sub init {
    $_[0]->sources([]);
    $_[0]->paragraphs(2, 8);
    $_[0]->sentences(2, 8);
    $_[0]->words(5, 15);
    $_[0];
}

sub sources {
    $_[0]->{sources} = $_[1] if defined $_[1];
    $_[0]->{sources};
}

sub add_source {
    my ($self, $text) = @_;
    return unless $text;
    $text =~ s/[\n\r]/ /g;
    $text =~ s/[[:punct:]]//g;
    my @words = map { lc $_ } split /\s+/, $text;
    push @{$self->{sources}}, \@words;
}

sub generate {
    my $self = shift;
    my $out;
    $self->_load_default_source unless defined $self->{sources}->[0];
    my @words = @{$self->{sources}->[int(rand(@{$self->{sources}}))]};
    my ($paramin, $paramax) = @{$self->{paragraphs}};
    my ($sentmin, $sentmax) = @{$self->{sentences}};
    my ($phramin, $phramax) = @{$self->{words}};
    my $pcount = int(rand($paramax - $paramin + 1) + $paramin);

    for (my $x = 0; $x < $pcount; $x++) {
        my $p;
        my $scount = int(rand($sentmax - $sentmin + 1) + $sentmin);
        for (my $y = 0; $y < $scount; $y++) {
            my $s;
            my $wcount = int(rand($phramax - $phramin + 1) + $phramin);
            for (my $w = 0; $w < $wcount; $w++) {
                my $word = $words[int(rand(@words))];
                $s .= $s ? " $word" : ucfirst($word);
                $s .=
                  (($w + 1 < $wcount) && !int(rand(10)))
                  ? $inpunc[int(rand(@inpunc))]
                  : '';
            }
            $s .= $punc[int(rand(@punc))];
            $p .= ' ' if $p;
            $p .= $s;
        }
        $out .= $p . "\n\n";    # assumes text.
    }
    $out;
}

sub paragraphs { $_[0]->{paragraphs} = [$_[1], $_[2]] }
sub sentences  { $_[0]->{sentences}  = [$_[1], $_[2]] }
sub words      { $_[0]->{words}      = [$_[1], $_[2]] }

sub _load_default_source {
    my $text = <<TEXT;
Lorem ipsum dolor sit amet, consectetuer adipiscing elit,
sed diam nonummy nibh euismod tincidunt ut laoreet dolore
magna aliquam erat volutpat. Ut wisi enim ad minim veniam,
quis nostrud exerci tation ullamcorper suscipit lobortis
nisl ut aliquip ex ea commodo consequat. Duis autem vel eum
iriure dolor in hendrerit in vulputate velit esse molestie
consequat, vel illum dolore eu feugiat nulla facilisis at
vero eros et accumsan et iusto odio dignissim qui blandit
praesent luptatum zzril delenit augue duis dolore te feugait
nulla facilisi.
Ut wisi enim ad minim veniam, quis nostrud exerci tation
ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo
consequat. Duis autem vel eum iriure dolor in hendrerit in
vulputate velit esse molestie consequat, vel illum dolore eu
feugiat nulla facilisis at vero eros et accumsan et iusto
odio dignissim qui blandit praesent luptatum zzril delenit
augue duis dolore te feugait nulla facilisi. Lorem ipsum
dolor sit amet, consectetuer adipiscing elit, sed diam
nonummy nibh euismod tincidunt ut laoreet dolore magna
aliquam erat volutpat. 
Duis autem vel eum iriure dolor in hendrerit in vulputate
velit esse molestie consequat, vel illum dolore eu feugiat
nulla facilisis at vero eros et accumsan et iusto odio
dignissim qui blandit praesent luptatum zzril delenit augue
duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit
amet, consectetuer adipiscing elit, sed diam nonummy nibh
euismod tincidunt ut laoreet dolore magna aliquam erat
volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci
tation ullamcorper suscipit lobortis nisl ut aliquip ex ea
commodo consequat.
TEXT
    $_[0]->add_source($text);
}

1;

__END__

=head1 NAME

Text::Greeking - generate meaningless text (eg to fill a page when designing)

=head1 SYNOPSIS

 use Text::Greeking;

 my $g = Text::Greeking->new;
 $g->paragraphs(1,2)    # min of 1 paragraph and a max of 2
 $g->sentences(2,5)     # min of 2 sentences per paragraph and a max of 5
 $g->words(8,16)        # min of 8 words per sentence and a max of 16
 print $g->generate;    # use default Lorem Ipsum source

=head1 DESCRIPTION

Greeking is the use of random letters or marks to show the
overall appearance of a printed page without showing the
actual text. Greeking is used to make it easy to judge the
overall appearance of a document without being distracted by
the meaning of the text.

This is a module is for quickly generating varying
meaningless text from any source to create this illusion of
the content in systems.

This module was created to quickly give developers simulated
content to fill systems with simulated content. Instead of
static Lorem Ipsum text, by using randomly generated text
and optionally varying word sources, repetitive and
monotonous patterns that do not represent real system usage
is avoided. 

=head1 METHODS

=over

=item Text::Greeking->new

Constructor method. Returns a new instance of the class.

=item $g->init

Initializes object with defaults. Called by the constructor.
Broken out for easy overloading to enable customized
defaults and other behaviour.

=item $g->sources([\@ARRAY])

Gets/sets the table of source word collections current in
memory as an ARRAY reference

=item $g->add_source($text)

The class takes a body of text passed as a SCALAR and
processes it into a list of word tokens for use in
generating random filler text later.

=item $g->generate

Returns a body of random text generated from a randomly
selected source using the minimum and maximum values set by
paragraphs, sentences, and words minimum and maximum values.
If generate is called without any sources a standard Lorem
Ipsum block is used added to the sources and then used for
processing the random text.

=item $g->paragraphs($min,$max)

Sets the minimum and maximum number of paragraphs to
generate. Default is a minimum of 2 and a maximum of 8.

=item $g->sentences($min,$max)

Sets the minimum and maximum number of sentences to generate
per paragraph. Default is a minimum of 2 and a maximum of 8.

=item $g->words($min,$max)

Sets the minimum and maximum number of words to generate per
sentence. Default is a minimum of 5 and a maximum of 15.

=back

=head1 SEE ALSO

L<WWW::Lipsum> - an interface to L<lipsum.com|http://www.lipsum.com>.

L<Text::Lorem> - generate random latin-looking text.

L<Text::Lorem::More> - class that provides methods for generating various
types of structured latin filler text, such as names, words, sentences,
paragraphs, titles, hostnames, etc.

L<Text::Lorem::JA> - generate Japanese filler text.

L<WWW::Lipsum::Chinese> - generate Chinese filler text.

L<Text::Greeking::zh_TW> - another module for generating Chinese filler text.

L<Acme::CorpusScrambler> - generates filler text based on text that you
provide; falls back to the using the corpus for L<Text::Greeking::zh_TW>.

L<Template::Plugin::Text::Greeking> - a template toolkit plugin
for C<Text::Greeking>.

L<Faker> - an extensible framework for generating fake data,
including I<lorem ipsum> style filler text.

L<Lingua::ManagementSpeak> - generates filler text in 'management speak'.

L<Toby Inkster|https://metacpan.org/author/TOBYINK> - pedant.

The L<wikipedia page on Greeking|http://en.wikipedia.org/wiki/Greeking>.

=head1 TO DO

=over

=item HTML output mode including random hyperlinked phrases.

=item Configurable punctuation controls.

=back

=head1 REPOSITORY

L<https://github.com/neilb/Text-Greeking>

=head1 LICENSE

The software is released under the Artistic License. The
terms of the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Text::Greeking is Copyright
2005-2009, Timothy Appnel, tima@cpan.org. All rights
reserved.

=cut

