package Win32::PEFile::PEBase;
use strict;
use warnings;
use Encode;
use Carp;
use Win32::PEFile::SectionHandlers;
use Win32::PEFile::PEConstants;


sub new {
    my ($class, %params) = @_;

    return bless \%params, $class;
}


sub AUTOLOAD {
    my ($self, @args) = @_;
    my $myClass = ref $self;
    my $fullMethod = $Win32::PEFile::PEBase::AUTOLOAD;
    (my $method = $fullMethod) =~ s/^([\w:]*):://;
    my $package = $1;
    my $class   = $Win32::PEFile::SectionHandlers::_EntryPoints{$method};

    Carp::confess "No such method '$fullMethod' defined for $myClass"
        if !defined $class;

    push @Win32::PEFile::PEBase::ISA, $class;
    return $self->$method(@args);
}


sub isOk {
    my ($self) = @_;
    return $self->{ok};
}


sub lastError {
    my ($self) = @_;
    return $self->{err};
}


sub _dispatch {
    my ($self, $method, $sectionCode, @args) = @_;

    Carp::confess "Not a recognised section code: $sectionCode"
        if !defined $sectionCode || !exists $kStdSectionCodeLu{$sectionCode};

    return if ! exists $Win32::PEFile::SectionHandlers::_SectionNames{$sectionCode};

    my $class = "$Win32::PEFile::SectionHandlers::_SectionNames{$sectionCode}";

    $method = "${class}::$method";
    return $self->$method(@args) if $self->can($method);

    $method = "${method}_$kStdSectionCodeLu{$sectionCode}";
    return $self->$method(@args) if $self->can($method);
    return '';
}


sub _readNameStr {
    my ($self, $fh, $nameFileAddr) = @_;
    my $nameStr = '';
    my $strEnd  = 0;
    my $oldLoc  = tell $fh;

    seek $fh, $nameFileAddr, 0 if defined $nameFileAddr;
    read $fh, $nameStr, 256, length $nameStr
        while !eof ($fh)
            and ($strEnd = index $nameStr, "\0") < 0;
    seek $fh, $oldLoc, 0 if defined $nameFileAddr;
    return substr $nameStr, 0, $strEnd;
}


1;


