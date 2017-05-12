package Tool::Bench;
{
  $Tool::Bench::VERSION = '0.003';
}
use Mouse;
use List::Util qw{shuffle};
use Data::Dumper;

# ABSTRACT: Tool Bench is a generic framework for running benchmarks.

=head1 NAME 

Tool::Bench - Tool Bench is a generic framework for running benchmarks.

=head1 SYNOPSIS 

Ok so I'm sure your asking your self, yet another benchmarking suit? Sure there
are many others but this one is not specific to Perl. Think of Tool::Bench more
as a jazzy version of the unix 'time' command it just happens to be written in
perl. With 'time' you have a very simple wrap a clock around this command for
one run.  Tool::Bench goes a bit further by wrapping a clock around the
execution of an number of CodeRef, run as many times as you want. Then because
all these times are stored you can build reports from the results of all these
runs.

That said Tool::Bench is designed to just be the clock engine, you
have to draw the line somewhere. So here's a quick example of usage.

  use Tool::Bench;
  my $bench = Tool::Bench->new;

  # simplest case: add a code ref with a name
  $bench->add_items( simple => sub{...} );

  # slightly more complex item: now with events
  $bench->add_items( complex => { startup  => sub{...},
                                  code     => sub{...},
                                  teardown => sub{...},
                                },
                   );

  # add items can takes a hash so you can add more then one item
  $bench->add_items( name1 => sub{...}, 
                     name2 => { startup => sub{...},
                                code    => sub{...},  
                              },
                     name3 => sub{...},
                   );

  # now that your all set up, you'll want to run them
  # lets say that you want to run each item 3 times
  $bench->run(3);

  # now you've got a bunch of data stored off... lets do something with it.

  $bench->report(format => 'Text');
  
=head1 ATTRIBUTES

=head2 items

This is the store for all the items to be bench marked. When called directly
you will get an arrayref of Item objects. 

=cut

has items => 
   is => 'rw',
   isa => 'ArrayRef[Tool::Bench::Item]',
   lazy => 1,
   default => sub{[]},
;

=head1 METHODS

=head2 items_count

Returns the count of the number of items currently stored.

=cut

sub items_count { scalar( @{ shift->items } ) };

=head2 add_items

  $bench->add_items( $name => $coderef );
  $bench->add_items( $name => { startup  => $coderef,
                                code     => $coderef,
                                teardown => $coderef,
                                #verify  => $coderef, # currently not implimented
                              }
                     ...
                   );

This method will take your input and build new Item objects and store them 
in the items stack. See L<Tool::Bench::Item> for more info on the events.

Returns items_count.
=cut

sub add_items {
   require Tool::Bench::Item;
   my $self  = shift;
   my %items = @_;
   for my $name ( keys %items ) {
      my $ref = ref($items{$name});
      my $new = $ref eq 'CODE' ? {code => $items{$name}}
              : $ref eq 'HASH' ? $items{$name}
              :                  {};

      push @{$self->items}, Tool::Bench::Item->new( name => $name, %$new );
   }
   return $self->items_count;
}

=head2 run


When you are done adding all your items, you'll want to run them. Run takes an
int that refers to the number of times that you want to run each item, the 
default is 1. 

  $bench->run; # fire off the run method of all known items in shuffled order
  $bench->run(3); # run all items 3 times, random order non-sequential runs

Returns the number of times that it ran each item. 

=cut

sub run {
   my $self  = shift;
   my $times = shift || 1;
   my $count = 0;
   $_->pre_run->() for @{ $self->items }; # pre run even tripping
   foreach my $i (1..int($times)) {
      foreach my $item ( shuffle( @{ $self->items } ) ) {
         $item->run;
         $count++;
      }
   }
   $_->post_run->() for @{ $self->items }; # post run even tripping
   $count; # seems completely pointless but should return something at least marginally useful
}


#---------------------------------------------------------------------------
#  REPORTING
#---------------------------------------------------------------------------

=head2 report

Lastly, once you've run the items, you'll likely want to mine them and build 
a report. The report method by default will return a Text report, though you
can ask for other formats. The 'format' value is expected to be the last part 
of the class to generate the report. 

  $bench->report(format => 'Text'); # uses Tool::Bench::Report::Text
  $bench->report(format => 'JSON'); # uses Tool::Bench::Report::JSON

By using class names you can build your own report simply, see 
L<Tool::Bench::Report::Text> for more info on how to build report types.

=cut

sub report {
   my ($self, %args) = @_;
   my $type = $args{format} || 'Text';
   my $class = qq{Tool::Bench::Report::$type};
   eval qq{require $class} or die $@; #TODO this is messy
   $class->new->report(
    items  => $self->items,
    %args,
    );
}

no Mouse;
1;
