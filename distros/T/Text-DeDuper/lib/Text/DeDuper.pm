=head1 NAME

Text::DeDuper - near duplicates detection module

=head1 SYNOPSIS

    use Text::DeDuper;

    $deduper = new Text::DeDuper();
    $deduper->add_doc("doc1", $doc1text);
    $deduper->add_doc("doc2", $doc2text);
    
    @similar_docs = $deduper->find_similar($doc3text);

    ...

    # delete near duplicates from an array of texts
    $deduper = new Text::DeDuper();
    foreach $text (@texts)
    {
        next if $deduper->find_similar($text);
        
        $deduper->add_doc($i++, $text);
        push @no_near_duplicates, $text;
    }

=head1 DESCRIPTION

This module uses the resemblance measure as proposed by Andrei Z. Broder at al
(http://www.ra.ethz.ch/CDstore/www6/Technical/Paper205/Paper205.html) to detect
similar (near-duplicate) documents based on their text.

Note of caution: The module only works correctly with languages where texts can
be tokenised to words by detecting alphabetical characters sequences. Therefore
it might not provide very good results for e.g. Chinese.

=cut

package Text::DeDuper;

use strict;
use warnings;
use vars qw($VERSION);

use Digest::MD4;
use Encode;

$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d", @r };

=head1 METHODS

=head2 new (CONSTRUCTOR)

    $deduper = new Text::DeDuper(<attribute-value-pairs>);

Create a new DeDuper instance. Supported attributes are described bellow, in the
I<Attributes> section.

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    my $self = bless {
        ngram_size => 5,
        sim_trsh   => 0.2,
        encoding   => 'utf8',
        _stoplist     => {},
        _digest_count => {},
        _doc_ids      => {},
    }, $class;

    $self->stoplist(  $options{stoplist});
    $self->ngram_size($options{ngram_size});
    $self->sim_trsh(  $options{sim_trsh});
    $self->encoding(  $options{encoding});

    return $self;
}

=cut

=head2 add_doc

    $deduper->add_doc($document_id, $document_text);

Add a new document to the DeDuper's database. The C<$document_id> must be
unique for each document.

=cut

sub add_doc
{
    my $self  = shift;
    my $docid = shift;
    my $text  = shift;

    croak("duplicate document id '$docid'")
        if defined $self->{_digest_count}->{$docid};
    
    my @tokens = $self->_tokenise($text);
    my @filtered_tokens = $self->_apply_stoplist(@tokens);
    my @digests = $self->_build_ngram_digests(@filtered_tokens);

    $self->{_digest_count}->{$docid} = scalar(@digests);
    foreach my $digest (@digests)
    {
        if (not defined $self->{_doc_ids}->{$digest})
            { $self->{_doc_ids}->{$digest} = [ $docid ]; }
        else
            { push @{$self->{_doc_ids}->{$digest}}, $docid; }
    }
}

=head2 find_similar

    $deduper->find_similar($document_text);

Returns (possibly empty) array of document IDs of documents in the DeDuper's
database similar to the C<$document_text>. This can be very simply used for
testing whether a near-duplicate document is in the database:

    if ($deduper->find_similar($document_text))
    {
        print "at least one near duplicate found";
    }

=cut

sub find_similar
{
    my $self = shift;
    my $text = shift;

    my @tokens = $self->_tokenise($text);
    my @filtered_tokens = $self->_apply_stoplist(@tokens);
    my @digests = $self->_build_ngram_digests(@filtered_tokens);

    # compute intersection sizes with all documents in the database
    my %intersection_size;
    foreach my $digest (@digests)
    {
        next
            unless defined($self->{_doc_ids}->{$digest});

        foreach my $docid (@{$self->{_doc_ids}->{$digest}})
        { 
            if (defined $intersection_size{$docid})
                { $intersection_size{$docid}++; }
            else
                { $intersection_size{$docid} = 1; }
        }
    }

    my @similar;
    foreach my $docid (keys %intersection_size)
    {
        # union size
        my $union_size = scalar(@digests) + $self->{_digest_count}->{$docid} -
            $intersection_size{$docid};
        # resemblance
        my $resemblance = $union_size > 0 ?
            $intersection_size{$docid} / $union_size : 0;
        # return docs with resemblance above treshold
        push @similar, $docid
            if $resemblance > $self->{sim_trsh};
    }

    return @similar;
}

=head2 clean

    $deduper->clean()

Removes all documents from DeDuper's database.

=cut

sub clean
{
    my $self = shift;
    
    $self->{_doc_ids}      = {};
    $self->{_digest_count} = {};
}

=head1 ATTRIBUTES

Attributes can be set using the constructor:

    $deduper = new Text::DeDuper(
        ngram_size => 4,
        encoding   => 'iso-8859-1'
    );

... or using the object methods:

    $deduper->ngram_size(4);
    $deduper->encoding('iso-8859-1');

The object methods can also be used for retrieving the values of the
attributes:

    $ngram_size = $deduper->ngram_size();
    @stoplist   = $deduper->stoplist();

=over

=item encoding

