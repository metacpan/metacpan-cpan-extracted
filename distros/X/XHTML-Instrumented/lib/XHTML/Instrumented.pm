use strict;
use warnings;

package XHTML::Instrumented;

use XHTML::Instrumented::Entry;
use XHTML::Instrumented::Context;

use Carp qw (croak verbose);
use XML::Parser;

=head1 NAME

XHTML::Instrumented - packages to control XHTML

=head1 VERSION

Version 0.092

=cut

our $VERSION = '0.092';

our @CARP_NOT = ( 'XML::Parser::Expat' );

use Params::Validate qw( validate SCALAR SCALARREF BOOLEAN HASHREF OBJECT UNDEF CODEREF );

our $path = '.';
our $cachepath;

sub path
{
    my $self = shift;

    $self->{path} || $path;
}

sub cachepath
{
    my $self = shift;

    $self->{cachepath} || $cachepath || $self->path;
}

sub cachefilename
{
    my $self = shift;
    my $file = $self->cachepath;

    if ($self->{type} || $self->{default_type}) {
	$file .= '/' . $self->{type} || $self->{default_type} if $self->{type} || $self->{default_type};
	$file .= '/' . $self->{name};
	$file .= '.cxi';
    } elsif ($self->{name}) {
        $file .= '/' . $self->{name} . '.cxi';
    } else {
        $file = $self->{filename} . '.cxi';
    }

    return $file;
}

sub import
{
    my $class = shift;
    my %p = validate(@_, {
       path => 0,
       cachepath => 0,
    });

    $path = $p{path};
    $cachepath = $p{cachepath};
}

sub new
{
    my $class = shift;
    my $self = bless { validate(@_, {
        'name' => {
	    type => SCALAR | SCALARREF,
	    optional => 1,
	},
        'type' => {
	    type => SCALAR,
	    optional => 1,
        },
        'default_type' => {
	    type => SCALAR,
	    optional => 1,
        },
        'filename' => {
	    type => SCALAR,
	    optional => 1,
        },
        'filter' => {
	    optional => 1,
	    type => CODEREF,
	},
        'replace_name' => {
	    optional => 1,
	    type => SCALAR,
	},
        'cachepath' => {
	    optional => 1,
	    type => SCALAR,
	},
        'path' => {
	    optional => 1,
	    type => SCALAR,
	},
    })}, $class;

    my $path = $self->path();
    my $type = $self->{type} || '';
    my $name = $self->{name};
    my $filename = $self->{filename};
    my $alt_filename = $self->{filename};

    unless ($filename or ref($name) eq 'SCALAR') {
	$filename = $self->{filename} = "$path/$type/$name";
	my $type = $self->{default_type} || '';
	unless (-f "$filename.html") {
	    $filename = $self->{filename} = "$path/$type/$name";
	}
	unless (-f "$filename.html") {
	    $filename = $self->{filename} = "$path/$name";
	}
	unless (-f "$filename.html") {
	    die "File not found: $filename";
	}
    }

    if ($filename) {
	my $cachefile = $self->cachefilename;

	my @path = split('/', $cachefile);
	pop @path;

        if (-r $cachefile and ( -M $cachefile < -M  $filename . '.html')) {
            require Storable;
	    $self->{parsed} = Storable::retrieve($cachefile);
	} elsif ( -r $filename . '.html') {
	    $self->{parsed} = $self->parse(
		$filename . '.html',
		name => $name,
		type => $self->{type},
		default_type => $self->{default_type},
		replace_name => $self->{replace_name} || 'home',
		path => $self->path,
		cachepath => $self->cachepath,
	    );
	    my $path = '';
	    while (@path) {
	       $path .= shift(@path) . '/';
	       unless ( -d $path ) {
		   mkdir $path or die 'Bad path ' . $path .  " $cachefile @path";
	       }
	    }
	    require Storable;
	    Storable::nstore($self->{parsed}, $cachefile );
	} else {
	    die "File not found: $filename";
	}
    } else {
	unless (ref($name) eq 'SCALAR') {
	    croak "no template for $name [$path/$type/$name.tmpl]" unless (-f "$path/$type/$name.tmpl");
	}
	$self->{parsed} = $self->parse(
	    $name,
	    name => '_scalar_',
	    replace_name => $self->{replace_name} || 'home',
	    path => $self->path,
	    cachepath => $self->cachepath,
	);
    }

    $self;
}

# helper functions

sub loop
{
    my $self = shift;
    my %p = validate(@_, {
       headers => 0,
       data => 0,
       inclusive => 0,
       default => 0,
    });
    require XHTML::Instrumented::Loop;

    XHTML::Instrumented::Loop->new(%p);
}

