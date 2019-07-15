use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

package MyBase {
    sub new {
        my $class = shift;
        return bless {} => $class;
    };
    sub on_client {
        my ($self, $client) = @_;
        print "MyBase::on_client\n";
        if ($client->{status} eq 'authorized'){ $client->{send} = '[welcome]' }
        elsif ($client->{status} eq 'not_authorized') { $client->{send} = '[disconnect]' };
    }
};

package MyLogger {
    use base qw/MyBase/;

    sub new {
        my $class = shift;
        my $obj = $class->next::method(@_) // {};
        return bless $obj => $class;
    }
    sub on_client {
        my ($self, $client) = @_;
        print "MyLogger::on_client\n";
        print "client ", $client->{id}, ", status = ", $client->{status}, "\n";
        $self->next::method($client);
        print "client ", $client->{id}, ", status = ", $client->{status}, "\n";
    }
};

package MyAuth {
    use base qw/MyBase/;

    sub new {
        my $class = shift;
        my $obj = $class->next::method(@_) // {};
        return bless $obj => $class;
    }
    sub on_client {
        my ($self, $client) = @_;
        print "MyAuth::on_client\n";
        if ($client->{id} < 0) { $client->{status} = 'not_authorized'; }
        else { $client->{status} = 'authorized'; }
        $self->next::method($client);
    }
};

package MyXServer {
    use base qw/MyLogger MyAuth MyBase/;
    sub new {
        my $class = shift;
        my $obj = $class->next::method(@_) // {};
        return bless $obj => $class;
    }
};

my $client = {status => 'connected', id => 10};
my $server = MyXServer->new;
$server->on_client($client);

print "\nLet's try in XS\n";

my $client2 = MyTest::Cookbook::Client07->new(10);
my $server2 = MyTest::Cookbook::Server07->new;
$server2->on_client($client2);

pass();
done_testing;
