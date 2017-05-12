# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot;
$UAV::Pilot::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;
use File::Spec;
use File::ShareDir;
use File::HomeDir;
use Log::Log4perl;

use constant DIST_NAME     => 'UAV-Pilot';
use constant LOG_CONF_FILE => 'log4perl.conf';

our $LOG_WAS_INITD = 0;

# ABSTRACT: Base library for controlling UAVs


sub default_module_dir
{
    my ($class) = @_;
    my $dir = File::ShareDir::dist_dir( $class->DIST_NAME );
    return $dir;
}

sub default_config_dir
{
    my ($class) = @_;
    my $dir = File::HomeDir->my_dist_config( $class->DIST_NAME, {
        create => 1,
    });
    return $dir,
}

sub init_log
{
    my ($class) = @_;
    return if $LOG_WAS_INITD;
    my $conf_dir = $class->default_config_dir;
    my $log_conf = File::Spec->catfile( $conf_dir, $class->LOG_CONF_FILE );

    $class->_make_default_log_conf( $log_conf ) if ! -e $log_conf;

    Log::Log4perl::init( $log_conf );
    return 1;
}

sub checksum_fletcher8
{
    my ($class, @bytes) = @_;
    my $ck_a = 0;
    my $ck_b = 0;

    foreach (@bytes) {
        $ck_a = ($ck_a + $_)    & 0xFF;
        $ck_b = ($ck_b + $ck_a) & 0xFF;
    }

    return ($ck_a, $ck_b);
}

sub convert_32bit_LE
{
    my ($class, @bytes) = @_;
    my $val = $bytes[0]
        | ($bytes[1] << 8)
        | ($bytes[2] << 16)
        | ($bytes[3] << 24);
    return $val;
}

sub convert_16bit_LE
{
    my ($class, @bytes) = @_;
    my $val = $bytes[0] | ($bytes[1] << 8);
    return $val;
}

sub convert_32bit_BE
{
    my ($class, @bytes) = @_;
    my $val = ($bytes[0] << 24)
        | ($bytes[1] << 16)
        | ($bytes[2] << 8)
        | $bytes[3];
    return $val;
}

sub convert_16bit_BE
{
    my ($class, @bytes) = @_;
    my $val = ($bytes[0] << 8) | $bytes[1];
    return $val;
}

sub _make_default_log_conf
{
    my ($class, $out_file) = @_;

    open( my $out, '>', $out_file )
        or die "Can't open [$out_file] for writing: $!\n";

    print $out "log4j.rootLogger=WARN, A1\n";
    print $out "log4j.appender.A1=Log::Log4perl::Appender::Screen\n";
    print $out "log4j.appender.A1.layout=org.apache.log4j.PatternLayout\n";
    print $out "log4j.appender.A1.layout.ConversionPattern="
        . '%-4r [%t] %-5p %c %t - %m%n' . "\n";

    close $out;
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot - Base library for controlling UAVs

=head1 DESCRIPTION

This library does not support controlling any UAVs on its own.  Rather, it 
provides the basic support for implementing other UAV libraries, much the same 
way DBI provides support for implementing different database drivers.

If you would like to control the Parrot AR.Drone, you should also install 
C<UAV::Pilot::ARDrone>, and probably C<UAV::Pilot::SDL> and 
C<UAV::Pilot::Video::Ffmpeg> as well.

=head1 LICENSE

Copyright (c) 2014  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
