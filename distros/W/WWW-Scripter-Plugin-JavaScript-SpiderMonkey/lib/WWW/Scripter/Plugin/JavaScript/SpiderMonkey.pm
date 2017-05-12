BEGIN { require 5.006 }

package WWW::Scripter::Plugin::JavaScript::SpiderMonkey;

use#
strict; use#
warnings;

use Carp 'croak';
use Hash::Util::FieldHash::Compat 'fieldhash';
use HTML::DOM::Interface ':all'; # for the constants
use JavaScript 1.12; # PerlSub type
use Scalar::Util qw'weaken blessed ';
use WWW'Scripter'Plugin'JavaScript 0.005; # back_end

our $VERSION = '0.003';

no constant 1.03 ();
use constant::lexical {
	wndw => 0,
	cntx => 1,
	setr => 2,
	exst => 3,
	hash => 4, # whether a particular package needs a hash wrapper
	isam => 5,
	wrap => 6, # hash wrappers
	defs => 7,
	defg => 8,
	defm => 9,
	getr =>10,
};

my $rt;

fieldhash my %destructibles;

sub new {
	$rt ||= new JavaScript::Runtime;

	my $class = shift;
	my $self = bless[], $class;
	$self->[wndw] = my $parathi = shift,
	$self->[cntx] = my $cx = $rt->create_context;
	$self->[hash] = {};

	# Weaken the reference to the WWW::Scripter object. Otherwise we
	# have a reference loop:
	#    	window -> js plugin -> sm back end -> window
	weaken $parathi;

	# cache $self so we can purge it in an END block
	weaken(my $weak_self = $self);
	$destructibles{$self} = \$weak_self;

	my @wrappers;
	@wrappers[BOOL,STR,OBJ] = @{ $cx->eval(' 0,function() {
		// for speed:
		frames = self = window = this
		return [
			function(func_name) {
		       		var f = this[func_name]
				func_name = function() {
					return Boolean(
						f.apply(this, arguments)
					)
				}
			},
			function(func_name) {
				var f = this[func_name]
				func_name = function() {
					var r = f.apply(this, arguments)
					return r === null || r === void 0
						? null : Object(r)
				}
			},
			function(func_name) {
				var f = this[func_name]
				func_name = function() {
					var r = f.apply(this, arguments)
					return r === null || r === void 0
						? null : ""+r
				}
			},
		]
	}() ') };
	
	
	my $i = \%WWW'Scripter'WindowInterface;
	my %methods;
	@methods{ grep !/^_/ && $$i{$_} & METHOD, =>=> keys %$i } = ();
	for(keys %methods) {
		my $method = $_;
		my $type = $$i{$_}&TYPE;
		if($type == NUM) {
			$cx->bind_function($_ => sub {
				0+$parathi->$method(@_);
			});
		}
		else {
			$cx->bind_function($_ => sub {
				$parathi->$method(@_);
			});
			$wrappers[$type]($_);
		}

	}

	my $fetch = $cx->eval('
	  0,function(p,f){__defineGetter__(p, function(){return f()})}
	');
	my $store = $cx->eval('
	  0,function(p,f){__defineSetter__(p, function(v){f(v)})}
	');
	weaken(my $cself = $self); # for closures (not foreclosures)
# ~~~ We still need to deal with type conversion.
	my %props;
	@props{ grep !/^_/ && !($$i{$_}&METHOD) =>=> keys %$i } = ();
	for(keys %props) {
		my $name = $_;
		next if $name =~ /^(?:frames|window|self)\z/; # for
		my $type = $$i{$_}&TYPE;                      # efficiency
		&$store($_ => sub {
				#my $self = shift;
				#$self->_cast(
				#	scalar
					  $self->[wndw]->$name,
				#	$types[$type&TYPE]
				#);
			});
		unless($type & READONLY) {
			&$fetch( $_ => sub {
					#my $self = shift;
					#$self->_cast(
					#	scalar
					my $ret = $cself->[wndw]->$name;
					exists $cself->[hash]{ref $ret}
					? $cself->hash_wrapper($ret)
					: $ret;
					#	$types[$type&TYPE]
					#);
				} );
		}
	}

	$self
}

END { # Empty any $selves *before*  global destruction,  to ensure that any
 for(values %destructibles) {  # SM objects we reference go away before the
  # This line causes a crash in perl 5.8.8. It seems   # runtime is  freed.
  # that 5.8.8 has some bug in av_clear in that it can end
  # up trying to write to the xpvav  struct after the array has
  # been freed.  Since, when the array is freed, the sv_any pointer
  # (which usually  points to the xpvav struct) points to another freed
  # sv, it causes a crash if that sv is used again. Or something like that.
  # I never did finish getting to the bottom of it.
  #@$$_ = ();
  undef $_ for @$$_;
 }
}

sub eval {
	my ($self,$code,$url,$line) = @_;
	defined $line and substr $code, 0, 0 =>= "\n" x ($line-1);
	$self->[cntx]->eval($code,$url)
}

sub set {
	croak "Not enough arguments for W:M:P:JS:SM->set" unless @_ > 2;

	my $self = shift;
	my @args = @_;
	if(my $h = $self->[hash]) {
		for(@args){
		 defined blessed $_ or next;
		 exists $$h{ref $_} and $_ = $self->hash_wrapper($_),
		}
	}
	( $$self[setr] ||= $self->[cntx]->eval('0,function() {
		var a = arguments;
		var $obj = this;
		var $val = a[a.length-1];
		var $prop = a[a.length-2];
		for (var i = 0; i < a.length-2; ++i) {
			var $_ = a[i]
			$_ in $obj || ($obj[$_] = {});
			$obj = $obj[$_];
		}
		$obj[$prop] = $val;
	  }') )
	  ->(@args);
	return;
}

sub bind_classes {
# ~~~ We still need to deal with type conversion and read-only props.
	my($self, $classes) = @_;
	weaken(my $cself = $self); # self for closures
	my $cx = $self->[cntx];
	my $exists = $self->[exst] ||= $cx->eval('0,function(prop) {
		return prop in this
	}');
	my @defer;
	my $isa_maker = $self->[isam] ||= $cx->eval('
		0,function(class,super) {
			this[class].__proto__ = this[super]
		}
	');
	my $define_setter = $self->[defs] ||= $cx->eval('
		0,function(class,prop,sub) {
			this[class].prototype.__defineSetter__(
			 prop,
			 function(v) {
			  sub(this, v)
			 }
			)
		}
	');
	my $define_string_getter = $self->[defg] ||= $cx->eval('
		0,function(class,prop,sub) {
			this[class].prototype.__defineGetter__(
			 prop,
			 function() {
			  var ret = sub(this)
			  return(
			   typeof ret == "undefined" ? null : String(ret)
			  );
			 }
			)
		}
	');
	my $define_string_meth = $self->[defm] ||= $cx->eval('
		0,function(class,prop,sub) {
			this[class].prototype[prop] = function() {
			  var ret = sub.apply(this,arguments);
			  return(
			   typeof ret == "undefined" ? null : String(ret)
			  );
			}
		}
	');
				

	for (grep /::/, keys %$classes) {
		my $i = $$classes{$$classes{$_}}; # interface info
		if($$i{_hash} || $$i{_array}) { #  **Shudder!**
		 my %props;
		 my %methods;
		 {
		  my $i = $i;
		  while() {
		   $props{$_} = undef
		    for grep !/^_/ && !($$i{$_} & METHOD),keys %$i;
		   $methods{$_} = undef
		    for grep !/^_/ && $$i{$_} & METHOD, keys %$i;
		   exists $$i{_isa} || last;
		   $i = $$classes{$$i{_isa}};
		  }
		 }
		 $self->[hash]{$_} = [
		  @$i{'_array','_hash'},\%props,\%methods
		 ];
		}
		else {
		 my @props = grep !/^_/ && !($$i{$_} & METHOD), keys %$i;
		 my @str_props;
		 my @str_meths;
		 $cx->bind_class(
		  package => $_,
		  name    => $$classes{$_},
		  methods => { map {
		   if(($$i{$_} & TYPE) == STR) {
		    push @str_meths, $_;
		    ()
		   }
		   else {
		    my $method = $_;
		    $_ => sub {
		     my $self = shift;
		     my $ret = $self->$method(@_);
		     exists $cself->[hash]{ref $ret}
		     ? $cself->hash_wrapper($ret)
		     : $ret
		    }
		   }
		  } grep !/^_/ && $$i{$_} & METHOD, keys %$i },
		  properties => { map {
		   if(($$i{$_} & TYPE) == STR) {
		    push @str_props, $_;
		    ()
		   }
		   else {
		    my $prop = $_;
		    $_ => [
		     sub {
		      my $self = shift;
		      my $ret = $self->$prop;
		      exists $cself->[hash]{ref $ret}
		      ? $cself->hash_wrapper($ret)
		      : $ret
		     },
		     sub {
		     # my $self = shift;
		     # my $ret = $self->$prop(@_);
		     # return;
		     },
		    ]
		   }
		  } @props },
		  exists $$i{_constructor}
		   ? (constructor => $$i{_constructor})
		   : (flags => JS_CLASS_NO_INSTANCE),
		 );
		 for my $p(@props) {
		  &$define_setter($$classes{$_}, $p, sub {
		   shift->$p(@_); return
		  });
		 }
		 for my $p(@str_props) {
		  &$define_string_getter($$classes{$_}, $p, sub {
		   shift->$p(@_);
		  });
		 }
		 for my $p(@str_meths) {
		  &$define_string_meth($$classes{$_}, $p, sub {
		   shift->$p(@_);
		  });
		 }
		}

		if(exists $$i{_constants}){
		   my $p = $_;
		   for(@{$$i{_constants}}){
		    /([^:]+\z)/;
		    $self->set($$classes{$p}, $1, eval);
		   }
		}
		
		if (exists $$i{_isa}) {
			if(!&$exists($$i{_isa})) {
				push @defer, [$$classes{$_}, $$i{_isa}]
			} else {
				$isa_maker->($$classes{$_}, $$i{_isa});
			}
		}
	}
	while(@defer) {
		my @copy = @defer;
		@defer = ();
		for (@copy) {
			if(&$exists($$_[1])) { # $$_[1] == superclass
				$isa_maker->(@$_);
			}
			else {
				push @defer, $_;
			}
		}
	}

	return;
}

sub event2sub {
	my ($self, $code, $elem, $url, $line) = @_;

	# We create a function with a specific scope chain by generating
	# and calling code like this:
	#  (function() {
	#   with(arguments[0])with(arguments[1])with(arguments[2])
	#    return function() { ... }
	#  })

	# The global object is automatically in the scope, so we don’t need
	# to add it explicitly.
	my @scope = (
		$elem->can('form') ? $elem->form : (),
		$elem
	);

	# We need the line break after $code, because there may be a sin-
	# gle-line comment at the end,  and no  line  break.  ("foo //bar"
	# would fail without this,  because the closing }})  would be  com-
	# mented out too.)
	($self->[cntx]->eval(
	  "\n" x($line-1) . "(function(){"
	  . (join '', map "with(arguments[$_])", 0..$#scope)
	  . "return function() { $code\n } })",
	  $url
	)||return) -> ( @scope );
}

sub new_function {
	my($self, $name, $sub) = @_;
	$self->set($name,$sub);
	return;
}

sub hash_wrapper {
	my $self = shift;
	my $w = $self->[wrap] ||= &fieldhash({});
	my $obj = shift;
	$w->{$obj} ||= do {
		my $wrapper = new JavaScript::PerlHash;
		# WWW::Scripter is the special case
		if(ref $obj eq 'WWW::Scripter') {
			tie
			  %{get_ref $wrapper},
			 __PACKAGE__.'::WindowProxy',
			  $obj;
		}
		else {
			my $binding_info = $self->[hash]{ref $obj};
			tie
			  %{$wrapper->get_ref},
			 __PACKAGE__.'::Hash',
			  $obj, @$binding_info, $self;
		}
		$wrapper;
	}
}

sub _hash_classes { shift->[hash] }


package WWW::Scripter::Plugin::JavaScript::SpiderMonkey::WindowProxy;
# Is this package name long enough?

sub TIEHASH {
	# Slot 0 is the WWW::Scripter object. Slot 1 is used to catch the
	# fetching function.
	bless [pop], shift;
}

sub STORE {
 my $w = ${;shift}[0];
 $w->plugin("JavaScript")->back_end($w)->set(shift, shift);
}

sub CLEAR{}

sub FETCH {
 my $self = shift;
 my $w = $$self[0];
 (
  $$self[1]
   ||= $w->plugin("JavaScript")->back_end($w)->eval(
        '0,function(k){ return this[k] }'
       )
 )->(shift)
}


package WWW::Scripter::Plugin::JavaScript::SpiderMonkey::Hash;

use constant::lexical {
 obje => 0, arry => 1, hash => 2, prop => 3, meth => 4, jsbe => 5,
};

sub TIEHASH {
	# args: 0) object to wrap
	#       1) array?
	#       2) hash?
	#       3) { props }
	#       4) { methods }
	#       5) JavaScript back end (wspjssm object)
	my $ret = bless \@_, shift;
#	warn "wrapping up a " . ref($obj) . " object with props [ @{$ret->[prop]} ]";
	Scalar::Util'weaken($ret->[jsbe]);
	$ret;
}

sub STORE {
 my $self = shift;
 my $name = shift;
 exists $self->[prop]{$name} and $self->[obje]->$name(shift), return;
 exists $self->[meth]{$name} and return;
 $self->[arry] && $name =~ /^(?:0|[1-9]\d*)\z/ && $name < 4294967295
 ? $self->[obje][$name]=shift
 :($self->[obje]{$name}=shift);
}

sub CLEAR{}

sub FETCH {
 my $self = shift;
 my $name = shift;
 my $ret =
  exists $self->[prop]{$name} ? $self->[obje]->$name :
  exists $self->[meth]{$name} ? return sub { $self->[obje]->$name(@_) } :
  $self->[arry] && $name =~ /^(?:0|[1-9]\d*)\z/ && $name < 4294967295
  ? $self->[obje][$name]
  : $self->[obje]{$name};
 exists $self->[jsbe]->_hash_classes->{ref $ret}
  ? $self->[jsbe]->hash_wrapper($ret)
  : $ret;
}


exit exit exit exit exit exit exit exit exit exit exit exit exit return 1;

# ------------------ DOCS --------------------#



=head1 NAME

WWW::Scripter::Plugin::JavaScript::SpiderMonkey - SpiderMonkey backend for wspjs

=head1 VERSION

0.003 (alpha)

=head1 SYNOPSIS

  use WWW::Scripter;
  
  my $w = new WWW::Scripter;
  $w->use_plugin('JavaScript', engine => 'SpiderMonkey');
  
  $w->get("http://...");
  # etc.

=head1 DESCRIPTION

This little module is a bit of duct tape to connect the JavaScript plugin
for L<WWW::Scripter> to the SpiderMonkey JavaScript engine via
L<JavaScript.pm|JavaScript>. Don't use this module
directly. For usage, see
L<WWW::Scripter::Plugin::JavaScript>.

=head1 BUGS

There are too many to list! This thing is currently very unstable, to put
it mildly.

If you find any bugs, please report them via L<http://rt.cpan.org/>
or
L<bug-WWW-Scripter-Plugin-JavaScript-SpiderMonkey@rt.cpan.org> (long e-mail
address, isn't it?).

=head1 SINE QUIBUS NON

perl 5.8.3 or higher (5.8.6 or higher recommended)

HTML::DOM 0.008 or later

JavaScript.pm 1.12 or later

Hash::Util::FieldHash::Compat

constant::lexical

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2010-11, Father Chrysostomos (org.cpan@sprout backwards)

This program is free software; you may redistribute it, modify it or
both under the same terms as perl.

=head1 SEE ALSO

=over 4

=item -

L<WWW::Scripter::Plugin::JavaScript>

=item -

L<JavaScript.pm|JavaScript>
