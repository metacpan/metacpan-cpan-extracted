package Term::UI;

use Carp;
use Params::Check qw[check allow];
use Term::ReadLine;
use Locale::Maketext::Simple Style => 'gettext';
use Term::UI::History;

use strict;

BEGIN {
    use vars        qw[$VERSION $AUTOREPLY $VERBOSE $INVALID];
    $VERBOSE    =   1;
    $VERSION    =   '0.20';
    $INVALID    =   loc('Invalid selection, please try again: ');
}

push @Term::ReadLine::Stub::ISA, __PACKAGE__
        unless grep { $_ eq __PACKAGE__ } @Term::ReadLine::Stub::ISA;


sub get_reply {
    my $term = shift;
    my %hash = @_;

    my $tmpl = {
        default     => { default => undef,  strict_type => 1 },
        prompt      => { default => '',     strict_type => 1, required => 1 },
        choices     => { default => [],     strict_type => 1 },
        multi       => { default => 0,      allow => [0, 1] },
        allow       => { default => qr/.*/ },
        print_me    => { default => '',     strict_type => 1 },
    };

    my $args = check( $tmpl, \%hash, $VERBOSE )
                or ( carp( loc(q[Could not parse arguments]) ), return );


    ### add this to the prompt to indicate the default
    ### answer to the question if there is one.
    my $prompt_add;
    
    ### if you supplied several choices to pick from,
    ### we'll print them seperately before the prompt
    if( @{$args->{choices}} ) {
        my $i;

        for my $choice ( @{$args->{choices}} ) {
            $i++;   # the answer counter -- but humans start counting
                    # at 1 :D
            
            ### so this choice is the default? add it to 'prompt_add'
            ### so we can construct a "foo? [DIGIT]" type prompt
            $prompt_add = $i if (defined $args->{default} and $choice eq $args->{default});

            ### create a "DIGIT> choice" type line
            $args->{print_me} .= sprintf "\n%3s> %-s", $i, $choice;
        }

        ### we listed some choices -- add another newline for 
        ### pretty printing
        $args->{print_me} .= "\n" if $i;

        ### allowable answers are now equal to the choices listed
        $args->{allow} = $args->{choices};

    ### no choices, but a default? set 'prompt_add' to the default
    ### to construct a 'foo? [DEFAULT]' type prompt
    } elsif ( defined $args->{default} ) {
        $prompt_add = $args->{default};
    }

    ### we set up the defaults, prompts etc, dispatch to the readline call
    return $term->_tt_readline( %$args, prompt_add => $prompt_add );

} 

sub ask_yn {
    my $term = shift;
    my %hash = @_;

    my $tmpl = {
        default     => { default => undef, allow => [qw|0 1 y n|],
                                                            strict_type => 1 },
        prompt      => { default => '', required => 1,      strict_type => 1 },
        print_me    => { default => '',                     strict_type => 1 },        
        multi       => { default => 0,                      no_override => 1 },
        choices     => { default => [qw|y n|],              no_override => 1 },
        allow       => { default => [qr/^y(?:es)?$/i, qr/^n(?:o)?$/i],
                         no_override => 1
                       },
    };

    my $args = check( $tmpl, \%hash, $VERBOSE ) or return undef;
    
    ### uppercase the default choice, if there is one, to be added
    ### to the prompt in a 'foo? [Y/n]' type style.
    my $prompt_add;
    {   my @list = @{$args->{choices}};
        if( defined $args->{default} ) {

            ### if you supplied the default as a boolean, rather than y/n
            ### transform it to a y/n now
            $args->{default} = $args->{default} =~ /\d/ 
                                ? { 0 => 'n', 1 => 'y' }->{ $args->{default} }
                                : $args->{default};
        
            @list = map { lc $args->{default} eq lc $_
                                ? uc $args->{default}
                                : $_
                    } @list;
        }

        $prompt_add .= join("/", @list);
    }

    my $rv = $term->_tt_readline( %$args, prompt_add => $prompt_add );
    
    return $rv =~ /^y/i ? 1 : 0;
}



