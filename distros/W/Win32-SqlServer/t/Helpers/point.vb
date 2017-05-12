' An adaption of the Point sample taken from Books Online for the
' OlleDB test suite. Only integer coordinates are accepted, but there
' a third dimension added.


Imports System
Imports System.Data.Sql
Imports Microsoft.SqlServer.Server
Imports System.Data.SqlTypes
Imports System.Runtime.Serialization

Namespace OlleDBtest

<Serializable(), SqlUserDefinedTypeAttribute(Format.Native)> _
Public Structure OllePoint

    Implements INullable
    Private is_non_Null As Boolean
    Private m_x As Integer
    Private m_y As Integer
    Private m_z As Integer

    Public ReadOnly Property IsNull() As Boolean _
       Implements INullable.IsNull
        Get
            Return (NOT is_non_Null)
        End Get
    End Property

    Public Overrides Function ToString() As String
        If Me.IsNull Then
            Return "NULL"
        Else
            Return Me.m_x & ":" & Me.m_y & ":" & Me.m_z
        End If
    End Function

    Public Shared Function Parse(ByVal s As SqlString) _
    As OllePoint
        If s.IsNull Then
            Return Nothing
        Else
          'Parse input string here to separate out points
           Dim pt as new OllePoint()
           Dim str as String = Convert.ToString(s)
           Dim xy() as String = str.Split(":")
           pt.x = xy(0)
           pt.y = xy(1)
           pt.z = xy(2)
           pt.is_non_null = true
           Return (pt)
        End If
    End Function

    Public Shared ReadOnly Property Null() As OllePoint
        Get
            Dim pt As New OllePoint
            pt.is_non_Null = false
            Return (pt)
        End Get
    End Property

    Public Property X() As Integer
        Get
            Return (Me.m_x)
        End Get
        Set(ByVal Value As Integer)
            m_x = Value
        End Set
    End Property


    Public Property Y() As Integer
        Get
            Return (Me.m_y)
        End Get
        Set(ByVal Value As Integer)
                m_y = Value
        End Set
    End Property

    Public Property Z() As Integer
        Get
            Return (Me.m_z)
        End Get
        Set(ByVal Value As Integer)
           m_z = Value
        End Set
    End Property

    <SqlMethod (IsMutator:=true, OnNullCall:=true)>    Public Sub Transpose()
        Dim x As Integer = m_x
        Dim y As Integer = m_y
        Dim z As Integer = m_z

        m_x = y
        m_y = z
        m_z = x
    End Sub
End Structure

End Namespace
