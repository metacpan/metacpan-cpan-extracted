package Xacobeo::I18n;

=head1 NAME

Xacobeo::I18n - Utilities for internationalization (i18n).

=head1 SYNOPSIS

	# Initialize the i18n framework (done once)
	use FindBin;
	use Xacobeo::I18n;
	Xacobeo::I18n->init("$FindBin::Bin/../share/locale/");
	
	
	# Import the i18n utilities (used everywhere where i18n is needed)
	use Xacobeo::I18n;
	print __("Hello world"), "\n";

=head1 DESCRIPTION

This package provides utilities that perform i18n. This module relies on
gettext.

The initialization of the i18n framework should be performed only once,
preferably as soon as possible. Once the framework is initialized any module
requiring to translate a string can include this module.

This module exports automatically the shortcut functions used for translating
messages. This is done in order to make the translation transparent.

=head1 FUNCTIONS

The following functions are available:

=cut

use strict;
use warnings;

use XML::LibXML;
use Locale::Messages qw(dgettext dngettext textdomain bindtextdomain);
use Encode qw(decode);

use Exporter 'import';
our @EXPORT = qw(
	__
	__x
	__n
	__nx
	__xn
);


# The text domain of the application.
my $DOMAIN = 'xacobeo';



=head2 __

Translates a single string through gettext.

Parameters:

=over

=item * $string

The string to translate.

=back

=cut

sub __ {
	my ($msgid) = @_;
	return dgettext_utf8($msgid);
}



=head2 __x

Translates a string that uses place holders for variable substitution.

Parameters:

=over

=item * $string

The string to translate.

=item * %values

A series of key/value pairs that will be replacing the place holders.

=back

=cut

sub __x {
	my ($msgid, %args) = @_;
	my $i18n = dgettext_utf8($msgid);
	return expand($i18n, %args);
}



=head2 __n

Translates a string in either singular or plural.

Parameters:

=over

=item * $singular

The string in its singular form (one item).

=item * $plural

The string in its plural form (more than one item).

=item * $count

The number of items.

=item * %values

A series of key/value pairs that will be replacing the place holders.


=back

=cut

sub __n {
	my ($msgid, $msgid_plural, $count) = @_;
	my $i18n = dngettext_utf8($msgid, $msgid_plural, $count);
	return $i18n;
}



=head2 __nx

Translates a string in either singular or plural with variable substitution.

Parameters:

=over

=item * $singular

The string in its singular form (one item).

=item * $plural

The string in its plural form (more than one item).

=item * $count

The number of items.

=back


=cut

sub __nx {
	my ($msgid, $msgid_plural, $count, %args) = @_;
	my $i18n = dngettext_utf8($msgid, $msgid_plural, $count);
	return expand($i18n);
}



=head2 __xn

Same as L</__nx>.

Parameters:

=over

=item * $singular

The string in its singular form (one item).

=item * $plural

The string in its plural form (more than one item).

=item * $count

The number of items.

=back


=cut

sub __xn {
	my ($msgid, $msgid_plural, $count, %args) = @_;
	return __nx($msgid, $msgid_plural, $count, %args);
}



=head2 domain

Returns the translation domain.

=cut

sub domain {
	return $DOMAIN;
}



#
# Replaces the place markers with their corresponding values.
#
sub expand {
	my ($i18n, %args) = @_;
	my $re = join q{|}, map { quotemeta $_ } keys %args;
	$i18n =~ s{
		[{] ($re) [}] # capture expressions in literal curlies
	}{
		defined $args{$1} ? $args{$1} : "{$1}"
	}egmsx; # and replace all
	return $i18n;
}



#
# Calls dgettext and ensures that the converted text is in UTF-8.
#
sub dgettext_utf8 {
	my ($msgid) = @_;
	my $i18n = dgettext($DOMAIN, $msgid);
	return decode('UTF-8', $i18n);
}



#
# Calls dngettext and ensures that the converted text is in UTF-8.
#
sub dngettext_utf8 {
	my ($msgid, $msgid_plural, $count) = @_;
	my $i18n = dngettext($DOMAIN, $msgid, $msgid_plural, $count);
	return decode('UTF-8', $i18n);
}



=head2 init

Initializes the i18n framework (gettext). Must be called in the fashion:

	Xacobeo::I18n->init($folder);

Parameters:

=over

=item * $folder

The folder where to find the translation files. For instance for the translation
F</usr/share/locale/fr/LC_MESSAGES/xacobeo.mo> the folder F</usr/share/locale>
has to be provided.

=back

=cut

sub init {
	my (undef, $folder) = @_;

	textdomain($DOMAIN);
	bindtextdomain($DOMAIN, $folder);

	return;
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

