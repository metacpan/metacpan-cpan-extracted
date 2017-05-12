# Copyright (c) 2009 Mons Anderson <mons@cpan.org>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package self::init;

=head1 NAME

self::init - Invoke package init methods at compile time

=cut

$self::init::VERSION = '0.01';

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # At compile time
    use self::init
        \-x => qw( y z ), # same as BEGIN { CLASS->x('y','z'); }
    ;
    
    # At runtime
    self::init
        \-a => qw(a b),
        \-b => (),
        \-c => qw( c c ),
    ;
    
    # Same as
    CLASS->a('a','v');
    CLASS->b();
    CLASS->c('c','c');
    
    # With bad arguments (scalarrefs, containing string, beginning from -)
    self::init
        [ a => \'-arg1', \'-arg2' ],
        [ b => 'arg3', 'arg4' ],
    ;
    
    # ! Warning!
    # Mixed syntax is not allowed
    self::init
        \-a => qw(arg1 arg2),
        [ b => \'-arg1', \'-arg2' ],
    ;

    # will be invoked as

    CLASS->a('arg1','arg2', [ 'b', \'-arg1', \'-arg2' ] );

    # So be aware

=head1 DESCRIPTION

This module is just a helper to avoid repetiotion of ugly __PACKAGE__->method();

=head1 INTERFACE

=over 4

=item self::init pragma

    use self::init ARGS;

=item self::init statement

    self::init ARGS;

=item ARGS

Synopsis 1:

Method name is constructed as a reference to string, containing method name, prefixed with '-'.
Rest in list is threated as arguments to that method, until next method name or end of whole statement.
So, if your arguments not written by hand or in some way could receive value of SCALARREF, containing string, beginning from -, invocation will be wrong (see Synopsis 2)

When writing method names not quoted (hash key bareword), the whole statement looks like an ASCII tree, where methods are descendants of self::init ;)

    self::init
        \-method1 => (1,2,3),
        \-method_another => ('some', 'args'),
        \-_private_method => (), # no args,
        # so on
    ;

Synopsis 2:

Single method invocation is constructed as ARRAYREF, containing first element as method name and rest as arguments.
It is reliable to any arguments, but don't mix both synopsises in a single call

    self::init
        [ method1 => 1,2,3 ],
        [ method_another => 'some', 'args' ],
        [ _private_method => (), ],  # no args
        # so on
    ;

=back

=cut

use strict;
use warnings;
use Carp;

sub _declare($@) {
	my ($class,$method,@args) = @_;
	#if ($class->can($method)) {
		#warn "$class $method (@args)";
		eval{ $class->$method(@args); 1 } or do {
			local $_ = $@;
			my $f = __FILE__;
			s{ at \Q$f\E line \d+.\s*$}{};
			croak $_;
		}
	#} else {
	#    push @DELAYED , [ $class, $method, @args ];
	#}
}

sub self::init (%) {
	@_ or return 'self::init';
	my $class = caller;
	my @opts = @_; # copy
	my ($key, @args);
	while (@opts) {
		my $v = shift @opts;
		if (ref $v and ref $v eq 'ARRAY' and !defined $key) {
			_declare $class, @$v;
		}
		elsif (ref $v eq 'SCALAR' and do { local $_ = $$v; s/^-// and $v = $_ }) {
			_declare $class, $key, @args if defined $key;
			@args = ();
			$key = $v;
		} else {
			push @args, $v;
		}
	}
	_declare $class, $key, @args if defined $key;
	return 'self::init';
}

sub import {
	shift;
	my $class = caller;
	@_ or return;
	goto &self::init;
}

1;
__END__
=head1 AUTHOR

Mons Anderson, <mons@cpan.org>

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
