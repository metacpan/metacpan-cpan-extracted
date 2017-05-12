# -----------------------------------------------------------------------------
# Tripletail::Validator::FilterFactory - Filterインスタンスの生成
# -----------------------------------------------------------------------------
package Tripletail::Validator::FilterFactory;
use strict;
use warnings;

use Tripletail;

use Tripletail::Validator::Filter;

my $filterCache = {};
my $userFilters = do {
	my $userFilters = {};

	my $ini     = $TL->INI();
	my @filters = $ini->getKeys('Validator');

	foreach my $filter (@filters) {
		eval 'use ' . $ini->get( Validator => $filter );
		if ( !$@
			&& $ini->get( Validator => $filter )
			->isa('Tripletail::Validator::Filter') )
		{
			$userFilters->{$filter} = $ini->get( Validator => $filter );
		}
	}

	$userFilters;
};

1;

#---------------------------------- 一般
sub getFilter {
	my $filter = shift;

	if ( !defined( $filterCache->{$filter} ) ) {
		eval qq{\$filterCache->{$filter} = new Tripletail::Validator::Filter::$filter};
		if ($@) {
			if ( defined( $userFilters->{$filter} ) ) {
				eval qq{\$filterCache->{$filter} = new $userFilters->{$filter}};
			}
			if ($@) {
				die qq{Filter [$filter] not found.};
			}
		}
	}
	return $filterCache->{$filter};
}

__END__

=encoding utf-8

=for stopwords
	YMIRLINK
	getFilter

=head1 NAME

Tripletail::Validator::FilterFactory - Tripletail::Validator 内部クラス

=head1 DESCRIPTION

L<Tripletail::Validator> 参照

=head2 METHODS

=over 4

=item getFilter

L<Tripletail::Validator> 参照

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
