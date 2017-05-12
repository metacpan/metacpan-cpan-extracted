#!perl -w


use strict;
use Test::More tests => 19;
use Text::Aspell;

BEGIN { use_ok( 'Text::Aspell' ); }

# Always passes, but returns true or false for so can show diag
sub ok_to_fail {
    my ( $ok, $message ) = @_;
    pass( $message );
    return $ok;
}



my $speller = Text::Aspell->new;
ok( $speller, 'Create Speller object' );

ok( $speller->set_option('sug-mode','fast'), 'Set option sug-mode to "fast"' ) or
    diag( "Error: " . $speller->errstr );


#print defined $speller->create_speller ? "ok 4\n" : "not ok 4 " . $speller->errstr . "\n";

ok( $speller->set_option( 'lang', 'en_US' ), 'Set language to en_US' ) or
    diag( "Error: " . $speller->errstr );

my $language = $speller->get_option('lang');
is ( $language, 'en_US', "check that 'lang' option is en_US" ) or
    diag( "Really need the en_US dictionary installed!" );


ok( $speller->check('test'), 'Make sure word "test" is in dictionary' ) or
    do {
        my $err = $speller->errstr;
        diag(<<"");
        ********************************************************************
        * Error: $err
        *
        * Are you sure you have the Aspell en_US dictionary installed?
        *
        *********************************************************************


    };

my $new_word = 'testt';

# make sure $new_word does NOT exist in the dictionary
ok( !$speller->check( $new_word ), "Word '$new_word' should NOT be in dictionary" );


ok( $speller->suggest($new_word), "suggest for word '$new_word'" ) or
    diag( 'Error: ' . $speller->errstr );


my @s_words = $speller->suggest($new_word);
ok( @s_words > 2, "search for testt returned more than 2 [@s_words]" );

# Now add $new_word to session so it will be returned in suggestions

ok ( $speller->add_to_session($new_word), "add '$new_word' to the aspell session") or
    diag( 'Error: ' . $speller->errstr );



@s_words = $speller->suggest($new_word);
ok( grep(/$new_word/, @s_words), "'$new_word' added to session now is returned in suggest" );


ok_to_fail( $speller->store_replacement( 'foo', 'bar' ), 'Store replacement "foo" for "bar"' ) or
    diag( 'See README for more info on store_replacemnt' );



ok( grep( /bar/, $speller->suggest('foo')), 'Searching for "foo" found replacement "bar"' );

ok_to_fail( $speller->clear_session, 'Clear the aspell session' ) or
    diag("clear_session may fail like store_replacement.  See README" );


@s_words = $speller->suggest($new_word);
ok( !grep(/$new_word/, @s_words), "'$new_word' should not be a suggestion after clearing the session")
    or diag( "suggested words were [@s_words]" );


my @dicts = $speller->list_dictionaries;
ok( @dicts, scalar @dicts . ' dictionaries listed' );

@dicts = $speller->dictionary_info;
ok( @dicts, scalar @dicts . ' dictionaries found with dictionary_info' );

use Data::Dumper;
print Dumper \@dicts;


my @list = $speller->get_option_as_list('sug-split-char');

SKIP: {
    skip "option 'sug-split-char' not in your version of Aspell", 1 if $speller->errstr =~ m/is unknown/;

    cmp_ok( scalar @list, '>', 1, 'Found more than one list item for "sug-split-char"') or
     diag('Maybe option "sug-split-char" not in your version of Aspell or modified by config. ' . $speller->errstr);
}


# Display option keys

my $options = $speller->fetch_option_keys;

my $keys_count = ref $options eq 'HASH' ? keys %$options : 0;

if ( $keys_count ) {
    for my $option ( sort keys %$options ) {
        my $detail = $options->{$option};
        for ( qw/ desc default type / ) {
            $detail->{$_} = '(*not defined*)' unless defined $detail->{$_};
        }

        my $current;
        if ( $detail->{type} == 3 ) {
           $current = join ', ', map { "'$_'" } $speller->get_option_as_list( $option );
           $current = "($current)" if defined $current;
        } else {
            $current = $speller->get_option( $option );
        }
        $current = '(* not defined *)' unless defined $current;

        print <<"";
            
                $option:
                    Description:  $detail->{desc}
                        Default:  $detail->{default}
                    Option type:  $detail->{type}
                    Current Val:  $current

    }
}

ok( $keys_count, "Found $keys_count option keys from fetch_option_keys()" );
