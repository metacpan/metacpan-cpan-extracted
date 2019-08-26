package XML::Grammar::Fortune::Synd::App;
$XML::Grammar::Fortune::Synd::App::VERSION = '0.0214';
use strict;
use warnings;

use parent 'Exporter';

use vars qw(@EXPORT);

@EXPORT=('run');

use Getopt::Long;
use File::Spec;

use XML::Grammar::Fortune::Synd;



sub run
{
    my $dir;
    my $yaml_data_file;
    my @xml_files = ();
    my $atom_output_fn;
    my $rss_output_fn;
    my $master_url;
    my $feed_title;
    my $feed_tagline;
    my $feed_author;

    GetOptions(
        'dir=s' => \$dir,
        'xml-file=s' => \@xml_files,
        'yaml-data=s' => \$yaml_data_file,
        'atom-output=s' => \$atom_output_fn,
        'rss-output=s' => \$rss_output_fn,
        'master-url=s' => \$master_url,
        'title=s' => \$feed_title,
        'tagline=s' => \$feed_tagline,
        'author=s' => \$feed_author,
    );


    my $url_callback = sub {
        my ($self, $args) = @_;

        my $id_obj = $args->{id_obj};

        my $base_fn = $id_obj->file();

        $base_fn =~ s{\.[^\.]*\z}{}ms;

        return $master_url . $base_fn . ".html" . "#" . $id_obj->id();
    };

    my $syndicator = XML::Grammar::Fortune::Synd->new(
        {
            xml_files => \@xml_files,
            url_callback => $url_callback,
        }
    );

    my @more_params;

    if ($atom_output_fn)
    {
        my (undef, undef, $atom_base) = File::Spec->splitpath($atom_output_fn);
        push @more_params, (atom_self_link => "$master_url$atom_base");
    }

    if ($rss_output_fn)
    {
        my (undef, undef, $rss_base) = File::Spec->splitpath($rss_output_fn);
        push @more_params, (rss_self_link => "$master_url$rss_base");
    }

    my $recent_ids_struct = $syndicator->calc_feeds(
           {
                yaml_persistence_file => $yaml_data_file,
                yaml_persistence_file_out => $yaml_data_file,
                xmls_dir => $dir,
                feed_params =>
                {
                    title => $feed_title,
                    'link' => $master_url,
                    tagline => $feed_tagline,
                    author => $feed_author,
                    @more_params,
                },
            }
        );

    if (defined($atom_output_fn))
    {
        open my $atom_out, ">", $atom_output_fn;
        print {$atom_out} $recent_ids_struct->{'feeds'}->{'Atom'}->as_xml();
        close($atom_out);
    }

    if (defined($rss_output_fn))
    {
        open my $rss20_out, ">", $rss_output_fn;
        print {$rss20_out} $recent_ids_struct->{'feeds'}->{'rss20'}->as_xml();
        close($rss20_out);
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fortune::Synd::App - module implementing a command line
application to syndicate FortuneXML as Atom/RSS.

=head1 VERSION

version 0.0214

=head1 SYNOPSIS

    perl -MXML::Grammar::Fortune::Synd::App -e 'run()' [ARGS] \

=head1 FUNCTIONS

=head2 run()

Call with no arguments to run the application from the commandline.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fortune-xml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Grammar::Fortune::Synd::App

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-Grammar-Fortune-Synd>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Grammar-Fortune-Synd>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Grammar-Fortune-Synd>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Grammar-Fortune-Synd>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune-Synd>

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

=cut
