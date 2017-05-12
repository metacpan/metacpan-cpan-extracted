package Text::Chump;

use strict;
use vars qw($VERSION);
use Text::DelimMatch;
use Tie::IxHash;
use URI::Find;
use Carp;

$VERSION = "1.02";



=pod

=head1 NAME

Text::Chump - a module for parsing Chump like syntax


=head1 SYNOPSIS

	use Text::Chump;

	my $tc = Text::Chump->new();

	$tc->chump('[all mine!|http://thegestalt.org]');
	# returns <a href='http://thegestalt.org'>all mine!</a>

	$tc->chump('+[all mine!|http://thegestalt.org]');
	# returns <img src='http://thegestalt.org' alt='all mine!'>

	$tc->chump('http://thegestalt.org');
	# returns <a href='http://thegestalt.org'>http;//thegestalt.org</a>

	my $tc = Text::Chump->new({images=>0});

	$tc->chump('+[all mine!|http://thegestalt.org]');
	# returns '+[all mine!|http://thegestalt.org]'


	sub foo {
		my ($url, $label) = @_;

		return "$label ($url)";
	}

	$tc->install('link',\&foo);
	$tc->chump('[foo|http://bar.com]');
	# returns 'foo (http://bar.com)'

	sub quirka {
		my ($opts, $match, $label) = @_;

		return "<a href="blog.cgi?entry=$match">$label</a>";

	}



	$tc->install('link',\$quirka,'\d+');
	$tc->chump('[stuff|4444]');
	# returns "<a href="blog.cgi?entry=4444">stuff</a>"



=head1 DESCRIPTION

Chump is an IRC bot that allows people to post links and comments 
onto a website from within an IRC Channel. Some people call this a blog 
but I hate that term. Hate it. *HATE IT*! ... *cough* ... so I'll avoid 
it from now on.

The Chump is based on an original idea by Bijan Parsia. Bijan wrote a bot in Squeak
called DiaWebLogBot, which powers the Monkeyfist Daily Churn and subsequently
Useful Inc. "stole all his good ideas". Therefore  The Chump syntax is derived
and extended from diaweblogbot.

The bot is available from B<http://usefulinc.com/chump/> and the original page 
that uses this form of markup is B<http://pants.heddley.com>.

The items which are displayed on the page can have a special format. These,
in turn get marked up as HTML (by default). Essentially this provides a simple 
markup language. Yes - they could have used XML and been fully buzzword compliant 
(it uses XML in the backend if that's any help) but they didn't.

Since then the syntax has been appropriated by a number of projects including one 
of my own, so, like the good little code that I am, it all went in a module.

Which I may as well release because somebody else wants to release a module which 
depends on it and it might be useful to someone else.

Alternatives to this module include B<Text::WikiFormat> and B<HTML::FromText> 
although they do subtly different things. In fact you could probably chain them 
together - especially B<HTML::FromText> with uri set to 0.

=head1 SYNTAX

As described here 

B<http://usefulinc.com/chump/MANUAL.txt>



=over 4

=item * Links :

  [<text>|url]

This creates an inline link (i.e. turning a word into a link). So, for example

  They also have [another site|http://foobar.com]

will make the words "another site" appear as a hyperlink to
the URL http://foobar.com.

=item * Images :

  +[http://url.of.image.com/image.jpg]

This creates an inline image in some text. By providing some text you can provide 
an alt tag which is considered a good thing to do.

  +[This is the alt text|http://url.of.image.com/image.jpg]

By providing a url in the middle 

  +[This is the alt text|http://foobar.com|http://url.of.image.com/image.jpg]

You can turn the image into a clickable link.


=item * Urls :

  http://foobar.com

this will be turned into a clicable link.

=back


=head1 METHODS

=head2 new <opts>

Can take an hashref of options (target defaults to nothing, border defaults to 0,
everything else defaults to 1 == yes)

=over 4

=item *  target : 

A default target for a URL (such as _blank)

=item * border : 

Whether inline images should have a border

=item * images : 

Whether to process image markup 

=item  * links : 

Whether to process link markup 

=item * urls : 

Whether to process urls 

=back


=cut


# standard set up stuff
sub new {
    my $class = shift;
    my $self  = shift || {};

    $self->{plugins} = {};
    $self->{types}   = {
			'link' => 'link',
			'+'    => 'image',
			'url'  => 'url',
		       };


    bless $self, $class;

    # we'll be macthing between '[' and ']'
    $self->{_mc}     = $self->_make_matcher();

    # Default handlers.
    $self->install('link',  sub { $self->_chump_link(@_)  } );
    $self->install('image', sub { $self->_chump_image(@_) } );
    $self->install('url',   sub { $self->_chump_url(@_)   } );

    return $self;

}


=pod

=head2 new_type [name] [char] [coderef] <regexp>

Installs a new type so that if the parser comes across

	$char[stuff|nonsense] 

then the parts  will be passed to the coderef in the 
normal way. If you pass in a regexp then that will be
used to determine the match, just like if you install a
new handler.

In order to turn off handling of the new type pass in

	$opt->{"${name}s"} = 0;

as the options to I<chump()>. So

	my $text = 'foo bar %[foo|http://quux.com]';

	$mc->new_type('percent','%', sub { return $_[1] });
	$mc->chump($text);
	
returns 

	'foo bar http://quux.com'

but

        my $text = 'foo bar %[foo|http://quux.com]';

        $mc->new_type('percent','%', sub { return $_[1] }, 'foo');
        $mc->chump($text);	

returns

	'foo bar foo'

but

        my $text = 'foo bar %[foo|http://quux.com]';

        $mc->new_type('percent','%', sub { return $_[1] }, 'foo');
        $mc->chump($text, { 'percents' => 0 });

returns

	'foo bar %[foo|http://quux.com]'


So that's all clear then :)


=cut


sub new_type {
	my ($self, $name, $char, $code, $regexp) = @_;


	$self->{types}->{$char} = $name;
	$self->{_mc}            = $self->_make_matcher();
	$self->{"${name}s"}     = 1; 
	$self->install($name, $code, $regexp);

}


sub _make_matcher {
	my ($self) = @_;

	my $regexp = "";
	foreach my $key (keys %{$self->{types}}) {
		next if length $key != 1;
		next if $key =~ m!^[a-z\d]$!m;
		$regexp .= '\\'.$key;
	}


	return Text::DelimMatch->new("[$regexp]{0,1}\\[","\\]");


}


=pod 

=head2 chump [text]

Takes some text to munge and returns it, fully chumped. Can optionally take 
a hashref with the same options as I<new> except that these options will only
apply to this bit of text.

=cut

# the real work
sub chump {
	# get the text, remembering that we may not actually be passed anything
	my $self = shift;
	my $text = shift || "";
	my $opts = shift || {};



	# set up options
	my $border = (defined $self->{border})? $self->{border} : 0;
	$opts->{border} = $border unless defined $opts->{border};
	$opts->{border} = "border='$opts->{border}'" unless $opts->{border} =~ /border/i;
	# (urgh)



	foreach my $val (values %{$self->{types}})
	{
		my $tmp    = (defined $self->{"${val}s"})? $self->{"${val}s"} : 1;
		$opts->{"${val}s"} = $tmp unless defined $opts->{"${val}s"};
	}



    	# curse the tedious URI::Find interface
    	$self->{_finder} = URI::Find->new(
                sub {
                    my($uri, $orig_uri) = @_;
                    return $self->_make_link($uri,$orig_uri,$opts);
                },
	);



	# get all our tokens
	my @tokens = $self->_get_tokens($text);



	# pre declare
	my $return;

	# for each token we've got, decide ...
	TOKEN: foreach my $token (@tokens) {

		my $orig = $token;

		# is it a bracket match? and if so is it an image ...
                if ($token =~ s/^([^\[]{0,1})\[(.*)\]$/$2/) {

			my $type = $1 || 'link';

			my $typename = $self->{types}->{$type};
			
			unless (defined $opts->{"${typename}s"} && $opts->{"${typename}s"}) {
				$return .= $orig;
				next TOKEN;
			}			

			
                        my @parts = split /\|/, $token, 3;
                
			# check to see if there's a user defined regexp
			if (my $tmp = $self->_do_regexp_plugins($typename, $opts,@parts)) {
				$return .= $tmp; 
				next TOKEN;
			}

			# stick it back on
			# $return .= $type unless (defined $typename);

			# if not then work out which one is the image url, 
			# the label and the optional link url
			my ($url, $label, $link)  = $self->_order_params(sub { $self->_is_url($_[0]) }, @parts);

			# check to see if there's a user defined regexp
                        if (my $tmp = $self->_do_normal_plugins($typename, $opts, $url, $label, $link)) {
                                $return .= $tmp;
                                next TOKEN;
                        }

			# otherwise return the original
			$return .= $orig;

		# otherwise it's plain text
        	} else  {
			# check to see if there's a user defined regexp
                        if (my $tmp = $self->_do_regexp_plugins('url', $opts, $orig)) {
                                $return .= $tmp;
                                next TOKEN;
                        }
	
			# check to see if there's a user defined regexp
                        if (my $tmp = $self->_do_normal_plugins('url', $opts, $orig)) {
                                $return .= $tmp;
                                next TOKEN;
                        }
			
			$return .= $orig;		

        	} 
	}
 
	# return the whole caboodle
	return  $return;  
}

=head2 install [type] [coderef] <regexp>

if you pass in either 'image', 'link' or 'url' and a valid coderef 
then that code ref will be called on the original sting instead of the
default behaviour.

This is useful for outputting something other than HTML.

And, in a special, one time only offer, if optionally you pass in 
a regexp then you can add your own handlers. So, for example, if you 
did :

	$tc->install('link', sub { return 'foo' }, '\d{4}');
	print $tc->chump('[test|1234]'); # prints "foo"

However you regexps are checked in reverse order they're put in so if
you then do :

	$tc->install('link', sub { return 'bar' }, '\d{5}');

then :

	print $tc->chump('[test|1234]');  # prints "foo"
	print $tc->chump('[test|12345]'); # prints "bar"


Note: all regexps are assumed to be case insensitive. 

If you want to monkey around with the ordering post install then the IxHash 
object that they're installed in can be found in 

	$tc->{plugins}->{[name]}->{regexp}



For a link or and image the values passed to the coderef are a hashref of 
options then the match then the label and then optionally a middle value.

If no label is passed then it will be set to the same value as the link.

So for these

	[foo|bar|http://thegestalt.org]
	[http://thegestaltorg|bar|foo]

a sub will be passed

	my ($opt, $link, $label, $middle) = @_;
	
	# $opt    = hashref of options
	# $link   = http://thegestalt.org
	# $label  = foo
	# $middle = bar


and for

	[http://thegestalt.org]

you'll get

        # $opt    = hashref of options
        # $link   = http://thegestalt.org
        # $label  = http://thegestalt.org
        # $middle = undef



For a url you'll only get passed an opt and the original string.



=cut

sub install {

	my $self = shift || carp "Must be called in an OO manner\n";
	my $name = shift || carp "Must pass a name\n";
	my $code = shift || carp "Must pass a coderef\n";
	my $regexp = shift;


	if (defined $regexp) {
		$self->{plugins}->{$name}->{regexp} = Tie::IxHash->new() 
				unless defined $self->{plugins}->{$name}->{regexp};

		$self->{plugins}->{$name}->{regexp}->Unshift($regexp => $code);
	} else {
		$self->{plugins}->{$name}->{default} = $code;
	}
}




sub _get_tokens 
{
	my $self = shift;
	my $text = shift || "";


	# we'll be matching stuff between '[' and ']'
        my $mc = $self->{_mc};

        # pre declare 
        my @tokens;

        # loop through all the matches
        # Why isn't this a standard method in Text::DelimMatch?
        # And if it is then why is it badly documented?
        while (my $match = $mc->match($text))   
        {
                # if we've got anything from before the match then whack it in
                my $pre = $mc->pre_matched() || "";
                push @tokens, $pre;

                # push the match in
                push @tokens, $match;

                # and reset $text so that we don't loop infinitely
                $text = $mc->post_matched() || "";
        }
        # push anything left onto the tokens. This also catches the case
        # of there being no matches
        push @tokens, $text;

	return @tokens;

}



=pod

=head2 _order_params [function] [@params]

Given a function and an array of params it will return the first 
parameter that matches the function. 

The order that it checks in is last element of the array and then 
the first element.

Why this weird order? Because it's more natural to write

	[foo|http://bar.com]

or, at least, that seems to be the behaviour I've observed.

A typical function would look like this


	sub {
		return $_[0] =~ /\d+/;
	}


=cut

sub _order_params
{
	my ($self, $function,@parts) = @_;
	
	return unless @parts;
	
	my $one = shift @parts;
	my $two = pop   @parts;
	

	my ($first, $second);

	if ($function->($one)) {
		$first = $one;
		$second = $two;
	} elsif ($function->($two)) {
		$first = $two;
		$second = $one;
	} else {
		return undef;
	}

	return ($first, $second, @parts);
}


sub _do_regexp_plugins
{
	my ($self, $type, $opts, @parts) = @_;

	return undef unless defined $self->{plugins}->{$type}->{regexp};

	foreach my $re ($self->{plugins}->{$type}->{regexp}->Keys()) 
	{
		my ($a, $b, $c) = $self->_order_params(sub { return $_[0] =~ m!$re!i }, @parts );
		next unless defined $a;
		$b = $a unless defined $b;
		
		
	        my $tmp;
                eval {  
                        $tmp = $self->{plugins}->{$type}->{regexp}->FETCH($re)->($opts, $a, $b, $c);
                };
                unless ($@) {
                        return $tmp;
                }
        }
         
        return undef;


}



sub _do_normal_plugins {
	my ($self, $type, $opts, $a, $b, $c) = @_;



	return undef unless defined $a;
	return undef unless defined $self->{plugins}->{$type}->{default};
	




	$b = $a unless defined $b;
	my $tmp;
        eval {
        	$tmp = $self->{plugins}->{$type}->{default}($opts, $a, $b, $c);
        };
        unless ($@) {
		return $tmp;
	} 

	return undef;
}


=pod

=head2 _chump_link [opts] [url] [labe]

Just incase you want to call this from your own plugin, 
this is the default action for links. 

Calls, I<_make_link> internally.

=cut
	
sub _chump_link
{
	my ($self, $opts, $url, $label) = @_;
	# We don't do a lot here, but I wanted a nice, easy-to-override
	# function name.
	return $self->_make_link($url, $label, $opts);
}

=pod

=head2 _chump_image [opts] [url] [labe] <link>

Ditto, but for images.

Returns

	<img src='$url' alt='$label' title='$label' $opts->{border} />

optionally wrapping it in an href to <link>

=cut

sub _chump_image
{
	my ($self, $opts, $url, $label, $link) = @_;

	
	$opts->{border} ||= "";
	$url   ||= "";	
	$label ||= "";	
	$link  ||= "";

	my $img = "<img src='$url' alt='$label' title='$label' $opts->{border} />";
        $img = $self->_make_link($link, $img, $opts) if $link and $self->_is_url($link);
	return $img;
}


=pod 

=head2 _chump_url [opts] [text]

Does a call to to I<_make_link> for each URL it finds.

=cut 

sub _chump_url
{
	my ($self, $opts, $text) = @_;
	$self->{_finder}->find(\$text) if ($opts->{urls} && $text !~ /^\+?\[.*\]$/);
	return $text;
}


=pod

=head2 _make_link [link] [label] <opts>

returns 
	
	<a href='$link' target='$opts->{target}'>$text</a>

=cut

# create a link including setting the target
sub _make_link
{
	my ($self, $link, $text) = @_;

	$link ||= "";
	$text ||= "";

	my $opts = $_[3] || {};

	my $target = (defined $self->{target})?  $self->{target} : undef;
	$target    = $opts->{target} if defined $opts->{target};

	$target = (defined $target)? " target='$target'" : "";

	return 	"<a href='$link' $target>$text</a>";

}


=pod

=head2 _is_url [text]

Returns 1 if the text is a url or 0 if it isn't.

=cut

sub _is_url {
	my ($self, $url) = @_;
	$url ||= "";

	my $copy = "$url";
	return $self->{_finder}->find(\$copy);
}


1;


=pod

=head1 BUGS

Not that I know of.

Oh, wait - maybe it should URL escape any entities in the text but you 
should probably do that yourself.

=head1 COPYING

(c)opyright 2002, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life, kill your friends, burn your house and bring about the apocalypse


=head1 AUTHOR

Copyright 2003, Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

B<http://usefulinc.com/chump/>, L<Bot::Basic::Pluggable::Blog>, 
L<Template::Plugin::Chump>, L<Text::WikiFormat>, L<HTML::FromText>,
L<Tie::IxHash>

=cut

