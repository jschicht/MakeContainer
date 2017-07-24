#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container inside Portable Executable
#AutoIt3Wrapper_Res_Description=Injects data into the resource section
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#EndRegion

#include <WinAPI.au3>
#include <WinAPIRes.au3>
#include <String.au3>

Global Const $tagimage_dos_header = "char Magic[2];ushort BytesOnLastPage;ushort Pages;ushort Relocations;ushort SizeofHeader;ushort MinimumExtra;ushort MaximumExtra;ushort SS;ushort SP;ushort Checksum;ushort IP;ushort CS;ushort Relocation;ushort Overlay;char Reserved[8];ushort OEMIdentifier;ushort OEMInformation;char Reserved2[20];dword AddressOfNewExeHeader"
Global Const $tagimage_file_header = "dword Signature;ushort Machine;ushort NumberOfSections;dword TimeDateStamp;dword PointerToSymbolTable;dword NumberOfSymbols;ushort SizeOfOptionalHeader;ushort Characteristics"
Global Const $tagresourcedirectory = "dword Characteristics;dword TimeDateStamp;word MajorVersion;word MinorVersion;word NumberOfNamedEntries;word NumberOfIdEntries"
Global Const $tagresourcedirectoryentry = "dword Name;dword OffsetToData"
Global Const $tagresourcedataentry = "dword OffsetToData;dword Size;dword CodePage;dword Reserved"
Dim $nbytes

