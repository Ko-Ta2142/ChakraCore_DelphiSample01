program Project1;

{$APPTYPE CONSOLE}

uses
  //fastmm4,
  SysUtils,classes,
  ChakraCommon,ChakraCommonWindows;

// \r\n
const _nn : string = char(10)+char(13);

// call & callback function argments cast record
type TJsParamsRecord = packed record   //packed
  _this : JsValueRef;
  values : array [0..31-1] of JsValueRef;
end;
PJsParamsRecord = ^TJsParamsRecord;


// get errorcode message
function jsErrorToString(error : JsErrorCode):string;
begin
  result := 'error code : ' + IntToStr(integer(error));
  case error of
     JsErrorInvalidArgument : result := 'TypeError: InvalidArgument';
     JsErrorNullArgument    : result := 'TypeError: NullArgument';
     JsErrorArgumentNotObject : result := 'TypeError: ArgumentNotAnObject';
     JsErrorOutOfMemory     : result := 'OutOfMemory';
     JsErrorScriptException : result := 'ScriptError';
     JsErrorScriptCompile   : result := 'SyntaxError';
     JsErrorFatal           : result := 'FatalError"';
     JsErrorInExceptionState: result := 'ErrorInExceptionState';
  end;
end;

// ref dispose
procedure ReleaseValueRef(ref:JsValueRef);
var
  count : LongWord;
begin
  if ref = nil then exit;
  if JsRelease(JsRef(ref),count) = JsNoError then exit;

  raise exception.Create('ReleaseValueRef.error');
end;

// property set(new) get delete
function SetProperty(obj:JsValueRef; const name:string; value:JsValueRef):boolean;
var
  idref : JsPropertyIdRef;
begin
  result := true;
  if JsGetPropertyIdFromName(pwchar_t(name),idref) = JsNoError then
    if JsSetProperty(obj,idref,value,true) = JsNoError then
      exit;

  result := false;
end;

function GetProperty(obj:JsValueRef; const name:string; _type:JsValueType):JsValueRef;
var
  idref : JsPropertyIdRef;
  t : JsValueType;
begin
  if JsGetPropertyIdFromName(pwchar_t(name),idref) = JsNoError then
    if JsGetProperty(obj,idref,result) = JsNoError then
      if JsGetValueType(result,t) = JsNoError then
        if _type = t then
          exit;

  result := nil;
end;

function DeleteProperty(obj:JsValueRef; const name:string):boolean;
var
  idref : JsPropertyIdRef;
  ret : JsValueRef;  // Whether the property was deleted.
begin
  result := true;
  if JsGetPropertyIdFromName(pwchar_t(name),idref) = JsNoError then
    if jsDeleteProperty(obj,idref,true,ret) = JsNoError then
      exit;

  result := false;
end;

// function
procedure EntryFunction(obj : JsValueRef; const name:string; func:JsNativeFunction; state:pointer);
var
  ref : JsValueRef;
begin
  if jsCreateFunction(func,state,ref) = JsNoError then
    if SetProperty(obj,name,ref) then
      exit;

  raise exception.Create('EntryFunction.error');
end;

// string
procedure MakeString(var value:JsValueRef; const s:string);
begin
  if JsPointerToString(pwchar_t(s),length(s),value) = JsNoError then exit;

  raise exception.Create('CreateString.error');
end;

function GetString(value:JsValueRef):string;
var
  wptr : pwchar_t;
  len : size_t;
  t : JsValueType;
  strref : JsValueRef;
begin
  result := '';
  if JsGetValueType(value,t) = JsNoError then
  begin
    // convert string
    if t = JsString then
    begin
      strref := value
    end
    else
    begin
      jsConvertValueToString(value,strref);   // .toString()
    end;
    // copy to native string buffer
    if jsStringToPointer(strref,wptr,len) = JsNoError then
    begin
      SetLength(result,len);
      move(wptr[0],result[1],len*sizeof(wchar_t));
      exit;
    end;
  end;

  raise exception.Create('GetString.error');
end;

// user class
procedure ObjectDispose_callback(data: Pointer); stdcall;
begin
  TObject(data).Free;   // call super class dispose
  Writeln( 'object.dispose:0x' + IntToHex(Integer(data),8) );
end;

procedure MakeObject(var value:JsValueRef; obj:TObject);
begin
  Writeln( 'object.entry:0x' + IntToHex(Integer(obj),8) );
  if JsCreateExternalObject(pointer(obj),ObjectDispose_callback,value) = JsNoError then exit;

  raise exception.Create('CreateObject.error');
end;

function GetObject(value:JsValueRef):TObject;
begin
  // valuetype is JsObject
  result := nil;
  if JsGetExternalData(value,pointer(result)) = JsNoError then exit;

  raise exception.Create('GetObject.error');
end;

