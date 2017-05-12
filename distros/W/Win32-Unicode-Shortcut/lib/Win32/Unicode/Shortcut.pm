package Win32::Unicode::Shortcut;

use strict;
use warnings;
use Exporter;
use AutoLoader;
use Carp;
use Win32::API;
use Encode;

our @ISA = qw/Exporter AutoLoader/;
use vars qw/$AUTOLOAD/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Unicode::Shortcut ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
                    COINIT_APARTMENTTHREADED
                    COINIT_MULTITHREADED
                    COINIT_DISABLE_OLE1DDE
                    COINIT_SPEED_OVER_MEMORY
                    SLGP_SHORTPATH
                    SLGP_UNCPRIORITY
                    SW_HIDE
                    SW_MINIMIZE
                    SW_RESTORE
                    SW_SHOW
                    SW_SHOWMAXIMIZED
                    SW_SHOWMINIMIZED
                    SW_SHOWMINNOACTIVE
                    SW_SHOWNA
                    SW_SHOWNOACTIVE
                    SW_SHOWNORMAL
);

our $VERSION = '0.04';
our $utf16le = find_encoding('UTF-16LE') ||
    croak "Failed to load UTF16-LE encoding\n";
our $GetFullPathNameW = Win32::API->new('kernel32.dll', 'GetFullPathNameW', 'PNPP', 'N') ||
    croak "Failed to load GetFullPathNameW\n";
our $CROAK_ON_ERROR = 0;

require XSLoader;
XSLoader::load('Win32::Unicode::Shortcut', $VERSION);

