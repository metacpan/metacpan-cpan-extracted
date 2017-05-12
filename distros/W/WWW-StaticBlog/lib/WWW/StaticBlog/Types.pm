use MooseX::Declare;

class WWW::StaticBlog::Types
{
    our $VERSION = '0.02';

    use MooseX::Types
        -declare => [qw(
            DateTime
            TagList
        )],
    ;

    use MooseX::Types::Moose qw(
        ArrayRef
        Object
        Str
    );

    use Date::Parse qw(str2time);

    use DateTime::TimeZone ();
    use Text::CSV ();
    use WWW::StaticBlog::Tag ();

    use aliased 'DateTime' => 'RealDateTime';

    subtype DateTime,
        as Object,
        where { $_->isa('DateTime') };

    coerce DateTime,
        from Str,
        via {
            my $epoch = str2time($_);

            return RealDateTime->now() unless $epoch;

            return RealDateTime->from_epoch(
                epoch     => $epoch,
                time_zone => DateTime::TimeZone->new( name => 'local' ),
            );
        };

    subtype TagList,
        as ArrayRef['WWW::StaticBlog::Tag'];

    coerce TagList,
        from Str,
        via {
            my $csv = Text::CSV->new({sep_char => ' '});
            $csv->parse($_);

            die "Unable to parse tags from '$_'"
                unless $csv->status();

            return [
                map { WWW::StaticBlog::Tag->new($_) }
                grep { /./ } $csv->fields()
            ];
        };
}

__END__

=head1 NAME

WWW::StaticBlog::Types - Moose types, and coercions for WWW::StaticBlog.

=head1 VERSION

0.02

=head1 SYNOPSIS

Moose types, and coercions for WWW::StaticBlog.

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
