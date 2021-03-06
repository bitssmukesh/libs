VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 1  'Persistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "StopWatch"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'    CopyRight (c) 2005 Kelly Ethridge
'
'    This file is part of VBCorLib.
'
'    VBCorLib is free software; you can redistribute it and/or modify
'    it under the terms of the GNU Library General Public License as published by
'    the Free Software Foundation; either version 2.1 of the License, or
'    (at your option) any later version.
'
'    VBCorLib is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Library General Public License for more details.
'
'    You should have received a copy of the GNU Library General Public License
'    along with Foobar; if not, write to the Free Software
'    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
'
'    Module: StopWatch
'

''
' Provides a timing mechanism using QueryPerformanceCounter if available, otherwise
' the system time is used.
'
' @see StopWatchStatic
'
Option Explicit
Implements IObject

Private mStartCount     As Currency
Private mIsRunning      As Boolean
Private mElapsedTime    As Currency

' We cache these values local to help cut down on the
' the number of function calls to the StopWatchStatic
' variable to provide as much accuracy as possible.
Private mFreqMultiplier As Currency
Private mIsHighRes      As Boolean


''
' Starts the StopWatch object.
'
' @remarks If StartCount is called again, the elapsed time is not reset.
' The elapsed time is increased as normal, but does not reflect the time
' spent while the StopWatch was not running.
' <p>Using the StartCount and StopCount allows for timing of only portions that
' are prefered and accumulates only those portions. The elapsed time properties
' will reflect the sum total of those timed portions. Calling Reset will set
' the elapsed time to zero.</p>
' <p>If the StopWatch is already running, then nothing is changed.</p>
'
Public Sub StartCount()
    If Not mIsRunning Then
        mIsRunning = True
        mStartCount = StopWatch.InternalGetTimeStamp
    End If
End Sub

''
' Halts the StopWatch if it is running, storing the elapsed time so far.
'
' @remarks If StartCount is called again, the elapsed time is not reset.
' The elapsed time is increased as normal, but does not reflect the time
' spent while the StopWatch was not running.
' <p>Using the StartCount and StopCount allows for timing of only portions that
' are prefered and accumulates only those portions. The elapsed time properties
' will reflect the sum total of those timed portions. Calling Reset will set
' the elapsed time to zero.</p>
'
Public Sub StopCount()
    If mIsRunning Then
        mElapsedTime = mElapsedTime + (StopWatch.InternalGetTimeStamp - mStartCount)
        mIsRunning = False
    End If
End Sub

''
' Returns if the StopWatch is currently running.
'
Public Property Get IsRunning() As Boolean
    IsRunning = mIsRunning
End Property

''
' Stops the StopWatch object and resets the elapsed time to zero.
'
Public Sub Reset()
    mElapsedTime = 0@
    mStartCount = 0@
    mIsRunning = False
End Sub

''
' Returns the elapsed time as a TimeSpan object.
'
' @return A TimeSpan object.
' @remarks The elapsed time reflects the sum total of all durations timed when calling
' the StartCount and StopCount. Each time the StopWatch is started, the elapsed time
' will accumulate, but it will not reset to zero when the StopWatch is stopped. Calling
' the Reset method will stop the StopWatch and reset the elapsed time to zero.
' <p>If the StopWatch is running when the elapsed time is checked, the current accumulated
' amount of time will be returned. The StopWatch will not be stopped.</p>
'
Public Property Get Elapsed() As TimeSpan
    Set Elapsed = TimeSpan.FromTicks(Me.ElapsedTicks)
End Property

''
' Returns the time elapsed in milliseconds.
'
' @return The time elapsed in milliseconds.
' @remarks The elapsed time reflects the sum total of all durations timed when calling
' the StartCount and StopCount. Each time the StopWatch is started, the elapsed time
' will accumulate, but it will not reset to zero when the StopWatch is stopped. Calling
' the Reset method will stop the StopWatch and reset the elapsed time to zero.
' <p>If the StopWatch is running when the elapsed time is checked, the current accumulated
' amount of time will be returned. The StopWatch will not be stopped.</p>
'
Public Property Get ElapsedMilliseconds() As Currency
    ElapsedMilliseconds = Int(GetElapsedTime)
End Property

''
' Returns the elapsed time in Ticks.
'
' @return The elapsed Ticks is returned.
' @remarks The elapsed time reflects the sum total of all durations timed when calling
' the StartCount and StopCount. Each time the StopWatch is started, the elapsed time
' will accumulate, but it will not reset to zero when the StopWatch is stopped. Calling
' the Reset method will stop the StopWatch and reset the elapsed time to zero.
' <p>If the StopWatch is running when the elapsed time is checked, the current accumulated
' amount of time will be returned. The StopWatch will not be stopped.</p>
'
Public Property Get ElapsedTicks() As Variant
    ElapsedTicks = CDec(GetElapsedTime) * 10000&
End Property

''
' Returns a string representation of this object.
'
' @return A string representation.
'
Public Function ToString() As String
    ToString = Object.ToString(Me, App)
End Function

''
' This function determines if the value passed in is the same
' as the current object instance. Meaning, are the Value and
' this object the same object in memory.
'
' @param Value The value to test for equality against this object instance.
' @return The result of the equality comparison.
'
Public Function Equals(ByRef Value As Variant) As Boolean
    Equals = Object.Equals(Me, Value)
End Function

''
' Returns a psuedo-unique number used to help identify this
' object in memory. The current method is to return the value
' obtained from ObjPtr.
'
' @return The hashcode for this object instance.
'
Public Function GetHashCode() As Long
    GetHashCode = ObjPtr(CUnk(Me))
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function GetElapsedTime() As Currency
    Dim Ret As Currency
    Ret = mElapsedTime
    
    If mIsRunning Then Ret = Ret + (StopWatch.InternalGetTimeStamp - mStartCount)
    If mIsHighRes Then Ret = Ret * mFreqMultiplier
    
    GetElapsedTime = Ret
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_Initialize()
    If StopWatch.IsHighResolution Then
        mFreqMultiplier = 1000@ / StopWatch.Frequency
        mIsHighRes = True
    End If
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   IObject Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function IObject_Equals(Value As Variant) As Boolean
    IObject_Equals = Equals(Value)
End Function

Private Function IObject_GetHashcode() As Long
    IObject_GetHashcode = GetHashCode
End Function

Private Function IObject_ToString() As String
    IObject_ToString = ToString
End Function
