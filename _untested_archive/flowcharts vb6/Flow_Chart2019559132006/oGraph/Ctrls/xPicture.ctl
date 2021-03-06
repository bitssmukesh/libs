VERSION 5.00
Begin VB.UserControl oPicture 
   Appearance      =   0  'Flat
   BackColor       =   &H80000005&
   CanGetFocus     =   0   'False
   ClientHeight    =   1050
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   1470
   BeginProperty Font 
      Name            =   "Microsoft Sans Serif"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   HasDC           =   0   'False
   InvisibleAtRuntime=   -1  'True
   ScaleHeight     =   1050
   ScaleWidth      =   1470
   Windowless      =   -1  'True
   Begin VB.Image ImgBuffer 
      Height          =   735
      Left            =   240
      Top             =   120
      Width           =   735
   End
End
Attribute VB_Name = "oPicture"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

'--------------------------Object Declaration----------------------------------
Private WithEvents m_oConvasPicBox As PictureBox
Attribute m_oConvasPicBox.VB_VarHelpID = -1

Private m_IXGraphics As IXGraphics
Private m_LinkedStepKey As StepKeys
'--------------------------Private Variables-----------------------------------
Private m_Selected As Boolean
Private m_NodeKey As String
Private m_ToolTipText As String
Private m_Visible As Boolean
Private m_Image As Long
Private m_Height As Double
Private m_Width As Double
Private m_Region As Long
Private m_Path As Long
Private m_PathText As Long
Private m_PathBack As Long
Private m_ForeColor As OLE_COLOR
Private m_Font As Font
Private m_DefFontSize As Single
Private m_Picture As StdPicture
'--------------------------Control Events---------------------------
Public Event Activate(ByVal XCentre As Double, ByVal YCentre As Double)
Public Event UnSelectAll(ByVal pExceptNodeKey As String)
Public Event RightClick(ByVal Key As String, ByVal X As Double, ByVal Y As Double)
Public Event Click(ByVal Key As String)
Public Event DoubleClick(ByVal Key As String)
Public Event MouseDown(ByVal Key As String, ByVal Button As Integer, ByVal Shift As Integer, ByVal X As Double, ByVal Y As Double)
Public Event MouseMove(ByVal Key As String, ByVal Button As Integer, ByVal Shift As Integer, ByVal X As Double, ByVal Y As Double)
Public Event MouseUp(ByVal Key As String, ByVal Button As Integer, ByVal Shift As Integer, ByVal X As Double, ByVal Y As Double)
Public Event Selected(ByVal Key As String)
Public Event Deleted(ByVal Key As String)
Public Event ReAlign(ByVal ShiftX As Double, ByVal ShiftY As Double)
Public Event MaxExtend(ByVal Width As Single, ByVal Height As Single)
'--------------------------Events End---------------------------------
'Default Property Values:
Const m_def_CentreX = 0
Const m_def_CentreY = 0
'Property Variables:
Private m_CentreX As Double
Private m_CentreY As Double
Private m_CentreOldX As Double
Private m_CentreOldY As Double
Private m_IsConnection As Boolean
Private m_MouseX As Double
Private m_MouseY As Double
Private m_TempX As Double
Private m_TempY As Double
Private m_TempPx1() As Double
Private m_TempPy1() As Double
Private m_TempPx2() As Double
Private m_TempPy2() As Double
Private m_TempUbound  As Single
Private m_SidePoints(3) As Collection

Private m_PointPerSide As Single
Private m_RaiseFromInside As Boolean
Private m_blnPointMoving As Boolean
Private m_DblClicked As Boolean
Private m_Caption As String
Private m_ImageRect As RECTF
Private m_LineGap As Single
Private m_Zoom As Single
Private m_TextRect As RECTF
Private m_ZoomFactor As Double
'--------------------------Properties---------------------------------
Public Property Let oSelected(ByVal pSelected As Boolean)
    m_Selected = pSelected

    If m_RaiseFromInside Then
        RaiseEvent Selected(m_NodeKey)
        Me.Paint
        m_RaiseFromInside = False
    End If
End Property

Public Property Get oSelected() As Boolean
    oSelected = m_Selected
End Property

Public Property Let NodeKey(ByVal pNodeKey As String)
    m_NodeKey = pNodeKey
End Property

Public Property Get NodeKey() As String
    NodeKey = m_NodeKey
End Property

Public Property Let ToolTipText(ByVal pToolTipText As String)
    m_ToolTipText = pToolTipText
End Property

Public Property Get ToolTipText() As String
    ToolTipText = m_ToolTipText
End Property


Public Property Get LinkedStepKey() As StepKeys
    If m_LinkedStepKey Is Nothing Then Set m_LinkedStepKey = New StepKeys
    Set LinkedStepKey = m_LinkedStepKey
End Property

Public Property Set LinkedStepKey(ByVal pLinkedStepKey As StepKeys)
    Set m_LinkedStepKey = pLinkedStepKey
End Property

'Public Function LinkedStepKey() As StepKeys
'    If (m_LinkedStepKey Is Nothing) Then Set m_LinkedStepKey = New StepKeys
'    Set LinkedStepKey = m_LinkedStepKey
'End Function

Public Property Get Visible() As Boolean
    Visible = m_Visible
End Property

Public Property Let Visible(ByVal pVisible As Boolean)
    m_Visible = pVisible
    If m_Visible Then
        Call CreateRegion
        Me.Paint
    Else
        m_oConvasPicBox.Tag = ""
        m_oConvasPicBox.ToolTipText = ""
        m_oConvasPicBox.MousePointer = vbDefault
        Call BeforeTerminate
    End If
    
End Property

'--------------------------Properties End-------------------------------
Public Sub Activate()
    m_blnPointMoving = False
    m_DblClicked = False
    RaiseEvent Activate(m_CentreX, m_CentreY)
    Me.Paint
End Sub

Friend Sub ReAlign()
    RaiseEvent ReAlign(m_CentreX - m_CentreOldX, m_CentreY - m_CentreOldY)
End Sub

Public Sub CordsChanged()
    Call m_oConvasPicBox_MouseDown(vbLeftButton, 0, CSng(m_CentreX), CSng(m_CentreY))
    Call m_oConvasPicBox_MouseMove(vbLeftButton, 0, CSng(m_CentreX) + 1, CSng(m_CentreY) + 1)
    Call m_oConvasPicBox_MouseUp(vbLeftButton, 0, CSng(m_CentreX), CSng(m_CentreY))
End Sub

Public Sub Paint()
    Dim pPen As Long
    Dim pTextPen As Long
    Dim pWidth As Single
    Dim pTextvbColor As Long
    Dim pColor As Colors
    Dim pTextBrush As Long
    Dim pSelectedBrush As Long
    Dim pRect As RECTF
    Dim pImageRect As RECTF
    If m_Visible Then
        If m_IXGraphics Is Nothing Then Call InitilizeEnviornment
        If m_Selected Then
            pWidth = 3
            pColor = DarkBlue
        Else
            pWidth = 1
            pColor = Black
        End If
        
        'Call GdipGetImageBounds(m_Image, pRect, UnitPixel)
        LSet pRect = m_ImageRect
        
        'Call GdipDrawImage(m_IXGraphics.GetoGraphicsHandle, m_Image, m_CentreX / 15 - pRect.Width / 2, m_CentreY / 15 - pRect.Height / 2)
        Call GdipDrawImageRect(m_IXGraphics.GetoGraphicsHandle, m_Image, m_CentreX / 15 - pRect.Width / 2, m_CentreY / 15 - pRect.Height / 2, pRect.Width, pRect.Height)
        Call GdipCreatePen1(pColor, pWidth, UnitPixel, pPen)
        
        Call GdipCreateSolidFill(GetGDIColorFromOLE(&HFFFFFF, 190), pTextBrush)
        Call GdipCreateSolidFill(GetGDIColorFromOLE(&H8000000D, 140), pSelectedBrush)
        
        Call GdipCreatePen1(Colors.Black, 1, UnitPixel, pTextPen)
        Call GdipSetPenLineJoin(pPen, LineJoinRound)
        'Call GdipDrawPath(m_IXGraphics.GetoGraphicsHandle, pPen, m_Path)
        If m_Selected Then
            Call GdipFillPath(m_IXGraphics.GetoGraphicsHandle, pSelectedBrush, m_Path)
            Call GdipFillPath(m_IXGraphics.GetoGraphicsHandle, pSelectedBrush, m_PathBack)
            Call GdipDeleteBrush(pSelectedBrush)
        Else
            Call GdipFillPath(m_IXGraphics.GetoGraphicsHandle, pTextBrush, m_PathBack)
        End If
        Call GdipDrawPath(m_IXGraphics.GetoGraphicsHandle, pTextPen, m_PathBack)
        
        Call GdipDeleteBrush(pTextBrush)
        Call GdipCreateSolidFill(GetGDIColorFromOLE(m_ForeColor), pTextBrush)
        
        
        'Call GdipDrawPath(m_IXGraphics.GetoGraphicsHandle, pTextPen, m_PathText)
        Call GdipFillPath(m_IXGraphics.GetoGraphicsHandle, pTextBrush, m_PathText)
        
        Call GdipDeletePen(pPen)
        Call GdipDeletePen(pTextPen)
        Call GdipDeleteBrush(pTextBrush)
        m_IXGraphics.RePaintoConvas
        
    End If
End Sub

Private Sub m_oConvasPicBox_DblClick()
    m_DblClicked = True
End Sub

Private Sub m_oConvasPicBox_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyDelete And m_Selected Then
        RaiseEvent Deleted(m_NodeKey)
        Call BeforeTerminate
    End If
End Sub

Private Sub m_oConvasPicBox_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim pResult  As Long
    m_MouseX = 0
    m_MouseY = 0
    If m_IXGraphics.IsoConvasLocked Then Exit Sub
    If m_Visible Then
        
        If m_Region <> 0 Then
            Call GdipIsVisibleRegionPoint(m_Region, X / 15, Y / 15, m_IXGraphics.GetoGraphicsHandle, pResult)
            
            If (pResult = 1 Or (m_IXGraphics.IsSelected(m_NodeKey) And Shift = vbCtrlMask)) Then
                m_MouseX = X / 15
                m_MouseY = Y / 15
                
                m_blnPointMoving = True
                
                If Not (m_IXGraphics.IsSelected(m_NodeKey) And Shift = vbCtrlMask) Then
                
                Else
                    
                    m_CentreOldX = m_CentreX
                    m_CentreOldY = m_CentreY
                End If
                If Not m_Selected Then
                    m_RaiseFromInside = True
                    Me.oSelected = True
                End If
                RaiseEvent Click(m_NodeKey)
                    If Button = vbRightButton And pResult = 1 Then
                        RaiseEvent RightClick(m_NodeKey, X, Y)
                        m_oConvasPicBox.Tag = ""
                        m_oConvasPicBox.ToolTipText = ""
                        m_oConvasPicBox.MousePointer = vbDefault
                        m_blnPointMoving = False
                        Exit Sub
                    End If
                RaiseEvent MouseDown(m_NodeKey, Button, Shift, CDbl(X), CDbl(Y))
            Else
                
                If m_Selected Then
                    m_RaiseFromInside = True
                    If Shift <> vbCtrlMask Then
                        Me.oSelected = False
                    End If
                End If
            End If
        
        End If
        
    End If
End Sub

