unit ChakraLlama;

{$mode delphi}

interface

  uses
    ChakraTypes;

  function GetJsValue: TJsValue;

implementation

  uses
    Chakra, ChakraErr, ChakraLlamaTypes, Math, LlamaAPI;

  var
    Model: TModel;

  function ChakraLoadModel(Args: PJsValue; ArgCount: Word): TJsValue;
  var
    aModelFilePath: WideString;
    ModelLoaded: Boolean;
  begin
    CheckParams('loadModel', Args, ArgCount, [jsString], 1);

    aModelFilePath := JsStringAsString(Args^);
    ModelLoaded := Model.Load(aModelFilePath);

    Result := BooleanAsJsBoolean(ModelLoaded);
  end;

  function ChakraUnloadModel(Args: PJsValue; ArgCount: Word): TJsValue;
  begin
    Result := Undefined;
  end;

  function ChakraPrompt(Args: PJsValue; ArgCount: Word): TJsValue;
  var
    aPromptMessage: WideString;
  begin
    Result := Undefined;
    CheckParams('prompt', Args, ArgCount, [jsString], 1);

    aPromptMessage := JsStringAsString(Args^);
    Model.Prompt(aPromptMessage);
  end;

  function ChakraGenerate(Args: PJsValue; ArgCount: Word): TJsValue;
  begin
    Result := StringAsJsString(Model.Generate);
  end;

  function ChakraSetModelParams(Args: PJsValue; ArgCount: Word): TJsValue;
  var
    Params: TModelParams;
  begin
    Result := Undefined;
    CheckParams('setModelParams', Args, ArgCount, [jsObject], 1);

    with Model.ModelParams do begin
      LayersToOffloadToGPU := GetIntProperty(Args^, 'layersToOffloadToGpu');
    end;
  end;

  function ChakraSetGenerationParams(Args: PJsValue; ArgCount: Word): TJsValue;
  var
    Params: TGenerationParams;
  begin
    Result := Undefined;
    CheckParams('setGenerationParams', Args, ArgCount, [jsObject], 1);

    with Model.GenerationParams do begin
      Temperature := GetDoubleProperty(Args^, 'temperature');
      TopKSampling := GetIntProperty(Args^, 'topKSampling');
      TopPSampling := GetDoubleProperty(Args^, 'topPSampling');
      TailFreeSampling := GetDoubleProperty(Args^, 'tailFreeSampling');
      LocallyTypicalSampling := GetDoubleProperty(Args^, 'locallyTypicalSampling');
    end;
  end;

  function ChakraSetContextParams(Args: PJsValue; ArgCount: Word): TJsValue;
  var
    Params: TContextParams;
  begin
    CheckParams('setContextParams', Args, ArgCount, [jsObject], 1);

    with Model.ContextParams do begin
      ThreadsToUseForGeneration := GetIntProperty(Args^, 'threadsToUseForGeneration');
      ThreadsToUseForBatchProcessing := GetIntProperty(Args^, 'threadsToUseForBatchProcessing');
    end;
  end;

  function GetJsValue;
  begin
    Result := CreateObject;

    SetFunction(Result, 'loadModel', ChakraLoadModel);
    SetFunction(Result, 'unloadModel', ChakraUnloadModel);
    SetFunction(Result, 'prompt', ChakraPrompt);
    SetFunction(Result, 'generate', ChakraGenerate);

    SetFunction(Result, 'setModelParams', ChakraSetModelParams);
    SetFunction(Result, 'setGenerationParams', ChakraSetGenerationParams);
    SetFunction(Result, 'setContextParams', ChakraSetContextParams);
  end;

  initialization

    SetExceptionMask(GetExceptionMask + [exOverflow, exZeroDivide, exInvalidOp]);

    llama_backend_init(False);
    // Initializes the llama + ggml backend
    // if True, uses NUMA optimizations

    with Model.GenerationParams do begin
      Temperature := 2;
      TopKSampling := 40;
      TopPSampling := 0.88;
      TailFreeSampling := 1.0;
      LocallyTypicalSampling := 1.0;
    end;

    with Model.ModelParams do begin
      LayersToOffloadToGPU := 0;
    end;

    with Model.ContextParams do begin
      ThreadsToUseForGeneration := 1;
      ThreadsToUseForBatchProcessing := 1;
    end;

    Model.Init;

  finalization

    Model.Finalize;
end.
