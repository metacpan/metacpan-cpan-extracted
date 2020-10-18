package WordList::Password::RockYou;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordList-Password-RockYou'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(WordList);

our $SORT = 'popularity';
our $DYNAMIC = 1;

our %STATS = (
    'num_words' => 14344391,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{fh_seekable} = 0;
    $self;
}

sub first_word {
    require File::ShareDir;

    my $self = shift;

    my $dir;
    eval { $dir = File::ShareDir::dist_dir('WordList-Password-RockYou') };
    if ($@) {
        $dir = "share";
    }
    (-d $dir) or die "Can't find share dir";
    my $path = "$dir/wordlist.txt.gz";
    (-f $path) or die "Can't find wordlist file '$path'";
    open my $fh, "<:gzip", $path
        or die "Can't open wordlist file '$path': $!";
    $self->{fh} = $fh;
    $self->{fh_orig_pos} = 0;
    chomp(my $word = scalar <$fh>);
    $word;
}

1;
# ABSTRACT: RockYou password wordlist (~14.3mil passwords)

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Password::RockYou - RockYou password wordlist (~14.3mil passwords)

=head1 VERSION

This document describes version 0.001 of WordList::Password::RockYou (from Perl distribution WordList-Password-RockYou), released on 2020-05-24.

=head1 DESCRIPTION

This class' C<word_exists()> uses linear search which is unusably slow. For
quick checking against wordlist, see L<WordList::Password::RockYou::BloomOnly>
which uses bloom filter.

=head1 METHODS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Password-RockYou>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Password-RockYou>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Password-RockYou>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