Private Sub m_oConvasPicBox_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim pResult  As Long
    Dim pShiftX As Double
    Dim pShiftY As Double
    
    pShiftX = m_CentreX - m_MouseX * 15
    pShiftY = m_CentreY - m_MouseY * 15
    If m_oConvasPicBox.Tag = "" Then m_oConvasPicBox.MousePointer = vbDefault
    If m_IXGraphics.IsoConvasLocked Or Not m_Visible Then
        If m_oConvasPicBox.Tag = m_NodeKey Then
           m_oConvasPicBox.Tag = ""
           m_oConvasPicBox.ToolTipText = ""
           m_oConvasPicBox.MousePointer = vbDefault
        End If
        m_blnPointMoving = False
        m_DblClicked = False
        Exit Sub
    End If
    If m_Visible Then
        
        Call CreateSidePoints(CDbl(X + pShiftX), CDbl(Y + pShiftY))
        If m_Region <> 0 And Not m_blnPointMoving And Button = 0 Then
            Call GdipIsVisibleRegionPoint(m_Region, X / 15, Y / 15, m_IXGraphics.GetoGraphicsHandle, pResult)
            If pResult = 1 Then
               m_TempX = X
               m_TempY = Y
               m_oConvasPicBox.Tag = m_NodeKey
               If Shift <> vbCtrlMask Then
                    m_oConvasPicBox.ToolTipText = m_ToolTipText
                    m_oConvasPicBox.MousePointer = MousePointerConstants.vbSizeAll 'GetPointer(X / 15, Y / 15)
               Else
                    m_oConvasPicBox.ToolTipText = ""
                    m_oConvasPicBox.MousePointer = MousePointerConstants.vbCustom
               End If
               RaiseEvent MouseMove(m_NodeKey, Button, Shift, CDbl(X + pShiftX), CDbl(Y + pShiftY))
            Else
                'If Shift <> vbCtrlMask Then
                     If m_oConvasPicBox.Tag = m_NodeKey Then
                        m_oConvasPicBox.Tag = ""
                        m_oConvasPicBox.ToolTipText = ""
                        m_oConvasPicBox.MousePointer = vbDefault
                     End If
               'Else
                '    m_oConvasPicBox.ToolTipText = ""
                 '   m_oConvasPicBox.MousePointer = MousePointerConstants.vbCustom
               'End If
           End If
        ElseIf m_blnPointMoving And Button = vbLeftButton Then
                m_TempX = X
                m_TempY = Y
                Call DrawTempLine(X / 15, Y / 15)
                RaiseEvent MouseMove(m_NodeKey, Button, Shift, CDbl(X + pShiftX), CDbl(Y + pShiftY))
        Else
            m_TempX = 0
            m_TempY = 0
            If pResult = 0 And m_blnPointMoving Then
                m_blnPointMoving = False
                If m_oConvasPicBox.Tag = m_NodeKey Then
                        m_oConvasPicBox.Tag = ""
                        m_oConvasPicBox.ToolTipText = ""
                        m_oConvasPicBox.MousePointer = vbDefault
                End If
            End If
        End If
    End If

End Sub



Private Function DrawLine(ByRef pLineIndex As Single, ByVal X1 As Double, ByVal Y1 As Double, ByVal X2 As Double, ByVal Y2 As Double, Optional ByVal ErasePresious As Boolean = True) As LINE_POINT()
        Dim pIndex As Single
        Dim pSearchX As Double
        Dim pSearchY As Double
        Dim pFound As Boolean
        If X1 = X2 And Y1 = Y2 And X1 = Y1 And X1 = 0 Then

            ReDim pPoints(m_TempUbound + 1)
            pIndex = 0
            pLineIndex = 0
            pFound = False
            m_oConvasPicBox.DrawMode = DrawModeConstants.vbCopyPen
            If m_TempUbound > 0 Then
                For pLineIndex = 0 To m_TempUbound
                        
                    If m_Visible Then m_oConvasPicBox.Line (m_TempPx1(pLineIndex) * 15, m_TempPy1(pLineIndex) * 15)-(m_TempPx2(pLineIndex) * 15, m_TempPy2(pLineIndex) * 15)
                Next
                pIndex = 1
                CentreX = (IIf(m_TempPx1(pIndex) < m_TempPx2(pIndex), m_TempPx1(pIndex), m_TempPx2(pIndex)) + Abs(m_TempPx1(pIndex) - m_TempPx2(pIndex)) / 2) * 15
                pIndex = 0
                CentreY = (IIf(m_TempPy1(pIndex) < m_TempPy2(pIndex), m_TempPy1(pIndex), m_TempPy2(pIndex)) + Abs(m_TempPy1(pIndex) - m_TempPy2(pIndex)) / 2) * 15
                Call CreateRegion
                Call CreatePath
            Else
                'pPoints = m_Points

            End If
            Erase m_TempPx1
            Erase m_TempPy1
            Erase m_TempPx2
            Erase m_TempPy2
            m_TempUbound = 0
            'DrawLine = pPoints
            Exit Function
        End If

        If m_TempUbound <= pLineIndex Then
            ReDim Preserve m_TempPx1(pLineIndex)
            ReDim Preserve m_TempPy1(pLineIndex)
            ReDim Preserve m_TempPx2(pLineIndex)
            ReDim Preserve m_TempPy2(pLineIndex)
            m_TempUbound = UBound(m_TempPx1)
        End If
        
        m_oConvasPicBox.DrawMode = DrawModeConstants.vbInvert
        If ErasePresious And m_Visible Then m_oConvasPicBox.Line (m_TempPx1(pLineIndex) * 15, m_TempPy1(pLineIndex) * 15)-(m_TempPx2(pLineIndex) * 15, m_TempPy2(pLineIndex) * 15)
        m_TempPx1(pLineIndex) = X1
        m_TempPy1(pLineIndex) = Y1
        m_TempPx2(pLineIndex) = X2
        m_TempPy2(pLineIndex) = Y2
        If m_Visible Then m_oConvasPicBox.Line (X1 * 15, Y1 * 15)-(X2 * 15, Y2 * 15)
        pLineIndex = pLineIndex + 1

End Function


Private Sub DrawTempLine(ByVal X As Double, ByVal Y As Double)
    Dim px1 As Double
    Dim py1 As Double
    Dim px2 As Double
    Dim py2 As Double
    Dim pShiftX As Double
    Dim pShiftY As Double
    Dim pLineIndex As Single
    pShiftX = m_CentreX / 15 - m_MouseX
    pShiftY = m_CentreY / 15 - m_MouseY
    'For pLineIndex = 0 To 3
        Call DrawLine(0, X + pShiftX - m_Width / 2, Y + pShiftY - m_Height / 2, X + pShiftX - m_Width / 2, Y + pShiftY + m_Height / 2, True)
        
        Call DrawLine(1, X + pShiftX - m_Width / 2, Y + pShiftY - m_Height / 2, X + pShiftX + m_Width / 2, Y + pShiftY - m_Height / 2, True)
        
        Call DrawLine(2, X + pShiftX + m_Width / 2, Y + pShiftY - m_Height / 2, X + pShiftX + m_Width / 2, Y + pShiftY + m_Height / 2, True)
        Call DrawLine(3, X + pShiftX - m_Width / 2, Y + pShiftY + m_Height / 2, X + pShiftX + m_Width / 2, Y + pShiftY + m_Height / 2, True)
    'Next


End Sub


Private Sub m_oConvasPicBox_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim pResult As Long
    If m_Visible Then
        If m_IXGraphics.IsoConvasLocked Then
            m_blnPointMoving = False
            m_DblClicked = False
            Exit Sub
        End If
        If m_DblClicked Then
            Call GdipIsVisibleRegionPoint(m_Region, X / 15, Y / 15, m_IXGraphics.GetoGraphicsHandle, pResult)
            If pResult = 1 Then
                RaiseEvent DoubleClick(m_NodeKey)
            End If
            m_DblClicked = False
        End If
        
        If m_blnPointMoving Then
            Call DrawLine(0, 0, 0, 0, 0)
            m_blnPointMoving = False
            Me.Paint
            RaiseEvent MouseUp(m_NodeKey, Button, Shift, CDbl(X), CDbl(Y))
            RaiseEvent MaxExtend((m_TextRect.Left + m_TextRect.Width) * 15, (m_TextRect.Top + m_TextRect.Height) * 15)
        End If
        
    End If
End Sub


Public Sub ReSizeoConvas()
        Call InitilizeEnviornment
        Call CreateImage
        Call CreatePath
        Call CreateRegion
End Sub

Private Sub UserControl_InitProperties()
    Set m_LinkedStepKey = New StepKeys
    Set m_SidePoints(0) = New Collection
    Set m_SidePoints(1) = New Collection
    Set m_SidePoints(2) = New Collection
    Set m_SidePoints(3) = New Collection
    Set m_LinkedStepKey = New StepKeys
    m_ForeColor = &HF000000
    Set m_Font = Ambient.Font
    m_PointPerSide = 10
    m_LineGap = 250
    m_ZoomFactor = 1
    m_CentreX = m_def_CentreX
    m_CentreY = m_def_CentreY
End Sub

'--------------------------Control Handling---------------------------------
Private Sub UserControl_Paint()
    UserControl.Cls
    UserControl.Print UserControl.name
End Sub

Private Sub InitilizeEnviornment()
    Dim poConvas As oConvas
    On Error Resume Next
    If (UserControl.Ambient.UserMode) Then
        Set poConvas = UserControl.Parent
        Set m_IXGraphics = poConvas
        Set m_oConvasPicBox = m_IXGraphics.GetoConvasPicBox
        Set poConvas = Nothing
    End If
End Sub
    
Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    
    Dim pIndex As Single
    Dim pStepKey As StepKey
    Dim pKey As String
    Dim pLinkedStepCount As Single
    Dim poConvas As oConvas
    Call InitilizeEnviornment
    m_LineGap = 250
    m_Zoom = 100
    Set poConvas = m_IXGraphics
    If poConvas Is Nothing Then
        m_ZoomFactor = 1
    Else
        m_ZoomFactor = poConvas.Zoom / 100
    End If
    
    m_Caption = PropBag.ReadProperty("Caption", "<Annotation>")
    m_CentreX = PropBag.ReadProperty("CentreX", m_def_CentreX)
    m_CentreY = PropBag.ReadProperty("CentreY", m_def_CentreY)
    Set m_Font = PropBag.ReadProperty("Font", UserControl.Font)
    m_DefFontSize = m_Font.Size
    m_ForeColor = PropBag.ReadProperty("ForeColor", UserControl.ForeColor)
    m_Selected = PropBag.ReadProperty("oSelected", False)
    m_IsConnection = PropBag.ReadProperty("IsConnection", False)
    m_PointPerSide = PropBag.ReadProperty("PointPerSide", 10)
    m_NodeKey = PropBag.ReadProperty("NodeKey", "")
    m_Visible = PropBag.ReadProperty("Visible", False)
    Set m_Picture = PropBag.ReadProperty("Image", Nothing)
    m_ToolTipText = PropBag.ReadProperty("ToolTipText", "")
    
    pLinkedStepCount = PropBag.ReadProperty("LSCount", 0)

    If pLinkedStepCount > 0 Then
        If m_LinkedStepKey Is Nothing Then Set m_LinkedStepKey = New StepKeys
        For pIndex = 1 To pLinkedStepCount
            pKey = PropBag.ReadProperty("LS" & pIndex, "")
            Set pStepKey = m_LinkedStepKey.Add(pKey)
        Next
    End If
    
End Sub

Private Sub UserControl_Resize()
    UserControl.Height = 500
    UserControl.Width = 500
End Sub

