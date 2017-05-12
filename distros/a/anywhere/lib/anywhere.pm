package anywhere;

# ABSTRACT: Use a module (or feature) everywhere


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
          $INC{$file} = $full;
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

anywhere - Use a module (or feature) everywhere

=head1 VERSION

This document describes version 0.002 of anywhere (from Perl distribution anywhere), released on 2017-02-14.

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use anywhere qw/ feature say /;
  use Greet;

  Greet::hello();

  # in Greet.pm
  package Greet;
  use strict;
  sub hello {
    say "Helloooooo!!!!";
  }

=head1 DESCRIPTION

C<anywhere> is a fork of L<everywhere> 0.07 while waiting my proposed change to
be merged (if ever). It currently only has one difference compared to
C<everywhere>: it sets C<%INC> entry to the file path instead of letting Perl
set it to C<CODE(0x...)> so other modules see the used module more normally and
C<anywhere> can work with things like L<true>.

The rest is from L<everywhere> documentation:

I got tired of putting "use 5.010" at the top of every module. So now I can
throw this in my toplevel program and not have to Repeat Myself elsewhere.

In theory you should be able to pass it whatever you pass to use.

Also, I just made it so you can do:

  use anywhere 'MooseX::Declare',
    matching => '^MyApp',
    use_here => 0;

for example and then it will only apply this module to things matching your
regex. And not use it here. You can also throw in 'package_level => 1' to use
your package after every "package ..." line. All these are experimental :)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/anywhere>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-anywhere>.

=head1 EVERYWHERE'S BUGS

Currently you can only use this once.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=anywhere>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://rt.cpan.org/Public/Bug/Display.html?id=120238>

L<Acme::use::strict::with::pride> -- from which most code came!

Also look at L<use> and L<feature>.

=head1 EVERYWHERE'S AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/
  Thanks to mst and #moose ;-)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 EVERYWHERE'S COPYRIGHT

  Copyright (c) 2008-2011 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl 5.10 or later.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
