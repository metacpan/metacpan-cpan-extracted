package Text::SpellChecker::GUI;

use warnings;
use strict;
use ZConf::GUI;
use ZConf;

=head1 NAME

Text::SpellChecker::GUI - Implements a user interface to Text::SpellChecker

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    use Text::SpellChecker::GUI;

    my $sg = Text::SpellChecker::GUI->new();
    ...

=head1 METHODS

=head2 new

This initilizes the object.

=head3 args hash

=head4 zconf

This is the ZConf object to use. If it is not specified the one in the
object for zcrunner will be used. If neither zconf or zcrunner is specified,
a new one is created.

=head4 zcgui

This is the ZConf::GUI to use. If one is not specified,


=cut

sub new {
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

	my @preferred=$self->{zg}->which('Text::SpellChecker');

	my $toeval='use Text::SpellChecker::GUI::'.$preferred[0].';'."\n".
	           '$self->{be}=Text::SpellChecker::GUI::'.$preferred[0].
			   '->new({zconf=>$self->{zconf}, useX=>$self->{useX}, '.
			   'zcgui=>$self->{zg} }); return 1';

	my $er=eval($toeval);

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

	if (!defined($self->{be})) {
		$self->{errorString}='Backend is not initilized';
		$self->{error}=2;
		warn('Text-SpellChecker-GUI check:2: '.$self->{errorString});
		return undef;
	}

	%toreturn=$self->{be}->check($text);

	return %toreturn;
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

Failed to initiate the object.

=head2 2

Backend is not initilized.

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

1; # End of Text::SpellChecker::GUI