# Preloaded methods go here.
{
    no warnings 'redefine';
    sub AUTOLOAD {
	my $sub = $AUTOLOAD;
	(my $constname = $sub) =~ s/.*:://;
	my $val = constant($constname);
	if ($! != 0) {
	    if ($! =~ /Invalid/ || $!{EINVAL}) {
		$AutoLoader::AUTOLOAD = $sub;
		goto &AutoLoader::AUTOLOAD;
	    }
	    else {
		croak "Your vendor has not defined constant $constname";
	    }
	}
	{
	    no strict 'refs';
	    *$sub = sub { $val }; # same as: eval "sub $sub { $val }";
	    goto &$sub;
	}
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

#=================
sub CoInitializeEx {
#=================
    my ($class, $coinit, $croak_on_failure) = @_;

    return(_CoInitializeEx($coinit, $croak_on_failure || $CROAK_ON_ERROR));
}

#===============
sub CoInitialize {
#===============
    my ($class, $croak_on_failure) = @_;

    return(_CoInitialize($croak_on_failure || $CROAK_ON_ERROR));
}

#===============
sub CoUninitialize {
#===============
    my ($class) = @_;

    _CoUninitialize();
}

#========
sub new {
#========
    my ($class, $file) = @_;
    my ($ilink, $ifile) = _Instance($CROAK_ON_ERROR);
    return unless $ilink && $ifile;

    my $self = bless {
        ilink            => $ilink,
        ifile            => $ifile,
        File             => '',
        Path             => '',
        Arguments        => '',
        WorkingDirectory => '',
        Description      => '',
        ShowCmd          => 0,
        Hotkey           => 0,
        IconLocation     => '',
        IconNumber       => 0,
    };

    if ($file) {
	$self->{File} = $file;
	$self->Load($file);
    }

    return $self;
}

#=========
sub Load {
#=========
    my ($self, $file) = @_;
    return undef unless ref($self);

    my $result = _Load($self->{'ilink'}, $self->{'ifile'}, $file, $CROAK_ON_ERROR);

    if ($result) {

        # fill the properties of $self
        $self->{'File'}             = $file;
        $self->{'Path'}             = _GetPath($self->{'ilink'}, $self->{'ifile'}, 0, $CROAK_ON_ERROR);
        $self->{'ShortPath'}        = _GetPath($self->{'ilink'}, $self->{'ifile'}, 1, $CROAK_ON_ERROR);
        $self->{'Arguments'}        = _GetArguments($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
        $self->{'WorkingDirectory'} = _GetWorkingDirectory($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
        $self->{'Description'}      = _GetDescription($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
        $self->{'ShowCmd'}          = _GetShowCmd($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
        $self->{'Hotkey'}           = _GetHotkey($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
        ($self->{'IconLocation'},
         $self->{'IconNumber'})     = _GetIconLocation($self->{'ilink'}, $self->{'ifile'}, $CROAK_ON_ERROR);
    }
    return $result;
}


#========
sub Set {
#========
    my ($self, $path, $arguments, $dir, $description, $show, $hotkey,
	$iconlocation, $iconnumber) = @_;
    return undef unless ref($self);

    $self->{'Path'}             = $path;
    $self->{'Arguments'}        = $arguments;
    $self->{'WorkingDirectory'} = $dir;
    $self->{'Description'}      = $description;
    $self->{'ShowCmd'}          = $show;
    $self->{'Hotkey'}           = $hotkey;
    $self->{'IconLocation'}     = $iconlocation;
    $self->{'IconNumber'}       = $iconnumber;
    return 1;
}


#=========
sub Save {
#=========
    my ($self, $file) = @_;
    return unless ref($self);

    $file = $self->{'File'} unless $file;
    return unless $file;

    $file = $utf16le->decode($self->_GetFullPathNameW($utf16le->encode("$file\0")));

    _SetPath($self->{'ilink'}, $self->{'ifile'}, $self->{'Path'}, $CROAK_ON_ERROR);
    _SetArguments($self->{'ilink'}, $self->{'ifile'}, $self->{'Arguments'}, $CROAK_ON_ERROR);
    _SetWorkingDirectory($self->{'ilink'}, $self->{'ifile'}, $self->{'WorkingDirectory'}, $CROAK_ON_ERROR);
    _SetDescription($self->{'ilink'}, $self->{'ifile'}, $self->{'Description'}, $CROAK_ON_ERROR);
    _SetShowCmd($self->{'ilink'}, $self->{'ifile'}, $self->{'ShowCmd'}, $CROAK_ON_ERROR);
    _SetHotkey($self->{'ilink'}, $self->{'ifile'}, $self->{'Hotkey'}, $CROAK_ON_ERROR);
    _SetIconLocation($self->{'ilink'}, $self->{'ifile'},
                     $self->{'IconLocation'}, $self->{'IconNumber'}, $CROAK_ON_ERROR);

    my $result = _Save($self->{'ilink'}, $self->{'ifile'}, $file, $CROAK_ON_ERROR);
    if ($result) {
	$self->{'File'} = $file unless $self->{'File'};
    } else {
        carp "Failed to save shortcut, $^E\n";
    }
    return $result;
}

#============
sub Resolve {
#============
    my ($self, $flags) = @_;
    return undef unless ref($self);
    $flags = 1 unless defined($flags);
    my $result = _Resolve($self->{'ilink'}, $self->{'ifile'}, $flags, $CROAK_ON_ERROR);
    return $result;
}


#==========
sub Close {
#==========
    my ($self) = @_;
    return undef unless ref($self);

    my $result = _Release($self->{'ilink'}, $self->{'ifile'});
    $self->{'released'} = 1;
    return $result;
}

#=========
sub Path {
#=========
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'Path'};
    } else {
        $self->{'Path'} = $value;
    }
    return $self->{'Path'};
}

#==============
sub ShortPath {
#==============
    my ($self) = @_;
    return undef unless ref($self);
    return $self->{'ShortPath'};
}

#==============
sub Arguments {
#==============
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'Arguments'};
    } else {
        $self->{'Arguments'} = $value;
    }
    return $self->{'Arguments'};
}

#=====================
sub WorkingDirectory {
#=====================
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'WorkingDirectory'};
    } else {
        $self->{'WorkingDirectory'} = $value;
    }
    return $self->{'WorkingDirectory'};
}


#================
sub Description {
#================
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'Description'};
    } else {
        $self->{'Description'} = $value;
    }
    return $self->{'Description'};
}

#============
sub ShowCmd {
#============
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'ShowCmd'};
    } else {
        $self->{'ShowCmd'} = $value;
    }
    return $self->{'ShowCmd'};
}

#===========
sub Hotkey {
#===========
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'Hotkey'};
    } else {
        $self->{'Hotkey'} = $value;
    }
    return $self->{'Hotkey'};
}

#=================
sub IconLocation {
#=================
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'IconLocation'};
    } else {
        $self->{'IconLocation'} = $value;
    }
    return $self->{'IconLocation'};
}

