package WWWXML::Output;
use strict;

#use Data::Page::Pageset;
use File::Spec::Functions qw(catfile);
use HTML::Template::Pro;
#use URI::Escape qw(uri_escape);

BEGIN {
    $INC{'HTML/Template.pm'} = 1; # make those who use HTML::Template think it's already loaded
    HTML::Template::Pro->register_function(int => sub { int $_[0] });
    *HTML::Template::Pro::tmpl_param = \&HTML::Template::Pro::param;
}

use XML::Simple qw/XMLout/;

use WWWXML::Form;
use WWWXML::Form::Template;

sub templates_dir {
    return $::CONFIG->{templates_dir};
}

#my %files;
sub new_template {
    my ($class, %args) = @_;
#    my $pager = delete $args{pager};

    # make template path absolute
    $args{filename} = catfile($class->templates_dir, $args{filename} || "$args{name}.tmpl");

#    my $fn = $args{filename} || "$args{name}.tmpl";
#    unless($files{$fn}) {
#        my $data;
#        open my $h, "<", catfile($class->templates_dir, $fn) or die "$!";
#        binmode $h;
#        read $h, $data, -s $h;
#        close $h;
#        $files{$fn} = \$data;
#    }

    my $template = HTML::Template::Pro->new(
#        $files{$fn},
        die_on_bad_params => 0,
        strict            => 1,
        %args,
    );

#    if ($pager) {
        # prepare navigation: [ { text => 'M-N'/'N', page => N, is_current => 1/0 }, ... ]
#        my $pageset = Data::Page::Pageset->new($pager);
#        my $navigation = [];
#        my $page = $pager->current_page;
#        foreach my $chunk ($pageset->total_pagesets) {
#            push @$navigation, $chunk->is_current
#                ? map +{ text => $_, page => $_, is_current => $_ == $page },
#                    ($chunk->first .. $chunk->last)
#                : { text => $chunk->as_string, page => $chunk->middle };
#        }
#        $template->param(navigation => $navigation);
#        $template->param(page => $pager->current_page);
#        $template->param(page_prev => $pager->previous_page || $page);
#        $template->param(page_next => $pager->next_page || $page);
#    }

    return $template;
}

sub new_form {
    my ($class, %args) = @_;

    # default template to form name with '.tmpl' extension
    $args{template} ||= "$args{name}.tmpl";
    # make template path absolute
    $args{template} = catfile($class->templates_dir, $args{template});

    # prepare arguments for custom templating object
    $args{template} = {
        type     => 'WWWXML::Form::Template',
        filename => $args{template},
    };

    my $form = WWWXML::Form->new(
        # override some defaults...
        javascript => 0,
        action     => "?$ENV{QUERY_STRING}",
        method     => 'post',
        params     => $::query,
        stylesheet => 1,
        styleclass => 'www_xml_form',
        # ...and let arguments passed override defaults above
        %args
    );
    
    $form->tmpl_param(styleclass => 'www_xml_form');
    $form->field(name => 'action', type => 'hidden', value => $args{name});
    $form->field(name => 'submit_action', type => 'hidden', value => 0);

    return $form;
}

sub print_header {
    shift;
    my %param = @_;
    $param{-type} = 'text/html'
        unless $param{-type};

    $param{-charset} = 'utf-8'
        unless $param{-charset};

    print $::session->header(%param);
}

