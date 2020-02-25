package credsman;
use 5.018000;
use strict;
use warnings;
use Types::Standard qw[Int Str CodeRef];
use Params::ValidationCompiler qw[validation_for];
use Data::Dumper;
use Exporter qw(import);
our @EXPORT_OK = qw[login GuiCred];

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('credsman', $VERSION);

# There are 4 XS internal functions that interact with Credential Manager
# RemoveCredentials  - Remove Credentials
# SaveCredentials    - Store Credentials
# GuiCredentials     - Open Prompt USER and PASSWORD gui 
# GuiCred            - Same of GuiCredentials but exposed to this module
# work_name          - Creates Credentials Name String 

#-------------------------------------------------------------------------------------------#
my $validator = validation_for(
    params => {
        program   => { type => Str },
        target    => { type => Str },
        subref    => { type => CodeRef },
        limit     => { type => Int, optional => 1, default => 3 },
        debug     => { type => Int, optional => 1, default => 0 }
    }
);
#-------------------------------------------------------------------------------------------#
sub login{
    my %arg = $validator->(@_);
    say  "*** Arguments ****\n".Dumper \%arg if $arg{debug};
    my %wrkCred = (
        status   => 5,
        attempt  => 0,
        limit    => $arg{limit},
        password => undef,
        user     => undef,
        target   => $arg{target},
    );
    # Concat Target Name - This is the name to be stored 
    my $TargetName = work_name($arg{program},$arg{target});
    say "TargetName : ".$TargetName if $arg{debug};
    # Load Passwords ad runs the function passed with the argument
    while ($wrkCred{status} != 0 and $wrkCred{attempt} < $wrkCred{limit}){
        say "in loop" if $arg{debug};
        # load Credentials from Windows Credential Manager
        ($wrkCred{user}, $wrkCred{password}) = @{LoadCredentials($TargetName)};
        say "*** Load Credentials ****\n".Dumper \%wrkCred if $arg{debug};
        # Check if the Credentials was found
        if( !defined $wrkCred{user}){
            # Request User and Password GUI
            say "Not Defined" if $arg{debug};
            ($wrkCred{user}, $wrkCred{password}) = @{
                GuiCredentials(
                    $arg{program}, 
                    $arg{target}, 
                    $TargetName, 
                    $wrkCred{attempt})
            };
            # No user or password passed, or cancel
            unless(defined $wrkCred{user} and defined $wrkCred{password}){
                die "Cancel" ;
            }

            say "After GUI \n".Dumper \%wrkCred if $arg{debug};
            # Store Credentials in Windoes Credential Manager
            if( SaveCredentials($TargetName, $wrkCred{user}, $wrkCred{password}) ){
                die "Error to Save Credentials";
            };
        }
        else {
            # Call Function passed in Argument
            $wrkCred{status} = $arg{subref}->(\%wrkCred);
            # Expeciting RC 0 to pass
            if ($wrkCred{status}){
                $wrkCred{attempt}++;
                RemoveCredentials($TargetName);
            }
        }
    }
    # Clear Credentials for Security
    $wrkCred{user}     =~ s/.*/ /g;
    $wrkCred{password} =~ s/.*/ /g;
    say "END" if $arg{debug};
    # Return Status
    return $wrkCred{status};
}
#-------------------------------------------------------------------------------------------#
my $GuiVal = validation_for(
    params => {
        message   => { type => Str },
        caption   => { type => Str },
        attempt   => { type => Int, optional => 1, default => 0 }
    }
);
#-------------------------------------------------------------------------------------------#
sub GuiCred {
    my %arg = $GuiVal->(@_);
    return GuiCredentials(
            $arg{caption}, 
            $arg{message}, 
            '', 
            $arg{attempt});
}

1;
__END__

=head1 NAME

credsman - is a simple Pel extension to work with 'Windows Credential Manager'.  

=head1 SYNOPSIS

    use strict;
    use warnings;
    use credsman qw(login);

    # This type of function is necessary to run login, 
    # You need to handle the access or conenction and Error messages

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
   
    # In this Example the program will die at the attempt number 10.

    die "No Zero Return" if login( 
        program  => 'credsman',          # The Prefix to Store the credentials in wcm 
        target   => "Test",              # The Target to validate user and password, usually a server
        subref   => \&Connect_Example,   # Reference to a Function (how to validate password)
        limit    => 10,                  # Number of Attemps before the program Finish
    );


=head1 DESCRIPTION

Credsman (credential manager)

A small library that interacts with Perl and Windows Credential Manager.

It incorporates Windows Credential GUI. It also uses and is integrated with the status.

The Credentials will be stored with the Following format


    - Windows Credential Manager - Generic Credentials
    - format:
    - *['program name']~['Server name or Addres']*

=head2 EXPORT

login:   Function  
GuiCred: Windows GUI User and Password Login.


=head1 AUTHOR

RODAGU , E<lt>rodagu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Rodrigo Agurto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
