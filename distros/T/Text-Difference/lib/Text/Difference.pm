package Text::Difference;

use strict;
use warnings;

use Data::Dumper;
use Moose;
use namespace::autoclean;

$Data::Dumper::Sortkeys = 1;

=head1 NAME

Text::Difference - Compare two strings and find which tokens are actually different, with optional stopwords.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Compare two strings to check what tokens (words) are actually different, if any.

 use Text::Difference;

 my $diff = Text::Difference->new(
     a => 'big blue car',
     b => 'yellow car in small',
     stopwords => [ 'in' ],
     tokens => {
         colour => [ 'blue', 'yellow' ],
         size   => [ 'big', 'small' ],
     }
     debug => 0,
 );

 $diff->check;

 $diff->match;   # true

 $diff->a_tokens_remaining;   # a hashref

 $diff->a_tokens_matched;     # a hashref
 
=cut

has debug => ( is => 'rw', isa => 'Bool', default => 0 );

has a => ( is => 'rw', isa => 'Str' );
has b => ( is => 'rw', isa => 'Str' );

has _stopwords => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    init_arg => 'stopwords',
    traits   => [ 'Array' ],
    default  => sub { [] },
    handles  => {
        stopwords => 'elements',
    },
);

has _tokens => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => 'tokens',
    traits   => [ 'Hash' ],
    default  => sub { {} },
    handles  => {
        tokens    => 'keys',
        get_token => 'get',
    },
);

has match => ( is => 'rw', isa => 'Bool', default => 0 );

has a_tokens_remaining => ( is => 'rw', isa => 'HashRef', clearer => '_clear_a_tokens_remaining' );
has b_tokens_remaining => ( is => 'rw', isa => 'HashRef', clearer => '_clear_b_tokens_remaining' );

has a_tokens_matched => ( is => 'rw', isa => 'HashRef', clearer => '_clear_a_tokens_matched' );
has b_tokens_matched => ( is => 'rw', isa => 'HashRef', clearer => '_clear_b_tokens_matched' );

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 Instance Methods

=head3 check

 $diff->check

=cut

sub check
{
    my $self = shift;

    #########
    # reset #
    #########

    $self->match( 0 );

    $self->_clear_a_tokens_remaining;
    $self->_clear_b_tokens_remaining;

    $self->_clear_a_tokens_matched;
    $self->_clear_b_tokens_matched;

    ##################
    # perform checks #
    ##################

    $self->_has_all_same_words;

    return $self;
}

sub _has_all_same_words
{
    my $self = shift;

    #####################
    # take a local copy #
    #####################

    my $string_a = lc( $self->a );
    my $string_b = lc( $self->b );

    ############################################
    # strip out/replace stopwords (or symbols) #
    ############################################

    foreach my $word ( map { quotemeta $_ } $self->stopwords )
    {
        $string_a =~ s/$word/ /g;
        $string_b =~ s/$word/ /g;
    }

    ###################
    # condense spaces #
    ###################

    $string_a =~ s/\s+/ /g;
    $string_b =~ s/\s+/ /g;

    ###############
    # trim spaces #
    ###############

    $string_a =~ s/^\s+//;
    $string_a =~ s/\s+$//;

    $string_b =~ s/^\s+//;
    $string_b =~ s/\s+$//;

    print "ORIGINAL A : " . $string_a . "\n" if $self->debug;
    print "ORIGINAL B : " . $string_b . "\n" if $self->debug;

    ###############################
    # extract any supplied tokens #
    ###############################
    
    if ( $self->tokens )
    {
        my %a_tokens_matched = ();
        my %b_tokens_matched = ();

        foreach my $category ( $self->tokens )
        {
            if ( ref $self->get_token( $category ) eq 'ARRAY' )
            {
                # order by the tokens with more spaces in

                foreach my $token ( sort { scalar( () = $b =~ /\s/g ) <=> scalar( () = $a =~ /\s/g ) } @{ $self->get_token( $category ) } )
                {
                    my $quoted_token = quotemeta $token;

                    my $a_substitutions = $string_a =~ s/$quoted_token//ig;

                    $a_tokens_matched{ $category }->{ $token } = $a_substitutions if $a_substitutions;

                    my $b_substitutions = $string_b =~ s/$quoted_token//ig;

                    $b_tokens_matched{ $category }->{ $token } = $b_substitutions if $b_substitutions;
                }
            }
        }

        $self->a_tokens_matched( \%a_tokens_matched );
        $self->b_tokens_matched( \%b_tokens_matched );

        if ( $self->debug )
        {
            print "A TOKENS MATCHED:\n";
            
            foreach my $category ( sort keys %a_tokens_matched )
            {
                print "\t" . $category . ":\n";

                foreach my $token ( sort keys %{ $a_tokens_matched{ $category } } )
                {
                    print "\t\t" . $token . " = " . $a_tokens_matched{ $category }->{ $token } . "\n";
                }
            }

            print "B TOKENS MATCHED:\n";
            
            foreach my $category ( sort keys %b_tokens_matched )
            {
                print "\t" . $category . ":\n";

                foreach my $token ( sort keys %{ $b_tokens_matched{ $category } } )
                {
                    print "\t\t" . $token . " = " . $b_tokens_matched{ $category }->{ $token } . "\n";
                }
            }
        }
    }

    ####################
    # get the a tokens #
    ####################

    my %a_tokens = ();

    foreach my $token ( split(' ', $string_a ) )
    {
        $a_tokens{ $token } = 0 if ! exists $a_tokens{ $token };
        $a_tokens{ $token } ++;
    }

    ########################
    # get the right tokens #
    ########################

    my %b_tokens = ();

    foreach my $token ( split(' ', $string_b ) )
    {
        $b_tokens{ $token } = 0 if ! exists $b_tokens{ $token };
        $b_tokens{ $token } ++;
    }

    ############################
    # filer out the duplicates #
    ############################

    foreach my $a_token ( keys %a_tokens )
    {
        if ( exists $b_tokens{ $a_token } )
        {
            delete $a_tokens{ $a_token };
            delete $b_tokens{ $a_token };
        }
    }

    print "REMAINING A : " . join( ' ', keys %a_tokens ) . "\n" if $self->debug;
    print "REMAINING B : " . join( ' ', keys %b_tokens ) . "\n" if $self->debug;

    #############################
    # evaluate what's remaining #
    #############################

    if ( keys %a_tokens == 0 && keys %b_tokens == 0 )
    {
        $self->match( 1 );
    }

    $self->a_tokens_remaining( \%a_tokens );

    $self->b_tokens_remaining( \%b_tokens );

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
