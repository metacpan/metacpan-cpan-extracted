package Web::Dash::Lens;
use strict;
use warnings;
use Carp;
use Try::Tiny;
use Future::Q 0.012;
use Scalar::Util qw(weaken);
use Net::DBus;
use Net::DBus::Reactor;
use Net::DBus::Annotation qw(dbus_call_noreply);
use Web::Dash::DeeModel;
use Web::Dash::Util qw(future_dbus_call);
use Encode;
use Async::Queue 0.02;
use utf8;

my %SCHEMA_RESULTS = (
    0 => 'uri',
    1 => 'icon_hint',
    2 => 'category_index',
    3 => 'mimetype',
    4 => 'name',
    5 => 'comment',
    6 => 'dnd_uri'
);

my %SCHEMA_CATEGORIES = (
    0 => 'name',
    1 => 'icon_hint',
    2 => 'renderer',
);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        reactor => $args{reactor} || Net::DBus::Reactor->main,
        service_name => undef,
        object_name => undef,
        bus => undef,
        bus_address => undef,
        query_object => undef,
        results_model_future => Future::Q->new,
        search_hint_future => Future::Q->new,
        categories_future => Future::Q->new,
        request_queue => undef,
    }, $class;
    $self->_init_queue($args{concurrency});
    $self->_init_bus(defined $args{bus_address} ? $args{bus_address} : ':session');
    $self->_init_service(@args{qw(lens_file service_name object_name)});

    ## --- Procedure to connect to remote Lens service

    ## 1. Get hold of query_object
    ##    query_object is the main entry point to the Lens service in DBus.
    ##    Its service name and object name are normally obtained from .lens file.
    ##    query_object implements com.canonical.Unity.Lens interface.
    
    $self->{query_object} =
        $self->{bus}->get_service($self->{service_name})->get_object($self->{object_name}, 'com.canonical.Unity.Lens');
    {
        ## 2. Fetch Lens meta information
        ##    We then have to obtain meta information about the lens.
        ##    query_object broadcasts such information by "Changed" signal,
        ##    so we listen to it here. "Changed" signal is emitted when
        ##    "InfoRequest" method is called on the query_object.
        
        weaken (my $self = $self);  ## prevent memory leak
        my $sigid; $sigid = $self->{query_object}->connect_to_signal('Changed', sub {
            my ($result_arrayref) = @_;
            my ($obj_name, $flag1, $flag2, $search_hint, $unknown,
                $service_results, $service_global_results, $service_categories, $service_filters) = @$result_arrayref;

            ## 4. Obtain search_hint and some Dee Model objects
            ##    "Changed" signal conveys a number of values. I'm not able to
            ##    figure out all of their meanings. The forth value ($search_hint)
            ##    is a short description of the Lens.

            ##    The last four values are DBus service names for Dee Model objects.
            ##    Lenses use these objects to export various data to DBus. Such data
            ##    include search results and categories of the results. A Dee Model
            ##    object's DBus object name is determined from the service name.
            ##    A Dee Model object is represented by Web::Dash::DeeModel class here.
            
            $self->{query_object}->disconnect_from_signal('Changed', $sigid);
            $self->{search_hint_future}->fulfill(Encode::decode('utf8', $search_hint));

            ##    Results Model exports Search results. We will use the Model object
            ##    later when searching.
            $self->{results_model_future}->fulfill(Web::Dash::DeeModel->new(
                bus => $self->{bus},
                service_name => $service_results,
                schema => \%SCHEMA_RESULTS,
            ));

            ##    Categories Model exports meta information about categories
            ##    of search results. Here we cache the category information,
            ##    and throw away the Model object.
            my $categories_model = Web::Dash::DeeModel->new(
                bus => $self->{bus},
                service_name => $service_categories,
                schema => \%SCHEMA_CATEGORIES,
            );
            $categories_model->get()->then(sub {
                $self->{categories_future}->fulfill(@_) if defined $self;
            }, sub {
                $self->{categories_future}->reject(@_) if defined $self;
            });
        });
    }
    
    ## 3. call "InfoRequest" method to make "Changed" signal fire.
    $self->{query_object}->InfoRequest(dbus_call_noreply);
    return $self;
}

