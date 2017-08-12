#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Turn a VeraCrypt container into a wav
#AutoIt3Wrapper_Res_Description=Turn a VeraCrypt container into a wav
#AutoIt3Wrapper_Res_Fileversion=1.0.0.1
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <WinAPI.au3>

$tagWAV1 = "char groupId[4];long TotalSize;char riffType[4]"
$tagFormatChunk = "char chunkId[3];byte space[1];long chunkSize;short wFormatTag;ushort wChannels;ulong dwSamplesPerSec;ulong dwAvgBytesPerSec;ushort wBlockAlign;ushort wBitsPerSample"
$tagDataChunk = "char chunkId[4];long chunkSize"

$File = FileOpenDialog("Select binary file with pixel bytes",@ScriptDir,"All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $File & @CRLF)
$hInput = _winapi_createfile("\\.\" & $File, 2, 2, 6)
If Not $hInput Then
	ConsoleWrite("Error opening file" & @CRLF)
	Exit
EndIf
$FileSize = _winapi_getfilesizeex($hInput)
If FileExists($File & ".wav") Then
	FileDelete($File & ".wav")
EndIf

$wChannels = InputBox("Set wChannels", "The number of channels in the audio", "1")
If @error Or $wChannels="" Then Exit
If Not StringIsDigit($wChannels) Then
	ConsoleWrite("Error setting channels" & @CRLF)
	Exit
EndIf

$hOutput = _winapi_createfile("\\.\" & $File & ".wav", 3, 6, 6)
If Not $hOutput Then
	ConsoleWrite("Error opening file" & @CRLF)
	Exit
EndIf

$BigBuff = 409600
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

$pWAV1 = DllStructCreate($tagWAV1)
ConsoleWrite("$tagWAV1: " & @error & @CRLF)
DllStructSetData($pWAV1, "groupId", "RIFF")
DllStructSetData($pWAV1, "TotalSize", $FileSize-8)
DllStructSetData($pWAV1, "riffType", "WAVE")
_winapi_setfilepointer($hOutput, 0)
If Not _winapi_writefile($hOutput, $pWAV1, DllStructGetSize($pWAV1), $nbytes) Then
	ConsoleWrite("Error in WriteFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf

$dwSamplesPerSec = 44100
$wBitsPerSample = 32
;$wChannels = 1
$wBlockAlign = $wChannels*($wBitsPerSample/8)
$dwAvgBytesPerSeculong = $wBlockAlign * $dwSamplesPerSec
$pFormatChunk = DllStructCreate($tagFormatChunk)
ConsoleWrite("$tagFormatChunk: " & @error & @CRLF)
DllStructSetData($pFormatChunk, "chunkId", "fmt")
DllStructSetData($pFormatChunk, "space", 0x20)
DllStructSetData($pFormatChunk, "chunkSize", 0x10)
DllStructSetData($pFormatChunk, "wFormatTag", 0x1)
DllStructSetData($pFormatChunk, "wChannels", $wChannels) ;1,2,3,4
DllStructSetData($pFormatChunk, "dwSamplesPerSec", $dwSamplesPerSec) ;11025,22050,44100,
DllStructSetData($pFormatChunk, "dwAvgBytesPerSeculong", $dwAvgBytesPerSeculong)
DllStructSetData($pFormatChunk, "wBlockAlign", $wBlockAlign)
DllStructSetData($pFormatChunk, "wBitsPerSample", $wBitsPerSample)
;_winapi_setfilepointer($hOutput, DllStructGetSize($pWAV1))
If Not _winapi_writefile($hOutput, DllStructGetPtr($pFormatChunk), DllStructGetSize($pFormatChunk), $nbytes) Then
	ConsoleWrite("Error in WriteFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf

$pDataChunk = DllStructCreate($tagDataChunk)
ConsoleWrite("$tagDataChunk: " & @error & @CRLF)
DllStructSetData($pDataChunk, "chunkId", "data")
DllStructSetData($pDataChunk, "chunkSize", $FileSize-0x2C)
_winapi_setfilepointer($hOutput, DllStructGetSize($pWAV1)+DllStructGetSize($pFormatChunk))
If Not _winapi_writefile($hOutput, DllStructGetPtr($pDataChunk), DllStructGetSize($pDataChunk), $nbytes) Then
	ConsoleWrite("Error in WriteFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf

_WinAPI_CloseHandle($hInput)
_WinAPI_CloseHandle($hOutput)

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc
