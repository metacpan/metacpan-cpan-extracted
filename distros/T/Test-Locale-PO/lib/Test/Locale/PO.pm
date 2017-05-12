package Test::Locale::PO;
# ABSTRACT: check PO files for empty/fuzzy translations

use strict;
use warnings;
our $VERSION = '1.02'; # VERSION

use base 'Test::Builder::Module';

our @EXPORT = qw( po_file_ok );

use Locale::PO;

my $CLASS = __PACKAGE__;

sub po_file_ok {
	my $file = shift;
	my $opts = { empty => 1, fuzzy => 1, @_ };
	my $tb = $CLASS->builder;

	if( ! -f $file ) {
		$tb->ok(0, $file.' does not exist!');
		return;
	}
	
	my $content;
	eval {
		$content = Locale::PO->load_file_asarray( $file );
	};
	if( $@ ) {
	       $tb->ok(0, 'could not load PO file!');
	       return;
	}
	if( scalar(@$content) == 0 ) {
	       $tb->ok(0, 'PO file has no entries!');
	       return;
       }

	my @no_msgstr;
	my @fuzzy;
	foreach my $po ( @$content ) {
		if( $opts->{'empty'} ) {
			# check for a simple translation
			if ( defined $po->msgstr && $po->msgstr !~ m/^["\- ]*$/ ) {
			}
			# check if plurals are involved
			elsif( defined $po->msgid_plural
					&& defined $po->msgstr_n->{"0"}
					&& $po->msgstr_n->{"0"} !~ m/^["\- ]*$/ ) {
			} else {
				push( @no_msgstr, $po );
			}
		}
		if( $opts->{'fuzzy'} && $po->has_flag('fuzzy') ) {
			push( @fuzzy, $po );
		}
	}

	if( scalar(@no_msgstr) != 0 || scalar(@fuzzy) != 0 ) {
		$tb->ok(0, 'check PO file '.$file.' for errors');
		foreach my $po ( @no_msgstr ) {
			$tb->diag('no translation for '.$po->msgid.' on line '.$po->loaded_line_number);
		}
		foreach my $po ( @fuzzy ) {
			$tb->diag('fuzzy translation for '.$po->msgid.' on line '.$po->loaded_line_number);
		}
		return;
	}

	$tb->ok(1, 'PO file '.$file.' is okay');
	return;
}

1;

__END__

=pod

=head1 NAME

Test::Locale::PO - check PO files for empty/fuzzy translations

=head1 SYNOPSIS

  use Test::More tests => 3;
  use Test::Locale::PO;

  po_file_ok('po/de.po');              # default is empty => 1, fuzzy => 1
  po_file_ok('po/fr.po', empty => 0);  # dont check for empty strings
  po_file_ok('po/it.po', fuzzy => 0);  # dont check for fuzzy flagged strings

=head1 DESCRIPTION

Test::Locale::PO will parse the specified PO file with Locale::PO and check it for empty
or fuzzy-flagged translations.

=head2 po_file_ok( $file, %options )

Will run the check against the specified file.

=head3 options

=over

=item empty (default 1)

check for empty translations.

=item fuzzy (default 1)

check for translations flagged as fuzzy.

=back

=head1 DEPENDENCIES

Test::Builder, Locale::PO

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Markus Benning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

