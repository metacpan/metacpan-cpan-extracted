package Test::iMETAr;

=head1 NAME

Test::iMETAr - shortcut for Test::Install::METArequires

=head1 SYNOPSIS

	prove -Ilib `perl -MTest::iMETAr -le 'print Test::iMETAr->t_file'` t/

=head1 DESCRIPTION

See L<Test::Install::METArequires>.

=cut

use warnings;
use strict;

use base 'Test::Install::METArequires';

our $VERSION = '0.03';

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