sub _template_params {
    my ($class, $obj) = @_;

    # provide support for both HTML::Template and CGI::FormBuilder
#    my $method = $obj->can('tmpl_param')
#        ? 'tmpl_param'
#        : 'param';
#

    if(index(lc ref $obj, 'form')) {
        if($obj->{_error_}) {
            $obj->tmpl_param(submit_error   => [ map +{ text => $_ }, @{$obj->{_error_}} ] );
        }
        if($obj->{_warn_}) {
            $obj->tmpl_param(submit_warning => [ map +{ text => $_ }, @{$obj->{_warn_}} ] );
        }
#        if($obj->submitted && !$obj->{_error_} && !$obj->{_warn_} && !$obj->invalid_fields) {
#            $obj->tmpl_param(submit_success => 1);
#        }
    }

    $obj->tmpl_param('action_'.($::query->get_param('action')) => 1);

#    if ($::session->param('submit_success')) {
        # set bool on submit success to display success messages, if any
#        $obj->$method('submit_success' => 1);
#        $::session->clear('submit_success');
#    }
#    if (my $warning = $::session->param('submit_warning')) {
        # set bool on submit warning to display warning messages, if any
#        $obj->$method("submit_warning_$warning" => 1);
#        $::session->clear('submit_warning');
#    }
#
#    if ($::member) {
        # propagate member profile to templates
#        $obj->$method('logged_' . { a => 'administrator', o => 'operator' }->{$::member->type} => 1);
#        $obj->$method("logged_privilege_$_" => $::member->priv & $::CONFIG->{member_privileges}->{$_})
#            foreach keys %{ $::CONFIG->{member_privileges} };
#        $obj->$method("logged_$_" => $::member->$_)
#            foreach qw/member name login/;
#    }
}

sub print_content {
    my $class = shift;
    my $content = shift;

    $class->print_header(@_);
    print $content;
}

sub print_fh_content {
    my $class = shift;
    my $fh = shift;

    $class->print_header(@_);
    my $buf;
    binmode STDOUT;
    seek $fh, 0, 0;
    while(read($fh, $buf, 4000)) {
        print $buf;
    }
}

sub print_template {
    my $class = shift;
    my $template = shift;

    $class->_template_params($template);
    
    if($::query->get_param('_make_xml')) {
        open my $h, ">", catfile($::CONFIG->{base_dir},'output.xml');
        print $h XMLout({
            map { $_ => $template->param($_) } grep {!/^_/} $template->param
        }, SuppressEmpty => 1, NoAttr => 1, KeyAttr => 0);
        close $h;
    }

    $class->print_header(@_);
    print $template->output;
}

sub print_form {
    my $class = shift;
    my $form = shift;
    
    $class->_template_params($form);
    
    if($::query->get_param('_make_xml')) {
        my $tmpl = $form->prepare;
        open my $h, ">", catfile($::CONFIG->{base_dir},'output.xml');
        print $h XMLout({
            (map { $_ => $form->tmpl_param($_) } grep {!/^_/} $form->tmpl_param),
            (map { "field_".$_ => $tmpl->{field}->{$_}->{field} } keys %{$tmpl->{field}}),
        }, SuppressEmpty => 1, NoAttr => 1, KeyAttr => 0);
        close $h;
    }

    $class->print_header(@_);
    print $form->render;
}

sub redirect {
    my $class = shift;
    print $::query->redirect(@_);
}

#sub redirect {
#    my $class = shift;
#    my %arg;
#    my ($addr,$uri);
#    if(@_ == 1) {
#        $uri = $_[0];
#    } else {
#        %arg = @_;
#        $uri = $arg{-uri};
#    }
#    if(length $uri < 1024){
#        return $class->redirect_old(@_);
#    }
#
#    ($addr,$uri) = $uri =~ m/^([^\?]*)\?(.*)$/;
#
#    my $act;
#    if($addr eq '' || $addr eq '/') {
#        $::session->param("__REDIRECTED__$_->[0]" => $_->[1])
#            foreach grep { $_->[0] ne 'action' or $act = $_->[1] and 0 } map { [ split /=/, $_ ] } split /&/, $uri;
#    }
#
#    $uri = "?action=$act";
#
#    $arg{-uri} = $addr.$uri;
#    return $class->redirect_old(%arg);
#}

sub redirect_status {
    my ($class, $status) = @_;

    if ($status == 403) {
        $::logger->debug("Access denied at ".(caller 1)[3]." for ".($::user ? $::user->{id} : '<>'));
        return $class->redirect('?action=home') if($::user);
        return $class->redirect('?action=login');
    } else {
        $class->print_header( -status => $status );
        print "Redirected with status: <b>$status</b> (TODO: handling statuses :))";
    }
}

1;

