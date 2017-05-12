package Text::SpellChecker::GUI::Curses;

use warnings;
use strict;
use ZConf::GUI;
use Curses::UI;
use String::ShellQuote;

=head1 NAME

Text::SpellChecker::GUI::Curses - Implements the Curses backend to Text::SpellChecker::GUI.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use Text::SpellChecker::GUI::Curses;

    my $sg = Text::SpellChecker::GUI::Curses->new();
    ...

=head1 METHODS

=head2 new

This initilizes the object.

=head3 args hash

=head4 useX

This is if it should try to use X or not. If it is not defined,
ZConf::GUI->useX is used.

=head4 zconf

This is the ZConf object to use. If it is not specified the one in the
object for zcrunner will be used. If neither zconf or zcrunner is specified,
a new one is created.

=head4 zcgui

This is the ZConf::GUI object. A new one will be created if it is

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>''};
	bless $self;

	#initilize the ZConf::GUI object if needed
	if (!defined($args{zcgui})) {
		if (!defined($args{zconf})) {
			$self->{zg}=ZConf::GUI->new();
		}else {
			$self->{zg}=ZConf::GUI->new({zconf=>$args{zconf}});
		}

		if ($self->{zg}->{error}) {
			$self->{errorString}='Failed to initilize the ZConf::GUI object. error="'.
			                     $self->{zg}->{error}.'" errorString="'
								 .$self->{zg}->{errorString}.'"';
			$self->{error}=1;
			warn('Text-SpellChecker-GUI new:1: '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{zg}=$args{zcgui};
	}

	#initilize the ZConf object if needed
	if (!defined($args{zconf})) {
		$self->{zconf}=$args{zconf};
	}else {
		$self->{zconf}=$self->{zg}->{zconf};
	}

	#as the GUI stuff is right below this module, use the module above this one
	$self->{useX}=$self->{zg}->useX('Text::SpellChecker');

	$self->{terminal}='xterm -rv -e ';
	#if the enviromental variable 'TERMINAL' is set, use 
	if(defined($ENV{TERMINAL})){
		$self->{terminal}=$ENV{TERMINAL};
	}

	return $self;
}

=head2 check

This checks the specified the specified text for spelling errors.

Only one option is taken and that is the text to be checked.

The returned value is a hash.

=head3 returned hash

=head4 text

This is the the resulting text.

=head4 cancel

If this is defined and true, then the user canceled the check and any changes.

    my %returned=$sg->check($text);
    if($sg->{error}){
        print "Error!\n";
    }else{
        if($returned{cancel}){
            print "The check was canceled.";
        }else{
            $text=$returned{text};
        }
    }

=cut

sub check{
	my $self=$_[0];
	my $text=$_[1];

	$self->errorblank;
	
	my %toreturn;

	#dump this 
	my $file='/tmp/'.rand().rand().rand();
	open(CHECKWRITE, '>', $file);
	print CHECKWRITE $text;
	close(CHECKWRITE);

	#the command to be run
	my $command='curses-textspellchecker -f '.$file;
	if ($self->{useX}) {
		$command=$self->{terminal}.shell_quote($command);
	}	

	system($command);
	my $exitcode=$? >> 8;

		#error if it got a -1... not in path
	if ($? == -1) {
		$self->{error}=2;
		$self->{errorString}='"curses-textspellchecker" or the terminal is not in the path.';
		warn('Text-SpellChecker-GUI-Curses check:2: '.$self->{errorString});
		$toreturn{text}=$text;
		$toreturn{code}=2;
		return %toreturn;
	}

	if ($? == 0) {
		if (open(READFH, $file)){
			my @textA=<READFH>;
			close(READFH);
			$toreturn{text}=join('', @textA);
		}else {
			$toreturn{text}=$text;
			$toreturn{code}=3;
		}

		return %toreturn;
	}

	if ($exitcode == 230) {
		$toreturn{text}=$text;
		$toreturn{exitcode}=$exitcode;
		$toreturn{cancel}=1;
		return %toreturn;
	}

	#error if it is something other than 0
	if (!($? == 0)) {
		$toreturn{text}=$text;
		$toreturn{code}=$exitcode;

		$self->{error}=3;
		$self->{errorString}='The backend script exited with a non-zero, "'.$exitcode.'"';
		warn('Text-SpellChecker-GUI-Curses check:3: '.$self->{errorString});
		return %toreturn;		
	}

	return %toreturn;
}

=head2 dialogs

This returns the available dailogs.

=cut

sub dialogs{
	return ('check');
}

=head2 windows

This returns a list of available windows.

=cut

sub windows{
	return undef;
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

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1 ERROR CODES

=head2 1

Failed to initiate ZConf::GUI.

=head2 2

Failed to find the required commands in the path.

=head2 3

Failed to read temp file.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-spellchecker-gui at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-SpellChecker-GUI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::SpellChecker::GUI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-SpellChecker-GUI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-SpellChecker-GUI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-SpellChecker-GUI>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-SpellChecker-GUI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::SpellChecker::GUI::Curses
