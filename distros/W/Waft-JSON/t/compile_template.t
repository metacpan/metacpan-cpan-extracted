
use Test;
BEGIN { plan tests => 1 };

use strict;
use vars qw( @ISA );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft with => '::JSON';

my $template = << 'END_OF_TEMPLATE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<title>compile_template.t</title>
<script type="text/javascript"><!-- <![CDATA[
    var hash = <%json= { foo => 1, bar => 2 } %>;
    var array = <%json= [1, 2, 3] %>;
    var hashAndArray = <%json= { foo => 1, bar => [2, 3, 4] } %>;
    // ]]> -->
</script>
</head>
<body>
</body>
</html>
END_OF_TEMPLATE

my $filtered = << 'END_OF_FILTERED';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<title>compile_template.t</title>
<script type="text/javascript"><!-- <![CDATA[
    var hash = {"bar":2,"foo":1};
    var array = [1,2,3];
    var hashAndArray = {"bar":[2,3,4],"foo":1};
    // ]]> -->
</script>
</head>
<body>
</body>
</html>
END_OF_FILTERED

my $output = q{};

sub output {
    ( undef, my @strings ) = @_;

    $output .= join q{}, @strings;

    return;
}

my $self = __PACKAGE__->new->initialize;

my $coderef = $self->compile_template($template, $0, __PACKAGE__);
$self->$coderef();

ok( $output eq $filtered );
