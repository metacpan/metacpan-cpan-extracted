use MooseX::Declare;

class WWW::StaticBlog::Template::Toolkit
{
    our $VERSION = '0.02';

    use Hash::Merge qw(merge);

    method render($template, HashRef $contents)
    {
        my $output = '';
        $self->template_engine($template, $contents, \$output)
            || die $self->template_engine()->error();

        return $output;
    }

    method render_to_file($template, HashRef $contents, Str $out_file_name)
    {
        $self->template_engine->process(
            $template,
            merge(
                { constants => $self->fixtures},
                $contents,
            ),
            $out_file_name,
            binmode => ':utf8',
        ) || die $self->template_engine()->error();

        return 1;
    }

    method _build_template_engine()
    {
        Class::MOP::load_class($self->template_class());

        return $self->template_class()->new(
            $self->options()
        );
    }

    with 'WWW::StaticBlog::Role::Template';

    has '+template_class' => (default => 'Template');
}

__END__

=head1 NAME

WWW::StaticBlog::Template::Toolkit - WWW::StaticBlog interface for Template::Toolkit

=head1 VERSION

0.02

=head1 SYNOPSIS

WWW::StaticBlog interface for Template::Toolkit

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
