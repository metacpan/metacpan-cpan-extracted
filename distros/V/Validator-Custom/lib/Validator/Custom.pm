package Validator::Custom;
use Object::Simple -base;
use 5.008001;
our $VERSION = '1.0201';

use Carp 'croak';
use Validator::Custom::Validation;
use Validator::Custom::FilterFunction;
use Validator::Custom::CheckFunction;

# Version 0 modules
use Validator::Custom::Constraints;
use Validator::Custom::Constraint;
use Validator::Custom::Result;
use Validator::Custom::Rule;

sub validation { Validator::Custom::Validation->new }

sub new {
  my $self = shift->SUPER::new(@_);
  
  # Add checks
  $self->add_check(
    ascii_graphic     => \&Validator::Custom::CheckFunction::ascii_graphic,
    number           => \&Validator::Custom::CheckFunction::number,
    int               => \&Validator::Custom::CheckFunction::int,
    in                => \&Validator::Custom::CheckFunction::in
  );
  
  # Add filters
  $self->add_filter(
    remove_blank      => \&Validator::Custom::FilterFunction::remove_blank,
    trim              => \&Validator::Custom::FilterFunction::trim,
  );
  
  # Version 0 constraints
  $self->register_constraint(
    any               => sub { 1 },
    ascii             => \&Validator::Custom::Constraint::ascii,
    between           => \&Validator::Custom::Constraint::between,
    blank             => \&Validator::Custom::Constraint::blank,
    date_to_timepiece => \&Validator::Custom::Constraint::date_to_timepiece,
    datetime_to_timepiece => \&Validator::Custom::Constraint::datetime_to_timepiece,
    decimal           => \&Validator::Custom::Constraint::decimal,
    defined           => sub { defined $_[0] },
    duplication       => \&Validator::Custom::Constraint::duplication,
    equal_to          => \&Validator::Custom::Constraint::equal_to,
    greater_than      => \&Validator::Custom::Constraint::greater_than,
    http_url          => \&Validator::Custom::Constraint::http_url,
    int               => \&Validator::Custom::Constraint::int,
    in_array          => \&Validator::Custom::Constraint::in_array,
    length            => \&Validator::Custom::Constraint::length,
    less_than         => \&Validator::Custom::Constraint::less_than,
    merge             => \&Validator::Custom::Constraint::merge,
    not_defined       => \&Validator::Custom::Constraint::not_defined,
    not_space         => \&Validator::Custom::Constraint::not_space,
    not_blank         => \&Validator::Custom::Constraint::not_blank,
    uint              => \&Validator::Custom::Constraint::uint,
    regex             => \&Validator::Custom::Constraint::regex,
    selected_at_least => \&Validator::Custom::Constraint::selected_at_least,
    shift             => \&Validator::Custom::Constraint::shift_array,
    space             => \&Validator::Custom::Constraint::space,
    string            => \&Validator::Custom::Constraint::string,
    to_array          => \&Validator::Custom::Constraint::to_array,
    to_array_remove_blank => \&Validator::Custom::Constraint::to_array_remove_blank,
    trim              => \&Validator::Custom::Constraint::trim,
    trim_collapse     => \&Validator::Custom::Constraint::trim_collapse,
    trim_lead         => \&Validator::Custom::Constraint::trim_lead,
    trim_trail        => \&Validator::Custom::Constraint::trim_trail,
    trim_uni          => \&Validator::Custom::Constraint::trim_uni,
    trim_uni_collapse => \&Validator::Custom::Constraint::trim_uni_collapse,
    trim_uni_lead     => \&Validator::Custom::Constraint::trim_uni_lead,
    trim_uni_trail    => \&Validator::Custom::Constraint::trim_uni_trail
  );
  
  return $self;
}

sub check_each {
  my ($self, $values, $name, $arg) = @_;
  
  if (@_ < 3) {
    croak "values and the name of a checking function must be passed";
  }
  
  my $checks = $self->{checks} || {};
  
  croak "Can't call \"$name\" checking function"
    unless $checks->{$name};
  
  croak "values must be array reference"
    unless ref $values eq 'ARRAY';
  
  my $is_invalid;
  for my $value (@$values) {
    my $is_valid = $checks->{$name}->($self, $value, $arg);
    unless ($is_valid) {
      $is_invalid = 1;
      last;
    }
  }
  
  return $is_invalid ? 0 : 1;
}

sub filter_each {
  my ($self, $values, $name, $arg) = @_;
  
  if (@_ < 3) {
    croak "values and the name of a filtering function must be passed";
  }
  
  my $filters = $self->{filters} || {};
  
  croak "Can't call \"$name\" filtering function"
    unless $filters->{$name};
  
  croak "values must be array reference"
    unless ref $values eq 'ARRAY';
  
  my $new_values = [];
  for my $value (@$values) {
    my $new_value = $filters->{$name}->($self, $value, $arg);
    push @$new_values, $new_value;
  }
  
  return $new_values;
}

sub check {
  my ($self, $value, $name, $arg) = @_;

  if (@_ < 3) {
    croak "value and the name of a checking function must be passed";
  }
  
  my $checks = $self->{checks} || {};
  
  croak "Can't call \"$name\" checking function"
    unless $checks->{$name};
  
  return $checks->{$name}->($self, $value, $arg);
}

sub filter {
  my ($self, $value, $name, $arg) = @_;
  
  if (@_ < 3) {
    croak "value and the name of a filtering function must be passed";
  }
  
  my $filters = $self->{filters} || {};
  
  croak "Can't call \"$name\" filtering function"
    unless $filters->{$name};
  
  return $filters->{$name}->($self, $value, $arg);
}

sub add_check {
  my $self = shift;
  
  # Merge
  my $checks = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{checks} = ({%{$self->{checks} || {}}, %$checks});
  
  return $self;
}

sub add_filter {
  my $self = shift;
  
  # Merge
  my $filters = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->{filters} = ({%{$self->{filters} || {}}, %$filters});
  
  return $self;
}

# Version 0 method
our %VALID_OPTIONS = map {$_ => 1} qw/message default copy require optional/;
sub _parse_constraint {
  my ($self, $c) = @_;

  # Constraint information
  my $cinfo = {};

  # Arrange constraint information
  my $constraint = $c->{constraint};
  $cinfo->{message} = $c->{message};
  $cinfo->{original_constraint} = $c->{constraint};
  
  # Code reference
  if (ref $constraint eq 'CODE') {
    $cinfo->{funcs} = [$constraint];
  }
  # Simple constraint name
  else {
    my $constraints;
    if (ref $constraint eq 'ARRAY') {
      $constraints = $constraint;
    }
    else {
      if ($constraint =~ /\|\|/) {
        $constraints = [split(/\|\|/, $constraint)];
      }
      else {
        $constraints = [$constraint];
      }
    }
    
    # Constraint functions
    my @cfuncs;
    my @cargs;
    for my $cname (@$constraints) {
      # Arrange constraint
      if (ref $cname eq 'HASH') {
        my $first_key = (keys %$cname)[0];
        push @cargs, $cname->{$first_key};
        $cname = $first_key;
      }

      # Target is array elements
      $cinfo->{each} = 1 if $cname =~ s/^@//;
      croak qq{"\@" must be one at the top of constrinat name}
        if index($cname, '@') > -1;
      
      
      # Trim space
      $cname =~ s/^\s+//;
      $cname =~ s/\s+$//;
      
      # Negative
      my $negative = $cname =~ s/^!// ? 1 : 0;
      croak qq{"!" must be one at the top of constraint name}
        if index($cname, '!') > -1;
      
      # Trim space
      $cname =~ s/^\s+//;
      $cname =~ s/\s+$//;
      
      # Constraint function
      croak "Constraint name '$cname' must be [A-Za-z0-9_]"
        if $cname =~ /\W/;
      my $cfunc = $self->constraints->{$cname} || '';
      croak qq{"$cname" is not registered}
        unless ref $cfunc eq 'CODE';
      
      # Negativate
      my $f = $negative ? sub {
        my $ret = $cfunc->(@_);
        if (ref $ret eq 'ARRAY') {
          $ret->[0] = ! $ret->[0];
          return $ret;
        }
        else { return !$ret }
      } : $cfunc;
      
      # Add
      push @cfuncs, $f;
    }
    $cinfo->{funcs} = \@cfuncs;
    $cinfo->{args} = \@cargs;
  }
  
  return $cinfo;
}

has shared_rule => sub { [] };
__PACKAGE__->attr('constraints' => sub { {} });

# Version 0 method
sub create_rule { Validator::Custom::Rule->new(validator => shift) }

# Version 0 method
sub register_constraint {
  my $self = shift;
  
  # Merge
  my $constraints = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->constraints({%{$self->constraints}, %$constraints});
  
  return $self;
}

