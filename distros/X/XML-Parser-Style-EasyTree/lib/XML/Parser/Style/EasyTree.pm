package XML::Parser::Style::EasyTree;

use strict;
use warnings;
use Scalar::Util ();
no  strict;

=head1 NAME

XML::Parser::Style::EasyTree - Parse xml to simple tree

=head1 VERSION

Version 0.08

=cut



=head1 PLEASE USE ETREE

This module intersects with L<XML::Parser::EasyTree> (I didn't found it before commit because of missing '::Style' in it's name)

But since we are using same style name, we're mutual exclusive ;(

It is leaved as a compatibility wrapper to L<XML::Parser::Style::ETree> (If you use it, all your code will keep working)

L<XML::Parser::Style::ETree> is included in this distribution

But I recommend to use C<ETree> instead

All documentation look in L<XML::Parser::Style::ETree>

=cut

BEGIN{
	for(qw(TEXT FORCE_ARRAY FORCE_HASH)) {
		if (defined *$_{HASH}) {
			#warn "have own $_";
			*{'XML::Parser::Style::ETree::'.$_} = \%$_;
		} else {
			#warn "use foreign $_";
			*$_ = \%{'XML::Parser::Style::ETree::'.$_};
		}
	}
	for(qw(STRIP_KEY)) {
		if (defined *$_{ARRAY}) {
			#warn "have own $_";
			*{'XML::Parser::Style::ETree::'.$_} = \@$_;
		} else {
			#warn "use foreign $_";
			*$_ = \%{'XML::Parser::Style::ETree::'.$_};
		}
	}
	require XML::Parser::Style::ETree;
	$VERSION = $XML::Parser::Style::ETree::VERSION;
	*$_ = \&{'XML::Parser::Style::ETree::'.$_}
		for qw(Init Start End Char Final); 
}

=head1 AUTHOR

Mons Anderson, <mons at cpan.org>

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
