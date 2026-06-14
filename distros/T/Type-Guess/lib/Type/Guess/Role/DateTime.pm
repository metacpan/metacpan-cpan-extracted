package Type::Guess::Role::DateTime;

use Moo::Role;
use Carp;

use Module::Runtime qw(require_module);

my $_parser = {
	       parser_class => "DateTime::Format::Flexible",
	       parser_opts => [],
	       parser_method => "parse_datetime"
	      };


sub parser_class {
    my $self = shift;
    my @keys = qw/parser_class parser_opts parser_method/;
    if (@_) {
	my @args = @_;
	my %args;
	$args[0] = "DateTime::Format::" . $args[0] unless $args[0] =~ /^DateTime::Format::/;
	@args{@keys} = @args;
	$_parser = { %$_parser, %args };
    }
    require_module $_parser->{parser_class};
    return map { $_parser->{$_} } qw/parser_class parser_opts parser_method/;
}

around '_type' => sub {
    my ($orig, $class, @vals) = @_;

    my ($parser_class, $parser_opts, $parser_method) = $class->parser_class;
    return "DateTime" if $class->_enough(sub { eval { $parser_class->$parser_method($_, $parser_opts->@*) } }, @vals);
    return $orig->($class, @vals);
};


1

