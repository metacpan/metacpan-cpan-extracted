# WordNet::SenseRelate::Word v0.09
# (Last updated $Id: Word.pm,v 1.11 2006/12/24 12:18:45 sidz1979 Exp $)

package WordNet::SenseRelate::Word;

use strict;
use vars qw($VERSION @ISA);

@ISA     = qw(Exporter);
$VERSION = '0.09';

# Constructor for this module
sub new
{
    my $class = shift;
    my $self  = {};

    # Create the Word object
    $class = ref $class || $class;
    bless($self, $class);

    # Set the Word
    $self->{word}    = "";
    $self->{poslist} = "nvar";
    my $word = shift;
    if (defined $word)
    {
        my $pos = "nvar";
        $pos = $1 if ($word =~ /\#([nvar]+)$/);
        $word =~ s/\#.*//;
        $self->{word}    = $word;
        $self->{poslist} = $pos;
    }
    $self->{forms}  = [($self->{word})];
    $self->{senses} = [];

    # Set the word forms and word senses if WordNet is available
    my $wn = shift;
    if (   defined $wn
        && ref($wn)
        && ref($wn) eq "WordNet::QueryData"
        && defined $self->{word}
        && $self->{word} ne "")
    {

        # First try the surface form
        my $tmpWord    = $self->{word};
        my @poslist    = split(//, @{$self->{poslist}});
        my $newPosList = "";
        $self->{forms}  = [];
        $self->{senses} = [];
        foreach my $pos (@poslist)
        {
            my @senseList = $wn->querySense($tmpWord . "\#" . $pos);
            if (scalar(@senseList) > 0)
            {
                push(@{$self->{forms}},  $tmpWord);
                push(@{$self->{senses}}, @senseList);
                $newPosList .= $pos;
            }
        }

     # If the surface form was not found in WordNet, ask WordNet for suggestions
        if (scalar(@{$self->{senses}}) <= 0)
        {
            $newPosList = "";
            foreach my $pos ('n', 'v', 'a', 'r')
            {
                my @forms = $wn->validForms(($self->{word}) . "\#" . $pos);
                foreach my $form (@forms)
                {
                    my @senseList = $wn->querySense($form);
                    if (scalar(@senseList) > 0)
                    {
                        $form =~ s/\#.*//g;
                        push(@{$self->{forms}},  $form);
                        push(@{$self->{senses}}, @senseList);
                    }
                }
                $newPosList .= $pos if (scalar(@forms) > 0);
            }
        }

        $self->{poslist} = $newPosList;
    }

    return $self;
}

# Return the word
sub getWord
{
    my $self = shift;
    return undef if (!defined $self || !ref $self);
    return $self->{word};
}

# Return the list of senses
sub getSenses
{
    my $self = shift;
    return undef if (!defined $self || !ref $self);
    return @{$self->{senses}};
}

# Return the list of valid forms
sub getForms
{
    my $self = shift;
    return undef if (!defined $self || !ref $self);
    return @{$self->{forms}};
}

# Recompute senses
sub computeSenses
{
    my $self = shift;
    my $wn   = shift;
    my $wordpos = shift;
    
    return if (!defined $self || !ref $self);
    return if (!defined $wn || !ref($wn) || ref($wn) ne "WordNet::QueryData");
    return if (!defined $self->{word} || $self->{word} eq "");

    # First try the surface form
    my $tmpWord    = $self->{word};
    my @poslist    = split(//, $self->{poslist});
    @poslist = split(//, $wordpos) if(defined $wordpos && $wordpos =~ /^[nvar]+$/);
    my $newPosList = "";
    $self->{forms}  = [];
    $self->{senses} = [];
    foreach my $pos (@poslist)
    {
        my @senseList = $wn->querySense($tmpWord . "\#" . $pos);
        if (scalar(@senseList) > 0)
        {
            push(@{$self->{forms}},  $tmpWord);
            push(@{$self->{senses}}, @senseList);
            $newPosList .= $pos;
        }
    }

    # If the surface form was not found in WordNet, ask WordNet for suggestions
    if (scalar(@{$self->{senses}}) <= 0)
    {
        $newPosList = "";
        foreach my $pos (@poslist)
        {
            my @forms = $wn->validForms(($self->{word}) . "\#" . $pos);
            foreach my $form (@forms)
            {
                my @senseList = $wn->querySense($form);
                if (scalar(@senseList) > 0)
                {
                    $form =~ s/\#.*//g;
                    push(@{$self->{forms}},  $form);
                    push(@{$self->{senses}}, @senseList);
                }
            }
            $newPosList .= $pos if (scalar(@forms) > 0);
        }
    }

    $self->{poslist} = $newPosList;
}

# Retrieve all senses for the inherent sense restriction
sub retrieveSenses
{
    my $self = shift;
    my $wn   = shift;
    
    return if (!defined $self || !ref $self);
    return if (!defined $wn || !ref($wn) || ref($wn) ne "WordNet::QueryData");
    return if (!defined $self->{word} || $self->{word} eq "");

    # First try the surface form
    my $tmpWord    = lc($self->{word});
    my $speeches   = $self->{poslist};
    $speeches   = "nvar" if(!defined $speeches);
    my @poslist    = split(//, $speeches);
    my $newPosList = "";
    $self->{forms}  = [];
    $self->{senses} = [];
    foreach my $pos (@poslist)
    {
        my @senseList = $wn->querySense($tmpWord . "\#" . $pos);
        if (scalar(@senseList) > 0)
        {
            push(@{$self->{forms}},  $tmpWord);
            push(@{$self->{senses}}, @senseList);
            $newPosList .= $pos;
        }
    }

    # If the surface form was not found in WordNet, ask WordNet for suggestions
    if (scalar(@{$self->{senses}}) <= 0)
    {
        $newPosList = "";
        foreach my $pos (@poslist)
        {
            my @forms = $wn->validForms(($self->{word}) . "\#" . $pos);
            foreach my $form (@forms)
            {
                my @senseList = $wn->querySense($form);
                if (scalar(@senseList) > 0)
                {
                    $form =~ s/\#.*//g;
                    push(@{$self->{forms}},  $form);
                    push(@{$self->{senses}}, @senseList);
                }
            }
            $newPosList .= $pos if (scalar(@forms) > 0);
        }
    }

    $self->{poslist} = $newPosList;
}

# Remove senses corresponding to a particular part of speech
sub restrictSenses
{
    my $self = shift;
    my $postag = shift;

    return if (!defined $self || !ref $self);
    return if (!defined $postag || $postag eq "");
    return if (!defined $self->{senses} || ref($self->{senses}) ne "ARRAY");
  
    my @newSenses = ();
    foreach my $sense (@{$self->{senses}})
    {
        foreach my $theTag (split(//, $postag))
        {
            if($sense =~ /\#$theTag\#[0-9]+$/)
            {
                push(@newSenses, $sense);
                last;
            }
        }
    }

    $self->{senses} = [@newSenses];
}


1;


__END__

=head1 NAME

WordNet::SenseRelate::Word - Perl module that represents a single word from the context.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Word;

  $object = WordNet::SenseRelate::Word->new("balloon");

  $object->retrieveSenses($wn, "nva");

  $object->restrictSenses("n");

  @senses = $object->getSenses();

=head1 DESCRIPTION

WordNet::SenseRelate::Word represents a single word from the context. A collection of word
objects is used to represent an instance. Each word object contains the surface form of a
word. In addition, it also contain the morphological root form, and the WordNet senses of
the word if any.

=head2 EXPORT

None by default.

=head1 SEE ALSO

perl(1)

WordNet::SenseRelate::TargetWord(3)

WordNet::QueryData(3)

=head1 AUTHOR

Ted Pedersen, tpederse at d.umn.edu

Siddharth Patwardhan, sidd at cs.utah.edu

Satanjeev Banerjee, banerjee+ at cs.cmu.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ted Pedersen, Siddharth Patwardhan, and Satanjeev Banerjee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
