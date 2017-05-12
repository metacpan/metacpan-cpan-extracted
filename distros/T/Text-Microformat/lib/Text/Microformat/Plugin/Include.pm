package Text::Microformat::Plugin::Include;
use strict;
use warnings;

sub post_parse {
    my $c = shift;
	my @includes = $c->tree->look_down(
		_tag => $c->tag_regex('object'),
		class => $c->class_regex('include'),
	);
	foreach my $source (@includes) {
		my $id = $source->attr('data');
		if (defined $id and length $id > 1 and $id =~ s/^#//) {
			my ($target) = $c->tree->look_down(id => $id);
			if ($target) {
				$source->replace_with($target->clone)->delete;
			}
		}
	}
    return $c->NEXT::post_parse(@_);
}

=head1 NAME

Text::Microformat::Plugin::Include - a plugin providing the Microformat include pattern

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org/wiki/include-pattern>

=head1 NAME

Text::Microformat::Plugin::Parser::HTML - HTML parser plugin for Text::Microformat

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 BUGS

Log bugs and feature requests here: L<http://code.google.com/p/ufperl/issues/list>

=head1 SUPPORT

Project homepage: L<http://code.google.com/p/ufperl/>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;