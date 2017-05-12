package XML::Tags;

use strict;
use warnings FATAL => 'all';

use File::Glob ();

require overload;

my $IN_SCOPE = 0;

sub import {
  die "Can't import XML::Tags into a scope when already compiling one that uses it"
    if $IN_SCOPE;
  my ($class, @args) = @_;
  my $opts = shift(@args) if ref($args[0]) eq 'HASH';
  my $target = $class->_find_target(0, $opts);
  my @tags = $class->_find_tags(@args);
  my $unex = $class->_export_tags_into($target => @tags);
  if ($INC{"bareword/filehandles.pm"}) { bareword::filehandles->import }
  $class->_install_unexporter($unex);
  $IN_SCOPE = 1;
}

sub to_xml_string {
  map { # string == text -> HTML, scalarref == raw HTML, other == passthrough
    ref($_)
      ? (ref $_ eq 'SCALAR' ? $$_ : $_)
      : do { local $_ = $_; # copy
          if (defined) {
            s/&/&amp;/g; s/"/&quot;/g; s/</&lt;/g; s/>/&gt;/g; $_;
          } else {
            ''
          }
        }
  } @_
}

sub _find_tags { shift; @_ }

sub _find_target {
  my ($class, $extra_levels, $opts) = @_;
  return $opts->{into} if defined($opts->{into});
  my $level = ($opts->{into_level} || 1) + $extra_levels;
  return (caller($level))[0];
}

sub _set_glob {
  # stupid insanity. delete anything already there so we disassociated
  # the *CORE::GLOBAL::glob typeglob. Then the string reference call
  # revivifies it - i.e. creates us a new glob, which we get a reference
  # to, which we can then assign to.
  # doing it without the quotes doesn't - it binds to the version in scope
  # at compile time, which means after a delete you get a nice warm segv.
  delete ${CORE::GLOBAL::}{glob};
  no strict 'refs';
  *{'CORE::GLOBAL::glob'} = $_[0];
}

sub _export_tags_into {
  my ($class, $into, @tags) = @_;
  foreach my $tag (@tags) {
    no strict 'refs';
    tie *{"${into}::${tag}"}, 'XML::Tags::TIEHANDLE', \"<${tag}>";
  }
  _set_glob(sub {
    local $XML::Tags::StringThing::IN_GLOBBERY = 1;
    \('<'."$_[0]".'>');
  });
  overload::constant(q => sub { XML::Tags::StringThing->from_constant(@_) });
  return sub {
    foreach my $tag (@tags) {
      no strict 'refs';
      delete ${"${into}::"}{$tag}
    }
    _set_glob(\&File::Glob::csh_glob);
    overload::remove_constant('q');
    $IN_SCOPE = 0;
  };
}

sub _install_unexporter {
  my ($class, $unex) = @_;
  $^H |= 0x20000; # localize %^H
  $^H{'XML::Tags::Unex'} = bless($unex, 'XML::Tags::Unex');
}

package XML::Tags::TIEHANDLE;

sub TIEHANDLE { my $str = $_[1]; bless \$str, $_[0] }
sub READLINE { ${$_[0]} }

package XML::Tags::Unex;

sub DESTROY { local $@; eval { $_[0]->(); 1 } || warn "ARGH: $@" }

package XML::Tags::StringThing;

use overload (
  '.' => 'concat',
  '""' => 'stringify',
  fallback => 1
);

sub stringify {
  join(
    '',
    ((our $IN_GLOBBERY)
      ? XML::Tags::to_xml_string(@{$_[0]})
      : (map +(ref $_ ? $$_ : $_), @{$_[0]})
    )
  );
}

sub from_constant {
  my ($class, $initial, $parsed, $type) = @_;
  return $parsed unless $type eq 'qq';
  return $class->new($parsed);
}

sub new {
  my ($class, $string) = @_;
  bless([ \$string ], $class);
}

sub concat {
  my ($self, $other, $rev) = @_;
  my @extra = do {
    if (ref($other) && ($other =~ /[a-z]=[A-Z]/) && $other->isa(__PACKAGE__)) {
      @{$other}
    } else {
      $other;
    }
  };
  my @new = @{$self};
  $rev ? unshift(@new, @extra) : push(@new, @extra);
  bless(\@new, ref($self));
}

1;
