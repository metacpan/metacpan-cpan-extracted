package Variable::Lazy;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.03';
use Variable::Lazy::Guts;

use Devel::Declare;
use B::Hooks::EndOfScope;
use Carp qw/croak/;
use namespace::clean;
our @CARP_NOT = qw/Devel::Declare/;

sub import {
	my $package = caller;

	Devel::Declare->setup_for($package, { lazy => { const => \&_parser } });

	{
		no strict 'refs';
		*{ $package . '::lazy' } = \&Variable::Lazy::Guts::lazy;
	}
	return;
}

sub _parser {
	my ($declarator, $offset) = @_;
	my $linestr = Devel::Declare::get_linestr;
	$offset += Devel::Declare::toke_move_past_token($offset);
	$offset += Devel::Declare::toke_skipspace($offset);

	if (substr($linestr, $offset, 1) eq '{') {
		substr $linestr, $offset, 1, q/(Variable::Lazy::_variable(), \\@_, sub { BEGIN { Variable::Lazy::_inject_scope(')') }; /;
	}
	else {
		if (my $length = Devel::Declare::toke_scan_word($offset, 0)) {
			my $word = substr $linestr, $offset, $length;
			croak "Invalid word '$word' in lazy expression" unless $word eq 'my' or $word eq 'our';
			$offset += $length;
			$offset += Devel::Declare::toke_skipspace($offset);
		}

		croak 'Variable expected' if substr($linestr, $offset, 1) ne '$';
		$offset += Devel::Declare::toke_scan_ident($offset) || croak 'Variable name expected';

		$offset += Devel::Declare::toke_skipspace($offset);

		croak 'Assignment expected' if substr($linestr, $offset, 1) ne '=';
		substr $linestr, $offset++, 1, ',';

		$offset += Devel::Declare::toke_skipspace($offset);

		croak 'Opening bracket expected' if substr($linestr, $offset, 1) ne '{';
		substr $linestr, $offset, 1, q/\\@_, sub { /;
	}
	Devel::Declare::set_linestr($linestr);
	return;
}

sub _variable {
	return my $foo;
}

sub _inject_scope {
	my $terminator = shift;
	on_scope_end {
		my $linestr = Devel::Declare::get_linestr;
		my $offset  = Devel::Declare::get_linestr_offset;
		substr $linestr, $offset, 0, $terminator;
		Devel::Declare::set_linestr($linestr);
	};
	return;
}

1;    # End of Variable::Lazy

__END__

=head1 NAME

Variable::Lazy - Lazy variables

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 lazy my $var = { foo() }

=head1 DESCRIPTION

This module implements lazy variables. It's different from other similar modules in that it works B<completely> transparant: there is no way to see from the outside that the variable was lazy, and there is no speed penalty once the variable has been evaluated.

=head1 CAVEATS

The reification is triggered more easily than most other laziness modules. Unlike other modules it doesn't use referential semantics, so assigning the value to an other variable triggers it. This is something to keep into account.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

This is an early release, bugs are to be expected at this stage.

Please report any bugs or feature requests to C<bug-variable-lazy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Lazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::Lazy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Variable-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Variable-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Variable-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Variable-Lazy>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
