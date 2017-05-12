package Test::Tail::Multi;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.06';

use File::Tail;
use Test::Builder;
use Carp;

my $Test = Test::Builder->new();
our @monitored;
our $cached_output;
our $tail_delay = 5;

sub import {
  my $self = shift;
  my $caller = caller;

  no strict 'refs';
  *{$caller."::delay"} = \&delay;
  *{$caller."::add_file"} = \&add_file;
  *{$caller."::contents_like"} = \&contents_like;
  *{$caller."::contents_unlike"} = \&contents_unlike;

  my %params;
  {
    no warnings;
    %params = @_;
  }
  if (exists($params{'files'})) {
    my $contents = $params{'files'};
    if (ref($contents) eq 'ARRAY') {
      # list of files provided
      @monitored = map {File::Tail->new(name=>$_)} @$contents;
    }
    elsif (defined $contents and ($contents ne "")) {
      @monitored = File::Tail->new(name=>$contents);
    }
    else {
      croak "You must specify at least one file to monitor";
    }
  }
  delete $params{'files'};

  $Test->plan(%params) if int keys %params;
}

sub delay($;$) {
  my ($delay, $comment) = @_;
  $tail_delay = $delay if defined $delay;
  $Test->diag($comment) if defined $comment;
}
  

sub add_file($;$) {
  my($file, $comment) = @_;
  push @monitored, File::Tail->new($file);
  $Test->diag($comment) if defined $comment; 
}

sub contents_like(&$;$) {
  my ($coderef, $pattern, $comment) = @_;
  _execute($coderef, $pattern, sub { $Test->like(@_) }, $comment);
}

sub contents_unlike(&$;$) {
  my ($coderef, $pattern, $comment) = @_;
  _execute($coderef, $pattern, sub { $Test->unlike(@_) }, $comment);
}

sub _execute {
  my ($coderef, $pattern, $testsub, $comment) = @_;
  if (defined $coderef) {
    # call code and capture output
    $coderef->();
    my ($nfound, $timeleft, @pending);
    $nfound = 1;
    while ($nfound) {
      ($nfound, $timeleft, @pending) =
        File::Tail::select(undef, undef, undef, $tail_delay, @monitored);
      last unless ($nfound);
      foreach (@pending) {
          $cached_output .=  $_->{"input"}." (".localtime(time).") ".$_->read;
      }
    }
  }
  # test vs. last output
  # (fall into here if coderef is not defined)
  $testsub->($cached_output, $pattern, $comment);
}

1;
__END__

=head1 NAME

Test::Tail::Multi - execute code, monitor dynamic file contents

=head1 SYNOPSIS

  use Test::Tail::Multi files => [qw(file1 file2)] tests=>2;
  # Can add files dynamically as well
  add_file('file3', "decided to add file3 too");

  # Execute a command and check against output
  contents_like {system('my_command -my_args")}   # Note no trailing comma!
                qr/expected value/,
		"got the expected output");

  # if code to execute is undef, check against previously captured new content
  contents_unlike undef,                          # trailing command REQUIRED
                  qr/unexpected text/,
		  "unexpected stuff not found in same text");

  # Shorten the delay to 1 second.
  delay(1, "Now a 1 second delay");
  contents_like(sub {system('fast_command')},     # trailing comma in parens
                qr/expected/,
                "this command runs faster");
                 

=head1 DESCRIPTION

C<Test::Tail::Multi> allows you to create tests or test classes that permit
you to monitor the contents of one or more files a la <tail -f> using the
nice C<File::Tail> module. You can execute arbitrary code and then run tests 
versus the new content in the files.

If you choose, you can run multiple tests against the same content by 
passing C<undef> as the code to be executed; C<Test::Tail::Multi> will then
reuse the contents it last extracted.

You can also adjust the delay time to be used to allow the code you called 
to "settle down" before checking the tails.

C<Test::Tail::Multi> comes in handy for those testing jobs that require 
you to monitor several files at once to see what's happening in each one.

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@yahoo-inc.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Joe McMahon and Yahoo!

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
