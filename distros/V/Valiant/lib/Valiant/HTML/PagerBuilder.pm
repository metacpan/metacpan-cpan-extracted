package Valiant::HTML::PagerBuilder;

use Moo;
use Module::Runtime ();
use Valiant::Util 'process_template';
use Carp 'croak';

has model => (is=>'ro', required=>1);
has pager => (is=>'ro', required=>1, lazy=>1, builder=>1);
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
    $self->model->model_name->human(count=>2) :
    $self->model->model_name->human(count=>1);

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

sub page_query_key {
  my ($self) = @_;
  return $self->name.'.page';
}

sub navigation_line {
  my $self = shift;
  my $link_generator = shift if (ref($_[0])||'') eq 'CODE';

  unless($link_generator) {
    my $uri_base = $self->has_uri_base ?
      $self->uri_base :
      croak "A Link generator must exist if there's no uri_base"; # Maybe $self->view->ctx->request->uri_base;
    
    $uri_base->query_param_delete($self->page_query_key); # delete defaults

    $link_generator = sub {
      my ($view, $pb, $page_num, $pager, $model) = @_;
      my $uri = $uri_base->clone;
      $uri->query_param_append($pb->page_query_key=>$page_num);
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
  return $self->process_window_info($none) unless $self->pager->last_page > 1;   

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

=head1 NAME

Valiant::HTML::PagerBuilder - A Perl module for building HTML paginators

=head1 SYNOPSIS

  use Valiant::HTML::PagerBuilder;

  my $pager_builder = Valiant::HTML::PagerBuilder->new(
    model => $model,
    pager => $pager_object,
  );

  my $window_info_html = $pager_builder->window_info(%args);

  my $navigation_line_html = $pager_builder->navigation_line(%args);

=head1 DESCRIPTION

The C<Valiant::HTML::PagerBuilder> module is designed for building HTML paginators for web applications. It provides methods for generating window information and navigation lines for paginated data.

=head1 CONSTRUCTOR

=over 4

=item new

Creates a new C<Valiant::HTML::PagerBuilder> object.

  my $pager_builder = Valiant::HTML::PagerBuilder->new(
    model => $model,
    pager => $pager_object,
  );

The constructor accepts the following parameters:

=over 4

=item model (required)

The model object representing the data to be paginated.

=item pager (required)

The pager object used for pagination.

=item uri_base (optional)

The base URI for the paginator's navigation links.  Should be a L<URI> object.

=back

=back

=head1 METHODS

This class supports the following public methods:

=head2 window_info

Generates window information HTML for the paginator.

  my $window_info_html = $pager_builder->window_info(%args);

The C<window_info> method accepts a hash of arguments, which can include custom window
 information templates. It generates HTML for the paginator's window information.

Where args are:

=over 4

=item none

The template for the window information when there are no entries to paginate.

=item one

The template for the window information when there is only one entry to paginate.

=item many

The template for the window information when there are multiple entries to paginate.

=item container

The template for the window information container.

=item container_attrs

The attributes for the window information container.

=back

=head2 navigation_line

Generates navigation line HTML for the paginator.

  my $navigation_line_html = $pager_builder->navigation_line(%args);

The C<navigation_line> method accepts a hash of arguments, which can include custom navigation
 line templates. It generates HTML for the paginator's navigation line.

Where args are:

=over 4

=item none

The template for the navigation line when there are no entries to paginate.

=item page

The template for the navigation line when there are multiple pages to paginate.

=item page_attrs

The attributes for the navigation line pages.

=item current_page

The template for the navigation line when the current page is selected.

=item current_page_attrs

The attributes for the navigation line current page.

=item container

The template for the navigation line container.

=item container_attrs

The attributes for the navigation line container.

=back

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>, L<Valiant::HTML::Util::FormTags>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut