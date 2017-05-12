#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::Filter::Dispatcher qw( :all );
use XML::SAX::PurePerl;

## PurePerl is slow, so only run it once.
my $stooges = QB->new( <<XML_END );
      <stooges>
        <stooge name="Moe" hairstyle="bowl cut">
          <attitude>Bully</attitude>
        </stooge>
        <stooge name="Shemp" hairstyle="mop">
          <attitude>Klutz</attitude>
          <stooge name="Larry" hairstyle="bushy">
            <attitude>Middleman</attitude>
          </stooge>
        </stooge>
        <stooge name="Curly" hairstyle="bald">
          <attitude>Fool</attitude>
          <stooge name="Shemp" repeat="yes">
            <stooge name="Joe" hairstyle="bald">
              <stooge name="Curly Joe" hairstyle="bald" />
            </stooge>
          </stooge>
        </stooge>
      </stooges>
XML_END


sub run { $stooges->playback( shift ) }


my @tests = (
sub {
    my $count;
    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                "stooge" => sub { ++$count },
            ],

        )
    );
    ok $count, 7;
},

sub {
    my $count;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge/stooge' => sub { ++$count },
            ],
        )
    );

    ok $count, 4;
},

sub {
    my $count;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                '@repeat' => sub { ++$count },
            ],
#            Debug => 10,
        )
    );

    ok $count, 1;
},


sub {
    my $count;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge[not(@repeat)]'
                    => sub { ++$count },
            ],
        )
    );

    ok $count, 6;
},

sub {
    my $count;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge[not(@repeat) or not(@repeat = "yes")]'
                    => sub { ++$count },
            ],
        )
    );

    ok $count, 6;
},

sub {
    my %styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge[@hairstyle]' => [
                    'string(@hairstyle)' => sub { $styles{xvalue()} = 1 }
                ],
            ],
        )
    );
    print "# ", join( ", ", sort keys %styles ), "\n";

    ok scalar keys %styles, 4;
},
sub {
    my %styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge[attitude]' => [
                    'string(attitude)' => sub { $styles{xvalue()} = 1 },
                ],
            ],
        )
    );
    print "# ", join( ", ", sort keys %styles ), "\n";

    ok scalar keys %styles, 4;
},

sub {
    my @styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge' => [
                    'concat( @name, "=>", @hairstyle )' => 
                        sub {
                            push @styles, $1 if xvalue =~ /(.+=>.+)/;
                        },
                ],
            ],
        )
    );

    ok scalar @styles, 6;
},

sub {
    my %styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge' => [
                    'concat(@hairstyle,"=>",attitude)' => sub {
                        $styles{$1} = $2 if xvalue() =~ /(.+)=>(.+)/;
                    },
                ],
            ],
        )
    );
    print map "# $_ => $styles{$_}\n", sort keys %styles;

    ok scalar keys %styles, 4;
},
);

plan tests => scalar @tests;

$_->() for @tests;

## This quick little buffering filter is used to save us the overhead
## of a parse for each test.  This saves me sanity (since I run the test
## suite a lot), allows me to see which tests are noticably slower in
## case something pathalogical happens, and keeps admins from getting the
## impression that this is a slow package based on test suite speed.
package QB;
use vars qw( $AUTOLOAD );

sub new {
    my $self = bless [], shift;
    my $p = XML::SAX::PurePerl->new( Handler => $self );
    $p->parse_string( shift );
    return $self;
}

sub DESTROY;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*://;
    if ( $AUTOLOAD eq "start_element" ) {
        ## Older (and mebbe newer :) X::S::PurePerls reuse the same
        ## hash in end_element but delete the Attributes, so we need
        ## to copy.  And I can't copy everything because some other
        ## overly magical thing dies, haven't tracked down beyond seeing
        ## signs that it's XML::SAX::DocumentLocator::NEXTKEY(/usr/local/lib/perl5/site_perl/5.6.1/XML/SAX/DocumentLocator.pm:72)
        ## but I hear that's fixed in CVS :).
        push @$self, [ $AUTOLOAD, [ { %{$_[0]} } ] ];
    }
    else {
        push @$self, [ $AUTOLOAD, [ $_[0] ] ];
    }
}

sub playback {
    my $self = shift;
    my $h = shift;
    for ( @$self ) {
        my $m = $_->[0];
        no strict "refs";
        $h->$m( @{$_->[1]} );
    }
}
