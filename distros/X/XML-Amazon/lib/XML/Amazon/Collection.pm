package XML::Amazon::Collection;
$XML::Amazon::Collection::VERSION = '0.14';
use strict;
use warnings;
use utf8;

sub new {
    my $pkg = shift;
    my $data = {
        total_results => undef,
        total_pages => undef,
        current_page => undef,
        collection => []
    };
    bless $data, $pkg;
    return $data;
}

sub add_Amazon {
    my $self = shift;
    my $add_data = shift;

    if(ref $add_data ne "XML::Amazon::Item") {
        warn "add_Amazon called with type ", ref $add_data;
        return undef;
    }
    push @{$self->{collection}}, $add_data;
}

sub total_results {
    my $self = shift;
    return $self->{total_results};
}

sub total_pages {
    my $self = shift;
    return $self->{total_pages};
}

sub current_page {
    my $self = shift;
    return $self->{current_page};
}

sub collection {
    my $self = shift;
    my @list;
    LIST: for my $el (@{$self->{collection}}) {
        if (! $el) {
            last LIST;
        }
        push @list, $el;
    }
    return @list;
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

Constructor

=head2 $self->add_Amazon($item)

Add item to the collection.

=head2 $self->current_page()

Returns the current page.

=head2 $self->total_pages()

Returns the count of total pages.

=head2 $self->total_results()

Returns the total results.

=head2 $self->collection()

Returns a flattened array of the collection.

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