sub service_name { shift->{service_name} }
sub object_name  { shift->{object_name} }

sub _init_bus {
    my ($self, $bus_address) = @_;
    $self->{bus_address} = $bus_address;
    if($bus_address eq ':session') {
        $self->{bus} = Net::DBus->session;
    }elsif($bus_address eq ':system') {
        $self->{bus} = Net::DBus->system;
    }else {
        $self->{bus} = Net::DBus->new($bus_address);
    }
}

sub _remove_delims {
    my ($str) = @_;
    $str =~ s|^[^a-zA-Z0-9_\-\.\/]+||;
    $str =~ s|[^a-zA-Z0-9_\-\.\/]+$||;
    return $str;
}

sub _init_service {
    my ($self, $lens_file, $service_name, $object_name) = @_;
    if(defined $lens_file) {
        open my $file, "<", $lens_file or croak "Cannot read $lens_file: $!";
        while(my $line = <$file>) {
            chomp $line;
            my ($key, $val) = split(/=/, $line);
            next if not defined $val;
            $key = _remove_delims($key);
            $val = _remove_delims($val);
            if($key eq 'DBusName') {
                $self->{service_name} = $val;
            }elsif($key eq 'DBusPath') {
                $self->{object_name} = $val;
            }
        }
        close $file;
    }
    $self->{service_name} = $service_name if defined $service_name;
    $self->{object_name} = $object_name if defined $object_name;
    if(!defined($self->{service_name}) || !defined($self->{object_name})) {
        croak 'Specify either lens_file or combination of service_name and object_name in new()';
    }
}

sub _wait_on {
    my ($self, $future) = @_;
    my @result;
    my $exception;
    my $is_immediate = 1;
    $future->then(sub {
        @result = @_;
        $self->{reactor}->shutdown if !$is_immediate;
    }, sub {
        $exception = shift;
        $self->{reactor}->shutdown if !$is_immediate;
    });
    $is_immediate = 0;
    $self->{reactor}->run if $future->is_pending;
    die $exception if defined $exception;
    return @result;
}

sub search_hint {
    my ($self) = @_;
    return $self->{search_hint_future};
}

sub search_hint_sync {
    my ($self) = @_;
    my ($desc) = $self->_wait_on($self->search_hint);
    return $desc;
}

sub _init_queue {
    my ($self, $concurrency) = @_;

    ## --- Procedure of searching
    ##     Concurrency of this procedure is regulated by Async::Queue.
    
    weaken $self;  ## prevent memory leak
    $self->{request_queue} = Async::Queue->new(
        concurrency => $concurrency,
        worker => sub {
            my ($task, $queue_done) = @_;
            my ($query_string, $final_future) = @$task;
            $self->{results_model_future}->then(sub {
                ## 1. Call "Search" method on query_object with search query.

                return future_dbus_call($self->{query_object}, "Search", $query_string, {});
            })->then(sub {
                ## 2. Obtain search results from Results Model object
                ##    The return value of "Search" method is NOT search results.
                ##    It contains a sequence number pointing to a state of the
                ##    Results Model object. We then obtain search results from the
                ##    Results Model object. However, the current sequence number of
                ##    the Results Model may be different from the one got from
                ##    query_object. That is possible when multiple processes are
                ##    making search queries concurrently. If that happens, the
                ##    obtained search result is discarded because it is not for
                ##    the query we made.

                my ($search_result) = @_;
                my $exp_seqnum = $search_result->{'model-seqnum'};
                my $results_model = $self->{results_model_future}->get;
                return $results_model->get($exp_seqnum);
            })->then(sub {
                my (@results) = @_;
                $final_future->fulfill(@results);
                $queue_done->();
            })->catch(sub {
                $final_future->reject(@_);
                $queue_done->();
            });
        }
    );
}

