#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container in any file at EOF
#AutoIt3Wrapper_Res_Description=Will hide VeraCrypt container in any file at EOF
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#EndRegion

ConsoleWrite("MakeContainer-Eof v1.0.0.3 -  by Joakim Schicht")
$file = FileOpenDialog("Select payload to hide", @ScriptDir, "All (*.*)")
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
$hfile = FileOpen($file, 16)
If NOT $hfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$rfile = FileRead($hfile)
$filesize = FileGetSize($file)
ConsoleWrite("$FileSize: " & $filesize & @CRLF)
$fillbytes = ""
$fillcounter = 0
$offsetmod = $filesize
$file2 = FileOpenDialog("Select original VeraCrypt container as host file", @ScriptDir, "All (*.*)")
If @error Then Exit
$hfile2 = FileOpen($file2, 16)
If NOT $hfile2 Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$rfile2 = FileRead($hfile2)
$startpos2 = 3
$filesize2 = FileGetSize($file2)
ConsoleWrite("$FileSize2: " & $filesize2 & @CRLF)
If Mod($offsetmod, 512) Then
	Do
		$fillcounter += 1
		$offsetmod += 1
		$fillbytes &= Hex(Random(0, 255, 1), 2)
	Until Mod($offsetmod, 512) = 0
EndIf
ConsoleWrite("$OffsetMod: " & $offsetmod & @CRLF)
$newcontainerbytes = $fillbytes & StringMid($rfile2, $startpos2)
$outputfilename = @ScriptDir & "\" & $filename & "." & $rand & "." & $fileextension
$outfile = FileOpen($outputfilename, 18)
If NOT $outfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
FileWrite($outfile, $rfile & $newcontainerbytes)
FileClose($hfile)
FileClose($outfile)
$batchfilename = $outputfilename & ".bat"
$hbatchfile = FileOpen($batchfilename, 2)
If NOT $hbatchfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$samplecmdline = "VeraCrypt.exe /v " & '"' & $outputfilename & '"' & " /l x /a /p password /i " & $offsetmod
FileWriteLine($hbatchfile, $samplecmdline)
FileClose($hbatchfile)

Func _dectolittleendian($decimalinput)
	Return _swapendian(Hex($decimalinput, 8))
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

Func _swapendian($ihex)
	Return StringMid(Binary(Dec($ihex, 2)), 3, StringLen($ihex))
EndFunc

Func _hexencode($binput)
	Local $tinput = DllStructCreate("byte[" & BinaryLen($binput) & "]")
	DllStructSetData($tinput, 1, $binput)
	Local $a_icall = DllCall("crypt32.dll", "int", "CryptBinaryToString", "ptr", DllStructGetPtr($tinput), "dword", DllStructGetSize($tinput), "dword", 11, "ptr", 0, "dword*", 0)
	If @error OR NOT $a_icall[0] Then
		Return SetError(1, 0, "")
	EndIf
	Local $isize = $a_icall[5]
	Local $tout = DllStructCreate("char[" & $isize & "]")
	$a_icall = DllCall("crypt32.dll", "int", "CryptBinaryToString", "ptr", DllStructGetPtr($tinput), "dword", DllStructGetSize($tinput), "dword", 11, "ptr", DllStructGetPtr($tout), "dword*", $isize)
	If @error OR NOT $a_icall[0] Then
		Return SetError(2, 0, "")
	EndIf
	Return SetError(0, 0, DllStructGetData($tout, 1))
EndFunc