# Version 0 method
sub _parse_random_string_rule {
  my $self = shift;
  
  # Rule
  my $rule = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  
  # Result
  my $result = {};
  
  # Parse string rule
  for my $name (keys %$rule) {
    # Pettern
    my $pattern = $rule->{$name};
    $pattern = '' unless $pattern;
    
    # State
    my $state = 'character';

    # Count
    my $count = '';
    
    # Chacacter sets
    my $csets = [];
    my $cset = [];
    
    # Parse pattern
    my $c;
    while (defined ($c = substr($pattern, 0, 1, '')) && length $c) {
      # Character class
      if ($state eq 'character_class') {
        if ($c eq ']') {
          $state = 'character';
          push @$csets, $cset;
          $cset = [];
          $state = 'character';
        }
        else { push @$cset, $c }
      }
      
      # Count
      elsif ($state eq 'count') {
        if ($c eq '}') {
          $count = 1 if $count < 1;
          for (my $i = 0; $i < $count - 1; $i++) {
              push @$csets, [@{$csets->[-1] || ['']}];
          }
          $count = '';
          $state = 'character';
        }
        else { $count .= $c }
      }
      
      # Character
      else {
        if ($c eq '[') { $state = 'character_class' }
        elsif ($c eq '{') { $state = 'count' }
        else { push @$csets, [$c] }
      }
    }
    
    # Add Charcter sets
    $result->{$name} = $csets;
  }
  
  return $result;
}

# Version 0 method
sub validate {
  my ($self, $input, $rule) = @_;
  
  # Class
  my $class = ref $self;
  
  # Validation rule
  $rule ||= $self->rule;
  
  # Data filter
  my $filter = $self->data_filter;
  $input = $filter->($input) if $filter;
  
  # Check data
  croak "First argument must be hash ref"
    unless ref $input eq 'HASH';
  
  # Check rule
  unless (ref $rule eq 'Validator::Custom::Rule') {
    croak "Invalid rule structure" unless ref $rule eq 'ARRAY';
  }
  
  # Result
  my $result = Validator::Custom::Result->new;
  $result->{_error_infos} = {};
  
  # Save raw data
  $result->raw_data($input);
  
  # Error is stock?
  my $error_stock = $self->error_stock;
  
  # Valid keys
  my $valid_keys = {};
  
  # Error position
  my $pos = 0;
  
  # Found missing parameters
  my $found_missing_params = {};
  
  # Shared rule
  my $shared_rule = $self->shared_rule;
  
  if (ref $rule eq 'Validator::Custom::Rule') {
    $self->rule_obj($rule);
  }
  else {
    my $rule_obj = $self->create_rule;
    $rule_obj->parse($rule, $shared_rule);
    $self->rule_obj($rule_obj);
  }
  my $rule_obj = $self->rule_obj;

  if ($rule_obj->{version} && $rule_obj->{version} == 1) {
    croak "Can't call validate method(Validator::Custom). Use \$rule->validate(\$input) instead";
  }
  
  # Process each key
  OUTER_LOOP:
  for (my $i = 0; $i < @{$rule_obj->rule}; $i++) {
    
    my $r = $rule_obj->rule->[$i];
    
    # Increment position
    $pos++;
    
    # Key, options, and constraints
    my $key = $r->{key};
    my $opts = $r->{option};
    my $cinfos = $r->{constraints} || [];
    
    # Check constraints
    croak "Invalid rule structure"
      unless ref $cinfos eq 'ARRAY';

    # Arrange key
    my $result_key = $key;
    if (ref $key eq 'HASH') {
      my $first_key = (keys %$key)[0];
      $result_key = $first_key;
      $key         = $key->{$first_key};
    }
    elsif (defined $r->{name}) {
      $result_key = $r->{name};
    }
    
    # Real keys
    my $keys;
    
    if (ref $key eq 'ARRAY') { $keys = $key }
    elsif (ref $key eq 'Regexp') {
      $keys = [];
      for my $k (keys %$input) {
         push @$keys, $k if $k =~ /$key/;
      }
    }
    else { $keys = [$key] }
    
    # Check option
    if (exists $opts->{optional}) {
      if ($opts->{optional}) {
        $opts->{require} = 0;
      }
      delete $opts->{optional};
    }
    for my $oname (keys %$opts) {
      croak qq{Option "$oname" of "$result_key" is invalid name}
        unless $VALID_OPTIONS{$oname};
    }
    
    # Default
    if (exists $opts->{default}) {
      $r->{default} = $opts->{default};
    }
    
    # Is data copy?
    my $copy = 1;
    $copy = $opts->{copy} if exists $opts->{copy};
    
    # Check missing parameters
    my $require = exists $opts->{require} ? $opts->{require} : 1;
    my $found_missing_param;
    my $missing_params = $result->missing_params;
    for my $key (@$keys) {
      unless (exists $input->{$key}) {
        if ($require && !exists $r->{default}) {
          push @$missing_params, $key
            unless $found_missing_params->{$key};
          $found_missing_params->{$key}++;
        }
        $found_missing_param = 1;
      }
    }
    if ($found_missing_param) {
      $result->data->{$result_key} = ref $r->{default} eq 'CODE'
          ? $r->{default}->($self) : $r->{default}
        if exists $r->{default} && $copy;
      next if $r->{default} || !$require;
    }
    
    # Already valid
    next if $valid_keys->{$result_key};
    
    # Validation
    my $value = @$keys > 1
      ? [map { $input->{$_} } @$keys]
      : $input->{$keys->[0]};
    
    for my $cinfo (@$cinfos) {
      
      # Constraint information
      my $args = $cinfo->{args};
      my $message = $cinfo->{message};
                                      
      # Constraint function
      my $cfuncs = $cinfo->{funcs};
      
      # Is valid?
      my $is_valid;
      
      # Data is array
      if($cinfo->{each}) {
          
        # To array
        $value = [$value] unless ref $value eq 'ARRAY';
        
        # Validation loop
        for (my $k = 0; $k < @$value; $k++) {
          my $input = $value->[$k];
          
          # Validation
          for (my $j = 0; $j < @$cfuncs; $j++) {
            my $cfunc = $cfuncs->[$j];
            my $arg = $args->[$j];
            
            # Validate
            my $cresult;
            {
              local $_ = Validator::Custom::Constraints->new(
                constraints => $self->constraints
              );
              $cresult= $cfunc->($input, $arg, $self);
            }
            
            # Constrint result
            my $v;
            if (ref $cresult eq 'ARRAY') {
              ($is_valid, $v) = @$cresult;
              $value->[$k] = $v;
            }
            elsif (ref $cresult eq 'HASH') {
              $is_valid = $cresult->{result};
              $message = $cresult->{message} unless $is_valid;
              $value->[$k] = $cresult->{output} if exists $cresult->{output};
            }
            else { $is_valid = $cresult }
            
            last if $is_valid;
          }
          
          # Validation error
          last unless $is_valid;
        }
      }
      
      # Data is scalar
      else {
        # Validation
        for (my $k = 0; $k < @$cfuncs; $k++) {
          my $cfunc = $cfuncs->[$k];
          my $arg = $args->[$k];
        
          my $cresult;
          {
            local $_ = Validator::Custom::Constraints->new(
              constraints => $self->constraints
            );
            $cresult = $cfunc->($value, $arg, $self);
          }
          
          if (ref $cresult eq 'ARRAY') {
            my $v;
            ($is_valid, $v) = @$cresult;
            $value = $v if $is_valid;
          }
          elsif (ref $cresult eq 'HASH') {
            $is_valid = $cresult->{result};
            $message = $cresult->{message} unless $is_valid;
            $value = $cresult->{output} if exists $cresult->{output} && $is_valid;
          }
          else { $is_valid = $cresult }
          
          last if $is_valid;
        }
      }
      
      # Add error if it is invalid
      unless ($is_valid) {
        if (exists $r->{default}) {
          # Set default value
          $result->data->{$result_key} = ref $r->{default} eq 'CODE'
                                       ? $r->{default}->($self)
                                       : $r->{default}
            if exists $r->{default} && $copy;
          $valid_keys->{$result_key} = 1
        }
        else {
          # Resist error info
          $message = $opts->{message} unless defined $message;
          $result->{_error_infos}->{$result_key} = {
            message      => $message,
            position     => $pos,
            reason       => $cinfo->{original_constraint},
            original_key => $key
          } unless exists $result->{_error_infos}->{$result_key};
          
          # No Error stock
          unless ($error_stock) {
            # Check rest constraint
            my $found;
            for (my $k = $i + 1; $k < @{$rule_obj->rule}; $k++) {
              my $r_next = $rule_obj->rule->[$k];
              my $key_next = $r_next->{key};
              $key_next = (keys %$key)[0] if ref $key eq 'HASH';
              $found = 1 if $key_next eq $result_key;
            }
            last OUTER_LOOP unless $found;
          }
        }
        next OUTER_LOOP;
      }
    }
    
    # Result data
    $result->data->{$result_key} = $value if $copy;
    
    # Key is valid
    $valid_keys->{$result_key} = 1;
    
    # Remove invalid key
    delete $result->{_error_infos}->{$key};
  }
  
  return $result;
}

# Version 0 attributes
has 'data_filter';
has 'rule';
has 'rule_obj';
has error_stock => 1;

