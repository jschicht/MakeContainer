#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container inside BMP
#AutoIt3Wrapper_Res_Description=Injects data in between BMP header and Pixel Array
#AutoIt3Wrapper_Res_Fileversion=1.0.0.5
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiEdit.au3>

Global Const $tagbmp_header = "align 1;char BmpMagic[2];ulong BmpSize;ushort Reserved1;ushort Reserved2;ulong OffsetPixelArray"
Global $payloadfile, $containerfile, $payloadfilesize, $containerfilesize, $hfilecontainer, $hfilepayload, $newoutputname, $outputfilename
Global $dolegacycompliant = False, $dorandominpadding = False
$form = GUICreate("MakeContainer-Bmp v1.0.0.5   -   by Joakim Schicht", 803, 400, -1, -1)
$label1 = GUICtrlCreateLabel("Select VeraCrypt container:", 20, 10, 160, 17)
$buttonpayload = GUICtrlCreateButton("Browse", 190, 10, 75, 25, $ws_group)
$secretfiletext = GUICtrlCreateInput("", 270, 10, 520, 20, $es_readonly)
$checklegacycompliant = GUICtrlCreateCheckbox("Legacy version compliant", 20, 40, 150, 20)
GUICtrlSetState($checklegacycompliant, $gui_unchecked)
$checkrandominpadding = GUICtrlCreateCheckbox("Fill padding with random data (default is 00's)", 20, 70, 250, 20)
GUICtrlSetState($checkrandominpadding, $gui_unchecked)
$labelpayloadoffset = GUICtrlCreateLabel("Set offset of payload:", 20, 100, 160, 17)
$inputpayloadoffset = GUICtrlCreateInput("65536", 190, 100, 250, 20)
$labelpayloadsize = GUICtrlCreateLabel("Raw size payload:", 580, 40, 130, 25, $ws_group)
$inputpayloadsize = GUICtrlCreateInput("", 680, 40, 110, 20, $es_readonly)
$labelhostfile = GUICtrlCreateLabel("Select bitmap host file:", 20, 130, 200, 17)
$buttoncontainer = GUICtrlCreateButton("Browse", 190, 130, 75, 25, $ws_group)
GUICtrlSetState($buttoncontainer, $gui_disable)
$containerfiletext = GUICtrlCreateInput("*.bmp", 270, 130, 780, 20, $es_readonly)
$labeloutputfile = GUICtrlCreateLabel("Create container with hybrid file format:", 20, 160, 220, 17)
$buttonmain = GUICtrlCreateButton("Hide file", 330, 160, 95, 25, $ws_group)
GUICtrlSetState($buttonmain, $gui_disable)
$myctredit = GUICtrlCreateEdit("Verbose output information:" & @CRLF, 0, 200, 803, 200, $es_autovscroll + $ws_vscroll)
_guictrledit_setlimittext($myctredit, 512000)
GUISetState(@SW_SHOW)
While 1
	$nmsg = GUIGetMsg()
	Select
		Case $nmsg = $buttonpayload
			$payloadfile = _select_secretfile()
			GUICtrlSetData($secretfiletext, $payloadfile)
		Case $nmsg = $buttoncontainer
			$containerfile = _select_container()
			GUICtrlSetData($containerfiletext, $containerfile)
		Case $nmsg = $buttonmain
			_main()
		Case $nmsg = $gui_event_close
			Exit
	EndSelect
WEnd

