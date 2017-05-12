package WWW::Spyder;

use strict;
use warnings;

use HTML::Parser 3;

use LWP::UserAgent;
use HTTP::Cookies;
use URI::URL;
use HTML::Entities;

use Digest::MD5 "md5_base64"; # For making seen content key/index.

use Carp;
our $VERSION = '0.24';
our $VERBOSITY ||= 0;

#  Methods
#--------------------------
{ # make it all a bit more private
    my %_methods = (# these are methods & roots of our attribute names
                    UA           => undef,
                    bell         => undef,
                    html_parser  => undef,
                    sleep_base   => undef,
                    cookie_file  => undef,
                    _exit_epoch  => undef,
                    _term_count  => undef,
                    );
#  Those may all get hardcoded eventually, but they're handy for now.
#--------------------------
sub new {
    my ( $caller ) = shift;
    my $class = ref($caller) || $caller;
    my $self = bless {}, $class;

    my ( $seed, %arg );
    if ( @_ == 1 ) {
        ( $seed ) = @_;
    }
    %arg = ( broken_links        => [],
             exit_on             => undef,
             image_checking      => 0,
             report_broken_links => 0,
             seed                => undef,
             sleep               => undef,
             sleep_base          => 5,
             UA                  => undef
             );
    %arg = ( %arg, @_ ) unless @_ % 2;

    # Set our UA object if it was passed on to our constructor.
    $self->{UA} = $arg{UA} if $arg{UA};

    # Turn on image checking if requested.  img src tags will be checked if
    # image_checking is set to 1 in the constructor.
    $self->{image_checking} = $arg{image_checking} if $arg{image_checking};

    # Turn on broken link checking if requested.  Broken link URIs can be
    # obtained via get_broken_links().
    $self->{report_broken_links} = $arg{report_broken_links}
        if $arg{report_broken_links};

# Install all our methods, either set once then get only or push/shift
# array refs.
    for my $method ( %_methods ) {
        no strict "refs";
        no warnings;
        my $attribute = '_' . $method;

        if ( ref $_methods{$method} eq 'ARRAY' ) {
            *{"$class::$method"} = sub {
                my($self,@args) = @_;
                return shift(@{$self->{$attribute}}) unless @args;
                push(@{$self->{$attribute}}, @args);
            };
        } else {
            *{"$class::$method"} = sub {
                my($self,$arg) = @_;
                carp "You cannot reset $method!"
                    if $arg and exists $self->{$attribute};
                return $self->{$attribute}   #get if already set
                if exists $self->{$attribute};
                $self->{$attribute} = $arg;  #only set one time!
            };
        }
    }

    $seed ||= $arg{seed};
    $self->seed($seed) if $seed;
    $self->sleep_base($arg{sleep_base});
    $self->_install_exit_check(\%arg) unless $self->can('_exit_check');
    $self->_install_html_parser;
    $self->_install_web_agent;

    return $self;
}
#--------------------------
sub terms {
    my ($self,@terms) = @_;
    if ( @terms and not exists $self->{_terms} ) {
        $self->_term_count(scalar @terms);  # makes this set once op
        my %terms;
        $terms{$_} = qr/$_/ for @terms;
        $self->{_terms} = \%terms;
    } else {
        return $self->{_terms}
    }
}
#--------------------------
sub show_attributes {
    my ($self) = @_;
    return map {/^_(.+)$/} keys %{$self};
}
#--------------------------
sub slept {
    my ($self, $time) = @_;
    $self->{_Slept} += $time if $time;
    return $self->{_Slept} unless $time;
}
#--------------------------
sub seed {
    my ($self, $url) = @_;
    $url or croak "Must provide URL to seed().";
    croak "You have passed something besides a plain URL to seed()!"
        if ref $url;
    $self->_stack_urls($url);
    return 1; # to the top of the stacks
}

#--------------------------
sub get_broken_links {
    my $self = shift;

    return $self->{broken_links};
}

#--------------------------
sub crawl {
    my $self      = shift;
    my $opts     = shift || undef;
    my $excludes = [];

    # Exclude list option.
    if ( ref($opts->{exclude}) eq 'ARRAY' ) {
        $excludes = $opts->{exclude};
    }

    while ('I have pages to get...') {

        $self->_exit_check and return;

        my $skip_url = 0;
        my $enQ      = undef;

        # Report a page with a 404 error in the title if report_broken_links is
        # enabled.  Also keep processing if we're looking for img src tags.
        if ($self->{report_broken_links} || $self->{image_checking}) {
            $enQ = $self->_choose_courteously ||
                $self->_just_choose;
        } else {
            $enQ = $self->_choose_courteously ||
                $self->_just_choose ||
                    return;
        }

        my $url = $enQ->url;

        # Skip this URL if it's in our excluded list.
        for (@$excludes) { $skip_url = 1 if $url =~ m/$_/; }
        next if $skip_url;

        $self->url($url);
        $self->_current_enQ($enQ);

        print "GET'ing: $url\n" if $VERBOSITY;

        my $response = $self->UA->request   # no redirects &c is simple_
            ( HTTP::Request->new( GET => "$url" ) );

        print STDERR "\a" if $self->bell;

        $response or
            carp "$url failed GET!" and next;

        push @{$self->{_courtesy_Queue}}, $enQ->domain;
        shift @{$self->{_courtesy_Queue}}
        if $self->{_courtesy_Queue}
        and @{$self->{_courtesy_Queue}} > 100;

        my $head = $response->headers_as_string;
        $head or
            carp "$url has no HEAD!" and
                next; # no headless webpages

        length($head) > 1_024 and $head = substr($head,0,1_024);

        print $head, "\n" if $VERBOSITY > 2;

        my $base;
        eval { $base = $response->base };
        $base or
            carp "$url has no discernible BASE!" and
                next; # no baseless webpages

# WE SHOULD also look for <HTML> because some servers that we might want
# to look at don't properly report the content-type

# start over unless this is something we can read
        my $title       = '';
        my $description = '';
        my $is_image    = 0;

        # Make an exception for images.
        if ($self->{image_checking}) {
            if ($head =~ /Content\-Type:\s*image/i) {
	        my ($img_size) = $head =~ /Content\-Length:\s*(\d+)/i;

                if ($img_size <= 0) {
                    $title = $description = '404 Not Found';
                    next;
                } else {
                    $is_image = 1;
                }
            }
        } else {
	    lc($head) =~ /content-type:\s?(?:text|html)/ or
	        carp "$url doesn't look like TEXT or HTML!" and
		    next; # no weird media, movies, flash, etc
        }

	( $title ) = $head =~ m,[Tt]itle:\s*(.+)\n,
            unless $title;

        ( $description ) = $head =~
            /[^:]*?DESCRIPTION:\s*((?:[^\n]+(?:\n )?)+)/i
                unless $description;

        # Add this link to our dead links list if the title matches
        # a standard "404 Not Found" error.
        if ($title && $self->{report_broken_links}) {
            push(@{ $self->{broken_links} }, $url)
                if $title =~ /^\s*404\s+Not\s+Found\s*$/;
        }

        $description = $self->_snip($description) if $description;

        my $page = $response->content or
            carp "Failed to fetch $url." and
                next; # no empty pages, start over with next url

        $self->{_current_Bytes} = length($page);
        $self->spyder_data($self->{_current_Bytes});

# we are going to use a digest to prevent parsing the identical
# content received via a different url
        my $digest = md5_base64($page); # unique microtag of the page
# so if we've seen it before, start over with the next URL
        $self->{_page_Memory}{$digest}++ and
            carp "Seen this page's content before: $url"
                and next;

        $self->{_page_content} = $page;
        print "PARSING: $url\n" if $VERBOSITY > 1;
        $self->{_spydered}{$url}++;
        $self->html_parser->parse($page);
        $self->html_parser->eof;

        $self->{_adjustment} = $self->_parse_for_terms if $self->terms;

# make links absolute and fix bad spacing in link names, then turn
# them into an Enqueue object
        for my $pair ( @{$self->{_enqueue_Objects}} ) {
            my $url;
            eval {
                $url = URI::URL::url($pair->[0], $base)->abs;
            };
            my $name =  _snip($pair->[1]);
            my $item = WWW::Spyder::Enqueue->new("$url",$name);
            $pair = $item;
        }
# put links into the queue(s)
       $self->_stack_urls() if $self->_links;

# clean up text a bit. should this be here...?
        if ( $self->{_text} and ${$self->{_text}} ) {
            ${$self->{_text}} =~ s/(?:\s*[\r\n]){3,}/\n\n/g;
        }

# in the future Page object should be installed like parsers as a
# reusable container
#    return
  my $Page =
      WWW::Spyder::Page->new(
                             title  => $title,
                             text   => $self->{_text},
                             raw    => \$page,
                             url    => $enQ->url,
                             domain => $enQ->domain,
                             link_name   => undef,
                             link        => undef,
                             description => $description || '',
                             pages_enQs  => $self->_enqueue,
                             );
        $self->_reset;       #<<--clear out things that might remain
        return $Page;
    }
}
#--------------------------
sub _stack_urls {  # should eventually be broken into stack and sift?

# dual purpose, w/ terms it filters as long as there are no urls
# passed, otherwise it's setting them to the top of the queues
    my ($self, @urls) = @_;

    print "Stacking " . join(', ', @urls) . "\n"
        if @urls and $VERBOSITY > 5;

    if ( $self->terms and not @urls ) {
        no warnings;
        my @Qs = $self->_queues;
        for my $enQ ( @{$self->_enqueue} ) {
            my ( $url, $name ) = ( $enQ->url, $enQ->name );

            next if $self->_seen($url);

            my $match = 0;
            while ( my ($term,$rx) = each %{$self->terms} ) {
                $match++ for $name =~ /$rx/g;
            }
            my $baseQ = 10;
            my $adjustment = $self->{_adjustment};
            $baseQ -= $adjustment; # 4 to 0

            push @{$self->{$baseQ}}, $enQ
                and next unless $match;

            if ( $VERBOSITY > 1 ) {
                print "NAME: $name\n";
                printf "   RATIO -->> %d\n", $match;
            }
            my $queue_index = sprintf "%d",
                $self->_term_count / $match;

            $queue_index -= $adjustment;
            $queue_index = 4 if $queue_index > 4;
            $queue_index = 0 if $queue_index < 0;
            my $queue = $Qs[$queue_index];
            if ($VERBOSITY > 2) {
                print "Q:$queue [$queue_index] match: $match terms:",
                $self->_term_count, "  Adjust: $adjustment\n\n";
            }
            push @{$self->{$queue}}, $enQ;
        }
    } elsif ( @urls > 0 ) {
        for my $url ( @urls ) {
            next if $self->_seen($url);
            my $queue = $self->_queues;
            carp "Placing $url in '$queue'\n" if $VERBOSITY > 2;

# unshift because seeding is priority
            unshift @{$self->{$queue}},
               WWW::Spyder::Enqueue->new($url,undef);
        }
    } else {
       for my $enQ ( @{$self->_enqueue} ) {
            my ( $url, $name ) = ( $enQ->url, $enQ->name );
            next if $self->_seen($url);
            my $queue = $self->_queues;
            push @{$self->{$queue}}, $enQ;
        }
   }
}
#--------------------------
sub queue_count {
    my ($self) = @_;
    my $count = 0;
    for my $Q ( $self->_queues ) {
        next unless ref($self->{$Q}) eq 'ARRAY';
        $count += scalar @{$self->{$Q}};
    }
    return $count;
}
#--------------------------
sub spyder_time {
    my ($self,$raw) = @_;

    my $time = time() - $^T;
    return $time if $raw;

    my $day  = int( $time / 86400 );
    my $hour = int( $time / 3600 ) % 24;
    my $min  = int( $time / 60 ) % 60;
    my $sec  = $time % 60;

# also collect slept time!
    return sprintf "%d day%s %02d:%02d:%02d",
    $day, $day == 1?'':'s', $hour, $min, $sec;
}
#--------------------------
sub spyder_data {
    my ($self, $bytes) = @_;
    $self->{_bytes_GOT} += $bytes and return $bytes if $bytes;

    return 0 unless $self->{_bytes_GOT};

    my $for_commas = int($self->{_bytes_GOT} / 1_024);

    for ( $for_commas ) {
        1 while s/(\d)(\d\d\d)(?!\d)/$1,$2/;
    }
    return $for_commas;
}
#--------------------------
sub spydered {
    my ($self) = @_;
    return wantarray ?
        keys %{ $self->{_spydered} } :
            scalar keys %{ $self->{_spydered} };
}
#--------------------------
#sub exclude {  # what about FILES TYPES!?
#    return undef; # not working yet!
#    my ($self,$thing) = @_;
#    if ( $thing =~ m<^[^:]{3,5}://> )
#    {
#        return $self->{_Xklood}{_domain}{$thing}++;
#    }
#    elsif ( $thing )
#    {
#        return $self->{_Xklood}{_name}{$thing}++;
#    }
#}
#--------------------------
#sub excluded_domains {
#    return undef; # not working yet!
#    my ($self) = @_;
#    return wantarray ?
#        keys %{$self->{_Xklood}{_domain}} :
#            [ keys %{$self->{_Xklood}{_domain}} ];
#}
#--------------------------
#sub excluded_names {
#    return undef; # not working yet!
#    my ($self) = @_;
#    return wantarray ?
#        keys %{$self->{_Xklood}{_name}} :
#            [ keys %{$self->{_Xklood}{_name}} ];
#}
#--------------------------
sub go_to_seed {
    my ( $self, $engine, $query ) = @_;
    carp "go_to_seed() is not functional yet!\n";
    return;  # NOT FUNCTIONAL
    my $seed = WWW::Spyder::Seed::get_seed($engine, $query);
    $self->seed($seed);
}
#--------------------------
sub verbosity {
    my ( $self, $verbosity ) = @_;
    carp "Not setting verbosity! Must be integer b/t 1 & 6!\n"
        and return
            unless $verbosity;
    $VERBOSITY = $verbosity;
}
#--------------------------

#--------------------------
#  PRIVATE Spyder Methods
#--------------------------
sub _reset {
# RESET MORE THAN THIS!?! make sure all the memory space is clean that
# needs be for clean iteration???
    my ($self) = @_;
    $self->{$_} = undef for qw( _linkText _linkSwitch _href _src
                               _current_enQ _page_content
                               _current_Bytes _alt _enqueue_Objects
                               _text );
}
#--------------------------
sub _current_enQ {
    my ($self, $enQ) = @_;
    my $last_enQ = $self->{_current_enQ};
    $self->{_current_enQ} = $enQ if $enQ;
    return $last_enQ; #<<-so we can get last while setting a new one
}
#--------------------------
sub _enqueue {
    my ($self,$enQ) = @_;
    push @{$self->{_enqueue_Objects}}, $enQ if $enQ;
    return $self->{_enqueue_Objects};
}
#--------------------------
sub _links {
    my ($self) = @_;
    return [ map { $_->url } @{$self->_enqueue} ];
}
#--------------------------
sub _seen {
    my ($self,$url) = @_;
    return $self->{_seenURLs}{$url}++;
}
#--------------------------
sub _parse_for_terms {
    my ($self) = @_;
    $self->{_page_terms_matches} = 0;

    return 0 unless $self->{_text};

    while ( my ($term,$rx) = each %{$self->terms} ) {
        $self->{_page_terms_matches}++ for
            $self->{_page_content} =~ /$rx/g;
    }

    my $index = int( ( $self->{_page_terms_matches} /
                       length($self->{_text}) ) * 1_000 );
# the algorithm might look it but isn't entirely arbitrary

    print " PARSE TERMS : $self->{_page_terms_matches} " .
        "/ $self->{_current_Bytes}\n" if $VERBOSITY > 1;

    return 7 if $index > 25;
    return 6 if $index > 18;
    return 5 if $index > 14;
    return 4 if $index > 11;
    return 3 if $index > 7;
    return 2 if $index > 3;
    return 1 if $index > 0;
    return 0;
}
#--------------------------
sub _install_html_parser {
    my ($self) = @_;

    my $Parser = HTML::Parser->new
        (
         start_h =>
         [sub {
             no warnings;
             my ( $tag, $attr ) = @_;

             # Check for broken image links if requested.
             return if $tag !~ /^(?:a|img)$/ && ! $self->{image_checking};

# need to deal with AREA tags from maps /^(?:a(?:rea)?|img)$/;
             $attr->{href} =~ s,#[^/]*$,,;
             $attr->{src}  =~ s,#[^/]*$,, if $self->{image_checking};
             return if lc($attr->{href}) =~ m,^\s*mailto:,;
             return if lc($attr->{href}) =~ m,^\s*file:,;
             return if lc($attr->{href}) =~ m,javascript:,;

             $self->{_src}  ||= $attr->{src} if $self->{image_checking};
             $self->{_href} ||= $attr->{href};
             $self->{_alt}  ||= $attr->{alt};
             $self->{_linkSwitch} = 1;

             # Don't wait for the end handler if we have an image, as an image
             # src tag doesn't have an end.
             if ($attr->{src} && $self->{image_checking} && ! $attr->{href}) {
                 $self->{_linkText} ||= $self->{_alt} || '+';
                 decode_entities($self->{_linkText});

                 push @{$self->{_enqueue_Objects}},
                     [ $self->{_href}, $self->{_linkText} ];

                 push @{$self->{_enqueue_Objects}},
                     [ $self->{_src}, $self->{_linkText} ]
                         if $self->{_src} and $self->{image_checking};

                 # reset all our caching variables
                 $self->{_linkSwitch} = $self->{_href} = $self->{_alt} =
                 $self->{_src} = $self->{_linkText} = undef;

                 return;
             }
         }, 'tagname, attr'],
         text_h =>
         [sub {

             return unless(my $it = shift);
             return if $it =~
                 m/(?:\Q<!--\E)|(?:\Q-->\E)/;
             ${$self->{_text}} .= $it;
             $self->{_linkText} .= $it
                 if $self->{_linkSwitch};
          }, 'dtext'],
         end_h =>
         [sub {
             my ( $tag ) = @_;
             no warnings; # only problem: <a><b>L</b>inks</a>

             if ($self->{image_checking}) {
                 return unless $tag eq 'a' or $self->{_linkSwitch} or
                               $tag eq 'img';
             } else {
                 return unless $tag eq 'a' or $self->{_linkSwitch};
             }

             $self->{_linkText} ||= $self->{_alt} || '+';
             decode_entities($self->{_linkText});

             push @{$self->{_enqueue_Objects}},
                 [ $self->{_href}, $self->{_linkText} ];

             push @{$self->{_enqueue_Objects}},
                 [ $self->{_src}, $self->{_linkText} ]
                     if $self->{_src} and $self->{image_checking};

          # reset all our caching variables
             $self->{_linkSwitch} = $self->{_href} = $self->{_alt} = $self->{_src} =
                 $self->{_linkText} = undef;
         }, 'tagname'],
         default_h => [""],
        );
    $Parser->ignore_elements(qw(script style));
    $Parser->unbroken_text(1);
    $self->html_parser($Parser);
}
#--------------------------
sub _install_web_agent {
    my $self     = shift;
    my $jar_jar = undef;

    # If a LWP::UserAgent object was passed in to our constructor, use
    # it.
    if ($self->{UA}) {
        $self->UA( $self->{UA} );

    # Otherwise, create a new one.
    } else {
        $self->UA( LWP::UserAgent->new );
    }

    $self->UA->agent('Mozilla/5.0');
    $self->UA->timeout(30);
    $self->UA->max_size(250_000);

    # Get our cookie from our the jar passed in.
    if ($self->{UA}) {
        $jar_jar = $self->{UA}->cookie_jar();

    # Or else create a new cookie.
    } else {
	$jar_jar = HTTP::Cookies->new
        (file => $self->cookie_file || "$ENV{HOME}/spyderCookies",
         autosave => 1,
         max_cookie_size => 4096,
         max_cookies_per_domain => 5, );
    }

    $self->UA->cookie_jar($jar_jar);
}
#--------------------------
sub _install_exit_check {
    my ($self, $arg) = @_;
    my $class = ref $self;

    unless ( ref($arg) and ref($arg->{exit_on}) eq 'HASH' ) {
        no strict "refs";
        *{$class."::_exit_check"} =
            sub { return 1 unless $self->queue_count;
                  return 0;
              };
        return;
    }

# checks can be: links => #, success => ratio, time => 10min...
# a piece of code we're going to build up to eval into method-hood
    my $SUB = 'sub {  my $self = shift; ' .
    'return 1 unless $self->queue_count; ';
#------------------------------------------------------------
    if ( $arg->{exit_on}{pages} ) {
        print "Installing EXIT on links: $arg->{exit_on}{pages}\n"
            if $VERBOSITY > 1;
        $SUB .= ' return 1 if ' .
            '$self->spydered >= ' .$arg->{exit_on}{pages} .';';
    }
#------------------------------------------------------------
    if ( $arg->{exit_on}{success} ) {
        #set necessary obj value and add to sub code
    }
#------------------------------------------------------------
    if ( $arg->{exit_on}{time} ) {
        print "Installing EXIT on time: $arg->{exit_on}{time}\n"
            if $VERBOSITY > 1;

        my ($amount,$unit) =
            $arg->{exit_on}{time} =~ /^(\d+)\W*(\w+?)s?$/;
# skip final "s" in case of hours, secs, mins

        my %times = ( hour => 3600,
                      min  => 60,
                      sec  => 1 );

        my $time_factor = 0;
        for ( keys %times ) {
            next unless exists $times{$unit};
            $time_factor = $amount * $times{$unit};
        }
        $self->_exit_epoch($time_factor + $^T);

        $SUB .= q{
            return 1 if $self->_exit_epoch < time();
        };
    }
#------------------------------------------------------------
    $SUB .= '}';

    no strict "refs";
    *{$class."::_exit_check"} = eval $SUB;
}
#--------------------------
sub _choose_courteously {
    my $self = shift;

# w/o the switch and $i-- it acts a bit more depth first. w/ it, it's
# basically hard head down breadth first
    print "CHOOSING courteously!\n" if $VERBOSITY > 1;
    for my $Q ( $self->_queues ) {
        print "Looking for URL in $Q\n" if $VERBOSITY > 2;
        next unless $self->{$Q} and @{$self->{$Q}} > 0;
        my %seen;
        my $total = scalar @{$self->{$Q}};
        my $switch;
        for ( my $i = 0; $i < @{$self->{$Q}}; $i++ ) {
            my $enQ = $self->{$Q}[$i];
            my ($url,$name) = ( $enQ->url, $enQ->name );

# if we see one again, we've reshuffled as much as is useful
            $seen{$url}++
                and $switch = 1; # progress through to next Q

            return splice(@{$self->{$Q}},$i,1)
                unless $self->_courtesy_call($enQ);

            my $fair_bump = int( log( $total - $i ) / log(1.5) );

            my $move_me_back = splice(@{$self->{$Q}},$i,1);
            splice(@{$self->{$Q}},($i+$fair_bump),0,$move_me_back);
            $i-- unless $switch;
        }
    }
    # we couldn't pick one courteously
} # end of _choose_courteously()
#--------------------------
sub _just_choose {
    my $self = shift;
    print "CHOOSING first up!\n" if $VERBOSITY > 1;

    my $enQ;
    for my $Q ( $self->_queues ) {
        next unless ref($self->{$Q}) eq 'ARRAY';
        $enQ = shift @{$self->{$Q}};
        last;
    }
    my $tax = $self->_courtesy_call($enQ);
    if ( $VERBOSITY > 4 ) {
        print ' QUEUE: ';
        print join("-:-", @{$self->{_courtesy_Queue}}), "\n"
            if $self->{_courtesy_Queue};
    }
    my $sleep = int(rand($self->sleep_base)) + $tax;

    if ( $VERBOSITY ) {
        printf "COURTESY NAP %d second%s ",
        $sleep, $sleep == 1 ?'':'s';
        printf "(Domain recently seen: %d time%s)\n",
        $tax, $tax == 1 ?'':'s';
    }
    sleep $sleep; # courtesy to websites but human-ish w/ random
    $self->slept($sleep);
    return $enQ;
}
#--------------------------
sub _courtesy_call {
    my ($self,$enQ) = @_;
    return 0 unless $enQ;
    my $domain = $enQ->domain;

    print 'COURTESY check: ', $domain, "\n" if $VERBOSITY > 5;

# yes, we have seen it in the last whatever GETs
    my $seen = 0;
    $seen = scalar grep { $_ eq $domain }
        @{$self->{_courtesy_Queue}};
    $seen = 10 if $seen > 10;
    return $seen;
}
#--------------------------
sub _queues {  # Q9 is purely for trash so it's not returned here
    return wantarray ?
        ( 0 .. 9 ) :
            '0';
}
#--------------------------
sub _snip {
    my $self = shift if ref($_[0]);
    my ( @text ) = @_;
    s/^\s+//, s/\s+$//, s/\s+/ /g for @text;
    return wantarray ? @text : shift @text;
}
#--------------------------
# Spyder ENDS
#--------------------------
}# WWW::Spyder privacy ends


#--------------------------
package WWW::Spyder::Enqueue;
#--------------------------
{
    use Carp;
#---------------------------------------------------------------------
use overload( q{""} => '_stringify',
              fallback => 1 );
#---------------------------------------------------------------------
#  0 -->> URL
#  1 -->> name, if any, of link URL was got from
#  2 -->> domain
#--------------------------
sub new {
    my ( $caller, $url, $name ) = @_;
    my $class = ref($caller) || $caller;
    croak "Here I am. " if ref $url;
    return undef unless $url;
    if ( length($url) > 512 ) { # that's toooo long, don't you think?
        $url = substr($url,0,512);
    }
    if ( $name and length($name) > 512 ) {
        $name = substr($url,0,509) . '...';
    }
    $name = '-' unless $name; # need this to find a bug later
    my ( $domain ) = $url =~ m,^[^:]+:/+([^/]+),;
    bless [ $url, $name, lc($domain) ], $class;
}
#--------------------------
sub url {
    return $_[0]->[0];
}
#--------------------------
sub name {
    return $_[0]->[1];
}
#--------------------------
sub domain {
    return $_[0]->[2];
}
#--------------------------
sub _stringify {
    return $_[0]->[0];
}
#--------------------------
}#privacy for WWW::Spyder::Enqueue ends


#--------------------------
package WWW::Spyder::Page;
#--------------------------
use strict;
use warnings;
use Carp;
{
sub new {
    my ( $caller, %arg ) = @_;
    my $class = ref($caller) || $caller;
    my $self = bless {}, $class;

    while ( my ( $method, $val ) = each %arg ) {

        no strict "refs";
        no warnings;
        my $attribute = '_' . $method;

        if ( ref $val eq 'ARRAY' ) {
            *{"$class::$method"} = sub {
                my($self,$arg) = @_;
                return @{$self->{$attribute}} unless $arg;
                push(@{$self->{$attribute}}, @{$arg});
            };
        } else {
            *{"$class::$method"} = sub {
                my($self,$arg) = @_;
                # get if already set and deref if needed
                if ( not $arg and exists $self->{$attribute} ) {
                    return ref($self->{$attribute}) eq 'SCALAR' ?
                        ${$self->{$attribute}} : $self->{$attribute};
                 }
                $self->{$attribute} = $arg if $arg;  #only set one time!
            };
        }
        $self->$method($val);
    }
    return $self;
}
#--------------------------
sub links {
    my ( $self ) = @_;
    return map {$_->url} @{$self->{_pages_enQs}};
}
#--------------------------
sub next_link {
    my ( $self ) = @_;
    shift @{$self->{_pages_enQs}};
}
#--------------------------
}#privacy for ::Page ends


#--------------------------
package WWW::Spyder::Exclusions;
#--------------------------
{
# THIS PACKAGE IS NOT BEING USED
my %_domains = qw(
                  ad.doubleclick.net        1
                  ads.clickagents.com       1
                  );
my %_names = qw(

                );
#--------------------------
sub exclude_domain {
    $_domains{shift}++;
}
#--------------------------
sub excluded {
    my $what = shift;
    exists $_domains{$what} || $_names{$what};
}
#--------------------------
}#privacy ends


#--------------------------
package WWW::Spyder::Seed;
#--------------------------
{
use URI::Escape;
use Carp;

my %engine_url =
    (
     google => 'http://www.google.com/search?q=',
     yahoo =>  1
     );

# should we exclude the search domain at this point? i think so because
# otherwise we've introduced dozens of erroneous links and the engine
# is gonna get hammered over time for it
#--------------------------
sub get_seed {

    my $engine = shift || croak "Must provide search engine! " .
        join(', ', sort keys %engine_url) . "\n";

    my $query  = shift || croak "Must provide query terms!\n";
    $query = uri_escape($query);

    croak "$engine is not a valid choice!\n"
        unless exists $engine_url{lc$engine};

    return $engine_url{lc$engine} . $query;
}

} # Privacy for WWW::Spyder::Seed ends

1;

#  Plain Old D'errrrr

=pod

=head1 NAME

WWW::Spyder - a simple non-persistent web crawler.

=head1 VERSION

0.24

=head1 SYNOPSIS

A web spider that returns plain text, HTML, and other information per
page crawled and can determine what pages to get and parse based on
supplied terms compared to the text in links as well as page content.

 use WWW::Spyder;
 # Supply your own LWP::UserAgent-compatible agent.
 use WWW::Mechanize;

 my $start_url = "http://my-great-domain.com/";
 my $mech = WWW::Mechanize->new(agent => "PreferredAgent/0.01")

 my $spyder = WWW::Spyder->new(
                               report_broken_links => 1,
                               seed                => $start_url,
                               sleep_base          => 5,
                               UA                  => $mech
                );
 while ( my $page = $spyder->crawl ) {
     # do something with the page...
 }

=head1 METHODS

=over 2

=item * $spyder->new()

Construct a new spyder object. Without at least the seed() set, or
go_to_seed() turned on, the spyder isn't ready to crawl.

 $spyder = WWW::Spyder->new(shift||die"Gimme a URL!\n");
    # ...or...
 $spyder = WWW::Spyder->new( %options );

Options include: sleep_base (in seconds), exit_on (hash of methods and
settings), report_broken_links, image_checking (verifies the images pointed to
by <img src=...> tags, disable_cnap (disables the courtesy nap when verbose
output is enabled), and UA (you can pass in an instantiated LWP::UserAgent
object via UA, i.e. UA => $ua_obj). Examples below.

=item * $spyder->seed($url)

Adds a URL (or URLs) to the top of the queues for crawling. If the
spyder is constructed with a single scalar argument, that is considered
the seed.

=item * $spyder->bell([bool])

This will print a bell ("\a") to STDERR on every successfully crawled
page. It might seem annoying but it is an excellent way to know your
spyder is behaving and working. True value turns it on. Right now it
can't be turned off.

=item * $spyder->spyder_time([bool])

Returns raw seconds since I<Spyder> was created if given a
boolean value, otherwise returns "D day(s) HH::MM:SS."

=item * $spyder->terms([list of terms to match])

The more terms, the more the spyder is going to grasp at. If you give
a straight list of strings, they will be turned into very open
regexes. E.g.: "king" would match "sulking" and "kinglet" but not
"King." It is case sensitive right now. If you want more specific
matching or different behavior, pass your own regexes instead of
strings.

    $spyder->terms( qr/\bkings?\b/i, qr/\bqueens?\b/i );

terms() is only settable once right now, then it's a done deal.

=item * $spyder->spyder_data()

A comma formatted number of kilobytes retrieved so far. B<Don't> give
it an argument. It's a set/get routine.

=item * $spyder->slept()

Returns the total number of seconds the spyder has slept while
running. Useful for getting accurate page/time counts (spyder
performance) discounting the added courtesy naps.

=item * $spyder->UA->...

The user agent. It should be an L<LWP::UserAgent> or a well-behaved
subclass like L<WWW::Mechanize>. Here are the initialized values you
might want to tweak-

    $spyder->UA->timeout(30);
    $spyder->UA->max_size(250_000);
    $spyder->UA->agent('Mozilla/5.0');

Changing the agent name can hurt your spyder because some servers won't
return content unless it's requested by a "browser" they recognize.

You should probably add your email with from() as well.

    $spyder->UA->from('bluefintuna@fish.net');

=item * $spyder->cookie_file([local_file])

They live in $ENV{HOME}/spyderCookie by default but you can set your
own file if you prefer or want to save different cookie files for
different spyders.

=item * $spyder->get_broken_links

Returns a reference to a list of broken link URLs if report_broken_links was
was enabled in the constructor.

=item * $spyder->go_to_seed

=item * $spyder->queue_count

=item * $spyder->show_attributes

=item * $spyder->spydered

=item * $spyder->crawl

Returns (and removes) a Spyder page object from the queue of spydered pages.

=back

=head2 Sypder::Page methods

=over 6

=item * $page->title

=item * $page->text

=item * $page->raw

=item * $page->url

=item * $page->domain

=item * $page->link_name

=item * $page->link

=item * $page->description

=item * $page->pages_enQs

=back

=head2 Weird courteous behavior

Courtesy didn't used to be weird, but that's another story. You will
probably notice that the courtesy routines force a sleep when a
recently seen domain is the only choice for a new link. The sleep is
partially randomized. This is to prevent the spyder from being
recognized in weblogs as a robot.

=head2 The web and courtesy

B<Please>, I beg of thee, exercise the most courtesy you can. Don't
let impatience get in the way. Bandwidth and server traffic are
C<$MONEY> for real. The web is an extremely disorganized and corrupted
database at the root but companies and individuals pay to keep it
available. The less pain you cause by banging away on a webserver with
a web agent, the more welcome the next web agent will be.

B<Update>: Google seems to be excluding generic LWP agents now. See, I
told you so. A single parallel robot can really hammer a major server,
even someone with as big a farm and as much bandwidth as Google.

=head2 VERBOSITY

=over 2

=item * $spyder->verbosity([1-6])  -OR-

=item * $WWW::Spyder::VERBOSITY = ...

Set it from 1 to 6 right now to get varying amounts of extra info to
STDOUT. It's an uneven scale and will be straightened out pretty soon.
If kids have a preference for sending the info to STDERR, I'll do
that. I might anyway.

=back

=head1 SAMPLE USAGE

=head2 See "spyder-mini-bio" in this distribution

It's an extremely simple, but fairly cool pseudo bio-researcher.

=head2 Simple continually crawling spyder:

In the following code snippet:

 use WWW::Spyder;

 my $spyder = WWW::Spyder->new( shift || die"Give me a URL!\n" );

 while ( my $page = $spyder->crawl ) {

    print '-'x70,"\n";
    print "Spydering: ", $page->title, "\n";
    print "      URL: ", $page->url, "\n";
    print "     Desc: ", $page->description || 'n/a', "\n";
    print '-'x70,"\n";
    while ( my $link = $page->next_link ) {
        printf "%22s ->> %s\n",
        length($link->name) > 22 ?
            substr($link->name,0,19).'...' : $link->name,
            length($link) > 43 ?
                substr($link,0,40).'...' : $link;
    }
 }

as long as unique URLs are being found in the pages crawled, the
spyder will never stop.

Each "crawl" returns a page object which gives the following methods
to get information about the page.

=over 2

=item * $page->links

URLs found on the page.

=item * $page->title

Page's <TITLE> Title </TITLE> if there is one.

=item * $page->text

The parsed plain text out of the page. Uses HTML::Parser and tries to
ignore non-readable stuff like comments and scripts.

=item * $page->url

=item * $page->domain

=item * $page->raw

The content returned by the server. Should be HTML.

=item * $page->description

The META description of the page if there is one.

=item * $page->links

Returns a list of the URLs in the page. Note: next_link() will shift
the available list of links() each time it's called.

=item * $link = $page->next_link

next_link() destructively returns the next URI-ish object in the page.
They are objects with three accessors.

=back

=over 6

=item * $link->url

This is also overloaded so that interpolating "$link" will get the
URL just as the method does.

=item * $link->name

=item * $link->domain

=back

=head2 Spyder that will give up the ghost...

The following spyder is initialized to stop crawling when I<either> of
its conditions are met: 10mins pass or 300 pages are crawled.

 use WWW::Spyder;

 my $url = shift || die "Please give me a URL to start!\n";

 my $spyder = WWW::Spyder->new
      (seed        => $url,
       sleep_base  => 10,
       exit_on     => { pages => 300,
                        time  => '10min', },);

 while ( my $page = $spyder->crawl ) {

    print '-'x70,"\n";
    print "Spydering: ", $page->title, "\n";
    print "      URL: ", $page->url, "\n";
    print "     Desc: ", $page->description || '', "\n";
    print '-'x70,"\n";
    while ( my $link = $page->next_link ) {
        printf "%22s ->> %s\n",
        length($link->name) > 22 ?
            substr($link->name,0,19).'...' : $link->name,
            length($link) > 43 ?
                substr($link,0,40).'...' : $link;
    }
 }

=head2 Primitive page reader

 use WWW::Spyder;
 use Text::Wrap;

 my $url = shift || die "Please give me a URL to start!\n";
 @ARGV or die "Please also give me a search term.\n";
 my $spyder = WWW::Spyder->new;
 $spyder->seed($url);
 $spyder->terms(@ARGV);

 while ( my $page = $spyder->crawl ) {
     print '-'x70,"\n * ";
     print $page->title, "\n";
     print '-'x70,"\n";
     print wrap('','', $page->text);
     sleep 60;
 }

=head1 TIPS

If you are going to do anything important with it, implement some
signal blocking to prevent accidental problems and tie your gathered
information to a DB_File or some such.

You might want to load C<POSIX::nice(40)>. It should top the nice off
at your system's max and prevent your spyder from interfering with
your system.

You might want to to set $| = 1.

=head1 PRIVATE METHODS

=head2 are private but hack away if you're inclined

=head1 TO DO

I<Spyder> is conceived to live in a future namespace as a servant class
for a complex web research agent with simple interfaces to
pre-designed grammars for research reports; or self-designed
grammars/reports (might be implemented via Parse::FastDescent if that
lazy-bones Conway would just find another 5 hours in the paltry 32
hour day he's presently working).

I'd like the thing to be able to parse RTF, PDF, and perhaps even
resource sections of image files but that isn't on the radar right
now.

The tests should work differently. Currently they ask for outside
resources without checking if there is either an open way to do it or
if the user approves of it. Bad form all around.

=head1 TO DOABLE BY 1.0

Add 2-4 sample scripts that are a bit more useful.

There are many functions that should be under the programmer's control
and not buried in the spyder. They will emerge soon. I'd like to put
in hooks to allow the user to keep(), toss(), or exclude(), urls, link
names, and domains, while crawling.

Clean up some redundant, sloppy, and weird code. Probably change or
remove the AUTOLOAD.

Put in a go_to_seed() method and a subclass, ::Seed, with rules to
construct query URLs by search engine. It would be the autostart or the
fallback for perpetual spyders that run out of links. It would hit a
given or default search engine with the I<Spyder>'s terms as the query.
Obviously this would only work with terms() defined.

Implement auto-exclusion for failure vs. success rates on names as well
as domains (maybe URI suffixes too).

Turn length of courtesy queue into the breadth/depth setting? make it
automatically adjusting...?

Consistently found link names are excluded from term strength sorting?
Eg: "privacy policy," "read more," "copyright..."

Fix some image tag parsing problems and add area tag parsing.

Configuration for user:password by domain.

::Page objects become reusable so that a spyder only needs one.

::Enqueue objects become indexed so they are nixable from anywhere.

Expand exit_on routines to size, slept time, dwindling success ratio,
and maybe more.

Make methods to set "skepticism" and "effort" which will influence the
way the terms are used to keep, order, and toss URLs.

=head1 BE WARNED

This module already does some extremely useful things but it's in its
infancy and it is conceived to live in a different namespace and
perhaps become more private as a subservient part of a parent class.
This may never happen but it's the idea. So don't put this into
production code yet. I am endeavoring to keep its interface constant
either way. That said, it could change completely.

=head2 Also!

This module saves cookies to the user's home. There will be more
control over cookies in the future, but that's how it is right now.
They live in $ENV{HOME}/spyderCookie.

=head2 Anche!

Robot Rules aren't respected. I<Spyder> endeavors to be polite as far
as server hits are concerned, but doesn't take "no" for answer right
now. I want to add this, and not just by domain, but by page settings.

=head1 UNDOCUMENTED FEATURES

A.k.a. Bugs. Don't be ridiculous! Bugs in B<my code>?!

There is a bug that is causing retrieval of image src tags, I think
but haven't tracked it down yet, as links. I also think the plain text
parsing has some problems which will be remedied shortly.

If you are building more than one spyder in the same script they are
going to share the same exit_on parameters because it's a
self-installing method. This will not always be so.

See B<Bugs> file for more open and past issues.

Let me know if you find any others. If you find one that is platform
specific, please send patch code/suggestion because I might not have
any idea how to fix it.

=head1 WHY C<Spyder?>

I didn't want to use the more appropriate I<Spider> because I think
there is a better one out there somewhere in the zeitgeist and the
namespace future of I<Spyder> is uncertain. It may end up a
semi-private part of a bigger family. And I may be King of Kenya
someday. One's got to dream.

If you like I<Spyder>, have feedback, wishlist usage, better
algorithms/implementations for any part of it, please let me know!

=head1 THANKS TO

Most all y'all. Especially Lincoln Stein, Gisle Aas, The Conway,
Raphael Manfredi, Gurusamy Sarathy, and plenty of others.

=head1 COMPARE WITH (PROBABLY PREFER)

L<WWW::Robot>, L<LWP::UserAgent>, L<WWW::SimpleRobot>, L<WWW::RobotRules>,
L<LWP::RobotUA>, and other kith and kin.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001-2008, Ashley Pond V C<< <ashley@cpan.org> >>. All
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
