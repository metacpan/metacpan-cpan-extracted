# WordNet::SenseRelate::Tools v0.09
# (Last updated $Id: Tools.pm,v 1.4 2006/12/24 12:18:45 sidz1979 Exp $)

package WordNet::SenseRelate::Tools;

use strict;
use warnings;
use Exporter;
use WordNet::QueryData;

our @ISA     = qw(Exporter);
our $VERSION = '0.09';

# Constructor for this module
sub new
{
    my $class = shift;
    my $wn    = shift;
    my $self  = {};

    # Create the preprocessor object
    $class = ref $class || $class;
    bless($self, $class);

    # Read in the wordnet data
    if (!defined $wn || !ref $wn || ref($wn) ne "WordNet::QueryData")
    {
        my $wnpath = undef;
        $wnpath = $wn if(defined $wn && !ref($wn) && $wn ne "");
        $wn = WordNet::QueryData->new($wnpath);
        return undef if (!defined $wn);
    }
    $self->{wn} = $wn;

    # Get the compounds from WordNet
    foreach my $pos ('n', 'v', 'a', 'r')
    {
        foreach my $word ($wn->listAllWords($pos))
        {
            $self->{compounds}->{$word} = 1 if ($word =~ /_/);
        }
    }

    return $self;
}

# Detect compounds in a block of text
sub compoundify
{
    my $self  = shift;
    my $block = shift;

    return $block
      if (!defined $block || !ref $self || !defined $self->{compounds});

    my $string;
    my $done;
    my $temp;
    my $firstPointer;
    my $secondPointer;
    my @wordsArray;

    # get all the words into an array
    @wordsArray = ();
    while ($block =~ /(\w+)/g)
    {
        push(@wordsArray, $1);
    }

    # now compoundify, GREEDILY!!
    $firstPointer = 0;
    $string       = "";

    while ($firstPointer <= $#wordsArray)
    {
        $secondPointer =
          (   ($#wordsArray > ($firstPointer + 7))
            ? ($firstPointer + 7)
            : ($#wordsArray));
        $done = 0;
        while ($secondPointer > $firstPointer && !$done)
        {
            $temp = join("_", @wordsArray[$firstPointer .. $secondPointer]);
            if (defined $self->{compounds}->{$temp})
            {
                $string .= "$temp ";
                $done = 1;
            }
            else
            {
                $secondPointer--;
            }
        }
        if (!$done)
        {
            $string .= "$wordsArray[$firstPointer] ";
        }
        $firstPointer = $secondPointer + 1;
    }
    $string =~ s/ $//;

    return $string;
}

1;

__END__

=head1 NAME

WordNet::SenseRelate::Tools - Perl modules that provides certain common WordNet tools.

=head1 SYNOPSIS

  use WordNet::SenseRelate::Tools;

  $wn = WordNet::SenseRelate::Tools->new();

  $newtext = $wn->compoundify($text);

=head1 DESCRIPTION

WordNet::SenseRelate::Tools is a set of common WordNet tools required in programs. Currently,
this module only contains a compound detection method. Other methods will be added in the future.
Additionally, this module will, most likely, be distributed independently of this package.

=head2 EXPORT

None by default.

=head1 SEE ALSO

perl(1)

WordNet::QueryData(3)

=head1 AUTHOR

Ted Pedersen, tpederse at d.umn.edu

Siddharth Patwardhan, sidd at cs.utah.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ted Pedersen and Siddharth Patwardhan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
