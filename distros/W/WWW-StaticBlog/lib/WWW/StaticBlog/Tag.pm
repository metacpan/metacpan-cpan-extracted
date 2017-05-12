package WWW::StaticBlog::Tag;

our $VERSION = '0.02';

use 5.010;
use Moose;
use MooseX::Method::Signatures;

our %existing_tags;
our $compendium;

use MooseX::Types::Moose qw(
    Str
    Undef
);

use WWW::StaticBlog::Util qw(
    sanitize_for_dir_name
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has url => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return '/tags/' . sanitize_for_dir_name($self->name()) . '/index.html';
    },
);

around new => sub {
    my $orig = shift;
    my $class = shift;

    if (@_ == 1 && ref $_[0]) {
        my $tag = _get_already_existing_tag($_[0]->{name})
            || $class->$orig(@_);
        _store_new_tag($tag);

        return $tag;
    }
    elsif (@_ > 1) {
        my %opts = @_;
        my $tag = _get_already_existing_tag($opts{name})
            || $class->$orig(@_);
        _store_new_tag($tag);

        return $tag;
    }
    else {
        my $tag = _get_already_existing_tag($_[0])
            || $class->$orig(name => $_[0]);
        _store_new_tag($tag);

        return $tag;
    }
};

sub _get_already_existing_tag
{
    my $tag_name = shift;
    return unless exists $WWW::StaticBlog::Tag::existing_tags{$tag_name};
    return $WWW::StaticBlog::Tag::existing_tags{$tag_name};
}

sub _store_new_tag
{
    my $new_tag = shift;
    $WWW::StaticBlog::Tag::existing_tags{$new_tag->name} = $new_tag;
}

method compendium($compendium?)
{
    $WWW::StaticBlog::Tag::compendium = $compendium
        if defined $compendium && UNIVERSAL::isa($compendium, 'WWW::StaticBlog::Compendium');

    return $WWW::StaticBlog::Tag::compendium;
}

method post_count()
{
    return unless $WWW::StaticBlog::Tag::compendium;

    return scalar $WWW::StaticBlog::Tag::compendium->posts_for_tags($self);
}

"No fair! You can't flash back to things we saw ten seconds ago!";

__END__

=head1 NAME

WWW::StaticBlog::Tag - Tags for posts.

=head1 VERSION

0.02

=head1 SYNOPSIS

Tags for posts.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StaticBlog>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc WWW::StaticBlog
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StaticBlog>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StaticBlog>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StaticBlog>


=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StaticBlog>


=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jacob Helwig, all rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
