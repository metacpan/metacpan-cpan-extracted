=head1 NAME

Unicode::Emoji::E4U - Emoji mappings based on emoji4unicode project

=head1 SYNOPSIS

    use Unicode::Emoji::E4U;

    my $e4u = Unicode::Emoji::E4U->new;

    # fetch data files from Google Code (default)
    $e4u->datadir('http://emoji4unicode.googlecode.com/svn/trunk/data/');

    # or load from local cached files
    $e4u->datadir('data');

    my $docomo   = $e4u->docomo;    # Unicode::Emoji::DoCoMo instance
    my $kddi     = $e4u->kddi;      # Unicode::Emoji::KDDI instance
    my $softbank = $e4u->softbank;  # Unicode::Emoji::SoftBank instance
    my $google   = $e4u->google;    # Unicode::Emoji::Google instance

    my $kddiweb  = $e4u->kddiweb;   # alias to $e4u->kddi

=head1 DESCRIPTION

This module provides emoji picture characters cross-mapping table
base on emoji4unicode, Emoji for Unicode, project on Google Code:
L<http://code.google.com/p/emoji4unicode/>

This has the following accessor methods.

=head2 datadir

To fetch data files from emoji4unicode project repository on Google Code. (default)

    $e4u->datadir('http://emoji4unicode.googlecode.com/svn/trunk/data/');

To load data files cached on local path.

    $e4u->datadir('data');

=head2 treepp

This returns L<XML::TreePP> instance to parse data files.

    $e4u->treepp->set(user_agent => 'Mozilla/4.0 (compatible; ...)');

=head2 docomo

This returns L<Unicode::Emoji::DoCoMo> instance.

=head2 kddi

This returns L<Unicode::Emoji::KDDI> instance.

=head2 softbank

This returns L<Unicode::Emoji::SoftBank> instance.

=head2 google

This returns L<Unicode::Emoji::Google> instance.

=head2 kddiweb

This returns L<Unicode::Emoji::KDDI> instance as an alias for C<kddi>.

=head1 LINKS

=over 4

=item * Subversion Trunk

L<http://emoji4unicode-ll.googlecode.com/svn/trunk/lang/perl/Unicode-Emoji-E4U/trunk/>

=item * Project Hosting on Google Code

L<http://code.google.com/p/emoji4unicode-ll/>

=item * Google Groups and some Japanese documents

L<http://groups.google.com/group/emoji4unicode-ll>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unicode-Emoji-E4U>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Unicode-Emoji-E4U>

=item * Search CPAN

L<http://search.cpan.org/dist/Unicode-Emoji-E4U/>

=back

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::E4U;
use Unicode::Emoji::Google;
use Unicode::Emoji::DoCoMo;
use Unicode::Emoji::KDDI;
use Unicode::Emoji::SoftBank;
use Any::Moose;
extends 'Unicode::Emoji::Base';
has google   => (is => 'rw', isa => 'Unicode::Emoji::Google',   lazy_build => 1);
has docomo   => (is => 'rw', isa => 'Unicode::Emoji::DoCoMo',   lazy_build => 1);
has kddi     => (is => 'rw', isa => 'Unicode::Emoji::KDDI',     lazy_build => 1);
has kddiweb  => (is => 'rw', isa => 'Unicode::Emoji::KDDI',     lazy_build => 1);
has softbank => (is => 'rw', isa => 'Unicode::Emoji::SoftBank', lazy_build => 1);

our $VERSION = '0.03';

sub _build_google {
    my $self = shift;
    Unicode::Emoji::Google->new($self->clone_config);
}

sub _build_docomo {
    my $self = shift;
    Unicode::Emoji::DoCoMo->new($self->clone_config);
}

sub _build_kddi {
    my $self = shift;
    Unicode::Emoji::KDDI->new($self->clone_config);
}

sub _build_kddiweb {
    $_[0]->kddi;        # alias
}

sub _build_softbank {
    my $self = shift;
    Unicode::Emoji::SoftBank->new($self->clone_config);
}

__PACKAGE__->meta->make_immutable;
