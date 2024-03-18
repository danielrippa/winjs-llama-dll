unit LlamaAPI;

{$calling stdcall}

interface

  uses
    LlamaTypes;

  const
    dll = 'libllama.dll';

  procedure llama_backend_init(numa: TBool); external dll;

  function llama_context_default_params: Tllama_context_params; external dll;
  function llama_model_default_params: Tllama_model_params; external dll;

   procedure llama_free(ctx: Pllama_context); external dll;

  function llama_n_vocab(ctx: Pllama_model): LongInt; external dll;

  function llama_get_kv_cache_token_count(ctx: Pllama_context): LongInt; external dll;

  function llama_eval(ctx: Pllama_context; tokens: Pllama_token; n_tokens: LongInt; n_past: LongInt): LongInt; external dll;

  function llama_get_logits(ctx: Pllama_context): Psingle; external dll;

  function llama_new_context_with_model(model: Pllama_model; params: Tllama_context_params): Pllama_context; external dll;

  function llama_load_model_from_file(path_model: PChar; params: Tllama_model_params): Pllama_model; external dll;

  function llama_n_ctx(ctx: Pllama_context): LongInt; external dll;

  procedure llama_sample_top_k(ctx: Pllama_context; candidates: Pllama_token_data_array; k: LongInt; min_keep: Tsize_t); external dll;
  procedure llama_sample_top_p(ctx: Pllama_context; candidates: Pllama_token_data_array; p: Single; min_keep: Tsize_t); external dll;

  procedure llama_sample_tail_free(ctx: Pllama_context; candidates: Pllama_token_data_array; z: Single; min_keep: Tsize_t); external dll;
  procedure llama_sample_typical(ctx: Pllama_context; candidates: Pllama_token_data_array; p: Single; min_keep: Tsize_t); external dll;
  procedure llama_sample_temperature(ctx: Pllama_context; candidates: Pllama_token_data_array; temp: Single); external dll;

  function llama_token_get_text(ctx: Pllama_model; token: Tllama_token): Pchar; external dll;

  function llama_token_eos(ctx: Pllama_model): Tllama_token; external dll;
  function llama_token_nl(ctx: Pllama_model): Tllama_token; external dll;

  function llama_tokenize(ctx: Pllama_model; text: Pchar; text_len: LongInt; tokens: Pllama_token; n_max_tokens: LongInt; add_bos: TBool; special: Tbool): LongInt; external dll;

  function llama_sample_token(ctx: Pllama_context; candidates: Pllama_token_data_array): Tllama_token; external dll;

implementation

  uses
    Math;

initialization

  SetExceptionMask(GetExceptionMask + [exOverflow,exZeroDivide,exInvalidOp]);

end.