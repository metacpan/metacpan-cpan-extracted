
package example::BookStore::BookAgeProperty;
use base qw(Xmldoom::Definition::Property::Simple);

use DBIx::Romani::Query::SQL::TTT::Function;
use DBIx::Romani::Query::SQL::TTT::Operator;
use DBIx::Romani::Query::Function::Now;
use Date::Calc qw( Today Date_to_Days );
use POSIX::strptime;
use strict;

sub get_data_type
{
	my $self = shift;

	# TODO: this isn't right!  There should be some way that hints is included 
	# automatically, and options can be pretty much ignored.
	my %value = (
		type    => 'integer',
		options => $self->{options},
		hints   => $self->{hints}
	);

	return \%value;
}

sub get
{
	my ($self, $object) = @_;

	my ($year1,$month1,$day1) = Today();
	my $today_days = Date_to_Days($year1,$month1,$day1);


	my ($sec2,$min2,$hour2,$day2,$month2,$year2,$tmp,$tmp) = 
		POSIX::strptime( $object->_get_attr( "created" ), '%Y-%m-%d %H:%M:%S' );
	my $created_days = Date_to_Days($year2+1900,$month2+1,$day2);

	return $today_days - $created_days;
}

sub set
{
	my ($self, $object, $value) = @_;

	die "Cannot write the age property";
}

sub get_query_lval
{
	my $self = shift;

	my $today_days = DBIx::Romani::Query::SQL::TTT::Function->new('TO_DAYS');
	$today_days->add( DBIx::Romani::Query::Function::Now->new() );

	my $created_days = DBIx::Romani::Query::SQL::TTT::Function->new('TO_DAYS');
	$created_days->add( DBIx::Romani::Query::SQL::Column->new( $self->{parent}->get_table_name(), 'created' ) );
	
	my $age_op = DBIx::Romani::Query::SQL::TTT::Operator->new('-');
	$age_op->add( $today_days );
	$age_op->add( $created_days );

	return [ $age_op ];
}

1;

