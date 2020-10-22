package XML::Grammar::Fortune::Synd;
$XML::Grammar::Fortune::Synd::VERSION = '0.0215';
use warnings;
use strict;

use 5.008;


use parent 'Class::Accessor';

use YAML::XS        (qw( DumpFile LoadFile ));
use Heap::Elem::Ref (qw(RefElem));
use Heap::Binary;
use XML::Feed;
use XML::Grammar::Fortune;
use DateTime::Format::W3CDTF;
use XML::Grammar::Fortune::Synd::Heap::Elem;

use File::Spec;

__PACKAGE__->mk_accessors(
    qw(
        _xml_parser
        _file_doms
        _date_formatter
        xml_files
        url_callback
        _file_processors
        )
);


sub new
{
    my ( $class, $args ) = @_;

    my $self = $class->SUPER::new($args);

    $self->_xml_parser( XML::LibXML->new() );
    $self->_date_formatter( DateTime::Format::W3CDTF->new() );
    $self->_file_doms( +{} );
    $self->_file_processors( +{} );

    return $self;
}


sub calc_feeds
{
    my ( $self, $args ) = @_;

    my $scripts_hash_filename = $args->{'yaml_persistence_file'};
    my $scripts_hash_fn_out   = $args->{'yaml_persistence_file_out'};
    my $xmls_dir              = $args->{xmls_dir};

    my $persistent_data;
    if ( -e $scripts_hash_filename )
    {
        $persistent_data = LoadFile($scripts_hash_filename);
    }
    else
    {
        $persistent_data = +{};
    }

    if ( !exists( $persistent_data->{'files'} ) )
    {
        $persistent_data->{'files'} = +{};
    }

    my $scripts_hash = $persistent_data->{'files'};

    my $ids_heap = Heap::Binary->new();

    my $ids_heap_count = 0;

    my $ids_limit = 20;

    foreach my $file ( @{ $self->xml_files() } )
    {
        my $xml = $self->_xml_parser->parse_file(
            File::Spec->catfile( $xmls_dir, $file ) );

        $self->_file_doms->{$file} = $xml;

        my @fortune_elems = $xml->findnodes("//fortune");

        my @ids = ( map { $_->getAttribute("id") } @fortune_elems );

        my $id_count = 1;

        # Get rid of IDs in the hash refs that don't exist in the file,
        # so we won't have globally duplicate IDs.
        {
            my $hash_ref = $scripts_hash->{$file};
            my %ids_map  = ( map { $_ => 1 } @ids );

            foreach my $id ( keys(%$hash_ref) )
            {
                if ( !exists( $ids_map{$id} ) )
                {
                    delete( $hash_ref->{$id} );
                }
            }
        }

    IDS_LOOP:
        foreach my $id (@ids)
        {
            if ( !exists( $scripts_hash->{$file}->{$id} ) )
            {
                $scripts_hash->{$file}->{$id} = {
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
                            idx  => $id_count,
                            id   => $id,
                            file => $file,
                        }
                    )
                )
            );

            if ( ++$ids_heap_count > $ids_limit )
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
    while ( defined( my $id_obj = $ids_heap->extract_top() ) )
    {
        push @recent_ids, $id_obj;
    }
    DumpFile( $scripts_hash_fn_out, $persistent_data );

    my @feed_formats = (qw(Atom RSS));

    my %feeds = ( map { $_ => XML::Feed->new($_), } @feed_formats );

    # First set some global parameters
    foreach my $feed ( values(%feeds) )
    {
        $feed->title( $args->{feed_params}->{'title'} );
        $feed->link( $args->{feed_params}->{'link'} );
        $feed->tagline( $args->{feed_params}->{'tagline'} );
        $feed->author( $args->{feed_params}->{'author'} );

        my $self_link = $args->{feed_params}->{'atom_self_link'};
        $feed->self_link($self_link);
        $feed->id($self_link);
    }

    # Now fill the XML-Feed object:
    {

        foreach my $id_obj ( map { $_->val() } @recent_ids )
        {
            my $file_dom =
                $self->_file_doms()->{ $id_obj->file() };

            my ($fortune_dom) =
                $file_dom->findnodes(
                "descendant::fortune[\@id='" . $id_obj->id() . "']" );

            my %entries =
                ( map { $_ => XML::Feed::Entry->new($_) } @feed_formats );

            my $title = $fortune_dom->findnodes("meta/title")->get_node(0)
                ->textContent();

            my $on_entries = sub {

                my ($callback) = @_;

                foreach my $entry ( values(%entries) )
                {
                    $callback->($entry);
                }
            };

            $on_entries->(
                sub {
                    my $entry = shift;

                    $entry->title($title);
                    $entry->summary($title);
                }
            );

            my $url = $self->url_callback()->(
                $self,
                {
                    id_obj => $id_obj,
                }
            );

            $on_entries->(
                sub {
                    my $entry = shift;

                    $entry->link($url);

                    $entry->id($url);

                    $entry->issued( $id_obj->date() );
                }
            );

            {
                $self->_file_processors()->{ $id_obj->file() } ||=
                    XML::Grammar::Fortune->new(
                    {
                        mode        => "convert_to_html",
                        output_mode => "string",
                    }
                    );

                my $file_processor =
                    $self->_file_processors()->{ $id_obj->file() };

                my $content = "";

                $file_processor->run(
                    {
                        xslt_params => {
                            'fortune.id' => "'" . $id_obj->id() . "'",
                        },
                        output => \$content,
                        input  =>
                            File::Spec->catfile( $xmls_dir, $id_obj->file() ),
                    }
                );

                $content =~ s{\A.*?<body>}{}ms;
                $content =~ s{</body>.*\z}{}ms;

                $on_entries->(
                    sub {
                        my $entry = shift;

                        $entry->content(
                            XML::Feed::Content->new(
                                {
                                    type => "text/html",
                                    body => $content,
                                },
                            )
                        );

                    }
                );
            }

            foreach my $format (@feed_formats)
            {
                $feeds{$format}->add_entry( $entries{$format} );
            }
        }
    }

    $feeds{"RSS"}->self_link( $args->{feed_params}->{'rss_self_link'} );

    {
        my $num_entries = scalar( () = $feeds{'RSS'}->entries() );
        if ( $num_entries > $ids_limit )
        {
            die "Assert failed. $num_entries rather than the $ids_limit limit.";
        }
    }

    return {
        'recent_ids' => [ reverse(@recent_ids) ],
        'feeds'      => {
            'Atom'  => $feeds{"Atom"},
            'rss20' => $feeds{"RSS"},
        },
    };
}


1;    # End of XML::Grammar::Fortune::Synd

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fortune::Synd - Provides syndication for a set of
XML-Grammar-Fortune files.

=head1 VERSION

version 0.0215

=head1 SYNOPSIS

    use XML::Grammar::Fortune::Synd;

    my $syndicator = XML::Grammar::Fortune::Synd->new();
    ...

=head1 FUNCTIONS

=head2 my $syndicator = $class->new(\%args)

Returns the new Syndicator.

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

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/Expat License

http://www.opensource.org/licenses/mit-license.php

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Grammar-Fortune-Synd>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Grammar-Fortune-Synd>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Grammar-Fortune-Synd>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fortune-Synd>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fortune-Synd>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fortune::Synd>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fortune-synd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Grammar-Fortune-Synd>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fortune-xml>

  git clone git://github.com/shlomif/fortune-xml.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fortune-xml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
