package XML::CompareML::HTML;

use strict;
use warnings;

use Carp;
use File::Spec;

use CGI ();
use XML::LibXSLT;

use XML::CompareML::ConfigData;

use base 'XML::CompareML::Base';

__PACKAGE__->mk_accessors(qw(
    _data_dir
    _xml_parser
    _stylesheet
    ));

sub _initialize
{
    my $self = shift;

    $self->SUPER::_initialize(@_);

    my (%args) = (@_);

    my $data_dir = $args{'data_dir'} ||
        XML::CompareML::ConfigData->config('extradata_install_path')->[0];

    $self->_data_dir($data_dir);

    $self->_xml_parser(XML::LibXML->new());

    my $xslt = XML::LibXSLT->new();

    my $style_doc = $self->_xml_parser()->parse_file(
            File::Spec->catfile(
                $self->_data_dir(),
                "compare-ml.xslt"
            ),
        );

    $self->_stylesheet($xslt->parse_stylesheet($style_doc));

    return 0;
}

=head2 $to-html->process()

Do the actual processing using the XSLT stylesheet.

=cut

sub process
{
    my ($self, $args) = @_;

=begin RELAX_NG_VALIDATION

    my $ret_code;

    eval
    {
        $ret_code = $self->_rng()->validate($source_dom);
    };

    if (defined($ret_code) && ($ret_code == 0))
    {
        # It's OK.
    }
    else
    {
        confess "RelaxNG validation failed [\$ret_code == $ret_code ; $@]";
    }

=end RELAX_NG_VALIDATION

=cut

    my $stylesheet = $self->_stylesheet();

    my $results = $stylesheet->transform($self->dom());

    print {*{$self->{o}}} $stylesheet->output_string($results);

    return 0;
}

=head1 NAME

XML::CompareML::HTML - convert CompareML to XHTML

=head1 SYNOPSIS

See L<XML::CompareXML>.

=head1 METHODS

=cut

=head2 $converter->gen_systems_list({output_handle => \*STDOUT})

Generates a list of li's with links to the systems, not unlike:

L<http://better-scm.berlios.de/comparison/>

=cut

sub gen_systems_list
{
    my ($self, %args) = @_;

    my $fh = $args{output_handle};

    my @implementations = $self->_findnodes("/comparison/meta/implementations/impl");

    foreach my $impl (@implementations)
    {
        my $name = $self->_impl_get_tag_text($impl, "name");
        my $url = $self->_impl_get_tag_text($impl, "url");
        my $fullname = $self->_impl_get_tag_text($impl, "fullname");
        my $vendor = $self->_impl_get_tag_text($impl, "vendor");
        if (!defined($url))
        {
            die "URL not specified for implementation $name.";
        }
        print {$fh} qq{<li><a href="} . CGI::escapeHTML($url) . qq{">} .
            CGI::escapeHTML(defined($fullname) ? $fullname : $name) .
            qq{</a>} . (defined($vendor) ? " by $vendor" : "") .
            qq{</li>\n}
            ;
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 SEE ALSO

L<XML::CompareML>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish. All rights reserved.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=cut

1;
