#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
# Simple Subclassing
package MyTTS;
use strict;
use warnings;
use lib qw(t/lib lib);
use base qw(Text::Template::Simple);
use Text::Template::Simple::Constants qw(:fields); # get the object fields 
use MyUtil;

sub new {
   my $class = shift;
   my $self  = $class->SUPER::new( @_ );
   _p "Sub class defined the constructor!\n";
   return $self;
}

sub compile {
   my $self = shift;
   _p 'Delimiters are: ' . join( ' & ', @{$self->[DELIMITERS] }) . "\n";
   return $self->SUPER::compile( @_ );
}

package main;

use strict;
use Test::More qw( no_plan );

ok(my $t = MyTTS->new, 'object');

ok( $t->compile(q/Just a test/), 'Compiled by subclass');
