package meon::Web::Controller::Root;
use Moose;
use namespace::autoclean;
use 5.010;

use Path::Class 'file', 'dir';
use meon::Web::SPc;
use meon::Web::Config;
use meon::Web::Util;
use meon::Web::env;
use XML::LibXML 1.70;
use URI::Escape 'uri_escape';
use IO::Any;
use Class::Load 'load_class';
use File::MimeInfo 'mimetype';
use Scalar::Util 'blessed';
use DateTime::Format::HTTP;
use Imager;
use URI::Escape 'uri_escape';
use List::MoreUtils 'none';
use WWW::Mechanize;
use JSON::XS 'decode_json';
use Data::asXML 0.07;

use meon::Web::Form::Login;
use meon::Web::Form::Delete;
use meon::Web::Member;
use meon::Web::TimelineEntry;


BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auto : Private {
    my ( $self, $c ) = @_;

    meon::Web::env->clear;
    meon::Web::env->stash($c->stash);
    meon::Web::env->session($c->session);

    my $uri      = $c->req->uri;
    my $hostname = $uri->host;
    meon::Web::env->hostname($hostname);
    my $hostname_dir_name = meon::Web::env->hostname_dir_name;
    $c->detach('/status_not_found', ['no such domain '.$hostname.' configured'])
        unless $hostname_dir_name;

    my $hostname_dir = $c->stash->{hostname_dir} = meon::Web::env->hostname_dir;

    my $template_file = file($hostname_dir, 'template', 'xsl', 'default.xsl')->stringify;
    $c->stash->{template} = XML::LibXML->load_xml(location => $template_file);

    $c->default_auth_store->folder(meon::Web::env->profiles_dir);
    meon::Web::env->user($c->user);

    # set cookie domain
    my $cookie_domain = $hostname;
    my $config_cookie_domain = meon::Web::env->hostname_config->{'main'}{'cookie-domain'};

    if ($config_cookie_domain && (substr($hostname,0-length($config_cookie_domain)) eq $config_cookie_domain)) {
        $cookie_domain = $config_cookie_domain;
    }

    $c->_session_plugin_config->{cookie_domain} = $cookie_domain;
    $c->change_session_expires( 30*24*60*60 )
        if $c->session->{remember_login};

    return 1;
}

sub static : Path('/static') {
    my ($self, $c) = @_;

    my $static_file = file(@{$c->static_include_path}, $c->req->path);
    $c->detach('/status_not_found', [($c->debug ? $static_file : '')])
        unless -e $static_file;

    my $mime_type = mimetype($static_file->stringify);
    $c->res->content_type($mime_type);
    $c->res->body(IO::Any->read([$static_file]));
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->forward('resolve_xml', []);
}

