unit ChakraErr;

{$mode delphi}

interface

  uses
    ChakraTypes, SysUtils;

  type

    TScriptError = record
      Line: Integer;
      Column: Integer;
      Source: WideString;
      ScriptName: WideString;

      Message: WideString;

      Exception: TJsValue;
    end;

    TJsErrorCode = (
      jecNoError = 0,

      jecUsageError = $10000,
        jecInvalidArgument,
        jecNullArgument,

      jecScriptError = $30000,
        jecOutOfMemory
    );

    EChakraError = class(Exception);

    EChakraAPIError = class(EChakraError);

    EChakraScriptError = class(EChakraError)
      ScriptError: TScriptError;

      constructor Create(aMessage: WideString; aScriptError: TScriptError);
    end;

  function MessageFormatFromErrorCode(aErrorCode: TJsErrorCode): WideString;
  function GetScriptError: TScriptError;

  procedure ThrowError(aFmt: WideString; aParams: array of const);

  procedure CheckParams(FunctionName: UnicodeString; Args: PJsValue; ArgCount: Word; ArgTypes: array of TJsValueType; MandatoryCount: Integer);

implementation

  uses
    Chakra, ChakraAPI, ChakraUtils;

  function MessageFormatFromErrorCode;
  begin
    case aErrorCode of

      jecInvalidArgument: Result := 'Invalid argument value when calling Chakracore API ''%s''';
      jecNullArgument: Result := 'Argument was null when calling Chakracore API ''%s''';

    end;
  end;

  constructor EChakraScriptError.Create;
  begin
    Message := aScriptError.Message;
    ScriptError := aScriptError;
  end;

  function CreateError(Message: TJsValue): TJsValue;
  begin
    TryChakraAPI('JsCreateError', JsCreateError(Message, Result));
  end;

  procedure SetException(Message: TJsValue);
  begin
    TryChakraAPI('JsSetException', JsSetException(CreateError(Message)));
  end;

  function GetScriptError;
  var
    Metadata: TJsValue;
  begin
    TryChakraAPI('JsGetAndClearExceptionWithMetadata', JsGetAndClearExceptionWithMetadata(Metadata));

    with Result do begin
      Line := GetIntProperty(Metadata, 'line');
      Column := GetIntProperty(Metadata, 'column');
      Source := GetStringProperty(Metadata, 'source');
      ScriptName := GetStringProperty(Metadata, 'url');

      Exception := GetProperty(Metadata, 'exception');

      case GetValueType(Exception) of
        jsObject: Exception := StringifyJsValue(Exception);
      end;

      Message := JsValueAsString(Exception);
    end;
  end;

  procedure ThrowError;
  var
    Message: TJsValue;
  begin
    Message := StringAsJsString(WideFormat(aFmt, aParams));
    SetException(Message);
  end;

  procedure CheckParams;
  var
    I: Integer;
    Value: TJsValue;
    ValueType: TJsValueType;
    RequiredTypeName, ValueTypeName: UnicodeString;
    ValueString: UnicodeString;
  begin
    if MandatoryCount > ArgCount then begin
      ThrowError('Not enough parameters when calling ''%s''. %d parameters expected but %d parameters given', [FunctionName, MandatoryCount, ArgCount]);
    end;

    for I := 0 to Length(ArgTypes) - 1 do begin

      Value := Args^; Inc(Args);

      ValueType := GetValueType(Value);

      if ValueType <> ArgTypes[I] then begin

        ValueTypeName := JsTypeName(ValueType);
        ValueString := JsValueAsString(Value);

        RequiredTypeName := JsTypeName(ArgTypes[I]);

        ThrowError('Error calling ''%s''. Argument[%d] (%s)%s must be %s', [ FunctionName, I, ValueTypeName, ValueString, RequiredTypeName ]);

      end;
    end;
  end;

end.