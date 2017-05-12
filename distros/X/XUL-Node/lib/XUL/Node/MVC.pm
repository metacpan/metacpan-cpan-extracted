package XUL::Node::MVC;

use strict;
use warnings;
use Carp;
use Aspect;
use Aspect::Library::Listenable;
use XUL::Node;
use XUL::Node::Model::Value;

# node value model support ----------------------------------------------------

before {
	# TODO: no way to remove model

	my $context         = shift;
	my $view            = $context->self;
	my $key             = $context->params_ref->[1];
	my $value           = $context->params_ref->[2];
	my $tied            = tied $context->params_ref->[2];
	my $model           = get_models($view) && get_models($view)->{$key};
	my $is_simple_value =
		(!$tied && !is_value_model($value)) ||
		($tied && !is_value_model($tied));

	if ($is_simple_value) {
		return unless $model;
		$context->return_value($value);
		$model->value($value);
		return;
	}

	if ($model) { remove_model($view, $key) }
	else        { init_models($view) }

	$model = $tied || $value;
	$context->params($view, $key, $model->value);
	set_model($view, $key, $model);

} call 'XUL::Node::set_attribute';

before { remove_all_models(shift->self) } call 'XUL::Node::destroy';

sub init_models ($) {
	my $view = shift;
	return if get_models($view);
	$view->{get_models_key()} = {};
}

# bind a view attribute to a model
sub set_model ($$$) {
	my ($view, $key, $model) = @_;
	# when model fires Change, call _$key on view, with one param:
	# the value of the model
	add_listener $model, Change => ["_$key", $view, [qw(value)]];
	get_models($view)->{$key} = $model;
}

sub remove_model ($$) {
	my ($view, $key) = @_;
	my $models = get_models($view);
	my $old_model = $models->{$key};
	return unless $old_model;

	remove_listener $old_model, Change => $view;
	delete $models->{$key};
}

sub remove_all_models ($) {
	my $view = shift;
	my $models = get_models($view);
	remove_model($view, $_) for keys %$models;
}

sub get_models     ($) { shift->{get_models_key()} }
sub get_models_key ()  { __PACKAGE__. '_value_models' }
sub is_value_model ($) { UNIVERSAL::isa(shift, 'XUL::Node::Model::Value') }

# exporting -------------------------------------------------------------------

my @MODEL_CLASSES = qw(Value);

sub import {
	my $class   = shift;
	my $package = caller();
	my @widgets = @_;
	no strict 'refs';

	# export model factories and attributes
	for my $name (@MODEL_CLASSES) {
		my $model_class = "XUL::Node::Model::$name";
		my $import_name = "${package}::$name";
		# import the model attribtue
		eval qq{
			use Attribute::Handlers autotieref =>
				{'$import_name', '$model_class'}
		};
		croak "cannot import attributes: [$@]" if $@;
		# import model factory subs
		*{"${import_name}Model"} = sub {
			my %params = @_;
			if (exists $params{tie}) {
				delete $params{tie};
				my $index;
				for my $i (0..@_ - 1) { if($_[$i] eq 'tie') { $index = $i; last } }
				my $tied = \$_[$index + 1];
				return tie $$tied, $model_class, %params;
			}
			return $model_class->new(%params);
		}
	}

	# add all XUL::Node stuff so YOU don't have to import it
	for my $name (@XUL::Node::EXPORT) { *{"${package}::$name"} = *{"$name"} }

	# export all custom widgets
	XUL::Node::import_widgets($package, @widgets);
}

1;














