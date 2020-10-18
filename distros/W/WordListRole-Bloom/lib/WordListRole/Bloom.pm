package WordListRole::Bloom;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordListRole-Bloom'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;
use Role::Tiny;

sub word_exists {
    no strict 'refs';

    require MIME::Base64;

    my ($self, $word) = @_;

    my $class = $self->{orig_class} || ref($self);


    my $bloom = ${"$class\::BLOOM_FILTER"};

    unless ($bloom) {
        my $dist = ${"$class\::DIST"};
        my $dir;
        if ($dist) {
            # if we are loading the installed version of module
            require File::ShareDir;
            eval { $dir = File::ShareDir::share_dir($dist) };
        }
        unless ($dir) {
            # if we are loading the dev version of module
            (my $classpm = "$class.pm") =~ s!::!/!g;
            if ($INC{$classpm} && $INC{$classpm} =~ m!.+/!) {
                $dir = $INC{$classpm};
                $dir =~ s!(.+)/.+!$1!;
                my $num_dcolons = 0; $num_dcolons++ while $class =~ /::/g;
                $dir .= ("/.." x ($num_dcolons + 1)) . "/share";
            }
        }
        die "Can't find share directory for $class" unless $dir;
        die "No such share directory '$dir' for $class" unless -d $dir;
        my $path = "$dir/bloom";
        die "Can't find bloom filter data file in '$path'" unless -f $path;
        my $bloom_str = do {
            local $/;
            open my $fh, "<", $path or die "Can't read bloom filter data file '$path': $!";
            scalar <$fh>;
        };

        require Algorithm::BloomFilter;
        ${"$class\::BLOOM_FILTER"} = $bloom =
            Algorithm::BloomFilter->deserialize($bloom_str);
    }

    $bloom->test($word);
}

1;
# ABSTRACT: Provide word_exists() that uses bloom filter

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::Bloom - Provide word_exists() that uses bloom filter

=head1 VERSION

This document describes version 0.006 of WordListRole::Bloom (from Perl distribution WordListRole-Bloom), released on 2020-05-24.

=head1 SYNOPSIS

In your F<lib/WordList/EN/Foo.pm>:

 package WordList::EN::Foo;

 use parent 'WordList';

 use Role::Tiny::With;
 with 'WordListRole::Bloom';

 __DATA__
 word1
 word2
 ...

In your F<share/bloom>, create your bloom filter data file, e.g. with
L<bloomgen>:

 % perl -ne 'print if (/^__DATA__$/ .. 0) && $i++' lib/WordList/EN/Foo.pm | \
   bloomgen -n 1234 -p 0.1% > share/bloom

(where C<-n> is set to the number of words, C<-p> to the maximum false-positive
rate).

After that, in F<yourscript.pl>:

 my $wl = WordList::EN::Foo->new;
 $wl->word_exists("foo"); # uses bloom filter to check for existence.

=head1 DESCRIPTION

This role provides an alternative C<word_exists()> method that checks a bloom
filter located in the distribution share directory (F<share/bloom>). This
provides a low startup-overhead way to check an item against a big list (e.g.
millions). Note that testing using a bloom filter can result in a false positive
(i.e. C<word_exists()> returns true but the word is not actually in the list.

=head1 PROVIDED METHODS

=head2 word_exists

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListRole-Bloom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListRole-Bloom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListRole-Bloom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
