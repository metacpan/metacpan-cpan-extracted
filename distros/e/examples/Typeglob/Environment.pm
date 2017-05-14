package Environment;
sub import {
    # Get some caller details; its package name, and the current file name
    # and line number
    my ($caller_package) = caller; 
    foreach $envt_var_name (keys %ENV) {
         # Use the soft reference mechanism to create variables
         # If $ENV{"USER"} == "sriram", then the following code
         # does  ${"main::USER"} = "sriram"  (assuming it is getting
         # called from package "main"
         *{"${caller_package}::${envt_var_name}"} = \$ENV{$envt_var_name};
    }
}
1;  # To signify successful initialization
