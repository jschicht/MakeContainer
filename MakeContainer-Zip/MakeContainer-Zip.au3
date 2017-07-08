#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container inside
#AutoIt3Wrapper_Res_Description=Injects data in between 2 concatenated files
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#EndRegion

#include <WinAPI.au3>

Dim $nbytes
ConsoleWrite("MakeContainer-Zip v1.0.0.2 - by Joakim Schicht")
$file = FileOpenDialog("Select ZIP container", @ScriptDir, "All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $file & @CRLF)
$filename = _getfilename($file)
If @error Then
	MsgBox(0, "Error", "Could not resolve file name")
	Exit
EndIf
ConsoleWrite("FileName: " & $filename & @CRLF)
$fileextension = _getfileextension($file)
If @error Then
	MsgBox(0, "Error", "Could not resolve file extension")
	Exit
EndIf
ConsoleWrite("$FileExtension: " & $fileextension & @CRLF)
$rand = Hex(Random(0, 65535, 1), 4)
$hfilecontainer = _winapi_createfile("\\.\" & $file, 2, 6, 7)
If NOT $hfilecontainer Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$filesize = FileGetSize($file)
ConsoleWrite("$FileSize: " & $filesize & @CRLF)
$filesizemod = $filesize
$fillcounter = 0
$fillbytes = ""
If Mod($filesizemod, 512) Then
	Do
		$fillcounter += 1
		$filesizemod += 1
		$fillbytes &= Hex(Random(0, 255, 1), 2)
	Until Mod($filesizemod, 512) = 0
EndIf
ConsoleWrite("$FillCounter: " & $fillcounter & @CRLF)
ConsoleWrite("$FileSizeMod: " & $filesizemod & @CRLF)
$file2 = FileOpenDialog("Select payload", @ScriptDir, "All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $file2 & @CRLF)
$filesize2 = FileGetSize($file2)
$newoutputname = $file & "." & $rand & "." & $fileextension
$hfileoutput = _winapi_createfile("\\.\" & $newoutputname, 1, 6, 2)
If NOT $hfileoutput Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize + $fillcounter + $filesize2 + $filesize)
_winapi_setendoffile($hfileoutput)
_winapi_flushfilebuffers($hfileoutput)
$bufferwholefilecontainer = DllStructCreate("byte[" & $filesize & "]")
_winapi_setfilepointer($hfilecontainer, 0)
$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($bufferwholefilecontainer), DllStructGetSize($bufferwholefilecontainer), $nbytes)
If $read = 0 Then
	MsgBox(0, "Error", "ReadFile failed")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, 0)
$write = _winapi_writefile($hfileoutput, DllStructGetPtr($bufferwholefilecontainer), DllStructGetSize($bufferwholefilecontainer), $nbytes)
If $write = 0 Then
	MsgBox(0, "Error", "WriteFile failed")
	Exit
EndIf
$bufferpadding = DllStructCreate("byte[" & $fillcounter & "]")
DllStructSetData($bufferpadding, 1, "0x" & $fillbytes)
$bufferwholefilepayload = DllStructCreate("byte[" & $filesize2 & "]")
$hfilepayload = _winapi_createfile("\\.\" & $file2, 2, 2, 2)
If NOT $hfilepayload Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$readpayload = _winapi_readfile($hfilepayload, DllStructGetPtr($bufferwholefilepayload), DllStructGetSize($bufferwholefilepayload), $nbytes)
If $readpayload = 0 Then
	MsgBox(0, "Error", "ReadFile failed")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize)
$write = _winapi_writefile($hfileoutput, DllStructGetPtr($bufferpadding), DllStructGetSize($bufferpadding), $nbytes)
If $write = 0 Then
	MsgBox(0, "Error", "WriteFile failed")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize + $fillcounter)
$write = _winapi_writefile($hfileoutput, DllStructGetPtr($bufferwholefilepayload), DllStructGetSize($bufferwholefilepayload), $nbytes)
If $write = 0 Then
	MsgBox(0, "Error", "WriteFile failed")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize + $fillcounter + $filesize2)
$write = _winapi_writefile($hfileoutput, DllStructGetPtr($bufferwholefilecontainer), DllStructGetSize($bufferwholefilecontainer), $nbytes)
If $write = 0 Then
	MsgBox(0, "Error", "WriteFile failed")
	Exit
EndIf
_winapi_closehandle($hfilepayload)
_winapi_closehandle($hfileoutput)
_winapi_closehandle($hfilecontainer)
$batchfilename = $newoutputname & ".bat"
$hbatchfile = FileOpen($batchfilename, 2)
If NOT $hbatchfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$samplecmdline = "VeraCrypt.exe /v " & '"' & $newoutputname & '"' & " /l x /a /p password /i " & $filesize + $fillcounter
FileWriteLine($hbatchfile, $samplecmdline)
FileClose($hbatchfile)
MsgBox(0, "Finished", "Job done")
Exit

Func _swapendian($ihex)
	Return StringMid(Binary(Dec($ihex, 2)), 3, StringLen($ihex))
EndFunc

Func _getfileextension($input)
	$pos = StringInStr($input, ".", 0, -1)
	$resolvedfileextension = StringMid($input, $pos + 1)
	If $resolvedfileextension = "" Then
		Return SetError(1, 0, 0)
	Else
		Return $resolvedfileextension
	EndIf
EndFunc

Func _getfilename($input)
	$pos = StringInStr($input, "\", 0, -1)
	$resolvedfilename = StringMid($input, $pos + 1)
	If $resolvedfilename = "" Then
		Return SetError(1, 0, 0)
	Else
		Return $resolvedfilename
	EndIf
EndFunc