# Version 0 method
sub js_fill_form_button {
  my ($self, $rule) = @_;
  
  my $r = $self->_parse_random_string_rule($rule);
  
  require JSON;
  my $r_json = JSON->new->encode($r);
  
  my $javascript = << "EOS";
(function () {

  var rule = $r_json;

  var create_random_value = function (rule, name) {
    var patterns = rule[name];
    if (patterns === undefined) {
      return "";
    }
    
    var value = "";
    for (var i = 0; i < patterns.length; i++) {
      var pattern = patterns[i];
      var num = Math.floor(Math.random() * pattern.length);
      value = value + pattern[num];
    }
    
    return value;
  };
  
  var addEvent = (function(){
    if(document.addEventListener) {
      return function(node,type,handler){
        node.addEventListener(type,handler,false);
      };
    } else if (document.attachEvent) {
      return function(node,type,handler){
        node.attachEvent('on' + type, function(evt){
          handler.call(node, evt);
        });
      };
    }
  })();
  
  var button = document.createElement("input");
  button.setAttribute("type","button");
  button.value = "Fill Form";
  document.body.insertBefore(button, document.body.firstChild)

  addEvent(
    button,
    "click",
    function () {
      
      var input_elems = document.getElementsByTagName('input');
      var radio_names = {};
      var checkbox_names = {};
      for (var i = 0; i < input_elems.length; i++) {
        var e = input_elems[i];

        var name = e.getAttribute("name");
        var type = e.getAttribute("type");
        if (type === "text" || type === "hidden" || type === "password") {
          var value = create_random_value(rule, name);
          e.value = value;
        }
        else if (type === "checkbox") {
          e.checked = Math.floor(Math.random() * 2) ? true : false;
        }
        else if (type === "radio") {
          radio_names[name] = 1;
        }
      }
      
      for (name in radio_names) {
        var elems = document.getElementsByName(name);
        var num = Math.floor(Math.random() * elems.length);
        elems[num].checked = true;
      }
      
      var textarea_elems = document.getElementsByTagName("textarea");
      for (var i = 0; i < textarea_elems.length; i++) {
        var e = textarea_elems[i];
        
        var name = e.getAttribute("name");
        var value = create_random_value(rule, name);
        
        var text = document.createTextNode(value);
        
        if (e.firstChild) {
          e.removeChild(e.firstChild);
        }
        
        e.appendChild(text);
      }
      
      var select_elems = document.getElementsByTagName("select");
      for (var i = 0; i < select_elems.length; i++) {
        var e = select_elems[i];
        var options = e.options;
        if (e.multiple) {
          for (var k = 0; k < options.length; k++) {
            options[k].selected = Math.floor(Math.random() * 2) ? true : false;
          }
        }
        else {
          var num = Math.floor(Math.random() * options.length);
          e.selectedIndex = num;
        }
      }
    }
  );
})();
EOS

  return $javascript;
}

1;

=encoding UTF-8

=head1 NAME

Validator::Custom - HTML form validation. Simple and good flexibility

=head1 DESCRIPTION

L<Validator::Custom> is a validator for HTML form.

=over 4

=item *

1. B<Checking functions:> C<ascii_graphic>, C<int>, C<number>, C<in>. You can also add your checking function.

=item *

2. B<Filtering functions:> C<trim>, C<remove_blank>. You can also add your filtering function.

=item *

3. B<Validation object:> Save each validation result and check if all data is valid.

=back

=head1 SYNOPSIS

  use Validator::Custom;
  my $vc = Validator::Custom->new;
  
  # Input data
  my $id = 1;
  my $name = 'Ken Suzuki';
  my $price = ' 19.23 ';
  my $favorite = ['001', '002'];
  
  # Create validation object
  my $validation = $vc->validation;
  
  # Check if id is integer
  if (!$vc->check($id, 'int')) {
    # Add failed message
    $validation->add_failed(id => 'id must be integer');
  }
  
  # Check if name has length
  if (!(length $name)) {
    $validation->add_failed(name => 'name must have length');
  }
  # Check if name's length is less than 30
  elsif (!(length $name < 30)) {
    $validation->add_failed(name => 'name is too long');
  }
  
  # Filter price to remove left-rigth space
  $price = $vc->filter($price, 'trim');

  # Check price is number and the digits of the decimal part is two or less than two
  if (!$vc->check($price, 'number', {decimal_part_max => 2})) {
    # Set default value if validation fail
    $price = 20.25;
  }
  
  # Filter each value of favorite using "trim" filtering function
  $favorite = $vc->filter_each($favorite, 'trim');
  
  # Check if favorite has at least one values
  if (@$favorite == 0) {
    $validation->add_failed(favorite => 'favorite must be selected more than one');
  }
  # Check if favorite is one of the specified values
  elsif (!($vc->check_each($favorite, 'in',  ['001', '002', '003']))) {
    $validation->add_failed(favorite => 'favorite is invalid');
  }
  
  # Check if validation result is valid
  if ($validation->is_valid) {
    # ...
  }
  else {
    
    # Check what parameter fail
    unless ($validation->is_valid('name')) {
      # ...
    }
    
    # Get all failed parameter names
    my $failed = $validation->failed;

    # Get a failed parameter message
    my $name_message = $validation->message('name');
    
    # Get all failed parameter messages
    my $messages = $validation->messages;
    
    # Get all failed parameter names and the messages as hash reference
    my $messages_h = $validation->messages_to_hash;
  }
  
