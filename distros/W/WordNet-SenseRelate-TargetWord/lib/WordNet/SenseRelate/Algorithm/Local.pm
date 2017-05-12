# WordNet::SenseRelate::Algorithm::Local v0.09
# (Last updated $Id: Local.pm,v 1.10 2006/12/24 12:18:45 sidz1979 Exp $)

package WordNet::SenseRelate::Algorithm::Local;

use strict;
use warnings;
use Exporter;

our @ISA     = qw(Exporter);
our $VERSION = '0.09';

# Constructor for this module
sub new
{
    my $class   = shift;
    my $wntools = shift;
    my $self    = {};
    my $trace   = shift;
    my $config  = shift;
    $trace = 0 if (!defined $trace);

    # Create the preprocessor object
    $class = ref $class || $class;
    bless($self, $class);

    # Read in the wordnet data, if required
    if (   !defined $wntools
        || !ref($wntools)
        || ref($wntools) ne "WordNet::SenseRelate::Tools")
    {
        my $wnpath = undef;
        $wnpath = $wntools
          if (defined $wntools && !ref($wntools) && $wntools ne "");
        $wntools = WordNet::SenseRelate::Tools->new($wnpath);
        return undef if (!defined $wntools);
    }
    $self->{wntools} = $wntools;

    # Load Similarity module
    my $modulePath   = "WordNet::Similarity::jcn";
    my $moduleName   = $modulePath;
    my $moduleConfig = undef;
    if (defined $config && ref($config) eq "HASH")
    {
        $modulePath   = $config->{measure} if (defined $config->{measure});
        $moduleName   = $modulePath;
        $moduleConfig = $config->{measureconfig}
          if (defined $config->{measureconfig});
    }
    $modulePath =~ s/::/\//g;
    $modulePath .= ".pm";
    require $modulePath;
    my $module = $moduleName->new($wntools->{wn}, $moduleConfig);
    return undef if (!defined($module));
    $module->{'trace'} = 2 if ($trace);
    $self->{measure} = $module;

    # Get the parts of speech for this module
    my $measurepos = "";
    foreach my $mypos ('n', 'v', 'a', 'r')
    {
        $measurepos .= $mypos if (defined $module->{$mypos});
    }
    $measurepos = "nvar" if ($measurepos eq "");
    $self->{contextpos} = $measurepos;

    # Sanity check on the similarity module
    return undef
      if (   !defined $self->{measure}
          || !ref($self->{measure})
          || !($self->{measure}->can('getRelatedness')));

    # Options accepted by this module
    $self->{optionlist}                  = {};
    $self->{optionlist}->{measure}       = "m!!0!!WordNet::Similarity::jcn";
    $self->{optionlist}->{measureconfig} = "f!!0!!";

    # Initialize traces
    $self->{tracestring} = "";
    $self->{trace}       = $trace;
    $self->{trace}       = 0 if (!defined $self->{trace});

    return $self;
}

# Select the intended sense of the target word
sub disambiguate
{
    my $self    = shift;
    my $context = shift;

    # Sanity checks on self and context
    return undef if (!defined $self || !ref $self || !defined $context);
    return undef
      if (   !defined $context->{targetwordobject}
          || !defined $context->{contextwords});
    return undef
      if (   ref($context->{contextwords}) ne "ARRAY"
          || ref($context->{targetwordobject}) ne "WordNet::SenseRelate::Word"
          || scalar(@{$context->{contextwords}}) <= 0);

    # Get the input required
    my $trace        = $self->{trace};
    my $measure      = $self->{measure};
    my $targetWord   = $context->{targetwordobject};
    my @targetSenses = $targetWord->getSenses();
    return undef if (scalar(@targetSenses) <= 0);

    # Print the list of target senses to the trace string
    if ($trace)
    {
        $self->{tracestring} .=
          "WordNet::SenseRelate::Algorithm::Local ~ Target senses:"
          . (join(", ", @targetSenses)) . "\n";
    }

    # Iterate over the target senses
    my %senseScores     = ();
    my %sensePairScores = ();
    my $max             = 0;
    my $maxSense        = "";
    foreach my $targetSense (@targetSenses)
    {

        # Iterate over the context words
        $senseScores{$targetSense} = 0;
        foreach my $wObject (@{$context->{contextwords}})
        {

            # Iterate over the senses of the context word
            $max      = 0;
            $maxSense = "";
            foreach my $wordSense ($wObject->getSenses())
            {

                # Get similarity
                my $similarity =
                  $measure->getRelatedness($targetSense, $wordSense);
                my ($errorCode, $errorString) = $measure->getError();

                # If error do what needs to be done
                if ($errorCode == 1) { printf STDERR "$errorString\n"; }
                elsif ($errorCode == 2)
                {
                    return (0, $errorCode, $errorString);
                }

                # Check against max
                if ($similarity > $max)
                {
                    $max      = $similarity;
                    $maxSense = $wordSense;
                }
                if ($trace)
                {
                    $self->{tracestring} .=
"WordNet::SenseRelate::Algorithm::Local ~ sim($targetSense, $wordSense) = $similarity\n";
                    $self->{tracestring} .= $measure->getTraceString();
                }
            }
            $senseScores{$targetSense} += $max;
            $sensePairScores{"$targetSense, $maxSense"} = $max;
        }
    }

    # More tracing
    if ($trace)
    {
        foreach my $keySense (keys(%sensePairScores))
        {
            $self->{tracestring} .=
"WordNet::SenseRelate::Algorithm::Local ~ Maximum score for pair ($keySense) = ";
            $self->{tracestring} .= $sensePairScores{$keySense};
            $self->{tracestring} .= "\n";
        }
    }

    my ($intended) =
      sort { $senseScores{$b} <=> $senseScores{$a} } keys %senseScores;
    $self->{tracestring} .=
      "WordNet::SenseRelate::Algorithm::Local ~ Selected sense = $intended\n"
      if ($trace);

    return $intended;
}

# Get the trace string, and reset the trace
sub getTraceString
{
    my $self = shift;
    return ""
      if (   !defined $self
          || !ref($self)
          || ref($self) ne "WordNet::SenseRelate::Algorithm::Local");
    my $returnString = "";
    $returnString = $self->{tracestring} if (defined $self->{tracestring});
    $self->{tracestring} = "";
    return $returnString;
}

1;

__END__


=head1 NAME

WordNet::SenseRelate::Algorithm::Local - Perl module that finds the sense of a target word
that is most related to its context.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Algorithm::Local;

  $algo = WordNet::SenseRelate::Algorithm::Local->new($wntools, $measure);

  $sense = $algo->disambiguate($instance);

=head1 DESCRIPTION

This modules uses a measure of relatedness (WordNet::Similarity module) to find the relatedness of
each sense of the target word with the senses of the words in the context. It then return the
most related sense of the target word.

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
