use strict;
use warnings;

package Util::H2O::More;
use parent q/Exporter/;
use Util::H2O ();

our @EXPORT_OK = (qw/baptise opt2h2o h2o o2h d2o o2d o2h2o ini2h2o ini2o h2o2ini HTTPTiny2h2o o2ini Getopt2h2o ddd dddie tr4h2o yaml2h2o yaml2o/);
our $VERSION = q{0.4.3};

use feature 'state';

# quick hack to export h2o, uses proper
# Util::H2O::h2o called with full namespace
sub h2o {
    return Util::H2O::h2o @_;
}

# maintains basically a count to create non-colliding
# unique $pkg names (basically what Util::H2O::h2o does
# if $pkg is not specified using -class
# monatomically increasing uuid
sub _uuid {
    state $uuid = 0;
    return ++$uuid;
}

# non-recursive option
sub baptise ($$@) {
    my ( $ref, $pkg, @default_accessors );
    my $pos0 = shift;

    # check pos0 for '-recurse'
    if ( $pos0 eq q{-recurse} ) {
        ( $ref, $pkg, @default_accessors ) = @_;
    }
    else {
        $ref = $pos0;
        ( $pkg, @default_accessors ) = @_;
    }

    my $self;
    my $real_pkg = sprintf qq{%s::_%s}, $pkg, _uuid;

    # uses -isa to inherit from $pkg; -class to bless with a package name
    # derived from $pkg
    if ( $pos0 eq q{-recurse} ) {
        $self = h2o -recurse, -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }
    else {
        $self = h2o -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }

    return $self;
}

# make keys legal for use as accessor, provides original keys via "__og_keys" accessor
sub tr4h2o($) {
    my $hash_ref    = shift;
    my $new_hashref = {};

    # List::Util::pairmap was not happy being require'd for some reason
    # so iterate and replace keys explicitly; store original key in resulting
    # hashref via __og_keys
    foreach my $og_k ( keys %$hash_ref ) {
        my $k = $og_k;
        $k =~ tr/a-zA-Z0-9/_/c;
        $new_hashref->{$k} = $hash_ref->{$og_k};

        # save old key via __og_keys
        $new_hashref->{__og_keys}->{$k} = $og_k;
    }
    return $new_hashref;
}

# preconditioner for use with Getopt::Long flags; returns just the flag name given
# a list of option descriptors, e.g., qw/option1=s option2=i option3/;

# Getopt to keys
sub opt2h2o(@) {
    my @getopt_def = @_;
    my @flags_only = map { m/([^=!|\s]+)/g; $1 } @getopt_def;
    return @flags_only;
}

