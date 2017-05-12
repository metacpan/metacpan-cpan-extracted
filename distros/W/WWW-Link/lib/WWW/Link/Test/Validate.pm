=head1 NAME

Link::Test::Validate - properly validate resources

=head1 SYNOPSIS

NOT YET IMPLEMENTED

=head1 DESCRIPTION

While simply using libwww-perl's HEAD function will generally pick up
resources which have some problem, there are a whole class of failures
which can be examined in much more detail at much more expense.  This
should be done rarely, but will often be worthwhile.

=head1 EXAMPLES

Resources which are software distributions stored in e.g. compressed
tarfiles can easily be vaildated.  This is done by downloading the
distribution and then attempting to expand it.

More generally, any resource which is represented by a file can be
validated by seeing whether that resource is a valid file of the
format that it should be.

=cut