// array
procedure SetArray(_array:JsValueRef; index:integer; value:JsValueRef);
var
  indexref : JsValueRef;
begin
  if JsIntToNumber(index,indexref) = JsNoError then
    if JsSetIndexedProperty(_array,indexref,value) = JsNoError then
      exit;

  raise exception.Create('SetArray.error');
end;

function GetArray(_array:JsValueRef; index:integer; _type:JsValueType):jsValueRef;
var
  t : JsValueType;
  //len : integer;
  indexref : JsValueRef;
begin
  result := nil;
  // length check
  //JsNumberToInt( GetProperty(_array,'length',JsValueNumber) , len );
  //if (len >= index)or(index < 0) then
  //begin
  //  raise exception.Create('GetArray.out of index');
  //end;

  if JsIntToNumber(index,indexref) = JsNoError then
    if JsGetIndexedProperty(_array,indexref,result) = JsNoError then
      if JsGetValueType(result,t) = JsNoError then
        if t = _type then
          exit;

  raise exception.Create('GetArray.error');
end;

// object
//   GetProperty & SetProperty use.



// other value type
// type
//   isGetValueType
// set
//   null set ????
//   JsDoubleToNumber
//   JsIntToNumber
//   JsBoolToBoolean
// get
//   JsGetUndefinedValue
//   JsGetNullValue
//   JsNumberToDouble
//   JsNumberToInt
//   JsBooleanToBool
// delete
//   JsDeleteProperty
// exists
//   JsHasProperty

// print object property
function PrintObject(obj:JsValueRef; space:string=''):string;
  function inToString(ref:JsValueRef):string;
  var
    t : JsValueType;
    strref : JsValueRef;
  begin
    result := '';
    JsGetValueType(ref,t);
    if t = JsString then
    begin
      result := GetString(ref);
    end
    else
    begin
      if jsConvertValueToString(ref,strref) = JsNoError then result := GetString(strref);
    end;
  end;
var
  names : JsValueRef;
  namecount : integer;
  ref,idref : JsValueRef;
  t : JsValueType;
  i : integer;
  name,value : string;
begin
  // is object or error?
  JsGetValueType(obj,t);
  if (t <> JsObject)and(t <> jsError) then
  begin
    result := inToString(obj);
    exit;
  end;

  result := '';
  JsGetOwnPropertyNames(obj,names);   // get propert name array object : ["aaa","bbb","cccc"]

  ref := GetProperty(names,'length',JsNumber);  // get array count
  if ref = nil then exit;
  JsNumberToInt(ref,namecount);

  for i:=0 to namecount-1 do
  begin
    ref := GetArray(names,i,JsString);
    if ref = nil then continue;
    name := GetString(ref);

    if JsGetPropertyIdFromName(pwchar_t(name),idref) <> JsNoError then continue;
    if JsGetProperty(obj,idref,ref) <> JsNoError then continue;

    value := inToString(ref);
    value := space + name + ' : ' + value;
    if result = '' then
      result := result + value
    else
      result := result + _nn + value;
  end;
end;

// error handling
function ScriptErrorHandling(error:JsErrorCode; const filename:string=''):string;
var
  exception : JsValueRef;
begin
  if error = JsNoError then exit;

  result := 'filename : ' + filename;                            // file , url , function name
  result := result + _nn + 'error : ' + jsErrorToString(error);  // JsErrorCode(int) -> string

  //exception object
  if jsGetAndClearException(exception) = JsNoError then
  begin
    result := result + _nn + PrintObject(exception,'');
  end;

  result := '----------' + _nn + result + _nn + '----------';
end;

// run script from string. load on memory.
function RunScriptString(runtime: JsRuntimeHandle; const script,filename: string):string;
var
  currentSourceContext: LongWord;
  error: JsErrorCode;
  resultValue : JsValueRef;

  strValueRef : JsValueRef;
  strPointer : pwchar_t;
  strBuffer : string;
  strLength: size_t;
begin
  result := '';

  // Run the script.
  error := JsRunScript(pwchar_t(script), @currentSourceContext, pwchar_t(filename), resultValue);

  // error handling
  result := ScriptErrorHandling(error,filename);

  // return value
  if error = JsNoError then
  begin
    error := JsConvertValueToString(resultValue, strValueRef);
    if error = JsNoError then
    begin
      error := JsStringToPointer(strValueRef, strPointer, strLength);
      setLength(strBuffer, strLength);  //get word count
      move(strPointer[0], strBuffer[1], strLength * sizeof(wchar_t));
      Writeln('result : ' + strBuffer);
    end;
  end;
end;

// call JSfunction
function CallFunction(obj : JsValueRef; const name:string; params:PJsParamsRecord; paramcount:integer; var retvalue:JsValueRef):string;
var
  ref : JsValueRef;
  error : JsErrorCode;
