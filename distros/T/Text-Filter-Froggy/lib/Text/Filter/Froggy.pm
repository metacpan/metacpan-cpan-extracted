package Text::Filter::Froggy;

use warnings;
use strict;
use Text::Thesaurus::Aiksaurus;
use Text::Autoformat qw(autoformat);

=head1 NAME

Text::Filter::Froggy - the frog goes rabbit rabbit rabbit

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use Text::Filter::Froggy;

    my $froggy = Text::Filter::Froggy->new();

    #read standard in and process it
    my @lines=<STDIN>;
    print $froggy->process(join('', @lines));

This takes a chunk of text and filters it. It will remove all
new lines, camas, semicolons, colons, single quotes, and double
quotes. Once it does it will search through the words and choose
some random words and replace them using a random selection from
Aiksaurus.

In regards to the Aiksaurus part, it ignores 'the', 'them', 'who',
'was', 'when', 'that', 'this', 'we', 'want', and 'what'.

=head1 METHODS

=head2 new

This initiates it.

=head3 args hash

=head4 hi

This is the is the random chance that will replace the
text with "hi\n". The default value is 5 and values between
0 and 100 are accepted.

=head4 minL

This is the minimum length for a word to be replaced. The
default is 5.

=head4 maxL

This is the max length for a word to be replaced. The
default is 20.

=head4 replaceP

This is the percentage that any of the words fitting in the
length restriction will be replaced. The default is 50.

=head4 maxR

This is the maximum number of words of words that will be replaced.

=head4 wrap

If this is defined, it should bethe number of columns to wrap the text to.

    #initiates it a a replaceP value of 30
    my $froggy=Text::Filter::Froggy->new({replaceP=>30})

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>'', hi=>5, minL=>5,
			  maxL=>20, replaceP=>50, maxR=>20};
	bless $self;

    if (defined($args{hi})) {
		$self->{hi}=$args{hi};
	}

    if (defined($args{minL})) {
		$self->{minL}=$args{minL};
	}

    if (defined($args{maxL})) {
		$self->{maxL}=$args{maxL};
	}

    if (defined($args{replaceP})) {
		$self->{replaceP}=$args{replaceP};
	}

    if (defined($args{maxR})) {
		$self->{maxR}=$args{maxR};
	}

    if (defined($args{wrap})) {
		$self->{wrap}=$args{wrap};
	}

	return $self;
}

=head2 process

This processes a chunk of text.

    my $text=$froggy->process($text);
    if($froggy->{error}){
        print "Error!\n";
    }

=cut

sub process{
	my $self=$_[0];
	my $text=$_[1];

	if (!defined($text)) {
		$self->{errorString}='No text specified';
		$self->{error}=1;
		warn('Text-Filter-Froggy process:1: '.$self->{errorString});
		return undef;
	}

	$text=lc($text);

	my $random=rand(100);
	
	if ($random <= $self->{hi}) {
		return "hi\n";
	}

	#remove all punctuation
	$text=~s/\.//g;
	$text=~s/\,//g;
	$text=~s/\;//g;
	$text=~s/\://g;
	$text=~s/\'//g;
	$text=~s/\"//g;

	#make sure it is all jumbled
	$text=~s/\n/ /g;

	#words to ignore
	my %ignore;
	$ignore{'the'}=1;
	$ignore{'them'}=1;
	$ignore{'who'}=1;
	$ignore{'was'}=1;
	$ignore{'that'}=1;
	$ignore{'this'}=1;
	$ignore{'we'}=1;
	$ignore{'want'}=1;
	$ignore{'what'}=1;

	#count the instances of various words
	my @words=split(/ /, $text);
	my %count;
	my $int=0;
	while (defined($words[$int])) {
		#make sure it is within the specified word length
		if ((length($words[$int]) > $self->{minL}) && (length($words[$int]) < $self->{maxR})) {
			#make sure it is not a ignored word
			if (!$ignore{$words[$int]}) {
				#build the word count
				if ($count{$words[$int]}) {
					$count{$words[$int]}=1;
				}else {
					$count{$words[$int]}++;
				}
			}
		}

		$int++;
	}
	
	#handles replacing some words with random words from a thesaurus
	my $replaceInt=0;
	$int=0;
	my @countKeys=keys(%count);
	my $ata=Text::Thesaurus::Aiksaurus->new;
	my $choosen=0;
	while (defined($countKeys[$int])) {
		$random=rand(100);
			
		#
		if (($random <= $self->{replaceP}) && ($choosen <= $self->{maxR})) {
			my %returnH=$ata->search($countKeys[$int]);
			if (defined($returnH{'%misspelled'})) {
				my $max=$#{$returnH{'%misspelled'}};
				my $replace=$returnH{'%misspelled'}[sprintf("%.0f", rand($max))];
				my $regex=quotemeta($countKeys[$int]);
				
				$text=~s/^$regex /$replace /g;
				$text=~s/ $regex / $replace /g;
				$text=~s/ $regex$/ $replace/g;

			}else {
				my @returnHkeys=keys(%returnH);
				my $max=$#returnHkeys;
				my $word1=$returnHkeys[sprintf("%.0f", rand($max) - 1)];
				
				$max=$#{$returnH{$word1}};
				my $replace=$returnH{$word1}[sprintf("%.0f", rand($max) - 1)];

				my $regex=quotemeta($countKeys[$int]);
				
				$text=~s/^$regex /$replace /g;
				$text=~s/ $regex / $replace /g;
				$text=~s/ $regex$/ $replace/g;
			}
		}
		$choosen++;
				
		$int++;
	}

	if (defined($self->{wrap})) {
		$text = autoformat($text, { left=>0, right=>$self->{wrap} });
	}

	return $text;
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

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-filter-froggy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Filter-Froggy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Filter::Froggy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Filter-Froggy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Filter-Froggy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Filter-Froggy>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Filter-Froggy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::Filter::Froggy
