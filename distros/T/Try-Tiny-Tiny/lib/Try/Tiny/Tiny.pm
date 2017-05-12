package Try::Tiny::Tiny; use strict; use warnings;
$Try::Tiny::Tiny::VERSION = '0.001';
# ABSTRACT: slim Try::Tiny down as far as reasonably possible

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

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 export PERL5OPT=-MTry::Tiny::Tiny

=head1 DESCRIPTION

The reason this module exists is that L<Try::Tiny> will try naming the blocks
it is passed, if it can load a module for doing so. This takes meaningful time,
is only useful in stack traces, and then may defeat code that tries to examine
the stack to print a more helpful error message.

Now, you yourself can avoid using L<Try::Tiny> in the first place, but you will
almost inevitably still pull it in through your dependency chain, and it is not
likely to be feasible to scrub it out.

This module helps sanitise your dependency chain a bit without patching all of
it by loading L<Try::Tiny> in such a way that it is forced to skip naming its
callbacks. In order to be useful, you must use this module before using any
other module that loads L<Try::Tiny>. In practice that means you probably want
to load it as early as possible, such as through L<PERL5OPT|perlrun/PERL5OPT>.

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
