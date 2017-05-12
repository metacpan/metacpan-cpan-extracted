package XML::Grammar::Fortune::Synd;

use warnings;
use strict;

use 5.008;

=head1 NAME

XML::Grammar::Fortune::Synd - Provides syndication for a set of
XML-Grammar-Fortune files.

=head1 VERSION

Version 0.0211

=cut

our $VERSION = '0.0211';

use base 'Class::Accessor';

use YAML::XS (qw( DumpFile LoadFile ));
use Heap::Elem::Ref (qw(RefElem));
use Heap::Binary;
use XML::Feed;
use XML::Grammar::Fortune;
use DateTime::Format::W3CDTF;
use XML::Grammar::Fortune::Synd::Heap::Elem;

use File::Spec;

__PACKAGE__->mk_accessors(qw(
        _xml_parser
        _file_doms
        _date_formatter
        xml_files
        url_callback
        _file_processors
    ));

=head1 SYNOPSIS

    use XML::Grammar::Fortune::Synd;

    my $syndicator = XML::Grammar::Fortune::Synd->new();
    ...

=head1 FUNCTIONS

=head2 my $syndicator = $class->new(\%args)

Returns the new Syndicator.

=cut

sub new
{
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    $self->_xml_parser(XML::LibXML->new());
    $self->_date_formatter(DateTime::Format::W3CDTF->new());
    $self->_file_doms(+{});
    $self->_file_processors(+{});

    return $self;
}

=head2 $syndicator->calc_feeds(\%args)

C<\%args> should be:

    {
        yaml_persistence_file => "/path/to/yaml-persistence.yaml",
        yaml_persistence_file_out => "/path/to/yaml-persistence.yaml",
        xml_dirs => "/path/to/the/directory-containing-xmls",
        feed_params =>
        {
            title => "My feed title",
            link => "http://mysite.tld/",
            tagline => "Feed tagline",
            author => "john.doe@hello.tld (John Doe)"
            atom_self_link => "http://mysite.tld/my-feed.atom",
            rss_self_link => "http://mysite.tld/my-feed.rss",
        }
    }

Returns:

    {
        recent-ids => \@list_of_recent_ids,
        feeds =>
        {
            Atom => $atom_XML_Feed_obj,
            rss20 => $rss_XML_Feed_obj,
        },
    }

=cut

