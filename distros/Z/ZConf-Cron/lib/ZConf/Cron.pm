package ZConf::Cron;

use DateTime::Event::Cron;
use DateTime::Duration;
use DateTime::Format::Strptime;
use ZConf;
use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

ZConf::Cron - Handles storing cron tabs in ZConf.

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';

=head1 SYNOPSIS

    use ZConf::Cron;

    my $zccron = ZConf::Cron->new;
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }
    
    $zccron->runTab( $tab );
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=head1 METHODS

=head2 new

Initiates the module. No arguements are currently taken.

    my $zccron = ZConf::Cron->new;
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub new{
	my $self={
		error=>undef,
		perror=>undef,
		errorString=>'',
		zconfconfig=>'zccron',
	};
	bless $self;

	$self->{zconf}=ZConf->new();
	if(defined($self->{zconf}->error)){
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Could not initiate ZConf. It failed with '"
		                     .$self->{zconf}->error."', '".$self->{zconf}->errorString."'";
		$self->warn;
		return $self;
	}

	#sets $self->{init} to a Perl boolean value...
	#true=config does exist
	#false=config does not exist
	if (!$self->{zconf}->configExists("zccron")){
		$self->{init}=undef;
	}else {
		$self->{init}=1;
	}

	if ( ! $self->{init} ){
		$self->init;
		if ( $self->error ){
			$self->{perror}=1;
			return undef;
		}
	}

	$self->{zconf}->read( {config=>$self->{'zconfconfig'}} );
	if ( $self->{zconf}->error ){
		$self->{perror}=1;
		$self->{error}=3;
		$self->{errorString}='Failed to initialize ';
		$self->warn;
		return $self;
	}

	return $self;
}

=head2 delSet

