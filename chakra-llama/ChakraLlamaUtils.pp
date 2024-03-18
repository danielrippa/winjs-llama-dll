unit ChakraLlamaUtils;

{$mode objfpc}

interface

  uses
    Generics.Collections, LlamaTypes;

  type

    TTokenList = class(specialize TList<Tllama_token>)
    public
      function Data(const P: Integer = 0): Pllama_token;
    end;

implementation

  function TTokenList.Data(const P: Integer = 0): Pllama_token;
  begin
    Result := @FItems[P];
  end;

end.