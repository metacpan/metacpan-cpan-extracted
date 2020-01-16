package overload::open;
use strict;
use warnings;
use 5.009_004;
use feature ':5.10';
use XSLoader;
our $VERSION = '1.8.0';
our $GLOBAL_OPEN;
our $GLOBAL_SYSOPEN;
our $SUPPRESS_WARNINGS;
require overload::open;

sub prehook_open {
    my ( undef, $callback ) = @_;
    $GLOBAL_OPEN = $callback;
}

sub prehook_sysopen {
    my ( undef, $callback ) = @_;
    $GLOBAL_SYSOPEN = $callback;
}
sub suppress_warnings {
    my ( undef, $value ) = @_;
    $SUPPRESS_WARNINGS = $value;
}
sub _install_open;    # Provided by open.xs
sub _install_sysopen; # Provided by open.xs

XSLoader::load( 'overload::open', $VERSION );
_install_open();
_install_sysopen();

q[Open sesame seed.];

__END__

=head1 NAME

overload::open - Hooks the native open function

=head1 SYNOPSIS

  use overload::open;
  my %opened_files;
  sub my_callback { return if @_ != 2 && @_ != 3; $opened_files{$_[-1]}++ }
  overload::open->prehook_open(\&my_callback);
  open my $fh, '>', "foo.txt";

=head1 DESCRIPTION

This module hooks the native C<open()> and/or C<sysopen()> functions and passes
the arguments first to callback you provide. It then calls the native open/sysopen.

It does this using the XS API and replacing the OP_OPEN/OP_SYSOPEN opcode's
with an XS function. This function will call your provided sub, then once that
returns it will run the original OP.

=head1 FEATURES

This function will work fine if you call C<open> or C<sysopen> inside the
callback due to it detecting recursive calls and not calling the callback for
recursive calls.

You are not allowed to pass XS subs as the callback because then this could
result in a recursive loop. If you need to do this, wrap the XS function in a
native Perl function.

=head1 METHODS

=over

=item prehook_open

  use overload::open
  overload::open->prehook_open(\&my_sub)

Runs a hook before C<open> by hooking C<OP_OPEN>. The provided sub reference
will be passed the same arguments as open.

=item prehook_sysopen

  use overload::open;
  overload::open->prehook_sysopen(\&my_sub)

Runs a hook before C<sysopen> by hooking C<OP_SYSOPEN>. Passes the same arguments
to the provided sub reference as provided to sysopen.

=item suppress_warnings

  overload::open->suppress_warnings(1)

Suppress runtime warnings

=back

=head1 AUTHOR

Samantha McVey <samantham@posteo.net>

=head1 LICENSE

This module is available under the same licences as perl, the Artistic license and the GPL.
