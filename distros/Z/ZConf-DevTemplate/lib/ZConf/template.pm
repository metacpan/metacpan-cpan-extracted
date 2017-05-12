package ZConf::template;

use warnings;
use strict;
use ZConf;

=head1 NAME

ZConf::template - 

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ZConf::template;

    my $foo = ZConf::template->new();
    ...

=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash.

=head3 hash values

=head4 zconf

If this is defined, it will be used instead of creating
a new ZConf object.

    my $foo=ZConf::template->new;
    if($foo->error){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $method='new';

	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  zconfconfig=>'%%%ZCONFCONFIG%%%',
			  module=>'ZConf-template',
			  };
	bless $self;
	
	#get the ZConf object
	if (!defined($args{zconf})) {
		#creates the ZConf object
		$self->{zconf}=ZConf->new();
		if(defined($self->{zconf}->{error})){
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                      .$self->{zconf}->{error}."', '".
			                      $self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#check if the config exists
	my $returned = $self->{zconf}->configExists($self->{zconfconfig});
	if (!$self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Checking if '".$self."' exists failed. error='".
		                     $self->{zconf}->{error}."', errorString='".
		                     $self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#initiate the config if it does not exist
	if (!$returned) {
		#create the config
		$self->{zconf}->createConfig($self->{zconfconfig});
		if ($self->{zconf}->{error}) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Checking if '".$self."' exists failed. error='".
		                         $self->{zconf}->{error}."', errorString='".
		                         $self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}

		#init it
		$self->init;
		if ($self->{zconf}->{error}) {
			$self->{perror}=1;
			$self->{errorString}='Init failed.';
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		#if we have a set, make sure we also have a set that will be loaded
		$returned=$self->{zconf}->defaultSetExists($self->{zconfconfig});
		if ($self->{zconf}->{error}) {
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Checking if '".$self."' exists failed. error='".
		                         $self->{zconf}->{error}."', errorString='".
		                         $self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}

		#initiliaze a the default set if needed.
		if (!$returned) {
			#init it
			$self->init;
			if ($self->{zconf}->{error}) {
				$self->{perror}=1;
				$self->{errorString}='Init failed.';
				warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
				return $self;
			}
		}
	}


	#read the config
	$self->{zconf}->read({config=>$self->{zconfconfig}});
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Checking if the default set for '".$self."' exists failed. error='".
		                     $self->{zconf}->{error}."', errorString='".
		                     $self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return $self;
}

=head2 delSet

This removes the specified ZConf set.

    $foo->delSet('someSet');
    if($foo->{error}){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub delSet{
	my $self=$_[0];
	my $set=$_[1];
	my $method='init';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	$self->{zconf}->delSet($self->{zconfconfg}, $set);
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{errorString}='ZConf getAvailableSets failed. error="'.
		                     $self->{zconf}->{error}.'", errorString="'.
		                     $self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}


	return 1;
}

=head2 getZConf

This returns the ZConf object.

The only time this will error is if a permanent error is set.

    my $zconf=$foo->getZConf;
    if ($foo->error){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub getZConf{
	my $self=$_[0];
	my $method='getZConf';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	return $self->{zconf};
}

=head2 init

This initiates a new set. If a set already exists, it will be overwritten.

If the set specified is undefined, the default will be used.

The set is not automatically read.

    $foo->init($set);
    if($foo->{error}){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];
	my $method='init';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	#the that what will be used for creating the new ZConf config
	my %hash=();

	$self->{zconf}->writeSetFromHash({config=>$self->{zconfconfig}, set=>$set},\%hash);
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{errorString}='ZConf writeSetFromHash failed. error="'.
		                     $self->{zconf}->{error}.'", errorString="'.
		                     $self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return 1;
}

=head2 listSets

This lists the available sets for the ZConf config.

    my @sets=$foo->listSets;
    if($foo->{error}){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub listSets{
	my $self=$_[0];
	my $method='listSets';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets($self->{zconfconfig});
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{errorString}='ZConf getAvailableSets failed. error="'.
		                     $self->{zconf}->{error}.'", errorString="'.
		                     $self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return @sets;
}

=head2 readSet

This reads a specified ZConf set.

If no set is specified, the default is used.

    $foo->readSet('someSet');
    if($foo->{error}){
        warn('error '.$foo->error.': '.$foo->errorString);
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];
	my $method='readSet';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$method.': A permanent error is set. error="'.$self->{error}.'" errorString="'.$self->{errorString}.'"');
		return undef;
	}

	#read the config
	$self->{zconf}->read({config=>$self->{zconfconfig}, set=>$set});
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{errorString}='Failed to read the set. error="'.
		                     $self->{zconf}->{error}.'", errorString="'.
		                     $self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$method.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	return 1;
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

    $foo->{error}=undef;
    $foo->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	if ($self->{perror}) {
		warn('ZConf-DevTemplate errorblank: A permanent error is set');
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
}

=head2 ERROR CODES

=head3 1

ZConf errored.

=head1 AUTHOR

%%%%AUTHOR%%%, C<< <%%%EMAIL%%%> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::template


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-template>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-template/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 %%%AUTHOR%%%, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::template