sub resolve_xml : Private {
    my ( $self, $c ) = @_;

    my $hostname_dir = $c->stash->{hostname_dir};
    my $include_dir  = meon::Web::env->include_dir;
    my $path            =
        delete($c->session->{post_redirect_path})
        || $c->stash->{path}
        || $c->req->uri;
    $path = URI->new($path)
        unless blessed($path);

    # replace …/index by …/ in url
    if ($path =~ m{/index$}) {
        my $new_uri = $c->req->uri;
        $new_uri->path(substr($path->path,0,-5));
        $c->res->redirect($new_uri->absolute);
        $c->detach;
    }

    meon::Web::env->current_path(file($path->path));
    my $xml_file = file(meon::Web::env->content_dir, $path->path_segments);
    $xml_file .= 'index' if ($xml_file =~ m{/$});
    $xml_file .= '.xml';

    # add trailing slash and redirect when uri points to a folder
    if ((! -f $xml_file) && (-d substr($xml_file,0,-4))) {
        my $new_uri = $c->req->uri;
        $new_uri->path($path->path.'/');
        $c->res->redirect($new_uri->absolute);
        $c->detach;
    }

    if ((! -f $xml_file) && (-f substr($xml_file,0,-4))) {
        my $static_file = file(substr($xml_file,0,-4));
        my $mtime = $static_file->stat->mtime;
        if (!$c->req->param('t')) {
            $c->res->redirect($c->req->uri_with({t => $mtime})->absolute);
            $c->detach;
        }

        my $max_age = 365*24*60*60;
        $c->res->header('Cache-Control' => 'max-age='.$max_age.', private');
        $c->res->header(
            'Expires' => DateTime::Format::HTTP->format_datetime(
                DateTime->now->add(seconds => $max_age)
            )
        );
        $c->res->header(
            'Last-Modified' => DateTime::Format::HTTP->format_datetime(
                DateTime->from_epoch(epoch => $mtime)
            )
        );

        my $mime_type = mimetype($static_file->basename);
        $c->res->content_type($mime_type);
        $c->res->body($static_file->open('r'));
        $c->detach;
    }

    meon::Web::env->xml_file($xml_file);

    unless (-e $xml_file) {
        my $not_found_handler = meon::Web::env->hostname_config->{'main'}{'not-found-handler'};
        if ($not_found_handler) {
            load_class($not_found_handler);
            my $content_dir = meon::Web::env->content_dir;
            my $relative_path = $xml_file;
            $relative_path =~ s/^$content_dir//;
            die 'forbidden' if $path eq $relative_path;
            $not_found_handler->check($content_dir, $relative_path);
        }
        $c->detach('/status_not_found', [($c->debug ? $path.' '.$xml_file : $path)])
            if (!eval { meon::Web::env->xml });
    }

    $xml_file = file($xml_file);
    $c->stash->{xml_file} = $xml_file;

    my $dom = meon::Web::env->xml;
    my $xpc = meon::Web::Util->xpc;

    $c->model('ResponseXML')->dom($dom);

    $c->model('ResponseXML')->push_new_element('current-path')->appendText($c->req->uri->path);
    $c->model('ResponseXML')->push_new_element('current-uri')->appendText($c->req->uri->absolute);
    $c->model('ResponseXML')->push_new_element('static-mtime')->appendText(meon::Web::env->static_dir_mtime);
    $c->model('ResponseXML')->push_new_element('run-env')->appendText(Run::Env->current);

    # user
    if ($c->user_exists) {
        my $user_el = $c->model('ResponseXML')->create_element('user');

        my $user_el_username = $c->model('ResponseXML')->create_element('username');
        $user_el_username->appendText($c->user->username);
        $user_el->appendChild($user_el_username);

        my $member = $c->member;
        my $full_name_el = $c->model('ResponseXML')->create_element('full-name');
        $full_name_el->appendText($member->get_member_meta('full-name'));
        $user_el->appendChild($full_name_el);
        my $profile_el = $c->model('ResponseXML')->create_element('profile');
        if (my $member_profile = $member->get_member_meta_element('member-profile')) {
            $profile_el->appendChild($member_profile);
            $user_el->appendChild($profile_el);
        }

        $c->model('ResponseXML')->append_xml($user_el);

        my @user_roles = $c->user->roles;
        if (my $backend_user_data = $c->session->{backend_user_data}) {
            my $bu_data_el = $c->model('ResponseXML')->create_element('backend-user-data');
            $c->model('ResponseXML')->append_xml($bu_data_el);
            my $dxml = Data::asXML->new(
                pretty    => Run::Env->dev,
                namespace => 1,
            );
            $bu_data_el->appendChild(
                $dxml->encode($backend_user_data)
            );

            if ($backend_user_data->{web_roles}) {
                my @backed_roles = map {
                    'backend-'.$_
                } eval {@{$backend_user_data->{web_roles}}};
                push(@user_roles, @backed_roles);
            }
        }

        my $roles_el = $c->model('ResponseXML')->create_element('roles');
        foreach my $role (@user_roles) {
            $roles_el->appendChild(
                $c->model('ResponseXML')->create_element($role)
            );
        }
        $user_el->appendChild($roles_el);

        my @access_roles = map { $_->textContent } $xpc->findnodes('/w:page/w:meta/w:access/w:role',$dom);
        foreach my $role (@access_roles) {
            $c->detach('/status_forbidden', []) if (none {$_ eq $role} @user_roles);
        }

    }
    else {
        if ($xpc->findnodes('/w:page/w:meta/w:members-only',$dom)) {
            $c->detach('/login', []);
        }
    }

    # redirect
    my ($redirect) = $xpc->findnodes('/w:page/w:meta/w:redirect', $dom);
    if ($redirect) {
        $redirect = $redirect->textContent;
        my $redirect_uri = $c->traverse_uri($redirect);
        $redirect_uri = $redirect_uri->absolute
            if $redirect_uri->can('absolute');
        $c->res->redirect($redirect_uri);
        $c->detach;
    }

    # includes
    my (@include_elements) =
        $xpc->findnodes('/w:page//w:include',$dom);
    foreach my $include_el (@include_elements) {
        my $include_path = $include_el->getAttribute('path');
        unless ($include_path) {
            $include_el->appendText('path attribute missing');
            next;
        }
        my $include_rel = dir(meon::Web::Util->path_fixup($include_path));
        my $file = file($include_dir, $include_rel)->absolute;
        next unless -f $file;
        $file = $file->resolve;
        $c->detach('/status_forbidden', [])
            unless $include_dir->contains($file);
        my $include_xml = eval { XML::LibXML->load_xml(location => $file) };

        my (@include_filter_elements) =
            $xpc->findnodes('//w:apply-filter',$include_xml);
        foreach my $include_filter_el (@include_filter_elements) {
            my $filter_ident = $include_filter_el->getAttribute('ident');
            die 'no filter name specified'
                unless $filter_ident;
            my $filter_class = 'meon::Web::Filter::'.$filter_ident;
            load_class($filter_class);
            my $status = $filter_class->new(
                dom          => $include_xml,
                include_node => $include_el,
                user         => $c->user,
            )->apply;
            if (my $err_msg = $status->{error}) {
                if (($status->{status} // 0) == 404) {
                    $c->detach('/status_not_found', [$err_msg]);
                }
                else {
                    die $err_msg;
                }
            }
            $include_filter_el->parentNode->removeChild($include_filter_el);
        }

        if ($include_xml) {
            $include_el->replaceNode($include_xml->documentElement());
        }
        else {
            die 'failed to load include '.$@;
        }
    }

    # forms
    if (my ($form_el) = $xpc->findnodes('/w:page/w:meta/w:form',$dom)) {
        my $skip_form = 0;
        if ($xpc->findnodes('w:owner-only',$form_el)) {
            $skip_form = 1;
            if ($c->user_exists) {
                my $member = $c->member;
                my $member_folder = $member->dir;

                $skip_form = 0
                    if $member_folder->contains($xml_file);
            }
        }

        unless ($skip_form) {
            my $back_link = delete $c->req->params->{_back_link};
            if (defined($back_link)) {
                $c->model('ResponseXML')->push_new_element('back-link')->appendText($back_link);
                $c->stash->{back_link} = $back_link;
            }
            my ($form_class) = 'meon::Web::Form::'.$xpc->findnodes('/w:page/w:meta/w:form/w:process', $dom);
            load_class($form_class);
            my $form = $form_class->new(c => $c);
            my $params = $c->req->body_parameters;
            foreach my $field ($form->fields) {
                next if $field->type ne 'Upload';
                my $field_name = $field->name;
                $params->{$field_name} = $c->req->upload($field_name)
                    if $c->req->params->{$field_name};
            }
            $form->process(params=>$params);
            $form->submitted
                if $form->is_valid && $form->can('submitted') && ($c->req->method eq 'POST');
            $c->model('ResponseXML')->add_xhtml_form(
                $form->render
            );

            if (my $form_input_errors = delete $c->session->{form_input_errors}) {
                foreach my $input_name (keys %$form_input_errors) {
                    my ($input) = $xpc->findnodes(
                        './/x:input[@name="'.$input_name.'"]'
                        .'|.//x:select[@name="'.$input_name.'"]'
                        .'|.//x:textarea[@name="'.$input_name.'"]'
                        ,$c->model('ResponseXML')->dom
                    );
                    next unless $input;
                    $input->setAttribute('class' => $input->hasAttribute('class') ? $input->getAttribute('class').' error' : 'error');
                    my $span = $input->parentNode->addNewChild($input->namespaceURI, 'span');
                    $span->setAttribute('class' => 'help-inline');
                    $span->appendText($form_input_errors->{$input_name});
                    my $error_class = 'error';
                    my $div = $input->parentNode;
                    if ($div->getAttribute('class') // '' eq 'form-group') {
                        $error_class = 'has-error';
                    }
                    else {
                        $div->parentNode;
                    }
                    $div->setAttribute(
                        'class'
                        => ($div->hasAttribute('class') ? $div->getAttribute('class').' '.$error_class : $error_class)
                    );
                }
            }

        }
    }

    # folder listing
    my (@folder_elements) =
        $xpc->findnodes('/w:page/w:content//w:dir-listing',$dom);
    foreach my $folder_el (@folder_elements) {
        my $folder_name = $folder_el->getAttribute('path');
        my $reverse     = $folder_el->getAttribute('reverse');
        unless ($folder_name) {
            $folder_el->appendText('path attribute missing');
            next;
        }
        my $folder_rel = dir(meon::Web::Util->path_fixup($folder_name));
        my $folder = dir($xml_file->dir, $folder_rel)->absolute;
        next unless -d $folder;
        $folder = $folder->resolve;
        $c->detach('/status_forbidden', [])
            unless $hostname_dir->contains($folder);

        my @folders = sort(grep { $_->is_dir }     $folder->children(no_hidden => 1));
        @folders = reverse @folders if $reverse;
        my @files   = sort(grep { not $_->is_dir } $folder->children(no_hidden => 1));
        @files = reverse @files if $reverse;

        foreach my $file (@folders) {
            $file = $file->basename;
            my $file_el = $c->model('ResponseXML')->create_element('folder');
            $file_el->setAttribute('href' => join('/', map { uri_escape($_) } $folder_rel->dir_list, $file));
            $file_el->appendText($file);
            $folder_el->appendChild($file_el);
        }
        foreach my $file (@files) {
            $file = $file->basename;
            my $file_el = $c->model('ResponseXML')->create_element('file');
            $file_el->setAttribute('href' => join('/', map { uri_escape($_) } $folder_rel->dir_list, $file));
            $file_el->appendText($file);
            $folder_el->appendChild($file_el);
        }
    }

    # gallery listing
    my (@galleries) = $xpc->findnodes('/w:page/w:content//w:gallery',$dom);
    foreach my $gallery (@galleries) {
        my $gallery_path = $gallery->getAttribute('href');
        my $max_width  = $gallery->getAttribute('thumb-width');
        my $max_height = $gallery->getAttribute('thumb-height');

        my $folder_rel = dir(meon::Web::Util->path_fixup($gallery_path));
        my $folder = dir($xml_file->dir, $folder_rel)->absolute;
        die 'no pictures in '.$folder unless -d $folder;
        $folder = $folder->resolve;
        $c->detach('/status_forbidden', [])
            unless $hostname_dir->contains($folder);

        my @files = sort(grep { not $_->is_dir } $folder->children(no_hidden => 1));

        foreach my $file (@files) {
            $file = $file->basename;
            next if $file =~ m/\.xml$/;
            my $thumb_file = file(map { uri_escape($_) } $folder_rel->dir_list, 'thumb', $file);
            my $img_file   = file(map { uri_escape($_) } $folder_rel->dir_list, $file);
            my $file_el = $c->model('ResponseXML')->create_element('img');
            $file_el->setAttribute('src' => $img_file);
            $file_el->setAttribute('src-thumb' => $thumb_file);
            $file_el->setAttribute('title' => $file);
            $file_el->setAttribute('alt' => $file);
            $gallery->appendChild($file_el);

            # create thumbnail image
            $thumb_file = file($xml_file->dir, $thumb_file);
            unless (-e $thumb_file) {
                $thumb_file->dir->mkpath
                    unless -e $thumb_file->dir;

                my $img = Imager->new(file => file($xml_file->dir, $img_file))
                    or die Imager->errstr();
                if ($img->getwidth > $max_width) {
                    $img = $img->scale(xpixels => $max_width)
                        || die 'failed to scale image - '.$img->errstr;
                }
                if ($img->getheight > $max_height) {
                    $img = $img->scale(ypixels => $max_height)
                        || die 'failed to scale image - '.$img->errstr;
                }
                $img->write(file => $thumb_file->stringify) || die 'failed to save image - '.$img->errstr;
            }
        }
    }

    # generate timeline
    my ($timeline_el) = $xpc->findnodes('/w:page/w:content//w:timeline', $dom);
    if ($timeline_el) {
        my $timeline_class = $timeline_el->getAttribute('class') // 'folder';
        my @entries_files;
        foreach my $href_entry ($xpc->findnodes('w:timeline-entry[@href]', $timeline_el)) {
            my $href = $href_entry->getAttribute('href');
            $timeline_el->removeChild($href_entry);
            my $path = file(meon::Web::Util->full_path_fixup($href).'.xml');
            push(@entries_files,$path)
                if -e $path;
        }
        @entries_files = $xml_file->dir->children(no_hidden => 1)
            if $timeline_class eq 'folder';

        my @entries =
            sort { $b->created <=> $a->created }
            grep { eval { $_->element } }
            map  { meon::Web::TimelineEntry->new(file => $_) }
            grep { $_->basename ne $xml_file->basename }
            grep { !$_->is_dir }
            @entries_files
        ;

        foreach my $entry (@entries) {
            my $entry_el = $entry->element;
            my $intro = $entry->intro;
            my $href = $entry->file->resolve;
            return unless $href;
            $href = substr($href,0,-4);
            $href = substr($href,length($c->stash->{hostname_dir}.'/content'));
            $entry_el->setAttribute('href' => $href);
            if (defined($intro)) {
                my $intro_snipped_el = $c->model('ResponseXML')->create_element('intro-snipped');
                $entry_el->appendChild($intro_snipped_el);
                $intro_snipped_el->appendText(length($intro) > 78 ? substr($intro,0,78).'…' : $intro);
            }

            $timeline_el->appendChild($entry_el);
        }

        if (my $older = $self->_older_entries($c)) {
            my $older_el = $c->model('ResponseXML')->create_element('older');
            $timeline_el->appendChild($older_el);
            $older_el->setAttribute('href' => $older);
        }
        if (my $newer = $self->_newer_entries($c)) {
            my $newer_el = $c->model('ResponseXML')->create_element('newer');
            $timeline_el->appendChild($newer_el);
            $newer_el->setAttribute('href' => $newer);
        }
    }

    # generate members list
    my ($members_list_el) = $xpc->findnodes('/w:page/w:content//w:members-list', $dom);
    if ($members_list_el) {
        my %members_by_section;
        my $active_only = $members_list_el->getAttribute('active-only');
        foreach my $member (sort { $a->section cmp $b->section } meon::Web::env->all_members) {
            next if ($active_only && !$member->is_active);
            $member->shred_password;
            my $sec = $member->section;
            $members_by_section{$sec} //= [];
            push(@{$members_by_section{$sec}}, $member);
        }
        foreach my $sec (sort keys %members_by_section) {
            my $sec_el = $c->model('ResponseXML')->create_element('section');
            $sec_el->setAttribute('name' => $sec);
            $members_list_el->appendChild($sec_el);
            foreach my $member (@{$members_by_section{$sec}}) {
                my $meta = $member->member_meta;
                $sec_el->appendChild($meta);

                my $username = $member->username;
                my $username_el = $c->model('ResponseXML')->create_element('username');
                $username_el->appendText($username);
                $meta->appendChild($username_el);
                my $status = $member->user->status;
                my $status_el = $c->model('ResponseXML')->create_element('status');
                $status_el->appendText($status);
                $meta->appendChild($status_el);
            }
        }
    }

    # generate exists
    my (@exists) = (
        $xpc->findnodes('//w:exists', $dom),
        $xpc->findnodes('//w:exists', $c->stash->{template}),
    );
    foreach my $exist_el (@exists) {
        my $href = $exist_el->getAttribute('href');
        my $path = meon::Web::Util->full_path_fixup($href);
        $exist_el->appendText(-e $path ? 1 : 0);
    }

    # handle different templates
    my ($template_node) = $xpc->findnodes('/w:page/w:meta/w:template', $dom);
    if ($template_node) {
        my $template_name = $template_node->textContent;
        my $template_file = file($hostname_dir, 'template', 'xsl', $template_name.'.xsl')->stringify;
        $c->detach('/status_not_found', ['no such template '.$template_name])
            unless -f $template_file;
        $c->stash->{template} = XML::LibXML->load_xml(location => $template_file);
    }
}

sub _older_entries {
    my ( $self, $c ) = @_;
    my $dir = $c->stash->{xml_file}->dir;
    my $cur_dir = $dir->basename;
    $dir = $dir->parent;
    while ($cur_dir =~ m/^\d+$/) {
        my @min_folders =
            sort
            grep { $_ < $cur_dir }
            grep { m/^\d+$/ }
            map  { $_->basename }
            grep { $_->is_dir }
            $dir->children(no_hidden => 1)
        ;

        if (@min_folders) {
            # find the last folder of this folder
            while (@min_folders) {
                $dir = $dir->subdir(pop(@min_folders));
                @min_folders =
                    sort
                    grep { m/^\d+$/ }
                    map { $_->basename }
                    grep { $_->is_dir }
                    $dir->children(no_hidden => 1)
                ;
            }
            return '/'.$dir->relative(meon::Web::env->content_dir).'/';
        }

        $cur_dir = $dir->basename;
        $dir = $dir->parent;
    }
}

sub _newer_entries {
    my ( $self, $c ) = @_;
    my $dir = $c->stash->{xml_file}->dir;
    my $cur_dir = $dir->basename;
    $dir = $dir->parent;
    while ($cur_dir =~ m/^\d+$/) {
        my @max_folders =
            sort
            grep { $_ > $cur_dir }
            grep { m/^\d+$/ }
            map  { $_->basename }
            grep { $_->is_dir }
            $dir->children(no_hidden => 1)
        ;

        if (@max_folders) {
            # find the first folder of this folder
            while (@max_folders) {
                $dir = $dir->subdir(shift(@max_folders));
                @max_folders =
                    sort
                    grep { m/^\d+$/ }
                    map { $_->basename }
                    grep { $_->is_dir }
                    $dir->children(no_hidden => 1)
                ;
            }
            return '/'.$dir->relative(meon::Web::env->content_dir).'/';
        }

        $cur_dir = $dir->basename;
        $dir = $dir->parent;
    }
}

sub status_forbidden : Private {
    my ( $self, $c, $message ) = @_;

    $c->res->status(403);

    my $xml_file = file(meon::Web::env->content_dir, '403.xml');
    if (-e $xml_file) {
        $c->session->{post_redirect_path} = '/403';
        $self->resolve_xml($c);
        $c->model('ResponseXML')->push_new_element('error-message')->appendText($message)
            if $message;
    }
    else {
        $message = '403 - Forbidden: '.$c->req->uri."\n".($message // '');
        $c->res->content_type('text/plain');
        $c->res->body($message);
    }
}

sub status_not_found : Private {
    my ( $self, $c, $message ) = @_;

    $c->res->status(404);

    my $xml_file = file(meon::Web::env->content_dir, '404.xml');
    if (-e $xml_file) {
        $c->session->{post_redirect_path} = '/404';
        $self->resolve_xml($c);
        $c->model('ResponseXML')->push_new_element('error-message')->appendText($message)
            if $message;
    }
    else {
        $message = '404 - Page not found: '.$c->req->uri."\n".($message // '');
        $c->res->content_type('text/plain');
        $c->res->body($message);
    }
}

sub logout : Local {
    my ( $self, $c ) = @_;

    my $username = eval { $c->user->username };
    $c->delete_session;
    $c->log->info('logout user '.$username)
        if $username;
    return $c->res->redirect($c->uri_for('/'));
}

sub login : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect($c->uri_for('/'))
        if $c->user_exists;

    my $members_folder = $c->default_auth_store->folder;

    my $ext_auth_username = $c->session->{external_auth_username};
    if (
        meon::Web::env->hostname_config->{'auth'}{'external'}
        && $ext_auth_username
    ) {
        my $member = meon::Web::Member->new(
            members_folder => $members_folder,
            username       => $ext_auth_username,
        );

        if ($member->exists) {
            $c->set_authenticated($c->find_user({ username => $ext_auth_username }));
            $c->log->info('user '.$ext_auth_username.' authenticated via external authentication');
            $c->change_session_id;
            delete $c->session->{external_auth_username};
            return $c->res->redirect($c->req->uri->absolute);
        }

        my $registration_link = meon::Web::env->hostname_config->{'auth'}{'registration'};
        $c->stash->{path} = $c->traverse_uri($registration_link);
        $c->detach('resolve_xml', []);
    }

    my $token    = $c->req->param('auth-token');
    my $username = $c->req->param('username');
    my $password = $c->req->param('password');
    my $back_to  = $c->req->param('back-to');
    $c->session->{remember_login} = $c->req->param('remember_login');

    if ($c->action eq 'logout') {
        return $c->res->redirect($c->uri_for('/'));
    }
    if ($c->user_exists && !$token) {
        $back_to ||= '/';
        return $c->res->redirect($c->uri_for($back_to));
    }

    my $login_form = meon::Web::Form::Login->new();

    # token authentication
    if ($token) {
        my $member;
        if (($token eq 'admin') && $c->user_exists) {
            my @roles = $c->user->roles;
            if (any {$_ eq 'admin'} @roles) {
                $member = meon::Web::Member->new(
                    members_folder => $members_folder,
                    username       => $username,
                );
            }
        }
        else {
            $member = meon::Web::Member->find_by_token(
                members_folder => $members_folder,
                token          => $token,
            );
            if ($member && !$member->is_active) {
                $member = undef;
                $login_form->add_form_error('Account not activated or expired.');
            }
        }

        if ($member) {
            my $username = $member->username;
            $c->set_authenticated($c->find_user({ username => $username }));
            $c->log->info('user '.$username.' authenticated via token');
            $c->change_session_id;
            $c->session->{old_pw_not_required} = 1;
            return $c->res->redirect(
                $c->req->uri_with({
                    'auth-token' => undef,
                    'username'   => undef,
                })->absolute
            );
        }
        else {
            $login_form->add_form_error('Invalid authentication token.');
        }
    }
    else {
        $login_form->process(params=>$c->req->params);

        if (meon::Web::env->hostname_config->{'auth'}{'external'}) {
            if ($username && $password && $login_form->is_valid) {
                my $auth_url       = meon::Web::env->hostname_config->{'auth'}{'url'};
                my $username_field = meon::Web::env->hostname_config->{'auth'}{'username'};
                my $password_field = meon::Web::env->hostname_config->{'auth'}{'password'};
                my $content_match  = meon::Web::env->hostname_config->{'auth'}{'content-match'};

                my $mech = WWW::Mechanize->new();
                if ($content_match) {
                    eval {
                        $mech->get( $auth_url );
                        $mech->submit_form(
                            with_fields      => {
                                $username_field => $username,
                                $password_field => $password,
                            }
                        );
                        die 'external auth failed - status '.$mech->status
                            unless $mech->status == 200;
                        $mech->get( $auth_url );
                        if ($content_match) {
                            die 'external auth failed - content does not match m/'.$content_match.'/xms ('.$mech->uri.')'
                                unless $mech->content =~ m/$content_match/xms;
                        }
                    };
                }
                else {
                    eval {
                        my $res = $mech->post( $auth_url, {
                            $username_field => $username,
                            $password_field => $password,
                        });
                        die 'external auth failed - status '.$mech->status
                            unless $mech->status == 200;
                        if ($res->header('Content-Type') =~ m{application/json}) {
                            my $data = eval { decode_json($res->content) };
                            if ($data && $data->{user_data}) {
                                $c->session->{backend_user_data} = $data->{user_data};
                            }
                        }
                    };
                }
                if ($@) {
                    $login_form->field('password')->add_error('authentication failed, please check your password or try again later');
                    $c->log->error($@);
                    $c->res->status(403);
                }
                else {
                    $c->session->{external_auth_username} = $username;
                    if (my $user = $c->find_user({ username => $username })) {
                        $c->set_authenticated($user);
                        delete $c->session->{external_auth_username};
                    }
                    $c->log->info('user '.$username.' authenticated via external authentication [2]');
                    return $c->res->redirect(
                        $c->req->uri_with({username => undef, password => undef})->absolute
                    );
                }
            }
        }
        else {
            if ($username =~ m/\@/) {
                my $member = meon::Web::Member->find_by_email(
                    members_folder => $members_folder,
                    email          => $username,
                );
                $username = $member->user->username
                    if $member;
            }
            if ($username && $password && $login_form->is_valid) {
                if (
                    $c->authenticate({
                        username => $username,
                        password => $password,
                    })
                ) {
                    $c->log->info('user '.$username.' authenticated');
                    $c->change_session_id;
                    return $c->res->redirect($c->req->uri);
                }
                else {
                    $c->log->info('login of user '.$username.' fail');
                    $login_form->field('password')->add_error('authentication failed');
                    $c->res->status(403);
                }
            }
        }
    }

    $c->stash->{path} = URI->new('/login');
    $c->forward('resolve_xml', []);
    $c->model('ResponseXML')->add_xhtml_form(
        $login_form->render
    );
}

sub exception : Path('/exception-test') {
    die 'here';
}

sub end : ActionClass('RenderView') {
	my ($self, $c) = @_;

    my @errors = @{ $c->error };

    if (@errors) {
        $c->response->status(500);

        my $message = join("\n", @errors);
        $message ||= 'No output';

        my $xml_file = file(meon::Web::env->content_dir, '500.xml');
        if (-e $xml_file) {
            eval {
                $c->session->{post_redirect_path} = '/500';
                $c->forward('resolve_xml', []);
                $c->model('ResponseXML')->push_new_element('error-message')->appendText($message)
                    if $message;
            };
            if ($@) {
                $c->log->error($@);
                return;
            }
        }
        else {
            $message = '500 - Internal server error: '.$c->req->uri."\n".($message // '');
            $c->res->content_type('text/plain');
            $c->res->body($message);
        }
    }

    while (my $error = shift(@{$c->error})) {
        $c->log->error($error);
    }
}

__PACKAGE__->meta->make_immutable;

1;
