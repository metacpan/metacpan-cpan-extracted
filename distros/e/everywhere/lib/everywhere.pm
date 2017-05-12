package everywhere;

=head1 NAME

everywhere - Use a module (or feature) everywhere

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use everywhere qw/ feature say /;
  use Greet;

  Greet::hello();

  # in Greet.pm
  package Greet;
  use strict;
  sub hello {
    say "Helloooooo!!!!";
  }

=head1 DESCRIPTION

I got tired of putting "use 5.010" at the top of every module. So now I can
throw this in my toplevel program and not have to Repeat Myself elsewhere.

In theory you should be able to pass it whatever you pass to use.

Also, I just made it so you can do:

  use everywhere 'MooseX::Declare',
    matching => '^MyApp',
    use_here => 0;

for example and then it will only apply this module to things matching your
regex. And not use it here. You can also throw in 'package_level => 1' to use
your package after every "package ..." line. All these are experimental :)

=cut

use strict;
use warnings;

our $VERSION = '0.07';

sub import {
  my ($class, $module, @items) = @_;
  my $use_line = "use $module";
  # TODO do this parameter parsing better :)
  my $matching = qr/.*/;
  if(defined $items[0] && $items[0] eq 'matching') {
    $matching = $items[1];
    shift @items; shift @items;
  }
  my $use_here = 1;
  if(defined $items[0] && $items[0] eq 'use_here') {
    $use_here = eval $items[1];
    shift @items; shift @items;
  }
  my $file_level = 1;
  if(defined $items[0] && $items[0] eq 'package_level') {
    $file_level = ! eval $items[1];
    shift @items; shift @items;
  }
  $use_line .= " qw/" . join(' ', @items) . "/" if @items;
  $use_line .= ";\n";
  eval $use_line if $use_here;
  unshift @INC, sub {
    my ($self, $file) = @_;
    if($file =~ $matching) {
      foreach my $dir (@INC) {
        next if ref $dir;
        my $full = "$dir/$file";
        if(open my $fh, "<", $full) {
          my @lines = ($file_level ? ($use_line) : (),
            qq{#line 1 "$dir/$file"\n});
          return ($fh, sub {
            if(@lines) {
              push @lines, $_;
              $_ = shift @lines;
              $_.= $use_line if (!$file_level) && /^\s*package\s+.+\s*;\s*$/;
              return length $_;
            }
            return 0;
          });
        }
      }
    } else {
      return undef;
    }
  };
  return;
}

=head1 BUGS

Currently you can only use this once.

=head1 SEE ALSO

L<Acme::use::strict::with::pride> -- from which most code came!

Also look at L<use> and L<feature>.

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/
  Thanks to mst and #moose ;-)

=head1 COPYRIGHT

  Copyright (c) 2008-2011 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl 5.10 or later.

=cut

1;