sub get_form
{
    my $self = shift;

    require XHTML::Instrumented::Form;
    XHTML::Instrumented::Form->new(@_);
}

sub replace
{
    my $self = shift;
    my %p = validate(@_, {
       args => 0,
       text => 0,
       src => 0,
       replace => 0,
       remove => 0,
       remove_tag => 0,
    });
    require XHTML::Instrumented::Control;
    XHTML::Instrumented::Control->new(%p);
}

sub args
{
    my $self = shift;

    $self->replace(args => { @_ });
}

our @unused;

# the main function
sub __filename
{
    my $self = shift;
    my ($path, $type, $name);
    unless (-f "$path/$type/$name.tmpl") {
	$type = $self->{default_type} || 'default';
    }
    die "no template for $name [$path/$type/$name.tmpl]" unless (-f "$path/$type/$name.tmpl");
    my $file = "$path/$type/$name.tmpl";
}	

sub parse
{
    my $self = shift;
    my $data = shift;

    @unused = ();
    my $parser = new XML::Parser::Expat(
	NoExpand => 1,
	ErrorContext => 1,
	ProtocolEncoding => 'utf-8',
    );
    $parser->setHandlers('Start' => \&_sh,
			 'End'   => \&_eh,
			 'Char'  => \&_ch,
			 'Attlist'  => \&_ah,
			 'Entity' => \&_ah,
			 'Element' => \&_ah,
			 'Default' => \&_ex,
			 'Unparsed' => \&_cm,
			 'CdataStart' => \&_cds,
			 'CdataEnd' => \&_cde,
			);
    $parser->{_OFF_} = 0;
    $parser->{__filter__} = $self->{filter};
    $parser->{__ids__} = {};
    $parser->{__idr__} = {};
    $parser->{__args__} = { @_ };

    $self->{_parser} = $parser;

    my $type = $self->{type};
    my $name = $self->{name};
    my %hash = (@_);

    $parser->{__data__} = {};  # FIXME this may need to be set
    $parser->{__top__} = XHTML::Instrumented::Entry->new(
	tag => '__global__',
	flags => {},
	args => {},
    );
    $parser->{__context__} = [ $parser->{__top__} ];

    if (ref($data) eq 'SCALAR') {
        my $html = ${$data};
	eval {
	    $parser->parse($html);
	};
	if ($@) {
	    die "$@";
	}
    } else {
        my $filename = $data;
	eval {
	    $parser->parsefile($filename);
	};
	if ($@) {
	    croak "$@ $filename";
	}
    }
    bless({
        idr => $parser->{__idr__},
	data => $parser->{__top__}->{data}
    }, 'XHTML::Intramented::Parsed');
}

sub _get_tag
{
    my $tag = shift;
    my $start = shift;
    my $data = $start;

    for my $element (@$data) {
	next unless ref($element);

	return $element if $element->{tag} eq $tag;

	my $data = _get_tag($tag, $element->{data});
	return $data if $data;
    }
    undef;
}

sub get_tag
{
    my $self = shift;
    my $tag = shift;

    my $data = _get_tag($tag, $self->{parsed}{data});

    return $data;
}

sub instrument
{
    my $self = shift;
    my %p = validate(@_, {
        content_tag => 1,
        control => {
	},
    });
    my $data = {};
    my $ret;

    $data->{data} = [ $self->{parsed}{data} ];

    if (my $tag = $p{content_tag}) {
        $data = _get_tag($tag, $self->{parsed}{data});
	$data->{data} = [ @{$self->{parsed}{data}} ] unless $data;
    }
    my $hash = $p{control} || {};

    for my $element ( @{$data->{data}} ) {
        if (ref($element)) {
	    $ret .= $element->expand(
	        context => XHTML::Instrumented::Context->new(
		    hash => $hash,
		),
	    );
	} else {
	    $ret .= $element;
	}
    }

    $ret;
}

sub head 
{
    my $self = shift;
    my %hash = (@_);

    return $self->instrument(
        content_tag => 'head',
	control => { %hash },
    );
}

sub output
{
    my $self = shift;
    my %hash = (@_);

    return $self->instrument(
        content_tag => 'body',
	control => { %hash },
    );
}

our $level = 0;

use Encode;

sub _fixup
{
    my @ret;
    for my $data (@_) {
        $data =~ s/&/&amp;/g;
        my $x = $data;

	push @ret, $data;
    }
    @ret;
}

sub _ex
{
    my $self = shift;

    push(@{$self->{__context__}[-1]->{data}}, @_);
}

sub _cm
{
    die "Don't know how to handle Unparsed Data";
}

sub _cds
{

}

sub _cde
{

}

