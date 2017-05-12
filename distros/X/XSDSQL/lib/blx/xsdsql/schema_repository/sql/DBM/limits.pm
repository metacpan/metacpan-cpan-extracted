package blx::xsdsql::schema_repository::sql::DBM::limits;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::schema_repository::sql::generic::limits);


my %LIMITS=();

my %MAXLIMITS=(
	string			=>  { SIZE => 1024 }
	,fixedstring	=>  { FIXSIZE => 1024 }
	,sizestring		=>  { SIZE => 1024 }
); 


my %SQL_TRANSLATE=(
			boolean			=> 'varchar(1)'
			,decimal		=> 'varchar(100)'
			,integer		=> 'int'
			,number			=> 'int'
			,number3		=> 'int'
			,number5		=> 'int'		
			,number10		=> 'int'		
			,number20		=> 'int'
			,unumber3		=> 'int'
			,unumber5		=> 'int'		
			,unumber10		=> 'int'			
			,unumber20		=> 'int'			
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

blx::xsdsql::schema_repository::sql::DBM::limits -  limits database depending

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::DBM::limits
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




