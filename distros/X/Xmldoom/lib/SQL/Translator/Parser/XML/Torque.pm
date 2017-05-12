
package SQL::Translator::Parser::XML::Torque;
use base qw(SQL::Translator::Parser::XML::Xmldoom);

# NOTE: Just an alias for Xmldoom.

1;

__END__

=pod

=head1 NAME

SQL::Translator::Parser::XML::Torque - parser for Apache Torque XML documents

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Parser::XML::Torque;
  
  my $translator = SQL::Translator->new;
  $translator->parser('SQL::Translator::Parser::XML::Torque');

=head1 DESCRIPTION

Just an alias for the Xmldoom parser.

=head1 AUTHOR

David R Snopek E<lt>dsnopek@gmail.comE<gt>

=head1 SEE ALSO

SQL::Translator, SQL::Translator::Parser::XML::Xmldoom, Xmldoom

=cut