Private Sub UserControl_Terminate()
    Call BeforeTerminate
End Sub

Friend Sub BeforeTerminate()
    If m_Path <> 0 Then
        Call GdipDeletePath(m_Path)
        m_Path = 0
    End If
    
    If m_Region <> 0 Then
        Call GdipDeleteRegion(m_Region)
        m_Region = 0
    End If
    
    If m_PathBack <> 0 Then
        Call GdipDeletePath(m_PathBack)
        m_PathBack = 0
    End If
    
    If m_PathText <> 0 Then
        Call GdipDeletePath(m_PathText)
        m_PathText = 0
    End If
    
    If m_Image <> 0 Then
        Call GdipDisposeImage(m_Image)
        'Call GdipDeleteCachedBitmap(m_Image)
        m_Image = 0
    End If
    
    
    Set m_SidePoints(0) = Nothing
    Set m_SidePoints(1) = Nothing
    Set m_SidePoints(2) = Nothing
    Set m_SidePoints(3) = Nothing
    Set m_Picture = Nothing
    Set m_Font = Nothing
    Set m_IXGraphics = Nothing
    Set m_oConvasPicBox = Nothing
    Set m_LinkedStepKey = Nothing
 End Sub
 
'--------------------------Control Handling End---------------------------------
'--------------------------Standard Functions-----------------------------------
Public Sub GetCordinates(ByRef CenX As Double, ByRef CenY As Double, ByRef oWidth As Double, ByRef oHeight As Double, Optional ByVal ResetValues As Boolean)
    If ResetValues Then
        m_TempX = 0
        m_TempY = 0
        m_MouseX = 0
        m_MouseY = 0
    End If
    CenX = m_TempX + (m_CentreX - m_MouseX * 15)
    CenY = m_TempY + (m_CentreY - m_MouseY * 15)
    oWidth = m_Width * 15
    oHeight = m_Height * 15
End Sub

Private Sub VacantSide(ByVal pKey As String)
    Dim pSide As Single
    Dim pSidePoint As SidePoint
    Dim pSplitResults() As String
    pSplitResults = Split(pKey, "_")
    pSide = CSng(pSplitResults(0))
    On Error Resume Next
    Select Case pSide
        Case 0:
            Set pSidePoint = m_SidePoints(0).Item(pKey)
        Case 1:
            Set pSidePoint = m_SidePoints(1).Item(pKey)
        Case 2:
            Set pSidePoint = m_SidePoints(2).Item(pKey)
        Case 3:
            Set pSidePoint = m_SidePoints(3).Item(pKey)
    End Select
    
    If Not pSidePoint Is Nothing Then
        pSidePoint.AllocatedToKey = ""
        pSidePoint.IsVacant = True
    End If
    
End Sub


Friend Sub GetExactCordinates(ByVal pNodeKey As String, ByVal Side As Single, ByVal pLineWidth As Single, ByRef SideAllocatedKey As String, ByRef X As Double, ByRef Y As Double, Optional ByRef XAct As Double, Optional ByRef YAct As Double)
   Dim pSidePoint As SidePoint
   Dim pNearestX As Double
   Dim pNearestY As Double
   Dim pDistance As Double
   Dim pClosestKey As String
   Dim pUbound As Single
   Dim pIndex As Single
   Dim pCentreByIndex As Single
   
   On Error GoTo 0
   
   X = X * 15
   Y = Y * 15
   pLineWidth = pLineWidth + 5
   If SideAllocatedKey <> "" Then
        Call VacantSide(SideAllocatedKey)
   End If
    
    If m_SidePoints(0).Count < 2 Then
        Call CreateSidePoints(m_CentreX, m_CentreY)
    End If
    
    
    Select Case Side
        Case 1:
            pNearestX = X
            pNearestY = Y
            pDistance = 0
            pUbound = 0 'CInt(m_SidePoints(0).Count)
            pCentreByIndex = 10
            For Each pSidePoint In m_SidePoints(0)
                If pSidePoint.IsVacant Then
                    If pDistance = 0 Then
                        pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        pDistance = Abs(pNearestY - pSidePoint.Y)
                        pCentreByIndex = 0
                    Else
                        If pDistance > Abs(pNearestY - pSidePoint.Y) Or pCentreByIndex < pUbound Then
                            pDistance = Abs(pNearestY - pSidePoint.Y)
                            pCentreByIndex = Abs(pIndex - pUbound)
                            pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        End If
                    End If
                End If
            Next
            Set pSidePoint = m_SidePoints(0).Item(pClosestKey)
            XAct = pSidePoint.X + m_LineGap '/ 15
            YAct = pSidePoint.Y
        Case 2:
            pNearestX = X
            pNearestY = Y
            pDistance = 0
            pCentreByIndex = 10
            For Each pSidePoint In m_SidePoints(1)
                If pSidePoint.IsVacant Then
                    If pDistance = 0 Then
                        pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        pDistance = Abs(pNearestX - pSidePoint.X)
                        pCentreByIndex = 0
                    Else
                        If pDistance > Abs(pNearestX - pSidePoint.X) Or pCentreByIndex < pUbound Then
                            pDistance = Abs(pNearestX - pSidePoint.X)
                            pCentreByIndex = Abs(pIndex - pUbound)
                            pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        End If
                    End If
                End If
            Next
            Set pSidePoint = m_SidePoints(1).Item(pClosestKey)
            XAct = pSidePoint.X
            YAct = pSidePoint.Y + m_LineGap '/ 15
        Case 3:
            pNearestX = X
            pNearestY = Y
            pDistance = 0
            pCentreByIndex = 0
            For Each pSidePoint In m_SidePoints(2)
                If pSidePoint.IsVacant Then
                    If pDistance = 0 Then
                        pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        pDistance = Abs(pNearestY - pSidePoint.Y)
                        pCentreByIndex = 0
                    Else
                        If pDistance > Abs(pNearestY - pSidePoint.Y) Or pCentreByIndex < pUbound Then
                            pDistance = Abs(pNearestY - pSidePoint.Y)
                            pCentreByIndex = Abs(pIndex - pUbound)
                            pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        End If
                    End If
                End If
            Next
            If pClosestKey <> "" Then
                Set pSidePoint = m_SidePoints(2).Item(pClosestKey)
                XAct = pSidePoint.X - m_LineGap '/ 15
                YAct = pSidePoint.Y
            End If
        Case 4:
            pNearestX = X
            pNearestY = Y
            pDistance = 0
            pCentreByIndex = 0
            For Each pSidePoint In m_SidePoints(3)
                If pSidePoint.IsVacant Then
                    If pDistance = 0 Then
                        pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        pDistance = Abs(pNearestX - pSidePoint.X)
                        pCentreByIndex = 0
                    Else
                        If pDistance > Abs(pNearestX - pSidePoint.X) Or pCentreByIndex < pUbound Then
                            pDistance = Abs(pNearestX - pSidePoint.X)
                            pCentreByIndex = Abs(pIndex - pUbound)
                            pClosestKey = pSidePoint.SideIndex & "_" & pSidePoint.CellNo
                        End If
                    End If
                End If
            Next
            Set pSidePoint = m_SidePoints(3).Item(pClosestKey)
            XAct = pSidePoint.X
            YAct = pSidePoint.Y - m_LineGap '/ 15
    End Select
    If Not pSidePoint Is Nothing Then
        X = pSidePoint.X
        Y = pSidePoint.Y
        pSidePoint.AllocatedToKey = pNodeKey
        pSidePoint.IsVacant = False
    End If
    XAct = Round(XAct)
    YAct = Round(YAct)
    X = Round(X)
    Y = Round(Y)
    SideAllocatedKey = pClosestKey
    'Debug.Print " Side :" & Side
    'Debug.Print " Key : ", pClosestKey
