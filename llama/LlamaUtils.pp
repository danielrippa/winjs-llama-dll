unit LlamaUtils;

{$mode delphi}

interface

  uses
    LlamaTypes;

  type

    TTokenList = class
      private
        FItems: array of Tllama_token;

        function GetCount: Integer;
        procedure SetCount(const C: Integer);
      public
        function Data(const P: Integer = 0): Pllama_token;

        procedure Add(const Item: Tllama_token);

        property Count: Integer read GetCount write SetCount;
    end;

implementation

  function TTokenList.Data;
  begin
    Result := @FItems[P];
  end;

  procedure TTokenList.Add;
  begin
    SetLength(FItems, Length(FItems) + 1);
    FItems[High(FItems)] := Item;
  end;

  function TTokenList.GetCount;
  begin
    Result := Length(FItems);
  end;

  procedure TTokenList.SetCount;
  begin
    SetLength(FItems, C);
  end;

end.
