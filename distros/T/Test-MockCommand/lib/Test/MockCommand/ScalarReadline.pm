package Test::MockCommand::ScalarReadline;
use strict;
use warnings;
use Carp qw(croak);

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(scalar_readline);

sub scalar_readline {
    croak "scalar context but no second parameter" unless wantarray() || @_ > 1;

    # return empty array or undef if there's no data
    if ((!defined $_[0]) || $_[0] eq '') {
	return () if wantarray();
	$_[1] = 0;
	return undef;
    }

    # slurp mode: $/ = undef
    if (not defined $/) {
	return ($_[0]) if wantarray();
	$_[1] = length $_[0];
	return $_[0];
    }

    # record mode: $/ = \$record_size
    if (ref $/ eq 'SCALAR' && ${$/} > 0) {
	# scalar wanted: return the first record
	if (! wantarray()) {
	    my $out = substr($_[0], 0, ${$/});
	    $_[1] = length $out;
	    return $out;
	}

	# list wanted: return all records
	my ($offset, $length, @out) = (0, length $_[0]);
	while ($offset < $length) {
	    push @out, substr($_[0], $offset, ${$/});
	    $offset += ${$/};
	}
	return @out;
    }

    # paragraph mode: $/ = ''
    my $rs = $/;
    my $paras = 0;
    if ($rs eq '') {
	$rs = "\n\n";
	$paras = 1;
    }

    # regular or paragraph mode: scalar wanted
    if (! wantarray()) {
	my $found = index $_[0], $rs;
	if ($found < 0) {
	    $_[1] = length $_[0];
	    return $_[0];
	}
	else {
	    $_[1] = $found + length $rs;
	    if ($paras) { while (substr($_[0], $_[1], 1) eq "\n") { $_[1]++; } }
	    return substr($_[0], 0, $found + length $rs);
	}
    }

    # regular or paragraph mode: list wanted
    my @out;
    my $pos = 0;
    while ((my $found = index $_[0], $rs, $pos) >= 0) {
	my $next = $found + length $rs;
	push @out, substr($_[0], $pos, $next - $pos);
	if ($paras) { while (substr($_[0], $next, 1) eq "\n") { $next++; } }
	$pos = $next;
    }
    push @out, substr($_[0], $pos) if $pos < length $_[0];

    return @out;
}

1;
__END__

=head1 NAME

Test::MockCommand::ScalarReadline - reads scalars using $/ behaviour

=head1 SYNOPSIS

 use Test::MockCommand::ScalarReadline qw(scalar_readline);

 my $s = "Hello\nWorld\n";

 $/ = "\n";  my @x = scalar_readline($s); # returns ("Hello\n", "World\n");
 $/ = "xyz"; my @x = scalar_readline($s); # returns ("Hello\nWorld\n");
 $/ = "or";  my @x = scalar_readline($s); # returns ("Hello\nWor", "ld\n");

 my $record_size = 3; $/ = \$record_size;
 my @x = scalar_readline($string); # returns ("Hel", "lo\n", "Wor", "ld\n");

 # can also be used in scalar context to get one line at a time
 my ($line, $chars_to_cut);
 while (defined ($line = scalar_readline($s, $chars_to_cut))) {
     # ...
     $s = substr($s, $chars_to_cut);
 }

=head1 DESCRIPTION

This module provides the C<scalar_readline> function, which breaks a
scalar into a list the same way that C<readline> breaks an input
stream up into lines, depending on the current value of C<$/>.

=head1 FUNCTIONS

=over

=item @all_lines = scalar_readline($string)

=item $line = scalar_readline($string, $chars_to_cut)

In list context, returns a list containing C<$string> broken apart
into lines according to the current value of C<$/>.

In a scalar context, returns the first line from C<$string>, In order
to get the next line, you have to provide a second parameter, which
must be a scalar variable. The number of bytes to cut from the start
of your data will be written back into this variable.

In order to fully emulate readline(), when C<$/> is set to C<undef>
(slurp mode), you must return C<""> the first time a string is empty
and C<undef> thereafter. This function does not do that.

=back

=head1 SEE ALSO

L<perlvar>, L<perlfunc/readline>

=cut
