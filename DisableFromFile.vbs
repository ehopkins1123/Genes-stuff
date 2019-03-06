REM ******************************************************************************
REM This script reads a MP in XML format and generates an override MP
REM that disables any Rule that only collects data and also disables
REM any manual reset monitors.
REM ******************************************************************************

If Not (WScript.Arguments.Named.Exists("InputFile")) Then
     WScript.Echo "The /InputFile: command line argument is required."
     WScript.Echo "The working directory is assumed unless a full path is given."
     WScript.Quit
End If

If Not (WScript.Arguments.Named.Exists("PublicKeyToken")) Then
     WScript.Echo "The /PublicKeyToken: command line argument is required."
     WScript.Quit
End If

If Not (WScript.Arguments.Named.Exists("DisableList")) Then
     WScript.Echo "The /DisableList: command line argument is required."
     WScript.Echo "The working directory is assumed unless a full path is given."
     WScript.Quit
End If

Set myFSO = CreateObject("Scripting.FileSystemObject")
myInputFile = WScript.Arguments.Named.Item("InputFile")
myDisableList = WScript.Arguments.Named.Item("DisableList")

If Not (myFSO.FileExists(myInputFile)) Then
     WScript.Echo "Cannot locate input file."
End If

If Not (myFSO.FileExists(myDisableList)) Then
     WScript.Echo "Cannot locate Disable file."
End If

myDisplayStringBloc = ""
myOverrideBloc = ""
refList = ""
disableCount = 0

Set objParser = CreateObject("Microsoft.XMLDOM")
objParser.Load(myInputFile)

Set versionNode = objParser.SelectSingleNode("/ManagementPack/Manifest/Identity/Version")
strVersion = versionNode.Text

Set idNode = objParser.SelectSingleNode("/ManagementPack/Manifest/Identity/ID")
strId = idNode.Text




REM ******************************************************************************
REM Check the Rules
REM ******************************************************************************

Set rulesNode = objParser.SelectSingleNode("/ManagementPack/Monitoring/Rules")

  If Not (rulesNode Is Nothing) Then

    For Each ruleNode In rulesNode.childNodes

      Set healthBlockName = ruleNode.Attributes.getNamedItem("ID")
      strRuleID = healthBlockName.nodeValue

      Set healthBlockStatus = ruleNode.Attributes.getNamedItem("Target")
      strTarget = healthBlockStatus.nodeValue

      Set myDisableFileObject = myFSO.OpenTextFile(myDisableList, 1)
      While Not myDisableFileObject.AtEndOfStream
        myLine = myDisableFileObject.ReadLine
        If myLine = strRuleID Then

          If UBound(Split(strTarget, "!")) > 0 Then
           strSourceMP = ""
             If Not (InStr(1, refList, "!" & Split(strTarget, "!")(0) & "!", 1) >= 1) Then
               refList = refList & "!" & Split(strTarget, "!")(0) & "!"
             End If
           Else
             strSourceMP = "RefMP!"
           End If
  
          myDisplayStringBloc = myDisplayStringBloc & "        <DisplayString ElementID=""" & strRuleID & ".enabled.override"">" & vBCrLf
          myDisplayStringBloc = myDisplayStringBloc & "          <Name>" & strRuleID & ".enabled.override</Name>" & vBCrLf
          myDisplayStringBloc = myDisplayStringBloc & "        </DisplayString>" & vBCrLf

          myOverrideBloc = myOverrideBloc & "      <RulePropertyOverride ID=""" & strRuleID & ".enabled.override"" Context=""" & strSourceMP & strTarget & """ Enforced=""true"" Rule=""RefMP!" & strRuleID & """ Property=""Enabled"">" & vBCrLf
          myOverrideBloc = myOverrideBloc & "        <Value>false</Value>" & vBCrLf
          myOverrideBloc = myOverrideBloc & "      </RulePropertyOverride>" & vBCrLf

        End If
      Wend
     myDisableFileObject.Close

    Next

  End If





REM ******************************************************************************
REM Create the override MP
REM ******************************************************************************


strRefBloc = ""
strRefBloc = strRefBloc & "      <Reference Alias=""RefMP"">" & vBCrLf
strRefBloc = strRefBloc & "        <ID>" & strId & "</ID>" & vBCrLf
strRefBloc = strRefBloc & "        <Version>" & strVersion & "</Version>" & vBCrLf
strRefBloc = strRefBloc & "        <PublicKeyToken>" & WScript.Arguments.Named.Item("PublicKeyToken") & "</PublicKeyToken>" & vBCrLf
strRefBloc = strRefBloc & "      </Reference>" & vBCrLf

arrRefs = Split(refList, "!")
For Each ref in arrRefs
  If ref <> "" Then

    Set rID = objParser.SelectSingleNode("/ManagementPack/Manifest/References/Reference[@Alias='" & ref & "']/ID")
    strrID = rID.Text
    Set rVer = objParser.SelectSingleNode("/ManagementPack/Manifest/References/Reference[@Alias='" & ref & "']/Version")
    strrVer = rVer.Text
    Set rTok = objParser.SelectSingleNode("/ManagementPack/Manifest/References/Reference[@Alias='" & ref & "']/PublicKeyToken")
    strrTok = rTok.Text


    strRefBloc = strRefBloc & "      <Reference Alias=""" & ref & """>" & vBCrLf
    strRefBloc = strRefBloc & "        <ID>" & strrID & "</ID>" & vBCrLf
    strRefBloc = strRefBloc & "        <Version>" & strrVer & "</Version>" & vBCrLf
    strRefBloc = strRefBloc & "        <PublicKeyToken>" & strrTok & "</PublicKeyToken>" & vBCrLf
    strRefBloc = strRefBloc & "      </Reference>" & vBCrLf

  End If
Next


strTop = ""
strTop = strTop & "<ManagementPack ContentReadable=""true"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">" & vBCrLf
strTop = strTop & "  <Manifest>" & vBCrLf
strTop = strTop & "    <Identity>" & vBCrLf
strTop = strTop & "      <ID>" & strId & ".Disable.Collection.And.ManualReset</ID>" & vBCrLf
strTop = strTop & "      <Version>" & strVersion & "</Version>" & vBCrLf
strTop = strTop & "    </Identity>" & vBCrLf
strTop = strTop & "    <Name>" & strId & ".Disable.Collection.And.ManualReset</Name>" & vBCrLf
strTop = strTop & "    <References>" & vBCrLf
strTop = strTop & strRefBloc
strTop = strTop & "    </References>" & vBCrLf
strTop = strTop & "  </Manifest>" & vBCrLf
strTop = strTop & "  <Monitoring>" & vBCrLf
strTop = strTop & "    <Overrides>" & vBCrLf



strMiddle = ""
strMiddle = strMiddle & "    </Overrides>" & vBCrLf
strMiddle = strMiddle & "  </Monitoring>" & vBCrLf
strMiddle = strMiddle & "  <LanguagePacks>" & vBCrLf
strMiddle = strMiddle & "    <LanguagePack ID=""ENU"" IsDefault=""true"">" & vBCrLf
strMiddle = strMiddle & "      <DisplayStrings>" & vBCrLf
strMiddle = strMiddle & "        <DisplayString ElementID=""" & strId & ".Disable.Collection.And.ManualReset"">" & vBCrLf
strMiddle = strMiddle & "          <Name>" & strId & ".Disable.Collection.And.ManualReset</Name>" & vBCrLf
strMiddle = strMiddle & "          <Description />" & vBCrLf
strMiddle = strMiddle & "        </DisplayString>" & vBCrLf


strBottom = ""
strBottom = strBottom & "      </DisplayStrings>" & vBCrLf
strBottom = strBottom & "    </LanguagePack>" & vBCrLf
strBottom = strBottom & "  </LanguagePacks>" & vBCrLf
strBottom = strBottom & "</ManagementPack>"



WScript.Echo "Creating " & strId & ".Disable.ForInsights.xml"
Set myOutFile = myFSO.OpenTextFile(strId & ".Disable.ForInsights.xml", 2, True, False)
myOutFile.Write strTop & myOverrideBloc & strMiddle & myDisplayStringBloc & strBottom
myOutFile.Close
