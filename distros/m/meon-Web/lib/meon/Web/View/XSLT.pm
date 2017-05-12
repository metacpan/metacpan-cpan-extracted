package meon::Web::View::XSLT;

use strict;
use base 'Catalyst::View::XSLT';
use Encode 'decode';
use Path::Class 'file';

# configured in meon_web.pl

sub render {
    my ($self, $c, @args) = @_;

    unless ($c->stash->{xml}) {
        $c->stash->{xml} = $c->model('ResponseXML')->as_xml;
    }

    my $content = $self->SUPER::render($c, @args);
    $content =~ s{<br></br>}{<br>}g;    # otherwise browser interprets it as 2x <br>
    return decode('UTF-8', $content);
}

sub process {
    my ($self, $c, @args) = @_;

    if ($c->debug && $c->req->param('debug_xml')) {
        $c->res->content_type('text/xml');
        $c->stash->{template} = file(
            meon::Web::SPc->datadir,
            'meon-web', 'template', 'xsl',
            'debug.xsl'
        );
    }

    return $self->SUPER::process($c, @args);
}

1;
