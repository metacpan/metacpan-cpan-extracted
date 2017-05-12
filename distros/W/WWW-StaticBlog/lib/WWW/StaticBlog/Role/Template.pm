use MooseX::Declare;

role WWW::StaticBlog::Role::Template
{
    our $VERSION = '0.02';

    use Class::MOP;

    has template_class => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has options => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );

    has template_engine => (
        is         => 'ro',
        isa        => 'Object',
        lazy_build => 1,
    );

    has fixtures => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );

    requires 'render';
    requires 'render_to_file';
    requires '_build_template_engine';
}

__END__

=head1 NAME

WWW::StaticBlog::Role::FileLoader - Role for interfacing WWW::StaticBlog with templating engines.

=head1 VERSION

0.02

=head1 SYNOPSIS

Role for interfacing WWW::StaticBlog with templating engines.

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
