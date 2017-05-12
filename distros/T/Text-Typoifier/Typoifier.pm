package Text::Typoifier;

require 5.005_62;
use strict;
use warnings;
use POSIX;
our $VERSION = '0.04a';


sub new 
{
    my $self = {};
    bless $self;
    $self->errorRate(5); # default error rate
    return $self;
}

sub errorRate 
{
    # rate of errors, between 1 and 10
    my $self = shift;
    my $errorRate = shift;
    if (defined($errorRate))
    {
       $self->{errorRate} = $errorRate;
    }
    return $self->{errorRate};
}

sub transform
{
    my $self = shift;
    my $text = shift;
    my $done = 0;
    if (rand(10) < $self->errorRate())
    {
       for (my $x = 0; $x <= 100; $x++)
       {
          my $text2 = $self->_transform($text);
          if ($text2 ne $text)
          {
              return $text2;
          }
       }
    }
    return $text;
}


sub _transform
{
   my $self = shift;
   my $text = shift;
   my $rand = POSIX::ceil(rand(4));
   return $self->transpose2($text) if ($rand == 1);
   return $self->stickyshift($text) if ($rand == 2);
   return $self->double($text) if ($rand == 3);
   return $self->deletion($text) if ($rand == 4);
}

sub arrayToString
{
    my $self = shift;
    my $ref2array = shift;
    my $string = "";
    for (my $x = 0; $x <= $#{$ref2array}; $x++)
    {
        $string .= $ref2array->[$x];
    }
    return $string;
}
 
sub transpose
{
    # this transposes any two characters. very unrealistic.
    my $self = shift;
    my $text = shift;
    my $length = length($text);
    my $randomChar = int(rand($length - 1));
    $text =~ /(.{$randomChar})(.)(.)/;
    return $` . $1 . $3 . $2 . $'
}

sub double
{ 
    my $self = shift;
    my $text = shift;
    my @sa = split '', $text;
    my $randomChar = int(rand($#sa));
    if ($sa[$randomChar] =~ /[A-Za-z]/)
    {
        splice(@sa, $randomChar, 0, $sa[$randomChar]);
        return $self->arrayToString(\@sa);
    }
    return $text;
}

sub deletion
{
    my $self = shift;
    my $text = shift;
    my @sa = split '', $text;
    my $randomChar = int(rand($#sa));
    splice(@sa, $randomChar, 1);
    return $self->arrayToString(\@sa);
}

sub stickyshift
{ 
    # this acts like a sticky shift key ie. TEsting
    my $self = shift;
    my $text = shift;
    my @sa = split '', $text;
    my $randomChar = int(rand($#sa));
    if ($text =~ /[A-Z][a-zA-Z]/)
    {
       my $done = 0;
       while ($done == 0)
       {
          if ($sa[$randomChar] =~ /[A-Z]/)
          {
              $sa[$randomChar+1] = uc($sa[$randomChar+1]);
              $done = 1;
          }
          $randomChar = int(rand($#sa - 1));
       }
       return $self->arrayToString(\@sa);
    }
    return $text;
}


sub transpose2
{
    # this transposes two characters, but only if they are lowercase
    # and also [a-z]
    my $self = shift;
    my $text = shift;
    my @sa = split '', $text;
    my $randomChar = int(rand($#sa - 1));
    if ($sa[$randomChar] =~ /[a-z\ ]/ && $sa[$randomChar] =~ /[a-z\ ]/)
    {
       ($sa[$randomChar], $sa[$randomChar + 1]) =
         ($sa[$randomChar + 1], $sa[$randomChar]);	
    }
    return $self->arrayToString(\@sa);
}

1;
=cut

=head1 NAME 

Text::Typoifier - mangles text

=head1 SYNOPSIS

   use Text::Typoifier;

   $t = new Text::Typoifier;
   $text = $t->transform($text);

=head1 DESCRIPTION

Text::Typoifier is used when you have a sample of text that you wish to induce random errors in the text. I use this for a few IRC bots to lend a little extra credibility to the bot. It's not really hard to use. 

=head1 METHODS

=head2 transform 
 
Pass in the text to transform, returns the transformed text.

=head1 ATTRIBUTES

=head2 errorRate

Configures the percentage of errors that the module outputs. The value must be an integer between 1 and 10. 10 means that 100% of the time an error will be present in the text. 5 means that 50% of the time an error will be in the text.

=head1 REQUIRES

Perl 5

=head1 EXPORTS

Nothing

=head1 AUTHOR

xjharding@mac.com

=cut
