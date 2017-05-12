package Tool::Bench::Report::Text;
{
  $Tool::Bench::Report::Text::VERSION = '0.003';
}
use Mouse;
use List::Util qw{min max sum };

# ABSTRACT: How to build the Text Report

=head1 SYNOPSIS 

At the very end of everything, you will likely want a nice clean report of
everything. 

  my $bench = Tool::Bench->new;
  $bench->add_items( true  => sub{1},
                     die   => sub{die},
                     ls    => {code => sub{qx{ls}},
                               note => 'some note',
                              },
                     sleep => sub{sleep(1)},
                   );
  $bench->run(4);
  print $bench->report(format => 'Text'); 

   min   max  total  avg  count name
  0.000 0.000 0.000 0.000     4 true
  0.000 0.000 0.000 0.000     4 die
  0.002 0.002 0.009 0.002     4 ls [some note]
  1.000 1.000 4.000 1.000     4 sleep

=head1 METHODS

=head2 report

This is the method that $bench->report will call to build the actual report. 
The most important thing that is passed along by $bench is the item objects.

  $bench->report(format => 'Text');

Will end up calling 'report' looking like:

  Tool::Bench::Report::Text->new->report(items => [...]);

Common practice is that you return the report, rather then printing. This 
allows the user to decide what they want to do with that report on there end.

=cut

sub report {
   my ($self,%args) = @_;

   sprintf qq{%s\n\n},
           join qq{\n},
               q{ min   max  total  avg   count name},
               map{ sprintf q{%0.3f %0.3f %0.3f %0.3f % 5d %s %s},
                            $_->min_time,
                            $_->max_time,
                            $_->total_time,
                            $_->avg_time,
                            $_->total_runs,
                            $_->name,
                            #length($_->note) ? sprintf q{[NOTE: %s]}, $_->note : ''
                            length($_->note) ? sprintf q{[%s]}, $_->note : ''
                  } sort {$a->total_time <=> $b->total_time} @{$args{items}};
   
};

1;

