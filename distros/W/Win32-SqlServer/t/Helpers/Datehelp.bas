Attribute VB_Name = "Datehelp"
Option Explicit

Public Sub Main()
Dim d As Date, _
    str As String
Open "datehelperin.txt" For Input Access Read As 1
Open "datehelperout.txt" For Output Access Write As 2
While Not EOF(1)
   Line Input #1, str
   d = CDate(str)
   Print #2, FormatDateTime(d) & " £ " & _
             Format(d, "YYYY-MM-DD HH:MM:SS")
Wend
Close #1, #2
End Sub


