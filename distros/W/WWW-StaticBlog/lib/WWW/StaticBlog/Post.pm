use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Post
{
    our $VERSION = '0.02';

    use MooseX::Types::Moose qw(
        Str
        Undef
    );
    use WWW::StaticBlog::Types qw(
        DateTime
        TagList
    );
    use WWW::StaticBlog::Util qw(
        sanitize_for_dir_name
    );

    use aliased 'DateTime' => 'DT';

    use Email::Simple ();
    use Text::CSV ();
    use Text::Multi ();

    use File::Slurp qw(
        read_file
        write_file
    );

    has title => (
        is      => 'rw',
        isa     => Str,
        lazy    => 1,
        default => sub {
            my $self = shift;
            return unless defined $self->_file_contents();
            return $self->_file_contents_for('Title');
        },
    );

    has tags => (
        is      => 'rw',
        traits  => ['Array'],
        isa     => TagList|Undef,
        coerce  => 1,
        lazy    => 1,
        handles => {
            add_tag     => 'push',
            all_tags    => 'elements',
            num_tags    => 'count',
            remove_tags => 'clear',
            _sorted_tags => 'sort',
        },
        default => sub {
            my $self = shift;
            return [] unless defined $self->_file_contents();
            return $self->_file_contents_for('Tags') // '';
        },
    );

    has raw_body => (
        is      => 'rw',
        isa     => Str,
        lazy    => 1,
        trigger => \&_raw_body_trigger,
        default => sub {
            my $self = shift;
            return unless defined $self->_file_contents();
            return $self->_file_body();
        },
    );

    has posted_on => (
        is      => 'rw',
        isa     => DateTime|Undef,
        coerce  => 1,
        lazy    => 1,
        trigger => \&_posted_on_trigger,
        default => sub {
            my $self = shift;
            return unless defined $self->_file_contents();
            return $self->_file_contents_for('Post-Date')
                // DT->from_epoch(
                    epoch     => time(),
                    time_zone => DateTime::TimeZone->new(name => 'local'),
                );
        },
    );

    has updated_on => (
        is      => 'rw',
        isa     => DateTime|Undef,
        coerce  => 1,
        lazy    => 1,
        default => sub {
            my $self = shift;
            return unless defined $self->_file_contents();
            return $self->_file_contents_for('Updated-On')
                // (
                    $self->_file_contents_for('Post-Date')
                    ? DT->from_epoch(
                        epoch     => time(),
                        time_zone => DateTime::TimeZone->new(name => 'local'),
                    )
                    : undef
                )
                // $self->posted_on();
        },
    );

    has author => (
        is      => 'rw',
        isa     => Str|Undef,
        lazy    => 1,
        default => sub {
            my $self = shift;
            return unless defined $self->_file_contents();
            return $self->_file_contents_for('Author');
        }
    );

    has slug => (
        is         => 'rw',
        isa        => Str,
        lazy_build => 1,
    );

    has _file_contents => (
        is         => 'ro',
        isa        => 'Maybe[Email::Simple]',
        lazy_build => 1,
        handles    => {
            '_file_contents_for' => 'header',
            '_file_body'         => 'body',
        }
    );

    has filename => (
        is        => 'ro',
        isa       => 'Str|Undef',
        predicate => 'has_filename',
    );

    has default_markup_lang => (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => 'Markdown',
    );

    has _parser => (
        is         => 'rw',
        isa        => 'Text::Multi',
        lazy_build => 1,
        clearer    => '_clear_parser',
    );

    method sorted_tags()
    {
        return $self->_sorted_tags(
            sub { $_[0]->name() cmp $_[1]->name() }
        );
    }

    sub _raw_body_trigger
    {
        my ($self, $body, $old_body) = @_;

        return unless defined $old_body && $old_body ne $body;
        $self->_clear_parser();
        $self->_parser($self->_build_parser());
    }

    sub _posted_on_trigger
    {
        my ($self, $posted_on, $old_posted_on) = @_;

        $self->posted_on(DT->now())
            unless defined $posted_on;
    }

    method _build__file_contents()
    {
        return unless $self->has_filename();

        return Email::Simple->new(
            scalar read_file($self->filename())
        );
    }

    method _build__parser()
    {
        my $parser = Text::Multi->new(
            default_type => $self->default_markup_lang(),
        );

        $parser->process_text($self->raw_body());

        return $parser;
    }

    method _build_slug()
    {
        return $self->_file_contents_for('Slug')
            if defined $self->_file_contents_for('Slug');

        my $slug = $self->title();
        return unless defined $slug;

        return lc sanitize_for_dir_name($slug);
    }

    method body($debug = 0)
    {
        $self->_parser()->detailed($debug);
        my $rendered_body = $self->_parser()->render();
        $self->_parser()->detailed($debug);

        return $rendered_body;
    }

    method inline_css()
    {
        $self->_parser()->css_inline();
    }

    method files_for_css()
    {
        $self->_parser()->css_files();
    }

    method save()
    {
        $self->_file_contents()->header_set( 'Author'     => $self->author()     );
        $self->_file_contents()->header_set( 'Post-Date'  => $self->posted_on()  );
        $self->_file_contents()->header_set( 'Slug'       => $self->slug()       );
        $self->_file_contents()->header_set( 'Title'      => $self->title()      );
        $self->_file_contents()->header_set( 'Updated-On' => $self->updated_on() );
        $self->_file_contents()->body_set($self->raw_body);
        if ($self->num_tags) {
            my $csv = Text::CSV->new({sep_char => ' '});

            $csv->combine(
                sort
                map { $_->name() } $self->all_tags()
            ) or die 'Could not save tags.';

            $self->_file_contents()->header_set('Tags' => $csv->string());
        }

        my $text = $self->_file_contents()->as_string();
        write_file(
            $self->filename(),
            {
                atomic  => 1,
                binmode => ':utf-8',
            },
            \$text,
        );
    }

    method url()
    {
        return '/' . join(
            '/',
            $self->posted_on()->year(),
            $self->posted_on()->strftime('%m'),
            $self->posted_on()->strftime('%d'),
            $self->slug() . '.html',
        );
    }
}

"I don't think there's a punch-line scheduled, is there?";
__END__

=head1 NAME

WWW::StaticBlog::Post - A Post itself.

=head1 VERSION

0.02

=head1 SYNOPSIS

A Post itself.

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
