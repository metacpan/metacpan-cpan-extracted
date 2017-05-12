package meon::Web::Form::TrainingCourse;

use meon::Web::Util;
use meon::Web::TimelineEntry;
use meon::Web::XML2Comment;
use Path::Class 'dir', 'file';
use Email::Sender::Simple qw(sendmail);
use Class::Load 'load_class';
use Run::Env;
use File::MimeInfo 'mimetype';

use utf8;
use 5.010;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has 'inputs' => (is => 'rw', isa => 'HashRef', default => sub {{}}, lazy => 1);

sub _course_form {
    my ($self) = @_;
    my $xpc = meon::Web::env->xpc;
    my $dom = meon::Web::env->xml;
    my ($course_form) = $xpc->findnodes('//*[@id="course"]//x:form',$dom);
    return $course_form;
}

sub certificate_status {
    my ($self) = @_;
    return eval { $self->get_config_text('certificate-status') } // 'on-going';
}

sub input_enabled {
    my ($self) = @_;
    my $cert_status = $self->certificate_status;
    return 1 if $cert_status eq 'on-going';
    return;
}

before 'process' => sub {
    my ($self) = @_;
    my $c = $self->c;

    my $xpc = meon::Web::env->xpc;
    my $dom = meon::Web::env->xml;

    my $course_form = $self->_course_form;
    return unless $course_form;

    my (@headings)  = $xpc->findnodes('.//x:h1|.//x:h2|.//x:h3|.//x:h4',$course_form);
    my (@inputs)    = $xpc->findnodes('.//x:input|.//x:select|.//x:textarea',$course_form);
    my $step        = eval { $self->get_config_text('step') } // 0;
    my $step_done   = eval { $self->get_config_text('step-done') } // 0;
    my $cert_id     = $self->get_config_text('certificate-id');
    my $cert_status = $self->certificate_status;
    my $forced_step = $c->req->param('step') // '';
    if (length($forced_step) && ($forced_step <= $step_done)) {
        $self->set_config_text('step' => $forced_step + 0);
        $self->store_config;
        $self->redirect($c->req->uri_with({step => undef})->absolute);
        return;
    }

    # build-up the content tree
    foreach my $summary ($xpc->findnodes('//w:training-course-summary',$dom)) {
        my $div_el = $c->model('ResponseXML')->create_xhtml_element('div');
        $div_el->setAttribute(class=>'training-course-summary');
        $summary->appendChild($div_el);

        my @inputs = $xpc->findnodes('.//x:input|.//x:select|.//x:textarea',$course_form);
        my %input_hash;
        foreach my $input (@inputs) {
            my $input_name  = $input->getAttribute('name');
            my $input_value = eval { $self->get_config_text('user_'.$input_name) } // '';

            my ($label) = $xpc->findnodes('.//x:*[@for="'.$input->getAttribute('id').'"]',$course_form);
            $input_name = $label->textContent
                if $label;

            my $input_div_el = $c->model('ResponseXML')->create_xhtml_element('div');
            $input_div_el->setAttribute(class=>'summary-item');
            $div_el->appendChild($input_div_el);
            $input_div_el->appendText("\n");
            my $label_div_el = $c->model('ResponseXML')->create_xhtml_element('div');
            $label_div_el->setAttribute(class=>'label');
            $input_div_el->appendChild($label_div_el);
            $input_div_el->appendText("\n");
            my $text_pre_el = $c->model('ResponseXML')->create_xhtml_element('pre');
            $input_div_el->appendChild($text_pre_el);
            $input_div_el->appendText("\n");

            $label_div_el->appendText($input_name);
            $text_pre_el->appendText($input_value);
            $input_hash{$input_name} = $input_value;
        }
        $self->inputs(\%input_hash);
    }

    # build-up the content tree
    foreach my $tree ($xpc->findnodes('//w:training-course-tree',$dom)) {
        my $div_el = $c->model('ResponseXML')->create_xhtml_element('div');
        $div_el->setAttribute(class=>'content-tree');
        $tree->appendChild($div_el);

        my $container = $div_el;
        my $cur_level = 0;
        my $tree_step = 0;
        foreach my $heading (@headings) {
            my $level = $heading->nodeName;
            $level =~ s/[^\d]//g;
            $level += 0;
            next unless $level;

            if ($level > $cur_level) {
                while ($level != $cur_level) {
                    $container = $container->lastChild // $container;
                    my $ul_el = $container->addNewChild($div_el->namespaceURI => 'ul');
                    $container = $ul_el;
                    $cur_level++
                }
            }
            elsif ($level < $cur_level) {
                while ($level != $cur_level) {
                    do {
                        $container = $container->parentNode;
                    } while ($container->nodeName ne 'ul');
                    $cur_level--
                }
            }

            my $li_el = $container->addNewChild($div_el->namespaceURI => 'li');
            if ($tree_step == $step) {
                my $b_el = $li_el->addNewChild($div_el->namespaceURI => 'b');
                $b_el->setAttribute(class => 'current-step');
                $b_el->appendText($heading->textContent);
            }
            elsif ($tree_step <= $step_done) {
                my $a_el  =  $li_el->addNewChild($div_el->namespaceURI => 'a');
                $a_el->setAttribute(href => '?step='.$tree_step);
                $a_el->appendText($heading->textContent);
            }
            else {
                $li_el->appendText($heading->textContent);
            }
            $tree_step++;
        }
    }

    # back/forward navigation
    my $current = $headings[$step];
    my $next    = ($step+1 < @headings ? $headings[$step+1] : undef);
    my $parent  = $current->parentNode;

    if ($next) {
        while (my $next_node = $next->nextSibling) {
            $parent->removeChild($next_node);
        }
        $parent->removeChild($next);
    }

    if ($step) {
        my $prev = $headings[$step-1];
        while (my $prev_node = $current->previousSibling) {
            $parent->removeChild($prev_node);
        }

        my $nav_back_el = $c->model('ResponseXML')->create_element('navigate-back');
        $nav_back_el->appendText($prev->textContent);
        $parent->appendChild(
            $nav_back_el
        );
    }

    if ($next) {
        my $nav_forward_el = $c->model('ResponseXML')->create_element('navigate-forward');
        $nav_forward_el->appendText($next->textContent);
        $parent->appendChild(
            $nav_forward_el
        );
    }
    elsif ($self->input_enabled) {
        my $nav_forward_el = $c->model('ResponseXML')->create_element('navigate-finish');
        $parent->appendChild(
            $nav_forward_el
        );
    }

    # add dummy element to the top of the step
    my $form_top_el = $c->model('ResponseXML')->create_element('form-top');
    $parent->insertBefore(
        $form_top_el,
        $current,
    );

    # populate input/select/textarea fields
    foreach my $input (@inputs) {
        my $input_name = $input->getAttribute('name');
        my $input_value = eval { $self->get_config_text('user_'.$input_name) } // '';

        my $nodeName = $input->nodeName;
        if ($nodeName eq 'select') {
            my ($option) = $xpc->findnodes('.//x:option[@value="'.$input_value.'"]',$input);
            $option->setAttribute('selected' => 'selected')
                if $option;
        } elsif ($nodeName eq 'textarea') {
            $input->removeChildNodes();
            $input->appendText($input_value)
        } else {
            $input->setAttribute(value => $input_value);
        }

        unless ($self->input_enabled) {
            $input->setAttribute(disabled => 'disabled');
        }
    }
};

