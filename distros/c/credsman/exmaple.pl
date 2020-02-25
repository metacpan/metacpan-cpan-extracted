    #!perl
    use strict;
    use warnings;
    use Carp::Always;
    use credsman qw(login);

    # This type of function is necessary to run login, 
    # you need to handle the access or conenction and Error messages

    sub Connect_Example {
        my $credentials = shift;
        # Here your code to login or connect using user and password
        if( $credentials->{user} eq 'pepe' and  $credentials->{password} eq 'pepepass' ){
            print "The Target Name is: $credentials->{target}\n";
            print "  User  : $credentials->{user}\n";
            print "  Pass  : $credentials->{password}\n";
            print "Attempt : $credentials->{attempt} of $credentials->{limit}\n"; 
            # Return 0 - Success
            return 0;
        }
        else{
            print "Fail\n";
            # Return to fail
            return 1;
        }
    }
   
    # In this Example the prgram will die at the attempt number 10.

    die "No Zero Return" if login( 
        program  => 'credsman',         # The Prefix to Store the credentials in wcm 
        target   => "Test",             # The Target to validate user and password, usually a server
        subref   => \&Connect_Example,  # Reference to a Function (how to validate password)
        limit    => 10,                 # Number of Attemps before the program Finish
    );