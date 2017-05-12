# NAME

autolocale - auto call setlocale() when set $ENV{"LANG"}

# SYNOPSIS

    use autolocale;
    
    $ENV{"LANG"} = "C"; # locale is "C"
    {
        local $ENV{"LANG"} = "en_US";# locale is "en_US"
    }
    # locale is "C"
    
    no autolocale; # auto setlocale disabled
    $ENV{"LANG"} = "en_US"; # locale is "C"

# DESCRIPTION

autolocale is pragma module that auto call setlocale() when set $ENV{"LANG"}.

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