The characters encoding of processed texts. Must be set to correct value so
that alphabetical characters could be detected. Accepted values are those
supported by the L<Encode> module (see L<Encode::Supported>).

B<default:> 'utf8'

=item sim_trsh

The similarity treshold defines how similar two documents must be to be
considered near duplicates. The boundary values are 0 and 1. The similarity
value of 1 indicates that the documents are exactly the same. The value of
0 on the other hand means that the documents do not share any n-gram.

Any two documents will have the similarity value below the default treshold
unless they share a significant part of text.

B<default:> 0.2

=item ngram_size

The document similarity is based on the information of how many n-grams the
documents have in common. An n-gram is a sequence of any n immeadiately
subsequent words. For example the text

    she sells sea shells on the sea shore

contains following 5-grams:

    she sells sea shells on
    sells sea shells on the
    sea shells on the sea
    shells on the sea shore

This attribute specifies the value of n (the size of n-gram).

B<default:> 5

=item stoplist

The stoplist is a list of very frequent words for given language (for English
e.g. a, the, is, ...). It is a good idea to remove the stoplist words from
texts before similarity is computed, because it is quite likely that two
documents will share n-grams of frequent words even if they are not similar
at all.

The stoplist can be specified both as an array of words and as a name of
a file where the words are stored one per line:

    $deduper->stoplist('a', 'the', 'is', @next_stopwords);
    $deduper->stoplist('/path/to/english_stoplist.txt');

Do not worry if you do not have a stoplist for your language. DeDuper will do
pretty good job even without the stoplist.

B<default:> empty

=back

=cut

sub encoding
{
    my $self     = shift;
    my $encoding = shift;
    $self->{encoding} = $encoding
        if defined $encoding;
    return $self->{encoding};
}

sub sim_trsh
{
    my $self     = shift;
    my $sim_trsh = shift;
    $self->{sim_trsh} = $sim_trsh
        if defined $sim_trsh;
    return $self->{sim_trsh};
}

sub ngram_size
{
    my $self     = shift;
    my $ngram_size = shift;
    $self->{ngram_size} = $ngram_size
        if defined $ngram_size;
    return $self->{ngram_size};
}

sub stoplist
{
    my $self     = shift;
    my @stoplist = @_;
    if (@stoplist && defined $stoplist[0])
    {
        if (@stoplist == 1 && -f $stoplist[0])
            { $self->_process_stoplist($stoplist[0]); }
        else
            { $self->_process_stoplist(\@stoplist); }
    }
    return sort keys %{$self->{_stoplist}};
}

# process stoplist attribute value
sub _process_stoplist
{
    my $self     = shift;
    my $stoplist = shift;

    $self->{_stoplist} = {};

    return unless
        defined $stoplist;

    # if not array, treat as filename
    if (ref($stoplist) ne 'ARRAY')
    {
        open(STOPLIST, '<', $stoplist)
            or croak("can't open '$stoplist' for reading: $!");
        while (<>)
        {
            chomp;
            $self->{_stoplist}->{$_} = 1;
        }
        close(STOPLIST);
    }
    else
    {
        foreach (@$stoplist)
            { $self->{_stoplist}->{$_} = 1; }
    }
}

# convert text into array of tokens (words)
sub _tokenise
{
    my $self = shift;
    my $text = shift;

    no warnings;
    my $dec_text = Encode::decode($self->{encoding}, $text);
    my $lc_text  = lc($dec_text);

    my @result;
    while ($lc_text =~ /([[:alnum:]]+)/g)
        { push @result, Encode::encode($self->{encoding}, $1); }
    use warnings;

    return @result;
}

# apply stoplist to array tokens (filter out stop words)
sub _apply_stoplist
{
    my $self   = shift;
    my @tokens = @_; 

    my @result;
    foreach my $token (@tokens)
    {
        push @result, $token
            unless $self->{_stoplist}->{$token};
    }

    return @result;
}

# convert array of tokens to array of unique hashes
# of ngrams (built out of the tokens)
sub _build_ngram_digests
{
    my $self   = shift;
    my @tokens = @_;

    my %digests;
    for my $i (0 .. scalar(@tokens) - $self->{ngram_size})
    {
        my @ngram  = @tokens[$i..($i+$self->{ngram_size}-1)];
        my $digest = Digest::MD4::md4_base64(@ngram);
        $digests{$digest} = 1;
    }

    return keys(%digests);
}

1;

__END__

=head1 MODULE DEPENDENCIES

=over

=item Encode

For decoding texts in various characters encodings into Perl's internal
form.

=item Digest::MD4

For n-grams hashing optimisation.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Text-DeDuper@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Encode>, L<Encode::Supported>, L<Digest::MD4>

=over

=item Andrei Z. Broder at al., Syntactic Clustering of the Web

http://www.ra.ethz.ch/CDstore/www6/Technical/Paper205/Paper205.html

Contains among other things definition of the resemblance measure.

=back

=head1 AUTHOR

Jan Pomikalek, C<< <xpomikal@fi.muni.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jan Pomikalek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
