package XML::Amazon::Item;
$XML::Amazon::Item::VERSION = '0.14';
use strict;
use warnings;
use utf8;

sub new {
    my($pkg, %options) = @_;

    bless {
        title => $options{'title'},
        authors => $options{'authors'},
        artists => $options{'artists'},
        creators => $options{'creators'},
        directors => $options{'directors'},
        actors => $options{'actors'},
        type => $options{'type'},
        url => $options{'url'},
        smallimage => $options{'smallimage'},
        mediumimage => $options{'mediumimage'},
        largeimage => $options{'largeimage'},
        publisher => $options{'publisher'},
        price => $options{'price'},
    }, $pkg;
}

sub creators_all {
    my $self = shift;
    my @list;
    for (my $i; $self->{authors}->[$i]; $i++){
        push @list, $self->{authors}->[$i];
    }
    for (my $i; $self->{artists}->[$i]; $i++){
        push @list, $self->{artists}->[$i];
    }
    for (my $i; $self->{creators}->[$i]; $i++){
        push @list, $self->{creators}->[$i];
    }
    return @list;
}

sub made_by {
    my $self = shift;
    my @list;
    for (my $i; $self->{authors}->[$i]; $i++){
        push @list, $self->{authors}->[$i];
    }
    for (my $i; $self->{artists}->[$i]; $i++){
        push @list, $self->{artists}->[$i];
    }

    for (my $i; $self->{creators}->[$i]; $i++){
        push @list, $self->{creators}->[$i];
    }

    for (my $i; $self->{directors}->[$i]; $i++){
        push @list, $self->{directors}->[$i];
    }

    for (my $i; $self->{actors}->[$i]; $i++){
        push @list, $self->{actors}->[$i];
    }


    my %tmp;
    @list = grep(  !$tmp{$_}++, @list );

    return @list;
}

sub authors {
    my $self = shift;
    my @list;
    for (my $i; $self->{authors}->[$i]; $i++){
        push @list, $self->{authors}->[$i];
    }
    return @list;
}

sub artists {
    my $self = shift;
    my @list;
    for (my $i; $self->{artists}->[$i]; $i++){
        push @list, $self->{artists}->[$i];
    }
    return @list;
}

sub creators {
    my $self = shift;
    my @list;
    for (my $i; $self->{creators}->[$i]; $i++){
        push @list, $self->{creators}->[$i];
    }
    return @list;
}

sub publisher {
    my $self = shift;
    return $self->{publisher};
}

sub asin {
    my $self = shift;
    return $self->{asin};
}

sub title {
    my $self = shift;
    return $self->{title};
}

sub author {
    my $self = shift;
    return @{$self->authors}[0];
}

sub image {
    my $self = shift;
    my $size = shift;

    return $self->{smallimage} if $size eq 's';
    return $self->{mediumimage} if $size eq 'm';
    return $self->{largeimage} if $size eq 'l';

}

sub url {
    my $self = shift;
    return $self->{url};
}

sub type {
    my $self = shift;
    return $self->{type};
}

sub price {
    my $self = shift;
    return $self->{price};
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.14

=head1 VERSION

version 0.14

=head1 METHODS

=head2 new

Constructor.

=head2 asin

Accessor.

=head2 author

Returns the first author.

=head2 authors

Returns a flattend list of all authors.

=head2 creators

Returns a flattend list of all creators.

=head2 creators_all

All creators authors and artists.

=head2 artists

Accessors. Returns a flattened list.

=head2 $obj->image('s' | 'm' | 'l')

Returns an image of the size.

=head2 made_by

Similar to creators_all.

=head2 price

Accessor.

=head2 publisher

Accessor.

=head2 title

Accessor.

=head2 type

Accessor.

=head2 url

Accessor.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Amazon>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Amazon>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Amazon>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Amazon>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Amazon>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Amazon>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-amazon at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Amazon>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-Amazon>

  git clone git://github.com/shlomif/perl-XML-Amazon.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-Amazon/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shlomi Fish.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Amazon>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Amazon>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Amazon>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Amazon>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Amazon>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Amazon>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-amazon at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Amazon>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-Amazon>

  git clone git://github.com/shlomif/perl-XML-Amazon.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-Amazon/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shlomi Fish.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
