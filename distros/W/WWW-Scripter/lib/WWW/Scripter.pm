use 5.006;

package WWW::Scripter;

our $VERSION = '0.032';

use strict; use warnings; no warnings qw 'utf8 parenthesis bareword';

use CSS'DOM'Interface;
use Encode qw'encode decode';
use Exporter 5.57 'import';
use HTML::DOM 0.045; # weaken_response
use HTML::DOM::EventTarget 0.053; # DOMAttrModified with correct type and
use HTML::DOM::Interface 0.019 ':all';  # cancellability
use HTML::DOM::View 0.018;
use HTTP::Headers::Util 'split_header_words';
use HTTP::Response;
use HTTP::Request;
use Scalar::Util 1.09 qw 'blessed weaken reftype';
use List'Util 'sum';
use LWP::UserAgent;
use Time::HiRes 'time';
BEGIN {
  require constant;
  require WWW::Mechanize;
  VERSION WWW::Mechanize $LWP::UserAgent::VERSION >= 5.815 ? 1.52 : 1.2;
  # Version 1.52 is necessary for LWP 5.815 compatibility. Version 1.2 is
  # needed otherwise for its handling of cookie jars during cloning.
  import constant Mech => 'WWW::Mechanize';
}

BEGIN {
 if(eval { require Hash::Util::FieldHash }) {
  import Hash::Util::FieldHash qw < fieldhash fieldhashes >;
 } else {
  require Tie::RefHash::Weak;
  VERSION Tie::RefHash::Weak 0.08; # fieldhash
  import Tie::RefHash::Weak qw < fieldhash fieldhashes >;
 }
}

our @ISA = (Mech, qw( HTML::DOM::View HTML::DOM::EventTarget ));

eval <<'' unless exists &UNIVERSAL'DOES;
sub DOES {
 goto &{$_[0]->can("SUPER::DOES")||$_[0]->can("isa")}
}

our @EXPORT_OK = qw/abort/;
our %EXPORT_TAGS = (
    all      => \@EXPORT_OK,
);

# Fields that we don’t want fiddled with when the page stack is
# manipulated:
fieldhashes \my( %scriptable, %script_handlers, %scrn,
                 %class_info, %navi );
# ~~~ Actually, most of these can be eliminated, since we can store them
#     directly in the object, as we are not doing that cloning that Mech
#     used to do between pages.

# Fields keyed by document:
fieldhashes \my( %timeouts, %timers, %frames, %evtg, %status, %dstatus );

fieldhash my %document; # keyed by response — we actually use
                        # HTML::DOM::View’s storage for the current doc,
                        # but this field hash is necessary when we return
                        # to a page.

# These are used to create a link between a WWW::Mechanize::(Image|Link)
# object and the DOM equivalent.
fieldhash my %dom_obj;

# ------------- Mech overrides (or does it?) ------------- #

sub new {
	my $class = shift;
	my %args = @_;
	exists $args{max_docs}
	 and $args{stack_depth} = -1+delete$args{max_docs};
	my $max_history = delete $args{max_history};

	my $self = $class->SUPER::new(%args);

	$$self{Scripter_max_hist} = $max_history;
	$script_handlers{$self} = {};
	$scriptable{$self} = 1;

	$self->{page_stack} = WWW'Scripter'History->new( $self );

	weaken(my $self_fc = $self); # for closures
	$class_info{$self} = [
	 \(%HTML::DOM'Interface, %CSS'DOM'Interface, our%Interface), {
	  'WWW::Scripter::Image' => "Image",
	   Image                 => {
	    _constructor => sub {
	     my $i = $self_fc->document->createElement('img');
	     @_ and $i->attr('width',shift);
	     @_ and $i->attr('height',shift);
	     $i
	    }
	   },
	 }
	];

	unless(exists $args{agent}) {
		$self->agent("WWW::Scripter/$VERSION");
	}

	# I would like to avoid doing this when it is not necessary, but
	# the alternative would  require  overriding  HTML::DOM::View’s
	# document method, and that might slow things down more, since
	# document  is called more often than new  Scripter  objects
	# are created.
	_initial_page($self);

	$self;
}

sub _initial_page {
	my $req = new HTTP::Request 'GET', 'about:blank';
	my $res = new HTTP::Response 200, OK => [
	 'content-length' => 0,
	 'content-type' => 'text/html',
	], '';
	$res->request($req);
	shift->_update_page(
	 $req, $res
	);
}

sub clone {
	my $clone = (my $self = shift)->SUPER::clone(@_);
	$$_{$clone}=$$_{$self} for \(
	 %scriptable,%script_handlers
	);
	$class_info{$clone} = [@{$class_info{$self}}];
	$clone->{handlers} = $self->{handlers};
	$clone->{page_stack} = WWW'Scripter'History->new($clone);
	delete @$clone{<Scripter_loc Scripter_nm>};
	$clone->_clone_plugins;
	$clone;
}

sub title { (shift->document||return)->title(@_) }

sub content {
	my $self = shift;
	if($self->is_html && $self->document) {
		my %parms = @_;
		my $cs = (my $doc = $self->document)->charset;;
		if(exists $parms{format} && $parms{format} eq 'text') {
			my $text = $doc->documentElement->as_text;
			return defined $cs ? encode $cs, $text : $text;
		}
		my $content = $doc->innerHTML;
		$content = encode $cs, $content if defined $cs;
		$self->{content} = $content; # banana
	}
	$self->SUPER::content(@_);
}

#sub discontent { ... }

# Some parts of this were taken straight from WWW::Mechanize.
sub follow_link {
	no warnings 'redefine';
	my $self = shift;
	my %parms = ( n=>1, @_ );

	if ( $parms{n} eq 'all' ) {
	    delete $parms{n};
	    $self->warn( q{follow_link(n=>"all") is not valid} );
	}

	my $link = $self->find_link(%parms);
	if($link and tag $link =~ '^a') {
		my $follow;
		my $dom_link = $dom_obj{$link};
		$dom_link->trigger_event('click',
			# We used to have simply DOMActivate_default => ...
			# but that  did  absolutely  nothing,  since  the
			# *_default arguments apply solely to the current
			# event  (which is a click event).  So  we  have
			# to override HTML::DOM::Element’s click_default
			# to  trigger  the  DOMActivate  event  with  the
			# DOMActivate_default argument. And, no, some sort
			# of localisation mechanism would not  do  instead,
			# because event handlers could click other  links
			# (or even this one again), which events should
			# remain unaffected by this *_default override.
			# ~~~ Or should they???
			click_default => sub {
			 $dom_link->trigger_event('DOMActivate',
			  DOMActivate_default => sub { ++$follow }
			 )
			}
		);
		return unless $follow;
		return ($self->find_target($dom_link->target)||$self)
		        ->get($link->url);
	}
	else {
	    $self->die(
	     'Link not found: ',
	      join ", ", map "$_ => '$parms{$_}'", sort keys %parms
	    )
	     if $self->{autocheck};
	}
	Scripter_plit:
}


sub request {
  for (my $foo) { # protect against tied $_
    my $self = shift;
    return unless defined(my $request = shift);

    $request = $self->_modify_request( $request );

    my $meth = $request->method;
    my $orig_uri = $request->uri;
    my $new_uri;
    if ((my $path = $orig_uri->path) =~ s-^(/*)/\.\./-$1||'/'-e) {
     0while $path =~ s\\$1||'/'\e;
     ($new_uri = $orig_uri->clone)->path($path)
    }
    my $skip_fetch;
    if(defined($orig_uri->fragment)) {
     ($new_uri ||= $orig_uri->clone)->fragment(undef);

     # Skip fetching the URL if it is the same (and there is a fragment).
     # We don’t need to strip the fragment from $self->uri before compari-
     # son as that always contains the actual URL  sent  in  the  request.
     $meth eq "GET" and $new_uri->eq($self->uri) and ++$skip_fetch;
    }
    if ($new_uri) {
     $request->uri($new_uri);
    }

    my $response;

    if($skip_fetch) {
     $response = $self->response;
    }
    else {
     Scripter_REQUEST: {
        Scripter_ABORT: {
            $response = $self->_make_request( $request, @_ );
            last Scripter_REQUEST;
        }
        return 1
     }
    }

    if ( $meth eq 'GET' || $meth eq 'POST' ) {
        $self->get_event_listeners('unload') and
         $self->trigger_event('unload'),
         $self->{page_stack}->_delete_res;

        $self->{page_stack}->${\(
         $self->{Scripter_replace} ? '_replace' : '_add'
        )}($request, $response, $orig_uri);
    }

    return $self->_update_page($request, $response);
  }
}

for my $method (qw < get put post head >){
 no strict 'refs';
 *$method = sub {
   for(my $foo) { # protect against tied $_
     my ($self, $uri) = (shift, shift);
     $uri = $uri->url if ref $uri eq 'WWW::Mechanize::Link';
     my $abs = new_abs URI $uri, my $base = $self->base;
     # URI screws up data fragments
     if ($abs =~ /^data:#/i && $abs ne $uri && $uri =~ /^#/) {
         $abs = "$base$uri";
     }
     # For get and put, we have replicated here what the Mech methods do,
     # so for speed’s sake go straight to LWP.
     return $self->${\"LWP::UserAgent::$method"}($abs, @_);
   }
 };
}


# The only difference between this one and Mech is the args to
# decoded_content. I.e., this is the way Mech *used* to work.
sub _update_page {
    my ($self, $request, $res) = @_;

    $self->{req} = $request;
    $self->{redirected_uri} = $request->uri->as_string;

    $self->{res} = $res;

    $self->{status}  = $res->code;
    $self->{base}    = $res->base;
    $self->{ct}      = $res->content_type || '';

    if ( $res->is_success ) {
        $self->{uri} = $self->{redirected_uri};
        $self->{last_uri} = $self->{uri};
    }

    if ( $res->is_error ) {
        if ( $self->{autocheck} ) {
            $self->die( 'Error ', $request->method, 'ing ', $request->uri, ': ', $res->message );
        }
    }

    $self->_reset_page;

    # Try to decode the content. Undef will be returned if there's nothing to decompress.
    # See docs in HTTP::Message for details. Do we need to expose the options there?
    my $content = $res->decoded_content(charset => "none");
    $content = $res->content if (not defined $content);

    $content .= &{\&{Mech."::_taintedness"}};

    if (
     !defined $$self{Scripter_dumb} || $$self{Scripter_dumb}
     and $self->is_html
    ) {
        $res = $self->update_html($content);
    }
    else {
        $self->{content} = $content;
        $self->document(undef);
    }

    return $res;
} # _update_page

sub _fetch_url {
    my ($self) = @'_;
    my $fetcher = $self->{Scripter_f}
	||= do {
			        (
			         my $clone = $self->clone->clear_history(1)
			        )->dom_enabled(0);
				$clone->max_history(1);
				$clone;
	       };
    $fetcher->{last_uri} = $self->{uri};
    require URI;
    my $base = $self->base;
    $_[1] = URI->new_abs( $_[1], $base )
			            if $base;
    $fetcher->get($_[1]);
}

sub update_html {
	my ($self,$src) = @_;

	# Restore an existing document (in case we are coming back from
	# another page).
	my $res = $self->{res};
	if(my $doc = $document{$res}) {
		$self->document($doc);
		$self->{form} = ($self->{forms} = $doc->forms)->[0];
		return $res;
	}

	my $life_raft = $self;
	weaken($self);

	$self->document($document{$res} = my $tree = new HTML::DOM
			response => $res,
			weaken_response => 1,
			cookie_jar => $self->cookie_jar);

	$tree->error_handler(sub{$self->warn($@)});

	$tree->default_event_handler_for( link => sub {
		my $link = shift->target;
		($self->find_target($link->target)||$self)
		 ->get($link->href)
	});
	$tree->default_event_handler_for( submit => sub {
		my $form = shift->target;
		($self->find_target($form->target)||$self)
		 ->request($form->make_request);
	});

	if(%{$script_handlers{$self}}) {
		my $script_type = $res->header(
			'Content-Script-Type');
		defined $script_type or $tree->elem_handler(meta =>
		    sub {
			my($tree, $elem) = @_;
			no warnings 'uninitialized';
			return unless lc $elem->attr('http-equiv')
				eq 'content-script-type';
			$script_type = $elem->attr('content');
		});

		$tree->elem_handler(script => sub {
			    return unless $scriptable{$self};
			    my($tree, $elem) = @_;

			    my $lang = $elem->attr('type');
			    defined $lang
			        or $lang = $elem->attr('language');
			    defined $lang or $lang = $script_type;

			    my $uri;
			    my($inline, $code, $line) = 0;
			    if($uri = $elem->attr('src')) {
			        my $res = _fetch_url($self, $uri);
			        $res->is_success or do {
			          my $url = $self->uri;
			          my $offset = $elem->content_offset;
			          if (!defined $offset) {
			           $url .= ' (generated HTML)';
				  }
			          else {
			           $url .= ' line '
			                 . _line_no($src,$offset);
			          }
			          $self->warn("couldn't get script $uri: "
			            . $res->status_line . " at $url"
			          ),
			          return;
			        };

			        # Find out the encoding:
			        my $cs = {
			          map @$_,
			          split_header_words $res->header(
			            'Content-Type'
			          )
	 		        }->{charset};

			        $code = decode $cs||$elem->charset
			            ||$tree->charset||'latin1',
			          $res->decoded_content(
			            charset=>'none', raise_error=>1
			          );
			        
			        
			        $line = 1;
			    }
			    else {
			        $code = ($elem->firstChild||return)->data;
			        ++$inline;
			        $uri = $self->uri;
			        if(defined(
			         my $offset = $elem->content_offset
			        )) {
			         $line = _line_no(
					$src,$elem->content_offset
			         );
			        }
			        else { $uri .= " (generated HTML)" }
			    };
			    length $code or return; # optimisation
	
			    my $h = $self->_handler_for_lang($lang);
			    $h && $h->eval($self, $code,
			                   $uri, $line, $inline);
			    $@ and $self->warn($@);
		});

		$tree->elem_handler(noscript => sub {
				return unless $scriptable{$self};
				$_[1]->detach#->delete;
				# ~~~ delete currently stops it from work-
				#     ing; I need to looook into this.
		});

		$tree->event_attr_handler(sub {
				return unless $scriptable{$self};
				my($elem, $event, $code, $offset) = @_;
				my $lang = $elem->attr('language');
				defined $lang or $lang = $script_type;

			        my $uri = $self->uri;
			        my $line = defined $offset ? _line_no(
					$src, $offset
			        ) : undef;

				local *@;
				if(my $h = $self->_handler_for_lang($lang))
				{
				 my $ret = $h->event2sub(
				  $self,$elem,$event,$code,$uri,$line
				 );
				 $@ and $self->warn($@);
				 return $ret;
				}
		});
	}

	$tree->elem_handler(noscript => sub {
		return if $scriptable{$self} && %{$script_handlers{$self}};
		$_[1]->replace_with_content->delete;
		# ~~~ why does this need delete?
	});

	if($self->{Scripter_i}){
	 $tree->elem_handler(img => my $img_cb = sub {
	  return unless defined (my $src = $_[1]->attr('src'));
	  my $res = _fetch_url($self, $src);
	  defined $self->{Scripter_ih} &&
	   $self->{Scripter_ih}($self,$_[1],$res);
	 });
	 $tree->elem_handler(input => sub {
	  return unless $_[1]->type eq 'image';
	  goto &$img_cb;
	 });
	 $tree->default_event_handler(sub {
	  return unless (my $event = shift)->type eq 'DOMAttrModified';
	  return unless (my $target = target $event)->tag=~/^i(mg|nput)\z/;
	  return if $1 eq 'nput' && $target->type ne 'image';
	  &$img_cb(undef, $target);
	 });
	}

	$tree->defaultView(
		$self
	);
	$tree->event_parent($self);
	$tree->set_location_object($self->location);

	$tree->elem_handler(iframe => my $frame_handler = sub {
		my ($doc,$elem) = @_;
		my $subwin = $self->clone->clear_history(1);
		if(defined(my $name = attr $elem 'name')) {
			name $subwin $name
		}
		$elem->contentWindow($subwin);
		$subwin->_set_parent(my $parent = $doc->defaultView);
		length(my $src = $elem->src) or return;
		$subwin->get(new_abs URI $src, $parent->base);
	});
	$tree->elem_handler(frame => $frame_handler);

	# Find out the encoding:
	my $cs = {
		map @$_,
		split_header_words $res->header('Content-Type')
	 }->{charset};
	$cs or $res->can('content_charset')
	       and $cs = (
	        $LWP::UserAgent::VERSION <= 5.834 && local *_,
	        $res->content_charset
	       );
	$tree->charset($cs||'iso-8859-1');

	# banana
	$self->{form} = undef;
	$self->{forms} = $tree->forms;

	$tree->write(defined $cs ? decode $cs, $src : $src);
	$tree->close;

	# This used to trigger the load event on the body  element  (which
	# conformed to HTML 5 at the time [10 June 2008 draft]),  but which
	# was not fully  compatible  with  any  existing  browser.  HTML  5
	# changed to what Firefox and Safari did  (some time before Septem-
	# ber, 2009),  which is what we now have here.  (It still doesn’t
	# quite make sense, as the document is not actually the target.)
	$self->trigger_event('load', target => $tree);

	# banana
	$self->{form} ||= $self->{forms}[0];

	return $self->{res};
}

# Not an override, but used by update_html
sub _handler_for_lang {
 my ($self,$lang) = @_;
 if(defined $lang) {
     while(my($lang_re,$handler) = each
          %{$script_handlers{$self}}) {
        next if $lang_re eq 'default';
        $lang =~ $lang_re and
            # reset iterator:
            keys %{$script_handlers{$self}},
            return $handler;
     }
 }
 return $script_handlers{$self}{default} || ();
}

# Not an override, but used by update_html
sub _line_no {
	my ($src,$offset) = @_;
defined $offset or Carp::cluck;
	return 1 + (() =
		substr($src,0,$offset)
		    =~ /\cm\cj?|[\cj\x{2028}\x{2029}]/g
	);
}

my %link_tags = (
    a      => 'href',
    area   => 'href',
    frame  => 'src',
    iframe => 'src',
    link   => 'href',
    meta   => 'content',
);

# ~~~ This ends up creating a new WSL object every time we come back to the
#     same page. We need a way to make this more efficient. The same goes
#     for images.
sub _extract_links {
	my $self = shift;
	my @links;
	if (my $doc = $self->document) {
		tie @links, WWW'Scripter'Links:: =>
		 HTML::DOM::NodeList::Magic->new(
		    sub { grep {
		        my $tag = tag $_;
			no warnings 'uninitialized';
		        exists $link_tags{$tag}
		            and defined $_->attr($link_tags{$tag})
			    and $tag ne 'meta'
		                || lc $_->attr('http-equiv') eq 'refresh'
		    } $doc->descendants }, $doc
		 );
	}
	# banana
	$self->{links} = \@links;
	$self->{_extracted_links} = 1;

	return;
}

sub _extract_images {
	my $doc = (my $self= shift)->document;
	my $list = HTML::DOM::NodeList::Magic->new(
	    sub { grep tag $_ =~ /^i(?:mg|nput)\z/,
		$doc->descendants },
	    $doc
	);
	tie my @images, WWW'Scripter'Images:: => $list;

	# banana
	$self->{images} = \@images;
	$self->{_extracted_images} = 1;

	return;
}

sub back {
   shift->{page_stack}->go(-1)
}

sub submit {
 if(defined wantarray) {
  # We have to return the response object if a request was made, so we
  # override the default event handler for this particular case.
  my $go_for_it;
  (my $form = $_[0]->current_form)->trigger_event(
   'submit',
    submit_default => sub { ++$go_for_it }
  );
  $go_for_it
   ? ($_[0]->find_target($form->target)||$_[0])
		 ->request($form->make_request)
   : ()
 }
 else {
  shift->current_form->submit
 }
}

sub base {
 my $self = shift;
 my $base = ($self->document || return SUPER'base $self @_)->base;
 if($base eq 'about:blank' and (my $parent = $self->parent) != $self) {
  return $parent->base;
 }
 length $base ? $base : undef;
}

sub click { # This duplicates a lot of code from WWW::Mechanize::click,
            # HTML::DOM::Element::Form::click and HTML::DOM::Ele-
            # ment::Input, but I don’t see a way around it.
 if(defined wantarray) {
  # We have to return the response object if a request was made, so we
  # override the default event handler for this particular case.
  my ($self, $button, $x, $y) = @_;

  # From HTML::DOM::Element::Form (ultimately from HTML::Form):
  # try to find first submit button to activate
  my $input;
  my $form = $self->current_form;
  for ($form->inputs) {
        next unless $_->type =~ /^(?:submit|image)\z/;
        next if $button && $_->name ne $button;
        next if $_->disabled;
        $input = $_;
        last;
  }
  Carp::croak("No clickable input with name $button")
   if $button && !$input;

  # From HTML::DOM::Element::Input:
  # We can’t put this in multiple statements, as the ‘local’ would go out
  # of scope too soon.
  my $continue;
  $input and
   # ~~~ We are breaking encapsulation here.
   local($$input{_HTML_DOM_clicked}) = [$x,$y],
   $input->trigger_event(
    'click',
     click_default => sub {
      $input->trigger_event(
       'DOMActivate', DOMActivate_default => sub { ++$continue }
      )
     }
   ),
   $continue || return;

  my $go_for_it;
  $form->trigger_event(
   'submit',
    submit_default => sub { ++$go_for_it }
  );
  $go_for_it
   ? ($self->find_target($form->target)||$self)
		 ->request($form->make_request)
   : ()
 }
 else {
  # Unlike the submit method, we *can* delegate to the superclass here,
  # as the form’s click method  (which  Mech->click calls)  calls our
  # default_event_handler_for submit, which chooses the right target.
  shift->SUPER::click(@_);
 }
}


# ------------- Window interface ------------- #

# This does not follow the same format as %HTML::DOM::Interface; this cor-
# responds to the format of hashes *within* %H:D:I. The other format does
# not apply here, since we can’t bind the class like other classes. This
# needs to be bound to the global  object  (at  least  in  JavaScript).
our %WindowInterface = (
	%{$HTML::DOM::Interface{AbstractView}},
	%{$HTML::DOM::Interface{EventTarget}},
	alert => VOID|METHOD,
	confirm => BOOL|METHOD,
	prompt => STR|METHOD,
	location => OBJ,
	setTimeout => NUM|METHOD,
	clearTimeout => NUM|METHOD,
	setInterval => NUM|METHOD,
	clearInterval => NUM|METHOD,
	open => OBJ|METHOD,
	blur => VOID|METHOD,
	close => VOID|METHOD,
	focus => VOID|METHOD,
	window => OBJ|READONLY,
	self => OBJ|READONLY,
	navigator => OBJ|READONLY,
	screen => OBJ|READONLY,
	top => OBJ|READONLY,
	frames => OBJ|READONLY,
	length => NUM|READONLY,
	parent => OBJ|READONLY,
	name => STR,
	scroll => VOID|METHOD,
	scrollBy => VOID|METHOD,
	scrollTo => VOID|METHOD,
	history => OBJ|READONLY,
# See the comment preceding the commented-out subs.
#	status => STR,
#	defaultStatus => STR,
);

sub alert {
	my $self = shift;
	&{$$self{Scripter_alert}||sub{print @_,"\n";()}}(@_);
}
sub confirm {
	my $self = shift;
	($$self{Scripter_confirm}||$self->die(
		"There is no default confirm function"
	 ))->(@_)
}
sub prompt {
	my $self = shift;
	($$self{Scripter_prompt}||$self->die(
		"There is no default prompt function"
	 ))->(@_)
}

sub location {
	my $self = shift;
	my $loc = $self->{Scripter_loc} ||= WWW::Scripter::Location->new(
	 $self
	);
	$loc->href(@_) if @_;
	$loc;
}

sub navigator {
	my $self = shift;
	$navi{$self} ||=
		new WWW::Scripter::Navigator:: $self;
}

sub screen {
	my $self = shift;
	$scrn{$self} ||=
		bless \my $foo, WWW::Scripter::Screen::;
}
@WWW::Scripter::Interface{WWW::Scripter::Screen::,'Screen'} = (
 'Screen', {}
);

sub setTimeout {
	my $doc = shift->document;
	my $time = time;
	my ($code, $ms) = (shift,shift);
	$ms /= 1000;
	my $t_o = $timeouts{$doc}||=[];
	$$t_o[my $id = @$t_o] =
		[$ms+$time, $code, @_];
	return $id;
}

sub clearTimeout {
	delete $timeouts{shift->document}[shift];
	return;
}

sub setInterval {
	my $doc = shift->document;
	my $time = time;
	my ($code, $ms) = (shift,shift);
	$ms /= 1000;
	my $t_o = $timers{$doc}||=[];
	$$t_o[my $id = @$t_o] =
		[$ms+$time, $code, @_];
	return $id;
}

sub clearInterval {
	delete $timers{shift->document}[shift];
	return;
}

sub open {
	my($self,$url,$target,undef,$replace) = @_;
	$target
	 = $self->find_target(defined $target ? $target : '_blank');
	if(defined $url and length $url) {
		if(my $base = $self->base) {
			require URI;
			$url = URI->new_abs( $url, $base );
		}
		$target||=$self->top;
		$replace
		 ? $target->location->replace($url)
		 : $target->get($url);
		$target;
	}
	elsif(!$target) {
		# undef or "" in single-window mode: append an ‘unbrowsed’
		# history entry to simulate a new window
		(my $ret = $self->top)->{page_stack}->_add();
		_initial_page($ret);
		$ret;
	}
	else {
		# open("") with existing window; do nothing
		$target
	}
}

sub close {
  if(my $g = $_[0]{Scripter_g}) {
   $g->detach($_[0]);
  }
  else {
   $_[0]->history->go(-1);
  }
 _:
}

sub focus {
 my $g = $_[0]{Scripter_g} or return;
 $g->bring_to_front(shift);
 return;
}

sub blur {
 my $g = $_[0]{Scripter_g} or return;
 my($maybe_self,$next) = $g->windows;
 $next or return;
 $maybe_self == $_[0] or return;
 $g->bring_to_front($next);
 return;
}


sub history { $_[0]{page_stack} }

sub frames {
 my $doc = $_[0]->document;
 my $frames = $frames{$doc||''}         # the ||'' is for non-HTML docu-
  ||= WWW::Scripter'Frames->new( $_[0], $doc );  # ments, which all share
 wantarray ? @$frames : $frames                          # an empty frames
}                                                              # collection

sub window { $_[0] }
*self = *window;
sub length { $frames{$_[0]->document}->length }

sub top {
	my $self = shift;
	$$self{Scripter_t} || do {
		my $parent = $self;
		while() {
			$$parent{Scripter_pa} or
			 weaken( $$self{Scripter_t} = $parent), last;
			$parent = $$parent{Scripter_pa};
		}
		$$self{Scripter_t}
	};
}

sub parent {
	my $self = shift;
	$$self{Scripter_pa} || $self;
}

sub _set_parent { weaken( $_[0]{Scripter_pa} = $_[1] ) }

sub name {
 my $self = shift;
 my $old = $$self{Scripter_nm};
 $$self{Scripter_nm} = $_[0] if @_;
 $old;
}

sub scroll{};  *scrollBy=*scrollTo=*scroll;

# ~~~ This conflicts with Mech’s method.  We probably need to bite the
#     bullet and provide a separate window object for scripts.
#sub status {
# my $old = $status{my $doc = shift->document};
# no warnings 'uninitialized';
# $status{$doc} = "$_[0]" if @_;
# defined $old ? $old : ''
#}
#
# ~~~ This one is commented out because it makes no sense without the
#     previous one.
#sub defaultStatus {
# my $old = $dstatus{my $doc = shift->document};
# no warnings 'uninitialized';
# $dstatus{$doc} = "$_[0]" if @_;
# defined $old ? $old : ''
#}

# ------------- Window-Related Public Methods -------------- #

sub set_alert_function   { ${$_[0]}{Scripter_alert}     = $_[1]; }
sub set_confirm_function { ${$_[0]}{Scripter_confirm} = $_[1]; }
sub set_prompt_function  { ${$_[0]}{Scripter_prompt} = $_[1]; }

sub check_timers {
	my $time = time;
	my $self = shift;
	local *_;
	my $doing_timers_now;
	my $jh;
	for my $timers(\%timeouts, \%timers) {
		my $t_o = $$timers{$self->document}||next;
		for my $id(0..$#$t_o) {
		 next unless $_ = $$t_o[$id];
		 no warnings 'uninitialized';
		 local *@;
		 $$_[0] <= $time and
		  reftype $$_[1] eq 'CODE' || (
		   exists $INC{'overload.pm'}
		   && defined blessed $$_[1]
		   && overload'Method($$_[1],'&{}')
		  )
		   ? eval { $$_[1]->(@$_[2..$#$_]) }
		   : (
		       $jh ||= $self->_handler_for_lang('JavaScript')
		        and $jh->eval($self,$$_[1])
		      ),
		  $@ && $self->warn($@),
		  $doing_timers_now ? $$_[0] = time : delete $$t_o[$id];
		}
	} continue { ++$doing_timers_now }
	$_->check_timers for $self->frames;
	# ~~~ Should we try to trigger the timers in the right order if,
	#     exempli gratia, an iframe’s timer was registered with 200 as
	#     the timeout,  and then the main window with 210 immediately
	#     thereafter?
	return
}

sub count_timers {
 	my $self =  shift;
	my $count;
	for(\%timeouts, \%timers) {
		if(my $t_o = $$_{$self->document}) {
#use DDS; Dump [map $_&&[map "$_", @$_], @$t_o];
			for my $id(0..$#$t_o) {
				next unless $$t_o[$id];
				++$count
			}
		}
	}
	sum $count||(), map $_->count_timers, $self->frames or 0;
}

sub wait_for_timers {
  my($self, %args) = @_;
  my $start_time = time if $args{max_wait};
  my $interval = $args{interval} || .1;
  my $min = $args{min_timers} || 0;
  $self->check_timers;
  while(
       $self->count_timers > $min
   and !$args{max_wait} || time-$start_time < $args{max_wait}
  ) {
   select(undef,undef,undef,$interval);
   $self->check_timers;
  }
 _:
}

sub window_group {
 my $old = (my $self = shift)->{Scripter_g};
 @_ and weaken($self->{Scripter_g} = shift);
 $old
}

sub find_target {
 my $self = shift;
 my $name = shift;
 no warnings 'uninitialized';
 if(!CORE::length $name and my $doc = document $self) {
  if(my $base_elem = $doc->look_down(_tag => 'base', target => qr)(?:\)))){
   $name = $base_elem->attr('target');
  }
 }
 CORE::length $name or return $self;
 if($name =~ /^_[Bb][Ll][Aa][Nn][Kk]\z/) {
  if(my $g = $$self{Scripter_g}) {
   attach $g my $neww = $self->clone->clear_history(1);
   return $neww;
  }
  return undef;
 }
 $name =~ /^_[Ss][Ee][Ll][Ff]\z/ and return $self;
 $name =~ /^_[Pp][Aa][Rr][Ee][Nn][Tt]\z/ and return $self->parent;
 $name =~ /^_[Tt][Oo][Pp]\z/ and return $self->top;

 # Search subframes, and then ancestors (including their subframes), in
 # breadth-first order
 my $current_ancestor = $self;
 my $prev_ancestor;
 while() {
  $current_ancestor->name eq $name and return $current_ancestor;
  my $next_level = [
   $prev_ancestor
    ? grep $_ != $prev_ancestor, $current_ancestor->frames
    : $current_ancestor->frames
  ];
  while($next_level) {
   my $tmp = $next_level; $next_level = undef;
   for(@$tmp) {
    if($_->name eq $name) { return $_ }
    push @$next_level, $_->frames;
   }
  }
  $prev_ancestor = $current_ancestor;
  $current_ancestor = $current_ancestor->parent;
  last if $prev_ancestor == $current_ancestor;
 }

 # If we reach this point, there are no frames named $name. Return undef
 # in single-window mode, or look for a window.
 my $g = $$self{Scripter_g} or return undef;
 my $named = ($$self{Scripter_n}||=&fieldhash({}))->{$self->response}||={};
 # The extra ${} is there since a reference in a tied hash element cannot
 # be weakened directly, as the element is just temporary each time.
 $$named{$name} && ${$$named{$name}}->window_group
  ? ${$$named{$name}}
  : do {
     attach $g my $neww = $self->clone->clear_history(1);
     weaken(${$$named{$name}} = $neww);
     $neww
    }
}

# ------------- EventTarget interface ------------- #

*event_listeners_enabled = *scripts_enabled; 

# What we are doing here is delegating event handler/listener storage to
# a response object  (and  fooling  EventTarget  into  thinking  that  the
# response object is an EventTarget). This is so that each page has its own
# set of event handlers,  but we still use the WWW::Scripter  object as the
# event target.
for my $meth (qw b addEventListener removeEventListener event_handler
                   get_event_listeners b) {
 no strict 'refs';
 my $full_meth= "HTML::DOM::EventTarget::$meth";
 *$meth = sub {
   shift->response->$full_meth(@_);
  }
}


# ------------- Image Hooks -------------- #

sub fetch_images {
 my $old = (my $self = shift)->{Scripter_i};
 @_ and $self->{Scripter_i} = shift;
 $old
}

sub image_handler {
 my $old = (my $self = shift)->{Scripter_ih};
 @_ and $self->{Scripter_ih} = shift;
 $old
}

# ------------- Scripting hooks and what-not ------------- #

sub eval {
 my ($self,$code) = (shift,shift);
 my $h = $self->_handler_for_lang(my $lang = shift);
 my $ret = (
  $h or $self->die(
   defined $lang ? "No scripting handlers have been registered for $lang"
                 : "No scripting handlers have been registered"
  )
 )->eval($self,$code);
 $@ and $self->warn($@);
 $ret;
}

sub use_plugin {
    my ($self, $plugin, @opts) = (shift, shift, @_);
    my $plugins = $self->{plugins} ||= {};
    $plugin = _plugin2module($plugin);
    return $plugins->{$plugin} if $self->{cloning};
    if(exists $plugins->{$plugin}) {
        $plugins->{$plugin}->options(@opts) if @opts;
    }
    else {
        (my $plugin_file = $plugin) =~ s-::-/-g;
        require "$plugin_file.pm";
        $plugins->{$plugin} = $plugin->init($self, \@opts);
        $plugins->{$plugin}->options(@opts) if @opts;
    }
    $plugins->{$plugin};
}

sub plugin {
    my $self = shift;
    my $plugin = _plugin2module(shift);
    return exists $self->{plugins}{$plugin}
        ? $self->{plugins}{$plugin} || 1 : 0;
}

sub _plugin2module { # This is NOT a method
    my $name = shift;
    return $name if $name =~ /::/;
    $name =~ s/-/::/g;
    return __PACKAGE__."::Plugin::$name";
}

sub _clone_plugins {
    my $self = shift;
    return unless $self->{plugins};
    my $plugins = $self->{plugins} = { %{$self->{plugins}} };
    while ( my($pn,$po) = each %$plugins ) {
            # plugin name, plugin object
        next unless $po && defined blessed $po && $po->can('clone');
        $plugins->{$pn} = $po->clone($self);
    }
}

sub dom_enabled {
	my $old = (my $self = shift)->{Scripter_dumb};
	defined $old or $old = 1; # default
	if(@_) {{
	  $$self{Scripter_dumb} = !!$_[0]; # We don’t want undef
	}}                                 # resetting it.
	$old
}

sub scripts_enabled {
	my $old = $scriptable{my $self = shift};
	defined $old or $old = 1; # default
	if(@_) {{
	  $scriptable{$self} = !!$_[0]; # We don’t want undef resetting it.
	  ($self->document ||last) ->event_listeners_enabled(shift) ;
	}}
	$old
}
# used by HTML::DOM::EventTarget:
*event_listeners_enabled = *scripts_enabled; 

sub script_handler {
	my($self,$key) = (shift,shift);
	my $old = $script_handlers{$self}{$key};
	@_ and $script_handlers{$self}{$key} = shift;
	$old
}

sub class_info {
	my $self = shift;
	@_ and push @{ $class_info{$self} }, shift;
	@{ $class_info{$self} } if defined wantarray;
}

# ------------- Miss Elaine E. S. ------------- #

# This function is exported upon request.
sub abort {
    no warnings 'exiting';
    last Scripter_ABORT;
}

sub forward {
    my $self = shift;
    $self->{page_stack}->go(1);
}

sub clear_history {
    my $self = shift;
    $$self{'page_stack'}->_clear(@_);
    if (shift) {
        $self->_reset_page;

        # list of keys taken from _update_page
        delete $self->{$_} for qw[ req redirected_url res status base ct
            uri last_uri content ];
        _initial_page($self);
    }
    return $self;
}

sub max_docs {
 my $self= shift;
 defined wantarray and my $old = $self->stack_depth+1;
 $self->stack_depth(shift()-1) if @_;
 $old;
}

sub max_history {
 my $old = (my $self = shift)->{Scripter_max_hist};
 @_ and $self->{Scripter_max_hist} = shift;
 $old
}

# ------------- History object ------------- #

package WWW::Scripter::History;

<<'mldistwatch' if 0;
use WWW::Scripter; $VERSION = $WWW'Scripter'VERSION;
mldistwatch
our $VERSION = $WWW'Scripter'VERSION;

BEGIN { *fieldhashes = *WWW::Scripter::fieldhashes }
use HTML::DOM::Interface qw 'NUM STR READONLY METHOD VOID';
use Scalar::Util 'weaken';

=begin comment

History notes

A history object is a blessed array ref. That array ref holds the browser
history entries. Each entry is itself an array ref containing:

0 - request object
1 - response object
2 - URL
3 - state info
4 - title

The length of the array tells us whether it is a state-info entry. The URL
is used both for fragments and for state objects. The second element will
be blank if it has been erased because of max_docs.

The history object has a pointer to the ‘current’ history item
($index{$self}).

Document objects are referenced by response: $document{$response}. The
window’s ‘document’ method is inherited from HTML::DOM::View, and we set it
whenever history is browsed, retrieving it from %document.

The ‘unbrowsed’ state that used to be mentioned in HTML 5 (before it got
really convoluted) is represented by an empty array. An empty array can
exist alongside other entries, as we add one when we simulate a
new window in single-window mode.

Response objects are also listed in the array ref stored in $res{$self} in
the order in which they were accessed. Subroutines that add to this array
then call  _clean($self),  which then eliminates duplicate entries  and
deletes from the history object itself as many of the oldest response
objects as are necessary to satisfy max_docs.

=end comment

=cut

$$_{~~__PACKAGE__} = 'History',
$$_{History} = {
	length => NUM|READONLY,
	index => NUM|READONLY,
	userAgent => STR|READONLY,
	go => METHOD|VOID,
	back => METHOD|VOID,
	forward => METHOD|VOID,
	pushState => METHOD|VOID,
}
for \%WWW::Scripter::Interface;

fieldhashes \my ( %w, %index, %res );

sub new {
	my ($pack,$mech) = @_;
	my $self = bless [[]], $pack;
	weaken(${$w{$self}} = $mech);
	$index{$self} = 0;
	$res{$self} = [];
	$self
}

sub _add {
 my $self = shift;
 if(defined $$self[-1][0]) { # if there is no ‘undef’ entry
  splice @$self, ++$index{$self};
  push @$self, \@_;
  $_[1] and push(@{$res{$self}}, $_[1]), _clean($self,1);
 }
 else {
  $$self[-1] = \@_;
  push @{$res{$self}}, $_[1] if $_[1];
 }
}

# Called when browsing to a stale history entry and also by
# location->replace
sub _replace {
 my $self = shift;
 if(defined $$self[-1][0]) { # if browsing has occurred
  $$self[$index{$self}] = \@_;
  $_[1] and push(@{$res{$self}}, $_[1]), _clean($self);
 }
 else {
  $$self[-1] = \@_;
  push @{$res{$self}}, $_[1] if $_[1];
 }
}

sub _delete_res {
 delete $_[0][$index{$_[0]}][1];
}

sub _clear { # called by Scripter->clear_history
	my $self = shift;
	@$self = shift() ? undef : $$self[$index{$self}];
	$index{$self} = 0;
}

sub length {
    scalar @{+shift}
}

sub index { # ~~~ We can probably make this modifiable later.
 $index{+shift}
}

sub go {
 my $self = shift;
 if(0==$_[0]) {
  ${$w{$self}}->reload;
 }
 else {
  my $new_pos = $index{$self}+shift;
  $new_pos < 0 || $new_pos > $#$self and return;
  $index{$self} = $new_pos;

  # ~~~ trigger popstate

  # If there is a response object, we just reset the page from that. If
  # there isn’t then this is a stale entry and we need to
  # re-fetch the page.
  my $entry = $$self[$new_pos];
  if(defined $$entry[1]) { # response
   ${$w{$self}}->_update_page(@$entry)
  }
  else {
   local(my $w = ${$w{$self}})->{Scripter_replace} = 1;
   $w->request($$entry[0]);
  }
 }
 return;
}

sub back { shift->go(-1) }
sub forward { shift->go(1) }

sub pushState {
 my $self = shift;

 my $index = $index{$self}++;
 my($req,$res) = @{$$self[$index]}[0,1];

 # count future entries that share the same doc
 my $to_delete;
 for($index+1..$#$self) {
  ($$self[$_][1]||0) == $res ? ++$to_delete : last;
 }

 # replace those future entries with the new item
 splice @$self, $index+1, $to_delete||0, [ $req, $res, $_[2], @_ ];

 _clean($self);

 return;
}

sub _clean {
 my($self, $check_max_hist) = @_;
 if($check_max_hist) {
  my $max = (my $w = ${$w{$self}})->{Scripter_max_hist};
  if($max && @$self > $max) {
   my $diff = @$self-$max;
   $index{$self} -= $diff;
   splice @$self, 0, $diff;
  }
 }
 my $max = ${$w{$self}}->stack_depth + 1;
 my $res = $res{$self};
 my %res;
 for(@$self) {
  defined $$_[1] and $res{0+$$_[1]}++
 }
 if($max) { # ~~~ It may be more efficient if, instead of searching for
  my @res;  #     duplicates here, we scan for the ones we know we’ve added
  my %seen; #     in _add and _replace.
  for(reverse @$res) {
   my $refaddr = 0+$_;
   unshift @res, $_ if exists $res{$refaddr} && !$seen{$refaddr}++;
  }
  @$res = @res, return unless @res > $max;
  my $diff = @res-$max;
  my %to_delete;
  @to_delete{map 0+$_, splice @res, 0,$diff}=();
  @$res = @res;
  for(@$self) {
   next unless defined $$_[1];
   delete $$_[1] if exists $to_delete{0+$$_[1]};
  }
 }
 else {
  @$res = grep exists $res{refaddr $_}, @$res;
 }
}

sub _uri {
 my $self = shift;
 $$self[$index{$self}][2] || ${$w{$self}}->uri;
}

# ~~~

# ------------- Location object ------------- #

package WWW'Scripter'Location;

use HTML::DOM::Interface qw'STR METHOD VOID';
use Scalar::Util 'weaken';

use overload fallback => 1, '""' => sub{${+shift}->history->_uri};

$$_{~~__PACKAGE__} = 'Location',
$$_{Location} = {
	assign => VOID|METHOD,
	hash => STR,
	host => STR,
	hostname => STR,
	href => STR,
	pathname => STR,
	port => STR,
	protocol => STR,
	search => STR,
	reload => VOID|METHOD,
	replace => VOID|METHOD,
}
for \%WWW::Scripter::Interface;

sub new { # usage: new .....::Location $mech
	my $class = shift;
	weaken (my $mech = shift);
	my $self = bless \$mech, $class;
	$self;
}

sub hash {
	my $loc = shift;
	my $old = (my $uri = $$loc->history->_uri)->fragment;
	$old = "#$old" if defined $old;
	if (@_){
		shift() =~ /#?(.*)/s;
		(my $uri_copy = $uri->clone)->fragment($1);
		$uri_copy->eq($uri) or $$loc->get($uri_copy);
	}
	$old||''
}

sub host {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_) {
		(my $uri = $uri->clone)->port("");
		$uri->host_port(shift);
		$$loc->get($uri);
	}
	defined wantarray ? $uri->host_port : ()
}

sub hostname {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_) {
		(my $uri = $uri->clone)->host(shift);
		$$loc->get($uri);
	}
	defined wantarray ? $uri->host : ()
}

sub href {
	my $loc = shift;
	my $old = $$loc->history->_uri->as_string if defined wantarray;
	if (@_) {
		$$loc->get(shift);
	}
	$old;
}

sub assign { ${$_[0]}->get($_[1]); () }

sub pathname {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_) {
		(my $uri = $uri->clone)->path(shift);
		$$loc->get($uri);
	}
	defined wantarray ? $uri->path : ()
}

sub port {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_) {
		(my $uri = $uri->clone)->port(shift);
		$$loc->get($uri);
	}
	defined wantarray ? $uri->port : ()
}

sub protocol {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_) {
		shift() =~ /(.*):?/s;
		(my $uri = $uri->clone)->scheme($1);
		$$loc->get($uri);
	}
	defined wantarray ? $uri->scheme . ':' : ()
}

sub search {
	my $loc = shift;
	my $uri = $$loc->history->_uri;
	if (@_){
		shift() =~ /(\??)(.*)/s;
		(
		 my $uri_copy = $uri->clone
		)->query(
			$1||length$2 ? "$2" : undef
		);
		$$loc->get($uri_copy);
	}
	return unless defined wantarray;
	my $q = $uri->query;
	defined $q ? "?$q" : "";
}


# ~~~ Safari doesn't support forceGet. Do I need to?
sub reload  { # args (forceGet) 
	${+shift}->reload
}
sub replace { # args (URL)
	my $mech = ${+shift};
	local $$mech{Scripter_replace } = 1;
	$mech->get(shift);
}


# ------------- Navigator object ------------- #

package WWW::Scripter::Navigator;

use HTML::DOM::Interface qw'STR READONLY METHOD BOOL';
use Scalar::Util 'weaken';

$$_{~~__PACKAGE__} = 'Navigator',
$$_{Navigator} = {
	appName => STR|READONLY,
	appCodeName => STR|READONLY,
	appVersion => STR|READONLY,
	userAgent => STR|READONLY,
	javaEnabled => METHOD|BOOL,
	platform     => STR|READONLY,
	taintEnabled => METHOD|BOOL,
	cookieEnabled => BOOL|READONLY,
}
for \%WWW::Scripter::Interface;

use constant 1.03 our $_const = {
	mech => 0,
	name => 1,
	vers => 2,
	cnam => 3,
	plat => 4,
};
{ no strict; delete @{__PACKAGE__."::"}{_const => keys %$_const} }

sub new {
	weaken((my $self = bless[],pop)->[mech] = pop);
	$self;
}

sub appName {
	my $self = shift;
	my $old = $self->[name];
	defined $old or $old = ref $self->[mech];
	@_ and $self->[name] = shift;
	return $old;
}

sub appCodeName {
	my $self = shift;
	my $old = $self->[cnam];
	defined $old or $old = ref $self->[mech];
	@_ and $self->[cnam] = shift;
	return $old;
}

sub appVersion {
	my $self = shift;
	my $old = $self->[vers];
	if(!defined $old and defined wantarray) {
		$old = $self->userAgent;
		$old =~ /(\d.*)/s
		? $old = $1
		: $old = ref($self->[mech])->VERSION;
	}
	@_ and $self->[vers] = shift;
	return $old;
}

sub userAgent {
	shift->[mech]->agent;
}

sub platform {
	my $self = shift;
	my $old = $self->[plat];
	if(!defined $old and defined wantarray) {
		my $ua = $self->[mech]->agent;
		no warnings 'uninitialized';
		$old
		 = $ua =~ /\bWin(?:dows|32)?\b/ ? 'Win32'
		 : $ua =~ /\bMac(?:intosh)\b/   ?  $ua =~ /\bIntel\b/
		                                    ? 'MacIntel' : 'MacPPC'
		 : $ua =~ /\b(FreeBSD(?: i386)?|Linux)\b/
		                                ?  $1
		 : $^O eq 'MSWin32'             ? 'Win32'
		 : $^O eq 'MacOS'               ? 'MacPPC'
		 : $^O eq 'freebsd'             ? 'FreeBSD'
		 : $^O eq 'linux'               ? 'Linux'
		 : $^O ne 'darwin'              ?  $^O
		 : pack "s", 28526, eq 'on' ? 'MacPPC' : 'MacIntel';
	}
	@_ and $self->[plat] = shift;
	return $old;
}

sub javaEnabled{}
*taintEnabled=*javaEnabled;

sub cookieEnabled { defined $_[0][mech]->cookie_jar }

# ------------- about: protocol ------------- #

package WWW'Scripter'_about_protocol;

# ~~~ This method may be a bad idea if someone else wants to implement
#     other aspects of the about: protocol. Maybe we should use an LWP
#     handler. (Then we would, of course, require a later LWP.)

<<'mldistwatch' if 0;
use WWW::Scripter; $VERSION = $WWW'Scripter'VERSION;
mldistwatch
our $VERSION = $WWW'Scripter'VERSION;

use LWP::Protocol;

our @ISA = LWP::Protocol::;

LWP::Protocol'implementor about => __PACKAGE__;

sub request { # based on the one in LWP::Protocol::file
	my($self, $request, $proxy, $arg) = @_;

	if(defined $proxy) {
		return new HTTP::Response 400,,
			'The about: protocol does not work with proxies';
	}

	my $url=  $request->url;
	my $scheme = $url->scheme;	

	if ($scheme ne 'about') {
		return new HTTP::Response 500,
		    "WWW::Scripter::_about_protocol called for $scheme";
	}

	return new HTTP::Response 404,
		"Nothing exists at $url" unless $url eq 'about:blank';

	my $response = new HTTP::Response 200, 'OK', [
		Content_Length=>0,
		Content_Type  =>'text/html',
	];

	$self->collect($arg, $response, sub {\''});
}

# ------------- Link and image lists for Mech ------------- #

package WWW::Scripter::Links;

BEGIN { eval "require ".WWW'Scripter'Mech."::Link" or die $@ }

sub TIEARRAY {
	bless \(my $links = pop), shift;
}

sub FETCH     {
	my $link = ${$_[0]}->[$_[1]];
	my $mech_link = bless [], WWW'Scripter'Mech."::Link";
	tie @$mech_link, WWW'Scripter'Link::, $link;
	$dom_obj{$mech_link} = $link;
	$mech_link;
}
sub FETCHSIZE { scalar @${$_[0]} }
sub EXISTS    { exists ${$_[0]}->links->[$_[1]] }

package WWW::Scripter::Link;

sub TIEARRAY { bless \(my $x = $_[1]) }
sub FETCH {
 my $self = shift;
 for(shift) {
  return
   $_ == 0 ? $$self->tag eq 'meta'         # url
              ? $$self->attr('content') =~ /^\d+\s*;\s*url\s*=\s*(\S+)/i
                 ? do { my $url = $1;
                        $url =~ s/^"(.+)"$/$1/ or $url =~ s/^'(.+)'$/$1/;
                        $url }
                 : undef
              : $$self->attr($link_tags{$$self->tag}) :
   $_ == 1 ? $$self->tag eq 'a' ? $$self->as_text : undef : # text
   $_ == 2 ? $$self->attr('name')        : # name
   $_ == 3 ? $$self->tag                 : # tag
   $_ == 4 ? $$self->ownerDocument->base : # base
   $_ == 5 ? {$$self->all_external_attr} : # attrs
             undef
 }
}
sub FETCHSIZE { 6 }

package WWW::Scripter::Images;

BEGIN { eval "require ".WWW'Scripter'Mech."::Image" or die $@ }

sub TIEARRAY {
	bless \(my $links = pop), shift;
}

sub FETCH     {
	my $img = ${$_[0]}->[$_[1]];
	my $mech_img = new WWW'Scripter'Image:: $img;
	$dom_obj{$mech_img} = $img;
	$mech_img;
}
sub FETCHSIZE { scalar @${$_[0]} }
sub EXISTS    { exists ${$_[0]}->links->[$_[1]] }

package WWW::Scripter::Image;
our @ISA = WWW::Scripter::Mech."::Image";
sub new { bless \(my $frin = pop) }
sub url { ${$_[0]}->attr('src')       }
sub base { ${$_[0]}-ownerDocument->base }
sub name { ${$_[0]}->attr('name')        }
sub tag   { ${$_[0]}->tag                }
sub height { ${$_[0]}->attr('height')    }
sub width  { ${$_[0]}->attr('width')     }
sub alt    { ${$_[0]}->attr('alt')       }


# ------------- Frames list ------------- #

package WWW::Scripter::Frames;

# ~~~ This is horribly inefficient and clunky. It probably needs to be
#     programmed in full here, or at least the ‘Collection’ part (a tiny
#     bit of copy&paste).

use HTML::DOM::Collection;
use HTML::DOM::NodeList::Magic;
our @ISA = "HTML::DOM::Collection";

{
	WWW::Scripter'fieldhash my %w;
	my @empty_array;
	
	sub new {
		; my($pack,$window,$doc) = @_
		; my $ret = $pack->SUPER'new(
		   $doc
		    ? HTML::DOM::NodeList::Magic->new(
		       sub { $doc->look_down(_tag => qr/^i?frame\z/) },
		       $doc
		      )
		    : HTML'DOM'NodeList->new(\@empty_array)
		  )
		; Scalar'Util'weaken($_) for $doc, $window;
		; $w{$ret} = \$window;
		; $ret
	}
	
	sub window { ${$w{+shift}||return undef} }
	}

use overload fallback => 1,'@{}' => sub {
	[map $_->contentWindow, @{shift->${\'SUPER::(@{}'}}]
};

sub FETCH { (shift->SUPER::FETCH(@_)||return)->contentWindow }


!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!
