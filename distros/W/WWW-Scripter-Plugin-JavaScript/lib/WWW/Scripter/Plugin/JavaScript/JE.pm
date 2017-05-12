package WWW::Scripter::Plugin::JavaScript::JE;

use strict;   # :-(
use warnings; # :-(

use Carp 'croak';
use Hash::Util::FieldHash::Compat 'fieldhash';
use HTML::DOM::Interface 0.032 ':all'; # for the constants (0.032
use JE'Destroyer;                      # for UTF16)
use JE 0.038; # call_with
use Scalar::Util 1.09 qw'weaken refaddr';

our $VERSION = '0.009';
our @ISA = 'JE';

fieldhash my %parathia;

# No need to implement eval since JE's method
# is sufficient

my @types;
$types[BOOL] = Boolean =>;
$types[STR ] = DOMString  =>;
$types[NUM ] = Number  =>;
$types[OBJ ] = null    =>;

sub new {
	my $self = SUPER::new{shift} html_mode => 1;
	weaken( $parathia{$self} = my $parathi = shift );
	
	my $i = \%WWW'Scripter'WindowInterface;
	for(grep !/^_/ && $$i{$_} & METHOD, =>=> keys %$i) {
		my $method = $_;
		my $type = $$i{$_};
		$self->new_method($_ => sub {
			my $parathi = $parathia{my $self = shift};
			# undocumented JE methods:
			$self->_cast(
				scalar
				 $parathi->$method($self->_unwrap(@_)),
				$types[$type&TYPE]
			);
		});
	}
	for(grep !/^_/ && !($$i{$_}&METHOD) =>=> keys %$i) {
		my $name = $_;
		next if $name =~ /^(?:window|self)\z/; # for efficiency
		my $type = $$i{$_};
		if ($type & READONLY) {
			$self->prop({
				name => $_,
				readonly => 1,
				fetch => sub {
					my $self = shift;
					$parathia{$self}->$name;
					$self->_cast(
						scalar
						  $parathia{$self}->$name,
						$types[$type&TYPE]
					);
				},
			});
		}
		else {
			$self->prop({
				name => $_,
				fetch => sub {
					my $self = shift;
					$self->_cast(
						scalar
						  $parathia{$self}->$name,
						$types[$type&TYPE]
					);
				},
				store => sub {
					my $self = shift;
					$self->_cast(
						scalar
						  $parathia{$self}
						    ->$name(shift),
						$types[$type&TYPE]
					);
				},
			});
		}
	}

	# ~~~ This is *such* a hack! If anyone wants to help me fix JE’s
	#     screwed up type-conversion system (which makes my head hurt),
	#     please let me know.
	$self->new_function("DOMString", sub {
		if(ref($_[0]) =~ /^JE::(?:Null|Undefined)\z/) {
			return $_[0]->global->null;
		}
		return $_[0]->to_string;
	});

	$self->bind_class(
		package => 'WWW::Scripter',
		wrapper => sub {
			my ($self, $window) = @_;

			# ~~~ This needs to be modified to create a special
			#     restrictive wrapper if the $window has a
			#     different origin.
			# Fetch the cached JavaScript  environment  corres-
			# ponding to the WWW::Scripter object.
#warn $window, " ", $window->response, " ", $window->uri;
			refaddr
			 $window->plugin("JavaScript")->back_end($window)
			 == refaddr $self
			  and return $self;
			(__PACKAGE__."::Proxy")->new($window)
		},
	);
	$self->bind_class(
		package => 'WWW::Scripter::Frames',
		wrapper => sub {
			my($self,$frames) = @_;
			return $self->upgrade($frames->window);
		},
	);
	# ~~~ We also need a 'JE' wrapper, that will create a special
	#     objcet that delegates to the JS environment currently
	#     belonging to the window.

	for my $p($self->{String}{prototype}) {
		for my $v(
		 ['anchor','a','name'],
		 ['fontcolor','font','color'],
		 ['fontsize','font','size'],
		 ['link','a','href'],
		) {
			$p->new_method(
			 $$v[0],
			 sub{
			  qq'<$$v[1] $$v[2]="'
			  . (defined $_[1] ? $_[1] : 'undefined')
			  . qq'">$_[0]</$$v[1]>'
			 }
			)
		}
		for my $v('big', 'blink', 'small','strike','sub','sup') {
			$p->new_method( $v, sub{"<$v>$_[0]</$v>"} )
		}
		for my $v(['bold','b'],['fixed','tt'],['italics','i'],) {
			$p->new_method(
			 $$v[0],
			 sub{"<$$v[1]>$_[0]</$$v[1]>"}
			);
		}
	}

	# for speed:
	$self->prop('frames' => $self);
	$self->prop('window' => $self);
	$self->prop('self' => $self);
}

sub prop {
	my $self = shift;
	return $self->SUPER::prop(@_) if ref $_[0] eq 'HASH';
	
	my $val = $self->SUPER::prop(@_);
	return $val if defined $val;

	my $name = shift;
	return $_[0] if @_;

	my $window = $parathia{$self};

	my $ret =
		$name =~ /^(?:0|[1-9]\d*)\z/ && $name < 4294967295
        	? $window->frames->[$name]
		: $window->frames->{$name};
	defined $ret ? $self->upgrade($ret) : $ret;
}

sub set {
	my $obj = shift;
	my $val = pop;
	croak "Not enough arguments for W:M:P:JS:JE->set" unless @_;
	my $prop = pop;
	for (@_) {
		my $next_obj = $obj->{$_};
		defined $next_obj or
			$obj->{$_} = {},
			$obj = $obj->{$_}, next;
		$obj = $next_obj;
	}
	$obj->{$prop} = $val;
	return;
}

sub bind_classes {
	my($self, $classes) = @_;
	my @defer;
	for (grep /::/, keys %$classes) {
		my $i = $$classes{$$classes{$_}}; # interface info
		my @args = (
			unwrap  => 1,
			package => $_,
			name    => $$classes{$_},
			methods => { map {
			   my $perlname = $_;
			   $perlname .= 16 if $$i{$_} & UTF16;
			   $_ => $$i{$_} & VOID
			    ? $perlname
			    : "$perlname:$types[$$i{$_} & TYPE]"
			  } grep !/^_/ && $$i{$_} & METHOD, keys %$i },
			props => { map {
			   my $perlname = $_;
			   $perlname .= 16 if $$i{$_} & UTF16;
			   $$i{$_} & READONLY
			      ? ($_ =>{
			          fetch=>
			           "$perlname:$types[$$i{$_} & TYPE]"
			        })
			      : ($_ => "$perlname:$types[$$i{$_} & TYPE]")
			 } grep !/^_/ && !($$i{$_} & METHOD), keys %$i  },
			hash  => $$i{_hash},
			array => $$i{_array},
			exists $$i{_isa} ? (isa => $$i{_isa}) : (),
			exists $$i{_constructor}
				? (constructor => $$i{_constructor})
				: (),
		);
		my $make_constants;
		if(exists $$i{_constants}){
		  my $p = $_;
		  $make_constants = sub { for(@{$$i{_constants}}){
			/([^:]+\z)/;
			$self->{$$classes{$p}}{$1} =
			# ~~~ to be replaced simply with 'eval' when JE's
			#     upgrading is improved:
				$self->upgrade(eval)->to_number;
		}}}
		if (exists $$i{_isa} and !exists $self->{$$i{_isa}}) {
			push @defer, [\@args, $$i{_isa}, $make_constants]
		} else {
#			use Data::Dumper; print Dumper \@args if $_ !~ /HTML|CSS/;
			$self->bind_class(@args);
			defined $make_constants and &$make_constants;
		}
	}
	while(@defer) {
		my @copy = @defer;
		@defer = ();
		for (@copy) {
			if(exists $self->{$$_[1]}) { # $$_[1] == superclass
				$self->bind_class(@{$$_[0]});
				&{$$_[2] or next}
			}
			else {
				push @defer, $_;
			}
		}
	}
	return;
}

sub event2sub {
	my ($w, $code, $elem, $url, $line) = @_;

	# ~~~ JE's interface needs to be improved. This is a mess:
	# We need the line break after $code, because there may be a sin-
	# gle-line comment at the end,  and no line break.  ("foo //bar"
	# would fail without  this,  because  the  })  would  be  com-
	# mented out too.)
	# We have to check whether the $elem is a form before calling it’s
	#‘form’  method,  because forms *do*  have such a method,  but it
	# returns a list of form element names and values, which is *not*
	# what we  want.  (We  want  the  element’s  parent  form  where
	# applicable.)
	($w->compile("(function(){ $code\n })",$url,$line)||return)
		->execute($w, bless [
			$w,
			$w->upgrade($elem->ownerDocument),
			$elem->tag ne 'form' && $elem->can('form')
			  ? $w->upgrade($elem->form) : (),
			my $wrapper=($w->upgrade($elem))
		], 'JE::Scope');
}

sub define_setter {
	my $obj = shift;
	my $cref = pop;
	my $prop = pop;
	for (@_) {
		my $next_obj = $obj->{$_};
		defined $next_obj or
			$obj->{$_} = {},
			$obj = $obj->{$_}, next;
		$obj = $next_obj;
	}
	$obj->prop({name=>$prop, store=>sub{$cref->($_[1])}});
	return;
}

sub new_function {
	my($self, $name, $sub, $type) = @_;
	if(defined $type) {
		$self->new_function(
			$name => sub { $self->{$type}->($sub->(@_)) }
		);
		weaken $self;
	} else {
		shift->SUPER::new_function(@_);
	}
}

sub exists {
	my $self = shift;
	SUPER::exists $self @_
	 or do {
		my($name) = @_;
		my $window = $parathia{$self};
		$name =~ /^(?:0|[1-9]\d*)\z/ && $name < 4294967295
		? defined $window->frames->[$name]
		: defined $window->frames->{$name}
	}
}

sub destroy {
 return SUPER::destroy{@_} if caller eq 'JE::Destroyer';
 JE'Destroyer'destroy $_[0]
}


package WWW::Scripter::Plugin::JavaScript::JE::Proxy;

# ~~~ This package needs to override any method used internally by
#     JavaScript that returns a JE datatype to return a wrapper instead.

sub new {
 # If a method is called on another window, as in frames[0].alert(), an
 # lvalue is created with the proxy object returned by frames[0]  as the
 # the base and ‘alert’ as the property name. The lvalue then fetches the
 # value of frames[0].alert  and runs it with  frames[0]  as the invocant.
 # This means that it is the proxy  that  gets  passed  to  the  closures
 # in  WSPJSJE:new  above.  Since  those  expect  to  find  a  window  in
 # $parathia{$self}, and $self might be a proxy, we have to add ourselves
 # to the %parathi field hash and store the window there. For the sake of
 # speed in autoload, we still keep a direct  reference  to  the  window.
 my $proxy = bless \(my $w = pop);
 Scalar'Util'weaken( $parathia{$proxy} = $w );
 $proxy
}

sub AUTOLOAD {
 my $window = ${;shift};
 (
   # We have to use this roundabout method
   # rather than __PACKAGE__->new($window),
   # because the JS plugin needs to do its
   # stuff (binding classes, etc.).
   $window->plugin("JavaScript")->back_end($window)
 )->${\(our $AUTOLOAD =~ /.*::(.+)\z/)[0]}(@_)
}

sub DESTROY{}
sub isa {
 goto &UNIVERSAL'isa;
}


=cut

# ------------------ DOCS --------------------#

=head1 NAME

WWW::Scripter::Plugin::JavaScript::JE - JE backend for WSPJS

=head1 VERSION

0.008 (alpha)

=head1 DESCRIPTION

This little module is a bit of duct tape to connect the JavaScript plugin
for L<WWW::Scripter> to the JE JavaScript engine. Don't use this module
directly. For usage, see
L<WWW::Scripter::Plugin::JavaScript>.

=head1 REQUIREMENTS

Hash::Util::FieldHash::Compat

HTML::DOM 0.032 or later

JE 0.056 or higher

WWW::Scripter 0.016 or higher

=head1 SEE ALSO

=over 4

=item -

L<WWW::Scripter::Plugin::JavaScript>

=item -

L<JE>

=item -

L<HTML::DOM>

=item -

L<WWW::Mechanize::Plugin::JavaScript::JE> (the original version of this
module)

=cut
