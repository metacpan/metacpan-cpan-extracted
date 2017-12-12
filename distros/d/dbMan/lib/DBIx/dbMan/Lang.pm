package DBIx::dbMan::Lang;

use strict;
use locale;
use POSIX;
use Locale::gettext;

our $VERSION = '0.03';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;

    $obj->{ gettext } = Locale::gettext->domain( 'dbman' );
	return $obj;
}

sub str {
	my $obj = shift;
	my $str = join '',@_;

	return $obj->{ gettext }->get( $str );
}