sub calc_feeds
{
    my ($self, $args) = @_;

    my $scripts_hash_filename = $args->{'yaml_persistence_file'};
    my $scripts_hash_fn_out =   $args->{'yaml_persistence_file_out'};
    my $xmls_dir = $args->{xmls_dir};


    my $persistent_data;
    if (-e $scripts_hash_filename)
    {
        $persistent_data = LoadFile ($scripts_hash_filename);
    }
    else
    {
        $persistent_data = +{};
    }

    if (!exists($persistent_data->{'files'}))
    {
        $persistent_data->{'files'} = +{};
    }

    my $scripts_hash = $persistent_data->{'files'};

    my $ids_heap = Heap::Binary->new();

    my $ids_heap_count = 0;

    my $ids_limit = 20;

    foreach my $file (@{$self->xml_files()})
    {
        my $xml = $self->_xml_parser->parse_file(
            File::Spec->catfile($xmls_dir, $file)
        );

        $self->_file_doms->{$file} = $xml;

        my @fortune_elems = $xml->findnodes("//fortune");

        my @ids = (map { $_->getAttribute("id") } @fortune_elems);

        my $id_count = 1;

        # Get rid of IDs in the hash refs that don't exist in the file,
        # so we won't have globally duplicate IDs.
        {
            my $hash_ref = $scripts_hash->{$file};
            my %ids_map = (map { $_ => 1 } @ids);

            foreach my $id (keys(%$hash_ref))
            {
                if (! exists($ids_map{$id}))
                {
                    delete ($hash_ref->{$id});
                }
            }
        }

        IDS_LOOP:
        foreach my $id (@ids)
        {
            if (! exists($scripts_hash->{$file}->{$id}))
            {
                $scripts_hash->{$file}->{$id} =
                {
                    'date' => $self->_date_formatter->format_datetime(
                        DateTime->now(),
                    ),
                };
            }

            my $date = $self->_date_formatter->parse_datetime(
                $scripts_hash->{$file}->{$id}->{'date'},
            );

            $ids_heap->add(
                RefElem(
                    XML::Grammar::Fortune::Synd::Heap::Elem->new(
                        {
                            date => $date,
                            idx => $id_count,
                            id => $id,
                            file => $file,
                        }
                    )
                )
            );

            if (++$ids_heap_count > $ids_limit)
            {
                $ids_heap->extract_top();
                $ids_heap_count--;
            }
        }
        continue
        {
            $id_count++;
        }
    }

    my @recent_ids = ();

    # TODO : Should we reverse this?
    while (defined(my $id_obj = $ids_heap->extract_top()))
    {
        push @recent_ids, $id_obj;
    }
    DumpFile($scripts_hash_fn_out, $persistent_data);

    my @feed_formats = (qw(Atom RSS));

    my %feeds = (map { $_ => XML::Feed->new($_), } @feed_formats);

    # First set some global parameters
    foreach my $feed (values(%feeds))
    {
        $feed->title($args->{feed_params}->{'title'});
        $feed->link($args->{feed_params}->{'link'});
        $feed->tagline($args->{feed_params}->{'tagline'});
        $feed->author($args->{feed_params}->{'author'});

        my $self_link = $args->{feed_params}->{'atom_self_link'};
        $feed->self_link($self_link);
        $feed->id($self_link);
    }

    # Now fill the XML-Feed object:
    {

        foreach my $id_obj (map { $_->val() } @recent_ids)
        {
            my $file_dom =
                $self->_file_doms()->{$id_obj->file()};

            my ($fortune_dom) =
                $file_dom->findnodes("descendant::fortune[\@id='". $id_obj->id() . "']");

            my %entries = (map { $_ => XML::Feed::Entry->new($_) } @feed_formats);

            my $title = $fortune_dom->findnodes("meta/title")->get_node(0)->textContent();

            my $on_entries = sub {

                my ($callback) = @_;

                foreach my $entry (values(%entries))
                {
                    $callback->($entry);
                }
            };

            $on_entries->(sub {
                my $entry = shift;

                $entry->title($title);
                $entry->summary($title);
            });

            my $url =
                $self->url_callback()->(
                    $self,
                    {
                        id_obj => $id_obj,
                    }
                );

            $on_entries->(sub {
                my $entry = shift;

                $entry->link( $url );

                $entry->id($url);

                $entry->issued($id_obj->date());
            });

            {
                $self->_file_processors()->{$id_obj->file()} ||=
                    XML::Grammar::Fortune->new(
                        {
                            mode => "convert_to_html",
                            output_mode => "string",
                        }
                    );

                my $file_processor =
                    $self->_file_processors()->{$id_obj->file()};

                my $content = "";

                $file_processor->run(
                    {
                        xslt_params =>
                        {
                            'fortune.id' => "'" . $id_obj->id() . "'",
                        },
                        output => \$content,
                        input => File::Spec->catfile($xmls_dir, $id_obj->file()),
                    }
                );

                $content =~ s{\A.*?<body>}{}ms;
                $content =~ s{</body>.*\z}{}ms;

                $on_entries->(sub {
                    my $entry = shift;

                    $entry->content(
                        XML::Feed::Content->new(
                            {
                                type => "text/html",
                                body => $content,
                            },
                        )
                    );

                });
            }

            foreach my $format (@feed_formats)
            {
                $feeds{$format}->add_entry($entries{$format});
            }
        }
    }

    $feeds{"RSS"}->self_link($args->{feed_params}->{'rss_self_link'});

    {
        my $num_entries = scalar (() = $feeds{'RSS'}->entries());
        if ($num_entries > $ids_limit)
        {
            die "Assert failed. $num_entries rather than the $ids_limit limit.";
        }
    }

    return
    {
        'recent_ids' => [reverse(@recent_ids)],
        'feeds' =>
        {
            'Atom' => $feeds{"Atom"},
            'rss20' => $feeds{"RSS"},
        },
    };
}


=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune-synd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune-Synd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune::Synd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune-Synd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune-Synd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune-Synd>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune-Synd>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11 License

http://www.opensource.org/licenses/mit-license.php

=cut

1; # End of XML::Grammar::Fortune::Synd