begin
  result := '';
  retvalue := nil;
  if paramcount > 31 then
  begin
    raise exception.Create('CallFunction.too many params');
  end;

  ref := GetProperty(obj,name , JsFunction);
  if ref <> nil then
  begin
    error := jsCallFunction(ref,PJsValueRef(params),paramcount,retvalue);
    result := ScriptErrorHandling(error,'*function:'+name);
    exit;
  end;

  raise exception.Create('CallFunction.error');
end;

// Runtime
procedure CreateRuntime(var runtime:JsRuntimeHandle; var context:JsContextRef);
begin
  // Create a runtime.
  JsCreateRuntime(JsRuntimeAttributeNone, nil, runtime);

  // Create an execution context.
  JsCreateContext(runtime, context);

  // Now set the execution context as being the current one on this thread.
  JsSetCurrentContext(context);
end;

procedure DisposeRuntime(runtime:JsRuntimeHandle);
begin
  if runtime = nil then exit;

  JsSetCurrentContext(JS_INVALID_REFERENCE);
  JsDisposeRuntime(runtime);
end;

// script load from file
function RunScriptFile(var runtime: JsRuntimeHandle; const filename: string):string;
var
  sl : TStringList;
  script : string;
begin
  result := '';

  sl := TStringList.Create;
  try
    sl.LoadFromFile(filename);
  except
    sl.Free;
    Writeln('file open error : '+filename);
    exit;
  end;

  script := sl.Text;
  sl.free;

  result := RunScriptString(runtime , script,filename);
end;


// pause (like getchar())
procedure pause;
var
  c : char;
begin
  Readln(c);
end;

// entry global functions
function implement_print(callee: JsValueRef; isConstructCall: bool; arguments: PJsValueRef; argumentCount: Word; callbackState: Pointer):JsValueRef; stdcall;
var
  s : string;
  pParams : PJsParamsRecord;
begin
  if argumentCount <> 2 then
  begin
    raise exception.Create('callback implement_printf.param error');
  end;

  pParams := PJsParamsRecord(arguments);  //cast
  s := GetString(pParams^.values[0]);
  Writeln(s);

  result := nil;
end;

// main code
procedure main_test(runtime:JsRuntimeHandle);
var
  global : JsValueRef;
  ref,obj,subret : JsValueRef;
  s,error : string;
  params : TJsParamsRecord;
  sl : TStringList;
  a : integer;
begin
  JsGetGlobalObject(global);  // get from current context (JsSetCurrentContext)

  // implement function
  EntryFunction(global,'imp_print',implement_print,nil);

  // set & create value
  MakeString(ref,'set value test');
  SetProperty(global,'g_value',ref);

  // get value
  ref := GetProperty(global,'g_value',JsString);
  s := GetString(ref);
  Writeln('get:g_value:'+s);

  // call JS function
  params._this := global;                 // need "this."
  MakeString(ref,'sample message');
  params.values[0] := ref;
  error := CallFunction(global,'callback_test',@params,2,subret);   // paramcount : include "this." in 2
  if error <> '' then Writeln(error);

  // user object
  sl := TStringList.Create;
  MakeObject(ref,sl);
  SetProperty(global,'g_class',ref);

  // delete user object
  //JsIntToNumber(0,ref);
  //SetProperty(global,'g_class',ref);
  DeleteProperty(global,'g_class');    // property delete , but not call dispose function(class destroy).

  // GC all
  JsCollectGarbage(runtime);

  // create array
  JsCreateArray(2,obj);
  SetProperty(global,'g_array',obj);
  JsIntToNumber(12300,ref);
  SetArray(obj,0,ref);
  JsIntToNumber(45600,ref);
  SetArray(obj,1,ref);
  //a := 789;
  //JsIntToNumber(a,ref);    //add error in call function . SetArray no detect error.
  //SetArray(obj,3,ref);

  a := 0;
  ref := GetArray(obj,1,JsNumber);
  JsNumberToInt(ref,a);

  Writeln('get array[1]:'+IntToStr(a));

  // print array
  params._this := global;                 // need "this."
  error := CallFunction(global,'array_test',@params,1,subret);
  if error <> '' then Writeln(error);
end;

procedure main;
var
  error : string;
  runtime: JsRuntimeHandle;
  context: JsContextRef;
begin
  CreateRuntime(runtime,context);;

  error := RunScriptFile(runtime,'sample01.js');
  if error = '' then
  begin
    Writeln('script run complete.');
    main_test(runtime);
  end
  else
  begin
    Writeln('script run failed.');
    Writeln(error);
  end;

  DisposeRuntime(runtime);

  pause;   // console pause
end;

begin
  //ReportMemoryLeaksOnShutdown := true;    //fastmm4 memory leak check enable

  main;
end.