sub search {
    my ($self, $query_string) = @_;
    my $outer_future = Future::Q->new;
    $self->{request_queue}->push([$query_string, $outer_future]);
    return $outer_future;
}

sub search_sync {
    my ($self, $query_string) = @_;
    return $self->_wait_on($self->search($query_string));
}

sub clone {
    my ($self) = @_;
    return ref($self)->new(
        service_name => $self->service_name,
        object_name => $self->object_name,
        reactor => $self->{reactor},
        bus_address => $self->{bus_address},
        concurrency => $self->{request_queue}->concurrency,
    );
}

sub category {
    my ($self, $category_index) = @_;
    return $self->{categories_future}->then(sub {
        my @categories = @_;
        if(not defined $categories[$category_index]) {
            die "Invalid category_index: $category_index\n";
        }
        return $categories[$category_index];
    });
}

sub category_sync {
    my ($self, $category_index) = @_;
    my ($result) = $self->_wait_on($self->category($category_index));
    return $result;
}

our $VERSION = '0.041';

1;

__END__

=pod

=head1 NAME

Web::Dash::Lens - An experimental Unity Lens object

=head1 VERSION

0.041

=head1 SYNOPSIS

    use Web::Dash::Lens;
    use utf8;
    use Encode qw(encode);
    
    sub show_results {
        my (@results) = @_;
        foreach my $result (@results) {
            print "-----------\n";
            print encode('utf8', "$result->{name}\n");
            print encode('utf8', "$result->{description}\n");
            print encode('utf8', "$result->{uri}\n");
        }
        print "=============\n";
    }
    
    my $lens = Web::Dash::Lens->new(lens_file => '/usr/share/unity/lenses/applications/applications.lens');
    
    
    ## Synchronous query
    my @search_results = $lens->search_sync("terminal");
    show_results(@search_results);
    
        
    ## Asynchronous query
    use Future::Q;
    use Net::DBus::Reactor;
        
    $lens->search("terminal")->then(sub {
        my @search_results = @_;
        show_results(@search_results);
        Net::DBus::Reactor->main->shutdown;
    })->catch(sub {
        my $e = shift;
        warn "Error: $e";
        Net::DBus::Reactor->main->shutdown;
    });
    Net::DBus::Reactor->main->run();


=head1 DESCRIPTION

L<Web::Dash::Lens> is an object that represents a Unity Lens.
Note that this module is for using lenses, not for creating your own lenses.

=head1 CAVEAT

If you use L<AnyEvent::DBus>, do not use C<*_sync()> methods.
Instead you have to use asynchronous methods and explicit condition variables.

    my $cv = AnyEvent->condvar;
    $lens->search_hint()->then(sub {
        $cv->send(@_);
    }, sub {
        $cv->croak(shift);
    });
    my $search_hint = $cv->recv;

This is because L<AnyEvent::DBus> replaces the DBus reactor
that is not completely compatible with the original L<Net::DBus::Reactor> objects.

=head1 CLASS METHOD

=head2 $lens = Web::Dash::Lens->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<lens_file> => FILE_PATH (semi-optional)

The file path to .lens file.
Usually you can find lens files installed under C</usr/share/unity/lenses/>.

You must either specify C<lens_file> or combination of C<service_name> and C<object_name>.

=item C<service_name> => DBUS_SERVICE_NAME (semi-optional)

DBus service name of the lens.

In a .lens file, the service name is specified by C<DBusName> field.

=item C<object_name> => DBUS_OBJECT_NAME (semi-optional)

DBus object name of the lens.

In a .lens file, the object name is specified by C<DBusPath> field.

=item C<reactor> => L<Net::DBus::Reactor> object (optional, default: C<< Net::DBus::Reactor->main >>)

The L<Net::DBus::Reactor> object.
This object is needed for *_sync() methods.

=item C<bus_address> => DBUS_BUS_ADDRESS (optional, default: ":session")

The DBus bus address where this module searches for the lens service.

