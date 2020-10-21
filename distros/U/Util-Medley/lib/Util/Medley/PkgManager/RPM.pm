package Util::Medley::PkgManager::RPM;
$Util::Medley::PkgManager::RPM::VERSION = '0.051';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Kavorka 'method', 'multi';

with
  'Util::Medley::Roles::Attributes::Spawn',
  'Util::Medley::Roles::Attributes::String';

=head1 NAME

Util::Medley::PkgManager::RPM - Class for interacting with RPM

=head1 VERSION

version 0.051

=cut

=head1 SYNOPSIS

  my $rpm = Util::Medley::PkgManager::RPM->new;
  
  #
  # positional  
  #
  $aref = $yum->queryAll([$rpmName]);
  $aref = $rpm->queryList($rpmName);
                        
  #
  # named pair
  #
  $aref = $yum->queryAll([rpmName => $rpmName]);
  $aref = $rpm->queryList(rpmName => $rpmName);

=cut

########################################################

=head1 DESCRIPTION

A simple wrapper library for the Redhat Package Manager.

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 queryAll

Query all installed packages.

Returns: ArrayRef[Str]

=over

=item usage:

 $aref = $yum->queryAll([$rpmName]);
 $aref = $yum->queryAll([rpmName => $rpmName]);
 
=item args:

=over

=item rpmName [Str] (optional)

The name of the rpm package to query.  This arg can contain wildcards.

=back

=back

=cut

multi method queryAll (Str :$rpmName) {

    my @cmd;
    push @cmd, 'rpm';
    push @cmd, '--query';
    push @cmd, '--all';
    push @cmd, $rpmName if $rpmName;
    
    my ($stdout, $stderr, $exit) = 
        $self->Spawn->capture(cmd => \@cmd, wantArrayRef => 1);
    if ($exit) {
        confess $stderr;    
    } 
    
    return $stdout;
}

multi method queryAll (Str $rpmName?) {

    my %a;
    $a{rpmName} = $rpmName if $rpmName;
    
    return $self->queryAll(%a);
}

=head2 queryList

List files in package.

Returns: ArrayRef[Str]

=over

=item usage:

 $aref = $yum->queryList($rpmName);

 $aref = $yum->queryList(rpmName => $rpmName);
 
=item args:

=over

=item rpmName [Str] (required)

The name of the rpm package to query.

=back

=back

=cut

multi method queryList (Str :$rpmName!) {

    my @cmd;
    push @cmd, 'rpm';
    push @cmd, '--query';
    push @cmd, '--list';
    push @cmd, $rpmName;
    
    my ($stdout, $stderr, $exit) = $self->Spawn->capture(cmd => \@cmd, wantArrayRef => 1);
    if ($exit) {
        confess $stderr;	
    } 
    
    return $stdout;
}

multi method queryList (Str $rpmName!) {

    return $self->queryList(rpmName => $rpmName);	
}

#################################################################3

1;
