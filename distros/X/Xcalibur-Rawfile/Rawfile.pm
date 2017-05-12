package Xcalibur::Rawfile;

require 5.8.0;

use Win32::OLE;
use Win32::OLE::Variant;
use Exporter;

our @EXPORT_OK = qw( contains_ms2 );

our $VERSION = 0.1;

sub contains_ms2{
	my $rawfile = shift;
	Win32::OLE->Option( Warn => 3 );
	# type comes from c:\Xcalibur\system\programs\XRawfile2.dll
	my $x = eval{
		Win32::OLE->new('XRawfile.XRawfile.1', sub{ $_[0]->Close } );
	};
	if($@){
		die "Could not create XRawfile object.\nDo you have the Xcalibur Development Kit installed?\nWin32::OLE error was: $@\n";
	}
	$x->Open( $rawfile );
	$x->SetCurrentController( 0, 1 ); # mass spec device, first MS device
	
	# print $x->GetFilters( $var, $lng );
	# $var needs to be initialized to VT_EMPTY and VT_BYREF with VT_ARRAY returned
	# Win32::OLE::Variant doesn't let us do that

	# my $i = Win32::OLE::Variant->new(VT_I4|VT_BYREF, 0);
	# $x->GetNumSpectra($i);
	# print $i;

	my $first = Win32::OLE::Variant->new(VT_I4|VT_BYREF,0);
	my $last = Win32::OLE::Variant->new(VT_I4|VT_BYREF,0);
	$x->GetFirstSpectrumNumber($first);
	$x->GetLastSpectrumNumber($last);

	for my $i ( $first .. $last ){
		# do not pass an initialization value to new or it won't work
		# this requires Activestate perl 5.8.*
		my $filter = Win32::OLE::Variant->new(VT_BSTR|VT_BYREF);
		$x->GetFilterForScanNum($i,$filter);
		return 1 if $filter =~ /\sms2\s/i;
	}
	return 0;
}

1;

__END__

=head1 NAME

Xcalibur::Rawfile - Making use of the Xcalilbur XDK

=head1 SYNOPSIS

use Xcalibur::Rawfile qw( contains_ms2 );

if( contains_ms2( "data01.RAW" ) ){
	
	# do something
	# such as analyze the ms2 spectra with SEQUEST
	
}

...

=head1 DESCRIPTION

Xcalibur software provides instrument control and data analysis for Thermo Finnigan mass spectrometers and related instruments.

<quote>

The Xcalibur Development Kit is a suite of programmable COM objects which allow display and manipulation of Xcalibur data and access to Xcalibur files. The objects are primarily intended to be used in either Visual C++ or Visual Basic to write specialised applications for use with Xcalibur. 

</quote>

As a COM interface the XDK can be manipulated in perl via Win32::OLE. 
Win32::OLE::Variant is also required because the XDK returns variants by reference.
To pass an uninitialized VT_BSTR|VT_BYREF requires Activestate perl 5.8.*

It is envisioned that this module will contain utility functions that will make it easier to work with the Xcalibur XDK.

=over

=head1 SEE ALSO

http://www.thermo.com/

file:///C:/Xcalibur/Help/xdkhelp/index.htm

file:///C:/Xcalibur/examples/xdk/

( if you have Xcalibur and the XDK installed on your system )

=head1 ACKNOWLEDGEMENTS

David Stranz ( david_stranz@massspec.com ) for introducing me to the XDK and showing me a Visual Basic example of how to work out which raw files contain MS2 spectra.

=head1 AUTHOR

Mark Southern (msouthern@exsar.com)

=head1 COPYRIGHT

Copyright (c) 2003, ExSAR Corporation. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