sub submitted {
    my $self = shift;

    my $c       = $self->c;
    my $xpc     = meon::Web::env->xpc;
    my $dom     = meon::Web::env->xml;
    my %params  = %{$c->req->params};
    my $back    = $params{back};
    my $forward = $params{forward};
    my $finish  = $params{finish};

    my $course_form = $self->_course_form;
    return unless $course_form;

    my $rcpt_to      = $self->get_config_text('rcpt-to');
    my $cert_id      = eval { $self->get_config_text('certificate-id') };
    my $cert_ver     = eval { $self->get_config_text('certificate-version') };
    my $post_process = eval { $self->get_config_text('post-process') };
    my $now          = DateTime->now(time_zone => 'UTC');

    # store/check inputs
    my $all_required_set = 1;
    my %inputs = map { $_->getAttribute('name') => $_ } $xpc->findnodes('.//x:input|.//x:select|.//x:textarea',$course_form);
    foreach my $key (keys %params) {
        next unless my $input = $inputs{$key};
        my $value = $params{$key} // '';
        $value =~ s/\r//g;
        $value = undef if (length($value) == 0);
        if (!defined($value) && $input->getAttribute('required')) {
            $all_required_set = 0;
            $c->session->{form_input_errors}->{$key} = 'Required';
        }
        if ($self->input_enabled) {
            $self->set_config_text('user_'.$key => $value);
        }
    }

    # set correct step
    if ($back || ($forward && $all_required_set)) {
        my $step      = eval { $self->get_config_text('step') } // 0;
        my $step_done = eval { $self->get_config_text('step-done') } // 0;
        $step-- if $back;
        $step++ if $forward && eval { $xpc->findnodes('.//w:navigate-forward',$course_form)->size };
        $self->set_config_text('step'      => $step);
        $self->set_config_text('step-done' => $step)
            if $step_done < $step;
    }
    elsif (
        $finish
        && $self->input_enabled
        && $all_required_set
        && eval { $xpc->findnodes('.//w:navigate-finish',$course_form)->size }
    ) {
        my ($email_content) = map { $_->textContent } $xpc->findnodes('//x:*[@class="training-course-summary"]',$dom);
        $email_content =
            'from: '.$c->member->email."\n"
            .'certificate: '.meon::Web::env->xml_file->dir."\n"
            .'certificate-id: '.$cert_id."\n"
            .'certificate-version: '.$cert_ver."\n"
            .$email_content;
        die 'failed to extract training course summary'
            unless defined $email_content;
        my $cert_status = 'submitted';

        my @attachments;
        if ($post_process) {
            load_class($post_process);
            my ($new_cert_status, $new_email_content, $extras) = $post_process->post_process(
                member              => $c->member,
                dom                 => $dom,
                inputs              => $self->inputs,
                results_text        => $email_content,
                certificate_id      => $cert_id,
                certificate_version => $cert_ver,
                now                 => $now,
            );
            $extras //= {};
            $email_content = $new_email_content
                if $new_email_content;
            $cert_status = $new_cert_status
                if $new_cert_status;

            if (my $attachment = delete $extras->{attachment}) {
                push(@attachments, (ref $attachment eq 'ARRAY' ? @{$attachment} : $attachment ));
            };
        }

        my @email_headers = (
            header_str => [
                From    => (
                    meon::Web::env->hostname_config->{'main'}{'support-email'}
                    || meon::Web::Config->get->{main}->{'no-reply-email'}
                ),
                To      => $rcpt_to,
                Subject => $cert_id.' finished',
            ],
        );
        my @email_text = (
            attributes => {
                content_type => "text/plain",
                charset      => "UTF-8",
                encoding     => "8bit",
            },
            body_str => $email_content,
        );
        my $email;
        if (@attachments) {
            $email = Email::MIME->create(
                @email_headers,
                parts => [
                    Email::MIME->create(@email_text),
                    (
                        map {
                            my $filename = file(
                                ref($_) eq 'HASH'
                                ? $_->{filename}
                                : $_
                            );
                            my $basename = $filename->basename;
                            my $content_type = (
                                ref($_) eq 'HASH'
                                ? $_->{content_type}
                                : undef
                            ) // mimetype($basename) // 'application/octet-stream';
                            Email::MIME->create(
                                attributes => {
                                    filename     => $basename,
                                    content_type => $content_type,
                                    encoding     => "base64",
                                    name         => $basename,
                                },
                                body => IO::Any->slurp($filename),
                            );
                        } @attachments
                    ),
                ],
            );
        }
        else {
            $email = Email::MIME->create(
                @email_headers,
                @email_text,
            );
        }

        $self->set_config_text('certificate-status' => $cert_status);
        $self->set_config_text('certificate-finish-datetime' => $now->strftime('%Y%m%d-%H%M%S'));
        if (my ($report_pdf) = @attachments) {
            $self->set_config_text('certificate-report' => $report_pdf->basename);
        }

        if (Run::Env->dev) {
            warn $email->as_string;
        }
        else {
            sendmail($email->as_string);
        }
    }

    $self->store_config;

    $self->redirect($c->req->uri->absolute);
}

no HTML::FormHandler::Moose;

1;
