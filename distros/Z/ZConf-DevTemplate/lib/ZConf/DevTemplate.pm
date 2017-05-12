package ZConf::DevTemplate;

use warnings;
use strict;
use ZConf::template;
use ZConf::template::GUI;
use String::ShellQuote;

=head1 NAME

ZConf::DevTemplate - Creates a the basic framework for a ZConf based module.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

    use ZConf::DevTemplate;

    my $zcdt = ZConf::DevTemplate->new();


=head1 METHODS

=head2 new

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	
	my $self={error=>undef, perror=>undef,  errorString=>undef, module=>'ZConf-DevTemplate'};
	bless $self;

	return $self;
}

=head2 create

This creates a new module.

=head3 args hash

=head4 name

This is the name of the module.

=head4 email

This is the email address of the author.

=head4 author

This is author's name.

=head4 config

This is the ZConf config the module will use.

    my $module=$zcdt->processGUI({
                       name=>'Some::Module',
                       email=>'foo@bar',
                       author=>'Foo Bar',
                       config=>'someModule',
                       });
    if($zcdt->{error}){
        print "Error!\n";
    }

=cut

sub create{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='create';

	$self->errorblank;

	#make sure a name is specified
	if (!defined( $args{name} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the module specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{email} )) {
		$self->{error}=1;
		$self->{errorString}='No email for author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{config} )) {
		$self->{error}=1;
		$self->{errorString}='No ZConf config specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{author} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#creates the module stuff
	system('module-starter --module='.shell_quote($args{name}).' --email='.shell_quote($args{email}).' --author='.shell_quote($args{author}));

	#processes the module
	my $module=$self->processTemplate(\%args);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': processTemplate errored');
		return undef;
	}

	#processes the GUI
	my $gui=$self->processGUI(\%args);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': processGUI errored');
		return undef;
	}

	#writes out the module stuff
	my $modulepath=$args{name}.'/lib/';
	$modulepath=~s/\:\:/\-/g;
	my $modulepath2=$args{name};
	$modulepath2=~s/\:\:/\//g;
	$modulepath=$modulepath.$modulepath2.'.pm';
	open(MODULE, '>', $modulepath);
	print MODULE $module;
	close(MODULE);

	#writes out the GUI stuff
	my $guipath=$args{name}.'/lib/';
	$guipath=~s/\:\:/\-/g;
	my $guipath2=$args{name};
	$guipath2=~s/\:\:/\//g;
	mkdir($guipath.$guipath2);
	$guipath=$guipath.$guipath2.'/GUI.pm';
	open(GUI, '>', $guipath);
	print GUI $gui;
	close(GUI);

	return 1;
}

=head2 processGUI

This processes 'ZConf::template::GUI' and returns a string
containing the module.

It takes one arguement and that is a hash.

=head3 args hash

=head4 name

This is the name of the module.

=head4 email

This is the email address of the author.

=head4 author

This is author's name.

=head4 config

This is the ZConf config the module will use.

    my $module=$zcdt->processGUI({
                       name=>'Some::Module',
                       email=>'foo@bar',
                       author=>'Foo Bar',
                       config=>'someModule',
                       });
    if($zcdt->{error}){
        print "Error!\n";
    }

=cut

sub processGUI{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='processGUI';

	$self->errorblank;

	#make sure a name is specified
	if (!defined( $args{name} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the module specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{email} )) {
		$self->{error}=1;
		$self->{errorString}='No email for author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{config} )) {
		$self->{error}=1;
		$self->{errorString}='No ZConf config specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{author} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @lines;
	if (open(TEMPLATE, $INC{'ZConf/template/GUI.pm'})) {
		my $line=<TEMPLATE>;
		while (defined($line)) {
			push(@lines, $line);
			$line=<TEMPLATE>;
		}
		close(TEMPLATE);
	}else {
		$self->{error}=2;
		$self->{errorString}='Failed to open "ZConf::template::GUI"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;		
	}

	#put it together
	my $toreturn=join('', @lines);

	#replace the module name
	my $regex='ZConf\:\:template\:\:GUI';
	my $new=$args{name}.'::GUI';
	$toreturn=~s/$regex/$new/g;

	#replaces parent as well
	$regex='ZConf\:\:template';
	$new=$args{name};
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex=quotemeta('ZConf-template-GUI');
	$new=$args{name}.'::GUI';
	$new=~s/\:\:/\-/g;
	$toreturn=~s/$regex/$new/g;

	#replaces parent module info
	$regex='\%\%\%PARENT\%\%\%';
	$new=$args{name};
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex='\%\%\%EMAIL\%\%\%';
	$new=$args{email};
	$new=~s/\@/ at /g;
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex='\%\%\%ZCONFCONFIG\%\%\%';
	$toreturn=~s/$regex/$args{config}/g;

	#replaces other name
	$regex='\%\%\%AUTHOR\%\%\%';
	$toreturn=~s/$regex/$args{author}/g;

	return $toreturn;
}

=head2 processTemplate

This processes 'ZConf::template' and returns
a string containing the new module.

It takes one arguement and that is a hash.

=head3 args hash

=head4 name

This is the name of the module.

=head4 email

This is the email address of the author.

=head4 author

This is author's name.

=head4 config

This is the ZConf config the module will use.

    my $module=$zcdt->processTemplate({
                       name=>'Some::Module',
                       email=>'foo@bar',
                       author=>'Foo Bar',
                       config=>'someModule',
                       });
    if($zcdt->{error}){
        print "Error!\n";
    }

=cut

sub processTemplate{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='processTemplate';

	$self->errorblank;

	#make sure a name is specified
	if (!defined( $args{name} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the module specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{email} )) {
		$self->{error}=1;
		$self->{errorString}='No email for author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{config} )) {
		$self->{error}=1;
		$self->{errorString}='No ZConf config specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a name is specified
	if (!defined( $args{author} )) {
		$self->{error}=1;
		$self->{errorString}='No name for the author specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @lines;
	if (open(TEMPLATE, $INC{'ZConf/template.pm'})) {
		my $line=<TEMPLATE>;
		while (defined($line)) {
			push(@lines, $line);
			$line=<TEMPLATE>;
		}
		close(TEMPLATE);
	}else {
		$self->{error}=2;
		$self->{errorString}='Failed to open "ZConf::template"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;		
	}

	#put it together
	my $toreturn=join('', @lines);

	#replace the module name
	my $regex='ZConf\:\:template';
	my $new=$args{name};
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex=quotemeta('ZConf-template');
	$new=$args{name};
	$new=~s/\:\:/\-/g;
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex='\%\%\%EMAIL\%\%\%';
	$new=$args{email};
	$new=~s/\@/ at /g;
	$toreturn=~s/$regex/$new/g;

	#replaces other name
	$regex='\%\%\%ZCONFCONFIG\%\%\%';
	$toreturn=~s/$regex/$args{config}/g;

	#replaces other name
	$regex='\%\%\%AUTHOR\%\%\%';
	$toreturn=~s/$regex/$args{author}/g;

	return $toreturn;
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

	if ($self->{perror}) {
		warn('ZConf-DevTemplate errorblank: A permanent error is set');
		return undef;
	}

	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
}

=head1 ERROR CODES

=head2 1

Missing arguement.

=head2 2

Could not open 'ZConf::template';

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-devtemplate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-DevTemplate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::DevTemplate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-DevTemplate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-DevTemplate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-DevTemplate>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-DevTemplate/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::DevTemplate
