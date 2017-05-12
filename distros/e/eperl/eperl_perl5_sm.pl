##
##  eperl_perl5_sm.pl -- Determine newXS() calls for XS-Init function
##  Copyright (c) 1997 Ralf S. Engelschall, All Rights Reserved. 
##

use Config;

print <<'EOT'
/*
**        ____           _ 
**    ___|  _ \ ___ _ __| |
**   / _ \ |_) / _ \ '__| |
**  |  __/  __/  __/ |  | |
**   \___|_|   \___|_|  |_|
** 
**  ePerl -- Embedded Perl 5 Language
**
**  ePerl interprets an ASCII file bristled with Perl 5 program statements
**  by evaluating the Perl 5 code while passing through the plain ASCII
**  data. It can operate both as a standard Unix filter for general file
**  generation tasks and as a powerful Webserver scripting language for
**  dynamic HTML page programming. 
**
**  ======================================================================
**
**  Copyright (c) 1996,1997 Ralf S. Engelschall, All rights reserved.
**
**  This program is free software; it may be redistributed and/or modified
**  only under the terms of either the Artistic License or the GNU General
**  Public License, which may be found in the ePerl source distribution.
**  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
**  a built-in copy of both license files.
**
**  This program is distributed in the hope that it will be useful, but
**  WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
**  Artistic License or the GNU General Public License for more details.
**
**  ======================================================================
**
**  eperl_perl5_sm.h -- Perl 5 Static Module definition 
*/
#ifndef EPERL_PERL5_SM_H
#define EPERL_PERL5_SM_H 1

EOT
;

#
#   code stolen from Perl 5.004_04's ExtUtils::Embed because
#   this module is only available in newer Perl versions.
#

sub static_ext {
    unless (scalar @Extensions) {
        @Extensions = sort split /\s+/, $Config{static_ext};
        unshift @Extensions, qw(DynaLoader);
    }
    return @Extensions;
}
sub xsi_body {
    my(@exts) = @_;
    my($pname,@retval,%seen);
    my($dl) = &canon('/','DynaLoader');
    foreach $_ (@exts){
        my($pname) = &canon('/', $_);
        my($mname, $cname, $ccode);
        ($mname = $pname) =~ s!/!::!g;
        ($cname = $pname) =~ s!/!__!g;
        if ($pname eq $dl){
            $ccode = "newXS(\"${mname}::boot_${cname}\", boot_${cname}, file);\\\n";
            push(@retval, $ccode) unless $seen{$ccode}++;
        } else {
            $ccode = "newXS(\"${mname}::bootstrap\", boot_${cname}, file);\\\n";
            push(@retval, $ccode) unless $seen{$ccode}++;
        }
    }
    return join '', @retval;
}
sub canon {
    my($as, @ext) = @_;
    foreach(@ext) {
       # might be X::Y or lib/auto/X/Y/Y.a
       next if s!::!/!g;
       s:^(lib|ext)/(auto/)?::;
       s:/\w+\.\w+$::;
    }
    grep(s:/:$as:, @ext) if ($as ne '/');
    return @ext;
}
@mods = ();
push(@mods, &static_ext());
@mods = grep(!$seen{$_}++, @mods);
$DEF = "#define DO_NEWXS_STATIC_MODULES \\\n";
$DEF .= &xsi_body(@mods);
$DEF =~ s|\\\n$|\n|s;
print $DEF;

print <<EOT

#endif /* EPERL_PERL5_SM_H */
/*EOF*/
EOT
;

##EOF##
