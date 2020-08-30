defmodule VendingMachineTest do
  use ExUnit.Case
  doctest VendingMachine

  alias VendingMachine, as: VM

  test "vending machine works" do
    vm = %VM{}

    # Let's try to load it with some coke and cookies
    assert {:ok, vm} = VM.trigger(vm, :fulfill, %{
      coke: %{price: 2, available: 1},
      cookie: %{price: 1, available: 5}
    })

    # And one more coke to ensure correct merging
    assert {:ok, vm} = VM.trigger(vm, :fulfill, %{
      coke: %{price: 2, available: 1},
    })

    assert vm.merch.coke.price == 2
    assert vm.merch.coke.available == 2
    assert vm.merch.cookie.price == 1
    assert vm.merch.cookie.available == 5

    # Now let's grab a coke
    assert {:error, {:transition, "Couldn't resolve transition"}} = VM.trigger(vm, :buy, :coke)

    # But wait, we could actually tell that before even trying:
    refute :buy in VM.allowed_events(vm)

    # Oh right, no money in there yet
    assert {:ok, vm} = VM.trigger(vm, :deposit, 1)
    assert {:ok, vm} = VM.trigger(vm, :deposit, 1)
    assert vm.balance == 2

    # Huh, hacking much? Note how error carries the callsite where it occurred
    assert {:error, {:after_event, error}} = VM.trigger(vm, :deposit, -10)
    assert error == "Expecting some positive amount of money to be deposited"

    # Gimme my coke already
    assert {:ok, vm} = VM.trigger(vm, :buy, :coke)
    assert vm.state == :dispensing

    # While it's busy, can I maybe ask for a cookie, since the balance is still there?
    assert {:error, {:transition, "Couldn't resolve transition"}} = VM.trigger(vm, :buy, :cookie)

    # Okay, the can is rolling into the tray, crosses the optical sensor, and it reports to VM...
    assert {:ok, vm} = VM.trigger(vm, :done)
    assert vm.state == :collecting
    assert vm.balance == 0
    assert vm.merch.coke.available == 1
  end
end
