package Text::Sentence::Alignment;

use warnings;
use strict;
use List::Util qw(max min);

=head1 NAME

Text::Sentence::Alignment - Two Sentence Alignment

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

This Module process two sentences (i.e. terms separated by space) alignment.
Now it provide two kind of alignment method, Global and Local Alignment.

    use Text::Sentence::Alignment;

    my $TSA = Text::Sentence::Alignment->new();

    # local alignment
    $TSA->is_local(1);
    my ($result1,$result2) = $TSA->do_alignment($s1,$s2); 

    # global alignment
    $TSA->is_local(0);
    my ($result1,$result2) = $TSA->do_alignment($s1,$s2); 

=head1 FUNCTIONS

=cut 

=head2 new
    
=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{IS_LOCAL} = 0; # 0 for global alignment
    $self->{DELIMETER} = '/'; # / for split tags
    $self->{TABLE} = (); # Dynamic Programming Table
    $self->{BEST} = (); # Best path, for local
    $self->{max_len} = 0; # for global
    $self->{SENARR1} = [];
    $self->{SENARR2} = [];
    $self->{has_tag} = 0; # if we need to do hierarchy match, 
			  # e.g. POS, semantic tags
    bless($self, $class);
    return($self);
}

=head2 is_local
    
Set/get if current algorithm is local alignment

=cut

sub is_local {
    my $self = shift;
    if (@_) { $self->{IS_LOCAL} = shift }
    return $self->{IS_LOCAL}
}

=head2 delimeter

The delimeter() is used to set delimeter of word/tags.

=cut

sub delimeter {
    my $self = shift;
    if (@_) { $self->{DELIMETER} = shift }
    return $self->{DELIMETER}
}

=head2 do_alignment
    
=cut

sub do_alignment {
    my $self = shift;
    my $sen1 = shift;
    my $sen2 = shift;
    @{ $self->{SENARR1} } = split / /,$sen1;
    @{ $self->{SENARR2} } = split / /,$sen2;
    if ($sen1 =~ m/$self->{DELIMETER}/ or 
	$sen2 =~ m/$self->{DELIMETER}/) {
	$self->{has_tag} = 1;
    }
    $self->{TABLE} = ();
    $self->{BEST} = ();
    $self->{BEST}{MAX} = 0;
    $self->{TABLE}{0}{0} = 0;
    calculate_matrix($self);
#    similarity_print();
    return get_align_result($self);
}

=head2 calculate_matrix
    
=cut

sub calculate_matrix {
    my $self = shift;
    my @sa1 = @{ $self->{SENARR1}};
    my @sa2 = @{ $self->{SENARR2}};
    if ($self->{IS_LOCAL}) {
	$self->{max_len}= 0;
    } else {
	$self->{max_len} = scalar(@sa1) > scalar(@sa2) ? scalar(@sa1): scalar(@sa2); # for global
    }
    my ($len_s1, $len_s2) = (0,0); # length of s1/s2

#    print STDERR "max_len is ".$max_len."\n";
    while ($len_s1 <= (scalar @sa1)) {
	while ($len_s2 <= scalar @sa2) {
	    my ($candidate1, $candidate2, $candidate3) = ($self->{max_len},$self->{max_len},$self->{max_len});
	    if ($len_s1 > 0 and $len_s2 > 0) {
		# if match, we add 1 for local, 0 for global
		# else (not matched), we add -1 for local, 1 for global
		$candidate1 = int($self->{TABLE}{$len_s1-1}{$len_s2-1}) + 
		    ( $self->{IS_LOCAL} ? 1: -1) *
			( $self->{has_tag} ? 
			    how_similar($sa1[$len_s1-1], $sa2[$len_s2-1]) :
			    ( ( $sa1[$len_s1-1] eq $sa2[$len_s2-1] ) ? 
				1+(-1+$self->{IS_LOCAL}) : -1 )
			)
		;
	    }
	    if ($len_s1 > 0) {
		$candidate2 = int($self->{TABLE}{$len_s1-1}{$len_s2}) + 
		    ( $self->{IS_LOCAL} ? (-1) : 1);
	    }
	    if ($len_s2 > 0) {
		$candidate3 = int($self->{TABLE}{$len_s1}{$len_s2 - 1})  + 
		    ( $self->{IS_LOCAL} ? (-1) : 1);
	    }
#	    print STDERR "setting ($len_s1,$len_s2)...";
#	    print STDERR "(".$candidate1."\t".$candidate2."\t".$candidate3.")\n";
	    if ($self->{IS_LOCAL}) {
		$self->{TABLE}{$len_s1}{$len_s2} = max (
		    $candidate1, $candidate2, $candidate3, 0
		) if ($len_s1 > 0 or $len_s2 > 0);
		$self->{BEST}{X} = $len_s1 if $self->{BEST}{MAX} <= $self->{TABLE}{$len_s1}{$len_s2};
		$self->{BEST}{Y} = $len_s2 if $self->{BEST}{MAX} <= $self->{TABLE}{$len_s1}{$len_s2};
		$self->{BEST}{MAX} = $self->{TABLE}{$len_s1}{$len_s2} if $self->{BEST}{MAX} <= $self->{TABLE}{$len_s1}{$len_s2};
	    } else { # global
		$self->{TABLE}{$len_s1}{$len_s2} = min (
		    $candidate1, $candidate2, $candidate3
		) if ($len_s1 > 0 or $len_s2 > 0);
	    }
	    $len_s2 +=1;
	}
	$len_s2 = 0;
	$len_s1 +=1;
    }
}

