package Unicode::RecursiveDowngrade;

use strict;
use Carp;
use bytes;
use vars qw($DowngradeFunc $VERSION);
$VERSION = 0.04;

BEGIN {
    $DowngradeFunc = sub { return defined $_[0] ? pack('C0A*', shift) : undef };
}

sub new { return bless {}, shift }

sub filter {
    my($self, $sub) = @_;
    if (defined $sub) {
	if (ref($sub) ne 'CODE') {
	    carp "Argument of filter() method must be a code-ref";
	    $self->{filter} = sub { shift };
	}
	else {
	    $self->{filter} = $sub;
	}
    }
    return $self->{filter};
}

sub downgrade {
    my($self, $var, $ref) = @_;
    $ref ||= ref($var);
    if ($ref eq 'ARRAY') {
	@$var = map { $self->downgrade($_) } @$var;
    }
    elsif ($ref eq 'HASH') {
	%$var =
	    map { $self->downgrade($_) => $self->downgrade($var->{$_}) }
		keys %$var;
    }
    elsif ($ref eq 'SCALAR') {
	$$var = $self->downgrade($$var);
    }
    elsif ($ref eq 'GLOB') {
	*var = $self->downgrade(*var);
    }
    elsif ($ref ne '' && $ref ne 'CODE') { # maybe blessed reference
	my $blessed_class = $ref;
	require overload;
	my($blessed_ref) =
	    overload::StrVal($var) =~ /^$blessed_class\=(.+?)\(0x[\da-f]+\)$/i;
	if (length $blessed_ref) {
	    $var = bless $self->downgrade($var, $blessed_ref), $blessed_class;
	}
    }
    elsif ($ref eq '') {
	my $filter = $self->filter || sub { shift };
	$var = $filter->($DowngradeFunc->($var));
    }
    return $var;
}

1;

=head1 NAME

Unicode::RecursiveDowngrade - Turn off the UTF-8 flags inside of complex variable

=head1 SYNOPSIS

 use Unicode::RecursiveDowngrade;
 
 $rd = Unicode::RecursiveDowngrade->new;
 $var = {
     foo   => 'bar',
     baz   => [
         'qux',
         'quux',
     ],
     corge => \$grault,
 };
 $unflagged = $rd->downgrade($var);

=head1 DESCRIPTION

Unicode::RecursiveDowngrade will turn off the UTF-8 flag inside of
complex variable in a lump.
In spite of your intention, some modules turn it on every elements of
returned variable.
You may be hard up for turn them off if you don't need any UTF-8 flags
in your variable.
This module will fix it up easily.

Sometime I think about the UTF-8 flag is not stead.
But some C<XML::Parser> based modules will turn it on.
For example, C<XML::Simple> is really simple way to parse XMLs, but
this module returns a simple hashref including flagged values.
This hashref is very hard to use, isn't it?

=head1 METHODS

=over 4

=item * new

C<new()> is a constructor method.

=item * filter

You can set some filter to C<filter()> accessor. The values of downgraded
will be passed this filter function.
You have to set a code reference to this accessor.
Like this:

 use Unicode::RecursiveDowngrade;
 use Unicode::Japanese;
 
 $rd = Unicode::RecursiveDowngrade->new;
 $rd->filter(sub { Unicode::Japanese->new(shift, 'utf8')->euc });
 $unflagged = $rd->downgrade($var);

the passed subref will be called inside C<downgrade()> method.

=item * downgrade

C<downgrade()> returns a turned off variable of argument.

=back

=head1 VARIABLES

=over 4

=item * $Unicode::RecursiveDowngrade::DowngradeFunc

This variable has a downgrade function for C<downgrade()> method.
You can override the variable for some other way.

=back

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Koichi Taniguchi. Japan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<utf8>

=cut
