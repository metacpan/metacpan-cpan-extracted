package URI::SmartURI;

use Moose;
use mro 'c3';

=head1 NAME

URI::SmartURI - Subclassable and hostless URIs

=head1 VERSION

Version 0.032

=cut

our $VERSION = '0.032';

=head1 SYNOPSIS

    my $uri = URI::SmartURI->new(
        'http://host/foo/',
        { reference => 'http://host/bar/' }
    );

    my $hostless = $uri->hostless; # '/foo/'

    $hostless->absolute; # 'http://host/foo/'

    $uri->relative; # '../foo/'

=cut

use URI;
use URI::URL;
use URI::QueryParam;
use File::Find::Rule;
use File::Spec::Functions qw/splitpath splitdir catfile catpath/;
use List::MoreUtils 'firstidx';
use Scalar::Util 'blessed';
use List::Util 'first';
use Exporter ();
use Class::C3::Componentised;

use namespace::clean -except => 'meta';

has 'obj'           => (is => 'ro', isa => 'Object');
has 'factory_class' => (is => 'ro', isa => 'ClassName');
has 'reference'     => (is => 'rw', isa => 'Maybe[Str]');

=head1 DESCRIPTION

This is a sort of "subclass" of L<URI> using delegation with some extra methods,
all the methods that work for L<URI>s will work on these objects as well.

It's similar in spirit to L<URI::WithBase>.

It's also completely safe to subclass for your own use.

=head1 CONSTRUCTORS

=head2 URI::SmartURI->new($str,
    [$scheme|{reference => $ref, scheme => $scheme}])

Takes a uri $str and an optional scheme or hashref with a reference uri
(for computing relative/absolute URIs) and an optional scheme.

    my $uri = URI::SmartURI->new('http://dev.catalyst.perl.org/');

    my $uri = URI::SmartURI->new('/dev.catalyst.perl.org/new-wiki/', 'http');

    my $uri = URI::SmartURI->new(
        'http://search.cpan.org/~jrockway/Catalyst-Manual-5.701003/', 
        { reference => 'http://search.cpan.org/' }
    );

The object returned will be blessed into a scheme-specific subclass, based on
the class of the underlying $uri->obj (L<URI> object.) For example,
URI::SmartURI::http, which derives from L<URI::SmartURI> (or
$uri->factory_class if you're subclassing.)

=cut

sub new {
    my ($class, $uri, $opts) = @_;

    $opts = { scheme => $opts }
        unless ref($opts) && ref($opts) eq 'HASH';

    my $self = {
        obj       => URI->new($class->_deflate_uris($uri, $opts->{scheme})),
        reference => $opts->{reference},
        factory_class => $class
    };

    bless $self, $class->_make_uri_class(blessed $self->{obj}, 1);
}

=head2 URI::SmartURI->new_abs($str, $base_uri)

Proxy for L<URI>->new_abs

=cut

sub new_abs {
    my $class = shift;

    my $self = {
        obj => URI->new_abs($class->_deflate_uris(@_)),
        factory_class => $class
    };

    bless $self, $class->_make_uri_class(blessed $self->{obj}, 1);
}

=head2 URI::SmartURI->newlocal($filename, [$os])

Proxy for L<URI::URL>->newlocal

=cut

sub newlocal {
    my $class = shift;

    my $self = {
        obj => URI::URL->newlocal($class->_deflate_uris(@_)),
        factory_class => $class
    };

    bless $self, $class->_make_uri_class(blessed $self->{obj}, 1);
}

=head1 METHODS

=head2 $uri->hostless

Returns the URI with the scheme and host parts stripped.

=cut

sub hostless {
    my $uri = $_[0]->clone;

    $uri->scheme('');
    $uri->host('');
    $uri->port('');

    $uri->factory_class->new(($uri =~ m!^[/:]*(/.*)!), $_[0]->_opts);
}

=head2 $uri->reference

Accessor for the reference URI (for relative/absolute below.)

=head2 $uri->relative

Returns the URI relative to the reference URI.

=cut

sub relative { $_[0]->rel($_[0]->reference) }

=head2 $uri->absolute

Returns the absolute URI using the reference URI as base.

=cut

sub absolute { $_[0]->abs($_[0]->reference) }

=head2 ""

stringification works, just like with L<URI>s

=head2 ==

and == does as well

=cut

use overload
    '""' => sub { "".$_[0]->obj },
    '==' =>
        sub { overload::StrVal($_[0]->obj) eq overload::StrVal($_[1]->obj) },
    fallback => 1;

=head2 $uri->eq($other_uri)

Explicit equality check to another URI, can be used as
URI::SmartURI::eq($uri1, $uri2) as well.

=cut

sub eq {
    my ($self, $other) = @_;

# Support URI::eq($first, $second) syntax. Not inheritance-safe :(
    $self = blessed $self ? $self : __PACKAGE__->new($self);

    return $self->obj->eq(ref $other eq blessed $self ? $other->obj : $other);
}

=head2 $uri->obj

Accessor for the L<URI> object methods are delegated to.

=head2 $uri->factory_class

The class whose constructor was called to create the $uri object, usually
L<URI::SmartURI> or your own subclass. This is used to call class (rather
than object) methods.

=cut

# The gory details

sub AUTOLOAD {
    use vars qw/$CAN $AUTOLOAD/;
    no strict 'refs';
    my $self   = $_[0];
# stolen from URI sources
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);

    return if ! blessed $self || ! blessed $self->obj
                              || $method eq 'DESTROY'
                              || ! $self->obj->can($method);

    my $class  = $self->factory_class;

    my $sub    = blessed($self)."::$method";

    *{$sub} = sub {
        my $self = shift;
        my @res;
        if (wantarray) {
            @res    = $self->obj->$method($class->_deflate_uris(@_));
        } else {
            $res[0] = $self->obj->$method($class->_deflate_uris(@_));
        }
        @res = $class->_inflate_uris(
            \@res,
            $method ne 'scheme' ? $self->_opts : {}
        );

        return wantarray ? @res : $res[0];
    };

    Class::C3::reinitialize;
    
    $CAN ? \&$sub : goto &$sub;
}

