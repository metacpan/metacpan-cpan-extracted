package Util::Medley::YAML;
$Util::Medley::YAML::VERSION = '0.059';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use Carp;
use YAML;

with 'Util::Medley::Roles::Attributes::List';

=head1 NAME

Util::Medley::YAML - utility YAML methods

=head1 VERSION

version 0.059

=cut

=head1 SYNOPSIS

 my $util = Util::Medley::YAML->new;

=cut

########################################################

=head1 DESCRIPTION

Provides utility methods for working with YAML.  All methods confess on
error.

=cut

########################################################

=head1 METHODS

=head2 yamlDecode 

=cut

method decode (Str $yaml) {

    my @yaml = YAML::Load($yaml);    
    
    return @yaml;        
}

=head2 yamlEncode

=cut

method encode(ArrayRef|HashRef $data) {

    if (ref($data) eq 'HASH') {
        $data = [ $data ];     
    }
    
    my $str = YAML::Dump(@$data);     
    
    return $str;
}

=head2 yamlRead

=cut

method read (Str $path) {
    
    my @yaml = YAML::LoadFile($path);    
    
    return @yaml;
}

=head2 yamlWrite 

=cut

method write (Str              $path,
              ArrayRef|HashRef $data) {

    if (ref($data) eq 'HASH') {
        $data = [ $data ];     
    }
    
    YAML::DumpFile($path, @$data);    
}

1;