#===============
sub IconNumber {
#===============
    my ($self, $value) = @_;
    return undef unless ref($self);

    if(not defined($value)) {
        return $self->{'IconNumber'};
    } else {
        $self->{'IconNumber'} = $value;
    }
    return $self->{'IconNumber'};
}

#============
sub Version {
#============
    return $VERSION;
}


#######################################################################
# PRIVATE METHODS
#

#============
sub DESTROY {
#============
    my ($self) = @_;

    if (not $self->{'released'}) {
        _Release($self->{'ilink'}, $self->{'ifile'});
	$self->{'released'} = 1;
    }
}

#====================
sub _GetFullPathNameW
#====================
{
    my ($self, $in) = @_;

    my $len = 0;
    $len = $GetFullPathNameW->Call($in, 0, 0, 0);
    my $len2 = $len * 2;
    my $out = ' ' x $len2;
    $len = $GetFullPathNameW->Call($in, $len, $out, 0);
    $out = substr($out, 0, $len2);

    return($out);
}

1;
__END__
=head1 NAME

Win32::Unicode::Shortcut - Perl extension for Windows Unicode Shortcut interface

=head1 SYNOPSIS

  use Win32::Unicode::Shortcut;

  BEGIN { Win32::Unicode::Shortcut->CoInitialize(); }

  my $LINK = new Win32::Unicode::Shortcut;
  $LINK->{'Path'} = "notepad.exe";
  my $target = "C:\\Windows\\Temp\\Target.lnk";
  $LINK->{'Arguments'} = "Euro-sign:" . chr(8364) . ", Chinese character: " . chr(25105);
  $LINK->{'WorkingDirectory'} = "C:\\";
  $LINK->{'Description'} = "Target Description with alef character: \x{05D0}";
  $LINK->{'ShowCmd'} = 1;
  $LINK->{'Hotkey'} = 115;
  $LINK->{'IconLocation'} = "%SystemRoot%\\system32\\SHELL32.dll";
  $LINK->{'IconNumber'} = 10;

  $LINK->Save($target);
  $LINK->Close();

  END { Win32::Unicode::Shortcut->CoUninitialize(); }

=head1 DESCRIPTION

This is the Unicode version of Win32::Shortcut. This module exposes all methods of Win32::Shortcut, plus the initialisation layer which is application specific. So the whole documentation of Win32::Unicode::Shortcut consists of: the documentation of Win32::Shortcut that the reader should read first, and the Methods section below.

Any bug in Win32::Unicode::Shortcut should be nevertheless send to me via RT of course -;

=head2 Methods

=over 8

=item Win32::Unicode::Shortcut->CoInitialize([CROAK_ON_FAILURE])

Unless your application has already initialized the COM layer, via Win32::OLE or Win32::API for example, you will have to do so.

=item Win32::Unicode::Shortcut->CoInitializeEx(COINIT_CONSTANT[, CROAK_ON_FAILURE])

You can have fine-grained granularity on the threading model, using CoInitializeEx. The COINIT_CONSTANT must be of one COINIT_APARTMENTTHREADED, COINIT_MULTITHREADED, COINIT_DISABLE_OLE1DDE or COINIT_SPEED_OVER_MEMORY.

=back

=head2 EXPORT

None by default.

=head2 NOTES

If the variable $Win32::Unicode::Shortcut::CROAK_ON_ERROR is setted to a true value, then the module will croak at any Windows API call error, with a meaningful message. For example doing a Load without an COM application initialisation will look like the following:

C:\>perl -e "use Win32::Unicode::Shortcut; $Win32::Unicode::Shortcut::CROAK_ON_ERROR = 1; $L = new Win32::Unicode::Shortcut;"
CoCreateInstance, CoInitialize has not been called

It is advisable to set this variable before the initialisation, and to reset it after, or to use the optional parameter of the initialisation functions to get it temporarly on during their execution.

None by default.

=head1 SEE ALSO

Win32::Shortcut
Understanding and Using COM Threading Models at http://msdn.microsoft.com/en-us/library/ms809971.aspx
Win32::OLE

=head1 AUTHOR

Jean-Damien Durand, E<lt>jeandamiendurand@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jean-Damien Durand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