If C<bus_address> is ":session", the session bus will be used.
If C<bus_address> is ":system", the system bus will be used.
Otherwise, C<bus_address> is passed to C<< Net::DBus->new() >> method.

=item C<concurrency> => CONCURRENCY_NUM (optional, default: 1)

The maximum number of asynchronous search queries that the lens handles simultaneously.

If you call searching methods more than this value before any of the requests is complete,
the extra requests are queued in the lens and processed later.

Setting C<concurrency> to 0 means there is no concurrency limit.

=back

=head1 OBJECT METHODS

=head2 @results = $lens->search_sync($query_string)

Makes a search with the C<$query_string> using the C<$lens>.
C<$query_string> must be a text string, not a binary (octet) string.

In success, this method returns a list of search results (C<@results>).
Each element in C<@results> is a hash-ref containing the following key-value pairs.
All the string values are text strings, not binary (octet) strings.

=over

=item C<uri> => STR

A URI of the result entry.
This URI is designed for Unity.
B<< Normal applications should refer to C<dnd_uri> below >>.

=item C<icon_hint> => STR

A string that specifies the icon of the result entry.


=item C<category_index> => INT

The category index for the result entry.
You can obtain category information by C<category()> method.

=item C<mimetype> => STR

MIME type of the result entry.

=item C<name> => STR

The name of the result entry.

=item C<comment> => STR

One line description of the result entry.

=item C<dnd_uri> => STR

A URI of the result entry.
This URI takes a form that most applications can comprehend.
"dnd" stands for "Drag and Drop", I guess.

=back

In failure, this method throws an exception.

See also: L<https://wiki.ubuntu.com/Unity/Lenses#Schema>


=head2 $future = $lens->search($query_string)

The asynchronous version of C<search_sync()> method.

Instead of returning the results, this method returns a L<Future::Q> object
that represents the search results obtained in future.

In success, C<$future> will be fulfilled. You can obtain the list of search results by C<< $future->get >> method.

In failure, C<$future> will be rejected. You can obtain the exception by C<< $future->failure >> method.


=head2 $search_hint = $lens->search_hint_sync()

Returns the search hint of the C<$lens>. The search hint is a short description of the C<$lens>.
C<$search_hint> is a text string, not a binary (or octet) string.

=head2 $future = $lens->search_hint()

The asynchronous version of C<search_hint_sync()> method.

Instead of returning the results, this method returns a L<Future::Q> object
that represents the search hint obtained in future.

When done, C<$future> will be fulfilled. You can obtain the search hint by C<< $future->get >> method.

=head2 $category_hashref = $lens->category_sync($category_index)

Returns a hash-ref describing the category specified by C<$category_index>.

C<$category_index> is an integer greater than or equal to zero.

C<$category_hashref> is an hash-ref containing information about the category.
It has the following key-value pairs.
All the string values are text strings, not binary (octet) strings.

=over

=item C<name> => STR

The name of the category.

=item C<icon_hint> => STR

A string that specifies the icon of the category.

=item C<renderer> => STR

A string that specifies how the results in this category should be rendered.

=back

If C<$category_index> is invalid, it throws an exception.

=head2 $future = $lens->category($category_index)

The asynchronous version of C<category_sync()> method.

Instead of returning the category hash-ref, this method returns a L<Future::Q> object.

In success, C<$future> will be fulfilled. You can obtain the category hash-ref by C<< $future->get >> method.

In failure, C<$future> will be rejected. You can obtain the exception by C<< $future->failure >> method.


=head2 $service_name = $lens->service_name

Returns the DBus service name of the C<$lens>.

=head2 $object_name = $lens->object_name

Returns the DBus object name of the C<$lens>.

=head2 $new_lens = $lens->clone

Returns the clone of the C<$lens>.

=head1 IMPLEMENTATION

For how L<Web::Dash::Lens> communicates with a Lens process via DBus,
read the source code of L<Web::Dash::Lens> and L<Web::Dash::DeeModel>.
I left some comments there.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
