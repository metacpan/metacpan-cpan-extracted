# WordNet::SenseRelate::Reader::Senseval2 v0.09
# (Last updated $Id: Senseval2.pm,v 1.10 2006/12/24 12:18:47 sidz1979 Exp $)

package WordNet::SenseRelate::Reader::Senseval2;

use strict;
use XML::Parser;
use WordNet::SenseRelate::Tools;
use WordNet::SenseRelate::Word;
use vars qw($VERSION @ISA);

@ISA     = qw(Exporter);
$VERSION = '0.09';

# Constructor for this module
# Instance Fields:
#   (a) text (array)
#   (b) words (array)
#   (c) head (scalar:int)
#   (d) target (scalar:int)
#   (e) wordobjects (array)
#   (f) lexelt (scalar:"art.n")
#   (g) id (scalar:string)
#   (h) answer (scalar:string, optional)
#   (i) targetpos (scalar:string, "n/v/a/r")
sub new
{
    my $class = shift;
    my $self  = {};

    # Create the Senseval2-reader object
    $class = ref $class || $class;
    bless($self, $class);

    # Read in the Senseval-2 data
    $self->{instances} = [];
    return undef if (!($self->_processFile(shift)));

    # Initialize WordNet tools
    my $wntools = shift;
    if (   !defined $wntools
        || !ref $wntools
        || ref($wntools) ne "WordNet::SenseRelate::Tools")
    {
        $wntools = WordNet::SenseRelate::Tools->new($wntools);
        return undef if (!defined $wntools);
    }
    $self->{wntools} = $wntools;

    return $self;
}

# Read in another Senseval-2 file
sub read
{
    my $self  = shift;
    my $fname = shift;

    # Basic checks on input
    return undef if (!ref $self);
    return undef if (!defined $fname);

    return undef if (!($self->_processFile($fname)));
    return 1;
}

# Return the instance count
sub instanceCount
{
    my $self = shift;
    return 0 if (!defined $self || !ref $self);
    return scalar(@{$self->{instances}});
}

