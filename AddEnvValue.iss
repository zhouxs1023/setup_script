;[setup]
;ChangesEnvironment=true
[Code]

procedure SetEnv(aEnvName, aEnvValue: string; aIsInstall, aIsInsForAllUser: Boolean);//设置环境变量函数
var
sOrgValue: string;
sFileName, sInsFlag: string;
S1: AnsiString;
bRetValue, bInsForAllUser: Boolean;
SL: TStringList;
x: integer;
begin
bInsForAllUser := aIsInsForAllUser;
if UsingWinNT then
begin
    if bInsForAllUser then
      bRetValue := RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', aEnvName, sOrgValue)
    else
      bRetValue := RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', aEnvName, sOrgValue);
    sOrgValue := Trim(sOrgValue);
    begin
      S1 := aEnvValue;
      if pos(Uppercase(s1), Uppercase(sOrgValue)) = 0 then //还没有加入
      begin
        if aIsInstall then
        begin
          x := Length(sOrgValue);
          if (x > 0) and (StringOfChar(sOrgValue[x], 1) <> ';') then
            sOrgValue := sOrgValue + ';';
          sOrgValue := sOrgValue + S1;
        end;
      end else
      begin
        if not aIsInstall then
        begin
          StringChangeEx(sOrgValue, S1 + ';', '', True);
          StringChangeEx(sOrgValue, S1, '', True);
        end;
      end;

      if bInsForAllUser then
        RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', aEnvName, sOrgValue)
      else
      begin
        if (not aIsInstall) and (Trim(sOrgValue) = '') then
          RegDeleteValue(HKEY_CURRENT_USER, 'Environment', aEnvName)
        else
          RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', aEnvName, sOrgValue);
      end;
    end;
end else //非NT 系统,如Win98
begin
    SL := TStringList.Create;
    try
      sFileName := ExpandConstant('{sd}\autoexec.bat');
      LoadStringFromFile(sFileName, S1);
      SL.Text := s1;
      s1 :=   '"' + aEnvValue + '"';
      s1 := 'set '+aEnvName +'=%path%;' + s1 ;

      bRetValue := False;
      x := SL.IndexOf(s1);
      if x = -1 then
      begin
        if aIsInstall then
        begin
          SL.Add(s1);
          bRetValue := True;
        end;
      end else //还没添加
        if not aIsInstall then
        begin
          SL.Delete(x);
          bRetValue := True;
        end;

      if bRetValue then
        SL.SaveToFile(sFileName);
    finally
      SL.free;
    end;

end;
end;

procedure CurStepChanged(CurStep: TSetupStep);//添加环境变量
begin
	if (CurStep = ssPostInstall) and IsTaskSelected('AddEnvValue') then
	begin
	   SetEnv('path',ExpandConstant('{app}\bin'),true,true); 		
	   if WizardIsComponentSelected('gtkwave') then
	   begin
		 SetEnv('path',ExpandConstant('{app}\gtkwave\bin'),true,true); 
	   end;
	end;
end;


procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);//删除环境变量
begin
	if CurUninstallStep = usPostUninstall then
	begin
	SetEnv('path',ExpandConstant('{app}\bin'),false,true);
	SetEnv('path',ExpandConstant('{app}\gtkwave\bin'),false,true);
	end;
end;