sub _sh
{
    my $self = shift;
    my $tag = shift;
    my %args = @_;

    my $top = $self->{__context__}->[-1];

    if (my $code = $self->{__filter__}) {
        $code->(
	   tag => $tag,
	   args => \%args,
	);
    }

    for my $key (keys %args) {
	my %hash = %{$self->{__data__}};
	if ($args{$key} =~ /\@\@([A-Za-z][A-Za-z0-9_-][^.@]*)\.?([^@]*)\@\@/) {
	    die q(Can't do this);
	}
	$args{$key} =~ s/\@\@([A-Za-z][A-Za-z0-9_-][^.@]*)\.?([^@]*)\@\@/
	    my @extra = split('\.', $2);
	    my $name = $1;
	    my $extra = $2;
	    my $type = $hash{$1};
	    if (defined $type) {
	       $type;
	    } else {
	       qq(-- $1 --);
	    }
	    /xge;
    }
    my %local = ();

    my $child = $top->child(
	tag => $tag,
	args => \%args,
    );
    if (my $id = $child->id) {
	warn "Duplicate id: $id" if exists $self->{__ids__}{$id};
        $self->{__ids__}{$args{id}}++;
        $self->{__idr__}{$id} = $child;
    }
    if (exists($self->{_inform_}) && $child->name && $child->id) {
        $self->{_inform_}->{_ids_}{$child->id} = $child->name;
        $self->{_inform_}->{_names_}{$child->name} = $child->id;
    }
    if (exists($self->{_inform_}) && $child->name) {
	my $form_id = $self->{_inform_id_};
	if ($form_id) {
	    $self->{_inform_ids_}{$form_id}{$child->name} = $tag;
	} else {
	    warn "Fix this";
	}
    }
    push(@{$self->{__context__}},
        $child,    
    );
    if ($tag eq 'form') {
	$self->xpcroak('embeded form') if ($self->{_inform_});
	$self->{_inform_} = $child;
	if (my $id = $args{id} || $args{name}) {
	    $self->{_inform_id_} = $id;
	    $self->{_inform_ids_}{$id} = {};
	}
    }
    return undef;
}

{
    package
        XML::Parser::Expat;

    sub clone {
        my $self = shift;
	my $parser = new XML::Parser::Expat(
	    NoExpand => $self->{'NoExpand'},
	    ErrorContext => $self->{'ErrorContext'},
	    ProtocolEncoding => $self->{'ProtocolEncoding'},
	);
	$parser->{__data__} = {};
	$parser->{__top__} = XHTML::Instrumented::Entry->new(
	    tag => 'div',
	    flags => {},
	    args => {},
	);
	$parser->{__context__} = [ $parser->{__top__} ];
        return $parser;
    }
}

sub _eh
{
    my $self = shift;
    my $tag = shift;
    my $current = pop(@{$self->{__context__}});
    my $parent = $self->{__context__}->[-1];

    my $args = { $current->args };

    die "mismatched tags $tag " . $current->tag unless $tag eq $current->tag;

    if ($args->{class} && grep(/:removetag/, split('\s+', $args->{class}))) {
	$parent->append(@{$current->{data} || []});
	return;
    }
    if ($args->{class} && grep(/:remove/, split('\s+', $args->{class}))) {
	return;
    }

    if ($args->{class} && (my @names = grep(/:replace/, split('\s+', $args->{class})))) {
	my $out;
	die "Only one replace per tag" if @names != 1;

	my $gargs = $self->{__args__};
	my $default = $gargs->{default_replace};
	my ($name, $file) = split('\.', $names[0]);

	$file ||= $self->{__args__}->{replace_name} || die;

	if ($self->{__args__}{name} ne $file) {
	    $out = XHTML::Instrumented->new(
	       path  => $self->{path},
	       cachepath => $self->{cachepath},
	       %{$gargs},
	       name => $file,
	    );
	} else {
	}

	if ($out) {
	    my $id = $args->{id};
die 'Need an id for :replace' unless defined $id;
die 'Replacement not found' unless $out->{parsed}{idr}{$id};

	    $current = $out->{parsed}{idr}{$id};
	}
    }

    $parent->append($current);

    if ($tag eq 'form') {
	delete $self->{_inform_};
    }
}

sub _ah
{
    my $self = shift;

    die q(We don't do these here);
}

sub _ch
{
    my $self = shift;
    my $context = $self->{__context__}->[-1];
    my $data = shift;
    my %hash = %{$self->{__data__}};

    my @ret;

    $data = join('', _fixup($data));

    if ($context->{flags} & 1) {
        ;
    } else {
        my @x = split(/(\@\@[A-Za-z][A-Za-z0-9_-][^.@]*\.?[^@]*\@\@)/, $data);
	if (@x > 1) {
	    for my $p (@x) {
		if ($p =~ m/\@\@([A-Za-z][A-Za-z0-9_-][^.@]*)\.?([^@]*)\@\@/) {
		    push @ret,
		    XHTML::Instrumented::Entry->new(
			tag => '__special__',
			flags => {rs => 1},
			args => {},
			data => [ "-- $p --" ],
			id => $1,
		    );
		} else {
		    push @ret, $p;
		}
	    }
	} else {
	    push @ret, $data;
	}
	$data =~ s/\@\@([A-Za-z][A-Za-z0-9_-][^.@]*)\.?([^@]*)\@\@/
	    my @extra = split('\.', $2);
	    my $name = $1;
	    my $extra = $2;
	    my $type = $hash{$1};
	    XHTML::Instrumented::Entry->new(
		tag => '__special__',
		flags => {},
		args => {},
		id => $name,
	    );
	    /xge;
    }
    push(@{$context->{data}}, @ret);
}

1;
__END__

=head1 DESCRIPTION

This package takes valid XHTML as input and outputs valid XHTML that may
be changed in several ways.

=head1 SYNOPSIS

 use XHTML::Instrumented;

 my $dom = XHTML::Instrumented->new(
    path => '/var/www/html',
    type => 'nl',
    default_type => 'en',
    name => 'index',

    cachepath => '/tmp/the_cache_path/',

 # run time
    replace_name => 'home',

 # compile time

    filter => sub {
        my $tag = shift;
	my $args = shift;
	if (my $path = $args->{href}) {

	}
    },
 };

This will load the file C</var/www/html/nl/index.html> or if that is not found
C</var/www/html/en/index.html> or an exception will be thrown.

You can also directly input html, although this is mainly used for testing.

 use XHTML::Instrumented;

 my $dom = XHTML::Instrumented->new(
    name => \"<html><head></head><body>hi</body></html>",
 );

You can also directly give a complete filename.

 use XHTML::Instrumented;

 my $dom = XHTML::Instrumented->new(
    filename => '/var/www/html/en/index.html',
 );

=head1 API

=head2 Constructor

=over

=item new

The new() constructor method instantiates a new C<XHTML::Intrumented> object.
The template is either compiled or loaded as well. 

The parameters to the constructor are describe in more detail in the
descriptions of the methods with the same name 
path() name() type() default_type() extension() filename() cachepath() replace_name()

There is also a C<filter> parameter: it is a call-back that allows the
arguments to C<tags> to be modified at compile time.

Get a XHTML::Instrumented object.

=back

=head2 Accessor Methods

=over

=item filename

This the complete name (path and filename) of the file that was compiled
to create the object. If the input was not from a file this will be undefined.
This is either build up from the path, type or default_type, name and extension
values or is set directly by the constructor.

=item path

This is the base path to the input file. It is set by an argument to the constructor.

=item name

This is the base name of the input file. It is set by an argument to the constructor.

=item type

This is the default type of the input file. This is really just an extra element to the 
path. It is set by an argument to the constructor.

=item default_type

If the file is not found using the C<type> then this is tried.

=item extension

This is the extension to the file.  It defaults to ".html' and can be set by the constructor.

=item cachepath

This is the base directory where the I<cache file> will be stored. It is
set by an argument to the constructor.

=item cachefilename

This is the full name of the I<cache file>.

=item replace_name

This is the default name of the file that will be used by the I<:replace> operator.

=back

=head2 Methods

=over

=item output

This returns the modified xhtml.

=item head

This returns the html between the Head tags!

=item get_form

This returns a form object.

=item loop()

Get a C<loop> control object.

   headers => [array of headers]
   data => [arrays of data]
   default => default value for any undefined data
   inclusive => include the tag that started the loop

inclusive is normally controlled in the template.

=item replace

This return a general control object. I can control 4 actions:

=over

=item replace the arguments to a tag.

=item replace the content of a tag.

=item remove the tag it self.

=back

=item args

C<args> is a helper function.  It is the same as:

 replace(args => { @_ });

=back

=head2 Functions

=over

=item get_tag('tag')

Return a list of XHTML::Intramented::Entry objects that have type 'tag';

=back

=head2 Functions

Both of these functions are used internally by the XHTML::Instrumented
and are only listed here for completeness.

=over

=item parse(input)

This causes the input to be parsed.

if I<input> is a string it is assumed to be a filename.
If I<input> is a SCALAR is is treated as HTML;

=item instrument()

This function take the template and the control structure and returns a block of XHTML.

=back


=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007-2008 G. Allen Morris III, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
