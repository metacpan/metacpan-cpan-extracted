package XML::Grammar::Fortune::Synd::App;

use strict;
use warnings;

use base 'Exporter';

use vars qw(@EXPORT);

our $VERSION = '0.0211';

@EXPORT=('run');

use Getopt::Long;
use File::Spec;

use XML::Grammar::Fortune::Synd;

=head1 NAME

XML::Grammar::Fortune::Synd::App - module implementing a command line
application to syndicate FortuneXML as Atom/RSS.

=head1 SYNOPSIS

    perl -MXML::Grammar::Fortune::Synd::App -e 'run()' [ARGS] \

=head1 FUNCTIONS

=head2 run()

Call with no arguments to run the application from the commandline.

=cut


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

