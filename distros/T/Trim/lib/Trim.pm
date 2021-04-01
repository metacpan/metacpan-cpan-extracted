#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Trim various things by removing leading and trailing whitespace.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Trim;
our $VERSION = "20210401";
use warnings FATAL => qw(all);
use strict;
use feature qw(say current_sub);

#D1 Trim                                                                        # Trim strings, arrays, hashes in situ and clones thereof.

sub trim(@)                                                                     # Trim somethings.
 {my (@things) = @_;                                                            # Things to be trimmed

  if (@_ == 0)                                                                  # Trim $_ as no argument specified
   {if (!defined(wantarray))                                                    # Void context - trim in place
     {if (!ref)                                                                 # Scalar string in $_ in void context
       {s/\A\s+|\s+\Z//gs;
       }
      elsif (ref eq q(ARRAY))                                                   # Array referenced from $_ in void context
       {for my $i(keys @$_)
         {$$_[$i] = __SUB__->($$_[$i]);
         }
       }
      elsif (ref eq q(HASH))                                                    # Hash referenced from $_ in void context
       {for my $k(keys %$_)
         {$$_{$k} = __SUB__->($$_{$k});
         }
       }
     }
    else                                                                        # Not void context - caller wants something back
     {if (!ref)                                                                 # Scalar string in $_ in non void context
       {return __SUB__->($_);
       }
      elsif (ref eq q(ARRAY))                                                   # Array referenced from $_ in non void context
       {return [__SUB__->(@$_)];
       }
      elsif (ref eq q(HASH))                                                    # Hash referenced from $_ in non void context
       {return {__SUB__->(%$_)};
       }
     }
   }
  else                                                                          # Arguments specified
   {if (!defined(wantarray))                                                    # Void context - trim in place
     {for my $i(keys @_)
       {if (!ref $_[$i])                                                        # Trim scalar in void context
         {$_[$i] = __SUB__->($_[$i]);
         }
        elsif (ref($_[$i]) eq q(ARRAY))                                         # Trim array reference in void context
         {for my $j(keys $_[$i]->@*)
           {$_[$i][$j] = __SUB__->($_[$i][$j]);
           }
         }
        elsif (ref($_[$i]) eq q(HASH))                                          # Trim hash reference  in void context
         {for my $k(keys $_[$i]->%*)
           {$_[$i]{$k} = __SUB__->($_[$i]{$k});
           }
         }
       }
     }
    else                                                                        # Want something back
     {my @r;
      for my $i(keys @_)
       {if (  !ref $_[$i])                                                      # Trim clone of scalar and return cloned value
         {push @r, $_[$i] =~ s/\A\s+|\s+\Z//gsr;
          return $r[0] if @_ == 1;
         }
        elsif (ref($_[$i]) eq q(ARRAY))                                         # Trim clone of array reference and return cloned value
         {my @a;
          for my $j(keys $_[$i]->@*)
           {push @a, __SUB__->($_[$i][$j]);
           }
          push @r, [@a];
          return $r[0] if @_ == 1;
         }
        elsif (ref($_[$i]) eq q(HASH))                                          # Trim clone of hash reference and return cloned value
         {my @a;
          for my $k(keys $_[$i]->%*)
           {push @a, (__SUB__->($k), __SUB__->($_[$i]{$k}));
           }
          push @r, {@a};
          return $r[0] if @_ == 1;
         }
       }
      return wantarray ? @r : @_ == $r[-1];                                     # Return array if requested else last element trimmed
     }
   }
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(trim);
@EXPORT_OK    = qw();
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Trim - Trim various things by removing leading and trailing whitespace

=head1 Synopsis

Trim nested structures in situ referenced from $_:

  {$_ = [" a ", " b ", {" c " => {" d\n ", " e "}}];
   trim;
   is_deeply $_, ["a", "b", { c => { d => "e" } }];
  }

Trim nested structures in situ:

  {my $a = [" a ", " b ", {" c " => {" d\n ", " e "}}];
   trim $a;
   is_deeply $a, ["a", "b", { c => { d => "e" } }];
  }

Trim cloned nested structures:

  {my $a = [" a ", " b ", {" c " => {" d\n ", " e "}}];
   my $b = trim $a;
   is_deeply $b, ["a", "b", { c => { d => "e" } }];
  }

=head1 Description

Trim various things by removing leading and trailing whitespace


Version "20210401".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Trim

Trim strings, arrays, hashes in situ and clones thereof.

=head2 trim(@things)

Trim somethings.

     Parameter  Description
  1  @things    Things to be trimmed

B<Example:>


    $_ = [" a ", " b ", {" c " => {" d ", " e "}}];                               # Trim nested structures in situ referenced from $_

    trim;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $_, ["a", "b", { c => { d => "e" } }];
  }

  {my $a = [" a ", " b ", {" c " => {" d ", " e "}}];                             # Trim nested structures in situ

   trim $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   is_deeply $a, ["a", "b", { c => { d => "e" } }];
  }

  {my $a = [" a ", " b ", {" c " => {" d ", " e "}}];                             # Trim cloned nested structures

   my $b = trim $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   is_deeply $b, ["a", "b", { c => { d => "e" } }];



=head1 Index


1 L<trim|/trim> - Trim somethings.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Trim

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Time::HiRes qw(time);
use Test::More tests=>25;

is_deeply trim(" \na\n\n  \t\r"), q(a);                                         # Trim a string - this what you get with 'other' languages

{$_ = " \n\ta\n\t  \n ";  trim; is_deeply $_, qq(a)}                            # Trim $_ in situ
{$_ = ['  a  ', "\nb\n"]; trim; is_deeply $_, [qw(a b)]}                        # Trim $_ refering to an array in situ
{$_ = {'  a  ', "\nb\n"}; trim; is_deeply $_, {'  a  ' =>'b'}}                  # Trim $_ refering to a hash in situ - only the hash values

{$_ = " \n\ta\n\t  \n ";  my $a = trim; is_deeply $a, qq(a)}                    # Trim a clones of $_ and return the result
{$_ = ['  a  ', "\nb\n"]; my $a = trim; is_deeply $a, [qw(a b)]}                # Trim a clones of $_ refering to an array and return the result
{$_ = {'  a  ', "\nb\n"}; my $a = trim; is_deeply $a, {a=>'b'}}                 # Trim a clones of $_ refering to a hash and return the result - only the hash values

{my $a = " \n\ta\nb\t  \n "; trim $a; is_deeply  $a, qq(a\nb)}                  # Trim a string in a variable situ
{my @a = (" a ", " b\n");    trim @a; is_deeply \@a, [qw(a b)]}                 # Trim the elements of an arry in situ
{my %a = (" a ", " b\n");    trim %a; is_deeply \%a, {" a "=>'b'}}              # Trim the values of a hash in situ
{my $a = [" a ", " b\n"];    trim $a; is_deeply  $a, [qw(a b)]}                 # Trim a reference to an array in situ
{my $a = {" a "=>" b\n"};    trim $a; is_deeply  $a, {" a "=>'b'}}              # Trim a reference to a hash in situ

{my $a = " \n\ta\nb\t  \n "; my $b = trim $a; is_deeply  $b, qq(a\nb)}          # Trim a clone of a single scalar value  and return the trimmed clone
{my @a = (" a ", " b\n");    my @b = trim @a; is_deeply \@b, [qw(a b)]}         # Trim a clone of an array of parameters and return the trimmed clones
{my %a = (" a ", " b\n");    my %b = trim %a; is_deeply \%b, {a=>'b'}}          # Trim a clone of a hash   of parameters and return the trimmed clones
{my $a = [" a ", " b\n"];    my $b = trim $a; is_deeply  $b, [qw(a b)]}         # Trim a clone of an array reference and return as an array reference
{my $a = {" a "=>" b\n"};    my $b = trim $a; is_deeply  $b, {a=>'b'}}          # Trim a clone of a hash   reference and return as a  hash  reference

{my $a = " \n\ta\nb\t  \n "; my @b = trim " 1", $a; is_deeply \@b, [1, qq(a\nb)]}  # Trim clones of scalar parameters and return as an array
{my @a = (" a ", " b\n");    my @b = trim " 1", @a; is_deeply \@b, [1, qw(a b)]}   # Trim clones of scalar and array parameters and return as an array
{my %a = (" a ", " b\n");    my @b = trim " 1", %a; is_deeply \@b, [1, qw(a b)]}   # Trim clones of scalar and hash  parameters and return as an array
{my $a = [" a ", " b\n"];    my @b = trim " 1", $a; is_deeply \@b, [1, [qw(a b)]]} # Trim clones of scalar and array reference parameters and return as an array containing an array reference
{my $a = {" a "=>" b\n"};    my @b = trim " 1", $a; is_deeply \@b, [1, {qw(a b)}]} # Trim clones of scalar and hash  reference parameters and return as an array containing a  hash reference

if (1) {                                                                        #Ttrim
  $_ = [" a ", " b ", {" c " => {" d ", " e "}}];                               # Trim nested structures in situ referenced from $_
  trim;
  is_deeply $_, ["a", "b", { c => { d => "e" } }];
}

{my $a = [" a ", " b ", {" c " => {" d ", " e "}}];                             # Trim nested structures in situ
 trim $a;
 is_deeply $a, ["a", "b", { c => { d => "e" } }];
}

{my $a = [" a ", " b ", {" c " => {" d ", " e "}}];                             # Trim cloned nested structures
 my $b = trim $a;
 is_deeply $b, ["a", "b", { c => { d => "e" } }];
}
