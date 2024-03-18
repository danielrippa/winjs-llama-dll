unit ChakraLlamaTypes;

{$mode delphi}

interface

  uses
    LlamaTypes, ChakraLlamaUtils;

  type

    TModelParams = record
      LayersToOffloadToGPU: Integer;
    end;

    TContextParams = record
      ThreadsToUseForGeneration: Integer;
      ThreadsToUseForBatchProcessing: Integer;
    end;

    TGenerationParams = record

      // https://github.com/ggerganov/llama.cpp/blob/master/examples/main/README.md

      Temperature: Single;

      // Temperature is a hyperparameter that controls the randomness of the generated text.
      // A higher temperature (e.g. 1.5) makes the output more random and creative.
      // A lower temperature (e.g. 0.5) makes the output more focused, deterministic and conservative.
      // The default value is 0.8 which provides a balance between randomness and determinism.
      // At the extreme, a temperature of 0 will always pick the most likely next token, leading
      // to identical outputs in each run.

      TopKSampling: Integer;

      // Top-k sampling is a text generation method that selects the next token only from the top k
      // most likely tokens predicted by the model.
      // It helps reduce the risk of generating low-probability or nonsensical tokens,
      // but it may also limit the diversity of the output.
      // A higher value (e.g. 100) will consider more tokens and may lead to more diverse text
      // A lower value (e.g. 10) will focus on the most probable tokens and generate more conservative text
      // The default value is 40.

      TopPSampling: Single;

      // Top-p sampling, also known as nucleus sampling, is another text generation method
      // that selects the next token from a subset of tokens that together have a cummulative probability of at least p.
      // This method provides a balance between diversity and quality
      // by considering both the probabilities of tokens and the number of tokens to sample from.
      // A higher value (e.g. 0.95) will lead to more diverse text
      // A lower value (e.g. 0.5) will generate more focused and conservative text.
      // The default value is 0.9.

      TailFreeSampling: Single;

      // Tail free sampling (TFS) is a text generation method that aims to reduce the impact of less likely tokens
      // which may be less relevant, les coherent, or nonsensical, on the output.
      // Similar to Top-P, it tries to determine the bulk of the most likely tokens dinamically.
      // But TFS filters out logits based on the second derivative of their probability.
      // Adding tokens is stopped after the sum of the second derivatives reaches the parameter Z.
      // TFS looks how quickly the probabilities of the tokens decrease and cuts off the tail of unlikely tokens
      // using the parameter Z.
      // Typical values for z are in the range of 0.9 to 0.95.
      // A value of 1.0 would include all tokens, and thus disables the effect of TFS.

      LocallyTypicalSampling: Single;

      // Locally typical sampling promotes the generation of contextually coherent and diverse text
      // by sampling tokens that are typical or expected based on the sorrounding context.
      // By setting the parameter P between 0 and 1, you can control the balance between producing text
      // that is locally coherent and diverse.
      // A value closer to 0 will promote more diverse tokens.
      // A value equal to 1 disables locally typical sampling.

    end;

    TModel = record
      private
        FModel: Pllama_model;
        FContext: Pllama_context;
        FModelParams: Tllama_model_params;
        FContextParams: Tllama_context_params;
        FTokenList: TTokenList;
        FNumTokensInInput: Integer;
        FNumTokensToGenerate: Integer;
        FContextLenght: Integer;
        FMaxContextSize: Integer;
        FTokenCandidates: array of Tllama_token_data;
      public
        ModelParams: TModelParams;
        ContextParams: TContextParams;
        GenerationParams: TGenerationParams;

        procedure Init;
        procedure Finalize;
        function Load(aModelFilePath: WideString): Boolean;
        procedure Prompt(aMessage: WideString);
        function Generate(aTokensRequested: Integer = 1024): String;
    end;

