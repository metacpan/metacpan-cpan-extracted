package deferred;
use strict;

our $VERSION = "0.01";

# Modules the user has requested to defer
my @enabled;
# Modules we've half loaded
my %half_loaded;

sub import {
  my $class = shift;

  push @enabled, map { ref $_ ? $_ : qr/^$_$/ } @_;
}

sub unimport {
  my $class = shift;

  my $discard = @_ && $_[0] eq '-discard' ? pop : 0;

  if(@_) {
    my @disable = map { ref $_ ? $_ : qr/^$_$/ } @_;

    for my $disable(@disable) {
      @enabled = grep { $_ ne $disable } @enabled;
    }
  } else {
    @enabled = ();

    if(!$discard) {
      for my $class(keys %half_loaded) {
        _load($class);
      }
    }

    %half_loaded = ();
  }
}

unshift @INC, my $inc_ref = sub {
  my(undef, $file) = @_;

  # We get a filename here, we let the user specify a module name, so convert
  # it back.
  (my $module = $file) =~ s{/}{::}g;
  $module =~ s/\.pm$//;

  if(caller =~ /^(?:base|parent)/) {
    # When these modules load something they really do mean it
    return;
  }

  for my $enabled(@enabled) {
    if($module =~ $enabled) {
      $half_loaded{$module} = join ":", (caller)[1,2];

      open my $fh, "<", \"1";
      return $fh;
    }
  }

  return;
};

sub UNIVERSAL::AUTOLOAD {
  my $load = $UNIVERSAL::AUTOLOAD;

  my($class, $method) = ($load =~ /^(.*)::(.*)$/);
  return if $method eq 'DESTROY';

  _load($class) if exists $half_loaded{$class};

  no warnings 'once';
  no strict 'refs';

  if(*{$load}{CODE}) {
    goto &$load;
  } elsif(my $can = $class->can($method)) {
    goto &$can;
  } else {
    # Really doesn't exist
    require Carp;
    Carp::croak("Undefined subroutine/method called ($load)");
  }
}

sub _load {
  my $class = shift;

  # Avoid the need to reimplement @INC searching
  local @INC = grep { !ref || $_ != $inc_ref } @INC;

  (my $file = $class) =~ s{::}{/}g;
  $file .= ".pm";
  local %INC = %INC;
  delete $INC{$file};

  my $orig = delete $half_loaded{$class};
  my $ok = eval { require $file };

  die "deferred load of $class failed (originally loaded at $orig):\n$@"
    if !$ok;
  $ok;
}

1;

__END__

=head1 NAME

deferred - Defer loading of modules until methods are called

=head1 SYNOPSIS

  use deferred "SomeModule";
  use SomeModule;

  # Module not yet loaded, but you don't have to worry about conditionally
  # loading it.
  
  my $foo = SomeModule->new; # Module now loaded

=head1 DESCRIPTION

For modules where you don't care about the C<-E<gt>import> method being called,
such as pure OO modules you may not want to load the module until it is
actually used. (The main reason being to save time or memory.)

You should be very careful if considering using this on code not under your
control, please understand this may break assumptions the code makes (that are
quite valid in normal circumstances).

=head1 USAGE

The interface to this module is via arguments to C<use deferred>.

Either a string or a regexp reference (C<qr//>) may be provided. A string will
be interpreted as a regular expression matching the full module name (i.e.
C<^> and C<$> are prepended and appended respectively).

For example:

  use deferred "Foo::.*"; # Defer loading all modules under the Foo namespace

  use deferred "Bar", qr/Baz/; # Defer loading

C<use> statements executed after a C<use deferred> statement will be checked to
see if loading of that module should be deferred, if so the module will not be
loaded until a method is called on that module name.

Multiple C<use deferred> statements will add to the list of matches.

This is B<not> currently a pragma, so it is not lexically scoped.

=head2 DISABLING

C<no deferred> will disable deferred loading from that point onwards. It will
load all deferred modules at the moment it is called, unless C<-discard> is
provided as an argument.

  no deferred; # Disable all deferred loading, load modules

  no deferred -discard; # Disable all deferred loading, discard list

An argument may be provided to stop future deferred loads of a previously
specified item:

  no deferred "Foo::.*";

If an argument is provided no modules will be loaded.

=head1 LIMITATIONS

This module certainly is a case of providing enough ammo to shoot yourself in
the foot several times over. Deferring the loading of modules such as L<base>
and L<parent> will almost certainly result in confusion. (The module itself
tries to handle some of these issues, but it can't cope with some cases).

Combining this module with other modules that make use of code references in
C<@INC> may or may not work, potentially dependant on order of loading. This
module places its code reference onto the start of C<@INC> when loaded.
(Particular modules -- that don't live in the Acme namespace -- to be aware of
are L<everywhere> and L<App::FatPacker>.)

In order for this to work your C<use> statements must exactly match the classes
you call methods on (i.e. with some modules it is common practice to use a high
level module such as C<Foo>, then create an instance of C<Foo::Bar> -- this
won't work).

This module also rudely hijacks C<UNIVERSAL::AUTOLOAD>.

=head1 SEE ALSO

L<Class::Autouse> - I tried this, I actually wanted something between its
I<superloader> and manually specifying classes. I think it handles more edge
cases though.

=head1 LICENSE

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. See L<http://sam.zoy.org/wtfpl/> or
L<Software::License::WTFPL_2> for more details.

=head1 AUTHORS

David Leadbeater E<lt>L<dgl@dgl.cx>E<gt>, 2010

=cut
