package Scanner::Actions;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Return Echo Ignore);

sub Return { $_[1]; }
sub Echo { print $_[1]; 0; }
sub Ignore { 0; }

1;
