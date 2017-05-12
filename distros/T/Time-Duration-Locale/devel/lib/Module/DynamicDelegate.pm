# Copyright 2009, 2010 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

package Module::DynamicDelegate;
use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT $AUTOLOAD @CARP_NOT);

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(can AUTOLOAD);

# uncomment this to run the ### lines
#use Smart::Comments;


# stub generation to hit right method when subclassing ?



# subclassing Exporter
sub export {
  my ($class, $caller_package) = @_;

  # when code here croaks, don't report it against the package using
  # Module::DynamicDelegate but against whatever was calling to there
  push @CARP_NOT, $caller_package;

  return shift->SUPER::export (@_);
}

sub can {
  my ($origin_module, $funcname) = @_;
  return ($origin_module->SUPER::can ($funcname)
          || sub { goto (_lookup($origin_module,$funcname)) });
}

# regexp per AutoLoader::find_filename()
#
sub AUTOLOAD {
  my ($origin_module, $funcname) = ($AUTOLOAD =~ /(.*)::([^:]+)$/);
  ### DynamicDelegate: $AUTOLOAD
  ### dispatch to: $origin_module->_module_dynamicdelegate

  goto (_lookup($origin_module,$funcname));
}

sub _lookup {
  my ($origin_module, $funcname) = @_;
  my $target_module = $origin_module->_module_dynamicdelegate;
  my $func = $target_module->can($funcname)
    || croak "No such function $funcname in $target_module";
}

1;
__END__

=head1 NAME

Module::DynamicDelegate - delegate to a dynamically chosen module

=head1 SYNOPSIS

 use Module::DynamicDelegate;
 sub _module_dynamicdelegate { return 'Some::Module::Name' }

=head1 DESCRIPTION

B<This is experimental, don't use it!>

=head1 SEE ALSO

L<Module::Alias>

=cut
