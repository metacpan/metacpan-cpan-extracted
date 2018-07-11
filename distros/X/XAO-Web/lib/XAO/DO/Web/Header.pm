=head1 NAME

XAO::DO::Web::Header - Simple HTML header

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Simple HTML header object. Accepts the following arguments, modifies
them as appropriate and displays "/bits/page-header" template passing the
rest of arguments unmodified.

=over

=item title => 'Page title'

Passed as is.

=item description => 'Page description for search engines'

This is converted to
<META NAME="Description" CONTENT="Page..">.

=item keywords => 'Page keywords for search engines'

This is converted to
<META NAME="Keywords" CONTENT="Page keywords..">.

=item path => '/bits/alternative-template-path'

Header template path, default is "/bits/page-header".

=item type => 'text/csv'

Allows you to set page type to something different then default
"text/html". If you set type the template would not be displayed! If you
still need it - call Header again without "type" argument.

Setting type to anything other than text/... switches the output to byte
mode, the same as calling $config->force_byte_output(1). It also removes
the "charset" extention on the Content-Type header.

=back

Would pass the folowing arguments to the template:

=over

=item META

Keywords and description combined.

=item TITLE

The value of 'title' argument above.

=back

Example:

 <%Header title="Site Search" keywords="super, duper, hyper, commerce"%>

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

=cut

###############################################################################
package XAO::DO::Web::Header;
use strict;
use XAO::Utils qw(:args :debug :html);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

our $VERSION='2.004';

###############################################################################
# Displaying HTML header.
#
sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    if(my $content_type=$args->{'type'}) {
        $self->siteconfig->header_args(-type => $content_type);

        # For older code compatibility, whenever the page content type is
        # switched away from text/* the default output is in bytes, not
        # characters.
        #
        if($content_type !~ /^text\//) {
            $self->siteconfig->force_byte_output(1);
            $self->siteconfig->header_args(-charset => '');
        }

        return;
    }

    if($args->{'http.name'}) {
        $self->siteconfig->header_args(
            $args->{'http.name'}    => $args->{'http.value'} || ''
        );
        return;
    }

    my $meta='';
    $meta.=qq(<META NAME="Keywords" CONTENT=").t2hf($args->{'keywords'}).qq(">\n)
        if $args->{'keywords'};
    $meta.=qq(<META NAME="Description" CONTENT=").t2hf($args->{'description'}).qq(">\n)
        if $args->{'description'};

    my $title=$args->{'title'} ||
              $self->siteconfig->get('default_title') ||
              "XAO::Web -- No Title";

    $self->object->display($args,{
        path        => $args->{'path'} || "/bits/page-header",
        TITLE       => $title,
        GIVEN_TITLE => $args->{'title'} || '',
        META        => $meta,
        KEYWORDS    => $args->{'keywords'},
        DESCRIPTION => $args->{'description'},
    });
}

###############################################################################
1;
