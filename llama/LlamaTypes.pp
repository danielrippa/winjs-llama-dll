unit LlamaTypes;

{$mode objfpc}{$H+}

interface

  uses
    CTypes, DynLibs;

  type

    Tllama_model = record end;
    Pllama_model = ^Tllama_model;

    Tllama_context = record end;
    Pllama_context = ^Tllama_context;

    Tllama_token = LongInt;
    Pllama_token = ^Tllama_token;

    TBool = cbool;
    TSize_t = csize_t;
    Tuint32_t = cuint;
    Tint32_t = cint;
    Tdouble = cdouble;
    single = cfloat;
    Psingle = ^single;
    Tfloat = cfloat;
    Tint64_t = clong;
    Tuint64_t = culong;
    Tuint8_t = cuchar;
    Tint8_t = cchar;

    Tllama_token_data = record
      id: Tllama_token;
      logit: Single;
      p: Single;
    end;
    Pllama_token_data = ^Tllama_token_data;

    Tllama_token_data_array = record
      data: ^Tllama_token_data;
      size: Tsize_t;
      sorted: TBool;
    end;
    Pllama_token_data_array = ^Tllama_token_data_array;

    Tllama_progress_callback = procedure (progress:single; ctx:pointer);

    Tllama_model_kv_override_type = (LLAMA_KV_OVERRIDE_INT,LLAMA_KV_OVERRIDE_FLOAT, LLAMA_KV_OVERRIDE_BOOL);

    Taaa = record
      case longint of
        0 : ( int_value : longint );
        1 : ( float_value : Tdouble );
        2 : ( bool_value : Tbool );
    end;

    Tllama_model_kv_override = record

        key : array[0..127] of char;
        tag : Tllama_model_kv_override_type;
        aa: Taaa;

    end;
    Pllama_model_kv_override = ^Tllama_model_kv_override;

    Tllama_context_params = record

      seed : Tuint32_t;
      n_ctx : Tint32_t;
      n_batch : Tint32_t;
      n_threads : Tint32_t;
      n_threads_batch : Tint32_t;
      rope_scaling_type : Tint8_t;
      rope_freq_base : single;
      rope_freq_scale : single;
      yarn_ext_factor: single;  // YaRN extrapolation mix factor, negative = from model
      yarn_attn_factor: single; // YaRN magnitude scaling factor
      yarn_beta_fast: single;   // YaRN low correction dim
      yarn_beta_slow: single;   // YaRN high correction dim
      yarn_orig_ctx: Tuint32_t;    // YaRN original context size

      type_k: Tuint32_t;    // YaRN original context size
      type_v: Tuint32_t;    // YaRN original context size

      mul_mat_q : TBool;
      logits_all : TBool;
      embedding : TBool;
      offload_kqv : TBool;
    end;

    Tllama_model_params = record

      n_gpu_layers : Tint32_t;
      main_gpu : Tint32_t;
      tensor_split : ^single;
      progress_callback : Tllama_progress_callback;
      progress_callback_user_data : pointer;
      kv_overrides:Pllama_model_kv_override;
      vocab_only : TBool;
      use_mmap : TBool;
      use_mlock : TBool;

    end;

implementation

end.

