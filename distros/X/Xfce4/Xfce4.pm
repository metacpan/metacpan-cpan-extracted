#
# Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

{ package Xfce4;
    use 5.008;
    use strict;
    use warnings;
    
    use Glib;
    use Gtk2;
    
    require DynaLoader;
    
    our $VERSION = '0.001';
    
    our @ISA = qw(DynaLoader);
    
    sub import {
        my $class = shift;
        
        foreach(@_) {
            $class->VERSION($_);
        }
    }
    
    # this next bit causes problems on darwin, hence the conditional
    sub dl_load_flags {
        return $^O eq 'darwin' ? 0x00 : 0x01;
    }
    
    # and we're off
    Xfce4->bootstrap($VERSION);
}

1;
__END__

=head1 NAME

Xfce4 - Perl interface to the 4.2+ series of the Xfce core libraries.

=head1 SYNOPSIS

  use Gtk2;
  use Xfce4;
  
  Gtk2->init;
  
  my $aboutbox = Xfce4::AboutDialog->new;
  $aboutbox->run;

=head1 ABSTRACT

Perl bindings to the 4.2+ version of the Xfce core libraries.  This module
allows you to make use of Xfce-specific widgets in your gtk2-perl applications.

=head1 DESCRIPTION

The Xfce4 module allows perl developers to make use of the convenience
functions and classes present in the Xfce 4 core libraries.  Learn more
about Xfce at http://xfce.org/.

The Xfce 4 API reference is very useful when writing apps using xfce4-perl.
The call signatures will not always be identical, but one can get a good idea
of what the different functions and classes do:
http://xfce.org/documentation/api-4.2/

To discuss xfce4-perl, please join the Xfce Development Discussion list.
Instructions can be found at http://foo-projects.org/mailman/listinfo/xfce4-dev

Finally, the xfce4-perl website is located at:
http://spuriousinterrupt.org/projects/xfce4-perl/

=head1 AUTHORS

  Brian Tarricone <bjt23@cornell.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA  02111-1307  USA.

=cut
