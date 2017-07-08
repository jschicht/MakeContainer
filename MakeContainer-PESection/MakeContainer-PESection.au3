#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Will hide VeraCrypt container inside a Portable Executable
#AutoIt3Wrapper_Res_Description=It injects data by manipulating the Sections Table
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#EndRegion

#include <WinAPI.au3>
#include <String.au3>

Dim $nbytes
Global Const $tagimage_dos_header = "char Magic[2];ushort BytesOnLastPage;ushort Pages;ushort Relocations;ushort SizeofHeader;ushort MinimumExtra;ushort MaximumExtra;ushort SS;ushort SP;ushort Checksum;ushort IP;ushort CS;ushort Relocation;ushort Overlay;char Reserved[8];ushort OEMIdentifier;ushort OEMInformation;char Reserved2[20];dword AddressOfNewExeHeader"
Global Const $tagimage_file_header = "dword Signature;ushort Machine;ushort NumberOfSections;dword TimeDateStamp;dword PointerToSymbolTable;dword NumberOfSymbols;ushort SizeOfOptionalHeader;ushort Characteristics"
$tbuff = DllStructCreate("byte[512]")
$offset = 0

ConsoleWrite("MakeContainer-PESection v1.0.0.3 - by Joakim Schicht")
$file2 = FileOpenDialog("Select payload", @ScriptDir, "All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $file2 & @CRLF)
$filesize2 = FileGetSize($file2)
$payloadsize = $filesize2
ConsoleWrite("$FileSize2: " & $filesize2 & @CRLF)
$fillcounter = 0
If Mod($filesize2, 512) Then
	Do
		$fillcounter += 1
		$filesize2 += 1
	Until Mod($filesize2, 512) = 0
EndIf
ConsoleWrite("$FileSize2: " & $filesize2 & @CRLF)
$file = FileOpenDialog("Select PE as container", @ScriptDir, "All (*.*)")
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
ConsoleWrite("Offset file header: 0x" & Hex($offset, 8) & @CRLF)
ConsoleWrite("$Signature: 0x" & Hex($signature, 8) & @CRLF)
ConsoleWrite("$Machine: 0x" & Hex($machine, 4) & @CRLF)
ConsoleWrite("$NumberOfSections: 0x" & Hex($numberofsections, 4) & @CRLF)
ConsoleWrite("$TimeDateStamp: 0x" & Hex($timedatestamp, 8) & @CRLF)
ConsoleWrite("$PointerToSymbolTable: 0x" & Hex($pointertosymboltable, 8) & @CRLF)
ConsoleWrite("$NumberOfSymbols: 0x" & Hex($numberofsymbols, 8) & @CRLF)
ConsoleWrite("$SizeOfOptionalHeader: 0x" & Hex($sizeofoptionalheader, 4) & @CRLF & @CRLF)
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
ConsoleWrite("Offset optional header: 0x" & Hex($offset, 8) & @CRLF)
ConsoleWrite("$Magic: 0x" & Hex($magic, 4) & @CRLF)
ConsoleWrite("$SizeOfCode: 0x" & Hex($sizeofcode, 8) & @CRLF)
ConsoleWrite("$AddressOfEntryPoint: 0x" & Hex($addressofentrypoint, 8) & @CRLF)
ConsoleWrite("$BaseOfCode: 0x" & Hex($baseofcode, 8) & @CRLF)
ConsoleWrite("$ImageBase: 0x" & Hex($imagebase, $ptrsizedigit) & @CRLF)
ConsoleWrite("$SectionAlignment: 0x" & Hex($sectionalignment, 8) & @CRLF)
ConsoleWrite("$SizeOfImage: 0x" & Hex($sizeofimage, 8) & @CRLF)
ConsoleWrite("$SizeOfHeaders: 0x" & Hex($sizeofheaders, 8) & @CRLF)
ConsoleWrite("$NumberOfRvaAndSizes: 0x" & Hex($numberofrvaandsizes, 8) & @CRLF & @CRLF)
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
ConsoleWrite("Offset data directory: 0x" & Hex($offset, 8) & @CRLF)
ConsoleWrite("$EXPORT_RVA: 0x" & Hex($export_rva, 8) & @CRLF)
ConsoleWrite("$EXPORT_SIZE: 0x" & Hex($export_size, 8) & @CRLF)
ConsoleWrite("$IMPORT_RVA: 0x" & Hex($import_rva, 8) & @CRLF)
ConsoleWrite("$IMPORT_SIZE: 0x" & Hex($import_size, 8) & @CRLF)
ConsoleWrite("$RESOURCE_RVA: 0x" & Hex($resource_rva, 8) & @CRLF)
ConsoleWrite("$RESOURCE_SIZE: 0x" & Hex($resource_size, 8) & @CRLF)
ConsoleWrite("$EXCEPTION_RVA: 0x" & Hex($exception_rva, 8) & @CRLF)
ConsoleWrite("$EXCEPTION_SIZE: 0x" & Hex($exception_size, 8) & @CRLF)
ConsoleWrite("$SECURITY_RVA: 0x" & Hex($security_rva, 8) & @CRLF)
ConsoleWrite("$SECURITY_SIZE: 0x" & Hex($security_size, 8) & @CRLF)
ConsoleWrite("$BASERELOC_RVA: 0x" & Hex($basereloc_rva, 8) & @CRLF)
ConsoleWrite("$BASERELOC_SIZE: 0x" & Hex($basereloc_size, 8) & @CRLF)
ConsoleWrite("$DEBUG_RVA: 0x" & Hex($debug_rva, 8) & @CRLF)
ConsoleWrite("$DEBUG_SIZE: 0x" & Hex($debug_size, 8) & @CRLF)
ConsoleWrite("$ARCHITECTURE_RVA: 0x" & Hex($architecture_rva, 8) & @CRLF)
ConsoleWrite("$ARCHITECTURE_SIZE: 0x" & Hex($architecture_size, 8) & @CRLF)
ConsoleWrite("$GLOBALPTR_RVA: 0x" & Hex($globalptr_rva, 8) & @CRLF)
ConsoleWrite("$GLOBALPTR_SIZE: 0x" & Hex($globalptr_size, 8) & @CRLF)
ConsoleWrite("$TLS_RVA: 0x" & Hex($tls_rva, 8) & @CRLF)
ConsoleWrite("$TLS_SIZE: 0x" & Hex($tls_size, 8) & @CRLF)
ConsoleWrite("$LOAD_CONFIG_RVA: 0x" & Hex($load_config_rva, 8) & @CRLF)
ConsoleWrite("$LOAD_CONFIG_SIZE: 0x" & Hex($load_config_size, 8) & @CRLF)
ConsoleWrite("$BOUND_IMPORT_RVA: 0x" & Hex($bound_import_rva, 8) & @CRLF)
ConsoleWrite("$BOUND_IMPORT_SIZE: 0x" & Hex($bound_import_size, 8) & @CRLF)
ConsoleWrite("$IAT_RVA: 0x" & Hex($iat_rva, 8) & @CRLF)
ConsoleWrite("$IAT_SIZE: 0x" & Hex($iat_size, 8) & @CRLF)
ConsoleWrite("$DELAY_IMPORT_RVA: 0x" & Hex($delay_import_rva, 8) & @CRLF)
ConsoleWrite("$DELAY_IMPORT_SIZE: 0x" & Hex($delay_import_size, 8) & @CRLF)
ConsoleWrite("$COM_DESCRIPTOR_RVA: 0x" & Hex($com_descriptor_rva, 8) & @CRLF)
ConsoleWrite("$COM_DESCRIPTOR_SIZE: 0x" & Hex($com_descriptor_size, 8) & @CRLF & @CRLF)
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
Dim $section[$numberofsections + 1]
$section[0] = $numberofsections
$testbuff = DllStructGetPtr($tbuff)
$newoutputname = $file & "." & $rand & "." & $fileextension
$hfileoutput = _winapi_createfile("\\.\" & $newoutputname, 1, 6, 2)
If NOT $hfileoutput Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $filesize + $filesize2)
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
$offsetofraw_address = $datadirectoryoffset + 20
$bufferrawaddress = DllStructCreate("align 1;byte[4]")
$targetsection = Random(2, $numberofsections, 1)
For $i = 1 To $numberofsections
	$psectionstable = DllStructCreate("byte Name[8];" & "dword VIRTUAL_SIZE;" & "dword VIRTUAL_ADDRESS;" & "dword RAW_SIZE;" & "dword RAW_ADDRESS;" & "dword RELOC_ADDRESS;" & "dword Linenumbers;" & "word RelocationsNumber;" & "word LinenumbersNumber;" & "dword Characteristics", $testbuff)
	$raw_address = DllStructGetData($psectionstable, "RAW_ADDRESS")
	$raw_address = $raw_address + $filesize2
	$raw_address_hex = _dectolittleendian($raw_address)
	DllStructSetData($bufferrawaddress, 1, "0x" & $raw_address_hex)
	If $i = $targetsection Then
		$offsetofpayload = $raw_address - $filesize2
		$targetsectionname = _hextostring(DllStructGetData($psectionstable, "Name"))
		ConsoleWrite("Writing payload to offset: 0x" & Hex($offsetofpayload, 8) & @CRLF)
		_writedatatofileoffset($hfileoutput, $raw_address - $filesize2, $bufferwholefilepayload)
	EndIf
	If $i > $targetsection - 1 Then
		ConsoleWrite("Updated RAW_ADDRESS: 0x" & Hex(DllStructGetData($bufferrawaddress, 1), 8) & @CRLF)
		_writedatatofileoffset($hfileoutput, $offsetofraw_address, $bufferrawaddress)
	EndIf
	ConsoleWrite("Section: " & $i & @CRLF)
	ConsoleWrite("Name: " & _hextostring(DllStructGetData($psectionstable, "Name")) & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("VIRTUAL_SIZE: 0x" & Hex(DllStructGetData($psectionstable, "VIRTUAL_SIZE"), 8) & @CRLF)
	ConsoleWrite("VIRTUAL_ADDRESS: 0x" & Hex(DllStructGetData($psectionstable, "VIRTUAL_ADDRESS"), 8) & @CRLF)
	ConsoleWrite("RAW_SIZE: 0x" & Hex(DllStructGetData($psectionstable, "RAW_SIZE"), 8) & @CRLF)
	ConsoleWrite("RAW_ADDRESS: 0x" & Hex(DllStructGetData($psectionstable, "RAW_ADDRESS"), 8) & @CRLF)
	ConsoleWrite("RELOC_ADDRESS: 0x" & Hex(DllStructGetData($psectionstable, "RELOC_ADDRESS"), 8) & @CRLF)
	ConsoleWrite("Linenumbers: 0x" & Hex(DllStructGetData($psectionstable, "Linenumbers"), 8) & @CRLF)
	ConsoleWrite("RelocationsNumber: 0x" & Hex(DllStructGetData($psectionstable, "RelocationsNumber"), 4) & @CRLF)
	ConsoleWrite("LinenumbersNumber: 0x" & Hex(DllStructGetData($psectionstable, "LinenumbersNumber"), 4) & @CRLF)
	ConsoleWrite("Characteristics: 0x" & Hex(DllStructGetData($psectionstable, "Characteristics"), 8) & @CRLF & @CRLF)
	$offsetofraw_address += 40
	$testbuff += 40
Next
_winapi_setfilepointer($hfilecontainer, $offsetofpayload)
$tbuffer4 = DllStructCreate("align 1;byte[" & $filesize - $offsetofpayload & "]")
$read = _winapi_readfile($hfilecontainer, DllStructGetPtr($tbuffer4), DllStructGetSize($tbuffer4), $nbytes)
If $read = 0 Then
	MsgBox(0, "Error", "ReadFile failed")
	Exit
EndIf
_winapi_setfilepointer($hfileoutput, $offsetofpayload + $filesize2)
_winapi_writefile($hfileoutput, DllStructGetPtr($tbuffer4), DllStructGetSize($tbuffer4), $nbytes)
_winapi_closehandle($hfileoutput)
_winapi_closehandle($hfilepayload)
_winapi_closehandle($hfilecontainer)
$batchfilename = $newoutputname & ".bat"
$hbatchfile = FileOpen($batchfilename, 2)
If NOT $hbatchfile Then
	MsgBox(0, "Error", "Could not open file")
	Exit
EndIf
$samplecmdline = "VeraCrypt.exe /v " & '"' & $newoutputname & '"' & " /l x /a /p password /i " & $offsetofpayload
FileWriteLine($hbatchfile, $samplecmdline)
FileClose($hbatchfile)
MsgBox(0, "Finished", "Payload injected at:" & @CRLF & "End of section number: " & $targetsection - 1 & @CRLF & "Section name: " & $targetsectionname)
Exit

Func _dectolittleendian($decimalinput)
	Return _swapendian(Hex($decimalinput, 8))
EndFunc

Func _writedatatofileoffset($targethandle, $targetoffset, $targetbuffer)
	Local $nbytes, $write
	If NOT $targethandle Then Return SetError(1, 0, 0)
	_winapi_setfilepointer($targethandle, $targetoffset)
	$write = _winapi_writefile($targethandle, DllStructGetPtr($targetbuffer), DllStructGetSize($targetbuffer), $nbytes)
	_winapi_flushfilebuffers($targethandle)
	If $write = 0 Then
		MsgBox(0, "Error", "_WriteDataToFileOffset() failed")
		Return SetError(1, 0, 0)
	Else
		Return True
	EndIf
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

Func _dosheader($hfile)
	ConsoleWrite("DosHeader: Attempt of decoding.." & @CRLF)
	Local $dos_header[18], $nbytes
	_winapi_setfilepointer($hfile, 0)
	Local $fsize = 64
	$tbuffer = 0
	$tbuffer = DllStructCreate("byte[" & $fsize & "]")
	$read = 0
	$read = _winapi_readfile($hfile, DllStructGetPtr($tbuffer), $fsize, $nbytes)
	If $read = 0 Then
		ConsoleWrite("DosHeader: Error ReadFile failed" & @CRLF)
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
	ConsoleWrite("DosHeader: Magic = " & $dos_header[0] & @CRLF)
	ConsoleWrite("DosHeader: AddressOfNewExeHeader (PE start) = 0x" & Hex($dos_header[17], 8) & @CRLF)
	Return $dos_header
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
