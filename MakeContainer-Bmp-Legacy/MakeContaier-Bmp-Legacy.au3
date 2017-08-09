#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Turn a VeraCrypt container into a bmp
#AutoIt3Wrapper_Res_Description=Turn a VeraCrypt container into a bmp
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
$File = FileOpenDialog("Select binary file with encrypted bytes",@ScriptDir,"All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $File & @CRLF)
$hFile = FileOpen($File,16)
$rFile = FileRead($hFile)
$Startpos = 3
$Signature = "424d"
$SizeDec = BinaryLen($rFile)+54
$Size = _SwapEndian(Hex($SizeDec,8))
$Reserved = "00000000" ; 4 bytes
$OffsetPixelArray = 54 ; default value
$OffsetPixelArray = _SwapEndian(Hex($OffsetPixelArray,8))
; DIB header
$DIBHeaderSize = 40
$DIBHeaderSize = _SwapEndian(Hex($DIBHeaderSize,8))
$GuessedWidth = Int(Sqrt($SizeDec/6)*2)
If Mod($GuessedWidth,4) Then
	Do
		$GuessedWidth+=1
		If Mod($GuessedWidth,4)=0 Then ExitLoop
	Until Mod($GuessedWidth,4)=0
EndIf
;$fillbytes=""
;For $i = 1 To 65482
;	$fillbytes &= Hex(Random(0, 255, 1), 2)
;	$fillbytes &= "00"
;Next
$DIBImageWidthDec = InputBox("Set wanted image width (X)","The height will be automatically set",$GuessedWidth)
If @error Then Exit
$DIBImageWidth = _SwapEndian(Hex($DIBImageWidthDec,8))
$DIBNumberOfPlanes = 1 ;2 bytes
$DIBNumberOfPlanes = _SwapEndian(Hex($DIBNumberOfPlanes,4))
$DIBBppDec = 24;2 bytes
$DIBBpp = _SwapEndian(Hex($DIBBppDec,4))
$DIBCompression = "00000000";4 bytes
$DIBImageSize = BinaryLen($rFile);4 bytes
$DIBImageSize = _SwapEndian(Hex($DIBImageSize,8))
$DIBXPixPerMeter = 2835;4 bytes
$DIBXPixPerMeter = _SwapEndian(Hex($DIBXPixPerMeter,8))
$DIBYPixPerMeter = 2835;4 bytes
$DIBYPixPerMeter = _SwapEndian(Hex($DIBYPixPerMeter,8))
$DIBColorsInTable = "00000000";4 bytes
$DIBImportantColorCount = "00000000";4 bytes

$TargetSize = BinaryLen($rFile)
$SizeX = $DIBImageWidthDec*6 ; Size of width x default colors per pixel
$MaxHeight = Ceiling(($TargetSize*2)/$SizeX)  ; Y
$TestSize = $DIBImageWidthDec*$MaxHeight*3 ; Caclulated total needed pixels
$TestDiff = $TestSize-$TargetSize ; Calculate diff to estimated image size
$TestDiff += 54
If $TestDiff > 0 Then ; Align total pixels according to X/Y
	For $i = 1 To $TestDiff
		$rFile &= Hex(Random(0, 255, 1), 2)
;		$rFile &= "00"
	Next
EndIf

$RecompiledPixArray = StringMid($rFile, 3 + 108)
$NewSize = StringLen($RecompiledPixArray)/2
$NewSizeWithHeader = $NewSize + 54
$NewSize = _SwapEndian(Hex(Int($NewSize),8))
$NewSizeWithHeader = _SwapEndian(Hex(Int($NewSizeWithHeader),8))
$MaxHeightDec = $MaxHeight
$MaxHeight = _SwapEndian(Hex($MaxHeight,8))
; Recreate BMP header + DIB header
$RecreatedHeader = $Signature&$NewSizeWithHeader&$Reserved&$OffsetPixelArray&$DIBHeaderSize&$DIBImageWidth&$MaxHeight&$DIBNumberOfPlanes&$DIBBpp&$DIBCompression&$NewSize&$DIBXPixPerMeter&$DIBYPixPerMeter&$DIBColorsInTable&$DIBImportantColorCount
$OutData = "0x"&$RecreatedHeader&$RecompiledPixArray
; Name output file to indicate which X/Y it's recreated from
$OutFile = FileOpen($File&"."&$DIBImageWidthDec&"x"&$MaxHeightDec&".bmp",18)
FileWrite($OutFile,$OutData)
FileClose($hFile)
FileClose($OutFile)

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc
