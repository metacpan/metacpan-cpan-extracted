package WWW::MLite::Util; # $Id: Util.pm 15 2014-06-04 06:24:25Z minus $
use strict;

=head1 NAME

WWW::MLite::Util - Utility functions

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use WWW::MLite::Util;

=head1 DESCRIPTION

Internal utility functions

=over 8

=item B<getHiTime>

See function L<Time::HiRes/gettimeofday>

=item B<getSID>

    my $sid = getSID( $length, $chars );
    my $sid = getSID( 16, "m" ); # 16 successful chars consisting of MD5 hash
    my $sid = getSID( 20 ); # 20 successful chars consisting of a set of chars 0-9A-Z
    my $sid = getSID(); # 16 successful chars consisting of a set of chars 0-9A-Z

Function returns Session-ID (SID)

$chars - A string containing a collection of characters or code:

    d - characters 0-9
    w - characters A-Z
    h - HEX characters 0-9A-F
    m - Digest::MD5 function from Apache::Session::Generate::MD5
      - default characters 0-9A-Z

=item B<sendmail, send_mail>

    my $sendstatus = sendmail(
        -to         => $mlite->conf->server_admin,
        -cc         => 'foo@example.com',   ### OPTIONAL
        -from       => sprintf('"%s" <%s>',$mlite->conf->server_name,$mlite->conf->server_admin),
        -subject    => 'Subject',
        -message    => 'Message',
        
        # Encoding/Types
        -type       => 'text/plain',        ### OPTIONAL
        -charset    => 'windows-1251',      ### OPTIONAL
        
        # Program sendmail
        -sendmail   => '/usr/sbin/sendmail',### OPTIONAL
        -flags      => '-t',                ### OPTIONAL
        
        # SMTP
        -smtp       => ($mlite->conf->smtp_host || ''),    ### OPTIONAL
        -smtpuser   => ($mlite->conf->smtp_user || ''),    ### OPTIONAL
        -smtppass   => ($mlite->conf->smtp_password || ''),### OPTIONAL
        
        # Attaches
        -attach => [                        ### OPTIONAL
                { 
                    Type=>'text/plain', 
                    Data=>'document 1 content', 
                    Filename=>'doc1.txt', 
                    Disposition=>'attachment',
                },
                
                {
                    Type=>'text/plain', 
                    Data=>'document 2 content', 
                    Filename=>'doc2.txt', 
                    Disposition=>'attachment',
                },
                
                ### ... ###
            ],
    );

If you need to send a letter with only one attachment:

    -attach => {
        Type=>'text/html', 
        Data=>$att, 
        Filename=>'response.htm', 
        Disposition=>'attachment',
    },

or

    -attach => {
        Type=>'image/gif', 
        Path=>'aaa000123.gif',
        Filename=>'logo.gif', 
        Disposition=>'attachment',
    },

Sending mail via L<CTK::Util/sendmail>

=back

=head1 HISTORY

See C<CHANGES> file

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = '1.01';

use Time::HiRes qw(gettimeofday);
use Digest::MD5;
use CTK::Util qw/ :BASE /; # Утилитарий

use base qw/Exporter/;
our @EXPORT = qw(
        getSID
        getHiTime
        sendmail send_mail
    );
our @EXPORT_OK = @EXPORT;

sub getSID {
    # Процедура возвращает Session-ID (SID) для контроля состояния сессий
    # IN: 
    #  $length - Количество символов
    #  $chars  - Строка символов набора или код:
    #        d - символы 0-9
    #        w - символы A-Z
    #        h - шеснадцатиричные символы 0-9A-F
    #        m - Digest::MD5 function from Apache::Session::Generate::MD5
    #          - По умолчанию символы 0-9A-Z
    # OUT:
    #  SID
    my $length = shift || 16; # Количество символов в случайной последовательности
    my $chars    = shift || "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"; # Строка символов

    # Copyright(c) 2000, 2001 Jeffrey William Baker (jwbaker@acm.org)
    # Distribute under the Perl License
    # Source: Apache::Session::Generate::MD5
    return substr(
        Digest::MD5::md5_hex(
            Digest::MD5::md5_hex(
                time() . {} . rand() . $$
            )
        ), 0, $length) if $chars =~ /^\s*m\s*$/i;

    $chars = "0123456789" if $chars =~ /^\s*d\s*$/i;
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" if $chars =~ /^\s*w\s*$/i;
    $chars = "0123456789ABCDEF" if $chars =~ /^\s*h\s*$/i;
    
    my @rows = split //, $chars;
    
    my $retv = '';
    for (my $i=0; $i<$length; $i++) {
        $retv .= $rows[int(rand(length($chars)-1))]
    }
    
    return "$retv"
}
sub getHiTime { 
    return gettimeofday() 
}
sub sendmail {
    # Отправка письма с помощью модуля CTK::Util::send_mail
    my $self = shift;
    return CTK::Util::send_mail(@_);
}
sub send_mail { goto &sendmail };


1;