sub can { # of PORK BRAINS in MILK GRAVY, yum!!!
    no strict 'refs';
    use vars qw/$CAN $AUTOLOAD/;
    my ($self, $method) = @_;

    if ($method eq 'can') {
        return \&can;
    }

    my $existing = eval { $self->next::method($method) };
    undef $@;
    return $existing if $existing;

    local $AUTOLOAD = ref($self)."::$method";
    local $CAN      = 1;

    $self->$method
}

# Preload some URI classes, the ones that come in files anyway,
# but only if asked to.
sub import {
    no strict 'refs';
    my $class = shift;

    return unless $_[0] && $_[0] eq '-import_uri_mods';

# File::Find::Rule is not taint safe, and Module::Starter suggests running
# tests in taint mode. Thanks for helping me with this one Somni!!!
# UPDATE: I turned off taint in tests because it breaks local::lib
    {
        no warnings 'redefine';
        my $getcwd = \&File::Find::Rule::getcwd;
        *File::Find::Rule::getcwd = sub { $getcwd->() =~ m!^(.*)\z! };
        # What are portably valid characters in a directory name anyway?
    }

    my @uri_pms = grep !/SmartURI\.pm\z/,
        File::Find::Rule->extras({untaint => 1})->file->name('*.pm')
        ->in( File::Find::Rule->extras({untaint => 1})->directory
            ->maxdepth(1)->name('URI')->in(
                grep { !ref($_) && -d $_ } @INC
            )
        );

    my @new_uri_pms;

    for (@uri_pms) {
        my ($vol, $dir, $file) = splitpath $_;

        my @dir          = grep $_ ne '', splitdir $dir;
        my @rel_dir      = @dir[(firstidx { $_ eq 'URI' } @dir) ..  $#dir];
        my $mod          = join '::' => @rel_dir, ($file =~ /^(.*)\.pm\z/);

        my $new_class    = $class->_make_uri_class($mod, 0);

        push @new_uri_pms, (join '/' => (split /::/, $new_class)) . '.pm';
    }

# HLAGHALAGHLAGHLAGHLAGH
    push @INC, sub {
        if (first { $_ eq $_[1] } @new_uri_pms) {
            open my $fh, '<', \"1;\n";
            return $fh;
        }
    };

    Class::C3::reinitialize;
}

=head1 INTERNAL METHODS

These are used internally by SmartURI, and are not interesting for general use,
but may be useful for writing subclasses.

=head2 $uri->_opts

Returns a hashref of options for the $uri (reference and scheme.)

=cut

sub _opts { +{
    reference => $_[0]->reference || undef,
    scheme => $_[0]->scheme || undef
} }


=head2 $class->_resolve_uri_class($uri_class)

Converts, eg., "URI::http" to "URI::SmartURI::http".

=cut

sub _resolve_uri_class {
    my ($class, $uri_class) = @_;

    (my $new_class = $uri_class) =~ s/^URI::/${class}::/;

    return $new_class;
}

=head2 $class->_make_uri_class($uri_class)

Creates a new proxy class class for a L<URI> class, with all exports and
constructor intact, and returns its name, which is made using
_resolve_uri_class (above).

=cut

sub _make_uri_class {
    my ($class, $uri_class, $re_init_c3) = @_;

    my $new_uri_class = $class->_resolve_uri_class($uri_class);

    no strict 'refs';
    no warnings 'redefine';

    unless (%{$new_uri_class.'::'}) {
        Class::C3::Componentised->inject_base(
            $new_uri_class, $class, 'Exporter'
        );

        *{$new_uri_class.'::new'} = sub {
            eval "require $uri_class";
            bless {
                obj => $uri_class->new($class->_deflate_uris(@_[1..$#_])),
                factory_class => $class
            }, $new_uri_class;
        };

        *{$new_uri_class.'::import'} = sub {
            shift; # $class

            eval "require $uri_class;";
            # URI doesn't use tags, thank god...
            my @vars = grep /^\W/, @_;
            my @subs = (@{$uri_class.'::EXPORT'}, grep /^\w/, @_);

            if (@vars) {
                my $import = $uri_class->can('import');
                @_ = ($uri_class, @vars);
                goto &$import;
            }

            for (@subs) {
                my $sub   = $uri_class."::$_";
                my $proto = prototype $sub;
                $proto    = $proto ? "($proto)" : '';
                eval qq{
                    sub ${new_uri_class}::$_ $proto {
                        my \@res;
                        if (wantarray) {
                            \@res    = &${sub}($class->_deflate_uris(\@_));
                        } else {
                            \$res[0] = &${sub}($class->_deflate_uris(\@_));
                        }

                        \@res = $class->_inflate_uris(\\\@res);

                        return wantarray ? \@res : \$res[0];
                    }
                };
            }

            @{$new_uri_class."::EXPORT_OK"} = @subs;

            local $^W; # get rid of more redefined warnings
            $new_uri_class->export_to_level(1, $new_uri_class, @subs);
        };

        Class::C3::reinitialize if $re_init_c3;
    }

    return $new_uri_class;
}

=head2 $class->_inflate_uris(\@rray, $opts)

Inflate any L<URI> objects in @rray into URI::SmartURI objects, all other
members pass through unharmed. $opts is a hashref of options to include in the
objects created.

=cut

sub _inflate_uris {
    my $class = shift;
    my ($args, $opts) = @_;

    my @res = map { blessed($_) && blessed($_) =~ /^URI::/ ?
            bless {
                    obj => $_,
                    factory_class => $class,
                    (defined $opts ? %$opts : ())
                  },
                $class->_make_uri_class(blessed $_, 1)
          :
                $_
    } @$args;
    @res ? @res == 1 ? $res[0] : @res : ();
}

=head2 $class->_deflate_uris(@rray)

Deflate any L<URI::SmartURI> objects in @rray into the L<URI> objects
they are proxies for, all other members pass through unharmed.

=cut

sub _deflate_uris {
    my $class = shift;
    my @res   = map { blessed $_ && $_->isa($class) ?  $_->{obj} : $_ } @_;
    @res ? @res == 1 ? $res[0] : @res : ();
}

=head1 MAGICAL IMPORT

On import with the C<-import_uri_mods> flag it loads all the URI .pms into your
class namespace.

This works:

    use URI::SmartURI '-import_uri_mods';
    use URI::SmartURI::WithBase;
    use URI::SmartURI::URL;

    my $url = URI::SmartURI::URL->new(...); # URI::URL proxy

Even this works:

    use URI::SmartURI '-import_uri_mods';
    use URI::SmartURI::Escape qw(%escapes);

It even works with a subclass of L<URI::SmartURI>.

I only wrote this functionality so that I could run the URI test suite without
much modification, it has no real practical value.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-smarturi at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-SmartURI>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::SmartURI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-SmartURI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-SmartURI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-SmartURI>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-SmartURI>

=back

=head1 SEE ALSO

L<Catalyst::Plugin::SmartURI>, L<URI>, L<URI::WithBase>

=head1 ACKNOWLEDGEMENTS

Thanks to folks on freenode #perl for helping me out when I was getting stuck,
Somni, revdiablo, PerlJam and others whose nicks I forget.

=head1 AUTHOR

Rafael Kitover, C<< <rkitover at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Rafael Kitover

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

'LONG LIVE THE ALMIGHTY BUNGHOLE';

# vim: expandtab shiftwidth=4 tw=80:
