
require 5;
package strict::ModuleName;     # Pod at end
$VERSION = '0.04';
use strict;
BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }
use vars qw($DIE);
$DIE = 1 unless defined $DIE;

sub import {
  # Make sure that the calling package's name agrees with its filename
  if(@_ > 1) {
    require Carp;
    for my $msg (
     "Proper usage: use " . __PACKAGE__ . "; #(with no parameters) "
    ) { $DIE ? Carp::croak($msg) : Carp::carp($msg) }
  }
  my($package, $filename) = caller(0);

  unless($filename =~ m/.\.pm$/s) {  # catch this first off
    if($filename =~ m/.(\.pm)$/is) {
      for my $msg (
       "filename \"$filename\" should end in \".pm\", not \"$1\"\n"
      ) { return $DIE ? die($msg) : warn($msg) }
    } else {
      for my $msg (
       "filename \"$filename\" should end in \".pm\"!\n"
      ) { return $DIE ? die($msg) : warn($msg) }
    }
  }

  my $pre = quotemeta($package);
  $pre =~ s/(\\[\'\:])+/./g;  # Foo::Bar => Foo.Bar
  
  DEBUG and print ">>>>. $package in $filename\n";

  my $re = join '',
    '^(',
    join('|', map quotemeta($_), 
      sort {length($b) <=> length($a)}
        @INC
    ),
    ')',
    '\W{0,2}',
       # generous RE matching trailing pathsep thing like / or \ or :
    $pre,
    '\.pm$',
  ;

  if(DEBUG) {
    DEBUG and print $re, "\n\n";
    for(0 .. 10) {
      print("\n"), last unless defined caller($_);
      print "caller($_) is ", join(" # ", map $_ || '', (caller($_))[0..7] ), "\n";
    }
  }
  
  if($filename =~ m/$re/s) {
    DEBUG and print "file \"$filename\" producing package \"$package\" is okay\n";
    
  } else {
  
    {
      # Jump thru hoops to check for a very common case:
      #  whether that package was like "perl -cw X.pm" or "perl -w X.pm"
      
      my @callstack;
      my $back_count = 0;
      my $real_depth = 0;
      while(1) {
        last unless defined caller($back_count);
        my $sub_name = (caller($back_count))[3];
        ++$real_depth
         unless $sub_name eq '(eval)' or $sub_name =~ m/\:\:BEGIN$/s;
        ++$back_count;
      }
      my $fn = $filename;
      $fn =~ s/\.pm$//s or die "WHAAAAAT?";
      
      if($real_depth == 1
        and length($fn) <= length($package)
        and substr($package, 0 - length($fn)) eq $fn
      ) {
        warn(   # yes, merely warn
         "Can't verify whether package name \"$package\" is good in \"$filename\""
         . "\n -- Instead try:  perl -M$package -e -1\n"
        );
        return;
      }
    }
    
    if(grep ref($_), @INC) {
      warn(
       "file \"$filename\" producing package \"$package\" may be bad,\n"
       . "  -- but I can't be sure, because there's coderefs in \@INC\n");
      return;
    }
      
    for my $msg (
     "file \"$filename\" producing package \"$package\" is bad\n"
    ) { return $DIE ? die($msg) : warn($msg) }
  }
  
  return;
}

&import(); # Yes, test myself!

1;

__END__

=head1 NAME

strict::ModuleName -- verify that current package name matches filename

=head1 SYNOPSIS

    # In a file (some @INC dir)/Shazbot.pm:
    package Shazbot;
    use strict::ModuleName;
     # does nothing, because Shazbot.pm matches package name "Shazbot"

That does nothing, because the package name "Shazbot" is exactly
what you'd expect from "Shazbot.pm" in an @INC directory.

But any of these will throw a fatal error:

    # In a file (some @INC dir)/Shazbot.pm:
    package ShazBot;
    use strict::ModuleName;
     # that's a fatal error, because Shazbot isn't ShazBot
 
    # In a file (some @INC dir)/Shazbot.pm:
    package Shaz::Bot;
    use strict::ModuleName;
     # that's a fatal error, because Shazbot isn't Shaz::Bot
 
    # In a file (not any @INC dir)/Shazbot.pm:
    package Shazbot;
    use strict::ModuleName;
     # That's a fatal error, because ShazBot wasn't findable
     #  via any @INC dir.

=head1 DESCRIPTION

This module stops you from having your module's filename and package
name disagree, such as might happen as you're changing the name as
you're developing the module; or such as might happen if you are using a
case insensitive filesystem, and get the case wrong in the filename.

A line saying C<use strict::ModuleName;> in a module is basically an
compile-time assertion that the current package name is compatible with
the filename which the current source is being read from.

=head1 NOTES

Maybe this module should just warn() more instead of die()ing?

=head1 COPYRIGHT

Copyright (c) 2002,2003 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The programs and documentation in this dist are distributed in the hope
that they will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut


