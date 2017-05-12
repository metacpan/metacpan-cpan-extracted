#!/usr/bin/perl -w

# my_mangle_examples.pl -- check EXE_FILES use #!perl for interpreter

# Copyright 2011 Kevin Ryde

# my_mangle_examples.pl is shared by several distributions.
#
# my_mangle_examples.pl is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# my_mangle_examples.pl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use File::Find;

# uncomment this to run the ### lines
#use Smart::Comments;

my $dir = $ARGV[0] || die "Usage: ./my_mangle_examples DIRECTORY";

-d "debian/$dir" or die "No such directory debian/$dir";
find({ wanted => sub {
         ### find: $_
         if (/\.pm$/ && ! -d) {
           mangle_file($_);
         }
       },
       no_chdir => 1 },
     "debian/$dir");

sub mangle_file {
  my ($filename) = @_;
  ### mangle_file(): $filename
  open FH, '<', $filename or die "Cannot open $filename: $!";
  my $content = do { local $/=undef; <FH> };
  my $count = ($content =~ s{F<(examples/[^>]*)>( in the .* sources)?}
                            {
                              my $example = $1;
                              "F</usr/share/doc/$dir/$example"
                                . (is_compressed($example) ? ".gz" : "")
                                  . ">"
                                }e);
  close FH or die "Error closing $filename: $!";

  if ($count) {
    print "my_mangle_examples.pl: $count changes in $filename\n";

    open FH, '>', $filename or die "Cannot write $filename: $!";
    print FH $content  or die "Cannot write $filename: $!";
    close FH or die "Error closing $filename: $!";
  }
}

sub is_compressed {
  my ($example) = @_;
  my $fullname = "debian/$dir/usr/share/doc/$dir/$example";
  if (-e $fullname) {
    return (-s $fullname >= 4096);
  }
  if (-e "$fullname.gz") {
    return 1;
  }
  die "Oops, no such file $fullname or .gz";
}

exit 0;
