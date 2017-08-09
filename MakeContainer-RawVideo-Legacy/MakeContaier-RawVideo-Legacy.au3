#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Turn a VeraCrypt container into a yuv
#AutoIt3Wrapper_Res_Description=Turn a VeraCrypt container into a yuv
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <WinAPI.au3>

Global $FmtStruct[2]
$FmtStruct[0] = "rgba"
$FmtStruct[1] = "yuva444p"

$File = FileOpenDialog("Select binary file with the encrypted bytes",@ScriptDir,"All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $File & @CRLF)
$hInput = _winapi_createfile("\\.\" & $File, 2, 2, 6)
If Not $hInput Then
	ConsoleWrite("Error opening file" & @CRLF)
	Exit
EndIf
$FileSize = _winapi_getfilesizeex($hInput)
ConsoleWrite("$FileSize: " & $FileSize & @CRLF)

$InputFrameFormat = InputBox("Set the frame format for video", "Pixel format:", "320x240")
If @error Or $InputFrameFormat="" Then Exit
$Fmt = StringSplit($InputFrameFormat,"x")
If IsArray($Fmt)=0 Then
	ConsoleWrite("Error1: Wrong format. Must be IntXInt." & @CRLF)
	Exit
EndIf
If $Fmt[0] <> 2 Then
	ConsoleWrite("Error2: Wrong format. Must be IntXInt." & @CRLF)
	Exit
EndIf
If StringIsDigit($Fmt[1])=0 Or StringIsDigit($Fmt[2])=0 Then
	ConsoleWrite("Error3: Wrong format. Must be IntXInt." & @CRLF)
	Exit
EndIf
$FmtX = $Fmt[1]
$FmtY = $Fmt[2]

;Create output
$RandCheck = Random(0,1,1)
$OutputName = $File & "_" & $InputFrameFormat & "_" & $FmtStruct[$RandCheck] & ".yuv"
If FileExists($OutputName) Then
	MsgBox(0,"Error","Output filename already existed: " & $OutputName)
	Exit
EndIf

$hOutput = _winapi_createfile("\\.\" & $OutputName, 3, 6, 6)
If Not $hOutput Then
	ConsoleWrite("Error opening file" & @CRLF)
	Exit
EndIf

;Do some calculations
$FrameSize = $FmtX * $FmtY * 4
$MinimumFrames = Floor($FileSize / $FrameSize)
$AdjustedFrameNumber = $MinimumFrames + 1
$AppendBytes = ($AdjustedFrameNumber * $FrameSize) - $FileSize
ConsoleWrite("$FrameSize: " & $FrameSize & @CRLF)
ConsoleWrite("Output filename: " & $OutputName & @CRLF)
ConsoleWrite("Adjusted filesize: " & $FileSize+$AppendBytes & @CRLF)

If $AdjustedFrameNumber >= 10 Then
	$BigBuff = $FrameSize * 10
Else
	$BigBuff = $FrameSize
EndIf
$pBigBuff = DllStructCreate("byte["&$BigBuff&"]")
$MaxRuns = Floor($FileSize / $BigBuff)
$Remainder = $FileSize - ($MaxRuns * $BigBuff)
$nBytes=0
For $i = 0 To $MaxRuns
	If $i = $MaxRuns Then
		$pBigBuff=0
		$pBigBuff = DllStructCreate("byte["&$Remainder&"]")
		$BigBuff=$Remainder
	EndIf
	ConsoleWrite("Writing " & $BigBuff & " bytes" & @CRLF)
	If Not _winapi_readfile($hInput, DllStructGetPtr($pBigBuff), $BigBuff, $nbytes) Then
		ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Exit
	EndIf
	If Not _winapi_writefile($hOutput, DllStructGetPtr($pBigBuff), $BigBuff, $nbytes) Then
		ConsoleWrite("Error in WriteFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Exit
	EndIf
Next
$pBigBuff=0

$fillbytes="0x"
For $i = 1 To $AppendBytes
	$fillbytes &= Hex(Random(0, 255, 1), 2)
;	$fillbytes &= "00"
Next
$pBigBuff = DllStructCreate("byte["&$AppendBytes&"]")
DllStructSetData($pBigBuff,1,$fillbytes)
;_winapi_setfilepointer($hOutput, $FileSize)
If Not _winapi_writefile($hOutput, DllStructGetPtr($pBigBuff), $AppendBytes, $nbytes) Then
	ConsoleWrite("Error in WriteFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf

_WinAPI_CloseHandle($hInput)
_WinAPI_CloseHandle($hOutput)

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc
