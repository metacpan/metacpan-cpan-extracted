use Test;
BEGIN { plan tests => 21 };

#1
use Text::ParagraphDiff;
ok(1);

#2
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle last \n</p>\n) ? ok(1) : ok(0);

#3
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle last extra"]
) eq qq(\n<p>\nFirst middle last  <span class="plus"> extra</span> \n</p>\n) ? ok(1) : ok(0);

#4
Text::ParagraphDiff::create_diff( ["First middle last extra"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle last  <span class="minus"> extra</span> \n</p>\n) ? ok(1) : ok(0);

#5
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["Extra First middle last"]
) eq qq(\n<p>\n <span class="plus"> Extra</span> First middle last \n</p>\n) ? ok(1) : ok(0);

#6
Text::ParagraphDiff::create_diff( ["Extra First middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="minus"> Extra</span> First middle last \n</p>\n) ? ok(1) : ok(0);

#7
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First middle other"]
) eq qq(\n<p>\nFirst middle  <span class="plus"> other</span>  <span class="minus"> last</span> \n</p>\n) ? ok(1) : ok(0);

#8
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["First other last"]
) eq qq(\n<p>\nFirst  <span class="plus"> other</span>  <span class="minus"> middle</span> last \n</p>\n) ? ok(1) : ok(0);

#9
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  ["Other middle last"]
) eq qq(\n<p>\n <span class="plus"> Other</span>  <span class="minus"> First</span> middle last \n</p>\n) ? ok(1) : ok(0);

#10
Text::ParagraphDiff::create_diff( ["First middle other"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst middle  <span class="plus"> last</span>  <span class="minus"> other</span> \n</p>\n) ? ok(1) : ok(0);

#11
Text::ParagraphDiff::create_diff( ["First other last"],
                                  ["First middle last"]
) eq qq(\n<p>\nFirst  <span class="plus"> middle</span>  <span class="minus"> other</span> last \n</p>\n) ? ok(1) : ok(0);

#12
Text::ParagraphDiff::create_diff( ["Other middle last"],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="plus"> First</span>  <span class="minus"> Other</span> middle last \n</p>\n) ? ok(1) : ok(0);

#13
Text::ParagraphDiff::create_diff( [""],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="plus"> First middle last</span> \n</p>\n) ? ok(1) : ok(0);

#14
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  [""],
) eq qq(\n<p>\n <span class="minus"> First middle last</span> \n</p>\n) ? ok(1) : ok(0);

#15
Text::ParagraphDiff::create_diff( [],
                                  ["First middle last"]
) eq qq(\n<p>\n <span class="plus"> First middle last</span> \n</p>\n) ? ok(1) : ok(0);

#16
Text::ParagraphDiff::create_diff( ["First middle last"],
                                  []
) eq qq(\n<p>\n <span class="minus"> First middle last</span> \n</p>\n) ? ok(1) : ok(0);

#17
Text::ParagraphDiff::create_diff( ["First other last"],
                                  ["First middle last"],
                                  { plain => 1 }
) eq qq(\n<p>\nFirst  <b><font color="#005500" size="+1"> middle</font></b>  <b><font color="#FF0000" size="+1"> other</font></b> last \n</p>\n) ? ok(1) : ok(0);

#18
Text::ParagraphDiff::create_diff( "First middle last extra",
                                  "First middle last",
                                  { string => 1 }
) eq qq(\n<p>\nFirst middle last  <span class="minus"> extra</span> \n</p>\n) ? ok(1) : ok(0);

#19
Text::ParagraphDiff::create_diff( ["First middle last", "First middle last"],
                                        ["First middle last"]
) eq qq(\n<p>\nFirst middle last \n</p>\n\n<p>\n <span class="minus"> First middle last</span> \n</p>\n) ? ok(1) : ok(0);

#20
Text::ParagraphDiff::create_diff( ["First middle last","a b c"],
                        ["one two three","First middle last"]
) eq qq(\n<p>\n <span class="plus"> one two three</span> \n</p>\n\n<p>\nFirst middle last \n</p>\n\n<p>\n <span class="minus"> a b c</span> \n</p>\n) ? ok(1) : ok(0);

#21
Text::ParagraphDiff::create_diff( ["test 1 2"],
                                  ["test 3 4"]
) eq qq(\n<p>\ntest  <span class="plus"> 3 4</span>  <span class="minus"> 1 2</span> \n</p>\n) ? ok(1) : ok(0);
