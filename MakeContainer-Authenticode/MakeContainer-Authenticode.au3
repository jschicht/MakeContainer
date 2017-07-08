#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container in digital certificate
#AutoIt3Wrapper_Res_Description=Injects data into Authenticode signature
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiEdit.au3>

Global $secretfile, $containerpath, $aesval, $rsize, $psize, $file, $ifile, $obfuscationsize, $hidemethod, $newpsize
$outheadersum = DllStructCreate("dword")
$outchecksum = DllStructCreate("dword")
$form = GUICreate("MakeContainer-Authenticode v1.0.0.3   -   by Joakim Schicht", 803, 400, -1, -1)
$label1 = GUICtrlCreateLabel("Select target file you want to hide:", 20, 10, 160, 17)
$button0 = GUICtrlCreateButton("Browse", 190, 10, 75, 25, $ws_group)
$secretfiletext = GUICtrlCreateInput("", 270, 10, 520, 20, $es_readonly)
$checkcompress = GUICtrlCreateCheckbox("Feature removed", 20, 40, 100, 20)
GUICtrlSetState($checkcompress, $gui_disable)
GUICtrlSetState($checkcompress, $gui_unchecked)
$checkaes = GUICtrlCreateCheckbox("Feature removed:", 20, 70, 160, 20)
GUICtrlSetState($checkaes, $gui_disable)
GUICtrlSetState($checkaes, $gui_unchecked)
$obfuscationkeyaes = GUICtrlCreateInput("Feature disabled", 190, 70, 250, 20)
GUICtrlSetState($obfuscationkeyaes, $gui_disable)
$obfuscationbutton = GUICtrlCreateButton("Prepare secret data", 450, 70, 120, 25, $ws_group)
GUICtrlSetState($obfuscationbutton, $gui_disable)
$obfuscationlabel1 = GUICtrlCreateLabel("Raw size payload:", 580, 70, 130, 25, $ws_group)
$obfuscationsize = GUICtrlCreateInput("", 680, 70, 110, 20, $es_readonly)
$label_dropdown1 = GUICtrlCreateLabel("Select executable as container:", 20, 100, 200, 17)
$button1 = GUICtrlCreateButton("Browse", 190, 100, 75, 25, $ws_group)
GUICtrlSetState($button1, $gui_disable)
$containerfiletext = GUICtrlCreateInput("*.dll | *.exe | *.sys | etc", 10, 130, 780, 20, $es_readonly)
$label_method1 = GUICtrlCreateLabel("Will hide payload inside signature of target:", 5, 160, 220, 17)
$checktimestamp1 = GUICtrlCreateCheckbox("Feature removed", 230, 160, 170, 20)
GUICtrlSetState($checktimestamp1, $gui_disable)
$button_method1 = GUICtrlCreateButton("Hide file", 430, 160, 95, 25, $ws_group)
GUICtrlSetState($button_method1, $gui_disable)
$myctredit = GUICtrlCreateEdit("Verbose output information:" & @CRLF, 0, 200, 803, 200, $es_autovscroll + $ws_vscroll)
_guictrledit_setlimittext($myctredit, 512000)

GUISetState(@SW_SHOW)
While 1
	$nmsg = GUIGetMsg()
	Select
		Case $nmsg = $button0
			$payloadfile = _select_secretfile()
			GUICtrlSetData($secretfiletext, $secretfile)
		Case $nmsg = $button1
			$containerfile = _select_container()
			GUICtrlSetData($containerfiletext, $containerpath)
		Case $nmsg = $button_method1
			$hidemethod = 1
			_main($containerfile, $payloadfile)
		Case $nmsg = $obfuscationbutton
			GUICtrlSetData($obfuscationsize, $psize)
			If $obfuscationsize <> "" Then GUICtrlSetState($button1, $gui_enable)
		Case $nmsg = $gui_event_close
			Exit
	EndSelect
WEnd

Func _getfileextension($input)
	$pos = StringInStr($input, ".", 0, -1)
	$resolvedfileextension = StringMid($input, $pos + 1)
	If $resolvedfileextension = "" Then
		Return SetError(1, 0, 0)
	Else
		Return $resolvedfileextension
	EndIf
EndFunc

