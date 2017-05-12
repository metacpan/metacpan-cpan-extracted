#######################################################
# Cookie lib
#######################################################
#####################################################################

# Copyright (c) 2001, Julian Lishev, Sofia 2002
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.

#####################################################################
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# HTTP Cookie Library may be used and modified free of charge by anyone so   #
# long as this copyright notice and the comments above remain intact.  By    #
# using this code you agree to indemnify Matthew M. Wright from any          #
# liability that might arise from it's use.                                  #  
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.  In all cases copyright and header must remain intact #
##############################################################################

@Cookie_Encode_Chars = ('\%', '\+', '\;', '\,', '\=', '\&', '\:\:', '\s');
%Cookie_Encode_Chars = ('\%',   '%25', '\+',   '%2B', '\;',   '%3B',
                        '\,',   '%2C', '\=',   '%3D', '\&',   '%26',
                        '\:\:', '%3A%3A',  '\s',   '+');
@Cookie_Decode_Chars = ('\+', '\%3A\%3A', '\%26', '\%3D', '\%2C', '\%3B', '\%2B', '\%25');
%Cookie_Decode_Chars = ('\+',       ' ',  '\%3A\%3A', '::',  '\%26',     '&',
                        '\%3D',     '=',  '\%2C',     ',',   '\%3B',     ';',
                        '\%2B',     '+',  '\%25',     '%');


sub SetCookieExpDate
{
    my $expd = shift(@_);
    require $library_path.'utl.pl';
    my $expire = expires($expd,'cookie');
    $cookie_exp_date_cgi = $expire;
    return 1;
}

sub SetCookiePath 
{

    $cookie_path_cgi = $_[0];
}

sub SetCookieDomain
{

    if ($_[0] =~ /\..+\..+$/) {
        $cookie_domain_cgi = $_[0];
        return 1;
       }
    else {
        return 0;
    }
}

##############################################################################
# Subroutine:    &GetCookies()                                               #
# Description:   This subroutine can be called with or without arguments. If #
#                arguments are specified, only cookies with names matching   #
#                those specified will be set in %Cookies.  Otherwise, all    #
#                cookies sent to this script will be set in %Cookies.        #
# Usage:         &GetCookies([cookie_names])                                 #
# Variables:     cookie_names - These are optional (depicted with []) and    #
#                               specify the names of cookies you wish to set.#
#                               Can also be called with an array of names.   #
#                               Ex. 'name1','name2'                          #
# Returns:       1 - If successful and at least one cookie is retrieved.     #
#                0 - If no cookies are retrieved.                            #
##############################################################################

sub GetCookies {

    local(@ReturnCookies) = @_;
    local($cookie_flag) = 0;
    local($cookie,$value);
    my $row_cookies = $ENV{'HTTP_COOKIE'} || $ENV{'COOKIE'};
    if ($row_cookies) {

       if ($ReturnCookies[0] ne '') {

          foreach (split(/; /,$row_cookies)) {

               ($cookie,$value) = split(/=/);

               foreach $char (@Cookie_Decode_Chars) {
                    $cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                    $value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                }

               foreach $ReturnCookie (@ReturnCookies) {

                    if ($ReturnCookie eq $cookie) {
                        $Cookies{$cookie} = $value;
                        $cookie_flag = "1";
                    }
                }
            }

        }

       else {

            foreach (split(/; /,$row_cookies)) {
                ($cookie,$value) = split(/=/);

            foreach $char (@Cookie_Decode_Chars) {
                    $cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                    $value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                }

                $Cookies{$cookie} = $value;
            }
            $cookie_flag = 1;
        }
    }

    return $cookie_flag;
}

##############################################################################
# Subroutine:    &SetSecureCookie()                                          #
# Usage:         &SetSecureCookie('flag')                                    #
# Variables:     flag - 0 or 1 depending whether you want it secure or not   #
#                       secure.  By default, it is set to unsecure, unless   #
#                       $secure_cookie_cgi was changed at the top.               #
#                       Ex. 1                                                #
##############################################################################

sub SetSecureCookie {

    if ($_[0] =~ /^[01]$/) {
        $secure_cookie_cgi = $_[0];
        return 1;
    }
    else {
        return 0;
    }
}

##############################################################################
# Subroutine:    &SetCookies()                                               #
# Description:   Sets one or more cookies by printing out the Set-Cookie     #
#                HTTP header to the browser, based on cookie information     #
#                passed to subroutine.                                       #
# Usage:         &SetCookies(name1,value1,...namen,valuen)                   #
# Variables:     name  - Name of the cookie to be set.                       #
#                        Ex. 'count'                                         #
#                value - Value of the cookie to be set.                      #
#                        Ex. '3'                                             #
#                n     - This is tacked on to the last of the name and value #
#                        pairs in the usage instructions just to show you    #
#                        you can have as many name/value pairs as you wish.  #
##############################################################################

sub SetCookies {

    local(@cookies) = @_;
    local($cookie,$value,$char);
    my $cd = '';

    while( ($cookie,$value) = @cookies ) {

         foreach $char (@Cookie_Encode_Chars) {
            $cookie =~ s/$char/$Cookie_Encode_Chars{$char}/g;
            $value =~ s/$char/$Cookie_Encode_Chars{$char}/g;
        }

        #$cd = 'Set-Cookie2: Version = 1'."\n";
        $cd = 'Set-Cookie: ' . $cookie . '=' . $value . ';';

        if ($cookie_exp_date_cgi) {
            $cd .= ' expires=' . $cookie_exp_date_cgi . ';';
        }

        if ($cookie_path_cgi) {
            $cd .= ' path=' . $cookie_path_cgi . ';';
        }
        else {$cd .= ' path=/;';}
        
        if ($cookie_domain_cgi) {
            $cd .= ' domain=' . $cookie_domain_cgi . ';';
        }

        if ($secure_cookie_cgi) {
            $cd .= ' secure';
        }
        $cd .= "\n";
        shift(@cookies); shift(@cookies);
    }
  return($cd);   # Return String of cookie(s)!
}

##############################################################################
# Subroutine:    &SetCompressedCookies                                       #
# Description:   This routine does much the same thing that &SetCookies does #
#                except that it combines multiple cookies into one.          #
# Usage:         &SetCompressedCookies(cname,name1,value1,...,namen,valuen)  #
# Variables:     cname - Name of the compressed cookie to be set.            #
#                        Ex. 'CC'                                            #
#                name  - Name of the individual cookie to be set.            #
#                        Ex. 'count'                                         #
#                value - Value of the individual cookie to be set.           #
#                        Ex. '3'                                             #
#                n     - This is tacked on to the last of the name and value #
#                        pairs in the usage instructions just to show you    #
#                        you can have as many name/value pairs as you wish.  #
# Returns:       Nothing.                                                    #
##############################################################################

sub SetCompressedCookies {

    local($cookie_name,@cookies) = @_;
    local($cookie,$value,$cookie_value);

    while ( ($cookie,$value) = @cookies ) {

        foreach $char (@Cookie_Encode_Chars) {
            $cookie =~ s/$char/$Cookie_Encode_Chars{$char}/g;
            $value =~ s/$char/$Cookie_Encode_Chars{$char}/g;
        }

        if ($cookie_value) {
            $cookie_value .= '&' . $cookie . '::' . $value;
        }
        else {
            $cookie_value = $cookie . '::' . $value;
        }
        shift(@cookies); shift(@cookies);
    }

    &SetCookies("$cookie_name","$cookie_value");
}

##############################################################################
# Subroutine:    &GetCompressedCookies()                                     #
# Description:   This subroutine takes the compressed cookie names, and      #
#                optionally the names of specific cookies you want returned  #
#                and uncompressed them, setting the values into %Cookies.    #
#                Specific names of cookies are optional and if not specified #
#                all cookies found in the compressed cookie will be set.     #
# Usage:         &GetCompressedCookies(cname,[names])                        #
# Variables:     cname - Name of the compressed cookie to be uncompressed.   #
#                        Ex. 'CC'                                            #
#                names - Optional names of cookies to be returned from the   #
#                        compressed cookie if you don't want them all.  The  #
#                        [] depict a list of optional names, don't use [].   #
#                        Ex. 'count'                                         #
# Returns:       1 - If successful and at least one cookie is retrieved.     #
#                0 - If no cookies are retrieved.                            #
##############################################################################

sub GetCompressedCookies {

    local($cookie_name,@ReturnCookies) = @_;
    local($cookie_flag) = 0;
    local($ReturnCookie,$cookie,$value);

    if (&GetCookies($cookie_name)) {

       if ($ReturnCookies[0] ne '') {

            foreach (split(/&/,$Cookies{$cookie_name})) {

                ($cookie,$value) = split(/::/);

                foreach $char (@Cookie_Decode_Chars) {
                    $cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                    $value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                }

                foreach $ReturnCookie (@ReturnCookies) {
                    if ($ReturnCookie eq $cookie) {
                        $Cookies{$cookie} = $value;
                        $cookie_flag = 1;
                    }
                }
            }
        }

        else {

            foreach (split(/&/,$Cookies{$cookie_name})) {
                ($cookie,$value) = split(/::/);

                foreach $char (@Cookie_Decode_Chars) {
                    $cookie =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                    $value =~ s/$char/$Cookie_Decode_Chars{$char}/g;
                }

                $Cookies{$cookie} = $value;
            }
            $cookie_flag = 1;
        }

        delete($Cookies{$cookie_name});
    }

    return $cookie_flag;
}

1;