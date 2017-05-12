package Win32::PEFile;
use strict;
use warnings;
use Encode;
use Carp;
use Win32::PEFile::PEBase;
use Win32::PEFile::PEWriter;
use Win32::PEFile::PEReader;
use Win32::PEFile::PEConstants;

use vars qw($VERSION);

$Win32::PEFile::VERSION = '0.7007';

push @Win32::PEFile::ISA, 'Win32::PEFile::PEBase';


sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);

    if ($params{'-create'}) {
        $self->{writer} = Win32::PEFile::PEWriter->new (owner => $self, %params);
    } elsif ($params{'-file'}) {
        $self->{reader} = Win32::PEFile::PEReader->new (owner => $self, %params);
    }

    $self->{err} = $@ || '';
    return $self;
}


sub getSectionNames {
    my ($self) = @_;
    my @names = keys %{$self->{DataDir}};
    my @sections = grep {$self->{DataDir}{$_}{size}} @names;

    return @sections;
}


sub setMSDOSStub {
    my ($self, $stub) = @_;

    $self->{MSDOSStub} = $stub;
}


sub getMSDOSStub {
    my ($self) = @_;

    return $self->{MSDOSStub};
}


sub writeFile {
    my ($self, %params) = @_;

    $self->{writer} = Win32::PEFile::PEWriter->new (owner => $self, %params)
        if ! $self->{writer};

    return $self->{writer}->writeFile();
}


1;


=head1 NAME

Win32::PEFile - Portable Executable File parser

=head1 SYNOPSIS

    use Win32::PEFile;

    my $pe = Win32::PEFile->new (-file => 'someFile.exe');

    print "someFile.exe has a entry point for EntryPoint1"
        if $pe->getEntryPoint ("EntryPoint1");

    my $strings = $pe->getVersionStrings ();
    print "someFile.exe version $strings->{'ProductVersion'}\n";

=head1 Methods

Win32::PEFile provides the following public methods.

=over 4

=item C<new (%parameters)>

Parses a PE file and returns an object used to access the results. The following
parameters may be passed:

=over 4

=item I<-file>: file name, required

The file name (and path if required) of the PE file to process.

=back

=item C<getSectionNames()>

Return the list of named sections present in the PEFile.

=item C<setMSDOSStub($stub)>

Set the MS-DOS stub code. C<$stub> contains the code as a raw binary blob.

=item C<getMSDOSStub()>

Return a string containing MS-DOS stub code as a raw binary blob.

=back

=head1 Section methods

The helper module Win32::PEFile::SectionHandlers provides handlers for various
sections. At present only a few of the standard sections are handled and
documented here. If there are sections that you would like to be able to
manipulate that are not currently handled enter a ticket using CPAN's request
tracker (see below).

=head2 .rsrc

Resource section. At present only access to the version resource is provided,
although the other resources are parsed internally.

=over 4

=item C<getVersionStrings ($language)>

Returns a hash reference containing the strings in the version resource keyed
by string name.

=back

=over 4

=item C<getVersionCount ($language)>

Returns a count of version resources.

=over 4

=item I<$language>: optional

Selected language specified as a MicroSoft LangID. If the language is not
specified all language variants are counted.

=back

=back

=item C<getFixedVersionValues ($language)>

Returns a hash reference containing the fixed version resource values keyed
by value name.

=item C<getResourceData ($type, $name, $language)>

Returns a string containg the raw data for the specified resource or undef if
the resource doesn't exist.

=over 4

=item I<$language>: optional

Preferred language for the strings specified as a MicroSoft LangID. US English
is preferred by default.

If the preferred language is not available one of the available languages will
be used instead.

=back

=back

=head2 .edata

Exports section.

=over 4

=item C<getExportNames ()>

Returns a list of all the named entry points.

=item C<getExportOrdinalsCount ()>

Returns the count of all the ordinal entry points.

=item C<haveExportEntry ($entryPointName)>

Returns true if the given entry point exists in the exports table. For
compatibility with previous versions of the module C<getEntryPoint
($entryPointName)> is provided as an alias for C<haveExportEntry
($entryPointName)>.

=over 4

=item I<$entryPointName>: required

Name of the entry point to search for in the Exports table of the PE file.

=back

=back

=head2 .idata

=over 4

=item C<getImportNames ()>

Returns a hash keyed by .DLL name of lists of all the named entry points.

=item C<getImportNamesArray ()>

Returns the list of .DLL names in table entry order.

=item C<haveImportEntry ($entryPath)>

Returns true if the given entry point exists in the imports table.

=over 4

=item I<$entryPath>: required

Path to the entry point to search for in the Imorts table of the PE file. The
path is in the form C<'dll name/entry name'>. For example:

    my $havePrintf = $pe->haveImportEntry('MSVCR80.dll/printf');

would set C<$havePrintf> true if the PE file has an import entry for the
MicroSoft C standard library version of printf.

=back

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Win32-PEFile at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-PEFile>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

This module is supported by the author through CPAN. The following links may be
of assistance:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-PEFile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-PEFile>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-PEFile>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-PEFile>

=back

=head1 SEE ALSO

=head2 Related documentation

http://kishorekumar.net/pecoff_v8.1.htm

=head2 Win32::Exe and Win32::PEFile

Win32::PEFile overlaps in functionality with Win32::Exe. Win32::Exe is a much
more mature module and is more comprehensive. The only current (small)
disadvantages of Win32::Exe are that it is not pure Perl and that has a larger
dependency tree than Win32::PEFile.

For some applications a larger problem with Win32::Exe is that some file editing
operations are not portable across systems.

The intent is that Win32::PEFile will remain pure Perl and low dependency. Over
time PEFile will acquire various editing functions and will remain both cross-
platform and endien agnostic.

=head1 ACKNOWLEDGEMENTS

Thank you Engin Bulanik for contributing the seed code for getVersionCount().

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
