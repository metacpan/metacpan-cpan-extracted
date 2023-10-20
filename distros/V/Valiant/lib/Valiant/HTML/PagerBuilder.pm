package Valiant::HTML::PagerBuilder;

use Moo;
use Module::Runtime ();
use Valiant::Util 'process_template';
use Carp 'croak';

has model => (is=>'ro', required=>1);
has pager => (is=>'ro', required=>1, lazy=>1, builder=>1);
has options => (is=>'ro', required=>1, default=>sub { +{} });

has uri_base => (is=>'ro', predicate=>'has_uri_base');

sub _build_pager {
  my ($self) = @_;
  return $self->model->pager;
}

has view => (is=>'ro', required=>1, builder=>1);

sub _build_view {
  my ($self) = @_;
  return my $view = Module::Runtime::use_module('Valiant::HTML::Util::View')->new;
}

has name => (is=>'ro', required=>1, builder=>1);

sub _build_name {
  my ($self) = @_;
  return $self->model->result_class->model_name->param_key;
} 

has tag_builder => (
  is => 'ro', 
  required => 1,
  builder => 1,
  lazy => 1,
);

  sub _build_tag_builder {
    my ($self) = @_;
    return Module::Runtime::use_module('Valiant::HTML::Util::TagBuilder')->new(view=>$self->view);
  }

sub default_window_info_none {
  my ($self) = @_;
  return '';
}

sub default_window_info_one {
  my ($self) = @_;
  return '{{total_entries}} {{model_name}}';
}

sub default_window_info_many {
  my ($self) = @_;
  return '{{first}} to {{last}} of {{total_entries}} {{model_name}}';
}

sub default_window_info_container {
  my ($self) = @_;
  return '<div {{container_attrs}}>{{message}}</div>';
}

sub default_window_info_container_attrs {
  my ($self) = @_;
  return +{
    id => $self->name.'_pager_window_info',
    class => 'pager_window_info',
  };
}

sub process_window_info {
  my ($self, $arg) = @_;
  return $arg->($self->view, $self, $self->pager, $self->model) if ref($arg) eq 'CODE';

  my $model_name = $self->pager->total_entries > 1 ?
    $self->model->result_class->model_name->human(count=>2) :
    $self->model->result_class->model_name->human; 

  return process_template $arg,
    model_name => $model_name,
    total_entries => $self->pager->total_entries,
    entries_per_page => $self->pager->entries_per_page,
    current_page => $self->pager->current_page,
    entries_on_this_page => $self->pager->entries_on_this_page,
    first => $self->pager->first,
    last => $self->pager->last,
    first_page => $self->pager->first_page,
    last_page => $self->pager->last_page,
    previous_page => $self->pager->previous_page,
    next_page => $self->pager->next_page,
}

sub window_info {
  my $self = shift;
  return $_[0]->($self->view, $self, $self->pager, $self->model) if ref($_[0]) eq 'CODE';
  my %extra_container_args = (ref($_[0]||'') eq 'HASH') ? %{shift(@_)} : ();

  my (%args) = @_;
  my $none = exists($args{none}) ? $args{none} : $self->default_window_info_none;
  my $one = exists($args{one}) ? $args{one} : $self->default_window_info_one;
  my $many = exists($args{many}) ? $args{many} : $self->default_window_info_many;
  
  return $self->process_window_info($none) unless $self->pager->total_entries > 0;

  my $message = $self->pager->last_page == 1 ?
    $self->process_window_info($one) :
    $self->process_window_info($many);

  my $container = exists($args{container}) ? $args{container} : $self->default_window_info_container;
  my $container_attrs = exists($args{container_attrs}) ? $args{container_attrs} : $self->default_window_info_container_attrs;
  $container_attrs = $self->tag_builder->_tag_options(%$container_attrs, %extra_container_args);

  my $window_info = process_template $container,
    message => $message,
    container_attrs => $container_attrs;

  return $self->view->raw($window_info);
}

sub default_navigation_line_none {
  my ($self) = @_;
  return '';
}