End Sub

Public Property Get Caption() As String
    Caption = m_Caption
End Property

Public Property Let Caption(ByVal New_Caption As String)
    m_Caption = New_Caption
    PropertyChanged "Caption"
    Call CreatePath
    Me.Paint
End Property

Public Property Get PointPerSide() As Long
    PointPerSide = m_PointPerSide
End Property

Public Property Let PointPerSide(ByVal New_PointPerSide As Long)
    m_PointPerSide = New_PointPerSide
    PropertyChanged "PointPerSide"
End Property

Public Property Get CentreX() As Double
    CentreX = m_CentreX
End Property

Public Property Let CentreX(ByVal New_CentreX As Double)
    m_CentreX = New_CentreX
    Call CreatePath
    Call CreateRegion
    PropertyChanged "CentreX"
End Property

Public Property Get CentreY() As Double
    CentreY = m_CentreY
End Property

Public Property Let CentreY(ByVal New_CentreY As Double)
    m_CentreY = New_CentreY
    Call CreatePath
    Call CreateRegion
    PropertyChanged "CentreY"
End Property

Public Property Get Font() As Font
    Set Font = m_Font
End Property

Public Property Set Font(ByVal New_Font As Font)
    Set m_Font = New_Font
    PropertyChanged "Font"
End Property

Public Property Get ForeColor() As OLE_COLOR
    ForeColor = m_ForeColor
End Property

Public Property Let ForeColor(ByVal New_ForeColor As OLE_COLOR)
    m_ForeColor = New_ForeColor
    PropertyChanged "ForeColor"
End Property

Public Property Get Image() As StdPicture
    Set Image = m_Picture
End Property

Public Property Set Image(ByVal New_Image As StdPicture)
    Dim pRect As RECTF
    On Error GoTo 0
    'CreateBitmapPicture(
    Set m_Picture = New_Image
    If Not m_Picture Is Nothing Then
        Call CreateImage
        Call CreatePath
        Call CreateRegion
    End If
    PropertyChanged "Image"
End Property

Private Sub CreateImage()
    Dim pRect As RECTF
    Dim pName As String
    Dim pImage As Long
    Dim poConvas As oConvas
    Dim pBuffer As PictureBox
    Dim pX As Double
    Dim pY As Double
    Set poConvas = UserControl.Parent
    Set pBuffer = poConvas.PictureBuffer
    Set pBuffer.Picture = m_Picture
    Call GdipCreateBitmapFromHBITMAP(pBuffer.Image.handle, pBuffer.Image.hPal, m_Image)
    Call GdipGetImageBounds(m_Image, pRect, UnitPixel)
    LSet m_ImageRect = pRect
    With m_ImageRect
        m_Height = .Height
        m_Width = .Width
    End With
    m_ZoomFactor = poConvas.Zoom / 100
    pX = m_CentreX
    pY = m_CentreY
    m_Font.Size = 9.75
    Call ScaleRegion(m_ZoomFactor)
    Me.CentreX = pX
    Me.CentreY = pY
    Call CreateSidePoints(m_CentreX, m_CentreY)
End Sub

Private Sub CreateSidePoints(ByVal pCentX As Double, ByVal pCentY As Double)
    Dim pRect As RECTF
    Dim pSidePoint As SidePoint
    Dim ptSidePoint As SidePoint
    Dim pIndex As Single
    Dim pPointWidth As Single
    Dim pTempSideCol(3) As Collection
    Dim pPtHDiff As Single
    Dim pPtWDiff As Single
    On Error Resume Next
    If Not m_SidePoints(0) Is Nothing Then
        Set pTempSideCol(0) = m_SidePoints(0)
        Set m_SidePoints(0) = Nothing
        Set pTempSideCol(1) = m_SidePoints(1)
        Set m_SidePoints(1) = Nothing
        Set pTempSideCol(2) = m_SidePoints(2)
        Set m_SidePoints(2) = Nothing
        Set pTempSideCol(3) = m_SidePoints(3)
        Set m_SidePoints(3) = Nothing
    End If
    Set m_SidePoints(0) = New Collection
    Set m_SidePoints(1) = New Collection
    Set m_SidePoints(2) = New Collection
    Set m_SidePoints(3) = New Collection
    
    With pRect
        .Left = (pCentX / 15 - (m_Width) / 2) * 15
        .Top = (pCentY / 15 - (m_Height) / 2) * 15
        .Height = m_Height * 15
        .Width = m_Width * 15
    End With
    m_PointPerSide = m_Height * 2
    pPtHDiff = (m_Height * 15) / m_PointPerSide
    pPtWDiff = (m_Width * 15) / m_PointPerSide
    
    Call InflateRectF(pRect, m_LineGap, m_LineGap)
    For pIndex = 1 To m_PointPerSide
        Set pSidePoint = New SidePoint
        With pSidePoint
            .CellNo = pIndex
            .SideIndex = 0
            .IsVacant = True
            .X = pRect.Left
            .Y = pRect.Top + pIndex * pPtHDiff + m_LineGap
        End With
        m_SidePoints(0).Add pSidePoint, "0_" & pIndex
        Set pSidePoint = Nothing
        Set pSidePoint = New SidePoint
        With pSidePoint
            .CellNo = pIndex
            .SideIndex = 2
            .IsVacant = True
            .X = pRect.Left + pRect.Width
            .Y = pRect.Top + pIndex * pPtHDiff + m_LineGap
        End With
        m_SidePoints(2).Add pSidePoint, "2_" & pIndex
        Set pSidePoint = Nothing
    Next
        
    For pIndex = 1 To m_PointPerSide
        Set pSidePoint = New SidePoint
        With pSidePoint
            .CellNo = pIndex
            .SideIndex = 1
            .IsVacant = True
            .X = pRect.Left + pIndex * pPtWDiff + m_LineGap
            .Y = pRect.Top
        End With
        m_SidePoints(1).Add pSidePoint, "1_" & pIndex
        Set pSidePoint = Nothing
        
        Set pSidePoint = New SidePoint
        With pSidePoint
            .CellNo = pIndex
            .SideIndex = 3
            .IsVacant = True
            .X = pRect.Left + pIndex * pPtWDiff + m_LineGap
            .Y = pRect.Top + pRect.Height
        End With
        m_SidePoints(3).Add pSidePoint, "3_" & pIndex
        Set pSidePoint = Nothing
    Next
    
    pIndex = 1
    If Not pTempSideCol(0) Is Nothing Then
        For Each pSidePoint In pTempSideCol(0)
            Set ptSidePoint = m_SidePoints(0).Item(pIndex)
            If pSidePoint.AllocatedToKey <> "" Then
                ptSidePoint.AllocatedToKey = pSidePoint.AllocatedToKey
                ptSidePoint.IsVacant = pSidePoint.IsVacant
              
            End If
    
            pIndex = pIndex + 1
        Next
    End If
    
    pIndex = 1
    If Not pTempSideCol(1) Is Nothing Then
        For Each pSidePoint In pTempSideCol(1)
            Set ptSidePoint = m_SidePoints(1).Item(pIndex)
            If pSidePoint.AllocatedToKey <> "" Then
                ptSidePoint.AllocatedToKey = pSidePoint.AllocatedToKey
                ptSidePoint.IsVacant = pSidePoint.IsVacant
                
            End If
    
            pIndex = pIndex + 1
        Next
    End If
    pIndex = 1
    If Not pTempSideCol(2) Is Nothing Then
        For Each pSidePoint In pTempSideCol(2)
            Set ptSidePoint = m_SidePoints(2).Item(pIndex)
            If pSidePoint.AllocatedToKey <> "" Then
                ptSidePoint.AllocatedToKey = pSidePoint.AllocatedToKey
                ptSidePoint.IsVacant = pSidePoint.IsVacant
                
            End If
    
            pIndex = pIndex + 1
        Next
    End If
    pIndex = 1
    If Not pTempSideCol(3) Is Nothing Then
        For Each pSidePoint In pTempSideCol(3)
            Set ptSidePoint = m_SidePoints(3).Item(pIndex)
            If pSidePoint.AllocatedToKey <> "" Then
                ptSidePoint.AllocatedToKey = pSidePoint.AllocatedToKey
                ptSidePoint.IsVacant = pSidePoint.IsVacant
            End If
    
            pIndex = pIndex + 1
        Next
    End If
End Sub

