# VendingMachine — a state machine example

This is an example state machine built on [StateMachine](https://hexdocs.pm/state_machine):
See tests for the example of interactions.

```elixir
defmodule VendingMachine do
  alias VendingMachine, as: VM
  use StateMachine

  defstruct state: :collecting, balance: 0, merch: %{}, dispensing: nil

  defmachine do
    state :collecting
    state :dispensing

    event :deposit, after: &VM.deposit/2 do
      transition from: :collecting, to: :collecting
    end

    event :buy, if: &VM.can_sell?/2, after: &VM.reserve/2 do
      transition from: :collecting, to: :dispensing
    end

    event :done, after: &VM.charge/1 do
      transition from: :dispensing, to: :collecting
    end

    event :fulfill, after: &VM.fulfill/2 do
      transition from: :collecting, to: :collecting
    end
  end

  def deposit(%{balance: balance} = model, %{payload: x})
    when is_integer(x) and x > 0
  do
    {:ok, %{model | balance: balance + x}}
  end

  def deposit(_, _) do
    {:error, "Expecting some positive amount of money to be deposited"}
  end

  def can_sell?(model, %{payload: item}) do
    model.merch[item]
    && model.merch[item][:available] > 0
    && model.merch[item][:price] <= model.balance
  end

  def reserve(model, %{payload: item}) do
    {:ok, %{model | dispensing: item}}
  end

  def charge(%{balance: balance, dispensing: item, merch: merch} = model) do
    {:ok, %{model |
      balance: balance - merch[item][:price],
      merch: put_in(merch[item][:available], merch[item][:available] - 1),
      dispensing: nil
    }}
  end

  def fulfill(%{merch: merch} = model, %{payload: additions})
    when is_map(additions)
  do
    {:ok, %{model |
      merch: Map.merge(merch, additions, fn _, existing, new ->
        %{new | available: new.available + existing.available}
      end)
    }}
  end
end
```

## Running

```bash
git clone git@github.com:youroff/vending_machine.git
cd vending_machine
mix deps.get
mix test
```
