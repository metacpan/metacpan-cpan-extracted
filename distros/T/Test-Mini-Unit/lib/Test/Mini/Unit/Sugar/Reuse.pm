# Defines the behavior of the +reuse+ keyword.
# @api private
package Test::Mini::Unit::Sugar::Reuse;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();
use Carp qw/confess/;

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::reuse"} = sub ($) {
            my $caller = caller;
            my $pkg = __PACKAGE__->qualify_name(shift, $caller);
            unshift(@_, $pkg);
            goto &{$pkg->can('import')};
        };
    }

    Devel::Declare->setup_for(
        $caller => { reuse => { const => sub { $class->new()->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator();

    my $name = $self->strip_name();
    $self->inject("'${name}'");
}

sub qualify_name {
    my ($self, $name, $mod) = @_;
    my $file;

    if ($name =~ s/^::// || $mod eq 'main') {
        ($file = $name) =~ s/::/\//g;
        die "Cannot find module '$name' to reuse..."
            unless exists $INC{"$file.pm"};
    } else {
        my $pkg = $mod;
        my @pkg_parts  = split('::', $pkg);
        my @name_parts = split('::', $name);

        unshift @pkg_parts, '';

        while (@pkg_parts) {
            $file = join('/', @pkg_parts[1..@pkg_parts-1], @name_parts);
            last if exists $INC{"$file.pm"};
            pop(@pkg_parts);
            $file = undef;
        }

        die <<ERROR unless $file;

Cannot resolve module '$name' relative to '$pkg'...
Remember that shared blocks must be declared before the call to `reuse`.
ERROR

        ($name = $file) =~ s/\//::/g;
    }

    return $name;
}

sub inject {
  my ($self, $inject) = @_;

  my $linestr = $self->get_linestr();
  substr($linestr, $self->offset, 0) = $inject;
  $self->set_linestr($linestr);
  $self->inc_offset(length($inject));
}

1;