# Return the ith instance
sub instance
{
    my $self  = shift;
    my $index = shift;
    return undef if (!defined $self || !ref $self);
    return undef
      if (   !defined $index
          || $index !~ /[0-9]+/
          || $index < 0
          || $index > $#{$self->{instances}});
    return $self->{instances}->[$index];
}

# Process a single XML file
sub _processFile
{
    my $self  = shift;
    my $fname = shift;

    # Perform some basic checks on input data
    return 0 if (!defined $self || !defined $fname || !ref $self);

    # Create a parser object, read the file
    my $xmlparser = XML::Parser->new("Style" => "Tree");
    my $parseTree;
    eval { $parseTree = $xmlparser->parsefile($fname); };

    # Paring error
    if ($@)
    {
        undef $parseTree;
        return 0;
    }

    # Traverse the parse tree, create our instances
    while (scalar(@{$parseTree}) > 1)
    {

        # Looking for a "corpus" node
        my $key = shift(@{$parseTree});
        my $val = shift(@{$parseTree});
        next if ($self->_isTextNode($key, $val) || $key ne "corpus");

        # Check for english language
        my $attribHash = shift(@{$val});
        my $language   = "english";
        $language = lc($attribHash->{"lang"})
          if (defined $attribHash && defined $attribHash->{"lang"});

        # Get the instances from the corpus
        push(@{$self->{instances}}, $self->_processCorpus($val))
          if ($language =~ /^en/);
    }

    return 1;
}

# Check if a node is a text node
sub _isTextNode
{
    my $self  = shift;
    my $label = shift;
    my $data  = shift;
    return 0 if (!defined $self);
    return 0 if (!defined $label || !defined $data);
    return 1 if ($label eq "0" && !ref($data));
    return 0;
}

# Process a senseval corpus
sub _processCorpus
{
    my $self = shift;
    my $aRef = shift;
    return () if (!defined $self);
    return () if (!defined $aRef || !ref $aRef);

    # Traversing a corpus tree
    my $lexelt    = "";
    my @instances = ();
    while (scalar(@{$aRef}) > 1)
    {

        # Get one node
        my $wonKey = shift(@{$aRef});
        my $wonVal = shift(@{$aRef});
        next if ($self->_isTextNode($wonKey, $wonVal));

        # Check for lexelt nodes
        if ($wonKey eq "lexelt" && ref($wonVal))
        {
            my $attr = shift(@{$wonVal});
            $lexelt = $attr->{"item"}
              if (defined $attr && defined $attr->{"item"});
            $lexelt =~ s/^\s+//;
            $lexelt =~ s/\s+$//;
            push(@instances, $self->_processLexelt($lexelt, $wonVal));
        }
    }

    return @instances;
}

# Process a lexelt
sub _processLexelt
{
    my $self   = shift;
    my $lexelt = shift;
    my $aRef   = shift;

    # Perform basic checks on input
    return () if (!defined $self);
    return ()
      if (   !defined $lexelt
          || !defined $aRef
          || $lexelt eq ""
          || !ref $aRef);

    # Traverse the lexelt node
    my @instances = ();
    my $id        = "";
    while (scalar(@{$aRef}) > 1)
    {

        # Get the node data
        my $wonKey = shift(@{$aRef});
        my $wonVal = shift(@{$aRef});

        # Follow down to the instance node
        if ($wonKey eq "instance" && ref($wonVal))
        {
            my $attr = shift(@{$wonVal});
            $id = $attr->{"id"} if (defined $attr && defined $attr->{"id"});
            $id =~ s/^\s+//;
            $id =~ s/\s+$//;
            my $inst = $self->_getInstance($lexelt, $id, $wonVal);
            push(@instances, $inst) if (defined $inst);
        }
    }

    return @instances;
}

# Get one instance/context
sub _getInstance
{
    my $self    = shift;
    my $lexelt  = shift;
    my $id      = shift;
    my $aRef    = shift;
    my $wntools = $self->{wntools};

    # Perform basic input checks
    return undef if (!defined $self);
    return undef
      if (   !defined $aRef
          || !defined $lexelt
          || !defined $id
          || !ref($aRef)
          || $lexelt eq ""
          || $id     eq "");

    # Create an empty instance
    my $retRef = {};
    $retRef->{text}        = [];
    $retRef->{words}       = [];
    $retRef->{head}        = -1;
    $retRef->{target}      = -1;
    $retRef->{wordobjects} = [];

    # Traverse the node
    my ($aid, $sid) = ("", "");
    while (scalar(@{$aRef}) > 1)
    {

        # Get the node data
        my $wonKey = shift(@{$aRef});
        my $wonVal = shift(@{$aRef});

        # Get the answer, if specified
        if ($wonKey eq "answer" && ref($wonVal))
        {
            my $attr = shift(@{$wonVal});
            $aid = $attr->{"instance"}
              if (defined $attr && defined $attr->{"instance"});
            $aid =~ s/^\s+//;
            $aid =~ s/\s+$//;
            $sid = $attr->{"senseid"}
              if (   defined $attr
                  && defined $attr->{"senseid"}
                  && $aid eq $id);
            $aid =~ s/^\s+//;
            $aid =~ s/\s+$//;
        }

        # Get the context info
        if ($wonKey eq "context" && ref($wonVal))
        {

            # Ignore attribs hash
            shift(@{$wonVal});

            # Traverse the context node
            while (scalar(@{$wonVal}) > 1)
            {

                # Get context data
                my $textKey = shift(@{$wonVal});
                my $textVal = shift(@{$wonVal});

                # Concatenate all text data
                if ($self->_isTextNode($textKey, $textVal))
                {
                    push(@{$retRef->{text}}, $textVal);
                    my $segment = lc($textVal);
                    $segment =~ s/[\n\r\f]+/ /g;
                    $segment =~ s/^\s+//;
                    $segment =~ s/\s+$//;
                    $segment =~ s/\[[^\]]*\]//g;
                    $segment =~ s/\&([a-z]*\;)+//g;
                    $segment =~ s/\'//g;              #'
                    $segment =~ s/[^a-z0-9]+/ /g;
                    while ($segment =~ s/([0-9]+)\s+([0-9]+)/$1$2/g) { }
                    $segment = $wntools->compoundify($segment)
                      if (defined($wntools));
                    $segment =~ s/^\s+//;
                    $segment =~ s/\s+$//;
                    my @tmpArr = split(/\s+/, $segment);
                    push(@{$retRef->{words}}, @tmpArr);

                    foreach my $wrd (@tmpArr)
                    {
                        push(
                             @{$retRef->{wordobjects}},
                             WordNet::SenseRelate::Word->new($wrd)
                        );
                    }
                }

                # Get text from head node
                elsif ($textKey eq "head" && ref($textVal))
                {
                    $retRef->{head} = scalar(@{$retRef->{text}});
                    my $attr    = shift(@{$textVal});
                    my $segment = "";
                    if (ref($attr) && defined $attr->{"sats"})
                    {
                        $segment = $attr->{"sats"};
                        $segment =~ s/^\s+//;
                        $segment =~ s/\s+.*//;
                        $segment =~ s/\.[0-9\:\s]*$//;
                        push(@{$retRef->{text}}, $segment);
                    }
                    else
                    {
                        $segment = $self->_getAllText($textVal);
                        push(@{$retRef->{text}}, $segment);
                    }
                    $segment = lc($segment);
                    $segment =~ s/[\n\r\f]+/ /g;
                    $segment =~ s/^\s+//;
                    $segment =~ s/\s+$//;
                    $segment =~ s/\[[^\]]*\]//g;
                    $segment =~ s/\&([a-z]*\;)+//g;
                    $segment =~ s/\'//g;              #'
                    $segment =~ s/[^a-z0-9]+/ /g;
                    while ($segment =~ s/([0-9]+)\s+([0-9]+)/$1$2/g) { }
                    $segment =~ s/^\s+//;
                    $segment =~ s/\s+$//;
                    my $tmpWrd = join("_", split(/\s+/, $segment));
                    push(@{$retRef->{words}}, $tmpWrd);
                    push(
                         @{$retRef->{wordobjects}},
                         WordNet::SenseRelate::Word->new($tmpWrd)
                    );
                    $retRef->{target} = scalar(@{$retRef->{words}}) - 1;
                }
            }
        }
    }

    # Complete the instance object data
    $retRef->{lexelt}    = $lexelt;
    $retRef->{id}        = $id;
    $retRef->{answer}    = $sid if (defined $aid && $aid ne "");
    $retRef->{targetpos} = $1 if ($lexelt =~ /\.([nvar])$/);

    return $retRef;
}

