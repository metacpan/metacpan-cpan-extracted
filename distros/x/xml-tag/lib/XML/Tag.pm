#! /usr/bin/perl
package XML::Tag;
use strict;
use warnings;
our $VERSION = '0.5';

# ABSTRACT: lib to build builders for xml content

sub import {
    shift;
    my ( $caller ) = caller;
    no strict 'refs';
    my @tags = do {
        if (@_) {@_}
        else { qw< tag empty_tag ns as_xml > }
   };
   for (@tags) { *{"$caller\::$_"} = \&{$_} }
}

sub tag {
    my ( $tag, $code, $attrs ) = @_;
    my %attr = $attrs ? %$attrs : ();
    my @data = $code ? $code->() : ();

    # TODO: what if blessed ? 
    while (my $ref = ref $data[0] ) {
	$ref eq 'HASH' or die "$ref cant hold xml attributes";
	my $news = shift @data;
        while ( my ( $k, $v ) = each %$news ) {
            if ( exists $attr{$k} ) {
                if ( ref $attr{$k} ) { push @{$attr{$k}}, $v }
                else { $attr{$k} = [$attr{$k}, $v] }
            }
            else { $attr{$k} = [ $v ] }
        }
    }

    my @content = 
    ( '<'
    , $tag
    ,   ( keys %attr
	    ? ( map {
		# yeah: i know that this code can lead to stuttering xml like
		# class="foo foo foo bar"
		# frankly ? i don't care :-)
		' '
		, $_
		, '='
		, ( map {ref $_ ? qq{"@$_"} : qq("$_") } $attr{$_} )
		} keys %attr )
	    : ()
	)
    ,   ( @data
	    ? ( '>', @data, '</', $tag , '>')
	    : '/>'
	)
    );

    if (wantarray) { @content }
    else { join '', @content }

}

sub empty_tag {
    my ( $tag, $attrs ) = @_;
    $attrs
    ? tag $tag, 0, $attrs
    : tag $tag;
}

sub empty_tag_ {
    my $tag = shift;
    @_
    ? tag $tag, 0, +{@_}
    : tag $tag;
}


sub ns {
    my ( $ns, $pkg ) = do {
        my $first = shift;
        if ( ref $first ) { map {$_||=''} @$first }
        else { $first, $first } # xml ns = perl package
    };
    $pkg ||= caller;
    $ns and $ns.=':'; # add namespace separator

    $_//='' for $ns, $pkg;

    for my $spec ( @_ ) {
        my ( $sub, $tag ) = do {
            if ( ref $spec ) { @$spec }
            else { $spec, $spec }
        };
        no strict 'refs';
        *{"${pkg}::$sub"} = sub (&) { tag "$ns$tag", @_ }
    }
}

sub as_xml (_);
sub as_xml (_) {
    my $entry = shift;
    my @render;
    while ( my ($tag,$v) = each %$entry ) {
        push @render
        , "<$tag>"
        , ( ref $v ? as_xml $v : $v )
        , "</$tag>"
    };
    join '', @render;
}

1;

=head1 XML::Tag in short


=head1 Teaser examples

C<XML::Tag> takes carre about XML and perl namespaces as well as empty tags. Those examples don't.

=head2 Use an existing tagset 





=head2 Create your own



First,

    package XML::Tag::Sympa;
    use Exporter 'import';
    use XML::Tag;

    BEGIN {
        our @EXPORT = qw< 
        description email env gecos host language list
        listname moderator name owner owner_include port
        pwd query shared_edit shared_read source
        sql status subject topic type user >;

        ns '' => @EXPORT;
    };

    1;

now every keywords of C<@EXPORT> are builders (see the documentation below), you can use them as follow: 

    use XML::Tag::Sympa;
    print '<?xml version="1.0">'
    , description {
        email  { 'dave.null@example.com' },
        gecos  { 'Dave Null' },
        status { 'MIA' }, 
        description { +{ lang => "en" },
            "Dave Null is not a number"
        }
    };

