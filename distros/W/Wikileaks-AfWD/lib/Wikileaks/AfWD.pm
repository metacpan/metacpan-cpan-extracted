package Wikileaks::AfWD;

use warnings;
use strict;
use DBI;
use Text::NeatTemplate;
use Text::Autoformat qw(autoformat);

=head1 NAME

Wikileaks::AfWD - Useful utilities for searching the Afganistan War Diary.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Wikileaks::AfWD;

    my $foo = Wikileaks::AfWD->new();
    ...

=head1 METHODS

=head2 new

This initiates the object.

It takes a optional hash reference.

=head3 hash ref

If both "dbb" and "dbhCS" is specified, "dbi" will be used.

If none are specified, it checks for envriromental variables.

=head4 dbi

This is the DBH  to use.

=head4 dbiCS

This is the DBI connection string to use.

=head4 dbiUser

If using "dbhCS", this will be checked for the user name
to use.

If not specified, it will be set to "".

=head4 dbiPass

If using "dbhCS", this will be checked for the password
to use.

If not specified, it will be set to "".

=head4 table

This is the table to search.

If not specified, "war_diary" is used.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='new';

	my $self={
			  error=>undef,
			  perror=>undef,
			  errorString=>'',
			  module=>'Wikileaks-AfWD',
			  };
	bless $self;

	#gets the DBI if we have it
	if (defined( $args{dbh} )) {
		if ($args{dbh} ne 'DBI::db') {
			$self->error=1;
			$self->{perror}=1;
			$self->{errorString}="The database handle passed is not a 'DBI::db' object";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
		$self->{dbh}=$args{dbh};
	}

	#if we still don't have a DBH yet, see if it was specified
	if ( (!defined( $self->{dbh} )) && (defined( $args{dbiCS} )) ) {
		#gets the user to use for connecting to the the server
		my $user;
		if(defined( $args{dbiUser} )){
			$user=$args{dbiUser};
		}
		#gets the password to use for connecting to the the server
		my $pass;
		if(defined( $args{dbiPass} )){
			$pass=$args{dbiPass};
		}

		#attempt to connect
		my $dbh=DBI->connect($args{dbiCS}, $user, $pass);
		if (!defined( $dbh )) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}="Failed to connect to the database";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;			
		}
		$self->{dbh}=$dbh;
	}

	#if we still don't have it, try fetching it via the environmental variable
	if (!defined( $self->{dbh} )) {
		#error if $ENV{AfWD_DBICS} is not defined... this being the final chance to get it
		if (!defined( $ENV{AfWD_DBICS} )) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}='$ENV{AfWD_DBICS} not defined';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;			
		}

		#gets the user to use for connecting to the the server
		my $user;
		if(defined( $ENV{AfWD_DBIUSER} )){
			$user=$ENV{AfWD_DBIUSER};
		}
		#gets the password to use for connecting to the the server
		my $pass;
		if(defined( $ENV{AfWD_DBIPASS} )){
			$pass=$ENV{AfWD_DBIPASS};
		}

		#attempt to connect
		my $dbh=DBI->connect($ENV{AfWD_DBICS}, $user, $pass);
		if (!defined( $dbh )) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}="Failed to connect to the database";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
		$self->{dbh}=$dbh;
	}

	if (!defined($args{table})) {
		$self->{table}="war_diary";
	}

	return $self;
}

=head2 search

This performs a search. This searches the table, specified in new, and returns the resutls.

One arguement is taken and is appended to the select statement.

For example if we wish to select every report where the dcolor is "BLUE", we would set it to
"dcolor='BLUE'", making the resulting string "SELECT * FROM war_diary WHERE dcolor='BLUE';".

What is returned is the resulting statement handle, post execute.

    my $sth=$foo->search($WHERE);

=cut

sub search{
	my $self=$_[0];
	my $search=$_[1];

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		return undef;
	}

	#default to it being blank if there is nothing
	if (!defined( $search )) {
		$search='';
	}else {
		$search='WHERE '.$search;
	}

	my $sth=$self->{dbh}->prepare('SELECT * FROM '.$self->{table}.' '.$search);

	$sth->execute;

	return $sth;
}

=head2 format

This formats the statement handler from the search method.

=head3 args hash ref

=head4 joiner

This is what should be used to join the entries.

The default is
"\n\n---------------------------------------------------------------------------\n\n".

=head4 print

If defined, it will be printed and '' will be returned.

=head4 sth

This is the statement handler to use. Generally what is returned from
the search method.

=head4 template

This is the Text::NeatTemplate to use.

=cut

