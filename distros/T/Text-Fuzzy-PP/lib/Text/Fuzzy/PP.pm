package Text::Fuzzy::PP;
use strict;
use warnings;
use utf8;
require Exporter;

our @ISA = qw(Exporter); 
our @EXPORT = qw/distance_edits/;
our $VERSION   = '0.01';

# Get away with some XS for speed if available...
local $@;
eval { require List::Util; };
unless ($@) {
    *min = \&List::Util::min;
}
else {
    *min = \&_min;
}
 
sub new {
    my ($class,$source,%args) = @_;
    
    my $self  = {
        source                => $source,
        _last_distance        => undef,
        _length_rejections    => 0,        
        _ualphabet_rejections => 0,        
        _no_alphabet          => 0,
        length                => length($source),
        no_exact              => defined($args{'no_exact'}) ? delete($args{'no_exact'}) : 0,
        trans                 => defined($args{'trans'})    ? delete($args{'trans'})    : 0,
        max_distance          => defined($args{'max'})      ? delete($args{'max'})      :-1,
    };

    bless( $self, $class );

    return $self;
}

sub _no_alphabet {
    my ($self,$onoff) = @_;
    $self->{_no_alphabet} = $onoff if ($onoff == 0 || $onoff == 1);
}

sub get_trans {
    my $self = shift;
    return $self->{trans};
}

sub ualphabet_rejections {
    my $self = shift;
    return $self->{_ualphabet_rejections};
}

sub length_rejections {
    my $self = shift;
    return $self->{_length_rejections};
}

sub unicode_length {
    my $self = shift;
    return length $self->{source};
}

sub last_distance {
    my $self = shift;
    return $self->{_last_distance};    
}

sub set_max_distance {
    my ($self,$max) = @_;
    # set_max_distance() with no args = no max
    $max = -1 if (!defined $max);
    $self->{max_distance} = $max if ($max >= -1);
}

sub get_max_distance {
    my $self = shift;
    return ($self->{max_distance} == -1)?undef:$self->{max_distance};
}

sub transpositions_ok {
    my ($self,$onoff) = @_;
    $self->{trans} = $onoff if ($onoff == 0 || $onoff == 1);
}

sub no_exact {
    my ($self,$onoff) = @_;
    $self->{no_exact} = $onoff if ($onoff == 0 || $onoff == 1);
}

sub distance {
    my ($self,$target,$max) = @_;

    if($self->{source} eq $target) {
        return $self->{no_exact}?undef:0;
    }

    # $max overrides our objects max_distance
    # allows nearest() to change he max_distance dynamically for speed
    $max = defined($max)?$max:$self->{max_distance};

    my $target_length = length($target);

    return ($self->{length}?$self->{length}:$target_length) 
        if(!$target_length || !$self->{length});

    # pass the string lengths to keep from calling length() again later
    if( $self->{trans} ) {
        my $score = _damerau($self->{source},$self->{length},$target,$target_length,$max);
        return ($score > 0)?$score:undef;
    }
    else {
        my $score = _levenshtein($self->{source},$self->{length},$target,$target_length,$max);
        return ($score > 0)?$score:undef;
    }
}

sub nearest {
    my ($self,$words) = @_;

    if ( ref $words eq ref [] ) {
        my $max = $self->{max_distance};
        my $best_index = undef;

        for ( 0 .. $#{ $words } ) {
            # compatability
            if( $max != -1 && abs($self->{length} - length($words->[$_])) > $max ) {
                $self->{_length_rejections}++;
                next;
            }

            # compatability
            if ( $max != -1 && _alphabet_difference($self->{source},$words->[$_]) > $max) {
                $self->{_ualphabet_rejections}++;
                next;
            }


            my $d = $self->distance($words->[$_], $max);

            if( !defined($d) ) {
                # no_exact => 1 match or $d > $max
            }
            elsif( $max == -1 || $d < $max ) {  
                # better match found
                $self->{_last_distance} = $max = $d;
                $best_index = $_;
            }
        }

        return $best_index;
    }
}

1;

sub _levenshtein {
    my ($source,$source_length,$target,$target_length,$max_distance) = @_;

    my @scores;;
    my ($i,$j,$large_value);

    if ($max_distance >= 0) {
        $large_value = $max_distance + 1;
    }
    else {
        if ($target_length > $source_length) {
            $large_value = $target_length;
        }
        else {
            $large_value = $source_length;
        }
    }

    for ($j = 0; $j <= $target_length; $j++) {
        $scores[0][$j] = $j;
    }

    for ($i = 1; $i <= $source_length; $i++) {
        my ($col_min,$next,$prev);
        my $c1    = substr($source,$i-1,1);
        my $min_j = 1;
        my $max_j = $target_length;

        if ($max_distance >= 0) {
            if ($i > $max_distance) {
                $min_j = $i - $max_distance;
            }
            if ($target_length > $max_distance + $i) {
                $max_j = $max_distance + $i;
            }
        }

        $col_min = $large_value;
        $next = $i % 2;

        if ($next == 1) {
            $prev = 0;
        }
        else {
            $prev = 1;
        }

        $scores[$next][0] = $i;

        for ($j = 1; $j <= $target_length; $j++) {
            if ($j < $min_j || $j > $max_j) {
                $scores[$next][$j] = $large_value;
            }
            else {
                my $c2 = substr($target,$j-1,1);

                if ($c1 eq $c2) {
                    $scores[$next][$j] = $scores[$prev][$j-1];
                }
                else {
                    my $delete     = $scores[$prev][$j] + 1;#[% delete_cost %];
                    my $insert     = $scores[$next][$j-1] + 1;#[% insert_cost %];
                    my $substitute = $scores[$prev][$j-1] + 1;#[% substitute_cost %];
                    my $minimum    = $delete;

                    if ($insert < $minimum) {
                        $minimum = $insert;
                    }
                    if ($substitute < $minimum) {
                        $minimum = $substitute;
                    }
                    $scores[$next][$j] = $minimum;
                }
            }

            if ($scores[$next][$j] < $col_min) {
                $col_min = $scores[$next][$j];
            }
        }

        if ($max_distance >= 0) {
            if ($col_min > $max_distance) {
                return -1;
            }
        }
    }

    return $scores[$source_length % 2][$target_length];
}

sub _damerau {
    my ($source,$source_length,$target,$target_length,$max_distance) = @_;
    
    my $lengths_max = $source_length + $target_length;
    my ($swap_count,$swap_score,$target_char_count);          
    my $dictionary_count = {};    #create dictionary to keep character count
    my @scores;              

    # init values outside of work loops
    $scores[0][0] = $scores[1][0] = $scores[0][1] = $lengths_max;
    $scores[1][1] = 0;
 
    # Work Loops
    foreach my $source_index ( 1 .. $source_length ) {
        $swap_count = 0;
        $dictionary_count->{ substr( $source, $source_index - 1, 1 ) } = 0;
        $scores[ $source_index + 1 ][1] = $source_index;
        $scores[ $source_index + 1 ][0] = $lengths_max;

        foreach my $target_index ( 1 .. $target_length ) {
            if ( $source_index == 1 ) {
                $dictionary_count->{ substr( $target, $target_index - 1, 1 ) } = 0;
                $scores[1][ $target_index + 1 ] = $target_index;
                $scores[0][ $target_index + 1 ] = $lengths_max;
            }

            $target_char_count =
              $dictionary_count->{ substr( $target, $target_index - 1, 1 ) };
            $swap_score = $scores[$target_char_count][$swap_count] +
                  ( $source_index - $target_char_count - 1 ) + 1 +
                  ( $target_index - $swap_count - 1 );

            if (
                substr( $source, $source_index - 1, 1 ) ne
                substr( $target, $target_index - 1, 1 ) )
            {
                $scores[ $source_index + 1 ][ $target_index + 1 ] = min(
                    $scores[$source_index][$target_index]+1,
                    $scores[ $source_index + 1 ][$target_index]+1,
                    $scores[$source_index][ $target_index + 1 ]+1,
                    $swap_score
                );
            }
            else {
                $swap_count = $target_index;

                $scores[ $source_index + 1 ][ $target_index + 1 ] = min(
                  $scores[$source_index][$target_index], $swap_score
                );
            }
        }

        # This is where the $max_distance check goes ideally, but it doesn't pass tests
        #if ( $max_distance != -1 && $max_distance < $scores[ $source_index + 1 ][ $target_length + 1 ] )
        #{
        #    return -1;
        #}

        $dictionary_count->{ substr( $source, $source_index - 1, 1 ) } =
          $source_index;
    }

    return -1 if ($max_distance != -1 && $scores[ $source_length + 1 ][ $target_length + 1 ] > $max_distance);
    return $scores[ $source_length + 1 ][ $target_length + 1 ]; 
}

# this function is very unoptimized
sub _alphabet_difference {
    my $source = shift;
    my $target = shift;
    my %dict;
    my $missing = 0;

    for (0 .. length($source)) {
        my $char = substr($source,$_,1);
        $missing++ if(!exists $dict{$char} && $target !~ $char);
        $dict{$char} = 1;
    }

    return $missing;
}

sub _min {
    my $min = shift;
    return $min if not @_;

    my $next = shift;
    unshift @_, $min < $next ? $min : $next;
    goto &_min;
}

__END__

=encoding utf8

=head1 NAME

Text::Fuzzy::PP - partial or fuzzy string matching using edit distances (Pure Perl)

=head1 SYNOPSIS

    use Text::Fuzzy::PP;
    my $tf = Text::Fuzzy::PP->new ('boboon');
    print "Distance is ", $tf->distance ('babboon'), "\n";
    # Prints "Distance is 2"
    my @words = qw/the quick brown fox jumped over the lazy dog/;
    my $nearest = $tf->nearest (\@words);
    print "Nearest array entry is ", $words[$nearest], "\n";
    # Prints "Nearest array entry is brown"

=head1 DESCRIPTION

This module is a drop in, pure perl, substitute for L<Text::Fuzzy>. All 
documentation is taken directly from L<Text::Fuzzy>.

This module calculates the Levenshtein edit distance between words,
and does edit-distance-based searching of arrays and files to find the
nearest entry. It can handle either byte strings or character strings
(strings containing Unicode), treating each Unicode character as a
single entity.

It is designed for high performance in searching for the nearest to a
particular search term over an array of words or a file, by reducing
the number of calculations which needs to be performed.

It supports either bytewise edit distances or Unicode-based edit distances:

    use utf8;
    my $tf = Text::Fuzzy::PP->new ('あいうえお☺');
    print $tf->distance ('うえお☺'), "\n";
    # prints "2".

The default edit distance is the Levenshtein edit distance, which
applies an equal weight of one to additions (C<cat> -> C<cart>),
substitutions (C<cat> -> C<cut>), and deletions (C<carp> ->
C<cap>). Optionally, the Damerau-Levenshtein edit distance, which
additionally allows transpositions (C<salt> -> C<slat>) may be
selected using the method L</transpositions_ok>.

=head1 METHODS

=head2 new

    my $tf = Text::Fuzzy::PP->new ('bibbety bobbety boo');

Create a new Text::Fuzzy::PP object from the supplied word.

=head2 distance

    my $dist = $tf->distance ($word);

Return the edit distance to C<$word> from the word used to create the
object in L</new>.

=head2 nearest

    my $index = $tf->nearest (\@words);

This returns the index of the nearest element in the array to the
argument to L</new>. If none of the elements are less than the maximum
distance away from the word, C<$index> is -1.

    if ($index >= 0) {
        printf "Found at $index, distance was %d.\n",
            $tf->last_distance ();
    }

Use L</set_max_distance> to alter the maximum distance used.

If there is more than one word with the same distance in C<@words>,
this returns the first of them.

=head2 last_distance

    my $last_distance = $tf->last_distance ();

The distance from the previous match closest match. This is used in
conjunction with L</nearest> to find the edit distance to the previous
match.

=head2 set_max_distance

    # Set the max distance.
    $tf->set_max_distance (3);

Set the maximum edit distance of C<$tf>. The default maximum distance
is 10. Set the maximum distance to a low value to improve the speed
of searches over lists with L</nearest>, or to reject unlikely
matches. When searching for a near match, anything with an edit
distance of a value at least as high as the maximum is rejected
without computing the exact distance. To compute exact distances, call
this method with zero or undefined, the maximum edit distance is
switched off, and whatever the nearest match is is accepted.

=head2 get_max_distance

    # Get the maximum edit distance.
    print "The max distance is ", $tf->get_max_distance (), "\n";

Get the maximum edit distance of C<$tf>. The default is set to 10. The
maximum distance may be set with L</set_max_distance>.

=head2 scan_file

    $tf->scan_file ('/usr/share/dict/words');

Scan a file to find the nearest match to the word used in
L</new>. This assumes that the file contains lines of text separated
by newlines and finds the closest match in the file.

This does not currently support Unicode-encoded files.

=head2 transpositions_ok

    $tf->transpositions_ok (1);

A true value in the argument changes the type of edit distance used to
allow transpositions, such as C<clam> and C<calm>. Initially
transpositions are not allowed, giving the Levenshtein edit
distance. If transpositions are used, the edit distance becomes the
Damerau-Levenshtein edit distance. A false value disallows
transpositions:

    $tf->transpositions_ok (0);

=head1 PRIVATE METHODS

These methods are not expected to be useful for the general user. They
may be useful in benchmarking the module and checking its correctness.

=head2 no_alphabet

    $tf->no_alphabet (1);

This turns off alphabetizing of the string. Alphabetizing is a filter
used in L</nearest> where the intersection of all the characters in
the two strings is computed, and if the alphabetical difference of the
two strings is greater than the maximum distance, the match is
rejected without applying the dynamic programming algorithm. This
increases speed, because the dynamic programming algorithm is
slow. 

The alphabetizing should not ever reject anything which is a
legitimate match, and it should make the program run faster in almost
every case. The only envisaged uses of switching this off are checking
that the algorithm is working correctly, and benchmarking performance.

=head2 get_trans

    my $trans_ok = $tf->get_trans ();

This returns the value set by L</transpositions_ok>.

=head2 unicode_length

    my $length = $tf->unicode_length ();

This returns the length in characters (not bytes) of the string used
in L</new>. If the string is not marked as Unicode, it returns the
undefined value. In the following, C<$l1> should be equal to C<$l2>.

    use utf8;
    my $word = 'ⅅⅆⅇⅈⅉ';
    my $l1 = length $word;
    my $tf = Text::Fuzzy::PP->new ($word);
    my $l2 = $tf->unicode_length ();

=head2 ualphabet_rejections

    my $rejected = $tf->ualphabet_rejections ();

After running L</nearest> over an array, this returns the number of
entries of the array which were rejected using only the alphabet. Its
value is reset to zero each time L</nearest> is called.

=head2 length_rejections

    my $rejected = $tf->length_rejections ();

After running L</nearest> over an array, this returns the number of
entries of the array which were rejected because the length difference
between them and the target string was larger than the maximum
distance allowed.

=head1 ACKNOWLEDGEMENTS

L<Text::Fuzzy> is authored by Ben Bullock (BKB). The levenshtein algorithm, 
the documentation, and Text::Fuzzy's tests were taken directly from Text::Fuzzy.

=head1 BUGS

Please report bugs to:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Fuzzy-PP>

=head1 AUTHOR

Nick Logan <F<ugexe@cpan.org>>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut



