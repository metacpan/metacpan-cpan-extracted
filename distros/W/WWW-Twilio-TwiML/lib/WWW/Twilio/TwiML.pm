package WWW::Twilio::TwiML;

use 5.008001;
use strict;
use warnings;
use Carp 'croak';
use Scalar::Util 'blessed';

our $VERSION = '1.05';
our $AUTOLOAD;
our $NL = "\n";
our $STRICT = 0;
our %TAGS   = ();

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->{_name}       = '';
    $self->{_attributes} = {};
    $self->{_parent}     = undef;
    $self->{_content}    = '';

    {
        no strict 'refs';
        my %args = @_;
        for my $arg ( keys %args ) {
            if( exists $self->{"_$arg"} ) {
                $self->$arg($args{$arg});
            }
        }
    }

    return $self;
}

sub name {
    my $self = shift;

    if( @_ ) {
        $self->{_name} = shift;
    }

    $self->{_name};
}

sub parent {
    my $self = shift;

    if( @_ ) {
        $self->{_parent} = shift;
    }

    $self->{_parent};
}

sub content {
    my $self = shift;
    my @args = grep { defined $_ } @_;

    if( @args ) {
        my $arg = shift;

        ## an object
        if( ref($arg) ) {
            $arg->parent($self);
            $self->{_content} = [ $arg ];
            return $arg;
        }

        ## http://www.w3.org/TR/REC-xml/#syntax
        $arg =~ s{\&}{&amp;}g;
        $arg =~ s{\<}{&lt;}g;
        $arg =~ s{\>}{&gt;}g;
        $arg =~ s{\"}{&quot;}g;
        $arg =~ s{\'}{&apos;}g;

        $self->{_content} = $arg;
    }

    $self->{_content};
}

sub attributes {
    my $self = shift;

    if( @_ ) {
        $self->{_attributes} = shift;
    }

    $self->{_attributes};
}

sub add_child {
    my $self = shift;
    my $child = shift;

    $child->parent($self);
    $self->{_content} ||= [];
    push @{$self->{_content}}, $child;

    return $child;
}

sub root {
    my $self = shift;

    if( $self->{_parent} ) {
        return $self->{_parent}->root;
    }

    return $self;
}

sub to_string {
    my $self = shift;
    my $hdrs = shift || {};

    my @headers = ();
    for my $hdr ( sort keys %$hdrs ) {
        push @headers, $hdr . ': ' . $hdrs->{$hdr};
    }
    push @headers, '' if scalar(@headers);

    join($NL, @headers, $self->to_list);
}

sub to_list {
    my $self = shift;
    my $sp   = shift || 0;

    my @str = ();

    ## named element
    if( $self->name ) {
        if( my $content = $self->content ) {
            push @str, (' ' x $sp) . $self->otag;

            my $is_str = 0;

            if( ref($content) eq 'ARRAY' ) {
                for my $child ( @$content ) {
                    push @str, $child->to_list($sp + ($child->parent->name ? 2 : 0));
                }
            }

            else {
                $is_str = 1;
                $str[$#str] .= $content || '';
            }

            if( $is_str ) {
                $str[$#str] .= $self->ctag;
            }
            else {
                push @str, (' ' x $sp) . $self->ctag;
            }
        }

        ## no content; make a tidy tag
        else {
            push @str, (' ' x $sp) . $self->octag;
        }
    }

    ## unnamed (root) element
    else {
        push @str, qq!<?xml version="1.0" encoding="UTF-8" ?>!;

        my $content = $self->content;

        my $is_str = 0;
        if( ref($content) eq 'ARRAY' ) {
            for my $child ( @$content ) {
                push @str, $child->to_list($sp + ($child->parent->name ? 2 : 0));
            }
        }

        else {
            $is_str = 1;
            $str[$#str] .= $content || '';
        }

        push @str, '';
    }

    return @str;
}

sub otag {
    return '<' . $_[0]->name . $_[0]->_attr_str . '>';
}

sub ctag {
    return '</' . $_[0]->name . '>';
}

sub octag {
    return '<' . $_[0]->name . $_[0]->_attr_str . ' />';
}

sub _attr_str {
    my $self = shift;
    my $str  = '';

    my %attr = %{ $self->attributes };

    for my $key ( sort keys %attr ) {
        my $val = $attr{$key} || '';
        $str .= ' ';
        $str .= qq!$key="$val"!;
    }

    return $str;
}

sub can {
    my $self = shift;
    my $method = shift;

    ## NOTE: this probably breaks inheritance
    if( $STRICT and keys %TAGS ) {
        unless( exists $TAGS{$method} ) {
            no strict 'refs';
            undef *{ $method };
            return;
        }
    }

    my $meth_ref = $self->SUPER::can($method);
    return $meth_ref if $meth_ref;

    $meth_ref = sub {
        my $me = shift;

        my $child = new blessed $me;
        $child->name($method);

        for my $arg ( @_ ) {
            if( ref($arg) ) {
                $child->attributes($arg);
            }
            else {
                $child->content($arg);
            }
        }

        $me->add_child($child);

        return $child;
    };

    no strict 'refs';
    return *{ $method } = $meth_ref;
}

sub AUTOLOAD {
    my $self = $_[0];

    my $method = $AUTOLOAD;
    $method =~ s/^(.*):://;

    my $meth_ref = $self->can($method);
    croak "Undefined subroutine $method\n"
      unless $meth_ref;

    goto &$meth_ref;
}

sub DESTROY { }

## resp_node = ( name       => 'Response',
##               content    => [
##                               dial_node = ( name       => 'Dial',
##                                             content    => [
##                                                             conf_node = ( name       => 'Conference',
##                                                                           content    => '1234',
##                                                                           attributes => { private => 1 },
##                                                                           parent     => dial_node ),
##                                                           ],
##                                             attributes => {},
##                                             parent     => resp_node ),
##
##                               say_node  = ( name       => 'Say',
##                                             content    => "Thanks for conferencing.",
##                                             attributes => { voice => 'woman' },
##                                             parent     => resp_node ),
##                             ],
##              attributes => {},
##              parent     => root )

1;
__END__

=head1 NAME

WWW::Twilio::TwiML - Light and fast TwiML generator

=head1 SYNOPSIS

  use WWW::Twilio::TwiML;

  my $t = new WWW::Twilio::TwiML;
  $t->Response->Dial("+1234567890");
  print $t->to_string;

=head1 DESCRIPTION

B<WWW::Twilio::TwiML> creates Twilio-compatible TwiML
documents. Documents can be built by creating and nesting one element
at a time or by chaining objects. Elements can contain attributes,
text content, or other elements.

TwiML, being XML, could be trivially generated with B<XML::LibXML> or
any number of other XML parsers/generators. Philosophically,
B<WWW::Twilio::TwiML> represents an I<economical> TwiML generator. It
has a small footprint (TwiML documents are typically small and simple)
and means to make TwiML creation straightforward and moderately fun.

B<WWW::Twilio::TwiML>'s primary aim is for economy of
expression. Therefore, B<Any method you call on a TwiML object (except
those described below) will create new TwiML objects by the name of
the method you called.> By chaining method calls, you can create
robust TwiML documents with very little code.

=head2 new( key => value, ... )

Creates a new TwiML object. With no arguments, this will create a root
for your TwiML document. You can also call B<new> with I<name>,
I<content>, or I<attributes> arguments to create unattached
elements.

The following examples all create the this TwiML document using
different calling styles:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say voice="man">Kilroy was here</Say>
  </Response>

The upside-down, piecemeal, verbose way:

  my $say = new WWW::Twilio::TwiML;
  $say->name('Say');
  $say->content("Kilroy was here");
  $say->attributes({voice => "man"});

  my $resp = new WWW::Twilio::TwiML;
  $resp->name('Response');
  $resp->content($say);

  my $tw = new WWW::Twilio::TwiML;
  $tw->content($resp);
  print $tw->to_string;

The same thing, with a little more powerful constructor:

  my $say = new WWW::Twilio::TwiML(name => 'Say',
                                   content => "Kilroy was here",
                                   attributes => {voice => "man"});

  my $tw = new WWW::Twilio::TwiML;
  $tw->Response->add_child($say);
  print $tw->to_string;

The concise way:

  my $tw = new WWW::Twilio::TwiML;
  $tw->Response->Say({voice => "man"}, "Kilroy was here");
  print $tw->to_string;

And the obligatory one-liner (spread across 4 lines for readability):

  print WWW::Twilio::TwiML->new
    ->Response
    ->Say({voice => "man"}, "Kilroy was here")
    ->root->to_string;

What you don't see in the latter two examples is that both B<Response>
and B<Say> create and return objects with the names I<Response> and
I<Say> respectively. When called in this way, methods can I<chain>,
making for compact, yet readable expressions.

=head2 Any TwiML Verb( string | { attributes } )

Constructor shortcuts. TwiML verbs are described at
L<http://www.twilio.com/docs/api/twiml>. Some examples include
I<Response>, I<Say>, I<Play>, I<Gather>, I<Record>, I<Sms>, I<Dial>,
I<Number>, I<Client>, I<Conference>, I<Hangup>, I<Redirect>,
I<Reject>, and I<Pause> (this list may be out of date with respect to
the official documentation).

See Twilio's documentation for usage for these and other TwiML verbs.

The B<(any TwiML verb)> shortcut is a constructor of a TwiML
object. When you call B<(any TwiML verb)> on an existing TwiML object,
the following occurs:

=over 4

=item *

A new object is created and named by the method you called. E.g., if
you called:

  $tw->Response;

a TwiML object named 'Response' will be created.

=item *

The newly created object is attached to its parent (the object called
to create it).

=item *

The parent object has the new object added to its list of children.

=back

These last two items means the objects are "chained" to each
other. Chaining objects allows concise expressions to create TwiML
documents. We could add another object to the chain:

  $tw->Response
    ->Say("I'm calling you.")
      ->parent
    ->Dial("+17175558309");

The B<parent> method returns the I<Say> object's parent (I<Response>
object), and we chain a I<Dial> object from it. The resulting I<$tw>
object returns:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>I&apos;m calling you.</Say>
    <Dial>+17175558309</Dial>
  </Response>

=head2 name( string )

Gives a name to an element. This is what is used when the element is
printed out. If you're generally chaining objects, you won't use this
method often.

  $elem->name('Dial');
  $elem->content("+1234567890");

becomes:

  <Dial>+1234567890</Dial>

When no string is supplied, the name of the object is returned.

  print $elem->name . "\n";

The element name may also be given with B<new> or is implicit when you
call the constructor by the name of the element you want to create.

=head2 content( string | object )

Sets the content of an element. A TwiML object's content can be
I<either> a string or a listref of objects, but not both. If the
argument is another B<WWW::Twilio::TwiML> object, the content of the
element (if any) will be replaced with the object. Any other argument
will be considered string content.

  my $say = new WWW::Twilio::TwiML(name => 'Say');
  $say->content("Eat at Joe's!");  ## a string as content

becomes:

  <Say>Eat at Joe&apos;s!</Say>

Now we can add I<$say> to another element:

  my $parent = new WWW::Twilio::TwiML(name => 'Response');
  $parent->content($say);  ## an object as content

which becomes:

  <Response>
    <Say>Eat at Joe&apos;s!</Say>
  </Response>

When no argument is supplied, the existing contents are returned.

  my $content = $elem->content;
  if( ref($content) ) {
    for my $obj ( @$content ) {
      ## do something with each $obj
    }
  }

  else {
    print $content . "\n";  ## assuming a string here
  }

=head2 add_child( object )

Adds an element to the content of the TwiML object. Returns a
reference to the added object. Unlike B<content>, B<add_child> does
not I<replace> the existing content, but I<appends> an object to the
existing content. Also unlike B<content>, B<add_child> is not
appropriate to use for setting text content of an element.

  my $tw = new WWW::Twilio::TwiML;
  my $resp = $tw->Response;
  $resp->add_child(new WWW::Twilio::TwiML(name => 'Say',
                                          content => 'Soooey!'));

  my $email = uri_escape('biff@example.com');
  my $msg = uri_escape("Heeer piiiig!");
  my $url = "http://twimlets.com/voicemail?Email=$email&Message=$msg";
  $resp->add_child(new WWW::Twilio::TwiML(name => 'Redirect',
                                          content => $url));

  print $tw->to_string({'Content-type' => 'text/xml'});

becomes:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>Soooey!</Say>
    <Redirect>http://twimlets.com/voicemail?Email=\
    biff%40example.com&amp;Message=Heeer%20piiiig!</Redirect>
  </Response>

=head2 attributes({ key => value })

Sets attributes for an element. If a hash reference is not supplied, a
hashref of the existing attributes is returned.

  my $elem = new WWW::Twilio::TwiML(name => 'Say');
  $elem->attributes({voice => 'woman'});
  $elem->content("gimme another donut");

becomes:

  <Say voice="woman">gimme another donut</Say>

=head2 root

Returns a handle to the root object.

  print WWW::Twilio::TwiML->new
    ->Response
    ->Say("All men are brothers,")
      ->parent
    ->Say("Like Jacob and Esau.")
    ->root->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>All men are brothers,</Say>
    <Say>Like Jacob and Esau.</Say>
  </Response>

B<root> is a convenient way to get a handle to the root TwiML object
when you're ready to print.

=head2 to_string( { header => value } )

Returns the object as a string. Unnamed (root) elements will include
the XML declaration entity. If a hashref is supplied, those will be
emitted as RFC 822 headers followed by a blank line.

Example:

  print WWW::Twilio::TwiML->new->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>

while this:

  print WWW::Twilio::TwiML->new
    ->Response
    ->Say("plugh")
    ->root->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>plugh</Say>
  </Response>

If we forget the call to B<root> in the previous example, like this:

  print WWW::Twilio::TwiML->new
    ->Response
    ->Say("plugh")
    ->to_string;

we get:

  <Say>plugh</Say>

because B<to_string> is being applied to the object created by B<Say>,
not B<$tw>.

By specifying a hashref, you can add RFC 822 headers to your
documents:

  $tw = new WWW::Twilio::TwiML;
  $tw->Response->Say('Arf!');
  $tw->to_string({'Content-type' => 'text/xml'});

which returns:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>Arf!</Say>
  </Response>

=head2 parent( object )

Sets the parent of the object; this done automatically by B<add_child>
and B<content>. When no arguments are given, the existing parent
object is returned.

Because B<WWW::Twilio::TwiML> objects chain, B<parent> is useful for
getting the previous object so you can add more content to it:

  WWW::Twilio::TwiML->new
    ->Response
    ->Gather({action => "/process_gather.cgi", method => "GET"})
      ->Say("Please enter your account number.")
        ->parent  ## Say's parent, Gather
      ->parent    ## Gather's parent, Response
    ->Say("We didn't receive any input. Goodbye!");

becomes:

  <Response>
    <Gather action="/process_gather.cgi" method="GET">
      <Say>Please enter your account number.</Say>
    </Gather>
    <Say>We didn't receive any input. Goodbye!</Say>
  </Response>

I<A note on readability>: the author recommends indenting multi-line
chains to show the parent-child relationship. Each time B<parent> is
invoked, the next line should be outdented, as illustrated above.

=head1 PACKAGE VARIABLES

You may control the behavior of B<WWW::Twilio::TwiML> in several ways
by setting package variables described in this section.

=head2 Newlines

You may change the default newline from "\n" to anything else by
setting the I<$NL> package variable:

  local $WWW::Twilio::TwiML::NL = "\r\n";

=head2 Strict mode

B<WWW:Twilio::TwiML> is capable of generating well-formed but invalid
TwiML documents. B<WWW::Twilio::TwiML> uses autoloaded methods to
determine the name of TwiML elements (Response, Say, Dial, Redirect,
etc.); this means that if you specify an incorrectly named method,
your TwiML will be incorrect:

  $tw->Response->Saay('plugh');

B<Saay> is not a valid Twilio TwiML tag and you will not know it until
Twilio's TwiML parser attempts to handle your TwiML document.

You may enable strict checks on the TwiML elements at runtime by
setting two package variables:

=over 4

=item $STRICT

When true, B<WWW::Twilio::TwiML>'s autoloader will look up the
unhandled method call in the B<%TAGS> package variable (below). If the
method name is not in that hash, the autoloader will die with an
"Undefined subroutine" error.

=item %TAGS

Empty by default. When B<$STRICT> is true, this hash will be consulted
to determine whether a method call is a valid TwiML tag or not.

=back

For example:

  local $WWW::Twilio::TwiML::STRICT = 1;
  local %WWW::Twilio::TwiML::TAGS = (Response => 1, Say => 1, Dial => 1);

Now any methods invoked on B<WWW::Twilio::TwiML> objects that are not
B<Response>, B<Say>, or B<Dial> will die with an error. E.g.:

  WWW::Twilio::TwiML->Response->Saay("Let's play Twister!");

generates the following fatal error:

  Undefined subroutine Saay at line 1.

You may wish to use the fast hash creation with hash slices (I learned
this syntax from Damian Conway at a conference some years ago--it's
faster than B<map> over an array for building hashes):

  ## TwiML verbs taken from http://www.twilio.com/docs/api/twiml
  my @tags = qw(Response Say Play Gather Record Sms Dial Number
                Client Conference Hangup Redirect Reject Pause);

  local @WWW::Twilio::TwiML::TAGS{@tags} = (1) x @tags;
  local $WWW::Twilio::TwiML::STRICT = 1;

  ## all method calls in this scope are now strict
  ...

=head1 EXAMPLES

This section demonstrates a few things you can do with
B<WWW::Twilio::TwiML>.

=head2 Example 1

  $t = new WWW::Twilio::TwiML;
  $t->Response->Say({voice => "woman"}, "This is Jenny");
  print $t->to_string({'Content-type' => 'text/xml'});

Output:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say voice="woman">This is Jenny</Say>
  </Response>

=head2 Examples from twilio.com

The following examples are from twilio.com's TwiML documentation,
listed by the primary verb they implement. Assume a TwiML object
I<$tw> for each of these examples has already been created:

  my $tw = new WWW::Twilio::TwiML;

and consequently each example would be printed with:

  print $tw->to_string;

See the F<t/twilio.t> test file distributed with this package for
additional context for these examples.

=over 4

=item Say

  $tw->Response
    ->Say({voice => "woman", loop => "2"}, "Hello");

=item Play

  $tw->Response
    ->Play("http://foo.com/cowbell.mp3");

=item Gather

  $tw->Response
    ->Gather({action => "/process_gather.cgi", method => "GET"})
      ->Say("Enter something, or not")
        ->parent
      ->parent
    ->Redirect({method => "GET"}, "/process_gather.cgi?Digits=TIMEOUT");

=item Record

  $tw->Response
    ->Say("Please leave a message at the beep. \
           Press the star key when finished.")
      ->parent
    ->Record({action => "http://foo.edu/handleRecording.cgi",
              method => "GET",
              maxLength => "20",
              finishOnKey => "*"});
      ->parent
    ->Say("I did not receive a recording");

=item Sms

  $tw->Response
    ->Say("Our store is located at 123 East St.")
      ->parent
    ->Sms({action => "/smsHandler.cgi", method => "POST"},
          "Store location: 123 East St.");

=item Dial

  $tw->Response
    ->Dial
      ->Number("858-987-6543")->parent
      ->Number("415-123-4567")->parent
      ->Number("619-765-4321");

=item Conference

  $tw->Response
    ->Dial
      ->Conference({startConferenceOnEnter => "true",
                    endConferenceOnExit => "true"},
                   "1234");

=item Hangup

  $tw->Response->Hangup;

=item Redirect

  $tw->Response
    ->Dial("415-123-4567")->parent
    ->Redirect("http://www.foo.com/nextInstructions");

=item Reject

  $tw->Response
    ->Reject({reason => "busy"});

=item Pause

  $tw->Response
    ->Pause({length => 5})->parent
    ->Say("Hi there.");

=back

=head2 Other examples

Other examples may be found in the F<t> directory that came with this
package, also available on CPAN.

=head1 COMPATIBILITY

B<WWW::Twilio::TwiML> will likely be forward compatible with all
future revisions of Twilio's TwiML language. This is because method
calls are constructors which generate TwiML objects on the fly.

For example, say Twilio began to support a B<Belch> verb (if only!),
we could take advantage of it immediately by simply calling a B<Belch>
method like this:

  my $tw = new WWW::Twilio::TwiML;
  $tw->Response->Belch('Braaaaaap!');
  print $tw->to_string;

Because there is no B<Belch> method, B<WWW::Twilio::TwiML> assumes you
want to create a node by that name and makes one for you:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Belch>Braaaaaap!</Belch>
  </Response>

If the B<$STRICT> package variable is enabled, all we need to do is
add B<Belch> to our B<%TAGS> hash and we're good to go.

=head1 SEE ALSO

L<WWW::Twilio::API>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
