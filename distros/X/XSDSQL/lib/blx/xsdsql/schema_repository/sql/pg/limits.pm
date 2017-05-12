package blx::xsdsql::schema_repository::sql::pg::limits;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::schema_repository::sql::generic::limits);

my %LIMITS=();

my %MAXLIMITS=(
	string			=>  { SIZE => 10485760 }
	,fixedstring	=>  { FIXSIZE => 10485760 }
	,sizestring		=>  { SIZE => 10485760 }
); 


my %SQL_TRANSLATE=(
			boolean			=> 'boolean'	
			,integer		=> 'decimal(%i)'
			,number			=> 'numeric(%i,%d)'
			,number3		=> 'smallint'
			,number5		=> 'smallint'		
			,number10		=> 'integer'		
			,number20		=> 'bigint'
			,unumber3		=> 'smallint'
			,unumber5		=> 'integer'		
			,unumber10		=> 'bigint'			
			,unumber20		=> 'decimal(20,0)'			
);


sub _get_sql_translate {  return \%SQL_TRANSLATE; }

sub _get_limits	 { return \%LIMITS; }

sub _get_maxlimits { return \%MAXLIMITS; }



sub new {
	my ($class,%params)=@_;
	return $class->SUPER::_new(%params);
}




1;


__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::pg::limits -  limits database depending

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::pg::limits

=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut




