package meon::Web::Role::Form;

use Moose::Role;
use Carp 'croak', 'confess';
use meon::Web::Util;
use meon::Web::env;

has 'c'      => ( is => 'ro', isa => 'Object', required => 1 );
has 'config' => ( is => 'ro', isa => 'Object', lazy_build => 1 );

sub _build_config {
    my ($self) = @_;

    my $c = $self->c;
    my $dom = meon::Web::env->xml;
    my $xpc = meon::Web::Util->xpc;
    my ($form_config) = $xpc->findnodes('/w:page/w:meta/w:form',$dom);
    return $form_config;
}

around 'submitted' => sub {
    my ($orig,$self) = @_;
    return unless $self->is_valid;
    $self->$orig(@_);
};

sub get_config_text {
    my ($self, $el_name) = @_;
    croak 'need element name argument'
        unless defined $el_name && length($el_name);

    my $xpc = meon::Web::Util->xpc;
    my $form_config = $self->config;
    my ($text) = map { $_->textContent } $xpc->findnodes('w:'.$el_name,$form_config);
    confess 'config element '.$el_name.' not found'
        unless defined $text;

    return $text;
}

sub set_config_text {
    my ($self, $el_name, $value) = @_;
    croak 'need element name argument'
        unless defined $el_name && length($el_name);

    my $xpc = meon::Web::Util->xpc;
    my $form_config = $self->config;
    my ($config_el) = $xpc->findnodes('w:'.$el_name,$form_config);
    if (defined($value)) {
        unless ($config_el) {
            $form_config->appendText(q{ }x4);
            $config_el = $form_config->addNewChild($form_config->namespaceURI,$el_name);
            $form_config->appendText("\n".q{ }x4);
        }
        $config_el->removeChildNodes();
        $config_el->appendText($value);
    }
    else {
        # FIXME remove whitespaces textnodes before
        $form_config->removeChild($config_el)
            if defined $config_el;
    }

    return $config_el;
}

sub get_config_folder {
    my ($self, $el_name) = @_;
    my $c = $self->c;
    my $path = $self->get_config_text($el_name);
    $path = meon::Web::Util->path_fixup($path);
    if ($path =~ m{^/}) {
        $path = meon::Web::env->hostname_subdir($path);
    }
    else {
        $path = $c->stash->{xml_file}->dir->subdir($path);
    }
    return $path;
}

sub detach {
    my ($self,$detach_path) = @_;

    my $c = $self->c;
    my $detach_uri = (
        $detach_path
        ? $c->traverse_uri($detach_path)
        : $c->req->uri->absolute
    );

    $c->session->{post_redirect_path} = $detach_uri;
    $c->res->redirect($c->req->uri->absolute);
}

sub redirect {
    my ($self,$redirect) = @_;

    my $c = $self->c;
    my $redirect_uri = $c->traverse_uri($redirect);
    $redirect_uri = $redirect_uri->absolute
        if $redirect_uri->can('absolute');
    $c->res->redirect($redirect_uri);
    $c->detach;
}

sub store_config {
    my $self = shift;

    my $xpc      = meon::Web::Util->xpc;
    my $filename = meon::Web::env->xml_file;
    my $dom      = XML::LibXML->load_xml(location => $filename);

    my ($form_config) = $xpc->findnodes('/w:page/w:meta/w:form',$dom);
    $form_config->replaceNode($self->config);
    return IO::Any->spew(
        [$filename],
        $dom->toString,
        {atomic => 1},
    );
}

1;
