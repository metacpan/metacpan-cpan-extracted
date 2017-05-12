package Toader::VCS;

use warnings;
use strict;
use base 'Error::Helper';
use Config::Tiny;

=head1 NAME

Toader::VCS - Handles the VCS integration for Toader.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 METHODS

=head2 new

This intiates the object.

One argument is accepted and that is to Toader object
to use.

    my $tvcs=Toader::VCS->new($toader);
    if ( $tvcs->error ){
        warn('Error:'$tvcs->error.':'.$tvcs->errorFlag.': '.$tvcs->errorString);
    }

=cut

sub new{
	my $toader=$_[1];

	my $self={
			  error=>undef,
			  errorString=>'',
			  perror=>undef,
			  errorExtra=>{
				  flags=>{
					  1=>'noToader',
					  2=>'notToader',
					  3=>'getConfigFailed',
					  4=>'nothingToAdd',
					  5=>'doesNotExist',
					  6=>'notFileOrDir',
					  7=>'configNotUsable',
					  8=>'nonZeroExit',
					  9=>'getVCSfailed',
				  },
			  },
			  usable=>1,
			  };
	bless $self;

	#make sure a Toader object is specified
	if ( ! defined( $toader ) ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No toader object specified';
		$self->warn;
		return $self;
	}

	#make sure it is a Toader object
	if ( ref( $toader ) ne 'Toader' ){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='The passed object is "'.ref( $toader ).'" and not a Toader object';
		$self->warn;
		return $self;
	}

	#saves the Toader object
	$self->{toader}=$toader;

	#gets the config manually as Toader::Config depends on this module
	my $configFile=$self->{toader}->getRootDir.'/.toader/config.ini';
	if ( -f $configFile ){
		$self->{config}=Config::Tiny->read( $configFile );
		if ( ! defined( $self->{config} ) ){
			$self->{perror}=1;
			$self->{error}=3;
			$self->{errorString}='Config::Tiny failed to read "'.$configFile.'"';
			$self->warn;
			return $self;
		}
	}else{
		$self->{config}=Config::Tiny->new;
	}
	
	#checks if it is usable or not
	if (
		( !defined( $self->{config}->{_}->{vcs} ) ) ||
		( !$self->{config}->{_}{vcs} ) ||
		( !defined( $self->{config}->{VCS} ) ) ||
		( !defined( $self->{config}->{VCS}->{addExec} ) ) ||
		( !defined( $self->{config}->{VCS}->{deleteExec} ) ) ||
		( !defined( $self->{config}->{VCS}->{underVCSexec} ) )
		){
		$self->{usable}=0;
	}


	return $self;
}

=head2 add

This adds a file or directory.

One option is accepted and that what is to be added.

    $tvcs->add($someFile);
    if ( $tvcs->error ){
        warn('Error:'$tvcs->error.':'.$tvcs->errorFlag.': '.$tvcs->errorString);
    }

=cut

sub add{
	my $self=$_[0];
	my $toAdd=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! $self->{usable} ){
		$self->{error}=7;
		$self->{errorString}='The VCS config is not usable';
		$self->warn;
		return undef;
	}

	if ( ! defined( $toAdd ) ){
		$self->{error}=4;
		$self->{errorString}='Nothing defined to add';
		$self->warn;
		return undef;
	}

	if ( ! -e $toAdd ){
		$self->{error}=5;
		$self->{errorString}='What is to be added does not exist';
		$self->warn;
		return undef;
	}

	if ( ( ! -f $toAdd ) || ( ! -d $toAdd ) ){
		$self->{error}=6;
		$self->{errorString}='What is to be added is not a file or directory';
		$self->warn;
		return undef;
	}

	my $toExec=$self->{config}->{VCS}->{addExec};
	$toExec=~s/\%\%\%item\%\%\%/$toAdd/g;
	system($toExec);
	my $exitCode=$?;
	if ( $exitCode != 0 ){
		$self->{error}=8;
		$self->{errorString}='Exit integer returned "'.$exitCode.'". instead of "0"';
		$self->warn;
		return undef;
	}
	
	return 1;
}

=head2 delete

This deletes a file or directory.

One option is accepted and that what is to be deleted.

    $tvcs->delete($someFile);
    if ( $tvcs->error ){
        warn('Error:'$tvcs->error.':'.$tvcs->errorFlag.': '.$tvcs->errorString);
    }

=cut

sub delete{
	my $self=$_[0];
	my $toDelete=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! $self->{usable} ){
		$self->{error}=7;
		$self->{errorString}='The VCS config is not usable';
		$self->warn;
		return undef;
	}

	if ( ! defined( $toDelete ) ){
		$self->{error}=4;
		$self->{errorString}='Nothing defined to delete';
		$self->warn;
		return undef;
	}

	my $toExec=$self->{config}->{VCS}->{deleteExec};
	$toExec=~s/\%\%\%item\%\%\%/$toDelete/g;
	system($toExec);
	my $exitCode=$?;
	if ( $exitCode != 0 ){
		$self->{error}=8;
		$self->{errorString}='Exit integer returned "'.$exitCode.'". instead of "0"';
		$self->warn;
		return undef;
	}
	
	return 1;
}

=head2 underVCS

This checks if something is under VCS.

The returned value is a Perl boolean.

    my $underVCS=$tvcs->underVCS($someFile);
    if ( $tvcs->error ){
        warn('Error:'$tvcs->error.':'.$tvcs->errorFlag.': '.$tvcs->errorString);
    }

=cut

sub underVCS{
	my $self=$_[0];
	my $toCheck=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	if ( ! $self->{usable} ){
		$self->{error}=7;
		$self->{errorString}='The VCS config is not usable';
		$self->warn;
		return undef;
	}

	if ( ! defined( $toCheck ) ){
		$self->{error}=4;
		$self->{errorString}='Nothing defined to check';
		$self->warn;
		return undef;
	}

	my $toExec=$self->{config}->{VCS}->{underVCSexec};
	$toExec=~s/\%\%\%item\%\%\%/$toCheck/g;
	system($toExec);
	my $exitCode=$?;
	if ( $exitCode != 0 ){
		$self->{error}=8;
		$self->{errorString}='Exit integer returned "'.$exitCode.'". instead of "0"';
		$self->warn;
		return undef;
	}
	
	return 1;
}

=head2 usable

Checks if this object is usable or not.

    $tvcs->usable;

=cut

sub usable{
	my $self=$_[0];

	if ( $self->perror ){
		return undef;
	}
	
	return $self->{usable};
}

=head1 ERROR CODES/FLAGS/HANDLING

Error handling is provided by L<Error::Helper>.

=head2 1, noToader

No L<Toader> object specified.

=head2 2, notToader

The object specified is not a L<Toader> object.

=head2 3, getConfigFailed

Failed to read the .toader/config.ini .

=head2 4, nothingToAdd

Nothing specified to add.

=head2 5, doesNotExist

What is to be added does not exist

=head2 6, notFileOrDir

The specified item is not a file or directory.

=head2 7, configNotUsable

The configuration is not usable.

This most likely means either a config value is missing or it is disabled, such as in the example below.

    vcs=0
    [VCS]
    addExec=svn add --parents %%%item%%% > /dev/null
    deleteExec=svn del %%%item%%% > /dev/null
    underVCSexec=svn info %%%info%%% > /dev/null


=head2 8, nonZeroExit

One of the commands to execute returned a non-zero status.

=head2 9, getVCSfailed

Toader->getVCS errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toader::VCS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toader>

=item * Search CPAN

L<http://search.cpan.org/dist/Toader/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Toader::VCS