Func _select_container()
	$file = FileOpenDialog("Select container with digital signature:", @ScriptDir, "Executables (*.exe;*.dll;*.mui;*.sys)")
	If @error Then Return
	Global $containerpath = $file
	_displayinfo("Select_Container: Selected executable container: " & $containerpath & @CRLF)
	$fileextension = _getfileextension($file)
	$rand = Hex(Random(0, 65535, 1), 4)
	FileCopy($file, $file & "." & $rand & "." & $fileextension)
	$file = $file & "." & $rand & "." & $fileextension
	_displayinfo("Main: Making backup of target file to: " & $file & @CRLF)
	Global $containerpath = $file
	$hfile = _winapi_createfile("\\.\" & $file, 2, 6, 7)
	$lasterror = _winapi_getlasterror()
	If $lasterror <> 0 Then
		_winapi_closehandle($hfile)
		_displayinfo("Select_Container: Error - CreateFile had some troubles on container. Will see if file permissions are the issue." & @CRLF)
		_grantfileaccess($containerpath)
		$hfile = _retrycreatefile($containerpath)
	EndIf
	If $hfile = 0 Then
		_displayinfo("Select_Container: Error - I give up on function CreateFile for container." & @CRLF)
		Return
	EndIf
	Global $rsize = _winapi_getfilesizeex($hfile)
	_displayinfo("Select_Container: Original size of container: " & $rsize & @CRLF)
	_setcontrols()
	Return $hfile
EndFunc

Func _select_secretfile()
	$hfile1 = 0
	$payload = FileOpenDialog("Select payload:", @ScriptDir, "All (*.*)")
	If @error Then Return
	Global $payloadpath = $payload
	_displayinfo("Select_SecretFile: Selected payload: " & $payloadpath & @CRLF)
	Global $secretfile = $payload
	$path2load = FileGetLongName($payloadpath)
	$hfile1 = _winapi_createfile("\\.\" & $payload, 2, 6, 7)
	$lasterror = _winapi_getlasterror()
	If $lasterror <> 0 Then
		_winapi_closehandle($hfile1)
		_displayinfo("Select_SecretFile: Error - CreateFile had some troubles on payload. Will see if file permissions are the issue." & @CRLF)
		_grantfileaccess($payloadpath)
		$hfile1 = _retrycreatefile($payloadpath)
	EndIf
	If $hfile1 = 0 Then
		_displayinfo("Select_SecretFile: Error - I give up on function CreateFile for payload." & @CRLF)
		Return
	EndIf
	Global $psize = _winapi_getfilesizeex($hfile1)
	If $psize > 102367232 Then
		MsgBox(0, "Warning", "The size of the payload will is larger than the limit that Microsoft has imposed. The signature will not be evaluated at all.")
	EndIf
	_displayinfo("Select_SecretFile: Original size of payload: " & $psize & @CRLF)
	GUICtrlSetState($obfuscationbutton, $gui_enable)
	Return $hfile1
EndFunc

Func _displayinfo($verboseinfo)
	GUICtrlSetData($myctredit, $verboseinfo, 1)
EndFunc

Func _main($hfile, $hfile1)
	If $hfile = 0 Then
		_displayinfo("CreateFile function function failed on container.." & @CRLF)
		Return
	EndIf
	If $hfile1 = 0 Then
		_displayinfo("CreateFile function function failed on payload.." & @CRLF)
		Return
	EndIf
	$dosheader = _dosheader($hfile)
	If $dosheader[0] <> "MZ" Then
		_displayinfo("Main: Error - This is not an executable. First 2 bytes returned: " & $dosheader[0] & " Choose another file!." & @CRLF)
		_winapi_closehandle($hfile)
		_winapi_closehandle($hfile1)
		Return
	EndIf
	$pestart = $dosheader[17]
	$fileheader = _fileheader($hfile, $pestart)
	$sizeofoptionalheader = $fileheader[6]
	$ohoffset = $pestart + 24
	$optionalheader = _optionalheader($hfile, $ohoffset, $sizeofoptionalheader)
	$magic = $optionalheader[0]
	$arch = ""
	If $magic = 523 Then $arch = "PE64"
	If $magic = 267 Then $arch = "PE32"
	If $magic <> 267 AND $magic <> 523 Then
		_displayinfo("Main: Error - PE file is neither of PE32 or PE64. Choose another one!." & @CRLF)
		_winapi_closehandle($hfile)
		_winapi_closehandle($hfile1)
		Return
	EndIf
	$filealignment = $optionalheader[11]
	$checksumposition = $pestart + 88
	If $magic = 267 Then
		$securityoffset = $pestart + 120 + 32
	Else
		If $magic = 523 Then
			$securityoffset = $pestart + 120 + 48
		EndIf
	EndIf
	$getsecurity = _getsecurity($hfile, $securityoffset)
	$signatureposition = $getsecurity[0]
	$signaturesize = $getsecurity[1]
	If $signatureposition = 0 OR $signaturesize = 0 Then
		_displayinfo("Main: Error - Executable does not contain a digital signature. Choose another one.." & @CRLF)
		_winapi_closehandle($hfile)
		_winapi_closehandle($hfile1)
		Return
	EndIf
	$setpayload = _setpayload($hfile, $hfile1, $rsize, $psize, $filealignment, $securityoffset + 4, $signatureposition, $signaturesize)
	If $setpayload = 0 Then
		_displayinfo("Main: Error occurred." & @CRLF)
		_deactivatecontrols()
		Return
	EndIf
	$calcchecksum = _mapfileandchecksum($containerpath)
	If $calcchecksum[0] <> 0 Then
		_displayinfo("Main: Warning - Error occurred when calculating checksum of PE, but signature seems OK" & @CRLF)
		_winapi_closehandle($hfile)
		_winapi_closehandle($hfile1)
		_displayinfo("FINISHED! - Now please check the executable and validate its digital signature" & @CRLF)
		_displayinfo(" (If you want to modify another file, then restart the program.)" & @CRLF)
		_deactivatecontrols()
		Return
	EndIf
	If Hex($calcchecksum[1]) = Hex($calcchecksum[2]) Then
		_displayinfo("Main: Weird - Checksum in PE was surprisingly correct" & @CRLF)
		_winapi_closehandle($hfile)
		_winapi_closehandle($hfile1)
		_displayinfo("FINISHED! - Now please check the executable and validate its digital signature" & @CRLF)
		_displayinfo("  (If you want to modify another file, then restart the program.)" & @CRLF)
		_deactivatecontrols()
		Return
	EndIf
	_fixchecksum($hfile, $checksumposition, $calcchecksum[2])
	_winapi_closehandle($hfile)
	_winapi_closehandle($hfile1)
	_displayinfo("" & @CRLF)
	_displayinfo("FINISHED! - Now please check the executable and validate its digital signature" & @CRLF)
	_displayinfo("  (If you want to modify another file, then restart the program.)" & @CRLF)
	_deactivatecontrols()
EndFunc

Func _dosheader($hfile)
	_displayinfo("DosHeader: Attempt of decoding.." & @CRLF)
	$ppointer = $hfile
	Local $dos_header[18], $nbytes
	_winapi_setfilepointer($hfile, 0)
	Local $fsize = 64
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		_displayinfo("DosHeader: Error ReadFile failed" & @CRLF)
		Return
	EndIf
	$raw = 0
	$raw = DllStructGetData($tbuffer, 1)
	Local $timage_dos_header = DllStructCreate("char Magic[2];" & "ushort BytesOnLastPage;" & "ushort Pages;" & "ushort Relocations;" & "ushort SizeofHeader;" & "ushort MinimumExtra;" & "ushort MaximumExtra;" & "ushort SS;" & "ushort SP;" & "ushort Checksum;" & "ushort IP;" & "ushort CS;" & "ushort Relocation;" & "ushort Overlay;" & "char Reserved[8];" & "ushort OEMIdentifier;" & "ushort OEMInformation;" & "char Reserved2[20];" & "dword AddressOfNewExeHeader", DllStructGetPtr($tbuffer))
	$dos_header[0] = DllStructGetData($timage_dos_header, "Magic")
	$dos_header[1] = DllStructGetData($timage_dos_header, "BytesOnLastPage")
	$dos_header[2] = DllStructGetData($timage_dos_header, "Pages")
	$dos_header[3] = DllStructGetData($timage_dos_header, "Relocations")
	$dos_header[4] = DllStructGetData($timage_dos_header, "SizeofHeader")
	$dos_header[5] = DllStructGetData($timage_dos_header, "MinimumExtra")
	$dos_header[6] = DllStructGetData($timage_dos_header, "SS")
	$dos_header[7] = DllStructGetData($timage_dos_header, "SP")
	$dos_header[8] = DllStructGetData($timage_dos_header, "Checksum")
	$dos_header[9] = DllStructGetData($timage_dos_header, "IP")
	$dos_header[10] = DllStructGetData($timage_dos_header, "CS")
	$dos_header[11] = DllStructGetData($timage_dos_header, "Relocation")
	$dos_header[12] = DllStructGetData($timage_dos_header, "Overlay")
	$dos_header[13] = DllStructGetData($timage_dos_header, "Reserved")
	$dos_header[14] = DllStructGetData($timage_dos_header, "OEMIdentifier")
	$dos_header[15] = DllStructGetData($timage_dos_header, "OEMInformation")
	$dos_header[16] = DllStructGetData($timage_dos_header, "Reserved2")
	$dos_header[17] = DllStructGetData($timage_dos_header, "AddressOfNewExeHeader")
	_displayinfo("DosHeader: Magic = " & $dos_header[0] & @CRLF)
	_displayinfo("DosHeader: AddressOfNewExeHeader (PE start) = 0x" & Hex($dos_header[17], 8) & @CRLF)
	Return $dos_header
EndFunc

Func _fileheader($hfile, $addressofnewexeheader)
	_displayinfo("FileHeader: Attempt of decoding.." & @CRLF)
	Local $file_header[8], $nbytes
	ConsoleWrite("$AddressOfNewExeHeader: " & $addressofnewexeheader & @CRLF)
	_winapi_setfilepointer($hfile, $addressofnewexeheader)
	Local $fsize = 25
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		_displayinfo("FileHeader: Error ReadFile failed" & @CRLF)
		Return
	EndIf
	$raw = 0
	$raw = DllStructGetData($tbuffer, 1)
	Local $timage_file_header = DllStructCreate("dword Signature;" & "ushort Machine;" & "ushort NumberOfSections;" & "dword TimeDateStamp;" & "dword PointerToSymbolTable;" & "dword NumberOfSymbols;" & "ushort SizeOfOptionalHeader;" & "ushort Characteristics", DllStructGetPtr($tbuffer))
	$file_header[0] = DllStructGetData($timage_file_header, "Signature")
	$file_header[1] = DllStructGetData($timage_file_header, "Machine")
	$file_header[2] = DllStructGetData($timage_file_header, "NumberOfSections")
	$file_header[3] = DllStructGetData($timage_file_header, "TimeDateStamp")
	$file_header[4] = DllStructGetData($timage_file_header, "PointerToSymbolTable")
	$file_header[5] = DllStructGetData($timage_file_header, "NumberOfSymbols")
	$file_header[6] = DllStructGetData($timage_file_header, "SizeOfOptionalHeader")
	$file_header[7] = DllStructGetData($timage_file_header, "Characteristics")
	_displayinfo("FileHeader: Signature = 0x" & Hex($file_header[0], 8) & @CRLF)
	_displayinfo("FileHeader: Machine = 0x" & Hex($file_header[1], 4) & @CRLF)
	_displayinfo("FileHeader: NumberOfSections = 0x" & Hex($file_header[2], 4) & @CRLF)
	_displayinfo("FileHeader: SizeOfOptionalHeader = 0x" & Hex($file_header[6], 4) & @CRLF)
	Return $file_header
EndFunc

Func _optionalheader($hfile, $ohoffset, $sizeofoptionalheader)
	_displayinfo("OptionalHeader: Attempt of decoding.." & @CRLF)
	Local $optional_header[30], $nbytes
	_winapi_setfilepointer($hfile, $ohoffset)
	Local $fsize = 92
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		_displayinfo("OptionalHeader: Error ReadFile failed" & @CRLF)
		Return
	EndIf
	$raw = 0
	$raw = DllStructGetData($tbuffer, 1)
	Local $timage_optional_header = DllStructCreate("ushort Magic;" & "ubyte MajorLinkerVersion;" & "ubyte MinorLinkerVersion;" & "dword SizeOfCode;" & "dword SizeOfInitializedData;" & "dword SizeOfUninitializedData;" & "dword AddressOfEntryPoint;" & "dword BaseOfCode;" & "dword BaseOfData;" & "dword ImageBase;" & "dword SectionAlignment;" & "dword FileAlignment;" & "ushort MajorOperatingSystemVersion;" & "ushort MinorOperatingSystemVersion;" & "ushort MajorImageVersion;" & "ushort MinorImageVersion;" & "ushort MajorSubsystemVersion;" & "ushort MinorSubsystemVersion;" & "dword Win32VersionValue;" & "dword SizeOfImage;" & "dword SizeOfHeaders;" & "dword CheckSum;" & "ushort Subsystem;" & "ushort DllCharacteristics;" & "dword SizeOfStackReserve;" & "dword SizeOfStackCommit;" & "dword SizeOfHeapReserve;" & "dword SizeOfHeapCommit;" & "dword LoaderFlags;" & "dword NumberOfRvaAndSizes", DllStructGetPtr($tbuffer))
	$optional_header[0] = DllStructGetData($timage_optional_header, "Magic")
	$optional_header[1] = DllStructGetData($timage_optional_header, "MajorLinkerVersion")
	$optional_header[2] = DllStructGetData($timage_optional_header, "MinorLinkerVersion")
	$optional_header[3] = DllStructGetData($timage_optional_header, "SizeOfCode")
	$optional_header[4] = DllStructGetData($timage_optional_header, "SizeOfInitializedData")
	$optional_header[5] = DllStructGetData($timage_optional_header, "SizeOfUninitializedData")
	$optional_header[6] = DllStructGetData($timage_optional_header, "AddressOfEntryPoint")
	$optional_header[7] = DllStructGetData($timage_optional_header, "BaseOfCode")
	$optional_header[8] = DllStructGetData($timage_optional_header, "BaseOfData")
	$optional_header[9] = DllStructGetData($timage_optional_header, "ImageBase")
	$optional_header[10] = DllStructGetData($timage_optional_header, "SectionAlignment")
	$optional_header[11] = DllStructGetData($timage_optional_header, "FileAlignment")
	$optional_header[12] = DllStructGetData($timage_optional_header, "MajorOperatingSystemVersion")
	$optional_header[13] = DllStructGetData($timage_optional_header, "MinorOperatingSystemVersion")
	$optional_header[14] = DllStructGetData($timage_optional_header, "MajorImageVersion")
	$optional_header[15] = DllStructGetData($timage_optional_header, "MinorImageVersion")
	$optional_header[16] = DllStructGetData($timage_optional_header, "MajorSubsystemVersion")
	$optional_header[17] = DllStructGetData($timage_optional_header, "MinorSubsystemVersion")
	$optional_header[18] = DllStructGetData($timage_optional_header, "Win32VersionValue")
	$optional_header[19] = DllStructGetData($timage_optional_header, "SizeOfImage")
	$optional_header[20] = DllStructGetData($timage_optional_header, "SizeOfHeaders")
	$optional_header[21] = DllStructGetData($timage_optional_header, "CheckSum")
	$optional_header[22] = DllStructGetData($timage_optional_header, "Subsystem")
	$optional_header[23] = DllStructGetData($timage_optional_header, "DllCharacteristics")
	$optional_header[24] = DllStructGetData($timage_optional_header, "SizeOfStackReserve")
	$optional_header[25] = DllStructGetData($timage_optional_header, "SizeOfStackCommit")
	$optional_header[26] = DllStructGetData($timage_optional_header, "SizeOfHeapReserve")
	$optional_header[27] = DllStructGetData($timage_optional_header, "SizeOfHeapCommit")
	$optional_header[28] = DllStructGetData($timage_optional_header, "LoaderFlags")
	$optional_header[29] = DllStructGetData($timage_optional_header, "NumberOfRvaAndSizes")
	_displayinfo("OptionalHeader: Magic = 0x" & Hex($optional_header[0], 4) & @CRLF)
	_displayinfo("OptionalHeader: FileAlignment = 0x" & Hex($optional_header[11], 8) & @CRLF)
	_displayinfo("OptionalHeader: SizeOfImage = 0x" & Hex($optional_header[19], 8) & @CRLF)
	_displayinfo("OptionalHeader: SizeOfHeaders = 0x" & Hex($optional_header[20], 8) & @CRLF)
	Return $optional_header
EndFunc

Func _getsecurity($hfile, $securityoffset)
	_displayinfo("GetSecurity: Attempt of decoding.." & @CRLF)
	Local $security[2], $nbytes
	_winapi_setfilepointer($hfile, $securityoffset)
	Local $fsize = 9
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		_displayinfo("GetSecurity: Error ReadFile failed" & @CRLF)
		Return
	EndIf
	$raw = 0
	$raw = DllStructGetData($tbuffer, 1)
	Local $timage_security = DllStructCreate("dword SECURITY_RVA;dword SECURITY_SIZE", DllStructGetPtr($tbuffer))
	$security[0] = DllStructGetData($timage_security, "SECURITY_RVA")
	$security[1] = DllStructGetData($timage_security, "SECURITY_SIZE")
	_displayinfo("GetSecurity: SECURITY_RVA = 0x" & Hex($security[0], 8) & @CRLF)
	_displayinfo("GetSecurity: SECURITY_SIZE = 0x" & Hex($security[1], 8) & @CRLF)
	Return $security
EndFunc

Func _setpayload($hfile, $hfile1, $rsize, $psize, $filealignment, $securityentryposition, $signatureposition, $signaturesize)
	Local $nbytes, $padding, $customheadersize = 512
	_displayinfo("SetPayload: Size of payload = " & $psize & " bytes" & @CRLF)
	$remainder = 0
	$sizediff = $psize / $filealignment
	$maxblocks = Ceiling($sizediff)
	$maxblocks_low = Floor($sizediff)
	$sizediff2 = $sizediff - $maxblocks_low
	$remainder = $filealignment - ($sizediff2 * $filealignment)
	$testoffset = $signatureposition + $signaturesize
	$fillcounter = 0
	$padding = ""
	If Mod($testoffset, 512) Then
		Do
			$fillcounter += 1
			$testoffset += 1
			;$padding &= "00"
			$padding &= Hex(Random(0x00, 0xFF, 1), 2)
		Until Mod($testoffset, 512) = 0
	EndIf
	$signatureincrease = $fillcounter + $psize
	$newsize = $rsize + $signatureincrease
	If $signaturesize + $signatureincrease > 4294967295 Then
		_displayinfo("SetPayload: Error - Payload is too large to fit inside digital signature" & @CRLF)
		Return 0
	EndIf
	$fillcounter2 = 0
	$padding2 = ""
	If Mod($newsize, 512) Then
		Do
			$fillcounter2 += 1
			$newsize += 1
			;$padding2 &= "00"
			$padding2 &= Hex(Random(0x00, 0xFF, 1), 2)
		Until Mod($newsize, 512) = 0
	EndIf
	_displayinfo("SetPayload: Setting new file size to " & $newsize & " bytes" & @CRLF)
	_winapi_setfilepointer($hfile, $newsize)
	_winapi_setendoffile($hfile)
	_winapi_flushfilebuffers($hfile)

	;
	_displayinfo("SetPayload: Adding " & $fillcounter & " bytes as first padding to fit FileAlignment" & @CRLF)
	_winapi_setfilepointer($hfile, $signatureposition + $signaturesize)
	_displayinfo("SetPayload: Writing padding to signature." & @CRLF)
	$tbuffer4 = DllStructCreate("align 1;byte[" & $fillcounter & "]")
	DllStructSetData($tbuffer4, 1, "0x" & $padding)
	_winapi_writefile($hfile, DllStructGetPtr($tbuffer4), $fillcounter, $nbytes)
	$tbuffer4=0

	;
	_displayinfo("SetPayload: Adding " & $psize & " bytes for the payload" & @CRLF)
	$hFilePayload = _winapi_createfile("\\.\" & $payloadpath, 2, 6, 7)
	_displayinfo("SetPayload: Writing payload to signature...." & @CRLF)
	$tbuffer4 = DllStructCreate("align 1;byte[" & $psize & "]")
	_winapi_readfile($hFilePayload, DllStructGetPtr($tbuffer4), $psize, $nbytes)
	_winapi_setfilepointer($hfile, $signatureposition + $signaturesize + $fillcounter)
	_winapi_writefile($hfile, DllStructGetPtr($tbuffer4), $psize, $nbytes)
	$tbuffer4=0
	_WinAPI_CloseHandle($hFilePayload)

	;
	_winapi_setfilepointer($hfile, $signatureposition)
	$newsignaturesize = $signaturesize + $signatureincrease
	$newsignaturesize = Hex(Int($newsignaturesize), 8)
	_displayinfo("SetPayload: Writing new signature size inside the signature: 0x" & $newsignaturesize & @CRLF)
	$newsignaturesize = "0x" & StringMid($newsignaturesize, 7, 2) & StringMid($newsignaturesize, 5, 2) & StringMid($newsignaturesize, 3, 2) & StringMid($newsignaturesize, 1, 2)
	$tbuffer3 = 0
	$tbuffer3 = DllStructCreate("byte[" & 4 & "]")
	DllStructSetData($tbuffer3, 1, $newsignaturesize)
	_winapi_writefile($hfile, DllStructGetPtr($tbuffer3), 4, $nbytes)

	;
	_winapi_setfilepointer($hfile, $securityentryposition)
	$newsignaturesize = $signaturesize + $signatureincrease + $fillcounter2
	$newsignaturesize = Hex(Int($newsignaturesize), 8)
	_displayinfo("SetPayload: Writing new signature size at SECURITY_SIZE: 0x" & $newsignaturesize & @CRLF)
	$newsignaturesize = "0x" & StringMid($newsignaturesize, 7, 2) & StringMid($newsignaturesize, 5, 2) & StringMid($newsignaturesize, 3, 2) & StringMid($newsignaturesize, 1, 2)
	$tbuffer3 = 0
	$tbuffer3 = DllStructCreate("byte[" & 4 & "]")
	DllStructSetData($tbuffer3, 1, $newsignaturesize)
	_winapi_writefile($hfile, DllStructGetPtr($tbuffer3), 4, $nbytes)

	;
	_displayinfo("SetPayload: Adding " & $fillcounter2 & " bytes as second padding to fit FileAlignment" & @CRLF)
	_winapi_setfilepointer($hfile, $signatureposition + $signaturesize + $signatureincrease)
	_displayinfo("SetPayload: Writing second padding" & @CRLF)
	$tbuffer4 = 0
	$tbuffer4 = DllStructCreate("align 1;byte[" & $fillcounter2 & "]")
	DllStructSetData($tbuffer4, 1, "0x" & $padding2)
	_winapi_writefile($hfile, DllStructGetPtr($tbuffer4), $fillcounter2, $nbytes)

	;
	$batchfilename = $containerpath & ".bat"
	$hbatchfile = FileOpen($batchfilename, 2)
	If NOT $hbatchfile Then
		MsgBox(0, "Error", "Could not open file " & $batchfilename)
		Exit
	EndIf
	$samplecmdline = "VeraCrypt.exe /v " & '"' & $containerpath & '"' & " /l x /a /p password /i " & $testoffset
	FileWriteLine($hbatchfile, $samplecmdline)
	FileClose($hbatchfile)
	Return 1
EndFunc

Func _datadirectories($hfile, $dataoffset)
	_displayinfo("DataDirectories: Attempt of decoding.." & @CRLF)
	Local $data_directories[32], $nbytes
	_winapi_setfilepointer($hfile, $dataoffset)
	Local $fsize = 128
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		_displayinfo("DataDirectories: Error ReadFile failed" & @CRLF)
		Return
	EndIf
	$raw = 0
	$raw = DllStructGetData($tbuffer, 1)
	Local $timage_data_directories = DllStructCreate("dword EXPORT_RVA;" & "dword EXPORT_SIZE;" & "dword IMPORT_RVA;" & "dword IMPORT_SIZE;" & "dword RESOURCE_RVA;" & "dword RESOURCE_SIZE;" & "dword EXCEPTION_RVA;" & "dword EXCEPTION_SIZE;" & "dword SECURITY_RVA;" & "dword SECURITY_SIZE;" & "dword BASERELOC_RVA;" & "dword BASERELOC_SIZE;" & "dword DEBUG_RVA;" & "dword DEBUG_SIZE;" & "dword COPYRIGHT_RVA;" & "dword COPYRIGHT_SIZE;" & "dword ARCHITECTURE_RVA;" & "dword ARCHITECTURE_SIZE;" & "dword GLOBALPTR_RVA;" & "dword GLOBALPTR_SIZE;" & "dword TLS_RVA;" & "dword TLS_SIZE;" & "dword LOAD_CONFIG_RVA;" & "dword LOAD_CONFIG_SIZE;" & "dword BOUND_IMPORT_RVA;" & "dword BOUND_IMPORT_SIZE;" & "dword IAT_RVA;" & "dword IAT_SIZE;" & "dword DELAY_IMPORT_RVA;" & "dword DELAY_IMPORT_SIZE;" & "dword COM_DESCRIPTOR_RVA;" & "dword COM_DESCRIPTOR_SIZE", DllStructGetPtr($tbuffer))
	$data_directories[0] = DllStructGetData($timage_data_directories, "EXPORT_RVA")
	$data_directories[1] = DllStructGetData($timage_data_directories, "EXPORT_SIZE")
	$data_directories[2] = DllStructGetData($timage_data_directories, "IMPORT_RVA")
	$data_directories[3] = DllStructGetData($timage_data_directories, "IMPORT_SIZE")
	$data_directories[4] = DllStructGetData($timage_data_directories, "RESOURCE_RVA")
	$data_directories[5] = DllStructGetData($timage_data_directories, "RESOURCE_SIZE")
	$data_directories[6] = DllStructGetData($timage_data_directories, "EXCEPTION_RVA")
	$data_directories[7] = DllStructGetData($timage_data_directories, "EXCEPTION_SIZE")
	$data_directories[8] = DllStructGetData($timage_data_directories, "SECURITY_RVA")
	$data_directories[9] = DllStructGetData($timage_data_directories, "SECURITY_SIZE")
	$data_directories[10] = DllStructGetData($timage_data_directories, "BASERELOC_RVA")
	$data_directories[11] = DllStructGetData($timage_data_directories, "BASERELOC_SIZE")
	$data_directories[12] = DllStructGetData($timage_data_directories, "DEBUG_RVA")
	$data_directories[13] = DllStructGetData($timage_data_directories, "DEBUG_SIZE")
	$data_directories[14] = DllStructGetData($timage_data_directories, "COPYRIGHT_RVA")
	$data_directories[15] = DllStructGetData($timage_data_directories, "COPYRIGHT_SIZE")
	$data_directories[16] = DllStructGetData($timage_data_directories, "ARCHITECTURE_RVA")
	$data_directories[17] = DllStructGetData($timage_data_directories, "ARCHITECTURE_SIZE")
	$data_directories[18] = DllStructGetData($timage_data_directories, "GLOBALPTR_RVA")
	$data_directories[19] = DllStructGetData($timage_data_directories, "GLOBALPTR_SIZE")
	$data_directories[20] = DllStructGetData($timage_data_directories, "TLS_RVA")
	$data_directories[21] = DllStructGetData($timage_data_directories, "TLS_SIZE")
	$data_directories[22] = DllStructGetData($timage_data_directories, "LOAD_CONFIG_RVA")
	$data_directories[23] = DllStructGetData($timage_data_directories, "LOAD_CONFIG_SIZE")
	$data_directories[24] = DllStructGetData($timage_data_directories, "BOUND_IMPORT_RVA")
	$data_directories[25] = DllStructGetData($timage_data_directories, "BOUND_IMPORT_SIZE")
	$data_directories[26] = DllStructGetData($timage_data_directories, "IAT_RVA")
	$data_directories[27] = DllStructGetData($timage_data_directories, "IAT_SIZE")
	$data_directories[28] = DllStructGetData($timage_data_directories, "DELAY_IMPORT_RVA")
	$data_directories[29] = DllStructGetData($timage_data_directories, "DELAY_IMPORT_SIZE")
	$data_directories[30] = DllStructGetData($timage_data_directories, "COM_DESCRIPTOR_RVA")
	$data_directories[31] = DllStructGetData($timage_data_directories, "COM_DESCRIPTOR_SIZE")
	_displayinfo("DataDirectories: SECURITY_RVA = 0x" & Hex($data_directories[8], 8) & @CRLF)
	_displayinfo("DataDirectories: SECURITY_SIZE = 0x" & Hex($data_directories[9], 8) & @CRLF)
	Return $data_directories
EndFunc

Func _mapfileandchecksum($pefile)
	Local $aresult[3]
	$aresult = DllCall("imagehlp.dll", "long", "MapFileAndCheckSum", "str", $pefile, "ptr", DllStructGetPtr($outheadersum), "ptr", DllStructGetPtr($outchecksum))
	If $aresult[0] <> 0 Then
		_displayinfo("MapFileAndCheckSum: Error code: " & $aresult[0] & @CRLF)
		Return SetError(@error, 0, 0)
	EndIf
	$aresult[1] = DllStructGetData($outheadersum, 1)
	$aresult[2] = DllStructGetData($outchecksum, 1)
	_displayinfo("MapFileAndCheckSum: Checksum present in header = 0x" & Hex($aresult[1], 8) & @CRLF)
	_displayinfo("MapFileAndCheckSum: Checksum calculated = 0x" & Hex($aresult[2], 8) & @CRLF)
	Return $aresult
EndFunc

Func _fixchecksum($input, $checksumposition, $correctchecksum)
	_displayinfo("FixChecksum: Writing updated checksum.." & @CRLF)
	Local $nbytes
	$correctchecksum = Hex($correctchecksum, 8)
	$correctchecksum = "0x" & StringMid($correctchecksum, 7, 2) & StringMid($correctchecksum, 5, 2) & StringMid($correctchecksum, 3, 2) & StringMid($correctchecksum, 1, 2)
	_winapi_setfilepointer($input, $checksumposition)
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & 4 & "]")
	DllStructSetData($tbuffer, 1, $correctchecksum)
	_winapi_writefile($input, DllStructGetPtr($tbuffer), 4, $nbytes)
EndFunc

Func _grantfileaccess($exe)
	_displayinfo("GrantFileAccess: Attemting to alter file permission.." & @CRLF)
	If @OSBuild >= 6000 Then
		Run(@ComSpec & " /c " & @WindowsDir & "\system32\takeown.exe /f " & $exe, "", @SW_HIDE)
		Run(@ComSpec & " /c " & @WindowsDir & "\system32\icacls.exe " & $exe & " /grant *S-1-5-32-544:F", "", @SW_HIDE)
		Return
	EndIf
EndFunc

Func _retrycreatefile($file)
	$hfile = _winapi_createfile("\\.\" & $file, 2, 6, 7)
	$lasterror = _winapi_getlasterror()
	If $lasterror <> 0 Then
		_displayinfo("RetryCreateFile: Error - Function CreateFile returned yet an error. This time error code: " & $lasterror & @CRLF)
		Return $hfile
	Else
		If $lasterror = 0 Then
			Return $hfile
		EndIf
	EndIf
EndFunc

Func _setcontrols()
	GUICtrlSetState($button_method1, $gui_enable)
EndFunc

Func _deactivatecontrols()
	GUICtrlSetState($button_method1, $gui_disable)
	GUICtrlSetState($button0, $gui_disable)
	GUICtrlSetState($button1, $gui_disable)
	GUICtrlSetState($obfuscationbutton, $gui_disable)
EndFunc