=head1 1. Basic usage

=head2 1. Create a new Validator::Custom object

At first, create L<Validator::Custom> object using C<new> method.

  use Validator::Custom;
  my $vc = Validator::Custom->new;

=head2 2. Prepare input data for validation

Next, prepare input data.

  my $id = 1;
  my $name = 'Ken Suzuki';
  my $price = ' 19.23 ';
  my $favorite = ['001', '002'];

=head2 3. Create a new validation object

Next, create a new validation object using C<validation> method.

  my $validation = $vc->validation;

This is L<Validator::Custom::Validation> object
to store failed parameter names and the messages.

=head2 4. Validate input data

  # Check if id is integer
  if (!$vc->check($id, 'int')) {
    # Add failed message
    $validation->add_failed(id => 'id must be integer');
  }

You can use C<int> checking function to check the value is integer.
C<int> checking function is default one.
Any checking function is available through C<check> method.

When the check doesn't succeed, you can add the failed parameter name and the message
using C<add_failed> method of L<Validator::Custom::Validation> class.
  
  # Filter price to remove left-rigth space
  $price = $vc->filter($price, 'trim');

You can use C<trim> filtering function to trim left-rigth spaces.
  
  # Filter each value of favorite using "trim" filtering function
  $favorite = $vc->filter_each($favorite, 'trim');

You can use C<filter_each> method to filter each value of favorite.
  
  # Check if favorite has at least one values
  if (@$favorite == 0) {
    $validation->add_failed(favorite => 'favorite must be selected more than one');
  }
  # Check if favorite is one of the specified values
  elsif (!($vc->check_each($favorite, 'in',  ['001', '002', '003']))) {
    $validation->add_failed(favorite => 'favorite is invalid');
  }

You can use C<check_each> method to check each value of favorite.

If you see default checks and filter,
see L<Validator::Custom/"CHECKING FUNCTIONS"> and L<Validator::Custom/"FILTERING FUNCTIONS">.

=head1 2. Manipulate validation object

If you check all input data is valid, use C<is_valid> method.
  
  # Check if validation result is valid
  if ($validation->is_valid) {
    # Success
  }
  else {
    # Failed
  }

If you can check a input data is valid, use C<is_valid> method with parameter name.
  
  # Check what parameter fail
  unless ($validation->is_valid('name')) {
    # ...
  }

You can get all failed parameter names using C<failed> method.

  # Get all failed parameter names
  my $failed = $validation->failed;

You can get a failed parameter message using C<message> method.

  # Get a failed parameter message
  my $name_message = $validation->message('name');

You can get all failed parameter messages using C<messages> method.

  # Get all failed parameter messages
  my $messages = $validation->messages;

You can get all failed names and the messages as hash reference using C<messages_to_hash> method.

  # Get all failed parameter names and the messages as hash reference
  my $messages_h = $validation->messages_to_hash;

See also L<Validator::Custom::Validation>.

=head1 3. Advanced tequnique

=head2 1. Add checking function

You can add your own checking function using C<add_check> method if you need.

  $vc->add_check(
    telephone => sub {
      my ($vc, $value, $arg) = @_;
      
      my $is_valid;
      if ($value =~ /^[\d-]+$/) {
        $is_valid = 1;
      }
      return $is_valid;
    }
  );

Checking function receives three arguments,
First argument is L<Validator::Custom> object,
Second argument is the value for checking,
Third argument is the argument of checking function.

Your Checking function must return true or false value.

=head2 2. Add filtering function

You can add your filtering function by C<add_filter> method if you need.

  $vc->add_filter(
    to_upper_case => sub {
      my ($vc, $value, $arg) = @_;
      
      my $new_$value = uc $value;
                  
      return $new_value;
    }
  );

Filtering function receives three arguments,
First argument is L<Validator::Custom> object,
Second argument is the value for filtering.
Third argument is the argument of filtering function.

Your filtering function must return the result of filtering.

=head1 Checking functions

L<Validator::Custom> have the following default checking functions.
You can call any checking function by C<check> method.

=head2 int

Check if the value is integer value.

  my $value = 19;
  my $is_valid = $vc->check($value, 'int');

Example of valid values:

  "-10"
  "234"

Example of invalid values:

  "10.11"
  "abc"

If you also need to check the range of value, you can write the following way.

  my $is_valid =  $vc->check($value, 'int') && $value > 0;

=head2 number

Check if the value is number.
Number means integer or decimal.
  
  my $is_valid = $vc->check($value, 'number');

Example of valid values:

  '1'
  '123'
  '123.456'
  '-1'
  '-100'
  '-100.789'

