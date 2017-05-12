package personal;

use 5.006_001;
use strict;
use File::Spec ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};

our $VERSION = '0.22';

our $Cache = {};
our $Count = 1;

# Public method
sub import : method {
  shift->_export( qw(personal) );

  if( @_ ) {
    my $cache = _personal_cache();
    my $class = shift;

    unless( $cache->{$class} ) {
      my $project = {
        class => $class,
        relative => _class2relative($class)
      };
      unless( _search_package($project) ) {
        _croak("Can't locate $project->{relative} in \@INC (\@INC contains: @INC)");
      } else {
        $project->{realname} = _class_newname();
        _compile_package($project);

        $cache->{$class} = {
          realname => $project->{realname}, mtime => $project->{filestat}[9],
          absolute => $project->{absolute},
        };
      }
    }

    if( @_
    and $cache->{$class}{realname}->can('import') ) {
      my @caller = caller;
      my $cinfo = $cache->{$class};

      eval qq(#line $caller[2] $caller[1]
        eval qq\(#line \$caller[2] \$caller[1]
          package \$caller[0]; \$cinfo->{realname}->import(\\\@_);
        \);
        die \$@ if \$@;
      );
      die $@ if $@;
    }
  }
}

# Public function
sub personal {
  my $cache = _personal_cache();
  my $class = shift;

  unless( exists $cache->{$class} ) {
    _croak("Package $class was not loaded with 'use personal'");
  } else {
    return $cache->{$class}{realname};
  }
}

# Private function: _search_package(PROJECT)
# Searching package in @INC. Returns true on success
sub _search_package {
  my $project = shift;

  foreach( @INC ) {
    my $t_path = File::Spec->catfile($_, $project->{relative});

    if( -f $t_path ) {
      $project->{filestat} = [ stat _ ];
      $project->{absolute} = File::Spec->rel2abs($t_path);
      return 1;
    }
  }
  return undef;
}

# Private function: _compile_package(PROJECT)
# Package compilation. Dieing on eny errors
sub _compile_package {
  my $project = shift;
  my $size = $project->{filestat}[7];
  my $fh;
  my $data;

  if( !open($fh, $project->{absolute})
  or  !binmode($fh) ) {
    _croak("Error opening $project->{relative}");
  }
  elsif( read($fh, $data, $size) != $size ) {
    _croak("Error reading $project->{relative}");
  }
  elsif( $data !~ s/^ *?package +?$project->{class}\b// ) {
    _croak("Package $project->{class} ",
           "is uncompatible with 'use personal'");
  }
  else {
    my @caller = caller 1;
    my $result = eval qq(#line $caller[2] $caller[1]
      my \$result = eval qq\(#line 1 \$project->{relative}
        package \$project->{realname} \$data
      \);
      warn \$@ if \$@;
      \$result;
    );
    warn $@ if $@;

    unless( $result ) {
      _carp("$project->{relative} did not return true value");
    }
    if( $@ or !$result ) {
      _croak("Compilation failed on 'use personal'");
    }
  }
}

# Private function: _class_newname()
# Generation of new unique personal class name
sub _class_newname {
  return sprintf( '%s::_%012d', __PACKAGE__, $Count++ );
}

# Private function: _class2relative(CLASS)
# Conversion class name to relative path of current FS
sub _class2relative {
  return File::Spec->catfile( split('::', shift) ).'.pm';
}

# Private function: _personal_cache()
# Returns reference to personal cache hash
sub _personal_cache {
  my $area;

  if( IS_MODPERL ) {
    my $r = Apache->request;
    $area = $r->dir_config('PersonalArea');
    $area = $r->filename unless defined($area);
  }
  $area = $0 unless defined($area);
  return $Cache->{$area} ||= {};
}

# Private method: SELF->_export( GLOB1, GLOB2, ... )
# Very simple exporter. Only for using from import() method in this package
sub _export : method {
  my $source = shift;
  my $destination = caller(1);

  no strict qw(refs);
  foreach( @_ ) {
    *{ "${destination}::$_" } = \&{ "${source}::$_" };
  }
}

# Private function: _carp(MESSAGE)
# Handling warnings
sub _carp {
  require Carp; &Carp::carp;
}

# Private function: _croak(REASON)
# Handling fatals
sub _croak {
  require Carp; &Carp::croak;
}

1;

__END__

=head1 NAME

personal - packages personalizer

=head1 SYNOPSIS

  use lib qw(.);
  use personal 'My::Package' => qw(func1 func2 $var1);

  personal('My::Package')->method;

=head1 DESCRIPTION

B<This is namespace collisions solution for scripts working under mod_perl.>

Every package, loaded with 'B<use personal>' will be renamed "on the fly"
into some unique name and tied to the current script. That mean, what every
script can have his personal packages.

To be compatible with 'B<use personal>' directive, package must pass this
three simple rules:

=over 4

=item *

One file - one package. Only one directive 'B<package>' must be presents
into file.

=item *

First line in file must be started with 'B<package>' directive.

=item *

Self-package name calls inside personal package must be called as 'B<__PACKAGE__>'
only. No one hardcoded self-package name must be presents.

=back

B<Important notice!> Under mod_perl2 you must using absolute paths to your
personal packages directories in 'B<use lib>' directive.

=head1 INTERFACE

=over 4

=item B<use personal 'PACKAGE'>

Alternative to 'B<use PACKAGE ()>'. PACKAGE will be compiled (if don't compiled yet)
without import() method calling.

=item B<use personal 'PACKAGE' =E<gt> qw(:DEFAULT)>

Alternative to 'B<use PACKAGE>'. The 'B<:DEFAULT>' is instruction for 'B<Exporter>'
module for exporting default symbols.

=item B<use personal PACKAGE =E<gt> qw( ... )>

Alternative to 'B<use PACKAGE qw( ... )>'.

B<Important notice!> You can using your own import() method in your personal packages
as you wish, without any limits.

=item B<personal(PACKAGE)>

Returns real package name. Argument PACKAGE must be one of the names of loaded
packages for the current area.

Real names looks like: personal::_000000000001, personal::_000000000002, etc...

=back

=head1 EXPORT

Function B<personal()> is exporting alltimes.

=head1 ADVANCED FEATURE

By default all personal packages tied to script name, but you can share some
personal packages between some different scripts under mod_perl. For this you
can using directive 'B<PerlSetVar PersonalArea>' in httpd.conf:

  <Directory /some/dir>
    PerlSetVar PersonalArea "area_1"
  </Directory>

In this example all mod_perl scripts in B</some/dir> will have they common
personal packages tied to "B<area_1>" key.

=head1 BACKWARD COMPATIBILITY

mod_cgi also supported without any changes.

=head1 NOTES

personal::Reloader will be soon. General idea of this sub-class will be next:
if any changes of personal packages based on some script(s) will be detected,
then all that personal packages will be deleted from cache and all that
script(s) will be reloaded. This will guarantee correct symbols re-importing.

=head1 BUGS

Please report them to author.

=head1 AUTHOR

Andrian Zubko aka Ondr, E<lt>ondr@cpan.orgE<gt>

=cut
