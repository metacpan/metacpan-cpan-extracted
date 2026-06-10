package Zuzu::Module::GUI::Objects;

use utf8;

our $VERSION = '0.003000';

use File::Spec;
use Scalar::Util qw( blessed refaddr );
use Time::HiRes qw( time );

use Zuzu::Value::Array;
use Zuzu::Value::Dict;
use Zuzu::Value::Function;
use Zuzu::Weak qw( slot_value store_value );
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

sub _runtime_error {
	my ( $code, $message ) = @_;

	die "$code: $message";
}

sub _class_name {
	my ( $object ) = @_;

	return '' if !blessed($object) or !$object->isa('Zuzu::Value::Object');
	return '' if !defined $object->class;
	return $object->class->name // '';
}

sub _is_menu_kind {
	my ( $object ) = @_;

	my $kind = _class_name($object);
	return $kind eq 'Menu' or $kind eq 'MenuItem';
}

sub _is_widget {
	my ( $object ) = @_;

	return 0 if !blessed($object) or !$object->isa('Zuzu::Value::Object');
	my $class = $object->class;
	while ($class) {
		return 1 if ( $class->name // '' ) eq 'Widget';
		$class = $class->parent;
	}

	return 0;
}

sub _is_function {
	my ( $value ) = @_;

	return blessed($value) && $value->isa('Zuzu::Value::Function');
}

sub _zarray {
	my ( @items ) = @_;

	return Zuzu::Value::Array->new( items => \@items );
}

sub _zdict {
	my ( %map ) = @_;

	return Zuzu::Value::Dict->new( map => \%map );
}

sub _copy_array {
	my ( $array ) = @_;

	return _zarray( @{ $array->items } );
}

sub _default_slots {
	my ( %args ) = @_;

	return {
		_id => $args{id},
		_parent => undef,
		_children => _zarray(),
		_visible => exists $args{visible} ? $args{visible} : 1,
		_enabled => exists $args{enabled} ? $args{enabled} : 1,
		_width => $args{width},
		_height => $args{height},
		_minwidth => $args{minwidth},
		_minheight => $args{minheight},
		_maxwidth => $args{maxwidth},
		_maxheight => $args{maxheight},
		_classes => _zarray(),
		_style => _zdict(),
		_meta => _zdict(),
		_listeners => {},
		_listener_seq => 0,
		_widget_type => $args{widget_type},
	};
}

sub _validate_props {
	my ( $class_name, $named, $allowed ) = @_;

	for my $key ( sort keys %{ $named // {} } ) {
		next if $allowed->{$key};
		_runtime_error(
			'GUI_PROP_UNKNOWN',
			"$class_name does not accept property '$key'",
		);
	}
}

sub _bool_prop {
	my ( $named, $name, $default ) = @_;

	return $default if !exists $named->{$name};
	return zuzu_bool( $named->{$name}, $default ) ? 1 : 0;
}

sub _string_prop {
	my ( $named, $name, $default ) = @_;

	return $default if !exists $named->{$name};
	return undef if !defined $named->{$name};
	return "$named->{$name}";
}

sub _number_prop {
	my ( $named, $name, $default ) = @_;

	return $default if !exists $named->{$name};
	return 0 + ( $named->{$name} // 0 );
}

sub _optional_number_prop {
	my ( $named, $name ) = @_;

	return undef if !exists $named->{$name};
	return undef if !defined $named->{$name};
	return 0 + $named->{$name};
}

sub _weekday_prop {
	my ( $named, $name, $default ) = @_;

	my $value = _number_prop( $named, $name, $default );
	_runtime_error(
		'GUI_PROP_TYPE',
		"$name property expects an integer from 0 to 6",
	) if $value < 0 or $value > 6 or int($value) != $value;
	return int($value);
}

sub _is_leap_year {
	my ( $year ) = @_;

	return 1 if $year % 400 == 0;
	return 0 if $year % 100 == 0;
	return $year % 4 == 0 ? 1 : 0;
}

sub _days_in_month {
	my ( $year, $month ) = @_;

	return 31 if $month == 1 or $month == 3 or $month == 5
		or $month == 7 or $month == 8 or $month == 10 or $month == 12;
	return 30 if $month == 4 or $month == 6 or $month == 9 or $month == 11;
	return _is_leap_year($year) ? 29 : 28 if $month == 2;
	return 0;
}

sub _today_date {
	my @date = localtime(time);
	return sprintf '%04d-%02d-%02d', $date[5] + 1900, $date[4] + 1, $date[3];
}

sub _validate_date {
	my ( $value, $prop ) = @_;

	return undef if !defined $value;
	$value = "$value";
	return undef if $value eq '';
	_runtime_error(
		'GUI_PROP_TYPE',
		"$prop property expects a date in YYYY-MM-DD format",
	) if $value !~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;

	my ( $year, $month, $day ) = ( 0 + $1, 0 + $2, 0 + $3 );
	_runtime_error(
		'GUI_PROP_TYPE',
		"$prop property expects a valid calendar date",
	) if $month < 1 or $month > 12
		or $day < 1
		or $day > _days_in_month( $year, $month );

	return $value;
}

sub _date_prop {
	my ( $named, $name, $default ) = @_;

	return $default if !exists $named->{$name};
	return _validate_date( $named->{$name}, $name );
}

sub _date_parts {
	my ( $value ) = @_;

	$value = _validate_date( $value, 'value' ) // _today_date();
	$value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
	return ( 0 + $1, 0 + $2, 0 + $3 );
}

sub _date_from_parts {
	my ( $year, $month, $day ) = @_;

	return sprintf '%04d-%02d-%02d', $year, $month, $day;
}

sub _check_date_range {
	my ( $widget, $value ) = @_;

	return _check_date_range_slots( $widget->slots, $value );
}

sub _check_date_range_slots {
	my ( $slots, $value ) = @_;

	my $min = $slots->{_min};
	my $max = $slots->{_max};
	_runtime_error( 'GUI_PROP_TYPE', 'DatePicker min is after max' )
		if defined $min and defined $max and $min gt $max;
	return if !defined $value;
	_runtime_error( 'GUI_PROP_TYPE', 'value is before DatePicker min' )
		if defined $min and $value lt $min;
	_runtime_error( 'GUI_PROP_TYPE', 'value is after DatePicker max' )
		if defined $max and $value gt $max;
	return;
}

sub _array_prop {
	my ( $named, $name, $default ) = @_;

	return $default if !exists $named->{$name};
	_runtime_error( 'GUI_PROP_TYPE', "$name property expects an Array" )
		if defined $named->{$name}
		and ( !blessed( $named->{$name} )
			or !$named->{$name}->isa('Zuzu::Value::Array') );
	return $named->{$name};
}

sub _enum_prop {
	my ( $class_name, $named, $name, $default, @allowed ) = @_;

	my $value = _string_prop( $named, $name, $default );
	my %allowed = map { $_ => 1 } @allowed;
	_runtime_error(
		'GUI_PROP_TYPE',
		"$class_name property '$name' must be one of: " . join( ', ', @allowed ),
	) if defined $value and !$allowed{$value};

	return $value;
}

sub _native_widget {
	my ( $class, $slots ) = @_;

	return native_object(
		class => $class,
		slots => $slots,
	);
}

sub _slot {
	my ( $object, $name ) = @_;

	return undef if !blessed($object) or !$object->isa('Zuzu::Value::Object');
	return slot_value( \$object->slots->{$name} );
}

sub _set_slot {
	my ( $object, $name, $value, $weak ) = @_;

	return if !blessed($object) or !$object->isa('Zuzu::Value::Object');
	$object->weak->{$name} = $weak ? 1 : 0;
	store_value( \$object->slots->{$name}, $value, $weak ? 1 : 0 );
	return $value;
}

sub _parent {
	my ( $widget ) = @_;

	return _slot( $widget, '_parent' );
}

sub _set_parent {
	my ( $child, $parent ) = @_;

	_set_slot( $child, '_parent', $parent, 1 );
	return;
}

sub _remove_child_ref {
	my ( $parent, $child ) = @_;

	my @kept = grep { $_ != $child } @{ $parent->slots->{_children}->items };
	$parent->slots->{_children}->items( \@kept );
	return;
}

sub _adopt_child {
	my ( $parent, $child ) = @_;

	_runtime_error( 'GUI_PROP_TYPE', 'add_child expects a Widget' )
		if !_is_widget($child);

	my $parent_kind = _class_name($parent);
	my $child_kind = _class_name($child);
	_runtime_error( 'GUI_PROP_TYPE', 'Menu widgets can only be Window children' )
		if $child_kind eq 'Menu' and $parent_kind ne 'Window';
	_runtime_error( 'GUI_PROP_TYPE', 'MenuItem widgets can only be Menu children' )
		if $child_kind eq 'MenuItem' and $parent_kind ne 'Menu';
	_runtime_error(
		'GUI_PROP_TYPE',
		'Menu widgets can only contain MenuItem children',
	)
		if $parent_kind eq 'Menu' and $child_kind ne 'MenuItem';
	_runtime_error( 'GUI_PROP_TYPE', 'MenuItem widgets cannot have children' )
		if $parent_kind eq 'MenuItem';

	my $old_parent = _parent($child);
	_remove_child_ref( $old_parent, $child )
		if defined $old_parent and $old_parent != $parent;

	my $children = $parent->slots->{_children}->items;
	push @{ $children }, $child if !grep { $_ == $child } @{ $children };
	_set_parent( $child, $parent );
	if ( $parent_kind eq 'RadioGroup' and $child_kind eq 'Radio' ) {
		if ( defined $parent->slots->{_value} ) {
			_sync_radio_group_value( $parent, $parent->slots->{_value} );
		}
		elsif ( $child->slots->{_checked} ) {
			_sync_radio_group_value( $parent, $child->slots->{_value} );
		}
	}
	elsif ( $parent_kind eq 'Tabs' and $child_kind eq 'Tab' ) {
		if ( defined $parent->slots->{_selected} ) {
			_sync_tabs_selected( $parent, $parent->slots->{_selected} );
		}
		elsif ( $child->slots->{_selected} ) {
			_sync_tabs_selected( $parent, $child->slots->{_value} );
		}
	}
	elsif ( $child_kind eq 'Radio' and $child->slots->{_checked} ) {
		_set_radio_checked( $child, 1 );
	}
	return;
}

sub _install_children {
	my ( $parent, $children ) = @_;

	return if !defined $children;
	_runtime_error( 'GUI_PROP_TYPE', 'children property expects an Array' )
		if !blessed($children) or !$children->isa('Zuzu::Value::Array');

	for my $child ( @{ $children->items } ) {
		_adopt_child( $parent, $child );
	}
	return;
}

sub _remove_class {
	my ( $self, $class_name ) = @_;

	$class_name = defined $class_name ? "$class_name" : '';
	my @kept = grep { $_ ne $class_name } @{ $self->slots->{_classes}->items };
	$self->slots->{_classes}->items( \@kept );
	return;
}

sub _make_event {
	my ( $event_class, $name, $target, $data ) = @_;

	my $event = native_object(
		class => $event_class,
		slots => {
			name => defined $name ? "$name" : '',
			target => undef,
			current_target => undef,
			timestamp => time(),
			data => $data,
			cancelled => 0,
			propagation_stopped => 0,
			default_prevented => 0,
			phase => '',
		},
	);
	_set_slot( $event, 'target', $target, 1 );
	_set_slot( $event, 'current_target', undef, 1 );
	return $event;
}

sub _call_handler {
	my ( $runtime, $handler, $event ) = @_;

	my $params = $handler->params // [];
	my $vararg = $handler->vararg;
	my @args = ( !@{ $params } and !defined $vararg ) ? () : ($event);

	return $runtime->_call_function(
		$handler,
		\@args,
		{},
		[],
		$runtime->{_native_call_file} // '<runtime>',
		$runtime->{_native_call_line} // 0,
	);
}

sub _dispatch_at {
	my ( $runtime, $widget, $event, $name, $phase, $errors ) = @_;

	my $listeners = $widget->slots->{_listeners}{$name} // [];
	return if !@{ $listeners };

	_set_slot( $event, 'current_target', $widget, 1 );
	$event->slots->{phase} = $phase;

	my @remaining;
	for my $listener ( @{ $listeners } ) {
		if ( $phase eq 'capture' and !$listener->{capture} ) {
			push @remaining, $listener;
			next;
		}
		if ( !$listener->{once_done} ) {
			eval {
				_call_handler( $runtime, $listener->{handler}, $event );
				1;
			} or do {
				push @{ $errors }, $@ || 'unknown handler error';
			};
		}
		$listener->{once_done} = 1 if $listener->{once};
		push @remaining, $listener if !$listener->{once_done};
		last if $event->slots->{propagation_stopped};
	}

	$widget->slots->{_listeners}{$name} = \@remaining;
	return;
}

sub _dispatch_event {
	my ( $runtime, $source, $event ) = @_;

	my $name = $event->slots->{name};
	my @path;
	my $node = $source;
	while ( defined $node ) {
		push @path, $node;
		$node = _parent($node);
	}

	my @errors;
	for ( my $i = $#path; $i > 0; $i-- ) {
		_dispatch_at( $runtime, $path[$i], $event, $name, 'capture', \@errors );
		last if $event->slots->{propagation_stopped};
	}

	if ( !$event->slots->{propagation_stopped} ) {
		_dispatch_at( $runtime, $source, $event, $name, 'target', \@errors );
	}

	for ( my $i = 1; $i <= $#path; $i++ ) {
		last if $event->slots->{propagation_stopped};
		_dispatch_at( $runtime, $path[$i], $event, $name, 'bubble', \@errors );
	}

	if (@errors) {
		my $message = join '; ', map { "$_" } @errors;
		_runtime_error( 'GUI_EVENT_HANDLER', $message );
	}

	return $event;
}

sub _owner_window {
	my ($widget) = @_;

	while ( defined $widget and _is_widget($widget) ) {
		return $widget if _class_name($widget) eq 'Window';
		$widget = _parent($widget);
	}

	return undef;
}

sub _find_by_id {
	my ( $widget, $id ) = @_;

	return $widget if defined $widget->slots->{_id}
		and defined $id
		and $widget->slots->{_id} eq "$id";

	for my $child ( @{ $widget->slots->{_children}->items } ) {
		my $found = _find_by_id( $child, $id );
		return $found if defined $found;
	}

	return undef;
}

sub _listener_token {
	my ( $class, $widget, $event, $id ) = @_;

	my $token = native_object(
		class => $class,
		slots => {
			_widget => undef,
			_event => $event,
			_id => $id,
		},
	);
	_set_slot( $token, '_widget', $widget, 1 );
	return $token;
}

sub _add_widget_methods {
	my ( $runtime, $widget_class, $event_class, $listener_token_class ) = @_;

	$widget_class->methods->{id} = native_function(
		name => 'id',
		native => sub { return $_[0]->slots->{_id}; },
	);
	$widget_class->methods->{set_id} = native_function(
		name => 'set_id',
		native => sub {
			my ( $self, $id ) = @_;
			$self->slots->{_id} = defined $id ? "$id" : undef;
			return $self;
		},
	);
	$widget_class->methods->{parent} = native_function(
		name => 'parent',
		native => sub { return _parent( $_[0] ); },
	);
	$widget_class->methods->{children} = native_function(
		name => 'children',
		native => sub { return _copy_array( $_[0]->slots->{_children} ); },
	);
	$widget_class->methods->{add_child} = native_function(
		name => 'add_child',
		native => sub {
			my ( $self, $child ) = @_;
			_adopt_child( $self, $child );
			return $self;
		},
	);
	$widget_class->methods->{remove_child} = native_function(
		name => 'remove_child',
		native => sub {
			my ( $self, $child ) = @_;
			return $self if !_is_widget($child);
			_remove_child_ref( $self, $child );
			_set_parent( $child, undef )
				if defined _parent($child)
				and _parent($child) == $self;
			return $self;
		},
	);
	$widget_class->methods->{enabled} = native_function(
		name => 'enabled',
		native => sub { return $_[0]->slots->{_enabled} ? 1 : 0; },
	);
	$widget_class->methods->{set_enabled} = native_function(
		name => 'set_enabled',
		native => sub {
			my ( $self, $enabled ) = @_;
			$self->slots->{_enabled} = zuzu_bool( $enabled, 1 ) ? 1 : 0;
			return $self;
		},
	);
	$widget_class->methods->{visible} = native_function(
		name => 'visible',
		native => sub { return $_[0]->slots->{_visible} ? 1 : 0; },
	);
	$widget_class->methods->{set_visible} = native_function(
		name => 'set_visible',
		native => sub {
			my ( $self, $visible ) = @_;
			$self->slots->{_visible} = zuzu_bool( $visible, 1 ) ? 1 : 0;
			return $self;
		},
	);
	for my $method_name ( qw(
		width height minwidth minheight maxwidth maxheight
	) ) {
		my $slot = '_' . $method_name;
		$widget_class->methods->{$method_name} = native_function(
			name => $method_name,
			native => sub {
				my ( $self, @args ) = @_;
				if (@args) {
					$self->slots->{$slot} = defined $args[0]
						? 0 + $args[0]
						: undef;
					_refresh_native($self);
					return $self;
				}
				return $self->slots->{$slot};
			},
		);
	}
	$widget_class->methods->{classes} = native_function(
		name => 'classes',
		native => sub { return _copy_array( $_[0]->slots->{_classes} ); },
	);
	$widget_class->methods->{add_class} = native_function(
		name => 'add_class',
		native => sub {
			my ( $self, $class_name ) = @_;
			$class_name = defined $class_name ? "$class_name" : '';
			my $items = $self->slots->{_classes}->items;
			push @{ $items }, $class_name if !grep { $_ eq $class_name } @{ $items };
			return $self;
		},
	);
	$widget_class->methods->{remove_class} = native_function(
		name => 'remove_class',
		native => sub {
			my ( $self, $class_name ) = @_;
			_remove_class( $self, $class_name );
			return $self;
		},
	);
	for my $method_name ( qw( style meta ) ) {
		my $slot = '_' . $method_name;
		$widget_class->methods->{$method_name} = native_function(
			name => $method_name,
			native => sub {
				my ( $self, $key, @rest ) = @_;
				$key = defined $key ? "$key" : '';
				my $map = $self->slots->{$slot}->map;
				if (@rest) {
					$map->{$key} = $rest[0];
					return $self;
				}
				return exists $map->{$key} ? $map->{$key} : undef;
			},
		);
	}

	$widget_class->methods->{on} = native_function(
		name => 'on',
		native => sub {
			my ( $self, $name, $handler ) = @_;
			_runtime_error( 'GUI_EVENT_HANDLER', 'on expects a Function handler' )
				if !_is_function($handler);
			$name = defined $name ? "$name" : '';
			my $id = ++$self->slots->{_listener_seq};
			push @{ $self->slots->{_listeners}{$name} }, {
				id => $id,
				handler => $handler,
				once => 0,
				once_done => 0,
				capture => 0,
			};
			return _listener_token( $listener_token_class, $self, $name, $id );
		},
	);
	$widget_class->methods->{once} = native_function(
		name => 'once',
		native => sub {
			my ( $self, $name, $handler ) = @_;
			_runtime_error( 'GUI_EVENT_HANDLER', 'once expects a Function handler' )
				if !_is_function($handler);
			$name = defined $name ? "$name" : '';
			my $id = ++$self->slots->{_listener_seq};
			push @{ $self->slots->{_listeners}{$name} }, {
				id => $id,
				handler => $handler,
				once => 1,
				once_done => 0,
				capture => 0,
			};
			return _listener_token( $listener_token_class, $self, $name, $id );
		},
	);
	$widget_class->methods->{off} = native_function(
		name => 'off',
		native => sub {
			my ( $self, $token ) = @_;
			return 0 if !blessed($token) or !$token->isa('Zuzu::Value::Object');
			return 0 if ( _slot( $token, '_widget' ) // undef ) != $self;
			my $name = $token->slots->{_event};
			my $id = $token->slots->{_id};
			my $listeners = $self->slots->{_listeners}{$name} // [];
			my $before = scalar @{ $listeners };
			my @kept = grep { $_->{id} != $id } @{ $listeners };
			$self->slots->{_listeners}{$name} = \@kept;
			return scalar(@kept) == $before ? 0 : 1;
		},
	);
	$widget_class->methods->{emit} = native_function(
		name => 'emit',
		native => sub {
			my ( $self, $name, $payload ) = @_;
			$name = defined $name ? "$name" : '';
			my $event;
			if (
				blessed($payload)
				and $payload->isa('Zuzu::Value::Object')
				and _class_name($payload) eq 'Event'
			) {
				$event = $payload;
				$event->slots->{name} = $name if !defined $event->slots->{name};
				_set_slot( $event, 'target', $self, 1 )
					if !defined _slot( $event, 'target' );
			}
			else {
				$event = _make_event( $event_class, $name, $self, $payload );
			}
			return _dispatch_event( $runtime, $self, $event );
		},
	);
	$widget_class->methods->{find_by_id} = native_function(
		name => 'find_by_id',
		native => sub {
			my ( $self, $id ) = @_;
			return _find_by_id( $self, $id );
		},
	);

	for my $event_name ( qw(
		activate blur change click close_request closed collapse enter
		expand focus input open resize select submit
	) ) {
		$widget_class->methods->{$event_name} = native_function(
			name => $event_name,
				native => sub {
					my ( $self, @args ) = @_;
					if (@args) {
						my $on = $runtime->_lookup_method(
							$self->class,
							'on',
							0,
						);
						return $on->{_native}->(
							$self,
							$event_name,
							$args[0],
						);
					}
					my $emit = $runtime->_lookup_method(
						$self->class,
						'emit',
						0,
					);
					return $emit->{_native}->(
						$self,
						$event_name,
					);
			},
		);
	}
}

sub _add_event_methods {
	my ( $event_class ) = @_;

	for my $method_name ( qw(
		name target current_target phase timestamp data cancelled
		propagation_stopped default_prevented
	) ) {
		$event_class->methods->{$method_name} = native_function(
			name => $method_name,
			native => sub { return _slot( $_[0], $method_name ); },
		);
	}
	$event_class->methods->{window} = native_function(
		name => 'window',
		native => sub {
			my ($self) = @_;
			return _owner_window( _slot( $self, 'target' ) );
		},
	);
	$event_class->methods->{stop_propagation} = native_function(
		name => 'stop_propagation',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{propagation_stopped} = 1;
			$self->slots->{cancelled} = 1;
			return $self;
		},
	);
	$event_class->methods->{prevent_default} = native_function(
		name => 'prevent_default',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{default_prevented} = 1;
			$self->slots->{cancelled} = 1;
			return $self;
		},
	);
}

sub _widget_constructor {
	my ( $class_name, $widget_type, $extra_allowed, $slot_builder ) = @_;

	return sub {
		my ( $runtime, $klass, $positional, $named ) = @_;
		my %allowed = map { $_ => 1 } qw(
			id visible enabled classes style meta children disabled
			width height minwidth minheight maxwidth maxheight
		);
		$allowed{$_} = 1 for @{ $extra_allowed // [] };
		_validate_props( $class_name, $named, \%allowed );

		my $enabled = exists $named->{disabled}
			? ( zuzu_bool( $named->{disabled}, 0 ) ? 0 : 1 )
			: _bool_prop( $named, 'enabled', 1 );
		my $slots = _default_slots(
			id => _string_prop( $named, 'id', undef ),
			visible => _bool_prop( $named, 'visible', 1 ),
			enabled => $enabled,
			width => _optional_number_prop( $named, 'width' ),
			height => _optional_number_prop( $named, 'height' ),
			minwidth => _optional_number_prop( $named, 'minwidth' ),
			minheight => _optional_number_prop( $named, 'minheight' ),
			maxwidth => _optional_number_prop( $named, 'maxwidth' ),
			maxheight => _optional_number_prop( $named, 'maxheight' ),
			widget_type => $widget_type,
		);
		$slot_builder->( $slots, $named ) if $slot_builder;

		my $object = _native_widget( $klass, $slots );
		if ( exists $named->{classes} and blessed($named->{classes})
			and $named->{classes}->isa('Zuzu::Value::Array') ) {
			$object->slots->{_classes} = _copy_array( $named->{classes} );
		}
		if ( exists $named->{style} and blessed($named->{style})
			and $named->{style}->isa('Zuzu::Value::Dict') ) {
			$object->slots->{_style} = $named->{style};
		}
		if ( exists $named->{meta} and blessed($named->{meta})
			and $named->{meta}->isa('Zuzu::Value::Dict') ) {
			$object->slots->{_meta} = $named->{meta};
		}

		my @children = @{ $positional // [] };
		push @children, @{ $named->{children}->items }
			if exists $named->{children}
			and blessed($named->{children})
			and $named->{children}->isa('Zuzu::Value::Array');
		_install_children( $object, _zarray(@children) ) if @children;
		if ( exists $slots->{_content} ) {
			my $content = $named->{content};
			if ( !defined $content and @children ) {
				for my $child (@children) {
					next if _is_menu_kind($child);
					$content = $child;
					last;
				}
			}
			if ( defined $content ) {
				_runtime_error(
					'GUI_PROP_TYPE',
					'content property expects a non-menu Widget or null',
				) if !_is_widget($content) or _is_menu_kind($content);
				$object->slots->{_content} = $content;
				_adopt_child( $object, $content );
			}
		}

		return $object;
	};
}

sub _add_text_methods {
	my ( $class, $slot, $getter, $setter ) = @_;

	$class->methods->{$getter} = native_function(
		name => $getter,
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{$slot} = defined $args[0] ? "$args[0]" : '';
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{$slot};
		},
	);
	$class->methods->{$setter} = native_function(
		name => $setter,
		native => sub {
			my ( $self, $value ) = @_;
			$self->slots->{$slot} = defined $value ? "$value" : '';
			_refresh_native($self);
			return $self;
		},
	);
}

sub _add_bool_method {
	my ( $class, $slot, $method ) = @_;

	$class->methods->{$method} = native_function(
		name => $method,
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{$slot} = zuzu_bool( $args[0], 0 ) ? 1 : 0;
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{$slot} ? 1 : 0;
		},
	);
}

sub _add_number_method {
	my ( $class, $slot, $method ) = @_;

	$class->methods->{$method} = native_function(
		name => $method,
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{$slot} = 0 + ( $args[0] // 0 );
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{$slot};
		},
	);
}

sub _add_getter {
	my ( $class, $slot, $method ) = @_;

	$class->methods->{$method} = native_function(
		name => $method,
		native => sub { return $_[0]->slots->{$slot}; },
	);
}

sub _nearest_radio_group {
	my ( $radio ) = @_;

	my $node = _parent($radio);
	while ( defined $node ) {
		return $node if _class_name($node) eq 'RadioGroup';
		$node = _parent($node);
	}

	return undef;
}

sub _find_root {
	my ( $widget ) = @_;

	my $node = $widget;
	while ( defined _parent($node) ) {
		$node = _parent($node);
	}
	return $node;
}

sub _walk_widgets {
	my ( $widget, $callback ) = @_;

	$callback->($widget);
	for my $child ( @{ $widget->slots->{_children}->items } ) {
		_walk_widgets( $child, $callback );
	}
	return;
}

sub _sync_radio_group_value {
	my ( $group, $value ) = @_;

	$group->slots->{_value} = defined $value ? "$value" : undef;
	for my $child ( @{ $group->slots->{_children}->items } ) {
		next if _class_name($child) ne 'Radio';
		my $child_value = $child->slots->{_value};
		$child->slots->{_checked} = (
			defined $value
			and defined $child_value
			and "$child_value" eq "$value"
		) ? 1 : 0;
		_refresh_native($child);
	}
	return;
}

sub _set_radio_checked {
	my ( $radio, $checked ) = @_;

	$radio->slots->{_checked} = $checked ? 1 : 0;
	return if !$checked;

	my $group = _nearest_radio_group($radio);
	if ($group) {
		_sync_radio_group_value( $group, $radio->slots->{_value} );
		return;
	}

	my $group_name = $radio->slots->{_group};
	return if !defined $group_name or $group_name eq '';

	my $root = _find_root($radio);
	_walk_widgets(
		$root,
		sub {
			my ( $candidate ) = @_;
			return if $candidate == $radio;
			return if _class_name($candidate) ne 'Radio';
		return if !defined $candidate->slots->{_group};
		return if $candidate->slots->{_group} ne $group_name;
		$candidate->slots->{_checked} = 0;
		_refresh_native($candidate);
	},
	);
	return;
}

sub _nearest_tabs {
	my ( $tab ) = @_;

	my $node = _parent($tab);
	while ( defined $node ) {
		return $node if _class_name($node) eq 'Tabs';
		$node = _parent($node);
	}

	return undef;
}

sub _sync_tabs_selected {
	my ( $tabs, $selected ) = @_;

	$tabs->slots->{_selected} = defined $selected ? "$selected" : undef;
	for my $child ( @{ $tabs->slots->{_children}->items } ) {
		next if _class_name($child) ne 'Tab';
		my $child_value = $child->slots->{_value};
		$child->slots->{_selected} = (
			defined $selected
			and defined $child_value
			and "$child_value" eq "$selected"
		) ? 1 : 0;
		_refresh_native($child);
	}
	_refresh_native($tabs);
	return;
}

sub _set_tab_selected {
	my ( $tab, $selected ) = @_;

	$tab->slots->{_selected} = $selected ? 1 : 0;
	return if !$selected;

	my $tabs = _nearest_tabs($tab);
	_sync_tabs_selected( $tabs, $tab->slots->{_value} ) if $tabs;
	return;
}

sub _path_key {
	my ( $path ) = @_;

	return join '/', @{ $path // [] };
}

sub _mark_tree_expanded {
	my ( $items, $prefix, $expanded ) = @_;

	for ( my $i = 0; $i < @{ $items->items }; $i++ ) {
		my $item = $items->items->[$i];
		my @path = ( @{ $prefix // [] }, $i );
		my $children = _tree_children($item);
		next if !@{ $children->items };
		$expanded->{ _path_key(\@path) } = [@path];
		_mark_tree_expanded( $children, \@path, $expanded );
	}
	return;
}

sub _item_label {
	my ( $item ) = @_;

	if ( blessed($item) and $item->isa('Zuzu::Value::Dict') ) {
		my $label = $item->map->{label};
		my $value = $item->map->{value};
		return defined $label ? "$label" : "$value";
	}

	return defined $item ? "$item" : '';
}

sub _item_at_index {
	my ( $widget, $index ) = @_;

	return undef if !defined $index;
	return $widget->slots->{_items}->items->[$index];
}

sub _path_indexes {
	my ( $path ) = @_;

	return [] if !defined $path;
	_runtime_error( 'GUI_PROP_TYPE', 'selected_path expects an Array' )
		if !blessed($path) or !$path->isa('Zuzu::Value::Array');
	return [ map { 0 + ( $_ // 0 ) } @{ $path->items } ];
}

sub _tree_children {
	my ( $item ) = @_;

	return _zarray() if !blessed($item) or !$item->isa('Zuzu::Value::Dict');
	my $children = $item->map->{children};
	return $children
		if blessed($children) and $children->isa('Zuzu::Value::Array');
	return _zarray();
}

sub _tree_item_at_path {
	my ( $tree, $path ) = @_;

	my $items = $tree->slots->{_items};
	my $item;
	for my $index ( @{ $path // [] } ) {
		return undef if $index < 0 or $index >= @{ $items->items };
		$item = $items->items->[$index];
		$items = _tree_children($item);
	}

	return $item;
}

sub _flatten_tree_items {
	my ( $items, $depth, $prefix, $labels, $paths, $expanded ) = @_;

	for ( my $i = 0; $i < @{ $items->items }; $i++ ) {
		my $item = $items->items->[$i];
		my @path = ( @{ $prefix // [] }, $i );
		my $key = _path_key(\@path);
		push @{ $paths }, \@path;
		push @{ $labels }, ( '  ' x $depth ) . _item_label($item);
		next if defined $expanded and !exists $expanded->{$key};
		_flatten_tree_items(
			_tree_children($item),
			$depth + 1,
			\@path,
			$labels,
			$paths,
			$expanded,
		);
	}
	return;
}

my $PRIMA_READY = 0;
my $PRIMA_FONT;

sub _prima_std_bitmap_warning {
	my ( $message ) = @_;

	return (
		$message =~ /\AFailed to load standard bitmap '.*?sysimage\.gif':/
		and $message =~ /Did you compile Prima with GIF support\?/
	) ? 1 : 0;
}

sub _without_prima_bitmap_warning {
	my ( $code ) = @_;

	my $previous = $SIG{__WARN__};
	local $SIG{__WARN__} = sub {
		my $message = join '', @_;
		return if _prima_std_bitmap_warning($message);
		return $previous->(@_) if $previous;
		CORE::warn(@_);
	};

	if ( wantarray ) {
		return $code->();
	}
	if ( defined wantarray ) {
		return scalar $code->();
	}
	$code->();
	return;
}

sub _prima_application_ready {
	return 0 if !defined $::application or !ref($::application);
	return eval { $::application->alive } ? 1 : 0;
}

sub _ensure_prima_application {
	return 1 if _prima_application_ready();

	_without_prima_bitmap_warning(
		sub {
			eval {
				undef $::application;
				$::application = Prima::Application->create(
					name => 'Zuzu',
				);
				1;
			};
		}
	) or do {
		my $error = $@ || 'unknown Prima application error';
		_runtime_error(
			'GUI_BACKEND',
			"Could not initialize Prima application: $error",
		);
	};

	return 1;
}

sub _load_prima_backend {
	return _ensure_prima_application() if $PRIMA_READY;

	_without_prima_bitmap_warning(
		sub {
			eval q{
				use Prima qw(
					Application
					Buttons
					ComboBox
					Drawable::Markup
					Edit
					InputLine
					Label
					Lists
					Menus
					Outlines
					Dialog::FileDialog
					Sliders
					Widget::Date
				);
				1;
			};
		}
	) or do {
		my $error = $@ || 'unknown Prima load error';
		_runtime_error(
			'GUI_BACKEND',
			"Could not initialize Prima GUI backend: $error",
		);
	};

	$PRIMA_READY = 1;
	_ensure_prima_application();
	return 1;
}

sub _dialog_props {
	my ( $value ) = @_;

	return {} if !defined $value;
	if (
		blessed($value)
		and (
			$value->isa('Zuzu::Value::PairList')
			or $value->isa('Zuzu::Value::Dict')
		)
	) {
		return zuzu_to_perl($value);
	}
	return {};
}

sub _dialog_bool {
	my ( $props, $key, $default ) = @_;

	return $default if !exists $props->{$key};
	return $props->{$key} ? 1 : 0;
}

sub _dialog_string {
	my ( $props, $key, $default ) = @_;

	return $default if !exists $props->{$key};
	return undef if !defined $props->{$key};
	return "$props->{$key}";
}

sub _dialog_filter {
	my ( $props ) = @_;

	return [[ 'All files' => '*' ]] if !exists $props->{filter};
	my $filter = $props->{filter};
	return [[ 'All files' => '*' ]] if ref($filter) ne 'ARRAY';

	my @out;
	for my $entry (@$filter) {
		if ( ref($entry) eq 'ARRAY' ) {
			my ( $label, $mask ) = @$entry;
			push @out, [ defined $label ? "$label" : '', defined $mask ? "$mask" : '*' ];
			next;
		}
		if ( ref($entry) eq 'HASH' ) {
			my $label = $entry->{label} // $entry->{name} // '';
			my $mask = $entry->{mask} // $entry->{pattern} // '*';
			push @out, [ "$label", "$mask" ];
		}
	}

	return @out ? \@out : [[ 'All files' => '*' ]];
}

sub _native_file_dialog_profile {
	my ( $props, $kind ) = @_;

	my $title = _dialog_string(
		$props,
		'title',
		$kind eq 'save' ? 'Save File' : 'Open File',
	);
	my %profile = (
		system => _dialog_bool( $props, 'system', 0 ),
		text => $title,
		fileName => _dialog_string( $props, 'value', '' ),
		filter => _dialog_filter($props),
		showDotFiles => _dialog_bool(
			$props,
			'show_dot_files',
			_dialog_bool( $props, 'show_hidden', 0 ),
		),
	);
	$profile{directory} = "$props->{directory}" if defined $props->{directory};
	$profile{defaultExt} = "$props->{default_ext}" if defined $props->{default_ext};
	$profile{pathMustExist} = _dialog_bool( $props, 'path_must_exist', 1 );

	if ( $kind eq 'open' ) {
		$profile{multiSelect} = _dialog_bool( $props, 'multiple', 0 );
		$profile{fileMustExist} = _dialog_bool( $props, 'file_must_exist', 1 );
		$profile{createPrompt} = _dialog_bool( $props, 'create_prompt', 0 );
	}
	else {
		$profile{fileMustExist} = _dialog_bool( $props, 'file_must_exist', 0 );
		$profile{overwritePrompt} = _dialog_bool( $props, 'overwrite_prompt', 1 );
		$profile{noTestFileCreate} = _dialog_bool( $props, 'no_test_file_create', 0 );
	}
	$profile{font} = _prima_font() if !$profile{system};

	return %profile;
}

sub _apply_prima_font {
	my ( $object, $seen ) = @_;

	return if !defined $object or !ref($object);
	$seen //= {};
	my $id = refaddr($object) // 0;
	return if $id and $seen->{$id}++;

	my $font = _prima_font();
	eval { $object->font($font) if $object->can('font'); 1 };

	if ( $object->can('get_widgets') ) {
		for my $child ( eval { $object->get_widgets } ) {
			_apply_prima_font( $child, $seen );
		}
	}
	return $object;
}

sub _native_file_open {
	my ( $props_value ) = @_;

	my $props = _dialog_props($props_value);
	_load_prima_backend();
	my %profile = _native_file_dialog_profile( $props, 'open' );
	my $dialog = _without_prima_bitmap_warning(
		sub { Prima::Dialog::OpenDialog->new(%profile) }
	);
	_apply_prima_font($dialog);
	if ( $profile{multiSelect} ) {
		my @files = _without_prima_bitmap_warning( sub { $dialog->execute } );
		return @files ? perl_to_zuzu( \@files ) : undef;
	}
	my $file = _without_prima_bitmap_warning( sub { $dialog->execute } );
	return defined $file ? "$file" : undef;
}

sub _native_file_save {
	my ( $props_value ) = @_;

	my $props = _dialog_props($props_value);
	_load_prima_backend();
	my %profile = _native_file_dialog_profile( $props, 'save' );
	my $dialog = _without_prima_bitmap_warning(
		sub { Prima::Dialog::SaveDialog->new(%profile) }
	);
	_apply_prima_font($dialog);
	my $file = _without_prima_bitmap_warning( sub { $dialog->execute } );
	return defined $file ? "$file" : undef;
}

sub _native_directory_open {
	my ( $props_value ) = @_;

	my $props = _dialog_props($props_value);
	_load_prima_backend();
	my $dialog = _without_prima_bitmap_warning(
		sub {
			Prima::Dialog::ChDirDialog->new(
				font => _prima_font(),
				text => _dialog_string( $props, 'title', 'Open Directory' ),
				directory => _dialog_string( $props, 'value', '.' ),
				showDotDirs => _dialog_bool(
					$props,
					'show_dot_dirs',
					_dialog_bool( $props, 'show_hidden', 0 ),
				),
			);
		}
	);
	_apply_prima_font($dialog);
	my $accepted = _without_prima_bitmap_warning(
		sub { $dialog->execute != mb::Cancel }
	);
	return $accepted ? $dialog->directory : undef;
}

sub _native_colour_picker {
	my ( $props_value ) = @_;

	# std/gui/dialogue already provides a validated pure-widget colour
	# picker. Keep the Perl native hook as an unsupported backend hook so
	# callers can fall back without changing the shared API.
	return undef;
}

sub _native_alert {
	return 0;
}

sub _native_confirm {
	return undef;
}

sub _native_prompt {
	return undef;
}

sub _native_directory_save {
	my ( $props_value ) = @_;

	# Prima's available native directory dialog is an existing-directory
	# chooser. Return undef so std/gui/dialogue can use its save-directory
	# fallback on this backend.
	return undef;
}

sub _prima_font {
	return { %{ $PRIMA_FONT } } if defined $PRIMA_FONT;

	my @preferred = (
		'DejaVu Sans',
		'Liberation Sans',
		'FreeSans',
		'Helvetica',
		'helvetica',
		'fixed',
	);
	my %available;
	eval {
		for my $font ( @{ $::application->fonts( '', 'iso8859-1' ) } ) {
			my $name = $font->{name} // '';
			$available{ lc $name } = $name if $name ne '';
		}
		1;
	};

	for my $name (@preferred) {
		next if !exists $available{ lc $name };
		$PRIMA_FONT = {
			name => $available{ lc $name },
			size => 10,
			encoding => 'iso8859-1',
		};
		return { %{ $PRIMA_FONT } };
	}

	$PRIMA_FONT = {
		name => 'DejaVu Sans',
		size => 10,
		encoding => 'iso8859-1',
	};
	return { %{ $PRIMA_FONT } };
}

sub _prima_font_size_pixels {
	my ( $font ) = @_;

	my $height = eval {
		if ($PRIMA_READY) {
			my $probe = Prima::Widget->new( font => $font );
			my $metrics = $probe->font;
			$probe->destroy;
			$metrics->{height};
		}
		else {
			undef;
		}
	};

	return 0 + $height if defined $height and $height =~ /^\d+$/;
	return 16;
}

sub _prima_groupbox_content_pady {
	my $height = _prima_font_size_pixels( _prima_font() );
	return int( $height * 1.5 ) + 6;
}

sub _backend_meta {
	my $font = _prima_font();

	return _zdict(
		backend => 'Prima',
		font_size_pixels => _prima_font_size_pixels($font),
		font_name => $font->{name},
		font_point_size => $font->{size},
	);
}

sub _has_native {
	my ( $widget ) = @_;

	my $native = $widget->slots->{_native};
	return 0 if !defined $native or !ref($native);
	return eval { $native->alive } ? 1 : 0
		if blessed($native) and $native->can('alive');
	return 1;
}

sub _native_text {
	my ( $widget ) = @_;

	my $kind = $widget->slots->{_widget_type} // '';
	return $widget->slots->{_title} if $kind eq 'Window';
	return $widget->slots->{_label} if $kind eq 'Frame';
	return $widget->slots->{_text} if $kind eq 'Label';
	return $widget->slots->{_value} if $kind eq 'Text';
	return $widget->slots->{_value} if $kind eq 'RichText';
	return $widget->slots->{_value} if $kind eq 'Input';
	return $widget->slots->{_value} if $kind eq 'DatePicker';
	return $widget->slots->{_label} if $kind eq 'Checkbox';
	return $widget->slots->{_label} if $kind eq 'Radio';
	return $widget->slots->{_text} if $kind eq 'Button';
	return $widget->slots->{_title} if $kind eq 'Tab';
	return '';
}

sub _decode_html_entities {
	my ( $text ) = @_;

	$text //= '';
	$text =~ s{&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);}{do {
		my $entity = $1;
		if ( $entity =~ /^#x([0-9a-fA-F]+)$/ ) {
			chr(hex($1));
		}
		elsif ( $entity =~ /^#([0-9]+)$/ ) {
			chr($1);
		}
		elsif ( $entity eq 'amp' ) { '&' }
		elsif ( $entity eq 'lt' ) { '<' }
		elsif ( $entity eq 'gt' ) { '>' }
		elsif ( $entity eq 'quot' ) { '"' }
		elsif ( $entity eq 'apos' ) { "'" }
		else { "&$entity;" }
	}}eg;

	return $text;
}

sub _prima_markup_quote {
	my ( $text ) = @_;

	return '' if !defined $text or $text eq '';

	my $depth = 2;
	my $close = '>' x $depth;
	while ( $text =~ /\s\Q$close\E/ ) {
		$depth++;
		$close = '>' x $depth;
	}

	return 'Q<' . ( '<' x ( $depth - 1 ) ) . ' ' . $text . ' '
		. $close;
}

sub _prima_markup_url {
	my ( $url ) = @_;

	$url = _decode_html_entities($url);
	$url =~ s/%/%25/g;
	$url =~ s/\|/%7C/g;
	$url =~ s/</%3C/g;
	$url =~ s/>/%3E/g;
	$url =~ s/\s/%20/g;
	return $url;
}

sub _rich_text_html_to_prima_markup {
	my ( $html ) = @_;

	$html //= '';
	my $out = '';
	my @stack;
	my $last = 0;

	while ( $html =~ m{(<[^>]*>)}g ) {
		my $tag = $1;
		my $text = substr( $html, $last, $-[0] - $last );
		$last = $+[0];

		$out .= _prima_markup_quote( _decode_html_entities($text) );

		if ( $tag =~ m{^<\s*(/)?\s*([A-Za-z][A-Za-z0-9]*)\b([^>]*)>$}s ) {
			my ( $closing, $name, $attrs ) = ( $1, lc($2), $3 // '' );
			$name = 'b' if $name eq 'strong';
			$name = 'i' if $name eq 'em';

			if ( !$closing and $name =~ /^(?:b|i|u)$/ ) {
				$out .= uc($name) . '<';
				push @stack, $name;
				next;
			}

			if ( !$closing and $name eq 'a' ) {
				my $href;
				if ( $attrs =~ /\bhref\s*=\s*"([^"]*)"/is ) {
					$href = $1;
				}
				elsif ( $attrs =~ /\bhref\s*=\s*'([^']*)'/is ) {
					$href = $1;
				}
				elsif ( $attrs =~ /\bhref\s*=\s*([^\s"'=<>`]+)/is ) {
					$href = $1;
				}
				if ( defined $href ) {
					$out .= 'L<' . _prima_markup_url($href) . '|';
					push @stack, 'a';
					next;
				}
			}

			if ( $closing and @stack and $stack[-1] eq $name ) {
				pop @stack;
				$out .= '>';
				next;
			}
		}

		$out .= _prima_markup_quote( _decode_html_entities($tag) );
	}

	$out .= _prima_markup_quote( _decode_html_entities( substr( $html, $last ) ) );
	$out .= '>' while @stack and pop @stack;
	return $out;
}

sub _native_rich_text {
	my ( $widget ) = @_;

	my $markup = _rich_text_html_to_prima_markup(
		$widget->slots->{_value} // '',
	);

	return Prima::Drawable::Markup->new( markup => $markup );
}

sub _refresh_native {
	my ( $widget ) = @_;

	my $kind = $widget->slots->{_widget_type} // '';
	return if !_has_native($widget)
		and !( $kind eq 'MenuItem' and defined $widget->slots->{_native_menu_owner} );
	return if $widget->slots->{_syncing_native};

	my $native = $widget->slots->{_native};
	local $widget->slots->{_syncing_native} = 1;

	eval {
		if ( defined $native ) {
			$native->enabled( $widget->slots->{_enabled} ? 1 : 0 )
				if $native->can('enabled');
			$native->visible( $widget->slots->{_visible} ? 1 : 0 )
				if $native->can('visible');
		}
		if ( $kind eq 'Window' ) {
			$native->text( $widget->slots->{_title} // '' )
				if $native->can('text');
		}
		elsif ( $kind eq 'Frame' ) {
			$native->text( $widget->slots->{_label} // '' )
				if $native->can('text');
		}
		elsif ( $kind eq 'Label' or $kind eq 'Text' or $kind eq 'RichText' ) {
			my $text = $kind eq 'RichText'
				? _native_rich_text($widget)
				: _native_text($widget) // '';
			$native->text($text)
				if $native->can('text');
		}
		elsif ( $kind eq 'Input' ) {
			$native->text( $widget->slots->{_value} // '' )
				if $native->can('text');
		}
		elsif ( $kind eq 'DatePicker' ) {
			if ( $native->can('date') ) {
				my ( $year, $month, $day ) = _date_parts(
					$widget->slots->{_value},
				);
				$native->date( $day, $month - 1, $year - 1900 );
			}
		}
		elsif ( $kind eq 'Checkbox' or $kind eq 'Radio' ) {
			$native->text( $widget->slots->{_label} // '' )
				if $native->can('text');
			$native->checked( $widget->slots->{_checked} ? 1 : 0 )
				if $native->can('checked');
		}
		elsif ( $kind eq 'Button' ) {
			$native->text( $widget->slots->{_text} // '' )
				if $native->can('text');
		}
		elsif ( $kind eq 'Tab' ) {
			$native->text( $widget->slots->{_title} // '' )
				if $native->can('text');
			$native->visible(
				$widget->slots->{_visible} && $widget->slots->{_selected}
					? 1
					: 0,
			) if $native->can('visible');
		}
		elsif ( $kind eq 'Tabs' ) {
			_sync_native_tabs($widget);
		}
		elsif ( $kind eq 'MenuItem' ) {
			my $menu = $widget->slots->{_native_menu_owner};
			my $name = $widget->slots->{_native_menu_name};
			if ( defined $menu and defined $name ) {
				my $item = eval { $menu->$name };
				if ($item) {
					$item->text( $widget->slots->{_text} // '' )
						if $item->can('text');
					$item->enabled( $widget->slots->{_enabled} ? 1 : 0 )
						if $item->can('enabled');
				}
			}
		}
		elsif ( $kind =~ /\A(?:Slider|Progress)\z/ ) {
			$native->value( int( $widget->slots->{_value} || 0 ) )
				if $native->can('value');
			$native->min( int( $widget->slots->{_min} || 0 ) )
				if $native->can('min');
			$native->max( int( $widget->slots->{_max} || 100 ) )
				if $native->can('max');
		}
		elsif ( $kind eq 'ListView' ) {
			if ( $native->can('items') ) {
				$native->items( [ map { _item_label($_) }
					@{ $widget->slots->{_items}->items } ] );
			}
			$native->focusedItem( $widget->slots->{_selected_index} )
				if defined $widget->slots->{_selected_index}
				and $native->can('focusedItem');
		}
		elsif ( $kind eq 'TreeView' ) {
			$native->items( _tree_outline_items($widget) )
				if $native->can('items');
			_sync_tree_outline_selection($widget);
		}
		elsif ( $kind eq 'Select' ) {
			$native->text( defined $widget->slots->{_value}
				? '' . $widget->slots->{_value}
				: '' )
				if $native->can('text');
		}
		my $native_width = $widget->slots->{_width}
			// $widget->slots->{_maxwidth};
		my $native_height = $widget->slots->{_height}
			// $widget->slots->{_maxheight};
		if ( defined $native_width and $native->can('width') ) {
			$native->width( int($native_width) );
		}
		if ( defined $native_height and $native->can('height') ) {
			$native->height( int($native_height) );
		}
		$native->repaint if $native->can('repaint');
		1;
	};

	return;
}

sub _sync_native_tabs {
	my ( $tabs ) = @_;

	return if !_has_native($tabs);
	return if !defined $tabs->slots->{_native_content};

	my $selected;
	for my $child ( @{ $tabs->slots->{_children}->items } ) {
		next if _class_name($child) ne 'Tab';
		next if !_has_native($child);
		my $native = $child->slots->{_native};
		eval { $native->packForget if $native->can('packForget'); 1 };
		$native->visible(0) if $native->can('visible');
		$selected = $child if $child->slots->{_selected} and !defined $selected;
	}

	return if !defined $selected or !_has_native($selected);
	my $native = $selected->slots->{_native};
	$native->pack(
		side => 'top',
		fill => 'both',
		expand => 1,
		padx => 0,
		pady => 0,
	) if $native->can('pack');
	$native->visible(1) if $native->can('visible');
	$native->repaint if $native->can('repaint');
	$tabs->slots->{_native_content}->repaint
		if $tabs->slots->{_native_content}->can('repaint');
	return;
}

sub _native_pack_for {
	my ( $parent_kind, $widget ) = @_;

	my $kind = $widget->slots->{_widget_type} // '';
	my $fixed_width = defined $widget->slots->{_width}
		|| defined $widget->slots->{_maxwidth};
	my $fixed_height = defined $widget->slots->{_height}
		|| defined $widget->slots->{_maxheight};
	my %pack = (
		side => ( $parent_kind eq 'HBox' ? 'left' : 'top' ),
		fill => ( $parent_kind eq 'HBox' ? 'y' : 'x' ),
		padx => 4,
		pady => 4,
	);

	if (
		$kind =~ /\A(?:
			VBox|HBox|Frame|Image|RadioGroup|Tabs|Tab|ListView|TreeView
		)\z/x
	) {
		$pack{expand} = 1;
		$pack{fill} = 'both';
	}
	if ( $parent_kind eq 'VBox' and $fixed_height ) {
		delete $pack{expand};
		$pack{fill} = 'x';
	}
	elsif ( $parent_kind eq 'HBox' and $fixed_height ) {
		delete $pack{expand};
		$pack{fill} = $fixed_width ? 'none' : 'x';
	}

	return \%pack;
}

sub _native_geometry_args {
	my ( $widget, %fallback ) = @_;

	my %args;
	for my $axis ( qw( width height ) ) {
		my $slot = '_' . $axis;
		my $max_slot = '_max' . $axis;
		my $min_slot = '_min' . $axis;
		my $value = $widget->slots->{$slot};
		$value = $widget->slots->{$max_slot}
			if !defined $value and defined $widget->slots->{$max_slot};
		$value = $fallback{$axis}
			if !defined $value and defined $fallback{$axis};
		$value = $widget->slots->{$min_slot}
			if defined $widget->slots->{$min_slot}
			and ( !defined $value or $value < $widget->slots->{$min_slot} );
		$args{$axis} = int($value) if defined $value;
	}
	return %args;
}

sub _emit_native_event {
	my ( $runtime, $widget, $name, $data ) = @_;

	return if $widget->slots->{_syncing_native};
	eval {
		my $event = _make_event(
			$runtime->{_gui_event_class},
			$name,
			$widget,
			$data,
		);
		_dispatch_event( $runtime, $widget, $event );
		1;
	} or warn "$@";
	return;
}

sub _dispatch_named_event {
	my ( $runtime, $widget, $name, $data ) = @_;

	my $event = _make_event( $runtime->{_gui_event_class}, $name, $widget, $data );
	return _dispatch_event( $runtime, $widget, $event );
}

sub _event_cancelled {
	my ( $event ) = @_;

	return 1 if $event->slots->{default_prevented};
	return 1 if $event->slots->{cancelled};
	return 0;
}

sub _clear_native_refs {
	my ( $widget ) = @_;

	delete @{ $widget->slots }{
		qw(
			_native
			_native_content
			_native_menu_owner
			_native_menu_name
			_native_node_by_path
			_native_path_by_node
			_native_paths
		)
	};

	if ( _is_widget($widget) ) {
		for my $child ( @{ $widget->slots->{_children}->items } ) {
			_clear_native_refs($child);
		}
	}

	return;
}

sub _stop_prima_call_loop {
	my ( $window ) = @_;

	return if !$window->slots->{_call_running};
	return if !$PRIMA_READY or !_prima_application_ready();
	eval { $::application->stop if $::application->can('stop'); 1 };
	return;
}

sub _close_window {
	my ( $runtime, $window, $result, $skip_native ) = @_;

	return $window if $window->slots->{_closed};

	my $event = _dispatch_named_event(
		$runtime,
		$window,
		'close_request',
		$result,
	);
	return $window if _event_cancelled($event);

	$window->slots->{_closed} = 1;
	$window->slots->{_close_result} = $result;
	if ( _has_native($window) and !$skip_native ) {
		local $window->slots->{_native_closing} = 1;
		eval { $window->slots->{_native}->close; 1 };
	}
	_stop_prima_call_loop($window);
	_dispatch_named_event( $runtime, $window, 'closed', $result );
	return $window;
}

sub _option_labels {
	my ( $select ) = @_;

	my @labels;
	for my $option ( @{ $select->slots->{_options}->items } ) {
		if ( blessed($option) and $option->isa('Zuzu::Value::Dict') ) {
			my $label = $option->map->{label};
			my $value = $option->map->{value};
			push @labels, defined $label ? "$label" : "$value";
			next;
		}
		push @labels, defined $option ? "$option" : '';
	}

	return \@labels;
}

sub _option_value_from_label {
	my ( $select, $label ) = @_;

	for my $option ( @{ $select->slots->{_options}->items } ) {
		next if !blessed($option) or !$option->isa('Zuzu::Value::Dict');
		my $olabel = $option->map->{label};
		my $value = $option->map->{value};
		next if !defined $olabel;
		return $value if "$olabel" eq "$label";
	}

	return $label;
}

sub _insert_container {
	my ( $runtime, $parent, $widget, $parent_kind, $class, %extra ) = @_;

	my $visible = $widget->slots->{_visible} ? 1 : 0;
	$visible = $visible && $widget->slots->{_selected}
		if $widget->slots->{_widget_type} eq 'Tab';
	my $native = $parent->insert(
		$class,
		pack => _native_pack_for( $parent_kind, $widget ),
		font => _prima_font(),
		enabled => $widget->slots->{_enabled} ? 1 : 0,
		visible => $visible,
		_native_geometry_args($widget),
		%extra,
	);
	$widget->slots->{_native} = $native;

	my $child_parent = $native;
	if ( $class eq 'GroupBox' and defined( $extra{text} ) and $extra{text} ne '' ) {
		$child_parent = $native->insert(
			Widget =>
			pack => {
				side => 'top',
					fill => 'both',
					expand => 1,
					padx => 6,
					pady => _prima_groupbox_content_pady(),
				},
				font => _prima_font(),
				ownerBackColor => 1,
		);
		$widget->slots->{_native_content} = $child_parent;
	}

	for my $child ( @{ $widget->slots->{_children}->items } ) {
		_render_widget( $runtime, $child_parent, $child, $widget->slots->{_widget_type} );
	}
	return $native;
}

sub _render_tabs_widget {
	my ( $runtime, $parent, $widget, $parent_kind ) = @_;

	my $native = $parent->insert(
		GroupBox =>
		pack => _native_pack_for( $parent_kind, $widget ),
		font => _prima_font(),
		text => 'Tabs',
		enabled => $widget->slots->{_enabled} ? 1 : 0,
		visible => $widget->slots->{_visible} ? 1 : 0,
	);
	$widget->slots->{_native} = $native;

	my $header = $native->insert(
		Widget =>
		pack => {
			side => 'top',
			fill => 'x',
			padx => 2,
			pady => 2,
		},
		font => _prima_font(),
	);
	for my $child ( @{ $widget->slots->{_children}->items } ) {
		next if _class_name($child) ne 'Tab';
		$header->insert(
			Button =>
			pack => {
				side => 'left',
				padx => 2,
				pady => 2,
			},
			font => _prima_font(),
			text => $child->slots->{_title} // '',
			onClick => sub {
				_sync_tabs_selected( $widget, $child->slots->{_value} );
				_emit_native_event( $runtime, $widget, 'select' );
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
	}

	my $content = $native->insert(
		Widget =>
		pack => {
			side => 'top',
			fill => 'both',
			expand => 1,
			padx => 2,
			pady => 2,
		},
		font => _prima_font(),
	);
	$widget->slots->{_native_content} = $content;
	for my $child ( @{ $widget->slots->{_children}->items } ) {
		_render_widget( $runtime, $content, $child, 'Tabs' );
	}
	_sync_native_tabs($widget);
	return $native;
}

sub _render_image_widget {
	my ( $runtime, $parent, $widget, $parent_kind ) = @_;

	my $image;
	my $src = $widget->slots->{_src};
	if ( defined $src and $src ne '' ) {
		my $path = File::Spec->file_name_is_absolute($src)
			? $src
			: File::Spec->rel2abs($src);
		$image = eval { Prima::Image->load($path) } if -f $path;
	}

	my $native = $parent->insert(
		Widget =>
		pack => _native_pack_for( $parent_kind, $widget ),
		font => _prima_font(),
		_native_geometry_args( $widget, height => 96 ),
		onPaint => sub {
			my ( $self, $canvas ) = @_;
			my ( $w, $h ) = $self->size;
			$canvas->clear;
			$canvas->color(cl::LightGray);
			$canvas->bar( 0, 0, $w, $h );
			if ($image) {
				$canvas->stretch_image( 4, 4, $w - 8, $h - 8, $image );
			}
			else {
				$canvas->color(cl::DarkGray);
				$canvas->rectangle( 4, 4, $w - 5, $h - 5 );
				$canvas->color(cl::Black);
				$canvas->font( _prima_font() );
				$canvas->text_out( $widget->slots->{_alt} // 'Image', 12, int( $h / 2 ) );
			}
		},
		onMouseUp => sub {
			_emit_native_event( $runtime, $widget, 'click' );
		},
	);
	$widget->slots->{_native} = $native;
	return $native;
}

sub _render_separator_widget {
	my ( $runtime, $parent, $widget, $parent_kind ) = @_;

	my $native = $parent->insert(
		Widget =>
		pack => _native_pack_for( $parent_kind, $widget ),
		height => $widget->slots->{_orientation} eq 'vertical' ? 48 : 8,
		width => $widget->slots->{_orientation} eq 'vertical' ? 8 : 48,
		onPaint => sub {
			my ( $self, $canvas ) = @_;
			my ( $w, $h ) = $self->size;
			$canvas->clear;
			$canvas->color(cl::DarkGray);
			if ( $widget->slots->{_orientation} eq 'vertical' ) {
				my $x = int( $w / 2 );
				$canvas->line( $x, 2, $x, $h - 3 );
			}
			else {
				my $y = int( $h / 2 );
				$canvas->line( 2, $y, $w - 3, $y );
			}
		},
	);
	$widget->slots->{_native} = $native;
	return $native;
}

sub _render_tree_items {
	my ( $tree ) = @_;

	my @labels;
	my @paths;
	_flatten_tree_items(
		$tree->slots->{_items},
		0,
		[],
		\@labels,
		\@paths,
		$tree->slots->{_expanded_path_keys},
	);
	$tree->slots->{_native_paths} = \@paths;
	return \@labels;
}

sub _tree_outline_items {
	my ( $tree ) = @_;

	my %path_by_node;
	my %node_by_path;
	my $build;
	$build = sub {
		my ( $items, $prefix ) = @_;
		my @nodes;
		for ( my $i = 0; $i < @{ $items->items }; $i++ ) {
			my $item = $items->items->[$i];
			my @path = ( @{ $prefix // [] }, $i );
			my $children = _tree_children($item);
			my @child_nodes = @{ $build->( $children, \@path ) };
			my $key = _path_key(\@path);
			my $node = [
				_item_label($item),
				@child_nodes ? \@child_nodes : undef,
				exists $tree->slots->{_expanded_path_keys}{$key} ? 1 : 0,
			];
			$path_by_node{ refaddr($node) } = \@path;
			$node_by_path{$key} = $node;
			push @nodes, $node;
		}
		return \@nodes;
	};

	my $nodes = $build->( $tree->slots->{_items}, [] );
	$tree->slots->{_native_path_by_node} = \%path_by_node;
	$tree->slots->{_native_node_by_path} = \%node_by_path;
	return $nodes;
}

sub _sync_tree_outline_selection {
	my ( $tree ) = @_;

	my $native = $tree->slots->{_native};
	return if !defined $native or !$native->can('focusedItem');

	my $key = _path_key( [ @{ $tree->slots->{_selected_path}->items } ] );
	my $node = $tree->slots->{_native_node_by_path}{$key};
	if ($node and $native->can('get_index')) {
		my ( $index ) = $native->get_index($node);
		$native->focusedItem($index) if defined $index and $index >= 0;
	}
}

sub _tree_outline_focused_path {
	my ( $tree, $native ) = @_;

	return [] if !defined $native or !$native->can('focusedItem');
	my $index = $native->focusedItem;
	return [] if !defined $index or $index < 0;
	my ( $node ) = $native->get_item($index);
	return [] if !$node;
	return $tree->slots->{_native_path_by_node}{ refaddr($node) } // [];
}

sub _render_widget {
	my ( $runtime, $parent, $widget, $parent_kind ) = @_;

	my $kind = $widget->slots->{_widget_type} // '';
	return _insert_container( $runtime, $parent, $widget, $parent_kind, 'Widget' )
		if $kind eq 'VBox' or $kind eq 'HBox';
	return _insert_container(
		$runtime,
		$parent,
		$widget,
		$parent_kind,
		'GroupBox',
		text => $widget->slots->{_label} // '',
	) if $kind eq 'Frame' or $kind eq 'RadioGroup';
	return _render_tabs_widget( $runtime, $parent, $widget, $parent_kind )
		if $kind eq 'Tabs';
	return _insert_container(
		$runtime,
		$parent,
		$widget,
		$parent_kind,
		'GroupBox',
		text => $widget->slots->{_title} // '',
	) if $kind eq 'Tab';

	if ( $kind eq 'Label' or $kind eq 'Text' ) {
		my $native = $parent->insert(
			Label =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => _native_text($widget) // '',
			wordWrap => 1,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onMouseUp => sub { _emit_native_event( $runtime, $widget, 'click' ) },
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'RichText' ) {
		my $native = $parent->insert(
			Label =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => _native_rich_text($widget),
			wordWrap => 1,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onMouseUp => sub { _emit_native_event( $runtime, $widget, 'click' ) },
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	return _render_image_widget( $runtime, $parent, $widget, $parent_kind )
		if $kind eq 'Image';
	return _render_separator_widget( $runtime, $parent, $widget, $parent_kind )
		if $kind eq 'Separator';

	if ( $kind eq 'Slider' ) {
		my $native = $parent->insert(
			Slider =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			min => int( $widget->slots->{_min} || 0 ),
			max => int( $widget->slots->{_max} || 100 ),
			value => int( $widget->slots->{_value} || 0 ),
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onChange => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_value} = $_[0]->value;
				_emit_native_event( $runtime, $widget, 'input' );
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'Progress' ) {
		my $native = $parent->insert(
			Widget =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			height => 28,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onPaint => sub {
				my ( $self, $canvas ) = @_;
				my ( $width, $height ) = $self->size;
				my $min = $widget->slots->{_min} || 0;
				my $max = $widget->slots->{_max} || 100;
				my $value = $widget->slots->{_value} || 0;
				my $range = $max - $min;
				my $ratio = $range <= 0 ? 0 : ( $value - $min ) / $range;
				$ratio = 0 if $ratio < 0;
				$ratio = 1 if $ratio > 1;

				$canvas->clear;
				$canvas->color(0xE6E6E6);
				$canvas->bar( 0, 0, $width, $height );
				$canvas->color(0x2D6CDF);
				$canvas->bar( 0, 0, int( $width * $ratio ), $height );
				$canvas->color(0x202020);
				$canvas->rectangle( 0, 0, $width - 1, $height - 1 );
				if ( $widget->slots->{_show_text} ) {
					my $text = int( $ratio * 100 ) . '%';
					$canvas->font( _prima_font() );
					my $tw = $canvas->get_text_width($text);
					my $th = ( $canvas->font->{height} || 12 );
					$canvas->color(0xFFFFFF);
					$canvas->text_out(
						$text,
						int( ( $width - $tw ) / 2 ),
						int( ( $height - $th ) / 2 ),
					);
				}
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'ListView' ) {
		my $native = $parent->insert(
			ListBox =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			items => [ map { _item_label($_) }
				@{ $widget->slots->{_items}->items } ],
			multiSelect => $widget->slots->{_multiple} ? 1 : 0,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onClick => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_selected_index} = $_[0]->focusedItem;
				_emit_native_event( $runtime, $widget, 'select' );
			},
			onMouseDblClk => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_selected_index} = $_[0]->focusedItem;
				_emit_native_event( $runtime, $widget, 'activate' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'TreeView' ) {
		my $native = $parent->insert(
			StringOutline =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			items => _tree_outline_items($widget),
			multiSelect => $widget->slots->{_multiple} ? 1 : 0,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onSelectItem => sub {
				return if $widget->slots->{_syncing_native};
				my $path = _tree_outline_focused_path( $widget, $_[0] );
				$widget->slots->{_selected_path} = _zarray( @{ $path } );
				_emit_native_event( $runtime, $widget, 'select' );
			},
			onMouseDblClk => sub {
				return if $widget->slots->{_syncing_native};
				my $path = _tree_outline_focused_path( $widget, $_[0] );
				$widget->slots->{_selected_path} = _zarray( @{ $path } );
				_emit_native_event( $runtime, $widget, 'activate' );
			},
			onExpand => sub {
				return if $widget->slots->{_syncing_native};
				my ( $native, $node, $action ) = @_;
				my $path = $widget->slots->{_native_path_by_node}{ refaddr($node) };
				return if !$path;
				my $key = _path_key($path);
				if ($action) {
					$widget->slots->{_expanded_path_keys}{$key} = [ @{ $path } ];
				}
				else {
					delete $widget->slots->{_expanded_path_keys}{$key};
				}
				_emit_native_event(
					$runtime,
					$widget,
					$action ? 'expand' : 'collapse',
				);
			},
		);
		$widget->slots->{_native} = $native;
		_sync_tree_outline_selection($widget);
		return $native;
	}

	if ( $kind eq 'Input' ) {
		my $native = $parent->insert(
			InputLine =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => $widget->slots->{_value} // '',
			readOnly => $widget->slots->{_readonly} ? 1 : 0,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onChange => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_value} = $_[0]->text;
				_emit_native_event( $runtime, $widget, 'input' );
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'DatePicker' ) {
		my ( $year, $month, $day ) = _date_parts( $widget->slots->{_value} );
		my $native = $parent->insert(
			'Widget::Date' =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			format => 'YYYY-MM-DD',
			date => [ $day, $month - 1, $year - 1900 ],
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onChange => sub {
				return if $widget->slots->{_syncing_native};
				my @date = $_[0]->date;
				my $value = _date_from_parts(
					$date[2] + 1900,
					$date[1] + 1,
					$date[0],
				);
				eval { _check_date_range( $widget, $value ); 1 } or return;
				$widget->slots->{_value} = $value;
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'Checkbox' ) {
		my $native = $parent->insert(
			CheckBox =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => $widget->slots->{_label} // '',
			checked => $widget->slots->{_checked} ? 1 : 0,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onCheck => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_checked} = $_[0]->checked ? 1 : 0;
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'Radio' ) {
		my $native = $parent->insert(
			Radio =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => $widget->slots->{_label} // '',
			checked => $widget->slots->{_checked} ? 1 : 0,
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onClick => sub {
				return if $widget->slots->{_syncing_native};
				_set_radio_checked( $widget, 1 );
				_emit_native_event( $runtime, $widget, 'change' );
				my $group = _nearest_radio_group($widget);
				_emit_native_event( $runtime, $group, 'change' ) if $group;
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'Select' ) {
		my $native = $parent->insert(
			ComboBox =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			items => _option_labels($widget),
			text => defined $widget->slots->{_value}
				? '' . $widget->slots->{_value}
				: '',
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			onChange => sub {
				return if $widget->slots->{_syncing_native};
				$widget->slots->{_value} = _option_value_from_label(
					$widget,
					$_[0]->text,
				);
				_emit_native_event( $runtime, $widget, 'change' );
			},
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	if ( $kind eq 'Button' ) {
		my $native = $parent->insert(
			Button =>
			pack => _native_pack_for( $parent_kind, $widget ),
			font => _prima_font(),
			text => $widget->slots->{_text} // '',
			enabled => $widget->slots->{_enabled} ? 1 : 0,
			_native_geometry_args($widget),
			onClick => sub { _emit_native_event( $runtime, $widget, 'click' ) },
		);
		$widget->slots->{_native} = $native;
		return $native;
	}

	return _insert_container( $runtime, $parent, $widget, $parent_kind, 'Widget' );
}

my $MENU_ITEM_SEQ = 0;

sub _menu_widgets {
	my ( $window ) = @_;

	return grep { _class_name($_) eq 'Menu' }
		@{ $window->slots->{_children}->items };
}

sub _menu_item_name {
	my ( $item ) = @_;

	$item->slots->{_native_menu_name} //= 'zuzu_menu_item_' . ++$MENU_ITEM_SEQ;
	return $item->slots->{_native_menu_name};
}

sub _prima_menu_item {
	my ( $runtime, $item ) = @_;

	my $name = _menu_item_name($item);
	$name = '-' . $name if !$item->slots->{_enabled};
	return [
		$name,
		$item->slots->{_text} // '',
		sub { _emit_native_event( $runtime, $item, 'click' ) },
	];
}

sub _prima_window_menu_items {
	my ( $runtime, $window ) = @_;

	my @menus;
	for my $menu ( _menu_widgets($window) ) {
		push @menus, [
			$menu->slots->{_text} // '',
			[
				map { _prima_menu_item( $runtime, $_ ) }
				grep { _class_name($_) eq 'MenuItem' }
				@{ $menu->slots->{_children}->items },
			],
		];
	}
	return @menus;
}

sub _bind_native_menu_items {
	my ( $window, $native_menu ) = @_;

	return if !defined $native_menu;
	for my $menu ( _menu_widgets($window) ) {
		for my $item ( @{ $menu->slots->{_children}->items } ) {
			next if _class_name($item) ne 'MenuItem';
			$item->slots->{_native_menu_owner} = $native_menu;
		}
	}
	return;
}

sub _ensure_prima_window {
	my ( $runtime, $window ) = @_;

	return $window->slots->{_native} if _has_native($window);

	_load_prima_backend();
	my @menu_items = _prima_window_menu_items( $runtime, $window );
	my %args = (
		text => $window->slots->{_title} // '',
		font => _prima_font(),
		width => int( $window->slots->{_width} || 800 ),
		height => int( $window->slots->{_height} || 600 ),
		centered => 1,
		onSize => sub {
			my ( $self ) = @_;
			my ( $width, $height ) = $self->size;
			$window->slots->{_width} = $width;
			$window->slots->{_height} = $height;
			_emit_native_event( $runtime, $window, 'resize' );
		},
		onClose => sub {
			return if $window->slots->{_native_closing};
			_close_window( $runtime, $window, undef, 1 );
			return $window->slots->{_closed} ? 1 : 0;
		},
		onDestroy => sub {
			_clear_native_refs($window);
		},
	);
	$args{menuItems} = \@menu_items if @menu_items;
	my $native = Prima::Window->new(%args);
	$window->slots->{_native} = $native;
	_bind_native_menu_items( $window, $native->menu ) if @menu_items;
	for my $child ( @{ $window->slots->{_children}->items } ) {
		next if _class_name($child) eq 'Menu';
		_render_widget( $runtime, $native, $child, 'Window' );
	}
	return $native;
}

sub _show_prima_window {
	my ( $runtime, $window ) = @_;

	my $native = _ensure_prima_window( $runtime, $window );
	$native->show if $native->can('show');
	$window->slots->{_shown} = 1;
	_emit_native_event( $runtime, $window, 'open' );
	return $window;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	$runtime->assert_capability(
		'gui',
		'std/gui/objects is denied by runtime policy',
		'<std/gui/objects>',
		0,
	);

	my $widget_class = native_class( name => 'Widget' );
	my $window_class = native_class( name => 'Window', parent => $widget_class );
	my $vbox_class = native_class( name => 'VBox', parent => $widget_class );
	my $hbox_class = native_class( name => 'HBox', parent => $widget_class );
	my $frame_class = native_class( name => 'Frame', parent => $widget_class );
	my $label_class = native_class( name => 'Label', parent => $widget_class );
	my $text_class = native_class( name => 'Text', parent => $widget_class );
	my $rich_text_class = native_class(
		name => 'RichText',
		parent => $widget_class,
	);
	my $image_class = native_class( name => 'Image', parent => $widget_class );
	my $input_class = native_class( name => 'Input', parent => $widget_class );
	my $date_picker_class = native_class(
		name => 'DatePicker',
		parent => $widget_class,
	);
	my $checkbox_class = native_class(
		name => 'Checkbox',
		parent => $widget_class,
	);
	my $radio_class = native_class( name => 'Radio', parent => $widget_class );
	my $radio_group_class = native_class(
		name => 'RadioGroup',
		parent => $widget_class,
	);
	my $select_class = native_class( name => 'Select', parent => $widget_class );
	my $menu_class = native_class( name => 'Menu', parent => $widget_class );
	my $menu_item_class = native_class(
		name => 'MenuItem',
		parent => $widget_class,
	);
	my $button_class = native_class( name => 'Button', parent => $widget_class );
	my $separator_class = native_class(
		name => 'Separator',
		parent => $widget_class,
	);
	my $slider_class = native_class( name => 'Slider', parent => $widget_class );
	my $progress_class = native_class(
		name => 'Progress',
		parent => $widget_class,
	);
	my $tabs_class = native_class( name => 'Tabs', parent => $widget_class );
	my $tab_class = native_class( name => 'Tab', parent => $widget_class );
	my $list_view_class = native_class(
		name => 'ListView',
		parent => $widget_class,
	);
	my $tree_view_class = native_class(
		name => 'TreeView',
		parent => $widget_class,
	);
	my $event_class = native_class( name => 'Event' );
	my $listener_token_class = native_class( name => 'ListenerToken' );
	$runtime->{_gui_event_class} = $event_class;

	_add_event_methods( $event_class );
	_add_widget_methods(
		$runtime,
		$widget_class,
		$event_class,
		$listener_token_class,
	);

	$widget_class->native_constructor( _widget_constructor(
		'Widget',
		'Widget',
		[],
		undef,
	) );

	$window_class->native_constructor( _widget_constructor(
		'Window',
		'Window',
		[ qw( title width height resizable modal content ) ],
		sub {
			my ( $slots, $named ) = @_;
			$slots->{_title} = _string_prop( $named, 'title', '' );
			$slots->{_width} = _number_prop( $named, 'width', 800 );
			$slots->{_height} = _number_prop( $named, 'height', 600 );
			$slots->{_resizable} = _bool_prop( $named, 'resizable', 1 );
			$slots->{_modal} = _bool_prop( $named, 'modal', 0 );
			$slots->{_shown} = 0;
			$slots->{_closed} = 0;
			$slots->{_close_result} = undef;
			$slots->{_content} = undef;
		},
	) );
	$window_class->methods->{show} = native_function(
		name => 'show',
		native => sub {
			my ( $self ) = @_;
			my $opened = 0;
			eval {
				_show_prima_window( $runtime, $self );
				$opened = 1;
				1;
			} or do {
				$self->slots->{_backend_error} = "$@";
			};
			$self->slots->{_shown} = 1;
			_dispatch_named_event( $runtime, $self, 'open' ) if !$opened;
			return $self;
		},
	);
	$window_class->methods->{call} = native_function(
		name => 'call',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{_close_result} if $self->slots->{_closed};
			if ( !_has_native($self) ) {
				eval {
					_show_prima_window( $runtime, $self );
					1;
				} or do {
					die $@;
				};
			}
			$self->slots->{_shown} = 1;
			return $self->slots->{_close_result} if $self->slots->{_closed};
			if ($PRIMA_READY) {
				local $self->slots->{_call_running} = 1;
				Prima->run if !$self->slots->{_closed};
			}
			return $self->slots->{_close_result};
		},
	);
	$window_class->methods->{close} = native_function(
		name => 'close',
		native => sub {
			my ( $self, @args ) = @_;
			return _close_window(
				$runtime,
				$self,
				@args ? $args[0] : undef,
				0,
			);
		},
	);
	$window_class->methods->{content} = native_function(
		name => 'content',
		native => sub { return $_[0]->slots->{_content}; },
	);
	$window_class->methods->{menus} = native_function(
		name => 'menus',
		native => sub {
			my ( $self ) = @_;
			return _zarray( _menu_widgets($self) );
		},
	);
	$window_class->methods->{set_content} = native_function(
		name => 'set_content',
		native => sub {
			my ( $self, $child ) = @_;
			_runtime_error(
				'GUI_PROP_TYPE',
				'set_content expects a non-menu Widget or null',
			) if defined $child and ( !_is_widget($child) or _is_menu_kind($child) );
			my @menus;
			for my $old ( @{ $self->slots->{_children}->items } ) {
				if ( _class_name($old) eq 'Menu' ) {
					push @menus, $old;
					next;
				}
				_set_parent( $old, undef )
					if defined _parent($old)
					and _parent($old) == $self;
			}
			$self->slots->{_children}->items( \@menus );
			$self->slots->{_content} = $child;
			_adopt_child( $self, $child ) if defined $child;
			return $self;
		},
	);
	_add_text_methods( $window_class, '_title', 'title', 'set_title' );

	for my $spec (
		[ $vbox_class, 'VBox', 'VBox', [ qw( align gap padding ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_align} = _enum_prop(
				'VBox',
				$named,
				'align',
				'top',
				qw( top centre bottom stretch ),
			);
			$slots->{_gap} = _number_prop( $named, 'gap', 0 );
			$slots->{_padding} = exists $named->{padding}
				? $named->{padding}
				: 0;
		} ],
		[ $hbox_class, 'HBox', 'HBox', [ qw( align gap padding ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_align} = _enum_prop(
				'HBox',
				$named,
				'align',
				'left',
				qw( left centre right stretch ),
			);
			$slots->{_gap} = _number_prop( $named, 'gap', 0 );
			$slots->{_padding} = exists $named->{padding}
				? $named->{padding}
				: 0;
		} ],
		[ $frame_class, 'Frame', 'Frame',
			[ qw( label collapsible collapsed ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_label} = _string_prop( $named, 'label', '' );
			$slots->{_collapsible} = _bool_prop( $named, 'collapsible', 0 );
			$slots->{_collapsed} = _bool_prop( $named, 'collapsed', 0 );
		} ],
		[ $label_class, 'Label', 'Label', [ qw( text for ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_text} = _string_prop( $named, 'text', '' );
			$slots->{_for} = _string_prop( $named, 'for', undef );
		} ],
		[ $text_class, 'Text', 'Text', [ qw( value multiline readonly wrap ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = _string_prop( $named, 'value', '' );
			$slots->{_multiline} = _bool_prop( $named, 'multiline', 0 );
			$slots->{_readonly} = _bool_prop( $named, 'readonly', 0 );
			$slots->{_wrap} = _bool_prop( $named, 'wrap', 1 );
		} ],
		[ $rich_text_class, 'RichText', 'RichText',
			[ qw( value multiline readonly ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = _string_prop( $named, 'value', '' );
			$slots->{_multiline} = _bool_prop( $named, 'multiline', 1 );
			$slots->{_readonly} = _bool_prop( $named, 'readonly', 1 );
		} ],
		[ $image_class, 'Image', 'Image', [ qw( src alt fit ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_src} = _string_prop( $named, 'src', '' );
			$slots->{_alt} = _string_prop( $named, 'alt', '' );
			$slots->{_fit} = _enum_prop(
				'Image',
				$named,
				'fit',
				'none',
				qw( none contain cover stretch ),
			);
		} ],
		[ $input_class, 'Input', 'Input',
			[ qw( value placeholder multiline readonly password required ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = _string_prop( $named, 'value', '' );
			$slots->{_placeholder} = _string_prop( $named, 'placeholder', '' );
			$slots->{_multiline} = _bool_prop( $named, 'multiline', 0 );
			$slots->{_readonly} = _bool_prop( $named, 'readonly', 0 );
			$slots->{_password} = _bool_prop( $named, 'password', 0 );
			$slots->{_required} = _bool_prop( $named, 'required', 0 );
		} ],
		[ $date_picker_class, 'DatePicker', 'DatePicker',
			[ qw( value min max first_day_of_week ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} =
				_date_prop( $named, 'value', _today_date() ) // _today_date();
			$slots->{_min} = _date_prop( $named, 'min', undef );
			$slots->{_max} = _date_prop( $named, 'max', undef );
			$slots->{_first_day_of_week} = _weekday_prop(
				$named,
				'first_day_of_week',
				0,
			);
			_check_date_range_slots( $slots, $slots->{_value} );
		} ],
		[ $checkbox_class, 'Checkbox', 'Checkbox',
			[ qw( label checked indeterminate ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_label} = _string_prop( $named, 'label', '' );
			$slots->{_checked} = _bool_prop( $named, 'checked', 0 );
			$slots->{_indeterminate} = _bool_prop(
				$named,
				'indeterminate',
				0,
			);
		} ],
		[ $radio_class, 'Radio', 'Radio', [ qw( label value group checked ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_label} = _string_prop( $named, 'label', '' );
			$slots->{_value} = _string_prop( $named, 'value', '' );
			$slots->{_group} = _string_prop( $named, 'group', undef );
			$slots->{_checked} = _bool_prop( $named, 'checked', 0 );
		} ],
		[ $radio_group_class, 'RadioGroup', 'RadioGroup', [ qw( name value ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_name} = _string_prop( $named, 'name', '' );
			$slots->{_value} = _string_prop( $named, 'value', undef );
		} ],
		[ $select_class, 'Select', 'Select', [ qw( value options multiple ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = exists $named->{value} ? $named->{value} : undef;
			$slots->{_options} = _array_prop( $named, 'options', _zarray() );
			$slots->{_multiple} = _bool_prop( $named, 'multiple', 0 );
		} ],
		[ $menu_class, 'Menu', 'Menu', [ qw( text ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_text} = _string_prop( $named, 'text', '' );
		} ],
		[ $menu_item_class, 'MenuItem', 'MenuItem', [ qw( text ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_text} = _string_prop( $named, 'text', '' );
			$slots->{_native_menu_name} = undef;
			$slots->{_native_menu_owner} = undef;
		} ],
		[ $button_class, 'Button', 'Button', [ qw( text variant ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_text} = _string_prop( $named, 'text', '' );
			$slots->{_variant} = _enum_prop(
				'Button',
				$named,
				'variant',
				'default',
				qw( default primary danger ),
			);
		} ],
		[ $separator_class, 'Separator', 'Separator',
			[ qw( orientation ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_orientation} = _enum_prop(
				'Separator',
				$named,
				'orientation',
				'horizontal',
				qw( horizontal vertical ),
			);
		} ],
		[ $slider_class, 'Slider', 'Slider',
			[ qw( value min max step orientation readonly ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = _number_prop( $named, 'value', 0 );
			$slots->{_min} = _number_prop( $named, 'min', 0 );
			$slots->{_max} = _number_prop( $named, 'max', 100 );
			$slots->{_step} = _number_prop( $named, 'step', 1 );
			$slots->{_orientation} = _enum_prop(
				'Slider',
				$named,
				'orientation',
				'horizontal',
				qw( horizontal vertical ),
			);
			$slots->{_readonly} = _bool_prop( $named, 'readonly', 0 );
		} ],
		[ $progress_class, 'Progress', 'Progress',
			[ qw( value min max indeterminate show_text ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_value} = _number_prop( $named, 'value', 0 );
			$slots->{_min} = _number_prop( $named, 'min', 0 );
			$slots->{_max} = _number_prop( $named, 'max', 100 );
			$slots->{_indeterminate} = _bool_prop(
				$named,
				'indeterminate',
				0,
			);
			$slots->{_show_text} = _bool_prop( $named, 'show_text', 0 );
		} ],
		[ $tabs_class, 'Tabs', 'Tabs',
			[ qw( selected value placement ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_selected} = exists $named->{selected}
				? _string_prop( $named, 'selected', undef )
				: _string_prop( $named, 'value', undef );
			$slots->{_placement} = _enum_prop(
				'Tabs',
				$named,
				'placement',
				'top',
				qw( top bottom left right ),
			);
		} ],
		[ $tab_class, 'Tab', 'Tab',
			[ qw( title value selected closable icon ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_title} = _string_prop( $named, 'title', '' );
			$slots->{_value} = _string_prop( $named, 'value', '' );
			$slots->{_selected} = _bool_prop( $named, 'selected', 0 );
			$slots->{_closable} = _bool_prop( $named, 'closable', 0 );
			$slots->{_icon} = _string_prop( $named, 'icon', undef );
		} ],
		[ $list_view_class, 'ListView', 'ListView',
			[ qw( items selected_index multiple ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_items} = _array_prop( $named, 'items', _zarray() );
			$slots->{_selected_index} = exists $named->{selected_index}
				? 0 + ( $named->{selected_index} // 0 )
				: undef;
			$slots->{_multiple} = _bool_prop( $named, 'multiple', 0 );
		} ],
		[ $tree_view_class, 'TreeView', 'TreeView',
			[ qw( items selected_path multiple ) ], sub {
			my ( $slots, $named ) = @_;
			$slots->{_items} = _array_prop( $named, 'items', _zarray() );
			$slots->{_selected_path} = exists $named->{selected_path}
				? _zarray( @{ _path_indexes( $named->{selected_path} ) } )
				: _zarray();
			$slots->{_multiple} = _bool_prop( $named, 'multiple', 0 );
			$slots->{_expanded_path_keys} = {};
			_mark_tree_expanded(
				$slots->{_items},
				[],
				$slots->{_expanded_path_keys},
			);
		} ],
	) {
		my ( $klass, $class_name, $widget_type, $allowed, $builder ) = @{ $spec };
		$klass->native_constructor( _widget_constructor(
			$class_name,
			$widget_type,
			$allowed,
			$builder,
		) );
	}

	for my $klass ( $vbox_class, $hbox_class ) {
		$klass->methods->{align} = native_function(
			name => 'align',
			native => sub { return $_[0]->slots->{_align}; },
		);
		$klass->methods->{gap} = native_function(
			name => 'gap',
			native => sub { return $_[0]->slots->{_gap}; },
		);
		$klass->methods->{padding} = native_function(
			name => 'padding',
			native => sub { return $_[0]->slots->{_padding}; },
		);
	}
	_add_text_methods( $frame_class, '_label', 'label', 'set_label' );
	_add_bool_method( $frame_class, '_collapsed', 'collapsed' );
	_add_bool_method( $frame_class, '_collapsible', 'collapsible' );

	_add_text_methods( $label_class, '_text', 'text', 'set_text' );
	_add_text_methods( $label_class, '_for', 'for_id', 'set_for_id' );

	for my $klass ( $text_class, $rich_text_class ) {
		_add_text_methods( $klass, '_value', 'value', 'set_value' );
		_add_bool_method( $klass, '_multiline', 'multiline' );
		_add_bool_method( $klass, '_readonly', 'readonly' );
	}
	_add_bool_method( $text_class, '_wrap', 'wrap' );
	_add_text_methods( $image_class, '_src', 'src', 'set_src' );
	_add_text_methods( $image_class, '_alt', 'alt', 'set_alt' );
	_add_getter( $image_class, '_fit', 'fit' );

	_add_text_methods( $button_class, '_text', 'text', 'set_text' );
	_add_text_methods( $input_class, '_value', 'value', 'set_value' );
	_add_text_methods(
		$input_class,
		'_placeholder',
		'placeholder',
		'set_placeholder',
	);
	_add_bool_method( $input_class, '_multiline', 'multiline' );
	_add_bool_method( $input_class, '_readonly', 'readonly' );
	_add_bool_method( $input_class, '_password', 'password' );
	_add_bool_method( $input_class, '_required', 'required' );
	$input_class->methods->{select_all} = native_function(
		name => 'select_all',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{_selection} = [
				0,
				length( $self->slots->{_value} // '' ),
			];
			return $self;
		},
	);

	$date_picker_class->methods->{value} = native_function(
		name => 'value',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				my $value = _validate_date( $args[0], 'value' )
					// _today_date();
				_check_date_range( $self, $value );
				$self->slots->{_value} = $value;
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{_value};
		},
	);
	$date_picker_class->methods->{set_value} = native_function(
		name => 'set_value',
		native => sub {
			my ( $self, $value ) = @_;
			$value = _validate_date( $value, 'value' ) // _today_date();
			_check_date_range( $self, $value );
			$self->slots->{_value} = $value;
			_refresh_native($self);
			return $self;
		},
	);
	$date_picker_class->methods->{min} = native_function(
		name => 'min',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				my $value = _validate_date( $args[0], 'min' );
				my %slots = %{ $self->slots };
				$slots{_min} = $value;
				_check_date_range_slots( \%slots, $self->slots->{_value} );
				$self->slots->{_min} = $value;
				return $self;
			}
			return $self->slots->{_min};
		},
	);
	$date_picker_class->methods->{max} = native_function(
		name => 'max',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				my $value = _validate_date( $args[0], 'max' );
				my %slots = %{ $self->slots };
				$slots{_max} = $value;
				_check_date_range_slots( \%slots, $self->slots->{_value} );
				$self->slots->{_max} = $value;
				return $self;
			}
			return $self->slots->{_max};
		},
	);
	$date_picker_class->methods->{first_day_of_week} = native_function(
		name => 'first_day_of_week',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				my $value = 0 + ( $args[0] // 0 );
				_runtime_error(
					'GUI_PROP_TYPE',
					'first_day_of_week property expects an integer from 0 to 6',
				) if $value < 0 or $value > 6 or int($value) != $value;
				$self->slots->{_first_day_of_week} = int($value);
				return $self;
			}
			return $self->slots->{_first_day_of_week};
		},
	);

	_add_text_methods( $checkbox_class, '_label', 'label', 'set_label' );
	_add_bool_method( $checkbox_class, '_checked', 'checked' );
	_add_bool_method( $checkbox_class, '_indeterminate', 'indeterminate' );

	_add_text_methods( $radio_class, '_label', 'label', 'set_label' );
	_add_text_methods( $radio_class, '_value', 'value', 'set_value' );
	_add_getter( $radio_class, '_group', 'group' );
	$radio_class->methods->{checked} = native_function(
		name => 'checked',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				_set_radio_checked( $self, zuzu_bool( $args[0], 0 ) ? 1 : 0 );
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{_checked} ? 1 : 0;
		},
	);

	_add_getter( $radio_group_class, '_name', 'name' );
	$radio_group_class->methods->{value} = native_function(
		name => 'value',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				_sync_radio_group_value( $self, $args[0] );
				for my $child ( @{ $self->slots->{_children}->items } ) {
					_refresh_native($child);
				}
				return $self;
			}
			return $self->slots->{_value};
		},
	);
	$radio_group_class->methods->{options} = native_function(
		name => 'options',
		native => sub {
			my ( $self ) = @_;
			my @radios = grep { _class_name($_) eq 'Radio' }
				@{ $self->slots->{_children}->items };
			return _zarray(@radios);
		},
	);

	$select_class->methods->{value} = native_function(
		name => 'value',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{_value} = $args[0];
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{_value};
		},
	);
	$select_class->methods->{options} = native_function(
		name => 'options',
		native => sub { return _copy_array( $_[0]->slots->{_options} ); },
	);
	$select_class->methods->{add_option} = native_function(
		name => 'add_option',
		native => sub {
			my ( $self, $option ) = @_;
			push @{ $self->slots->{_options}->items }, $option;
			if ( _has_native($self) ) {
				eval { $self->slots->{_native}->items( _option_labels($self) ); 1 };
			}
			return $self;
		},
	);
	$select_class->methods->{clear_options} = native_function(
		name => 'clear_options',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{_options}->items( [] );
			if ( _has_native($self) ) {
				eval { $self->slots->{_native}->items( [] ); 1 };
			}
			return $self;
		},
	);
	_add_bool_method( $select_class, '_multiple', 'multiple' );

	_add_text_methods( $menu_class, '_text', 'text', 'set_text' );
	$menu_class->methods->{items} = native_function(
		name => 'items',
		native => sub { return _copy_array( $_[0]->slots->{_children} ); },
	);
	_add_text_methods( $menu_item_class, '_text', 'text', 'set_text' );
	$menu_item_class->methods->{disabled} = native_function(
		name => 'disabled',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{_enabled} = zuzu_bool( $args[0], 0 ) ? 0 : 1;
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{_enabled} ? 0 : 1;
		},
	);

	_add_getter( $button_class, '_variant', 'variant' );
	_add_getter( $separator_class, '_orientation', 'orientation' );

	for my $klass ( $slider_class, $progress_class ) {
		_add_number_method( $klass, '_value', 'value' );
		_add_number_method( $klass, '_min', 'min' );
		_add_number_method( $klass, '_max', 'max' );
	}
	_add_number_method( $slider_class, '_step', 'step' );
	_add_getter( $slider_class, '_orientation', 'orientation' );
	_add_bool_method( $slider_class, '_readonly', 'readonly' );
	_add_bool_method( $progress_class, '_indeterminate', 'indeterminate' );
	_add_bool_method( $progress_class, '_show_text', 'show_text' );

	_add_getter( $tabs_class, '_placement', 'placement' );
	$tabs_class->methods->{selected} = native_function(
		name => 'selected',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				_sync_tabs_selected( $self, $args[0] );
				return $self;
			}
			return $self->slots->{_selected};
		},
	);
	$tabs_class->methods->{value} = native_function(
		name => 'value',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				_sync_tabs_selected( $self, $args[0] );
				return $self;
			}
			return $self->slots->{_selected};
		},
	);
	$tabs_class->methods->{tabs} = native_function(
		name => 'tabs',
		native => sub {
			my ( $self ) = @_;
			my @tabs = grep { _class_name($_) eq 'Tab' }
				@{ $self->slots->{_children}->items };
			return _zarray(@tabs);
		},
	);
	$tabs_class->methods->{selected_tab} = native_function(
		name => 'selected_tab',
		native => sub {
			my ( $self ) = @_;
			for my $child ( @{ $self->slots->{_children}->items } ) {
				next if _class_name($child) ne 'Tab';
				return $child if $child->slots->{_selected};
			}
			return undef;
		},
	);

	_add_text_methods( $tab_class, '_title', 'title', 'set_title' );
	_add_text_methods( $tab_class, '_value', 'value', 'set_value' );
	_add_text_methods( $tab_class, '_icon', 'icon', 'set_icon' );
	_add_bool_method( $tab_class, '_closable', 'closable' );
	$tab_class->methods->{selected} = native_function(
		name => 'selected',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				_set_tab_selected( $self, zuzu_bool( $args[0], 0 ) ? 1 : 0 );
				return $self;
			}
			return $self->slots->{_selected} ? 1 : 0;
		},
	);

	$list_view_class->methods->{items} = native_function(
		name => 'items',
		native => sub { return _copy_array( $_[0]->slots->{_items} ); },
	);
	$list_view_class->methods->{selected_index} = native_function(
		name => 'selected_index',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{_selected_index} = defined $args[0]
					? 0 + $args[0]
					: undef;
				_refresh_native($self);
				return $self;
			}
			return $self->slots->{_selected_index};
		},
	);
	$list_view_class->methods->{selected_item} = native_function(
		name => 'selected_item',
		native => sub {
			my ( $self ) = @_;
			return _item_at_index( $self, $self->slots->{_selected_index} );
		},
	);
	$list_view_class->methods->{add_item} = native_function(
		name => 'add_item',
		native => sub {
			my ( $self, $item ) = @_;
			push @{ $self->slots->{_items}->items }, $item;
			_refresh_native($self);
			return $self;
		},
	);
	$list_view_class->methods->{clear_items} = native_function(
		name => 'clear_items',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{_items}->items( [] );
			$self->slots->{_selected_index} = undef;
			_refresh_native($self);
			return $self;
		},
	);
	$list_view_class->methods->{activate_index} = native_function(
		name => 'activate_index',
		native => sub {
			my ( $self, $index ) = @_;
			$self->slots->{_selected_index} = 0 + ( $index // 0 );
			_emit_native_event( $runtime, $self, 'activate' );
			return $self;
		},
	);
	_add_bool_method( $list_view_class, '_multiple', 'multiple' );

	$tree_view_class->methods->{items} = native_function(
		name => 'items',
		native => sub { return _copy_array( $_[0]->slots->{_items} ); },
	);
	_add_bool_method( $tree_view_class, '_multiple', 'multiple' );
	$tree_view_class->methods->{selected_path} = native_function(
		name => 'selected_path',
		native => sub {
			my ( $self, @args ) = @_;
			if (@args) {
				$self->slots->{_selected_path} = _zarray(
					@{ _path_indexes( $args[0] ) },
				);
				_refresh_native($self);
				return $self;
			}
			return _copy_array( $self->slots->{_selected_path} );
		},
	);
	$tree_view_class->methods->{selected_item} = native_function(
		name => 'selected_item',
		native => sub {
			my ( $self ) = @_;
			return _tree_item_at_path(
				$self,
				[ @{ $self->slots->{_selected_path}->items } ],
			);
		},
	);
	$tree_view_class->methods->{add_item} = native_function(
		name => 'add_item',
		native => sub {
			my ( $self, $item ) = @_;
			push @{ $self->slots->{_items}->items }, $item;
			_mark_tree_expanded(
				$self->slots->{_items},
				[],
				$self->slots->{_expanded_path_keys},
			);
			_refresh_native($self);
			return $self;
		},
	);
	$tree_view_class->methods->{clear_items} = native_function(
		name => 'clear_items',
		native => sub {
			my ( $self ) = @_;
			$self->slots->{_items}->items( [] );
			$self->slots->{_selected_path}->items( [] );
			$self->slots->{_expanded_path_keys} = {};
			_refresh_native($self);
			return $self;
		},
	);
	$tree_view_class->methods->{activate_path} = native_function(
		name => 'activate_path',
		native => sub {
			my ( $self, $path ) = @_;
			$self->slots->{_selected_path} = _zarray(
				@{ _path_indexes($path) },
			);
			_emit_native_event( $runtime, $self, 'activate' );
			return $self;
		},
	);
	$tree_view_class->methods->{expand_path} = native_function(
		name => 'expand_path',
		native => sub {
			my ( $self, $path ) = @_;
			my $indexes = _path_indexes($path);
			$self->slots->{_expanded_path_keys}{ _path_key($indexes) } = [
				@{ $indexes },
			];
			_refresh_native($self);
			_emit_native_event( $runtime, $self, 'expand' );
			return $self;
		},
	);
	$tree_view_class->methods->{collapse_path} = native_function(
		name => 'collapse_path',
		native => sub {
			my ( $self, $path ) = @_;
			my $indexes = _path_indexes($path);
			delete $self->slots->{_expanded_path_keys}{ _path_key($indexes) };
			_refresh_native($self);
			_emit_native_event( $runtime, $self, 'collapse' );
			return $self;
		},
	);
	$tree_view_class->methods->{is_expanded} = native_function(
		name => 'is_expanded',
		native => sub {
			my ( $self, $path ) = @_;
			my $indexes = _path_indexes($path);
			return exists $self->slots->{_expanded_path_keys}{ _path_key($indexes) }
				? 1
				: 0;
		},
	);

	return {
		Widget => $widget_class,
		Window => $window_class,
		VBox => $vbox_class,
		HBox => $hbox_class,
		Frame => $frame_class,
		Label => $label_class,
		Text => $text_class,
		RichText => $rich_text_class,
		Image => $image_class,
		Input => $input_class,
		DatePicker => $date_picker_class,
		Checkbox => $checkbox_class,
		Radio => $radio_class,
		RadioGroup => $radio_group_class,
		Select => $select_class,
		Menu => $menu_class,
		MenuItem => $menu_item_class,
		Button => $button_class,
		Separator => $separator_class,
		Slider => $slider_class,
		Progress => $progress_class,
		Tabs => $tabs_class,
		Tab => $tab_class,
		ListView => $list_view_class,
		TreeView => $tree_view_class,
		Event => $event_class,
		ListenerToken => $listener_token_class,
		native_file_open => native_function(
			name => 'native_file_open',
			native => \&_native_file_open,
		),
		native_file_save => native_function(
			name => 'native_file_save',
			native => \&_native_file_save,
		),
		native_directory_open => native_function(
			name => 'native_directory_open',
			native => \&_native_directory_open,
		),
		native_directory_save => native_function(
			name => 'native_directory_save',
			native => \&_native_directory_save,
		),
		native_alert => native_function(
			name => 'native_alert',
			native => \&_native_alert,
		),
		native_confirm => native_function(
			name => 'native_confirm',
			native => \&_native_confirm,
		),
		native_prompt => native_function(
			name => 'native_prompt',
			native => \&_native_prompt,
		),
		native_colour_picker => native_function(
			name => 'native_colour_picker',
			native => \&_native_colour_picker,
		),
		meta => _backend_meta(),
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::GUI::Objects - headless std/gui object model.

=head1 DESCRIPTION

Implements the early runtime-backed GUI object, event, and baseline
control model for the Perl runtime, with a Prima backend for on-screen
windows and controls.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::GUI::Objects >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