sub _tt_readline {
    my $term = shift;
    my %hash = @_;

    local $Params::Check::VERBOSE = 0;  # why is this?
    local $| = 1;                       # print ASAP


    my ($default, $prompt, $choices, $multi, $allow, $prompt_add, $print_me);
    my $tmpl = {
        default     => { default => undef,  strict_type => 1, 
                            store => \$default },
        prompt      => { default => '',     strict_type => 1, required => 1,
                            store => \$prompt },
        choices     => { default => [],     strict_type => 1, 
                            store => \$choices },
        multi       => { default => 0,      allow => [0, 1], store => \$multi },
        allow       => { default => qr/.*/, store => \$allow, },
        prompt_add  => { default => '',     store => \$prompt_add },
        print_me    => { default => '',     store => \$print_me },
    };

    check( $tmpl, \%hash, $VERBOSE ) or return;

    ### prompts for Term::ReadLine can't be longer than one line, or
    ### it can display wonky on some terminals.
    history( $print_me ) if $print_me;

    
    ### we might have to add a default value to the prompt, to
    ### show the user what will be picked by default:
    $prompt .= " [$prompt_add]: " if $prompt_add;


    ### are we in autoreply mode?
    if ($AUTOREPLY) {
        
        ### you used autoreply, but didnt provide a default!
        carp loc(   
            q[You have '%1' set to true, but did not provide a default!],
            '$AUTOREPLY' 
        ) if( !defined $default && $VERBOSE);

        ### print it out for visual feedback
        history( join ' ', grep { defined } $prompt, $default );
        
        ### and return the default
        return $default;
    }


    ### so, no AUTOREPLY, let's see what the user will answer
    LOOP: {
        
        ### annoying bug in T::R::Perl that mucks up lines with a \n
        ### in them; So split by \n, save the last line as the prompt
        ### and just print the rest
        {   my @lines   = split "\n", $prompt;
            $prompt     = pop @lines;
            
            history( "$_\n" ) for @lines;
        }
        
        ### pose the question
        my $answer  = $term->readline($prompt);
        $answer     = $default unless length $answer;

        $term->addhistory( $answer ) if length $answer;

        ### add both prompt and answer to the history
        history( "$prompt $answer", 0 );

        ### if we're allowed to give multiple answers, split
        ### the answer on whitespace
        my @answers = $multi ? split(/\s+/, $answer) : $answer;

        ### the return value list
        my @rv;
        
        if( @$choices ) {
            
            for my $answer (@answers) {
                
                ### a digit implies a multiple choice question, 
                ### a non-digit is an open answer
                if( $answer =~ /\D/ ) {
                    push @rv, $answer if allow( $answer, $allow );
                } else {

                    ### remember, the answer digits are +1 compared to
                    ### the choices, because humans want to start counting
                    ### at 1, not at 0 
                    push @rv, $choices->[ $answer - 1 ] 
                        if $answer > 0 && defined $choices->[ $answer - 1];
                }    
            }
     
        ### no fixed list of choices.. just check if the answers
        ### (or otherwise the default!) pass the allow handler
        } else {       
            push @rv, grep { allow( $_, $allow ) }
                        scalar @answers ? @answers : ($default);  
        }

        ### if not all the answers made it to the return value list,
        ### at least one of them was an invalid answer -- make the 
        ### user do it again
        if( (@rv != @answers) or 
            (scalar(@$choices) and not scalar(@answers)) 
        ) {
            $prompt = $INVALID;
            $prompt .= "[$prompt_add] " if $prompt_add;
            redo LOOP;

        ### otherwise just return the answer, or answers, depending
        ### on the multi setting
        } else {
            return $multi ? @rv : $rv[0];
        }
    }
}

sub parse_options {
    my $term    = shift;
    my $input   = shift;

    my $return = {};

    ### there's probably a more elegant way to do this... ###
    while ( $input =~ s/(?:^|\s+)--?([-\w]+=("|').+?\2)(?=\Z|\s+)//  or
            $input =~ s/(?:^|\s+)--?([-\w]+=\S+)(?=\Z|\s+)//         or
            $input =~ s/(?:^|\s+)--?([-\w]+)(?=\Z|\s+)//
    ) {
        my $match = $1;

        if( $match =~ /^([-\w]+)=("|')(.+?)\2$/ ) {
            $return->{$1} = $3;

        } elsif( $match =~ /^([-\w]+)=(\S+)$/ ) {
            $return->{$1} = $2;

        } elsif( $match =~ /^no-?([-\w]+)$/i ) {
            $return->{$1} = 0;

        } elsif ( $match =~ /^([-\w]+)$/ ) {
            $return->{$1} = 1;

        } else {
            carp(loc(q[I do not understand option "%1"\n], $match)) if $VERBOSE;
        }
    }

    return wantarray ? ($return,$input) : $return;
}

sub history_as_string { return Term::UI::History->history_as_string };

1;