Example of invalid values:

  'a';
  '1.a';
  'a.1';

You can also specify decimal part max digits using C<decimal_part_max> option.

  my $is_valid = $vc->check($value, 'number', {decimal_part_max => 3});

Example of valid values:

  '123'
  '123.456'
  '-100.789'

Example of invalid values:

  '123.4567'
  '-100.7891'

=head2 ascii_graphic

Check if the value is Ascii graphic characters(hex 21-7e).
Generally, C<ascii_graphic> function is used to
check the characters of a password.
  
  my $is_valid = $vc->check($value, 'ascii');

Example of valid values:

  "Ken!@-"

Example of invalid values:
  
  "aa aa"
  "\taaa"

=head2 in

Check if the value is one of the given values.
  
  my $value = '001';
  my $is_valid = $vc->check($value, 'in', ['001', '002', '003']);

Example of valid values:

  '001'
  '002'
  '003'

Example of invalid values:

  '004'
  '005'

=head1 Filtering functions

L<Validator::Custom> have the following default filtering functions.
You can call any filtering function using C<filter> method.

=head2 trim

Trim leading and trailing white space.
Note that trim function remove unicode space character, not only C<[ \t\n\r\f]>.

  my $new_value = $vc->filter($value, 'trim');

Filtering example:

  Input : '  　Ken  '
  Output: 'Ken'

=head2 remove_blank

Remove blank character and undefined value from array reference.

  my $new_values = $vc->filter($values, 'remove_blank');

Filtering example:

  Input : [1, 2, '', undef, 4]
  Output: [1, 2, 4]

=head1 Methods

L<Validator::Custom> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 new

Create a new L<Validator::Custom> object.

  my $vc = Validator::Custom->new;

=head2 add_check

Add a checking function.

  $vc->add_check(int => sub { ... });

Example:
  
  $vc->add_check(
    int => sub {
      my ($vc, $value, $arg) = @_;
      
      my $is_valid = $value =~ /^\-?[\d]+$/;
      
      return $is_valid;
    }
  );

Checking function receives three arguments,
First argument is L<Validator::Custom> object,
Second argument is the value for checking,
Third argument is the argument of checking function.

Your Checking function must return true or false value.

=head2 add_filter

Add a filtering function. 

  $vc->add_filter(trim => sub { ... });

Example:

  $vc->add_filter(
    trim => sub {
      my ($vc, $value, $arg) = @_;
      
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      
      return $value;
    }
  );

=head2 check

Execute a checking function.

  my $is_valid = $vc->check($value, 'int');
  my $is_valid = $vc->check($value, 'int', $arg);

First argument is the value for checking.
Second argument is the name of the checking funcion.
Third argument is the argument of the checking function.

=head2 check_each

Execute a checking function to all elements of array reference.
If more than one element is invalid, C<check_each> method return false.

  my $is_valid = $vc->check_each($values, 'int');
  my $is_valid = $vc->check_each($values, 'int', $arg);

First argument is the values for checking, which must be array reference.
Second argument is the name of the checking funcion.
Third argument is the argument of the checking function.

=head2 filter

Execute a filtering function.

  my $new_value = $vc->filter($value, 'trim');
  my $new_value = $vc->filter($value, 'trim', $arg);

First argument is the value for filtering.
Second argument is the name of the filtering funcion.
Third argument is the argument of the filtering function.

=head2 filter_each

Execute a filtering function to all elements of array reference.

  my $new_values = $vc->filter_each($values, 'trim');
  my $new_values = $vc->filter_each($values, 'trim', $arg);

First argument is the values for filtering, which must be array reference.
Second argument is the name of the filtering funcion.
Third argument is the argument of the filtering function.

=head1 EXAMPLES

Show you some examples to do some validation.

Password checking:
  
  my $password = 'abc';
  my $password2 = 'abc';
  
  my $validation = $vc->validation;
  
  if (!length $password) {
    $validation->add_failed(password => 'password must have length');
  }
  elsif (!$vc->check($password, 'ascii')) {
    $validation->add_failed(password => 'password contains invalid characters');
  }
  elsif ($password ne $password2) {
    $validation->add_failed(password => "two passwords don't match");
  }
  
  if ($validation->is_valid) {
    # ...
  }
  else {
    # ...
  }

Check box, selected at least 1, one of the given values:

  my $favorite = ['001', '002'];

  my $validation = $vc->validation;
  
  if (@$favorite == 0) {
    $validation->add_failed(favorite => 'favorite must be selected at least 1');
  }
  elsif (!$vc->check($favorite, 'in', ['001', '002', '003'])) {
    $validation->add_failed(favorite => 'favorite have invalid value');
  }
  
  if ($validtion->is_valid) {
    # ...
  }
  else {
    # ...
  }