ConsoleWrite("MakeContainer-PEResource v1.0.0.3 -  by Joakim Schicht")
$file = FileOpenDialog("Select Portable Executable container", @ScriptDir, "Executables (*.exe;*.dll;*.sys;*.mui;*.com)")
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
;$rand = Hex(Random(0, 65535, 1), 4)
$rand = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
$newoutputname = $file & "." & $rand & "." & $fileextension
$file2 = FileOpenDialog("Select payload", @ScriptDir, "All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $file2 & @CRLF)

$ResValues = InputBox("Set Resource Type and Language", "Examples:" & @CRLF & "RT_RCDATA,0" & @CRLF & "RT_BITMAP,1033" _
				& @CRLF & "RT_ACCELERATOR,0" & @CRLF & "RT_ANICURSOR,1033" & @CRLF & "RT_ANIICON,0" & @CRLF & "RT_CURSOR,1033" _
				& @CRLF & "RT_DIALOG,0" & @CRLF & "RT_DLGINCLUDE,1033" & @CRLF & "RT_FONT,0" & @CRLF & "RT_FONTDIR,1033" _
				& @CRLF & "RT_GROUP_CURSOR,0" & @CRLF & "RT_GROUP_ICON,1033" & @CRLF & "RT_HTML,0" & @CRLF & "RT_ICON,1033" _
				& @CRLF & "RT_MANIFEST,0" & @CRLF & "RT_MENU,1033" & @CRLF & "RT_MESSAGETABLE,0" & @CRLF & "RT_PLUGPLAY,1033" _
				& @CRLF & "RT_STRING,0" & @CRLF & "RT_VERSION,1033" & @CRLF & "RT_VXD,0", "RT_RCDATA,0")
If @error Then Exit
$ResValues = StringSplit($ResValues,",")
If Not IsArray($ResValues) Then
	MsgBox(0, "Error", "Input not well formed")
	Exit
EndIf
If $ResValues[0] <> 2 Then
	MsgBox(0, "Error", "Input not well formed")
	Exit
EndIf
$resourcetypestring = $ResValues[1]
$resourcelanguage = $ResValues[2]

Select
	Case $resourcetypestring = "RT_RCDATA"
		$resourcetype = $RT_RCDATA
	Case $resourcetypestring = "RT_BITMAP"
		$resourcetype = $RT_BITMAP
	Case $resourcetypestring = "RT_ACCELERATOR"
		$resourcetype = $RT_ACCELERATOR
	Case $resourcetypestring = "RT_ANICURSOR"
		$resourcetype = $RT_ANICURSOR
	Case $resourcetypestring = "RT_ANIICON"
		$resourcetype = $RT_ANIICON
	Case $resourcetypestring = "RT_CURSOR"
		$resourcetype = $RT_CURSOR
	Case $resourcetypestring = "RT_DIALOG"
		$resourcetype = $RT_DIALOG
	Case $resourcetypestring = "RT_DLGINCLUDE"
		$resourcetype = $RT_DLGINCLUDE
	Case $resourcetypestring = "RT_FONT"
		$resourcetype = $RT_FONT
	Case $resourcetypestring = "RT_FONTDIR"
		$resourcetype = $RT_FONTDIR
	Case $resourcetypestring = "RT_GROUP_CURSOR"
		$resourcetype = $RT_GROUP_CURSOR
	Case $resourcetypestring = "RT_GROUP_ICON"
		$resourcetype = $RT_GROUP_ICON
	Case $resourcetypestring = "RT_HTML"
		$resourcetype = $RT_HTML
	Case $resourcetypestring = "RT_ICON"
		$resourcetype = $RT_ICON
	Case $resourcetypestring = "RT_MANIFEST"
		$resourcetype = $RT_MANIFEST
	Case $resourcetypestring = "RT_MENU"
		$resourcetype = $RT_MENU
	Case $resourcetypestring = "RT_MESSAGETABLE"
		$resourcetype = $RT_MESSAGETABLE
	Case $resourcetypestring = "RT_PLUGPLAY"
		$resourcetype = $RT_PLUGPLAY
	Case $resourcetypestring = "RT_STRING"
		$resourcetype = $RT_STRING
	Case $resourcetypestring = "RT_VERSION"
		$resourcetype = $RT_VERSION
	Case $resourcetypestring = "RT_VXD"
		$resourcetype = $RT_VXD
	Case Else
		MsgBox(0, "Error", "Resource type not yet supported")
		Exit
EndSelect
;The id could just as well be optional on input instead of picking from random
$resourcenameorid = Random(1, 2000, 1)
ConsoleWrite("$resourcetypestring: " & $resourcetypestring & @CRLF)
ConsoleWrite("$resourcetype: " & $resourcetype & @CRLF)
ConsoleWrite("$resourcenameorid: " & $resourcenameorid & @CRLF)

$filesize2 = FileGetSize($file2)
$filesize = FileGetSize($file)
ConsoleWrite("$FileSize: " & $filesize & @CRLF)
$filesizemod = $filesize
$bufferwholefilepayload = DllStructCreate("byte[" & $filesize2 & "]")
$hfilepayload = _winapi_createfile("\\.\" & $file2, 2, 2, 2)
If NOT $hfilepayload Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$readpayload = _winapi_readfile($hfilepayload, DllStructGetPtr($bufferwholefilepayload), DllStructGetSize($bufferwholefilepayload), $nbytes)
If NOT $readpayload Then
	MsgBox(0, "Error", "ReadFile failed")
	Exit
EndIf
$hfilecontainer = _winapi_createfile("\\.\" & $file, 2, 6, 7)
If NOT $hfilecontainer Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$hfileoutput = _winapi_createfile("\\.\" & $newoutputname, 1, 6, 2)
If NOT $hfileoutput Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize)
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
_winapi_closehandle($hfileoutput)
_winapi_closehandle($hfilecontainer)
$resupdate = _updateresource($newoutputname, $resourcetype, $resourcenameorid, $resourcelanguage, $bufferwholefilepayload)
If NOT $resupdate Then
	MsgBox(0, "Error", "_UpdateResource() failed 1")
	Exit
EndIf
$retrievedsectioninfo = _getsectioninfo($newoutputname, "RESOURCE")
If NOT @error Then
	ConsoleWrite("$RetrievedSectionInfo[0]: " & $retrievedsectioninfo[0] & @CRLF)
	ConsoleWrite("$RetrievedSectionInfo[3]: " & $retrievedsectioninfo[3] & @CRLF)
	ConsoleWrite("$RetrievedSectionInfo[4]: " & $retrievedsectioninfo[4] & @CRLF)
Else
	ConsoleWrite("Error: Function _GetSectionInfo() Failed 1" & @CRLF)
	MsgBox(0, "Error", "Function _GetSectionInfo() Failed 1")
	Exit
EndIf
$foundresourceoffset = _decoderesourcesection($newoutputname, $retrievedsectioninfo[4], $retrievedsectioninfo[3], $resourcetypestring, $resourcenameorid, $resourcelanguage)
If $foundresourceoffset Then
	ConsoleWrite("Resource found at Virtual Address: 0x" & Hex($foundresourceoffset, 8) & @CRLF)
Else
	ConsoleWrite("Error: Resource not found 1" & @CRLF)
	MsgBox(0, "Error", "Resource not found 1")
	Exit
EndIf
$resourcerawaddress = $foundresourceoffset - $retrievedsectioninfo[2] + $retrievedsectioninfo[4]
ConsoleWrite("Raw Address: 0x" & Hex($resourcerawaddress, 8) & @CRLF)
If NOT Mod($resourcerawaddress, 512) Then
	MsgBox(0, "Finished", "Job done")
	Exit
EndIf
$fillcounter = 0
$fillbytes = ""
If Mod($resourcerawaddress, 512) Then
	Do
		$fillcounter += 1
		$resourcerawaddress += 1
		$fillbytes &= Hex(Random(0, 255, 1), 2)
	Until Mod($resourcerawaddress, 512) = 0
EndIf
ConsoleWrite("Needed padding bytes: " & $fillcounter & @CRLF)
ConsoleWrite("Correct Resource Raw Address should be: 0x" & Hex($resourcerawaddress, 8) & @CRLF)
$bufferpaddingandpayload = DllStructCreate("byte[" & $filesize2 + $fillcounter & "]")
DllStructSetData($bufferpaddingandpayload, 1, "0x" & $fillbytes & StringMid(DllStructGetData($bufferwholefilepayload, 1), 3))
Sleep(1000)
$resupdate = _updateresource($newoutputname, $resourcetype, $resourcenameorid, $resourcelanguage, $bufferpaddingandpayload)
If NOT $resupdate Then
	MsgBox(0, "Error", "_UpdateResource() failed 2")
	Exit
EndIf
$retrievedsectioninfo = _getsectioninfo($newoutputname, "RESOURCE")
If NOT @error Then
Else
	ConsoleWrite("Error: Function _GetSectionInfo() failed 2" & @CRLF)
	MsgBox(0, "Error", "Function _GetSectionInfo() failed 2")
	Exit
EndIf
$foundresourceoffset = _decoderesourcesection($newoutputname, $retrievedsectioninfo[4], $retrievedsectioninfo[3], $resourcetypestring, $resourcenameorid, $resourcelanguage)
If $foundresourceoffset Then
	ConsoleWrite("Resource found at Virtual Address: 0x" & Hex($foundresourceoffset, 8) & @CRLF)
Else
	ConsoleWrite("Error: Resource not found 2" & @CRLF)
	MsgBox(0, "Error", "Resource not found 2")
	Exit
EndIf
$resourcerawaddress = $foundresourceoffset - $retrievedsectioninfo[2] + $retrievedsectioninfo[4]
ConsoleWrite("Raw Address: 0x" & Hex($resourcerawaddress, 8) & @CRLF)
$batchfilename = $newoutputname & ".bat"
$hbatchfile = FileOpen($batchfilename, 2)
If NOT $hbatchfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$samplecmdline = "VeraCrypt.exe /v " & '"' & $newoutputname & '"' & " /l x /a /p password /i " & $resourcerawaddress + $fillcounter
FileWriteLine($hbatchfile, $samplecmdline)
FileClose($hbatchfile)
MsgBox(0, "Finished", "Job done")
Exit

Func _updateresource($resourcefilename, $targetrestype, $resourcenameorid, $resourcelanguage, $buffernewresource)
	Local $discardchanges = 0
	Local $hupdate = _winapi_beginupdateresource($resourcefilename, 0)
	If NOT $hupdate Then
		ConsoleWrite("Error: BeginUpdateResource failed" & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Local $updated = _winapi_updateresource($hupdate, $targetrestype, $resourcenameorid, $resourcelanguage, DllStructGetPtr($buffernewresource), DllStructGetSize($buffernewresource))
	If NOT $updated Then
		ConsoleWrite("Error: UpdateResource failed" & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Local $ret = _winapi_endupdateresource($hupdate, $discardchanges)
	If NOT $ret Then
		ConsoleWrite("Error: EndUpdateResource failed" & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc

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

Func _detectarch($data)
	$localoffset = 3
	$addressofnewexeheader = StringMid($data, $localoffset + 120, 8)
	$addressofnewexeheader = Dec(_swapendian($addressofnewexeheader))
	$magic = StringMid($data, $localoffset + ($addressofnewexeheader * 2) + 48, 4)
	$magic = Dec(_swapendian($magic))
	Select
		Case $magic = 523
			Return "PE64"
		Case $magic = 267
			Return "PE32"
		Case $magic = 263
			Return "ROM"
		Case Else
			Return "UNKNOWN"
	EndSelect
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

Func _getsectioninfo($file, $targetdirectory)
	Local $nbytes
	Local $tbuff = DllStructCreate("byte[512]")
	$offset = 0
	$hfilecontainer = _winapi_createfile("\\.\" & $file, 2, 6, 7)
	If NOT $hfilecontainer Then
		MsgBox(0, "Error", "Could not open file")
		Exit
	EndIf
	$filesize = FileGetSize($file)
	ConsoleWrite("$FileSize: " & $filesize & @CRLF)
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($tbuff), DllStructGetSize($tbuff), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$outdata = DllStructGetData($tbuff, 1)
	ConsoleWrite(_hexencode($outdata) & @CRLF)
	$arch = _detectarch($outdata)
	If $arch <> "PE32" AND $arch <> "PE64" Then
		MsgBox(0, "Error", "Unknown PE")
		Exit
	EndIf
	ConsoleWrite("Detected arch: " & $arch & @CRLF)
	If $arch = "PE64" Then
		$type_regionsize = "UINT64"
		$type_dwsize = "UINT64"
		$ptrsizetext = "UINT64"
		$ptrsizedigit = 16
		$baseofdatasize = 0
		$tagimage_optional_header = "ushort Magic;" & "ubyte MajorLinkerVersion;" & "ubyte MinorLinkerVersion;" & "dword SizeOfCode;" & "dword SizeOfInitializedData;" & "dword SizeOfUninitializedData;" & "dword AddressOfEntryPoint;" & "dword BaseOfCode;" & "uint64 ImageBase;" & "dword SectionAlignment;" & "dword FileAlignment;" & "ushort MajorOperatingSystemVersion;" & "ushort MinorOperatingSystemVersion;" & "ushort MajorImageVersion;" & "ushort MinorImageVersion;" & "ushort MajorSubsystemVersion;" & "ushort MinorSubsystemVersion;" & "dword Win32VersionValue;" & "dword SizeOfImage;" & "dword SizeOfHeaders;" & "dword CheckSum;" & "ushort Subsystem;" & "ushort DllCharacteristics;" & "uint64 SizeOfStackReserve;" & "uint64 SizeOfStackCommit;" & "uint64 SizeOfHeapReserve;" & "uint64 SizeOfHeapCommit;" & "dword LoaderFlags;" & "dword NumberOfRvaAndSizes"
	Else
		$type_regionsize = "UINT"
		$type_dwsize = "UINT"
		$ptrsizetext = "dword"
		$ptrsizedigit = 8
		$baseofdatasize = 4
		$tagimage_optional_header = "ushort Magic;" & "ubyte MajorLinkerVersion;" & "ubyte MinorLinkerVersion;" & "dword SizeOfCode;" & "dword SizeOfInitializedData;" & "dword SizeOfUninitializedData;" & "dword AddressOfEntryPoint;" & "dword BaseOfCode;" & "dword BaseOfData;" & "dword ImageBase;" & "dword SectionAlignment;" & "dword FileAlignment;" & "ushort MajorOperatingSystemVersion;" & "ushort MinorOperatingSystemVersion;" & "ushort MajorImageVersion;" & "ushort MinorImageVersion;" & "ushort MajorSubsystemVersion;" & "ushort MinorSubsystemVersion;" & "dword Win32VersionValue;" & "dword SizeOfImage;" & "dword SizeOfHeaders;" & "dword CheckSum;" & "ushort Subsystem;" & "ushort DllCharacteristics;" & "dword SizeOfStackReserve;" & "dword SizeOfStackCommit;" & "dword SizeOfHeapReserve;" & "dword SizeOfHeapCommit;" & "dword LoaderFlags;" & "dword NumberOfRvaAndSizes"
	EndIf
	$pimage_dos_header = DllStructCreate($tagimage_dos_header)
	_winapi_setfilepointer($hfilecontainer, $offset)
	$read = 0
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($pimage_dos_header), DllStructGetSize($pimage_dos_header), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$pestart = DllStructGetData($pimage_dos_header, "AddressOfNewExeHeader")
	ConsoleWrite("$PEStart: 0x" & Hex($pestart, 8) & @CRLF & @CRLF)
	$offset += $pestart
	_winapi_setfilepointer($hfilecontainer, $offset)
	$pimage_file_header = DllStructCreate($tagimage_file_header)
	$read = 0
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($pimage_file_header), DllStructGetSize($pimage_file_header), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$signature = DllStructGetData($pimage_file_header, "Signature")
	$machine = DllStructGetData($pimage_file_header, "Machine")
	$numberofsections = DllStructGetData($pimage_file_header, "NumberOfSections")
	$timedatestamp = DllStructGetData($pimage_file_header, "TimeDateStamp")
	$pointertosymboltable = DllStructGetData($pimage_file_header, "PointerToSymbolTable")
	$numberofsymbols = DllStructGetData($pimage_file_header, "NumberOfSymbols")
	$sizeofoptionalheader = DllStructGetData($pimage_file_header, "SizeOfOptionalHeader")
	$offset += DllStructGetSize($pimage_file_header)
	_winapi_setfilepointer($hfilecontainer, $offset)
	$pimage_optional_header = DllStructCreate($tagimage_optional_header)
	$read = 0
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($pimage_optional_header), DllStructGetSize($pimage_optional_header), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$magic = DllStructGetData($pimage_optional_header, "Magic")
	$sizeofcode = DllStructGetData($pimage_optional_header, "SizeOfCode")
	$addressofentrypoint = DllStructGetData($pimage_optional_header, "AddressOfEntryPoint")
	$baseofcode = DllStructGetData($pimage_optional_header, "BaseOfCode")
	$imagebase = DllStructGetData($pimage_optional_header, "ImageBase")
	$sectionalignment = DllStructGetData($pimage_optional_header, "SectionAlignment")
	$sizeofimage = DllStructGetData($pimage_optional_header, "SizeOfImage")
	$sizeofheaders = DllStructGetData($pimage_optional_header, "SizeOfHeaders")
	$numberofrvaandsizes = DllStructGetData($pimage_optional_header, "NumberOfRvaAndSizes")
	$offset += DllStructGetSize($pimage_optional_header)
	_winapi_setfilepointer($hfilecontainer, $offset)
	$pimage_data_directories = DllStructCreate("dword EXPORT_RVA;" & "dword EXPORT_SIZE;" & "dword IMPORT_RVA;" & "dword IMPORT_SIZE;" & "dword RESOURCE_RVA;" & "dword RESOURCE_SIZE;" & "dword EXCEPTION_RVA;" & "dword EXCEPTION_SIZE;" & "dword SECURITY_RVA;" & "dword SECURITY_SIZE;" & "dword BASERELOC_RVA;" & "dword BASERELOC_SIZE;" & "dword DEBUG_RVA;" & "dword DEBUG_SIZE;" & "dword ARCHITECTURE_RVA;" & "dword ARCHITECTURE_SIZE;" & "dword GLOBALPTR_RVA;" & "dword GLOBALPTR_SIZE;" & "dword TLS_RVA;" & "dword TLS_SIZE;" & "dword LOAD_CONFIG_RVA;" & "dword LOAD_CONFIG_SIZE;" & "dword BOUND_IMPORT_RVA;" & "dword BOUND_IMPORT_SIZE;" & "dword IAT_RVA;" & "dword IAT_SIZE;" & "dword DELAY_IMPORT_RVA;" & "dword DELAY_IMPORT_SIZE;" & "dword COM_DESCRIPTOR_RVA;" & "dword COM_DESCRIPTOR_SIZE")
	$read = 0
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($pimage_data_directories), DllStructGetSize($pimage_data_directories), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$export_rva = DllStructGetData($pimage_data_directories, "EXPORT_RVA")
	$export_size = DllStructGetData($pimage_data_directories, "EXPORT_SIZE")
	$import_rva = DllStructGetData($pimage_data_directories, "IMPORT_RVA")
	$import_size = DllStructGetData($pimage_data_directories, "IMPORT_SIZE")
	$resource_rva = DllStructGetData($pimage_data_directories, "RESOURCE_RVA")
	$resource_size = DllStructGetData($pimage_data_directories, "RESOURCE_SIZE")
	$exception_rva = DllStructGetData($pimage_data_directories, "EXCEPTION_RVA")
	$exception_size = DllStructGetData($pimage_data_directories, "EXCEPTION_SIZE")
	$security_rva = DllStructGetData($pimage_data_directories, "SECURITY_RVA")
	$security_size = DllStructGetData($pimage_data_directories, "SECURITY_SIZE")
	$basereloc_rva = DllStructGetData($pimage_data_directories, "BASERELOC_RVA")
	$basereloc_size = DllStructGetData($pimage_data_directories, "BASERELOC_SIZE")
	$debug_rva = DllStructGetData($pimage_data_directories, "DEBUG_RVA")
	$debug_size = DllStructGetData($pimage_data_directories, "DEBUG_SIZE")
	$architecture_rva = DllStructGetData($pimage_data_directories, "ARCHITECTURE_RVA")
	$architecture_size = DllStructGetData($pimage_data_directories, "ARCHITECTURE_SIZE")
	$globalptr_rva = DllStructGetData($pimage_data_directories, "GLOBALPTR_RVA")
	$globalptr_size = DllStructGetData($pimage_data_directories, "GLOBALPTR_SIZE")
	$tls_rva = DllStructGetData($pimage_data_directories, "TLS_RVA")
	$tls_size = DllStructGetData($pimage_data_directories, "TLS_SIZE")
	$load_config_rva = DllStructGetData($pimage_data_directories, "LOAD_CONFIG_RVA")
	$load_config_size = DllStructGetData($pimage_data_directories, "LOAD_CONFIG_SIZE")
	$bound_import_rva = DllStructGetData($pimage_data_directories, "BOUND_IMPORT_RVA")
	$bound_import_size = DllStructGetData($pimage_data_directories, "BOUND_IMPORT_SIZE")
	$iat_rva = DllStructGetData($pimage_data_directories, "IAT_RVA")
	$iat_size = DllStructGetData($pimage_data_directories, "IAT_SIZE")
	$delay_import_rva = DllStructGetData($pimage_data_directories, "DELAY_IMPORT_RVA")
	$delay_import_size = DllStructGetData($pimage_data_directories, "DELAY_IMPORT_SIZE")
	$com_descriptor_rva = DllStructGetData($pimage_data_directories, "COM_DESCRIPTOR_RVA")
	$com_descriptor_size = DllStructGetData($pimage_data_directories, "COM_DESCRIPTOR_SIZE")
	Select
		Case $targetdirectory = "EXPORT"
			$targetdirectoryrva = $export_rva
			$targetdirectorysize = $export_size
		Case $targetdirectory = "IMPORT"
			$targetdirectoryrva = $import_rva
			$targetdirectorysize = $import_size
		Case $targetdirectory = "RESOURCE"
			$targetdirectoryrva = $resource_rva
			$targetdirectorysize = $resource_size
		Case $targetdirectory = "EXCEPTION"
			$targetdirectoryrva = $exception_rva
			$targetdirectorysize = $exception_size
		Case $targetdirectory = "SECURITY"
			$targetdirectoryrva = $security_rva
			$targetdirectorysize = $security_size
		Case $targetdirectory = "BASERELOC"
			$targetdirectoryrva = $basereloc_rva
			$targetdirectorysize = $basereloc_size
		Case $targetdirectory = "DEBUG"
			$targetdirectoryrva = $debug_rva
			$targetdirectorysize = $debug_size
		Case $targetdirectory = "ARCHITECTURE"
			$targetdirectoryrva = $architecture_rva
			$targetdirectorysize = $architecture_size
		Case $targetdirectory = "GLOBALPTR"
			$targetdirectoryrva = $globalptr_rva
			$targetdirectorysize = $globalptr_size
		Case $targetdirectory = "TLS"
			$targetdirectoryrva = $tls_rva
			$targetdirectorysize = $tls_size
		Case $targetdirectory = "LOAD_CONFIG"
			$targetdirectoryrva = $load_config_rva
			$targetdirectorysize = $load_config_size
		Case $targetdirectory = "BOUND_IMPORT"
			$targetdirectoryrva = $bound_import_rva
			$targetdirectorysize = $bound_import_size
		Case $targetdirectory = "IAT"
			$targetdirectoryrva = $iat_rva
			$targetdirectorysize = $iat_size
		Case $targetdirectory = "DELAY_IMPORT"
			$targetdirectoryrva = $delay_import_rva
			$targetdirectorysize = $delay_import_size
		Case $targetdirectory = "COM_DESCRIPTOR"
			$targetdirectoryrva = $com_descriptor_rva
			$targetdirectorysize = $com_descriptor_size
		Case Else
			MsgBox(0, "Error", "Function _GetSectionInfo() received unknown Data Directory member as input")
			Exit
	EndSelect
	$datadirectoryoffset = $offset + ($numberofrvaandsizes * 8)
	_winapi_setfilepointer($hfilecontainer, $datadirectoryoffset)
	ConsoleWrite("$DataDirectoryOffset: 0x" & Hex($datadirectoryoffset, 8) & @CRLF)
	If Mod($datadirectoryoffset, 8) Then
		Do
			$datadirectoryoffset += 1
		Until Mod($datadirectoryoffset, 4) = 0
	EndIf
	ConsoleWrite("$DataDirectoryOffset: 0x" & Hex($datadirectoryoffset, 8) & @CRLF)
	$tbuff = 0
	$tbuff = DllStructCreate("byte[" & $numberofsections * 40 & "]")
	$read = 0
	$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($tbuff), DllStructGetSize($tbuff), $nbytes)
	If $read = 0 Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$outdata = DllStructGetData($tbuff, 1)
	ConsoleWrite(_hexencode($outdata) & @CRLF)
	$testbuff = DllStructGetPtr($tbuff)
	Dim $sectionsinfo[10]
	$sectionfound = 0
	For $i = 1 To $numberofsections
		$psectionstable = DllStructCreate("byte Name[8];" & "dword VIRTUAL_SIZE;" & "dword VIRTUAL_ADDRESS;" & "dword RAW_SIZE;" & "dword RAW_ADDRESS;" & "dword RELOC_ADDRESS;" & "dword Linenumbers;" & "word RelocationsNumber;" & "word LinenumbersNumber;" & "dword Characteristics", $testbuff)
		$sectionnamehex = Hex(DllStructGetData($psectionstable, "Name"))
		$virtual_size = DllStructGetData($psectionstable, "VIRTUAL_SIZE")
		$virtual_address = DllStructGetData($psectionstable, "VIRTUAL_ADDRESS")
		$raw_size = DllStructGetData($psectionstable, "RAW_SIZE")
		$raw_address = DllStructGetData($psectionstable, "RAW_ADDRESS")
		$reloc_address = DllStructGetData($psectionstable, "RELOC_ADDRESS")
		$linenumbers = DllStructGetData($psectionstable, "Linenumbers")
		$relocationsnumber = DllStructGetData($psectionstable, "RelocationsNumber")
		$linenumbersnumber = DllStructGetData($psectionstable, "LinenumbersNumber")
		$characteristics = DllStructGetData($psectionstable, "Characteristics")
		Do
			$sectionnamehex = StringTrimRight($sectionnamehex, 2)
		Until StringRight($sectionnamehex, 2) <> "00"
		$sectionname = _hextostring("0x" & $sectionnamehex)
		ConsoleWrite("Section: " & $i & @CRLF)
		If ($virtual_size = $targetdirectorysize) AND ($virtual_address = $targetdirectoryrva) Then
			$sectionfound = 1
			$sectionsinfo[0] = $sectionname
			$sectionsinfo[1] = $virtual_size
			$sectionsinfo[2] = $virtual_address
			$sectionsinfo[3] = $raw_size
			$sectionsinfo[4] = $raw_address
			$sectionsinfo[5] = $reloc_address
			$sectionsinfo[6] = $linenumbers
			$sectionsinfo[7] = $relocationsnumber
			$sectionsinfo[7] = $linenumbersnumber
			$sectionsinfo[8] = $characteristics
			ExitLoop
		EndIf
		$testbuff += 40
	Next
	If NOT $sectionfound Then
		MsgBox(0, "Error", "Section not found")
		_winapi_closehandle($hfilecontainer)
		Return SetError(1, 0, 0)
	Else
		_winapi_closehandle($hfilecontainer)
		Return $sectionsinfo
	EndIf
EndFunc

Func _decoderesourcesection($filename, $sectionoffset, $sectionsize, $targetresourcetype, $targetresourceid, $targetresourcelanguage)
	Local $nbytes, $currentoffset
	Local $tbuff = DllStructCreate("byte[" & $sectionsize & "]")
	$currentoffset = $sectionoffset
	$hfile = _winapi_createfile("\\.\" & $filename, 2, 6, 7)
	If NOT $hfile Then
		MsgBox(0, "Error", "Could not open file")
		Exit
	EndIf
	_winapi_setfilepointer($hfile, $currentoffset)
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuff), DllStructGetSize($tbuff), $nbytes)
	If NOT $read Then
		MsgBox(0, "Error", "ReadFile failed")
		Exit
	EndIf
	$tbuffcontinue = DllStructGetPtr($tbuff)
	$tbuffcontinue2 = DllStructGetPtr($tbuff)
	$tbuffcontinue3 = DllStructGetPtr($tbuff)
	$presourcedirectorystart = DllStructGetPtr($tbuff)
	Local $presourcedirectory = DllStructCreate($tagresourcedirectory, $tbuffcontinue)
	$characteristics = DllStructGetData($presourcedirectory, "Characteristics")
	$timedatestamp = DllStructGetData($presourcedirectory, "TimeDateStamp")
	$majorversion = DllStructGetData($presourcedirectory, "MajorVersion")
	$minorversion = DllStructGetData($presourcedirectory, "MinorVersion")
	$numberofnamedentries = DllStructGetData($presourcedirectory, "NumberOfNamedEntries")
	$numberofidentries = DllStructGetData($presourcedirectory, "NumberOfIdEntries")
	$tbuffcontinue += DllStructGetSize($presourcedirectory)
	Local $tbuff2 = DllStructCreate("byte[" & ($numberofnamedentries + $numberofidentries) * 8 & "]", $tbuffcontinue)
	$resourcedirectorydata = DllStructGetData($tbuff2, 1)
	$totalsections = $numberofnamedentries + $numberofidentries
	For $i = 1 To $totalsections
		$presourcedirectoryentry = DllStructCreate($tagresourcedirectoryentry, $tbuffcontinue)
		$name = DllStructGetData($presourcedirectoryentry, "Name")
		$offsettodata = DllStructGetData($presourcedirectoryentry, "OffsetToData")
		$offsettodata = Dec(StringTrimLeft(Hex($offsettodata, 8), 2))
		$resolvedresourcetype = _getresourcetype($name)
		$presourcedirectory2 = DllStructCreate($tagresourcedirectory, $presourcedirectorystart + $offsettodata)
		$characteristics2 = DllStructGetData($presourcedirectory2, "Characteristics")
		$timedatestamp2 = DllStructGetData($presourcedirectory2, "TimeDateStamp")
		$majorversion2 = DllStructGetData($presourcedirectory2, "MajorVersion")
		$minorversion2 = DllStructGetData($presourcedirectory2, "MinorVersion")
		$numberofnamedentries2 = DllStructGetData($presourcedirectory2, "NumberOfNamedEntries")
		$numberofidentries2 = DllStructGetData($presourcedirectory2, "NumberOfIdEntries")
		$totalsections2 = $numberofnamedentries2 + $numberofidentries2
		For $j = 1 To $totalsections2
			$presourcedirectoryentry2 = DllStructCreate($tagresourcedirectoryentry, $tbuffcontinue2 + $offsettodata + DllStructGetSize($presourcedirectory2))
			$name2 = DllStructGetData($presourcedirectoryentry2, "Name")
			$offsettodata2 = DllStructGetData($presourcedirectoryentry2, "OffsetToData")
			$offsettodata2 = Dec(StringTrimLeft(Hex($offsettodata2, 8), 2))
			$testoffset = $sectionoffset + Int(($tbuffcontinue2 + $offsettodata + DllStructGetSize($presourcedirectory2)) - $presourcedirectorystart)
			$presourcedirectory3 = DllStructCreate($tagresourcedirectory, $presourcedirectorystart + $offsettodata2)
			$characteristics3 = DllStructGetData($presourcedirectory3, "Characteristics")
			$timedatestamp3 = DllStructGetData($presourcedirectory3, "TimeDateStamp")
			$majorversion3 = DllStructGetData($presourcedirectory3, "MajorVersion")
			$minorversion3 = DllStructGetData($presourcedirectory3, "MinorVersion")
			$numberofnamedentries3 = DllStructGetData($presourcedirectory3, "NumberOfNamedEntries")
			$numberofidentries3 = DllStructGetData($presourcedirectory3, "NumberOfIdEntries")
			$totalsections3 = $numberofnamedentries3 + $numberofidentries3
			For $k = 1 To $totalsections3
				$presourcedirectoryentry3 = DllStructCreate($tagresourcedirectoryentry, $tbuffcontinue3 + $offsettodata2 + DllStructGetSize($presourcedirectory3))
				$name3 = DllStructGetData($presourcedirectoryentry3, "Name")
				$offsettodata3 = DllStructGetData($presourcedirectoryentry3, "OffsetToData")
				$testoffset2 = $sectionoffset + Int(($tbuffcontinue3 + $offsettodata2 + DllStructGetSize($presourcedirectory3)) - $presourcedirectorystart)
				$presourcedataentry = DllStructCreate($tagresourcedataentry, $presourcedirectorystart + $offsettodata3)
				$rdeoffsettodata = DllStructGetData($presourcedataentry, "OffsetToData")
				$rdesize = DllStructGetData($presourcedataentry, "Size")
				$rdecodepage = DllStructGetData($presourcedataentry, "CodePage")
				$rdereserved = DllStructGetData($presourcedataentry, "Reserved")
				If ($resolvedresourcetype = $targetresourcetype) AND ($name2 = $targetresourceid) AND ($name3 = $targetresourcelanguage) Then
					_winapi_closehandle($hfile)
					Return $rdeoffsettodata
				EndIf
			Next
			$tbuffcontinue2 += 8
		Next
		$tbuffcontinue2 = $tbuffcontinue2 - ($totalsections2 * 8)
		$tbuffcontinue += 8
	Next
	_winapi_closehandle($hfile)
	Return SetError(1, 0, 0)
EndFunc

Func _getresourcetype($input)
	Select
		Case $input = 9
			Return "RT_ACCELERATOR"
		Case $input = 21
			Return "RT_ANICURSOR"
		Case $input = 22
			Return "RT_ANIICON"
		Case $input = 2
			Return "RT_BITMAP"
		Case $input = 1
			Return "RT_CURSOR"
		Case $input = 5
			Return "RT_DIALOG"
		Case $input = 17
			Return "RT_DLGINCLUDE"
		Case $input = 8
			Return "RT_FONT"
		Case $input = 7
			Return "RT_FONTDIR"
		Case $input = 12
			Return "RT_GROUP_CURSOR"
		Case $input = 14
			Return "RT_GROUP_ICON"
		Case $input = 23
			Return "RT_HTML"
		Case $input = 3
			Return "RT_ICON"
		Case $input = 24
			Return "RT_MANIFEST"
		Case $input = 4
			Return "RT_MENU"
		Case $input = 11
			Return "RT_MESSAGETABLE"
		Case $input = 19
			Return "RT_PLUGPLAY"
		Case $input = 10
			Return "RT_RCDATA"
		Case $input = 6
			Return "RT_STRING"
		Case $input = 16
			Return "RT_VERSION"
		Case $input = 20
			Return "RT_VXD"
		Case Else
			Return "UNKNOWN"
	EndSelect
EndFunc
