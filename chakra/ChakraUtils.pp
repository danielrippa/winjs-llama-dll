unit ChakraUtils;

{$mode delphi}

interface

  uses
    ChakraTypes;

  function StringifyJsValue(aValue: TJsValue): TJsValue;

  function JsTypeName(Value: TJsValueType): UnicodeString;

implementation

  uses
    Chakra;

  function StringifyJsValue;
  var
    JSON: TJsValue;
    stringify: TJsValue;
    Args: Array of TJsValue;
    ArgCount: Word;
  begin
    JSON := GetProperty(GetGlobalObject, 'JSON');
    stringify := GetProperty(JSON, 'stringify');

    Args := [ JSON, aValue ];
    ArgCount := Length(Args);

    Result := CallFunction(stringify, @Args[0], ArgCount);
  end;

  function JsTypeName;
  begin
    case Value of
      JsUndefined: Result := 'Undefined';
      JsNull: Result := 'Null';
      JsNumber: Result := 'Number';
      JsString: Result := 'String';
      JsBoolean: Result := 'Boolean';
      JsObject: Result := 'Object';
      JsFunction: Result := 'Function';
      JsError: Result := 'Error';
      JsArray: Result := 'Array';
      JsSymbol: Result := 'Symbol';
      JsArrayBuffer: Result := 'ArrayBuffer';
      JsTypedArray: Result := 'TypedArray';
      JsDataView: Result := 'DataView';
    end;
  end;


end.