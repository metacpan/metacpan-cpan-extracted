package blx::xsdsql::schema_repository::sql::DBM::catalog;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use base qw(blx::xsdsql::schema_repository::sql::generic::catalog);

use constant {
				 DICTIONARY_NAME_MAXSIZE		=> 63
				,DICTIONARY_COMMENT_MAXSIZE	=> 2048
				,BEGIN_COMMENT				=> '/*'
				,END_COMMENT				=> '*/'
				,COMMAND_TERMINATOR			=> ';'
				,MAX_COLUMNS_VIEW			=> undef 
				,MAX_JOINS_VIEW				=> undef
				,MAX_COLUMNS_TABLE			=> 1600
};

sub new {
	my ($class,%params)=@_;
	return $class->SUPER::_new(%params);
}

sub get_name_maxsize { return DICTIONARY_NAME_MAXSIZE; }

sub get_comment_maxsize { return DICTIONARY_COMMENT_MAXSIZE; }

sub get_begin_comment { return 	BEGIN_COMMENT; }

sub get_end_comment { return END_COMMENT; }

sub command_terminator { return COMMAND_TERMINATOR; }

sub get_max_columns_view { return MAX_COLUMNS_VIEW; }

sub get_max_joins_view { return MAX_JOINS_VIEW; }

sub get_max_columns_table { return MAX_COLUMNS_TABLE; }

sub is_support_views { return 0; }

1;

__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::DBM::catalog -  a catalog class for DBM
=cut

=head1 SYNOPSIS

  use blx::xsdsql::schema_repository::sql::DBM::catalog

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

see the methods of blx::xsdsql::schema_repository::sql::generic::catalog


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

See blx::xsdsql::schema_repository::sql::generic::catalog - this class inerith for it

See blx:.xsdsql::generator for generate the schema of the database and blx::xsdsql::parser  for parse a xsd file (schema file)

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut




