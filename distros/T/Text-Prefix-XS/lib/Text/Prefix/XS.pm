package Text::Prefix::XS;
use XSLoader;
use strict;
use warnings;

our ($VERSION, @ISA);

BEGIN {
 $VERSION = '0.15';
 require DynaLoader;
 push @ISA, 'DynaLoader';
 __PACKAGE__->bootstrap($VERSION);
}

use base qw(Exporter);

our @EXPORT = qw(
    prefix_search_build
    prefix_search_create
    prefix_search
    prefix_search_multi
);

#sub import {
#    #Sub::Op::enable(psearch => scalar caller);
#    goto &Exporter::import;
#}
#
#sub unimport {
#    #Sub::Op::disable(psearch => scalar caller);
#    goto &Exporter::unimport;
#}
#

sub prefix_search_create(@)
{
    my @copy = @_;
    @copy = sort { length $b <=> length $a || $a cmp $b } @copy;
    return prefix_search_build(\@copy);
}


"MOVE EVERY ZIG!!!";

__END__

=head1 NAME

Text::Prefix::XS - Fast prefix searching

=head1 SYNOPSIS

    use Text::Prefix::XS;
    
    my @haystacks = qw(
        garbage
        blarrgh
        FOO-stuff
        meh
        AA-ggrr
        AB-hi!
    );
    
    my @prefixes = qw(AAA AB FOO FOO-BAR);
    
    my $search = prefix_search_create( map uc($_), @prefixes );
    
    my %seen_hash;
    
    foreach my $haystack (@haystacks) {
        if(my $prefix = prefix_search($search, $haystack)) {
            $seen_hash{$prefix}++;
        }
    }
    
    $seen_hash{'FOO'} == 1;
    
    {
        %seen_hash = ();
        my $re = join('|', map quotemeta $_, @prefixes);
        $re = qr/^($re)/;
        
        foreach my $haystack (@haystacks) {
            my ($match) = ($haystack =~ $re);
            if($match) {
                $seen_hash{$match}++;
            }
        }
        $seen_hash{'FOO'} == 1;
    }
    
    #Super fast:
    
    my $match_results = prefix_search_multi($search, @haystacks);
    grep $_ eq 'FOO-stuff', @{ $match_results->{FOO} };

=head1 DESCRIPTION

This module implements a variety of algorithms to ensure fast prefix matching.

It is particularly high performant with pessimistic matching (when a match is
unlikely), but is still faster than other methods with optimistic matching (when
a match is likely).

A common application I had was to pre-filter lots and lots of text for a small
amount of preset prefixes.

Interestingly enough, the quickest solution until I wrote this module was to use
a large regular expression (as in the synopsis)

=head1 FUNCTIONS

The interface is relatively simple. This is alpha software and the API is subject
to change

=head2 prefix_search_create(@prefixes)

Create an opaque prefix search handle. It returns a thingy, which you should
keep around.

Each prefix must be no longer than 256 I<bytes>. For normal ASCII strings, this
should be the number of characters - but does not hold true for encodings like
UTF8.

=head2 prefix_search($thingy, $haystack)

Will check C<$haystack> for any of the prefixes in C<@prefixes> passed to
L</prefix_search_create>. If C<$haystack> has a prefix, it will be returned by
this function; otherwise, the return value is C<undef>.

Input strings can be text or random byte sequences (any is acceptable)

=head2 prefix_search_multi($thingy, @haystacks)

B<EXTREMELY FAST!!!>

Will check each item in C<@haystacks> for any of the C<@prefixes> passed to
L</prefix_search_create>. The return value is a hash reference. Its keys are matched
prefix strings, and its values are array references containing items from C<@haystacks>
which matched.

This function is extremely fast. It's four times quicker than the normal
L</prefix_search> function (which is itself about twice as fast as any other
method).

However, it will not gain a lot of performance benefit with optimistic searching
(meaning that a match has a good chance of being found), and will just consume
more memory (since it needs to store the results in a hash).


=head1 PERFORMANCE

In most normal use cases, C<Text::Prefix::XS> will outperform any other module
or search algorithm.

Specifically, this module is intended for a pessimistic search mechanism,
where most of the input is assumed not to match (which is usually the case anyway).

The ideal position of C<Text::Prefix::XS> would reside between raw but delimited
user input, and more complex searching and processing algorithms. This module
acts as a layer between those.

In addition to a trie, this module also uses a very fast sparse array to check
characters in the input against an index of known characters at the given
position. This is much quicker than a hash lookup.

See the C<trie.pl> script included with this distribution for detailed benchmark
comparison methods

Here are a bunch of numbers. The entries are in the format of

    [capture (Y/N)] NAME DURATION MATCHES
    
Where C<capture> means whether the test was also able to return the prefix which
matched. C<MATCHES> is the amount of matches returned.

Additionally, each test has a few parameters defining the input. These are:

=over

=item C<TERMS>

The amount of search terms

=item C<TERM_MIN>

The minimum length of a term

=item C<TERM_MAX>

The maximum length of a term

=item INPUT

The count of input strings which will be checked to see if they are prefixed with
any of the C<TERMS>. The strings are each exactly one character longer than
C<TERM_MAX>

=back

Sample input is taken by making a C<sha1_hex> string of each number from 0
until C<TERMS>, and then encoding that output into Base64, ensuring that
both the terms and the input get a diversity of the ASCII charset.


A few methods were benchmarked, and are listed as keys:

=over

=item C<TMFA>

L<Text::Match::FastAlternatives> C<match_at> function

