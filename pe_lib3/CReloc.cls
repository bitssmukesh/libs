VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CReloc"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'2.2.2010 David Zimmer <dzzie@yahoo.com>

Public RType As Long
Public rva As Long
Public CurValue As Long
Public length As Long
Public CurBase As Long
Public index As Long
Public errLog As String

'assumes newbase is lower than oldbase
Public Function Recalc(newBase As Long) As Double
    Dim delta
    On Error GoTo hell
    
    Dim cv As New ULong 'changed from asm 2.14.18
    
    cv = CurValue
    errLog = Empty
    
    Select Case RType
        Case 3: 'HIGHLOW
            'Recalc = RelocCalc(CurValue, CurBase, newBase) '(CurValue - CurBase) - newBase
            Recalc = CLng(cv.subtract(CurBase).subtract(newBase)) 'subtract without overflow
        Case Default:
            errLog = errLog & "Unsupported reloc type: " & RType & " offset: " & rva & vbCrLf
    End Select
    
Exit Function
hell: Recalc = -1
Debug.Print "Err in recalc: " & Me.rva & " " & Err.Description

End Function

Public Function GetInfo(Optional newBase As Long)
    
    GetInfo = "Index:" & Hex(index) & " Type: " & Hex(RType) & " VA: " & Hex(CurBase + rva) & _
              " RVA:" & Hex(rva) & " CurVal:" & Hex(CurValue) & " CurBase:" & Hex(CurBase)
              
    If newBase > 0 Then GetInfo = GetInfo & " Recalc(" & Hex(newBase) & ")=" & Hex(Recalc(newBase))
    
End Function
    
