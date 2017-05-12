package Text::Thesaurus::Aiksaurus;

use warnings;
use strict;
use String::ShellQuote;

=head1 NAME

Text::Thesaurus::Aiksaurus - The great new Text::Thesaurus::Aiksaurus!

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Text::Thesaurus::Aiksaurus;
    use Data::Dumper;
    
    my $ata=Text::Thesaurus::Aiksaurus->new;
    my %h=$ata->search('test');
    
    print join("\n", keys(%h));


=head1 METHODS

=head2 new

=cut

sub new {
	my $self={error=>undef, errorString=>undef};
	bless $self;

	return $self;
}

=head2 search

This searches the aiksaurus for the specified word.

    %returnedH=$ata->search($word);
    if($ata->{error}){
        #handles it if it errored
        print "It errored... ".$ata->{error};
    }else{
        my $int=0;
        if(defined($returnedH{'%misspelled'})){
            #handles it if it misspelled
            while(defined($returnedH{'%misspelled'}[$int])){
                print $returnedH{'%misspelled'}[$int]."\n";

                $int++;
            }
        }else{
            #handles it if it was not misspelled
            my @returnedHkeys=keys(%returnedH);
            while(defined($returnedHkeys[$int])){
               print $returnedHkeys[$int].":\n";

               my $int2==0;
               while(){
                    print '    '.$returnedH{$returnedHkeys[$int]}[$int2];
                    $int2++;
                }

                $int++;
            };
        }
    }

=cut

sub search{
	my $self=$_[0];
	my $word=$_[1];

	my $wordquote=shell_quote($word);

	my $search=`aiksaurus $wordquote`;
	my $exitcode=$? >> 8;

	#error if it got a -1... not in path
	if ($? == -1) {
		$self->{error}=1;
		$self->{errorString}='"aiksaurus" not found in the current path';
		warn('Text-Thesaurus-Aiksaurus search:1: '.$self->{errorString});
		return undef;
	}

	#error if it is something other than 0
	if (!($? == 0)) {
		$self->{error}=2;
		$self->{errorString}='"aiksaurus" exit with a non-zero';
		warn('Text-Thesaurus-Aiksaurus search:2: '.$self->{errorString});
		return undef;		
	}

	#used for holding the returned information
	my %returnedH;

	#split
	my @searchA=split(/\n/, $search);

	#this handles it if does not match it
	if ($searchA[0] =~ /^\*/) {
		my $int=2;

		$returnedH{'%misspelled'}=[];

		my $int2=0;
		while (defined($searchA[$int])) {
			$searchA[$int]=~s/^\t//g;

			$returnedH{'%misspelled'}[$int2]=$searchA[$int];
			
			$int2++;
			$int++;
		}

		return %returnedH;
	}

	#if we get here, it means it was matched and we should break it apart
	my $int=0;
	my $last='';
	while (defined($searchA[$int])) {
		#used for checking if it has been matched or not
		my $matched=0;

		if ($searchA[$int] =~ /^=/) {
			#removes the stuff around the word
			$searchA[$int]=~s/^=== //;
			$searchA[$int]=~s/ ===*//;

			#sets the last word
			$last=$searchA[$int];

			#creates the array that will hold the possibilities
			$returnedH{$last}=[];
		
			$matched=1;
		}

		#match the blank lines between words
		if ($searchA[$int] =~ /^$/) {
			$matched=1;
		}

		#if it is not matched at this point, it is a list of words
		if (!$matched) {
			my @words=split(/\,\ /, $searchA[$int]);

			my $int2=0;

			while (defined($words[$int2])) {
				$returnedH{$last}[$int2]=$words[$int2];

				$int2++;
			}
		}

		$int++;
	}

	return %returnedH;
}

=head2 errorblank

This is a internal function.

=cut

sub errorblank{
	$_[0]->{error}=undef;
	$_[1]->{errorString}='';
}

=head1 ERROR CODES

=head2 1

Failed to execute aiksaurus.

=head2 2

It exited with a non-zero status.

=head1 RETURNED HASH

If the only key in the returned has is '%misspelled', it aiksaurus
regards it as being mis-spelled. The key is a array of possible matches.

Each key in the returned hash is a main word containing various other ones
with similar meanings. Each key is a array containing the other words.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-thesaurus-aiksaurus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Thesaurus-Aiksaurus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Thesaurus::Aiksaurus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Thesaurus-Aiksaurus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Thesaurus-Aiksaurus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Thesaurus-Aiksaurus>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Thesaurus-Aiksaurus/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::Thesaurus::Aiksaurus
