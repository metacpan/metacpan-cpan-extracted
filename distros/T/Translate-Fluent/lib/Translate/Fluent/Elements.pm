package Translate::Fluent::Elements;

use Translate::Fluent::Elements::Message;
use Translate::Fluent::Elements::Pattern;
use Translate::Fluent::Elements::PatternElement;
use Translate::Fluent::Elements::InlinePlaceable;
use Translate::Fluent::Elements::InlineText;
use Translate::Fluent::Elements::InlineExpression;
use Translate::Fluent::Elements::BlockText;
use Translate::Fluent::Elements::BlockPlaceable;
use Translate::Fluent::Elements::FunctionReference;
use Translate::Fluent::Elements::VariableReference;
use Translate::Fluent::Elements::CallArguments;
use Translate::Fluent::Elements::ArgumentList;
use Translate::Fluent::Elements::Argument;
use Translate::Fluent::Elements::NamedArgument;
use Translate::Fluent::Elements::MessageReference;
use Translate::Fluent::Elements::TermReference;
use Translate::Fluent::Elements::AttributeAccessor;
use Translate::Fluent::Elements::StringLiteral;
use Translate::Fluent::Elements::Term;
use Translate::Fluent::Elements::SelectExpression;
use Translate::Fluent::Elements::Variant;
use Translate::Fluent::Elements::DefaultVariant;
use Translate::Fluent::Elements::Attribute;

sub create {
  my (undef, $type, $args) = @_;

  $type = "\u$type";
  $type =~ s/_(.)/\u$1/g;

  my $class = "Translate::Fluent::Elements::$type";

  my $res;
  eval {
    $res = $class->new( %$args );

    1;
  } or do {
    my ($err) = $@;
    print STDERR "err: $err\n"
      unless $err =~ m{Can't locate object method "new"};
    unless ($type eq 'Text') {
      print STDERR "FLT: Missing $class\n";
    }
  };

  return $res;
}

1;

__END__

=head1 NOTHING TO SEE HERE

this file is part of L<Translate::Fluent>. See its documentation for more information

=head2 create

this package implements a create method, but is not that interesting


=cut

