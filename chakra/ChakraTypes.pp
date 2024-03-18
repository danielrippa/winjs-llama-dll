unit ChakraTypes;

{$mode delphi}

interface

  type

    TJsValue = ^TJsHandle;
    TJsHandle = record end;

    PJsValue = ^TJsValue;

    PJsValueArray = ^TJsValueArray;
    TJsValueArray = array[0..255] of TJsValue;

    TJsValues = array of TJsValue;

    TJsValueType = (
      jsUndefined = 0,
      jsNull,
      jsNumber,
      jsString,
      jsBoolean,
      jsObject,
      jsFunction,
      jsError,
      jsArray,
      jsSymbol,
      jsArrayBuffer,
      jsTypedArray,
      jsDataView
    );

    TJsError = (
      jecNoError = 0,

      jecUsageError = $10000,
        jecInvalidArgument,
        jecNullArgument,

      jecScriptError = $30000,
        jecOutOfMemory
    );

    TJsBackgroundItemProc = procedure(CallbackState: Pointer); stdcall;

    TJsThreadServiceFunc = function(Callback: TJsBackgroundItemProc; CallbackState: Pointer): ByteBool; stdcall;

    TJsFinalizeProc = procedure(Data: Pointer); stdcall;

    TJsParseScriptAttribute = (
      psaLibraryCode,
      psaUtf16Encoded
    );

    TJsParseScriptAttributeSet = set of TJsParseScriptAttribute;

    TJsFunctionFunc = function(Args: PJsValue; ArgCount: Word): TJsValue;

    TJsNativeFunc = function(Callee: TJsValue; IsConstructCall: ByteBool; Args: PJsValue; ArgCount: Word; CallbackState: Pointer): TJsValue; stdcall;


implementation

end.