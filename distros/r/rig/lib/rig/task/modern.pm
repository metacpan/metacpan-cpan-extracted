package rig::task::modern;
{
  $rig::task::modern::VERSION = '0.04';
}

sub rig {
     return {
      use => [
         'strict',
         { 'warnings'=> [ 'FATAL','all' ] }
      ]
   };
}

=head1 NAME

rig::task::modern - standard modern Perl

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A basic Modern Perl setting:


    use strict;
    use warnings qw/FATAL all/;

=cut

1;