Func _main()
	Local $nbytes, $tcnormalheadersize = 65535
	If GUICtrlRead($checklegacycompliant) = 1 Then $dolegacycompliant = True
	If GUICtrlRead($checkrandominpadding) = 1 Then $dorandominpadding = True
	$payloadoffset = GUICtrlRead($inputpayloadoffset)
	If $dolegacycompliant AND $payloadoffset <> 65536 Then
		ConsoleWrite("Warning: Offset has been corrected to 65536 (0x00010000) due to Legacy Compliant mode requirement" & @CRLF)
		_displayinfo("Warning: Offset has been corrected to 65536 (0x00010000) due to Legacy Compliant mode requirement" & @CRLF)
		$payloadoffset = 65536
	EndIf
	If Mod($payloadoffset, 512) Then
		_displayinfo("PayloadOffset not aligned to sector size: " & $payloadoffset & " -> 0x" & Hex($payloadoffset, 8) & @CRLF)
		Return
	EndIf
	_displayinfo("PayloadOffset: " & $payloadoffset & " -> 0x" & Hex($payloadoffset, 8) & @CRLF)
	If $dolegacycompliant Then
		$substractfrompayload = 65536
		$extrapadding = 65024
		$adjustoffset = 0
	Else
		$substractfrompayload = 0
		$extrapadding = $payloadoffset - 512
	EndIf
	$tbuffhostfile = DllStructCreate("byte[" & $containerfilesize & "]")
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($tbuffhostfile), DllStructGetSize($tbuffhostfile), $nbytes)
	If NOT $read Then
		MsgBox(0, "Error", "ReadFile failed")
		Return
	EndIf
	$pbmp_header = DllStructCreate($tagbmp_header, DllStructGetPtr($tbuffhostfile))
	$bmpmagic = DllStructGetData($pbmp_header, "BmpMagic")
	$bmpsize = DllStructGetData($pbmp_header, "BmpSize")
	$offsetpixelarray = DllStructGetData($pbmp_header, "OffsetPixelArray")
	ConsoleWrite("$BmpMagic: " & $bmpmagic & @CRLF)
	ConsoleWrite("$BmpSize: " & $bmpsize & @CRLF)
	ConsoleWrite("$OffsetPixelArray: " & $offsetpixelarray & @CRLF)
	If $bmpmagic <> "BM" Then
		MsgBox(0, "Error", "No BM signature found in header")
		Return
	EndIf
	$fillbytes = ""
	$fillcounter = 0
	$offsetpixelarraymod = $offsetpixelarray
	If $dolegacycompliant Then
		$tbuffpayload = DllStructCreate("byte[" & $payloadfilesize - 65536 & "]")
		_winapi_setfilepointer($hfilepayload, $payloadoffset)
	Else
		$tbuffpayload = DllStructCreate("byte[" & $payloadfilesize & "]")
		_winapi_setfilepointer($hfilepayload, 0)
	EndIf
	$read = _winapi_readfile($hfilepayload, DllStructGetPtr($tbuffpayload), DllStructGetSize($tbuffpayload), $nbytes)
	If NOT $read Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	If $dorandominpadding Then
		If Mod($offsetpixelarraymod, 512) Then
			Do
				$fillcounter += 1
				$offsetpixelarraymod += 1
				$fillbytes &= Hex(Random(0, 255, 1), 2)
			Until Mod($offsetpixelarraymod, 512) = 0
		EndIf
		For $i = 0 To $extrapadding
			$fillbytes &= Hex(Random(0, 255, 1), 2)
		Next
	Else
		If Mod($offsetpixelarraymod, 512) Then
			Do
				$fillcounter += 1
				$offsetpixelarraymod += 1
				$fillbytes &= "00"
			Until Mod($offsetpixelarraymod, 512) = 0
		EndIf
		For $i = 0 To $extrapadding
			$fillbytes &= "00"
		Next
	EndIf
	ConsoleWrite("$OffsetPixelArrayMod: " & $offsetpixelarraymod & @CRLF)
	$tbufffillbytes = DllStructCreate("byte[" & $fillcounter + $extrapadding & "]")
	DllStructSetData($tbufffillbytes, 1, "0x" & $fillbytes)
	$newtotalsize = $containerfilesize + $payloadfilesize - $substractfrompayload
	ConsoleWrite("$NewTotalSize: " & $newtotalsize & @CRLF)
	$hfileoutput = _winapi_createfile("\\.\" & $newoutputname, 1, 6, 2)
	If NOT $hfileoutput Then
		MsgBox(0, "Error", "Could not open file: " & $newoutputname & @CRLF & "Eror code: " & _winapi_getlasterrormessage())
		Exit
	EndIf
	_winapi_setfilepointer($hfileoutput, $newtotalsize)
	_winapi_setendoffile($hfileoutput)
	_winapi_flushfilebuffers($hfileoutput)
	_winapi_setfilepointer($hfileoutput, 0)
	$write = _winapi_writefile($hfileoutput, DllStructGetPtr($tbuffhostfile), DllStructGetSize($tbuffhostfile), $nbytes)
	If NOT $write Then
		MsgBox(0, "Error", "WriteFile failed")
		Exit
	EndIf
	_winapi_setfilepointer($hfileoutput, $offsetpixelarray)
	$write = _winapi_writefile($hfileoutput, DllStructGetPtr($tbufffillbytes), DllStructGetSize($tbufffillbytes), $nbytes)
	If NOT $write Then
		MsgBox(0, "Error", "WriteFile failed")
		Exit
	EndIf
	_winapi_setfilepointer($hfileoutput, $payloadoffset)
	$write = _winapi_writefile($hfileoutput, DllStructGetPtr($tbuffpayload), DllStructGetSize($tbuffpayload), $nbytes)
	If NOT $write Then
		MsgBox(0, "Error", "WriteFile failed")
		Exit
	EndIf
	$tbuffhostfile2 = DllStructCreate("byte[" & $containerfilesize - $offsetpixelarray & "]")
	_winapi_setfilepointer($hfilecontainer, $offsetpixelarray)
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($tbuffhostfile2), DllStructGetSize($tbuffhostfile2), $nbytes)
	If NOT $read Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	_winapi_setfilepointer($hfileoutput, $payloadoffset + Number(DllStructGetSize($tbuffpayload)))
	$write = _winapi_writefile($hfileoutput, DllStructGetPtr($tbuffhostfile2), DllStructGetSize($tbuffhostfile2), $nbytes)
	If NOT $write Then
		MsgBox(0, "Error", "WriteFile failed")
		Exit
	EndIf
	$bufferrawaddress = DllStructCreate("align 1;byte[4]")
	$offsetpixelarraycorrected = Int($payloadoffset + DllStructGetSize($tbuffpayload))
	ConsoleWrite("$OffsetPixelArrayCorrected: " & $offsetpixelarraycorrected & @CRLF)
	$offsetpixelarraycorrectedhex = _swapendian(Hex($offsetpixelarraycorrected, 8))
	ConsoleWrite("$OffsetPixelArrayCorrectedHex: " & $offsetpixelarraycorrectedhex & @CRLF)
	DllStructSetData($bufferrawaddress, 1, "0x" & $offsetpixelarraycorrectedhex)
	_winapi_setfilepointer($hfileoutput, 10)
	$write = _winapi_writefile($hfileoutput, DllStructGetPtr($bufferrawaddress), DllStructGetSize($bufferrawaddress), $nbytes)
	If NOT $write Then
		MsgBox(0, "Error", "WriteFile failed")
		Exit
	EndIf
	_winapi_closehandle($hfileoutput)
	_winapi_closehandle($hfilepayload)
	_winapi_closehandle($hfilecontainer)
	$batchfilename = $outputfilename & ".bat"
	$hbatchfile = FileOpen($batchfilename, 2)
	If NOT $hbatchfile Then
		MsgBox(0, "Error", "Could not open file")
		Exit
	EndIf
	If $dolegacycompliant Then
		$samplecmdline = "VeraCrypt.exe /v " & '"' & $outputfilename & '"' & " /l x /a /p innerpassword"
	Else
		$samplecmdline = "VeraCrypt.exe /v " & '"' & $outputfilename & '"' & " /l x /a /p eitherpassword /i " & $payloadoffset
	EndIf
	FileWriteLine($hbatchfile, $samplecmdline)
	FileClose($hbatchfile)
	_deactivatecontrols()
	MsgBox(0, "Finished", "Job done")
EndFunc

Func _select_secretfile()
	Global $hfilepayload, $payloadfilesize
	$payloadfile = FileOpenDialog("Select original VeraCrypt container as host file", @ScriptDir, "All (*.*)")
	If @error Then
		ConsoleWrite("Error opening file." & @CRLF)
		_displayinfo("Error opening file." & @CRLF)
		Return
	EndIf
	ConsoleWrite("$PayloadFile: " & $payloadfile & @CRLF)
	$payloadfilesize = FileGetSize($payloadfile)
	ConsoleWrite("$PayloadFileSize: " & $payloadfilesize & @CRLF)
	$hfilepayload = _winapi_createfile("\\.\" & $payloadfile, 2, 2, 7)
	If NOT $hfilepayload Then
		MsgBox(0, "Error", "Could not open file: " & $payloadfile & @CRLF & "Eror code: " & _winapi_getlasterrormessage())
		Return
	EndIf
	GUICtrlSetState($buttoncontainer, $gui_enable)
	Return $payloadfile
EndFunc

Func _select_container()
	Global $hfilecontainer, $outputfilename, $newoutputname, $containerfilesize
	$containerfile = FileOpenDialog("Select BMP", @ScriptDir, "All (*.*)")
	If @error Then
		ConsoleWrite("Error opening file." & @CRLF)
		_displayinfo("Error opening file." & @CRLF)
		Return
	EndIf
	ConsoleWrite("$ContainerFile: " & $containerfile & @CRLF)
	$filename = _getfilename($containerfile)
	If @error Then
		MsgBox(0, "Error", "Could not resolve file name")
		ConsoleWrite("Error: Could not resolve file name." & @CRLF)
		_displayinfo("Error: Could not resolve file name." & @CRLF)
		Return
	EndIf
	ConsoleWrite("FileName: " & $filename & @CRLF)
	$fileextension = _getfileextension($containerfile)
	If @error Then
		MsgBox(0, "Error", "Could not resolve file extension")
		ConsoleWrite("Error: Could not resolve file extension" & @CRLF)
		_displayinfo("Error: Could not resolve file extension" & @CRLF)
		Return
	EndIf
	ConsoleWrite("$FileExtension: " & $fileextension & @CRLF)
	$rand = Hex(Random(0, 65535, 1), 4)
	$hfilecontainer = _winapi_createfile("\\.\" & $containerfile, 2, 2, 7)
	If NOT $hfilecontainer Then
		MsgBox(0, "Error", "Could not open file: " & $containerfile & @CRLF & "Error code: " & _winapi_getlasterrormessage())
		ConsoleWrite("Error: Could not open file: " & $containerfile & @CRLF)
		_displayinfo("Error: Could not open file: " & $containerfile & @CRLF)
		Return
	EndIf
	$containerfilesize = FileGetSize($containerfile)
	ConsoleWrite("$ContainerFileSize: " & $containerfilesize & @CRLF)
	$outputfilename = @ScriptDir & "\" & $filename & "." & $rand & "." & $fileextension
	$newoutputname = $containerfile & "." & $rand & "." & $fileextension
	_displayinfo("Output file: " & $newoutputname & @CRLF)
	GUICtrlSetState($buttonmain, $gui_enable)
	Return $containerfile
EndFunc

Func _displayinfo($verboseinfo)
	GUICtrlSetData($myctredit, $verboseinfo, 1)
EndFunc

Func _dectolittleendian($decimalinput)
	ConsoleWrite("_DecToLittleEndian: " & $decimalinput & @CRLF)
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

Func _deactivatecontrols()
	GUICtrlSetState($buttonmain, $gui_disable)
	GUICtrlSetState($buttoncontainer, $gui_disable)
EndFunc