# Get all the text from inside a tag
sub _getAllText
{
    my $self = shift;
    my $aRef = shift;

    # Perform some basic input checks
    return "" if (!defined $self);
    return "" if (!defined $aRef || !ref $aRef);

    # Traverse the node
    my $text = "";
    while (scalar @{$aRef} > 1)
    {

        # Get node data
        my $first  = shift(@{$aRef});
        my $second = shift(@{$aRef});

        # Concatenate the text
        $text .= " $second" if ($self->_isTextNode($first, $second));
        print STDERR "In getAllText(): Not a text node. Tag=$first\n"
          if (!$self->_isTextNode($first, $second));
    }

    return $text;
}

# Print the XML parse tree
sub printTree
{
    my $self  = shift;
    my $fname = shift;
    return if (!defined $self || !defined $fname);

    # Create a parser object
    my $xmlparser = XML::Parser->new("Style" => "Tree");
    my $parseTree;
    eval { $parseTree = $xmlparser->parsefile($fname); };

    # Paring error
    if ($@)
    {
        undef $parseTree;
        return;
    }

    $self->_printTree($parseTree);
}

# Recursive routine to traverse tree
sub _printTree
{
    my $self      = shift;
    my $parseTree = shift;
    my ($attribs, $key, $val);
    return if (!defined $self || !defined $parseTree || !ref $parseTree);

    # Traverse the tree
    while (scalar(@{$parseTree}))
    {
        $key = shift(@{$parseTree});
        $val = shift(@{$parseTree});
        if (ref($key))
        {
            print STDERR "Key Error!\n";
            return;
        }
        elsif ($key eq "0")
        {
            print STDERR "$val ";
        }
        elsif (!ref($val))
        {
            print STDERR "Val Error!\n";
            return;
        }
        else
        {
            $attribs = shift(@{$val});
            print STDERR "Key: ($key) ";
            $self->_printTree($val);
        }
    }
}

1;

__END__

=head1 NAME

WordNet::SenseRelate::Reader::Senseval2 - Perl module for reading in a Senseval-2
formatted, lexical sample file.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Reader::Senseval2;

  $reader = WordNet::SenseRelate::Reader::Senseval2->new($filename);

=head1 DESCRIPTION

This module parses the XML formatted data of the Senseval-2 lexical sample data file and store
the instances in the created object. This data can then be accessed from the object for further
processing.

=head2 EXPORT

None by default.

=head1 SEE ALSO

perl(1)

WordNet::SenseRelate::TargetWord(3)

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
