package Text::NLP::Stanford::EntityExtract;

use warnings;
use strict;

use Mouse;
use utf8;
use Text::Unidecode;
use IO::Socket;

=head1 NAME

Text::NLP::Stanford::EntityExtract - Talks to a stanford-ner socket server to get named entities back

=head1 VERSION

Version 0.06

=cut

=head1 Quick Start:

=over

=item *

Grab the Stanford Named Entity recogniser from http://nlp.stanford.edu/ner/index.shtml.

=item *

Run the server, something like as follows:

 java -server -mx400m -cp stanford-ner.jar edu.stanford.nlp.ie.NERServer -loadClassifier classifiers/ner-eng-ie.crf-4-conll-distsim.ser.gz 1234

=item *

Wrte a script to extract the named entities from the text, like the following:

 #!/usr/bin/env perl -w
 use strict;
 use Text::NLP::Stanford::EntityExtract;
 my $ner = Text::NLP::Stanford::EntityExtract->new;
 my $server = $ner->server;
 my @txt = ("Some text\n\n", "Treated as \\n\\n delimited paragraphs");
 my @tagged_text = $ner->get_entities(@txt);
 my $entities = $ner->entities_list($txt[0]); # rather complicated
                                              # @AOA based data
                                              # structure for further
                                              # processing

=back

=cut

our $VERSION = '0.06';

=head2 METHODS

=head2 new ( host => '127.0.0.1', port => '1234' debug => 0|1|2);

The debug flag warns the length of the text sent to the server if set
to 1 and shows the actual text as well as the length if set to > 1.

=cut

has 'host'  => (is => 'ro', isa => 'Str', default => '127.0.0.1');
has 'port'  => (is => 'ro', isa => 'Int', default => '1234');
has 'debug' => (is => 'rw', isa => 'Int', default => 0);

=head2 server

Gets the socket connection.  I think that the ner server will only do
one line per connection, so you want a new connection for every line
of text.

=cut

sub server {
    my ($self) = @_;
    my $sock = IO::Socket::INET->new( PeerAddr => $self->host,
                                      PeerPort => $self->port,
                                      Proto    => 'tcp',
                                  );
    die "$!" if !$sock;
    return $sock;
}

=head2 get_entities(@txt)

Grabs the tagged text for an arbitrary number of paragraphs of text,
and returns as the ner tagged text.

=cut

sub get_entities {
    my ($self, @txt) = @_;
    my @result;
     foreach my $t (@txt) {
         warn "LENGTH: " . length($t) .  "\n" if $self->debug > 0;
         warn "TEXT: " .  $t . "\n" if $self->debug > 1;
         $t = unidecode($t);
         $t =~ s/\n/ /mg;
         $t =~ s/[^[:ascii:]]//mg;
         push @result, $self->_process_line($t);
     }
    return @result;
}

=head2 _process_line ($line)

processes a single line of text to tagged text

=cut


sub _process_line {
    my ($self, $line) = @_;
    my $server = $self->server;
    print $server $line,"\n";
    my $tagged_txt =  <$server>;
    return $tagged_txt;
}

=head2 entities_list($tagged_line)

returns a rater arcane data structure of the entities from the text.
the position of the word in the line is recorded as is the entity
type, so that the line of text can be recovered in full from the data
structure.

TODO:  This needs some utility subs around it to make it more useful.

=cut

sub entities_list {
    my ($self, $line) = @_;
    my @tagged_words = split /\s+/, $line;
    my $last_tag = '';
    my $taglist = {};
    my $pos = 1;
    foreach my $w (@tagged_words) {
        my ($word, $tag) = $w =~ m{(.*)/(.*)$};
        if (! $taglist->{$tag}) {
            $taglist->{$tag} = [ ];
        }
        if ($tag ne $last_tag) {
            push @{$taglist->{$tag}}, [$word, $pos++];
        }
        else {
            push @{ $taglist->{$tag}->[ $#{ $taglist->{$tag}} ] }, [$word, $pos++];
        }
        $last_tag = $tag;
    }
    return $taglist;
}

=head2 list_entities ($self->entities_list($line)

Lists the entities contained within a line based from the data
structure provided by entities_list($line).

If passed a list of entities it adds to that list, including counts of
the numbes of each entity already found.

The data structure returns looks like this:

 $list_data = {
    'LOCATION' => {
        'Outer Mongolia' => 1,
        'Location Location Location' => 1,
        'Chinese Mainland' => 1,
        'Britney' => 1
    },
    'O' => {
        'may have returned from the' => 1,
        'said from his home in' => 1,
        '. Test a three word entity' => 1,
        'faith that she follows . Now she is attempting , for a second time , to persuade' => 1,
        '. There is a question that' => 1,
        'blah blah' => 1,
        'to the controversial' => 1,
        '.' => 1,
        'to follow suit , reports said .' => 1
    },
    'PERSON' => {
        'Bruce Lee' => 1,
        'Gwyneth Paltrow' => 1,
        'Lord Lucan' => 1
    },
    'MISC' => {
        'Jewish-based' => 1
    }
 };

=cut

sub list_entities {
    my ($self, $data, $list) = @_;
    $list ||= {};
    foreach my $d (keys %$data) {
        $list->{$d} = { };
        foreach my $l ($data->{$d}) {
            for my $i ( 0 .. $#{$l}) {
                my $words = $l->[$i];
                my $firstword = $words->[0];
                my $entity = $firstword;
                map { $entity .= ' ' . $words->[$_]->[0] } (2 .. $#$words);
                $list->{$d}->{$entity}++;
            }
        }
    }
    return $list;
}


=head1 AUTHOR

Kieren Diment, C<< <zarquon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-nlp-stanford-entityextract at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-NLP-Stanford-EntityExtract>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

The git repository for this code is available from git://github.com/singingfish/text-nlp-stanford-entityextract.git

You can find documentation for this module with the perldoc command.

    perldoc Text::NLP::Stanford::EntityExtract

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-NLP-Stanford-EntityExtract>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-NLP-Stanford-EntityExtract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-NLP-Stanford-EntityExtract>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-NLP-Stanford-EntityExtract/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Kieren Diment, all rights reserved.

This program is released under the following license: GPL


=cut

1; # End of Text::NLP::Stanford::EntityExtract
