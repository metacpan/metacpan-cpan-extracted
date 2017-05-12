use MooseX::Declare;

class WWW::StaticBlog::Author
{
    our $VERSION = '0.02';

    use Config::JFDI ();

    has name => (
        is      => 'ro',
        isa     => 'Str|Undef',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return unless $self->has_filename;
            return $self->get_config('name');
        },
    );

    has email => (
        is      => 'ro',
        isa     => 'Str|Undef',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return unless $self->has_filename;
            return $self->get_config('email');
        },
    );

    has alias => (
        is       => 'ro',
        isa      => 'Str|Undef',
        lazy     => 1,
        default  => sub {
            my $self = shift;
            return unless $self->has_filename;
            return $self->get_config('alias');
        },
    );

    has config => (
        is         => 'ro',
        traits     => ['Hash'],
        isa        => 'HashRef|Undef',
        lazy_build => 1,
        handles    => {
            exists_in_config => 'exists',
            get_config       => 'get',
        },
    );

    has filename => (
        is        => 'ro',
        isa       => 'Str|Undef',
        predicate => 'has_filename',
    );

    method _build_config()
    {
        die 'Tried to build WWW::StaticBlog::Author from file, without a filename.'
            unless $self->has_filename();

        my $config = Config::JFDI->new(
            file          => $self->filename(),
            no_06_warning => 1,
        );

        return $config->get();
    }
}

#"Dinsdale, He was a nice boy...... He nailed my head to a coffee table.";
#"1943, an ewok makes it behind German lines.";
__END__

=head1 NAME

WWW::StaticBlog::Author - An Author of a Post.

=head1 VERSION

0.02

=head1 SYNOPSIS

An Author of a Post.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at
rt.cpan.org>, or through the web interface at
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