sub format{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	my $method='format';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		return undef;
	}

	#makes sure we have $sth
	if (!defined($args{sth})) {
		$self->{error}=3;
		$self->{errorString}="No statement handle passed";
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}
	my $sth=$args{sth};

	#
	my $template='ReportKey: {$reportkey}'."\n".
	             'TrackingNumber: {$trackingnumber}'."\n".
	             "\n".
	             'Date: {$date}'."\n".
	             'Type: {$type}'."\n".
	             'Category: {$category}'."\n".
	             'Region: {$region}'."\n".
	             'AttackOn: {aAttackon}'."\n".
	             'ComplexAttack: {$complexattack}'."\n".
	             'ReportingUnit: {$reportingunit}'."\n".
	             'UnitName: {$unitname}'."\n".
	             'TypeOfUnit: {$typeofunit}'."\n".
				 "\n".
	             'FriendlyWIA: {$friendlywia}'."\n".
	             'FriendlyKIA: {$friendlykia}'."\n".
	             'HostNationWIA: {$hostnationwia}'."\n".
	             'HostNationKIA: {$hostnationkia}'."\n".
	             'CivilianWIA: {$civilianwia}'."\n".
	             'CivilianKIA: {$civiliankia}'."\n".
	             'EnemyWIA: {$enemywia}'."\n".
	             'EnemyKIA: {$enemykia}'."\n".
	             'EnemyDetained: {$enemydetained}'."\n".
				 "\n".
	             'MGRS: {$MGRS}'."\n".
	             'Latitude: {$latitude}'."\n".
	             'Longitude: {$longitude}'."\n".
				 "\n".
	             'OriginatorGroup: {$originatorgroup}'."\n".
	             'UpdatedByGroup: {$updatedbygroup}'."\n".
	             'CCIR: {$ccir}'."\n".
	             'Sigact: {$sigact}'."\n".
	             'Affiliation: {$affiliation}'."\n".
	             'DColor: {$dcolor}'."\n".
	             'classification: {$classification}'."\n".
				 "\n".
	             'Title: {$title}'."\n\n".
				 '{$summary}';
	if (defined( $args{template} )) {
		$template=$args{template};
	}

	#the template object that will be filled in
	my $tobj = Text::NeatTemplate->new();

	#used to join each item
	my $joiner="\n\n---------------------------------------------------------------------------\n\n";

	#does the initial one and forms the text
	my $hashref=$sth->fetchrow_hashref;

	#hash cleanup... some servers will return it with proper capilization
	#and others, Pg, will return it all lower case... so lc it all
	my @keys=%{ $hashref };
	my $int=0;
	while (defined( $keys[$int] )) {
		$hashref->{ lc( $keys[$int] ) }=$hashref->{ $keys[$int] };

		$int++;
	}

	$hashref->{summary}=~s/\&amp\;apos\;/\'/g;
	$hashref->{summary}=~s/\&amp\;quot\;/\"/g;
	$hashref->{summary}=autoformat($hashref->{summary}, {
														 right=>72,
														 lists =>'',
														 all=>1,
														 });
	my $text=$tobj->fill_in(
							data_hash=>$hashref,
							template=>$template
							);

	#process each one
	$hashref=$sth->fetchrow_hashref;
	while (defined( $hashref )) {
		#hash cleanup... some servers will return it with proper capilization
		#and others, Pg, will return it all lower case... so lc it all
		my @keys=%{ $hashref };
		my $int=0;
		while (defined( $keys[$int] )) {
			$hashref->{ lc( $keys[$int] ) }=$hashref->{ $keys[$int] };
			
			$int++;
		}

		$hashref->{summary}=~s/\&amp\;apos\;/\'/g;
		$hashref->{summary}=~s/\&amp\;amp\;apos\;/\'/g;
		$hashref->{summary}=~s/\&amp\;quot\;/\"/g;

		$hashref->{summary}=autoformat($hashref->{summary}, {
															 right=>72,
															 lists =>'',
															 all=>1,
															 });
		
		#found one case this is true for while watching stderr
		if (!defined($hashref->{summary})) {
			$hashref->{summary}='';
		}

		$text=$text.$joiner.$tobj->fill_in(
										   data_hash=>$hashref,
										   template=>$template,
										   );

		if (defined( $args{print} )) {
			print $text;
			$text='';
		}

		$hashref=$sth->fetchrow_hashref;
	}

	return $text;
}

=head1 ERROR RELATED METHODS

=head2 error

This returns the current error code if one is set. If undef/evaulates as false
then no error is present. Other wise one is.

    if($foo->error){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub error{
        return $_[0]->{error};
}

=head2 errorString

This returns the current error string. A return of "" means no error is present.

    my $errorString=$foo->errorString;

=cut

sub errorString{
        return $_[0]->{errorString};
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];
		my $function='errorBlank';
		
		if ($self->{perror}) {
			warn($self->{error}.' '.$function.': A permanent error is set. error="'.
				 $self->{error}.'" errorString="'.$self->{errorSting}.'"');
			return undef;
		}
		
        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

The error code is contianed in $foo->{error} and a extended description can be
found in $foo->{errorString}. If any module ever sets $foo->{perror} then the error
is permanent and none of the methods are usable.

=head2 1

The database handle passed is not a "DBI::db" object.

=head2 2

Failed to create the DBI connection.

=head2 3

No statement handle passed.

=head1 ENVIRONMENTAL VARIABLES

=head2 AfWD_DBICS

If neither "dbiCS" or "dbh" is specified for the new method, this will be used.

=head2 AfWD_DBIUSER

This if $ENV{AfWD_DBICS} is used, this will be checked for the user.

=head2 AfWD_DBIPASS

This if $ENV{AfWD_DBICS} is used, this will be checked for the password.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbi-wikileaks-afwd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wikileaks-AfWD>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wikileaks::AfWD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wikileaks-AfWD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wikileaks-AfWD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wikileaks-AfWD>

=item * Search CPAN

L<http://search.cpan.org/dist/Wikileaks-AfWD/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Wikileaks::AfWD

