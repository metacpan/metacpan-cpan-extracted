
package WWW::Kickstarter::Error;

use strict;
use warnings;
no autovivification;


use Exporter qw( import );
our @EXPORT_OK = qw( my_croak );


use Carp qw( );


use overload '""' => \&as_string;


$Carp::CarpInternal{ (__PACKAGE__) } = 1;

{
   my @pkgs = qw(
      WWW::Kickstarter
      WWW::Kickstarter::Data
      WWW::Kickstarter::Data::Categories
      WWW::Kickstarter::Data::Category
      WWW::Kickstarter::Data::NotificationPref
      WWW::Kickstarter::Data::Project
      WWW::Kickstarter::Data::User
      WWW::Kickstarter::Data::User::Myself
      WWW::Kickstarter::Error
      WWW::Kickstarter::HttpClient::Lwp
      WWW::Kickstarter::Iterator
      WWW::Kickstarter::JsonParser::JsonXs
   );

   my $code = join '', map "package $_; our \@CARP_NOT = \@pkgs;\n", @pkgs;
   eval $code."1" or die $@;
}


sub my_croak {
   my ($code, $message) = @_;
   die __PACKAGE__->new($code, $message);
}


sub new {
   my $class   = shift;
   my $code    = @_ > 1 ? shift : 500;
   my $message = shift;

   if (eval { $message->isa(__PACKAGE__) }) {
      return $message;
   }

   my $self = bless({}, $class);
   $self->{code   } = $code;
   $self->{message} = $message;
   $self->{trace  } = Carp::shortmess('');
   return $self;
}


sub code    { $_[0]{code} }
sub message { $_[0]{message} }

sub as_string { $_[0]{message} . $_[0]{trace} }


1;


__END__

=head1 NAME

WWW::Kickstarter::Error - Kickstarter error information


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $exists = 1;
   if (!eval { $ks->user($user_id); 1 }) {
      my $e = WWW::Kickster::Error->new($@);
      die $e if $e->code != 404;
      $exists = 0;
   }


=head1 DESCRIPTION

By throwing objects of this class rather than a string,
the caller can identify certain errors programatically
without relying on matching the exact text of the message.


=head1 CONSTRUCTOR

=head2 new

   my $error = WWW::Kickstarter::Error->new($code, $message);
   my $error = WWW::Kickstarter::Error->new($message);

Creates an WWW::Kickstarter::Error object from the specified C<$code> and C<$message>.
See L<C<code>|/code> for acceptable values for C<$code>.

If C<$message> is an WWW::Kickstarter::Error object, it is simply returned.


=head1 SUBROUTINES

=head2 my_croak

   my_croak($code, $message);

Creates a WWW::Kickstarter::Error object from the arguments and throws it as an exception.


=head1 ACCESSORS

=head2 code

   my $code = $error->code();

The C<$code> passed to L<C<my_croak>|/my_croak> or L<the constructor|/new>.

One of the following:

=over

=item * C<400> to C<499>

Invalid arguments provided.

=item * C<401>

Authentication failure. The user does not exist, or an incorrect password was supplied.

=item * C<404>

The specified user, project or category does not exist.

=item * C<500> to C<599>

A communication error or an unrecognized response.

=back


=head2 message

   my $message = $error->message();

The C<$message> passed to L<C<my_croak>|/my_croak> or L<the constructor|/new>.


=head2 as_string

   my $message = $error->as_string();
   my $message = "$error";

An error message complete with the file name and line number
of the call into the WWW::Kickstarter library.


=head1 EXPORTS

The following are exported on demand:

=over

=item * C<my_croak>

=back


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
