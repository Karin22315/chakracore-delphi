(*

MIT License

Copyright (c) 2018 Ondrej Kelle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*)

unit Test_Classes;

interface

{$include ..\src\common.inc}

uses
  Classes, SysUtils,
{$ifdef FPC}
{$ifndef WINDOWS}
  cwstring,
{$endif}
  fpcunit, testutils, testregistry,
{$else}
  TestFramework,
{$endif}
  Compat, ChakraCoreVersion, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses;

type
  TBaseTestCase = class(TTestCase)
  private
  end;

  TChakraCoreContextTestCase = class(TBaseTestCase)
  end;

  TNativeClassTestCase = class(TBaseTestCase)
  published
    procedure TestMethod1;
    procedure TestNamedProperty;
  end;

implementation

type
  TTestObject1 = class(TNativeObject)
  private
    FMethod1Called: Boolean;
    FProp1: UnicodeString;

    function GetProp1: JsValueRef;
    procedure SetProp1(Value: JsValueRef);
    function Method1(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsHandle); override;
  public
  end;

{ TTestObject1 }

function TTestObject1.GetProp1: JsValueRef;
begin
  Result := StringToJsString(FProp1);
end;

procedure TTestObject1.SetProp1(Value: JsValueRef);
var
  SValue: UnicodeString;
begin
  SValue := JsStringToUnicodeString(Value);
  if SValue <> FProp1 then
  begin
    // Prop1 changed
    FProp1 := SValue;
  end;
end;

function TTestObject1.Method1(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  FMethod1Called := True;
end;

class procedure TTestObject1.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'method1', @TTestObject1.Method1);
end;

class procedure TTestObject1.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'prop1', False, False, @TTestObject1.GetProp1, @TTestObject1.SetProp1);
end;

{ TNativeClassTestCase }

procedure TNativeClassTestCase.TestMethod1;
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  TestObject: TTestObject1;
begin
  Runtime := nil;
  Context := nil;
  TestObject := nil;
  try
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject1.Project('Object1');
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Context.RunScript('obj.method1(null, null);', 'TestMethod1.js');
    Check(TestObject.FMethod1Called, 'method1 called');
  finally
    TestObject.Free;
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TNativeClassTestCase.TestNamedProperty;
const
  SValue: UnicodeString = 'Hello';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  TestObject: TTestObject1;
begin
  Runtime := nil;
  Context := nil;
  TestObject := nil;
  try
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject1.Project('Object1');
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Context.RunScript(WideFormat('obj.prop1 = ''%s'';', [SValue]), 'TestNamedProperty.js');
    CheckEquals(SValue, TestObject.FProp1, 'prop1 value');
    CheckEquals(SValue, JsStringToUnicodeString(JsGetProperty(TestObject.Instance, 'prop1')), 'prop1 value');
  finally
    TestObject.Free;
    Context.Free;
    Runtime.Free;
  end;
end;

initialization

{$ifdef FPC}
  RegisterTests([{TChakraCoreContextTestCase,} TNativeClassTestCase]);
{$else}
  RegisterTests([{TChakraCoreContextTestCase.Suite,} TNativeClassTestCase.Suite]);
{$endif}

end.