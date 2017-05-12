use Win32::MultiMedia::Mci(SendString);

SendString("open count.avi alias avi1");
SendString("play avi1 wait");
SendString("close avi1");
