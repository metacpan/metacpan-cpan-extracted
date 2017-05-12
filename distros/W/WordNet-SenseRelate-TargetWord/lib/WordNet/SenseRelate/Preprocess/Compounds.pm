# WordNet::SenseRelate::Preprocess::Compounds v0.09
# (Last updated $Id: Compounds.pm,v 1.8 2006/12/24 12:18:46 sidz1979 Exp $)

package WordNet::SenseRelate::Preprocess::Compounds;

use strict;
use warnings;
use Exporter;
use WordNet::SenseRelate::Tools;
use WordNet::SenseRelate::Word;

our @ISA     = qw(Exporter);
our $VERSION = '0.09';

# Constructor for this module
sub new
{
    my $class   = shift;
    my $wntools = shift;
    my $self    = {};
    my $trace   = shift;
    $trace = 0 if (!defined $trace);

    # Create the preprocessor object
    $class = ref $class || $class;
    bless($self, $class);

    # Read in the wordnet data
    if (   !defined $wntools
        || !ref $wntools
        || ref($wntools) ne "WordNet::SenseRelate::Tools")
    {
        $wntools = WordNet::SenseRelate::Tools->new($wntools);
        return undef if (!defined $wntools);
    }
    $self->{wntools}     = $wntools;
    $self->{trace}       = $trace;
    $self->{tracestring} = "";

    # No options for this module
    $self->{optionlist} = {};

    return $self;
}

# Preprocess a given input instance:
#  (1) Convert to lowercase
#  (2) Remove unwanted characters
#  (3) Combine all consecutive occurrence of numbers into one
#  (4) Detect compounds
#  (5) Split the words on white spaces
#  (6) Create a context object
sub preprocess
{
    my $self     = shift;
    my $instance = shift;
    my $wntools  = $self->{wntools};
    if (!defined($wntools))
    {
        $wntools = {};
        $wntools->{compounds} = {};
    }

    return undef if (!defined $self || !defined $instance);
    my $trace = $self->{trace};

    # Create empty context object
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
    my $context = {};
    $context->{words}       = [];
    $context->{text}        = [];
    $context->{head}        = -1;
    $context->{target}      = -1;
    $context->{wordobjects} = [];
    $context->{lexelt} = $instance->{lexelt} if (defined $instance->{lexelt});
    $context->{id}     = $instance->{id} if (defined $instance->{id});
    $context->{answer} = $instance->{answer} if (defined $instance->{answer});
    $context->{targetpos} = $instance->{targetpos}
      if (defined $instance->{targetpos});

    # Check that the text segments exist
    if (defined $instance->{text})
    {
        foreach my $textseg (@{$instance->{text}})
        {
            push(@{$context->{text}}, $textseg);
        }
    }
    $context->{head} = $instance->{head} if (defined $instance->{head});

    # Detect compounds in the words
    my $string;
    my $done;
    my $temp;
    my $firstPointer;
    my $secondPointer;

    # Start compound detection
    $firstPointer = 0;
    $string       = "";

    while ($firstPointer <= $#{$instance->{words}})
    {
        $secondPointer = (
                            ($#{$instance->{words}} > ($firstPointer + 7))
                          ? ($firstPointer + 7)
                          : ($#{$instance->{words}})
        );
        $done = 0;
        while ($secondPointer > $firstPointer && !$done)
        {
            $temp =
              join("_", @{$instance->{words}}[$firstPointer .. $secondPointer]);
            if (defined $wntools->{compounds}->{$temp})
            {
                push(@{$context->{words}}, $temp);
                push(
                     @{$context->{wordobjects}},
                     WordNet::SenseRelate::Word->new($temp)
                );
                $context->{target} = scalar(@{$context->{words}}) - 1
                  if (   defined $instance->{target}
                      && $instance->{target} >= $firstPointer
                      && $instance->{target} <= $secondPointer);
                $done = 1;
            }
            else
            {
                $secondPointer--;
            }
        }
        if (!$done)
        {
            push(@{$context->{words}}, $instance->{words}->[$firstPointer]);
            push(
                 @{$context->{wordobjects}},
                 WordNet::SenseRelate::Word->new(
                                             $instance->{words}->[$firstPointer]
                 )
            );
            $context->{target} = scalar(@{$context->{words}}) - 1
              if (defined $instance->{target}
                  && $instance->{target} == $firstPointer);
        }
        $firstPointer = $secondPointer + 1;
    }

    return $context;
}

# Get the trace string, and reset the trace
sub getTraceString
{
    my $self = shift;
    return ""
      if (   !defined $self
          || !ref($self)
          || ref($self) ne "WordNet::SenseRelate::Preprocess::Compounds");
    my $returnString = "";
    $returnString = $self->{tracestring} if (defined $self->{tracestring});
    $self->{tracestring} = "";
    return $returnString;
}

1;


__END__


=head1 NAME

WordNet::SenseRelate::Preprocess::Compounds - Perl module that detects compounds in a piece of text.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Preprocess::Compounds;

  $preprocess = WordNet::SenseRelate::Preprocess::Compounds->new($wntools);

  $newInstance = $preprocess->preprocess($instance);

=head1 DESCRIPTION

This module is a preprocessor module for the WordNet::SenseRelate::TargetWord algorithm. It 
take as input an instance, and detects WordNet compounds within this instance.

=head2 EXPORT

None by default.

=head1 SEE ALSO

perl(1)

WordNet::SenseRelate::TargetWord

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
