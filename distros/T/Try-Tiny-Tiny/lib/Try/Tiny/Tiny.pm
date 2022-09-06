use strict; use warnings;

package Try::Tiny::Tiny;
our $VERSION = '0.005';

my $effective;

BEGIN {
	if ( not exists $INC{'Try/Tiny.pm'} ) {
		my @hide = qw( Sub/Name.pm Sub/Util.pm );
		local  @INC{ @hide };
		delete @INC{ @hide };
		local @INC = ( sub { die if 'Try::Tiny' eq caller and grep $_ eq $_[1], @hide }, @INC );
		require Try::Tiny;
	}
	my $cb = sub { (caller 0)[3] };
	my $name = &$cb;
	$effective = $name eq &Try::Tiny::try($cb);
	warn __PACKAGE__ . " is ineffective (probably loaded too late)\n" unless $effective;
}

$effective;

__END__

=pod

=encoding UTF-8

=head1 NAME

Try::Tiny::Tiny - slim Try::Tiny down as far as reasonably possible

=head1 SYNOPSIS

 export PERL5OPT=-MTry::Tiny::Tiny

=head1 DESCRIPTION

This module slims down L<Try::Tiny> as much as possible,
currently by preventing L<Try::Tiny> from giving somewhat more human-friendly
names to the code references it is passed.

This is done by blocking L<Try::Tiny> from finding any of the utility modules
it needs for this feature.
As a result, you must use this module before using any other module that loads
L<Try::Tiny>.
In practice that means you probably want to load it as early as possible, such
as through L<PERL5OPT|perlrun/PERL5OPT>.

=head1 RATIONALE

=head2 Overall

L<Try::Tiny> is very heavy compared to raw L<C<eval>|perlfunc/eval>.
It is also used all across the CPAN.
You yourself could avoid using it in your own code (and if you write CPAN
modules, please do), but your applications will almost invariably wind up
loading it anyway due to its pervasive use.
It is not likely to be feasible to completely avoid depending on it, nor to
send patches to remove it from every one of your dependencies (and then get
all of the patches accepted).

With this module, you can at least sanitise your dependency chain a little,
without patching anything.

=head2 Current effect

There are several reasons to not want L<Try::Tiny> to name the coderefs it is passed:
it takes meaningful time on every invocation,
and it requires modules that may otherwise not have been loaded,
yet it is useful only in stack traces,
and then only to a human looking at the stack trace directly,
whereas other code may be impeded in examining the stack
(e.g. to print more helpful error messages in certain scenarios).

=head1 DIAGNOSTICS

This module will fail to load if you load it too late to take effect.

=head1 SEE ALSO

L<Try::Catch> E<ndash> a stripped-down clone of L<Try::Tiny>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
