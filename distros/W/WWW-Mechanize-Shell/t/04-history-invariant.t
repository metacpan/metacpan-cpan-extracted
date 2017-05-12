#!/usr/bin/perl -w
use strict;

use lib './inc';
use IO::Catch;

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

use vars qw( @history_invariant @history_add );

BEGIN {
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;

  # Also disable the paged output of Term::Shell

  @history_invariant = qw(
      browse
      cookies
      dump
      eval
      exit
      forms
      history
      links
      parse
      quit
      restart
      script
      set
      source
      tables
      versions
      ct
      response
      title
      headers
  );
  push @history_invariant, "headers 1","headers 12","headers 2","headers 12345";
  push @history_invariant, "#","      #", "# a comment", "  # another comment";

  @history_add = qw(
      autofill
      back
      click
      content
      fillout
      get
      open
      reload
      save
      submit
      table
      ua
      value
      tick
      untick
      referer
      referrer
      timeout
  );
};

# For testing the "versions" command
sub WWW::Mechanize::Shell::print_pairs {};

use Test::More tests => scalar @history_invariant +1;
SKIP: {

use_ok('WWW::Mechanize::Shell');

# Silence all warnings
#$SIG{__WARN__} = sub {};

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
$s->agent->{content} = '';

my @history;

sub disable {
  my ($namespace,$subname) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"$namespace\::$subname"} = sub { return };
};

{ no warnings 'redefine','once';
  *WWW::Mechanize::Shell::add_history = sub {
    shift;
    push @history, join "", @_;
  };
  
  *WWW::Mechanize::links = sub {()};
};

disable( "WWW::Mechanize::Shell", $_ )
  for (qw( restart_shell browser ));

disable( "WWW::Mechanize",$_ )
  for (qw( cookie_jar current_form forms ));

disable( "Term::Shell",$_ )
  for (qw( print_pairs ));

for my $cmd (@history_invariant) {
  @history = ();
  $s->cmd($cmd);
  is_deeply( \@history, [], "$cmd is history invariant");
};
};
