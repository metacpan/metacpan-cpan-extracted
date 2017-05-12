
package SQL::Translator::Producer::XML::Propel;

use SQL::Translator::Producer::XML::Xmldoom;
use strict;

sub produce
{
	my ($translator, $data) = @_;

	$translator->producer_args( propel_compatible => 1 );

	return SQL::Translator::Producer::XML::Xmldoom::parse( $translator, $data );
}

1;

__END__

=pod

=head1 NAME

SQL::Translator::Producer::XML::Propel - Generates XML documents for use with Propel

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Producer::XML::Propel;

  my $translator = SQL::Translator->new;
  $translator->producer('SQL::Translator::Producer::XML::Propel');

=head1 DESCRIPTION

Just an alias to the Xmldoom module running in Propel compatibility mode.

=head1 SEE ALSO

SQL::Translator, SQL::Translator::Producer::XML::Xmldoom, Xmldoom

=head1 AUTHORS

David R Snopek E<lt>dsnopek@gmail.comE<gt>

=cut

