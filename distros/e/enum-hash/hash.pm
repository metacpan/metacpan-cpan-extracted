package enum::hash;
use strict;
use warnings;
use Carp;

require Exporter;
our $VERSION = '1.00';

our @ISA       = qw/ Exporter /;
our @EXPORT_OK = qw/ enum /;


sub enum {
  my $prefix = '';
  my $index  = 0;
  my @enum;
  
  while (@_) {
    my $item = shift;
    my $key;
    
    ## Prefix change
    if (substr($item, 0, 1) eq ':') {
      
      ## get rid of leading :
      $item = substr($item, 1);
      
      ## Index change too?
      my $tmp_prefix;
      
      if (index($item, '=') != -1) {
        my $assign;
        ($tmp_prefix, $assign) = split '=', $item;
        
        $index = index_change( $assign );
      }
      else {
        $tmp_prefix = $item;
      }
      
      ## Incase it's a null prefix
      $prefix = defined $tmp_prefix ? $tmp_prefix : '';
      
      next;
    }
    
    ## Index change
    elsif (index($item, '=') != -1) {
      my $assign;
      ($key, $assign) = split '=', $item;
      
      $index = index_change( $assign );
    }
    
    ## A..Z case magic lists
    elsif (index($item, '..') != -1) {
      
      my ($start, $end) = split(/\.\./, $item, 2);
      
      for ($start .. $end) {
        push @enum, $prefix.$_, $index++;
      }
      
      next;
    }
    
    ## Plain tag is most common case
    else {
      
      $key = $item;
    }
    
    push @enum, $prefix.$key, $index++;
  }
  
  return @enum;
}


sub index_change {
  my ($change) = @_;
  my ($neg, $index);
  
  if ($change =~ /(-?)(.+)/) {
    $neg   = $1;
    $index = $2;
  }
  else {
    croak (qq/No index value defined after "="/);
  }
  
  ## Convert non-decimal numerics to decimal
  if ($index =~ /^0x[\da-f]+$/i) {    ## Hex
      $index = hex $index;
  }
  elsif ($index =~ /^0\d/) {          ## Octal
      $index = oct $index;
  }
  elsif ($index !~ /[^\d_]/) {        ## 123_456 notation
      $index =~ s/_//g;
  }
  
  ## Force numeric context, but only in numeric context
  if ($index =~ /\D/) {
      $index  = "$neg$index";
  }
  else {
      $index  = "$neg$index";
      $index  += 0;
  }
  
  return $index;
}

1;

__END__

=head1 NAME

enum::hash - create a hash of 'enum's, with the same interface as enum.pm

=head1 SYNOPSIS

  use enum::hash 'enum';
  
  %days = enum (qw/ Sun Mon Tue Wed Thu Fri Sat /);
  # $enum{Sun} == 0, $enum{Mon} == 1, etc
  
  %random = enum (qw/ Forty=40 FortyOne Five=5 Six Seven /);
  # Yes, you can change the start indexes at any time as in C

  %count = enum (qw/ :Prefix_ One Two Three /);
  ## Creates $enum{Prefix_One}, $enum{Prefix_Two}, $enum{Prefix_Three}

  %letters = enum (qw/ :Letters_ A..Z /);
  ## Creates $enum{Letters_A}, $enum{Letters_B}, $enum{Letters_C}, ...

  %enum = enum (qw/
      :Months_=0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
      :Days_=0   Sun Mon Tue Wed Thu Fri Sat
      :Letters_=20 A..Z
  /);
  ## Prefixes can be changed mid list and can have index changes too

=head1 DESCRIPTION

Provides the same interface as the L<enum> module, but returns the 
values as a list, instead of creating symbolic constants.

By default, the 'index' values start at zero, increasing by one for each 
pair. You can change the index at any time by passing it after an equals 
sign.

  %enum = enum ('one=1', 'two', 'three', 'ten=10', 'eleven');
  # outputs
  one    => 1
  two    => 2
  three  => 3
  ten    => 10
  eleven => 11

You can set a prefix that will be prepended to each key name, by passing an 
item beginning with C<:>. You can remove any prefix by passing an item 
containing only C<:>.

  %enum = enum (qw/
    :prefix_ 1 2
    : 3 4
  /);
  # outputs
  prefix_1 => 1
  prefix_2 => 2
  3        => 3
  4        => 4

A prefix declaration can also set the index value.

  %enum = enum (qw/
    :day=1 One Two
  /);
  # outputs
  dayOne => 1
  dayTwo => 2

Any items containing C<..> will be treated as a list range:

  %enum = enum ('1..5');
  # is equivalent to
  %enum = enum (1 .. 5);

enum::hash is less restrictive on key names than L<enum> is: a key name can 
start with a character other than C<[a-zA-Z]>.

=head1 EXPORT

Nothing by default.

C<enum> subroutine, on request.

=head1 INCOMPATABILITY

Does not support L<enum>'s BITMASK function, and does not support any type 
of label before the C<:> prefix identifier.

  # Not Supported
  
  use enum qw(
      BITMASK:BITS_ FOO BAR CAT DOG
      ENUM: FALSE TRUE
      ENUM: NO YES
      BITMASK: ONE TWO FOUR EIGHT SIX_TEEN
  );

=head1 SUPPORT / BUGS

Submit to the CPAN bugtracker L<http://rt.cpan.org>.

=head1 SEE ALSO

L<enum> by Byron Brummer (see L</"COPYRIGHT AND LICENSE">).

=head1 AUTHOR

Carl Franks

=head1 CREDITS

Byron Brummer, author of L<enum> (see L</"COPYRIGHT AND LICENSE">).

=head1 COPYRIGHT AND LICENSE

Copyright 2005, Carl Franks.  All rights reserved.  

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself (L<perlgpl>, L<perlartistic>).

Contains code and documentation examples copied from the L<enum> 
distribution, by Byron Brummer.

  Derived from the original enum cpan distribution,
  Copyright 1998 (c) Byron Brummer. Copyright 1998 (c) OMIX, Inc.
  
  Permission to use, modify, and redistribute this module granted under the 
  same terms as Perl.

=cut