=head2 similarity_print

=cut

sub similarity_print {
    my $self = shift;
    my @sa1 = @{ $self->{SENARR1}};
    my @sa2 = @{ $self->{SENARR2}};
    print STDERR "\n \t \t".join("\t",@sa2)."\n";
    for my $key (sort {int($a) <=> int($b)}(keys %{$self->{TABLE}})) {
	print STDERR $sa1[$key-1]."\t" if $key > 0;
	print STDERR " \t" unless $key > 0;
	for my $subkey (sort {int($a) <=> int($b)} (keys %{$self->{TABLE}{$key}})) {
	    print STDERR $self->{TABLE}{$key}{$subkey}."\t";
	}
	print STDERR "\n";
    }
};

=head2 get_align_result

=cut

sub get_align_result {
    my $self = shift;
    my @sa1 = @{ $self->{SENARR1}};
    my @sa2 = @{ $self->{SENARR2}};
    my ($i, $j) = (0, 0);
    my (@as1, @as2);
    my $baseline = 0;
    my $first_round = 0;
    if ($self->{IS_LOCAL}) {
	$i = $self->{BEST}{X};
	$j = $self->{BEST}{Y};
    } else {
	$i = scalar @sa1;
	$j = scalar @sa2;
    }
    my $pi = $i + 2;
    my $pj = $j + 2;
    do { 
	if ($first_round) {
	    push @as1, $sa1[$i];
	    push @as2, $sa2[$j];
	    $first_round = 0;
	} else {
	    if ($i == ($pi-1)) {
		push @as1, $sa1[$i];
	    }
	    elsif ($i == $pi) {
		push @as1, "-";
	    }
	    if ($j == ($pj-1)) {
		push @as2, $sa2[$j];
	    }
	    elsif ($j == $pj) {
		push @as2, "-";
	    }
	}
	$pi = $i;
	$pj = $j;
	if ($self->{IS_LOCAL}) { 
	    $baseline = max($self->{TABLE}{$i-1}{$j-1},$self->{TABLE}{$i-1}{$j},$self->{TABLE}{$i}{$j-1});
	} else {
	    $baseline = min($self->{TABLE}{$i-1}{$j-1},$self->{TABLE}{$i-1}{$j},$self->{TABLE}{$i}{$j-1});
	}
	if ($self->{TABLE}{$i-1}{$j-1} == $baseline) {
	    $i--;
	    $j--;
	} elsif ($self->{TABLE}{$i}{$j-1} == $baseline) {
	    $j--;
	} elsif ($self->{TABLE}{$i-1}{$j} == $baseline) {
	    $i--;
	} else {
	    die $!;
	}
    } while ( $self->{TABLE}{$pi}{$pj} > 0 and $i >0 and $j > 0);
    if (!$self->{IS_LOCAL}) {
	push @as1, $sa1[$i];
	push @as2, $sa2[$j];
    }
    return ( join (" ",reverse @as1)."\t".join (" ",reverse @as2) );
}

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-sentence-alignment@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Sentence-Alignment>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 - 2007 Cheng-Lung Sung, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::Sentence::Alignment
