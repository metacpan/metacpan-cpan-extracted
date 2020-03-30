package new;

our $VERSION = '0.000001'; # 0.0.1

$VERSION = eval $VERSION;

use strict;
use warnings;

sub import {
  my ($me, $class, @args) = @_;
  return unless $class;
  my $targ = caller;
  require join('/', split '::', $class).'.pm';
  my ($name) = @args && $args[0] =~ /^\$/ ? map /^\$(.*)/, shift @args : 'O';
  my $obj = $class->new(@args);
  no strict 'refs';
  ${"${targ}::${name}"} = $obj;
}

1;

=head1 NAME

new - Object instantiation sugar for one-liners

=head1 SYNOPSIS

Simplest possible usage:

  perl -Mnew=HTTP::Tiny -E \
    'say $O->get("http://trout.me.uk/X11/vimrc")->{content}'

With arguments:

  perl -Mnew=HTTP::Tiny,max_redirects,3 -E \
    'say $O->get("http://trout.me.uk/X11/vimrc")->{content}'

With custom object name:

  perl -Mnew=HTTP::Tiny,\$H -E \
    'say $H->get("http://trout.me.uk/X11/vimrc")->{content}'

With both:

  perl -Mnew=HTTP::Tiny,\$H,max_redirects,3 -E \
    'say $H->get("http://trout.me.uk/X11/vimrc")->{content}'

=head1 DESCRIPTION

=head2 import

  new->import($class, @args)

First we C<require> the file for C<$class>, then call

  $class->new(@args)

then install the resulting object in C<$O> in the calling package.

If the first argument to C<import> after C<$class> begins with C<$>, this
is treated as the name to install the object as, so

  new->import($class, '$Obj', @args);

will create a variable C<$Obj> in the calling package instead of C<$O>.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the new L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
