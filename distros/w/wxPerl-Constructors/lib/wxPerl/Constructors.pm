package wxPerl::Constructors;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.4);

use warnings;
use strict;
use Carp;

=head1 NAME

wxPerl::Constructors - parameterized constructors

=head1 SYNOPSIS

This package provides a mix of named and positional parameters which
mirrors the original C++ API, allowing you to omit default values, even
if you need to specify arguments which would otherwise follow them.

By applying C<s/Wx::([^-]*-)/wxPerl::$1-/g> (and some editing) to your
code:

  use wxPerl::Constructors;

  my $ctrl = wxPerl::TextCtrl->new($self, $label,
    style => wxTE_MULTILINE|wxTE_READONLY|wxTE_DONTWRAP);

=head1 Usage

Note the mixed positional/named arguments.  Required values are
positional and must come before key-value pairs.

  my $ctrl = wxPerl::Foo->new($parent, $req_arg, key => $value);

The exception is when there are no arguments.  This goes directly to the
Wx::Foo->new() call with no intermediate processing.

  my $ctrl = wxPerl::Foo->new();

All constructors also accept a C<($parent, \%params)> syntax, which may
be useful if you are building a data-driven class generator (or just
prefer to use named parameters for everything.)

  my $ctrl = wxPerl::Foo->new($parent,
    {
      req_arg => $req_arg,
      key     => $value,
    }
  );

In this mode, you must still provide the required arguments because
there are no default values for them (they're, uh... required.)

=head1 Advanced usage

The constructors are also (well actually, not yet) available via this
longhand form (intended as infrastructure for other packages.)

  my $ctrl = wxPerl::Constructors->new(
    'TextCtrl', $self, $label,
    style => wxTE_MULTILINE|wxTE_READONLY|wxTE_DONTWRAP);

You may inherit from wxPerl::$foo as follows:

  use wxPerl::Constructors;
  use base 'wxPerl::Frame';

CAVEAT:  There will probably be no way to deduce that you've
accidentally called a wxPerl::foo->new() with the Wx::foo-style
positional arguments.  Though it might be possible later, for now you
have to take care to change the calls.

=head1 Methods

See L<wxPerl::Constructors::doc> for available classes and details on
the argument syntax.

=cut

=begin Notes

Some issue to do with custom classes which derive from our constructors.
They should C<use base 'Wx::Thing'>, but need to have a new() which
comes from here?  This implies that we need to discover their underlying
Wx::Perl type.  I suppose we could either traverse their @ISA until we
find a m/Wx::/, and/or we could require/allow them to define a WxType
method?

Bah.  The classes are all setup to inherit from the Wx::Thingy.  That
still leaves the "I don't want to be a wxPerl::Frame" issue, but maybe
that's not really desired?

  use wxPerl::Constructors qw(override);
  use base qw(wxPerl::Frame Wx::Frame);

I'm going to let some of that slide until I see how I want to use it.

=end Notes

=cut

use Wx ();
use wxPerl::Constructors::argmap;

# load the definitions and define the classes
{
  my $ARGPOS   = wxPerl::Constructors::argmap->ARGPOS;
  my $DEFAULTS = wxPerl::Constructors::argmap->DEFAULTS;

  foreach my $class_base (keys(%$ARGPOS)) {
    my $argpos = $ARGPOS->{$class_base};
    my $defaults = $DEFAULTS->{$class_base};
    my $super_method = 'Wx::' . $class_base . '::new';

    my $constructor = sub {
      my @argpos = @$argpos; # need a fresh copy each time

      my $class = shift;

      unless(scalar(@_)) { # go directly to Foo->new()
        @_ = ($class);
        goto &$super_method;
      }

      my @args = shift(@_); # parent

      push(@args, '-1'); # id

      # then the positional args
      # unless it is a hashref
      if(@_ and ((ref($_[0])||'') eq 'HASH')) {
        my %opts = %{shift(@_)};
        # id is special
        $args[1] = delete($opts{id}) if(exists($opts{id}));
        while(my $arg = shift(@argpos)) {
          exists($defaults->{$arg}) and last;
          exists($opts{$arg}) or
            croak("required argument '$arg' not given");
          push(@args, delete($opts{$arg}));
        }
        foreach my $arg (@argpos) { # these all have defaults
          %opts or last;
          push(@args, (exists($opts{$arg}) ?
            delete($opts{$arg}) : $defaults->{$arg}));
        }
      } # end hashref wrangling
      else { # standard usage
        if(@_) { # first collect the required positional arguments
          while(my $arg = shift(@argpos)) {
            if(exists($defaults->{$arg})) {
              unshift(@argpos, $arg); # put it back
              last;
            }
            push(@args, shift(@_));
          }
        }

        if(@_) {
          (@_ % 2) and croak("odd number of elements in options list");
          my %opts = @_;

          # id is special
          $args[1] = delete($opts{id}) if(exists($opts{id}));
          foreach my $arg (@argpos) { # these all have defaults
            %opts or last;
            push(@args, (exists($opts{$arg}) ?
              delete($opts{$arg}) : $defaults->{$arg}));
          }
        }
      } # end argument wrangling
      @_ = ($class, @args);
      # TODO there's a problem with dangling args, so we'll need to do
      # something like remove any trailing undef arguments
      # (XXX the trailing undef comes from Wx.pm Frame->defaultname I
      # think.)
      #warn "$super_method ", join(',', @_), "\n";
      goto &$super_method;
      # vs:
      #$class->$super_method(@args);
    }; # end $constructor

    my $class_name = 'wxPerl::' . $class_base;
    no strict 'refs';
    @{$class_name . '::ISA'} = ('Wx::' . $class_base); # TODO careful?
    *{$class_name . '::new'} = $constructor;
  }

} # end auto-define




=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
