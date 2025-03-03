package Text::TransMetaphone::ru;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.08';

	$LocaleRange = qr/\p{InCyrillic}/;

}


sub trans_metaphone
{

	#
	# since I know nothing about russian orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[АЕЁИОУЫЭЯ]/a/i;
	s/[АЕЁИОУЫЭЯ]//ig;

	s/Б/b/ig;
	s/Д/d/ig;
	s/д/d/g;   # /i isn't working above
	s/Ю/j/ig;
	s/Г/g/ig;
	s/Ф/f/ig;
	s/К/k/ig;
	s/Л/l/ig;
	s/М/m/ig;
	s/Н/n/ig;
	s/П/p/ig;
	s/Р/r/ig;
	s/C/s/ig;
	s/Ш/ʃ/ig;
	s/T/t/ig;
	s/([TД])?Ч/ʧ/ig;
	s/([TД])?Ц/ʦ/ig;
	s/В/v/ig;
	s/З/z/ig;
	s/Ж/ʒ/ig;

	s/ЗДН/zn/ig;
	s/РДц/pʦ/ig;
	s/ЛНЦ/nʦ/ig;
	s/СТН/sn/ig;
	s/ВСТВ/stv/ig;
	s/Щ|([жЗС]Ч)/ʃʧ/ig;
	s/ЧТ/ʃt/ig;
	s/ЧН/ʃn/ig;
	s/ТЬ?СЯ/ʦʦ/ig;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{
	$_ = $_[0];

	s/a/[АЕЁИОУЫЭЮЯ]/i;

	s/zn/ЗДН/g;
	s/pʦ/РДц/g;
	s/nʦ/ЛНЦ/g;
	s/sn/СТН/g;
	s/stv/ВСТВ/g;
	s/ʃt/ЧТ/g;
	s/ʃn/ЧН/g;
	s/ʦʦ/ТЬСЯ/g;

	s/ʃʧ/Щ|([жЗС]Ч)/g;
	s/ʧ/([TД])?Ч/g;
	s/ʦ/([TД])?Ц/g;

	s/b/Б/g;
	s/d/Д/g;
	s/g/Г/g;
	s/f/Ф/g;
	s/k/К/g;
	s/l/Л/g;
	s/m/М/g;
	s/n/Н/g;
	s/p/П/g;
	s/r/Р/g;
	s/s/C/g;
	s/ʃ/Ш/g;
	s/t/T/g;
	s/v/В/g;
	s/z/З/g;
	s/ʒ/Ж/g;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__


=encoding utf8


=head1 NAME

Text::TransMetaphone::ru – Transcribe Russian words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::ru module implements the TransMetaphone algorithm
for Russian.  The module provides a C<trans_metaphone> function that accepts
a Russian word as an argument and returns a list of keys transcribed into
IPA symbols under Russian orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Russian orthography.

=head1 STATUS

The Russian module has limited awareness of Russian orthography, no alternative
keys are generated at this time.   The module will be updated as more rules
of Russian orthography are learnt.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 BUGS

The /i substitution switch isn't working for Cyrillic in some cases.
Fixes will be provided in a future release.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::TransMetaphone>

=cut