Convert date string to L<Time::Piece> object.

  my $date = '2014/05/16';
  
  my $validation = $vc->validation;
  
  my $date_tp;
  if (!length $date) {
    $validation->add_failed(date => 'date must have length');
  }
  else {
    eval { $date_tp = Time::Piece->strptime($date, '%Y/%m/%d') };
    if (!$date_tp) {
      $validation->add_failed(date => 'date value is invalid');
    }
  }

Convert datetime string to L<Time::Piece> object.

  my $datetime = '2014/05/16 12:30:40';
  
  my $validation = $vc->validation;
  
  my $datetime_tp;
  if (!length $datetime) {
    $validation->add_failed(datetime => 'datetime must have length');
  }
  else {
    eval { $datetime_tp = Time::Piece->strptime($datetime, '%Y/%m/%d %H:%M:%S') };
    if (!$datetime_tp) {
      $validation->add_failed(datetime => 'datetime value is invalid');
    }
  }

=head1 FAQ

=head2 I use Validator::Custom 0.xx yet. I want to see documentation of Version 0.xx.

See L<Validator::Custom::Document::Version0>.
This is complete document for L<Validator::Custom> version 0.xx.

=head2 What point I take care of in Version 1.xx.

=over 4

=item *

C<in_array> constraint function is renamed to C<in> checking function.

=item *

C<trim> filtering function becomes triming unicode space characters, not only C<[ \t\n\r\f]>.

=item *

C<decimal> constraint is renamed to C<number> checking function and simplified.

=item *

C<date_to_timepiece> checking function doesn't exist.
About alternative way, see the topic "Convert date string to Time::Piece object" in "EXAMPLES".

=item *

C<datetime_to_timepiece> checking function doesn't exists.
About alternative way, see the topic "Convert datetime string to Time::Piece object" in "EXAMPLES".

=back

=head2 How to create the corresponding checking functions in Version 0.xx constraint functions.

I show some examples.

space

  $vc->add_check(space => sub {
    my ($vc, $value, $arg) = @_;
    return defined $value && $value =~ '^[ \t\n\r\f]*$' ? 1 : 0;
  });

http_url

  $vc->add_check(http_url => sub {
    my ($vc, $value, $arg) = @_;
    return defined $value && $value =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ ? 1 : 0;
  });

decimal

  $vc->add_check(decimal => sub {
    my ($vc, $value, $arg) = @_;

    return undef unless defined $value;
    
    my $digits_tmp = $arg;
    
    # Digit
    my $digits;
    if (defined $digits_tmp) {
      if (ref $digits_tmp eq 'ARRAY') {
        $digits = $digits_tmp;
      }
      else {
        $digits = [$digits_tmp, undef];
      }
    }
    else {
      $digits = [undef, undef];
    }
    
    # Regex
    my $re;
    if (defined $digits->[0] && defined $digits->[1]) {
      $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]{0,$digits->[1]})?$/;
    }
    elsif (defined $digits->[0]) {
      $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]*)?$/;
    }
    elsif (defined $digits->[1]) {
      $re = qr/^[0-9]+(\.[0-9]{0,$digits->[1]})?$/;
    }
    else {
      $re = qr/^[0-9]+(\.[0-9]*)?$/;
    }
    
    # Check value
    if ($value =~ /$re/) {
      return 1;
    }
    else {
      return 0;
    }
  }

=head2 How to create the corresponding filtering functions in Version 0.xx constraint functions.

I show some examples.

trim_collapse

  $vc->add_filter(trim_collapse => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;
    
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;

    return $value;
  });

trim_lead

  $vc->add_filter(trim_lead => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;

    $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms;

    return $value;
  });

trim_trail

  $vc->add_filter(trim_trail => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;

    $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms;

    return $value;
  });

trim_uni

  $vc->add_filter(trim_uni => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;

    $value =~ s/^\s*(.*?)\s*$/$1/ms;

    return $value;
  });

trim_uni_collapse

  $vc->add_filter(trim_uni_collapse => sub {
    my ($vc, $value, $arg) = @_;

    return undef unless defined $value;
    
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;

    return $value;
  });

trim_uni_lead

  $vc->add_filter(trim_uni_lead => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;
    
    $value =~ s/^\s+(.*)$/$1/ms;
    
    return $value;
  });

trim_uni_trail

  $vc->add_filter(trim_uni_trail => sub {
    my ($vc, $value, $arg) = @_;
    
    return undef unless defined $value;

    $value =~ s/^(.*?)\s+$/$1/ms;

    return $value;
  });

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

L<http://github.com/yuki-kimoto/Validator-Custom>

=head1 COPYRIGHT & LICENCE

Copyright 2009-2017 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
