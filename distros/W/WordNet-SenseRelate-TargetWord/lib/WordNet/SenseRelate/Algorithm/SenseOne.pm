# WordNet::SenseRelate::Algorithm::SenseOne v0.09
# (Last updated $Id: SenseOne.pm,v 1.7 2006/12/24 12:18:46 sidz1979 Exp $)

package WordNet::SenseRelate::Algorithm::SenseOne;

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

    # No options
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

    if ($trace)
    {
        $self->{tracestring} .=
          "WordNet::SenseRelate::Algorithm::SenseOne ~ Target senses: "
          . (join(", ", @targetSenses)) . "\n";
    }
    return undef if (scalar(@targetSenses) <= 0);
    if ($trace)
    {
        $self->{tracestring} .=
"WordNet::SenseRelate::Algorithm::SenseOne ~ Selected sense = $targetSenses[0]\n";
    }
    return $targetSenses[0];
}

# Get the trace string, and reset the trace
sub getTraceString
{
    my $self = shift;
    return ""
      if (   !defined $self
          || !ref($self)
          || ref($self) ne "WordNet::SenseRelate::Algorithm::SenseOne");
    my $returnString = "";
    $returnString = $self->{tracestring} if (defined $self->{tracestring});
    $self->{tracestring} = "";
    return $returnString;
}

1;

__END__


=head1 NAME

WordNet::SenseRelate::Algorithm::SenseOne - Perl modules that picks the first sense of the target word.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Algorithm::SenseOne;

  $algo = WordNet::SenseRelate::Algorithm::SenseOne->new($wntools);

  $sense = $algo->disambiguate($instance);

=head1 DESCRIPTION

WordNet::SenseRelate::Algorithm::SenseOne is a module designed to pick the first sense of the
target word in a word sense disambiguation task. The primary goal of this module is to allow
us to create a baseline for this task.

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