sub default_navigation_line_page {
  my ($self) = @_;
  return '<a {{page_attrs}}>{{page}}</a>';
}

sub default_navigation_line_page_attrs {
  my ($self) = @_;
  return +{
    class => "pager_page @{[ $self->name ]}_pager_page",
  };
}

sub default_navigation_line_current_page {
  my ($self) = @_;
  return '<a {{current_page_attrs}}>{{current_page}}</a>';
}

sub default_navigation_line_current_page_attrs {
  my ($self) = @_;
  return +{
    id => $self->name.'_pager_current_page',
    class => 'pager_page pager_current_page',
  };
}

sub process_navigation_line {
  my ($self, $arg) = @_;
  return $arg->($self->view, $self, $self->pager, $self->model) if ref($arg) eq 'CODE';
  return process_template $arg, 
    total_entries => $self->pager->total_entries,
    entries_per_page => $self->pager->entries_per_page,
    current_page => $self->pager->current_page,
    entries_on_this_page => $self->pager->entries_on_this_page,
    first => $self->pager->first,
    last => $self->pager->last,
    first_page => $self->pager->first_page,
    last_page => $self->pager->last_page,
    previous_page => $self->pager->previous_page,
    next_page => $self->pager->next_page,
}

sub default_navigation_line_container {
  my ($self) = @_;
  return '<div {{container_attrs}}>Page: {{message}}</div>';
}

sub default_navigation_line_container_attrs {
  my ($self) = @_;
  return +{
    id => $self->name.'_pager_navigation_line',
    class => 'pager_navigation_line',
  };
}

sub navigation_line {
  my $self = shift;
  my $link_generator = shift if ref($_[0])||'' eq 'CODE';

  unless($link_generator) {
    my $uri_base = $self->has_uri_base ?
      $self->uri_base :
      croak "A Link generator must exist if there's no uri_base"; # Maybe $self->view->ctx->request->uri_base;

    $link_generator = sub {
      my ($view, $pb, $page_num, $pager, $model) = @_;
      my $uri = $uri_base->clone;
      $uri->query_form($uri->query_form, $pb->name.'.page'=>$page_num);
      return $uri;
    };
  }
  
  my (%args) = @_;
  my $none = exists($args{none}) ? $args{none} : $self->default_navigation_line_none;
  my $page = exists($args{page}) ? $args{page} : $self->default_navigation_line_page;
  my $page_attrs = exists($args{page_attrs}) ? $args{page_attrs} : $self->default_navigation_line_page_attrs;
  my $current_page = exists($args{current_page}) ? $args{current_page} : $self->default_navigation_line_current_page;
  my $current_page_attrs = exists($args{current_page_attrs}) ? $args{current_page_attrs} : $self->default_navigation_line_current_page_attrs;

  return $self->process_window_info($none) unless $self->pager->total_entries > 0; 

  my $html = '';
  foreach my $page_num (1..$self->pager->last_page) {
    my $href = $link_generator->($self->view, $self, $page_num, $self->pager, $self->model);
    if($page_num == $self->pager->current_page) {
      my $attrs = $self->tag_builder->_tag_options(%$current_page_attrs, href=>$href);
      my $link = process_template $current_page, current_page=>$page_num, current_page_attrs=>$attrs;
      $html .= $link;
    } else {
      my $attrs = $self->tag_builder->_tag_options(%$page_attrs, href=>$href);
      my $link = process_template $page, page=>$page_num, page_attrs=>$attrs;
      $html .= $link;
    }
  }
  $link_generator = undef; # Needed because the coderef doesn't go out of scope for some reason...

  my $container = exists($args{container}) ? $args{container} : $self->default_navigation_line_container;
  my $container_attrs = exists($args{container_attrs}) ? $args{container_attrs} : $self->default_navigation_line_container_attrs;
  $container_attrs = $self->tag_builder->_tag_options(%$container_attrs);

  my $navigation_line = process_template $container,
    message => $html,
    container_attrs => $container_attrs;

  return $self->view->raw($navigation_line);
}

1;