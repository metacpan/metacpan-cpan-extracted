use t::boilerplate;

use English      qw( -no_match_vars );
use File::DataClass::IO;
use Scalar::Util qw( blessed );
use Test::More;

{  package TestConfig;

   use File::DataClass::IO;
   use Moo;

   # For Role::TT
   has 'layout'  => is => 'ro', default => 'standard';
   has 'root'    => is => 'ro', builder => sub { io[ 't', 'root' ] };
   has 'skin'    => is => 'ro', default => 'default';
   has 'tempdir' => is => 'ro', builder => sub { io[ 't' ] };

   # For Role::Email (optional)
   has 'email_attr'     => is => 'ro', builder => sub { { charset => 'UTF-8' }};
   has 'transport_attr' => is => 'ro', builder => sub { { class => 'Test' } };
}

my $logged_error = q();

{  package TestLog;

   use Moo;

   sub error { $logged_error = $_[ 1 ] }
}

{  package Test;

   use Moo;

   # Role::Email requires config and log
   has 'config' => is => 'ro', builder => sub { TestConfig->new };
   has 'log'    => is => 'ro', builder => sub { TestLog->new };

   with 'Web::Components::Role::Email';
}

my $test = Test->new;

can_ok $test, 'send_email';

eval { $test->send_email }; my $e = $EVAL_ERROR;

like $e, qr{ \Qemail args\E .* \Qnot specified\E }mx, 'Default error';

eval { $test->send_email( {} ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qfrom\E .* \Qnot specified\E }mx, 'From not specified';

eval { $test->send_email( { from => 'dave@example.com' } ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qto\E .* \Qnot specified\E }mx, 'To not specified';

eval { $test->send_email( { from => 'dave@example.com',
                            to   => 'john@nowhere.com', } ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qtemplate\E .* \Qnot specified\E }mx, 'Template not specified';

my $res = eval { $test->send_email( {
   from => 'dave@example.com',
   to   => 'john@nowhere.com',
   body => 'This is the message body', } ) };

is $res, 'OK Message sent', 'Test send success - with message body';

$res = eval { $test->try_to_send_email( {
   from     => 'dave@example.com',
   to       => 'john@nowhere.com',
   template => 'standard', } ) };

is $res, 'OK Message sent', 'Test send success - from template';

$res = eval { $test->send_email( {
   from     => 'dave@example.com',
   to       => 'john@nowhere.com',
   template => 'not_found', } ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qnot found\E }mx, 'Template not found';

$res = eval { $test->send_email( {
   from           => 'dave@example.com',
   to             => 'john@nowhere.com',
   body           => 'This is the message body',
   transport_attr => { class => 'Unknown', }, } ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qlocate\E .* \QUnknown\E }mx, 'Unknown transport class';

$res = eval { $test->try_to_send_email( {
   from           => 'dave@example.com',
   to             => 'john@nowhere.com',
   body           => 'This is the message body',
   transport_attr => { class => 'Unknown', }, } ) };

like $res, qr{ \Qlocate\E .* \QUnknown\E }mx, 'Try to send does not throw';
like $logged_error, qr{ \Qlocate\E .* \QUnknown\E }mx, 'Logs errors';

my $foo_count = 0; my $loc_count = 0;

{  package TestReq;

   use Moo;

   sub foo { $foo_count++; $_[ 1 ] }
   sub loc { $loc_count++; $_[ 1 ] }
}

$res = eval { $test->send_email( {
   from        => 'dave@example.com',
   to          => 'john@nowhere.com',
   template    => 'standard', # Standard template calls loc subroutine
   subprovider => TestReq->new, } ) };

is $res, 'OK Message sent', 'Test send success - with subprovider';
is $loc_count, 1, 'Localises text';

$res = eval { $test->send_email( {
   from        => 'dave@example.com',
   to          => 'john@nowhere.com',
   template    => 'extended', # Extended template calls foo and loc subroutines
   subprovider => TestReq->new,
   functions   => [ 'foo', 'loc', ], } ) };

is $res, 'OK Message sent', 'Test send success - with functions';
is $foo_count, 1, 'Calls included function';
is $loc_count, 2, 'Localises text - again';

my $file = io[ 't', 'root', 'not_found.txt' ];

$res = eval { $test->send_email( {
   from        => 'dave@example.com',
   to          => 'john@nowhere.com',
   body        => 'This is the message body',
   attachments => { file => $file->pathname }, } ) }; $e = $EVAL_ERROR;

like $e, qr{ \Qnot_found\E .* \Qcannot open\E }mx, 'Non existant attachment';

$file = io[ 't', 'root', 'attachment.txt' ];

$res = eval { $test->send_email( {
   from        => 'dave@example.com',
   to          => 'john@nowhere.com',
   body        => 'This is the message body',
   attachments => { file => $file->pathname }, } ) }; $e = $EVAL_ERROR;

is $res, 'OK Message sent', 'Test send success - with attachment';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
