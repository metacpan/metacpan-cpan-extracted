package blx::xsdsql::schema_repository::sql::oracle::limits;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::schema_repository::sql::generic::limits);


my %LIMITS=( );

my %MAXLIMITS=(
	string			=>  { SIZE => 4000 }
	,fixedstring	=>  { FIXSIZE => 2000 }
	,sizestring		=>  { SIZE => 4000 }
); 


my %SQL_TRANSLATE=(
			boolean			=> 'varchar(1 byte)'		
			,string 		=> 'varchar(%d char)'
			,fixedstring 	=> 'char(%d char)'
			,string50		=> 'varchar(%d char)'
			,sizestring		=> 'varchar(%d byte)'
			,sizestring50	=> 'varchar(%d byte)'
			,integer		=> 'number(%i,0)'
			,number			=> 'number(%i,%d)'
			,number3		=> 'number(3,0)'
			,number5		=> 'number(5,0)'		
			,number10		=> 'number(10,0)'		
			,number20		=> 'number(20,0)'
			,unumber3		=> 'number(3,0)'
			,unumber5		=> 'number(5,0)'		
			,unumber10		=> 'number(10,0)'			
			,unumber20		=> 'number(20,0)'			
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

blx::xsdsql::schema_repository::sql::oracle::limits -  limits database depending

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::oracle::limits
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




