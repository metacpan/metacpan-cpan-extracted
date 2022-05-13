#!/usr/bin/env perl

package My::Opts;

use FindBin qw( $RealBin );
use lib "$RealBin/lib";

use v5.32;
use Mojo::Base -strict;
use Getopt::Long qw( GetOptions );
use Mojo::Util qw( dumper );
use My::Array();

=head2 new

Input:
   [
      {
         desc => "Option1",
         spec => "opt1=s",
      },
      {
         desc => "Option2",
         spec => "opt2=s",
      },
   ]

=cut

sub new {
   my ( $class, $spec ) = @_;

   my $s = bless {
      _args => \@ARGV,
      _spec => $spec,
   }, $class;

   $s->_init();
   $s;
}

sub _init {
   my ( $s ) = @_;

   $s->_parse();

   GetOptions( $s, $s->{_opts_spec}->@* ) or die "\n[$!]\n";

   $s->debug()        if $s->{debug};
   $s->list_options() if $s->{list_options};
}

sub _parse {
   my ( $s ) = @_;

   my $parsed = $s->{_parsed} = $s->__parse();

   $s->{_opts_spec} = [ map { $_->{spec} } @$parsed ];
   $s->{_opts_list} = [ sort map { $_->{list}->@* } @$parsed ];

   $s;
}

sub __parse {
   my ( $s ) = @_;

   my @parsed = map {
      my $opt_spec = $_->{spec};
      my $opt_desc = $_->{desc};
      my @opt_list = split /\|/, $opt_spec;
      my $arg      = $1 if $opt_list[-1] =~ s/ (\W+.*) //x;

      for ( @opt_list ) {
         s/ (?=^\w{2,}) /--/x;    # Long options.
         s/ (?=^\w$)     /-/x;    # Short options.
      }

      {
         key  => $_,
         spec => $opt_spec,
         list => \@opt_list,
         arg  => $arg         // "",
         desc => $opt_desc        // "...",
      };

     }
     $s->{_spec}->@*;

   \@parsed;
}

sub debug {
   my ( $s ) = @_;
   delete $s->{_parsed} unless $s->{debug} > 1;
   say dumper $s;
   exit 1;
}

sub list_options {
   my ( $s ) = @_;
   say for $s->{_opts_list}->@*;
   exit 1;
}

sub build_help_options {
   my ( $s )  = @_;
   my $indent = " " x 6;
   my $parsed = $s->{_parsed};

   my @line = map {
      my $arg       = _expand_arg( $_->{arg} );
      my $opts_list = join ", ", $_->{list}->@*;
      [ "$opts_list$arg", $_->{desc}, ]
   } @$parsed;

   my $max    = My::Array->max_lengths( \@line );
   my $format = $s->_make_format( $max );
   my $output = join "\n$indent", map { sprintf $format, @$_; } @line;

   $output;
}

sub _expand_arg {
   local ( $_ ) = @_;

   my $required = s/=//;
   my $optional = s/:(\d+)/DEFAULT=$1/ or s/://;

   my %means = (
      s   => "STRING",
      i   => "INTEGER",
      '+' => "INCREMENT",
   );

   my $arg = $means{$_} // $_;

   $arg = "[$arg]" if $optional;
   $arg = " $arg"  if $arg ne "";

   $arg;
}

sub _make_format {
   my ( $s, $max ) = @_;
   join " # ", map { "%-${_}s" } @$max;
}

1;
