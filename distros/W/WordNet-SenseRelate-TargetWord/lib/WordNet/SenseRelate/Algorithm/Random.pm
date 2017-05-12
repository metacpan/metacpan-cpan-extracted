# WordNet::SenseRelate::Algorithm::Random v0.09
# (Last updated $Id: Random.pm,v 1.9 2006/12/24 12:18:45 sidz1979 Exp $)

package WordNet::SenseRelate::Algorithm::Random;

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

    # No options accepted by this module
    $self->{optionlist} = {};

    # Initialize traces
    $trace = 0 if (!defined $trace);
    $self->{trace}       = $trace;
    $self->{tracestring} = "";

    return $self;
}

# Select the intended sense of the target word
sub disambiguate
{
    my $self    = shift;
    my $context = shift;
    my $trace   = $self->{trace};
    return undef if (!defined $self || !ref $self || !defined $context);
    return undef
      if (   !defined $context->{targetwordobject}
          || !defined $context->{contextwords});
    return undef
      if (   ref($context->{contextwords}) ne "ARRAY"
          || ref($context->{targetwordobject}) ne "WordNet::SenseRelate::Word");
    my $targetWord   = $context->{targetwordobject};
    my @targetSenses = $targetWord->getSenses();
    return undef if (scalar(@targetSenses) <= 0);

    if ($trace)
    {
        $self->{tracestring} .=
          "WordNet::SenseRelate::Algorithm::Random ~ Target senses: "
          . (join(", ", @targetSenses)) . "\n";
    }
    my $count  = scalar(@targetSenses);
    my $random = int(rand($count));
    if ($trace)
    {
        $self->{tracestring} .=
          "WordNet::SenseRelate::Algorithm::Random ~ Random number ($random)\n";
        $self->{tracestring} .=
"WordNet::SenseRelate::Algorithm::Random ~ Selected sense = $targetSenses[$random]\n";
    }
    return $targetSenses[$random];
}

# Get the trace string, and reset the trace
sub getTraceString
{
    my $self = shift;
    return ""
      if (   !defined $self
          || !ref($self)
          || ref($self) ne "WordNet::SenseRelate::Algorithm::Random");
    my $returnString = "";
    $returnString = $self->{tracestring} if (defined $self->{tracestring});
    $self->{tracestring} = "";
    return $returnString;
}

1;

__END__


=head1 NAME

WordNet::SenseRelate::Algorithm::Random - Perl module that randomly selects a sense of the
target word.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Algorithm::Random;

  $algo = WordNet::SenseRelate::Algorithm::Random->new($wntools);

  $sense = $algo->disambiguate($instance);

=head1 DESCRIPTION

WordNet::SenseRelate::Algorithm::Random is a module designed to randomly pick a sense of target
word, from its list of senses. The primary goal of this modules is to be able to compute a 
baseline for the disambiguation task.

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