implementation

  uses
    LlamaAPI, Math;

  procedure TModel.Init;
  begin

    FTokenList := TTokenList.Create;
    FModelParams := llama_model_default_params;

    with FModelParams do begin
      n_gpu_layers := ModelParams.LayersToOffloadToGPU;
    end;

    FContextParams := llama_context_default_params;

    with FContextParams do begin
      n_threads := ContextParams.ThreadsToUseForGeneration;
      n_threads_batch := ContextParams.ThreadsToUseForBatchProcessing;
    end;

  end;

  procedure TModel.Finalize;
  begin
    FTokenList.Free;
  end;

  function TModel.Load;
  var
    ModelName: AnsiString;
  begin
    ModelName := aModelFilePath;

    FModel := llama_load_model_from_file(PChar(ModelName), FModelParams);

    FContext := llama_new_context_with_model(FModel, FContextParams);

    Result := FModel <> Nil;
  end;

  procedure TModel.Prompt;
  var
    PromptMessage: AnsiString;
  begin
    PromptMessage := aMessage;
    FTokenList.Count := Length(PromptMessage) + 1;

    FMaxContextSize := llama_n_ctx(FContext);

    // recibe el prompt y lo tokeniza, almacenandolo en tokenlist, devuelve la cantidad de tokens que asigno al tokenlist
    FNumTokensInInput := llama_tokenize(FModel, PChar(PromptMessage), Length(PromptMessage), FTokenList.Data, FTokenList.Count, False, False);
  end;

  function SanitizedTokenString(Model: Pllama_model; TokenID: Tllama_token): String;
  var
    I: Integer;
    AddSpace: Boolean;
  begin
    Result := llama_token_get_text(Model, TokenID);
    I := 1;
    while I <= Length(Result) do begin
      if not (Result[I] in [#32..#126]) then begin
        if Ord(Result[I]) = 150 then begin
          Result[I] := ' ';
        end else begin
          Delete(Result, I, 1);
        end;

      end else begin
        Inc(I);
      end;
    end;
  end;

  function TModel.Generate;
  var
    NumVocabTokens: Integer;
    Logits: PSingle;
    TokenID: Tllama_token;
    TokenCandidates: array of Tllama_token_data;
    TokenCandidatesArray: Tllama_token_data_array;
    MinTokensToKeep, NumProbabilities, NumTokensInInput: Integer;
    TokenText: String;
    NumTokensInCache: Integer;
  begin
    Result := '';

    FNumTokensToGenerate := Min(aTokensRequested, FMaxContextSize);

    TokenCandidates := [];

    if llama_get_kv_cache_token_count(FContext) < FNumTokensToGenerate then begin

      NumTokensInCache := llama_get_kv_cache_token_count(FContext);

      // FNumTokensInInput lo obtuvo cuando ejecuto Prompt
      llama_eval(FContext, FTokenList.Data, FNumTokensInInput, NumTokensInCache);

      FTokenList.Clear;

      NumVocabTokens := llama_n_vocab(FModel);
      SetLength(TokenCandidates, NumVocabTokens);

      Logits := llama_get_logits(FContext);

      for TokenID := 0 to NumVocabTokens - 1 do begin

        with TokenCandidates[TokenID] do begin
          id := TokenID;
          logit := Logits[TokenID];
          p := 0.0;
        end;

      end;

      with TokenCandidatesArray do begin
        data := @TokenCandidates[0];
        size := NumVocabTokens;
        sorted := False;
      end;

      // NumProbabilities := 1;
      // MinTokensToKeep := Max(1, NumProbabilities);

      MinTokensToKeep := 1;

      with GenerationParams do begin

        llama_sample_top_k(FContext, @TokenCandidatesArray, TopKSampling, MinTokensToKeep);
        llama_sample_tail_free(FContext, @TokenCandidatesArray, TailFreeSampling, MinTokensToKeep);
        llama_sample_typical(FContext, @TokenCandidatesArray, LocallyTypicalSampling, MinTokensToKeep);
        llama_sample_top_p(FContext, @TokenCandidatesArray, TopPSampling, MinTokensToKeep);
        llama_sample_temperature(FContext, @TokenCandidatesArray, Temperature);

      end;

      TokenID := llama_sample_token(FContext, @TokenCandidatesArray);

      if TokenID = llama_token_eos(FModel) then begin

        Result := '<EOS>'

      end else begin

        if TokenID = llama_token_nl(FModel) then begin

          Result := #10;

        end else begin

          Result := SanitizedTokenString(FModel, TokenID);
          FTokenList.Add(TokenID);

          FNumTokensInInput := 1;

        end;

      end;

    end;

  end;

end.