This deletes a set.

    $zccron->delSet('someSet');
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub delSet{
	my $self=$_[0];
	my $set=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	$self->{zconf}->delSet( $self->{'zconfconfig'} ,$set);
	if ($self->{zconf}->error){
		$self->{errorString}='Failed to delete set. set="'.$set.
			'" error="'.$self->{zconf}->error.
			'" errorString="'.$self->{zconf}->errorString.'"';
		$self->{error}=10;
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 delTab

This removes a tab.

One arguement is taken and that is the tab to delete.

    $zccron->delTab('someTab');
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub delTab{
	my $self=$_[0];
	my $tab=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	$self->{zconf}->regexVarDel( $self->{'zconfconfig'} , '^tabs\/'.quotemeta($tab).'$');
	if ($self->{zconf}->error) {
		$self->{errorString}='Failed to delete tab, "'.$tab.'" error="'
			.$self->{zconf}->error.'" errorString="'.$self->{zconf}->errorString.'"';
		$self->{error}=11;
		$self->warn;
		return undef;
	}

	my $returned=$self->{zconf}->writeSetFromLoadedConfig(
		{
			config=>$self->{'zconfconfig'}
		}
		);
	if ($self->{zconf}->error){
		$self->{errorString}='Failed to save the ZConf config.'.
			'" error="'.$self->{zconf}->error.
			'" errorString="'.$self->{zconf}->errorString.'"';
		$self->{error}=7;
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 getTab

Gets a specified tab.

    my $tab=zccron->readTab("sometab");
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub getTab{
	my $self=$_[0];
	my $tab=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	$tab='tabs/'.$tab;

	#errors if the tab is not defined
	my $tabdata=$self->{zconf}->getVar( $self->{'zconfconfig'}, $tab );
	if (!defined( $tabdata )){
		$self->{errorString}='The tab "'.$tab.'" is not defined';
		$self->{error}=5;
		$self->warn;
		return undef;
	}

	return $tabdata;
}

=head2 init

Initializes a specified set.

If no set is specified, the default is used.

    $zccron->init('someSet');
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	#checks if it exists
	my $configExists = $self->{zconf}->configExists($self->{'zconfconfig'});

	#creates the config if needed
	if (!$configExists){
		$self->{zconf}->createConfig($self->{'zconfconfig'});
		if( $self->{zconf}->error ){
			$self->{errorString}='Failed to create the ZConf config "zccron"';
			$self->{error}=8;
			$self->warn;
			return undef;
		}
	}

	my $returned=$self->{zconf}->writeSetFromHash({config=>$self->{'zconfconfig'}, set=>$set},{});
	if ($self->{zconf}->error){
		$self->{errorString}='Failed to create set. set="'.$set.
			'" error="'.$self->{zconf}->error.
			'" errorString="'.$self->{zconf}->errorString.'"';
		$self->{error}=9;
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 listSets

This gets a list of of sets for the config 'cron'.

    my @sets=$zccron->getSets;
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub listSets{
	my $self=$_[0];
	my $function='getSets';

	$self->errorblank();
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	my @sets=$self->{zconf}->getAvailableSets( $self->{'zconfconfig'} );
	if ($self->{zconf}->error){
		$self->{errorString}='ZConf->getAvailableSets errored error="'.$self->{zconf}->error.
			'" errorString="'.$self->{zconf}->errorString.'"';
		$self->{error}=4;
		$self->warn;
		return undef;
	};

	return @sets;
}

=head2 listTabs

Gets a list of tabs for the current set.

    my @tabs=$zccron->listTabs();
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub listTabs{
	my $self=$_[0];

	if ( ! $self->errorblank ){
		return undef;
	}

	my @matched = $self->{zconf}->regexVarSearch( $self->{'zconfconfig'} , "^tabs\/");

	my $matchedInt=0;
	while (defined($matched[$matchedInt])){
		$matched[$matchedInt]=~s/^tabs\///;
		$matchedInt++;
	}

	return @matched;
}

=head2 runTab

This runs the specified tab.

One option is taken and that is the specified tab.

    $zccron->runTab( $tab );
    if ( $zccron->error ){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub runTab{
	my $self=$_[0];
	my $tabName=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}	

	if($self->{zconf}->varNameCheck($tabName)){
		$self->{errorString}="'".$tabName."' is not a legit ZConf variable name";
		$self->{error}=2;
		$self->warn;
		return undef;
	}		

	my $tab=$self->getTab( $tabName );
	if ( $self->error ){
		$self->warnString('getTab errored');
		return undef;
	}

	#splits the lines apart
	my @lines=split(/\n/, $tab);

	#runs each line
	my $linesInt=0;
	while (defined($lines[$linesInt])){
		if (!($lines[$linesInt] =~ /^#/)){

			my $cronline=$lines[$linesInt];
			my $now=DateTime->now;#get the time
			
			my $dtc = DateTime::Event::Cron->new_from_cron($cronline);
			my $next_datetime_string = $dtc->next;
			my $last_datetime_string = $dtc->previous;
			
			#takes the strings and make DateTime objects out of them.
			my $time_string_parse= new DateTime::Format::Strptime(pattern=>'%FT%T');
			my $dt_last=$time_string_parse->parse_datetime($last_datetime_string);
			my $dt_next=$time_string_parse->parse_datetime($next_datetime_string);
			
			#check to make sure last or next is within a minute and 15 seconds of now.
			my $interval = DateTime::Duration->new(minutes => 1);

			#if it falls within 1 minute and 15 secons of now, it runs it
			if (
				$self->within_interval($dt_last, $now, $interval) ||
				$self->within_interval($dt_next, $now, $interval)
				){		
				system($dtc->command);
			}

		}

		$linesInt++;
	}

	return 1;
}

=head2 setSet

Sets what set is being worked on. It will also read it when this is called.

    $zccron->setSet('someSet');
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub setSet{
	my $self=$_[0];
	my $set=$_[1];

	if ( ! $self->errorblank ){
		return undef;
	}

	if (!defined($set)){
		my $set=$self->{zconf}->chooseSet( $self->{'zconfconfig'} );
	}

	if(!$self->{zconf}->setNameLegit($set)){
		$self->{errorString}="'".$set."' is not a legit ZConf set name";
		$self->{error}=2;
		$self->warn;
		return undef;
	}

	$self->{zconf}->read(
		{
			config=>$self->{'zconfconfig'},
			set=>$set
		}
		);
	if($self->{zconf}->error){
		$self->{errorString}="Could not read config. set='".$set."'.  error='"
			.$self->{zconf}->error."' errorString='".$self->{zconf}->errorString."'";
		$self->{error}=3;
		$self->error;
		return undef;
	}

	return 1;
}

=head2 setTab

Saves a tab. The return is a Perl boolean value.

Two values are required. The first one is the name of the tab.
The second one is the value of the tab.

    $zccron->setTab("someTab", $tabValuexs);
    if($zccron->error){
        warn('Error:'.$zccron->error.': '.$zccron->errorString);
    }

=cut

sub setTab{
	my $self=$_[0];
	my $tab=$_[1];
	my $value=$_[2];

	if ( ! $self->errorblank ){
		return undef;
	}

	if (!defined($value)){
		$self->{errorString}="No value specified for the value of the tab.";
		$self->{error}=6;
		$self->warn;
		return undef;
	}

	if($self->{zconf}->varNameCheck($tab)){
		$self->{errorString}="'".$tab."' is not a legit ZConf variable name";
		$self->{error}=2;
		$self->warn;
		return undef;
	}

	#$self->{zconf}->{conf}{zccron}{'tabs/'.$tab}=$value;
	$tab='tabs/'.$tab;
	$self->{zconf}->setVar('zccron', $tab , $value);
	if ($self->{zconf}->error) {
		$self->{error}=12;
		$self->{errorString}='setVar failed. error="'.$self->{zconf}->error.'" errorString="'.$self->errorString.'"';
		$self->warn;
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'zccron'});
	if ($self->{zconf}->error){
		$self->{error}=10;
		$self->{errorString}='setVar failed. error="'.$self->{zconf}->error.'" errorString="'.$self->errorString.'"';
		$self->warn;
		return undef;
	}

	print "saved\n";

	return 1;
}

=head2 within_interval

This is a internal sub.

=cut

sub within_interval {
    my ($self, $dt1, $dt2, $interval) = @_;
	
    # Make sure $dt1 is less than $dt2
    ($dt1, $dt2) = ($dt2, $dt1) if $dt1 > $dt2;
	
    # If the older date is more recent than the newer date once we
    # subtract the interval then the dates are closer than the
    # interval
    if ($dt2 - $interval < $dt1) {
        return 1;
    } else {
        return 0;
    }
}

=head1 ZConf Keys

The keys for this are stored in the config 'zccron'.

=head2 tabs/<tab>

Any thing under tabs is considered a tab.

=head1 ERROR CODES/HANDLING

Error handling is provided by L<Error::Helper>.

=head2 1

Failed to intiate ZConf.

=head2 2

Illegal set name specified.

=head2 3

Could not read the ZConf config 'zccron'.

=head2 4

Failed to get the available sets for 'zccron'.

=head2 5

No tab specified.

=head2 6

No value for the tab specified.

=head2 7

Saving the ZConf config failed.

=head2 8

Failed to create the ZConf config 'zccron'.

=head2 9

Failed to create set.

=head2 10

Failed to delete the set.

=head2 11

Failed to delete the tab.

=head2 12

Failed to write the tab to ZConf.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-cron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Cron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Cron


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Cron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Cron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Cron>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Cron>

=item * SVN

L<http://eesdp.org/svnweb/index.cgi/pubsvn/browse/Perl/ZConf%3A%3ACron>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Cron