The output is

        <?xml version="1.0"><description><email>dave.null@example.com</email><gecos>Dave Null</gecos><status>MIA</status><description lang="en">Dave Null is not a number</description></description>

now extra-space, or indent and this is a feature (please see the C<FAQ>).

I really encourage you to send me your 
You can also 




=head1 XML::Tag, a simple XML builder

an XML Builder is a function that generate a rendered html tag.

    use XML::Tag::html5;
    print br;

    use XML::Tag::html5;
    print br;

, optionnally taking a block as argument,

that render a an xml tag in memory. When possible,
the function is named on the tag to generate. (See grails taglib for example).



Builders are a set of helpers using

to generate the tag content. I see 3 major gains
using this strategy over templating systems:

=over 2

=item *

this is 

keep the power of perl in your hands (don't abuse it and respect at least
an MVC separation)


=item *

don't be WYSIWYG. When i write code, i need indentations and line feeds
to make things readable. All those extra stuff must disapear in the final
result because they are useless and anoying when you manage to control spaces
with CSS.

=item * 

stay confident about the quality of generated code: as long as they
compiles, the helpers render bug free xml (WARNING: the quality of all PCDATA,
attribute values and schemas is *your* job)

=back

L<see how builders works|http://docs.codehaus.org/display/GROOVY/How+Builders+Work>
or see it in action:

To render this text on C<STDIN>.

    <!doctype html><html><head><title lang="fr">my personal homepage</title></head></html> 

you can use directly the C<tag()> function from XML::Tag 

    use XML::Tag;
    use Modern::Perl;

    print '<!doctype html>'
    , tag html => sub {
        tag head => sub {
            tag title => sub { +{lang => 'fr'}, "my personal homepage" }
        }
    } 

you can use the C<ns()> function from XML::Tag to generate the helpers

    use XML::Tag;
    use Modern::Perl;

    BEGIN {
        ns '' # use the default namespace
        , qw< html head title > 
    }

    print '<!doctype html>', html {
        head {
            title { +{lang => 'fr'}, "my personal homepage" }
        }
    }

you can even use a ready to use set of helpers

    use XML::Tag::html5;
    print '<!doctype html>', html {
        head {
            title { +{lang => 'fr'}, "my personal homepage" }
        }
    }

=head2 XML::Tag functions

=head3 tag

=head3 ns

=head3 tag $name, $content, $attrs

the parameters of tag are 

=over 2

=item *

$name: the name of the tag

=item * 

$content: 

a sub returning th

    * content sub
    * a hashref with the list of default attributes for the tag 

=item *

$name ??? 

=back

    perl -MXML::Tag -E '
        print "($_)" for tag title => sub { "content" },  +{qw(class test)};
    '

    (<)(title)( )(class)(=)("test")(>)(content)(</)(title)(>)


    tag title => sub { "content" },  +{qw(class test)}
    tag title => sub { +{qw(class test)}, "content" }

    use XML::Tag;
    print for tag title => sub { "content" },  +{qw(class test)};


    use XML::Tag;
    print for tag title => sub { "content" },  +{qw(class test)};

    use XML::Tag;
    tag title => sub { "content" },  +{qw(class test)}
    tag title => sub { +{qw(class test)}, "content" }


the content sub returns a list, the first elements of the lists are 

    use Modern::Perl;
    use XML::Tag;

    sub foo (&) { tag foo => @_, {qw< isa foo >} }

    print foo{
        + {qw< class bar id bang >}
        , {qw< style text-align:center >}
        , "this is "
        , "the content"
    };

=head2 how to build tag list

    extract_elements () {
        xmlstarlet sel -T -t -m '//xs:element/@name' -v . -n "$@"
    }

    schema=http://dublincore.org/schemas/xmls/simpledc20021212.xsd
    curl -ls "$schema" | extract_elements

=head1 FAQ

=head2 how render indented xml? 

there is no way to indent the things as i really 

=over 1

=item *

wanted to keep this module as simple as possible.

=item *

strongly believe there is no other good way to render xml (you need indentation
to debug? use a indentation tool or any appropriate xml renderer like a web
browser).

=back
