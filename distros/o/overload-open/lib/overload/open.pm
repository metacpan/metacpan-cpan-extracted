package overload::open;
use strict;
use warnings;
use 5.009_004;
use feature ':5.10';
use XSLoader;

our $GLOBAL;
require overload::open;
sub before_open {

}
#| overload::open->import(\&before_open);
sub import {
    my ( undef, $callback ) = @_;
    $GLOBAL = $callback;
    return;
}

sub _global {
    1;
}
# not used... probably delete it later
our $init_done;
sub _install_open; # Provided by open.xs

our $VERSION = '0.01';
XSLoader::load( 'overload::open', $VERSION );
_install_open();

q[Open sesame seed.];

__END__

=head1 NAME

overload::open - Hooks the native open function

=head1 SYNOPSIS

  my %opened_files;
  sub my_callback { return if !@_; $opened_files{shift}++ }
  use overload::open 'my_callback';

  open my $fh, '>', "foo.txt";

=head1 DESCRIPTION

This module hooks the native open() function and sends it to your
function instead. It passes the filename opened as its argument. It does this
using XS and replacing the OP_OPEN opcode with a custom one, which calls the
Perl function you supply, then calls the original OP_OPEN opcode.

=head1 AUTHOR

Samantha McVey <samantham@posteo.net>

=head1 LICENSE

This module is available under the same licences as perl, the Artistic license and the GPL.