# wrapper around opt2h2o (yeah!)
sub Getopt2h2o(@) {
    my $autoundef;
    if ( @_ && $_[0] && !ref$_[0] && $_[0]=~/^-autoundef/ ) {
      $autoundef = shift;
    }
    my ( $ARGV_ref, $defaults, @opts ) = @_;
    $defaults //= {};
    if ($autoundef) {
      $defaults->{AUTOLOAD} = sub {
        my $self = shift;
        our $AUTOLOAD;
        ( my $key = $AUTOLOAD ) =~ s/.*:://;
        die qq{Getopt2h2o: Won't set value for non-existing key. Need it? Let the module author know!\n} if @_;
        return undef;
      };
    }
    my $o = h2o -meth, $defaults, opt2h2o(@opts);
    require Getopt::Long;
    Getopt::Long::GetOptionsFromArray( $ARGV_ref, $o, @opts );    # Note, @ARGV is passed by reference
    return $o;
}

# general form of method used to give accessors to Config::Tiny in Util::H2O's
# POD documentation
sub o2h2o($) {
    my $ref = shift;
    return h2o -recurse, { %{$ref} };
}

# more specific helper app that uses Config::Tiny->read and o2h2o to get a config
# object back from an .ini; requries Config::Tiny
sub ini2h2o($) {
    my $filename = shift;
    require Config::Tiny;
    return o2h2o( Config::Tiny->read($filename) );
}

# back compat
sub ini2o($) {
    return ini2h2o(shift);
}

# write out the INI file
sub h2o2ini($$) {
    my ( $config, $filename ) = @_;
    require Config::Tiny;
    return Config::Tiny->new( Util::H2O::o2h $config)->write($filename);
}

# back compat
sub o2ini($$) {
    return h2o2ini( shift, shift );
}

# return a dereferences hash (non-recursive); reverse of `h2o'
sub o2h($) {
    $Util::H2O::_PACKAGE_REGEX = qr/::_[0-9A-Fa-f]+\z/;    # makes internal package name more generic for baptise created references
    my $ref = Util::H2O::o2h @_;
    if ( ref $ref ne q{HASH} ) {
        die qq{o2h: Could not fully remove top-level reference. Probably an issue with \$Util::H2O_PACKAGE_REGEX\n};
    }
    return $ref;
}

sub d2o(@);    # forward declaration to get rid of "too early" warning
sub a2o($);

# accepts '-autoundef' flag that will insert all keys/getters to be checked
# i.e., if (not $myref->doesntexist) { ... } rather than if (not exists $myref->{doesntexist}) { ... }
sub d2o(@) {
    my ($autoundef);
    # basically how Util::H2O::h2o does it, if we have more options
    # then we should use the `while` form of this ...
    if ( @_ && $_[0] && !ref$_[0] && $_[0]=~/^-autoundef/ ) {
      $autoundef = shift;
    }
    my $thing = shift;

    my $isa   = ref $thing;

    if ( $isa eq q{ARRAY} ) {
        a2o $thing;
        foreach my $element (@$thing) {
          if ($autoundef) { # 'd2o -autoundef, $hash'
            d2o $autoundef, $element;
          }
          else {
            d2o $element;
          }
        }
    }
    elsif ( $isa eq q{HASH} ) {
        foreach my $keys ( keys %$thing ) {
          if ($autoundef) { # 'd2o -autoundef, $hash'
            d2o $autoundef, $thing->{$keys};
          }
          else {
            d2o $thing->{$keys};
          }
        }
        if ($autoundef) { # 'd2o -autoundef, $hash'
          $thing->{AUTOLOAD} = sub {
            my $self = shift;
            our $AUTOLOAD;
            ( my $key = $AUTOLOAD ) =~ s/.*:://;
            die qq{d2o: Won't set value for non-existing key. Need it? Let the module author know!\n} if @_;
            return undef;
          };
          h2o -meth, $thing;
        }
        else {           # default behavior
          h2o $thing;
        }
    }
    return $thing;
}

# blesses ARRAY ref as a container and gives it some virtual methods
# useful in the context of containing HASH refs that get objectified
# by h2o
sub a2o($) {
    no strict 'refs';

    my $array_ref = shift;

    # uses lexical scop of the 'if' to a bless $array_ref (an ARRAY ref)
    # and assigns to it some virtual methods for making dealing with
    # the "lists of C<HASH> references easier, as a container

    my $a2o_pkg = sprintf( qq{%s::__a2o_%d::vmethods}, __PACKAGE__, int rand 100_000_000 );    # internal a2o

    bless $array_ref, $a2o_pkg;

    ## add vmethod to wrap around array_refs

    # return item at index INDEX
    my $GET = sub {
      my ( $self, $i ) = @_;
      return undef if $i > $#{$self}; # prevent ARRAY from growing just to get an undef back
      return $self->[$i];
    };
    *{"${a2o_pkg}::get"} = $GET;
    *{"${a2o_pkg}::i"}   = $GET;

    # return rereferenced ARRAY
    my $ALL = sub { my $self = shift; return @$self; };
    *{"${a2o_pkg}::all"} = $ALL;

    # returns value returned by the 'scalar' keyword, alias also to 'count'
    my $SCALAR = sub { my $self = shift; return scalar @$self; };
    *{"${a2o_pkg}::scalar"} = $SCALAR;
    *{"${a2o_pkg}::count"}  = $SCALAR;

    # 'push' will apply "d2o" to all elements pushed
    my $PUSH = sub { my ( $self, @i ) = @_; d2o \@i; push @$self, @i; return \@i };
    *{"${a2o_pkg}::push"} = $PUSH;

    # 'pop' intentionally does NOT apply "o2d" to anyarray_ref pop'd
    my $POP = sub { my $self = shift; return pop @$self };
    *{"${a2o_pkg}::pop"} = $POP;

    # 'unshift' will apply "d2o" to all elements unshifted
    my $UNSHIFT = sub { my ( $self, @i ) = @_; d2o \@i; unshift @$self, @i; return \@i };
    *{"${a2o_pkg}::unshift"} = $UNSHIFT;

    # 'shift' intentionally does NOT apply "o2d" to anyarray_ref shift'd
    my $SHIFT = sub { my $self = shift; return shift @$self };
    *{"${a2o_pkg}::shift"} = $SHIFT;

    return $array_ref;
}

# includes internal dereferencing so to be compatible
# with the behavior of Util::H2O::o2h
sub o2d($);    # forward declaration to get rid of "too early" warning

sub o2d($) {
    my $thing = shift;
    return $thing if not $thing;
    my $isa = ref $thing;
    if ( $isa =~ m/^Util::H2O::More::__a2o/ ) {
        my @_thing = @$thing;
        $thing = \@_thing;
        foreach my $element (@$thing) {
            $element = o2d $element;
        }
    }
    elsif ( $isa =~ m/^Util::H2O::_/ ) {
        foreach my $key ( keys %$thing ) {
            $thing->{$key} = o2d $thing->{$key};
        }
        $thing = Util::H2O::o2h $thing;
    }
    return $thing;
}

# handy, poor man's debug wrappers

sub ddd(@) {
    require Data::Dumper;
    foreach my $ref (@_) {
        print STDERR Data::Dumper::Dumper($ref);
    }
}

sub dddie(@) {
    require Data::Dumper;
    foreach my $ref (@_) {
        print STDERR Data::Dumper::Dumper($ref);
    }
    die qq{died due to use of dddie};
}

# YAML configuration support - may return more than 1 reference
sub yaml2h2o($) {
    require YAML;
    my $file_or_yaml = shift; # may be a file or a string
    my @yaml         = ();    # yaml can have multiple objects serialized, via ---

    # determine if YAML or file name
    my @lines = split /\n/, $file_or_yaml;

    # if a file, use YAML::LoadFile
    if ( @lines == 1 and -e $file_or_yaml ) {
        @yaml = YAML::LoadFile($file_or_yaml);
    }

    # if not a file, assume YAML string and use YAML::Load
    elsif ($lines[0] eq q{---}) {
        @yaml = YAML::Load($file_or_yaml);
    }

    # die because not supported content $file_or_yaml - it is neither
    else {
        die qq{Provided parameter looks like neither a file name nor a valid YAML snippet.\n};
    }

    # iterate over 1 or more serialized objects that were deserialized
    # from the YAML, applie C<d2o> to it due to the potential presence
    # of ARRAY references
    my @obs = ();
    foreach my $y (@yaml) {
        push @obs, d2o $y;
    }

    return @obs;
}

# back compat
sub yaml2o($) {
    return yaml2h2o(shift);
}

# NOTE: no h2o2yaml or o2yaml, but can add one if somebody needs it ... please file an issue on the tracker (GH these days)

# This method assumes a response HASH reference returned by HTTP::Tiny; so
# it looks for $ref->{content}, and if anything is found there it will attempt
# to turn it into a Perl data structure usin JSON::XS::Maybe::decode_json; it
# them applies "d2o -autoundef" to it; if the JSON decode fails, the error will
# be hidden silently and the original content will be retained in the provided
# response reference (also available via ->content by virtu of h2o being applied).
# To force the JSON decode error to propagate up so that it may be caught, use
# the "-autothrow" option, e.g.;
#   HTTPTiny2h2o -autothrow, $ref_with_bad_JSON; # propagates decode_json exception from "malformed" JSON
#   HTTPTiny2h2o $ref_with_bad_JSON;             # hides bad decode, "->content" accessor created to return original content
#   HTTPTiny2h2o $ref_with_good_JSON;            # h2o applied to $ref, "d2o -autoundef" applied to value of ->{content}
sub HTTPTiny2h2o(@) {
  my $autothrow;
  if ( @_ && $_[0] && !ref$_[0] && $_[0]=~/^-autothrow/ ) {
    $autothrow = shift;
  }
  my $ref = shift;
  if (ref $ref eq q{HASH} and exists $ref->{content}) {
    require JSON::MaybeXS; # tries to load the JSON module you want, (by default, exports decode_json, encode_json)
    h2o $ref, qw/content/;
    if ($ref->content) {
      # allows exception from decode_json to be raised if -autothrow
      # and the JSON is determined to be malformed
      if ($autothrow) {
        # the JSON decode will die on bad JSON
        my $JSON = JSON::MaybeXS::decode_json($ref->content);
        my $content= d2o -autoundef, $JSON;
        $ref->content($content);
      }
      # default is hide any malformed JSON exception, effectively
      # leaving the ->content untouched
      else {
        eval {
          # the JSON decode will die on bad JSON
          my $JSON = JSON::MaybeXS::decode_json($ref->content);
          my $content= d2o -autoundef, $JSON;
          $ref->content($content);
        }
      }
    }
    else {
      my $content= d2o -autoundef, {};
      $ref->content($content);
    }
  }
  else {
    die qq{Provided parameter must be a proper HASH reference returned by HTTP::Tiny that contains a 'content' HASH key.};
  }

  return $ref;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Util::H2O::More - Convenience utilities built on Util::H2O (baptise, d2o, INI/YAML/HTTP helpers, Getopt helpers)

=head1 SYNOPSIS

Below is an example of a traditional Perl OOP class constructor using C<baptise>
to define a set of default accessors, in addition to any that are created by virtue
of the C<%opts> passed.

    use strict;
    use warnings;

    package Foo::Bar;

    # exports 'h2o' also
    use Util::H2O::More qw/baptise/;

    sub new {
      my $pkg    = shift;
      my %opts   = @_;

      # replaces bless, defines default accessors and creates
      # accessors based on what's passed into %opts

      my $self = baptise \%opts, $pkg, qw/bar haz herp derpes/;

      return $self;
    }

    1;

Then in a caller script:

    use strict;
    use warnings;

    use Foo::Bar;

    my $foo = Foo::Bar->new(some => q{thing}, else => 4);

    print $foo->some . qq{\n};

    # set bar via default accessor
    $foo->bar(1);
    print $foo->bar . qq{\n};

    # default accessors also available from the class defined above:
    #   $foo->haz, $foo->herp, $foo->derpes
    #
    # and from the supplied tuple:
    #   $foo->else

In most cases, C<baptise> can be used as a drop-in replacement for C<bless>.

For more examples, please look at the classes created for unit tests contained in
C<t/lib>.

=head1 DESCRIPTION

L<Util::H2O> provides a compelling approach that allows one to incrementally add
I<OOP-ish> ergonomics into Perl without committing to a full OO framework. It makes
dealing with C<HASH> references much easier while still being idiomatic Perl.

C<Util::H2O::More> is a toolbox built on that foundation. It provides:

=over 4

=item *
C<baptise> — a C<bless>-like constructor helper that also creates accessors

=item *
C<d2o> / C<o2d> — objectify and de-objectify arbitrarily nested structures (HASH/ARRAY mixtures)

=item *
Cookbook helpers for configuration and interoperability (INI via L<Config::Tiny>, YAML via L<YAML>)

=item *
Command-line options helpers (C<opt2h2o>, C<Getopt2h2o>)

=item *
An L<HTTP::Tiny> response helper (C<HTTPTiny2h2o>) that can decode JSON content and objectify it

=item *
Debugging helpers (C<ddd>, C<dddie>)

=item *
Key normalization helper (C<tr4h2o>) for “non-compliant” hash keys

=back

This module targets a practical problem: Perl programs frequently pass around
ad-hoc hashrefs (and arrays of hashrefs) from config, DBI, JSON APIs, or small
in-house services. Even when correct, code can become visually dense due to
repeated C<< ->{key} >> and C<< ->[idx] >> access. These helpers aim to reduce
that syntactic noise while keeping the data model the same.

=head1 WHICH FUNCTION SHOULD I USE?

If you are new to this module, this section answers the common question:
I<“Which helper do I actually want here?”>

=head2 Quick Decision Guide

=over 4

=item * Writing a constructor → C<baptise>

=item * You already have a hashref and want accessors → C<h2o>

=item * You have nested data (JSON / API / DB results) with arrays and hashes → C<d2o>

=item * You want missing keys to return undef without C<exists> checks → add C<-autoundef> (C<d2o> or C<Getopt2h2o>)

=item * You need plain Perl structures again (serialization / frameworks) → C<o2h> or C<o2d>

=item * INI config files → C<ini2h2o> / C<h2o2ini>

=item * YAML files or YAML strings → C<yaml2h2o>

=item * L<HTTP::Tiny> JSON responses → C<HTTPTiny2h2o>

=back

=head2 Minimal Cheatsheet

=over 4

=item * C<baptise> — like C<bless>, but also creates accessors

=item * C<h2o> — add accessors to a hashref (non-recursive unless you use Util::H2O flags)

=item * C<d2o> — walk a whole structure (arrays + hashes) and objectify all hashrefs, plus array “container” helpers

=item * C<o2h> — turn an objectified top-level hash back into a plain hashref (useful before JSON encoding)

=item * C<o2d> — de-objectify a structure created by C<d2o> (arrays + hashes back to plain refs)

=back

=head1 ANTI-EXAMPLE GALLERY: BRACE SOUP → CLEAN CODE

This gallery shows common Perl patterns written with traditional hash/array
dereferencing, then the same behavior expressed using C<h2o>, C<d2o>, and
friends from this module.

=head2 HTTP + JSON

=head3 Before: Brace-heavy dereferencing

    my $res = HTTP::Tiny->new->get($url);
    die unless $res->{success};

    my $data = decode_json($res->{content});

    foreach my $item (@{ $data->{results} }) {
        next unless $item->{meta};
        my $id = $item->{meta}->{id};

        foreach my $tag (@{ $item->{tags} }) {
            next unless $tag->{enabled};
            print "$id => $tag->{name}\n";
        }
    }

=head3 After: C<HTTPTiny2h2o> + C<d2o -autoundef>

    my $res = HTTPTiny2h2o HTTP::Tiny->new->get($url);
    die unless $res->success;

    foreach my $item ($res->content->results->all) {
        my $id = $item->meta->id or next;

        foreach my $tag ($item->tags->all) {
            next unless $tag->enabled;
            say "$id => " . $tag->name;
        }
    }

=head2 DBI rows

=head3 Before

    while (my $row = $sth->fetchrow_hashref) {
        next unless $row->{address};
        my $city = $row->{address}->{city};
        print "$row->{name} lives in $city\n";
    }

=head3 After: C<d2o> for iteration

    my @rows;
    push @rows, $_ while ($_ = $sth->fetchrow_hashref);
    my $data = d2o -autoundef, \@rows;

    foreach my $row ($data->all) {
        next unless $row->address;
        say $row->name . " lives in " . $row->address->city;
    }

=head2 Configuration (INI)

=head3 Before

    my $cfg  = Config::Tiny->read('app.ini');
    my $host = $cfg->{database}->{host};
    my $port = $cfg->{database}->{port};

=head3 After: C<ini2h2o>

    my $cfg  = ini2h2o 'app.ini';
    my $host = $cfg->database->host;
    my $port = $cfg->database->port;

=head1 PATHOLOGICAL EXAMPLE: 1:1 BRACE DEREF → ACCESSORS

This example preserves I<all logic, control flow, and ordering>. The only change
is replacing deref syntax with accessor calls via C<h2o> and C<d2o -autoundef>.
No refactoring and no “clever” simplification is introduced.

=head2 Before: Brace-heavy dereferencing (original logic)

    my $res = HTTP::Tiny->new->get($url);
    die unless $res->{success};

    my $data = decode_json($res->{content});

    foreach my $user (@{ $data->{users} }) {

        next unless exists $user->{profile};
        next unless exists $user->{profile}->{active};
        next unless $user->{profile}->{active};

        next unless exists $user->{company};
        next unless exists $user->{company}->{name};

        foreach my $project (@{ $user->{projects} }) {

            next unless exists $project->{status};
            next unless $project->{status} eq 'active';

            next unless exists $project->{meta};
            next unless exists $project->{meta}->{title};

            print
                $user->{company}->{name}
                . ": "
                . $project->{meta}->{title}
                . "\n";
        }
    }

=head2 After: Same logic, same flow, accessors only

    my $res = h2o HTTP::Tiny->new->get($url);
    die unless $res->success;

    my $data = d2o -autoundef, decode_json($res->content);

    foreach my $user ($data->users->all) {

        next unless $user->profile;
        next unless $user->profile->active;
        next unless $user->profile->active;

        next unless $user->company;
        next unless $user->company->name;

        foreach my $project ($user->projects->all) {

            next unless $project->status;
            next unless $project->status eq 'active';

            next unless $project->meta;
            next unless $project->meta->title;

            print
                $user->company->name
                . ": "
                . $project->meta->title
                . "\n";
        }
    }

=head2 Quantifying what was removed

The transformation above removes (in this snippet):

=over 4

=item *
Hash deref operators: 48 instances of C<< ->{...} >>

=item *
Array deref expressions: 6 instances of C<< @{ ... } >>

=item *
Structural braces used only for access: 22 braces/brackets

=item *
Paired C<exists> + deref checks replaced by safe accessor reads via C<-autoundef>

=back

In raw punctuation characters, that’s roughly 300+ characters of access-only
syntax removed in a small example. In a larger file with hundreds of dereferences,
this scales to kilobytes of Perl source I<not typed>, I<not diffed>, and I<not reviewed>.
Even when file size is irrelevant, cognitive load is not.

=head1 METHODS

=head2 C<baptise [-recurse] REF, PKG, LIST>

Takes the same first two parameters as C<bless>, with an additional list that
defines a set of default accessors that do not rely on top-level keys of the
provided hash reference.

In other words: it looks like C<bless>, but you can also specify a list of
methods you want available as accessors even if they are not present in the
hash (or not present yet).

    my $self = baptise \%opts, $class, qw/foo bar baz/;

=head3 The B<-recurse> option

Like C<baptise>, but creates accessors recursively for a nested hash reference.
This uses C<h2o>'s C<-recurse> flag.

Note: Accessors created in nested hashes are handled by C<h2o -recurse>.
Those nested hashes are blessed with C<Util::H2O>’s internal package naming for
recursive objects. That is expected behavior.

=head2 C<tr4h2o REF>

Replaces all characters not considered legal for subroutine/accessor names with
an underscore C<_>, using:

    tr/a-zA-Z0-9/_/c

It also preserves the original keys in a hash accessible via C<__og_keys>.

Example (adapted from the Util::H2O cookbook):

  use Util::H2O::More qw/h2o tr4h2o ddd/;

  my $hash = { "foo bar" => 123, "quz-ba%z" => 456 };
  my $obj  = h2o tr4h2o $hash;
  print $obj->foo_bar, $obj->quz_ba_z, "\n";    # prints "123456"

  # inspect new structure
  ddd $obj;            # Data::Dumper::Dumper
  ddd $obj->__og_keys; # original keys

Note: This helper is not recursive; recursive key-normalization would be better
handled upstream in Util::H2O (e.g., via a dedicated flag).

=head2 C<Getopt2h2o [-autoundef], ARGV_REF, DEFAULTS_REF, LIST>

Wrapper around the idiom enabled by C<opt2h2o>. It also C<require>s L<Getopt::Long>.
Usage:

  use Util::H2O::More qw/Getopt2h2o/;
  my $opts = Getopt2h2o \@ARGV, { n => 10 }, qw/f=s n=i/;

The first argument is a reference to the C<@ARGV> array (or equivalent). The
second argument is the initial state of the hash to be objectified via C<h2o>.
The remaining arguments are standard L<Getopt::Long> option specifications.

=head3 C<-autoundef>

With C<-autoundef>, missing options can be queried without inspecting the hash
directly. This avoids patterns like:

  exists $opts->{foo}

and enables:

  if (not $opts->foo) { ... }

Example:

  my $opts = Getopt2h2o -autoundef, \@ARGV, { n => 10 }, qw/f=s n=i verbose!/;

Negative option syntax (e.g. C<verbose!> supporting both C<--verbose> and
C<--no-verbose>) is supported.

=head2 C<opt2h2o LIST>

Takes a list of L<Getopt::Long> option specs and extracts only the flag names so
they can be passed to C<h2o> to create accessors without duplicating lists.

    use Getopt::Long qw//;
    my @opts = qw/option1=s options2=s@ option3 option4=i o5|option5=s option6!/;

    my $o = h2o {}, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray(\@ARGV, $o, @opts);

    if ($o->option3) {
      do_the_thing();
    }

Defaults may be provided via the initial hashref:

    my $o = h2o { option1 => q{foo} }, opt2h2o(@opts);

=head2 C<HTTPTiny2h2o [-autothrow], REF>

Helper for dealing with L<HTTP::Tiny> responses, which are typically hashrefs like:

  {
    success => 1,
    status  => 200,
    content => q/some string, could be JSON, etc/,
    ...
  }

If the response contains a C<content> field, this helper attempts to decode that
content as JSON (using L<JSON::MaybeXS>) and, if successful, applies
C<d2o -autoundef> to the decoded structure. The response hashref itself is also
objectified via C<h2o> so you can call C<< $res->success >>, C<< $res->content >>, etc.

Happy-path usage:

  my $res = HTTPTiny2h2o HTTP::Tiny->new->get($url);
  die unless $res->success;
  say $res->content->someField;

=head3 C<HTTPTiny2h2o> may C<die>

This method expects a proper hashref returned by L<HTTP::Tiny> that includes a
C<content> key. If the input doesn’t look like that, it throws an exception.

=head3 JSON decode failure behavior and C<-autothrow>

By default, JSON decode errors are caught and suppressed (the original C<content>
string remains accessible). If you want malformed JSON to raise an exception, use
C<-autothrow>:

  local $@;
  my $ok = eval {
    HTTPTiny2h2o -autothrow, $res;
    1;
  };
  if (not $ok) {
    ... # handle malformed JSON
  }

=head3 Note on serialization formats

Currently, this helper only attempts JSON decoding. It does not check headers
to determine content type; JSON validity is determined solely by C<decode_json>.

=head2 C<yaml2h2o FILENAME_OR_YAML_STRING>

Takes a single parameter that may be either:

=over 4

=item *
A YAML filename (uses C<YAML::LoadFile>)

=item *
A YAML string that begins with C<---\n> (uses C<YAML::Load>)

=back

YAML may contain multiple serialized objects separated by C<---\n>, so C<yaml2h2o>
returns a list of objects.

For example, if C<myfile.yaml> contains two documents:

  ---
  database:
    host: localhost
  ---
  devices:
    thingy:
      active: 1

Then:

  my ($dbconfig, $devices) = yaml2h2o q{/path/to/myfile.yaml};

Each returned value has been passed through C<d2o>, so nested hashrefs are
objectified and array containers gain helper methods.

=head3 C<yaml2h2o> may C<die>

If the argument looks like neither a filename nor a YAML string beginning with
C<---\n>, an exception is thrown.

=head2 C<yaml2o FILENAME>

Alias to C<yaml2h2o> for backward compatibility.

=head2 C<ini2h2o FILENAME>

Takes the name of a file, uses L<Config::Tiny> to read it, then converts the
result into an accessor-based object using C<o2h2o>.

Given an INI file:

  [section1]
  var1=foo
  var2=bar

  [section2]
  var3=herp
  var4=derp

You can do:

  my $config = ini2h2o q{/path/to/config.ini};
  say $config->section1->var1;

C<ini2o> is provided as a backward-compat alias.

=head2 C<h2o2ini REF, FILENAME>

Takes an object created via C<ini2h2o> and writes it back to disk in INI format
using L<Config::Tiny>.

  my $config = ini2h2o q{/path/to/config.ini};
  $config->section1->var1("some new value");
  h2o2ini $config, q{/path/to/other.ini};

C<o2ini> is provided as a backward-compat alias.

=head2 C<o2h2o REF>

General helper to objectify an already-blessed config-like object by copying its
top-level hash content into a new hash and applying C<h2o -recurse>. This is
useful for objects like those returned by L<Config::Tiny>.

=head2 C<o2h REF>

Uses C<Util::H2O::o2h> and behaves identically to it, but adjusts
C<$Util::H2O::_PACKAGE_REGEX> to accept package names generated by C<baptise>.
A new plain hashref is returned.

This complements C<h2o> / C<baptise> when you need to serialize data (e.g. JSON
encoding) and the encoder dislikes blessed references.

=head2 C<d2o [-autoundef] REF>

Wrapper around C<h2o> that traverses an arbitrarily complex Perl data structure,
applying C<h2o> to any C<HASH> refs along the way, and blessing C<ARRAY> refs as
containers with helper methods.

A common use case is web APIs returning arrays of hashes:

  my $array_of_hashes = JSON::decode_json $json;
  d2o $array_of_hashes;
  my $co = $array_of_hashes->[3]->company->name;

With C<d2o>, you can navigate without manual deref punctuation, and arrays gain
helpers such as C<all>, C<get>, C<count>, etc.

=head3 C<-autoundef>

If C<-autoundef> is used, an C<AUTOLOAD> is attached such that calling a method
for a missing key returns C<undef> (and attempts to set a missing key die).

This avoids patterns like:

  exists $hash->{k}

Example:

  my $ref = somecall(...);
  d2o -autoundef, $ref;

  foreach my $k (qw/foo bar baz/) {
    say $ref->$k if $ref->$k;
  }

=head3 Relationship to Util::H2O C<-arrays>

As of Util::H2O 0.20, C<h2o> supports an arrays-related modifier. In many cases,
that may be sufficient for nested JSON-like structures. C<d2o> exists largely
because this module originally added deep traversal before that feature was known,
and because C<d2o> also blesses array containers and provides the vmethods described
below.

=head2 C<o2d REF>

Does for structures objectified with C<d2o> what C<o2h> does for objects created
with C<h2o>. It removes blessing from C<Util::H2O::...> and
C<Util::H2O::More::__a2o...> references and returns plain refs.

=head2 C<a2o REF>

Used internally to bless arrayrefs as containers and attach “virtual methods”.
Exposed in case you find a use for it directly, but it is primarily an internal
implementation detail of C<d2o>.

=head1 C<ARRAY> CONTAINER VIRTUAL METHODS

When C<d2o> encounters arrayrefs, it blesses them as containers and attaches
helper methods. This is intentionally “heavier” than base Util::H2O.

=head2 C<all>

Returns a LIST of all items in the array container.

  my @items = $root->teams->all;

=head2 C<get INDEX>, C<i INDEX>

Returns element at INDEX. C<i> is a short alias for C<get>.

  my $x = $root->teams->get(0);
  my $y = $root->teams->i(0);

This makes deeply nested reads more readable:

  $data->company->teams->i(0)->members->i(0)->projects->i(0)->tasks->i(1)->status('Completed');

=head2 C<push LIST>

Pushes items onto the container and applies C<d2o> to anything pushed.

  my @added = $root->items->push({ foo => 1 }, { foo => 2 });
  say $root->items->get(0)->foo;

Items pushed are returned for convenience.

=head2 C<pop>

Pops an element from the container. C<pop> intentionally does NOT apply C<o2d>.

=head2 C<unshift LIST>

Like C<push>, but on the near end. Applies C<d2o> to items unshifted.

=head2 C<shift>

Like C<pop>, but on the near end. Does NOT apply C<o2d>.

=head2 C<scalar>, C<count>

Returns the number of items in the container:

  my $n = $root->items->count;

=head1 DEBUGGING METHODS

=head2 C<ddd LIST>

Applies L<Data::Dumper>::C<Dumper> to each argument and prints to STDERR.
L<Data::Dumper> is loaded via C<require>.

=head2 C<dddie LIST>

Same as C<ddd>, but dies afterward.

=head1 EXTERNAL METHODS

=head2 C<h2o>

Because C<Util::H2O::More> exports C<h2o> as the basis for its operations,
C<h2o> is also available without qualifying its full namespace.

=head1 DEPENDENCIES

=head2 L<Util::H2O>

Required. This module is effectively a convenience layer around C<h2o> and C<o2h>.

It also uses the C<state> keyword, available in Perl ≥ 5.10.

=head2 Optional / conditional dependencies

Some helpers load external modules only when you call them:

=over 4

=item *
C<Getopt2h2o> loads L<Getopt::Long>

=item *
C<ini2h2o> / C<h2o2ini> load L<Config::Tiny>

=item *
C<yaml2h2o> loads L<YAML>

=item *
C<HTTPTiny2h2o> loads L<JSON::MaybeXS>

=item *
C<ddd> / C<dddie> load L<Data::Dumper>

=back

=head1 BUGS

At the time of this release, there are no bugs listed on the GitHub issue tracker.

=head1 LICENSE AND COPYRIGHT

Perl / Perl 5.

=head1 ACKNOWLEDGEMENTS

Thank you to HAUKEX for creating L<Util::H2O> and hearing me out on its usefulness
for some unintended use cases.

=head1 SEE ALSO

This module was featured in the 2023 Perl Advent Calendar on December 22:
L<https://perladvent.org/2023/2023-12-22.html>.

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >>
