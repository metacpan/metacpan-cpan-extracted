package Text::CSV::SQLhelper;

use warnings;
use strict;

=head1 NAME

Text::CSV::SQLhelper - Processes a CSV file and tries to figure out

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS



=head1 METHODS

=head2 new

=head3 args hash

=head4 csv

This is the text CSV object.

=head4 defaultAllowNull

If no null is found,

It defaults to false.

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
				  errorString=>undef,
				  module=>'Text-CSV-SQLhelper',
				  };
        bless $self;

		if (!defined( $args{csv} )) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}='No Text::CSV object passed';
			warn( $self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString} );
			return $self;
		}

		if (ref( $args{csv} ) ne 'Text::CSV') {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}='No Text::CSV object passed';
			warn( $self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString} );
			return $self;
		}

		if (!defined($args{defaultAllowNull})) {
			$args{defaultAllowNull}=0;
		}

		$self->{csv}=$args{csv};
		$self->{allownull}=$args{defaultAllowNull};

		return $self;
}

=head2

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    my $error=$foo->error;
    if($error){
        print 'error code: '.$error."\n";
    }

=cut

sub error{
    return $_[0]->{error};
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return ''.

    my $error=$foo->error;
    if($error){
        print 'error code:'.$error.': '.$foo->errorString."\n";
    }

=cut

sub errorString{
    return $_[0]->{errorString};
}

=head2 processFile

This processes the specified file.

Two arguements are required. The first one is the file to read and the
second one is a boolean specifying if the top line should be skipped
or not.

The returned value is a array.

=head3 returned array

=head4 allownull

Wether or not a column can have a null value.

This defaults to false.

=head4 min

This is the smallest value found. In regards to strings,
it represents number of characters in the shortest string.

=head4 max

This is the largest value found. In regards to strings,
it represents number of characters in the longest string.

=head4 sql

This is a SQL description for the column.

=head4 type

This is the data type of the column.

The possible values are 'float', 'int', and 'string'.


    #process the file, including the top line
    my @columns=$foo->processFile($file);
    if($foo->error){
        print 'error code:'.$foo->error.': '.$foo->errorString."\n";
    }

    #process the file, skipping the top line
    my @columns=$foo->processFile($file, 1);
    if($foo->error){
        print 'error code:'.$foo->error.': '.$foo->errorString."\n";
    }


=cut

sub processFile{
	my $self=$_[0];
	my $file=$_[1];
	my $removetop=$_[2];
	my $method='processfile';

	$self->errorblank;
	if ($self->error) {
		warn($self->{module}.' '.$method.': failed to blank the previous error');
		return undef;
	}

	if (!defined($file)) {
		$self->{error}=2;
		$self->{errorString}='No file specified';
		warn( $self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString} );
		return undef;
	}

	#read the file
	my $fh;
	if (!open($fh, "<:encoding(utf8)", $file)) {
		$self->{error}=3;
		$self->{errorString}='Failed to open the file, "'.$file.'",';
		warn( $self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString} );
		return undef;		
	}

	#what will be returned
	my @columns;

	#remove the top if asked to
	if ($removetop) {
		my @top=@{$self->{csv}->getline ($fh)};
	}

	#processes each row
	my @row;
	my $continueloop=1;
	#fetches the new row and we do get it, save it as a array and if we don't stop this loop
	my $newrow=$self->{csv}->getline ($fh);
	if (defined($newrow->[0])) {
		@row = @{$newrow};
	}else {
		$continueloop=0;
	}
	while ($continueloop) {
		#processes each row
		my $int=0;
		while ($int <= $#row) {
			my %rowinfo;
			my $matched=0;

			#handles it if this item is undefined
			if (!defined($row[$int])) {
				if (!defined( $columns[$int] )) {
					$rowinfo{allownull}=1;
					$rowinfo{min}=0;
					$rowinfo{max}=0;
					$columns[$int]=\%rowinfo;
				}else {
					$columns[$int]{allownull}=1;
				}
				$matched=1;
			}
			
			#handles it if it is a int
			if ( ($row[$int] =~ /^[0123456789]*$/ ) && (!$matched) ) {
				if (!defined( $columns[$int] )) {
					$rowinfo{type}='int';
					$rowinfo{max}=$row[$int];
					$rowinfo{min}=$row[$int];
					$rowinfo{allownull}=$self->{allownull};
					$columns[$int]=\%rowinfo;
				}else {
					#handles it if the type has not been set previously.
					if (defined($columns[$int]{type})){
						$columns[$int]{type}='int';
					}

					#handles it if the last type was int as well
					if ($columns[$int]{type} eq 'int') {
						#updates the new min and max value, if needed
						if ($columns[$int]{min} > $row[$int]) {
							$columns[$int]{min}=$row[$int];
						}
						if ($columns[$int]{max} < $row[$int]) {
							$columns[$int]{min}=$row[$int];
						}
					}
					#handles it if it is a string
					if ($columns[$int]{type} eq 'string') {
						#updates the new min and max length, if needed
						my $length=length($row[$int]);
						if ($columns[$int]{min} > $length) {
							$columns[$int]{min}=$length;
						}
						if ($columns[$int]{max} < $length) {
							$columns[$int]{max}=$length;
						}
					}
					#handles it if the last type was float
					if ($columns[$int]{type} eq 'float') {
						#updates the new min and max value, if needed
						if ($columns[$int]{min} > $row[$int]) {
							$columns[$int]{min}=$row[$int];
						}
						if ($columns[$int]{max} < $row[$int]) {
							$columns[$int]{max}=$row[$int];
						}
					}
				}
				$matched=1;
			}

			#handles it if it is a float
			if ( ($row[$int] =~ /^[0123456789]*\.[0123456789]*$/ ) && (!$matched) ) {
				if (!defined( $columns[$int] )) {
					$rowinfo{type}='float';
					$rowinfo{max}=$row[$int];
					$rowinfo{min}=$row[$int];
					$rowinfo{allownull}=$self->{allownull};
					$columns[$int]=\%rowinfo;
				}else {
					#handles it if the type has not been set previously.
					if (defined($columns[$int]{type})){
						$columns[$int]{type}='float';
					}

					#handles it if the last type was int as well
					if ($columns[$int]{type} eq 'int') {
						#updates the new min and max value, if needed
						if ($columns[$int]{min} > $row[$int]) {
							$columns[$int]{min}=$row[$int];
						}
						if ($columns[$int]{max} < $row[$int]) {
							$columns[$int]{max}=$row[$int];
						}
						#change the type to float as int can also be a float value as well, but float is
						#more accurate
						$columns[$int]{type}='float';
					}
					#handles it if it is a string
					if ($columns[$int]{type} eq 'string') {
						#updates the new min and max length, if needed
						my $length=length($row[$int]);
						if ($columns[$int]{min} > $length) {
							$columns[$int]{min}=$length;
						}
						if ($columns[$int]{max} < $length) {
							$columns[$int]{max}=$length;
						}
					}
					#handles it if the last type was float
					if ($columns[$int]{type} eq 'float') {
						#updates the new min and max value, if needed
						if ($columns[$int]{min} > $row[$int]) {
							$columns[$int]{min}=$row[$int];
						}
						if ($columns[$int]{max} < $row[$int]) {
							$columns[$int]{max}=$row[$int];
						}
					}
				}
				$matched=1;
			}

			#handles it if it was not matched, which in this case only leaves a string
			if (!$matched) {
				if (!defined( $columns[$int] )) {
					$rowinfo{type}='string';
					$rowinfo{allownull}=$self->{allownull};
					my $length=length($row[$int]);
					$columns[$int]{min}=$length;
					$columns[$int]{max}=$length;
					$columns[$int]=\%rowinfo;
				}

				#just set this to a string instead of bothering to check if this was
				#set to a int or float initially...
				$columns[$int]{type}='string';

				#updates the new min and max length, if needed
				my $length=length($row[$int]);
				if ( (!defined( $columns[$int]{min} )) || ($columns[$int]{min} > $length) ) {
					$columns[$int]{min}=$length;
				}
				if ( (!defined( $columns[$int]{max} )) || ($columns[$int]{max} < $length)) {
					$columns[$int]{max}=$length;
				}
			}

			$int++;
		}
		
		#fetches the new row and we do get it, save it as a array and if we don't stop this loop
		$newrow=$self->{csv}->getline ($fh);
		if (defined($newrow)) {
			my @row = @{$newrow};
		}else {
			$continueloop=0;
		}
	}

	#runs through each one setting up the SQL information and handling any consistently nulls
	my $int=0;
	while (defined($columns[$int])) {
		if (!defined($columns[$int]{type})) {
			$columns[$int]{type}='string';
			$columns[$int]{sql}='VARCHAR(1024)';
			$columns[$int]{min}=0;
			$columns[$int]{max}=1024;
		}

		if ($columns[$int]{type} eq 'int') {
			$columns[$int]{sql}='BIGINT';
		}

		if ($columns[$int]{type} eq 'float') {
			$columns[$int]{sql}='DOUBLE PRECISION';
		}

		if ($columns[$int]{type} eq 'string') {
			$columns[$int]{max}=((( $columns[$int]{max} / 1024) % 1024) + 1) * 1024;
			$columns[$int]{sql}='VARCCHAR('.$columns[$int]{max}.')';
		}

		if (!$columns[$int]{allownull}) {
			$columns[$int]{sql}=$columns[$int]{sql}.' NOT NULL';
		}

		$int++;
	}

	return @columns;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

If a permanent error is set, it will not be cleared.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

sub errorblank{
        my $self=$_[0];

        if ($self->{perror}) {
                warn($self->{module}.' errorblank: A permanent error is set');
                return undef;
        }

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

=head2 1

No "Text::CSV" object specified or defined.

=head2 2

No file specified.

=head3 3

Failed to open the file.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-csv-sqlhelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-CSV-SQLhelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::CSV::SQLhelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-CSV-SQLhelper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-CSV-SQLhelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-CSV-SQLhelper>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-CSV-SQLhelper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::CSV::SQLhelper