=item C<perl-re>

Generic perl regex. The capturing version is C<qr/^(term1|term2)/>,
and the non-capturing version is C<qr/^(?:term1|term2)/>, where the terms
are joined together in a C<list2re> fashion.

=item C<RE2>

Same as C<perl-re>, except using L<re::engine::RE2>

=item C<TXS>

Using a loop of L</prefix_search> over the input items

=item C<TXS-Multi>

Using a single function call to L</prefix_search_multi>

=back


    Generated INPUT=2000000 TERMS=20 TERM_MIN=3 TERM_MAX=6
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.12s	M=23578
    [N] perl-re    	1.24s	M=23578
    [N] RE2        	0.91s	M=23578
    [Y] perl-re    	1.44s	M=23578
    [Y] RE2        	2.91s	M=23578
    [Y] TXS        	0.53s	M=23578
    [Y] TXS-Multi  	0.18s	M=23578
    
    Generated INPUT=2000000 TERMS=50 TERM_MIN=10 TERM_MAX=16
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.14s	M=50
    [N] perl-re    	1.20s	M=50
    [N] RE2        	0.90s	M=50
    [Y] perl-re    	1.43s	M=50
    [Y] RE2        	1.10s	M=50
    [Y] TXS        	0.53s	M=50
    [Y] TXS-Multi  	0.17s	M=50
    
    Generated INPUT=2000000 TERMS=49 TERM_MIN=2 TERM_MAX=16
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.18s	M=241799
    [N] perl-re    	1.44s	M=241799
    [N] RE2        	1.01s	M=241799
    [Y] perl-re    	1.77s	M=241799
    [Y] RE2        	4.94s	M=241799
    [Y] TXS        	1.47s	M=241799
    [Y] TXS-Multi  	1.15s	M=241799


    Generated INPUT=2000000 TERMS=10 TERM_MIN=5 TERM_MAX=10
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.12s	M=131
    [N] perl-re    	1.27s	M=131
    [N] RE2        	0.97s	M=131
    [Y] perl-re    	1.50s	M=131
    [Y] RE2        	2.76s	M=131
    [Y] TXS        	0.46s	M=131
    [Y] TXS-Multi  	0.09s	M=131

    Generated INPUT=2000000 TERMS=100 TERM_MIN=3 TERM_MAX=25
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.15s	M=15734
    [N] perl-re    	1.26s	M=15734
    [N] RE2        	0.94s	M=15734
    [Y] perl-re    	1.49s	M=15734
    [Y] RE2        	1.69s	M=15734
    [Y] TXS        	1.06s	M=15734
    [Y] TXS-Multi  	0.68s	M=15734
    
    Generated INPUT=2000000 TERMS=200 TERM_MIN=5 TERM_MAX=25
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.15s	M=1300
    [N] perl-re    	1.22s	M=1300
    [N] RE2        	1.00s	M=1300
    [Y] perl-re    	1.43s	M=1300
    [Y] RE2        	1.27s	M=1300
    [Y] TXS        	0.73s	M=1300
    [Y] TXS-Multi  	0.24s	M=1300

    Generated INPUT=2000000 TERMS=8 TERM_MIN=2 TERM_MAX=5
    CAP   NAME       DUR	MATCH
    [N] TMFA       	1.12s	M=88025
    [N] perl-re    	1.22s	M=88025
    [N] RE2        	0.82s	M=88025
    [Y] perl-re    	1.64s	M=88025
    [Y] RE2        	1.13s	M=88025
    [Y] TXS        	0.63s	M=88025
    [Y] TXS-Multi  	0.27s	M=88025

    
I've mainly tested this on Debian's 5.10 - for newer perls, this module performs
better, and for el5 5.8, The differences are a bit lower. TBC


=head1 SEE ALSO 

There are quite a few modules out there which aim for a Trie-like search, but
they are all either not written in C, or would not be performant enough for this
application.

These two modules are implemented in pure perl, and are not part of the comparison.

L<Text::Trie>

L<Regexp::Trie>

L<Regexp::Optimizer>

L<Text::Match::FastAlternatives>

L<re::engine::RE2>


=head1 CAVEATS

=head2 Threads

As of version 0.15, threads are fully supported.

=head2 Optimistic Matching

The performance gains from this algorithm are less when matches are more likely
(optimistic). Nevertheless, when matches are likely, chances are you want to
figure out what it was that matched - in which case the performance benefits are
still reaped - as this is the fastest performing capturing method.

Do not use L</prefix_search_multi> with optimistic matching, as it will provide
minimal speed boosts and increase your memory usage.

In the future, an interface to provide a function callback would be handy - but
in the case of optimistic matching, would be bad for performance as well

=head2 Prefix Lengths

Prefixes may not exceed 256 bytes. You can increase this limit
(at the cost of more memory) by changing the C<#define> of
C<CHARTABLE_MAX> in the XS code and recompiling.

=head2 UTF-8 Support

Doing some basic tests with C<use utf8;> and non-ascii input, it seems to work
as expected. The character tables and prefix tries work at the byte level, so
no conversion is done for you. This is usually not an issue, but I am no unicode
expert, so nag me if you find something wrong

=head2 Many Prefixes

In the case where the prefix count becomes insanely high (i.e. over 5,000), the 
performance of this module will begin to drop. This could probably be solved in 
the future by a bunch of different methods. Even at a 10,000 prefix count, it 
still remains on-par with perl regular expressions.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2011 M. Nunberg

You may use and distribute this software under the same terms, conditions, and
licensing as Perl itself.