Private Sub CreatePath()
    Dim pRect As RECTF
    Dim rct As RECTF
    Dim fontFam          As Long
    Dim curFont          As Long
    Dim strFormat        As Long
    Dim box              As RECTF
    Dim rct2             As RECTF
    Dim FS               As Long
    Dim IsAvailable      As Long
   
    'Call GdipGetImageBounds(m_Image, pRect, UnitPixel)
    LSet pRect = m_ImageRect
    m_Height = pRect.Height
    m_Width = pRect.Width
    If m_Path <> 0 Then
        GdipDeletePath (m_Path)
    End If
    
    If m_PathText <> 0 Then
        GdipDeletePath (m_PathText)
    End If
    
    If m_PathBack <> 0 Then
        GdipDeletePath (m_PathBack)
    End If
    
    Call GdipCreatePath(FillModeWinding, m_PathBack)
    Call GdipCreatePath(FillModeWinding, m_PathText)
    Call GdipCreatePath(FillModeWinding, m_Path)
    
    'Text stuff follows

   ' Set the Text Rendering Quality
   
   ' Create a font family object to allow us to create a font
   ' We have no font collection here, so pass a NULL for that parameter
    If m_Font Is Nothing Then
        Call InitilizeEnviornment
        Set m_Font = UserControl.Font
   End If
   GdipCreateFontFamilyFromName m_Font.name, 0, fontFam
   GdipIsStyleAvailable fontFam, FS, IsAvailable
   If IsAvailable = 0 Then
      Dim Msg              As String
      Msg = "Font family " & m_Font.name & " NOT available under GDI+.Please select another font."
      Me.Font = Ambient.Font
      MsgBox Msg
      Exit Sub
   End If
   ' Create the font from the specified font family name
   ' >> Note that we have changed the drawing Unit from pixels to points!!
   FS = FontStyleRegular 'not really needed since it's zero
   If m_Font.Bold Then FS = FS + FontStyleBold
   If m_Font.Italic Then FS = FS + FontStyleItalic
   If m_Font.Strikethrough Then FS = FS + FontStyleStrikeout
   If m_Font.Underline Then FS = FS + FontStyleUnderline
    
   GdipCreateFont fontFam, m_Font.Size, FS, UnitPoint, curFont
   ' Create the StringFormat object
   ' We can pass NULL for the flags and language id if we want
   GdipCreateStringFormat 0, 0, strFormat

   ' Justify each line of text
   GdipSetStringFormatAlign strFormat, StringAlignmentCenter

   ' Justify the block of text (top to bottom) in the rectangle.
   GdipSetStringFormatLineAlign strFormat, StringAlignmentCenter
    
   GdipMeasureString m_IXGraphics.GetoGraphicsHandle, m_Caption, -1, curFont, _
   rct, strFormat, pRect, 0, 0
   LSet rct = pRect
   rct.Width = rct.Width - rct.Width / 5
   
   rct.Top = m_CentreY / 15 + m_Height / 2 + 15
   rct.Left = m_CentreX / 15 - rct.Width / 2
   
   GdipAddPathString m_PathText, _
      m_Caption, -1, _
      fontFam, _
      FS, _
      m_Font.Size, _
      rct, _
      strFormat
   Call GdipAddPathRectangle(m_PathBack, rct.Left, rct.Top, rct.Width, rct.Height)
   
   With pRect
        .Height = m_Height
        .Width = m_Width
        .Top = m_CentreY / 15 - .Height / 2
        .Left = m_CentreX / 15 - .Width / 2
   End With
   Call GdipAddPathRectangle(m_Path, pRect.Left, pRect.Top, pRect.Width, pRect.Height)
   LSet m_TextRect = pRect
   GdipDeleteStringFormat strFormat
   GdipDeleteFont curFont
   GdipDeleteFontFamily fontFam
   
End Sub

Private Sub CreateRegion()
    Dim pRect As RECTF
    If m_Region <> 0 Then
        GdipDeleteRegion m_Region
        m_Region = 0
    End If
    
    With pRect
        .Height = m_Height
        .Width = m_Width
        .Top = m_CentreY / 15 - .Height / 2
        .Left = m_CentreX / 15 - .Width / 2
    End With
    Call GdipCreateRegionRect(pRect, m_Region)
End Sub
'Write property values to storage
Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    Dim pStepKey As StepKey
    Dim pIndex As Single

    Call PropBag.WriteProperty("Caption", m_Caption, "<Annotation>")
    Call PropBag.WriteProperty("CentreX", m_CentreX, m_def_CentreX)
    Call PropBag.WriteProperty("CentreY", m_CentreY, m_def_CentreY)
    Call PropBag.WriteProperty("Font", m_Font, UserControl.Font)
    Call PropBag.WriteProperty("ForeColor", m_ForeColor, UserControl.ForeColor)
    Call PropBag.WriteProperty("Image", m_Picture, Nothing)
    Call PropBag.WriteProperty("PointPerSide", m_PointPerSide, 10)
    Call PropBag.WriteProperty("NodeKey", m_NodeKey, "")
    Call PropBag.WriteProperty("ToolTipText", m_ToolTipText, "")
    Call PropBag.WriteProperty("Visible", m_Visible, False)
    Call PropBag.WriteProperty("oSelected", m_Selected, False)
    Call PropBag.WriteProperty("IsConnection", m_IsConnection, False)
    If m_LinkedStepKey Is Nothing Then
        Call PropBag.WriteProperty("LSCount", 0, Nothing)
    Else
        Call PropBag.WriteProperty("LSCount", m_LinkedStepKey.Count, Nothing)
        For pIndex = 1 To m_LinkedStepKey.Count
            Set pStepKey = m_LinkedStepKey.Item(pIndex)
            Call PropBag.WriteProperty("LS" & pIndex, pStepKey.Key, Nothing)
        Next
    End If
    'Save Side Points
    'Save LinkedStepInfo
End Sub

Public Property Get IsConnection() As Boolean
    IsConnection = m_IsConnection
End Property

Public Property Let IsConnection(ByVal pValue As Boolean)
    m_IsConnection = pValue
    PropertyChanged "IsConnection"
End Property


Public Sub ScaleRegion(ByVal ZoomFactor As Double)
    m_ZoomFactor = ZoomFactor
    m_CentreX = m_CentreX * ZoomFactor
    m_CentreY = m_CentreY * ZoomFactor
    m_Width = m_Width * ZoomFactor
    m_Height = m_Height * ZoomFactor
    m_ImageRect.Top = m_ImageRect.Top * ZoomFactor
    m_ImageRect.Height = m_ImageRect.Height * ZoomFactor
    m_ImageRect.Left = m_ImageRect.Left * ZoomFactor
    m_ImageRect.Width = m_ImageRect.Width * ZoomFactor
    
    m_Font.Size = m_Font.Size * ZoomFactor
    m_LineGap = m_LineGap * ZoomFactor
    Call CreatePath
    Call CreateRegion
    RaiseEvent MaxExtend((m_TextRect.Left + m_TextRect.Width) * 15, (m_TextRect.Top + m_TextRect.Height) * 15)
End Sub
